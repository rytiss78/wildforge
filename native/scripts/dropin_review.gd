extends RefCounted

# Two-process drop-in review: the host starts a run alone, opens a chest, and a
# new player (a different profile, not a reconnect) joins mid-run with an
# internet invite code for this machine. Both sides must end up in the same run.
const SEED=40417

static func wait_for(g,predicate: Callable,seconds: float=15) -> bool:
	var until=Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<until:
		if predicate.call(): return true
		await g.get_tree().create_timer(.05).timeout
	return false

static func finish(g,role: String,checks: Dictionary,extra: Dictionary={}):
	var result={"role":role,"checks":checks,"status":g.coop.status};result.merge(extra)
	print("DROPIN_REVIEW "+JSON.stringify(result))
	await g.get_tree().create_timer(.5).timeout
	# Same orderly shutdown as the shared review, so nothing leaks at exit.
	g.set_process(false);g.coop.leave();g.mode="test_finished";g.clear_entities();g.sound.active=false;g.sound.shutdown()
	await g.get_tree().create_timer(.25).timeout
	g.get_tree().quit(0 if not checks.values().has(false) else 1)

static func run(g,host: bool):
	AudioServer.set_bus_volume_db(0,-80);g.coop.test_mode=true
	g.career.data.settings.name="Drop Host" if host else "Drop Guest"
	# A separate profile token, so the host must treat this as a new player.
	g.career.data.settings.coopToken="dropin-"+("host" if host else "guest")
	var checks={}
	if host:
		g.coop.host_lan();g.coop.set_ready(true)
		checks.solo_start=g.coop.start_party(SEED) and g.run_active and g.coop.members.is_empty()
		g.spawn_clock=99999;g.invulnerable=1000
		var chest=g.chests.filter(func(c):return c is Dictionary and is_instance_valid(c.get("node")))
		checks.chest_opened=not chest.is_empty()
		var opened_at=Vector3.ZERO
		if checks.chest_opened: chest[0].opened=true;opened_at=chest[0].node.position
		checks.guest_joined=await wait_for(g,func():return not g.coop.members.is_empty())
		var guest_id=g.coop.members.keys()[0] if checks.guest_joined else -1
		checks.guest_playing=checks.guest_joined and await wait_for(g,func():return str(g.coop.members.get(guest_id,{}).get("mode",""))=="playing")
		checks.world_resumed=checks.guest_playing and await wait_for(g,func():return not g.coop.frozen(),5)
		checks.guest_avatar=checks.guest_playing and await wait_for(g,func():return g.coop.avatars.has(guest_id))
		checks.guest_report=await wait_for(g,func():return g.coop.test_messages.has("dropin"))
		var report=g.coop.test_messages.get("dropin",{})
		checks.same_run=int(report.get("seed",-1))==g.seed_value and int(report.get("realm",-1))==g.realm
		checks.chest_hidden_for_guest=bool(report.get("chest_hidden",false))
		checks.guest_sees_host=bool(report.get("host_avatar",false))
		var plate=g.coop.avatars[guest_id].get_meta("nameplate").text if checks.guest_avatar else ""
		checks.guest_nameplate=plate.begins_with("Drop Guest")
		# Party combos: the guest hits a target over the network, then the host hits
		# it (Crossfire); the host then strikes it with lightning while it burns
		# from the guest's fire (Overload). The guest reports the effects it saw.
		g.spawn_enemy(5);var target=g.enemies[-1];target.hp=1e6;target.maxHp=1e6;target.speed=0.0
		await g.get_tree().create_timer(1.0).timeout
		g.coop.broadcast({"type":"test_shared","phase":"combo_target","data":{"id":target.net_id}})
		checks.guest_hit=await wait_for(g,func():return g.coop.test_messages.has("combo_hit_sent"))
		await wait_for(g,func():return target.get("hitters",{}).has(guest_id),3)
		g.hurt_enemy(target,5.0,"hit","gun")
		checks.crossfire=float(target.get("crossfire_until",-1))>g.elapsed
		target.fire=6.0;target.fire_owner=guest_id;target.status_time=4.0
		g.hurt_enemy(target,10.0,"lightning","lightning")
		checks.overload=is_equal_approx(float(target.get("overload_time",-9)),g.elapsed)
		checks.guest_saw_combos=await wait_for(g,func():return int(g.coop.test_messages.get("combos_seen",{}).get("count",0))>=2)
		await finish(g,"host",checks,{"nameplate":plate,"ping":g.coop.ping_to(guest_id) if guest_id>0 else 0,"report":report})
	else:
		# Give the host time to start its run before joining.
		await g.get_tree().create_timer(3.0).timeout
		g.coop.join_lan(InviteCode.encode("127.0.0.1",g.coop.party_port))
		checks.joined_run=await wait_for(g,func():return g.coop.welcomed and g.run_active and g.mode=="playing")
		checks.host_avatar=checks.joined_run and await wait_for(g,func():return g.coop.avatars.has(g.coop.owner_id))
		var opened=g.chests.filter(func(c):return c is Dictionary and is_instance_valid(c.get("node")) and not c.node.visible)
		var report={"seed":g.seed_value,"realm":g.realm,"host_avatar":checks.host_avatar,"chest_hidden":not opened.is_empty()}
		g.coop.send_to(g.coop.owner_id,{"type":"test_shared","phase":"dropin","data":report})
		checks.combo_target=await wait_for(g,func():return g.coop.test_messages.has("combo_target"))
		var target_id=int(g.coop.test_messages.get("combo_target",{}).get("id",-1))
		checks.target_synced=await wait_for(g,func():return g.enemies.any(func(e):return e.net_id==target_id and not e.dead))
		if checks.target_synced:
			g.hurt_enemy(g.enemies.filter(func(e):return e.net_id==target_id)[0],5.0,"hit","gun")
		g.coop.send_to(g.coop.owner_id,{"type":"test_shared","phase":"combo_hit_sent","data":{}})
		checks.saw_combos=await wait_for(g,func():return g.coop.party_combos_seen>=2)
		g.coop.send_to(g.coop.owner_id,{"type":"test_shared","phase":"combos_seen","data":{"count":g.coop.party_combos_seen}})
		await g.get_tree().create_timer(2.0).timeout
		await finish(g,"client",checks,{"report":report})

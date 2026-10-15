extends RefCounted

static func wait_for(g,predicate: Callable,seconds: float=12) -> bool:
	var until=Time.get_ticks_msec()+int(seconds*1000)
	while Time.get_ticks_msec()<until:
		if predicate.call(): return true
		await g.get_tree().create_timer(.05).timeout
	return false
static func send(g,phase: String,data: Dictionary={}):
	var message={"type":"test_shared","phase":phase,"data":data}
	if g.coop.hosting: g.coop.broadcast(message)
	else: g.coop.send_to(g.coop.owner_id,message)
static func choose(g):
	if g.mode=="offer" and not g.hud.cards.is_empty(): g.hud.cards[0].pressed.emit()

static func run(g,host: bool):
	AudioServer.set_bus_volume_db(0,-80);g.coop.test_mode=true
	g.set_physics_process(false)
	if host: g.coop.host_lan()
	else: g.coop.join_lan("127.0.0.1")
	var checks={}
	if host:
		checks.connected=await wait_for(g,func():return not g.coop.members.is_empty() and g.coop.members.values()[0].get("ready",false))
		g.coop.set_ready(true);g.coop.start_party(91731)
	else:
		checks.connected=await wait_for(g,func():return g.coop.welcomed)
		g.coop.set_ready(true)
		checks.started=await wait_for(g,func():return g.run_active)
	g.set_physics_process(false);g.spawn_clock=99999;g.invulnerable=1000;g.gold=100;g.level_choice_cooldown=0
	if host:
		g.player.position=Vector3(-20,g.world.height_at(-20,0),0);g.xp=21;g.xp_target=27
		checks.client_ready=await wait_for(g,func():return g.coop.test_messages.has("ready"))
		await g.get_tree().create_timer(.3).timeout
		var member=g.coop.members.values()[0];var p=CoopSession.vector(member.position)
		g.spawn_pickup(p+Vector3.UP*.4,"xp",9)
		for i in range(30): g.update_pickups(.02);await g.get_tree().create_timer(.02).timeout
		checks.shared_level=g.level==2 and g.xp==3 and g.update.run_xp==9
		checks.client_level=await wait_for(g,func():return g.coop.test_messages.has("level"))
		var data=g.coop.test_messages.get("level",{})
		checks.same_pool=data.get("pool",[])==g.offers.map(func(o):return o.id)
		checks.client_progress=data.get("level",0)==2 and data.get("xp",0)==3 and data.get("no_private_xp",false)
		await wait_for(g,func():return g.mode=="offer");choose(g)
		await wait_for(g,func():return not g.coop.frozen() and g.mode=="playing")
		checks.no_double_xp=g.xp==3 and g.update.run_xp==9
		var chest=g.chests[0];chest.mimic=false;chest.free=false;chest.rolled_free=true
		send(g,"chest",{"position":CoopSession.array(chest.node.position)})
		checks.opened=await wait_for(g,func():return chest.opened)
		if g.mode=="reveal": g.finish_reveal()
		var pool=g.offers.map(func(o):return o.id);choose(g)
		checks.client_chest=await wait_for(g,func():return g.coop.test_messages.has("chest_done"))
		data=g.coop.test_messages.get("chest_done",{})
		checks.one_payment=data.get("gold",-1)==70 and data.get("paid",-1)==1 and g.gold==100
		checks.shared_chest_pool=data.get("pool",[])==pool and data.get("hidden",false)
		checks.resumed=await wait_for(g,func():return not g.coop.frozen() and g.mode=="playing")
		var sentry=g.update.magnet_turrets[0];var sentry_hp=sentry.hp
		send(g,"guard",{"id":sentry.net_id})
		checks.remote_guard_hit=await wait_for(g,func():return sentry.hp<sentry_hp)
		checks.critical_cause=g.damage_numbers.any(func(d):return d.enemy_id==sentry.net_id and d.cause=="crit")
		checks.no_phantom_poison=sentry.poison==0
		for guard in g.update.magnet_turrets:
			if not guard.dead: g.hurt_enemy(guard,100000,"melee")
		g.update.tick(.01)
		send(g,"magnet")
		checks.remote_magnet=await wait_for(g,func():return g.update.magnet_active)
		checks.magnet_mirrored=await wait_for(g,func():return g.coop.test_messages.has("magnet_done"))
		# Exercise the actual contact entry point and snapshot on two processes.
		g.equipped.clear();g.spawn_enemy(8);var attacker=g.enemies[-1]
		var client_id=g.coop.members.keys()[0]
		attacker.node.position=CoopSession.vector(g.coop.members[client_id].position)+Vector3.FORWARD
		attacker.speed=0;attacker.behavior="chase";attacker.contact=0;attacker.freeze=0;attacker.blind=0
		g.update_combat(.04);send(g,"contact",{"id":attacker.net_id})
		checks.remote_warning=await wait_for(g,func():return g.coop.test_messages.has("contact_seen"))
		checks.remote_warning_visible=g.coop.test_messages.get("contact_seen",{}).get("visible",false)
		g.enter_realm(3)
		checks.remote_baron=await wait_for(g,func():return g.coop.test_messages.has("baron_seen"))
		checks.remote_baron_model=g.coop.test_messages.get("baron_seen",{}).get("model",false)
		send(g,"finish",checks)
		await wait_for(g,func():return g.coop.test_messages.has("finished"))
	else:
		g.player.position=Vector3(20,g.world.height_at(20,0),0);send(g,"ready")
		checks.level_offer=await wait_for(g,func():return g.mode=="offer" and g.offer_source=="level")
		var before=g.pickups.size();g.spawn_pickup(g.player.position,"xp",999)
		checks.no_private_xp=g.pickups.size()==before
		send(g,"level",{"level":g.level,"xp":g.xp,"pool":g.offers.map(func(o):return o.id),"no_private_xp":checks.no_private_xp})
		choose(g)
		# A stale/duplicate client XP credit is never trusted by the host.
		g.coop.send_to(g.coop.owner_id,{"type":"credit","pickup_id":"xp_0","xp":999})
		checks.chest_instruction=await wait_for(g,func():return g.coop.test_messages.has("chest"))
		var position_value=CoopSession.vector(g.coop.test_messages.get("chest",{}).get("position",[]))
		g.player.position=position_value
		var chest=g.chests.filter(func(c):return c.node.position.distance_to(position_value)<.1)[0]
		chest.mimic=false;g.interact()
		g.coop.send_to(g.coop.owner_id,{"type":"chest_request","realm":g.realm,"position":CoopSession.array(position_value)})
		checks.chest_offer=await wait_for(g,func():return g.mode=="offer" and g.offer_source=="chest")
		await g.get_tree().create_timer(.3).timeout
		send(g,"chest_done",{"gold":g.gold,"paid":g.paid_chests,"pool":g.offers.map(func(o):return o.id),"hidden":chest.opened and not chest.node.visible})
		choose(g)
		checks.defenses_replicated=g.enemies.filter(func(e):return e.get("magnet_guard",false)).size()==3
		checks.guard_instruction=await wait_for(g,func():return g.coop.test_messages.has("guard"))
		var sentry=g.enemies.filter(func(e):return e.net_id==int(g.coop.test_messages.guard.id))[0]
		g.player.position=sentry.node.position+Vector3(0,0,4)
		# Carrying a poison weapon must not poison an unrelated gun hit.
		var poison=g.rules.data.weapons.filter(func(w):return w.id=="poison")[0].duplicate(true);poison.kind="weapon";poison.strength=1;poison.tier=0;g.equip_weapon(poison)
		g.coop.send_to(g.coop.owner_id,g.coop.pose());g.hurt_enemy(sentry,11,"crit","gun")
		checks.confirmed_critical=await wait_for(g,func():return g.damage_numbers.any(func(d):return d.enemy_id==sentry.net_id and d.cause=="crit"))
		checks.magnet_instruction=await wait_for(g,func():return g.coop.test_messages.has("magnet") and g.update.magnet_turret_count==0)
		g.player.position=g.update.magnet_position;g.interact()
		checks.activated=await wait_for(g,func():return g.update.magnet_active)
		send(g,"magnet_done")
		checks.contact_instruction=await wait_for(g,func():return g.coop.test_messages.has("contact"))
		var attack_id=int(g.coop.test_messages.get("contact",{}).get("id",-1))
		checks.warning_received=await wait_for(g,func():return g.enemies.any(func(e):return e.net_id==attack_id and e.get("contact_windup",0)>0))
		g.equipped.clear();g.update_combat(.04)
		var attackers=g.enemies.filter(func(e):return e.net_id==attack_id)
		checks.warning_visible=not attackers.is_empty() and attackers[0].has("contact_ring") and attackers[0].contact_ring.visible
		send(g,"contact_seen",{"visible":checks.warning_visible})
		checks.final_realm=await wait_for(g,func():return g.realm==3 and g.enemies.any(func(e):return e.get("boss_id",-1)==8))
		var bosses=g.enemies.filter(func(e):return e.get("boss_id",-1)==8)
		checks.baron_model=not bosses.is_empty() and bosses[0].node.get_meta("rig").solid.identity=="boss_8_baron" and bosses[0].node.get_meta("rig").find_children("BaronSteam*","GPUParticles3D",true,false).size()==4
		send(g,"baron_seen",{"model":checks.baron_model})
		checks.host_finished=await wait_for(g,func():return g.coop.test_messages.has("finish"))
		checks.host_checks=g.coop.test_messages.get("finish",{}).values().all(func(v):return v)
		send(g,"finished");await g.get_tree().create_timer(.3).timeout
	print("SHARED_REVIEW "+JSON.stringify({"role":"host" if host else "client","checks":checks}))
	g.set_process(false);g.coop.leave();g.mode="test_finished";g.clear_entities();g.sound.active=false;g.sound.shutdown()
	await g.get_tree().create_timer(.25).timeout
	g.get_tree().quit(0 if checks.values().all(func(v):return v) else 1)

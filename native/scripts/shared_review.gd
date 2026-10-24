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
# A teammate's nameplate is their name, optionally followed by " · <ping> ms".
static func named(text: String,name: String) -> bool:
	return text==name or text.begins_with(name+" · ") and text.ends_with(" ms")
static func choose(g):
	if g.mode=="offer" and not g.hud.cards.is_empty(): g.hud.cards[0].pressed.emit()

static func run(g,host: bool):
	AudioServer.set_bus_volume_db(0,-80);g.coop.test_mode=true
	g.career.data.settings.name="Review Host" if host else "Review Guest"
	var trace=[]
	if not host and OS.get_cmdline_user_args().has("--slow-peer"):
		Engine.max_fps=20
		Engine.physics_ticks_per_second=20
	g.set_physics_process(false)
	if host: g.coop.host_lan()
	# The guest joins with an internet invite code for this machine, exercising
	# the same decode-and-connect path a friend uses.
	else: g.coop.join_lan(InviteCode.encode("127.0.0.1",g.coop.party_port))
	var checks={}
	if host:
		checks.host_open=g.coop.active and g.coop.hosting
		checks.connected=checks.host_open and await wait_for(g,func():return not g.coop.members.is_empty() and g.coop.members.values()[0].get("ready",false))
		g.coop.set_ready(true)
		checks.lobby_valid=checks.connected and g.coop.can_start()
		if not checks.lobby_valid:
			print("SHARED_REVIEW "+JSON.stringify({"role":"host","checks":checks,"status":g.coop.status,"members":g.coop.members}))
			g.coop.leave();g.get_tree().quit(1);return
		checks.started=g.coop.start_party(91731)
		checks.ready_achievement=float(g.career.data.total.get("ready_runs",0))==1
	else:
		checks.connected=await wait_for(g,func():return g.coop.welcomed)
		if not checks.connected:
			print("SHARED_REVIEW "+JSON.stringify({"role":"client","checks":checks,"status":g.coop.status,"active":g.coop.active}))
			g.coop.leave();g.get_tree().quit(1);return
		g.coop.set_ready(true)
		checks.started=await wait_for(g,func():return g.run_active)
	if not checks.started or not g.run_active or g.chests.is_empty():
		checks.started=false;checks.has_chests=not g.chests.is_empty()
		print("SHARED_REVIEW "+JSON.stringify({"role":"host" if host else "client","checks":checks,"status":g.coop.status,"active":g.coop.active,"members":g.coop.members.size(),"realm":g.realm,"mode":g.mode,"chests":g.chests.size()}))
		g.coop.leave();g.get_tree().quit(1);return
	g.set_physics_process(false);g.spawn_clock=99999;g.invulnerable=1000;g.gold=100;g.level_choice_cooldown=0
	if not host:
		var learn=g.rules.data.loot.filter(func(item):return item.id=="study-0")[0]
		g.rules.apply_effects(g.stats,learn.effects)
		g.owned.append(learn)
		g.activate_consumable("xp")
		checks.boosted_local_stats=g.stat("xpGain")>1.7
	if host:
		var guest_id=g.coop.members.keys()[0]
		checks.custom_guest_name=g.coop.members[guest_id].get("player_name","")=="Review Guest"
		checks.remote_nameplate=await wait_for(g,func():return g.coop.avatars.has(guest_id) and named(g.coop.avatars[guest_id].get_meta("nameplate").text,"Review Guest"))
		checks.local_nameplate=is_instance_valid(g.coop.local_nameplate) and g.coop.local_nameplate.text=="Review Host"
		checks.custom_guest_xp_gain=await wait_for(g,func():return float(g.coop.members.get(guest_id,{}).get("stats",{}).get("xpGain",1))>1.7)
		checks.custom_host_lobby_name=g.coop.lobby_roster.any(func(entry):return entry.get("host",false) and entry.get("name","")=="Review Host")
	else:
		checks.custom_host_lobby_name=await wait_for(g,func():return g.coop.lobby_roster.any(func(entry):return entry.get("host",false) and entry.get("name","")=="Review Host"))
		checks.local_nameplate=is_instance_valid(g.coop.local_nameplate) and g.coop.local_nameplate.text=="Review Guest"
		checks.remote_nameplate=await wait_for(g,func():return g.coop.avatars.has(g.coop.owner_id) and named(g.coop.avatars[g.coop.owner_id].get_meta("nameplate").text,"Review Host"))
	if host:
		# Repeat a host pause/resume while the guest is otherwise playing. Each
		# transition records shared progression and both peer positions.
		for cycle in range(3):
			var phase="pause_probe_"+str(cycle);var resume_phase="pause_resumed_"+str(cycle)
			g.mode="paused";g.coop.broadcast(g.coop.snapshot(),false)
			checks[phase]=await wait_for(g,func():return g.coop.test_messages.has(phase))
			var pause_result=g.coop.test_messages.get(phase,{})
			checks[phase+"_input_blocked"]=not pause_result.get("dash_started",true) and not pause_result.get("chest_pending",true)
			var enemies=g.enemies.filter(func(e):return not e.dead).map(func(e):return {"id":e.net_id,"hp":e.hp,"position":CoopSession.array(e.node.position)}).slice(0,8)
			trace.append({"phase":phase,"host":{"mode":g.mode,"realm":g.realm,"level":g.level,"xp":g.xp,"xp_target":g.xp_target,"elapsed":g.elapsed,"position":CoopSession.array(g.player.position),"pause":g.mode!="playing","offer_source":g.offer_source,"offers":g.offers.map(func(o):return o.id),"enemies":enemies},"client":pause_result})
			g.mode="playing";g.coop.broadcast(g.coop.snapshot(),false)
			checks[resume_phase]=await wait_for(g,func():return g.coop.test_messages.has(resume_phase))
		# Early-game crowd: ~100 live enemies must keep replicating to the guest.
		var crowd_ids=[]
		for i in range(100):
			var crowd_before=g.enemies.size();g.spawn_enemy(30)
			if g.enemies.size()>crowd_before: crowd_ids.append(g.enemies[-1].net_id)
		checks.crowd_spawned=crowd_ids.size()>=90
		var crowd_bytes=var_to_bytes(g.coop.snapshot()).size()
		checks.crowd_snapshot_compact=crowd_bytes<16000
		send(g,"crowd",{"ids":crowd_ids})
		checks.crowd_reported=await wait_for(g,func():return g.coop.test_messages.has("crowd_seen"),20)
		var crowd_seen=g.coop.test_messages.get("crowd_seen",{})
		checks.crowd_snapshots_flowing=int(crowd_seen.get("snapshots",0))>=10
		checks.crowd_all_visible=int(crowd_seen.get("visible",0))==crowd_ids.size()
		trace.append({"phase":"crowd","count":crowd_ids.size(),"snapshot_bytes":crowd_bytes,"client":crowd_seen})
		for enemy in g.enemies:
			if enemy.net_id in crowd_ids: enemy.dead=true;enemy.node.queue_free()
		g.enemies=g.enemies.filter(func(e):return not e.dead)
		g.player.position=Vector3(-20,g.world.height_at(-20,0),0);g.xp=21;g.xp_target=27
		checks.client_ready=await wait_for(g,func():return g.coop.test_messages.has("ready"))
		await g.get_tree().create_timer(.3).timeout
		var member=g.coop.members.values()[0];var p=CoopSession.vector(member.position)
		g.spawn_pickup(p+Vector3.UP*.4,"xp",9)
		for i in range(30): g.update_pickups(.02);await g.get_tree().create_timer(.02).timeout
		checks.shared_level=g.level==2 and g.xp==10 and g.update.run_xp==16
		checks.client_level=await wait_for(g,func():return g.coop.test_messages.has("level"))
		var data=g.coop.test_messages.get("level",{})
		# Each player gets cards of their own (October 24 request; this used to
		# require the host's pool).
		checks.own_pool=data.get("pool",[]).size()==g.offers.size() and data.get("pool",[])!=g.offers.map(func(o):return o.id)
		var client_options=data.get("options",[])
		var client_state=g.party_seen.get(str(g.coop.members.keys()[0]),{})
		checks.client_options=data.get("reward_id","")==g.party_reward_id and client_options.size()==g.offers.size() and client_state.get("options",[]).size()==g.offers.size()
		checks.client_progress=data.get("level",0)==2 and data.get("xp",0)==10 and data.get("xp_gain",1)>1.7 and data.get("no_private_xp",false)
		await wait_for(g,func():return g.mode=="offer");choose(g)
		var client_id=g.coop.members.keys()[0]
		checks.client_choice_highlight=await wait_for(g,func():return str(g.party_seen.get(str(client_id),{}).get("selected_id",""))!="")
		await wait_for(g,func():return not g.coop.frozen() and g.mode=="playing")
		checks.no_double_xp=g.xp==10 and g.update.run_xp==16
		var chest=g.chests[0];chest.mimic=false;chest.free=false;chest.rolled_free=true
		send(g,"chest",{"position":CoopSession.array(chest.node.position)})
		checks.opened=await wait_for(g,func():return chest.opened)
		if g.mode=="reveal": g.finish_reveal()
		var pool=g.offers.map(func(o):return o.id);choose(g)
		checks.client_chest=await wait_for(g,func():return g.coop.test_messages.has("chest_done"))
		data=g.coop.test_messages.get("chest_done",{})
		checks.one_payment=data.get("gold",-1)==70 and data.get("paid",-1)==1 and g.gold==100
		checks.own_chest_pool=data.get("pool",[]).size()==pool.size() and data.get("pool",[])!=pool and data.get("hidden",false)
		checks.shared_chest_options=data.get("options",[]).size()==pool.size() and data.get("reward_id","")==g.party_reward_id and g.party_seen.get(str(client_id),{}).get("options",[]).size()==pool.size()
		checks.chest_choice_highlight=await wait_for(g,func():return str(g.party_seen.get(str(client_id),{}).get("selected_id",""))!="")
		checks.resumed=await wait_for(g,func():return not g.coop.frozen() and g.mode=="playing")
		var sentry=g.update.magnet_turrets[0];var sentry_hp=sentry.hp
		send(g,"guard",{"id":sentry.net_id})
		checks.remote_guard_hit=await wait_for(g,func():return sentry.hp<sentry_hp)
		# A teammate's hit shows on their screen only (October 24); the guest's own
		# confirmed critical is checked on its side (confirmed_critical).
		checks.teammate_number_hidden=not g.damage_numbers.any(func(d):return d.enemy_id==sentry.net_id)
		checks.no_phantom_poison=sentry.poison==0
		for guard in g.update.magnet_turrets:
			if not guard.dead: g.hurt_enemy(guard,100000,"melee")
		g.update.tick(.01)
		send(g,"magnet")
		checks.remote_magnet=await wait_for(g,func():return g.update.magnet_active)
		checks.magnet_mirrored=await wait_for(g,func():return g.coop.test_messages.has("magnet_done"))
		# Exercise the actual contact entry point and snapshot on two processes.
		g.equipped.clear();g.spawn_enemy(8);var attacker=g.enemies[-1]
		attacker.node.position=CoopSession.vector(g.coop.members[client_id].position)+Vector3.FORWARD
		attacker.speed=0;attacker.behavior="chase";attacker.contact=0;attacker.freeze=0;attacker.blind=0
		g.update_combat(.04);send(g,"contact",{"id":attacker.net_id})
		checks.remote_warning=await wait_for(g,func():return g.coop.test_messages.has("contact_seen"))
		checks.remote_warning_visible=g.coop.test_messages.get("contact_seen",{}).get("visible",false)
		# Drop 1: the guest disconnects mid-reward while the host opens another chest.
		var free_chest=func():
			var free=g.chests.filter(func(c):return not c.opened)[0];free.mimic=false;free.free=true;free.rolled_free=true
			g.buy_chest(free)
			if g.mode=="reveal": g.finish_reveal()
			choose(g);return free
		free_chest.call()
		checks.pre_drop_offer=await wait_for(g,func():return g.coop.test_messages.has("pre_drop_offer"))
		g.coop.test_messages.erase("reconnected");send(g,"reconnect_force",{"hold":1.5})
		checks.drop1_dropped=await wait_for(g,func():return g.coop.members.values().any(func(m):return m.get("disconnected",false)))
		checks.host_runs_while_away=not g.coop.frozen()
		var away_chest=free_chest.call()
		checks.drop1_rejoined=await wait_for(g,func():return g.coop.test_messages.has("reconnected"),42)
		send(g,"away_chest",{"position":CoopSession.array(away_chest.node.position)})
		checks.drop1_client=await wait_for(g,func():return g.coop.test_messages.has("drop1_done"),15) and g.coop.test_messages.drop1_done.values().all(func(v):return v)
		# Drop 2: the host travels to a new realm while the guest is away.
		var away_token=str(g.coop.members.values()[0].get("token",""))
		g.coop.test_messages.erase("reconnected");send(g,"reconnect_force",{"hold":1.5})
		checks.drop2_dropped=await wait_for(g,func():return g.coop.members.values().any(func(m):return m.get("disconnected",false)))
		# A chest opened on this island while the guest is away, then the host moves on:
		# the guest must still get it after rejoining on the next island.
		free_chest.call()
		g.enter_realm(1)
		checks.drop2_rejoined=await wait_for(g,func():return g.coop.test_messages.has("reconnected"),42)
		var away_restored=g.coop.members.values().filter(func(member):return str(member.get("token",""))==away_token and not member.get("disconnected",false))
		# The returning guest may already be choosing the chest replayed from island 1.
		checks.drop2_state=away_restored.size()==1 and away_restored[0].get("mode","") in ["playing","offer"]
		checks.drop2_client=await wait_for(g,func():return g.coop.test_messages.has("drop2_done"),15) and g.coop.test_messages.drop2_done.values().all(func(v):return v)
		trace.append({"phase":"rejoin","drop1":g.coop.test_messages.get("drop1_done",{}),"drop2":g.coop.test_messages.get("drop2_done",{})})
		g.enter_realm(3)
		checks.baron_intro_peer=await wait_for(g,func():return g.coop.test_messages.has("baron_intro_seen"))
		var final_bosses=g.enemies.filter(func(e):return e.get("boss_id",-1)==8)
		if not final_bosses.is_empty():
			preload("res://scripts/final_arena.gd").phase_changed(g,final_bosses[0],1)
			var target_id=int(g.coop.members.keys()[0]);var target_name=g.coop.player_name_for(target_id)
			g.coop.set_boss_focus(target_id,target_name);g.coop.broadcast({"type":"boss_focus","realm":g.realm,"player_id":target_id,"name":target_name})
			checks.baron_target_remote=await wait_for(g,func():return g.coop.avatars.has(target_id) and g.coop.avatars[target_id].get_meta("nameplate").text.contains("TARGET"))
			checks.baron_phase_peer=await wait_for(g,func():return g.coop.test_messages.has("baron_phase_seen"))
			checks.baron_focus_peer=await wait_for(g,func():return g.coop.test_messages.has("baron_focus_seen"))
		checks.remote_baron=await wait_for(g,func():return g.coop.test_messages.has("baron_seen"))
		checks.remote_baron_model=g.coop.test_messages.get("baron_seen",{}).get("model",false)
		var reconnect_id=int(g.coop.members.keys()[0]);var reconnect_token=str(g.coop.members[reconnect_id].get("token",""))
		# A silent drop: the guest's connection dies without notice and it rejoins
		# while this side still sees the old connection. It must take back its own
		# slot, not join as a second copy of itself (October 23 user report).
		g.coop.test_messages.erase("reconnected");send(g,"reconnect_force",{"silent":true})
		checks.reconnect_host=await wait_for(g,func():return g.coop.test_messages.has("reconnected"),42)
		var restored=g.coop.members.values().filter(func(member):return str(member.get("token",""))==reconnect_token and not member.get("disconnected",false))
		checks.reconnect_state=not reconnect_token.is_empty() and restored.size()==1 and restored[0].get("mode","")=="playing"
		checks.reconnect_no_duplicate=g.coop.members.size()==1 and g.coop.avatars.size()<=1
		trace.append({"phase":"duplicate_probe","members":g.coop.members.keys().map(func(k):return [k,str(g.coop.members[k].get("token","")).left(6),g.coop.members[k].get("disconnected",false),g.coop.members[k].get("mode","")]),"avatars":g.coop.avatars.keys()})
		trace.append({"phase":"reconnect","host_mode":g.mode,"restored":restored.map(func(m):return {"mode":m.get("mode",""),"hp":m.get("hp",-1)})})
		send(g,"reconnect_host_confirm",{"restored":checks.reconnect_state})
		send(g,"finish",checks)
		await wait_for(g,func():return g.coop.test_messages.has("finished"))
	else:
		g.player.position=Vector3(20,g.world.height_at(20,0),0);send(g,"ready")
		for cycle in range(3):
			var phase="pause_probe_"+str(cycle);var resume_phase="pause_resumed_"+str(cycle)
			checks[phase]=await wait_for(g,func():return g.coop.paused and g.mode=="playing")
			var nearby=g.chests.filter(func(c):return not c.opened).front();g.player.position=nearby.node.position
			var dash=InputEventAction.new();dash.action="dash";dash.pressed=true;dash.strength=1;g._input(dash)
			var interact=InputEventAction.new();interact.action="interact";interact.pressed=true;interact.strength=1;g._input(interact)
			var enemies=g.enemies.filter(func(e):return not e.dead).map(func(e):return {"id":e.net_id,"hp":e.hp,"position":CoopSession.array(e.node.position)}).slice(0,8)
			var pause_probe={"dash_started":g.dash_time>0,"chest_pending":g.pending_chest,"mode":g.mode,"realm":g.realm,"level":g.level,"xp":g.xp,"xp_target":g.xp_target,"elapsed":g.elapsed,"position":CoopSession.array(g.player.position),"paused":g.coop.paused,"offer_source":g.offer_source,"offers":g.offers.map(func(o):return o.id),"enemies":enemies,"max_fps":Engine.max_fps,"physics_hz":Engine.physics_ticks_per_second}
			send(g,phase,pause_probe);g.pending_chest=false
			checks[resume_phase]=await wait_for(g,func():return not g.coop.paused and g.mode=="playing")
			send(g,resume_phase)
			trace.append({"phase":phase,"client":pause_probe})
		checks.crowd_instruction=await wait_for(g,func():return g.coop.test_messages.has("crowd"))
		var crowd_ids=g.coop.test_messages.get("crowd",{}).get("ids",[]).map(func(id):return int(id))
		var crowd_start=g.coop.snapshots_received
		var count_crowd=func():return g.enemies.filter(func(e):return not e.dead and int(e.net_id) in crowd_ids).size()
		await wait_for(g,func():return count_crowd.call()==crowd_ids.size(),6)
		await g.get_tree().create_timer(2).timeout
		var crowd_seen={"visible":count_crowd.call(),"snapshots":g.coop.snapshots_received-crowd_start,"connected":g.coop.active and not g.coop.reconnecting}
		send(g,"crowd_seen",crowd_seen)
		checks.crowd_visible=crowd_seen.visible==crowd_ids.size() and crowd_seen.snapshots>=10
		trace.append({"phase":"crowd","client":crowd_seen})
		checks.level_offer=await wait_for(g,func():return g.mode=="offer" and g.offer_source=="level")
		var before=g.pickups.size();g.spawn_pickup(g.player.position,"xp",999)
		checks.no_private_xp=g.pickups.size()==before
		var option_state=g.party_seen.get(str(g.coop.local_id),{})
		send(g,"level",{"level":g.level,"xp":g.xp,"xp_gain":g.stat("xpGain"),"pool":g.offers.map(func(o):return o.id),"no_private_xp":checks.no_private_xp,"options":option_state.get("options",[]),"reward_id":option_state.get("reward_id","")})
		choose(g)
		checks.host_choice_highlight=await wait_for(g,func():return str(g.party_seen.get(str(g.coop.owner_id),{}).get("selected_id",""))!="")
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
		option_state=g.party_seen.get(str(g.coop.local_id),{})
		send(g,"chest_done",{"gold":g.gold,"paid":g.paid_chests,"pool":g.offers.map(func(o):return o.id),"hidden":chest.opened and not chest.node.visible,"options":option_state.get("options",[]),"reward_id":option_state.get("reward_id","")})
		choose(g)
		checks.host_chest_choice_highlight=await wait_for(g,func():return str(g.party_seen.get(str(g.coop.owner_id),{}).get("selected_id",""))!="")
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
		# Drop 1: disconnect mid-reward; the choice must survive the rejoin.
		checks.pre_drop_offer=await wait_for(g,func():return g.mode=="offer" and g.offer_source=="chest")
		g.coop.test_messages.erase("reconnected");send(g,"pre_drop_offer")
		var drop1={}
		drop1.rejoined=await wait_for(g,func():return g.coop.test_messages.has("reconnected"),42)
		drop1.offer_kept=g.mode=="offer" and g.hud.modal.visible and not g.offers.is_empty()
		var kept_reward=g.party_reward_id
		choose(g)
		# The chest the host opened while this guest was away follows once the kept
		# choice is made (it used to be lost), and is offered only once.
		drop1.away_offer=await wait_for(g,func():return g.mode=="offer" and g.offer_source=="chest" and g.party_reward_id!=kept_reward,6)
		var away_reward=g.party_reward_id
		choose(g)
		drop1.away_offer_once=g.party_reward_id==away_reward and g.coop.queued_offers.is_empty()
		drop1.offer_chosen=await wait_for(g,func():return g.mode=="playing",4)
		await g.get_tree().create_timer(.5).timeout
		drop1.away_offer_once=drop1.away_offer_once and g.mode=="playing"
		drop1.nameplate=is_instance_valid(g.coop.local_nameplate) and g.coop.local_nameplate.is_inside_tree()
		var away_instruction=await wait_for(g,func():return g.coop.test_messages.has("away_chest"))
		var away=CoopSession.vector(g.coop.test_messages.get("away_chest",{}).get("position",[]))
		drop1.away_chest_hidden=away_instruction and await wait_for(g,func():return g.chests.any(func(c):return c.node.position.distance_to(away)<.1 and c.opened and not c.node.visible),4)
		checks.drop1=drop1.values().all(func(v):return v)
		g.coop.test_messages.erase("reconnected");send(g,"drop1_done",drop1)
		# Drop 2: the host changes realm while this guest is away.
		var drop2={}
		drop2.rejoined=await wait_for(g,func():return g.coop.test_messages.has("reconnected"),42)
		var rejoin_start=g.coop.snapshots_received
		drop2.realm=await wait_for(g,func():return g.realm==1,6)
		# The host may still be streaming the new realm; require snapshots to resume.
		drop2.snapshots=await wait_for(g,func():return g.coop.snapshots_received-rejoin_start>=5,5)
		drop2.earlier_island_chest=await wait_for(g,func():return g.mode=="offer" and g.offer_source=="chest",8)
		choose(g)
		drop2.mode=await wait_for(g,func():return g.mode=="playing",4)
		trace.append({"phase":"rejoin_client","snapshots":g.coop.snapshots_received-rejoin_start,"last_seq":g.coop.last_snapshot_seq,"realm":g.realm,"run_active":g.run_active,"since_snapshot":Time.get_ticks_msec()/1000.0-g.coop.last_snapshot})
		checks.drop2=drop2.values().all(func(v):return v)
		send(g,"drop2_done",drop2)
		checks.final_realm=await wait_for(g,func():return g.realm==3 and g.enemies.any(func(e):return e.get("boss_id",-1)==8))
		var bosses=g.enemies.filter(func(e):return e.get("boss_id",-1)==8)
		checks.baron_model=not bosses.is_empty() and bosses[0].node.get_meta("rig").solid.identity=="boss_8_baron" and bosses[0].node.get_meta("rig").find_children("BaronSteam*","GPUParticles3D",true,false).size()==4
		var intro_line=g.coop.test_messages.get("boss_phase_0",{})
		checks.baron_intro_voice=intro_line.get("name","")=="THE ARRIVAL" and intro_line.get("index",-1)==10
		if checks.baron_intro_voice:send(g,"baron_intro_seen")
		if not bosses.is_empty():
			checks.baron_phase_peer=await wait_for(g,func():return g.sound.boss_voice.stream!=null and g.sound.boss_voice.stream.get_length()>0)
			if checks.baron_phase_peer:send(g,"baron_phase_seen")
			checks.baron_focus_peer=await wait_for(g,func():return g.events.get("boss_focus_id",0)==g.coop.local_id and is_instance_valid(g.coop.local_nameplate) and g.coop.local_nameplate.text.contains("TARGET"))
			if checks.baron_focus_peer:send(g,"baron_focus_seen")
		send(g,"baron_seen",{"model":checks.baron_model})
		checks.reconnect=await wait_for(g,func():return g.coop.test_messages.has("reconnect_host_confirm"),42)
		checks.reconnect_mode=g.coop.active and g.coop.welcomed and not g.coop.reconnecting and g.mode=="playing"
		g.update.ping_clock=0;g.update.send_ping()
		checks.ping_achievement=float(g.career.data.total.get("coop_pings",0))>=1
		checks.host_finished=await wait_for(g,func():return g.coop.test_messages.has("finish"))
		checks.host_checks=g.coop.test_messages.get("finish",{}).values().all(func(v):return v)
		send(g,"finished");await g.get_tree().create_timer(.3).timeout
	print("SHARED_REVIEW "+JSON.stringify({"role":"host" if host else "client","checks":checks,"trace":trace}))
	g.set_process(false);g.coop.leave();g.mode="test_finished";g.clear_entities();g.sound.active=false;g.sound.shutdown()
	await g.get_tree().create_timer(.25).timeout
	g.get_tree().quit(0 if checks.values().all(func(v):return v) else 1)

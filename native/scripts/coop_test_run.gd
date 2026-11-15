extends RefCounted

# The two-process co-op test (--coop-host-test / --coop-client-test): a host and
# a guest play a shared run and each reports what it saw as COOP_TEST {json}.
# Moved out of game.gd; `g` is the game.
static func run(g):
	g.coop.test_mode=true
	var discovered_party=false
	if g.network_test_role=="host": g.coop.host_lan()
	else:
		g.hud.coop_menu()
		var discovery_deadline=Time.get_ticks_msec()+6000
		while Time.get_ticks_msec()<discovery_deadline:
			if g.coop.discovered.has("127.0.0.1"): discovered_party=true;break
			await g.get_tree().create_timer(.1).timeout
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			g.get_viewport().get_texture().get_image().save_png("user://standalone-coop-menu.png")
		g.coop.join_lan("127.0.0.1")
	var deadline=Time.get_ticks_msec()+14000
	var lobby_blocked=not g.coop.can_start();var hero_reset=false;var lobby_synced=false;var ready_sent=false
	while Time.get_ticks_msec()<deadline:
		if g.network_test_role=="client" and g.coop.welcomed and not ready_sent:
			g.coop.set_ready(true)
			g.select_hero(g.rules.data.heroes[2])
			hero_reset=not g.coop.local_ready
			g.coop.set_ready(true);ready_sent=true
		if g.network_test_role=="client":
			# The lobby roster carries hero display names (CoopSession.publish_lobby).
			lobby_synced=lobby_synced or g.coop.lobby_roster.any(func(m):return m.id==g.coop.local_id and m.hero==g.hero.name and m.ready)
		if g.network_test_role=="host" and not g.coop.members.is_empty():
			g.coop.set_ready(true)
			if g.coop.can_start():
				lobby_synced=g.coop.members.values().any(func(m):return m.get("hero","")==g.rules.data.heroes[2].id and m.get("ready",false))
				hero_reset=true
				await g.get_tree().create_timer(.5).timeout
				g.coop.start_party(91731);break
		if g.network_test_role=="client" and g.run_active: break
		await g.get_tree().create_timer(.1).timeout
	if not g.run_active: print("COOP_TEST failure: connection/start");g.get_tree().quit(1);return
	g.hp=10000;g.stats.maxHp=10000;g.stats.regen=0
	if g.network_test_role=="client":
		var variant=g.rules.data.weapons.filter(func(w):return w.id=="venom-candle")[0].duplicate(true)
		variant.kind="weapon";variant.strength=1;variant.tier=0;g.equip_weapon(variant)
		g.stats["augment-healthy-damage"]=.25
		g.stats.enemyPull=2;g.stats.enemyPush=3
	var garden_weapon=g.rules.data.weapons.filter(func(w):return w.id=="flowers")[0].duplicate(true)
	garden_weapon.kind="weapon";garden_weapon.strength=1;garden_weapon.tier=0;g.equip_weapon(garden_weapon)
	g.plant_flower(g.player.position,garden_weapon)
	if g.network_test_role=="host": g.stats.damage=2
	var started=Time.get_ticks_msec();var pause_done=false;var realm_done=false;var moved=false;var shared_enemies=false;var maximum_avatars=0
	var down_sent=false;var saw_down=false;var saw_rescue=false;var saw_ping=false;var purchase_sent=false;var supply_sent=false;var saw_purchase=false;var saw_supply=false;var gold_before=0
	var down_sent2=false;var rescued2=false;var pause_done2=false;var down_done=false
	var realm_cycle_done=false;var realm_cycle_done2=false;var final_test_done=false;var final_reset=false;var saw_final=false;var saw_final_eclipse=false
	var saw_remote_flowers=false;var saw_own_numbers=false;var saw_boss_identity=false;var saw_remote_vitals=false
	var hunt_retry=0.0;var down_retry=0.0
	var hunt_active_since=-1.0
	var hunt_sent=false;var hunt_seen=false;var hunt_reward=false;var guardian_sent=false;var guardian_seen=false
	while Time.get_ticks_msec()-started<(360000 if g.network_test_role=="host" else 360000):
		var seconds=(Time.get_ticks_msec()-started)/1000.0
		saw_final=saw_final or g.realm==RealmWorld.ARENA and g.enemies.any(func(e):return e.get("boss_id",-1)==8 and e.maxHp>90000)
		saw_final_eclipse=saw_final_eclipse or g.realm==RealmWorld.ARENA and g.events.get("final_defeated",false) and g.events.get("eclipse",false)
		saw_boss_identity=saw_boss_identity or g.enemies.any(func(e):return e.boss and e.get("boss_id",-1)>=0 and e.node.get_meta("rig").identity=="boss_"+str(e.boss_id))
		for id in g.coop.avatars:
			var member=g.coop.members.get(id,{})
			var maximum=float(member.get("vitals",{}).get("max_hp",member.get("stats",{}).get("maxHp",0)))
			if maximum>0:
				saw_remote_vitals=saw_remote_vitals or is_equal_approx(g.coop.avatars[id].get_meta("rig").solid.fill,clampf(float(member.get("hp",0))/maximum,0,1))
		saw_remote_flowers=saw_remote_flowers or not g.coop.flower_visuals.is_empty()
		saw_own_numbers=saw_own_numbers or not g.damage_numbers.is_empty()
		shared_enemies=shared_enemies or g.enemies.size()>0
		maximum_avatars=maxi(maximum_avatars,g.coop.avatars.size())
		moved=moved or g.player.position.x>2
		saw_down=saw_down or g.update.downed or not g.update.downed_ids.is_empty()
		saw_rescue=saw_rescue or saw_down and not g.update.downed and g.update.downed_ids.is_empty()
		saw_ping=saw_ping or not g.update.pings.is_empty()
		saw_purchase=saw_purchase or g.update.memories.has("MERCHANT") or not g.update.purchased.is_empty()
		saw_supply=saw_supply or g.update.beacon_state=="complete" or g.update.memories.has("BEACON")
		hunt_seen=hunt_seen or g.Hunt.state(g)=="active"
		hunt_reward=hunt_reward or (g.Hunt.shrine(g)!=null and g.Hunt.shrine(g).has_meta("reward_spawned"))
		guardian_seen=guardian_seen or g.events.get("guardian_defeated",false)
		if seconds>11: g.xp_target=1000000
		# Retried each second until the hunt starts (frame timing varies with the map).
		if g.network_test_role=="client" and seconds>12 and seconds<24 and g.realm==1 and g.Hunt.state(g)=="idle" and seconds>=hunt_retry:
			hunt_sent=true;hunt_retry=seconds+1.0;g.player.position=g.Hunt.shrine(g).position;g.Hunt.interact(g)
		# The marked foes fall a second after the hunt began, not in the same tick: the
		# guest has to see the hunt active in a snapshot first. A hunt the guest started
		# after 13.5 s was over within one 0.1 s step, and the guest often never saw it.
		if g.network_test_role=="host" and g.Hunt.state(g)=="active" and hunt_active_since<0: hunt_active_since=seconds
		if g.network_test_role=="host" and seconds>13.5 and g.Hunt.state(g)=="active" and seconds-hunt_active_since>=1.0:
			for target in g.enemies.filter(func(e):return e.net_id in g.events.hunt_ids and not e.dead): g.kill_enemy(target,"diagnostic")
		if g.network_test_role=="host" and seconds>15 and not guardian_sent:
			guardian_sent=true;g.realm_bosses=2;g.Journey.activate(g)
		if g.network_test_role=="host" and seconds>16 and seconds<18:
			for target in g.enemies.filter(func(e):return e.get("guardian",false) and not e.dead): g.kill_enemy(target,"diagnostic")
		# Extended 6-minute test: realm cycling with frame-budgeted chunk building
		if g.network_test_role=="host":
			# Cycle realms every 2 minutes to test realm transitions
			if seconds>120 and not realm_cycle_done:
				realm_cycle_done=true
				var old_r=g.realm
				g.realm=RealmWorld.ARENA-1
				print("REALM_CYCLE: "+str(old_r)+" -> "+str(g.realm))
				g.enter_realm(g.realm)
				g.realm_time=0
			if seconds>240 and not realm_cycle_done2:
				realm_cycle_done2=true;g.realm_bosses=2;g.Journey.activate(g)
				for target in g.enemies.filter(func(e):return e.get("guardian",false) and not e.dead): g.kill_enemy(target,"diagnostic")
				g.Journey.activate(g)
			if seconds>300 and not final_test_done:
				final_test_done=true
				for target in g.enemies.filter(func(e):return e.get("boss_id",-1)==8 and not e.dead): g.kill_enemy(target,"diagnostic")
			if seconds>330 and not final_reset:
				final_reset=true;g.enter_realm(0)
			# Periodic merchant visits
			if seconds>30 and seconds<300 and g.update.merchant and g.mode!="merchant" and Time.get_ticks_msec()%30000<100:
				g.player.position=g.update.merchant.position;g.gold=1000;g.update.merchant_menu()
			# Periodic down/rescue cycles
			if seconds>30 and Time.get_ticks_msec()%60000<100 and not down_sent2:
				down_sent2=true;g.player.position=Vector3(2,0.1,0);g.invulnerable=1000
				g.coop.send_to(g.coop.members.keys()[0],{"type":"damage","amount":100000,"position":[0,0,0],"sound":"hit"})
			if seconds>30 and Time.get_ticks_msec()%60000>1000 and Time.get_ticks_msec()%60000<2000 and g.update.downed and not rescued2:
				rescued2=true;g.hp=5000;g.update.downed=false;g.update.downed_ids.clear()
			if seconds>30 and Time.get_ticks_msec()%60000>2000 and Time.get_ticks_msec()%60000<3000 and not pause_done2:
				pause_done2=true;g.mode="paused";await g.get_tree().create_timer(0.5).timeout;g.mode="playing"
		if g.network_test_role=="host":
			if seconds>2 and not down_sent and not g.coop.members.is_empty():
				down_sent=true;g.player.position=Vector3(2,.1,0);g.invulnerable=1000
				# First hit: one-hit protection caps at 85% maxHP; second hit will be lethal after .55s invuln
				g.coop.send_to(g.coop.members.keys()[0],{"type":"damage","amount":100000,"position":[2,.1,0],"sound":"hit"})
			if seconds>2.6 and seconds<6.0 and not g.coop.members.is_empty() and not g.update.downed_ids.has(g.coop.members.keys()[0]) and seconds>=down_retry:
				# Follow-up hits every 0.7 s until the client is down (each lands
				# once its 0.55 s invulnerability is over, whatever the frame timing).
				down_done=true;down_retry=seconds+.7;g.player.position=Vector3(2,.1,0)
				g.coop.send_to(g.coop.members.keys()[0],{"type":"damage","amount":100000,"position":[2,.1,0],"sound":"hit"})
			if seconds>2.6 and seconds<6.7 and down_sent: Input.action_press("interact")
			else: Input.action_release("interact")
			if seconds>9 and not supply_sent:
				supply_sent=true;g.player.position=g.update.beacon_position;g.update.activate_beacon();g.update.beacon_seconds=24.8
			if seconds>9.5 and g.mode=="offer": g.choose_offer(0)
			if seconds>6.5 and not pause_done: pause_done=true;g.level_up()
			if seconds>7.5 and g.mode=="offer": g.choose_offer(0)
			if seconds>11 and not realm_done: realm_done=true;g.enter_realm(1);g.realm_time=75
		else:
			if seconds>1.5 and seconds<2.3: g.invulnerable=0;g.stats.dodge=0
			if seconds>1 and not down_sent: down_sent=true;g.update.send_ping()
			if seconds>8 and not purchase_sent:
				g.player.position=g.update.merchant.position;g.gold=500;gold_before=g.gold
				if seconds>8.3: purchase_sent=true;g.update.merchant_menu();g.update.purchase(1)
			if g.mode=="merchant" and g.update.pending_purchase<0 and seconds>8.6: g.hud.close()
			if g.mode=="offer": g.choose_offer(0)
		if DisplayServer.get_name()!="headless" and seconds>5 and seconds<5.2:
			await RenderingServer.frame_post_draw
			g.get_viewport().get_texture().get_image().save_png("user://coop-"+g.network_test_role+".png")
		await g.get_tree().create_timer(.1).timeout
	# Both peers record their final state while the transport is still connected.
	if g.coop.hosting: g.coop.broadcast({"type":"test_done","realm":g.realm})
	else: g.coop.send_to(g.coop.owner_id,{"type":"test_done","realm":g.realm})
	var finish_deadline=Time.get_ticks_msec()+8000
	while g.coop.test_finished_peers.is_empty() and Time.get_ticks_msec()<finish_deadline:
		await g.get_tree().create_timer(.1).timeout
	var checks={"final_boss":saw_final,"final_eclipse":saw_final_eclipse,"realm_trace":g.network_test_realms,"all_realm_transitions":g.network_test_realms==[0,1,RealmWorld.ARENA-1,RealmWorld.ARENA,0],"finish_handshake":not g.coop.test_finished_peers.is_empty() and g.coop.test_finished_peers.values().all(func(r):return r==g.realm),"boss_identity":saw_boss_identity,"remote_vitals":saw_remote_vitals,"remote_flowers":saw_remote_flowers,"own_damage_numbers":saw_own_numbers,"force_pulses":g.coop.force_requests_received>0 if g.network_test_role=="host" else g.coop.saw_force_pulse,"lobby_blocked":lobby_blocked,"hero_change_clears_ready":hero_reset,"lobby_hero_ready_synced":lobby_synced,"role":g.network_test_role,"standalone":not Engine.has_singleton("Steam"),"discovery":discovered_party if g.network_test_role=="client" else true,"connected":g.coop.active,"avatars":maximum_avatars,"members":g.coop.members.size(),"same_enemies":shared_enemies,"remote_hits":g.coop.remote_hits,"kills_received":g.coop.kills_received,"snapshots":g.coop.snapshots_received,"moved":moved,"party_pause":g.coop.saw_pause if g.network_test_role=="client" else true,"realm":g.realm,"realm_received":g.coop.saw_realm,"downed":saw_down,"rescued":saw_rescue,"ping":saw_ping,"merchant":saw_purchase,"supply":saw_supply,"hunt_started":hunt_seen,"hunt_reward":hunt_reward,"guardian_defeated":guardian_seen}
	var passed=checks.final_boss and checks.final_eclipse and checks.all_realm_transitions and checks.finish_handshake and checks.boss_identity and checks.remote_vitals and checks.remote_flowers and checks.own_damage_numbers and checks.force_pulses and lobby_blocked and hero_reset and lobby_synced and checks.hunt_started and checks.hunt_reward and checks.guardian_defeated and checks.downed and checks.rescued and checks.ping and checks.merchant and checks.supply and checks.standalone and checks.discovery and checks.connected and checks.avatars>0 and shared_enemies and g.realm==0 and (g.coop.remote_hits>0 if g.network_test_role=="host" else g.coop.snapshots_received>20 and g.coop.saw_pause and g.coop.saw_realm and moved)
	print("COOP_TEST "+JSON.stringify(checks));var report=FileAccess.open("user://coop-"+g.network_test_role+"-results.json",FileAccess.WRITE);report.store_string(JSON.stringify(checks,"  "));report.close()
	await g.get_tree().create_timer(.75).timeout
	g.coop.leave()
	g.mode="test_finished";g.clear_entities();g.sound.active=false
	for channel in g.sound.get_children():
		if channel is AudioStreamPlayer or channel is AudioStreamPlayer3D: channel.stop();channel.stream=null
	await g.get_tree().create_timer(.25).timeout
	g.get_tree().quit(0 if passed else 1)

extends RefCounted
static func capture(g,name: String) -> bool:
	g.hud.update(0)
	for i in range(5): await g.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return g.get_viewport().get_texture().get_image().save_png("user://hunt-"+name+".png")==OK
static func run(g):
	if DisplayServer.get_name()=="headless": g.get_tree().quit(1);return
	seed(407);AudioServer.set_bus_volume_db(0,-80);g.start_run(407);g.set_physics_process(false);g.set_process(false)
	var checks={};var shrine=g.Hunt.shrine(g);g.player.position=shrine.position+Vector3(0,0,2)
	checks.early_locked=not g.Hunt.activate(g,g.player.position)
	g.realm_time=75
	checks.remote_blocked=not g.Hunt.activate(g,Vector3.ZERO)
	var gold=g.gold;var chests=g.chests.size()
	checks.started=g.Hunt.activate(g,g.player.position) and g.events.hunt_ids.size()==3 and g.gold==gold
	checks.no_duplicate=not g.Hunt.activate(g,g.player.position)
	g.Hunt.tick(g)
	checks.marked=g.enemies.filter(func(e):return e.net_id in g.events.hunt_ids).all(func(e):return e.node.has_node("HuntMark"))
	g.camera.position=shrine.position+Vector3(9,10,18);g.camera.look_at(shrine.position+Vector3.UP)
	checks.captures=await capture(g,"active")
	# Hunt music: plays during the hunt and speeds up through the last 20 seconds.
	var deadline=float(g.events.hunt_deadline)
	g.realm_time=deadline-30;g.Hunt.tick(g);var calm=g.sound.hunt_player.pitch_scale
	g.realm_time=deadline-10;g.Hunt.tick(g)
	checks.hunt_music=g.sound.hunt_active and is_equal_approx(calm,1.0) and is_equal_approx(g.sound.hunt_player.pitch_scale,1.15)
	g.realm_time=121;g.Hunt.tick(g)
	checks.timeout=g.Hunt.state(g)=="failed" and g.chests.size()==chests
	checks.failure_card=str(g.events.get("announcement",""))=="HUNT FAILED" and not g.sound.hunt_active
	g.enter_realm(0);g.set_physics_process(false);g.set_process(false);shrine=g.Hunt.shrine(g)
	checks.realm_reset=g.Hunt.state(g)=="idle" and not shrine.has_meta("reward_spawned")
	g.realm_time=75;g.player.position=shrine.position+Vector3(0,0,2)
	checks.restart=g.Hunt.activate(g,g.player.position)
	var targets=g.enemies.filter(func(e):return e.net_id in g.events.hunt_ids)
	chests=g.chests.size()
	for enemy in targets: g.kill_enemy(enemy,"diagnostic")
	g.Hunt.tick(g);g.Hunt.tick(g)
	checks.single_reward=g.Hunt.state(g)=="complete" and g.chests.size()==chests+1 and g.chests[-1].free and g.chests[-1].elite
	checks.success_card=str(g.events.get("announcement",""))=="HUNT COMPLETE"
	checks.event_beacon=g.chests[-1].get("event",false) and g.chests[-1].has("beacon")
	g.camera.position=shrine.position+Vector3(9,10,18);g.camera.look_at(shrine.position+Vector3.UP)
	checks.captures=await capture(g,"complete") and checks.captures
	# Event chests roll rare-or-better cards and always carry a mutation.
	g.buy_chest(g.chests[-1]);checks.rare_offers=g.offers.size()==5 and g.offers.all(func(o):return o.tier>=1) and g.offers.filter(func(o):return o.kind!="mutation").all(func(o):return o.tier>=EventLoot.MIN_TIER) and g.offers.any(func(o):return o.kind=="mutation")
	print("HUNT_REVIEW "+JSON.stringify(checks));g.get_tree().quit(0 if checks.values().all(func(v):return v) else 1)

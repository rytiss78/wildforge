extends RefCounted
static func capture(game,name):
	game.hud.update(0)
	for i in range(5): await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return game.get_viewport().get_texture().get_image().save_png("user://journey-"+name+".png")==OK
static func run(game):
	AudioServer.set_bus_volume_db(0,-80);seed(407);game.start_run(407);game.set_physics_process(false);game.camera_locked=true
	game.player.position=game.gate_position+Vector3(0,0,14);game.camera.position=game.gate_position+Vector3(12,11,24);game.camera.look_at(game.gate_position+Vector3.UP*4)
	var checks={}
	checks.captures=await capture(game,"portal")
	checks.sealed=game.Journey.state(game)=="sealed"
	var coast=game.world.shore_radius(Vector3.RIGHT)
	checks.irregular_coast=absf(coast-game.world.shore_radius(Vector3.FORWARD))>5
	checks.chests_inland=game.chests.all(func(c):return not game.world.dangerous(c.node.position))
	game.player.position=Vector3(coast-12,game.world.height_at(coast-12,0),0)
	game.camera.position=game.player.position+Vector3(-12,10,14);game.camera.look_at(Vector3(coast+14,0,0))
	checks.captures=await capture(game,"coast") and checks.captures
	game.player.position=game.gate_position+Vector3(0,0,14)
	game.Journey.activate(game);checks.seal_blocks=not game.events.get("guardian_summoned",false)
	game.realm_time=600;game.update_events()
	checks.eclipse=game.events.get("eclipse",false) and game.Journey.state(game)=="ready" and game.events.eclipse_stage==1
	game.realm_time=630;game.Journey.tick(game);checks.escalation=game.events.eclipse_stage==2
	game.Journey.activate(game)
	var guardians=game.enemies.filter(func(e):return e.get("guardian",false) and not e.dead)
	checks.guardian=guardians.size()==1 and game.Journey.state(game)=="fighting"
	var count=game.enemies.size();game.Journey.activate(game);checks.no_duplicate=game.enemies.size()==count
	var guardian=guardians[0]
	checks.near_portal=guardian.node.position.distance_to(game.gate_position)<38
	game.world.eclipse=true;game.world.weather_tick(8,game.player.position)
	game.camera.position=guardian.node.position+Vector3(14,13,25);game.camera.look_at(guardian.node.position+Vector3.UP*4)
	checks.captures=await capture(game,"boss") and checks.captures
	game.kill_enemy(guardian,"diagnostic");checks.guardian_unlocks=game.Journey.state(game)=="cleared"
	game.Journey.activate(game);checks.travel=game.realm==1 and game.Journey.state(game)=="sealed"
	game.enter_realm(2);game.events.guardian_defeated=true;game.Journey.activate(game);checks.final_victory=game.mode=="ended"
	print("JOURNEY_REVIEW "+JSON.stringify(checks));game.get_tree().quit(0 if checks.values().all(func(v):return v) else 1)

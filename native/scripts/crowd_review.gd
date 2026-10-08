extends RefCounted

static func run(game):
	seed(81173);AudioServer.set_bus_volume_db(0,-80)
	game.start_run(81173);game.invulnerable=10000;game.spawn_clock=100000
	game.xp_target=100000;game.camera_locked=true
	game.camera.position=Vector3(0,18,26);game.camera.look_at(Vector3.ZERO)
	for weapon in game.equipped: weapon.clock=100000
	for i in range(180): game.spawn_enemy(16+i%16)
	var eclipse=OS.get_cmdline_user_args().has("--eclipse-crowd")
	if eclipse:
		for enemy in game.enemies: EclipseCorruption.apply(enemy,6)
	var count=game.enemies.size()
	var frames=[];var physics=[];var start=Time.get_ticks_msec();var previous=Time.get_ticks_usec()
	while Time.get_ticks_msec()-start<12000:
		await game.get_tree().process_frame
		var now=Time.get_ticks_usec()
		if Time.get_ticks_msec()-start>4000:
			frames.append((now-previous)/1000.0)
			physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
		else: game.combat_profile.clear()
		previous=now
	frames.sort();physics.sort();game.combat_profile.sort()
	await RenderingServer.frame_post_draw
	var saved=game.get_viewport().get_texture().get_image().save_png("user://crowd-review.png")==OK
	var result={"seed":81173,"eclipse":eclipse,"spawned":count,"remaining":game.enemies.size(),"samples":frames.size(),"frame_p50_ms":frames[frames.size()/2],"frame_p95_ms":frames[int(frames.size()*.95)],"physics_p95_ms":physics[int(physics.size()*.95)],"combat_p95_ms":game.combat_profile[int(game.combat_profile.size()*.95)],"capture_saved":saved}
	print("CROWD_REVIEW "+JSON.stringify(result));game.get_tree().quit(0 if saved and count>=120 else 1)

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
	var surface_stress=OS.get_cmdline_user_args().has("--surface-crowd")
	if surface_stress:
		var wall=StaticBody3D.new();wall.collision_layer=1;game.add_child(wall);wall.position=Vector3(-1,26,0)
		var collision=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(2,54,90);collision.shape=box;wall.add_child(collision)
		var mesh=BoxMesh.new();mesh.size=box.size;game.shape(mesh,Color("b6b2a1"),wall)
		for i in range(game.enemies.size()):
			var enemy=game.enemies[i];enemy.flying=false
			EnemySurface.attach(enemy,{"position":Vector3(0,3+int(i/25)*4,(i%25-12)*3),"normal":Vector3.RIGHT},Vector3.UP)
		game.player.position=Vector3(8,30,0);game.camera.position=Vector3(40,34,40);game.camera.look_at(Vector3(0,18,0))
	var max_climbers=0
	var count=game.enemies.size()
	var frames=[];var physics=[];var start=Time.get_ticks_msec();var previous=Time.get_ticks_usec()
	while Time.get_ticks_msec()-start<12000:
		await game.get_tree().process_frame
		if surface_stress:
			game.player.position=Vector3(8,30,0);game.player.velocity=Vector3.ZERO
			max_climbers=maxi(max_climbers,game.enemies.filter(func(e):return e.get("surface_attached",false)).size())
		var now=Time.get_ticks_usec()
		if Time.get_ticks_msec()-start>4000:
			frames.append((now-previous)/1000.0)
			physics.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000)
		else: game.combat_profile.clear()
		previous=now
	frames.sort();physics.sort();game.combat_profile.sort()
	await RenderingServer.frame_post_draw
	var saved=game.get_viewport().get_texture().get_image().save_png("user://crowd-review.png")==OK
	var result={"seed":81173,"eclipse":eclipse,"surface_stress":surface_stress,"max_climbers":max_climbers,"spawned":count,"remaining":game.enemies.size(),"samples":frames.size(),"frame_p50_ms":frames[frames.size()/2],"frame_p95_ms":frames[int(frames.size()*.95)],"physics_p95_ms":physics[int(physics.size()*.95)],"combat_p95_ms":game.combat_profile[int(game.combat_profile.size()*.95)],"capture_saved":saved}
	print("CROWD_REVIEW "+JSON.stringify(result));game.get_tree().quit(0 if saved and count>=120 else 1)

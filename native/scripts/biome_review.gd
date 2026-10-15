extends RefCounted

static func run(g: Node3D):
	AudioServer.set_bus_volume_db(0,-80);g.start_run(407);g.invulnerable=10000;g.spawn_clock=99999
	for i in range(150): await g.get_tree().process_frame
	g.set_process(false);g.set_physics_process(false);g.clear_entities();g.hud.modal.visible=false
	var checks={"camera":g.camera_distance==12 and g.camera.fov==70 and is_equal_approx(g.pitch,.3),"biomes":true,"streaming":true,"captures":true}
	checks.natural_landmarks=range(6).all(func(i):return g.world.get_node("Landmark_"+str(i)).get_meta("natural_landmark",false))
	for biome in range(6):
		var p=g.world.landmarks[biome]+Vector3(0,0,14);p.y=g.world.height_at(p.x,p.z)+.1
		g.player.position=p;g.player.velocity=Vector3.ZERO;g.yaw=0;g.world.stream(p)
		for i in range(240):
			g.world.stream(p);g.world.weather_tick(.05,p);g._process(.016)
			await g.get_tree().process_frame
		checks.biomes=checks.biomes and g.world.biome_at(p)==biome
		checks.streaming=checks.streaming and g.world.chunks.size()>0
		checks["natural_scattering_"+str(biome)]=g.world.find_children("*","MultiMeshInstance3D",true,false).any(func(n):return n.multimesh!=null and NatureScenery.meshes.values().has(n.multimesh.mesh))
		g.current_biome=biome;g.hud.update(0)
		await RenderingServer.frame_post_draw
		checks.captures=g.get_viewport().get_texture().get_image().save_png("user://biome-"+str(biome)+".png")==OK and checks.captures
		g.damage_area(p+Vector3(2,0,-5),3,5,"explosion");g._process(.04)
		await RenderingServer.frame_post_draw
		checks.captures=g.get_viewport().get_texture().get_image().save_png("user://biome-fx-"+str(biome)+".png")==OK and checks.captures
	print("BIOME_REVIEW "+JSON.stringify({"checks":checks}));g.get_tree().quit(0 if not checks.values().has(false) else 1)

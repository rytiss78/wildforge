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
		checks["mist_"+str(biome)]=g.world.low_mist.all(func(n):return n.emitting==(biome in [1,3]) and n.amount==12)
		g.current_biome=biome;g.hud.update(0)
		await RenderingServer.frame_post_draw
		checks.captures=g.get_viewport().get_texture().get_image().save_png("user://biome-"+str(biome)+".png")==OK and checks.captures
		if biome in [1,3]:
			for mist in g.world.low_mist: mist.visible=false
			await g.get_tree().process_frame;await g.get_tree().process_frame;await RenderingServer.frame_post_draw
			checks.captures=g.get_viewport().get_texture().get_image().save_png("user://biome-no-mist-"+str(biome)+".png")==OK and checks.captures
			for mist in g.world.low_mist: mist.visible=true
		g.damage_area(p+Vector3(2,0,-5),3,5,"explosion");g._process(.04)
		await RenderingServer.frame_post_draw
		checks.captures=g.get_viewport().get_texture().get_image().save_png("user://biome-fx-"+str(biome)+".png")==OK and checks.captures
		# The biome's fight mechanic in front of the hero, with a few enemies in it,
		# captured while it is live (lava once it has spread, the gust mid-shove).
		var forward=-g.camera.global_basis.z;forward.y=0;forward=forward.normalized()
		var at=p+forward*7.0
		for i in range(4):
			g.spawn_enemy(6);var enemy=g.enemies[-1];var spot=at+forward.rotated(Vector3.UP,i*1.6)*2.0;spot.y=g.world.height_at(spot.x,spot.z)
			enemy.node.position=spot;enemy.speed=0.0;enemy.attack=1e9;enemy.contact=1e9;enemy.damage=0.0;enemy.hp=1e6;enemy.maxHp=1e6;enemy.behavior="chase";enemy.home=spot
		g.mode="playing";BiomeMechanics.spawn(g,{"type":"biome_event","realm":g.realm,"biome":biome,"pos":[at.x,at.z],"dir":[forward.cross(Vector3.UP).x,forward.cross(Vector3.UP).z]})
		var zone=g.biome_zones[-1];var wait=zone.warn+{0:1.5,1:1.5,2:1.2,3:.6,4:3.5,5:1.6}[biome]
		var t=0.0
		while t<wait:
			g.realm_time=0.0;g.update_combat(1.0/60.0);g._process(1.0/60.0);t+=1.0/60.0
			await g.get_tree().process_frame
		await RenderingServer.frame_post_draw
		checks["mechanic_"+str(biome)]=BiomeMechanics.live(zone) and g.get_viewport().get_texture().get_image().save_png("user://biome-mechanic-"+str(biome)+".png")==OK
		g.clear_entities()
	print("BIOME_REVIEW "+JSON.stringify({"checks":checks}));g.get_tree().quit(0 if not checks.values().has(false) else 1)

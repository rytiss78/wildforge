extends RefCounted

static func run(game):
	seed(81173);AudioServer.set_bus_volume_db(0,-80)
	game.start_run(81173);game.invulnerable=10000;game.spawn_clock=100000
	game.xp_target=100000;game.camera_locked=true
	game.camera.position=Vector3(0,18,26);game.camera.look_at(Vector3.ZERO)
	for weapon in game.equipped: weapon.clock=100000
	for i in range(180): game.spawn_enemy(16+i%16)
	# --spells-crowd: the same crowd under three rank-9 spells firing on their own
	# clocks, with half the crowd burning or poisoned. Enemies cannot die, so the
	# crowd size matches the plain run it is compared against.
	# --spells-only=a,b and --no-status narrow the run down when profiling.
	var spells=OS.get_cmdline_user_args().has("--spells-crowd")
	var kinds=["thunderstorm","blackhole","inferno"];var statuses=not OS.get_cmdline_user_args().has("--no-status")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--spells-only="): kinds=Array(arg.trim_prefix("--spells-only=").split(",",false))
	if spells:
		for weapon in game.equipped:
			if is_instance_valid(weapon.get("node")): weapon.node.queue_free()
		game.equipped.clear()
		for kind in kinds:
			var item=game.rules.data.weapons.filter(func(w):return w.id==kind)[0].duplicate(true);item.kind="weapon";item.strength=1.0
			for rank in range(9): game.equip_weapon(item)
		for i in range(game.enemies.size()):
			var enemy=game.enemies[i];enemy.hp=1e7;enemy.maxHp=1e7
			if statuses and i%2==0: enemy.fire=6.0
			if statuses and i%3==0: enemy.poison=6.0
			if statuses: enemy.status_time=1e6
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
	var viewport_rid=game.get_viewport().get_viewport_rid();RenderingServer.viewport_set_measure_render_time(viewport_rid,true)
	var process=[];var gpu=[];var render_cpu=[]
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
			process.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
			gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid));render_cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid))
		else: game.combat_profile.clear();game.crowd_sections.clear()
		previous=now
	frames.sort();physics.sort();process.sort();gpu.sort();render_cpu.sort()
	game.combat_profile.sort()
	await RenderingServer.frame_post_draw
	var saved=game.get_viewport().get_texture().get_image().save_png("user://crowd-review.png")==OK
	var result={"seed":81173,"spells":kinds if spells else [],"statuses":spells and statuses,"eclipse":eclipse,"surface_stress":surface_stress,"max_climbers":max_climbers,"spawned":count,"remaining":game.enemies.size(),"samples":frames.size(),"frame_p50_ms":frames[frames.size()/2],"frame_p95_ms":frames[int(frames.size()*.95)],"physics_p95_ms":physics[int(physics.size()*.95)],"physics_p50_ms":physics[physics.size()/2],"process_p50_ms":process[process.size()/2],"gpu_p50_ms":gpu[gpu.size()/2],"render_cpu_p50_ms":render_cpu[render_cpu.size()/2],"combat_p95_ms":game.combat_profile[int(game.combat_profile.size()*.95)],"capture_saved":saved}
	result.sections={}
	for key in game.crowd_sections:
		var values=game.crowd_sections[key];values.sort();result.sections[key]=values[int(values.size()*.95)]
	print("CROWD_REVIEW "+JSON.stringify(result));game.get_tree().quit(0 if saved and count>=120 else 1)

extends RefCounted

static func run(game):
	if DisplayServer.get_name()=="headless": game.get_tree().quit(1);return
	AudioServer.set_bus_volume_db(0,-80)
	game.start_run(407);game.set_physics_process(false);game.set_process(false)
	game.clear_entities();game.hud.modal.visible=false
	game.player.position=Vector3(0,game.world.height_at(0,0),0)
	game.camera.position=game.player.position+Vector3(0,9.5,8)
	game.camera.look_at(game.player.position+Vector3.UP)
	game.world.weather_tick(.016,game.player.position)
	game.hud.update(0)
	var okay=true
	for biome in [0,2]:
		var prop=MeshInstance3D.new();prop.mesh=load("res://assets/style3d/baked/prop_%d_0.res" % biome)
		prop.material_override=game.world.scenery_material;game.add_child(prop)
		prop.position=game.player.position+Vector3(0,0,2.5);prop.scale=Vector3.ONE*1.2
		for frame in range(5): await game.get_tree().process_frame
		await RenderingServer.frame_post_draw
		okay=game.get_viewport().get_texture().get_image().save_png("user://scenery-"+str(biome)+".png")==OK and okay
		prop.queue_free();await game.get_tree().process_frame
	print("SCENERY_REVIEW "+JSON.stringify({"captures_saved":okay}))
	game.get_tree().quit(0 if okay else 1)

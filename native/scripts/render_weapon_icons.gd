extends SceneTree

func _initialize(): call_deferred("render_icons")

func render_icons():
	var viewport=SubViewport.new();viewport.size=Vector2i(256,256);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_4X;root.add_child(viewport)
	var stage=Node3D.new();viewport.add_child(stage)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("f4e8cf");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("fff2d7");env.environment.ambient_light_energy=.55;stage.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-35,0);sun.light_energy=.8;stage.add_child(sun)
	var camera=Camera3D.new();stage.add_child(camera);camera.position=Vector3(.9,.6,-1.2);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=1.12;camera.look_at(Vector3(0,.1,-.12))
	DirAccess.make_dir_recursive_absolute("res://assets/illustrated/weapon-icons")
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	var count=0
	for entry in catalog.weapons:
		var id=str(entry.id)
		var weapon=WeaponModel.new();weapon.setup(id);stage.add_child(weapon)
		await process_frame
		var bounds=AABB();var first=true
		for mesh in weapon.find_children("*","MeshInstance3D",true,false):
			if not mesh.is_visible_in_tree(): continue
			var box=mesh.global_transform*mesh.mesh.get_aabb()
			bounds=box if first else bounds.merge(box);first=false
		var center=bounds.get_center()
		camera.position=center+Vector3(1.3,.8,-1.5)*2;camera.look_at(center)
		camera.size=maxf(.7,bounds.size.length()*1.12)
		await process_frame;await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
		var error=viewport.get_texture().get_image().save_png("res://assets/illustrated/weapon-icons/"+id+".png")
		if error!=OK: push_error("Weapon icon write failed: "+id);quit(1);return
		count+=1;print("WEAPON_ICON ",id," ",error);weapon.queue_free();await process_frame
	print("WEAPON_ICONS_COMPLETE "+str(count));viewport.queue_free();await process_frame;quit()

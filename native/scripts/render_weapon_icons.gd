extends SceneTree

const RENDER=640
const SIZE=256
const FILL=.86

func _initialize(): call_deferred("render_icons")

# Crops a render to its visible pixels and centres it, square, at FILL of the icon.
func framed(image: Image) -> Image:
	image.convert(Image.FORMAT_RGBA8)
	var used=image.get_used_rect()
	var icon=Image.create(SIZE,SIZE,false,Image.FORMAT_RGBA8)
	if used.size.x<=0 or used.size.y<=0: return icon
	var crop=image.get_region(used)
	var scale_value=SIZE*FILL/float(maxi(used.size.x,used.size.y))
	var size=Vector2i(maxi(1,roundi(used.size.x*scale_value)),maxi(1,roundi(used.size.y*scale_value)))
	crop.resize(size.x,size.y,Image.INTERPOLATE_LANCZOS)
	icon.blit_rect(crop,Rect2i(Vector2i.ZERO,size),(Vector2i(SIZE,SIZE)-size)/2)
	return icon

func render_icons():
	var viewport=SubViewport.new();viewport.size=Vector2i(RENDER,RENDER);viewport.own_world_3d=true;viewport.transparent_bg=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_4X;root.add_child(viewport)
	var stage=Node3D.new();viewport.add_child(stage)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_CLEAR_COLOR;env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("fff2d7");env.environment.ambient_light_energy=.55;stage.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-35,0);sun.light_energy=.8;stage.add_child(sun)
	var camera=Camera3D.new();stage.add_child(camera);camera.position=Vector3(.9,.6,-1.2);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=1.12;camera.look_at(Vector3(0,.1,-.12))
	DirAccess.make_dir_recursive_absolute("res://assets/illustrated/weapon-icons")
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	# --only=a,b renders just those weapons and leaves every other icon untouched.
	var only=[]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="): only=arg.trim_prefix("--only=").split(",")
	var count=0
	for entry in catalog.weapons:
		var id=str(entry.id)
		if OS.get_cmdline_user_args().has("--forge-slice") and id!="gun": continue
		if not only.is_empty() and not id in only: continue
		var weapon=WeaponModel.new();weapon.setup(id);stage.add_child(weapon)
		await process_frame
		var bounds=AABB();var first=true
		for mesh in weapon.find_children("*","MeshInstance3D",true,false):
			if not mesh.is_visible_in_tree(): continue
			var box=mesh.global_transform*mesh.mesh.get_aabb()
			bounds=box if first else bounds.merge(box);first=false
		var center=bounds.get_center()
		camera.position=center+Vector3(1.3,.8,-1.5)*2;camera.look_at(center)
		# Generous view; framed() crops to the weapon afterwards.
		camera.size=maxf(.7,bounds.size.length()*1.6)
		await process_frame;await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
		var error=framed(viewport.get_texture().get_image()).save_png("res://assets/illustrated/weapon-icons/"+id+".png")
		if error!=OK: push_error("Weapon icon write failed: "+id);quit(1);return
		count+=1;print("WEAPON_ICON ",id," ",error);weapon.queue_free();await process_frame
	print("WEAPON_ICONS_COMPLETE "+str(count));viewport.queue_free();await process_frame;quit()

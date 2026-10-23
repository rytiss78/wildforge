extends RefCounted

# Model pilot comparison in the real renderer: the shipped Count Duck and Briar
# Beetle beside the Blender pilot versions (loaded from WILDFORGE_PILOT_DIR, not
# from the game's assets), at the gameplay camera and close up. Both go through
# StyleModel, so shading, ink outline and the health orb match.
# Writes model-sheet.png, four columns:
#   row 1  gameplay camera: duck (current, pilot) from behind, beetle trio (current, pilot) ahead
#   row 2  close-ups: duck front (current, pilot), beetle front (current, pilot)
const CELL=Vector2i(480,270)

static func pilot(path: String) -> Node3D:
	var document=GLTFDocument.new();var state=GLTFState.new()
	if document.append_from_file(path,state)!=OK: return null
	return document.generate_scene(state)

static func model(g,asset: String,pilot_path: String) -> StyleModel:
	var shape=StyleModel.new();g.add_child(shape)
	if pilot_path.is_empty(): shape.setup(asset)
	else: shape.setup_scene(pilot(pilot_path),asset)
	return shape

static func frame(g,crop: Rect2=Rect2(0,0,1,1)) -> Image:
	await RenderingServer.frame_post_draw
	var image=g.get_viewport().get_texture().get_image();var size=Vector2(image.get_size())
	image=image.get_region(Rect2i(Vector2i(size*crop.position),Vector2i(size*crop.size)));image.resize(CELL.x,CELL.y,Image.INTERPOLATE_LANCZOS)
	return image

static func settle(g,frames: int):
	for i in range(frames): g._process(1.0/60.0);await g.get_tree().process_frame

static func run(g: Node3D):
	if DisplayServer.get_name()=="headless": g.get_tree().quit(1);return
	AudioServer.set_bus_volume_db(0,-80);g.start_run(407);g.invulnerable=1e9;g.spawn_clock=1e9;g.formation_clock=1e9
	await settle(g,90)
	g.set_physics_process(false);g.clear_entities();g.avatar.visible=false
	var folder=OS.get_environment("WILDFORGE_PILOT_DIR")
	var checks={"pilot_folder":DirAccess.dir_exists_absolute(folder)}
	var duck_path=folder.path_join("pilot_count_duck.glb");var beetle_path=folder.path_join("pilot_briar_beetle.glb")
	checks.pilot_files=FileAccess.file_exists(duck_path) and FileAccess.file_exists(beetle_path)
	if not checks.pilot_files:
		print("MODEL_REVIEW "+JSON.stringify({"checks":checks}));g.get_tree().quit(1);return
	var hero=g.player.position;var forward=-g.camera.global_basis.z;forward.y=0;forward=forward.normalized()
	# Same height for both: the hero is 1.5 m tall in play.
	var duck_scale=Vector3.ONE*.76
	var cells=[]
	for path in ["",duck_path]:
		var duck=model(g,"count_duck",path);duck.position=hero;duck.scale=duck_scale;duck.rotation.y=atan2(-forward.x,-forward.z)
		checks["orb_"+("pilot" if path else "current")]=duck.core_material!=null
		await settle(g,8);cells.append(await frame(g,Rect2(.3,.25,.4,.5)));duck.queue_free()
	for path in ["",beetle_path]:
		var trio=[]
		for i in range(3):
			var beetle=model(g,"creature_0_0",path);var p=hero+forward*(6.0+i%2*1.5)+forward.cross(Vector3.UP)*(float(i)-1.0)*2.2
			p.y=g.world.height_at(p.x,p.z);beetle.position=p;beetle.look_at(Vector3(hero.x,p.y,hero.z));trio.append(beetle)
		await settle(g,8);cells.append(await frame(g,Rect2(.2,.15,.6,.6)))
		for beetle in trio: beetle.queue_free()
	# Close-ups from a front three-quarter view with the camera locked.
	g.camera_locked=true
	for spec in [["count_duck","",1.5],["count_duck",duck_path,1.5],["creature_0_0","",1.4],["creature_0_0",beetle_path,1.4]]:
		var shape=model(g,spec[0],spec[1]);shape.position=hero;shape.rotation.y=0.0
		if spec[0]=="count_duck": shape.scale=duck_scale
		var side=Vector3(1.4,0,-2.6).normalized()*3.4
		g.camera.global_position=hero+side+Vector3.UP*1.5;g.camera.look_at(hero+Vector3.UP*float(spec[2])*.55)
		await settle(g,4);cells.append(await frame(g,Rect2(.2,.1,.6,.8)));shape.queue_free()
	g.camera_locked=false
	var board=Image.create(CELL.x*4,CELL.y*2,false,Image.FORMAT_RGBA8);board.fill(Color("101014"))
	for i in range(cells.size()):
		var image: Image=cells[i];image.convert(Image.FORMAT_RGBA8);board.blit_rect(image,Rect2i(Vector2i.ZERO,CELL),Vector2i(i%4*CELL.x,i/4*CELL.y))
	checks.sheet=board.save_png("user://model-sheet.png")==OK
	print("MODEL_REVIEW "+JSON.stringify({"checks":checks}))
	g.get_tree().quit(0 if not checks.values().has(false) else 1)

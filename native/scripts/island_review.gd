extends RefCounted

# Rendered island identity review: the same three biome spots on islands 1, 2 and
# 3 (rows), so each island's sky, ground corruption, veins and air can be
# compared, plus the arrival card on island 2. Writes island-sheet.png.
const CELL=Vector2i(480,270)

static func frame(g) -> Image:
	await RenderingServer.frame_post_draw
	var image=g.get_viewport().get_texture().get_image();image.resize(CELL.x,CELL.y,Image.INTERPOLATE_LANCZOS);return image

static func run(g: Node3D):
	if DisplayServer.get_name()=="headless": g.get_tree().quit(1);return
	AudioServer.set_bus_volume_db(0,-80);g.start_run(407);g.invulnerable=1e9;g.spawn_clock=1e9;g.formation_clock=1e9
	for i in range(90): await g.get_tree().process_frame
	g.set_process(false);g.set_physics_process(false)
	var cells=[];var checks={}
	for realm in [0,1,2]:
		g.enter_realm(realm,false);g.clear_entities();g.spawn_clock=1e9
		for i in range(30): g._process(.016);await g.get_tree().process_frame
		if realm==1:
			# The arrival card, shown as a player sees it on landing.
			g.Journey.announce(g,"ISLAND 2 · "+RealmWorld.NAMES[1].to_upper(),RealmWorld.GRADE[1].title+" · enemies +28% health and damage")
			g.hud.update(0);cells.append(await frame(g))
		checks["corruption_"+str(realm)]=is_equal_approx(float(g.world.terrain_material.get_shader_parameter("corruption")),float(RealmWorld.GRADE[realm].corruption))
		for biome in [0,2,4]:
			var p=g.world.landmarks[biome]+Vector3(0,0,14);p.y=g.world.height_at(p.x,p.z)+.1
			g.player.position=p;g.player.velocity=Vector3.ZERO;g.yaw=0;g.world.stream(p)
			for i in range(160):
				g.world.stream(p);g.world.weather_tick(.05,p);g._process(.016)
				await g.get_tree().process_frame
			cells.append(await frame(g))
	var board=Image.create(CELL.x*4,CELL.y*ceili(cells.size()/4.0),false,Image.FORMAT_RGBA8);board.fill(Color("101014"))
	for i in range(cells.size()):
		var image: Image=cells[i];image.convert(Image.FORMAT_RGBA8);board.blit_rect(image,Rect2i(Vector2i.ZERO,CELL),Vector2i(i%4*CELL.x,i/4*CELL.y))
	checks.sheet=board.save_png("user://island-sheet.png")==OK
	print("ISLAND_REVIEW "+JSON.stringify({"checks":checks,"cells":["island 1: biome 0,2,4","arrival card island 2","island 2: biome 0,2,4","island 3: biome 0,2,4"]}))
	g.get_tree().quit(0 if not checks.values().has(false) else 1)

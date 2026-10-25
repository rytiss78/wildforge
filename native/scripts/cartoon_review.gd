extends RefCounted

# The cartoon test enemy (CartoonAlienRig, the Gloop Gazer) beside the Briar Beetle
# it would replace, in Clover Woods. Captures: cartoon-ingame.png (game camera and
# HUD, the beetle left, the Gazer right, two more Gazers behind) and
# cartoon-sheet.png (close-up idle, mouth open on an attack, three-quarter walk, and
# hurt).

const CELL=Vector2i(720,405)

static func frame(g) -> Image:
	await RenderingServer.frame_post_draw
	var image=g.get_viewport().get_texture().get_image();image.convert(Image.FORMAT_RGBA8);image.resize(CELL.x,CELL.y,Image.INTERPOLATE_LANCZOS);return image

static func ground(g,p: Vector3) -> Vector3:
	return Vector3(p.x,g.world.height_at(p.x,p.z),p.z)

# Runs every rig's animation for a while; the review drives them itself.
static func play(g,rigs: Array,seconds: float,movement: Vector3=Vector3.ZERO):
	# Fixed 60 Hz steps, so a pose does not depend on how fast frames render.
	for step in range(maxi(1,int(seconds*60))):
		if g.mode=="paused": g.hud.close()
		var delta=1.0/60.0
		for rig in rigs: rig.animate(delta,movement,true)
		await g.get_tree().process_frame

static func run(g):
	AudioServer.set_bus_volume_db(0,-80)
	var checks={}
	g.start_run(151);g.set_physics_process(false);g.camera_locked=true;g.clear_entities();g.spawn_clock=1e9
	await play(g,[],.4)
	var origin: Vector3=g.player.position
	var beetle=g.world.model("creature_0_0",CreatureBook.HEIGHTS[0]);g.add_child(beetle);beetle.position=ground(g,origin+Vector3(-1.7,0,-5.5));beetle.rotation.y=PI
	var gazers=[]
	for spot in [Vector3(1.7,0,-5.5),Vector3(3.6,0,-9.5),Vector3(-.4,0,-11.0)]:
		var gazer=CartoonAlienRig.new();gazer.setup("cartoon_gazer");g.add_child(gazer);gazer.position=ground(g,origin+spot);gazer.rotation.y=PI+randf_range(-.4,.4);gazers.append(gazer)
	checks.built=gazers[0].eyeballs.size()==3 and gazers[0].legs.size()==4 and gazers[0].find_child("GlassCore",true,false)!=null
	var rigs=[beetle]+gazers
	# 1. In the game: its camera height and HUD, the hero in front.
	g.camera.position=origin+Vector3(0,2.6,3.2);g.camera.look_at(origin+Vector3(0,.9,-6.5))
	await play(g,rigs,1.2)
	await RenderingServer.frame_post_draw
	checks.ingame=g.get_viewport().get_texture().get_image().save_png("user://cartoon-ingame.png")==OK
	# 2-5. The sheet, on the front Gazer.
	g.hud.visible=false;g.player.visible=false
	var hero=gazers[0];var at: Vector3=hero.position
	var sheet=Image.create(CELL.x*2,CELL.y*2,false,Image.FORMAT_RGBA8)
	g.camera.position=at+Vector3(0,1.0,2.6);g.camera.look_at(at+Vector3(0,.75,0))
	await play(g,rigs,.8)
	sheet.blit_rect(await frame(g),Rect2i(Vector2i.ZERO,CELL),Vector2i.ZERO)
	hero.attack=.5;await play(g,rigs,.15)
	checks.mouth_opens=hero.jaw.rotation.x>.3
	sheet.blit_rect(await frame(g),Rect2i(Vector2i.ZERO,CELL),Vector2i(CELL.x,0))
	g.camera.position=at+Vector3(-2.4,1.3,1.6);g.camera.look_at(at+Vector3(0,.7,0))
	await play(g,rigs,.55,Vector3(0,0,3))
	checks.walks=absf(hero.legs[0].rotation.x)>.05 or absf(hero.legs[1].rotation.x)>.05
	sheet.blit_rect(await frame(g),Rect2i(Vector2i.ZERO,CELL),Vector2i(0,CELL.y))
	g.camera.position=at+Vector3(1.9,1.1,2.0);g.camera.look_at(at+Vector3(0,.75,0))
	hero.hurt=.3;hero.set_health(.35);await play(g,rigs,.1)
	sheet.blit_rect(await frame(g),Rect2i(Vector2i.ZERO,CELL),Vector2i(CELL.x,CELL.y))
	checks.sheet=sheet.save_png("user://cartoon-sheet.png")==OK
	print("CARTOON_REVIEW "+JSON.stringify({"checks":checks}))
	g.get_tree().quit(0 if not checks.values().has(false) else 1)

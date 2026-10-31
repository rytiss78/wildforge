extends RefCounted

# Underside review (October 31): a real run walks the hero out over the island's
# rim, under it, and back, with screenshots on top at the rim, mid-flip, under the
# island (upside down, view turned over), and back on top. Also renders the island
# from the side so the rim and the hanging belly can be judged.

static func shot(g,name: String) -> bool:
	await RenderingServer.frame_post_draw
	return g.get_viewport().get_texture().get_image().save_png("user://underside-"+name+".png")==OK

static func walk(g,direction: Vector3,frames: int,until: String=""):
	for i in range(frames):
		g.player.velocity=direction*6.0
		Input.action_press("move_forward")
		await g.get_tree().physics_frame
		if until!="" and g.underside.state==until: break
	Input.action_release("move_forward")

static func run(g):
	AudioServer.set_bus_volume_db(0,-80)
	var checks={}
	g.start_run(77);g.invulnerable=1e9;g.spawn_clock=1e9
	await g.get_tree().create_timer(.5).timeout
	g.clear_entities()
	var coast=g.world.shore_radius(Vector3.RIGHT)
	var start=Vector3(coast-14,0,0);start.y=g.world.height_at(start.x,0)+.3
	g.world.ensure_ground(start);g.player.position=start;g.player.reset_physics_interpolation()
	# Face the rim (+X): camera behind the hero, looking out.
	g.yaw=-PI*.5;g.pitch=.35
	for i in range(30): await g.get_tree().process_frame
	checks.top=await shot(g,"top")
	# A few enemies and a coin on top, near the rim: they must stay up there.
	for i in range(4):
		g.spawn_enemy(6);var e=g.enemies[-1];var at=Vector3(coast-6,0,(i-1.5)*3);at.y=g.world.height_at(at.x,at.z)+.2;e.node.position=at
	await walk(g,Vector3.RIGHT,240,"down")
	for i in range(12): await g.get_tree().physics_frame
	checks.mid=await shot(g,"flip")
	await walk(g,Vector3.RIGHT,120,"under")
	# Walk on under the island, inward (forward after the flip), then look.
	for i in range(50):
		Input.action_press("move_forward");await g.get_tree().physics_frame
	Input.action_release("move_forward")
	for i in range(30): await g.get_tree().process_frame
	checks.under=g.underside.state=="under" and g.player.position.y<g.world.height_at(g.player.position.x,g.player.position.z)-8
	checks.enemies_on_top=g.enemies.all(func(e):return e.dead or (not g.world.dangerous(e.node.position) and e.node.position.y>g.world.height_at(e.node.position.x,e.node.position.z)-2))
	checks.under_shot=await shot(g,"under")
	# Turn round and walk back out over the rim.
	g.yaw+=PI
	for i in range(30): await g.get_tree().process_frame
	checks.under_back=await shot(g,"under-back")
	for i in range(400):
		Input.action_press("move_forward");await g.get_tree().physics_frame
		if g.underside.state=="top": break
	Input.action_release("move_forward")
	for i in range(30): await g.get_tree().process_frame
	checks.returned=g.underside.state=="top"
	checks.return_shot=await shot(g,"return")
	# The island from outside: rim and belly.
	g.camera_locked=true;g.hud.visible=false
	g.camera.position=Vector3(coast+40,-6,30);g.camera.look_at(Vector3(coast-30,-14,0))
	for i in range(20): await g.get_tree().process_frame
	checks.side=await shot(g,"side")
	print("UNDERSIDE_REVIEW "+JSON.stringify({"checks":checks,"coast":coast}))
	g.get_tree().quit()

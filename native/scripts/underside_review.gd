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
	# The three pet wisps at the hero's shoulder, at stages 1, 2 and 3, close up.
	for i in range(3):
		var kind=Pet.KINDS[i];g.pet.kind=kind;g.pet.stage=i;g.pet.rebuild();g.pet.position=g.pet.home()
		g.camera_locked=true
		var hero=g.player.position;var side=g.avatar.global_basis.x.normalized()
		var behind=g.avatar.global_basis.z.normalized()
		g.camera.position=hero+Vector3.UP*2.0+side*1.6+behind*3.0;g.camera.look_at(hero+Vector3.UP*1.3+side*.4)
		for f in range(40): await g.get_tree().process_frame
		checks["pet_"+kind]=await shot(g,"pet-"+kind)
	g.camera_locked=false
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
	# Digby Mole (November 1): a close-up, then his trick (V) for real, down
	# through the island and back up under a few enemies.
	g.select_hero(g.rules.data.heroes.filter(func(h):return h.id=="mole")[0])
	var dig_at=Vector3(coast-24,0,8);dig_at.y=g.world.height_at(dig_at.x,dig_at.z)+.3
	g.world.ensure_ground(dig_at);g.player.position=dig_at;g.player.velocity=Vector3.ZERO;g.player.reset_physics_interpolation()
	g.camera_locked=true
	var front=g.avatar.global_basis.z.normalized()
	g.camera.position=dig_at+Vector3.UP*1.3+front*3.2+g.avatar.global_basis.x.normalized()*1.2;g.camera.look_at(dig_at+Vector3.UP*.8)
	for i in range(30): await g.get_tree().process_frame
	checks.mole_shot=await shot(g,"mole")
	g.camera_locked=false
	for i in range(20): await g.get_tree().physics_frame
	g.trick_cooldown=0.0;checks.mole_trick=HeroTricks.use(g)
	for i in range(24): await g.get_tree().process_frame
	checks.mole_mid=await shot(g,"mole-dig")
	for i in range(90):
		await g.get_tree().physics_frame
		if g.underside.state=="under": break
	for i in range(30): await g.get_tree().process_frame
	checks.mole_under=g.underside.state=="under" and g.avatar.visible
	checks.mole_under_shot=await shot(g,"mole-under")
	for i in range(3):
		g.spawn_enemy(6);var e=g.enemies[-1];var at=Vector3(g.player.position.x+(i-1)*2.0,0,g.player.position.z+2.5);at.y=g.world.height_at(at.x,at.z)+.2;e.node.position=at
	g.trick_cooldown=0.0;checks.mole_trick_up=HeroTricks.use(g)
	for i in range(90):
		await g.get_tree().physics_frame
		if g.underside.state=="top": break
	for i in range(4): await g.get_tree().process_frame
	checks.mole_up=g.underside.state=="top"
	checks.mole_up_shot=await shot(g,"mole-up")
	# The island from outside: rim and belly.
	g.camera_locked=true;g.hud.visible=false
	g.camera.position=Vector3(coast+40,-6,30);g.camera.look_at(Vector3(coast-30,-14,0))
	for i in range(20): await g.get_tree().process_frame
	checks.side=await shot(g,"side")
	print("UNDERSIDE_REVIEW "+JSON.stringify({"checks":checks,"coast":coast}))
	g.get_tree().quit()

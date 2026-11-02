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
	for i in range(Pet.KINDS.size()):
		var kind=Pet.KINDS[i];g.pet.kind=kind;g.pet.stage=i%3;g.pet.rebuild();g.pet.position=g.pet.home()
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
	# Underneath: place a turret (it hangs from the rock) and jump (November 1).
	var hung={"id":"heal-turret","rank":1,"power":1.0,"turret":true,"range":7.0}
	g.deploy_turret(hung)
	for i in range(20): await g.get_tree().process_frame
	g.try_jump()
	for i in range(10): await g.get_tree().physics_frame
	checks.under_hop=g.underside.hop>.4
	checks.under_turret_shot=await shot(g,"under-turret")
	for i in range(60):
		await g.get_tree().physics_frame
		if g.underside.grounded(): break
	if is_instance_valid(hung.node): hung.node.queue_free()
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
	# Back on top: a Mender and a Thumper turret and a few of the Florist's flowers,
	# each with its ring on the ground.
	var spot=Vector3(coast-40,0,-10);spot.y=g.world.height_at(spot.x,spot.z)+.3
	g.world.ensure_ground(spot);g.player.position=spot;g.player.velocity=Vector3.ZERO;g.player.reset_physics_interpolation();g.yaw=-PI*.5;g.pitch=.5
	for w in g.equipped:
		if is_instance_valid(w.get("node")): w.node.queue_free()
	g.equipped.clear()
	for id in ["heal-turret","pulse-turret"]:
		var item=g.rules.data.weapons.filter(func(w):return w.id==id)[0].duplicate(true);item.kind="weapon";item.strength=1.0;g.equip_weapon(item)
	var turrets=g.equipped.filter(func(w):return w.id in ["heal-turret","pulse-turret"])
	if turrets.size()==2:
		turrets[0].node.position=spot+Vector3(6,0,-6);turrets[1].node.position=spot+Vector3(6,0,6)
		for t in turrets: t.node.position.y=g.world.height_at(t.node.position.x,t.node.position.z);t.node.get_node("Ring").queue_free();TurretPulse.add_ring(g,t,false)
	var flowers_item=g.rules.data.weapons.filter(func(w):return w.id=="flowers")[0].duplicate(true);flowers_item.kind="weapon";flowers_item.strength=1.0;g.equip_weapon(flowers_item)
	for k in range(2): g.plant_flower(spot+Vector3(14+k*7,0,(k-.5)*6),g.equipped[-1])
	for f in g.flowers: f.age=2.0
	for i in range(40): await g.get_tree().process_frame
	checks.turrets_flowers=await shot(g,"turrets-flowers")
	if not g.flowers.is_empty():
		var bloom_at=g.flowers[0].node.position;g.camera_locked=true;g.hud.visible=false
		g.camera.position=bloom_at+Vector3(0,7,7);g.camera.look_at(bloom_at)
		for i in range(10): await g.get_tree().process_frame
		checks.flowers_ring=g.flowers[0].node.get_node("Area").visible and await shot(g,"flowers")
		g.camera_locked=false;g.hud.visible=true
	# The Florist's trick plants a ring of grown flowers, while she is on fire
	# (lava flames), and a danger mark and a burst show as plain colour fills.
	g.select_hero(g.rules.data.heroes.filter(func(h):return h.id=="florist")[0])
	var trick_at=spot+Vector3(-12,0,0);trick_at.y=g.world.height_at(trick_at.x,trick_at.z)+.3
	g.world.ensure_ground(trick_at);g.player.position=trick_at;g.player.velocity=Vector3.ZERO;g.player.reset_physics_interpolation()
	for i in range(10): await g.get_tree().physics_frame
	var planted=g.flowers.size();g.trick_cooldown=0.0;checks.florist_trick=HeroTricks.use(g) and g.flowers.size()>=mini(planted+6,g.FLOWER_MAX)
	g.player_fire=30.0
	var mark=preload("res://scripts/danger_mark.gd").make(g,trick_at+Vector3(-7,0,4),3.0,"meteor");mark.material_override.set_shader_parameter("progress",.5)
	CombatInk.wave(g,trick_at+Vector3(-7,0,-4),3.0,Color("ffbd35"))
	g.camera_locked=true;g.hud.visible=false
	g.camera.position=trick_at+Vector3(9,11,9);g.camera.look_at(trick_at+Vector3(-2,0,0))
	for i in range(12): await g.get_tree().process_frame
	checks.florist_shot=await shot(g,"florist")
	g.camera.position=trick_at+Vector3(2.6,2.0,2.6);g.camera.look_at(trick_at+Vector3.UP*.9)
	for i in range(8): await g.get_tree().process_frame
	checks.fire_shot=await shot(g,"fire")
	# Prickle Rick lying on his side among a few monsters (November 2).
	g.player_fire=0.0
	g.select_hero(g.rules.data.heroes.filter(func(h):return h.id=="cactus")[0])
	for i in range(3): await g.get_tree().process_frame
	g.camera.position=trick_at+Vector3(3.2,2.2,3.2);g.camera.look_at(trick_at+Vector3.UP*.4)
	for i in range(8): await g.get_tree().process_frame
	checks.pickle_shot=await shot(g,"pickle")
	g.camera_locked=false;g.hud.visible=true;g.player_fire=0.0;mark.queue_free()
	# The island from outside: rim and belly.
	g.camera_locked=true;g.hud.visible=false
	g.camera.position=Vector3(coast+40,-6,30);g.camera.look_at(Vector3(coast-30,-14,0))
	for i in range(20): await g.get_tree().process_frame
	checks.side=await shot(g,"side")
	print("UNDERSIDE_REVIEW "+JSON.stringify({"checks":checks,"coast":coast}))
	g.get_tree().quit()

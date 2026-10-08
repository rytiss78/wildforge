extends RefCounted

static func block(game,p: Vector3,size: Vector3,color: Color) -> StaticBody3D:
	var body=StaticBody3D.new();body.collision_layer=1;game.add_child(body);body.position=p
	var shape=BoxShape3D.new();shape.size=size;var collider=CollisionShape3D.new();collider.shape=shape;body.add_child(collider)
	var mesh=BoxMesh.new();mesh.size=size;game.shape(mesh,color,body,Vector3.ZERO)
	return body

static func capture(game,name: String) -> bool:
	game.hud.update(0)
	for i in range(4): await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return game.get_viewport().get_texture().get_image().save_png("user://surface-"+name+".png")==OK

static func run(game):
	seed(614);AudioServer.set_bus_volume_db(0,-80);game.start_run(614);game.set_physics_process(false);game.camera_locked=true
	game.clear_entities();game.equipped.clear();game.spawn_clock=99999;game.invulnerable=10000
	block(game,Vector3(0,29.5,0),Vector3(40,1,16),Color("8b9e91"))
	block(game,Vector3(0,34,0),Vector3(1,8,8),Color("b4a78e"))
	var ceiling=block(game,Vector3(3,38.25,0),Vector3(8,.5,8),Color("aab5c7"))
	game.spawn_enemy(8);var enemy=game.enemies[-1];enemy.flying=false;enemy.boss=false;enemy.behavior="chase";enemy.speed=4;enemy.hp=10000;enemy.maxHp=10000;enemy.node.position=Vector3(3,30.1,0)
	game.player.position=Vector3(-2,38.6,0);game.player.velocity=Vector3.ZERO
	game.camera.position=Vector3(17,39,19);game.camera.look_at(Vector3(0,34,0))
	var checks={};checks.before=await capture(game,"before")
	for i in range(300):
		await game.get_tree().physics_frame;game.update_combat(1./60)
		if enemy.node.position.y>34.5: break
	checks.wall=enemy.node.position.y>34.5 and enemy.get("surface_attached",false) and enemy.node.basis.y.x>.8
	print("SURFACE_WALL "+str(enemy.node.position)+" up "+str(enemy.node.basis.y))
	checks.wall_capture=await capture(game,"wall")
	var frozen=enemy.node.position;enemy.freeze=1.
	for i in range(20): await game.get_tree().physics_frame;game.update_combat(1./60)
	checks.freeze=enemy.node.position.distance_to(frozen)<.01;enemy.freeze=0
	game.player.position=Vector3(5,38.6,0)
	for i in range(300):
		await game.get_tree().physics_frame;game.update_combat(1./60)
		if enemy.node.basis.y.y<-.8 and enemy.node.position.x>3: break
	checks.ceiling=enemy.node.basis.y.y<-.8 and enemy.node.position.x>3
	print("SURFACE_CEILING "+str(enemy.node.position)+" up "+str(enemy.node.basis.y))
	checks.ceiling_capture=await capture(game,"ceiling")
	checks.no_roof_damage=not game.enemy_touching(enemy,Vector3(enemy.node.position.x,38.5,enemy.node.position.z))
	var actor=game.coop.snapshot().actors.filter(func(a):return a.id==enemy.net_id)[0]
	var remote=game.spawn_network_enemy(actor);EnemySurface.replicate(remote,CoopSession.vector(actor.surface_up),CoopSession.vector(actor.surface_forward))
	checks.network_orientation=remote.node.basis.is_equal_approx(enemy.node.basis)
	checks.hit_center=game.enemy_center(enemy).y<enemy.node.position.y
	var contact=game.melee_contact(enemy,game.enemy_center(enemy)+Vector3.RIGHT*4)
	checks.melee_axis=absf(contact.y-game.enemy_center(enemy).y)<.1
	remote.node.queue_free();game.enemies.erase(remote)
	ceiling.queue_free();await game.get_tree().physics_frame;await game.get_tree().physics_frame
	for i in range(30): await game.get_tree().physics_frame;game.update_combat(1./60)
	checks.detach=not enemy.get("surface_attached",false) and enemy.node.basis.y.is_equal_approx(Vector3.UP)
	block(game,Vector3(-12,32,0),Vector3(4,4,6),Color("c6a683"))
	EnemySurface.detach(enemy);enemy.node.position=Vector3(-7,30.1,0);enemy.node.velocity=Vector3.ZERO
	game.player.position=Vector3(-12,34.1,0)
	for i in range(420):
		await game.get_tree().physics_frame;game.update_combat(1./60)
		if enemy.node.position.y>33.9 and enemy.node.basis.y.y>.9 and enemy.node.position.x<-10.5: break
	checks.ledge=enemy.node.position.y>33.9 and enemy.node.basis.y.y>.9 and enemy.node.position.x<-10.5
	print("SURFACE_LEDGE "+str(enemy.node.position)+" up "+str(enemy.node.basis.y))
	game.camera.position=Vector3(-3,38,13);game.camera.look_at(Vector3(-11,32,0))
	checks.ledge_capture=await capture(game,"ledge")
	var slope=block(game,Vector3(12,33,0),Vector3(1,8,8),Color("a7b1cc"));slope.rotation.z=PI/4
	await game.get_tree().physics_frame;await game.get_tree().physics_frame
	var normal=slope.basis.x;var tangent=slope.basis.y
	var hit=EnemySurface.ray(game,enemy,slope.position+normal*3,slope.position-normal*2)
	EnemySurface.attach(enemy,hit,tangent);var start=enemy.node.position
	for i in range(30):
		await game.get_tree().physics_frame;EnemySurface.tick(game,enemy,start+tangent*3,1./60)
	checks.slope=enemy.node.basis.y.dot(normal)>.98 and (enemy.node.position-start).dot(tangent)>1
	game.camera.position=Vector3(24,39,15);game.camera.look_at(slope.position)
	checks.slope_capture=await capture(game,"slope")
	print("SURFACE_REVIEW "+JSON.stringify(checks));game.get_tree().quit(0 if checks.values().all(func(v):return v) else 1)

extends RefCounted

static func block(game,p: Vector3,size: Vector3,color: Color) -> StaticBody3D:
	var body=StaticBody3D.new();body.collision_layer=1;game.add_child(body);body.position=p
	var collider=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;collider.shape=shape;body.add_child(collider)
	var mesh=BoxMesh.new();mesh.size=size;game.shape(mesh,color,body,Vector3.ZERO)
	return body

static func run(game) -> Dictionary:
	var checks={}
	var base=block(game,Vector3(60,29.5,0),Vector3(30,1,14),Color("8b9e91"))
	var step=block(game,Vector3(62,30.175,0),Vector3(8,.35,5),Color("c6a683"))
	game.spawn_enemy(8);var enemy=game.enemies[-1]
	enemy.flying=false;enemy.boss=false;enemy.behavior="chase";enemy.speed=4;enemy.hp=10000;enemy.maxHp=10000
	enemy.node.position=Vector3(55,30.1,0);game.player.position=Vector3(66,30.4,0)
	for i in range(240):
		await game.get_tree().physics_frame;game.update_combat(1./60)
	checks.small_step=enemy.node.position.x>61 and enemy.node.position.y>30.3
	print("HILL_STEP "+str(enemy.node.position))
	step.queue_free();await game.get_tree().physics_frame;await game.get_tree().physics_frame
	var slope=block(game,Vector3(62,31.65,0),Vector3(9,.25,5),Color("a7b1cc"));slope.rotation.z=deg_to_rad(22)
	EnemySurface.detach(enemy);enemy.node.position=Vector3(55,30.1,0);enemy.node.velocity=Vector3.ZERO;enemy.vertical=0
	game.player.position=Vector3(65,33.3,0)
	for i in range(240):
		await game.get_tree().physics_frame;game.update_combat(1./60)
	checks.gentle_hill=enemy.node.position.x>62 and enemy.node.position.y>31.5
	print("HILL_SLOPE "+str(enemy.node.position))
	base.queue_free();slope.queue_free();enemy.node.queue_free();game.enemies.erase(enemy)
	return checks

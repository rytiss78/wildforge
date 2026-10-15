extends RefCounted

static func run(g) -> Dictionary:
	g.start_run(407);g.set_process(false);g.set_physics_process(false)
	g.stats=g.rules.data.stats.duplicate(true);g.buffs.clear();g.harvest_buffs.clear()
	g.clear_entities();g.equipped.clear();g.spawn_clock=99999;g.invulnerable=10000
	# A level elevated floor isolates tactics from terrain traversal.
	var floor_body=StaticBody3D.new();floor_body.collision_layer=1;g.add_child(floor_body)
	var collider=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(100,1,100)
	collider.shape=shape;floor_body.add_child(collider);floor_body.position.y=49.5
	g.player.position=Vector3(0,50,0);g.player.velocity=Vector3.ZERO
	g.spawn_enemy(20);var enemy=g.enemies[-1]
	enemy.behavior="spit";enemy.biome=0;enemy.flying=false;enemy.speed=4;enemy.freeze=0;enemy.blind=0;enemy.attack=0
	enemy.node.position=Vector3(0,50,12);enemy.surface_probe=999
	await g.get_tree().physics_frame
	for i in range(180):
		g.update_combat(1.0/60);await g.get_tree().physics_frame
	var checks={}
	var distance=Vector2(enemy.node.position.x,enemy.node.position.z).length()
	checks.ranged_keeps_firing_distance=distance>9 and distance<16
	checks.ranged_fires_from_ring=enemy.attack>0
	enemy.node.position=Vector3(0,50,4);enemy.node.velocity=Vector3.ZERO;enemy.surface_probe=999
	for i in range(45): g.update_combat(1.0/60);await g.get_tree().physics_frame
	checks.ranged_retreats=enemy.node.position.z>5
	enemy.behavior="charge";enemy.attack=0;enemy.windup=0;enemy.charge=0;enemy.node.position=Vector3(0,50,10);enemy.node.velocity=Vector3.ZERO
	g.update_combat(.04)
	checks.charge_warns_before_moving=enemy.get("windup",0)>.7 and enemy.node.velocity.length()<.1
	g.player.position=Vector3(8,50,0)
	for i in range(60): g.update_combat(1.0/60);await g.get_tree().physics_frame
	print("CHARGE_TRACE "+JSON.stringify({"windup":enemy.get("windup",0),"charge":enemy.get("charge",0),"velocity":str(enemy.node.velocity),"direction":str(enemy.get("charge_direction",Vector3.ZERO)),"position":str(enemy.node.position)}))
	checks.charge_commits_after_dodge=enemy.get("charge",0)>0 and absf(enemy.node.velocity.x)<.1 and enemy.node.velocity.z< -1
	enemy.freeze=1;g.update_combat(.04)
	checks.freeze_cancels_charge=enemy.get("charge",0)==0 and enemy.get("windup",0)==0 and enemy.node.velocity.length()<.1
	# Exercise the real collision/steering/climbing path against a thick tree.
	g.player.position=Vector3(0,50,0);enemy.node.position=Vector3(0,50,14)
	enemy.node.velocity=Vector3.ZERO;enemy.behavior="chase";enemy.freeze=0;enemy.surface_probe=0
	var tree=Node3D.new();g.add_child(tree);tree.position=Vector3(0,50,7)
	NatureScenery.collision(tree,0,0,2.0)
	await g.get_tree().physics_frame
	var climbed=false;var sideways=0.0
	for i in range(480):
		g.update_combat(1.0/60);await g.get_tree().physics_frame
		climbed=climbed or enemy.get("surface_attached",false) or enemy.node.position.y>50.5
		sideways=maxf(sideways,absf(enemy.node.position.x))
	checks.tree_does_not_trigger_climb=not climbed
	checks.enemy_passes_tree=enemy.node.position.distance_to(g.player.position)<4 and sideways>1.5
	tree.queue_free()
	g.clear_entities();floor_body.queue_free()
	return checks

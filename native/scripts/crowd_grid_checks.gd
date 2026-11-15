extends RefCounted

# enemies_near (the crowd grid) must never miss an enemy that a loop over every
# enemy would have found, and must hand them back in the same order.
static func run(game: Node3D) -> Dictionary:
	var checks={}
	game.select_hero(game.rules.data.heroes[1])
	game.start_run(911);game.set_physics_process(false);game.spawn_clock=99999;game.clear_entities();game.mode="playing"
	var here: Vector3=game.player.position
	for i in range(48): game.spawn_enemy(12.0)
	for i in range(game.enemies.size()):
		var enemy=game.enemies[i]
		enemy.maxHp=5000.0;enemy.hp=5000.0;enemy.speed=0.0;enemy.erase("modifier")
		# A spiral out to about 40 m, so near cells are packed and far ones sparse.
		enemy.node.position=here+Vector3(cos(i*2.4),0,sin(i*2.4))*(1.5+i*.8)
	game.enemies[5].dead=true
	checks.grid_stale_returns_everyone=not game.crowd_live and game.enemies_near(here,1.0).size()==game.enemies.size()-1
	game.crowd_build()
	var same=true;var ordered=true;var narrowed=false
	for probe in [[here,2.0],[here,6.0],[here+Vector3(9,0,-4),3.5],[here+Vector3(-20,0,14),5.0],[here+Vector3(30,0,30),8.0],[here,60.0]]:
		var point: Vector3=probe[0];var radius: float=probe[1]
		var hit=func(e):return not e.dead and point.distance_to(game.melee_contact(e,point))<radius
		var found=game.enemies_near(point,radius)
		same=same and found.filter(hit).map(func(e):return e.net_id)==game.enemies.filter(hit).map(func(e):return e.net_id) and found.all(func(e):return not e.dead)
		for i in range(1,found.size()): ordered=ordered and game.enemies.find(found[i-1])<game.enemies.find(found[i])
		narrowed=narrowed or found.size()<game.enemies.size()/2
	checks.grid_finds_what_a_full_loop_finds=same
	checks.grid_keeps_spawn_order=ordered
	checks.grid_narrows_small_queries=narrowed
	# An enemy spawned after the grid was built is found in the same tick.
	game.spawn_enemy(12.0);var late=game.enemies[-1];late.erase("modifier")
	checks.grid_sees_late_spawn=game.enemies_near(late.node.position,1.0).has(late)
	# Area damage through the grid hurts exactly the enemies in the blast.
	var blast: Vector3=here+Vector3(4,0,3)
	var due=game.enemies.filter(func(e):return not e.dead and blast.distance_to(game.melee_contact(e,blast))<5.0)
	game.damage_area(blast,5.0,10.0,"crit")
	checks.grid_area_damage_exact=due.size()>=3 and game.enemies.all(func(e):return e.dead or (e.hp<5000.0)==due.has(e))
	game.crowd_live=false
	game.clear_entities()
	return checks

extends RefCounted

static func run(game: Node3D):
	AudioServer.set_bus_volume_db(0,-80)
	game.start_run(407);game.set_physics_process(false);game.set_process(false);game.mode="playing"
	game.clear_entities();game.equipped.clear();game.spawn_clock=99999
	var checks={}
	checks.stronger_more_xp=game.enemy_xp_reward({"maxHp":92,"damage":2})>game.enemy_xp_reward({"maxHp":23,"damage":1})*4
	checks.boss_more_xp=game.enemy_xp_reward({"maxHp":500,"damage":1})>game.enemy_xp_reward({"maxHp":92,"damage":2})
	var p=game.player.position+Vector3(12,5,0)
	game.spawn_pickup(p,"xp",1.5);game.spawn_pickup(p+Vector3(.1,0,0),"xp",6);game.spawn_pickup(p+Vector3(0,2,0),"xp",3);game.spawn_pickup(p,"gold",2)
	game.merge_xp_orbs()
	checks.touch_merges=game.pickups.size()==3 and game.pickups.filter(func(v):return v.kind=="xp" and v.value==7.5).size()==1
	checks.value_conserved=is_equal_approx(game.pickups.filter(func(v):return v.kind=="xp").reduce(func(total,v):return total+v.value,0.0),10.5)
	checks.vertical_gap_not_merged=game.pickups.filter(func(v):return v.kind=="xp" and v.value==3).size()==1
	checks.gold_separate=game.pickups.filter(func(v):return v.kind=="gold" and v.value==2).size()==1
	var blob=game.pickups.filter(func(v):return v.kind=="xp" and v.value==7.5)[0]
	checks.bigger_glowing=blob.radius>.12 and blob.node.material_override.emission_enabled
	for frame in range(180): game.update_pickups(1.0/60)
	checks.merged_lands=blob.settled and absf(blob.node.position.y-game.world.height_at(blob.node.position.x,blob.node.position.z)-blob.radius-.01)<.01
	# Collecting may also pick up the nearby separate drop; reconcile the whole XP ledger.
	var expected=blob.value;var earned=game.xp;game.player.position=blob.node.position;game.update_pickups(.01)
	var remaining=game.pickups.filter(func(v):return v.kind=="xp").reduce(func(total,v):return total+v.value,0.0)
	checks.collection_correct=game.xp-earned>=expected and is_equal_approx(game.xp-earned+remaining,10.5)
	game.clear_entities();game.player.position=Vector3(0,game.world.height_at(0,0)+.3,0)
	var kills=game.kills
	for i in range(125):
		var node=Node3D.new();game.add_child(node);node.position=game.player.position+Vector3(100+i,0,0)
		game.enemies.append({"node":node,"dead":false,"boss":i==0,"net_id":i,"radius":.6})
	checks.cap_recycles_far=game.make_spawn_room() and game.enemies.size()==124
	checks.boss_protected=game.enemies[0].boss and not game.enemies[0].dead
	checks.no_free_kill_rewards=game.kills==kills and game.pickups.is_empty()
	game.spawn_enemy(22)
	checks.fresh_spawn_at_cap=game.enemies.size()==125 and game.enemies[-1].node.position.distance_to(game.player.position)<45
	game.clear_entities()
	# Real capsule movement against a wall with a group, rather than a mock steering check.
	game.player.position=Vector3(0,game.world.height_at(0,0)+.3,-12)
	var wall=StaticBody3D.new();wall.collision_layer=1;game.add_child(wall)
	var collider=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(8,8,1);collider.shape=box;wall.add_child(collider);wall.position=Vector3(0,game.world.height_at(0,0)+4,0)
	var starts={}
	for i in range(12):
		game.spawn_enemy(20)
		if game.enemies.is_empty(): continue
		var enemy=game.enemies[-1];enemy.flying=false;enemy.behavior="walk";enemy.speed=3;enemy.node.position=Vector3((i%4-1.5)*1.7,game.world.height_at(0,8)+.3,8+(i/4)*2.5);starts[enemy.net_id]=enemy.node.position
	await game.get_tree().physics_frame
	for frame in range(600):
		game.update_combat(1.0/60)
		await game.get_tree().physics_frame
	var progressed=0
	for enemy in game.enemies:
		if starts.has(enemy.net_id) and enemy.node.position.z< -1: progressed+=1
	checks.crowd_advances_around_wall=progressed>=8
	print("CROWD_XP_CHECK "+JSON.stringify(checks)+" progressed="+str(progressed))
	wall.queue_free();game.clear_entities();game.sound.active=false
	for child in game.sound.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D: child.stop();child.stream=null
	await game.get_tree().create_timer(.3).timeout
	game.get_tree().quit(0 if checks.values().all(func(ok):return ok) else 1)

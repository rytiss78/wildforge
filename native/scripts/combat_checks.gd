extends RefCounted

static func run(game: Node3D):
	AudioServer.set_bus_volume_db(0,-80)
	game.start_run(407);game.set_physics_process(false);game.set_process(false)
	game.clear_entities();game.equipped.clear();game.spawn_clock=99999
	game.stats.armor=0;game.stats.dodge=0;game.stats.thorns=0;game.shield_hp=0;game.hp=10000
	var checks={}
	# Real capsules must approach and hit the hero, rather than avoid its collider.
	for behavior in ["chase","swoop","armored","spit","skitter","charge","flying"]:
		game.clear_entities();game.player.position=Vector3(0,.3,0)
		game.spawn_enemy(20)
		var enemy=game.enemies[0]
		enemy.behavior="swoop" if behavior=="flying" else behavior
		enemy.flying=behavior=="flying";enemy.speed=3;enemy.attack=0;enemy.altitude=4.5
		enemy.node.floor_snap_length=0 if enemy.flying else 1.2
		enemy.node.position=Vector3(enemy.radius+1.8,4.5 if enemy.flying else .15,0)
		game.elapsed=8-fposmod(enemy.net_id,9);game.invulnerable=0
		var before=game.health_damage
		await game.get_tree().physics_frame
		for frame in range(180):
			game.elapsed+=1.0/60;game.update_combat(1.0/60)
			await game.get_tree().physics_frame
		checks[behavior+"_attacks"]=game.health_damage>before
		checks[behavior+"_collision_restored"]=enemy.node.collision_mask==3
	game.clear_entities();game.player.position=Vector3(0,.3,0);game.spawn_enemy(20)
	var frozen=game.enemies[0];frozen.flying=false;frozen.behavior="chase";frozen.freeze=5
	frozen.node.position=Vector3(frozen.radius+.6,.15,0)
	game.invulnerable=0;var before_freeze=game.health_damage
	await game.get_tree().physics_frame
	for frame in range(30):
		game.update_combat(1.0/60);await game.get_tree().physics_frame
	checks.frozen_cannot_contact=game.health_damage==before_freeze
	game.clear_entities()
	var point=Vector3(20,15,0)
	game.spawn_pickup(point,"xp",1.5);game.spawn_pickup(point+Vector3(.1,0,0),"xp",6)
	for frame in range(180): game.update_pickups(1.0/60)
	checks.merge_conserves_xp=game.pickups.size()==1 and is_equal_approx(game.pickups[0].value,7.5)
	var orb=game.pickups[0]
	checks.merged_orb_lands=orb.settled and absf(orb.node.position.y-game.world.height_at(orb.node.position.x,orb.node.position.z)-orb.radius-.01)<.01
	game.player.position=orb.node.position;var before_xp=game.xp;game.update_pickups(1.0/60)
	checks.merged_orb_collects=is_equal_approx(game.xp-before_xp,7.5) and game.pickups.is_empty()
	print("COMBAT_CHECK "+JSON.stringify(checks))
	game.clear_entities();game.sound.active=false
	for child in game.sound.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D: child.stop();child.stream=null
	await game.get_tree().create_timer(.3).timeout
	game.get_tree().quit(0 if checks.values().all(func(ok):return ok) else 1)

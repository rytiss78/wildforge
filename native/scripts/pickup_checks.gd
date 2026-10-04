extends RefCounted

static func run(game: Node3D):
	AudioServer.set_bus_volume_db(0,-80)
	game.start_run(407);game.set_physics_process(false);game.set_process(false);game.clear_entities()
	var point=Vector3(95,0,55);point.y=game.world.height_at(point.x,point.z)+15
	game.spawn_pickup(point,"xp",7);game.spawn_pickup(point,"gold",13)
	var coin=game.pickups[1];var orb=game.pickups[0];var checks={}
	checks.separate_drops=Vector2(coin.node.position.x-orb.node.position.x,coin.node.position.z-orb.node.position.z).length()>=.8
	for i in range(30): game.update_pickups(1.0/60)
	checks.aerial_coin_falls=coin.node.position.y<point.y-1
	for i in range(330): game.update_pickups(1.0/60)
	checks.coin_lands=coin.settled and absf(coin.node.position.y-game.world.height_at(coin.node.position.x,coin.node.position.z)-.27)<.001
	var landed: Vector3=coin.node.position
	for i in range(60): game.update_pickups(1.0/60)
	checks.no_idle_float=coin.node.position.is_equal_approx(landed)
	checks.xp_glow_preserved=orb.node.material_override.emission_enabled and absf(orb.node.position.y-point.y)<.08
	checks.values_preserved=coin.value==13 and orb.value==7
	game.player.position=coin.node.position+Vector3(2,0,0);game.stats.coinRadius=4
	var gold_before=game.gold
	for i in range(30): game.update_pickups(1.0/60)
	checks.magnet_collects_coin=game.gold==gold_before+13 and not game.pickups.has(coin)
	game.player.position=orb.node.position
	var xp_before=game.xp;game.update_pickups(1.0/60)
	checks.xp_collects=game.xp==xp_before+7 and game.pickups.is_empty()
	# A low drop must not fall beneath the terrain on a hill.
	var hill=Vector3(210,0,160);hill.y=game.world.height_at(hill.x,hill.z)
	game.spawn_pickup(hill,"gold",3);var hill_coin=game.pickups[0]
	for i in range(180): game.update_pickups(1.0/60)
	checks.hill_landing=hill_coin.settled and hill_coin.node.position.y>=game.world.height_at(hill_coin.node.position.x,hill_coin.node.position.z)
	game.clear_entities()
	for child in game.sound.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D: child.stop();child.stream=null
	game.sound.active=false
	await game.get_tree().create_timer(.3).timeout
	print("PICKUP_CHECK "+JSON.stringify(checks));game.get_tree().quit(0 if checks.values().all(func(ok):return ok) else 1)

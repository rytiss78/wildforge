extends RefCounted

static func run(game):
	seed(407);AudioServer.set_bus_volume_db(0,-80);game.start_run(407)
	# Normal starter stats and health; the bot gathers nearby drops and circles the start.
	var levels=[];var previous_level=1;var chest_ready=-1.0;var captured=false
	var began=Time.get_ticks_msec()
	while game.elapsed<60 and Time.get_ticks_msec()-began<85000 and game.hp>0:
		await game.get_tree().process_frame
		if game.level>previous_level:
			levels.append({"level":game.level,"seconds":game.elapsed});previous_level=game.level
		if game.mode=="offer": game.choose_offer(0)
		if game.mode=="replace": game.replace_weapon(0,game.offers[0])
		if game.mode=="reveal": game.finish_reveal()
		if game.gold>=game.rules.chest_price(game.paid_chests) and chest_ready<0: chest_ready=game.elapsed
		var target=Vector3(cos(game.elapsed*.23)*9,0,sin(game.elapsed*.23)*9)
		var best=18.0
		for pickup in game.pickups:
			var distance=pickup.node.position.distance_to(game.player.position)
			if distance<best: best=distance;target=pickup.node.position
		var direction=target-game.player.position;direction.y=0;direction=direction.normalized().rotated(Vector3.UP,-game.yaw)
		for action in ["move_right","move_left","move_forward","move_back"]: Input.action_release(action)
		Input.action_press("move_right" if direction.x>0 else "move_left",absf(direction.x)*.7)
		Input.action_press("move_back" if direction.z>0 else "move_forward",absf(direction.z)*.7)
		if game.elapsed>10 and not captured and DisplayServer.get_name()!="headless":
			captured=true;await RenderingServer.frame_post_draw
			if game.get_viewport().get_texture().get_image().save_png("user://pace-review.png")!=OK: game.get_tree().quit(1);return
	for action in ["move_right","move_left","move_forward","move_back"]: Input.action_release(action)
	var nearest_chest=10000.0
	for chest in game.chests: nearest_chest=minf(nearest_chest,Vector2(chest.node.position.x,chest.node.position.z).length())
	print("PACE_REVIEW "+JSON.stringify({"seconds":game.elapsed,"levels":levels,"kills":game.kills,"hp":game.hp,"gold":game.gold,"chest_affordable_seconds":chest_ready,"nearest_chest_m":nearest_chest,"xp":game.xp,"xp_target":game.xp_target}))
	game.get_tree().quit()

extends RefCounted

# Headless UI-capture driver. Starts a run, plays a short bot loop that opens
# the reward offer overlay, then saves named PNGs of the live HUD.
static func run(game):
	seed(407);AudioServer.set_bus_volume_db(0,-80);game.start_run(407)
	var captured={}
	var elapsed=0.0
	var bot_target=Vector3(0,0,0)
	while captured.size()<3 and game.hp>0:
		await game.get_tree().process_frame
		elapsed+=1.0/60.0
		if game.mode=="start":
			if game.hero.id!=game.rules.data.heroes[0].id: game.select_hero(game.rules.data.heroes[0])
			if elapsed>2.0: game.start_run()
		elif game.mode=="offer" or game.mode=="replace":
			game.choose_offer(0)
			if game.mode=="replace": game.replace_weapon(0,game.offers[0])
		elif game.mode=="reveal":
			game.finish_reveal()
		elif game.mode=="playing":
			var best=25.0
			for pickup in game.pickups:
				var d=pickup.node.position.distance_to(game.player.position)
				if d<best: best=d;bot_target=pickup.node.position
			var dir=bot_target-game.player.position;dir.y=0
			if dir.length()>0.001: dir=dir.normalized()
			Input.action_release("move_left");Input.action_release("move_right")
			Input.action_release("move_forward");Input.action_release("move_back")
			Input.action_press("move_right" if dir.x>0.12 else "",absf(maxf(0.0,dir.x-0.05)))
			Input.action_press("move_left" if dir.x<-0.12 else "",absf(maxf(0.0,-dir.x-0.05)))
			Input.action_press("move_forward" if dir.z<-0.12 else "",absf(maxf(0.0,-dir.z-0.05)))
			Input.action_press("move_back" if dir.z>0.12 else "",absf(maxf(0.0,dir.z-0.05)))
		if not captured.has("title") and game.mode=="start" and elapsed>3.0:
			await RenderingServer.frame_post_draw;shot(game,"title");captured["title"]=true
		if not captured.has("hud") and game.mode=="playing" and elapsed>8.0:
			await RenderingServer.frame_post_draw;shot(game,"hud");captured["hud"]=true
		if not captured.has("offer") and (game.mode=="offer" or game.mode=="level_reveal"):
			await RenderingServer.frame_post_draw;shot(game,"offer");captured["offer"]=true
	if captured.size()<3:
		print("UISHOT INCOMPLETE "+JSON.stringify(captured))
	game.get_tree().quit(0)

static func shot(game, name):
	await RenderingServer.frame_post_draw
	var img=game.get_viewport().get_texture().get_image()
	var ok=img.save_png("user://ui-shot-"+name+".png")
	print("UISHOT "+name+" code="+str(ok)+" size="+str(img.get_width())+"x"+str(img.get_height()))

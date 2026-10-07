extends RefCounted

static func capture(game, name: String) -> bool:
	for frame in range(4): await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path="user://ui-"+name+".png"
	var error=game.get_viewport().get_texture().get_image().save_png(path)
	print("UI_CAPTURE "+name+" "+str(error))
	return error==OK

static func run(game):
	if DisplayServer.get_name()=="headless": game.get_tree().quit(1);return
	AudioServer.set_bus_volume_db(0,-80)
	game.set_physics_process(false)
	var okay=await capture(game,"menu")
	game.start_run(407);game.set_physics_process(false);game.spawn_clock=99999
	game.player.position=Vector3(0,.2,0);game.camera.position=Vector3(0,10,15)
	game.camera.look_at(Vector3(0,0,-5));game.gold=75;game.hp=game.stats.maxHp*.7
	game.hud.update(0)
	okay=await capture(game,"hud") and okay
	var offers=[]
	for pair in [["jump-boots-item",0],["augment-air-damage",1],["augment-dash-rate",2],["jump-boots-skill",3],["augment-kill-speed",1]]:
		var item=game.rules.loot_by_id[pair[0]].duplicate(true)
		item.tier=pair[1];item.strength=[1.0,2.0,3.5,5.5][pair[1]]
		for effect in item.effects: effect.amount*=item.strength
		offers.append(item)
	game.offers=offers;game.mode="offer";game.offer_kind="item";game.offer_source="level"
	game.hud.show_offers(offers,"level",false)
	okay=await capture(game,"offers") and okay
	game.hud.controller_move(Vector2.RIGHT)
	okay=game.hud.cards[1].has_focus() and game.update.focused_offer==1 and okay
	okay=await capture(game,"focus") and okay
	var weapons=[]
	for id in ["flame","popcorn-repeater","gravity","horn","lightning"]:
		var item=game.rules.data.weapons.filter(func(w):return w.id==id)[0].duplicate(true)
		item.kind="weapon";item.tier=2;item.strength=3.5;weapons.append(item)
	game.offers=weapons;game.hud.show_offers(weapons,"chest",false)
	okay=await capture(game,"weapons") and game.hud.offer_layout_fits() and okay
	print("UI_REVIEW_SAVED: "+("OK" if okay else "FAILED"))
	game.get_tree().quit(0 if okay else 1)

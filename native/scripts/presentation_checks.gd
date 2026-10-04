extends RefCounted

static func run(game: Node3D):
	AudioServer.set_bus_volume_db(0,-80)
	game.start_run(407);game.set_physics_process(false);game.set_process(false);game.mode="paused"
	var checks={}
	var keys=InputMap.action_get_events("jump").filter(func(e):return e is InputEventKey)
	checks.space_jump=keys.any(func(e):return e.physical_keycode==KEY_SPACE)
	checks.shift_dash=InputMap.action_get_events("dash").any(func(e):return e is InputEventKey and e.physical_keycode==KEY_SHIFT)
	game.hud.update(0)
	checks.bigger_map=game.hud.map_view.size.x==230
	checks.box_markers=game.hud.map_view.known_chests.size()==game.chests.size()
	checks.simple_counter=game.hud.box_counter.text=="BOXES  6 left"
	game.gold=1000;game.buy_chest(game.chests[0]);await game.get_tree().create_timer(.65).timeout
	checks.opened_box_hidden=not game.chests[0].node.visible
	game.hud.update(0);checks.opened_marker_removed=game.hud.map_view.known_chests.size()==5
	checks.reel_sounds=range(4).all(func(i):return ResourceLoader.exists("res://assets/music/chest_reels_%d.wav" % i))
	game.finish_reveal();game.xp=0;game.offers=game.rules.offers("weapon",0,false,game.stats,game.equipped);game.offer_source="level";game.mode="offer";game.hud.show_offers(game.offers,"level")
	var before=game.equipped.duplicate(true);game.skip_offer()
	checks.skip_keeps_weapons=game.mode=="playing" and game.equipped==before and game.offers.is_empty()
	game.sound.settings.voice=1.0;game.sound.hero_hurt(game.hero.id,game.player);var first=game.sound.last_hurt
	game.sound.hero_hurt(game.hero.id,game.player);checks.hurt_cooldown=game.sound.last_hurt==first
	game.sound.tick(0,true,false)
	checks.hero_spatial_audio=game.sound.hurt_voice is AudioStreamPlayer3D and game.sound.hurt_voice.global_position.is_equal_approx(game.player.global_position+Vector3.UP)
	checks.sky_voice=game.sound.voice is AudioStreamPlayer3D and game.sound.voice.bus=="SkyVoice" and game.sound.voice.global_position.y>game.player.global_position.y+20
	game.hud.update(0)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw;game.get_viewport().get_texture().get_image().save_png("user://presentation-0.7.1.png")
	for child in game.sound.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D: child.stop();child.stream=null
	game.sound.active=false;game.clear_entities();await game.get_tree().create_timer(.3).timeout
	print("PRESENTATION_CHECK "+JSON.stringify(checks));game.get_tree().quit(0 if checks.values().all(func(ok):return ok) else 1)

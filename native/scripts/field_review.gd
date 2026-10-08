extends RefCounted

static func run(game):
	seed(407);AudioServer.set_bus_volume_db(0,-80)
	game.start_run(407);game.set_physics_process(false);game.spawn_clock=99999
	game.clear_entities();game.camera_locked=true
	game.camera.position=Vector3(0,10,13);game.camera.look_at(Vector3(0,0,-1))
	game.remote_weapon_effect("gravity",Vector3.ZERO,Vector3(-4,0,-1))
	game.spawn_enemy(8)
	var enemy=game.enemies[0];enemy.node.position=Vector3(4,game.world.height_at(4,-1),-1)
	game.stats.pools=2;game.kill_enemy(enemy,"hit")
	game.hud.toast_time=0;game.screen_flash=0
	var audio_ok=true
	game.sound.settings.sfx=1.0
	for id in game.sound.WEAPON_SFX:
		game.sound.effect(id,game.player.position)
		audio_ok=audio_ok and game.sound.cache["effect_"+id]==game.sound.weapon_samples[id] and game.sound.weapon_samples[id].get_length()>=.3
	for id in ["saw","flame","fire-turret"]:
		game.sound.weapon_loop(id,true,game.player.position)
		audio_ok=audio_ok and game.sound.weapon_loops[id].stream.get_length()>1.9
		game.sound.weapon_loop(id,false,game.player.position)

	await game.get_tree().create_timer(.6).timeout
	await RenderingServer.frame_post_draw
	var saved=game.get_viewport().get_texture().get_image().save_png("user://field-review.png")==OK
	print("FIELD_REVIEW "+JSON.stringify({"weapon_samples_playable":audio_ok,"capture_saved":saved,"poison_pool":game.pools.size()==1,"gravity_visual":game.effects.any(func(e):return e.get("stationary",false) and e.life>1)}))
	game.get_tree().quit(0 if saved and audio_ok and game.pools.size()==1 else 1)

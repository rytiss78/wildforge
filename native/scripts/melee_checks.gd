extends RefCounted

static func run(game: Node3D):
	AudioServer.set_bus_volume_db(0,-80)
	game.hero=game.rules.data.heroes.filter(func(h):return h.id=="loaf")[0]
	game.start_run(407);game.set_physics_process(false);game.set_process(false);game.clear_entities();game.mode="playing"
	var weapon=game.equipped[0]
	var checks={"eight_meter_reach":weapon.id=="saw" and weapon.range==8}
	game.spawn_enemy(6);game.spawn_enemy(5);game.spawn_enemy(10)
	var victim=game.enemies[0];var behind=game.enemies[1];var distant=game.enemies[2]
	for enemy in game.enemies:
		enemy.hp=1000;enemy.maxHp=1000;enemy.speed=0;enemy.radius=.6;enemy.height=2
	victim.node.position=game.player.position+Vector3(0,0,-6)
	behind.node.position=game.player.position+Vector3(0,0,7.5)
	distant.node.position=game.player.position+Vector3(0,0,-12)
	var origin=game.player.position+Vector3.UP*.9
	game.fire(weapon,origin)
	checks.windup_no_instant_damage=victim.hp==1000 and game.melee_attacks.size()==1
	game.update_melee(.1);game.avatar.animate(.1,Vector3.ZERO,true)
	checks.damage_waits_for_blade=victim.hp==1000
	game.avatar.animate(.12,Vector3.ZERO,true);game.update_melee(.12)
	checks.hit_without_touching=victim.hp<1000 and game.player.position.distance_to(victim.node.position)>5
	checks.forward_sweep=behind.hp==1000 and distant.hp==1000
	checks.hand_reaches_enemy=game.avatar.melee.hand.global_position.distance_to(game.melee_contact(victim,origin))<.5
	checks.visible_slash=game.effects.any(func(e):return e.get("slash",false))
	checks.blood_at_impact=game.effects.filter(func(e):return e.get("blood",false)).size()==6
	var blood_count=game.effects.filter(func(e):return e.get("blood",false)).size()
	game.hurt_enemy(victim,1,"poison")
	checks.no_dot_splatter_spam=game.effects.filter(func(e):return e.get("blood",false)).size()==blood_count
	game.camera.position=game.player.position+Vector3(9,6,7);game.camera.look_at(game.player.position+Vector3(0,1,-2));game.camera.reset_physics_interpolation()
	game.player.reset_physics_interpolation()
	for enemy in game.enemies: enemy.node.reset_physics_interpolation()
	game.hud.update(0)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png("user://melee-0.7.2.png")
	game.avatar.animate(.22,Vector3.ZERO,true)
	checks.hand_returns=game.avatar.melee.is_empty() and not game.avatar.reach_glove.visible
	var hp_before=victim.hp
	game.remote_weapon_effect("saw",origin,game.enemy_center(victim));game.update_melee(.3)
	checks.remote_visual_no_extra_damage=victim.hp==hp_before
	game.fire(weapon,origin);game.mode="paused";game._physics_process(.3)
	checks.pause_stops_impact=victim.hp==hp_before and game.melee_attacks.size()==1
	game.clear_entities()
	checks.cleanup=game.melee_attacks.is_empty() and game.avatar.melee.is_empty()
	for child in game.sound.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D: child.stop();child.stream=null
	game.sound.active=false
	await game.get_tree().create_timer(.3).timeout
	print("MELEE_CHECK "+JSON.stringify(checks));game.get_tree().quit(0 if checks.values().all(func(ok):return ok) else 1)

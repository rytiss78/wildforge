extends RefCounted
static func run(game):
	game.start_run(41);game.set_physics_process(false);game.camera_locked=true;game.clear_entities();game.hud.close()
	game.player.position=Vector3(0,game.world.height_at(0,0),0)
	game.camera.position=game.player.position+Vector3(8,7,10);game.camera.look_at(game.player.position)
	var checks={};var weapon={"power":1.0}
	game.plant_flower(game.player.position+Vector3(2,0,0),weapon);game.flowers[0].age=2
	var state={"flower_realm":game.realm,"flowers":game.coop.flower_state()}
	game.coop.sync_flowers(77,state)
	checks.remote_flower=game.coop.flower_visuals.size()==1 and game.flowers.size()==1
	checks.visual_only=game.coop.flower_visuals.values()[0] is Node3D and game.flowers.size()==1
	game.coop.sync_flowers(77,{"flower_realm":game.realm});checks.removal=game.coop.flower_visuals.is_empty()
	game.coop.sync_flowers(77,state)
	game.spawn_enemy(4);var enemy=game.enemies[-1];enemy.hp=1000;enemy.node.position=game.player.position+Vector3(-2,0,0)
	game.coop.active=true;game.coop.hosting=true;game.coop.members[77]={}
	enemy.hit_owner=77;game.hurt_enemy(enemy,15,"coop","gun");enemy.erase("hit_owner")
	checks.other_hidden=game.damage_numbers.is_empty()
	game.hurt_enemy(enemy,12,"hit","gun");checks.own_visible=game.damage_numbers.size()==1 and game.damage_numbers[0].value==12
	game.set_damage_status(enemy,"poison",3,77);game.hurt_enemy(enemy,1,"poison")
	checks.other_dot_hidden=game.damage_numbers.size()==1
	game.set_damage_status(enemy,"fire",3,game.coop.local_id);game.hurt_enemy(enemy,2,"fire")
	checks.own_dot_visible=game.damage_numbers.size()==2
	game.coop.hosting=false;game.coop.owner_id=77;game.damage_numbers.clear()
	game.hurt_enemy(enemy,7,"hit","gun");checks.no_predicted_duplicate=game.damage_numbers.is_empty()
	game.update.receive(77,{"type":"big_damage","realm":game.realm,"amount":7,"enemy_id":enemy.net_id,"cause":"hit","source":"gun","position":CoopSession.array(game.enemy_center(enemy))})
	checks.confirmed_client=game.damage_numbers.size()==1 and game.damage_numbers[0].value==7
	game.coop.active=false;game.coop.members.clear();game.hud.update(0)
	var first_y=game.hud.damage_labels[0].position.y
	checks.starts_at_bottom=first_y>750 and first_y<810
	game.damage_numbers[0].life=.75;game.hud.update(0)
	checks.rises_up=game.hud.damage_labels[0].position.y<first_y-60
	for i in range(4): await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	checks.capture=game.get_viewport().get_texture().get_image().save_png("user://coop-feedback.png")==OK
	checks.label_on_screen=game.hud.damage_labels.any(func(l):return l.visible and Rect2(Vector2.ZERO,Vector2(1440,810)).has_point(l.position))
	print("COOP_FEEDBACK "+JSON.stringify(checks));game.get_tree().quit(0 if not checks.values().has(false) else 1)

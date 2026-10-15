extends RefCounted

static func run(game):
	if DisplayServer.get_name()=="headless": game.get_tree().quit(1);return
	seed(407);AudioServer.set_bus_volume_db(0,-80)
	game.start_run(407);game.invulnerable=1000;game.spawn_clock=99999
	# Burst feedback remains bounded and reuses labels after expiration.
	game.damage_numbers.clear()
	for i in range(500): game.record_damage_number(1,0.25,"poison")
	var aggregated=game.damage_numbers.size()==1 and game.damage_numbers[0].value==125
	for i in range(500): game.record_damage_number(i+2,2,"hit")
	var regular_hits_hidden=game.damage_numbers.size()==1
	for i in range(500): game.record_damage_number(i+2,2,"crit")
	game.hud.update(0)
	var bounded=game.damage_numbers.size()==game.MAX_DAMAGE_NUMBERS and game.hud.damage_labels.size()==game.MAX_DAMAGE_NUMBERS
	var label_id=game.hud.damage_labels[0].get_instance_id()
	game.damage_numbers.clear();game.hud.update(0)
	var cleared=game.hud.damage_labels.all(func(n):return not n.visible)
	game.record_damage_number(999,12,"ice");game.hud.update(0)
	var reused=game.hud.damage_labels[0].get_instance_id()==label_id
	if not (aggregated and regular_hits_hidden and bounded and cleared and reused):
		push_error("Damage feedback burst/reuse contract failed");game.get_tree().quit(1);return
	game.damage_numbers.clear()
	# Behind-camera actors must still emit feedback above the lower HUD.
	game.record_damage_number(10001,128,"crit",game.camera.position+game.camera.global_basis.z*20)
	game.damage_numbers[0].screen_x=.5
	game.hud.update(0)
	var start_rect=game.hud.damage_labels[0].get_global_rect()
	var band_clear=start_rect.end.y<=game.get_viewport().get_visible_rect().size.y-200 and game.hud.damage_labels[0].visible
	game.damage_numbers[0].life=.5;game.hud.update(0)
	var rises=game.hud.damage_labels[0].position.y<start_rect.position.y-50
	var fades=game.hud.damage_labels[0].modulate.a<1
	game.hud.pause_menu();game.hud.update(0)
	var modal_clear=game.hud.damage_labels.all(func(n):return not n.visible)
	game.hud.close()
	if not (band_clear and rises and fades and modal_clear):
		push_error("Bottom-band damage motion/clearance contract failed");game.get_tree().quit(1);return
	game.damage_numbers.clear()
	game.xp_target=100000;game.stats.damage=4
	for id in ["shotgun","ice"]:
		var item=game.rules.data.weapons.filter(func(w):return w.id==id)[0].duplicate(true)
		item.kind="weapon";item.tier=0;item.strength=1;game.equip_weapon(item)
	for i in range(65): game.spawn_enemy(10+i%18)
	var frames=[];var nodes=0;var began=Time.get_ticks_usec();var previous=began;var captured=false
	while Time.get_ticks_usec()-began<18000000:
		await game.get_tree().process_frame
		var now=Time.get_ticks_usec();var seconds=(now-began)/1000000.0
		if seconds>4: frames.append((now-previous)/1000.0)
		previous=now;nodes=maxi(nodes,game.get_tree().get_node_count())
		if seconds>5 and not captured:
			captured=true;await RenderingServer.frame_post_draw
			if game.get_viewport().get_texture().get_image().save_png("user://combat-review.png")!=OK: game.get_tree().quit(1);return
		if seconds>6 and seconds<8: Input.action_press("move_right")
		elif seconds>=8 and seconds<10: Input.action_release("move_right");Input.action_press("move_left")
		else: Input.action_release("move_right");Input.action_release("move_left")
	Input.action_release("move_right");Input.action_release("move_left")
	frames.sort()
	var heights=[]
	for index in range(6):
		var mesh=load("res://assets/style3d/baked/creature_0_%d.res" % index)
		heights.append({"species":index,"asset_height":mesh.get_aabb().size.y,"requested_height":CreatureBook.HEIGHTS[index]})
	var result={"bottom_band_clear":band_clear,"damage_rises":rises,"damage_fades":fades,"damage_hidden_in_menu":modal_clear,"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"damage_aggregated":aggregated,"damage_bounded":bounded,"damage_cleared":cleared,"damage_labels_reused":reused,"p50_ms":frames[frames.size()/2],"p95_ms":frames[int(frames.size()*.95)],"frames":frames.size(),"nodes":nodes,"enemies":game.enemies.size(),"kills":game.kills,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"mesh_heights":heights,"renderer":RenderingServer.get_video_adapter_name()}
	var file=FileAccess.open("user://combat-review.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
	# Capture the actual contact entry point with simulation paused mid-warning.
	game.set_process(false);game.set_physics_process(false);game.clear_entities();game.equipped.clear()
	game.spawn_enemy(2);var attacker=game.enemies[-1]
	attacker.node.position=game.player.position+Vector3.FORWARD;attacker.behavior="chase";attacker.speed=0
	attacker.freeze=0;attacker.blind=0;attacker.contact=0
	game.update_combat(.04)
	game.camera.position=game.player.position+Vector3(5,5,7);game.camera.look_at(game.player.position+Vector3.UP*.6)
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	result.contact_warning_saved=game.get_viewport().get_texture().get_image().save_png("user://contact-warning.png")==OK and attacker.get("contact_windup",0)>0
	print("COMBAT_REVIEW "+JSON.stringify(result));game.get_tree().quit(0 if result.contact_warning_saved else 1)

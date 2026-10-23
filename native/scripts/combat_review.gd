extends RefCounted

static func run(game):
	if DisplayServer.get_name()=="headless": game.get_tree().quit(1);return
	seed(407);AudioServer.set_bus_volume_db(0,-80)
	game.start_run(407);game.invulnerable=1000;game.spawn_clock=99999
	# Burst feedback remains bounded and reuses labels after expiration.
	game.damage_numbers.clear()
	for i in range(500): game.record_damage_number(1,0.25,"poison")
	var aggregated=game.damage_numbers.size()==1 and game.damage_numbers[0].value==125
	# October 21 spec: ordinary hits show numbers; the pool stays bounded and crits
	# still get through when it is full of ordinary hits. October 23: numbers that
	# make room fade out, so up to DAMAGE_FADE_SLACK extra may be fading.
	for i in range(500): game.record_damage_number(i+2,2,"hit")
	var regular_hits_shown=game.damage_numbers.size()==game.MAX_DAMAGE_NUMBERS and game.damage_numbers.any(func(n):return n.cause=="hit")
	for i in range(500): game.record_damage_number(i+2,2,"crit")
	game.hud.update(0)
	var cap=game.MAX_DAMAGE_NUMBERS+game.DAMAGE_FADE_SLACK
	var bounded=game.damage_numbers.size()<=cap and game.damage_numbers.filter(func(n):return not n.get("leaving",false)).size()==game.MAX_DAMAGE_NUMBERS and game.hud.damage_labels.size()<=cap and game.damage_numbers.any(func(n):return n.cause=="crit")
	var label_id=game.hud.damage_labels[0].get_instance_id()
	game.damage_numbers.clear();game.hud.update(0)
	var cleared=game.hud.damage_labels.all(func(n):return not n.visible)
	game.record_damage_number(999,12,"ice");game.hud.update(0)
	var reused=game.hud.damage_labels[0].get_instance_id()==label_id
	if not (aggregated and regular_hits_shown and bounded and cleared and reused):
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
	# A weapon's own hit rises from that weapon's slot icon.
	game.damage_numbers.clear();game.hud.update(0)
	var weapon_id=str(game.equipped[0].id)
	game.record_damage_number(10002,21,"hit",game.player.position,weapon_id);game.hud.update(0)
	var slot=game.hud.weapons.slot_rect(weapon_id);var shown=game.hud.damage_labels[0].get_global_rect()
	var from_slot=slot.size!=Vector2.ZERO and absf(shown.get_center().x-slot.get_center().x)<40 and shown.end.y<=slot.position.y+1 and shown.end.y>slot.position.y-20
	game.damage_numbers[0].life=.5;game.hud.update(0)
	var slot_rises=game.hud.damage_labels[0].get_global_rect().end.y<shown.end.y-40
	if not (from_slot and slot_rises):
		push_error("Weapon damage does not rise from its slot: slot=%s label=%s later=%s weapon=%s visible=%s" % [slot,shown,game.hud.damage_labels[0].get_global_rect(),weapon_id,game.hud.damage_labels[0].visible]);game.get_tree().quit(1);return
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
	# The species follows the spawn biome, which varies with the frame count of the
	# soak above. Flyers hover out of reach and wall-crawlers use another contact
	# test, so keep spawning until a grounded melee attacker comes up.
	var attacker={}
	for attempt in range(30):
		game.spawn_enemy(2);attacker=game.enemies[-1]
		if not attacker.get("flying",false) and not attacker.get("surface_attached",false) and attacker.get("behavior","")!="spit": break
		attacker.node.queue_free();game.enemies.pop_back()
	attacker.node.position=game.player.position+Vector3.FORWARD;attacker.behavior="chase";attacker.speed=0
	attacker.freeze=0;attacker.blind=0;attacker.contact=0
	game.update_combat(.04)
	game.camera.position=game.player.position+Vector3(5,5,7);game.camera.look_at(game.player.position+Vector3.UP*.6)
	await game.get_tree().process_frame
	await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	result.contact_attacker={"model":str(attacker.get("model","")),"behavior":str(attacker.get("behavior","")),"radius":float(attacker.get("radius",0)),"windup":float(attacker.get("contact_windup",0))}
	result.contact_warning_saved=game.get_viewport().get_texture().get_image().save_png("user://contact-warning.png")==OK and attacker.get("contact_windup",0)>0
	result.minimap_camera_alignment=true
	for degrees in [0,90,180,270]:
		var heading=deg_to_rad(degrees)
		game.yaw=heading+.3 # The target orbit differs while the camera catches up.
		game.camera.position=game.player.position+Vector3(0,8,12).rotated(Vector3.UP,heading)
		game.camera.look_at(game.player.position+Vector3.UP)
		game.hud.update(0)
		var map=game.hud.map_view
		var ahead=map.point(game.player.position-game.camera.global_basis.z*30,100)-map.size*.5
		var right=map.point(game.player.position+game.camera.global_basis.x*30,100)-map.size*.5
		result.minimap_camera_alignment=result.minimap_camera_alignment and absf(ahead.x)<.01 and ahead.y<0 and right.x>0 and absf(right.y)<.01
		await game.get_tree().process_frame
		await RenderingServer.frame_post_draw
		result.minimap_camera_alignment=result.minimap_camera_alignment and game.get_viewport().get_texture().get_image().save_png("user://minimap-%d.png" % degrees)==OK
	print("COMBAT_REVIEW "+JSON.stringify(result));game.get_tree().quit(0 if result.contact_warning_saved and result.minimap_camera_alignment else 1)

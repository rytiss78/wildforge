extends RefCounted

static func capture(g,name: String):
	g.hud.update(0)
	for frame in range(90):
		g.world.build_tick(.016);g.world.weather_tick(.016,g.player.position);await g.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return g.get_viewport().get_texture().get_image().save_png("user://hermes-"+name+".png")==OK

static func run(g):
	AudioServer.set_bus_volume_db(0,-80);seed(407)
	g.start_run(407);g.set_physics_process(false);g.set_process(false);g.camera_locked=true
	var checks={};var guards=g.enemies.filter(func(e):return e.get("magnet_guard",false))
	checks.three_targetable_guards=guards.size()==3 and guards.all(func(e):return e.node.get_meta("rig").identity=="magnet_guard")
	g.player.position=g.update.magnet_position+Vector3(0,1,17)
	g.world.ensure_ground(g.player.position)
	for chunk in range(40): g.world.stream(g.player.position)
	g.camera.position=g.update.magnet_position+Vector3(15,16,23);g.camera.look_at(g.update.magnet_position+Vector3.UP)
	g.update.activate_magnet();checks.defenses_lock_activation=not g.update.magnet_active
	var position_before=g.player.position;g.player.position=g.update.magnet_position;checks.defense_hint=g.update.hint().contains("Destroy 3 turrets");g.player.position=position_before
	checks.guards_grounded=guards.all(func(e):return not e.flying and absf(e.node.position.y-g.world.height_at(e.node.position.x,e.node.position.z))<.3)
	g.stats.shield=25;g.shield_hp=17;g.stats.armor=12;g.xp=12;g.hud.update(0)
	checks.defense_numbers=g.hud.shield_text.text.contains("17 / 25") and g.hud.armor_text.text.contains("12")
	checks.edge_bar=g.hud.xp.get_global_rect().size.x==g.get_viewport().get_visible_rect().size.x and is_equal_approx(g.hud.xp.get_global_rect().end.y,g.get_viewport().get_visible_rect().size.y)
	checks.edge_level=g.hud.status.get_parent()==g.hud.root and g.hud.status.text=="LV. 1"
	checks.map_center=g.hud.map_view.point(g.player.position,100).distance_to(g.hud.map_view.size*.5)<.01
	checks.map_transparent=g.hud.map_view.terrain.get_image().get_pixel(0,0).a==0
	checks.captures=await capture(g,"magnet")
	var target=guards[0];g.player.position=target.node.position+Vector3(0,0,4)
	g.equipped.clear();var gun=g.rules.data.weapons.filter(func(w):return w.id=="gun")[0].duplicate(true);gun.kind="weapon";gun.strength=1;gun.tier=0;g.equip_weapon(gun)
	var before=target.hp;g.fire(g.equipped[0],g.player.position+Vector3.UP)
	for i in range(80): g.update_combat(.016)
	checks.projectile_hits_guard=target.hp<before
	g.damage_area(target.node.position,3,100000,"slam")
	checks.area_hits_guard=target.dead
	for guard in guards:
		if not guard.dead: g.hurt_enemy(guard,100000,"melee")
	g.update.tick(.01);checks.defenses_destroyed=g.update.magnet_turret_count==0
	# October 21 spec: one pull of every drop on the map at activation, then spent.
	for pickup in g.pickups: pickup.node.queue_free()
	g.pickups.clear();g.spawn_pickup(g.update.magnet_position+Vector3(5,1,0),"xp",7);g.spawn_pickup(g.update.magnet_position+Vector3(-200,1,0),"gold",3)
	g.mode="playing";g.player.position=g.update.magnet_position;g.interact()
	checks.interact_activates=g.update.magnet_active
	g.player.position=g.update.magnet_position+Vector3(40,0,0);g.xp=0;g.xp_target=10000
	var coins=g.gold
	for i in range(900): g.update_pickups(.02)
	checks.magnet_collects=g.xp==7 and g.gold==coins+3 and g.pickups.is_empty()
	g.spawn_pickup(g.update.magnet_position+Vector3(6,1,0),"gold",5)
	for i in range(150): g.update.tick(.02);g.update_pickups(.02)
	checks.magnet_spent_once=g.update.magnet_spent and not g.update.magnet_active and g.pickups.size()==1 and g.gold==coins+3
	g.player.position=g.update.magnet_position;g.interact()
	checks.magnet_not_reusable=not g.update.magnet_active and g.update.hint().contains("SPENT")
	var old_magnet=g.update.magnet_node
	g.enter_realm(1);g.set_physics_process(false);g.set_process(false)
	await g.get_tree().process_frame
	checks.no_broken_buildings=g.world.find_children("GreatHall_*","Node3D",false,false).is_empty()
	checks.realm_cleanup=not is_instance_valid(old_magnet) and not g.update.magnet_active and g.update.magnet_turrets.size()==3
	g.realm_time=75;var shrine=g.Hunt.shrine(g);g.player.position=shrine.position;g.interact()
	var targets=g.enemies.filter(func(e):return e.net_id in g.events.hunt_ids)
	checks.hunt_entry=targets.size()==3
	checks.hunt_distance=targets.all(func(e):return Vector2(e.node.position.x-shrine.position.x,e.node.position.z-shrine.position.z).length()>=80 and Vector2(e.node.position.x-shrine.position.x,e.node.position.z-shrine.position.z).length()<=120)
	for i in range(5): g.update_combat(.1)
	checks.hunt_not_despawned=targets.all(func(e):return not e.dead)
	g.camera.position=shrine.position+Vector3(0,9,15);g.camera.look_at(shrine.position+Vector3.UP)
	g.Hunt.tick(g);checks.captures=await capture(g,"hunt") and checks.captures
	g.sound.start(407);g.sound.tick(.02,true,true)
	checks.boss_music_solo=g.sound.boss_melody.playing and not g.sound.rhythm.playing and not g.sound.lead.playing and not g.sound.synth.playing
	g.sound.boss_voice_last=-100;var spoken=g.sound.boss_curse(g.player.position,9)
	checks.lithuanian_voice=spoken==9 and is_equal_approx(g.sound.boss_voice.pitch_scale,.75)
	g.events.eclipse=true;g._process(.1);g.set_process(false)
	checks.blood_only=g.blood_rain.emitting and g.blood_rain.visible and not g.world.weather.emitting
	checks.eclipse_audio=g.sound.eclipse_active and g.sound.eclipse_music.playing and g.sound.boss_melody.volume_db<=-79
	for i in range(120): await g.get_tree().process_frame
	checks.captures=await capture(g,"eclipse") and checks.captures
	g.events.eclipse=false;g._process(.1);g.set_process(false)
	checks.weather_resumes=g.world.weather.emitting==(g.world.biome_at(g.player.position) in [0,1,3,4,5])
	g.sound.tick(.02,true,false);checks.normal_music_resumes=g.sound.lead.playing and not g.sound.boss_melody.playing
	g.enter_realm(3);g.set_physics_process(false);g.set_process(false);g.update.tick(.1)
	checks.final_cleanup=not is_instance_valid(g.update.magnet_node)
	checks.final_health=g.enemies[0].maxHp==360000 and g.enemies[0].height==42 and g.enemies[0].speed<=.22
	print("HERMES_REVIEW "+JSON.stringify(checks));g.get_tree().quit(0 if checks.values().all(func(v):return v) else 1)

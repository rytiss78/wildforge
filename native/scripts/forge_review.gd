extends RefCounted

static func capture(g,name: String) -> bool:
	for i in range(4): await g.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return g.get_viewport().get_texture().get_image().save_png("user://forge-"+name+".png")==OK

static func run(g):
	if DisplayServer.get_name()=="headless": g.get_tree().quit(1);return
	AudioServer.set_bus_volume_db(0,-80)
	# Exercise the real start button before the deterministic rendering fixture.
	g.hud.menu_start.pressed.emit()
	var checks={"start_button":g.run_active}
	g.start_run(407);g.invulnerable=1000;g.spawn_clock=99999;g.xp_target=100000
	for i in range(180): await g.get_tree().process_frame
	g.set_physics_process(false)
	checks.camera_defaults=g.camera.fov==70 and g.camera_distance==12 and is_equal_approx(g.pitch,.3) and not g.camera_locked
	var camera_state={"fov":g.camera.fov,"distance":g.camera_distance,"pitch":g.pitch,"yaw":g.yaw}
	var grove=g.world.get_node("Landmark_0")
	var trunk=grove.get_child(1)
	var center=trunk.global_position+Vector3.UP*2
	var collision=g.world.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(center+Vector3.LEFT*4,center+Vector3.RIGHT*4,1))
	checks.natural_trunk_collision=not collision.is_empty() and collision.collider.get_meta("natural_obstacle",false)
	# Controlled actors use the real spawner and runtime assets, not preview-only meshes.
	for enemy in g.enemies: enemy.node.queue_free()
	g.enemies.clear()
	for i in range(6):
		g.spawn_enemy(12+i*2)
		if not g.enemies.is_empty():
			var enemy=g.enemies[-1];enemy.node.position=Vector3((i-2.5)*2.3,0,-9-absf(i-2.5)*2)
			enemy.node.position.y=g.world.height_at(enemy.node.position.x,enemy.node.position.z)
			enemy.node.look_at(Vector3(g.player.position.x,enemy.node.position.y,g.player.position.z))
	g.spawn_enemy(29,true)
	var boss=g.enemies.filter(func(e):return e.boss)
	checks.boss_orb=not boss.is_empty() and boss[0].node.get_meta("rig").solid.core_material!=null and not boss[0].node.has_meta("boss_hp_bar")
	if not boss.is_empty():
		boss[0].node.position=Vector3(0,g.world.height_at(0,-29),-29)
		boss[0].node.look_at(Vector3(g.player.position.x,boss[0].node.position.y,g.player.position.z))
	# Preserve normal camera placement; allow it to settle at the player's anchor.
	for i in range(90): await g.get_tree().process_frame
	var harvest=g.harvestables.filter(func(h):return h.biome==0)[0]
	harvest.node.position=Vector3(-3,g.world.height_at(-3,-3),-3)
	checks.scene=await capture(g,"scene")
	checks.orb_states=true
	for entry in [[.5,"half"],[.15,"low"],[0.0,"empty"]]:
		g.hp=g.stats.maxHp*entry[0];g.update_hero_vitals()
		g.avatar.solid.set_health(entry[0],true)
		for enemy in g.enemies:
			enemy.hp=enemy.maxHp*entry[0];var rig=enemy.node.get_meta("rig")
			# Cartoon creatures (October 25) carry their orb themselves; bosses keep StyleModel.
			if rig is CartoonCreatureRig: rig.set_health(entry[0]);rig.orb_fill=entry[0];rig.orb_paint.set_shader_parameter("fill",entry[0])
			else: rig.solid.set_health(entry[0],true)
		checks.orb_states=checks.orb_states and is_equal_approx(float(g.avatar.solid.core_material.get_shader_parameter("fill")),entry[0])
		checks[entry[1]]=await capture(g,entry[1])
	g.hp=g.stats.maxHp;g.update_hero_vitals();g.avatar.set_defense(6,2,2)
	checks.hero_shield=not g.avatar.solid.armour_shells.is_empty() and g.avatar.solid.armour_shells[0].visible
	# Serialize the host snapshot, apply it as a different client, then exercise avatar ticking.
	var host_id=g.coop.local_id;var original_stats=g.stats.duplicate(true)
	g.hp=g.stats.maxHp*.5;g.stats.armor=6;g.stats.shield=2;g.shield_hp=1
	var packet=bytes_to_var(var_to_bytes(g.coop.snapshot()))
	checks.compact_snapshot=not packet.players[host_id].has("stats")
	g.coop.local_id=98765;g.coop.apply_world(packet);g.coop.active=true;g.coop.tick(0);g.coop.active=false
	var remote=g.coop.avatars[host_id].get_meta("rig").solid
	checks.remote_half_hp=is_equal_approx(remote.fill,.5)
	checks.remote_shield=not remote.armour_shells.is_empty() and remote.armour_shells[0].visible
	g.coop.avatars[host_id].position=g.player.position+Vector3(2,0,-1)
	g.coop.avatars[host_id].rotation.y=PI
	remote.animate(1,0,true)
	checks.remote_capture=await capture(g,"remote-half")
	for fraction in [.15,0.0,1.0]:
		packet.players[host_id].hp=original_stats.maxHp*fraction
		g.coop.apply_world(packet);g.coop.active=true;g.coop.tick(0);g.coop.active=false
		checks["remote_hp_"+str(fraction)]=is_equal_approx(remote.fill,fraction)
	g.coop.avatars[host_id].queue_free();g.coop.avatars.erase(host_id);g.coop.members.erase(host_id);g.coop.local_id=host_id
	g.stats=original_stats;g.hp=g.stats.maxHp;g.shield_hp=0;g.update_hero_vitals()
	for enemy in g.enemies: enemy.hp=enemy.maxHp
	if not g.enemies.is_empty(): g.hurt_enemy(g.enemies[0],42,"crit")
	g.hud.update(0);checks.damage=await capture(g,"damage")
	checks.actual_critical=g.damage_numbers.any(func(d):return d.cause=="crit")
	var offers=[]
	for id in ["jump-boots-item","augment-air-damage","augment-dash-rate"]:
		var item=g.rules.loot_by_id[id].duplicate(true);item.tier=1;item.strength=1;offers.append(item)
	g.offers=offers;g.hud.show_offers(offers,"level",false)
	checks.reward=await capture(g,"reward")
	g.hud.controller_move(Vector2.RIGHT)
	checks.reward_focus=g.hud.cards[1].has_focus()
	var result={"checks":checks,"camera":camera_state,"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC),"nodes":g.get_tree().get_node_count(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
	print("FORGE_REVIEW "+JSON.stringify(result));g.get_tree().quit(0 if not checks.values().has(false) else 1)

extends RefCounted

static func capture(g,name: String) -> bool:
	for i in range(5): await g.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return g.get_viewport().get_texture().get_image().save_png("user://red-moon-"+name+".png")==OK

static func clear(list):
	for item in list:
		if is_instance_valid(item.node): item.node.queue_free()
	list.clear()

static func run(g):
	AudioServer.set_bus_volume_db(0,-80)
	g.set_physics_process(false)
	var checks={}
	# Exercise the visible selector, rebuild it, then change selection again.
	g.hud.start_menu()
	for id in ["ninja","smoker","alcoholic","white-supra"]:
		var hero=g.rules.data.heroes.filter(func(h):return h.id==id)[0]
		g.hud.menu_controls().filter(func(c):return c is Button and c.text==hero.name)[0].pressed.emit()
		for i in range(4): await g.get_tree().process_frame
		checks["selection_"+id]=g.hero.id==id and is_instance_valid(g.hud.portrait.preview_actor)
		checks["portrait_"+id]=await capture(g,id)
		checks["scale_"+id]=is_equal_approx(g.avatar.scale.y,hero.height/1.65)
		var shape=g.player.get_child(0).shape
		checks["collider_"+id]=is_equal_approx(shape.size.y if shape is BoxShape3D else shape.height,hero.height)
	g.hud.start_menu(true)
	g.hud.menu_controls().filter(func(c):return c is Button and c.text=="Ninja")[0].pressed.emit()
	g.start_run(407);g.invulnerable=1000;g.spawn_clock=99999;g.xp_target=100000
	g.set_physics_process(false);g.set_process(false)
	for i in range(160):
		g._process(.016);await g.get_tree().process_frame
	clear(g.enemies);clear(g.projectiles);clear(g.effects)
	checks.camera=g.camera_distance==12 and g.camera.fov==70 and is_equal_approx(g.pitch,.3)
	g.yaw=PI*.5;g.dash_cooldown=0;Input.action_press("move_back");g.dash();Input.action_release("move_back")
	checks.dash_back=g.dash_direction.dot(Vector3.RIGHT)>.99
	var locked=g.dash_direction;g.direction=Vector3.FORWARD
	checks.dash_locked=g.dash_direction==locked
	g.yaw=0;g.dash_cooldown=0;Input.action_press("move_left");g.dash();Input.action_release("move_left")
	checks.dash_left=g.dash_direction.dot(Vector3.LEFT)>.99
	g.dash_time=0;g.equipped.clear();g.stats.dodge=0;g.stats.armor=0;g.shield_hp=0
	g.spawn_enemy(9);var enemy=g.enemies[-1];enemy.damage=1;enemy.biome=0;enemy.freeze=999;enemy.contact=999
	g.player.position=Vector3(0,g.world.height_at(0,0)+.1,0)
	preload("res://scripts/combat_tactics.gd").ranged_attack(g,enemy,g.player.position)
	# One mark per shot since October 25 (three filled the ground).
	checks.readable_ranged=g.hazards.size()==1 and g.hazards[0].life>=1.0
	var hp=g.hp;g.invulnerable=0;g.update_combat(1.1)
	checks.ranged_damage=g.hp<=hp-23
	clear(g.hazards);g.invulnerable=0;hp=g.hp
	preload("res://scripts/combat_tactics.gd").ranged_attack(g,enemy,g.player.position)
	g.player.position+=Vector3.FORWARD*6;g.update_combat(1.5)
	checks.ranged_dodge=is_equal_approx(hp,g.hp)
	clear(g.hazards);clear(g.enemies);clear(g.effects)
	g.player.position=Vector3(0,g.world.height_at(0,0)+.1,0)
	for i in range(120):g._process(.016)
	g.hud.update(0);checks.field=await capture(g,"field")
	# Use the third-world portal's real interaction entry point.
	g.enter_realm(2);g.events.guardian_defeated=true;g.Journey.activate(g)
	checks.portal=g.realm==3 and g.enemies.size()==1 and not g.gate.visible
	var arena_spawn=g.player.position;g.player.position=g.gate_position
	checks.hidden_portal_no_hint=not g.interaction_hint().contains("PORTAL")
	g.interact();checks.hidden_portal_no_travel=g.realm==3
	g.player.position=arena_spawn
	var boss=g.enemies[0]
	checks.final_identity=boss.boss_id==8 and boss.height==BossBook.entry(8).height and is_equal_approx(boss.speed,BossBook.entry(8).speed) and is_equal_approx(boss.maxHp,(preload("res://scripts/final_arena.gd").TARGET_SECONDS*preload("res://scripts/final_arena.gd").REFERENCE_DPS*preload("res://scripts/final_arena.gd").HEALTH_MULTIPLIER))
	checks.arena_cracks=g.events.final_cracks.size()==32 and g.events.final_cracks.all(func(crack):return is_instance_valid(crack) and crack.mesh is BoxMesh and crack.is_inside_tree())
	checks.entrance_darkened=is_equal_approx(g.world.environment.ambient_light_energy,.12) and is_equal_approx(g.world.environment.adjustment_brightness,.68) and boss.node.scale.x<.1
	for frame in range(20):
		g._process(.016);g.Journey.tick(g);await g.get_tree().process_frame
		if not g.world.build_in_progress:break
	g.hud.update(0)
	checks.entrance_capture=await capture(g,"baron-entrance")
	g.invulnerable=1000;g.equipped.clear();g.spawn_clock=99999
	for i in range(110):
		g._process(.016);g.Journey.tick(g);await g.get_tree().process_frame
	checks.entrance_midpoint=g.events.final_intro and boss.node.scale.x>.1 and boss.node.scale.x<.9
	checks.rising_capture=await capture(g,"baron-rising")
	for i in range(130):
		g._process(.016);g.Journey.tick(g);await g.get_tree().process_frame
	checks.entrance_rise=not g.events.final_intro and is_equal_approx(boss.node.scale.x,1.0) and is_equal_approx(g.world.environment.ambient_light_energy,.36) and is_equal_approx(g.world.environment.adjustment_brightness,1.0)
	g.hud.update(0);checks.arena=await capture(g,"arena")
	# Inspect the full authored silhouette with an ordinary player-controlled look angle.
	g.player.position=Vector3(0,g.world.height_at(0,46),46);g.pitch=0
	for i in range(80):g._process(.016);await g.get_tree().process_frame
	checks.silhouette=await capture(g,"silhouette")
	var minimum=Vector3(INF,INF,INF);var maximum=Vector3(-INF,-INF,-INF)
	for mesh in boss.node.get_meta("rig").model.find_children("*","MeshInstance3D",true,false):
		var bounds=mesh.mesh.get_aabb()
		for corner in range(8):
			var point=mesh.global_transform*bounds.get_endpoint(corner)
			minimum=minimum.min(point);maximum=maximum.max(point)
	# The Grand Noggin: the floating head, its posed parts and three phase paints.
	checks.authored_giant=maximum.y-minimum.y>14 and maximum.x-minimum.x>8
	var colossus=boss.node.get_meta("rig")
	# The floating head (October 26): two hands, two eyes that are its health orbs
	# sharing one liquid, and a jaw.
	checks.baron_model=colossus is ColossusRig and colossus.hands.size()==2 and colossus.eyes.size()==2 and colossus.eyes.all(func(e):return e.material_override==colossus.orb_paint) and colossus.parts.has("jaw")
	checks.steam_budget=colossus.skins.size()==3 and colossus.find_child("GlassCore",true,false)!=null
	g.player.position=Vector3(0,g.world.height_at(0,28),28);g.pitch=.3
	checks.small_map=g.world.shore_radius(Vector3.ZERO)==72 and g.hud.map_view.map_extent==85
	var counts=[]
	for i in range(4):
		clear(g.hazards);BossBook.attack(g,boss);counts.append(g.hazards.size())
		checks["attack_"+str(i)]=await capture(g,"attack-"+str(i))
	# The Colossus (October 24): each attack is an action with its own red marks.
	checks.attack_patterns=counts.all(func(c):return c>=5)
	checks.deadly_warnings=g.hazards.all(func(h):return h.damage>=45 and h.duration>=.8 and Vector2(h.node.position.x,h.node.position.z).length()<=60.1)
	checks.terrain_marks=preload("res://scripts/boss_review.gd").marks_follow_terrain(g)
	clear(g.hazards);preload("res://scripts/final_arena.gd").erupt(g)
	checks.arena_eruption=g.hazards.size()==10 and g.hazards.all(func(h):return h.style=="lava" and h.damage==48 and h.duration==2.6 and Vector2(h.node.position.x,h.node.position.z).length()<=64.1)
	checks.eruption_capture=await capture(g,"arena-eruption")
	clear(g.hazards)
	var actor=bytes_to_var(var_to_bytes(g.coop.actor_descriptor(boss)))
	var remote=g.spawn_network_enemy(actor)
	checks.network_boss=remote.boss_id==8 and remote.maxHp==boss.maxHp and remote.node.get_meta("rig").identity=="boss_8"
	remote.node.queue_free();g.enemies.erase(remote)
	clear(g.hazards)
	# It walks the hero down (the Baron stood almost still), then real attack resolution.
	boss.freeze=0;boss.attack=999;boss.recovery=0;var start=boss.node.position
	for i in range(120):
		await g.get_tree().physics_frame;g.update_combat(1.0/60);g._process(1.0/60)
	checks.walks_toward_hero=Vector2(boss.node.position.x-start.x,boss.node.position.z-start.z).length()>.6
	boss.freeze=999;g.hp=500;g.invulnerable=0
	g.warn_at(g.player.position,3.4,1.6,120,"annihilation");g.update_combat(1.7)
	checks.deadly_impact=is_equal_approx(g.hp,380)
	checks.lance_capture=await capture(g,"lance-impact")
	g.hp=g.stats.maxHp;g.invulnerable=0
	g.warn_at(g.player.position,3.4,1.6,120,"annihilation");g.player.position+=Vector3.RIGHT*9;g.update_combat(1.7)
	checks.deadly_attack_dodge=is_equal_approx(g.hp,g.stats.maxHp)
	# Huge enemies must remain targetable by weapons with short ranges.
	var test_origin=boss.node.position+Vector3(18,1,0)
	checks.giant_surface_target=g.nearest_enemy(test_origin,24).get("net_id",-1)==boss.net_id
	g.player.position=boss.node.position+Vector3(10,1,0)
	checks.short_range_target=g.nearest_enemy(g.player.position,9).get("net_id",-1)==boss.net_id
	var gun=g.rules.data.weapons.filter(func(w):return w.id=="gun")[0].duplicate(true);gun.kind="weapon";gun.strength=1;gun.tier=0;g.equip_weapon(gun)
	var before_shot=boss.hp;g.fire(g.equipped[-1],g.player.position+Vector3.UP*.9)
	checks.giant_weapon_fires=not g.projectiles.is_empty()
	for i in range(90):g.update_combat(1.0/60)
	checks.giant_weapon_hits=boss.hp<before_shot
	g.equipped.clear();clear(g.projectiles);g.invulnerable=1000
	# Cross both phase thresholds with real damage: the body takes the ice, then fire skin.
	var rig=boss.node.get_meta("rig")
	checks.roar_asset=rig.roar_player.stream!=null and rig.roar_player.stream.get_length()>1.0
	var phase_checks=[]
	for step in [[1,.6],[2,.25]]:
		boss.open_until=-1;g.hurt_enemy(boss,boss.hp-boss.maxHp*float(step[1]),"shot")
		phase_checks.append(ColossusFight.phase(boss)==step[0] and rig.phase_index==step[0] and rig.parts.head.mesh==ColossusRig.group(step[0],"head") and rig.orb_paint.get_shader_parameter("liquid_color")==ColossusRig.ORB_COLORS[step[0]])
	checks.phase_voices=phase_checks.size()==2 and phase_checks.all(func(value):return value)
	# Calibrate health with real damage application; no mandatory five-minute invulnerability.
	boss.open_until=-1;var original_hp=boss.hp;g.hurt_enemy(boss,300,"shot");checks.reference_dps=is_equal_approx(original_hp-boss.hp,300)
	g.hurt_enemy(boss,boss.hp+1000,"shot")
	checks.death_eclipse=g.events.get("final_defeated",false) and g.events.get("eclipse",false) and g.mode=="playing"
	checks.baron_fall_event=g.events.get("final_ceremony",false) and g.events.announcement=="THE NOGGIN FALLS"
	g.realm_time=float(g.events.get("final_ceremony_until",0))+.01;g.Journey.tick(g)
	checks.eclipse_transition=not g.events.get("final_ceremony",true) and g.events.announcement=="ENDLESS ECLIPSE" and int(g.events.eclipse_stage)>=1 and g.events.final_cracks.all(func(crack):return crack.material_override.emission.g>.5)
	g.realm_time=660;g.Journey.tick(g)
	checks.endless=g.events.eclipse and g.events.eclipse_stage>=20 and g.events.wave_budget>0
	g.spawn_enemy(15);checks.new_corruption=g.enemies[-1].get("corruption",0)==g.events.eclipse_stage
	g.Journey.activate(g);checks.no_exit=g.realm==3 and g.mode=="playing"
	for i in range(90):g._process(.016)
	g.hud.update(0);checks.eclipse=await capture(g,"eclipse")
	print("RED_MOON_REVIEW "+JSON.stringify({"checks":checks,"attack_counts":counts,"authored_size":CoopSession.array(maximum-minimum),"reference_seconds":(preload("res://scripts/final_arena.gd").TARGET_SECONDS*preload("res://scripts/final_arena.gd").REFERENCE_DPS*preload("res://scripts/final_arena.gd").HEALTH_MULTIPLIER)/1200.0,"timing_note":"Solo Colossus HP = 300 s x 300 dps x HEALTH_MULTIPLIER (37.5 since October 24, 7.5 before that, 6 since Phase D; 4 was the requested fourfold). Representative builds still need playtesting."}))
	g.get_tree().quit(0 if not checks.values().has(false) else 1)

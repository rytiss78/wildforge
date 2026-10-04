extends RefCounted

static func run(game: Node3D):
	AudioServer.set_bus_volume_db(0,-80)
	game.select_hero(game.rules.data.heroes.filter(func(h):return h.id=="bathtub")[0])
	game.start_run(407);game.set_physics_process(false);game.set_process(false);game.mode="playing"
	var checks={"starts_with_shield":game.shield_hp==25}
	var signatures=[];var perks=[];var rigs=[]
	var viewport=SubViewport.new();viewport.size=Vector2i(1920,1080);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;game.add_child(viewport)
	var stage=Node3D.new();viewport.add_child(stage)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("e4e8ce");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color("fff2d7");env.environment.ambient_light_energy=.6;stage.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-25,0);sun.light_energy=.9;stage.add_child(sun)
	var camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=17;stage.add_child(camera)
	var valid=true;var cores=true
	for i in range(game.rules.data.heroes.size()):
		var hero=game.rules.data.heroes[i];var stats=game.rules.data.stats.duplicate(true);game.rules.apply_effects(stats,hero.effects)
		valid=valid and not hero.effects.is_empty() and not hero.description.is_empty() and not hero.perk.is_empty()
		for effect in hero.effects: valid=valid and stats.has(effect.key) and stats[effect.key]>game.rules.data.stats[effect.key]
		signatures.append(hero.effects[0].key);perks.append(hero.perk)
		var rig=ActorRig.new();rig.setup(hero.model);stage.add_child(rig);rig.position=Vector3((i%7-3)*2.25,(2-i/7)*2.4,0)
		rig.set_health(.75);rig.set_defense(stats.armor,stats.shield,stats.shield);rig.animate(.2,Vector3.ZERO,true)
		cores=cores and rig.solid!=null and rig.solid.core_materials.size()==1 and rig.solid.armour_shells.size()==1
		var core=rig.solid.model.find_child("GlassCore",true,false)
		cores=cores and core!=null and core.mesh.get_aabb().size.y>.5
		var label=Label3D.new();label.text=hero.name+"\n"+hero.perk;label.font_size=25;label.pixel_size=.009;label.position=Vector3(0,-.18,-.55);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;rig.add_child(label);rigs.append(rig)
	checks.all_21_have_working_bonuses=valid and rigs.size()==21
	checks.distinct_primary_perks=signatures.size()==21 and signatures.all(func(key):return signatures.count(key)==1) and perks.all(func(key):return perks.count(key)==1)
	checks.all_21_body_orbs=cores
	game.hp=game.stats.maxHp*.4;game.update_hero_vitals();game.avatar.animate(.3,Vector3.ZERO,true)
	checks.blood_tracks_health=is_equal_approx(game.avatar.solid.fill,.4)
	game.shield_hp=12.5;game.update_hero_vitals()
	checks.blue_shield_tracks_damage=is_equal_approx(float(game.avatar.solid.armour_materials[0].get_shader_parameter("shield_fill")),.5)
	game.shield_hp=0;game.update_hero_vitals()
	checks.no_shield_no_coating=not game.avatar.solid.armour_shells[0].visible
	game.stats.armor=6;game.update_hero_vitals()
	checks.armour_coating_visible=game.avatar.solid.armour_shells[0].visible and float(game.avatar.solid.armour_materials[0].get_shader_parameter("armour"))>0
	game.hud.update(0)
	checks.no_hud_hp_or_armour=not game.hud.status.text.contains("♥") and game.hud.root.find_children("*","ProgressBar",true,false).size()==1
	# Roll Ronin's critical bonus must work with the starting Saw.
	game.stats.crit=1;game.stats.critPower=2;game.stats.burn=0;game.stats.poison=0;game.stats.chain=0;game.stats.splash=0
	game.clear_entities();game.spawn_enemy(6);var enemy=game.enemies[0];enemy.node.position=game.player.position+Vector3(0,0,-6);enemy.hp=1000;enemy.maxHp=1000
	game.melee_attacks.append({"origin":game.player.position+Vector3.UP*.9,"target":game.enemy_center(enemy),"aim":Vector3.FORWARD,"reach":8,"damage":10,"delay":.01});game.update_melee(.02)
	checks.melee_critical_works=is_equal_approx(enemy.hp,980)
	game.stats.poison=8;game.hit_enemy(enemy,{"kind":"gun","damage":1});checks.on_hit_perks_work=enemy.poison==8
	game.stats.multishot=1
	var shotgun=game.rules.data.weapons.filter(func(w):return w.id=="shotgun")[0].duplicate(true);shotgun.power=1.0
	var shot_count=game.projectiles.size();game.fire(shotgun,game.player.position+Vector3.UP*.9)
	checks.octopus_extra_shot=game.projectiles.size()-shot_count==4
	var rng=RandomNumberGenerator.new();rng.seed=407
	var flying_ok=true;var spawn_rates=[]
	for biome in range(6):
		var count=0;var old_weight=0
		for index in CreatureBook.FLYING[biome]: old_weight+=CreatureBook.WEIGHTS[index]
		for sample in range(6000):
			if CreatureBook.pick(biome,rng).flying: count+=1
		var rate=float(count)/6000;spawn_rates.append(rate)
		flying_ok=flying_ok and absf(rate-float(old_weight)/1000)<.009
	checks.ten_times_fewer_flyers=flying_ok
	game.clear_entities()
	var point=Vector3(95,0,55);point.y=game.world.height_at(point.x,point.z)+15
	game.spawn_pickup(point,"xp",7);game.spawn_pickup(point,"gold",13)
	var xp_drop=game.pickups[0];var coin_drop=game.pickups[1]
	for frame in range(30): game.update_pickups(1.0/60)
	checks.xp_falls_from_sky=xp_drop.node.position.y<point.y-1
	for frame in range(330): game.update_pickups(1.0/60)
	checks.both_drops_land=xp_drop.settled and coin_drop.settled and absf(xp_drop.node.position.y-game.world.height_at(xp_drop.node.position.x,xp_drop.node.position.z)-.13)<.001
	checks.xp_keeps_glow=xp_drop.node.material_override.emission_enabled
	game.hud.update(0)
	checks.hud_numbers_labelled=game.hud.coins.text.contains("GOLD") and game.hud.coins.text.contains("BOX PRICE") and game.hud.status.text.begins_with("LEVEL") and game.hud.xp_text.text.begins_with("XP")
	checks.no_black_blood=not rigs[0].solid.core_material.shader.code.contains("tank")
	if DisplayServer.get_name()!="headless":
		camera.position=Vector3(0,5,-16);camera.look_at(Vector3(0,3,0));await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("user://heroes-front-0.7.5.png")
		camera.position=Vector3(0,5,16);camera.look_at(Vector3(0,3,0));await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png("user://heroes-back-0.7.5.png")
		game.camera.position=game.player.position+Vector3(8,5,9);game.camera.look_at(game.player.position+Vector3.UP);game.camera.reset_physics_interpolation();game.player.reset_physics_interpolation()
		await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png("user://hero-hud-0.7.5.png")
		game.hud.start_menu();await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png("user://hero-menu-0.7.5.png")
	viewport.queue_free();game.clear_entities()
	for child in game.sound.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D: child.stop();child.stream=null
	game.sound.active=false;await game.get_tree().create_timer(.3).timeout
	print("HERO_CHECK "+JSON.stringify(checks));game.get_tree().quit(0 if checks.values().all(func(ok):return ok) else 1)

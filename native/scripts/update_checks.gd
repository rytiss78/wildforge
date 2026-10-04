extends RefCounted

static func run(game: Node3D):
	var checks={};game.start_run(407);game.set_physics_process(false);game.set_process(false);game.mode="paused";game.invulnerable=1000
	checks.baseline_air_jumps=game.rules.data.stats.airJumps==0
	game.stats.airJumps=0
	for i in range(3): game.rules.apply_effects(game.stats,[{"key":"airJumps","amount":1}])
	checks.stack_jumps=game.stats.airJumps==3
	var all_heroes=true
	for hero in game.rules.data.heroes:
		var rig=ActorRig.new();game.add_child(rig);rig.setup(hero.model);rig.sync_equipment([{"id":hero.weapon,"rank":1}])
		all_heroes=all_heroes and rig.solid!=null and not rig.illustrated and rig.held.size()==1 and rig.solid.core_materials.size()>=1
		rig.free()
	checks.all_heroes_3d=all_heroes
	var all_creatures=true;var fill_ok=true
	for biome in range(6):
		for index in range(6):
			var rig=ActorRig.new();game.add_child(rig);rig.setup(CreatureBook.entry(biome,index).model);rig.bake_enemy();rig.set_health(.25,true);rig.animate(.5,Vector3.ZERO)
			all_creatures=all_creatures and rig.solid!=null and rig.batched!=null and rig.solid.core_materials.size()==1
			fill_ok=fill_ok and is_equal_approx(float(rig.solid.core_material.get_shader_parameter("fill")),.25) and bool(rig.solid.core_material.get_shader_parameter("tank"))
			rig.set_health(0);fill_ok=fill_ok and float(rig.solid.core_material.get_shader_parameter("fill"))==0
			rig.free()
	checks.all_creatures_3d=all_creatures;checks.blood_readout=fill_ok
	var inventory=game.rules.data.weapons.slice(0,3)
	var legal=true
	for i in range(120):
		var offers=game.rules.offers("weapon",.3,false,game.stats,inventory)
		legal=legal and offers.size()==3 and offers.all(func(item):return inventory.any(func(w):return w.id==item.id))
	checks.full_slots_upgrade_only=legal
	checks.potion_count=PotionBook.TYPES.size()==14
	game.owned.clear();game.stats.luck=1.0
	var drops=game.consumables.size();game.drop_consumable(game.player.position)
	checks.innate_luck_no_drop=game.consumables.size()==drops
	game.owned.append({"effects":[{"key":"luck","amount":.1}]});game.stats.potionChance=1.0
	game.drop_consumable(game.player.position)
	checks.luck_item_drop=game.consumables.size()==drops+1
	var potions_work=true
	for key in PotionBook.TYPES:
		var entry=PotionBook.TYPES[key]
		if entry.key.is_empty(): continue
		potions_work=potions_work and PotionBook.value(entry.key,1.0 if entry.key!="fallGuard" and entry.key!="crit" else 0.0,{key:25})>(1.0 if entry.key!="fallGuard" and entry.key!="crit" else 0.0)
	checks.potion_effects=potions_work
	checks.new_weapons=game.rules.data.weapons.size()==25
	checks.new_cards=game.rules.data.loot.size()==332
	game.clear_entities();game.mode="playing";game.spawn_enemy(12)
	var enemy=game.enemies[0];enemy.node.position=game.player.position+Vector3(0,0,-8);enemy.hp=100000;enemy.maxHp=100000
	game.equipped.clear()
	var weapon_results={}
	for id in ["boomerang","disc","harpoon","gravity","horn","bubble","meteor","bomb"]:
		var weapon=game.rules.data.weapons.filter(func(w):return w.id==id)[0].duplicate(true);weapon.kind="weapon";weapon.strength=1;weapon.tier=0
		game.equip_weapon(weapon);game.fire(game.equipped[-1],game.player.position+Vector3.UP*.9)
		match id:
			"gravity": weapon_results[id]=game.pools.any(func(p):return p.get("gravity",false))
			"meteor": weapon_results[id]=game.hazards.any(func(h):return h.get("friendly",false))
			"horn": weapon_results[id]=enemy.hp<100000
			_: weapon_results[id]=game.projectiles.any(func(s):return s.kind==id)
		game.equipped.clear()
	checks.weapon_mechanics=weapon_results.values().all(func(value):return value)
	var returning=game.projectiles.filter(func(s):return s.kind=="boomerang")[0]
	checks.blade_return=returning.return and returning.pierce>=2
	checks.disc_bounces=game.projectiles.filter(func(s):return s.kind=="disc")[0].bounce>=3
	game.hit_enemy(enemy,{"kind":"bubble","damage":1});checks.bubble_trap=enemy.get("bubble",0)>0
	game.clear_entities();game.spawn_enemy(20,true)
	checks.huge_boss=game.enemies[0].height>=9 and game.enemies[0].radius>=2.8
	game.telegraph(game.enemies[0]);checks.boss_telegraph=game.hazards.size()>=1
	checks.draw_distance=game.camera.far<=230
	checks.character_voices=game.rules.data.heroes.all(func(h):return ResourceLoader.exists("res://assets/voices/hurt_"+h.id+"_0.wav") and ResourceLoader.exists("res://assets/voices/hurt_"+h.id+"_1.wav"))
	checks.weapon_icons=["boomerang","disc","harpoon","gravity","horn","bubble","meteor","bomb"].all(func(id):return ResourceLoader.exists("res://assets/illustrated/weapon-icons/"+id+".png"))
	game.clear_entities();game.select_hero(game.rules.data.heroes[1]);game.mode="playing";game.hud.close();game.hud.update(0)
	game.buffs.clear();game.spawn_clock=999
	if DisplayServer.get_name()!="headless":
		for biome in range(6):
			var point=Vector3.ZERO
			if biome>0:
				var angle=(biome+.5)*TAU/6-float(game.world.seed_value%23)*.03-game.realm*.4
				point=Vector3(cos(angle)*260,0,sin(angle)*260)
			point.y=game.world.height_at(point.x,point.z);game.world.ensure_ground(point)
			game.player.position=point+Vector3.UP*.1
			game.player.reset_physics_interpolation()
			for i in range(16): game.world.stream(point)
			for i in range(90): game.world.weather_tick(.1,point)
			game.current_biome=biome;game.hud.update(0)
			game.camera.position=point+Vector3(8,5,11);game.camera.look_at(point+Vector3.UP)
			game.camera.reset_physics_interpolation()
			await game.get_tree().process_frame;await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
			game.get_viewport().get_texture().get_image().save_png("user://update-biome-%d.png" % biome)
	game.mode="test_finished";game.sound.active=false;game.clear_entities()
	for audio in game.sound.get_children():
		if audio is AudioStreamPlayer or audio is AudioStreamPlayer3D: audio.stop();audio.stream=null
	await game.get_tree().create_timer(.2).timeout
	var report=FileAccess.open("user://update-07-results.json",FileAccess.WRITE);report.store_string(JSON.stringify(checks,"  "));report.close()
	print("UPDATE_07 "+JSON.stringify(checks));game.get_tree().quit(0 if checks.values().all(func(value):return value) else 1)

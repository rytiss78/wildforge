extends RefCounted

static func run(game: Node3D):
	AudioServer.set_bus_volume_db(0,-80)
	game.start_run(407);game.set_physics_process(false);game.set_process(false)
	game.clear_entities();game.equipped.clear();game.spawn_clock=99999;game.invulnerable=10000
	var checks={}
	checks.stronger_colour=game.world.environment.adjustment_saturation>1.1 and game.world.environment.adjustment_contrast>1
	checks.clear_foreground=game.world.environment.fog_mode==Environment.FOG_MODE_DEPTH and game.world.environment.fog_depth_begin>=18
	checks.six_distinct_landmarks=game.world.landmarks.size()==6 and range(6).all(func(i):return game.world.has_node("Landmark_"+str(i)))
	checks.skill_art_not_guns=game.rules.data.loot.all(func(item):
		var texture=IllustratedIcons.texture(item.effects[0].key)
		return texture is AtlasTexture and (texture.atlas==IllustratedIcons.skill_atlas or texture.region.position.y>=256)
	)
	game.mode="offer";game.offer_source="level";game.offer_kind="skill";game.offer_rerolls=0;game.gold=1000
	game.offers=game.rules.offers("skill",0,false,game.stats);game.hud.show_offers(game.offers,"level")
	checks.card_animation=game.hud.cards[0].scale.x<1
	var previous_ids=game.offers.map(func(item):return item.id);var price=game.reroll_price()
	game.reroll_offers()
	checks.reroll_paid_once=game.gold==1000-price and game.offer_rerolls==1 and game.reroll_price()>price
	checks.reroll_new_cards=game.offers.size()==3 and game.offers.all(func(item):return not previous_ids.has(item.id))
	game.gold=0;var unchanged=game.offers.duplicate(true);game.reroll_offers()
	checks.no_unaffordable_reroll=game.gold==0 and game.offers==unchanged and game.offer_rerolls==1
	game.hud.cards[1].grab_focus();var focused=game.hud.cards[1];game.input_kind="xbox";game.hud.update(0)
	checks.device_switch_preserves_focus=game.hud.cards[1]==focused and game.get_viewport().gui_get_focus_owner()==focused
	await game.get_tree().create_timer(.75).timeout
	checks.card_animation_finishes=game.hud.cards.all(func(card):return card.scale.is_equal_approx(Vector2.ONE))
	checks.flip_sound=game.sound.cache.has("ui_card")
	for key in ["burn","poison","freeze","armor","goldGain","flowerPower"]: game.sound.choose_power(key)
	checks.family_sounds=game.sound.cache.has("ui_fire") and game.sound.cache.has("ui_poison") and game.sound.cache.has("ui_ice") and game.sound.cache["ui_fire"].data!=game.sound.cache["ui_ice"].data
	game.sound.settings.sfx=0;game.sound.weapon_loop("saw",true,game.player.position)
	checks.muted_loop_safe=not game.sound.weapon_loops.has("saw");game.sound.settings.sfx=.65
	for id in ["gun","shotgun","ice"]:
		var item=game.rules.data.weapons.filter(func(w):return w.id==id)[0].duplicate(true);item.kind="weapon";item.strength=1;item.tier=0;game.equip_weapon(item)
	game.gold=1000;game.offer_kind="weapon";game.offer_rerolls=0;game.offers=game.rules.offers("weapon",0,false,game.stats,game.equipped)
	game.reroll_offers()
	checks.full_slots_only_upgrade=game.equipped.size()==3 and game.offers.all(func(item):return game.equipped.any(func(w):return w.id==item.id))
	var upgrade=game.equipped[2].duplicate();upgrade.strength=1;game.equip_weapon(upgrade)
	checks.third_hand_thumbs_up=game.avatar.thumb_clock>0 and is_instance_valid(game.avatar.thumb_glove) and not game.avatar.held[2].visible
	game.avatar.animate(.8,Vector3.ZERO,true)
	checks.third_hand_restores_weapon=game.avatar.held[2].visible and not is_instance_valid(game.avatar.thumb_glove)
	game.hud.close();game.gold=1000;game.make_chest(Vector3(12,0,0),false);game.buy_chest(game.chests[-1])
	checks.chest_sneeze=game.pickups.filter(func(item):return item.kind=="gold" and item.value==1).size()==4 and game.sound.cache.has("effect_sneeze")
	var gun=game.equipped[0].duplicate()
	game.clear_entities();game.equipped.clear();game.hud.close();game.stats.thorns=12;game.stats.auraDamage=0;game.spawn_enemy(20)
	var enemy=game.enemies[0];enemy.freeze=5;enemy.flying=false;enemy.behavior="chase";enemy.hp=1000;enemy.maxHp=1000
	game.player.position=Vector3(0,.3,0);enemy.node.position=Vector3(enemy.radius+.6,.15,0)
	await game.get_tree().physics_frame
	for frame in range(66): game.update_combat(1.0/60);await game.get_tree().physics_frame
	checks.thorns_matches_perk=is_equal_approx(1000-enemy.hp,36)
	game.stats.thorns=0;var before_hp=enemy.hp;var center=game.enemy_center(enemy)
	var bullet=MeshInstance3D.new();bullet.mesh=game.orb_mesh;game.add_child(bullet);bullet.position=center-Vector3.RIGHT*5
	game.projectiles.append({"node":bullet,"velocity":Vector3.RIGHT*600,"damage":1.0,"life":1.0,"kind":"gun","hit":[],"hit_radius":.1,"pierce":0,"bounce":0,"return":false,"return_clock":0.0})
	game.update_combat(1.0/60)
	checks.fast_bullet_hits=is_equal_approx(before_hp-enemy.hp,1)
	game.projectiles.clear();game.stats.range=36;enemy.node.position=Vector3(40,game.world.height_at(40,0),0)
	var baseline=gun.range/game.stats.projectileSpeed+.25
	game.fire(gun,game.player.position+Vector3.UP)
	checks.range_extends_flight=not game.projectiles.is_empty() and game.projectiles[-1].life>baseline*1.5
	game.clear_entities();game.stats.range=18;game.stats.thorns=0
	if DisplayServer.get_name()!="headless":
		for biome in range(6):
			var p: Vector3=game.world.landmarks[biome]
			for x in range(-1,2):
				for z in range(-1,2): game.world.ensure_ground(p+Vector3(x*64,0,z*64))
			game.player.position=p+Vector3(0,1.8,0);game.world.weather_tick(20,p);game.current_biome=biome
			game.camera.position=p+Vector3(24,16,33);game.camera.look_at(p+Vector3(0,10,-7));game.hud.update(0)
			await game.get_tree().process_frame;await RenderingServer.frame_post_draw
			game.get_viewport().get_texture().get_image().save_png("user://landmark-"+str(biome)+".png")
		game.mode="offer";game.offer_kind="skill";game.offer_rerolls=0;game.gold=123
		game.offers=[game.rules.roll("skill",0,1),game.rules.roll("skill",0,2),game.rules.roll("skill",0,3)]
		game.hud.show_offers(game.offers,"level");game.hud.update(0);await game.get_tree().create_timer(.75).timeout;await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png("user://new-skill-cards.png")
	print("VISUAL_UPDATE_CHECK "+JSON.stringify(checks))
	game.clear_entities();game.sound.active=false
	for child in game.sound.get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer3D: child.stop();child.stream=null
	await game.get_tree().create_timer(.3).timeout
	game.get_tree().quit(0 if checks.values().all(func(ok):return ok) else 1)

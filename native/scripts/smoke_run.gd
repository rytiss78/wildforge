extends RefCounted

# The headless smoke run (--smoke): menus, a run through every map and the
# systems along the way, reported as NATIVE_SMOKE {json}. Moved out of game.gd;
# `g` is the game.
static func run(g):
	await g.get_tree().process_frame
	var rebuilt_menu=is_instance_valid(g.hud.menu_start) and g.hud.menu_start.is_visible_in_tree()
	g.input_kind="xbox";g.hud.menu_start.grab_focus();g.hud.controller_move(Vector2.DOWN);g.hud.controller_move(Vector2.DOWN)
	var navigated=g.get_viewport().gui_get_focus_owner()!=g.hud.menu_start
	var focused_before=g.get_viewport().gui_get_focus_owner()
	var idle_mouse=InputEventMouseMotion.new();idle_mouse.relative=Vector2(5,3);g._input(idle_mouse)
	var pointer_safe=g.input_kind=="xbox" and g.get_viewport().gui_get_focus_owner()==focused_before
	var confirm=InputEventJoypadButton.new();confirm.button_index=JOY_BUTTON_A;confirm.pressed=true;g._input(confirm)
	var accepted=g.mode=="career"
	g.hud.start_menu();g.input_kind="keyboard";await g.get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		g.get_viewport().get_texture().get_image().save_png("user://native-menu.png")
	g.start_run()
	g.invulnerable=1000
	await g.get_tree().create_timer(2).timeout
	var checks = {"native":true,"initial_enemies":g.enemies.size(),"weapon_slots":g.equipped.size(),"chests":g.chests.size(),"first_price":g.rules.chest_price(0),"rarities":g.rules.data.loot.size(),"achievements":g.career.achievements.size(),"xp_target":g.xp_target,"realm":g.realm,"paid_count":g.paid_chests}
	checks.main_menu=rebuilt_menu
	checks.xbox_navigation=navigated;checks.xbox_accept=accepted;checks.pointer_focus_safe=pointer_safe
	checks.hero_roster=g.rules.data.heroes.size()==20 and g.rules.data.heroes.all(func(h):return CartoonHeroes.has("count_duck" if h.model=="rubber_duck_toy" else "hero_"+h.model))
	# Every biome's ten cartoon species build as one merged mesh (CartoonBook).
	checks.enemy_roster=range(RealmWorld.BIOME_COUNT).all(func(b):return range(CreatureBook.WEIGHTS.size()).all(func(s):return CartoonBook.get_model(b,s).mesh.get_surface_count()==1))
	checks.painted_terrain=range(6).all(func(i):return ResourceLoader.exists("res://assets/illustrated/terrain-%d.png" % i))
	checks.painted_weapons=g.rules.data.weapons.all(func(w):return ResourceLoader.exists("res://assets/illustrated/weapon-icons/"+w.id+".png"))
	checks.opaque_ui=is_equal_approx(g.hud.style(Color(0,0,0,.2)).bg_color.a,1.0)
	var _gun_tex=IllustratedIcons.texture("gun",true)
	checks.illustrated_icons=(_gun_tex is AtlasTexture and _gun_tex.atlas.get_width()==768) or (_gun_tex is Texture2D and _gun_tex.get_width() in [128, 256, 768])
	g.yaw=0;g.pitch=0
	var before_yaw=g.yaw
	g.camera_look(Vector2(.12,.08))
	checks.camera_look=g.yaw<before_yaw and g.pitch>0
	g.mode="paused"
	before_yaw=g.yaw
	g.camera_look(Vector2(.2,.2))
	checks.menu_blocks_look=is_equal_approx(g.yaw,before_yaw)
	g.mode="playing"
	g.yaw=0;g.pitch=0
	var starter=g.equipped[0].duplicate(true)
	g.equip_weapon(starter)
	g.hud.weapons.refresh()
	checks.weapon_rank=g.equipped[0].rank==2 and g.hud.weapons.get_child_count()==RunRules.WEAPON_CAP
	var weapon_desc_ok = true
	for w in g.rules.data.weapons:
		if w.get("archetype"):
			var item = ContentExpansion.weapon(w.id)
			if not item.has("description") or item.description == "": weapon_desc_ok = false
			if not WeaponDetails.MECHANICS.has(item.archetype): weapon_desc_ok = false
		else:
			if not WeaponDetails.MECHANICS.has(w.id): weapon_desc_ok = false
	checks.weapon_mechanics = weapon_desc_ok
	var motion=InputEventMouseMotion.new()
	motion.relative=Vector2(10,5)
	g.dragging=true
	g._input(motion)
	checks.mouse_camera=g.yaw<0 and g.pitch>0
	g.dragging=false;g.yaw=0;g.pitch=0
	var pad_event=InputEventJoypadMotion.new()
	pad_event.axis=JOY_AXIS_RIGHT_X;pad_event.axis_value=.6
	g._input(pad_event)
	checks.xbox_prompts=g.input_kind=="xbox"
	g.input_kind="keyboard"
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		g.get_viewport().get_texture().get_image().save_png("user://native-gameplay.png")
	g.gold=1000
	var chest=g.chests[0]
	g.buy_chest(chest)
	checks.paid_once = g.paid_chests==1 and g.gold==970 and g.offers.size()==5
	if DisplayServer.get_name()!="headless":
		g.hud.chest_reveal(3,.6)
		await RenderingServer.frame_post_draw
		g.hud.chest_reveal(3,.6)
		await RenderingServer.frame_post_draw
		g.get_viewport().get_texture().get_image().save_png("user://native-chest.png")
	var skip_reveal=InputEventAction.new();skip_reveal.action="jump";skip_reveal.pressed=true;g._input(skip_reveal)
	checks.reveal_keeps_choice=g.mode=="offer" and g.owned.is_empty() and g.offers.size()==5
	g.input_kind="xbox";g.hud.cards[1].grab_focus();g.hud.cards[0].mouse_entered.emit()
	checks.xbox_reward_focus=g.get_viewport().gui_get_focus_owner()==g.hud.cards[1]
	# A confirm press right as an offer opens is ignored on purpose (Space/A spam
	# from Block Drop); this check presses after that moment has passed.
	g.hud.offer_guard=0.0
	g._input(confirm)
	checks.xbox_reward_accept=g.owned.size()==1 and g.mode=="playing"
	g.input_kind="keyboard"
	checks.one_item = g.owned.size()==1
	var a=g.rules.data.weapons.filter(func(w):return w.id=="shotgun")[0].duplicate(true)
	a.kind="weapon";a.strength=1.0;a.tier=1
	g.equip_weapon(a)
	a=g.rules.data.weapons.filter(func(w):return w.id=="ice")[0].duplicate(true)
	a.kind="weapon";a.strength=1.0;a.tier=2
	g.equip_weapon(a)
	# Four weapon slots since big update MB: fill the fourth too.
	while g.equipped.size()<RunRules.WEAPON_CAP:
		var extra=g.rules.data.weapons.filter(func(w):return not w.get("turret",false) and w.id!="rocket" and not g.equipped.any(func(e):return e.id==w.id))[0].duplicate(true)
		extra.kind="weapon";extra.strength=1.0;extra.tier=0;g.equip_weapon(extra)
	g.hud.weapons.refresh()
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		g.get_viewport().get_texture().get_image().save_png("user://native-weapons.png")
		g.mode="offer"
		g.offers=g.equipped.duplicate(true)
		g.offer_source="level"
		g.hud.show_offers(g.offers,"level")
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		g.get_viewport().get_texture().get_image().save_png("user://native-cards.png")
		g.input_kind="xbox"
		await g.get_tree().process_frame
		await RenderingServer.frame_post_draw
		g.get_viewport().get_texture().get_image().save_png("user://native-xbox.png")
		g.input_kind="keyboard"
		g.hud.close()
	g.mode="offer"
	g.offers=g.equipped.duplicate(true)
	g.offer_source="level"
	g.hud.show_offers(g.offers,"level")
	g.hud.cards[1].grab_focus()
	await g.get_tree().process_frame
	checks.selection_preview=g.hud.offer_detail.get_child(0).text.ends_with(g.offers[1].name) and g.update.focused_offer==1
	checks.weapon_cards_fit=DisplayServer.get_name()=="headless" or g.hud.offer_layout_fits()
	g.hud.close()
	g.mode="offer"
	g.offers=g.rules.offers("item",1.0,true)
	g.offer_source="chest"
	g.hud.show_offers(g.offers,"chest")
	await g.get_tree().process_frame;await g.get_tree().process_frame;await g.get_tree().process_frame
	checks.item_cards_fit=DisplayServer.get_name()=="headless" or g.hud.offer_layout_fits()
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		g.get_viewport().get_texture().get_image().save_png("user://native-items.png")
	g.hud.close()
	checks.weapon_limit = not g.rules.can_weapon(g.equipped,"rocket") and g.equipped.size()==RunRules.WEAPON_CAP
	checks.key_free = g.rules.free_chance(.3)>.2
	checks.portal_locked = g.realm_bosses<2
	g.career.dirty=true
	g.career.save()
	checks.disk_save = FileAccess.file_exists(g.career.file)
	checks.standalone=not Engine.has_singleton("Steam")
	# Free boss chests preserve the price index and still grant exactly one choice.
	g.mode="playing"
	var before_paid=g.paid_chests
	var before_gold=g.gold
	g.chests[1].free=true
	g.buy_chest(g.chests[1])
	checks.free_price=g.paid_chests==before_paid and g.gold==before_gold and g.offers.size()==5
	g.finish_reveal();g.choose_offer(0)
	# A garden is not a projectile emitter. Test roots, pollen, nectar and chain blooms.
	g.select_hero(g.rules.data.heroes.filter(func(h):return h.id=="florist")[0])
	g.start_run();g.mode="playing";g.invulnerable=1000
	for e in g.enemies: e.node.queue_free()
	g.enemies.clear()
	for i in range(3): g.plant_flower(Vector3(i,0,0),g.equipped[0]);g.flowers[-1].age=2
	g.spawn_enemy(3,true)
	var boss=g.enemies[-1]
	boss.node.position=Vector3(1,0,0)
	g.hp=g.stats.maxHp-10
	var before_hp=g.hp
	var before_boss_hp=boss.hp
	g.last_plant=g.player.position
	g.update_garden(.1)
	checks.garden=g.flowers.size()==3 and boss.hp<before_boss_hp and g.hp>before_hp and boss.slow>0 and boss.poison>0 and g.projectiles.is_empty()
	# The Florist's automatic flower effects are no longer achievements (November 3).
	checks.garden_goals=not g.career.achievements.any(func(a):return a.id in ["WF_BLOOM_CHAIN","WF_FLOWER_BOSS","WF_POLLEN","WF_ROOTS"])
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		boss.node.position=Vector3(4,0,-4)
		await RenderingServer.frame_post_draw
		g.get_viewport().get_texture().get_image().save_png("user://native-florist.png")
	g.gold=123;g.level=4
	g.enter_realm(1)
	checks.realm_preserves=g.realm==1 and g.gold==123 and g.level==4 and g.equipped[0].id=="flowers"
	await g.get_tree().process_frame
	g.enter_realm(2)
	checks.three_realms=g.realm==2 and g.career.data.unlocked.has("WF_THREE_REALMS")
	g.hud.settings_menu()
	await g.get_tree().process_frame
	checks.settings_fit=g.get_viewport().get_visible_rect().encloses(g.hud.content.get_parent().get_global_rect())
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		g.get_viewport().get_texture().get_image().save_png("user://native-settings.png")
	var guard_before=g.stats.fallGuard
	g.stats.fallGuard=0
	checks.safe_jump_fall=g.fall_damage(7)==0 and g.fall_damage(13)==24
	g.stats.fallGuard=.5
	checks.fall_guard=g.fall_damage(13)==12
	g.stats.fallGuard=guard_before
	checks.single_bonus=g.rules.data.loot.all(func(item):return item.effects.size()==1)
	var rolls_ok=true
	for i in range(120):
		var roll=g.rules.roll("item",0,i%4)
		if roll.effects.size()!=1 and not roll.get("relic",false): rolls_ok=false
		if roll.effects[0].key in ["airJumps","revive","chain","multishot","flowerSeeds"] and roll.effects[0].amount!=roundf(roll.effects[0].amount): rolls_ok=false
	checks.discrete_bonuses=rolls_ok
	var capped=g.rules.data.stats.duplicate(true);capped.discount=.6;capped.keyPower=.75;capped.airJumps=8;capped.dodge=.65
	checks.useful_offers=g.rules.offers("item",0,false,capped).all(func(item):
		if item.kind=="weapon": return true
		var copy=capped.duplicate(true);g.rules.apply_effects(copy,item.effects)
		return not is_equal_approx(copy[item.effects[0].key],capped[item.effects[0].key]))
	g.mode="playing";g.hud.close();g.invulnerable=1000
	var original_speed=g.stat("speed")
	g.activate_consumable("speed");var first_boost=g.stat("speed")
	g.activate_consumable("speed")
	checks.buff_refresh=g.buffs.speed==25 and first_boost>original_speed and g.stat("speed")==first_boost
	g.mode="paused";var buff_remaining=g.buffs.speed
	g._physics_process(.5)
	checks.buff_pause=g.buffs.speed==buff_remaining
	g.mode="playing";g.buffs.speed=.01;g.update_exploration(.02)
	checks.buff_expiry=not g.buffs.has("speed") and g.stat("speed")==original_speed
	g.player_poison=3;g.activate_consumable("poison");g.update_exploration(.1)
	checks.immunity=g.player_poison==0
	g.drop_consumable(g.player.position,true);var drop_count=g.consumables.size()
	g.update_combat(.01)
	checks.manual_consumable=g.consumables.size()==drop_count
	g.interact();checks.consume_key=g.consumables.size()==drop_count-1
	var rig_test=ActorRig.new();g.add_child(rig_test);rig_test.setup("rubber_duck_toy")
	rig_test.sync_equipment([{"id":"gun","rank":1},{"id":"ice","rank":1},{"id":"rocket","rank":1}])
	checks.third_arm=rig_test.arms.size()==3 and rig_test.held.size()==3 and rig_test.arms[2].visible
	rig_test.sync_equipment([{"id":"gun","rank":1}]);checks.arm_removal=not rig_test.arms[2].visible and rig_test.held.size()==1
	rig_test.queue_free()
	# One biome per map (big update MB): this map is all one biome, and the
	# seven maps together hold every biome.
	var detected={}
	for i in range(36):
		var p=Vector3(cos(i*TAU/36)*300,0,sin(i*TAU/36)*300);detected[g.world.biome_at(p)]=true
	var every={}
	for b in RealmWorld.MAP_BIOMES: every[b]=true
	checks.six_biomes=detected.size()==1 and detected.has(RealmWorld.biome_of(g.realm)) and every.size()==RealmWorld.BIOME_COUNT and RealmWorld.MAPS==RealmWorld.BIOME_COUNT
	checks.large_world=RealmWorld.EXTENT==400
	checks.enemy_size=g.enemies.all(func(e):return e.node is CharacterBody3D and e.node.get_child(0).shape.height+.0001>=e.height and is_equal_approx(e.node.get_child(0).shape.radius,e.radius))
	g.player.position=Vector3(0,8,0);g.player.velocity=Vector3.ZERO;g.air_jumps=0;g.try_jump()
	checks.no_free_air_jump=g.air_jumps==0 and g.player.velocity.y==0
	g.rules.apply_effects(g.stats,[{"key":"airJumps","amount":1}]);g.try_jump()
	checks.double_jump=g.air_jumps==1 and g.player.velocity.y>0
	var before_jump=g.player.velocity.y;g.try_jump();checks.jump_limit=g.air_jumps==1 and g.player.velocity.y==before_jump
	var damage_before=g.health_damage
	g.last_safe=Vector3(0,0,0);g.recover_player()
	checks.recovery=not g.landing_ready and g.player.velocity==Vector3.ZERO and g.health_damage==damage_before
	# Exercise real landings, rather than only the fall-damage formula.
	g.clear_entities();g.mode="playing";g.spawn_clock=999;g.xp=0;g.storm_clock=999;g.nova_clock=999
	g.stats.dodge=0;g.stats.armor=0;g.stats.regen=0;g.stats.auraDamage=0;g.stats.shield=0;g.stats.fallGuard=0;g.shield_hp=0;g.invulnerable=0;g.hp=1000;g.stats.maxHp=1000
	g.buffs.clear();g.stats.fallThreshold=0;g.stats.jumpShield=0;g.stats.landingHeal=0
	# A 12 m drop onto whatever this map has underfoot.
	var drop_top=g.world.height_at(0,0)+12
	g.player.position=Vector3(0,drop_top,0);g.player.velocity=Vector3.ZERO;g.player.reset_physics_interpolation();g.peak_height=drop_top;g.landing_ready=true;g.slamming=false
	var before_fall=g.health_damage
	await g.get_tree().create_timer(1.4).timeout
	checks.real_fall_damage=g.health_damage-before_fall>19 and g.health_damage-before_fall<21 and g.player.is_on_floor()
	var landed_damage=g.health_damage
	await g.get_tree().create_timer(.2).timeout
	checks.single_landing_damage=is_equal_approx(landed_damage,g.health_damage)
	g.spawn_enemy(8)
	var slam_target=g.enemies[0];g.plain_enemy(slam_target);slam_target.node.position=Vector3(2.5,g.world.height_at(2.5,0),0);slam_target.hp=1000;slam_target.maxHp=1000;slam_target.freeze=3
	g.player.position=Vector3(0,8,0);g.player.velocity=Vector3(0,-24,0);g.player.reset_physics_interpolation();g.peak_height=8;g.landing_ready=true;g.slamming=true;g.invulnerable=1000
	var slam_expected=g.stat("damage")*2*g.stats.slamPower
	await g.get_tree().create_timer(.65).timeout
	checks.real_ground_slam=is_equal_approx(1000-slam_target.hp,slam_expected) and not g.slamming and g.player.is_on_floor()
	var before_level=g.level;g.mode="playing";g.xp=g.xp_target;g.level_up()
	checks.level_celebration=g.mode=="level_reveal" and g.level==before_level+1 and g.offers.size()==5
	g.level_reveal=.01;g._process(.02)
	checks.level_choice=g.mode=="offer"
	checks.biome_voices=range(RealmWorld.BIOME_COUNT).all(func(i):return ResourceLoader.exists("res://assets/voices/biome_"+str(i)+".wav"))
	checks.achievement_art=g.rules.data.achievements.all(func(a):return ResourceLoader.exists("res://assets/illustrated/achievements/"+a.id+".svg"))
	g.clear_entities()
	g.mode="playing";g.spawn_enemy(12)
	var stomp_target=g.enemies[0];g.plain_enemy(stomp_target);stomp_target.node.position=Vector3.ZERO;stomp_target.hp=10000
	g.slam_cooldown=0;g.slamming=false
	g.player.position=Vector3(0,stomp_target.height-.05,0);g.check_stomp(Vector3(0,stomp_target.height+.7,0),-8)
	checks.head_stomp=not stomp_target.dead and is_equal_approx(10000-stomp_target.hp,g.stat("damage")*2*g.stat("slamPower")) and g.player.velocity.y>0 and g.slam_cooldown>0
	g.mode="playing";g.invulnerable=0;g.stats.dodge=0;g.stats.armor=0;g.hp=1000
	g.take_damage(10,Vector3(1,1,0),"shell_bump")
	checks.hit_bump=g.knock_velocity.x<0 and g.hit_shake>0 and g.avatar.hurt>0
	g.spawn_pickup(Vector3(480,0,0),"xp",100);g.make_chest(Vector3(480,0,1),false);g.spawn_enemy(15)
	var edge_enemy=g.enemies[-1];edge_enemy.node.position=Vector3(480,0,0)
	g.player.position=Vector3.ZERO;g.update_boiling_edge()
	# No sea (October 31): things past the coast are held inside it, not destroyed.
	checks.border_holds=not edge_enemy.dead and not g.world.dangerous(edge_enemy.node.position) and not g.pickups.any(func(p):return g.world.dangerous(p.node.position)) and not g.chests[-1].get("destroyed",false) and not g.world.dangerous(g.chests[-1].node.position)
	var coast=g.world.shore_radius(Vector3.RIGHT)
	checks.border_bounds=g.world.dangerous(Vector3(coast+8,0,0)) and not g.world.dangerous(Vector3(coast-15,0,0))
	# The underside: walking out over the rim flips the hero under the island, upside
	# down and out of reach; walking out again flips them back on top.
	g.clear_entities();g.hp=g.stats.maxHp;g.invulnerable=0
	var rim_at=Vector3(coast-1.0,0,0);rim_at.y=g.world.height_at(rim_at.x,0)+.1
	g.world.ensure_ground(rim_at);g.player.position=rim_at;g.player.velocity=Vector3(6,0,0);g.underside.clear(g);g.underside.flips=0
	for i in range(80):
		g.player.velocity=Vector3(6,0,0)
		if g.underside.tick(g,1.0/60.0) and g.underside.state=="under": break
		g.player.position+=g.player.velocity/60.0
	var hp_under=g.hp;g.take_damage(50,g.player.position)
	checks.underside_flip=g.underside.state=="under" and g.underside.flipped() and g.player.position.y<g.world.height_at(g.player.position.x,g.player.position.z)-8 and absf(g.avatar.rotation.z-PI)<.01 and g.underside.camera_up().y<-.99
	checks.underside_safe=g.hp==hp_under and g.coop.target(g.player.position+Vector3(3,0,0)).id==-1 and not g.world.dangerous(g.coop.target(g.player.position).position)
	# Under the island the hero can still jump, slam and place a turret (November 1).
	g.player.velocity=Vector3.ZERO;g.slam_cooldown=0.0;g.air_jumps=0
	var belly_y=g.player.position.y;g.try_jump()
	for i in range(14): g.player.velocity=Vector3.ZERO;g.underside.tick(g,1.0/60.0)
	checks.under_jump=g.underside.hop>.5 and g.player.position.y<belly_y-.5
	var slams_before=g.underside.slams;g.try_slam()
	for i in range(60):
		g.player.velocity=Vector3.ZERO;g.underside.tick(g,1.0/60.0)
		if g.underside.grounded(): break
	checks.under_slam=g.underside.slams==slams_before+1 and g.underside.grounded() and absf(g.player.position.y-belly_y)<.6
	var hung={"id":"turret","rank":1,"power":1.0,"turret":true}
	g.deploy_turret(hung)
	checks.under_turret=is_instance_valid(hung.node) and hung.node.position.y<g.world.height_at(hung.node.position.x,hung.node.position.z)-8 and absf(hung.node.rotation.z-PI)<.01
	if is_instance_valid(hung.node): hung.node.queue_free()
	g.player.velocity=Vector3(6,0,0)
	for i in range(160):
		g.player.velocity=Vector3(6,0,0).rotated(Vector3.UP,0.0)
		if g.underside.tick(g,1.0/60.0) and g.underside.state=="top": break
	checks.underside_return=g.underside.state=="top" and not g.underside.flipped() and absf(g.player.position.y-g.world.height_at(g.player.position.x,g.player.position.z))<1.0 and g.underside.flips==2
	# Digby Mole's trick digs straight through the island and back; popping out on
	# top hurts the enemies standing there.
	g.underside.clear(g);var dig_at=Vector3(12,0,6);dig_at.y=g.world.height_at(dig_at.x,dig_at.z)+.1
	g.world.ensure_ground(dig_at);g.player.position=dig_at;g.player.velocity=Vector3.ZERO
	g.underside.dig(g,40.0,6.0)
	for i in range(150):
		if g.underside.tick(g,1.0/60.0) and g.underside.state=="under": break
	checks.mole_dig_down=g.underside.state=="under" and g.underside.flipped() and Vector2(g.player.position.x-dig_at.x,g.player.position.z-dig_at.z).length()<.01 and g.player.position.y<g.world.height_at(dig_at.x,dig_at.z)-8
	g.spawn_enemy(0);var dug_enemy=g.enemies[-1];g.plain_enemy(dug_enemy);dug_enemy.node.position=dig_at+Vector3(1.5,0,0);var dug_hp=float(dug_enemy.hp)
	g.underside.dig(g,40.0,6.0)
	for i in range(150):
		if g.underside.tick(g,1.0/60.0) and g.underside.state=="top": break
	checks.mole_dig_up=g.underside.state=="top" and not g.underside.flipped() and absf(g.player.position.y-g.world.height_at(dig_at.x,dig_at.z))<1.0 and g.underside.digs==2 and (dug_enemy.dead or float(dug_enemy.hp)<dug_hp)
	checks.mole_hero=HeroTricks.TRICKS.has("mole") and g.rules.data.heroes.any(func(h):return h.id=="mole" and CartoonHeroes.has("hero_"+h.model))
	g.underside.clear(g);g.player.position=Vector3(0,1.2,0);g.player.velocity=Vector3.ZERO
	g.clear_entities()
	g.hud.modal.visible=false
	await g.get_tree().process_frame
	var old_realm=g.realm
	g.sound.start(407);g.sound.tick(.01,true,false)
	checks.weapon_icon_models=g.rules.data.weapons.all(func(w):return IllustratedIcons.texture(w.id,true).resource_path=="res://assets/illustrated/weapon-icons/"+str(w.id)+".png")
	checks.long_music=range(3).all(func(i):return g.sound.stream("realm_theme_"+str(i)).get_length()>53)
	var theme_before=g.sound.atmosphere.stream
	g.sound.phrase+=1;g.sound.play_phrase()
	checks.music_theme_continuity=g.sound.atmosphere.stream==theme_before
	g.sound.tick(.01,false,false)
	checks.music_pause=g.sound.atmosphere.stream_paused and g.sound.rhythm.stream_paused
	g.realm=(old_realm+1)%RealmWorld.MAPS;g.sound.tick(.01,true,true)
	checks.music_realm_and_boss=g.sound.theme_realm==g.realm and g.sound.atmosphere.stream!=theme_before and not g.sound.atmosphere.stream_paused and g.sound.boss
	g.realm=old_realm
	checks.merge(preload("res://scripts/repair_checks.gd").run(g))
	g.mode="test_finished"
	g.sound.active=false
	for audio_player in g.sound.get_children():
		if audio_player is AudioStreamPlayer or audio_player is AudioStreamPlayer3D: audio_player.stop();audio_player.stream=null
	# Let the audio mixer release the short effect playbacks before teardown.
	await g.get_tree().create_timer(.2).timeout
	var report=FileAccess.open("user://smoke-results.json",FileAccess.WRITE)
	if report!=null: report.store_string(JSON.stringify(checks,"  "));report.close()
	print("NATIVE_SMOKE "+JSON.stringify(checks))
	var failure = not checks.main_menu or not checks.opaque_ui or not checks.illustrated_icons or not checks.selection_preview or not checks.weapon_cards_fit or not checks.item_cards_fit or not checks.camera_look or not checks.menu_blocks_look or not checks.weapon_rank or not checks.weapon_mechanics or not checks.mouse_camera or not checks.xbox_prompts or not checks.settings_fit or checks.initial_enemies<6 or checks.chests!=4*RealmWorld.BIOME_COUNT+g.world.climb_mesas.size() or checks.first_price!=30 or checks.achievements!=91 or not checks.paid_once or not checks.one_item or not checks.weapon_limit or not checks.disk_save or not checks.free_price or not checks.garden or not checks.garden_goals or not checks.realm_preserves or not checks.three_realms or not checks.standalone
	for key in checks:
		if checks[key] is bool and not checks[key]: failure=true
	g.get_tree().quit(1 if failure else 0)

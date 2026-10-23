extends RefCounted

static func run(game: Node3D):
	AudioServer.set_bus_volume_db(0,-80)
	game.start_run(407);game.set_physics_process(false)
	game.spawn_clock=99999;game.invulnerable=10000;game.xp=0
	var expansion=await preload("res://scripts/content_expansion_checks.gd").run(game)
	game.equipped.clear();game.clear_entities();game.mode="playing"
	var checks=expansion
	checks.world_dimensions=RealmWorld.EXTENT==400 and RealmWorld.SPAWN_EXTENT==370
	var coast=game.world.shore_radius(Vector3.RIGHT)
	checks.boundary=not game.world.dangerous(Vector3(coast-15,0,0)) and game.world.dangerous(Vector3(coast+8,0,0))
	checks.visible_sea=game.world.has_node("DeadlySea") and game.world.height_at(coast+8,0)<0 and game.world.height_at(coast-8,0)>0
	var jump_stats=game.stats.duplicate(true)
	var boots=game.rules.data.loot.filter(func(i):return i.id=="jump-boots-item")[0]
	game.rules.apply_effects(jump_stats,boots.effects)
	checks.jump_height_multiplier=is_equal_approx(jump_stats.jumpHeight,game.stats.jumpHeight*1.2)
	checks.extra_air_jump=game.rules.data.loot.any(func(i):return i.id=="extra-hop-item" and i.effects[0].key=="airJumps" and i.effects[0].amount==1)
	game.hud.update(0)
	var minimap=game.hud.map_view
	checks.minimap_no_fog=minimap.terrain!=null
	var map_colors={}
	for biome in range(6):
		var angle=(biome+.5)*TAU/6-float(game.world.seed_value%23)*.03-game.realm*.4
		var pixel=Vector2(cos(angle),sin(angle))*56+Vector2(128,128)
		var color=minimap.terrain.get_image().get_pixel(int(pixel.x),int(pixel.y))
		checks.minimap_no_fog=checks.minimap_no_fog and color.a==1 and color.get_luminance()>.025
		map_colors[color.to_html()]=true
	checks.minimap_biome_palette=map_colors.size()==6
	checks.minimap_interactions=minimap.interactables.any(func(i):return i.kind=="merchant") and minimap.interactables.any(func(i):return i.kind=="supply") and not minimap.interactables.any(func(i):return i.kind=="landmark")
	checks.rare_boxes=game.rules.chest_price(0)==30 and RunRules.WEAPON_CAP==3
	checks.achievements=game.career.achievements.size()==117 and game.career.achievements.map(func(a):return a.id).size()==117
	game.clear_entities();game.spawn_formation()
	var formation=game.enemies.filter(func(enemy):return int(enemy.get("formation_id",-1))>0)
	checks.enemy_formation=formation.size()==3 and formation.map(func(enemy):return enemy.formation_id).all(func(id):return id==formation[0].formation_id) and formation[0].get("formation_name","") in ["WEDGE","LINE","RING"]
	if not formation.is_empty():
		var formation_before=float(game.career.data.total.get("formation_breaks",0));game.kill_enemy(formation[0],"diagnostic")
		checks.formation_progress=float(game.career.data.total.get("formation_breaks",0))==formation_before+1
	else: checks.formation_progress=false
	game.clear_entities()
	checks.single_bonus=game.rules.data.loot.all(func(i):return i.effects.size()==1)
	checks.no_community=not game.hud.has_method("community_menu")
	game.spawn_enemy(8);game.spawn_enemy(12,true)
	var ordinary=game.enemies[0];var boss=game.enemies[1]
	ordinary.node.position=Vector3(3,0,0);boss.node.position=Vector3(10,0,0)
	checks.boss_priority=game.nearest_enemy(Vector3(0,1,0),30)==boss
	checks.out_of_range_boss=game.nearest_enemy(Vector3(0,1,0),5)==ordinary
	checks.melee_reach=game.nearest_melee(Vector3(0,1,0),3)==ordinary
	boss.node.position=Vector3(5,0,0)
	checks.melee_boss_priority=game.nearest_melee(Vector3(0,1,0),4)==boss
	boss.node.position=Vector3(5,20,0)
	checks.melee_flying=game.nearest_melee(Vector3(0,1,0),4)==ordinary
	game.clear_entities();game.spawn_clock=99999
	# Body pursuit, a real wall, dense spacing and frozen/paused clocks.
	game.spawn_enemy(9);ordinary=game.enemies[0];ordinary.node.position=Vector3(8,.1,0)
	ordinary.behavior="chase";ordinary.flying=false;ordinary.speed=5;ordinary.hp=10000;ordinary.freeze=0
	game.player.position=Vector3(0,.1,0);game.player.velocity=Vector3.ZERO
	var wall=StaticBody3D.new();wall.collision_layer=1;game.add_child(wall)
	var collider=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(2,4,3)
	collider.shape=box;wall.add_child(collider);wall.position=Vector3(4,2,0)
	var moved=ordinary.node.position
	for i in range(480):
		await game.get_tree().physics_frame
		game.update_combat(1.0/60)
	print("WALL_RESULT "+str(ordinary.node.position)+" radius "+str(ordinary.radius)+" wall "+str(ordinary.get("wall_direction",Vector3.ZERO)))
	checks.wall_pursuit=ordinary.node.position.distance_to(game.player.position)<3 and ordinary.node.position.distance_to(moved)>4
	# Enemy now climbs over walls - verify it reached the player after climbing.
	checks.contact_collision=Vector2(ordinary.node.position.x,ordinary.node.position.z).length()<1.5
	wall.queue_free();await game.get_tree().physics_frame
	ordinary.freeze=3;var frozen=ordinary.node.position
	for i in range(15):
		await game.get_tree().physics_frame;game.update_combat(1.0/60)
	checks.freeze=Vector2(ordinary.node.position.x-frozen.x,ordinary.node.position.z-frozen.z).length()<.05
	game.mode="paused";var attack=ordinary.attack;var freeze=ordinary.freeze;var clock=game.realm_time
	game._physics_process(.5)
	checks.pause=ordinary.attack==attack and ordinary.freeze==freeze and game.realm_time==clock
	game.mode="playing";game.clear_entities()
	game.spawn_pickup(Vector3(7,.3,0),"xp",2);game.spawn_pickup(Vector3(7.5,.3,0),"xp",3)
	game.spawn_pickup(Vector3(7,.3,0),"gold",4);game.spawn_pickup(Vector3(7.4,.3,0),"gold",5)
	game.spawn_pickup(Vector3(7,5,0),"xp",11)
	for pickup in game.pickups:
		pickup.settled=true;pickup.attracted=false;pickup.base_y=0 if pickup.node.position.y<1 else 5
		pickup.node.position=Vector3(7+randf()*.4,pickup.base_y+.3,0)
	game.merge_xp_orbs()
	checks.merge_conservation=game.pickups.size()==3 and is_equal_approx(game.pickups.filter(func(p):return p.kind=="xp").reduce(func(v,p):return v+p.value,0),16) and game.pickups.filter(func(p):return p.kind=="gold")[0].value==9
	checks.merge_units=game.pickups.filter(func(p):return p.kind=="gold")[0].units==2
	game.spawn_pickup(Vector3(12,.3,0),"gold",7)
	var distant=game.pickups[-1];distant.node.position=Vector3(12,.3,0);distant.settled=true;distant.base_y=0
	game.merge_xp_orbs()
	checks.distant_coin_merge=game.pickups.filter(func(p):return p.kind=="gold").size()==1 and game.pickups.filter(func(p):return p.kind=="gold")[0].value==16 and game.pickups.filter(func(p):return p.kind=="gold")[0].units==3
	game.spawn_pickup(Vector3(12,.3,0),"xp",7)
	distant=game.pickups[-1];distant.node.position=Vector3(12,.3,0);distant.settled=true;distant.base_y=0
	game.merge_xp_orbs()
	checks.distant_xp_merge=game.pickups.filter(func(p):return p.kind=="xp").size()==2 and game.pickups.filter(func(p):return p.kind=="xp").reduce(func(v,p):return v+p.value,0)==23


	game.clear_entities();game.update.realm_started()
	game.gold=500;game.mode="merchant";var gold=game.gold
	game.update.purchase(1);var owned=game.owned.size()
	game.update.purchase(1)
	checks.merchant_once=game.gold==gold-game.update.merchant_price(1) and game.owned.size()==owned
	game.hud.close();game.offer_kind="skill";game.offer_source="level";game.mode="offer"
	game.offers=game.rules.offers("skill",0,false,game.stats,game.equipped)
	var charges=game.update.banish_charges
	var banned=game.offers[0].effects[0].key;game.update.banish(0)
	checks.banish=charges==5 and game.update.banish_charges==charges-1 and game.rules.banished.has(banned)
	for i in range(30):
		checks.banish=checks.banish and game.rules.offers("skill",0,false,game.stats,game.equipped).all(func(item):return item.kind=="weapon" or item.effects[0].key!=banned)
	var banishes=game.rules.banished.duplicate()
	game.rules.banished=game.rules.data.loot.map(func(i):return i.effects[0].key)
	checks.exhausted_pool=game.rules.offers("skill",0,false,game.stats,game.equipped).size()==5
	game.rules.banished=banishes;game.hud.close()
	# Banish through the offer screen's own button on a real level-up offer: the
	# replacement set keeps its mutations, and a banished mutation never returns.
	game.mode="playing";game.hp=game.stats.maxHp;game.level=3;game.level_choice_cooldown=0;game.xp=game.xp_target
	game.level_up();game.level_reveal=0.0;game._process(.016)
	var mutation_slot=game.offers.map(func(i):return i.kind).find("mutation")
	var banish_button=game.hud.find_children("*","Button",true,false).filter(func(b):return b.is_visible_in_tree() and b.text.begins_with("Banish selected"))
	checks.banish_level_offer=game.mode=="offer" and mutation_slot>=0 and not banish_button.is_empty()
	if checks.banish_level_offer:
		var banned_mutation=str(game.offers[mutation_slot].id).trim_prefix("mut:")
		# The replaced panel is freed at the end of the frame; press the newest one.
		game.update.focused_offer=mutation_slot;banish_button.back().pressed.emit()
		checks.banish_keeps_mutations=game.offers.filter(func(i):return i.kind=="mutation").size()==3
		checks.banish_mutation_gone=game.rules.banished.has("mut:"+banned_mutation) and not game.offers.any(func(i):return i.id=="mut:"+banned_mutation)
		for i in range(40): checks.banish_mutation_gone=checks.banish_mutation_gone and MutationBook.roll(game,[]).get("id","")!="mut:"+banned_mutation
	game.rules.banished=banishes;game.hud.close();game.mode="playing"
	# Dashing ignores enemy bodies (live crowds can pin a walking hero; bot runs
	# showed 3 of 8 first-minute deaths without this) and collides again after.
	game.mode="playing";game.dash_cooldown=0.0;game.invulnerable=5.0;game.dash()
	game._physics_process(1.0/60.0)
	var through=game.player.collision_mask&4==0
	for i in range(20): game._physics_process(1.0/60.0)
	checks.dash_through_enemies=through and game.player.collision_mask==5
	game.invulnerable=0.0
	# Elite modifiers, each forced on a fresh elite through the real spawn path.
	var elite_checks={}
	for id in EliteMods.ORDER:
		# A random spawn spot can be blocked; try a few distances.
		var before=game.enemies.size()
		for attempt in range(6):
			game.spawn_enemy(8+attempt*3)
			if game.enemies.size()>before: break
		if game.enemies.size()==before: elite_checks[id]=false;continue
		var elite=game.enemies[-1];elite.elite=true
		if elite.node.has_meta("elite_badge"): elite.node.get_meta("elite_badge").queue_free();elite.node.remove_meta("elite_badge")
		EliteMods.assign(game,elite,id)
		if id=="blinking": elite.blink_clock=.5
		match id:
			"shielded":
				var hp_before=elite.hp;game.hurt_enemy(elite,elite.shield_max*.5,"hit")
				var absorbed=is_equal_approx(elite.hp,hp_before) and elite.shield<elite.shield_max
				elite.shield_clock=0.0;var low=elite.shield;EliteMods.tick(game,elite,1.0)
				elite_checks[id]=absorbed and elite.shield>low and elite.node.has_meta("elite_bubble") and elite.node.has_meta("elite_badge")
			"blinking":
				EliteMods.tick(game,elite,.3);var warned=elite.has("blink_to");EliteMods.tick(game,elite,.3)
				elite_checks[id]=warned and elite.node.position.distance_to(game.player.position)<5.0 and not elite.has("blink_to")
			"berserk":
				var speed_before=elite.speed;elite.hp=elite.maxHp*.4;EliteMods.tick(game,elite,.1)
				elite_checks[id]=elite.get("enraged",false) and elite.speed>speed_before*1.5
			"splitting":
				var count=game.enemies.filter(func(e):return not e.dead).size()
				game.hurt_enemy(elite,elite.hp+10,"hit")
				elite_checks[id]=elite.dead and game.enemies.filter(func(e):return not e.dead).size()==count+1
		if not elite.dead: elite.dead=true;elite.node.queue_free()
	game.enemies=game.enemies.filter(func(e):return not e.dead)
	checks.elite_modifiers=elite_checks.values().all(func(v):return v) and elite_checks.size()==4
	if not checks.elite_modifiers: print("ELITE_CHECKS ",elite_checks)
	# Internet invite codes round-trip, tolerate retyping, and reject garbage;
	# carrier-grade and private addresses are recognised as unreachable.
	var codes_ok=true
	for case in [["203.0.113.7",29736],["8.8.8.8",29736],["255.255.255.255",65535],["1.2.3.4",1]]:
		var code=InviteCode.encode(case[0],case[1]);var back=InviteCode.decode(code)
		codes_ok=codes_ok and code.length()==14 and back.get("address","")==case[0] and back.get("port",0)==case[1]
		codes_ok=codes_ok and InviteCode.decode(code.to_lower().replace("-"," "))==back
	codes_ok=codes_ok and InviteCode.decode("WF-HELLO-WORLD").is_empty() and InviteCode.decode("192.168.1.5").is_empty() and InviteCode.encode("300.1.1.1",29736).is_empty()
	checks.invite_codes=codes_ok
	checks.unreachable_addresses=["100.64.0.1","100.127.9.9","10.0.0.2","192.168.1.1","172.20.0.1",""].all(func(a):return InviteCode.unreachable(a)) and not InviteCode.unreachable("203.0.113.7") and not InviteCode.unreachable("100.128.0.1")
	# Effect settings: the real Shake slider (first of the three effect sliders)
	# changes both the saved setting and the live value.
	game.hud.settings_menu()
	var effect_sliders=game.hud.find_children("*","HSlider",true,false).filter(func(x):return x.is_visible_in_tree() and x.custom_minimum_size.x==150)
	checks.effect_sliders=effect_sliders.size()>=3
	if checks.effect_sliders:
		effect_sliders[-3].value=0.0
		checks.effect_sliders=is_zero_approx(float(game.career.data.settings.shake)) and is_zero_approx(EffectDetail.shake)
	game.career.data.settings.merge({"shake":1.0,"flashes":1.0,"particles":1.0},true);EffectDetail.load_settings(game.career.data.settings)
	game.hud.close();game.mode="playing"
	for id in ["gun","shotgun","ice"]:
		var item=game.rules.data.weapons.filter(func(w):return w.id==id)[0].duplicate(true);item.kind="weapon";item.strength=1;item.tier=0;game.equip_weapon(item)
	checks.full_slots=game.rules.offers("weapon",0,false,game.stats,game.equipped).size()==5
	checks.merchant_full_slots=game.rules.can_weapon(game.equipped,game.update.merchant_item(0,game.equipped).id)
	game.equipped[0].rank=6;game.avatar.sync_equipment(game.equipped);game.avatar.held[0].transform_rank()
	checks.weapon_transforms=game.avatar.held[0].rank_parts.get_child_count()>=3
	game.mode="offer";game.offers=game.rules.offers("skill",0,false,game.stats,game.equipped);game.hud.show_offers(game.offers,"level")
	game.hud.cards[1].grab_focus();var focused=game.hud.cards[1]
	game.input_kind="xbox";game.hud.update(0)
	checks.controller_focus=game.get_viewport().gui_get_focus_owner()==focused and InputMap.action_has_event("ping",ping_button())
	checks.card_values=game.hud.offer_detail.get_child(0).text.ends_with(game.offers[1].name) and game.hud.offer_detail.get_child(1).text.length()>10 and game.update.focused_offer==1
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png("user://big-update-cards.png")
	game.hud.close();game.equipped.clear();game.clear_entities();game.update.realm_started()
	# Keep reaction fixtures independent of the three world defense enemies.
	game.clear_entities()
	game.spawn_enemy(12);ordinary=game.enemies[0];ordinary.hp=10000;ordinary.maxHp=10000
	ordinary.fire=8;ordinary.poison=8;game.update_reaction(ordinary,"gun",20)
	var pools=game.pools.size();game.update_reaction(ordinary,"gun",20)
	checks.ignited_once=pools==1 and game.pools.size()==1
	ordinary.reaction_until=-1;ordinary.fire=0;ordinary.poison=0;ordinary.freeze=1
	game.update_reaction(ordinary,"slam",20);checks.shatter=ordinary.freeze==0
	game.spawn_enemy(12);var second=game.enemies[1];second.node.position=ordinary.node.position+Vector3.RIGHT*3
	ordinary.reaction_until=-1;ordinary.bubble=2;var health=second.hp
	game.update_reaction(ordinary,"lightning",20);checks.wet_chain=second.hp<health
	game.clear_entities();game.player.position=game.update.beacon_position;game.update.activate_beacon()
	game.update.host_tick(25.1);checks.beacon_choice=game.update.beacon_state=="complete" and game.mode=="offer" and game.offers.size()==5
	var claims=game.update.beacon_claimed.size();game.update.award_beacon();checks.reward_once=claims==game.update.beacon_claimed.size()
	game.hud.close();game.update.beacon_state="idle";game.update.activate_beacon();game.player.position=Vector3.ZERO;game.update.host_tick(7)
	checks.optional_failure=game.update.beacon_state=="failed" and game.hp>0
	game.mode="playing";game.update.send_ping();var count=game.update.pings.size();game.update.send_ping()
	checks.ping=count==1 and game.update.pings.size()==count
	var map=game.hud.map_view
	checks.map_rotates_with_camera=true
	map.hero_position=Vector3(37,0,-19)
	# Use the actual 3D camera basis convention, independently of map rotation.
	for heading in [0.0,PI*.25,PI*.5,PI,-PI*.5]:
		map.camera_yaw=heading
		var ahead=map.point(map.hero_position+Vector3.FORWARD.rotated(Vector3.UP,heading)*10,100)-map.size*.5
		var right=map.point(map.hero_position+Vector3.RIGHT.rotated(Vector3.UP,heading)*10,100)-map.size*.5
		checks.map_rotates_with_camera=checks.map_rotates_with_camera and absf(ahead.x)<.01 and ahead.y<0 and right.x>0 and absf(right.y)<.01
	game.make_chest(Vector3(3,0,0),false);var chest=game.chests[-1];chest.mimic=true;gold=game.gold;game.update.start_mimic(chest)
	checks.mimic_no_charge=game.gold==gold and not chest.opened and not game.update.mimic.is_empty()
	game.update.tick(.7);checks.mimic_coins=game.pickups.any(func(p):return p.kind=="gold")
	game.activate_consumable("speed");var effects=game.effects.size();game.activate_consumable("speed")
	checks.burp_throttle=game.effects.size()==effects
	game.update.quip_clock=0;game.update.quip("discovery");var quip=game.update.quip_clock;game.update.quip("boss")
	checks.quip_throttle=quip==45 and game.update.quip_clock==45
	game.career.save();var reloaded=game.ProfileScript.new(game.rules.data,true)
	checks.save_roundtrip=reloaded.data.total.get("runs",0)==game.career.data.total.get("runs",0)
	checks.recap=game.update.recap().contains("SURVIVED") and game.update.recap().contains("YOUR CONTRIBUTION") and game.update.recap().contains("PARTY DAMAGE")
	# All biome scenes, route slopes, and map edges in one rendered traversal.
	var worst_slope=0.0
	for biome in range(6):
		var angle=float(biome)*TAU/6-float(game.seed_value%23)*.03
		for radius in range(90,350,8):
			var p=Vector3(cos(angle)*radius,0,sin(angle)*radius);var q=Vector3(cos(angle)*(radius+4),0,sin(angle)*(radius+4))
			worst_slope=maxf(worst_slope,absf(game.world.height_at(p.x,p.z)-game.world.height_at(q.x,q.z))/4)
		angle+=TAU/12;game.player.position=game.world.landmarks[biome]+Vector3(0,0,12)
		game.world.ensure_ground(game.player.position);game.player.position.y=game.world.height_at(game.player.position.x,game.player.position.z)+.2
		game.yaw=0;game.current_biome=biome;game._process(1.0);game.world.weather_tick(5,game.player.position)
		for i in range(4): await game.get_tree().process_frame
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw;game.get_viewport().get_texture().get_image().save_png("user://big-update-biome-%d.png" % biome)
	checks.base_routes=worst_slope<tan(deg_to_rad(52))
	game.player.position=Vector3(coast-3,game.world.height_at(coast-3,0)+.2,0);game.yaw=-PI*.5
	game.world.ensure_ground(game.player.position);game._process(1.0)
	for i in range(24): await game.get_tree().process_frame
	game.update_boiling_edge()
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw;game.get_viewport().get_texture().get_image().save_png("user://deadly-sea-minimap.png")
	game.world.stream(Vector3(-280,0,0),[Vector3(280,0,0)])
	var coverage=game.world.pending+game.world.chunks.keys()
	checks.separated_party_chunks=coverage.any(func(cell):return cell.x>3) and coverage.any(func(cell):return cell.x< -3)
	checks.merge(await preload("res://scripts/encounter_checks.gd").run(game))
	checks.merge(preload("res://scripts/mutation_checks.gd").run(game))
	checks.merge(preload("res://scripts/evolution_checks.gd").run(game))
	checks.merge(preload("res://scripts/synergy_checks.gd").run(game))
	checks.merge(preload("res://scripts/biome_checks.gd").run(game))
	var result={"checks":checks,"route_max_slope":worst_slope,"passed":checks.values().all(func(v):return bool(v))}
	var file=FileAccess.open("user://big-update-results.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
	game.set_process(false);game.sound.shutdown()
	await game.get_tree().create_timer(.15).timeout
	print("BIG_UPDATE_CHECK "+JSON.stringify(result));game.get_tree().quit(0 if result.passed else 1)

static func ping_button() -> InputEventJoypadButton:
	var event=InputEventJoypadButton.new();event.button_index=JOY_BUTTON_RIGHT_STICK;return event

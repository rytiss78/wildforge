extends Node3D

const RulesScript = preload("res://scripts/rules.gd")
const WorldScript = preload("res://scripts/world.gd")
const HudScript = preload("res://scripts/hud.gd")
const ProfileScript = preload("res://scripts/profile.gd")
const SoundScript = preload("res://scripts/sound.gd")

var rules = RulesScript.new()
var world: RealmWorld
var hud: RunHUD
var career
var sound: RunSound
var player: CharacterBody3D
var avatar: Node3D
var camera: Camera3D
var hero: Dictionary
var stats: Dictionary
var mode = "start"
var run_active = false
var run_recorded = true
var run_id = ""
var seed_value = 0
var realm = 0
var realm_time = 0.0
var elapsed = 0.0
var realm_bosses = 0
var run_bosses = 0
var run_chests = 0
var paid_chests = 0
var gold = 0
var level = 1
var xp = 0.0
var xp_target = 41
var hp = 100.0
var health_damage = 0.0
var shield_hp = 0.0
var shield_delay = 0.0
var invulnerable = 0.0
var dash_time = 0.0
var dash_cooldown = 0.0
var ghost_time = 0.0
var burrow_time = 0.0
var yaw = 0.0
var pitch = 0.0
var camera_distance = 6.0
var walking_gold = 0.0
var spawn_clock = 0.0
var metric_clock = 0.0
var last_minute = 0
var storm_clock = 5.0
var nova_clock = 6.0
var low_health_warned = false
var affordable_warned = false
var controller_id = -1
var selected_turret = 0
var dragging = false
var input_kind = "keyboard"
var smoke = false
var smoke_started = false
var boss_name = ""
var gate_position = Vector3.ZERO
var gate: Node3D
var enemies = []
var projectiles = []
var pickups = []
var chests = []
var pots = []
var pools = []
var effects = []
var melee_attacks = []
var hazards = []
var equipped = []
var owned = []
var flowers = []
var garden_patches = {}
var visited_ruins = {}
var last_plant = Vector3(9999,0,9999)
var offers = []
var offer_source = ""
var families = {}
var events = {}
var reveal_clock = 0.0
var reveal_duration = 0.0
var reveal_tier = 0
var next_save = 0.0
var projectile_mesh = SphereMesh.new()
var brass_mesh: Mesh
var painted_shot: ShaderMaterial
var coin_mesh = CylinderMesh.new()
var orb_mesh = SphereMesh.new()
var materials = {}
var direction = Vector3.FORWARD
var air_jumps = 0
var slamming = false
var peak_height = 0.0
var last_safe = Vector3.ZERO
var landing_ready = false
var buffs = {}
var consumables = []
var biome_seen = {}
var current_biome = 0
var level_reveal = 0.0
var player_poison = 0.0
var player_fire = 0.0
var crowd = {}
var player_chill=0.0
var player_blind=0.0
var status_tick=0.0
var enemy_step=0.0
var knock_velocity=Vector3.ZERO
var hit_shake=0.0
var menu_repeat=0.0
var coop: CoopSession
var network_test_role=""


func _ready():
	if OS.get_cmdline_user_args().has("--style-check") or OS.get_cmdline_user_args().has("--style-inspect"):
		set_physics_process(false);set_process(false);set_process_input(false)
		get_tree().change_scene_to_file.call_deferred("res://style_lab.tscn")
		return
	world=WorldScript.new();hud=HudScript.new();sound=SoundScript.new()
	get_viewport().use_occlusion_culling=true
	player=CharacterBody3D.new();camera=Camera3D.new();coop=CoopSession.new()
	smoke = OS.get_cmdline_user_args().has("--smoke") or OS.get_cmdline_user_args().has("--soak") or OS.get_cmdline_user_args().has("--art") or OS.get_cmdline_user_args().has("--style-roundtrip")
	smoke=smoke or OS.get_cmdline_user_args().has("--update-check")
	smoke=smoke or OS.get_cmdline_user_args().has("--presentation-check")
	smoke=smoke or OS.get_cmdline_user_args().has("--melee-check")
	smoke=smoke or OS.get_cmdline_user_args().has("--pickup-check")
	smoke=smoke or OS.get_cmdline_user_args().has("--hero-check")
	smoke=smoke or OS.get_cmdline_user_args().has("--crowd-xp-check")
	if OS.get_cmdline_user_args().has("--coop-host-test"): network_test_role="host";smoke=true
	if OS.get_cmdline_user_args().has("--coop-client-test"): network_test_role="client";smoke=true
	career = ProfileScript.new(rules.data,smoke)
	if network_test_role!="": career.file="user://coop-test-"+network_test_role+".json"
	career.on_unlock = func(achievement): hud.tell("★  " + achievement.name); sound.say("achievement",25)
	stats = rules.data.stats.duplicate(true)
	hero = rules.data.heroes[1]
	add_child(world)
	world.build(0,407)
	add_child(player)
	player.collision_layer = 2
	player.collision_mask = 5
	player.floor_snap_length = .65
	player.floor_max_angle = deg_to_rad(52)
	var collision = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = .42
	capsule.height = 1.6
	collision.shape = capsule
	collision.position.y = .8
	player.add_child(collision)
	select_hero(hero)
	player.position = Vector3(0,1,0)
	add_child(camera)
	camera.fov = 70
	camera.far = 180
	camera.current = true
	camera.physics_interpolation_mode=Node.PHYSICS_INTERPOLATION_MODE_OFF
	var listener=AudioListener3D.new();camera.add_child(listener);listener.make_current()
	projectile_mesh.radius = .1
	projectile_mesh.height = .2
	projectile_mesh.radial_segments = 8
	projectile_mesh.rings = 4
	brass_mesh=load("res://assets/style3d/baked/brass_bullet.res") if ResourceLoader.exists("res://assets/style3d/baked/brass_bullet.res") else projectile_mesh
	painted_shot=PaintedBatch.material(false)
	coin_mesh.top_radius = .26
	coin_mesh.bottom_radius = .26
	coin_mesh.height = .045
	coin_mesh.radial_segments = 12
	orb_mesh.radius = .12
	orb_mesh.height = .24
	orb_mesh.radial_segments = 6
	orb_mesh.rings = 4
	add_child(sound)
	sound.setup(career.data.settings)
	add_child(hud)
	hud.setup(self)
	hud.start_menu()
	add_child(coop);coop.setup(self)
	configure_inputs()
	Input.joy_connection_changed.connect(func(id,connected):
		if not connected and id == controller_id and mode == "playing": hud.pause_menu(); hud.tell("Controller disconnected")
	)
	if OS.get_cmdline_user_args().has("--presentation-check"): preload("res://scripts/presentation_checks.gd").run.call_deferred(self)
	if OS.get_cmdline_user_args().has("--hero-check"): preload("res://scripts/hero_checks.gd").run.call_deferred(self)
	if OS.get_cmdline_user_args().has("--crowd-xp-check"): preload("res://scripts/crowd_xp_checks.gd").run.call_deferred(self)
	elif OS.get_cmdline_user_args().has("--pickup-check"): preload("res://scripts/pickup_checks.gd").run.call_deferred(self)
	elif OS.get_cmdline_user_args().has("--melee-check"): preload("res://scripts/melee_checks.gd").run.call_deferred(self)
	elif OS.get_cmdline_user_args().has("--update-check"): preload("res://scripts/update_checks.gd").run.call_deferred(self)
	elif OS.get_cmdline_user_args().has("--style-roundtrip"): call_deferred("run_style_roundtrip")
	elif network_test_role!="": call_deferred("run_coop_test")
	elif smoke: call_deferred("export_hero_art" if OS.get_cmdline_user_args().has("--art") else "run_soak" if OS.get_cmdline_user_args().has("--soak") else "run_smoke")

func configure_inputs():
	var keys = {"move_left":KEY_A,"move_right":KEY_D,"move_forward":KEY_W,"move_back":KEY_S,"dash":KEY_SHIFT,"jump":KEY_SPACE,"slam":KEY_CTRL,"interact":KEY_E,"build":KEY_B,"pause_game":KEY_ESCAPE,"deploy":KEY_T,"camera_left":KEY_Q,"camera_right":KEY_R}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		var event = InputEventKey.new()
		event.physical_keycode = keys[action]
		if not InputMap.action_has_event(action,event): InputMap.action_add_event(action,event)
	var buttons = {"jump":JOY_BUTTON_A,"slam":JOY_BUTTON_B,"interact":JOY_BUTTON_X,"build":JOY_BUTTON_Y,"pause_game":JOY_BUTTON_START,"deploy":JOY_BUTTON_LEFT_SHOULDER}
	for action in buttons:
		var event = InputEventJoypadButton.new()
		event.button_index = buttons[action]
		if not InputMap.action_has_event(action,event): InputMap.action_add_event(action,event)
	var trigger = InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 1.0
	if not InputMap.action_has_event("dash",trigger): InputMap.action_add_event("dash",trigger)

func run_style_roundtrip():
	await get_tree().process_frame
	var stage=int(get_tree().get_meta("style_roundtrip_stage",0))
	if stage==0:
		var buttons=hud.menu_controls().filter(func(control):return control is Button and control.text=="3D Style Lab")
		if buttons.is_empty(): get_tree().quit(1);return
		get_tree().set_meta("style_roundtrip_stage",1)
		buttons[0].grab_focus();hud.controller_accept()
	else:
		configure_inputs()
		var ok=stage==2 and mode=="start" and hud.modal.visible and InputMap.action_get_events("jump").size()==2
		print("STYLE_ROUNDTRIP ",ok)
		get_tree().quit(0 if ok else 1)

func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var key = color.to_html()+str(glow)
	if not materials.has(key):
		var item = StandardMaterial3D.new()
		item.albedo_color = color
		item.roughness = .9
		item.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
		item.metallic_specular=0
		if glow > 0:
			item.emission_enabled = true
			item.emission = color
			item.emission_energy_multiplier = glow
		materials[key] = item
	return materials[key]

func shape(mesh_value: Mesh, color: Color, parent: Node3D, position_value: Vector3 = Vector3.ZERO, glow: float = 0.0) -> MeshInstance3D:
	var node = MeshInstance3D.new()
	node.mesh = mesh_value
	node.material_override = material(color,glow)
	node.position = position_value
	parent.add_child(node)
	return node

func select_hero(item: Dictionary):
	hero=item
	if is_instance_valid(avatar): avatar.queue_free()
	avatar=world.model(hero.model,1.65)
	avatar.rotation.y=PI
	player.add_child(avatar)

func clear_entities():
	melee_attacks.clear()
	if is_instance_valid(avatar): avatar.finish_melee()
	for id in sound.weapon_loops: sound.weapon_loop(id,false,player.position)
	for drop in consumables:
		if is_instance_valid(drop.node): drop.node.queue_free()
	consumables.clear()
	for list in [enemies,projectiles,pickups,chests,pots,pools,effects,hazards,flowers]:
		for item in list:
			if is_instance_valid(item.node): item.node.queue_free()
		list.clear()
	for weapon in equipped:
		if weapon.has("node") and is_instance_valid(weapon.node): weapon.node.queue_free()
	if is_instance_valid(gate): gate.queue_free()

func start_run(shared_seed: int=-1):
	if shared_seed<0 and coop.active and not coop.hosting: hud.tell("The party host starts the run.");return
	record_run(false,true)
	clear_entities()
	seed_value = randi() if shared_seed<0 else shared_seed
	rules.rng.seed = seed_value
	run_id = str(Time.get_unix_time_from_system())+"-"+str(seed_value)
	run_recorded = false
	run_active = true
	realm = 0
	elapsed = 0.0
	level = 1
	xp = 0
	xp_target = rules.next_xp(level)
	stats = rules.data.stats.duplicate(true)
	rules.apply_effects(stats,hero.effects)
	hp = stats.maxHp
	shield_hp = stats.shield
	health_damage = 0
	kills = 0
	gold = 0
	paid_chests = 0
	run_bosses = 0
	run_chests = 0
	low_health_warned = false
	affordable_warned = false
	families.clear()
	garden_patches.clear()
	visited_ruins.clear()
	last_plant = Vector3(9999,0,9999)
	owned.clear()
	equipped.clear()
	buffs.clear();biome_seen.clear();player_poison=0;player_fire=0;player_chill=0;player_blind=0
	var first = rules.data.weapons.filter(func(w): return w.id == hero.weapon)[0].duplicate(true)
	first.kind = "weapon"
	first.strength = 1.0
	first.tier = 0
	equip_weapon(first)
	career.bump("runs")
	career.bump("play_"+hero.id)
	sound.start(seed_value)
	enter_realm(0)
	hud.close()
	if shared_seed<0: coop.run_started()

var kills = 0

func enter_realm(index: int):
	clear_entities()
	realm = index
	realm_time = 0
	garden_patches.clear()
	visited_ruins.clear()
	last_plant = Vector3(9999,0,9999)
	if index == 2: achievement_event("THREE_REALMS")
	realm_bosses = 0
	events.clear()
	spawn_clock = 0
	last_minute = 0
	dash_cooldown = 0
	dash_time = 0
	invulnerable = 1.2
	storm_clock = 5
	nova_clock = 6
	yaw = 0
	pitch = 0
	world.build(realm,seed_value)
	player.position = Vector3(0,1.2,0)
	player.velocity = Vector3.ZERO
	player.reset_physics_interpolation()
	air_jumps=0;slamming=false;landing_ready=false;peak_height=player.position.y;last_safe=player.position
	avatar.sync_equipment(equipped)
	avatar.visible = true
	hud.map_view.visited.clear()
	make_chests()
	make_pots()
	make_gate()
	for weapon in equipped:
		weapon.clock = 0
		if weapon.turret: deploy_turret(weapon)
	# A ring already converges on you at spawn. No free minute of idling.
	for i in range(9): spawn_enemy(11.0+randf()*5.0)
	hud.tell("%d / 3  ·  %s" % [realm+1,RealmWorld.NAMES[realm]],4)
	if realm > 0: sound.say("realm",0)
	if index>0: coop.realm_changed()

func make_chests():
	# Five scattered chests plus one at a raised ruin; no starter chest or global beacon.
	for i in range(6):
		var angle = rules.rng.randf()*TAU
		var radius = rules.rng.randf_range(80,450)
		var p = Vector3(cos(angle)*radius,0,sin(angle)*radius)
		p.y = world.height_at(p.x,p.z)
		if i == 5: p = world.landmarks[rules.rng.randi_range(0,3)] + Vector3(0,1.8,0)
		make_chest(p,false)

func make_chest(p: Vector3, elite: bool):
	var node = world.model("old_military_crate",.9)
	node.position = p
	add_child(node)
	chests.append({"node":node,"opened":false,"elite":elite,"discovered":elite,"free":elite,"rolled_free":false})

func make_pots():
	for i in range(42):
		var angle = rules.rng.randf()*TAU
		var radius = rules.rng.randf_range(9,450)
		var node = Node3D.new()
		node.position = Vector3(cos(angle)*radius,0,sin(angle)*radius)
		node.position.y = world.height_at(node.position.x,node.position.z)
		add_child(node)
		var body = CylinderMesh.new()
		body.top_radius = .23
		body.bottom_radius = .34
		body.height = .65
		body.radial_segments = 20
		shape(body,Color("9f6548"),node,Vector3(0,.33,0))
		pots.append({"node":node})

func make_gate():
	gate_position = world.landmarks[(realm+1)%4]+Vector3(0,1.8,0)
	gate = Node3D.new()
	gate.position = gate_position
	add_child(gate)
	var ring = TorusMesh.new()
	ring.inner_radius = 1.7
	ring.outer_radius = 2.05
	var rim = shape(ring,Color("a89db1"),gate,Vector3(0,2,0),.3)
	rim.rotation.x = PI/2
	for x in [-2.1,2.1]:
		var pillar = CylinderMesh.new()
		pillar.top_radius = .5
		pillar.bottom_radius = .7
		pillar.height = 3.7
		shape(pillar,Color("788a92"),gate,Vector3(x,1.85,0))
	var marker = Label3D.new()
	marker.text = "☠ 0 / 2"
	marker.font_size = 48
	marker.position.y = 5
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	gate.add_child(marker)
	gate.set_meta("marker",marker)

func nearest_chest() -> Dictionary:
	var nearest = {}
	var distance_value = 3.2
	for chest in chests:
		if chest.opened: continue
		var distance = player.position.distance_to(chest.node.position)
		if distance < distance_value: nearest=chest;distance_value=distance
	return nearest

func interaction_hint() -> String:
	var drop=nearest_consumable()
	if not drop.is_empty(): return "E / X  ·  "+drop.title+"  ·  25 s"
	if mode != "playing": return ""
	var chest = nearest_chest()
	if not chest.is_empty():
		var price = 0 if chest.free else rules.chest_price(paid_chests,stats.discount)
		return "E / X   ▣   %s" % ("FREE" if price == 0 else "● %d" % price) + ("   ✓" if gold >= price else "   ✕")
	if player.position.distance_to(gate_position) < 4:
		return "E / X   →  " + ("NEXT WORLD" if realm < 2 else "VICTORY") if realm_bosses >= 2 else "☠  %d / 2   →   LOCKED" % realm_bosses
	return ""

func interact():
	var drop=nearest_consumable()
	if not drop.is_empty():
		activate_consumable(drop.kind);drop.node.queue_free();consumables.erase(drop);return
	var chest = nearest_chest()
	if not chest.is_empty(): buy_chest(chest);return
	if player.position.distance_to(gate_position) < 4:
		if realm_bosses < 2: achievement_event("LOCKED_GATE");hud.tell("☠  Defeat both bosses to open this gate");return
		if coop.active and not coop.hosting: coop.send_to(coop.owner_id,{"type":"travel"});return
		if realm == 2: end_run(true)
		else: enter_realm(realm+1)

func buy_chest(chest: Dictionary):
	if chest.opened: return
	# Key outcome is rolled once per chest, preventing repeated-interaction rerolls.
	if not chest.rolled_free:
		chest.rolled_free = true
		chest.free = chest.free or rules.rng.randf() < rules.free_chance(stats.keyPower)
	var price = 0 if chest.free else rules.chest_price(paid_chests,stats.discount)
	if gold < price: hud.tell("● %d / %d" % [gold,price]);return
	if price > 0 and gold == price: achievement_event("LAST_COIN")
	if price > 0 and stats.discount > 0: achievement_event("SALE")
	if chest.free: achievement_event("BOSS_GIFT" if chest.elite else "FREE_KEY")
	if chest.node.position.y > world.height_at(chest.node.position.x,chest.node.position.z)+1: achievement_event("HIGH_CHEST")
	gold -= price
	if price > 0: paid_chests += 1
	chest.opened = true
	if chest.node.has_meta("lid"): create_tween().tween_property(chest.node.get_meta("lid"),"rotation:x",-1.5,.5).set_trans(Tween.TRANS_BACK)
	var disappear=create_tween();disappear.tween_interval(.5);disappear.tween_callback(func():if is_instance_valid(chest.node): chest.node.visible=false)
	run_chests += 1
	career.bump("chests")
	if stats.chestBonus > 0: career.best("chestRewards",5 if rules.rng.randf()<stats.chestBonus else 3)
	offers = rules.offers("item",stats.luck+stats.chestBonus*.2,chest.elite,stats,equipped)
	heal(stats.chestHeal)
	offer_source = "chest"
	reveal_tier = offers.map(func(item):return item.tier).max()
	if reveal_tier == 3: achievement_event("LEGENDARY")
	reveal_duration = [.75,1.25,2.1,3.1][reveal_tier]
	sound.chest_open(reveal_tier,reveal_duration)
	reveal_clock = 0
	mode = "reveal"
	hud.open("▣  TREASURE", "Three choices. One new power.")
	sound.effect("coin")
	vibrate(.25,.55,.2)
	if reveal_tier == 3: sound.say("legendary",0)
	else: sound.say("treasure",18)

func level_up():
	if mode != "playing": return
	xp -= xp_target
	level += 1
	xp_target = rules.next_xp(level)
	# Levels feel like milestones: heal and reveal a weapon/skill choice, not a tiny stat pop.
	heal(stats.maxHp*.15)
	shield_hp = stats.shield
	var kind = "weapon" if level == 2 or level%3 == 0 else "skill"
	offers = rules.offers(kind,stats.luck,false,stats,equipped)
	offer_source = "level"
	mode = "level_reveal"
	level_reveal = .95
	hud.level_flash()
	burst(player.position+Vector3.UP,Color("eac97f"),18)
	sound.say("level",0)
	vibrate(.4,.65,.25)
	hud.tell("LEVEL %d  ·  NEW POWER!" % level,1.2)

func choose_offer(index: int):
	if mode != "offer" or index < 0 or index >= offers.size(): return
	var item = offers[index]
	if item.kind == "weapon":
		if not rules.can_weapon(equipped,item.id):
			offers=rules.offers("weapon",stats.luck,false,stats,equipped)
			hud.show_offers(offers,"level")
			return
		equip_weapon(item)
	else:
		var previous_hp = stats.maxHp
		rules.apply_effects(stats,item.effects)
		hp += maxf(0,stats.maxHp-previous_hp)
		shield_hp = minf(stats.shield+stats.jumpShield,shield_hp+float(item.effects.filter(func(e):return e.key=="shield").reduce(func(sum,e):return sum+e.amount,0)))
		owned.append(item)
		career.bump("loot")
		families[item.family] = int(families.get(item.family,0))+1
		career.best("family_"+item.family,families[item.family])
	hud.tell("+  " + item.name)
	hud.close()
	if xp >= xp_target: level_up()

func skip_offer():
	if mode!="offer" or not offers.any(func(item):return item.kind=="weapon"): return
	offers.clear();hud.close();hud.tell("Kept your weapons")
	if xp>=xp_target: level_up()

func equip_weapon(item: Dictionary):
	for weapon in equipped:
		if weapon.id == item.id:
			achievement_event("RANK_UP")
			weapon.rank += 1
			weapon.power += item.strength*.3
			avatar.sync_equipment(equipped)
			return
	if equipped.size()>=RunRules.WEAPON_CAP: return
	var weapon = item.duplicate(true)
	weapon.rank = 1
	weapon.power = item.strength
	weapon.clock = 0
	weapon.node = null
	weapon.deploy_clock = 0
	equipped.append(weapon)
	avatar.sync_equipment(equipped)
	if weapon.turret and run_active: deploy_turret(weapon)

func replace_weapon(index: int, item: Dictionary):
	achievement_event("REPLACE")
	var previous = equipped[index]
	if is_instance_valid(previous.node): previous.node.queue_free()
	sound.weapon_loop(previous.id,false,player.position)
	equipped.remove_at(index)
	equip_weapon(item)
	hud.close()

func deploy_turret(weapon: Dictionary):
	if is_instance_valid(weapon.get("node")): weapon.node.queue_free()
	var node = Node3D.new()
	node.position = player.position+Vector3(1.6,0,0)
	node.position.y = world.height_at(node.position.x,node.position.z)
	add_child(node)
	var model=WeaponModel.new();model.setup(weapon.id);model.scale=Vector3.ONE*1.7;model.position.y=.75;node.add_child(model);node.set_meta("model",model)
	node.scale=Vector3.ONE*.05
	create_tween().tween_property(node,"scale",Vector3.ONE,.25).set_trans(Tween.TRANS_BACK)
	weapon.node = node
	weapon.deploy_clock = 2
	weapon.clock = 0

func vibrate(weak: float, strong: float, duration: float):
	if controller_id >= 0 and career.data.settings.rumble: Input.start_joy_vibration(controller_id,weak,strong,duration)

func heal(amount: float):
	var actual = maxf(0,minf(stats.maxHp-hp,amount))
	hp += actual
	if actual > 0: career.bump("healing",actual)
	update_hero_vitals()

func update_hero_vitals():
	if not is_instance_valid(avatar): return
	avatar.set_health(hp/maxf(1,stats.maxHp))
	avatar.set_defense(stat("armor"),shield_hp,stats.shield+stats.jumpShield)

func record_run(win: bool, abandoned: bool = false):
	if run_recorded or not run_active: return
	run_recorded = true
	if elapsed < 2 and abandoned: return
	career.score({"id":run_id,"hero":hero.id,"seconds":elapsed,"kills":kills,"level":level,"bosses":run_bosses,"chests":run_chests,"win":win,"abandoned":abandoned,"healthDamage":health_damage,"realm":realm,"gold":gold,"seed":seed_value})

func end_run(win: bool):
	if coop.active and coop.hosting and win: coop.broadcast({"type":"finish","win":true})
	record_run(win)
	avatar.visible = true
	avatar.finale(win)
	sound.say("victory" if win else "defeat",0)
	hud.pause_menu(true,win)

func boss_active() -> bool:
	return enemies.any(func(enemy):return enemy.boss and enemy.hp > 0)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST and career != null:
		record_run(false,true)
		career.save()
		get_tree().quit()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == "playing" and not smoke: hud.pause_menu()

func camera_look(amount: Vector2):
	if mode != "playing": return
	var sensitivity = float(career.data.settings.lookSensitivity)
	yaw -= amount.x*sensitivity
	pitch = clampf(pitch+amount.y*sensitivity*(-1 if career.data.settings.invertLook else 1),-.2,.45)

func _input(event):
	if event is InputEventKey or event is InputEventMouseButton: input_kind = "keyboard"
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value)>.25): input_kind = "xbox"
	if hud.modal.visible and input_kind=="xbox":
		if event is InputEventJoypadButton:
			if event.pressed:
				controller_id=event.device
				if event.button_index==JOY_BUTTON_A: hud.controller_accept()
				elif event.button_index in [JOY_BUTTON_DPAD_UP,JOY_BUTTON_DPAD_DOWN,JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_DPAD_RIGHT]:
					hud.controller_move({JOY_BUTTON_DPAD_UP:Vector2.UP,JOY_BUTTON_DPAD_DOWN:Vector2.DOWN,JOY_BUTTON_DPAD_LEFT:Vector2.LEFT,JOY_BUTTON_DPAD_RIGHT:Vector2.RIGHT}[event.button_index])
			if event.button_index!=JOY_BUTTON_B and event.button_index!=JOY_BUTTON_START:
				get_viewport().set_input_as_handled();return
		elif event is InputEventJoypadMotion:
			get_viewport().set_input_as_handled();return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT: dragging = event.pressed
	if event is InputEventMouseMotion and (dragging or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED):
		camera_look(event.relative*Vector2(.004,.002))
	if event is InputEventMouseButton and event.pressed and mode == "playing":
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: camera_distance=maxf(3,camera_distance-.5)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: camera_distance=minf(11,camera_distance+.5)
	if event is InputEventJoypadButton and event.pressed:
		controller_id = event.device
		if event.button_index == JOY_BUTTON_BACK:
			hud.career_menu(false)
		if event.button_index == JOY_BUTTON_B and mode not in ["playing","start","offer","reveal","replace","level_reveal"]:
			hud.start_menu() if not run_active else hud.pause_menu(run_recorded)
		if event.button_index == JOY_BUTTON_RIGHT_SHOULDER: selected_turret += 1
	if event.is_action_pressed("pause_game"):
		if mode == "playing": hud.pause_menu()
		elif mode == "paused": hud.close()
		elif mode in ["settings","career","build","community","coop"]: hud.start_menu() if not run_active else hud.pause_menu(run_recorded)
		get_viewport().set_input_as_handled()
	if mode == "offer" and event is InputEventKey and event.pressed:
		var index = int(event.physical_keycode)-KEY_1
		if index >= 0 and index < 3: choose_offer(index)
	if mode == "reveal" and (event.is_action_pressed("jump") or event.is_action_pressed("interact")):
		finish_reveal();get_viewport().set_input_as_handled();return
	if mode != "playing": return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_G: selected_turret+=1
	if event.is_action_pressed("interact"): interact()
	if event.is_action_pressed("build"): hud.build_menu()
	if event.is_action_pressed("dash"): dash()
	if event.is_action_pressed("jump"): try_jump()
	if event.is_action_pressed("slam") and not player.is_on_floor(): slamming=true;player.velocity.y=-24;sound.effect("dash")
	if event.is_action_pressed("deploy"):
		var turrets = equipped.filter(func(weapon):return weapon.turret)
		if not turrets.is_empty() and turrets[selected_turret%turrets.size()].deploy_clock <= 0: deploy_turret(turrets[selected_turret%turrets.size()])

func finish_reveal():
	if mode != "reveal": return
	mode = "offer"
	hud.blast.color.a = 0
	hud.show_offers(offers,"chest")

func random_spawn(radius: float) -> Vector3:
	var angle = rules.rng.randf()*TAU
	var origin=player.position
	if coop.active and coop.hosting:
		var positions=[player.position]
		for member in coop.members.values():
			if member.has("position") and member.get("hp",0)>0: positions.append(CoopSession.vector(member.position))
		origin=positions[rules.rng.randi_range(0,positions.size()-1)]
	var p = origin + Vector3(cos(angle)*radius,0,sin(angle)*radius)
	p.x = clampf(p.x,-480,480)
	p.z = clampf(p.z,-480,480)
	p.y = world.height_at(p.x,p.z)
	return p

func spawn_enemy(radius: float = 22.0, boss: bool = false):
	if coop.active and not coop.hosting: return
	if not boss and not make_spawn_room(): return
	var p=random_spawn(radius)
	for attempt in range(12):
		if p.distance_to(player.position)>3 and not enemies.any(func(e):return not e.dead and e.node.position.distance_to(p)<2.2) and spawn_is_clear(p,boss): break
		p=random_spawn(radius+attempt*.6)
	if not spawn_is_clear(p,boss):
		p.x=-sin(p.z*.035)*9;p.y=world.height_at(p.x,p.z)
	world.ensure_ground(p)
	var biome=world.biome_at(p)
	var species=CreatureBook.pick(biome,rules.rng)
	var elite=not boss and rules.rng.randf()<.08
	var height=9.0+realm*2.0 if boss else species.height*(1.25 if elite else 1.0)
	var radius_value=2.8+realm*.5 if boss else species.radius*(1.25 if elite else 1.0)
	var valid_spawn=false
	for attempt in range(24):
		if spawn_is_clear(p,boss) and not enemies.any(func(e):return not e.dead and Vector2(e.node.position.x-p.x,e.node.position.z-p.z).length()<radius_value+e.radius+.1):
			valid_spawn=true;break
		p=random_spawn(radius+attempt*.7)
	if not valid_spawn: return
	world.ensure_ground(p)
	var node=CharacterBody3D.new()
	node.collision_layer=4;node.collision_mask=3;node.floor_snap_length=1.2;node.floor_max_angle=deg_to_rad(55);node.max_slides=2
	var collider=CollisionShape3D.new();var capsule=CapsuleShape3D.new()
	capsule.radius=radius_value;capsule.height=maxf(height,radius_value*2)
	collider.shape=capsule;collider.position.y=capsule.height*.5;node.add_child(collider)
	var rig=world.model("creature_%d_5" % biome if boss else species.model,height)
	node.add_child(rig);node.set_meta("rig",rig)
	node.position=p+Vector3.UP*.15
	add_child(node)
	if not boss: rig.bake_enemy()
	if elite or species.rarity==3:
		var title=Label3D.new();title.text=("ELITE  ·  " if elite else "MYTHIC  ·  ")+species.name;title.font_size=22;title.position.y=2.3;title.modulate=Color("ffd992");title.billboard=BaseMaterial3D.BILLBOARD_ENABLED;node.add_child(title)
	var max_health = (500+realm*400+realm_time*2) if boss else (23+realm*15+realm_time*.065)
	max_health *= 1+biome*.18
	if not boss: max_health*=species.health
	if elite: max_health*=2.5
	var enemy = {"biome":biome,"elite":elite,"node":node,"hp":max_health,"maxHp":max_health,"speed":2.9+realm*.35+randf()*.6,"boss":boss,"fire":0.0,"poison":0.0,"status_time":0.0,"freeze":0.0,"blind":0.0,"slow":0.0,"attack":2.5,"telegraph":0.0,"dead":false,"contact":0.0,"phase":1,"startDamage":health_damage}
	enemy.merge(species);enemy.speed*=species.speed
	enemy.height=height;enemy.radius=radius_value;enemy.flying=species.flying and not boss
	rig.set_health(1,boss or species.health>=1.8)
	if enemy.flying: node.floor_snap_length=0;node.position.y+=species.altitude
	enemy.net_id=coop.next_entity;coop.next_entity+=1
	enemy.xp_reward=enemy_xp_reward(enemy)
	if boss:
		enemy.speed = 2.7+realm*.3
		boss_name = ["World Maw","Sun Breaker","Star Eater"][realm]
		var crown = TorusMesh.new()
		crown.inner_radius = .72
		crown.outer_radius = .87
		shape(crown,Color("e7cb79"),node,Vector3(0,3.4,0),.3)
		var hp_label = Label3D.new()
		hp_label.font_size = 45
		hp_label.text = boss_name
		hp_label.position.y = height+.8
		hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		node.add_child(hp_label)
		enemy.label = hp_label
		sound.say("boss",0)
		vibrate(.5,.8,.35)
		hud.tell("☠  " + boss_name,5)
	enemies.append(enemy)

func enemy_xp_reward(enemy: Dictionary) -> float:
	# Spawn-time health captures species, elite, biome and difficulty strength.
	return maxf(.75,float(enemy.maxHp)/23.0*1.5*sqrt(maxf(.25,float(enemy.get("damage",1)))))

func make_spawn_room() -> bool:
	enemies=enemies.filter(func(e):return not e.dead)
	if enemies.size()<125: return true
	var farthest={};var far_distance=55.0
	for enemy in enemies:
		if enemy.boss: continue
		# Nearest living party member protects enemies near co-op players too.
		var distance=enemy.node.position.distance_to(coop.target(enemy.node.position).position)
		if distance>far_distance: farthest=enemy;far_distance=distance
	if farthest.is_empty(): return false
	# Despawn, never kill: no XP, gold, achievements or boss progress for recycling.
	farthest.dead=true;farthest.node.queue_free();enemies.erase(farthest)
	return true

func steer_enemy(enemy: Dictionary,aim: Vector3) -> Vector3:
	if enemy.flying or aim.length()<.01: return aim
	var body: CharacterBody3D=enemy.node
	var reach=maxf(1.2,enemy.speed*.65)
	var side=float(enemy.get("avoid_side",1 if enemy.net_id%2==0 else -1))
	if not body.test_move(body.global_transform,aim*reach): return aim
	for angle in [.55,1.1,1.65,2.2]:
		for turn in [side,-side]:
			var candidate=aim.rotated(Vector3.UP,angle*turn)
			if not body.test_move(body.global_transform,candidate*reach):
				enemy.avoid_side=turn;return candidate
	return aim.rotated(Vector3.UP,side*PI*.5)

func nearest_enemy(origin: Vector3, distance_value: float, excluded: Array = []) -> Dictionary:
	var result = {}
	var best_distance = distance_value*distance_value
	for enemy in enemies:
		if enemy.dead or excluded.has(enemy): continue
		var distance = origin.distance_squared_to(enemy_center(enemy))
		if distance < best_distance: best_distance=distance;result=enemy
	return result

func enemy_center(enemy: Dictionary) -> Vector3:
	return enemy.node.position+Vector3.UP*float(enemy.get("height",1.7))*.5

func melee_contact(enemy: Dictionary,origin: Vector3) -> Vector3:
	var radius_value=float(enemy.get("radius",.6))
	var height_value=float(enemy.get("height",1.7))
	var axis=enemy.node.position+Vector3.UP*clampf(origin.y-enemy.node.position.y,radius_value,maxf(radius_value,height_value-radius_value))
	return axis+(origin-axis).normalized()*minf(radius_value,origin.distance_to(axis))

func nearest_melee(origin: Vector3,reach: float) -> Dictionary:
	var closest={};var distance_value=reach
	for enemy in enemies:
		if enemy.dead: continue
		var distance_to_body=origin.distance_to(melee_contact(enemy,origin))
		if distance_to_body<distance_value: closest=enemy;distance_value=distance_to_body
	return closest

func update_melee(delta: float):
	for swing in melee_attacks:
		swing.delay-=delta
		if swing.delay>0: continue
		slash_fx(swing.origin,swing.target)
		if swing.get("visual_only",false): continue
		var hits=0
		for enemy in enemies:
			if enemy.dead: continue
			var contact=melee_contact(enemy,swing.origin);var offset=contact-swing.origin
			if offset.length()>swing.reach or (offset.length()>.6 and offset.normalized().dot(swing.aim)<.45): continue
			var critical=rules.rng.randf()<stat("crit")
			if critical: career.bump("crits")
			hit_enemy(enemy,{"kind":"saw","damage":swing.damage*(stats.critPower if critical else 1.0)},"melee");hits+=1
		if hits>0: sound.effect("melee_hit",swing.target);vibrate(.12,.22,.08)
	melee_attacks=melee_attacks.filter(func(swing):return swing.delay>0)

func slash_fx(origin: Vector3,target: Vector3):
	if effects.size()>220: return
	var forward=(target-origin).normalized();var radius_value=maxf(.7,origin.distance_to(target))
	var vertices=PackedVector3Array();var uvs=PackedVector2Array();var indices=PackedInt32Array()
	for i in range(25):
		var angle=lerpf(-.85,.85,float(i)/24);var direction=forward.rotated(Vector3.UP,angle)
		var width=.04+.22*sin(PI*float(i)/24)
		vertices.append(direction*(radius_value-width));vertices.append(direction*(radius_value+width))
		uvs.append(Vector2(float(i)/24,0));uvs.append(Vector2(float(i)/24,1))
		if i<24: indices.append_array([i*2,i*2+1,i*2+2,i*2+1,i*2+3,i*2+2])
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var paint=ShaderMaterial.new();paint.shader=preload("res://shaders/melee_marks.gdshader");paint.set_shader_parameter("color",Color("fff1ba"))
	var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=paint;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node);node.position=origin
	effects.append({"node":node,"life":.24,"lifetime":.24,"velocity":Vector3.ZERO,"stationary":true,"mark_paint":paint,"slash":true})

func blood_hit(enemy: Dictionary):
	var now=Time.get_ticks_msec()/1000.0
	if now-float(enemy.get("blood_time",-100))<.14 or effects.size()>220: return
	enemy.blood_time=now
	var position_value=melee_contact(enemy,player.position+Vector3.UP*.95)
	var color=Color("c34f48")
	for i in range(5):
		var drop=shape(orb_mesh,color,self,position_value);drop.scale=Vector3(.14,.10,.14)
		effects.append({"node":drop,"life":.38,"velocity":Vector3(randf_range(-2,2),randf_range(1,3),randf_range(-2,2)),"blood":true,"base_scale":drop.scale})
	var mesh=PlaneMesh.new();mesh.size=Vector2(1.25,1.25)
	var paint=ShaderMaterial.new();paint.shader=preload("res://shaders/melee_marks.gdshader");paint.set_shader_parameter("color",color);paint.set_shader_parameter("splatter",true)
	var stain=MeshInstance3D.new();stain.mesh=mesh;stain.material_override=paint;stain.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(stain)
	stain.position=position_value;stain.position.y=world.height_at(position_value.x,position_value.z)+.035;stain.rotation.y=randf()*TAU
	effects.append({"node":stain,"life":1.1,"lifetime":1.1,"velocity":Vector3.ZERO,"stationary":true,"mark_paint":paint,"blood":true})

func spawn_network_enemy(actor: Dictionary) -> Dictionary:
	var node=CharacterBody3D.new();node.collision_layer=4;node.collision_mask=1
	var collision=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=1.05 if actor.boss else .53;capsule.height=3.4 if actor.boss else 1.7;collision.shape=capsule;collision.position.y=capsule.height*.5;node.add_child(collision)
	var entry=CreatureBook.entry(int(actor.biome),int(actor.species));var height=float(actor.get("height",9.0+realm*2 if actor.boss else entry.height*(1.25 if actor.elite else 1.0)));capsule.height=height;capsule.radius=float(actor.get("radius",2.8 if actor.boss else entry.radius));collision.position.y=height*.5;var rig=world.model("creature_%d_5" % int(actor.biome) if actor.boss else entry.model,height);node.add_child(rig);node.set_meta("rig",rig);node.position=CoopSession.vector(actor.position);add_child(node)
	var enemy={"net_id":int(actor.id),"node":node,"hp":float(actor.hp),"maxHp":float(actor.maxHp),"boss":bool(actor.boss),"elite":bool(actor.elite),"biome":int(actor.biome),"dead":false,"speed":0.0,"fire":0.0,"poison":0.0,"status_time":0.0,"freeze":0.0,"blind":0.0,"slow":0.0,"phase":1,"startDamage":health_damage,"contact":0.0,"attack":2.5};enemy.merge(entry);enemy.height=height;enemy.radius=capsule.radius;enemy.flying=entry.flying and not enemy.boss;enemy.xp_reward=float(actor.get("xp_reward",enemy_xp_reward(enemy)))
	if not enemy.boss: rig.bake_enemy()
	if enemy.boss:
		boss_name=["World Maw","Sun Breaker","Star Eater"][realm]
		var label=Label3D.new();label.font_size=45;label.position.y=height+.8;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;node.add_child(label);enemy.label=label
	enemies.append(enemy);return enemy

func fire(weapon: Dictionary, origin: Vector3):
	if weapon.id == "flowers": return
	if weapon.id=="saw":
		if not avatar.melee.is_empty(): return
		var reach=float(weapon.range)*stat("range")/18.0
		var victim=nearest_melee(origin,reach)
		if victim.is_empty(): return
		var contact=melee_contact(victim,origin);var duration=clampf(.8/(weapon.rate*stat("rate")),.07,.44)
		avatar.begin_melee("saw",contact,duration);sound.effect("slash",origin);coop.shot("saw",origin,contact,duration)
		melee_attacks.append({"origin":origin,"target":contact,"aim":(contact-origin).normalized(),"reach":reach,"damage":stat("damage")*weapon.damage*weapon.power*(1+stats.get("airDamage",0.0) if not player.is_on_floor() else 1.0),"delay":duration*.5})
		return
	var target = nearest_enemy(origin,weapon.range*stat("range")/18.0*(stats.turretRange if weapon.turret else 1.0))
	if target.is_empty(): return
	avatar.shot(weapon.id)
	if weapon.id not in ["saw","flame","fire-turret"]: sound.effect(weapon.id,origin)
	avatar.aim_weapon(weapon.id,enemy_center(target))
	if not weapon.turret: origin=avatar.muzzle_position(weapon.id)
	elif weapon.node.has_meta("model"): weapon.node.get_meta("model").shoot()
	coop.shot(weapon.id,origin,enemy_center(target))
	var shot_count = (3 if weapon.id == "shotgun" else 1)+mini(7,int(stats.multishot))
	var aim = (enemy_center(target)-origin).normalized()
	var base_damage=stat("damage")*weapon.damage*weapon.power*stats.get(weapon.id+"Power",1.0)*(1+stats.get("airDamage",0.0) if not player.is_on_floor() else 1.0)
	if weapon.id=="horn":
		for enemy in enemies:
			var offset=enemy_center(enemy)-origin
			if not enemy.dead and offset.length()<weapon.range and offset.normalized().dot(aim)>.55:
				hurt_enemy(enemy,base_damage,"sonic","horn");enemy.freeze=maxf(enemy.freeze,.35+stats.hornStun)
				if not enemy.boss: enemy.node.move_and_collide(aim*1.5)
		beam(origin,origin+aim*weapon.range,Color("e5cb98"));burst(origin+aim*3,Color("e5cb98"),8);return
	if weapon.id=="gravity":
		var radius_value=3.0*stats.gravitySize
		var disk=CylinderMesh.new();disk.top_radius=radius_value;disk.bottom_radius=radius_value;disk.height=.08
		var well=shape(disk,Color("9277b1"),self,target.node.position+Vector3.UP*.12)
		pools.append({"node":well,"life":3.0,"radius":radius_value,"gravity":true,"damage":base_damage*.65});return
	if weapon.id=="meteor":
		for meteor_index in range(1+mini(5,int(stats.meteorCount))):
			var position_value=target.node.position+Vector3.RIGHT.rotated(Vector3.UP,meteor_index*2.4)*meteor_index*.8
			position_value.y=world.height_at(position_value.x,position_value.z)
			var marker=CylinderMesh.new();marker.top_radius=3;marker.bottom_radius=3;marker.height=.04
			var warning=shape(marker,Color("f3c27f"),self,position_value+Vector3.UP*.08)
			hazards.append({"node":warning,"life":.85+meteor_index*.12,"radius":3.0,"damage":base_damage,"friendly":true})
			var meteor=shape(orb_mesh,Color("ee986d"),self,position_value+Vector3.UP*14,1.0);meteor.scale=Vector3.ONE*6
			effects.append({"node":meteor,"life":.85,"velocity":Vector3(0,-13,0),"meteor":true})
		return
	for i in range(shot_count):
		var node = MeshInstance3D.new()
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.mesh = brass_mesh if weapon.id in ["gun","shotgun","rail","harpoon","turret"] else load("res://assets/style3d/baked/weapon_"+weapon.id+".res") if weapon.id in ["boomerang","disc","bomb"] else projectile_mesh
		var color = PowerIcon.color_for(weapon.id)
		node.material_override = material(color,1.8)
		node.material_override.albedo_texture=load("res://assets/illustrated/paper.png")
		if node.mesh!=projectile_mesh: node.material_override=painted_shot
		node.position = origin
		node.scale = Vector3.ONE * minf(2.5,stats.size)*(1.6 if weapon.id.contains("rocket") else 1.0)
		add_child(node)
		if node.mesh==brass_mesh:
			node.scale*=2.5;node.look_at(origin+aim)
		var spread = (i-(shot_count-1)*.5)*.12
		var critical = rules.rng.randf()<stat("crit")
		if critical: career.bump("crits")
		var rage = 1+stats.berserk*(1-hp/stats.maxHp)
		var damage = base_damage*(stats.turretDamage if weapon.turret else 1.0)*rage*(stats.critPower if critical else 1.0)
		projectiles.append({"node":node,"velocity":aim.rotated(Vector3.UP,spread)*stats.projectileSpeed,"damage":damage,"life":2.0 if weapon.id=="boomerang" else 1.0 if weapon.id=="bomb" else weapon.range/stats.projectileSpeed+0.25,"kind":weapon.id,"hit":[],"pierce":int(stats.pierce)+(8 if weapon.id=="rail" else 3 if weapon.id=="harpoon" else 2+int(stats.boomerangPierce) if weapon.id=="boomerang" else 0),"bounce":int(stats.ricochet)+(3+int(stats.discBounces) if weapon.id=="disc" else 0),"return":stats.boomerang>0 or weapon.id=="boomerang","return_clock":.55})
	if projectiles.size() > 140:
		for i in range(projectiles.size()-140): projectiles[0].node.queue_free();projectiles.pop_front()


func remote_weapon_effect(id: String,origin: Vector3,target: Vector3,duration: float=.44):
	if id=="saw":
		melee_attacks.append({"origin":origin,"target":target,"delay":duration*.5,"visual_only":true});return
	if id=="gravity":
		var disk=CylinderMesh.new();disk.top_radius=3;disk.bottom_radius=3;disk.height=.08
		var point=target;point.y=world.height_at(point.x,point.z)+.12
		var well=shape(disk,Color("9277b1"),self,point)
		effects.append({"node":well,"life":3.0,"velocity":Vector3.ZERO,"stationary":true})
	elif id=="meteor":
		var meteor=shape(orb_mesh,Color("ee986d"),self,target+Vector3.UP*14);meteor.scale=Vector3.ONE*6
		effects.append({"node":meteor,"life":.85,"velocity":Vector3(0,-13,0),"meteor":true,"remote_impact":target})
	elif id in ["boomerang","disc","bomb","bubble","gun","shotgun","rail","harpoon","turret"]:
		var node=MeshInstance3D.new();node.mesh=load("res://assets/style3d/baked/weapon_"+id+".res") if id in ["boomerang","disc","bomb"] else orb_mesh if id=="bubble" else brass_mesh
		node.material_override=painted_shot;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node);node.position=origin
		var aim=(target-origin).normalized();node.look_at(origin+aim)
		effects.append({"node":node,"life":maxf(.05,origin.distance_to(target)/22),"velocity":aim*22,"visual_shot":true,"remote_impact":target,"bomb":id=="bomb"})
	else: beam(origin,target,PowerIcon.color_for(id))

func hit_enemy(enemy: Dictionary, shot: Dictionary,cause: String="hit"):
	var kind: String = shot.kind
	var damage = shot.damage
	if enemy.boss: damage *= stats.bossDamage
	hurt_enemy(enemy,damage,cause,kind)
	if not enemy.dead:
		if kind=="harpoon" and not enemy.boss: enemy.node.move_and_collide((player.position-enemy.node.position).normalized()*minf(4,1+stats.harpoonPull))
		if kind=="bubble":
			enemy.bubble=1.5*stats.bubbleTime;enemy.slow=maxf(enemy.slow,.7);enemy.status_time=enemy.bubble
			var shell=SphereMesh.new();shell.radius=enemy.get("radius",.7)*1.4;shell.height=shell.radius*2
			var pop=shape(shell,Color("c6e4ed"),self,enemy_center(enemy));pop.material_override=pop.material_override.duplicate();pop.material_override.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;pop.material_override.albedo_color.a=.22
			effects.append({"node":pop,"life":enemy.bubble,"velocity":Vector3.ZERO,"bubble_enemy":enemy})
		enemy.status_time = 4
		enemy.fire = maxf(enemy.fire,stats.burn + (10.0 if kind.contains("fire") or kind=="flame" else 0.0))
		enemy.poison = maxf(enemy.poison,stats.poison + (9.0 if kind.contains("poison") else 0.0))
		enemy.slow = maxf(enemy.slow,stats.slow + (.35 if kind.contains("ice") else 0.0))
		if rules.rng.randf()<stats.freeze or kind.contains("ice") and rules.rng.randf()<.3:
			enemy.freeze = .35 if enemy.boss else 1.6
			career.bump("freezes")
			burst(enemy.node.position+Vector3.UP*.85,Color("8be7ef"),3)
		if rules.rng.randf()<stats.blind:
			enemy.blind = 3
			career.bump("blinds")
		if enemy.fire>0 and enemy.freeze>0: achievement_event("HOT_COLD")
		if enemy.poison>0 and enemy.blind>0: achievement_event("TOXIC_DARK")
		if enemy.boss and enemy.blind>0: achievement_event("BOSS_BLIND")
		if enemy.boss and enemy.freeze>0: achievement_event("BOSS_ICE")
		if rules.rng.randf()<stats.stun: enemy.freeze=maxf(enemy.freeze,.4)
		if not enemy.boss and stats.knockback>0:
			enemy.node.move_and_collide((enemy.node.position-player.position).normalized()*minf(3,stats.knockback))
		if stats.execute > 0 and not enemy.boss and enemy.hp < enemy.maxHp*stats.execute: hurt_enemy(enemy,enemy.hp+1,"hit")
	heal(damage*stats.lifesteal)
	if kind=="bomb":
		damage_area(enemy.node.position,3.5*stats.bombSize,damage,"explosion",enemy)
	if stats.splash>0 or kind.contains("rocket"):
		damage_area(enemy.node.position,2.2,damage*maxf(stats.splash,0.75 if kind.contains("rocket") else 0),"explosion",enemy)
	var chains = mini(8,int(stats.chain)+(2 if kind.contains("lightning") else 0))
	var excluded = [enemy]
	var origin = enemy.node.position
	for i in range(chains):
		var next = nearest_enemy(origin,8,excluded)
		if next.is_empty(): break
		excluded.append(next)
		beam(origin+Vector3.UP,next.node.position+Vector3.UP,Color("b2e0f4"))
		hurt_enemy(next,damage*.6,"lightning")
		origin = next.node.position

func hurt_enemy(enemy: Dictionary, damage: float, cause: String,mechanic: String="",mechanic_origin: Vector3=Vector3.ZERO):
	if enemy.dead or damage <= 0: return
	if cause in ["hit","melee","coop","sonic","lightning","explosion","meteor","burrow","stomp"]: blood_hit(enemy)
	if coop.active and not coop.hosting:
		coop.hit(enemy,damage,mechanic if not mechanic.is_empty() else cause,mechanic_origin);enemy.node.get_meta("rig").hurt=.18;return
	enemy.hp -= damage
	enemy.node.get_meta("rig").set_health(enemy.hp/enemy.maxHp,enemy.boss or enemy.health>=1.8)
	if enemy.node.has_meta("rig"): enemy.node.get_meta("rig").hurt=.18
	if enemy.hp <= 0: kill_enemy(enemy,cause)

func kill_enemy(enemy: Dictionary, cause: String):
	if enemy.dead: return
	enemy.hp=0;enemy.node.get_meta("rig").set_health(0,enemy.boss or enemy.health>=1.8)
	coop.died(enemy,cause)
	enemy.dead = true
	if enemy.get("elite",false): drop_consumable(enemy.node.position)
	kills += 1
	career.bump("kills")
	if cause != "hit" and cause != "melee": career.bump(cause+"Kills")
	var p = enemy.node.position
	spawn_pickup(p+Vector3.UP*.35,"xp",float(enemy.get("xp_reward",enemy_xp_reward(enemy)))*stats.xpGain)
	spawn_pickup(p+Vector3.UP*.4,"gold",roundi((1+enemy.get("biome",0)*.2)*(40 if enemy.boss else (2+realm)*(3 if enemy.get("elite",false) else 1))*stats.goldGain))
	burst(p+Vector3.UP*.5,Color("c8aa75"),5)
	if enemy.boss:
		if hp < stats.maxHp*.25: achievement_event("COMEBACK")
		if health_damage == enemy.startDamage: achievement_event("NO_HIT_BOSS")
		if equipped.size()==1: achievement_event("ONE_WEAPON")
		if equipped.size()==1 and equipped[0].id=="flowers": achievement_event("PURE_GARDEN")
		if not equipped.any(func(w):return w.id in ["gun","shotgun","rail"]): achievement_event("NO_GUN")
		run_bosses += 1
		realm_bosses += 1
		career.bump("bosses")
		make_chest(p,true)
		gate.get_meta("marker").text = "☠ %d / 2" % realm_bosses
		if realm_bosses >= 2:
			gate.get_meta("marker").text = "→  NEXT" if realm < 2 else "★  WIN"
			sound.say("portal",0)
			hud.tell("→  GATE OPEN",6)
	if stats.explosion > 0 and cause != "explosion": damage_area(p,3.0,stats.explosion,"explosion",enemy)
	if stats.pools > 0:
		var node = MeshInstance3D.new()
		var disk = CylinderMesh.new()
		disk.top_radius = 2.3
		disk.bottom_radius = 2.3
		disk.height = .025
		node.mesh = disk
		node.material_override = material(Color("74a858"),.2)
		node.position = p+Vector3.UP*.06
		add_child(node)
		pools.append({"node":node,"life":5.0,"damage":stats.pools})
		if pools.size()>16: pools[0].node.queue_free();pools.pop_front()
	if rules.rng.randf()<stats.salvage: heal(4)
	var death=create_tween();death.tween_property(enemy.node,"scale",Vector3(.9,.08,.9),.24);death.tween_callback(enemy.node.queue_free)

func damage_area(origin: Vector3,radius: float,damage: float,cause: String,excluded: Dictionary = {}):
	for enemy in enemies.duplicate():
		if enemy != excluded and not enemy.dead and origin.distance_to(enemy.node.position) < radius: hurt_enemy(enemy,damage,cause)
	if cause in ["explosion","burrow"]: burst(origin+Vector3.UP,Color("f2b777"),8);explosion_fx(origin,radius)

func take_damage(amount: float, source: Vector3=Vector3.ZERO, voice_type: String="hit"):
	if invulnerable>0 or mode != "playing": return
	if rules.rng.randf()<stats.dodge: invulnerable=.18;return
	var absorbed = minf(shield_hp,amount)
	shield_hp -= absorbed
	shield_delay = 4
	if absorbed > 0:
		career.bump("shieldBlocks")
		achievement_event("BUBBLE")
		if shield_hp == 0: sound.say("shield_down",20)
	var taken = maxf(0,amount-absorbed)*100/(100+stat("armor")*6)
	hp -= taken
	update_hero_vitals()
	health_damage += taken
	if stats.hurtGold>0: achievement_event("HURT_PAY");gold += roundi(stats.hurtGold*maxf(1,taken))
	invulnerable = .55
	avatar.hurt=.35
	hit_shake=.25
	if source!=Vector3.ZERO:
		knock_velocity=(player.position-source).normalized()*8;knock_velocity.y=0
		player.velocity.y=maxf(player.velocity.y,1.7)
	sound.effect(voice_type,source)
	sound.hero_hurt(hero.id,player)
	vibrate(.35,.65,.13)
	if hp < stats.maxHp*.28 and not low_health_warned:
		low_health_warned = true
		sound.say("low_health",30)
	if hp <= 0:
		if stats.revive >= 1: achievement_event("REVIVE");stats.revive-=1;hp=stats.maxHp*.6;invulnerable=3;hud.tell("♥  ANOTHER LIFE")
		else: hp=0;end_run(false)

func dash():
	if dash_cooldown>0: return
	dash_time = .2
	dash_cooldown = stats.dashCooldown
	invulnerable = .3+stats.ghost
	ghost_time = stats.ghost
	career.bump("dashes")
	if stats.ghost>0:
		career.bump("ghostDashes")
		if boss_active(): achievement_event("GHOST_DANGER")
	if stats.burrow>0: burrow_time=.4;career.bump("burrows")
	if stats.dashBlast>0: damage_area(player.position,4.5,stats.dashBlast,"explosion")
	burst(player.position+Vector3.UP*.5,Color("b0d9ea"),7)
	sound.effect("dash")
	vibrate(.35,.2,.12)

func spawn_pickup(p: Vector3, kind: String, value: float):
	var node = MeshInstance3D.new()
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.mesh = coin_mesh if kind == "gold" else orb_mesh
	node.material_override = material(Color("edc361") if kind == "gold" else Color("88cfe2"),.3)
	if kind=="xp":
		node.material_override=node.material_override.duplicate();node.material_override.emission_enabled=true;node.material_override.emission=Color("88cfe2");node.material_override.emission_energy_multiplier=1.8
	node.position = p
	var direction=Vector3.RIGHT.rotated(Vector3.UP,rules.rng.randf()*TAU)
	var velocity=direction*.45+Vector3.UP*1.5
	if kind == "gold":
		# Coins scatter away from the XP drop, then fall even after aerial kills.
		node.position+=direction*rules.rng.randf_range(.8,1.15)
		velocity=direction*1.5+Vector3.UP*2.5
		node.rotation.z=PI/2
	add_child(node)
	var pickup={"node":node,"kind":kind,"value":value,"age":0.0,"base_y":p.y,"velocity":velocity,"settled":false,"bounced":false,"attracted":false,"merge_pulse":0.0}
	resize_xp(pickup,true);pickups.append(pickup)
	if pickups.size()>450:
		# Merge far drops rather than losing earned gold/XP at the effect cap.
		var old = pickups[0]
		for item in pickups:
			if item != old and item.kind == old.kind:
				item.value+=old.value;resize_xp(item);old.node.queue_free();pickups.pop_front();break

func resize_xp(pickup: Dictionary,instant: bool=false):
	if pickup.kind!="xp": return
	pickup.radius=clampf(.12*pow(maxf(1,pickup.value/1.5),1.0/3.0),.12,1.2)
	if instant: pickup.node.scale=Vector3.ONE*(pickup.radius/.12)

func merge_xp_orbs():
	# Hash touching spheres in 3D, including aerial drops, instead of comparing every pair.
	var cells={}
	for pickup in pickups:
		if pickup.kind!="xp" or pickup.age<0: continue
		var p: Vector3=pickup.node.position
		var cell=Vector3i(floori(p.x/3),floori(p.y/3),floori(p.z/3))
		if not cells.has(cell): cells[cell]=[]
		cells[cell].append(pickup)
	for pickup in pickups:
		if pickup.kind!="xp" or pickup.age<0: continue
		var p: Vector3=pickup.node.position
		var cell=Vector3i(floori(p.x/3),floori(p.y/3),floori(p.z/3))
		for x in range(-1,2):
			for y in range(-1,2):
				for z in range(-1,2):
					for other in cells.get(cell+Vector3i(x,y,z),[]):
						if pickup.age<0: break
						if other==pickup or other.age<0: continue
						if pickup.node.position.distance_to(other.node.position)>pickup.radius+other.radius+.035: continue
						var big=pickup if pickup.value>=other.value else other
						var small=other if big==pickup else pickup
						big.value+=small.value;big.merge_pulse=.22;big.attracted=big.attracted or small.attracted;resize_xp(big)
						small.age=-1
						var blob=small.node;var target=big.node
						var tween=create_tween().set_parallel(true)
						tween.tween_property(blob,"position",target.position,.16).set_trans(Tween.TRANS_QUAD)
						tween.tween_property(blob,"scale",Vector3.ONE*.02,.16)
						tween.chain().tween_callback(blob.queue_free)
	pickups=pickups.filter(func(pickup):return pickup.age>=0)

func update_pickups(delta: float):
	merge_xp_orbs()
	for pickup in pickups:
		if pickup.age<0: continue
		pickup.age+=delta
		if pickup.kind=="xp":
			pickup.merge_pulse=maxf(0,pickup.merge_pulse-delta)
			var size_value=pickup.radius/.12*(1+sin(pickup.merge_pulse/.22*PI)*.12)
			pickup.node.scale=pickup.node.scale.lerp(Vector3.ONE*size_value,minf(1,delta*18))
			if pickup.settled and not pickup.attracted: pickup.node.position.y=world.height_at(pickup.node.position.x,pickup.node.position.z)+pickup.radius+.01
		var distance=player.position.distance_to(pickup.node.position)
		var radius=stats.coinRadius if pickup.kind=="gold" else stat("pickup")
		if distance<radius: pickup.attracted=true
		if pickup.attracted:
			pickup.node.position=pickup.node.position.move_toward(player.position+Vector3.UP*.4,delta*14)
		else:
			if not pickup.settled:
				pickup.velocity.y-=24*delta
				pickup.node.position+=pickup.velocity*delta
				var p: Vector3=pickup.node.position
				var floor_y=world.height_at(p.x,p.z)+(.27 if pickup.kind=="gold" else pickup.radius+.01)
				if p.y<=floor_y:
					pickup.node.position.y=floor_y
					if not pickup.bounced and pickup.velocity.y< -3:
						pickup.velocity.y=absf(pickup.velocity.y)*.22;pickup.velocity.x*=.35;pickup.velocity.z*=.35;pickup.bounced=true
					else: pickup.velocity=Vector3.ZERO;pickup.settled=true
		pickup.node.rotation.y+=delta*2
		if player.position.distance_to(pickup.node.position)<1.05+float(pickup.get("radius",.12))-.12:
			if pickup.kind=="gold": gold+=roundi(pickup.value*stat("goldGain")/stats.goldGain);heal(stats.coinHeal);sound.effect("coin")
			else: xp+=pickup.value*(stat("xpGain")/stats.xpGain)
			pickup.node.queue_free();pickup.age=-1
	pickups=pickups.filter(func(pickup):return pickup.age>=0)

func burst(p: Vector3,color: Color,count: int):
	for i in range(mini(count,20)):
		var node = shape(orb_mesh,color,self,p,.4)
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var velocity = Vector3(randf_range(-3,3),randf_range(1,5),randf_range(-3,3))
		effects.append({"node":node,"life":.55,"velocity":velocity})

func explosion_fx(p: Vector3, radius_value: float):
	sound.effect("blast",p)
	var mesh=SphereMesh.new();mesh.radius=1;mesh.height=2;mesh.radial_segments=16;mesh.rings=8
	var node=MeshInstance3D.new();node.mesh=mesh;node.position=p+Vector3.UP*.3;add_child(node)
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var paint=ShaderMaterial.new();paint.shader=load("res://shaders/explosion.gdshader");paint.set_shader_parameter("paper",load("res://assets/illustrated/paper.png"));node.material_override=paint
	effects.append({"node":node,"life":.65,"velocity":Vector3.ZERO,"blast_radius":radius_value,"paint":paint,"age":0.0})

func beam(from: Vector3,to: Vector3,color: Color):
	var cylinder = CylinderMesh.new()
	cylinder.top_radius=.025
	cylinder.bottom_radius=.025
	cylinder.height=from.distance_to(to)
	var node = shape(cylinder,color,self,(from+to)*.5,2)
	if from.distance_to(to)>.01:
		node.look_at(to,Vector3.FORWARD)
		node.rotate_object_local(Vector3.RIGHT,PI/2)
	effects.append({"node":node,"life":.16,"velocity":Vector3.ZERO})

func telegraph(enemy: Dictionary):
	enemy.node.get_meta("rig").attack=1.0
	var target=coop.target(enemy.node.position).position
	var style_name=["roots","toxic","meteor","storm","lava","void"][enemy.biome]
	var count=2+enemy.phase if enemy.biome in [0,2,3,4] else 1
	for i in range(count):
		var p=target+Vector3.RIGHT.rotated(Vector3.UP,i*TAU/count+elapsed)*(0 if i==0 else 3.5+enemy.phase)
		var radius_value=3.0 if count>1 else 5.0+enemy.phase
		warn_at(p,radius_value,1.4+i*.18,25+realm*10,style_name)
		if coop.active and coop.hosting: coop.broadcast({"type":"hazard","position":CoopSession.array(p),"radius":radius_value,"delay":1.4+i*.18,"damage":25+realm*10,"style":style_name,"realm":realm})

func warn_at(p: Vector3,radius_value: float,delay: float,damage_value: float,style_name: String):
	p.y=world.height_at(p.x,p.z)
	var ring=TorusMesh.new();ring.inner_radius=radius_value-.12;ring.outer_radius=radius_value
	var node=shape(ring,Color("d67565") if style_name!="void" else Color("9683c5"),self,p+Vector3.UP*.08,.3)
	hazards.append({"node":node,"life":delay,"radius":radius_value,"damage":damage_value,"style":style_name})

func update_combat(delta: float):
	update_melee(delta)
	enemy_step+=delta
	var update_enemies=enemy_step>=1.0/30.0
	var enemy_delta=enemy_step
	if update_enemies: enemy_step=0
	spawn_clock -= delta
	if spawn_clock <= 0:
		var swarm = events.get("swarm_until",0.0)>realm_time
		var count = 2+realm+(3 if swarm or realm_time>600 else 0)
		for i in range(count): spawn_enemy(randf_range(18,25))
		spawn_clock = maxf(.4,.95-realm_time*.0005)/(1.35 if swarm else 1.0)
	crowd.clear()
	for enemy in enemies:
		if enemy.dead: continue
		var cell=Vector2i(floori(enemy.node.position.x/3),floori(enemy.node.position.z/3))
		if not crowd.has(cell): crowd[cell]=[]
		crowd[cell].append(enemy)
	update_garden(delta)
	for weapon in equipped:
		if weapon.id=="flowers": continue
		if hp<=0: continue
		weapon.clock -= delta
		weapon.deploy_clock -= delta
		var origin = player.position+Vector3.UP*.9
		if weapon.turret:
			if not is_instance_valid(weapon.node): deploy_turret(weapon)
			origin = weapon.node.position+Vector3.UP*.9
			var target = nearest_enemy(origin,weapon.range)
			if not target.is_empty(): weapon.node.rotation.y=atan2(origin.x-target.node.position.x,origin.z-target.node.position.z)
			if stats.repair>0 and origin.distance_to(player.position)<5: heal(stats.repair*delta)
		if weapon.id in ["saw","flame","fire-turret"]: sound.weapon_loop(weapon.id,not (nearest_melee(origin,weapon.range*stat("range")/18.0) if weapon.id=="saw" else nearest_enemy(origin,weapon.range)).is_empty(),origin)
		if weapon.turret and weapon.node.has_meta("model"): weapon.node.get_meta("model").tick(delta)
		if weapon.clock<=0:
			fire(weapon,origin)
			weapon.clock = 1.0/(weapon.rate*(stats.turretRate if weapon.turret else stat("rate")))
	for enemy in enemies:
		if enemy.dead or not update_enemies: continue
		if coop.active and not coop.hosting:
			var previous=enemy.node.position
			enemy.node.position=enemy.node.position.lerp(enemy.get("target_position",previous),1-exp(-enemy_delta*16))
			var rig=enemy.node.get_meta("rig");rig.set_health(enemy.hp/enemy.maxHp,enemy.boss or enemy.health>=1.8);rig.animate(enemy_delta,(enemy.node.position-previous)/enemy_delta,true);rig.statuses(enemy.fire>0,enemy.poison>0,enemy.freeze>0,enemy.blind>0)
			if enemy.boss: enemy.label.text="%s  %d%%" % [boss_name,enemy.hp/enemy.maxHp*100]
			continue
		enemy.freeze = maxf(0,enemy.freeze-enemy_delta)
		enemy.blind = maxf(0,enemy.blind-enemy_delta)
		if enemy.status_time > 0:
			enemy.status_time -= enemy_delta
			if enemy.poison>0: hurt_enemy(enemy,enemy.poison*enemy_delta,"poison")
			if enemy.fire>0: hurt_enemy(enemy,enemy.fire*enemy_delta,"fire")
			if enemy.dead: continue
		else: enemy.poison=0;enemy.fire=0;enemy.slow=0
		var target_player=coop.target(enemy.node.position)
		var toward = target_player.position-enemy.node.position
		toward.y = 0
		var distance = toward.length()
		var aim=toward.normalized() if enemy.blind<=0 else Vector3(sin(elapsed*1.2+distance),0,cos(elapsed*1.2+distance))
		if distance<enemy.radius+.65 and absf(target_player.position.y-enemy.node.position.y)<2.0: aim=-aim*.2
		if not enemy.boss:
			if enemy.behavior=="swoop": aim=aim.rotated(Vector3.UP,sin(elapsed*2+enemy.species)*.55)
			if enemy.behavior=="skitter": aim=aim.rotated(Vector3.UP,sin(elapsed*6+distance)*.8)
			if enemy.behavior=="spit":
				enemy.attack-=enemy_delta
				if distance<14 and enemy.attack<=0:
					enemy.attack=4.5;enemy.node.get_meta("rig").attack=.4
					warn_at(target_player.position,1.6,.9,12*enemy.damage,"toxic")
					coop.broadcast({"type":"hazard","realm":realm,"position":coop.array(target_player.position),"radius":1.6,"delay":.9,"damage":12*enemy.damage,"style":"toxic"})
				if distance<7: aim=-aim*.6
		aim=steer_enemy(enemy,aim)
		var cell=Vector2i(floori(enemy.node.position.x/3),floori(enemy.node.position.z/3))
		var separation=Vector3.ZERO
		var neighbors=ceili((enemy.radius+1.5)/3.0)
		for x in range(-neighbors,neighbors+1):
			for z in range(-neighbors,neighbors+1):
				for other in crowd.get(cell+Vector2i(x,z),[]):
					if other==enemy or other.dead: continue
					var away=enemy.node.position-other.node.position;away.y=0
					var spacing=enemy.radius+other.get("radius",.53)+.2
					if absf(enemy.node.position.y-other.node.position.y)<minf(enemy.height,other.get("height",1.7)) and away.length_squared()<spacing*spacing:
						var apart=away.normalized() if away.length_squared()>.00001 else Vector3.RIGHT*(1 if enemy.net_id>other.net_id else -1)
						separation+=apart*(spacing-away.length())*3
		if not enemy.boss and enemy.behavior=="charge":
			enemy.attack-=enemy_delta
			if enemy.attack<0 and distance<9: enemy.charge=.55;enemy.attack=4;enemy.node.get_meta("rig").attack=.55
			enemy.charge=maxf(0,enemy.get("charge",0)-enemy_delta)
		var velocity=(aim*enemy.speed*(2 if enemy.get("charge",0)>0 else 1)*(1-minf(.7,enemy.slow))+separation) if enemy.freeze<=0 else Vector3.ZERO
		var body: CharacterBody3D=enemy.node
		body.velocity.x=velocity.x*(enemy_delta/delta);body.velocity.z=velocity.z*(enemy_delta/delta)
		var vertical=enemy.get("vertical",0.0)
		enemy.bubble=maxf(0,enemy.get("bubble",0.0)-enemy_delta)
		if enemy.bubble>0 and not enemy.boss:
			vertical=clampf((world.height_at(body.position.x,body.position.z)+1.8-body.position.y)*3,-3,3)
		elif enemy.get("flying",false):
			var cruise=enemy.altitude*(.15 if fmod(elapsed+enemy.net_id,9.0)>7 else 1.0)
			vertical=clampf((world.height_at(body.position.x,body.position.z)+cruise-body.position.y)*3,-6,6)
		elif not body.is_on_floor(): vertical-=24*enemy_delta
		body.velocity.y=vertical*(enemy_delta/delta)
		body.move_and_slide()
		# Resolve overlapping horizontal footprints without making capsules climb each other.
		var corrected=body.position
		for x in range(-neighbors,neighbors+1):
			for z in range(-neighbors,neighbors+1):
				for other in crowd.get(cell+Vector2i(x,z),[]):
					if other==enemy or other.dead: continue
					if absf(body.position.y-other.node.position.y)>=minf(enemy.height,other.get("height",1.7)): continue
					var offset: Vector3=corrected-other.node.position;offset.y=0
					var gap: float=offset.length();var required: float=enemy.radius+other.get("radius",.53)
					if gap<required:
						var direction=offset/gap if gap>.001 else Vector3.RIGHT*(1 if enemy.net_id>other.net_id else -1)
						corrected+=direction*(required-gap+.005)
		if corrected.distance_squared_to(body.position)>.00001:
			# Slide the separation push along scenery; keep the valid forward movement.
			var push=(corrected-body.position).limit_length(maxf(.12,enemy_delta*8))
			var collision=body.move_and_collide(push)
			if collision!=null:
				var slide=collision.get_remainder().slide(collision.get_normal());slide.y=0
				body.move_and_collide(slide)
		enemy.vertical=body.velocity.y/(enemy_delta/delta)
		if body.position.y<world.height_at(body.position.x,body.position.z)-4: body.position.y=world.height_at(body.position.x,body.position.z)+.3;body.velocity.y=0
		if aim.length()>.01: body.rotation.y=lerp_angle(body.rotation.y,atan2(-aim.x,-aim.z),enemy_delta*6)
		if body.has_meta("rig"):
			var rig: ActorRig=body.get_meta("rig")
			rig.set_health(enemy.hp/enemy.maxHp,enemy.boss or enemy.health>=1.8)
			rig.animate(enemy_delta,body.velocity,body.is_on_floor())
			rig.statuses(enemy.fire>0,enemy.poison>0,enemy.freeze>0,enemy.blind>0)
		enemy.contact=maxf(0,enemy.get("contact",0)-enemy_delta)
		if distance < enemy.radius+.85 and absf(target_player.position.y-enemy.node.position.y)<2.2 and enemy.contact<=0:
			enemy.contact=.7
			enemy.node.get_meta("rig").attack=.25
			coop.damage_player(target_player.id,(18+realm*5 if enemy.boss else 11+realm*4)*enemy.damage*(1+enemy.get("biome",0)*.12),enemy.node.position,enemy.sound)
			if target_player.id==coop.local_id:
				if enemy.get("biome",0)==1 and not buffs.has("poison"): player_poison=3
				if enemy.get("biome",0)==4 and not buffs.has("fire"): player_fire=3
				if enemy.get("biome",0)==3: player_chill=2
				if enemy.get("biome",0)==5: player_blind=2
				if stats.thorns>0: hurt_enemy(enemy,stats.thorns*enemy_delta*2,"thorn")
		if enemy.boss:
			enemy.phase = 2 if enemy.hp<enemy.maxHp*.5 else 1
			enemy.label.text = "%s  %d%%" % [boss_name,enemy.hp/enemy.maxHp*100]
			enemy.attack -= enemy_delta
			if enemy.attack<=0 and enemy.blind<=0: telegraph(enemy);enemy.attack=2.7 if enemy.phase==2 else 4
		if stats.auraDamage>0 and distance<4: hurt_enemy(enemy,stats.auraDamage*enemy_delta,"aura")
	for shot in projectiles:
		shot.life -= delta
		shot.return_clock -= delta
		if shot.return and shot.return_clock<=0:
			if not shot.get("returning",false): shot.hit.clear();shot.returning=true
			shot.velocity = (player.position+Vector3.UP*.9-shot.node.position).normalized()*stats.projectileSpeed
			if shot.node.position.distance_to(player.position+Vector3.UP*.9)<.6: shot.life=0
		shot.node.position += shot.velocity*delta
		if shot.kind in ["boomerang","disc"]: shot.node.rotation.y+=delta*18
		if shot.kind=="bomb":
			shot.node.position.y=world.height_at(shot.node.position.x,shot.node.position.z)+.3;shot.node.rotation.x+=delta*9
		if shot.life<=0:
			if shot.kind=="bomb": damage_area(shot.node.position,3.5*stats.bombSize,shot.damage,"explosion")
			continue
		for enemy in enemies:
			if enemy.dead or shot.hit.has(enemy): continue
			if shot.node.position.distance_to(enemy_center(enemy)) < maxf(enemy.get("radius",.7),enemy.get("height",1.7)*.35):
				shot.hit.append(enemy)
				hit_enemy(enemy,shot)
				if shot.bounce>0:
					var target=nearest_enemy(shot.node.position,12,shot.hit)
					if not target.is_empty(): shot.velocity=(enemy_center(target)-shot.node.position).normalized()*stats.projectileSpeed;shot.bounce-=1;break
				shot.pierce-=1
				if shot.pierce<0 and not shot.return: shot.life=0;break
	update_pickups(delta)
	for pool in pools:
		pool.life-=delta
		for enemy in enemies:
			if not enemy.dead and enemy.node.position.distance_to(pool.node.position)<pool.get("radius",2.5)+enemy.get("radius",0):
				hurt_enemy(enemy,pool.damage*delta,"gravity" if pool.get("gravity",false) else "poison","gravity" if pool.get("gravity",false) else "",pool.node.position)
				if pool.get("gravity",false) and not enemy.boss: enemy.node.move_and_collide((pool.node.position-enemy.node.position).normalized()*delta*3)
	for hazard in hazards:
		hazard.life-=delta
		hazard.node.rotation.y+=delta*.6
		if hazard.get("style","")=="void" and hazard.node.position.distance_to(player.position)<hazard.radius*1.8:
			player.move_and_collide((hazard.node.position-player.position).normalized()*delta*2)
		if hazard.life<=0:
			if hazard.get("friendly",false): damage_area(hazard.node.position,hazard.radius,hazard.damage,"meteor")
			elif player.position.distance_to(hazard.node.position)<hazard.radius: take_damage(hazard.damage)
			if not hazard.get("friendly",false) and coop.active and coop.hosting:
				for id in coop.members:
					if CoopSession.vector(coop.members[id].get("position",[])).distance_to(hazard.node.position)<hazard.radius: coop.damage_player(id,hazard.damage,hazard.node.position,"blast")
			burst(hazard.node.position+Vector3.UP,Color("f69559"),10)
			explosion_fx(hazard.node.position,hazard.radius)
			match hazard.get("style",""):
				"storm": beam(hazard.node.position+Vector3.UP*35,hazard.node.position,Color("b2dfec"))
				"roots":
					for spike_index in range(5):
						var spike=PrismMesh.new();spike.size=Vector3(.4,3,.4)
						var spike_node=shape(spike,Color("8ea57c"),self,hazard.node.position+Vector3.RIGHT.rotated(Vector3.UP,spike_index*1.4)*2+Vector3.UP*1.4)
						effects.append({"node":spike_node,"life":.55,"velocity":Vector3.UP*2})
				"toxic":
					if not hazard.get("friendly",false): player_poison=3 if player.position.distance_to(hazard.node.position)<hazard.radius and not buffs.has("poison") else player_poison
			hazard.node.queue_free()
	for pot in pots:
		if player.position.distance_to(pot.node.position)<3:
			spawn_pickup(pot.node.position+Vector3.UP*.4,"gold",roundi(rules.rng.randi_range(6,12)*stats.potGold))
			pot.node.queue_free()
			pot.dead=true
	for chest in chests:
		if player.position.distance_to(chest.node.position)<26: chest.discovered=true
	enemies = enemies.filter(func(enemy):return not enemy.dead)
	for shot in projectiles:
		if shot.life<=0: shot.node.queue_free()
	projectiles=projectiles.filter(func(shot):return shot.life>0)
	pickups=pickups.filter(func(pickup):return pickup.age>=0)
	for pool in pools:
		if pool.life<=0: pool.node.queue_free()
	pools=pools.filter(func(pool):return pool.life>0)
	hazards=hazards.filter(func(hazard):return hazard.life>0)
	pots=pots.filter(func(pot):return not pot.get("dead",false))
	storm_clock-=delta
	nova_clock-=delta
	if storm_clock<=0:
		if stats.storm>0:
			for enemy in enemies.slice(0,mini(enemies.size(),4)):
				beam(enemy.node.position+Vector3.UP*12,enemy.node.position+Vector3.UP,Color("b9dfef"))
				hurt_enemy(enemy,stats.storm,"lightning")
		storm_clock=5
	if nova_clock<=0:
		if stats.nova>0: damage_area(player.position,7,stats.nova,"explosion")
		nova_clock=6
	if xp>=xp_target and mode=="playing": level_up()

func update_events():
	for item in [[150,"warn_one","boss"],[180,"boss_one","spawn"],[210,"warn_swarm","swarm"],[240,"swarm_one","rush"],[390,"warn_swarm_two","swarm"],[420,"swarm_two","rush"],[450,"warn_two","boss"],[480,"boss_two","spawn"],[600,"overtime","rush"]]:
		if realm_time>=item[0] and not events.has(item[1]):
			events[item[1]]=true
			if item[2]=="spawn": spawn_enemy(18,true)
			if item[2] in ["boss","swarm"]: sound.say(item[2],0);hud.tell("☠  00:30" if item[2]=="boss" else "☠☠☠  00:30",4)
			if item[2]=="rush": events.swarm_until=realm_time+25

func _physics_process(delta: float):
	var pads = Input.get_connected_joypads()
	if not pads.is_empty(): controller_id=pads[0]
	else: controller_id=-1
	if coop.active and coop.hosting and mode=="ended" and not coop.frozen():
		realm_time+=delta;elapsed+=delta;update_events();update_combat(delta);return
	if mode != "playing": return
	if coop.frozen(): return
	update_exploration(delta)
	elapsed+=delta
	realm_time+=delta
	var movement = Input.get_vector("move_left","move_right","move_forward","move_back")
	if network_test_role=="client" and player.position.x<4: movement=Vector2.RIGHT
	if controller_id>=0:
		var stick = Vector2(Input.get_joy_axis(controller_id,JOY_AXIS_LEFT_X),Input.get_joy_axis(controller_id,JOY_AXIS_LEFT_Y))
		if stick.length()>.18: movement+=stick.normalized()*minf(1,(stick.length()-.18)/.82)
		var look = Vector2(Input.get_joy_axis(controller_id,JOY_AXIS_RIGHT_X),Input.get_joy_axis(controller_id,JOY_AXIS_RIGHT_Y))
		if look.length()>.18:
			var filtered = look.normalized()*minf(1,(look.length()-.18)/.82)
			camera_look(filtered*Vector2(2,.65)*delta)
	if movement.length()>1: movement=movement.normalized()
	yaw += delta*((1.6 if Input.is_action_pressed("camera_left") else 0)-(1.6 if Input.is_action_pressed("camera_right") else 0))
	var wish = Vector3(movement.x,0,movement.y).rotated(Vector3.UP,yaw)
	if not player.is_on_floor(): wish*=1+minf(.5,stats.airControl)
	if wish.length()>.1: direction=wish.normalized()
	var facing=direction
	var target=nearest_enemy(player.position,24)
	if not target.is_empty(): facing=(target.node.position-player.position).normalized()
	avatar.rotation.y=lerp_angle(avatar.rotation.y,atan2(-facing.x,-facing.z),delta*9)
	var previous = player.position
	dash_time=maxf(0,dash_time-delta)
	dash_cooldown=maxf(0,dash_cooldown-delta)
	invulnerable=maxf(0,invulnerable-delta)
	ghost_time=maxf(0,ghost_time-delta)
	burrow_time=maxf(0,burrow_time-delta)
	if dash_time>0: player.velocity.x=direction.x*stats.speed*3;player.velocity.z=direction.z*stats.speed*3
	else: player.velocity.x=wish.x*stat("speed");player.velocity.z=wish.z*stat("speed")
	if player_chill>0: player.velocity.x*=.7;player.velocity.z*=.7
	player.velocity.x+=knock_velocity.x;player.velocity.z+=knock_velocity.z
	knock_velocity=knock_velocity.move_toward(Vector3.ZERO,delta*30)
	if not player.is_on_floor(): player.velocity.y-=24*delta
	var was_grounded=player.is_on_floor()
	peak_height=maxf(peak_height,player.position.y)
	var falling_speed=player.velocity.y
	player.move_and_slide()
	check_stomp(previous,falling_speed)
	check_landing(was_grounded)
	player.position.x=clampf(player.position.x,-497,497)
	player.position.z=clampf(player.position.z,-497,497)
	if player.position.y<world.height_at(player.position.x,player.position.z)-5: recover_player()
	update_boiling_edge()
	if mode!="playing": return
	update_hero_vitals()
	avatar.animate(delta,player.velocity,player.is_on_floor(),slamming)
	avatar.statuses(player_fire>0,player_poison>0,player_chill>0,player_blind>0)
	avatar.visible=burrow_time<=0
	if burrow_time==0 and events.get("burrowing",false): damage_area(player.position,5.5,stats.burrow,"burrow");events.burrowing=false
	if burrow_time>0: events.burrowing=true
	walking_gold+=previous.distance_to(player.position)*stats.walkGold
	if walking_gold>=1: achievement_event("WALK_PAY");gold+=int(walking_gold);walking_gold-=int(walking_gold)
	shield_delay=maxf(0,shield_delay-delta)
	if shield_delay==0 and shield_hp<stats.shield: shield_hp=minf(stats.shield,shield_hp+maxf(2,stats.shield*.1)*delta)
	heal(stat("regen")*delta)
	if hp>stats.maxHp*.45: low_health_warned=false
	var minute=int(realm_time)/60
	if minute>last_minute:
		last_minute=minute
		if roundi(gold*stats.interest)>0: achievement_event("INTEREST")
		gold+=roundi(gold*stats.interest)
	update_events()
	update_combat(delta)
	metric_clock+=delta
	if metric_clock>=1:
		metric_clock=0
		check_creative_goals()
		career.best("seconds",elapsed)
		career.best("bestLevel",level)
		for key in ["maxHp","damage","rate","multishot"]: career.best(key,stats[key])
		career.best("turrets",equipped.filter(func(weapon):return weapon.turret).size())
		var can_afford=gold>=rules.chest_price(paid_chests,stats.discount)
		if can_afford and not affordable_warned and chests.any(func(chest):return chest.discovered and not chest.opened): sound.say("affordable",30);affordable_warned=true
		if not can_afford: affordable_warned=false

func _process(delta: float):
	if not is_instance_valid(avatar): return
	coop.tick(delta)
	menu_repeat=maxf(0,menu_repeat-delta)
	if hud.modal.visible and input_kind=="xbox" and controller_id>=0 and menu_repeat<=0:
		var menu_stick=Vector2(Input.get_joy_axis(controller_id,JOY_AXIS_LEFT_X),Input.get_joy_axis(controller_id,JOY_AXIS_LEFT_Y))
		if menu_stick.length()>.55:
			hud.controller_move(Vector2(signf(menu_stick.x),0) if absf(menu_stick.x)>absf(menu_stick.y) else Vector2(0,signf(menu_stick.y)));menu_repeat=.22
	world.stream(player.position)
	world.weather_tick(delta,player.position)
	sound.weapon_loop("steam",world.edge_near,player.position)
	if mode=="level_reveal":
		level_reveal-=delta
		if level_reveal<=0: mode="offer";hud.show_offers(offers,"level")
	var anchor=player.position+Vector3.UP*1.2
	var offset=Vector3(sin(yaw)*camera_distance,2.4+pitch*6,cos(yaw)*camera_distance)
	var desired=player.position+offset
	var ray=PhysicsRayQueryParameters3D.create(anchor,desired)
	ray.collision_mask=1
	ray.exclude=[player.get_rid()]
	var obstacle=get_world_3d().direct_space_state.intersect_ray(ray)
	if not obstacle.is_empty(): desired=obstacle.position+(anchor-obstacle.position).normalized()*.4
	camera.position=camera.position.lerp(desired,1-exp(-delta*9))
	hit_shake=maxf(0,hit_shake-delta)
	if hit_shake>0: camera.position+=Vector3(sin(hit_shake*140),cos(hit_shake*110),0)*hit_shake*.32
	camera.look_at(anchor-Vector3(sin(yaw)*2,0,cos(yaw)*2))
	for effect in effects:
		effect.life-=delta
		effect.node.position+=effect.velocity*delta
		if not effect.get("visual_shot",false) and not effect.get("stationary",false): effect.velocity.y-=8*delta
		effect.node.scale=Vector3.ONE*maxf(.05,effect.life/.55)
		if effect.has("blast_radius"):
			effect.age+=delta;effect.node.scale=Vector3.ONE*effect.blast_radius*(.2+effect.age*1.5);effect.paint.set_shader_parameter("age",effect.age/.65)
		elif effect.has("bubble_enemy"):
			if not effect.bubble_enemy.dead and is_instance_valid(effect.bubble_enemy.node): effect.node.position=enemy_center(effect.bubble_enemy)
			else: effect.life=0
			effect.velocity=Vector3.ZERO;effect.node.scale=Vector3.ONE
		elif effect.get("meteor",false): effect.node.scale=Vector3.ONE*6
		elif effect.get("visual_shot",false) or effect.get("stationary",false): effect.node.scale=Vector3.ONE
		if effect.has("mark_paint"): effect.mark_paint.set_shader_parameter("fade",clampf(effect.life/effect.lifetime,0,1))
		if effect.has("base_scale"): effect.node.scale=effect.base_scale*minf(1,effect.life/.12)
		if effect.life<=0:
			if effect.has("remote_impact") and (effect.get("meteor",false) or effect.get("bomb",false)): explosion_fx(effect.remote_impact,3)
			effect.node.queue_free()
	effects=effects.filter(func(effect):return effect.life>0)
	if mode=="reveal":
		reveal_clock+=delta
		hud.chest_reveal(reveal_tier,minf(1,reveal_clock/reveal_duration))
		if reveal_clock>=reveal_duration: finish_reveal()
	sound.tick(delta,mode in ["playing","settings"],boss_active())
	hud.update(delta)
	next_save+=delta
	if next_save>10:
		next_save=0
		career.save()

func run_smoke():
	await get_tree().process_frame
	var rebuilt_menu=is_instance_valid(hud.menu_start) and hud.menu_start.is_visible_in_tree()
	input_kind="xbox";hud.menu_start.grab_focus();hud.controller_move(Vector2.DOWN)
	var navigated=get_viewport().gui_get_focus_owner()!=hud.menu_start
	var focused_before=get_viewport().gui_get_focus_owner()
	var idle_mouse=InputEventMouseMotion.new();idle_mouse.relative=Vector2(5,3);_input(idle_mouse)
	var pointer_safe=input_kind=="xbox" and get_viewport().gui_get_focus_owner()==focused_before
	var confirm=InputEventJoypadButton.new();confirm.button_index=JOY_BUTTON_A;confirm.pressed=true;_input(confirm)
	var accepted=mode=="career"
	hud.start_menu();input_kind="keyboard";await get_tree().process_frame
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://native-menu.png")
	start_run()
	invulnerable=1000
	await get_tree().create_timer(2).timeout
	var checks = {"native":true,"initial_enemies":enemies.size(),"weapon_slots":equipped.size(),"chests":chests.size(),"first_price":rules.chest_price(0),"rarities":rules.data.loot.size(),"achievements":career.achievements.size(),"xp_target":xp_target,"realm":realm,"paid_count":paid_chests}
	checks.main_menu=rebuilt_menu
	checks.xbox_navigation=navigated;checks.xbox_accept=accepted;checks.pointer_focus_safe=pointer_safe
	checks.hero_roster=rules.data.heroes.size()==21 and rules.data.heroes.all(func(h):return ResourceLoader.exists("res://assets/illustrated/heroes/"+h.model+".png"))
	checks.enemy_roster=range(6).all(func(b):return range(6).all(func(s):return ResourceLoader.exists("res://assets/illustrated/creatures/creature_%d_%d.png" % [b,s])))
	checks.painted_terrain=range(6).all(func(i):return ResourceLoader.exists("res://assets/illustrated/terrain-%d.png" % i))
	checks.painted_weapons=equipped.all(func(w):return ResourceLoader.exists("res://assets/illustrated/weapons/"+("turret" if w.turret else w.id)+".png"))
	checks.opaque_ui=is_equal_approx(hud.style(Color(0,0,0,.2)).bg_color.a,1.0)
	checks.illustrated_icons=IllustratedIcons.texture("gun",true).atlas.get_width()==768
	var before_yaw=yaw
	camera_look(Vector2(.12,.08))
	checks.camera_look=yaw<before_yaw and pitch>0
	mode="paused"
	before_yaw=yaw
	camera_look(Vector2(.2,.2))
	checks.menu_blocks_look=is_equal_approx(yaw,before_yaw)
	mode="playing"
	yaw=0;pitch=0
	var starter=equipped[0].duplicate(true)
	equip_weapon(starter)
	hud.weapons.refresh()
	checks.weapon_rank=equipped[0].rank==2 and hud.weapons.get_child_count()==3
	checks.weapon_mechanics=rules.data.weapons.all(func(w):return WeaponDetails.MECHANICS.has(w.id))
	var motion=InputEventMouseMotion.new()
	motion.relative=Vector2(10,5)
	dragging=true
	_input(motion)
	checks.mouse_camera=yaw<0 and pitch>0
	dragging=false;yaw=0;pitch=0
	var pad_event=InputEventJoypadMotion.new()
	pad_event.axis=JOY_AXIS_RIGHT_X;pad_event.axis_value=.6
	_input(pad_event)
	checks.xbox_prompts=input_kind=="xbox"
	input_kind="keyboard"
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://native-gameplay.png")
	gold=1000
	var chest=chests[0]
	buy_chest(chest)
	checks.paid_once = paid_chests==1 and gold==970 and offers.size()==3
	if DisplayServer.get_name()!="headless":
		hud.chest_reveal(3,.6)
		await RenderingServer.frame_post_draw
		hud.chest_reveal(3,.6)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://native-chest.png")
	var skip_reveal=InputEventAction.new();skip_reveal.action="jump";skip_reveal.pressed=true;_input(skip_reveal)
	checks.reveal_keeps_choice=mode=="offer" and owned.is_empty() and offers.size()==3
	input_kind="xbox";hud.cards[1].grab_focus();hud.cards[0].mouse_entered.emit()
	checks.xbox_reward_focus=get_viewport().gui_get_focus_owner()==hud.cards[1]
	_input(confirm)
	checks.xbox_reward_accept=owned.size()==1 and mode=="playing"
	input_kind="keyboard"
	checks.one_item = owned.size()==1
	var a=rules.data.weapons.filter(func(w):return w.id=="shotgun")[0].duplicate(true)
	a.kind="weapon";a.strength=1.0;a.tier=1
	equip_weapon(a)
	a=rules.data.weapons.filter(func(w):return w.id=="ice")[0].duplicate(true)
	a.kind="weapon";a.strength=1.0;a.tier=2
	equip_weapon(a)
	hud.weapons.refresh()
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://native-weapons.png")
		mode="offer"
		offers=equipped.duplicate(true)
		offer_source="level"
		hud.show_offers(offers,"level")
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://native-cards.png")
		input_kind="xbox"
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://native-xbox.png")
		input_kind="keyboard"
		hud.close()
	mode="offer"
	offers=equipped.duplicate(true)
	offer_source="level"
	hud.show_offers(offers,"level")
	hud.cards[1].grab_focus()
	await get_tree().process_frame
	checks.selection_preview=hud.offer_detail.get_child(1).text==offers[1].name
	checks.compact_choices=hud.cards.all(func(card):return card.size.y<95)
	hud.close()
	mode="offer"
	offers=rules.offers("item",1.0,true)
	offer_source="chest"
	hud.show_offers(offers,"chest")
	await get_tree().process_frame
	checks.compact_items=hud.cards.all(func(card):return card.size.y<95)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://native-items.png")
	hud.close()
	checks.weapon_limit = not rules.can_weapon(equipped,"rocket") and equipped.size()==3
	checks.key_free = rules.free_chance(.3)>.2
	checks.portal_locked = realm_bosses<2
	career.dirty=true
	career.save()
	checks.disk_save = FileAccess.file_exists(career.file)
	checks.standalone=not Engine.has_singleton("Steam")
	# Free boss chests preserve the price index and still grant exactly one choice.
	mode="playing"
	var before_paid=paid_chests
	var before_gold=gold
	chests[1].free=true
	buy_chest(chests[1])
	checks.free_price=paid_chests==before_paid and gold==before_gold and offers.size()==3
	finish_reveal();choose_offer(0)
	# A garden is not a projectile emitter. Test roots, pollen, nectar and chain blooms.
	select_hero(rules.data.heroes.filter(func(h):return h.id=="florist")[0])
	start_run();mode="playing";invulnerable=1000
	for e in enemies: e.node.queue_free()
	enemies.clear()
	for i in range(3): plant_flower(Vector3(i,0,0),equipped[0]);flowers[-1].age=2
	spawn_enemy(3,true)
	var boss=enemies[-1]
	boss.node.position=Vector3(1,0,0)
	hp=stats.maxHp-10
	var before_hp=hp
	var before_boss_hp=boss.hp
	last_plant=player.position
	update_garden(.1)
	checks.garden=flowers.size()==3 and boss.hp<before_boss_hp and hp>before_hp and boss.slow>0 and boss.poison>0 and projectiles.is_empty()
	checks.garden_goals=career.data.unlocked.has("WF_BLOOM_CHAIN") and career.data.unlocked.has("WF_FLOWER_BOSS")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		boss.node.position=Vector3(4,0,-4)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://native-florist.png")
	gold=123;level=4
	enter_realm(1)
	checks.realm_preserves=realm==1 and gold==123 and level==4 and equipped[0].id=="flowers"
	await get_tree().process_frame
	enter_realm(2)
	checks.three_realms=realm==2 and career.data.unlocked.has("WF_THREE_REALMS")
	hud.settings_menu()
	await get_tree().process_frame
	checks.settings_fit=hud.content.get_parent().position.y+hud.content.get_parent().size.y<=810
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://native-settings.png")
	hud.community_menu()
	checks.community_ui=mode=="community" and hud.content.get_child_count()>5
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("user://native-community.png")
	career.data.feedback.append({"id":"native-smoke","text":"More funny flowers","status":"Submitted locally"})
	achievement_event("FEEDBACK");career.dirty=true;career.save()
	var reload_profile=ProfileScript.new(rules.data,true)
	checks.feedback_save=reload_profile.data.feedback.any(func(f):return f.id=="native-smoke")
	var guard_before=stats.fallGuard
	stats.fallGuard=0
	checks.safe_jump_fall=fall_damage(7)==0 and fall_damage(13)==24
	stats.fallGuard=.5
	checks.fall_guard=fall_damage(13)==12
	stats.fallGuard=guard_before
	checks.single_bonus=rules.data.loot.all(func(item):return item.effects.size()==1)
	var rolls_ok=true
	for i in range(120):
		var roll=rules.roll("item",0,i%4)
		if roll.effects.size()!=1: rolls_ok=false
		if roll.effects[0].key in ["airJumps","revive","chain","multishot","flowerSeeds"] and roll.effects[0].amount!=roundf(roll.effects[0].amount): rolls_ok=false
	checks.discrete_bonuses=rolls_ok
	var capped=rules.data.stats.duplicate(true);capped.discount=.6;capped.keyPower=.75;capped.airJumps=8;capped.dodge=.65
	checks.useful_offers=rules.offers("item",0,false,capped).all(func(item):
		if item.kind=="weapon": return true
		var copy=capped.duplicate(true);rules.apply_effects(copy,item.effects)
		return not is_equal_approx(copy[item.effects[0].key],capped[item.effects[0].key]))
	mode="playing";hud.close();invulnerable=1000
	var original_speed=stats.speed
	activate_consumable("speed");activate_consumable("speed")
	checks.buff_refresh=buffs.speed==25 and stats.speed==original_speed
	mode="paused";var buff_remaining=buffs.speed
	_physics_process(.5)
	checks.buff_pause=buffs.speed==buff_remaining
	mode="playing";buffs.speed=.01;update_exploration(.02)
	checks.buff_expiry=not buffs.has("speed") and stats.speed==original_speed
	player_poison=3;activate_consumable("poison");update_exploration(.1)
	checks.immunity=player_poison==0
	drop_consumable(player.position,true);var drop_count=consumables.size()
	update_combat(.01)
	checks.manual_consumable=consumables.size()==drop_count
	interact();checks.consume_key=consumables.size()==drop_count-1
	var rig_test=ActorRig.new();add_child(rig_test);rig_test.setup("rubber_duck_toy")
	rig_test.sync_equipment([{"id":"gun","rank":1},{"id":"ice","rank":1},{"id":"rocket","rank":1}])
	checks.third_arm=rig_test.arms.size()==3 and rig_test.held.size()==3 and rig_test.arms[2].visible
	rig_test.sync_equipment([{"id":"gun","rank":1}]);checks.arm_removal=not rig_test.arms[2].visible and rig_test.held.size()==1
	rig_test.queue_free()
	var detected={}
	for i in range(36):
		var p=Vector3(cos(i*TAU/36)*300,0,sin(i*TAU/36)*300);detected[world.biome_at(p)]=true
	checks.six_biomes=detected.size()==6
	checks.large_world=RealmWorld.EXTENT>=500
	checks.enemy_size=enemies.all(func(e):return e.node is CharacterBody3D and e.node.get_child(0).shape.height>=1.65)
	player.position=Vector3(0,8,0);player.velocity=Vector3.ZERO;air_jumps=0;try_jump()
	checks.no_free_air_jump=air_jumps==0 and player.velocity.y==0
	rules.apply_effects(stats,[{"key":"airJumps","amount":1}]);try_jump()
	checks.double_jump=air_jumps==1 and player.velocity.y>0
	var before_jump=player.velocity.y;try_jump();checks.jump_limit=air_jumps==1 and player.velocity.y==before_jump
	var damage_before=health_damage
	last_safe=Vector3(0,0,0);recover_player()
	checks.recovery=not landing_ready and player.velocity==Vector3.ZERO and health_damage==damage_before
	# Exercise real landings, rather than only the fall-damage formula.
	clear_entities();mode="playing";spawn_clock=999;xp=0;storm_clock=999;nova_clock=999
	stats.dodge=0;stats.armor=0;stats.regen=0;stats.auraDamage=0;stats.shield=0;stats.fallGuard=0;shield_hp=0;invulnerable=0;hp=1000;stats.maxHp=1000
	buffs.clear();stats.fallThreshold=0;stats.jumpShield=0;stats.landingHeal=0
	player.position=Vector3(0,12,0);player.velocity=Vector3.ZERO;player.reset_physics_interpolation();peak_height=12;landing_ready=true;slamming=false
	var before_fall=health_damage
	await get_tree().create_timer(1.4).timeout
	checks.real_fall_damage=health_damage-before_fall>19 and health_damage-before_fall<21 and player.is_on_floor()
	var landed_damage=health_damage
	await get_tree().create_timer(.2).timeout
	checks.single_landing_damage=is_equal_approx(landed_damage,health_damage)
	spawn_enemy(8)
	var slam_target=enemies[0];slam_target.node.position=Vector3(2.5,world.height_at(2.5,0),0);slam_target.hp=1000;slam_target.maxHp=1000;slam_target.freeze=3
	player.position=Vector3(0,8,0);player.velocity=Vector3(0,-24,0);player.reset_physics_interpolation();peak_height=8;landing_ready=true;slamming=true;invulnerable=1000
	var slam_expected=stats.damage*2*stats.slamPower
	await get_tree().create_timer(.65).timeout
	checks.real_ground_slam=is_equal_approx(1000-slam_target.hp,slam_expected) and not slamming and player.is_on_floor()
	var before_level=level;mode="playing";xp=xp_target;level_up()
	checks.level_celebration=mode=="level_reveal" and level==before_level+1 and offers.size()==3
	level_reveal=.01;_process(.02)
	checks.level_choice=mode=="offer"
	checks.biome_voices=range(6).all(func(i):return ResourceLoader.exists("res://assets/voices/biome_"+str(i)+".wav"))
	checks.achievement_art=ResourceLoader.exists("res://assets/illustrated/achievements.png")
	clear_entities()
	mode="playing";spawn_enemy(12)
	var stomp_target=enemies[0];stomp_target.node.position=Vector3.ZERO;stomp_target.hp=10000
	player.position=Vector3(0,stomp_target.height-.05,0);check_stomp(Vector3(0,stomp_target.height+.7,0),-8)
	checks.head_stomp=stomp_target.dead and player.velocity.y>0
	mode="playing";invulnerable=0;stats.dodge=0;stats.armor=0;hp=1000
	take_damage(10,Vector3(1,1,0),"shell_bump")
	checks.hit_bump=knock_velocity.x<0 and hit_shake>0 and avatar.hurt>0
	spawn_pickup(Vector3(480,0,0),"xp",100);make_chest(Vector3(480,0,1),false);spawn_enemy(15)
	var edge_enemy=enemies[-1];edge_enemy.node.position=Vector3(480,0,0)
	player.position=Vector3.ZERO;update_boiling_edge()
	checks.border_destroys=edge_enemy.dead and not pickups.any(func(p):return world.dangerous(p.node.position)) and chests[-1].get("destroyed",false)
	checks.border_bounds=world.dangerous(Vector3(476,0,0)) and not world.dangerous(Vector3(450,0,0))
	clear_entities()
	hud.modal.visible=false
	await get_tree().process_frame
	mode="test_finished"
	sound.active=false
	for audio_player in sound.get_children():
		if audio_player is AudioStreamPlayer or audio_player is AudioStreamPlayer3D: audio_player.stop();audio_player.stream=null
	# Let the audio mixer release the short effect playbacks before teardown.
	await get_tree().create_timer(.2).timeout
	var report=FileAccess.open("user://smoke-results.json",FileAccess.WRITE)
	if report!=null: report.store_string(JSON.stringify(checks,"  "));report.close()
	print("NATIVE_SMOKE "+JSON.stringify(checks))
	var failure = not checks.main_menu or not checks.opaque_ui or not checks.illustrated_icons or not checks.selection_preview or not checks.compact_choices or not checks.compact_items or not checks.camera_look or not checks.menu_blocks_look or not checks.weapon_rank or not checks.weapon_mechanics or not checks.mouse_camera or not checks.xbox_prompts or not checks.settings_fit or checks.initial_enemies<6 or checks.chests!=6 or checks.first_price!=30 or checks.achievements!=100 or not checks.paid_once or not checks.one_item or not checks.weapon_limit or not checks.disk_save or not checks.free_price or not checks.garden or not checks.garden_goals or not checks.realm_preserves or not checks.three_realms or not checks.community_ui or not checks.feedback_save or not checks.standalone
	for key in checks:
		if checks[key] is bool and not checks[key]: failure=true
	get_tree().quit(1 if failure else 0)

func achievement_event(id: String):
	if float(career.data.total.get("event_"+id,0)) < 1: career.bump("event_"+id)

func check_creative_goals():
	if equipped.size()==3: achievement_event("TRIPLE_WEAPON")
	if equipped.size()==3 and equipped.all(func(w):return w.rank>=2): achievement_event("REPLACE")
	if equipped.any(func(w):return w.turret) and equipped.any(func(w):return not w.turret): achievement_event("MIX_TURRET")
	if families.size()>=6: achievement_event("MIXED_BAG")
	if Vector2(player.position.x,player.position.z).length()>150: achievement_event("LONG_WALK")
	if hud.map_view.visited.size()>=30: achievement_event("FULL_EXPLORER")
	for i in range(world.landmarks.size()):
		if player.position.distance_to(world.landmarks[i])<12: visited_ruins[i]=true
	if visited_ruins.size()==4: achievement_event("RUINS")
	for a in career.achievements:
		if a.key.begins_with("combo_"):
			var pair = a.key.trim_prefix("combo_").split("_")
			if stats.get(pair[0],0)>rules.data.stats.get(pair[0],0) and stats.get(pair[1],0)>rules.data.stats.get(pair[1],0):
				if career.data.total.get(a.key,0)==0: career.bump(a.key)

func plant_flower(position_value: Vector3, weapon: Dictionary):
	var node=Node3D.new()
	node.position=position_value
	node.position.y=world.height_at(position_value.x,position_value.z)
	add_child(node)
	var stem=CylinderMesh.new()
	stem.top_radius=.025;stem.bottom_radius=.04;stem.height=.7
	ToonArt.part(node,stem,Color("507e35"),Vector3(0,.35,0))
	var tone=Color("f49cbd") if flowers.size()%3==0 else Color("e9c954") if flowers.size()%3==1 else Color("ab93ef")
	for i in range(6):
		var petal=SphereMesh.new();petal.radius=.17;petal.height=.13
		ToonArt.part(node,petal,tone,Vector3(cos(i*TAU/6)*.2,.72,sin(i*TAU/6)*.2))
	var center=SphereMesh.new();center.radius=.12;center.height=.17
	ToonArt.part(node,center,Color("fff2a5"),Vector3(0,.74,0))
	flowers.append({"node":node,"age":0.0,"life":22.0,"bloom":0.0,"power":weapon.power,"ready":false})
	achievement_event("GARDEN")
	garden_patches[Vector2i(roundi(position_value.x/10),roundi(position_value.z/10))]=true
	if garden_patches.size()>=5: achievement_event("GARDEN_MOVE")
	if flowers.size()>48: flowers[0].node.queue_free();flowers.pop_front()

func update_garden(delta: float):
	var weapon = equipped.filter(func(w):return w.id=="flowers")
	if weapon.is_empty():
		for flower in flowers: flower.node.queue_free()
		flowers.clear()
		return
	# Movement lays a trail. Flowers never aim, shoot or deploy as turrets.
	if player.position.distance_to(last_plant)>2.3 and player.is_on_floor():
		last_plant=player.position
		plant_flower(last_plant,weapon[0])
		for i in range(mini(2,int(stats.flowerSeeds))): plant_flower(last_plant+Vector3.RIGHT.rotated(Vector3.UP,i*PI+elapsed)*1.5,weapon[0])
	for flower in flowers:
		flower.node.rotation.z=sin(elapsed*2+flower.age)*.045
		flower.age+=delta;flower.life-=delta;flower.bloom=maxf(0,flower.bloom-delta)
		flower.node.scale=Vector3.ONE*minf(1,flower.age/1.5)
		if flower.age<1.5: continue
		for enemy in enemies:
			if enemy.dead or not is_instance_valid(enemy.node): continue
			if enemy.node.position.distance_to(flower.node.position)<3:
				enemy.slow=maxf(enemy.slow,stats.flowerRoots);enemy.poison=maxf(enemy.poison,stats.flowerPollen);enemy.status_time=3
				achievement_event("ROOTS");achievement_event("POLLEN")
		if flower.bloom<=0 and enemies.any(func(e): return not e.dead and e.node.position.distance_to(flower.node.position)<3+e.get("radius",0)):
			var chain=flowers.filter(func(f):return f.age>=1.5 and f.bloom<=0 and f.node.position.distance_to(flower.node.position)<5)
			if chain.size()>=3: achievement_event("BLOOM_CHAIN")
			for bloom in chain:
				bloom.bloom=3.5
				for enemy in enemies:
					if not enemy.dead and enemy.boss and enemy.node.position.distance_to(bloom.node.position)<3.5: achievement_event("FLOWER_BOSS")
				damage_area(bloom.node.position,3.5,stats.damage*stats.flowerPower*bloom.power*.8,"bloom")
				burst(bloom.node.position+Vector3.UP*.85,Color("f5a8c4"),5)
				if player.position.distance_to(bloom.node.position)<4 and hp<stats.maxHp: heal(stats.flowerHeal);achievement_event("FLOWER_HEAL")
	for flower in flowers:
		if flower.life<=0: flower.node.queue_free()
	flowers=flowers.filter(func(f):return f.life>0)

func try_jump():
	if not player.is_on_floor() and air_jumps>=int(stats.airJumps): return
	if player.is_on_floor(): air_jumps=0;peak_height=player.position.y;landing_ready=true
	else: air_jumps+=1
	slamming=false
	player.velocity.y=8.5*sqrt(stat("jumpHeight"))
	shield_hp=minf(stats.shield+stats.jumpShield,shield_hp+stats.jumpShield)
	if stats.jumpBlast>0: damage_area(player.position,3,stats.jumpBlast,"jump")
	sound.effect("jump")
	burst(player.position+Vector3.UP*.1,Color("e6dfb8"),5)
	vibrate(.12,.18,.07)
	if boss_active(): achievement_event("AIRTIME")

func check_stomp(previous: Vector3,falling_speed: float):
	if falling_speed>-.5: return
	for enemy in enemies:
		if enemy.dead: continue
		var top=enemy.node.position.y+enemy.get("height",1.7)
		var planar=Vector2(player.position.x-enemy.node.position.x,player.position.z-enemy.node.position.z).length()
		if planar<enemy.get("radius",.53)+.27 and previous.y>=top-.25 and player.position.y<=top+.16:
			if enemy.boss: hurt_enemy(enemy,stats.damage*4,"stomp")
			elif coop.active and not coop.hosting: coop.stomp(enemy)
			else: kill_enemy(enemy,"stomp")
			player.position.y=top+.15;player.velocity.y=6.5;air_jumps=0;slamming=false;peak_height=player.position.y;landing_ready=true
			sound.effect("squish",enemy.node.position);burst(enemy.node.position+Vector3.UP,Color("f1d39c"),9);vibrate(.22,.45,.1)
			return

func update_boiling_edge():
	if maxf(absf(player.position.x),absf(player.position.z))>440: hud.tell("BOILING BORDER  ·  TURN BACK",.2)
	for enemy in enemies:
		if not enemy.dead and world.dangerous(enemy.node.position):
			enemy.dead=true;burst(enemy.node.position+Vector3.UP,Color("ffd498"),6);enemy.node.queue_free()
	for collection in [pickups,consumables,pots,flowers,pools,projectiles]:
		for i in range(collection.size()-1,-1,-1):
			var item=collection[i]
			if is_instance_valid(item.node) and world.dangerous(item.node.position): item.node.queue_free();collection.remove_at(i)
	for chest in chests:
		if not chest.get("destroyed",false) and world.dangerous(chest.node.position): chest.destroyed=true;chest.opened=true;chest.node.visible=false
	if world.dangerous(player.position):
		hp=0;health_damage+=stats.maxHp;end_run(false);hud.tell("THE BOILING BORDER CLAIMED YOU",6)

func run_coop_test():
	coop.test_mode=true
	var discovered_party=false
	if network_test_role=="host": coop.host_lan()
	else:
		hud.coop_menu()
		var discovery_deadline=Time.get_ticks_msec()+6000
		while Time.get_ticks_msec()<discovery_deadline:
			if coop.discovered.has("127.0.0.1"): discovered_party=true;break
			await get_tree().create_timer(.1).timeout
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://standalone-coop-menu.png")
		coop.join_lan("127.0.0.1")
	var deadline=Time.get_ticks_msec()+14000
	while Time.get_ticks_msec()<deadline:
		if network_test_role=="host" and not coop.members.is_empty(): start_run(91731);coop.run_started();break
		if network_test_role=="client" and run_active: break
		await get_tree().create_timer(.1).timeout
	if not run_active: print("COOP_TEST failure: connection/start");get_tree().quit(1);return
	hp=10000;stats.maxHp=10000;stats.regen=0
	if network_test_role=="host": stats.damage=2
	var started=Time.get_ticks_msec();var pause_done=false;var realm_done=false;var moved=false;var shared_enemies=false;var maximum_avatars=0
	while Time.get_ticks_msec()-started<(13000 if network_test_role=="host" else 11000):
		var seconds=(Time.get_ticks_msec()-started)/1000.0
		shared_enemies=shared_enemies or enemies.size()>0
		maximum_avatars=maxi(maximum_avatars,coop.avatars.size())
		moved=moved or player.position.x>2
		if network_test_role=="host":
			if seconds>3 and not pause_done: pause_done=true;level_up()
			if seconds>4 and mode=="offer": choose_offer(0)
			if seconds>7 and not realm_done: realm_done=true;enter_realm(1)
		elif mode=="offer": choose_offer(0)
		if DisplayServer.get_name()!="headless" and seconds>5 and seconds<5.2:
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("user://coop-"+network_test_role+".png")
		await get_tree().create_timer(.1).timeout
	var checks={"role":network_test_role,"standalone":not Engine.has_singleton("Steam"),"discovery":discovered_party if network_test_role=="client" else true,"connected":coop.active,"avatars":maximum_avatars,"members":coop.members.size(),"same_enemies":shared_enemies,"remote_hits":coop.remote_hits,"kills_received":coop.kills_received,"snapshots":coop.snapshots_received,"moved":moved,"party_pause":coop.saw_pause,"realm":realm,"realm_received":coop.saw_realm}
	var passed=checks.standalone and checks.discovery and checks.connected and checks.avatars>0 and shared_enemies and realm==1 and (coop.remote_hits>0 if network_test_role=="host" else coop.snapshots_received>20 and coop.saw_pause and coop.saw_realm and moved)
	print("COOP_TEST "+JSON.stringify(checks));var report=FileAccess.open("user://coop-"+network_test_role+"-results.json",FileAccess.WRITE);report.store_string(JSON.stringify(checks,"  "));report.close();coop.leave()
	mode="test_finished";clear_entities();sound.active=false
	for channel in sound.get_children():
		if channel is AudioStreamPlayer or channel is AudioStreamPlayer3D: channel.stop();channel.stream=null
	await get_tree().create_timer(.25).timeout
	get_tree().quit(0 if passed else 1)

func check_landing(was_grounded: bool):
	if not player.is_on_floor():
		if was_grounded: peak_height=player.position.y;landing_ready=true
		return
	if not was_grounded and landing_ready:
		var drop=maxf(0,peak_height-player.position.y)
		avatar.hurt=.15
		sound.effect("land")
		if slamming:
			slam_wave()
			damage_area(player.position,4*stats.slamRadius,stats.damage*2*stats.slamPower,"slam")
			burst(player.position+Vector3.UP*.1,Color("dfbb8d"),20)
			vibrate(.5,.75,.2)
			heal(stats.slamHeal)
			for enemy in enemies:
				if not enemy.dead and enemy.node.position.distance_to(player.position)<4*stats.slamRadius+enemy.radius:
					enemy.fire=maxf(enemy.fire,stats.slamFire);enemy.poison=maxf(enemy.poison,stats.slamPoison);enemy.status_time=4
		heal(stats.landingHeal)
		if drop>7: take_damage(fall_damage(drop))
		if slamming and stats.bounceJump>0: player.velocity.y=8.5*sqrt(1+stats.bounceJump);air_jumps=0
	air_jumps=0;slamming=false;landing_ready=false;peak_height=player.position.y
	last_safe=player.position

func recover_player():
	world.ensure_ground(last_safe)
	player.position=last_safe+Vector3.UP*.3
	player.reset_physics_interpolation()
	player.velocity=Vector3.ZERO
	landing_ready=false;slamming=false;air_jumps=0;peak_height=player.position.y

func update_exploration(delta: float):
	world.ensure_ground(player.position)
	current_biome=world.biome_at(player.position)
	if not biome_seen.has(current_biome):
		biome_seen[current_biome]=true
		hud.tell("DISCOVERED  ·  "+RealmWorld.BIOMES[current_biome],4)
		sound.say("biome_"+str(current_biome),0)
	for key in buffs.keys():
		buffs[key]=maxf(0,buffs[key]-delta)
		if buffs[key]<=0: buffs.erase(key);sound.effect("coin");hud.tell("Finished  ·  "+PotionBook.TYPES[key].name)
	if buffs.has("poison"): player_poison=0
	if buffs.has("fire"): player_fire=0
	player_poison=maxf(0,player_poison-delta);player_fire=maxf(0,player_fire-delta);player_chill=maxf(0,player_chill-delta);player_blind=maxf(0,player_blind-delta)
	status_tick+=delta
	if status_tick>=.6:
		status_tick=0
		if player_poison>0: take_damage(1.2)
		elif player_fire>0: take_damage(1.8)
	for drop in consumables:
		drop.age+=delta
		drop.node.position.y=drop.base_y+sin(drop.age*2)*.08
		drop.node.rotation.y+=delta*.5
		if drop.age>120: drop.node.queue_free()
	consumables=consumables.filter(func(drop):return drop.age<=120)

func nearest_consumable() -> Dictionary:
	var found={};var distance=2.4
	for drop in consumables:
		var d=drop.node.position.distance_to(player.position)
		if d<distance: found=drop;distance=d
	return found

func activate_consumable(kind: String):
	if not PotionBook.TYPES.has(kind): return
	var duration=25.0*stats.get("potionDuration",1.0)
	buffs[kind]=maxf(float(buffs.get(kind,0)),duration)
	if kind=="poison": player_poison=0
	if kind=="fire": player_fire=0
	sound.effect("drink");vibrate(.2,.2,.1)
	hud.tell("%d s  ·  %s" % [duration,PotionBook.TYPES[kind].name])

func drop_consumable(p: Vector3, force: bool=false):
	if not force and not owned.any(func(item): return item.effects.any(func(effect): return effect.key=="luck")): return
	if not force and rules.rng.randf()>minf(.95,.35+stats.luck*.4+stats.potionChance): return
	var kinds=PotionBook.TYPES.keys();var kind=kinds[rules.rng.randi_range(0,kinds.size()-1)]
	var entry=PotionBook.TYPES[kind]
	var node=Node3D.new();add_child(node)
	p.x=clampf(p.x,-480,480);p.z=clampf(p.z,-480,480);p.y=world.height_at(p.x,p.z)
	node.position=p+Vector3.UP*.4
	var colors={"poison":Color("8bb773"),"fire":Color("e59b73"),"speed":Color("99cbce"),"xp":Color("ccacd7")}
	ToonArt.tube(node,Color(entry.color),Vector3.ZERO,.17,.24,.4)
	ToonArt.tube(node,Color("735b43"),Vector3(0,.25,0),.11,.11,.10)
	var badge=BoxMesh.new();badge.size=Vector3(.24,.19,.025)
	ToonArt.part(node,badge,Color("f2e4cb"),Vector3(0,0,-.22))
	var mark=Label3D.new();mark.text=entry.mark;mark.font_size=30;mark.modulate=Color("584735");mark.position=Vector3(0,0,-.24);node.add_child(mark)
	var title=entry.name
	var tag=Label3D.new();tag.text=title;tag.font_size=26;tag.position.y=.85;tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED;tag.visibility_range_end=35;tag.modulate=Color("fff0cc");node.add_child(tag)
	consumables.append({"node":node,"kind":kind,"title":title,"base_y":node.position.y,"age":0.0})

func stat(key: String) -> float:
	return PotionBook.value(key,float(stats.get(key,0)),buffs,float(stats.get("potionPower",1.0)))

func slam_wave():
	var ring=TorusMesh.new();ring.inner_radius=.85;ring.outer_radius=1
	var node=ToonArt.part(self,ring,Color("eed39a"),player.position+Vector3.UP*.12)
	node.scale=Vector3.ONE*.1
	var tween=create_tween();tween.tween_property(node,"scale",Vector3(4*stats.slamRadius,.2,4*stats.slamRadius),.3);tween.tween_callback(node.queue_free)


func run_soak():
	start_run();invulnerable=1000;stats.damage=2
	for id in ["shotgun","ice"]:
		var item=rules.data.weapons.filter(func(w):return w.id==id)[0].duplicate(true);item.kind="weapon";item.strength=1;item.tier=0;equip_weapon(item)
	while enemies.size()<110: spawn_enemy(randf_range(10,28))
	var frame_times=[];var began=Time.get_ticks_msec();var next_region=0;var snapshots={};var max_nodes=0;var lowest_y=0.0;var crowd_min=1000.0
	while Time.get_ticks_msec()-began<36000:
		await get_tree().process_frame
		var seconds=float(Time.get_ticks_msec()-began)/1000
		if mode=="offer": choose_offer(0)
		if mode=="replace": replace_weapon(0,offers[0])
		if mode=="reveal": finish_reveal()
		if mode!="playing": continue
		var region=mini(5,int(seconds/6))
		if region>=next_region:
			var angle=(region+.5)*TAU/6-float(seed_value%23)*.03
			player.position=Vector3(cos(angle)*330,0,sin(angle)*330);world.ensure_ground(player.position)
			player.position.y=world.height_at(player.position.x,player.position.z)+.2;player.velocity=Vector3.ZERO;landing_ready=false;last_safe=player.position
			for enemy in enemies: enemy.node.queue_free()
			enemies.clear()
			while enemies.size()<100: spawn_enemy(randf_range(10,28))
			drop_consumable(player.position);activate_consumable("speed");activate_consumable("xp")
			next_region=region+1
			print("SOAK_REGION "+str(region))
		Input.action_press("move_forward",.45)
		if int(seconds*10)%31==0: try_jump()
		lowest_y=minf(lowest_y,player.position.y-world.height_at(player.position.x,player.position.z))
		max_nodes=maxi(max_nodes,int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
		if fmod(seconds,6)>2:
			frame_times.append(get_process_delta_time()*1000)
			if not snapshots.has(region) and DisplayServer.get_name()!="headless":
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("user://biome-"+str(region)+".png");snapshots[region]=true
		if int(seconds*10)%10==0:
			for a in enemies:
				for b in enemies:
					if a==b or a.dead or b.dead or absf(a.node.position.y-b.node.position.y)>=minf(a.height,b.height): continue
					crowd_min=minf(crowd_min,Vector2(a.node.position.x-b.node.position.x,a.node.position.z-b.node.position.z).length()/(a.radius+b.radius))
	Input.action_release("move_forward")
	frame_times.sort()
	var result={"renderer":RenderingServer.get_video_adapter_name(),"cpu":OS.get_processor_name(),"frames":frame_times.size(),"p50_ms":frame_times[int(frame_times.size()*.5)],"p95_ms":frame_times[int(frame_times.size()*.95)],"process_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"max_nodes":max_nodes,"static_memory_mb":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576,"regions":next_region,"lowest_ground_delta":lowest_y,"minimum_enemy_spacing":crowd_min,"remaining_enemies":enemies.size(),"buffs":buffs.size(),"chunks":world.chunks.size()}
	var file=FileAccess.open("user://soak-results.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
	print("NATIVE_SOAK "+JSON.stringify(result))
	get_tree().quit(0 if next_region==6 and lowest_y>-5 else 1)

func export_hero_art():
	var destination="res://assets/illustrated/heroes"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination))
	for item in rules.data.heroes:
		var portrait=HeroPortrait.new();hud.root.add_child(portrait);portrait.size=Vector2(512,512);portrait.setup(item.model,item.weapon)
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		portrait.texture.get_image().save_png(destination+"/"+item.id+".png")
		portrait.queue_free()
		print("HERO_ART "+item.id)
	get_tree().quit()

func spawn_is_clear(p: Vector3,boss: bool=false) -> bool:
	var query=PhysicsShapeQueryParameters3D.new();var shape=CapsuleShape3D.new()
	shape.radius=1.05 if boss else .55;shape.height=3.4 if boss else 1.7
	query.shape=shape;query.transform=Transform3D(Basis.IDENTITY,p+Vector3.UP*(shape.height*.5+.45));query.collision_mask=5
	return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func fall_damage(drop: float) -> float:
	return maxf(0,drop-7-stats.get("fallThreshold",0))*4*(1-clampf(stat("fallGuard"),0,.95))

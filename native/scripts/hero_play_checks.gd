extends RefCounted

# Checks for the November 2 hero rework (HeroRules / HeroPlay), run inside the
# integration checks. Each hero is set up with a fresh run on the same island.
static func use(game: Node3D,hero_id: String):
	game.select_hero(game.rules.data.heroes.filter(func(h):return h.id==hero_id)[0])
	game.start_run(407);game.set_physics_process(false);game.spawn_clock=99999;game.clear_entities();game.mode="playing"
	game.player.position=Vector3(0,game.world.height_at(0,0)+.05,0);game.player.velocity=Vector3.ZERO

static func step(game: Node3D,frames: int,input: Vector3=Vector3.ZERO):
	for i in range(frames):
		game.player.velocity.x+=0.0
		var running=HeroPlay.drive(game,input,1.0/60.0)
		game.player.velocity.x=running.x;game.player.velocity.z=running.z
		HeroPlay.tick(game,1.0/60.0)
		game.player.velocity.y=0.0 if game.player.is_on_floor() else game.player.velocity.y-24.0/60.0
		game.player.move_and_slide()
		await game.get_tree().physics_frame

static func run(game: Node3D) -> Dictionary:
	var checks={}
	var saved_hero=game.hero
	# White Supra: no jump, no jump/slam cards, a drift that keeps speed in a turn.
	use(game,"white-supra")
	var before_y=game.player.velocity.y;game.try_jump()
	checks.supra_no_jump=game.player.velocity.y==before_y and not game.try_slam() and game.rules.banished.has("airJumps") and game.rules.banished.has("slamPower")
	game.player.velocity=Vector3(0,0,-16);game.set_meta("test_drift",true)
	await step(game,20,Vector3(16,0,0))
	checks.supra_drifts=HeroPlay.drifting and Vector2(game.player.velocity.x,game.player.velocity.z).length()>12.0 and game.player.velocity.z< -4.0
	game.remove_meta("test_drift")
	checks.supra_crash=HeroPlay.hurt_sound(game) and is_instance_valid(game.player.get_node_or_null("DriftSound"))
	checks.supra_fast=float(game.stats.speed)>=float(game.rules.data.stats.speed)*1.95
	# Smoker hovers: off the ground and out of the lava.
	use(game,"smoker")
	for i in range(40): HeroPlay.tick(game,1.0/60.0)
	checks.smoker_hovers=game.avatar.position.y>.3 and HeroRules.hovers(game.hero)
	# Honey Hustler: flies, no jump; wild flowers give XP once, then regrow.
	use(game,"bee")
	for i in range(40): HeroPlay.tick(game,1.0/60.0)
	checks.bee_flies=game.avatar.position.y>.7 and not HeroRules.can_jump(game.hero)
	var flower=HeroPlay.nectar[0] if not HeroPlay.nectar.is_empty() else {}
	var pickups_before=game.pickups.size()
	if not flower.is_empty():
		game.player.position=flower.node.position+Vector3(.5,.05,0);HeroPlay.sip_clock=0.0;HeroPlay.tick(game,1.0/60.0)
	checks.bee_nectar=HeroPlay.nectar.size()>=20 and game.pickups.size()==pickups_before+1 and game.pickups[-1].kind=="xp" and float(flower.ready)>game.elapsed
	# Admiral Bubbles: no health; hits only pop the bubble; a broken bubble ends him.
	use(game,"bathtub")
	game.invulnerable=0;game.stats.dodge=0;var full=game.shield_hp;var hp_before=game.hp
	game.take_damage(30)
	checks.bubbles_shield_only=game.hp==hp_before and game.shield_hp<full and game.equipped[0].id=="bubble" and game.rules.banished.has("maxHp")
	game.invulnerable=0;game.shield_hp=0.0;game.take_damage(10)
	checks.bubbles_no_health=game.hp<=0 or game.mode=="ended"
	game.mode="playing";game.hud.close()
	# Turbo Snail: a lasting trail that slows enemies crossing it.
	use(game,"snail")
	for i in range(30):
		game.player.position+=Vector3(.5,0,0);game.player.position.y=game.world.height_at(game.player.position.x,0)+.02
		await game.get_tree().physics_frame
		HeroPlay.tick(game,1.0/60.0)
	game.spawn_enemy(6);var crawler=game.enemies[-1];crawler.flying=false;crawler.slow=0.0;crawler.node.position=Vector3(6,game.world.height_at(6,0),0)
	HeroPlay.trail_clock=0.0;HeroPlay.tick(game,1.0/60.0)
	checks.snail_trail=HeroPlay.trail_points>=8 and HeroPlay.on_trail(Vector3(6,0,0)) and crawler.slow>=HeroPlay.TRAIL_SLOW
	# Prickle Rick: no weapon or weapon cards, lies down, enemies shove him and come for him.
	use(game,"cactus")
	var offers=game.rules.offers("weapon",0.0,false,game.stats,game.equipped)
	var model=game.avatar.find_child("CartoonModel",true,false)
	checks.cactus_unarmed=game.equipped.is_empty() and not offers.any(func(o):return o.kind=="weapon") and model!=null and absf(model.rotation.z-PI*.5)<.01 and game.stats.maxHp>=game.rules.data.stats.maxHp*2.5
	game.spawn_enemy(6);var bully=game.enemies[-1];bully.node.position=game.player.position+Vector3(.6,0,0)
	HeroPlay.roll=Vector3.ZERO
	for i in range(15): HeroPlay.tick(game,1.0/60.0)
	var shove=HeroPlay.roll
	game.clear_entities()
	for i in range(10): HeroPlay.tick(game,1.0/60.0)
	# Pushed away from the enemy, and still rolling a moment later (friction, not a stop).
	checks.cactus_shoved=shove.x<0.0 and HeroPlay.roll.x<0.0 and HeroPlay.roll.length()<shove.length()+.001 and HeroPlay.drive(game,Vector3.ZERO,1.0/60.0).x<0.0
	# Digby Mole sees glowing roots under the Florist's flowers and eats them to heal.
	use(game,"mole")
	var garden=game.rules.data.weapons.filter(func(w):return w.id=="flowers")[0].duplicate(true);garden.kind="weapon";garden.strength=1.0;game.equip_weapon(garden)
	game.plant_flower(Vector3(4,0,0),game.equipped[-1])
	HeroPlay.root_clock=0.0;HeroPlay.update_roots(game,0.0,false)
	var root=HeroPlay.roots.values()[0] if not HeroPlay.roots.is_empty() else {}
	game.hp=game.stats.maxHp*.5;var hungry=game.hp
	game.player.position=Vector3(4.5,game.world.under_height(4,0)-1.6,0)
	HeroPlay.update_roots(game,0.0,true)
	checks.mole_eats_roots=not root.is_empty() and root.eaten and game.hp>hungry and root.node.position.y<game.world.height_at(4,0)-5
	for bloom in game.flowers: bloom.node.queue_free()
	game.flowers.clear();HeroPlay.root_clock=0.0;HeroPlay.update_roots(game,0.0,false)
	checks.roots_follow_flowers=HeroPlay.roots.is_empty()
	# Three more pets (November 2): Ward shields, Mote pulls XP in, Rime slows.
	game.clear_entities();game.mode="playing";game.hp=game.stats.maxHp
	var pet=game.pet
	pet.kind="ward";pet.stage=0;pet.rebuild();pet.work=0.0;pet.state="follow";game.shield_hp=0.0
	pet.duty();checks.pet_ward=Pet.KINDS.size()==6 and game.shield_hp>=Pet.WARD_SHIELD[0]-.01
	pet.kind="mote";pet.rebuild()
	game.spawn_pickup(game.player.position+Vector3(7,.3,0),"xp",3);var orb=game.pickups[-1];orb.settled=true;orb.attracted=false
	pet.duty();checks.pet_mote=orb.attracted
	pet.kind="rime";pet.rebuild();pet.work=0.0
	game.spawn_enemy(6);var chilly=game.enemies[-1];chilly.boss=false;chilly.node.position=game.player.position+Vector3(2,0,0);chilly.slow=0.0
	pet.duty();checks.pet_rime=chilly.slow>=Pet.RIME_SLOW[0]-.01
	# Wrench tunes a placed turret with arrows: twice as fast while he keeps it up.
	use(game,"wrench")
	var tool=game.equipped.filter(func(w):return w.turret)
	if not tool.is_empty():
		var placed=tool[0];game.player.position=placed.node.position+Vector3(1.5,0,0)
		var started=WrenchTune.try_start(game)
		var arrow=game.hud.tune_code.code[0] if started else "up"
		WrenchTune.enter(game,game.hud.tune_code.press(arrow))
		var fast=WrenchTune.rate(game,placed)
		var wrong="down" if game.hud.tune_code.code[game.hud.tune_code.step]!="down" else "up"
		WrenchTune.enter(game,game.hud.tune_code.press(wrong))
		var broken=WrenchTune.rate(game,placed)
		game.player.position+=Vector3(9,0,0);WrenchTune.tick(game,1.0/60.0)
		checks.wrench_tune=started and is_equal_approx(fast,2.0) and is_equal_approx(broken,1.0) and not WrenchTune.active
	else: checks.wrench_tune=false
	# Downed in co-op: the camera follows a living friend; cheers play for all.
	var friend=CharacterBody3D.new();game.add_child(friend);friend.position=game.player.position+Vector3(20,0,0)
	game.coop.active=true;game.coop.avatars[77]=friend;game.coop.members[77]={"hp":50.0,"name":"Friend"};game.update.downed=true
	Spectate.tick(game,1.0/60.0)
	var watching=Spectate.target_id==77 and Spectate.anchor(game,Vector3.ZERO).distance_to(friend.position+Vector3.UP*1.2)<.01
	Spectate.last_cheer=-99.0;var cheered=Spectate.cheer(game,0) and int(Spectate.last_heard.get("index",-1))==0 and not Spectate.cheer(game,1)
	checks.downed_spectate=watching and cheered and ResourceLoader.exists("res://assets/voices/cheers/cheer_horn.wav")
	game.update.downed=false;game.coop.avatars.erase(77);game.coop.members.erase(77);game.coop.active=false;friend.queue_free();Spectate.tick(game,1.0/60.0)
	# Dyleris reveals three dropai under the island; each changes the run when taken.
	use(game,"duck")
	var first=Dropai.reveal(game);var again=Dropai.reveal(game)
	var under=Dropai.hidden.all(func(h):return h.position.y<game.world.height_at(h.position.x,h.position.z)-5.0 and is_instance_valid(h.node))
	var before_stats=game.stats.duplicate(true)
	for item in Dropai.hidden.duplicate(): Dropai.take(game,item)
	var changed=Dropai.found.size()==3 and Dropai.markers().is_empty() and (Dropai.found.has("rain") or game.stats!=before_stats)
	checks.dropai=first and not again and Dropai.hidden.size()==3 and under and changed
	Dropai.reset()
	# Clutch: first person, aims by hand, headshots, Lock-On, sneaking, no slam.
	use(game,"clutch")
	game.yaw=0.0;game.pitch=0.0;ClutchPlay.place_camera(game,1.0/60.0)
	var fps_ok=ClutchPlay.first_person(game) and is_equal_approx(game.camera.fov,ClutchPlay.FOV) and game.camera.global_position.distance_to(game.player.position+Vector3.UP*ClutchPlay.EYE)<.05
	game.spawn_enemy(6);var target=game.enemies[-1];target.node.position=game.player.position+Vector3(0,0,-8);target.flying=false;target.hp=99999.0;target.maxHp=99999.0
	var gun=ClutchPlay.active_weapon(game);var hp0=float(target.hp)
	var idle=ClutchPlay.trigger(game,gun)
	game.set_meta("test_trigger",true)
	var belly=target.node.position+Vector3.UP*float(target.height)*.4;var eye0=game.player.position+Vector3.UP*ClutchPlay.EYE
	game.pitch=-atan2(belly.y-eye0.y,eye0.distance_to(Vector3(belly.x,eye0.y,belly.z)));ClutchPlay.place_camera(game,1.0/60.0)
	var shot=ClutchPlay.trigger(game,gun);var body_hit=hp0-float(target.hp)
	# Aim at the head: the pitch that points the eye at the top of the body.
	var head=ClutchPlay.head_point(game,target);var eye=game.player.position+Vector3.UP*ClutchPlay.EYE
	game.pitch=-atan2(head.y-eye.y,eye.distance_to(Vector3(head.x,eye.y,head.z)));ClutchPlay.place_camera(game,1.0/60.0)
	var hp1=float(target.hp);ClutchPlay.trigger(game,gun);var head_hit=hp1-float(target.hp)
	# Look away and miss; Lock-On still finds the head, at five times the damage.
	game.yaw=PI*.5;game.pitch=0.0;ClutchPlay.place_camera(game,1.0/60.0)
	var hp2=float(target.hp);ClutchPlay.trigger(game,gun);var missed=is_equal_approx(hp2,float(target.hp))
	game.trick_cooldown=0.0;HeroTricks.use(game)
	var hp3=float(target.hp);ClutchPlay.trigger(game,gun);var locked=hp3-float(target.hp)
	game.remove_meta("test_trigger")
	checks.clutch_aims=fps_ok and not idle and shot and body_hit>0 and head_hit>body_hit*1.5 and missed and locked>body_hit*4.0
	checks.clutch_rules=not HeroRules.can_slam(game.hero) and HeroRules.can_jump(game.hero) and game.rules.banished.has("slamPower") and not game.rules.banished.has("jumpHeight")
	ClutchPlay.sneaking=true;ClutchPlay.last_seen=Vector3(3,0,3)
	var hunted=game.coop.target(target.node.position) if game.coop.has_method("target") else {"position":ClutchPlay.last_seen}
	checks.clutch_sneak=ClutchPlay.hidden(game) and Vector3(hunted.position).distance_to(ClutchPlay.last_seen)<.01 and is_equal_approx(ClutchPlay.speed_scale(game),ClutchPlay.SNEAK_SPEED)
	ClutchPlay.reset()
	game.clear_entities()
	game.select_hero(saved_hero)
	return checks

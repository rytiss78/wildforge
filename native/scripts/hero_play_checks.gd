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
	game.clear_entities()
	game.select_hero(saved_hero)
	return checks

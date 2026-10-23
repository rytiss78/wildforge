extends RefCounted

# Biome fight mechanics through the real tick (update_combat) and the hero's
# real movement step, each against a control outside the zone.
static func dummy(game: Node3D,offset: Vector3) -> Dictionary:
	game.spawn_enemy(6);var enemy=game.enemies[-1]
	var p=game.player.position+offset;p.y=game.world.height_at(p.x,p.z)
	enemy.node.position=p;enemy.speed=0.0;enemy.attack=1e9;enemy.contact=1e9;enemy.damage=0.0;enemy.hp=1e6;enemy.maxHp=1e6;enemy.boss=false;enemy.behavior="chase";enemy.home=p
	enemy.fire=0.0;enemy.poison=0.0;enemy.freeze=0.0;enemy.slow=0.0
	return enemy

static func setup(game: Node3D):
	game.clear_entities();game.spawn_clock=1e9;game.mode="playing";game.realm_time=0.0;game.invulnerable=0.0
	game.player.position=Vector3(0,game.world.height_at(0,0)+.05,0);game.player.velocity=Vector3.ZERO;game.knock_velocity=Vector3.ZERO

static func event(game: Node3D,biome: int,at: Vector3,dir: Vector3=Vector3.RIGHT) -> Dictionary:
	var message={"type":"biome_event","realm":game.realm,"biome":biome,"pos":[at.x,at.z],"dir":[dir.x,dir.z],"serial":biome}
	BiomeMechanics.spawn(game,message)
	return game.biome_zones[-1]

static func run_frames(game: Node3D,frames: int,physics: bool=false):
	for i in range(frames):
		game.realm_time=0.0  # keep the scheduler from adding events of its own
		if physics: game._physics_process(1.0/60.0)
		game.update_combat(1.0/60.0)

static func run(game: Node3D) -> Dictionary:
	var checks={}
	var hp_scale=game.stats.maxHp
	# Clover: heals and sheds statuses inside.
	setup(game);game.hp=hp_scale*.4;game.player_poison=5.0
	event(game,0,game.player.position);var before=game.hp
	run_frames(game,90)
	checks.biome_clover=game.hp>before+1.0 and game.player_poison<=0.0
	# Spore fog: poisons the hero and enemies inside, not an enemy outside.
	setup(game);var foggy=dummy(game,Vector3(1.5,0,0));var clear_air=dummy(game,Vector3(14,0,0))
	var spores=event(game,1,game.player.position,Vector3.FORWARD)
	run_frames(game,int(spores.warn*60)+20)
	checks.biome_spores=game.player_poison>0.0 and float(foggy.poison)>0.0 and float(clear_air.poison)<=0.0 and spores.pos.distance_to(Vector3(0,spores.pos.y,0))>.2
	# Ice: the hero keeps sliding with no input; outside, they stop. Enemies slow.
	setup(game);game.player.velocity=Vector3(8,0,0);run_frames(game,30,true);var dry=Vector2(game.player.velocity.x,game.player.velocity.z).length()
	setup(game);var skater=dummy(game,Vector3(-2,0,0))
	var ice=event(game,2,game.player.position);run_frames(game,int(ice.warn*60)+5)
	game.player.velocity=Vector3(8,0,0);run_frames(game,30,true);var icy=Vector2(game.player.velocity.x,game.player.velocity.z).length()
	checks.biome_ice=icy>dry+2.0 and float(skater.slow)>=.45
	# Gust: shoves the hero and enemies along its direction.
	setup(game);var blown=dummy(game,Vector3(0,0,3));var start=blown.node.position;var hero_start=game.player.position
	var gust=event(game,3,game.player.position,Vector3.RIGHT);run_frames(game,int(gust.warn*60)+60,true)
	checks.biome_gust=blown.node.position.x-start.x>2.0 and game.player.position.x-hero_start.x>2.0
	# Lava vent: the pool spreads, burns enemies, and hurts a hero standing in it.
	setup(game);game.hp=hp_scale;var scorched=dummy(game,Vector3(1.5,0,0))
	var lava=event(game,4,game.player.position);run_frames(game,int(lava.warn*60)+5)
	var small=BiomeMechanics.zone_radius(lava);run_frames(game,250,true)
	checks.biome_lava=small<2.0 and BiomeMechanics.zone_radius(lava)>4.0 and float(scorched.fire)>0.0 and game.hp<hp_scale
	# Gravity rift: pulls enemies in, then implodes on them.
	setup(game);var pulled=dummy(game,Vector3(5,0,0));var far=pulled.node.position.distance_to(game.player.position+Vector3(0,0,8))
	var rift=event(game,5,game.player.position+Vector3(0,0,8));run_frames(game,int(rift.warn*60)+40,true)
	var nearer=pulled.node.position.distance_to(rift.pos)
	run_frames(game,int(rift.life*60)+10,true)
	checks.biome_rift=nearer<far-1.0 and pulled.hp<1e6 and game.biome_zones.is_empty()
	# The scheduler rolls the hero's own biome after the opening 40 s, and says what it is.
	setup(game);var biome=game.world.biome_at(game.player.position)
	game.realm_time=60.0;game.spawn_clock=0.0;game.biome_clocks[str(game.coop.local_id)]=0.0;game.remove_meta("biome_seen_mechanics")
	BiomeMechanics.tick(game,1.0/60.0);game.spawn_clock=1e9
	checks.biome_scheduled=game.biome_zones.size()==1 and game.biome_zones[0].kind==BiomeMechanics.KINDS[biome].id and game.get_meta("biome_seen_mechanics",{}).has(game.biome_zones[0].kind)
	# An event for another island is ignored; clearing a realm removes zones; none on the Red Moon.
	var count=game.biome_zones.size()
	BiomeMechanics.spawn(game,{"type":"biome_event","realm":game.realm+1,"biome":1,"pos":[0,0],"dir":[1,0]})
	checks.biome_other_realm=game.biome_zones.size()==count
	game.clear_entities();checks.biome_cleared=game.biome_zones.is_empty()
	var realm=game.realm;game.realm=3;checks.biome_not_red_moon=not BiomeMechanics.active(game);game.realm=realm
	setup(game);game.hp=game.stats.maxHp
	return checks

extends RefCounted

# Measured mutation damage through the real game code: strain effects, areas,
# clouds, burn/poison ticks, echoes, chances and cooldowns. Triggers fire at
# fixed rates that approximate ordinary play against stationary dummies, with
# a seeded RNG, in a crowd (12 enemies within 7 m) and a sparse field (3).
# Runs last 12 s at 20 steps/s to keep the whole sweep within the step budget.
# Rule, hybrid and wild cards are measured as the damage they add to a kit.
# The hero sits at half health, so low-health cards stay in their ordinary state.
# This compares mutations with each other and with the starting gun; it is not
# a survival or full-run measurement.

const SECONDS=12.0
const STEP=1.0/20.0
const RATES={"hit":2.0,"crit":.3,"kill":.5,"dash":.35,"jump":.6,"slam":.15,"hurt":.2,"pickup":1.0}

static func field(g,crowd: bool) -> Array:
	g.clear_entities()
	var spots=[]
	if crowd:
		for ring in [[2.5,4],[4.5,4],[7.0,4]]:
			for i in range(ring[1]): spots.append(Vector3.FORWARD.rotated(Vector3.UP,TAU*i/ring[1]+ring[0])*ring[0])
	else: spots=[Vector3(0,0,-3),Vector3(4,0,-4),Vector3(-6,0,-6)]
	var dummies=[]
	for spot in spots:
		g.spawn_enemy(6);var enemy=g.enemies[-1]
		var p=g.player.position+spot;p.y=g.world.height_at(p.x,p.z);enemy.node.position=p
		enemy.speed=0.0;enemy.attack=1e9;enemy.contact=1e9;enemy.damage=0.0;enemy.behavior="chase";enemy.home=p
		dummies.append(enemy)
	return dummies

static func reset(g,dummies: Array,seed_value: int):
	for list in [g.projectiles,g.effects,g.pools,g.hazards]:
		for item in list:
			if is_instance_valid(item.get("node")): item.node.queue_free()
		list.clear()
	for enemy in g.enemies.filter(func(e): return not dummies.has(e)):
		if is_instance_valid(enemy.node): enemy.node.queue_free()
	g.enemies=g.enemies.filter(func(e): return dummies.has(e))
	for enemy in dummies:
		enemy.hp=1e7;enemy.maxHp=1e7;enemy.fire=0.0;enemy.poison=0.0;enemy.freeze=0.0;enemy.blind=0.0;enemy.slow=0.0;enemy.status_time=0.0;enemy.dead=false
		# Pulls and knockbacks move dummies; each run starts from the same layout.
		enemy.node.position=enemy.home;enemy.vertical=0.0;enemy.reaction_until=0.0;enemy.slip_until=0.0;enemy.bubble=0.0;enemy.charge=0.0
	g.stats=g.rules.data.stats.duplicate(true);g.stats.maxHp=1e6;g.hp=5e5;g.shield_hp=0.0
	g.equipped.clear();g.owned.clear();g.buffs.clear();g.condition_times.clear()
	MutationBook.reset(g);g.rules.rng.seed=seed_value;g.elapsed=1000.0;g.dash_cooldown=0.0

# Damage per second dealt to the dummies, and healing per second, over one run.
static func run_once(g,dummies: Array,mutations: Array,gun: bool,seed_value: int) -> Dictionary:
	reset(g,dummies,seed_value)
	for id in mutations: MutationBook.take(g,MutationBook.card(id,1))
	if gun:
		var weapon=g.rules.data.weapons.filter(func(w):return w.id=="gun")[0].duplicate(true);weapon.kind="weapon";weapon.strength=1.0;g.equip_weapon(weapon)
	# Reseed after setup: taking cards and weapons draws from the RNG, and a shifted
	# sequence would show up as damage noise on cards that change nothing here.
	g.rules.rng.seed=seed_value
	var counters={};var target=0;var t=0.0
	while t<SECONDS:
		t+=STEP;g.elapsed+=STEP;g.realm_time+=STEP
		for trigger in RATES:
			var due=int(t*RATES[trigger])-int(counters.get(trigger,0))
			for i in range(due):
				counters[trigger]=int(counters.get(trigger,0))+1
				var enemy=dummies[target%dummies.size()];target+=1
				var point=enemy.node.position if trigger in ["hit","crit","kill"] else g.player.position
				if trigger=="dash": g.condition_times.dash=g.elapsed
				MutationBook.event(g,trigger,point,{"enemy":enemy} if trigger in ["hit","crit","kill"] else {})
		MutationBook.tick(g,STEP)
		g.update_combat(STEP)
	var dealt=0.0
	for enemy in dummies: dealt+=1e7-enemy.hp
	return {"dps":snappedf(dealt/SECONDS,.1),"hps":snappedf((g.hp-5e5)/SECONDS,.01)}

static func run(g):
	AudioServer.set_bus_volume_db(0,-80)
	g.start_run(2025);g.set_process(false);g.set_physics_process(false)
	g.invulnerable=1e9;g.spawn_clock=1e9;g.formation_clock=1e9;g.xp_target=1e9;g.sound.settings.sfx=0
	var result={"seconds":SECONDS,"rates":RATES,"gun":{},"core":{},"extras":{}}
	for layout in ["crowd","sparse"]:
		var dummies=field(g,layout=="crowd")
		result.gun[layout]=run_once(g,dummies,[],true,7).dps
		for strain in MutationBook.STRAIN_ORDER:
			for trigger in MutationBook.TRIGGER_ORDER:
				var id=strain+"_"+trigger;var row=result.core.get(id,{})
				var measured=run_once(g,dummies,[id],false,11);row[layout]=measured.dps;row[layout+"_heal"]=measured.hps
				result.core[id]=row
		# Extras: the damage a card adds to the gun plus a two-mutation kit of its strain(s),
		# in the crowd. Gun hits keep landing on the nearest enemy, as in play, which
		# conditional cards (Shatter, Rot, Thermal Shock) depend on.
		if layout!="crowd": continue
		# Repeatability: the same kit and seed must measure the same; extras rely on it.
		result.repeat=[]
		for i in range(3): result.repeat.append(run_once(g,dummies,["ember_dash","frost_kill","storm_hit"],true,13).dps)
		for id in MutationBook.all():
			var definition=MutationBook.all()[id]
			if definition.group=="core": continue
			var kit=[]
			if definition.has("strain"): kit=[definition.strain+"_hit",definition.strain+"_kill"]
			elif definition.has("pair"): kit=[definition.pair[0]+"_hit",definition.pair[1]+"_kill"]
			else: kit=["ember_dash","frost_kill","storm_hit"]
			var base=run_once(g,dummies,kit,true,13)
			var with_card=run_once(g,dummies,kit+[id],true,13)
			var row=result.extras.get(id,{"group":definition.group})
			row.base=base.dps;row[layout]=snappedf(with_card.dps-base.dps,.1);row[layout+"_heal"]=snappedf(with_card.hps-base.hps,.01)
			result.extras[id]=row
	print("MUTATION_BALANCE "+JSON.stringify(result))
	g.get_tree().quit(0)

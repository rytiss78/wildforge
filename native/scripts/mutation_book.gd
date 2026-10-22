extends RefCounted
class_name MutationBook

# Mutations change how a run plays rather than adding a stat percentage. Each
# strain comes from one biome and releases its element on a trigger (dash, kill,
# slam...). Strain rules, hybrids and wild cards bend those effects further.
# Owned mutations live in game.mutations as id -> level; taking one again levels it.

const STRAINS={
	"bloom":{"name":"Bloom","biome":"Clover Woods","color":Color("7fe08a"),"cause":"thorn","effect":"thorns burst out and heal you"},
	"venom":{"name":"Venom","biome":"Puffcap Marsh","color":Color("a6e04c"),"cause":"poison","effect":"a poison cloud bursts and lingers"},
	"frost":{"name":"Frost","biome":"Moon Craters","color":Color("8be7ff"),"cause":"ice","effect":"a freezing nova erupts"},
	"storm":{"name":"Storm","biome":"Cloudwilds","color":Color("6fb8ff"),"cause":"lightning","effect":"lightning strikes nearby enemies"},
	"ember":{"name":"Ember","biome":"Candy Hell","color":Color("ff7a3d"),"cause":"fire","effect":"the ground erupts in flame"},
	"comet":{"name":"Comet","biome":"Starfall Space","color":Color("c9a4ff"),"cause":"hit","effect":"a gravity shock hurls enemies away"},
}
const STRAIN_ORDER=["bloom","venom","frost","storm","ember","comet"]
# power scales the hero's damage stat; chance/cooldown keep frequent triggers readable.
const TRIGGERS={
	"hit":{"when":"on 20% of weapon hits","power":.6,"chance":.2,"cooldown":.3,"glyph":"hit"},
	"crit":{"when":"on critical hits","power":1.0,"cooldown":.25,"glyph":"crit"},
	"kill":{"when":"when you defeat an enemy","power":.75,"cooldown":.12,"glyph":"kill"},
	"dash":{"when":"when you dash","power":.8,"glyph":"dash"},
	"jump":{"when":"when you jump","power":.45,"cooldown":.2,"glyph":"jump"},
	"slam":{"when":"when your slam lands","power":3.4,"glyph":"slam"},
	"hurt":{"when":"when you are hit","power":1.6,"glyph":"hurt"},
	"pulse":{"when":"every 4 seconds","power":1.0,"glyph":"pulse"},
	"pickup":{"when":"on 25% of coin pickups","power":.9,"chance":.25,"cooldown":.4,"glyph":"pickup"},
}
const TRIGGER_ORDER=["hit","crit","kill","dash","jump","slam","hurt","pulse","pickup"]
const CORE_NAMES={
	"bloom":["Thorn Edge","Briar Point","Seed Wake","Petal Step","Vine Leap","Root Fist","Bark Skin","Verdant Pulse","Bloom Purse"],
	"venom":["Fang Edge","Toxic Point","Rot Wake","Miasma Step","Spore Leap","Plague Fist","Bitter Blood","Swamp Pulse","Venom Purse"],
	"frost":["Rime Edge","Hoarfrost Point","Frozen Wake","Glacier Glide","Snowburst Leap","Avalanche Fist","Ice Mirror","Winter Pulse","Frost Purse"],
	"storm":["Arc Edge","Thunder Point","Static Wake","Bolt Step","Skybreak Leap","Thunderclap Fist","Lightning Rod","Storm Heart","Charged Purse"],
	"ember":["Spark Edge","Searing Point","Pyre Wake","Cinder Step","Flare Leap","Magma Fist","Smoldering Hide","Hearthbeat","Ember Purse"],
	"comet":["Star Edge","Nova Point","Meteor Wake","Orbit Step","Starfall Leap","Impact Fist","Event Horizon","Gravity Pulse","Stardust Purse"],
}
const RULES=[
	{"id":"bloom_mastery","strain":"bloom","name":"Deep Roots","text":"Bloom mutations deal +40% damage and reach 15% farther."},
	{"id":"bloom_echo","strain":"bloom","name":"Second Bloom","text":"Bloom mutations burst again 0.45 s later at 60% power."},
	{"id":"bloom_lifebloom","strain":"bloom","name":"Lifebloom","text":"Bloom healing is tripled; healing past full grows your shield."},
	{"id":"venom_mastery","strain":"venom","name":"Potent Spores","text":"Venom mutations deal +40% damage and reach 15% farther."},
	{"id":"venom_echo","strain":"venom","name":"Lingering Bite","text":"Venom mutations burst again 0.45 s later at 60% power."},
	{"id":"venom_rot","strain":"venom","name":"Rot","text":"Poisoned enemies take +40% damage from you."},
	{"id":"frost_mastery","strain":"frost","name":"Deep Winter","text":"Frost mutations deal +40% damage and reach 15% farther."},
	{"id":"frost_echo","strain":"frost","name":"Second Frost","text":"Frost mutations burst again 0.45 s later at 60% power."},
	{"id":"frost_shatter","strain":"frost","name":"Shatter","text":"Frozen enemies take +50% damage from you."},
	{"id":"storm_mastery","strain":"storm","name":"High Voltage","text":"Storm mutations deal +40% damage and reach 15% farther."},
	{"id":"storm_echo","strain":"storm","name":"Afterstrike","text":"Storm mutations strike again 0.45 s later at 60% power."},
	{"id":"storm_conductor","strain":"storm","name":"Conductor","text":"Storm lightning jumps to 2 more enemies."},
	{"id":"ember_mastery","strain":"ember","name":"White Heat","text":"Ember mutations deal +40% damage and reach 15% farther."},
	{"id":"ember_echo","strain":"ember","name":"Twin Flames","text":"Ember mutations erupt again 0.45 s later at 60% power."},
	{"id":"ember_wildfire","strain":"ember","name":"Wildfire","text":"Enemies you defeat while they burn erupt in flame."},
	{"id":"comet_mastery","strain":"comet","name":"Dense Core","text":"Comet mutations deal +40% damage and reach 15% farther."},
	{"id":"comet_echo","strain":"comet","name":"Aftershock","text":"Comet mutations strike again 0.45 s later at 60% power."},
	{"id":"comet_slipstream","strain":"comet","name":"Slipstream","text":"Move 20% faster; each kill cuts dash cooldown by 0.3 s.","stats":{"speed":.2}},
]
# A hybrid needs one mutation from each of its two strains.
const HYBRIDS=[
	{"id":"hy_thermal","pair":["ember","frost"],"name":"Thermal Shock","text":"Hitting an enemy that is burning and frozen detonates it for heavy damage."},
	{"id":"hy_plasma","pair":["ember","storm"],"name":"Plasma Arc","text":"Storm lightning sets enemies on fire.","infuse":["storm","fire"]},
	{"id":"hy_fumes","pair":["ember","venom"],"name":"Toxic Fumes","text":"Ember eruptions leave poison clouds.","pool":"ember"},
	{"id":"hy_ash","pair":["ember","bloom"],"name":"Ash Garden","text":"Ember eruptions heal you 2.","heal":["ember",2.0]},
	{"id":"hy_meteor","pair":["ember","comet"],"name":"Burning Meteor","text":"Comet shocks set enemies on fire.","infuse":["comet","fire"]},
	{"id":"hy_supercond","pair":["frost","storm"],"name":"Superconductor","text":"Storm lightning deals double damage to frozen enemies."},
	{"id":"hy_coldvenom","pair":["frost","venom"],"name":"Cold Venom","text":"Venom clouds also freeze.","infuse":["venom","ice"]},
	{"id":"hy_rose","pair":["frost","bloom"],"name":"Winter Rose","text":"Frost novas heal you 2.","heal":["frost",2.0]},
	{"id":"hy_comet_ice","pair":["frost","comet"],"name":"Ice Comet","text":"Comet shocks freeze enemies.","infuse":["comet","ice"]},
	{"id":"hy_neuro","pair":["storm","venom"],"name":"Neurotoxin","text":"Storm lightning poisons enemies.","infuse":["storm","poison"]},
	{"id":"hy_rain","pair":["storm","bloom"],"name":"Spring Rain","text":"Each Storm strike heals you 1.","heal":["storm",1.0]},
	{"id":"hy_thunderhead","pair":["storm","comet"],"name":"Thunderhead","text":"Comet shocks also call two lightning strikes."},
	{"id":"hy_nightshade","pair":["venom","bloom"],"name":"Nightshade","text":"Venom clouds heal you 2.","heal":["venom",2.0]},
	{"id":"hy_plague_star","pair":["venom","comet"],"name":"Plague Star","text":"Comet shocks poison enemies.","infuse":["comet","poison"]},
	{"id":"hy_pollen","pair":["bloom","comet"],"name":"Pollen Drift","text":"Bloom bursts reach 60% farther and Comet shocks heal you 1.","heal":["comet",1.0]},
]
const WILD=[
	{"id":"wild_twin","name":"Twin Fate","text":"Mutation cooldowns and pulse timers are 35% shorter."},
	{"id":"wild_resonance","name":"Resonance","text":"Mutations deal +15% damage for each strain you carry."},
	{"id":"wild_hair","name":"Hair Trigger","text":"Chance-based mutations trigger twice as often."},
	{"id":"wild_bloodrush","name":"Bloodrush","text":"Each kill cuts your dash cooldown by 0.25 s."},
	{"id":"wild_overflow","name":"Overflow","text":"Pulse mutations fire every 2.5 seconds."},
	{"id":"wild_glass","name":"Glass Heart","text":"Mutations deal +60% damage; max health −25%.","stats":{"maxHp":-.25}},
	{"id":"wild_second","name":"Second Wind","text":"For 3 s after you are hit, mutations deal double damage."},
	{"id":"wild_vortex","name":"Vortex","text":"Mutation bursts drag nearby enemies inward."},
	{"id":"wild_echo","name":"Great Echo","text":"Every mutation repeats once more at 40% power."},
	{"id":"wild_wide","name":"Wide Arc","text":"Mutation bursts reach 25% farther."},
	{"id":"wild_last","name":"Last Stand","text":"Below 35% health, mutations deal double damage."},
	{"id":"wild_momentum","name":"Momentum","text":"For 1 s after a dash, mutations deal +50% damage."},
	{"id":"wild_hunter","name":"Hunter's Mark","text":"Mutations deal +80% damage to elites and bosses."},
	{"id":"wild_conduit","name":"Conduit","text":"Dash and jump mutations fire twice."},
	{"id":"wild_vigor","name":"Vigor","text":"Each mutation you take raises max health by 10 and heals 25."},
]

static var catalog={}

static func all() -> Dictionary:
	if not catalog.is_empty(): return catalog
	for strain in STRAIN_ORDER:
		for i in range(TRIGGER_ORDER.size()):
			var trigger=TRIGGER_ORDER[i];var info=TRIGGERS[trigger]
			var sentence=str(info.when)+", "+str(STRAINS[strain].effect)+"."
			catalog[strain+"_"+trigger]={"id":strain+"_"+trigger,"group":"core","strain":strain,"trigger":trigger,"name":CORE_NAMES[strain][i],"text":sentence.left(1).to_upper()+sentence.substr(1)}
	for rule in RULES: catalog[rule.id]=rule.merged({"group":"rule"})
	for hybrid in HYBRIDS: catalog[hybrid.id]=hybrid.merged({"group":"hybrid"})
	for wild in WILD: catalog[wild.id]=wild.merged({"group":"wild"})
	return catalog

static func entry(id: String) -> Dictionary:
	return all().get(id,{})

static func tier_for(definition: Dictionary) -> int:
	return {"core":1,"rule":2,"wild":2,"hybrid":3}.get(definition.get("group","core"),1)

static func family(definition: Dictionary) -> String:
	if definition.has("strain"): return STRAINS[definition.strain].name
	if definition.has("pair"): return STRAINS[definition.pair[0]].name+" + "+STRAINS[definition.pair[1]].name
	return "Wild"

# An offer card. The single marker effect keeps banish and description paths
# working; apply_effects() ignores the key because it is not a hero stat.
static func card(id: String,level: int) -> Dictionary:
	var definition=entry(id)
	return {"id":"mut:"+id,"name":definition.name+(" · Lv "+str(level) if level>1 else ""),"title":definition.name,"kind":"mutation","family":family(definition),"tier":tier_for(definition),"strength":1.0,"effects":[{"key":"mut:"+id,"amount":level,"mode":"add"}]}

static func describe(key: String,level: int) -> String:
	var definition=entry(key.trim_prefix("mut:"))
	if definition.is_empty(): return "Mutation"
	var text=str(definition.text)
	if definition.group=="core" and level>1: text+=" Level %d: +%d%% power." % [level,(level-1)*50]
	return text

static func strains_owned(g) -> Array:
	var found=[]
	for id in g.mutations:
		var definition=entry(id)
		if definition.has("strain") and not found.has(definition.strain): found.append(definition.strain)
	return found

static func eligible(g,definition: Dictionary) -> bool:
	if g.rules.banished.has("mut:"+definition.id): return false
	if definition.group=="hybrid":
		var owned=strains_owned(g);return owned.has(definition.pair[0]) and owned.has(definition.pair[1]) and not g.mutations.has(definition.id)
	if definition.group in ["rule","wild"] and g.mutations.has(definition.id): return false
	if definition.group=="rule": return strains_owned(g).has(definition.strain)
	return true

static func roll(g,exclude: Array) -> Dictionary:
	var owned=strains_owned(g);var pool=[]
	for id in all():
		var definition=all()[id]
		if exclude.has("mut:"+id) or not eligible(g,definition): continue
		var weight={"core":3.0,"rule":2.5,"hybrid":4.0,"wild":1.0}[definition.group]
		# Favour strains already carried so runs grow a direction, with room to branch.
		if definition.has("strain") and owned.has(definition.strain): weight*=1.8
		if definition.group=="core" and g.mutations.has(id): weight*=.8
		pool.append([id,weight])
	if pool.is_empty(): return {}
	var total=pool.reduce(func(sum,item):return sum+item[1],0.0);var pick=g.rules.rng.randf()*total
	for item in pool:
		pick-=item[1]
		if pick<=0: return card(item[0],int(g.mutations.get(item[0],0))+1)
	return card(pool[-1][0],int(g.mutations.get(pool[-1][0],0))+1)

# Level-up skill offers become mostly mutations; chests sometimes carry one.
static func mix(g,offers: Array,source: String) -> Array:
	if offers.is_empty() or offers.any(func(item):return item.kind=="weapon"): return offers
	var count=3 if source=="level" else (1 if g.rules.rng.randf()<.4 else 0)
	var result=offers.duplicate();var taken=offers.map(func(item):return item.id)
	for slot in range(mini(count,result.size())):
		var mutation=roll(g,taken)
		if mutation.is_empty(): break
		result[slot]=mutation;taken.append(mutation.id)
	return result

static func take(g,item: Dictionary):
	var id=str(item.id).trim_prefix("mut:");var definition=entry(id)
	if definition.is_empty(): return
	g.mutations[id]=int(g.mutations.get(id,0))+1
	if g.mutations[id]==1:
		for key in definition.get("stats",{}):
			g.rules.apply_effects(g.stats,[{"key":key,"amount":definition.stats[key],"mode":"multiply"}])
			if key=="maxHp": g.hp=minf(g.hp,g.stats.maxHp)
	if g.mutations.has("wild_vigor"):
		g.stats.maxHp+=10;g.heal(25)
	g.update_hero_vitals()

static func reset(g):
	g.mutations.clear()
	g.mutation_state={"cooldowns":{},"echo":[],"pulse":0.0,"depth":0,"second_wind":-99.0,"shocked":{}}

static func has(g,id: String) -> bool:
	return g.mutations.has(id)

# Damage scaling shared by every strain effect.
static func power(g,strain: String,base: float,target: Dictionary={}) -> float:
	var value=g.stat("damage")*base
	if has(g,strain+"_mastery"): value*=1.4
	if has(g,"wild_resonance"): value*=1.0+.15*strains_owned(g).size()
	if has(g,"wild_glass"): value*=1.6
	if has(g,"wild_second") and g.elapsed-float(g.mutation_state.second_wind)<3.0: value*=2.0
	if has(g,"wild_last") and g.hp<g.stats.maxHp*.35: value*=2.0
	if has(g,"wild_momentum") and g.elapsed-float(g.condition_times.get("dash",-99))<1.0: value*=1.5
	if has(g,"wild_hunter") and not target.is_empty() and (target.get("boss",false) or target.get("elite",false)): value*=1.8
	return value

static func reach(g,strain: String,base: float) -> float:
	var value=base
	if has(g,strain+"_mastery"): value*=1.15
	if has(g,"wild_wide"): value*=1.25
	if strain=="bloom" and has(g,"hy_pollen"): value*=1.6
	return value

# Damage the hero deals personally (not remote hits or damage-over-time ticks).
static func modify_damage(g,enemy: Dictionary,damage: float) -> float:
	if g.mutations.is_empty(): return damage
	if has(g,"frost_shatter") and float(enemy.get("freeze",0))>0: damage*=1.5
	if has(g,"venom_rot") and float(enemy.get("poison",0))>0: damage*=1.4
	return damage

static func event(g,trigger: String,point: Vector3,context: Dictionary={}):
	if g.mutations.is_empty(): return
	var state=g.mutation_state
	if trigger=="hurt": state.second_wind=g.elapsed
	if trigger=="kill":
		var cut=(.25 if has(g,"wild_bloodrush") else 0.0)+(.3 if has(g,"comet_slipstream") else 0.0)
		if cut>0: g.dash_cooldown=maxf(0,g.dash_cooldown-cut)
		var victim=context.get("enemy",{})
		if has(g,"ember_wildfire") and not victim.is_empty() and float(victim.get("fire",0))>0: release(g,"ember",point,.8,victim)
	if trigger=="hit":
		var target=context.get("enemy",{})
		if has(g,"hy_thermal") and not target.is_empty() and not target.dead and float(target.get("fire",0))>0 and float(target.get("freeze",0))>0:
			var key=int(target.net_id)
			if g.elapsed-float(state.shocked.get(key,-99))>2.0:
				state.shocked[key]=g.elapsed
				CombatInk.blast(g,point,3.5);g.damage_area(point,3.5,power(g,"ember",.8,target),"explosion")
	var cooldown_scale=.65 if has(g,"wild_twin") else 1.0
	for strain in STRAIN_ORDER:
		var id=strain+"_"+trigger
		if not g.mutations.has(id): continue
		var info=TRIGGERS[trigger]
		var chance=float(info.get("chance",1.0))*(2.0 if has(g,"wild_hair") else 1.0)
		if chance<1.0 and g.rules.rng.randf()>chance: continue
		var cooldown=float(info.get("cooldown",0))*cooldown_scale
		if cooldown>0 and g.elapsed-float(state.cooldowns.get(id,-99))<cooldown: continue
		state.cooldowns[id]=g.elapsed
		var level_scale=1.0+.5*(int(g.mutations[id])-1)
		var repeats=2 if trigger in ["dash","jump"] and has(g,"wild_conduit") else 1
		for repeat in range(repeats):
			release(g,strain,point,float(info.power)*level_scale,context.get("enemy",{}))

# One strain effect at a point, plus any echoes it earns.
static func release(g,strain: String,point: Vector3,strength: float,target: Dictionary={},echo: bool=false):
	var state=g.mutation_state
	if int(state.depth)>2: return
	state.depth+=1
	match strain:
		"bloom": bloom(g,point,strength,target)
		"venom": venom(g,point,strength,target)
		"frost": frost(g,point,strength,target)
		"storm": storm(g,point,strength,target)
		"ember": ember(g,point,strength,target)
		"comet": comet(g,point,strength,target)
	if has(g,"wild_vortex"): drag(g,point,reach(g,strain,4.5),-1.6)
	state.depth-=1
	if echo: return
	if has(g,strain+"_echo"): state.echo.append({"at":g.elapsed+.45,"strain":strain,"point":point,"strength":strength*.6})
	if has(g,"wild_echo"): state.echo.append({"at":g.elapsed+.6,"strain":strain,"point":point,"strength":strength*.4})

static func infuse(g,strain: String,enemies: Array):
	for hybrid in HYBRIDS:
		if not hybrid.has("infuse") or hybrid.infuse[0]!=strain or not has(g,hybrid.id): continue
		for enemy in enemies:
			if not enemy.dead: g.hurt_enemy(enemy,1.0,hybrid.infuse[1])

static func hybrid_heal(g,strain: String):
	for hybrid in HYBRIDS:
		if hybrid.has("heal") and hybrid.heal[0]==strain and has(g,hybrid.id): g.heal(float(hybrid.heal[1]))

static func inside(g,point: Vector3,radius: float) -> Array:
	return g.enemies.filter(func(e):return not e.dead and point.distance_to(g.melee_contact(e,point))<radius)

static func area(g,strain: String,point: Vector3,radius: float,damage: float,cause: String) -> Array:
	var hit=inside(g,point,radius)
	for enemy in hit: g.hurt_enemy(enemy,damage,cause,"mutation:"+strain)
	infuse(g,strain,hit);hybrid_heal(g,strain)
	return hit

static func bloom(g,point: Vector3,strength: float,target: Dictionary):
	var radius=reach(g,"bloom",2.8)
	CombatInk.wave(g,point,radius,STRAINS.bloom.color)
	area(g,"bloom",point,radius,power(g,"bloom",strength*1.15,target),"thorn")
	var amount=1.0+strength*1.2
	if has(g,"bloom_lifebloom"):
		amount*=3.0
		var spill=maxf(0,g.hp+amount-g.stats.maxHp)
		if spill>0: g.shield_hp=minf(g.shield_hp+spill,maxf(g.stats.shield+g.stats.jumpShield,30.0))
	g.heal(amount)

static func venom(g,point: Vector3,strength: float,target: Dictionary):
	var radius=reach(g,"venom",2.4)
	g.burst(point+Vector3.UP*.6,STRAINS.venom.color,8)
	area(g,"venom",point,radius,power(g,"venom",strength*.25,target),"poison")
	cloud(g,point,radius*.8,power(g,"venom",strength*.1,target))

static func frost(g,point: Vector3,strength: float,target: Dictionary):
	var radius=reach(g,"frost",3.6)
	CombatInk.wave(g,point,radius,STRAINS.frost.color)
	area(g,"frost",point,radius,power(g,"frost",strength*.85,target),"ice")

static func storm(g,point: Vector3,strength: float,target: Dictionary):
	var bolts=3+(2 if has(g,"storm_conductor") else 0)
	var origin=point;var struck=[]
	for i in range(bolts):
		var next=g.nearest_enemy(origin,reach(g,"storm",11.0),struck.map(func(e):return e.net_id))
		if next.is_empty(): break
		struck.append(next)
		g.lightning_bolt(origin+Vector3.UP*(2.5 if i==0 else 1.0),g.enemy_center(next))
		var damage=power(g,"storm",strength*1.15,next)
		if has(g,"hy_supercond") and float(next.get("freeze",0))>0: damage*=2.0
		g.hurt_enemy(next,damage,"lightning","mutation:storm")
		origin=next.node.position
	infuse(g,"storm",struck)
	for i in range(struck.size()): hybrid_heal(g,"storm")

static func ember(g,point: Vector3,strength: float,target: Dictionary):
	var radius=reach(g,"ember",3.2)
	CombatInk.blast(g,point,radius)
	area(g,"ember",point,radius,power(g,"ember",strength*.85,target),"fire")
	if has(g,"hy_fumes"): cloud(g,point,radius*.8,power(g,"venom",strength*.1,target))

static func comet(g,point: Vector3,strength: float,target: Dictionary):
	var radius=reach(g,"comet",4.2)
	CombatInk.wave(g,point,radius,STRAINS.comet.color)
	area(g,"comet",point,radius,power(g,"comet",strength*.8,target),"hit")
	drag(g,point,radius,2.2)
	if has(g,"hy_thunderhead"): storm(g,point,strength*.6,target)

static func cloud(g,point: Vector3,radius: float,damage: float):
	var node=preload("res://scripts/area_visual.gd").make(g,"poison",radius,point+Vector3.UP*.06)
	g.pools.append({"node":node,"life":4.0,"damage":damage,"radius":radius})
	if g.pools.size()>16: g.pools[0].node.queue_free();g.pools.pop_front()

# Enemy movement belongs to the host; clients only show the burst.
static func drag(g,point: Vector3,radius: float,push: float):
	if g.coop.active and not g.coop.hosting: return
	for enemy in inside(g,point,radius):
		if enemy.boss: continue
		var away=enemy.node.position-point;away.y=0
		if away.length_squared()<.01: continue
		enemy.node.move_and_collide(away.normalized()*push)

static func tick(g,delta: float):
	if g.mutations.is_empty(): return
	var state=g.mutation_state
	var due=state.echo.filter(func(e):return e.at<=g.elapsed)
	state.echo=state.echo.filter(func(e):return e.at>g.elapsed)
	for echo in due: release(g,echo.strain,echo.point,echo.strength,{},true)
	var interval=(2.5 if has(g,"wild_overflow") else 4.0)*(.65 if has(g,"wild_twin") else 1.0)
	state.pulse+=delta
	if state.pulse>=interval:
		state.pulse=0.0;event(g,"pulse",g.player.position)

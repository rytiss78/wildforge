extends RefCounted
class_name SpellSynergy

# Spells and mutation strains feed each other. Spell hits count as weapon hits
# for "on hit" mutations (SkillBook calls MutationBook.event), and each spell
# has two named synergies that switch on while the hero carries the matching
# strain (any mutation of it). Synergy damage scales like the strain's own
# effects, so mastery, Resonance, Glass Heart and the rest apply.
const PAIRS={
	"inferno":{
		"ember":{"name":"Firestorm","text":"Inferno Halo burns twice as hot and ends in a ring of Ember eruptions."},
		"bloom":{"name":"Phoenix Ring","text":"Each enemy Inferno Halo burns heals you 0.3, up to 3 per cast."},
	},
	"thunderstorm":{
		"storm":{"name":"Supercell","text":"Every Storm Crown strike forks Storm lightning to nearby enemies."},
		"frost":{"name":"Hailstorm","text":"Storm Crown strikes freeze the enemies they hit for 0.8 s."},
	},
	"blackhole":{
		"comet":{"name":"Collapsar","text":"Void Orb collapses 50% wider and hurls the crowd outward."},
		"venom":{"name":"Plague Well","text":"Void Orb leaves a poison cloud where it collapses."},
	},
	"tornado":{
		"ember":{"name":"Fire Whirl","text":"Twister Totem sets the enemies it holds on fire."},
		"venom":{"name":"Toxic Cyclone","text":"Twisters leave poison clouds along their path."},
	},
}
const SPELL_NAMES={"inferno":"Inferno Halo","thunderstorm":"Storm Crown","blackhole":"Void Orb","tornado":"Twister Totem"}

static func carried(g,strain: String) -> bool:
	return MutationBook.strains_owned(g).has(strain)

static func on(g,spell_kind: String,strain: String) -> bool:
	return PAIRS.get(spell_kind,{}).has(strain) and carried(g,strain)

# Active synergies for the equipped spells, as [spell kind, strain, definition].
static func active(g) -> Array:
	var found=[]
	for weapon in g.equipped:
		var kind=ContentExpansion.kind(str(weapon.id))
		for strain in PAIRS.get(kind,{}):
			if carried(g,strain): found.append([kind,strain,PAIRS[kind][strain]])
	return found

# Offer-card text: what a strain would switch on with the spells already equipped,
# or what a spell would switch on with the strains already carried.
static func note_for_strain(g,strain: String) -> String:
	var names=[]
	for weapon in g.equipped:
		var kind=ContentExpansion.kind(str(weapon.id))
		if PAIRS.get(kind,{}).has(strain): names.append(PAIRS[kind][strain].name+" with "+SPELL_NAMES[kind])
	return "" if names.is_empty() else "SPELL SYNERGY · "+", ".join(names)

static func note_for_spell(g,weapon_id: String) -> String:
	var kind=ContentExpansion.kind(weapon_id);var names=[]
	for strain in PAIRS.get(kind,{}):
		if carried(g,strain): names.append(PAIRS[kind][strain].name)
	return "" if names.is_empty() else "SPELL SYNERGY · "+", ".join(names)

static func lines(g) -> Array:
	return active(g).map(func(entry):return "%s · %s + %s: %s" % [entry[2].name,SPELL_NAMES[entry[0]],MutationBook.STRAINS[entry[1]].name,entry[2].text])

# The first time each synergy fires in a run, name it on screen.
static func fired(g,kind: String,strain: String):
	var seen: Dictionary=g.mutation_state.get("synergies",{})
	var key=kind+":"+strain
	seen[key]=int(seen.get(key,0))+1;g.mutation_state.synergies=seen
	if seen[key]==1: g.Hunt.announce(g,"SPELL SYNERGY · "+str(PAIRS[kind][strain].name).to_upper(),str(PAIRS[kind][strain].text),"level")

# A spell damaged one enemy (casts that deal damage only, never teammates' visuals).
static func on_hit(g,spell: Dictionary,enemy: Dictionary):
	if g.mutations.is_empty() or enemy.dead: return
	var kind=str(spell.kind)
	if kind=="inferno" and on(g,kind,"ember"):
		# The halo alone leaves a burn of 3; Firestorm leaves twice that, plus the
		# strain's scaling. A fixed target, so repeated casts never compound.
		g.set_damage_status(enemy,"fire",6.0+MutationBook.power(g,"ember",.1,enemy),g.coop.local_id);enemy.status_time=4.0
		fired(g,kind,"ember")
	if kind=="tornado" and on(g,kind,"ember"):
		g.set_damage_status(enemy,"fire",maxf(6.0,MutationBook.power(g,"ember",.5,enemy)),g.coop.local_id);enemy.status_time=4.0
		fired(g,kind,"ember")
	if kind=="inferno" and on(g,kind,"bloom") and float(spell.get("healed",0))<2.99:
		spell.healed=float(spell.get("healed",0))+.3;g.heal(.3);fired(g,kind,"bloom")
		if int(round(spell.healed*10))%15==0: CombatInk.star(g,g.enemy_center(enemy),.9,MutationBook.STRAINS.bloom.color,6.0,.3)

# One Storm Crown strike landed at a point.
static func on_strike(g,spell: Dictionary,point: Vector3):
	if g.mutations.is_empty(): return
	if on(g,"thunderstorm","storm"):
		MutationBook.storm(g,point,.35,{});fired(g,"thunderstorm","storm")
	if on(g,"thunderstorm","frost"):
		var hit=MutationBook.inside(g,point,float(spell.radius))
		for enemy in hit: enemy.freeze=maxf(float(enemy.freeze),.25 if enemy.boss else .8)
		if not hit.is_empty(): CombatInk.wave(g,point,float(spell.radius)*.8,MutationBook.STRAINS.frost.color);fired(g,"thunderstorm","frost")

# Void Orb's collapse; returns the radius scale for its blast.
static func collapse_scale(g) -> float:
	return 1.5 if on(g,"blackhole","comet") else 1.0

static func on_collapse(g,spell: Dictionary,center: Vector3):
	if g.mutations.is_empty(): return
	if on(g,"blackhole","comet"):
		MutationBook.comet(g,center,1.0,{});MutationBook.drag(g,center,float(spell.radius)*1.6,3.0);fired(g,"blackhole","comet")
	if on(g,"blackhole","venom"):
		MutationBook.cloud(g,center,MutationBook.reach(g,"venom",float(spell.radius)*.6),MutationBook.power(g,"venom",.12,{}));fired(g,"blackhole","venom")

# Inferno Halo finished its sweep at radius "front".
static func on_end(g,spell: Dictionary,center: Vector3,front: float):
	if g.mutations.is_empty() or not on(g,"inferno","ember"): return
	for i in range(6):
		var p=center+Vector3.FORWARD.rotated(Vector3.UP,TAU*i/6.0)*front*.85;p.y=g.world.height_at(p.x,p.z)
		MutationBook.ember(g,p,.45,{})
	fired(g,"inferno","ember")

# A twister's damage tick at its current position.
static func on_twister(g,spell: Dictionary,point: Vector3):
	if g.mutations.is_empty() or not on(g,"tornado","venom"): return
	spell.cloud_clock=float(spell.get("cloud_clock",0))-.25
	if spell.cloud_clock>0: return
	spell.cloud_clock=.8
	MutationBook.cloud(g,point,MutationBook.reach(g,"venom",float(spell.radius)*.7),MutationBook.power(g,"venom",.35,{}));fired(g,"tornado","venom")

extends RefCounted
class_name WeaponEvolution

# A weapon at rank RANK, with one matching upgrade card taken (its catalyst),
# can evolve once. The next chest, or the next weapon level-up, offers a gold
# EVOLVE card; choosing it renames the weapon, raises its power and adds the
# evolved form's modifiers, using the same modifier keys as themed weapons.
# Evolved weapons keep their id, so icons, models, co-op and damage numbers
# keep working; the "evolved" flag drives their gilded look.
const RANK=5
const GOLD=Color("ffd36b")
# kind → evolved form. "name" renames the base weapon; variants (themed weapons
# of the same kind) get "adjective" in front of their own name instead.
const FORMS={
	"gun":{"name":"Hand Cannon","adjective":"Gilded","catalyst":"crit","catalyst_text":"Critical hit","power":1.5,"mods":{"extraPierce":2,"shotScale":1.5},"text":"Heavy rounds pierce 2 more enemies"},
	"shotgun":{"name":"Dragon's Breath","adjective":"Dragonfire","catalyst":"burn","catalyst_text":"Fire","power":1.4,"mods":{"extraShots":2,"payload":"fire"},"text":"2 more pellets that set enemies on fire"},
	"flame":{"name":"Phoenix Torch","adjective":"Phoenix","catalyst":"range","catalyst_text":"Reach","power":1.5,"mods":{"extraShots":2,"shotScale":1.4},"text":"2 more, larger flame jets"},
	"poison":{"name":"Plague Bloom","adjective":"Plague","catalyst":"poison","catalyst_text":"Poison","power":1.5,"mods":{"extraShots":2,"shotScale":1.4},"text":"2 more, larger toxic globs"},
	"ice":{"name":"Glacier Lance","adjective":"Glacial","catalyst":"freeze","catalyst_text":"Freeze","power":1.5,"mods":{"extraPierce":3,"shotScale":1.3,"payload":"ice"},"text":"Shards pierce 3 more enemies and always chill"},
	"rail":{"name":"Star Lance","adjective":"Starlit","catalyst":"pierce","catalyst_text":"Piercing","power":1.6,"mods":{"extraPierce":6,"shotScale":1.6},"text":"A thicker beam that pierces 6 more enemies"},
	"lightning":{"name":"Storm Caller","adjective":"Thundering","catalyst":"chain","catalyst_text":"Chain lightning","power":1.5,"mods":{"extraShots":2},"text":"2 more bolts"},
	"saw":{"name":"Blood Reaper","adjective":"Reaping","catalyst":"lifesteal","catalyst_text":"Lifesteal","power":1.8,"mods":{"sweepDot":-.2},"text":"Each swing sweeps a much wider arc"},
	"rocket":{"name":"Doom Barrage","adjective":"Doom","catalyst":"splash","catalyst_text":"Explosive hits","power":1.4,"mods":{"extraShots":2,"shotScale":1.3},"text":"2 more, larger rockets"},
	"ghost":{"name":"Wraith Choir","adjective":"Wraith","catalyst":"blind","catalyst_text":"Blind","power":1.5,"mods":{"extraShots":2,"extraPierce":2},"text":"2 more spirits that pierce 2 more enemies"},
	"turret":{"name":"Fortress Turret","adjective":"Fortress","catalyst":"turretDamage","catalyst_text":"Turret damage","power":1.6,"mods":{"extraShots":1,"shotScale":1.3},"text":"Fires 1 more, larger shot"},
	"boomerang":{"name":"Twin Crescent","adjective":"Crescent","catalyst":"boomerangPower","catalyst_text":"Boomerang power","power":1.5,"mods":{"extraShots":1,"extraPierce":2},"text":"Throws 1 more blade that pierces 2 more enemies"},
	"disc":{"name":"Saw Storm","adjective":"Storm","catalyst":"discBounces","catalyst_text":"Disc bounces","power":1.5,"mods":{"extraShots":1,"extraBounce":3},"text":"1 more disc, 3 more bounces"},
	"harpoon":{"name":"Kraken Hook","adjective":"Kraken","catalyst":"harpoonPull","catalyst_text":"Hook pull","power":1.6,"mods":{"extraPierce":3,"shotScale":1.5},"text":"A huge hook that pierces 3 more enemies"},
	"gravity":{"name":"Event Horizon","adjective":"Abyssal","catalyst":"gravitySize","catalyst_text":"Gravity radius","power":1.5,"mods":{"areaScale":1.6,"durationScale":1.4},"text":"60% wider wells that last 40% longer"},
	"horn":{"name":"Doom Horn","adjective":"Thunderous","catalyst":"hornStun","catalyst_text":"Horn stun","power":1.6,"mods":{"coneDot":.2,"stunBonus":.6},"text":"A much wider blast that stuns 0.6 s longer"},
	"bubble":{"name":"Tide Prison","adjective":"Tidal","catalyst":"bubbleTime","catalyst_text":"Bubble time","power":1.5,"mods":{"extraShots":2,"shotScale":1.4},"text":"2 more, larger bubbles"},
	"meteor":{"name":"Starfall","adjective":"Starfall","catalyst":"meteorCount","catalyst_text":"Extra meteors","power":1.4,"mods":{"extraMeteors":3,"areaScale":1.4},"text":"3 more meteors with 40% wider impacts"},
	"bomb":{"name":"Cluster Charge","adjective":"Cluster","catalyst":"bombSize","catalyst_text":"Bomb radius","power":1.5,"mods":{"extraShots":2,"areaScale":1.5},"text":"2 more bombs with 50% wider blasts"},
	"flowers":{"name":"Wild Garden","adjective":"Wild","catalyst":"flowerPower","catalyst_text":"Bigger blooms","power":2.0,"mods":{},"text":"Blooms hit twice as hard"},
	# Spell damage grows with the square root of power: 2.25 is 1.5x damage.
	"tornado":{"name":"Hurricane Totem","adjective":"Ascended","catalyst":"size","catalyst_text":"Size","power":2.25,"mods":{},"text":"Twisters hit 50% harder"},
	"blackhole":{"name":"Singularity","adjective":"Ascended","catalyst":"size","catalyst_text":"Size","power":2.25,"mods":{},"text":"The vortex hits 50% harder"},
	"thunderstorm":{"name":"Tempest Crown","adjective":"Ascended","catalyst":"size","catalyst_text":"Size","power":2.25,"mods":{},"text":"Sky lightning hits 50% harder"},
	"inferno":{"name":"Sun Halo","adjective":"Ascended","catalyst":"size","catalyst_text":"Size","power":2.25,"mods":{},"text":"The fire ring hits 50% harder"},
}

static func form(weapon_id: String) -> Dictionary:
	var kind=ContentExpansion.kind(weapon_id)
	if FORMS.has(kind): return FORMS[kind]
	return FORMS.turret if kind.ends_with("turret") else {}

static func evolved_name(weapon: Dictionary) -> String:
	var shape=form(str(weapon.id))
	if shape.is_empty(): return str(weapon.name)
	return shape.name if ContentExpansion.kind(str(weapon.id))==str(weapon.id) else shape.adjective+" "+str(weapon.name)

# The catalyst counts once any taken card raises its stat (augments included).
static func has_catalyst(g,key: String) -> bool:
	for card in g.owned:
		if card.get("kind","") in ["mutation","evolution"]: continue
		for effect in card.get("effects",[]):
			var stat=str(effect.key)
			if g.rules.data.augments.has(stat): stat=str(g.rules.data.augments[stat].stat)
			if stat==key: return true
	return false

static func ready(g,weapon: Dictionary) -> bool:
	if weapon.get("evolved",false) or int(weapon.get("rank",1))<RANK: return false
	var shape=form(str(weapon.id))
	return not shape.is_empty() and has_catalyst(g,shape.catalyst)

# What is still missing, for the HUD tooltip and build menu.
static func recipe(g,weapon: Dictionary) -> String:
	var shape=form(str(weapon.id))
	if shape.is_empty(): return ""
	if weapon.get("evolved",false): return "EVOLVED · "+shape.text
	var parts=["rank %d/%d" % [mini(int(weapon.rank),RANK),RANK]+(" ✓" if int(weapon.rank)>=RANK else ""),"a %s card" % shape.catalyst_text+(" ✓" if has_catalyst(g,shape.catalyst) else "")]
	return "Evolves into %s: %s" % [evolved_name(weapon)," + ".join(parts)]

static func card(weapon: Dictionary) -> Dictionary:
	var shape=form(str(weapon.id))
	return {"id":"evolve:"+str(weapon.id),"kind":"evolution","weapon_id":str(weapon.id),"name":"EVOLVE · "+evolved_name(weapon),"title":evolved_name(weapon),"family":"Evolution","tier":3,"strength":1.0,"effects":[],
		"text":"%s becomes %s: +%d%% power. %s." % [weapon.name,evolved_name(weapon),roundi((float(shape.power)-1.0)*100),shape.text]}

# A card of the catalyst stat, rolled like any other, marked with what it evolves.
static func catalyst_card(g,weapon: Dictionary,kind: String) -> Dictionary:
	var key=str(form(str(weapon.id)).catalyst)
	var pool: Array=g.rules.mechanic_pools.get(kind,{}).get(key,[])
	if pool.is_empty() or g.rules.banished.has(key): return {}
	var item: Dictionary=pool[g.rules.rng.randi_range(0,pool.size()-1)].duplicate(true)
	item.tier=g.rules.rarity(float(g.stats.luck));item.strength=[1.0,2.0,3.5,5.5][item.tier]
	item.effects=[item.effects[0].duplicate()];item.effects[0].amount*=item.strength;item.name=item.title
	var candidate=g.stats.duplicate(true);g.rules.apply_effects(candidate,item.effects)
	if candidate.hash()==g.stats.hash(): return {}
	item.catalyst_for=str(weapon.id)
	return item

# Chests and weapon level-ups carry one evolution card for the local player.
# A weapon at full rank that still lacks its catalyst gets that card offered in
# chests and skill level-ups instead, so the recipe is found, not hoped for.
# Co-op pools arrive with the opener's card in them, so strip any first.
static func inject(g,offers: Array,source: String) -> Array:
	var result=[]
	for item in offers:
		if item.get("kind","")=="evolution": continue
		if item.has("catalyst_for"): item=item.duplicate(true);item.erase("catalyst_for")
		result.append(item)
	if result.is_empty(): return result
	var weapon_offer=result.any(func(item):return item.kind=="weapon")
	if source=="chest" or weapon_offer:
		for weapon in g.equipped:
			if ready(g,weapon):
				result[0]=card(weapon);return result
	if source=="chest" or source=="level" and not weapon_offer:
		for weapon in g.equipped:
			var shape=form(str(weapon.id))
			if weapon.get("evolved",false) or int(weapon.rank)<RANK or shape.is_empty() or has_catalyst(g,shape.catalyst): continue
			var catalyst=catalyst_card(g,weapon,"item" if source=="chest" else "skill")
			if not catalyst.is_empty(): result[-1]=catalyst;return result
	return result

static func merge(base: Dictionary,extra: Dictionary) -> Dictionary:
	var result=base.duplicate(true)
	for key in extra:
		var value=extra[key]
		if str(key).begins_with("extra") or key=="stunBonus": result[key]=float(result.get(key,0))+float(value)
		elif str(key).ends_with("Scale"): result[key]=float(result.get(key,1))*float(value)
		elif key in ["coneDot","sweepDot"]: result[key]=minf(float(result.get(key,1)),float(value))
		elif key=="payload": result[key]=value if str(result.get(key,"")).is_empty() else result[key]
		else: result[key]=value
	return result

static func apply(g,item: Dictionary) -> bool:
	for weapon in g.equipped:
		if weapon.id!=item.get("weapon_id","") or weapon.get("evolved",false): continue
		var shape=form(str(weapon.id))
		if shape.is_empty(): return false
		weapon.base_name=weapon.name;weapon.name=evolved_name(weapon);weapon.evolved=true;weapon.evolved_at=g.elapsed
		weapon.power=float(weapon.power)*float(shape.power)
		weapon.modifiers=merge(weapon.get("modifiers",{}),shape.mods)
		g.avatar.sync_equipment(g.equipped)
		if weapon.turret and is_instance_valid(weapon.get("node")) and weapon.node.has_meta("model"): weapon.node.get_meta("model").evolved=true
		g.career.bump("evolutions");g.achievement_event("EVOLVE")
		celebrate(g,weapon)
		return true
	return false

static func celebrate(g,weapon: Dictionary):
	var at: Vector3=g.player.position
	g.Hunt.announce(g,"WEAPON EVOLVED",str(weapon.base_name)+" → "+str(weapon.name),"evolve")
	CombatInk.beam(g,at+Vector3.UP*30,at+Vector3.UP*.2,GOLD,false,6.0)
	CombatInk.wave(g,at,7.0,GOLD)
	var star=CombatInk.star(g,at+Vector3.UP*1.4,4.5,GOLD,8.0,.7)
	if star!=null: star.shards(Color("fff2b8"),14,5.0);star.fall=-2.0;star.lamp(g,GOLD,4.0,12.0,Vector3.UP*2)
	g.hit_shake=maxf(g.hit_shake,.25)

# Evolved casts that are not projectiles (melee, horn, wells, meteors, spells)
# get a small gold flare where they land, so their look changes too.
static func flare(g,point: Vector3):
	var star=CombatInk.star(g,point+Vector3.UP*.6,1.6,GOLD,8.0,.3)
	if star!=null: star.shards(Color("fff2b8"),4,3.0)

extends RefCounted

# Every weapon with card and chest-item builds (user, November 5: "run all gun
# test with different cards and items combinations"). Same pinned dummies as the
# weapon review, rank 3, a short stand per build. A weapon is flagged when a build
# leaves it dealing no damage (a card that breaks it), when a doubled Damage stat
# hardly raises its damage, or when the hero's health or a total goes bad.
const WR=preload("res://scripts/weapon_review.gd")
const SECONDS=2.5
const RANK=3
# Card builds by role; "all" stacks every one of them.
const BUILDS={
	"damage":{"damage":30.0},
	"shots":{"multishot":3.0,"pierce":2.0,"ricochet":2.0,"boomerang":1.0},
	"reach":{"size":2.0,"range":27.0,"projectileSpeed":34.0,"duration":2.0},
	"status":{"burn":1.0,"poison":1.0,"freeze":.5,"slow":.3,"blind":.3,"stun":.3,"knockback":2.0},
	"crit":{"crit":.5,"critPower":3.0,"berserk":1.0,"execute":.1,"rate":3.3},
	"blast":{"splash":1.0,"explosion":1.0,"chain":2.0,"lifesteal":.1},
}
const ITEM_BUILDS=2
const ITEMS_PER_BUILD=12

# Real chest items, rolled once (fixed seed), turned into stat values.
static func item_builds(g) -> Array:
	var rng=RandomNumberGenerator.new();rng.seed=511
	var pool=g.rules.data.loot.filter(func(i):return i.kind=="item")
	var builds=[]
	for b in range(ITEM_BUILDS):
		var stats: Dictionary=g.rules.data.stats.duplicate(true);var names=[]
		for i in range(ITEMS_PER_BUILD):
			var item=pool[rng.randi_range(0,pool.size()-1)];names.append(str(item.id))
			g.rules.apply_effects(stats,item.effects)
		var changed={}
		for key in stats:
			if not is_equal_approx(float(stats[key]),float(g.rules.data.stats.get(key,0))): changed[key]=stats[key]
		builds.append({"name":"items-%d" % b,"stats":changed,"items":names})
	return builds

static func run(g: Node3D):
	AudioServer.set_bus_volume_db(0,-80)
	g.start_run(2026);g.set_process(false);g.set_physics_process(false)
	g.invulnerable=1e9;g.spawn_clock=1e9;g.formation_clock=1e9;g.xp_target=1e9;g.sound.settings.sfx=0;g.mode="playing"
	var builds=[]
	var all={}
	for name in BUILDS: builds.append({"name":name,"stats":BUILDS[name]});all.merge(BUILDS[name],true)
	builds.append({"name":"all","stats":all})
	var items=item_builds(g);builds.append_array(items)
	var rows={};var flagged=[];var measured=0
	for weapon in g.rules.data.weapons:
		# The Mender Turret heals instead of hurting (the weapon review measures it).
		if weapon.id=="heal-turret": continue
		# Let queued frees happen: the measurements run inside one frame, and dead
		# dummies left in the tree block new spawns after a few hundred rings.
		await g.get_tree().process_frame
		var base=WR.measure(g,weapon.id,RANK,{},SECONDS)
		var row={"base":base.dealt};var reasons=[]
		if base.dealt<=0: reasons.append("no damage without cards")
		for build in builds:
			var result=WR.measure(g,weapon.id,RANK,build.stats,SECONDS);measured+=1
			row[build.name]=result.dealt
			if not is_finite(result.dealt) or result.dealt<=0: reasons.append(build.name+": no damage")
			if int(result.dummies)<8: reasons.append(build.name+": only %d dummies" % result.dummies)
			if not is_finite(g.hp) or g.hp<=0: reasons.append(build.name+": hero health "+str(g.hp))
		# Statuses (burn, poison) tick a flat amount by design, so status-heavy weapons
		# gain less than 2x; below 1.2x the Damage stat is being ignored.
		if base.dealt>0 and float(row.damage)<base.dealt*1.2: reasons.append("doubled Damage gives only x%.2f" % (float(row.damage)/base.dealt))
		rows[weapon.id]=row
		if not reasons.is_empty(): flagged.append({"id":weapon.id,"reasons":reasons,"row":row})
	var checks={"weapons_measured":rows.size()==g.rules.data.weapons.size()-1,"builds_measured":measured==rows.size()*builds.size(),"combos_work":flagged.is_empty()}
	print("WEAPON_COMBOS "+JSON.stringify({"checks":checks,"flagged":flagged,"builds":builds.map(func(b):return {"name":b.name,"stats":b.stats,"items":b.get("items",[])}),"rows":rows}))
	g.get_tree().quit(0 if checks.values().all(func(v):return v) else 1)

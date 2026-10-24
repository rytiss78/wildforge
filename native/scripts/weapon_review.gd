extends RefCounted

# Every weapon through the real combat path at rank 1 and rank 5, against a ring
# of tough dummies: damage dealt, and the largest damage number shown for that
# weapon's slot. Flags weapons whose numbers stay near 1 or whose damage does not
# grow with rank (user report, October 24: "one weapon always shows 1 dmg even
# after leveling it up"). Also checks that every hero's own weapon is offered to
# other heroes.
# Six seconds: slow bomb weapons fire about twice and a 1.8 s fuse must still land.
const SECONDS=6.0

static func ring(g) -> Array:
	# Same seed for every measurement: rank 1 and rank 5 face the same dummies and
	# the same crit rolls, so a difference comes from the rank, not the layout.
	g.clear_entities();g.spawn_clock=1e9;g.rules.rng.seed=2026;seed(2026)
	var dummies=[]
	for i in range(8):
		# spawn_enemy can decline a spot (water, unsafe ground); retry farther out.
		var before=g.enemies.size()
		for attempt in range(12):
			g.spawn_enemy(6.0+attempt*2.0)
			if g.enemies.size()>before: break
		if g.enemies.size()==before: continue
		var enemy=g.enemies[-1]
		var p=g.player.position+Vector3.FORWARD.rotated(Vector3.UP,TAU*i/8.0)*(2.2+float(i%3)*1.6);p.y=g.world.height_at(p.x,p.z)
		enemy.node.position=p;enemy.speed=0.0;enemy.attack=1e9;enemy.contact=1e9;enemy.damage=0.0;enemy.hp=1e7;enemy.maxHp=1e7;enemy.behavior="chase";enemy.home=p;enemy.boss=false
		dummies.append(enemy)
	return dummies

static func measure(g,weapon_id: String,rank: int) -> Dictionary:
	var dummies=ring(g)
	for weapon in g.equipped:
		if is_instance_valid(weapon.get("node")): weapon.node.queue_free()
	g.equipped.clear();g.skills.clear();g.damage_numbers.clear()
	g.stats=g.rules.data.stats.duplicate(true);g.stats.maxHp=1e6;g.hp=1e6
	var item=g.rules.data.weapons.filter(func(w):return w.id==weapon_id)[0].duplicate(true);item.kind="weapon";item.strength=1.0
	for i in range(rank): g.equip_weapon(item)
	# Flowers grow along the hero's path; the hero stands still here, so plant a bed
	# under the dummies instead.
	if weapon_id=="flowers":
		for enemy in dummies: g.plant_flower(enemy.home,g.equipped[0])
	var shown=0.0;var t=0.0
	while t<SECONDS:
		t+=1.0/60.0;g.elapsed+=1.0/60.0;g.realm_time=0.0
		# Only the dummies: wardens spawn as game time passes, and bosses win
		# targeting outright, which would pull long-range weapons off the ring.
		for enemy in g.enemies.filter(func(e):return not dummies.has(e) and not e.dead): enemy.dead=true;enemy.node.queue_free()
		g.enemies=g.enemies.filter(func(e):return dummies.has(e))
		# Dummies stand still: knockback and gravity pulls would otherwise push them
		# out of range for good, since they never walk back.
		for enemy in dummies: enemy.node.position=enemy.home
		g.update_combat(1.0/60.0)
		for entry in g.damage_numbers:
			if str(entry.get("weapon_id",""))==weapon_id: shown=maxf(shown,float(entry.amount))
	var dealt=0.0
	for enemy in dummies: dealt+=1e7-enemy.hp
	return {"dealt":snappedf(dealt,.1),"shown":snappedf(shown,.1)}

static func run(g: Node3D):
	AudioServer.set_bus_volume_db(0,-80)
	g.start_run(2026);g.set_process(false);g.set_physics_process(false)
	g.invulnerable=1e9;g.spawn_clock=1e9;g.formation_clock=1e9;g.xp_target=1e9;g.sound.settings.sfx=0;g.mode="playing"
	var rows={};var flagged=[]
	for weapon in g.rules.data.weapons:
		var low=measure(g,weapon.id,1);var high=measure(g,weapon.id,5)
		# Area weapons vary run to run (where the well lands, how many dummies it
		# catches): a weak result is measured again and both samples are summed.
		if high.dealt<=low.dealt*1.1:
			var low2=measure(g,weapon.id,1);var high2=measure(g,weapon.id,5)
			low={"dealt":low.dealt+low2.dealt,"shown":maxf(low.shown,low2.shown)};high={"dealt":high.dealt+high2.dealt,"shown":maxf(high.shown,high2.shown)}
		rows[weapon.id]={"r1":low,"r5":high}
		var reasons=[]
		if high.dealt<=low.dealt*1.1: reasons.append("no growth with rank")
		if high.shown>0 and high.shown<2.0: reasons.append("shown number near 1")
		if high.dealt<=0: reasons.append("no damage")
		if high.dealt>0 and high.shown<=0: reasons.append("no number at its slot")
		if not reasons.is_empty(): flagged.append({"id":weapon.id,"reasons":reasons,"r1":low,"r5":high})
	# Every hero's own weapon is offered to the other heroes: weapon offers come from
	# the full pool, never from the hero's starting weapon only.
	var offered={}
	for i in range(4000): offered[g.rules.roll("weapon").id]=true
	var hero_weapons=g.rules.data.heroes.map(func(h):return str(h.weapon))
	# The first weapon offer of a run (level 2) over many runs: how many different
	# weapons appear, and how often the commonest one does (user report, October 24:
	# "all runs become with same weapons").
	var early={};var early_cards=0
	for run_seed in range(1,81):
		g.start_run(run_seed);g.set_process(false);g.set_physics_process(false);g.mode="playing";g.level_choice_cooldown=0
		g.xp=g.xp_target;g.level_up()
		for item in g.offers:
			if item.kind=="weapon": early[item.id]=int(early.get(item.id,0))+1;early_cards+=1
	var early_top=early.keys().map(func(id):return [early[id],id]);early_top.sort();early_top.reverse()
	# Weapons from recent runs never show in the first offer while others remain.
	var recent=["marble-rain","pumpkin-fuse","button-barrage","teacup-singularity","shotgun","ninja-shuriken","bomb","flame"]
	g.career.data.recentWeapons=recent.duplicate();var recent_shown=0
	for run_seed in range(101,141):
		g.start_run(run_seed);g.set_process(false);g.set_physics_process(false);g.mode="playing";g.level_choice_cooldown=0
		g.xp=g.xp_target;g.level_up()
		recent_shown+=g.offers.filter(func(item):return recent.has(item.id) and not g.equipped.any(func(w):return w.id==item.id)).size()
	g.career.data.recentWeapons=[]
	# A shared co-op weapon level with a full loadout keeps all five cards.
	g.start_run(7);g.set_process(false);g.set_physics_process(false);g.equipped.clear()
	for id in ["gun","rocket","disc"]:
		var item=g.rules.data.weapons.filter(func(w):return w.id==id)[0].duplicate(true);item.kind="weapon";item.strength=1.0;g.equip_weapon(item)
	g.open_shared_offer(g.rules.offers("weapon",0,false,g.stats,g.equipped),"weapon",false,"level","review:full")
	var full_cards=g.offers.size();g.hud.close();g.mode="playing"
	print("EARLY_OFFERS "+JSON.stringify({"cards":early_cards,"distinct":early.size(),"top":early_top.slice(0,8),"recent_shown":recent_shown,"full_loadout_cards":full_cards}))
	var checks={"dummies":ring(g).size()==8,"hero_weapons_offered":hero_weapons.all(func(id):return offered.has(id)),"weapons_measured":rows.size()==g.rules.data.weapons.size(),"weapons_scale":flagged.is_empty(),"early_diverse":early.size()>=50 and int(early_top[0][0])<=early_cards/10,"recent_sit_out":recent_shown==0,"full_loadout_cards":full_cards==5}
	print("WEAPON_REVIEW "+JSON.stringify({"checks":checks,"flagged":flagged,"rows":rows}))
	g.get_tree().quit(0 if not checks.values().has(false) else 1)

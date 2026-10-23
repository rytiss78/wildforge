extends RefCounted

# Full-run playtest bot. It plays the real game headless and faster than real
# time: the same movement inputs, dash, interact and offer choices a player
# uses, on the game's own physics and combat code. It kites crowds and attack
# warnings, collects XP and gold, opens affordable chests, follows the portal
# objective through all three realms and fights the Baron. A "competent but
# not perfect" player: it reacts every 0.1 s and dashes only when cornered.
#
# Arguments: --bot-hero=<id> --bot-seed=<n> --bot-style=balanced|offense|defense
#            --bot-minutes=<cap on simulated minutes>
const STEP=1.0/30.0
const THINK=.1
const OFFENSE=["damage","rate","size","multishot","crit","critPower","projectileSpeed","pierce","chain","splash","burn","poison"]
const DEFENSE=["maxHp","armor","regen","lifesteal","shield","dodge","speed"]

static func arg(name: String,default: String) -> String:
	for value in OS.get_cmdline_user_args():
		if value.begins_with("--"+name+"="): return value.trim_prefix("--"+name+"=")
	return default

static func run(g):
	AudioServer.set_bus_volume_db(0,-80);g.sound.settings.sfx=0
	var hero_id=arg("bot-hero","duck");var seed_value=int(arg("bot-seed","1"));var style=arg("bot-style","balanced")
	var cap=float(arg("bot-minutes","45"))*60.0
	var heroes=g.rules.data.heroes.filter(func(h):return h.id==hero_id)
	if heroes.is_empty(): print("RUN_BOT {\"error\":\"unknown hero\"}");g.get_tree().quit(1);return
	g.select_hero(heroes[0]);g.start_run(seed_value)
	g.set_process(false);g.set_physics_process(false)
	var report={"hero":hero_id,"seed":seed_value,"style":style,"realms":[],"baron_defeated":false,"died":false}
	var realm_entry={"realm":g.realm,"entered":0.0,"level":g.level}
	var think=0.0;var goal=Vector3.INF;var wish=Vector3.ZERO;var stuck_from=g.player.position;var stuck_clock=0.0;var wander=Vector3.ZERO
	var started=Time.get_ticks_msec();var steps=0;var last_realm=g.realm;var hits_taken=0.0;var hp_before=g.hp
	var timeline=[];var next_sample=0.0;var last_hit={};var hits=[]
	var shots=Array(arg("bot-shots","").split("-",false));var last_shot=-1
	var trail=[]
	while g.elapsed<cap:
		steps+=1
		if steps%20==0: await g.get_tree().process_frame
		if not g.run_active or g.run_recorded:
			report.died=true;report.death=last_hit;break
		# --bot-shots=a-b saves one rendered frame per second between a and b seconds.
		if not shots.is_empty() and g.elapsed>=float(shots[0]) and g.elapsed<=float(shots[1]) and int(g.elapsed)!=last_shot:
			last_shot=int(g.elapsed);await RenderingServer.frame_post_draw
			g.get_viewport().get_texture().get_image().save_png("user://bot-%03d.png" % last_shot)
		if g.elapsed>=next_sample:
			next_sample=g.elapsed+10.0
			var near=g.enemies.filter(func(e):return not e.dead and g.player.position.distance_to(e.node.position)<8).size()
			timeline.append([roundi(g.elapsed),g.realm,roundi(g.hp),roundi(g.stats.maxHp),g.level,near,g.enemies.size(),roundi(Vector2(g.player.position.x,g.player.position.z).length())])
		match g.mode:
			"offer": g.choose_offer(pick(g,style))
			"replace": g.mode="offer";g.skip_offer()
			"reveal": g.finish_reveal()
			"merchant","career","build","settings","paused": g.hud.close()
		if g.realm!=last_realm:
			realm_entry.left=g.elapsed;realm_entry.level_out=g.level;report.realms.append(realm_entry)
			realm_entry={"realm":g.realm,"entered":g.elapsed,"level":g.level};last_realm=g.realm
		if g.events.get("final_defeated",false) and not report.baron_defeated:
			report.baron_defeated=true;report.baron_time=g.elapsed
		think-=STEP
		if think<=0 and g.mode=="playing":
			think=THINK
			goal=objective(g)
			wish=steer(g,goal,wander)
			# Unstick: barely moved for 4 s while trying to → wander for a moment.
			stuck_clock+=THINK
			if stuck_clock>=4:
				if g.player.position.distance_to(stuck_from)<2 and wish.length()>.5: wander=Vector3.RIGHT.rotated(Vector3.UP,randf()*TAU)*1.5
				else: wander=Vector3.ZERO
				stuck_from=g.player.position;stuck_clock=0
			if goal!=Vector3.INF and g.player.position.distance_to(goal)<3.2: g.interact()
			if cornered(g) and g.dash_cooldown<=0: g.dash()
			tend_turrets(g)
		drive(g,wish)
		g._physics_process(STEP);g._process(STEP)
		trail.append(g.player.position);if trail.size()>10: trail.pop_front()
		if g.hp<hp_before:
			hits_taken+=hp_before-g.hp
			var source: Vector3=g.damage_feedback_source
			var near=g.enemies.filter(func(e):return not e.dead and e.node.position.distance_to(g.player.position)<4)
			var nearest={};var nd=999.0
			for e in g.enemies:
				if not e.dead and e.node.position.distance_to(g.player.position)<nd: nd=e.node.position.distance_to(g.player.position);nearest=e
			var hz={};var hd=999.0
			for h in g.hazards:
				if is_instance_valid(h.get("node")) and not h.get("friendly",false) and Vector2(h.node.position.x-g.player.position.x,h.node.position.z-g.player.position.z).length()<hd: hd=Vector2(h.node.position.x-g.player.position.x,h.node.position.z-g.player.position.z).length();hz=h
			hits.append({"t":snappedf(g.elapsed,.1),"dmg":roundi(hp_before-g.hp),"hp":roundi(g.hp),"enemy":[snappedf(nd,.1),str(nearest.get("behavior","")),bool(nearest.get("boss",false))],"hazard":[snappedf(hd,.1),str(hz.get("style","")),snappedf(float(hz.get("radius",0)),.1),snappedf(float(hz.get("life",0)),.01)],"speed":snappedf(Vector2(g.player.position.x-trail[0].x,g.player.position.z-trail[0].z).length()/(trail.size()*STEP),.1) if not trail.is_empty() else 0.0,"wish":[snappedf(wish.x,.1),snappedf(wish.z,.1)],"dash":snappedf(g.dash_cooldown,.1),"blockers":blockers(g),"floor":g.player.is_on_floor()})
			if hits.size()>12: hits.pop_front()
			last_hit={"t":snappedf(g.elapsed,.1),"amount":roundi(hp_before-g.hp),"hp":roundi(g.hp),"near":near.size(),"boss_near":near.any(func(e):return e.boss),"hazards":g.hazards.filter(func(h):return not h.get("friendly",false)).size(),"radius":roundi(Vector2(g.player.position.x,g.player.position.z).length()),"edge":roundi(RealmWorld.coast_radius(atan2(g.player.position.z,g.player.position.x),g.seed_value,g.realm)),"from":roundi(source.distance_to(g.player.position)) if source!=Vector3.ZERO else -1}
		hp_before=g.hp
	release_inputs()
	realm_entry.left=g.elapsed;realm_entry.level_out=g.level;report.realms.append(realm_entry)
	report.minutes=snappedf(g.elapsed/60.0,.01);report.level=g.level;report.kills=g.kills;report.reached_realm=g.realm
	report.damage_taken=roundi(hits_taken);report.wall_seconds=snappedf((Time.get_ticks_msec()-started)/1000.0,.1)
	report.weapons=g.equipped.map(func(w):return str(w.id)+":"+str(w.rank));report.mutations=g.mutations.size()
	report.capped=g.elapsed>=cap;report.timeline=timeline;report.last_hits=hits
	print("RUN_BOT "+JSON.stringify(report))
	g.get_tree().quit(0)

# Where to go: the portal when it wants the hero, else a close safe pickup or an
# affordable chest; Vector3.INF means "just survive".
static func objective(g) -> Vector3:
	if g.realm<3:
		var state=g.Journey.state(g)
		if state in ["ready","cleared"]: return g.gate_position
	var best=Vector3.INF;var best_d=16.0
	for pickup in g.pickups:
		if not is_instance_valid(pickup.get("node")): continue
		var d=g.player.position.distance_to(pickup.node.position)
		if d<best_d: best=pickup.node.position;best_d=d
	if best!=Vector3.INF: return best
	var price=g.rules.chest_price(g.paid_chests,g.stat("discount"))
	if g.gold>=price:
		var chest_d=45.0
		for chest in g.chests:
			if chest.opened or not is_instance_valid(chest.get("node")): continue
			var d=g.player.position.distance_to(chest.node.position)
			if d<chest_d: best=chest.node.position;chest_d=d
	return best

# Flee nearby enemies (bosses harder) and attack warnings (harder the sooner
# they land), pulled toward the goal, back from the island or arena edge, and
# toward the middle when idle far out.
static func steer(g,goal: Vector3,wander: Vector3) -> Vector3:
	var p: Vector3=g.player.position;var push=Vector3.ZERO;var danger=0.0
	for enemy in g.enemies:
		if enemy.dead: continue
		var away: Vector3=(p-enemy.node.position)*Vector3(1,0,1);var d=away.length()
		var reach=9.0 if enemy.boss else 6.0
		if d<reach and d>.01:
			var weight=(reach-d)/reach*(3.0 if enemy.boss else 1.0)
			push+=away/d*weight;danger+=weight
	var urgent=false
	for hazard in g.hazards:
		if hazard.get("friendly",false) or not is_instance_valid(hazard.get("node")): continue
		var away: Vector3=(p-hazard.node.position)*Vector3(1,0,1);var d=away.length()
		var r=float(hazard.get("radius",2))+1.5
		if d<r:
			var soon=1.5-clampf(float(hazard.life),0,1.5)
			push+=(away/d if d>.05 else Vector3.RIGHT.rotated(Vector3.UP,float(hazard.node.position.x)))*(5.0+4.0*soon)*(r-d)/r;danger+=4
			urgent=urgent or (d<r-1.2 and float(hazard.life)<.6)
	g.set_meta("bot_trapped",urgent)
	var toward=Vector3.ZERO
	var edge=RealmWorld.coast_radius(atan2(p.z,p.x),g.seed_value,g.realm)
	var from_centre=Vector2(p.x,p.z).length()
	if goal!=Vector3.INF: toward=((goal-p)*Vector3(1,0,1)).normalized()*(1.5 if danger<2 else .6)
	elif danger<.2 and from_centre>edge*.5: toward=-Vector3(p.x,0,p.z).normalized()*.4
	var inward=Vector3.ZERO
	var margin=minf(18.0,edge*.2)
	if from_centre>edge-margin*1.6: inward=-Vector3(p.x,0,p.z).normalized()*(2.0+4.0*clampf((from_centre-(edge-margin*1.6))/margin,0,1))
	return push.normalized()*minf(1.0,danger)*1.6+toward+inward+wander

# What the hero's last move slid against: "enemy", "world" or a node class.
static func blockers(g) -> Array:
	var found=[]
	for i in range(g.player.get_slide_collision_count()):
		var other=g.player.get_slide_collision(i).get_collider()
		var kind="world" if other is StaticBody3D else "enemy" if other is CharacterBody3D and int(other.collision_layer)==4 else str(other.get_class()) if other!=null else "none"
		if not kind in found: found.append(kind)
	return found

static func cornered(g) -> bool:
	if g.get_meta("bot_trapped",false): return true
	var close=0
	for enemy in g.enemies:
		if not enemy.dead and g.player.position.distance_to(enemy.node.position)<(3.5 if enemy.boss else 2.2): close+=1
	return close>=3

# Turret heroes keep their turret near the fight.
static func tend_turrets(g):
	for weapon in g.equipped:
		if weapon.turret and weapon.deploy_clock<=0 and (not is_instance_valid(weapon.get("node")) or weapon.node.position.distance_to(g.player.position)>12): g.deploy_turret(weapon)

static func drive(g,wish: Vector3):
	g.yaw=0.0
	var d=Vector2(wish.x,wish.z).limit_length(1.0)
	for pair in [["move_right",d.x],["move_left",-d.x],["move_back",d.y],["move_forward",-d.y]]:
		if pair[1]>.05: Input.action_press(pair[0],pair[1])
		else: Input.action_release(pair[0])

static func release_inputs():
	for action in ["move_right","move_left","move_back","move_forward"]: Input.action_release(action)

# Offer choice by build style. Weapons fill empty slots; useless cards are avoided.
static func pick(g,style: String) -> int:
	var best=0;var best_score=-99.0
	for i in range(g.offers.size()):
		var item=g.offers[i];var score=float(item.get("tier",0))*.5
		if item.kind=="weapon":
			var owned=g.equipped.any(func(w):return w.id==item.id)
			# A full loadout never swaps weapons (that needs the replace screen).
			score+=4.0 if owned else (3.5 if g.equipped.size()<RunRules.WEAPON_CAP else -9.0)
		elif item.kind=="mutation": score+=2.6
		else:
			var key=str(item.effects[0].key)
			if g.rules.data.augments.has(key): key=str(g.rules.data.augments[key].stat)
			var offense={"offense":3.0,"defense":1.5,"balanced":2.5}[style];var defense={"offense":1.0,"defense":3.0,"balanced":2.2}[style]
			score+=offense if key in OFFENSE else defense if key in DEFENSE else 1.0
			# Keep some survivability: defence gains value when health lags behind level.
			if key in DEFENSE: score+=clampf((100.0+g.level*5.0-float(g.stats.maxHp))/60.0,0,1.5)
			if not UpgradeFit.describe(g,item).get("useful",true): score-=3.0
		if score>best_score: best=i;best_score=score
	return best


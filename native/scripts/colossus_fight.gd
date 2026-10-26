extends RefCounted
class_name ColossusFight

# The final boss fight (user request, October 24; since October 26 the boss is The
# Grand Noggin, a giant floating head, ColossusRig): a huge monster in the Dark
# Souls manner. It walks the hero down and commits to heavy, readable blows: every
# attack has a body wind-up and red ground marks timed to the impact, and heavy
# blows leave it open (OPEN_DAMAGE) while its core flares.
#   I   100-65%  sweep, overhead slam, stomp, lunge
#   II  65-30%   adds leap slam, fire breath, tail spin; lava vents in the arena
#   III below 30% faster wind-ups, chained combos, meteor rain
# Phase changes roar, blast a shockwave and ignite the body. The host decides;
# guests replay the same actions from "colossus_action" messages.

const NAME="THE GRAND NOGGIN"
const PHASES=["I · THE NOGGIN DESCENDS","II · THE NOGGIN BOILS","III · THE LAST TANTRUM"]
const THRESHOLDS=[.65,.30]
const OPEN_DAMAGE=1.35
const SPEED=[1.0,.88,.75]
const REST=[1.1,.8,.5]
# Every blow, vent and meteor hits this much harder (October 24, user request):
# the fight is paid for with health potions, POTIONS of them every POTION_SECONDS.
const DEADLY=2.5
const POTIONS=3
const POTION_SECONDS=60.0
const POTION_HEAL=.4
# The Noggin's performance (user request, October 26): about once a minute it stops
# attacking and demands a show. A 3x3 grid of marks falls round every player on
# each beat, one outer square left safe (shown in the gold of safe areas); the next wave follows the
# player. If nobody is hit, its eyes crack and it takes PERFORM_BONUS damage for
# PERFORM_OPEN seconds; if anyone is hit, it heals PERFORM_HEAL of its health.
const PERFORM_FIRST=35.0
const PERFORM_EVERY=60.0
const PERFORM_WAVES=7
const PERFORM_BEAT=1.3
const PERFORM_WARN=1.2
const PERFORM_CELL=4.2
const PERFORM_DAMAGE=40.0
const PERFORM_BONUS=2.0
const PERFORM_OPEN=8.0
const PERFORM_HEAL=.04

static func phase(enemy: Dictionary) -> int:
	return int(enemy.get("colossus_phase",0))

static func rig(enemy: Dictionary):
	return enemy.node.get_meta("rig") if is_instance_valid(enemy.get("node")) and enemy.node.has_meta("rig") else null

static func is_open(g,enemy: Dictionary) -> bool:
	return g.realm_time>=float(enemy.get("open_from",-1)) and g.realm_time<float(enemy.get("open_until",-1))

static func damage_scale(g,enemy: Dictionary) -> float:
	if g.realm_time<float(enemy.get("perform_bonus_until",-1)): return PERFORM_BONUS
	return OPEN_DAMAGE if is_open(g,enemy) else 1.0

# Host: the attack clock ran out; pick the next blow for the target's distance.
static func attack(g,enemy: Dictionary):
	var origin: Vector3=enemy.node.position;var info=g.coop.target(origin);var target: Vector3=info.position
	if g.coop.active:
		var target_id=int(info.id);var target_name=g.coop.player_name_for(target_id)
		g.coop.set_boss_focus(target_id,target_name)
		if g.coop.hosting: g.coop.broadcast({"type":"boss_focus","realm":g.realm,"player_id":target_id,"name":target_name})
	var queue: Array=enemy.get("colossus_queue",[])
	var action=str(queue.pop_front()) if not queue.is_empty() else choose(g,enemy,(target-origin).length())
	start(g,enemy,action,target)

static func choose(g,enemy: Dictionary,distance: float) -> String:
	var p=phase(enemy);var pool=[]
	if distance<15: pool=["sweep","stomp","slam"]+(["tail"] if p>=1 else [])
	elif distance<30: pool=["slam","lunge"]+(["breath","leap"] if p>=1 else [])
	else: pool=["lunge","lunge"]+(["leap","leap"] if p>=1 else [])
	var fresh=pool.filter(func(a):return a!=str(enemy.get("last_action","")))
	if not fresh.is_empty(): pool=fresh
	return str(pool[g.rules.rng.randi_range(0,pool.size()-1)])

static func start(g,enemy: Dictionary,action: String,target: Vector3):
	var p=phase(enemy);var k=SPEED[p]
	var origin: Vector3=enemy.node.position
	var toward=(target-origin)*Vector3(1,0,1);var distance=toward.length()
	var forward=toward.normalized() if distance>.1 else -enemy.node.global_basis.z
	# It turns to the target as the wind-up starts, then commits: no tracking mid-swing.
	enemy.node.rotation.y=atan2(-forward.x,-forward.z)
	var marks=[];var windup=1.0;var active=.3;var recover=1.0;var open=false;var damage=90.0;var style="annihilation"
	var destination=origin;var arc=0.0
	match action:
		"sweep":
			windup=1.3*k;active=.35;recover=1.0;damage=90
			# Right arm across: the marks light up from its right to its left.
			for i in range(9):
				for r in [7.0,11.0,15.0]: marks.append([origin+forward.rotated(Vector3.UP,(4-i)*.2)*r,2.6,windup+.05+i*.03])
		"slam":
			windup=1.6*k;active=.25;recover=1.8;open=true;damage=130
			var at=origin+forward*clampf(distance,8,18)
			marks.append([at,6.5,windup+.2])
			for i in range(10): marks.append([at+Vector3.RIGHT.rotated(Vector3.UP,i*TAU/10)*10.5,2.4,windup+.6,60.0])
		"stomp":
			windup=1.0*k;active=.2;recover=1.0;damage=75
			marks.append([origin,5.0,windup+.15])
			for i in range(12): marks.append([origin+Vector3.RIGHT.rotated(Vector3.UP,i*TAU/12)*7.5,3.0,windup+.25])
		"lunge":
			windup=1.2*k;active=.6;recover=1.6;open=true;damage=110
			var travel=clampf(distance+4,10,30)
			destination=origin+forward*travel
			for i in range(6): marks.append([origin+forward*(4+i*travel/5.0),4.2,windup+.1+i*.1])
		"leap":
			windup=1.5*k;active=1.1;recover=2.0;open=true;damage=140;arc=11.0
			destination=target
			marks.append([target,8.0,windup+active])
			for i in range(14): marks.append([target+Vector3.RIGHT.rotated(Vector3.UP,i*TAU/14)*14,2.6,windup+active+.45,60.0])
		"breath":
			windup=1.1*k;active=1.4;recover=1.2;damage=55;style="lava"
			for wave in range(6):
				for i in range(-2,3): marks.append([origin+forward.rotated(Vector3.UP,i*.15*(1+wave*.1))*(8+wave*5),2.6+wave*.25,windup+wave*.2])
		"tail":
			windup=1.0*k;active=.6;recover=1.0;damage=85
			for i in range(16): marks.append([origin+Vector3.RIGHT.rotated(Vector3.UP,i*TAU/16)*12,3.2,windup+.1+i*.03])
	destination=on_arena(g,destination)
	for mark in marks: hazard(g,mark[0],mark[1],mark[2],float(mark[3]) if mark.size()>3 else damage,style)
	enemy.recovery=g.realm_time+windup+active+recover
	enemy.attack=windup+active+recover+REST[p]
	enemy.last_action=action
	if open: enemy.open_from=g.realm_time+windup+active;enemy.open_until=g.realm_time+windup+active+recover
	if destination!=origin: enemy.colossus_move={"from":origin,"to":destination,"start":g.realm_time+windup,"duration":active,"arc":arc}
	# Phase III chains a second blow onto some attacks.
	if p==2 and not enemy.get("chained",false) and g.rules.rng.randf()<.4:
		enemy.chained=true;enemy.attack=windup+active+.35
		enemy.colossus_queue=[choose(g,enemy,(destination-target).length())]
	else: enemy.chained=false
	var body=rig(enemy)
	if body!=null: body.play(action,windup,active,recover,open)
	if g.coop.active and g.coop.hosting: g.coop.broadcast({"type":"colossus_action","realm":g.realm,"action":action,"windup":windup,"active":active,"recover":recover,"open":open,"turn":enemy.node.rotation.y})

static func hazard(g,at: Vector3,radius: float,delay: float,damage: float,style: String):
	at=on_arena(g,at);damage*=DEADLY
	g.warn_at(at,radius,delay,damage,style)
	if g.coop.active: g.coop.broadcast({"type":"hazard","realm":g.realm,"position":CoopSession.array(at),"radius":radius,"delay":delay,"damage":damage,"style":style})

# Each player's game shakes POTIONS health potions out of the living Colossus
# every POTION_SECONDS, scattered round it, so healing means closing in.
static func potions(g,enemy: Dictionary):
	if enemy.dead or g.events.get("final_intro",false): return
	if not enemy.has("next_potions"): enemy.next_potions=g.realm_time+POTION_SECONDS;return
	if g.realm_time<float(enemy.next_potions): return
	enemy.next_potions=g.realm_time+POTION_SECONDS
	var turn=g.rules.rng.randf()*TAU
	for i in range(POTIONS):
		var at=enemy.node.position+Vector3.RIGHT.rotated(Vector3.UP,turn+i*TAU/POTIONS)*g.rules.rng.randf_range(9.0,14.0)
		g.drop_consumable(on_arena(g,at),true,"health")
	g.hud.tell("THE NOGGIN SHEDS HEALTH POTIONS",3)

# Keep impacts and landings on the playable ground of the arena.
static func on_arena(g,at: Vector3) -> Vector3:
	var flat=Vector2(at.x,at.z)
	if flat.length()>60: flat=flat.normalized()*60
	return Vector3(flat.x,g.world.height_at(flat.x,flat.y),flat.y)

# Host, every frame: lunges and leaps move the body; later phases add arena hazards.
static func tick(g,enemy: Dictionary):
	var move: Dictionary=enemy.get("colossus_move",{})
	if not move.is_empty() and g.realm_time>=float(move.start):
		var f=clampf((g.realm_time-float(move.start))/maxf(.05,float(move.duration)),0,1)
		var at: Vector3=move.from.lerp(move.to,f)
		at.y=g.world.height_at(at.x,at.z)+float(move.arc)*4.0*f*(1.0-f)
		enemy.node.position=at
		if f>=1:
			enemy.erase("colossus_move");g.hit_shake=maxf(g.hit_shake,.6)
	perform_tick(g,enemy)
	# No vents or meteors during a performance: the dodge pattern is the whole test.
	if enemy.has("performing"): return
	var p=phase(enemy)
	if p>=1 and g.realm_time>=float(enemy.get("next_vents",g.realm_time+6)):
		enemy.next_vents=g.realm_time+15.0
		g.hud.tell("LAVA VENTS · MOVE BETWEEN THE RED MARKS",2.5)
		for i in range(9):
			var angle=TAU*float(i)/9.0+g.realm_time*.13;var radius=14.0+(i%3)*12.0
			hazard(g,Vector3(cos(angle)*radius,0,sin(angle)*radius),3.0,2.4,50,"lava")
	if p>=2 and g.realm_time>=float(enemy.get("next_meteors",g.realm_time+4)):
		enemy.next_meteors=g.realm_time+9.0
		for hero in heroes(g):
			for i in range(5):
				var offset=Vector3.RIGHT.rotated(Vector3.UP,g.rules.rng.randf()*TAU)*g.rules.rng.randf_range(0,9)
				hazard(g,hero+offset,2.8,1.6+i*.2,70,"meteor")

# Host, every frame: start the performance when it is due, drop its waves on the
# beat, and judge it when the last wave has gone off.
static func perform_tick(g,enemy: Dictionary):
	if enemy.dead: return
	if not enemy.has("next_perform"): enemy.next_perform=g.realm_time+PERFORM_FIRST;return
	var show: Dictionary=enemy.get("performing",{})
	if show.is_empty():
		if g.realm_time>=float(enemy.next_perform) and not enemy.has("colossus_move") and g.realm_time>=float(enemy.get("recovery",0)): start_perform(g,enemy)
		return
	if int(show.waves_left)>0 and g.realm_time>=float(show.next_wave):
		show.waves_left=int(show.waves_left)-1;show.next_wave=float(show.next_wave)+PERFORM_BEAT
		for hero in heroes(g): perform_wave(g,hero)
	if g.realm_time>=float(show.end): finish_perform(g,enemy)

static func start_perform(g,enemy: Dictionary):
	var length=PERFORM_WAVES*PERFORM_BEAT+PERFORM_WARN
	enemy.performing={"waves_left":PERFORM_WAVES,"next_wave":g.realm_time+1.0,"end":g.realm_time+1.0+length,"failed":false}
	enemy.colossus_queue=[];enemy.attack=length+3.0;enemy.recovery=g.realm_time+length+1.0;enemy.open_until=-1
	var body=rig(enemy)
	if body!=null: body.play("perform",.6,length,.6)
	if g.coop.active and g.coop.hosting: g.coop.broadcast({"type":"colossus_action","realm":g.realm,"action":"perform","windup":.6,"active":length,"recover":.6,"open":false,"turn":enemy.node.rotation.y})
	broadcast_perform(g,"start")

# One beat: a 3x3 grid of marks round a hero, one outer square left safe.
static func perform_wave(g,hero: Vector3):
	var cells=[]
	for dx in [-1,0,1]:
		for dz in [-1,0,1]: cells.append(Vector2(dx,dz))
	var safe=cells[[0,1,2,3,5,6,7,8][g.rules.rng.randi_range(0,7)]]
	for cell in cells:
		var at=hero+Vector3(cell.x,0,cell.y)*PERFORM_CELL
		if cell==safe:
			g.warn_at(on_arena(g,at),PERFORM_CELL*.45,PERFORM_WARN,0.0,"ally",true)
			continue
		hazard(g,at,PERFORM_CELL*.55,PERFORM_WARN,PERFORM_DAMAGE,"annihilation")
		g.hazards[-1].perform=true

# Host: a performance mark hit a player.
static func perform_hit(g):
	for enemy in g.enemies:
		if enemy.get("boss_id",-1)==8 and enemy.has("performing"): enemy.performing.failed=true

static func finish_perform(g,enemy: Dictionary):
	var failed=bool(enemy.performing.failed);enemy.erase("performing")
	enemy.next_perform=g.realm_time+PERFORM_EVERY;enemy.attack=2.0
	if failed:
		enemy.hp=minf(enemy.maxHp,enemy.hp+enemy.maxHp*PERFORM_HEAL)
	else:
		enemy.perform_bonus_until=g.realm_time+PERFORM_OPEN
		enemy.open_from=g.realm_time;enemy.open_until=g.realm_time+PERFORM_OPEN
		enemy.attack=PERFORM_OPEN*.6
	broadcast_perform(g,"fail" if failed else "success")

static func broadcast_perform(g,stage: String):
	show_perform(g,stage)
	if g.coop.active and g.coop.hosting: g.coop.broadcast({"type":"noggin_perform","realm":g.realm,"stage":stage})

# Every machine: the call, the verdict, and the cracked eyes on a success.
static func show_perform(g,stage: String):
	match stage:
		"start": g.Journey.announce(g,"THE NOGGIN DEMANDS A PERFORMANCE","Dodge every mark · stand on the gold square")
		"success": g.Journey.announce(g,"BRAVO!","Its eyes crack · hit them now for double damage")
		"fail": g.Journey.announce(g,"BOO!","The Noggin is disappointed and heals")
	speak(g,{"start":"sing","success":"bravo","fail":"boo"}.get(stage,""))
	if stage=="success":
		for enemy in g.enemies:
			if enemy.get("boss_id",-1)==8 and not enemy.dead:
				var body=rig(enemy)
				if body!=null: body.crack(PERFORM_OPEN)

static func heroes(g) -> Array:
	var result=[g.player.position]
	if g.coop.active and g.coop.hosting:
		for member in g.coop.members.values():
			if member.has("position") and float(member.get("hp",0))>0: result.append(CoopSession.vector(member.position))
	return result

# Host: after a hit, cross into the next phase when health falls past a threshold.
static func on_hurt(g,enemy: Dictionary):
	var fraction=clampf(enemy.hp/maxf(1,enemy.maxHp),0,1)
	var wanted=2 if fraction<THRESHOLDS[1] else 1 if fraction<THRESHOLDS[0] else 0
	if wanted>phase(enemy): transition(g,enemy,wanted)

static func transition(g,enemy: Dictionary,next: int):
	enemy.colossus_phase=next;enemy.colossus_queue=[];enemy.erase("colossus_move")
	enemy.recovery=g.realm_time+3.2;enemy.attack=3.6;enemy.open_until=-1
	enemy.next_vents=g.realm_time+6.0;enemy.next_meteors=g.realm_time+5.0
	# The roar blasts a shockwave out from its feet: get clear or be thrown.
	var origin: Vector3=enemy.node.position
	for ring in [9.0,16.0]:
		for i in range(14): hazard(g,origin+Vector3.RIGHT.rotated(Vector3.UP,i*TAU/14+ring)*ring,3.0,1.2+ring*.03,45,"annihilation")
	show_phase(g,next)
	var body=rig(enemy)
	if body!=null: body.play("roar",.9,1.4,.9)
	preload("res://scripts/final_arena.gd").phase_changed(g,enemy,next)

# Every machine: the body ignites and the title comes up.
static func show_phase(g,next: int):
	for enemy in g.enemies:
		if enemy.get("boss_id",-1)==8 and not enemy.dead:
			var body=rig(enemy)
			if body!=null: body.set_phase(next)
	g.hit_shake=maxf(g.hit_shake,1.0)
	if next>0: g.Journey.announce(g,NAME,PHASES[clampi(next,0,2)]);speak(g,"roar")

# Every machine: one of the Noggin's booming lines (CreatureVoice), from its head.
static func speak(g,cue: String):
	if cue.is_empty(): return
	for enemy in g.enemies:
		if enemy.get("boss_id",-1)==8 and not enemy.dead:
			CreatureVoice.noggin(g,cue,enemy.node.position+Vector3.UP*4.2);return

# Guest: replay the host's action on the local body.
static func replay(g,message: Dictionary):
	for enemy in g.enemies:
		if enemy.get("boss_id",-1)==8 and not enemy.dead:
			var body=rig(enemy)
			enemy.node.rotation.y=float(message.get("turn",enemy.node.rotation.y))
			if body!=null: body.play(str(message.get("action","")),float(message.get("windup",1)),float(message.get("active",.3)),float(message.get("recover",1)),bool(message.get("open",false)))
			return

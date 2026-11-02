extends RefCounted
class_name WrenchTune

# Wrench's turret tune-up (user, November 2): at a placed turret, E starts an
# arrow sequence like the co-op rescue code. While he keeps entering arrows
# without a mistake, that turret works twice as fast (shots, pulses, heals).
# A wrong arrow or a hit stops the boost and starts the code over; E again,
# walking away or the turret going ends the tune-up. While tuning he stands
# still (the movement keys are the arrows).

const REACH=3.4
const LEAVE=5.0
const BOOST=2.0
const HOLD=1.6  # seconds of boost each correct arrow keeps alive

static var active=false
static var turret={}
static var boost_until=-1.0
static var streak=0

static func reset():
	active=false;turret={};boost_until=-1.0;streak=0

static func code(g) -> RescueCode: return g.hud.tune_code

static func nearest_turret(g) -> Dictionary:
	var best=REACH;var found={}
	for weapon in g.equipped:
		if not weapon.get("turret",false) or not is_instance_valid(weapon.get("node")): continue
		var d=Vector2(weapon.node.position.x-g.player.position.x,weapon.node.position.z-g.player.position.z).length()
		if d<best: best=d;found=weapon
	return found

# E: start (or stop) tuning the turret in reach. Only Wrench can.
static func try_start(g) -> bool:
	if str(g.hero.get("id",""))!="wrench": return false
	if active: stop(g);return true
	var found=nearest_turret(g)
	if found.is_empty(): return false
	active=true;turret=found;streak=0;boost_until=-1.0
	code(g).begin(1)
	g.sound.ui_effect("switch")
	return true

static func stop(g):
	active=false;boost_until=-1.0;streak=0;turret={}
	if is_instance_valid(g.hud.tune_code): g.hud.tune_code.clear_code()

static func tick(g,delta: float):
	if not active: return
	var c=code(g);c.tick(delta)
	if turret.is_empty() or not is_instance_valid(turret.get("node")) or not g.equipped.has(turret) or g.hp<=0 or g.mode!="playing": stop(g);return
	if Vector2(turret.node.position.x-g.player.position.x,turret.node.position.z-g.player.position.z).length()>LEAVE: stop(g);return
	enter(g,c.read_input())
	if boosted(g,turret) and randf()<delta*8.0: g.burst(turret.node.position+Vector3.UP*1.2,Color("ffd23f"),3)

# One arrow's result: keep the boost going, finish a code, or break it.
static func enter(g,result: String):
	match result:
		"ok":
			streak+=1;boost_until=maxf(boost_until,g.elapsed)+HOLD
			boost_until=minf(boost_until,g.elapsed+HOLD*2.0)
		"done":
			streak+=1;boost_until=g.elapsed+HOLD*2.0
			g.burst(turret.node.position+Vector3.UP*1.6,Color("ffd23f"),8);g.sound.effect("deploy",turret.node.position)
			code(g).begin(1)
		"wrong":
			streak=0;boost_until=-1.0;g.sound.ui_effect("error")

# A hit knocks him out of the rhythm.
static func interrupt(g):
	if not active: return
	streak=0;boost_until=-1.0
	if is_instance_valid(g.hud.tune_code): g.hud.tune_code.interrupt()

static func boosted(g,weapon: Dictionary) -> bool:
	return active and weapon==turret and g.elapsed<boost_until

static func rate(g,weapon: Dictionary) -> float:
	return BOOST if boosted(g,weapon) else 1.0

extends RefCounted
class_name PartyCombo

# Co-op combos, decided by the host from who landed each hit:
#   Crossfire  two different players hit the same enemy within 1.5 s: it is
#              marked for 3 s and takes 25% more damage from everyone.
#   Overload   lightning from one player strikes an enemy another player set
#              burning: a fire-and-lightning blast hurts everything nearby.
# Solo play is unchanged. The host broadcasts each combo so every player sees it.
const WINDOW=1.5
const MARK=3.0
const BONUS=1.25

static func active(g) -> bool:
	return g.coop.active and g.coop.hosting and not g.coop.members.is_empty()

# Damage multiplier for a direct hit on an enemy currently marked by Crossfire.
static func multiplier(g,enemy: Dictionary) -> float:
	return BONUS if float(enemy.get("crossfire_until",-1))>g.elapsed else 1.0

static func on_hit(g,enemy: Dictionary,damage: float,cause: String,hitter: int):
	if not active(g) or enemy.dead or cause in ["poison","fire","gravity"]: return
	var hitters: Dictionary=enemy.get("hitters",{})
	for id in hitters.keys():
		if g.elapsed-float(hitters[id])>WINDOW: hitters.erase(id)
	var others=hitters.keys().filter(func(id):return int(id)!=hitter)
	hitters[hitter]=g.elapsed;enemy.hitters=hitters
	if not others.is_empty() and float(enemy.get("crossfire_until",-1))<=g.elapsed:
		enemy.crossfire_until=g.elapsed+MARK
		announce(g,"crossfire",g.enemy_center(enemy))
	var burner=int(enemy.get("fire_owner",enemy.get("status_owner",-1)))
	if cause=="lightning" and enemy.fire>0 and burner>=0 and burner!=hitter and g.elapsed-float(enemy.get("overload_time",-9))>2.0:
		enemy.overload_time=g.elapsed
		var center: Vector3=enemy.node.position
		announce(g,"overload",center)
		g.damage_area(center,3.5,maxf(damage,8.0)*.8,"explosion",enemy,"party:overload")

static func announce(g,kind: String,point: Vector3):
	visual(g,kind,point)
	g.coop.broadcast({"type":"party_combo","kind":kind,"realm":g.realm,"position":CoopSession.array(point)})

static func visual(g,kind: String,point: Vector3):
	match kind:
		"crossfire":
			# A gold cross over the marked enemy, read at a glance in a busy fight.
			var mark=CombatInk.star(g,point+Vector3.UP*1.6,3.4,Color("ffd35a"),4.0,.6,1.0,"status")
			if mark!=null: mark.shards(Color("fff0b0"),8,3.0);mark.lamp(g,Color("ffd35a"),3.0,6.0,Vector3.ZERO)
			CombatInk.star(g,point+Vector3.UP*1.6,2.6,Color("fff0b0"),2.0,.45,3.0,"status")
			CombatInk.wave(g,point+Vector3.DOWN*.8,2.2,Color("ffd35a"))
		"overload":
			var blast=CombatInk.star(g,point+Vector3.UP,4.0,Color("79c6ff"),8.0,.45)
			if blast!=null: blast.shards(Color("ffb347"),10,4.0);blast.lamp(g,Color("9fd8ff"),4.0,8.0,Vector3.UP)
			CombatInk.wave(g,point,3.5,Color("ff7424"))
			for i in range(3):
				var angle=i*TAU/3.0+point.x
				CombatInk.beam(g,point+Vector3.UP,point+Vector3(cos(angle),.3,sin(angle))*3.0,Color("79c6ff"),true,.8)

extends RefCounted
class_name Lasso

# The rope for everyday use (user, November 2: "keep the C skill, make it fun to
# use casually all the time ... no blast or damage, it is for fun: dragging
# your friend or enemies"). C throws a rope round the nearest monster in front
# (not a boss): it is stunned and dragged behind the hero. C again (or after
# HOLD seconds) tosses it where the camera looks; it tumbles through the air
# and lands in a puff of dust, unhurt. Friends come first: next to one, C
# drags them instead (CarryRescue).
#
# The host owns the monsters: a client asks with big_action "lasso" / "hurl",
# and its pose carries "lasso" (the roped monster's id) so everyone sees the rope.

const REACH=7.0
const LENGTH=2.4
const HOLD=6.0
const COOLDOWN=2.5
const THROW=11.0
const FLY=.6

static var mine=-1          # net id of the monster this player ropes
static var cooldown=0.0
static var held={}          # host: player id -> {"id":net id,"time":seconds,"flail":clock}
static var flights=[]       # host: thrown monsters in the air
static var throws=0

static func reset():
	mine=-1;cooldown=0.0;held.clear();flights.clear();throws=0

static func enemy_by_id(g,id: int) -> Dictionary:
	if id<0: return {}
	for enemy in g.enemies:
		if int(enemy.net_id)==id and not enemy.dead and is_instance_valid(enemy.node): return enemy
	return {}

static func forward(g) -> Vector3: return Vector3(-sin(g.yaw),0,-cos(g.yaw))

# The monster the rope would catch: near, roughly in front, not a boss.
static func pick(g) -> Dictionary:
	var best={};var score=1e9;var at: Vector3=g.player.position;var ahead=forward(g)
	for enemy in g.enemies:
		if enemy.dead or enemy.boss or enemy.get("thrown",false) or not is_instance_valid(enemy.node): continue
		var to: Vector3=enemy.node.position-at;to.y=0
		var d=to.length()
		if d>REACH+float(enemy.radius): continue
		var s=d-3.0*(to.normalized().dot(ahead) if d>.01 else 1.0)
		if s<score: score=s;best=enemy
	return best

# C with nobody downed in reach.
static func press(g):
	if g.underside.active() or g.mode!="playing": return
	if mine>=0: hurl(g);return
	if cooldown>0: return
	var enemy=pick(g)
	if enemy.is_empty(): return
	mine=int(enemy.net_id)
	if g.coop.active and not g.coop.hosting: g.coop.send_to(g.coop.owner_id,{"type":"big_action","action":"lasso","id":mine,"realm":g.realm})
	else: grab(g,g.coop.local_id if g.coop.active else 0,enemy)
	g.sound.effect("dash",g.player.position);HeroTricks.word(g,"⛓",Color("e6c27a"))

static func hurl(g):
	var dir=forward(g)
	if g.coop.active and not g.coop.hosting: g.coop.send_to(g.coop.owner_id,{"type":"big_action","action":"hurl","direction":[dir.x,dir.z],"realm":g.realm})
	else: throw(g,g.coop.local_id if g.coop.active else 0,dir)
	mine=-1;cooldown=COOLDOWN;g.sound.effect("jump",g.player.position)

# Host side.
static func grab(g,player: int,enemy: Dictionary):
	if enemy.is_empty() or enemy.boss or enemy.dead: return
	for other in held.values():
		if int(other.id)==int(enemy.net_id): return
	held[player]={"id":int(enemy.net_id),"time":0.0}

static func throw(g,player: int,dir: Vector3):
	if not held.has(player): return
	var enemy=enemy_by_id(g,int(held[player].id));held.erase(player)
	if enemy.is_empty(): return
	dir.y=0;dir=dir.normalized() if dir.length()>.01 else Vector3.FORWARD
	var from: Vector3=enemy.node.position;var flat=Vector2(from.x+dir.x*THROW,from.z+dir.z*THROW)
	var coast=g.world.shore_radius(Vector3(flat.x,0,flat.y))
	if flat.length()>coast-2.0: flat=flat.normalized()*(coast-2.0)
	var to=Vector3(flat.x,g.world.height_at(flat.x,flat.y),flat.y)
	enemy.thrown=true
	flights.append({"enemy":enemy,"from":from,"to":to,"t":0.0})
	throws+=1

static func holder_position(g,player: int) -> Vector3:
	if not g.coop.active or player==g.coop.local_id: return g.player.position
	return CoopSession.vector(g.coop.members.get(player,{}).get("position",[]))

static func holder_ok(g,player: int) -> bool:
	if not g.coop.active or player==g.coop.local_id: return g.hp>0 and not g.update.downed and not g.underside.active()
	var member=g.coop.members.get(player,{})
	return not member.is_empty() and float(member.get("hp",0))>0 and not bool(member.get("under",false))

# A client's request (BigUpdate.receive on the host).
static func receive(g,sender: int,message: Dictionary) -> bool:
	match str(message.get("action","")):
		"lasso": grab(g,sender,enemy_by_id(g,int(message.get("id",-1))));return true
		"hurl":
			var d=message.get("direction",[0,-1])
			if d is Array and d.size()==2: throw(g,sender,Vector3(float(d[0]),0,float(d[1])))
			return true
	return false

# Every physics frame while playing.
static func tick(g,delta: float):
	cooldown=maxf(0,cooldown-delta)
	if mine>=0 and (enemy_by_id(g,mine).is_empty() or g.update.downed or g.underside.active()): mine=-1
	if g.coop.active and not g.coop.hosting: return
	# Host (or solo): drag, auto-throw, flights.
	for player in held.keys():
		var hold=held[player];var enemy=enemy_by_id(g,int(hold.id))
		if enemy.is_empty() or not holder_ok(g,int(player)): held.erase(player);continue
		hold.time+=delta
		if hold.time>=HOLD:
			var dir=forward(g) if not g.coop.active or int(player)==g.coop.local_id else Vector3(-sin(float(g.coop.members[player].get("yaw",0))),0,-cos(float(g.coop.members[player].get("yaw",0))))
			throw(g,int(player),dir)
			if int(player)==g.coop.local_id or not g.coop.active: mine=-1;cooldown=COOLDOWN
			continue
		var anchor=holder_position(g,int(player))
		var to: Vector3=anchor-enemy.node.position;to.y=0
		enemy.freeze=maxf(float(enemy.freeze),.3)
		if to.length()>LENGTH: enemy.pull=to.normalized()*(to.length()-LENGTH)*14.0
	for flight in flights.duplicate():
		var enemy: Dictionary=flight.enemy
		if enemy.dead or not is_instance_valid(enemy.node): flights.erase(flight);continue
		flight.t+=delta/FLY
		var t=minf(1.0,float(flight.t))
		enemy.node.position=flight.from.lerp(flight.to,t)+Vector3.UP*sin(t*PI)*3.2
		enemy.node.rotation.x=t*TAU
		enemy.freeze=maxf(float(enemy.freeze),.3)
		if t>=1.0:
			flights.erase(flight);enemy.thrown=false;enemy.node.rotation.x=0
			# A harmless landing: a puff of dust and a dizzy wobble.
			var at: Vector3=flight.to
			g.burst(at+Vector3.UP*.3,Color("c9b48a"),10)
			g.sound.effect("land",at)
			enemy.freeze=maxf(float(enemy.freeze),.8)

# Ropes to draw: [holder body, monster body, holder under the island].
static func pairs(g) -> Array:
	var list=[]
	if mine>=0:
		var enemy=enemy_by_id(g,mine)
		if not enemy.is_empty(): list.append([g.player,enemy.node,false])
	if g.coop.active:
		for id in g.coop.members:
			var target=int(g.coop.members[id].get("lasso",-1))
			if target<0: continue
			var a=CarryRescue.body(g,int(id));var enemy=enemy_by_id(g,target)
			if a!=null and not enemy.is_empty(): list.append([a,enemy.node,false])
	return list

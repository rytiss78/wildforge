extends RefCounted
class_name CarryRescue

# Dragging a downed friend (user, November 2). Beside a downed friend, C (L3 on
# a pad) grabs them: the body is dragged behind on a short rope and the helper
# walks a bit slower; C again lets go. The point: a hero under the island who
# stands below a friend's body on top pulls it straight down through the rock
# ("pull the body from the ground to the underworld"), where nothing can hit
# them during the usual rescue code. It works the other way round too.
# A living friend can be roped too, just for fun: they are tugged along behind
# (a rope snaps past SNAP metres). With no friend in reach, C ropes a monster
# (Lasso).
#
# The helper's pose carries "carry" (the friend's id); the downed player's game
# follows its carrier and goes under or back on top with it.

const ROPE=1.4
const SLOW=.75
const REACH=3.0
const SNAP=12.0
const TUG=7.0

static var carrying=-1     # the friend this player drags (-1: nobody)
static var carried_by=-1   # on a downed player: who drags them
static var pressed=false
static var rope: MeshInstance3D
static var ropes=[]

static func reset():
	carrying=-1;carried_by=-1;pressed=false;Lasso.reset()

static func speed_scale(_g) -> float: return SLOW if carrying>=0 else 1.0

# The body a player id stands for on this screen.
static func body(g,id: int) -> Node3D:
	if id==g.coop.local_id: return g.player
	var node=g.coop.avatars.get(id,null)
	return node if is_instance_valid(node) else null

# Someone else already drags this friend.
static func taken(g,target: int) -> bool:
	for id in g.coop.members:
		if int(id)!=g.coop.local_id and int(g.coop.members[id].get("carry",-1))==target and float(g.coop.members[id].get("hp",0))>0: return true
	return false

# A downed friend in reach: beside them, or right above / below on the other
# side of the island (same spot, through the rock).
static func find(g) -> int:
	if not g.coop.active: return -1
	var at: Vector3=g.player.position;var best=-1;var best_d=REACH
	for key in g.update.downed_ids:
		var id=int(key)
		if id==g.coop.local_id or taken(g,id): continue
		var b=body(g,id)
		if b==null: continue
		var d=Vector2(b.position.x-at.x,b.position.z-at.z).length()
		if not through(g,id) and absf(b.position.y-at.y)>3.0: continue
		if d<best_d: best_d=d;best=id
	return best

# Is the friend on the other side of the island (a pull through the rock)?
static func through(g,id: int) -> bool:
	return id>=0 and bool(g.coop.members.get(id,{}).get("under",false))!=g.underside.flipped()

static func flat_distance(a: Vector3,b: Vector3) -> float: return Vector2(a.x-b.x,a.z-b.z).length()

# A living friend in reach (on the same side of the island).
static func find_friend(g) -> int:
	if not g.coop.active: return -1
	var at: Vector3=g.player.position;var best=-1;var best_d=REACH
	for key in g.coop.members:
		var id=int(key);var member=g.coop.members[key]
		if id==g.coop.local_id or g.update.downed_ids.has(id) or float(member.get("hp",0))<=0 or taken(g,id) or through(g,id): continue
		var b=body(g,id)
		if b==null: continue
		var d=b.position.distance_to(at)
		if d<best_d: best_d=d;best=id
	return best

# A living player roped by a friend is tugged after them.
static func tugged(g):
	if not g.coop.active or g.update.downed: return
	for key in g.coop.members:
		var member=g.coop.members[key]
		if int(member.get("carry",-1))!=g.coop.local_id or float(member.get("hp",0))<=0: continue
		var c=CoopSession.vector(member.get("position",[]))
		if not c.is_finite() or bool(member.get("under",false))!=g.underside.flipped(): continue
		var to: Vector3=c-g.player.position;to.y=0
		if to.length()>ROPE*1.5: g.knock_velocity=to.normalized()*minf(TUG*1.6,(to.length()-ROPE)*TUG*.6)
		return

# Every physics frame while playing (also while downed).
static func tick(g,delta: float):
	var key=Input.is_action_pressed("carry");var tap=key and not pressed;pressed=key
	if g.update.downed: carrying=-1
	else:
		carried_by=-1
		if carrying>=0 and (not g.coop.active or body(g,carrying)==null or flat_distance(body(g,carrying).position,g.player.position)>SNAP or not g.update.downed_ids.has(carrying) and float(g.coop.members.get(carrying,{}).get("hp",0))<=0): carrying=-1
		if tap and g.mode=="playing":
			if carrying>=0: carrying=-1;g.sound.effect("land",g.player.position)
			else:
				var target=find(g)
				if target<0: target=find_friend(g)
				if target>=0:
					if through(g,target): g.underside.dirt(g,g.player.position,-1.0 if g.underside.flipped() else 1.0);g.hit_shake=maxf(g.hit_shake,.25)
					carrying=target;Lasso.mine=-1;g.sound.effect("land",g.player.position);HeroTricks.word(g,"⛓",Color("8fd3ff"))
				else: Lasso.press(g)
	tugged(g)
	Lasso.tick(g,delta)
	draw_ropes(g)

# On the downed player: follow the carrier on the rope, on top or under the
# island with them. Returns true while carried (the usual downed fall is off).
static func follow(g) -> bool:
	carried_by=-1
	var carrier={}
	for id in g.coop.members:
		var member=g.coop.members[id]
		if int(member.get("carry",-1))==g.coop.local_id and float(member.get("hp",0))>0: carried_by=int(id);carrier=member;break
	if carried_by<0:
		# Let go under the island: stay there (the belly holds the body).
		if g.underside.state=="under": g.player.position.y=g.world.under_height(g.player.position.x,g.player.position.z)
		return g.underside.state=="under"
	Spectate.target_id=carried_by
	var c=CoopSession.vector(carrier.get("position",[]))
	if not c.is_finite(): return true
	var under=bool(carrier.get("under",false))
	var p: Vector3=g.player.position;var flat=Vector2(p.x,p.z);var anchor=Vector2(c.x,c.z)
	if flat.distance_to(anchor)>ROPE: flat=anchor+(flat-anchor).normalized()*ROPE
	var coast=g.world.shore_radius(Vector3(flat.x,0,flat.y))
	if flat.length()>coast-Underside.INSET*.5: flat=flat.normalized()*(coast-Underside.INSET*.5)
	if under and g.underside.state!="under":
		# Pulled down through the rock: a spray of dirt where the body sinks.
		g.underside.dirt(g,g.player.position,1.0)
		g.underside.state="under";g.underside.clock=0.0;g.underside.light(g,true)
		g.avatar.rotation=Vector3(0,g.avatar.rotation.y,PI)
	elif not under and g.underside.state=="under":
		g.underside.dirt(g,g.player.position,-1.0)
		g.underside.state="top";g.underside.light(g,false)
		g.avatar.rotation=Vector3(0,g.avatar.rotation.y,0)
	var y=g.world.under_height(flat.x,flat.y) if under else g.world.height_at(flat.x,flat.y)+.05
	g.player.position=Vector3(flat.x,y,flat.y);g.player.velocity=Vector3.ZERO
	return true

# The rope between each carrier and the friend they drag, seen by everyone.
static func draw_ropes(g):
	var pairs=Lasso.pairs(g)
	if carrying>=0 and body(g,carrying)!=null: pairs.append([g.player,body(g,carrying),g.underside.flipped()])
	if g.coop.active:
		for id in g.coop.members:
			var target=int(g.coop.members[id].get("carry",-1))
			if target<0 or float(g.coop.members[id].get("hp",0))<=0: continue
			var a=body(g,int(id));var b=body(g,target)
			if a!=null and b!=null: pairs.append([a,b,bool(g.coop.members[id].get("under",false))])
	while ropes.size()<pairs.size():
		var node=MeshInstance3D.new();var tube=CylinderMesh.new();tube.top_radius=.035;tube.bottom_radius=.035;tube.height=1.0;tube.radial_segments=6
		node.mesh=tube;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var paint=StandardMaterial3D.new();paint.albedo_color=Color("c9a46a");paint.roughness=.9;node.material_override=paint
		g.add_child(node);ropes.append(node)
	for i in range(ropes.size()):
		var node: MeshInstance3D=ropes[i]
		if not is_instance_valid(node): continue
		node.visible=i<pairs.size()
		if not node.visible: continue
		var up=Vector3.DOWN if pairs[i][2] else Vector3.UP
		var a: Vector3=pairs[i][0].position+up*.85;var b: Vector3=pairs[i][1].position+up*.35
		var span=b-a
		if span.length()<.05: node.visible=false;continue
		node.position=(a+b)*.5
		var y=span.normalized();var x=y.cross(Vector3.FORWARD if absf(y.dot(Vector3.FORWARD))<.9 else Vector3.RIGHT).normalized();var z=x.cross(y)
		node.basis=Basis(x,y*span.length(),z)
	ropes=ropes.filter(func(n):return is_instance_valid(n))

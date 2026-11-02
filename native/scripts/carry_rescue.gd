extends RefCounted
class_name CarryRescue

# Dragging a downed friend under the island (user, November 2: "a hero should be
# able to pull another player's body to the underworld to revive; reviving on
# the normal side is too hard"). Next to a downed friend, C (L3 on a pad) grabs
# them: the body is dragged behind on a short rope and the helper walks a bit
# slower. Taken under the island (over the rim, or with Digby's dig) nothing can
# hit either of them, and the friend comes back by themselves after REVIVE
# seconds there. C again lets go.
#
# The helper's pose carries "carry" (the friend's id); the downed player's game
# follows its carrier and goes under or back on top with it; the host counts
# the seconds under and revives (BigUpdate.host_tick).

const ROPE=1.4
const SLOW=.75
const REVIVE=3.0

static var carrying=-1     # the friend this player drags (-1: nobody)
static var carried_by=-1   # on a downed player: who drags them
static var progress={}     # host: friend id -> seconds spent under the island
static var pressed=false
static var rope: MeshInstance3D
static var ropes=[]

static func reset():
	carrying=-1;carried_by=-1;progress.clear();pressed=false

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

# Every physics frame while playing (also while downed).
static func tick(g,_delta: float):
	if not g.coop.active or not g.run_active: carrying=-1;carried_by=-1;draw_ropes(g);return
	var key=Input.is_action_pressed("carry");var tap=key and not pressed;pressed=key
	if g.update.downed: carrying=-1
	else:
		carried_by=-1
		if carrying>=0 and (not g.update.downed_ids.has(carrying) or body(g,carrying)==null): carrying=-1
		if tap and g.mode=="playing":
			if carrying>=0: carrying=-1;g.sound.effect("land",g.player.position)
			else:
				var target=g.update.rescue_target(g.player.position,g.coop.local_id)
				if target>0 and not taken(g,target):
					carrying=target;g.sound.effect("land",g.player.position);g.hud.tell("⛓",1)
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
		g.underside.state="under";g.underside.clock=0.0;g.underside.light(g,true)
		g.avatar.rotation=Vector3(0,g.avatar.rotation.y,PI)
	elif not under and g.underside.state=="under":
		g.underside.state="top";g.underside.light(g,false)
		g.avatar.rotation=Vector3(0,g.avatar.rotation.y,0)
	var y=g.world.under_height(flat.x,flat.y) if under else g.world.height_at(flat.x,flat.y)+.05
	g.player.position=Vector3(flat.x,y,flat.y);g.player.velocity=Vector3.ZERO
	return true

# Host: a downed friend under the island (dragged there, or let go there) comes
# back after REVIVE seconds underneath; the one who dragged them gets the rescue.
static func host_tick(g,delta: float,working: Dictionary):
	var players={g.coop.local_id:{"carry":carrying,"under":g.underside.flipped(),"hp":g.hp}}
	for id in g.coop.members: players[int(id)]=g.coop.members[id]
	var seen={}
	for target in g.update.downed_ids.keys():
		target=int(target)
		var rescuer=-1;var under=bool(players.get(target,{}).get("under",false))
		for helper in players:
			var member=players[helper]
			if int(member.get("carry",-1))==target and float(member.get("hp",0))>0:
				rescuer=int(helper);under=under or bool(member.get("under",false))
		if not under: continue
		seen[target]=true
		progress[target]=float(progress.get(target,0))+delta
		g.update.rescue_progress[target]=3.0*clampf(float(progress[target])/REVIVE,0,1);working[target]=true
		if float(progress[target])>=REVIVE:
			progress.erase(target);g.update.revive(target)
			if rescuer==g.coop.local_id: g.update.run_rescues+=1;g.update.note("RESCUE")
			elif rescuer>=0: g.coop.send_to(rescuer,{"type":"big_memory","key":"RESCUE"})
	for id in progress.keys():
		if not seen.has(id): progress.erase(id)

# How far the friend this player drags is from coming back (0..1).
static func revive_share(g,id: int) -> float:
	return clampf(float(g.update.rescue_progress.get(id,g.update.rescue_progress.get(str(id),0)))/3.0,0,1)

# The rope between each carrier and the friend they drag, seen by everyone.
static func draw_ropes(g):
	var pairs=[]
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

extends RefCounted

static func dash_vector(stick: Vector2,yaw: float,last_direction: Vector3) -> Vector3:
	if stick.length()>.18: return Vector3(stick.x,0,stick.y).rotated(Vector3.UP,yaw).normalized()
	var fallback=Vector3(last_direction.x,0,last_direction.z)
	return fallback.normalized() if fallback.length()>.01 else Vector3.FORWARD.rotated(Vector3.UP,yaw)

static func ranged_movement(enemy: Dictionary,toward: Vector3,distance: float,visible: bool) -> Vector3:
	# Different firing rings leave room for melee enemies to pass through.
	# Walk closer when terrain blocks the shot; never kite forever beyond range.
	var forward=toward.normalized()
	if not visible or distance>21: return forward
	var preferred=[12.0,10.0,17.0,14.0,11.0,16.0][enemy.biome]+float(enemy.net_id%3)-1.0
	if distance<preferred-2: return -forward*.75
	if distance>preferred+2: return forward*.8
	if enemy.get("ranged_recovery",0)>0: return Vector3.ZERO
	var side=forward.cross(Vector3.UP)*(1 if int(enemy.net_id)%2==0 else -1)
	return side*[.2,.45,.08,.5,.3,.6][enemy.biome]

static func charge_movement(g,enemy: Dictionary,aim: Vector3,distance: float,delta: float) -> Vector3:
	# A rush commits when the warning starts. Dodging sideways then matters.
	if enemy.freeze>0 or enemy.blind>0:
		enemy.windup=0.0;enemy.charge=0.0
		return aim
	if enemy.get("windup",0)>0:
		enemy.windup=maxf(0,enemy.windup-delta);g.update.eyebrows(enemy)
		if enemy.windup<=0: enemy.charge=.65
		return Vector3.ZERO
	if enemy.get("charge",0)>0:
		enemy.charge=maxf(0,enemy.charge-delta)
		return enemy.get("charge_direction",aim)
	if enemy.attack<=0 and distance>2 and distance<13:
		enemy.windup=.8;enemy.attack=5.0;enemy.charge_direction=aim.normalized()
		enemy.node.get_meta("rig").attack=.8;g.update.eyebrows(enemy)
		return Vector3.ZERO
	return aim

static func ranged_attack(g,enemy: Dictionary,target: Vector3):
	if g.coop.active and not g.coop.hosting: return
	enemy.attack=4.2+float(enemy.net_id%3)*.35
	enemy.ranged_recovery=.65
	enemy.node.get_meta("rig").attack=.8
	var forward=(target-enemy.node.position).normalized();forward.y=0
	var side=forward.cross(Vector3.UP).normalized()
	var damage=(24+g.realm*7)*enemy.damage*g.realm_difficulty
	var style=["roots","toxic","meteor","storm","lava","void"][enemy.biome]
	var points=[target]
	if enemy.biome in [0,3]: points.append(target+side*3.4);points.append(target-side*3.4)
	elif enemy.biome in [2,5]: points.append(target+forward*3.8)
	for i in range(points.size()):
		var p=points[i];p.y=g.world.height_at(p.x,p.z)
		var delay=1.05+i*.2
		g.warn_at(p,1.7,delay,damage,style)
		if g.coop.active: g.coop.broadcast({"type":"hazard","realm":g.realm,"position":CoopSession.array(p),"radius":1.7,"delay":delay,"damage":damage,"style":style})

# Host-owned contact attacks commit to one target and can miss or be interrupted.
static func contact_tick(g,enemy: Dictionary,target: Dictionary,touching: bool,delta: float) -> bool:
	enemy.contact=maxf(0,float(enemy.get("contact",0))-delta)
	var remaining=float(enemy.get("contact_windup",0))
	if enemy.freeze>0 or enemy.blind>0:
		enemy.contact_windup=0.0
		contact_warning(enemy)
		return false
	if remaining>0:
		enemy.contact_windup=maxf(0,remaining-delta)
		contact_warning(enemy)
		if enemy.contact_windup<=0:
			enemy.contact=.7
			return touching and int(enemy.get("contact_target",-1))==int(target.id)
	elif touching and enemy.contact<=0:
		enemy.contact_windup=.45;enemy.contact_target=target.id
		enemy.node.get_meta("rig").attack=.45
		contact_warning(enemy)
	return false

static var contact_mesh: TorusMesh
static var contact_paint: StandardMaterial3D

static func contact_warning(enemy: Dictionary):
	var remaining=float(enemy.get("contact_windup",0))
	if remaining>0 and not enemy.has("contact_ring"):
		if contact_mesh==null:
			contact_mesh=TorusMesh.new();contact_mesh.inner_radius=.90;contact_mesh.outer_radius=1.0
			contact_mesh.rings=24;contact_mesh.ring_segments=6
			contact_paint=StandardMaterial3D.new();contact_paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			contact_paint.albedo_color=Color("ff674a")
		var ring=MeshInstance3D.new();ring.mesh=contact_mesh;ring.material_override=contact_paint
		ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		enemy.node.add_child(ring);enemy.contact_ring=ring
	if enemy.has("contact_ring"):
		var ring=enemy.contact_ring;ring.visible=remaining>0
		var radius=(enemy.radius+.85)*lerpf(.75,1.0,1-clampf(remaining/.45,0,1))
		ring.position.y=.12;ring.scale=Vector3(radius,.3,radius)

extends RefCounted
class_name ExplosiveBarrels

# Red explosive barrels (user request, October 29): eighteen spots per island,
# some in pairs and threes, placed from the run seed so every machine has the same
# ones. A hero shot, any explosion or a slam lights a barrel; it shakes and flashes
# for a moment, then blows up, hurting enemies AND any hero nearby, and lights the
# barrels around it, so a row of them goes off in a chain.
#
# Co-op: the host decides every explosion. A guest who hits a barrel asks the host
# (barrel_hit); the host lights it, deals the enemy damage and tells everyone
# (barrel_boom). Each machine then hurts only its own hero and draws the blast.

const SPOTS=18
const RADIUS=5.5
const FUSE_SHOT=.22
const FUSE_CHAIN=.16
const HERO_DAMAGE=.18  # of max health at the centre, half at the edge
const ENEMY_DAMAGE=55.0

static func setup(g):
	clear(g)
	if g.realm>=3: return
	var rng=RandomNumberGenerator.new();rng.seed=g.seed_value+g.realm*2903
	var id=0
	for spot in range(SPOTS):
		var angle=(spot+rng.randf())*TAU/SPOTS+g.realm*.7
		var radius=rng.randf_range(42,250)
		var center=Vector3(cos(angle)*radius,0,sin(angle)*radius)
		var count=[1,1,2,2,3][rng.randi_range(0,4)]
		for k in range(count):
			var p=center+Vector3(rng.randf_range(-1,1),0,rng.randf_range(-1,1)).normalized()*(1.4*k)
			p.y=g.world.height_at(p.x,p.z)
			if g.world.lava_at(p) or p.y<g.world.height_at(0,0)-30: continue
			g.barrels.append({"id":id,"node":model(g,p),"fuse":-1.0,"asked":false});id+=1

static func clear(g):
	for barrel in g.barrels:
		if is_instance_valid(barrel.node): barrel.node.queue_free()
	g.barrels.clear()

# A red drum with dark rims, a yellow hazard band and a flame mark, on a small
# collision cylinder so heroes and enemies bump into it.
static func model(g,p: Vector3) -> StaticBody3D:
	var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;body.position=p
	var collider=CollisionShape3D.new();var cylinder=CylinderShape3D.new();cylinder.radius=.48;cylinder.height=1.15
	collider.shape=cylinder;collider.position=Vector3(0,.58,0);body.add_child(collider)
	var look=Node3D.new();look.name="Look";body.add_child(look)
	var drum=CylinderMesh.new();drum.top_radius=.46;drum.bottom_radius=.46;drum.height=1.1;drum.radial_segments=14;drum.rings=1
	g.shape(drum,Color("e0262b"),look,Vector3(0,.56,0))
	for y in [.08,.4,.72,1.06]:
		var rim=CylinderMesh.new();rim.top_radius=.49;rim.bottom_radius=.49;rim.height=.06;rim.radial_segments=14;rim.rings=1
		g.shape(rim,Color("57191b"),look,Vector3(0,y,0))
	var band=CylinderMesh.new();band.top_radius=.475;band.bottom_radius=.475;band.height=.22;band.radial_segments=14;band.rings=1
	g.shape(band,Color("ffd23f"),look,Vector3(0,.56,0),.15)
	var lid=CylinderMesh.new();lid.top_radius=.4;lid.bottom_radius=.44;lid.height=.05;lid.radial_segments=14;lid.rings=1
	g.shape(lid,Color("8a1d20"),look,Vector3(0,1.13,0))
	var flame=PrismMesh.new();flame.size=Vector3(.2,.26,.04)
	for side in [-1.0,1.0]:
		var mark=g.shape(flame,Color("1d1d1d"),look,Vector3(0,.57,-.47*side))
		if side>0: mark.rotation.y=PI
	g.add_child(body)
	return body

static func find(g,id: int) -> Dictionary:
	for barrel in g.barrels:
		if int(barrel.id)==id: return barrel
	return {}

# Something hit this barrel. Only the host (or a solo game) lights it.
static func light(g,barrel: Dictionary,fuse: float):
	if barrel.is_empty() or float(barrel.fuse)>=0: return
	if g.coop.active and not g.coop.hosting:
		if not barrel.asked: barrel.asked=true;g.coop.send_to(g.coop.owner_id,{"type":"barrel_hit","realm":g.realm,"id":int(barrel.id)})
		return
	barrel.fuse=fuse

# A hero shot moved from a to b: does it pass through a barrel?
static func shot(g,a: Vector3,b: Vector3):
	for barrel in g.barrels:
		if float(barrel.fuse)>=0: continue
		var center: Vector3=barrel.node.position+Vector3.UP*.56
		var dir=b-a;var t=clampf((center-a).dot(dir)/maxf(dir.length_squared(),.0001),0,1)
		if (a+dir*t).distance_to(center)<.7: light(g,barrel,FUSE_SHOT)

# An explosion or slam at origin lights every barrel it reaches.
static func area(g,origin: Vector3,radius: float):
	for barrel in g.barrels:
		if float(barrel.fuse)<0 and origin.distance_to(barrel.node.position+Vector3.UP*.5)<radius+.5: light(g,barrel,FUSE_CHAIN)

static func tick(g,delta: float):
	for barrel in g.barrels.duplicate():
		if float(barrel.fuse)<0 or not is_instance_valid(barrel.node): continue
		barrel.fuse-=delta
		# Lit: it shakes and flashes white.
		var look=barrel.node.get_node("Look");look.position=Vector3(randf_range(-.06,.06),0,randf_range(-.06,.06))
		look.scale=Vector3.ONE*(1.0+.12*(1.0-clampf(barrel.fuse/FUSE_SHOT,0,1)))
		if barrel.fuse<=0: explode(g,barrel)

# The host's explosion: enemy damage (which lights the next barrels), then the
# blast everyone sees.
static func explode(g,barrel: Dictionary):
	var at: Vector3=barrel.node.position
	boom(g,int(barrel.id))
	g.damage_area(at+Vector3.UP*.5,RADIUS,ENEMY_DAMAGE*float(g.realm_difficulty),"explosion",{},"barrel")
	if g.coop.active and g.coop.hosting: g.coop.broadcast({"type":"barrel_boom","realm":g.realm,"id":int(barrel.id)})

# Every machine: the barrel bursts, the screen shakes and the local hero is hurt
# if close.
static func boom(g,id: int):
	var barrel=find(g,id)
	if barrel.is_empty(): return
	g.barrels.erase(barrel)
	var at: Vector3=barrel.node.position
	barrel.node.queue_free()
	g.explosion_fx(at+Vector3.UP*.5,RADIUS)
	g.burst(at+Vector3.UP*.8,Color("ff5a2a"),18);g.burst(at+Vector3.UP*1.2,Color("ffd23f"),12)
	g.sound.effect("blast",at)
	var reach=g.player.position.distance_to(at)
	g.hit_shake=maxf(g.hit_shake,clampf(1.0-reach/30.0,0,1)*.6)
	if reach<RADIUS and g.hp>0:
		g.take_damage(g.stats.maxHp*HERO_DAMAGE*lerpf(1.0,.5,reach/RADIUS),at,"blast")

# Co-op messages: barrel_hit (host) and barrel_boom (guests).
static func receive(g,sender: int,message: Dictionary) -> bool:
	var kind=str(message.get("type",""))
	if not kind.begins_with("barrel_"): return false
	if int(message.get("realm",-1))!=g.realm: return true
	if kind=="barrel_hit" and g.coop.hosting and g.coop.members.has(sender):
		var barrel=find(g,int(message.get("id",-1)))
		# A guest who joined late can still have a barrel that went off before.
		if barrel.is_empty(): g.coop.send_to(sender,{"type":"barrel_boom","realm":g.realm,"id":int(message.get("id",-1))})
		else: light(g,barrel,FUSE_SHOT)
	elif kind=="barrel_boom" and not g.coop.hosting and sender==g.coop.owner_id: boom(g,int(message.get("id",-1)))
	return true

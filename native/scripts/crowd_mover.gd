extends RefCounted
class_name CrowdMover

# Script-side movement for ordinary monsters on open ground (Build 29 perf work).
# move_and_slide for 125 bodies against the terrain trimesh was the biggest cost
# of a packed fight. A monster with nothing solid near it (no tree, rock, wall,
# lift or hero within a couple of metres, checked a few times a second) simply
# glides along the terrain: the terrain height is known exactly (World.height_at
# matches the collision triangles). Anywhere near something solid, on steep
# ground, in the air, near the rim, climbing or a boss, the physics body moves as
# before.

const RECHECK=.18
const CLEARANCE=1.4
const MAX_SLOPE=1.2  # rise per metre (about 50°) still glided; steeper uses physics
static var query: PhysicsShapeQueryParameters3D
static var sphere: SphereShape3D
static var glided=0
static var slid=0

# Tag terrain colliders so the openness probe ignores the ground itself.
static func mark_terrain(mesh_instance: Node):
	for child in mesh_instance.get_children():
		if child is StaticBody3D: child.set_meta("terrain",true)

static func open(g,enemy: Dictionary,body: CharacterBody3D,delta: float) -> bool:
	enemy.open_clock=float(enemy.get("open_clock",randf()*RECHECK))-delta
	if enemy.open_clock>0: return enemy.get("open",false)
	enemy.open_clock=RECHECK
	if query==null:
		query=PhysicsShapeQueryParameters3D.new();sphere=SphereShape3D.new();query.shape=sphere;query.collision_mask=9  # world and lifts; heroes are checked directly
	sphere.radius=float(enemy.radius)+CLEARANCE+float(enemy.speed)*RECHECK
	query.transform=Transform3D(Basis(),body.position+Vector3.UP*maxf(float(enemy.height)*.5,.6))
	query.exclude=[body.get_rid()]
	var clear=true
	for hit in g.get_world_3d().direct_space_state.intersect_shape(query,6):
		var other=hit.collider
		if other==null or not other.has_meta("terrain"): clear=false;break
	enemy.open=clear
	return clear

static func keep_off_heroes(g,p: Vector3,radius: float,height: float) -> Vector3:
	p=keep_off(p,g.player.position,radius+float(g.hero.get("radius",.42))+(.8 if g.hero.get("id","")=="white-supra" else 0.0),height)
	for avatar in g.coop.avatars.values():
		if is_instance_valid(avatar): p=keep_off(p,avatar.position,radius+.5,height)
	return p

static func keep_off(p: Vector3,hero: Vector3,reach: float,height: float) -> Vector3:
	if hero.y>p.y+height or hero.y+1.6<p.y: return p
	var away=Vector2(p.x-hero.x,p.z-hero.z)
	if away.length_squared()>=reach*reach: return p
	if away.length_squared()<.0001: away=Vector2.RIGHT
	away=away.normalized()*reach
	return Vector3(hero.x+away.x,p.y,hero.z+away.y)

# Moves the body itself and returns true, or returns false to let physics move it.
static func glide(g,enemy: Dictionary,body: CharacterBody3D,delta: float) -> bool:
	if enemy.boss or enemy.get("surface_attached",false) or enemy.get("bubble",0)>0 or enemy.get("structure",false): return false
	if g.world.realm==RealmWorld.ARENA: return false
	var flying=enemy.get("flying",false)
	var at=body.position;var ground=g.world.height_at(at.x,at.z)
	if not flying and at.y>ground+.12: return false  # airborne: falls with physics
	var step=Vector3(body.velocity.x,0,body.velocity.z)*delta
	var next=at+step
	if Vector2(next.x,next.z).length()>g.world.shore_radius(next)-RealmWorld.RIM_START-4.0: return false
	# Heroes are solid: a gliding monster stops at a hero's edge and slides
	# round it, as the physics body did.
	next=keep_off_heroes(g,next,float(enemy.radius),float(enemy.height))
	if not open(g,enemy,body,delta): slid+=1;return false
	var next_ground=g.world.height_at(next.x,next.z)
	var run=Vector2(next.x-at.x,next.z-at.z).length()
	if run>.0001 and (next_ground-ground)/run>MAX_SLOPE: return false
	if flying: next.y=maxf(next_ground,at.y+body.velocity.y*delta)
	else: next.y=next_ground;body.velocity.y=0
	body.position=next
	glided+=1
	return true

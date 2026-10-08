extends RefCounted
class_name EnemySurface

# Only world geometry is queried; one reusable query per actively climbing actor.
static func ray(game,enemy: Dictionary,origin: Vector3,end: Vector3) -> Dictionary:
	if not enemy.has("surface_query"):
		enemy.surface_query=PhysicsRayQueryParameters3D.new();enemy.surface_query.collision_mask=1
	var query: PhysicsRayQueryParameters3D=enemy.surface_query
	query.from=origin;query.to=end
	return game.get_world_3d().direct_space_state.intersect_ray(query)

static func orient(body: Node3D,normal: Vector3,forward: Vector3):
	var tangent=forward.slide(normal).normalized()
	if tangent.length_squared()<.01: tangent=Vector3.FORWARD.slide(normal).normalized()
	if tangent.length_squared()<.01: tangent=Vector3.RIGHT.slide(normal).normalized()
	body.basis=Basis(tangent.cross(normal).normalized(),normal,-tangent).orthonormalized()

static func detach(enemy: Dictionary):
	enemy.surface_attached=false;enemy.surface_up=Vector3.UP;enemy.vertical=0.
	orient(enemy.node,Vector3.UP,-enemy.node.basis.z)

static func attach(enemy: Dictionary,hit: Dictionary,forward: Vector3):
	enemy.surface_attached=true;enemy.surface_up=hit.normal.normalized()
	enemy.node.position=hit.position+enemy.surface_up*.06
	orient(enemy.node,enemy.surface_up,forward)
	enemy.vertical=0.

static func tick(game,enemy: Dictionary,target: Vector3,delta: float) -> bool:
	var body: CharacterBody3D=enemy.node
	if enemy.flying or enemy.boss or enemy.get("bubble",0)>0:
		if enemy.get("surface_attached",false): detach(enemy)
		return false
	if enemy.freeze>0:
		if enemy.get("surface_attached",false): body.velocity=Vector3.ZERO
		return enemy.get("surface_attached",false)
	if not enemy.get("surface_attached",false):
		enemy.surface_probe=maxf(0,float(enemy.get("surface_probe",0))-delta)
		if target.y-body.position.y<1.5 or enemy.surface_probe>0: return false
		enemy.surface_probe=.15
		var aim=(target-body.position);aim.y=0;aim=aim.normalized()
		var origin=body.position+Vector3.UP*maxf(enemy.radius+.15,enemy.height*.5)
		var hit=ray(game,enemy,origin,origin+aim*(enemy.radius+.65))
		if hit.is_empty() or hit.normal.y>.65: return false
		attach(enemy,hit,Vector3.UP)
	var normal: Vector3=enemy.surface_up
	var offset=target-body.position
	var projected=offset.slide(normal)
	var direction=projected.normalized()
	# A target on the far side of a roof requires continuing to its edge.
	if projected.length()<enemy.radius+.4 and offset.dot(normal)<-.25: direction=-body.basis.z
	if enemy.blind>0: direction=(Vector3(sin(game.elapsed),0,cos(game.elapsed))).slide(normal).normalized()
	if direction.length_squared()<.01: body.velocity=Vector3.ZERO;return true
	var speed=enemy.speed*(1-minf(.7,enemy.slow))
	var travel=direction*speed*delta
	# Concave corners: transfer from a wall onto an overhang/ceiling.
	var nose=body.position+normal*(enemy.radius+.12)
	var front=ray(game,enemy,nose,nose+direction*(enemy.radius+.25+travel.length()))
	if not front.is_empty() and front.normal.dot(normal)<.7:
		attach(enemy,front,direction);normal=enemy.surface_up
		direction=(target-body.position).slide(normal).normalized();travel=direction*speed*delta
	orient(body,normal,direction)
	var previous=body.position
	var collision=body.move_and_collide(travel)
	if collision!=null: body.move_and_collide(collision.get_remainder().slide(collision.get_normal()))
	var support=ray(game,enemy,body.position+normal*.3,body.position-normal*.65)
	if support.is_empty():
		# Convex edges: look back around the edge to find the next supporting face.
		var around=body.position+direction*(enemy.radius+.2)-normal*(enemy.radius+.3)
		support=ray(game,enemy,around,around-direction*(enemy.radius*2+.8))
	if support.is_empty():
		detach(enemy);return true
	attach(enemy,support,direction)
	body.velocity=(body.position-previous)/maxf(.001,delta)
	if enemy.surface_up.y>.8:
		detach(enemy)
	return true

static func replicate(enemy: Dictionary,up: Vector3,forward: Vector3):
	if up.length_squared()<.5 or forward.length_squared()<.5: return
	enemy.surface_up=up.normalized();enemy.surface_attached=up.y<.8
	orient(enemy.node,enemy.surface_up,forward)

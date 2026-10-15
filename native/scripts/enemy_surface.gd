extends RefCounted
class_name EnemySurface

# Only world geometry is queried; one reusable query per actively climbing actor.
static func ray(game, enemy: Dictionary, origin: Vector3, end: Vector3) -> Dictionary:
	if not enemy.has("surface_query"):
		enemy.surface_query = PhysicsRayQueryParameters3D.new()
		enemy.surface_query.collision_mask = 1
	var query: PhysicsRayQueryParameters3D = enemy.surface_query
	query.from = origin
	query.to = end
	var result = game.get_world_3d().direct_space_state.intersect_ray(query)
	# Decorative growths are navigation obstacles, not climbable walls.
	if not result.is_empty() and result.collider.has_meta("natural_obstacle"): return {}
	return result

static func orient(body: Node3D, normal: Vector3, forward: Vector3):
	var tangent = forward.slide(normal).normalized()
	if tangent.length_squared() < .01:
		tangent = Vector3.FORWARD.slide(normal).normalized()
	if tangent.length_squared() < .01:
		tangent = Vector3.RIGHT.slide(normal).normalized()
	body.basis = Basis(tangent.cross(normal).normalized(), normal, -tangent).orthonormalized()

static func detach(enemy: Dictionary):
	enemy.surface_attached = false
	enemy.surface_up = Vector3.UP
	enemy.vertical = 0.
	orient(enemy.node, Vector3.UP, -enemy.node.basis.z)

static func attach(enemy: Dictionary, hit: Dictionary, forward: Vector3):
	enemy.surface_attached = true
	enemy.surface_up = hit.normal.normalized()
	enemy.node.position = hit.position + enemy.surface_up * .06
	orient(enemy.node, enemy.surface_up, forward)
	enemy.vertical = 0.

static func step_up(enemy: Dictionary, travel: Vector3) -> bool:
	var body: CharacterBody3D=enemy.node
	if enemy.flying or enemy.freeze>0 or enemy.get("bubble",0)>0 or enemy.get("surface_attached",false): return false
	if travel.length_squared()<.00001 or not body.is_on_floor(): return false
	# Free movement needs no second sweep. A blocked slide triggers stepping on
	# the following simulation tick, preserving full-body clearance checks.
	if not body.is_on_wall(): return false
	if not enemy.has("step_obstruction"): enemy.step_obstruction=KinematicCollision3D.new()
	var obstruction: KinematicCollision3D=enemy.step_obstruction
	if not body.test_move(body.global_transform,travel,obstruction): return false
	if obstruction.get_normal().y>cos(body.floor_max_angle): return false
	# Sweep the whole body up, forward and down: never warp through a wall/ceiling.
	var lift=Vector3.UP*.65
	if body.test_move(body.global_transform,lift): return false
	var raised=body.global_transform;raised.origin+=lift
	var ahead=travel.normalized()*maxf(travel.length(),.22)
	if body.test_move(raised,ahead): return false
	raised.origin+=ahead
	if not enemy.has("step_landing"): enemy.step_landing=KinematicCollision3D.new()
	var landing: KinematicCollision3D=enemy.step_landing
	if not body.test_move(raised,Vector3.DOWN*.72,landing): return false
	if landing.get_normal().y<cos(body.floor_max_angle): return false
	var destination=raised.origin+landing.get_travel()
	if destination.y-body.global_position.y<.025: return false
	body.global_position=destination;body.velocity.y=0;enemy.vertical=0
	return true

static func tick(game, enemy: Dictionary, target: Vector3, delta: float) -> bool:
	var body: CharacterBody3D = enemy.node
	if enemy.flying or enemy.boss or enemy.get("bubble", 0) > 0:
		if enemy.get("surface_attached", false):
			detach(enemy)
		return false
	if enemy.freeze > 0:
		if enemy.get("surface_attached", false):
			body.velocity = Vector3.ZERO
		return enemy.get("surface_attached", false)

	if not enemy.get("surface_attached", false):
		enemy.surface_probe = maxf(0, float(enemy.get("surface_probe", 0)) - delta)
		if enemy.surface_probe > 0:
			return false
		enemy.surface_probe = .15
		# Slope acquisition: only climb genuinely steep slopes (>45°) leading toward target
		var aim = (target - body.position)
		aim.y = 0
		aim = aim.normalized()
		# A blocking wall still needs climbing when the target is at ground level.
		var nose=body.position+Vector3.UP*.8
		var wall_hit=ray(game,enemy,nose,nose+aim*(enemy.radius+.8))
		if not wall_hit.is_empty() and absf(wall_hit.normal.y)<.5:
			attach(enemy,wall_hit,Vector3.UP)
			return true
		# Probe immediately ahead, not eight metres away. Any blocking steep slope
		# can be climbed, including a short rise with a target at the same height.
		var ahead=body.position+aim*(enemy.radius+.4)
		var ground_hit = ray(game, enemy, ahead+Vector3.UP*1.4,ahead-Vector3.UP*.3)
		if not ground_hit.is_empty() and ground_hit.normal.y < cos(body.floor_max_angle):
			attach(enemy, ground_hit, aim)
			return true
		return false

	var normal: Vector3 = enemy.surface_up
	var offset = target - body.position
	var projected = offset.slide(normal)
	var direction = projected.normalized()

	if absf(normal.y) < .5:
		direction = Vector3.UP

	if projected.length() < enemy.radius + .4 and offset.dot(normal) < -.25:
		direction = -body.basis.z

	if enemy.blind > 0:
		direction = (Vector3(sin(game.elapsed), 0, cos(game.elapsed))).slide(normal).normalized()

	if direction.length_squared() < .01:
		body.velocity = Vector3.ZERO
		return true

	var speed = enemy.speed * (1 - minf(.7, enemy.slow))
	var travel = direction * speed * delta

	var nose = body.position + normal * (enemy.radius + .12)
	var front = ray(game, enemy, nose, nose + direction * (enemy.radius + .25 + travel.length()))
	# Only re-attach to genuinely steep surfaces (>45° from vertical = normal.y < 0.71)
	if not front.is_empty() and front.normal.dot(normal) < .7:
		attach(enemy, front, direction)
		normal = enemy.surface_up
		direction = (target - body.position).slide(normal).normalized()
		travel = direction * speed * delta

	orient(body, normal, direction)
	var previous = body.position
	var collision = body.move_and_collide(travel)
	if collision != null:
		body.move_and_collide(collision.get_remainder().slide(collision.get_normal()))

	var support = ray(game, enemy, body.position + normal * .3, body.position - normal * .65)
	if support.is_empty():
		var around = body.position + direction * (enemy.radius + .2) - normal * (enemy.radius + .3)
		support = ray(game, enemy, around, around - direction * (enemy.radius * 2 + .8))

	if support.is_empty():
		detach(enemy)
		return true

	# Follow the edge onto its top before returning to ground walking.
	attach(enemy, support, direction)
	body.velocity = (body.position - previous) / maxf(.001, delta)

	if enemy.surface_up.y > .8:
		var offset_to_target = target - body.position
		offset_to_target.y = 0
		if offset_to_target.length_squared() > .01:
			var aim = offset_to_target.normalized()
			var top_probe=body.position+Vector3.UP*1.5
			var hit_ahead = ray(game, enemy, top_probe, top_probe + aim * 2)
			if hit_ahead.is_empty():
				detach(enemy)
			else:
				var spd = enemy.speed * (1 - minf(.7, enemy.slow))
				var trv = aim * spd * delta
				body.position += trv
				body.velocity = trv / delta
		else:
			detach(enemy)

	return true

static func replicate(enemy: Dictionary, up: Vector3, forward: Vector3):
	if up.length_squared() < .5 or forward.length_squared() < .5:
		return
	enemy.surface_up = up.normalized()
	enemy.surface_attached = up.y < .8
	orient(enemy.node, enemy.surface_up, forward)

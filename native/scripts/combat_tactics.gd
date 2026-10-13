extends RefCounted

static func dash_vector(stick: Vector2,yaw: float,last_direction: Vector3) -> Vector3:
	if stick.length()>.18: return Vector3(stick.x,0,stick.y).rotated(Vector3.UP,yaw).normalized()
	var fallback=Vector3(last_direction.x,0,last_direction.z)
	return fallback.normalized() if fallback.length()>.01 else Vector3.FORWARD.rotated(Vector3.UP,yaw)

static func ranged_attack(g,enemy: Dictionary,target: Vector3):
	if g.coop.active and not g.coop.hosting: return
	enemy.attack=4.2+float(enemy.net_id%3)*.35
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

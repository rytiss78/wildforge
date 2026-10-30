extends RefCounted
class_name BossBook

# Original silhouettes and attack roles. Models are authored at 3 m reference height.
const ROSTER=[
 {"name":"The Last Receiver","height":12.0,"radius":1.8,"speed":1.9,"cooldown":5.0,"biomes":[2,5,6],"style":"storm","role":"Line pulses · leave the marked corridor"},
 {"name":"Mourning Bell","height":10.5,"radius":2.3,"speed":1.7,"cooldown":5.8,"biomes":[0,3],"style":"storm","role":"Tolling rings · use the gaps between marks"},
 {"name":"Lantern Ossuary","height":9.0,"radius":2.2,"speed":2.2,"cooldown":4.8,"biomes":[4,5],"style":"meteor","role":"Crossfire · move diagonally out of the cross"},
 {"name":"The Hollow Procession","height":9.5,"radius":2.5,"speed":1.6,"cooldown":5.7,"biomes":[0,1],"style":"roots","role":"Marching lanes · leave the parallel trails"},
 {"name":"Witness of Knots","height":8.0,"radius":3.3,"speed":2.7,"cooldown":4.8,"biomes":[1,2],"style":"toxic","role":"Triangulation · leave the locked marks"},
 {"name":"The Drowned Spire","height":11.5,"radius":2.0,"speed":1.5,"cooldown":5.8,"biomes":[1,3],"style":"storm","role":"Spiral tide · move through the open center"},
 {"name":"Gallows Appetite","height":10.0,"radius":2.9,"speed":2.0,"cooldown":5.2,"biomes":[4,5,6],"style":"lava","role":"Closing jaws · retreat behind the crescent"},
 {"name":"Antler Reliquary","height":11.0,"radius":2.6,"speed":1.7,"cooldown":5.8,"biomes":[0,2],"style":"roots","role":"Root spokes · move between the three branches"}
]

static func entry(id: int) -> Dictionary:
	if id==8: return {"name":"The Grand Noggin","height":17.0,"radius":4.2,"speed":3.0,"cooldown":3.0,"style":"annihilation","role":"Giant floating head · its eyes show its health; heavy committed blows, openings after the big ones, three phases"}
	return ROSTER[clampi(id,0,ROSTER.size()-1)]

static func choose(seed_value: int,realm: int,biome: int,history: Array) -> int:
	# Weighted shuffle bag: all eight appear before reuse, and bag boundaries cannot repeat.
	var used=history.slice(history.size()-history.size()%ROSTER.size())
	var rng=RandomNumberGenerator.new();rng.seed=seed_value+realm*7919+history.size()*104729
	var pool=[];var total=0
	for id in range(ROSTER.size()):
		if used.has(id) or not history.is_empty() and id==history[-1]: continue
		var weight=1+(3 if biome in ROSTER[id].biomes else 0)+(1 if id%3==realm else 0)
		pool.append([id,weight]);total+=weight
	var roll=rng.randi_range(1,total)
	for candidate in pool:
		roll-=candidate[1]
		if roll<=0: return candidate[0]
	return pool[0][0]

static func pattern(id: int,origin: Vector3,target: Vector3,phase: int) -> Array:
	var marks=[];var toward=target-origin;toward.y=0
	var forward=toward.normalized() if toward.length()>.01 else Vector3.FORWARD
	var right=forward.cross(Vector3.UP)
	match id:
		0:
			for i in range(5): marks.append([target+forward*((i-2)*3.4),1.9,1.5+i*.14])
		1:
			for ring in range(2):
				for i in range(6): marks.append([origin+Vector3.RIGHT.rotated(Vector3.UP,i*TAU/6+ring*.3)*(5+ring*4),1.6,1.6+ring*.8])
		2:
			marks.append([target,1.8,1.6])
			for i in range(4): marks.append([target+Vector3.RIGHT.rotated(Vector3.UP,i*PI/2)*4.5,2.0,1.9])
		3:
			for side in [-1,1]:
				for i in range(4): marks.append([target+right*side*3+forward*(i-1.5)*3.4,1.6,1.7+i*.25])
		4:
			marks.append([target,2.0,1.5])
			for i in range(3): marks.append([target+Vector3.RIGHT.rotated(Vector3.UP,i*TAU/3)*4.5,1.7,2.1])
		5:
			for i in range(7): marks.append([target+Vector3.RIGHT.rotated(Vector3.UP,i*.8)*(4+i*.7),1.7,1.6+i*.20])
		6:
			for i in range(7): marks.append([origin+forward.rotated(Vector3.UP,(i-3)*.28)*8,1.7,1.5+abs(i-3)*.14])
		7:
			for arm in range(3):
				for i in range(3): marks.append([origin+forward.rotated(Vector3.UP,arm*TAU/3)*(4+i*3.6),1.7,1.7+i*.25])
	var result=[]
	for mark in marks: result.append({"position":mark[0],"radius":mark[1],"delay":mark[2],"damage_scale":1.1 if phase==2 else 1.0,"style":entry(id).style})
	return result

static func attack(g,enemy: Dictionary):
	if g.coop.active and not g.coop.hosting: return
	var id=int(enemy.boss_id);var boss=entry(id)
	if id==8:
		ColossusFight.attack(g,enemy);return
	enemy.node.get_meta("rig").attack=1.4
	for mark in pattern(id,enemy.node.position,g.coop.target(enemy.node.position).position,enemy.phase):
		var damage=roundi((22+g.realm*8)*g.realm_difficulty*mark.damage_scale)
		g.warn_at(mark.position,mark.radius,mark.delay,damage,mark.style)
		if g.coop.active: g.coop.broadcast({"type":"hazard","realm":g.realm,"position":CoopSession.array(mark.position),"radius":mark.radius,"delay":mark.delay,"damage":damage,"style":mark.style})
	enemy.recovery=g.realm_time+1.5;enemy.attack=boss.cooldown*(.82 if enemy.phase==2 else 1.0)
	g.sound.say("attack_warn",25)

static func animate(rig,clock: float,speed: float,warning: float):
	var stride=clampf(speed/3,0,1)
	for i in range(rig.legs.size()): rig.legs[i].rotation.x=sin(clock*2.1+i*PI)*.15*stride
	for i in range(rig.arms.size()): rig.arms[i].rotation.x=-.25*warning+sin(clock*1.7+i)*.07
	rig.body.rotation.z=sin(clock*.65)*.025
	rig.body.position.y=absf(sin(clock*2.1))*.015*stride

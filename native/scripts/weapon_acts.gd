extends RefCounted
class_name WeaponActs

# Each weapon attacks in its own way (user, November 3, after we looked at
# Megabonk's weapons: "your weapons are very similar in action ... they are
# distinct"). Before this almost every weapon fired a ball at the nearest enemy.
# Our own weapons and names; the attack patterns follow the kinds of weapon that
# game has:
#   flame        a flamethrower: a short cone of fire, ticking fast
#   lightning    bolts fall from the sky on random enemies in range, then chain
#   poison       a thrown flask that shatters into a lingering poison cloud
#   rocket       homing rockets that turn after their target, retarget, explode
#   bomb         mines dropped at your feet as you go; they arm, then blow on contact
#   ghost        a ghost that blinks from enemy to enemy, through walls
#   rail         a sniper shot: instant, across the range, through every enemy in line
# and twelve new ones:
#   halo         a constant damage field around you
#   orbit-lids   pot lids orbiting you, knocking back what they touch
#   fire-trail   burning footprints left behind you
#   frost-trail  icy footprints: slow builds up, then freezes
#   dice         a thrown die: damage times the roll, a six explodes
#   blood-pump   pulses that spend some of your health for a big blast
#   whip         a long noodle whip in a wide cone; the tip hits harder
#   snip-knife   very fast short slashes that finish off weak enemies
#   katana       a long narrow slash with extra crit chance
#   scythe       a sweep almost all the way round you
#   hero-blade   a slash that also throws a flying wave of light
#   grudge-blade slashes front and back, stronger with every kill this run

const PASSIVE=["halo","orbit-lids","fire-trail","frost-trail","bomb"]
const MOVERS=["fire-trail","frost-trail","bomb"]  # work best on the move (weapon_review walks)
const MELEE={
	"whip":{"dot":.35,"tip":1.6,"push":1.6,"color":"c97aff"},
	"snip-knife":{"dot":.5,"execute":.1,"color":"d8e0ee"},
	"katana":{"dot":.93,"crit":.15,"color":"e8f4ff"},
	"scythe":{"dot":-.75,"color":"9fe0c0"},
	"hero-blade":{"dot":.4,"wave":true,"color":"ffe98a"},
	"grudge-blade":{"dot":.4,"both":true,"grudge":true,"color":"b04060"},
}
# Weapons fired by the usual clock that are handled here.
const ACTIVE=["flame","lightning","poison","rocket","ghost","rail","dice","blood-pump"]
# These keep the old thrown projectile (their own design: bottles that burst).
const KEEP=["bottle-barrage"]
# Per-tick numbers merge into one running total at the weapon's slot.
const MERGED=["halo","fire-trail","frost-trail","orbit-lids","flame"]
const FLAME_PACE=.34  # the flamethrower ticks three times as often, a third as hard

static var live=[]
static var state={}

static func clear():
	for item in live:
		if is_instance_valid(item.get("node")): item.node.queue_free()
	live.clear()
	for id in state:
		for key in ["halo","lids"]:
			var value=state[id].get(key)
			if value is Node and is_instance_valid(value): value.queue_free()
			elif value is Array:
				for n in value:
					if is_instance_valid(n): n.queue_free()
	state.clear()

static func owns(weapon: Dictionary) -> bool:
	var kind=ContentExpansion.kind(str(weapon.id))
	return not str(weapon.id) in KEEP and (kind in PASSIVE or kind in ACTIVE or MELEE.has(kind))

static func passive(weapon: Dictionary) -> bool:
	return not str(weapon.id) in KEEP and ContentExpansion.kind(str(weapon.id)) in PASSIVE

static func merged(weapon_id: String) -> bool: return ContentExpansion.kind(weapon_id) in MERGED

# Seconds between attacks, as a share of the usual 1/(rate*stat rate).
static func pace(weapon: Dictionary) -> float:
	return FLAME_PACE if ContentExpansion.kind(str(weapon.id))=="flame" and not str(weapon.id) in KEEP else 1.0

static func mods(weapon: Dictionary) -> Dictionary: return weapon.get("modifiers",{})

static func count(g,weapon: Dictionary,cap: int=4) -> int:
	return 1+int(mods(weapon).get("extraShots",0))+mini(cap,int(g.stats.multishot))

static func size(g) -> float: return clampf(float(g.stat("size")),.5,3.0)

static func duration(g) -> float: return maxf(.2,float(g.stats.get("duration",1.0)))

static func base(g,weapon: Dictionary) -> float:
	var kind=ContentExpansion.kind(str(weapon.id))
	return g.stat("damage")*float(weapon.damage)*float(weapon.get("power",1.0))*float(g.stats.get(kind+"Power",1.0))

# One weapon hit with a crit roll, through the usual hit path (statuses, lifesteal).
static func strike(g,enemy: Dictionary,weapon: Dictionary,kind: String,damage: float,crit_bonus: float=0.0):
	if enemy.dead: return
	var critical=g.rules.rng.randf()<g.stat("crit")+crit_bonus
	if critical: g.career.bump("crits")
	g.hit_enemy(enemy,{"kind":kind,"weapon_id":str(weapon.id),"critical":critical,"damage":damage*(g.stat("critPower") if critical else 1.0),"payload":mods(weapon).get("payload","")})

static func in_range(g,origin: Vector3,reach: float) -> Array:
	return g.enemies.filter(func(e):return not e.dead and is_instance_valid(e.node) and origin.distance_to(g.melee_contact(e,origin))<reach)

static func spark(g,at: Vector3,velocity: Vector3,color: Color,life: float,scale: float=1.0):
	if g.effects.size()>260: return
	var node=g.shape(g.orb_mesh,color,g,at,2.2);node.scale=Vector3.ONE*scale
	g.effects.append({"node":node,"life":life,"velocity":velocity})

# --- Weapons fired by the usual clock ------------------------------------------

static func fire(g,weapon: Dictionary,kind: String,origin: Vector3,target: Dictionary,damage: float,reach: float) -> bool:
	if str(weapon.id) in KEEP: return false
	if MELEE.has(kind): melee(g,weapon,kind,origin,target,damage,reach);return true
	match kind:
		"flame": flamethrower(g,weapon,origin,target,damage*FLAME_PACE,reach)
		"lightning": sky_bolts(g,weapon,damage,reach)
		"poison": throw_lobs(g,weapon,origin,damage,reach,"flask")
		"dice": throw_lobs(g,weapon,origin,damage,reach,"dice")
		"rocket": rockets(g,weapon,origin,target,damage)
		"ghost": ghost(g,weapon,origin,target,damage)
		"rail": sniper(g,weapon,origin,damage,reach)
		"gun": bullet_stream(g,weapon,origin,target,damage,reach)
		"shotgun": shotgun_shot(g,weapon,origin,target,damage,reach)
		"harpoon": harpoon_shot(g,weapon,origin,target,damage,reach)
		"blood-pump": blood_pulse(g,weapon,damage)
		_: return false
	return true

static func flamethrower(g,weapon: Dictionary,origin: Vector3,target: Dictionary,damage: float,reach: float):
	var aim=g.enemy_center(target)-origin;aim.y=0;aim=aim.normalized()
	var length=minf(reach,7.0)*sqrt(size(g))
	var widen=1+int(mods(weapon).get("extraShots",0))+mini(3,int(g.stats.multishot))
	var dot=cos(clampf(deg_to_rad(26.0+8.0*widen)*size(g),.3,1.4))
	for enemy in in_range(g,origin,length):
		var to=g.melee_contact(enemy,origin)-origin;to.y=0
		if to.length()<.8 or to.normalized().dot(aim)>dot: strike(g,enemy,weapon,"flame",damage)
	var hot=PowerIcon.color_for("flame")
	for i in range(5):
		var spread=g.rules.rng.randf_range(-1,1)*acos(dot)
		var v=aim.rotated(Vector3.UP,spread)*g.rules.rng.randf_range(9,13)*length/7.0+Vector3.UP*g.rules.rng.randf_range(.5,2.5)
		spark(g,origin+aim*.4,v,hot if i%2==0 else Color("ffd56b"),.42,1.4)

static func sky_bolts(g,weapon: Dictionary,damage: float,reach: float):
	var pool=in_range(g,g.player.position,reach)
	pool.shuffle()
	var hit_count=0
	for enemy in pool:
		if hit_count>=count(g,weapon,5)+int(mods(weapon).get("extraPierce",0)): break
		hit_count+=1
		var at=g.enemy_center(enemy)
		CombatInk.beam(g,at+Vector3.UP*26+Vector3(g.rules.rng.randf_range(-3,3),0,g.rules.rng.randf_range(-3,3)),at,PowerIcon.color_for("lightning"),true,1.6)
		CombatInk.star(g,Vector3(at.x,enemy.node.position.y+.2,at.z),1.6*sqrt(size(g)),Color("fff27d"),8.0,.2)
		strike(g,enemy,weapon,"lightning",damage)
		# A little splash where it lands.
		for other in in_range(g,Vector3(at.x,enemy.node.position.y,at.z),1.6*sqrt(size(g))):
			if other!=enemy: g.hurt_enemy(other,damage*.35,"lightning",str(weapon.id))

static func throw_lobs(g,weapon: Dictionary,origin: Vector3,damage: float,reach: float,what: String):
	var pool=in_range(g,g.player.position,reach)
	if pool.is_empty(): return
	pool.shuffle()
	for i in range(count(g,weapon,3)):
		var enemy=pool[i%pool.size()]
		var to: Vector3=enemy.node.position+Vector3(g.rules.rng.randf_range(-1,1),0,g.rules.rng.randf_range(-1,1))*(.4 if i<pool.size() else 1.6)
		to.y=g.world.height_at(to.x,to.z)
		var node: Node3D
		if what=="flask":
			node=Node3D.new();g.add_child(node)
			ToonArt.ball(node,Color("8fff5a"),Vector3.ZERO,Vector3(.36,.42,.36));ToonArt.ball(node,Color("a86a3a"),Vector3(0,.26,0),Vector3(.14,.14,.14))
		else:
			node=MeshInstance3D.new();var cube=BoxMesh.new();cube.size=Vector3.ONE*.5;node.mesh=cube;node.material_override=g.material(Color("fff6e6"),.4);g.add_child(node)
		node.position=origin
		live.append({"type":"lob","what":what,"node":node,"from":origin,"to":to,"t":0.0,"dur":clampf(origin.distance_to(to)/16.0,.35,.8),"damage":damage,"weapon":weapon,"target":enemy})

static func rockets(g,weapon: Dictionary,origin: Vector3,target: Dictionary,damage: float):
	var n=count(g,weapon,6)
	for i in range(n):
		var node=Node3D.new();g.add_child(node);node.position=origin
		ToonArt.ball(node,Color("ff6a4a"),Vector3.ZERO,Vector3(.22,.22,.6));ToonArt.ball(node,Color("ffd27a"),Vector3(0,0,.32),Vector3(.18,.18,.2))
		var side=(i-(n-1)*.5)*.7
		var up=Vector3.UP*4.0+(g.enemy_center(target)-origin).normalized().rotated(Vector3.UP,side)*6.0
		live.append({"type":"rocket","node":node,"velocity":up,"target":target,"life":3.2,"damage":damage,"weapon":weapon})

static func ghost(g,weapon: Dictionary,origin: Vector3,target: Dictionary,damage: float):
	var node=g.shape(g.orb_mesh,PowerIcon.color_for("ghost"),g,origin,2.4);node.scale=Vector3.ONE*3.2
	live.append({"type":"ghost","node":node,"hops":3+int(mods(weapon).get("extraShots",0))+mini(5,int(g.stats.multishot))+int(mods(weapon).get("extraPierce",0)),"timer":0.0,"visited":[],"damage":damage,"weapon":weapon,"next":target})

# The sniper: the toughest enemy in range (bosses first), instantly, through
# everything on the line.
static func sniper(g,weapon: Dictionary,origin: Vector3,damage: float,reach: float):
	var best={};var best_hp=-1.0
	for enemy in in_range(g,g.player.position,reach):
		var score=float(enemy.hp)+(1e9 if enemy.boss else 0.0)
		if score>best_hp and g.target_visible(origin,g.enemy_center(enemy)): best=enemy;best_hp=score
	if best.is_empty(): return
	var aim=(g.enemy_center(best)-origin).normalized()
	var end=origin+aim*reach*1.2
	g.beam(origin,end,PowerIcon.color_for("rail"))
	for enemy in in_range(g,origin,reach*1.2):
		var c: Vector3=g.enemy_center(enemy);var t=(c-origin).dot(aim)
		if t<0: continue
		if (origin+aim*t).distance_to(c)<float(enemy.get("radius",.6))+.5*sqrt(size(g)): strike(g,enemy,weapon,"rail",damage)

static func bullet_stream(g,weapon: Dictionary,origin: Vector3,target: Dictionary,damage: float,reach: float):
	# Gun: single piercing bullet that hits ALL enemies along its path
	var aim=(g.enemy_center(target)-origin).normalized()
	var node=MeshInstance3D.new()
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mesh=CylinderMesh.new()
	mesh.top_radius=0.035;mesh.bottom_radius=0.035;mesh.height=0.18
	mesh.radial_segments=6;mesh.rings=2
	node.mesh=mesh
	var mat=StandardMaterial3D.new()
	mat.albedo_color=Color("e8c88a")
	mat.metallic=0.5;mat.roughness=0.4
	node.material_override=mat
	node.position=origin
	var pierce=int(g.stats.pierce)+int(mods(weapon).get("extraPierce",0))
	g.projectiles.append({"node":node,"velocity":aim*g.stat("projectileSpeed"),"damage":damage,"critical":false,"life":reach/g.stat("projectileSpeed")+0.25,"kind":"gun","weapon_id":weapon.id,"payload":mods(weapon).get("payload",""),"area_scale":1.0,"hit":[],"hit_radius":0.08*minf(2.5,g.stat("size")),"pierce":pierce,"bounce":0,"return":false,"return_clock":0.55})
	node.scale=Vector3.ONE*1.2*g.stat("size")
	node.look_at(origin+aim)
	ShotFx.muzzle(g,origin,aim,"gun")

static func shotgun_shot(g,weapon: Dictionary,origin: Vector3,target: Dictionary,damage: float,reach: float):
	# Shotgun: multiple pellets with spread, each hits one enemy
	var aim=g.enemy_center(target)-origin;aim.y=0;aim=aim.normalized()
	var count=3+mini(4,int(g.stats.multishot))+int(mods(weapon).get("extraShots",0))
	var color=PowerIcon.color_for("gun")
	for i in range(count):
		var spread=(i-(count-1)*0.5)*0.18
		var vel=aim.rotated(Vector3.UP,spread)*g.stat("projectileSpeed")
		var node=MeshInstance3D.new()
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mesh=SphereMesh.new()
		mesh.radius=0.06
		node.mesh=mesh
		var mat=StandardMaterial3D.new()
		mat.albedo_color=color
		mat.metallic=0.3;mat.roughness=0.6
		node.material_override=mat
		node.position=origin
		g.projectiles.append({"node":node,"velocity":vel,"damage":damage*0.6,"critical":false,"life":reach/g.stat("projectileSpeed")+0.25,"kind":"shotgun","weapon_id":weapon.id,"payload":"","area_scale":1.0,"hit":[],"hit_radius":0.12,"pierce":0,"bounce":0,"return":false,"return_clock":0.55})
		node.scale=Vector3.ONE*0.9
		node.look_at(origin+vel)
	ShotFx.muzzle(g,origin,aim,"shotgun")

static func harpoon_shot(g,weapon: Dictionary,origin: Vector3,target: Dictionary,damage: float,reach: float):
	# Harpoon: long fast piercing projectile
	var aim=(g.enemy_center(target)-origin).normalized()
	var node=MeshInstance3D.new()
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var shaft=CylinderMesh.new()
	shaft.top_radius=0.025;shaft.bottom_radius=0.025;shaft.height=0.5
	shaft.radial_segments=6;shaft.rings=2
	var shaft_node=MeshInstance3D.new()
	shaft_node.mesh=shaft
	var mat1=StandardMaterial3D.new()
	mat1.albedo_color=Color("a0b0c0")
	mat1.metallic=0.6;mat1.roughness=0.3
	shaft_node.material_override=mat1
	node.add_child(shaft_node)
	var head=ConeMesh.new()
	head.radius=0.06;head.height=0.15
	var head_node=MeshInstance3D.new()
	head_node.mesh=head
	var mat2=StandardMaterial3D.new()
	mat2.albedo_color=Color("c0c8d0")
	mat2.metallic=0.7;mat2.roughness=0.2
	head_node.material_override=mat2
	head_node.position.y=0.32
	node.add_child(head_node)
	node.position=origin
	var pierce=int(g.stats.pierce)+int(mods(weapon).get("extraPierce",0))+5
	g.projectiles.append({"node":node,"velocity":aim*g.stat("projectileSpeed")*1.3,"damage":damage,"critical":false,"life":reach/g.stat("projectileSpeed")+0.25,"kind":"harpoon","weapon_id":weapon.id,"payload":"","area_scale":1.0,"hit":[],"hit_radius":0.15,"pierce":pierce,"bounce":0,"return":false,"return_clock":0.55})
	node.scale=Vector3.ONE*2.5
	node.look_at(origin+aim)
	ShotFx.muzzle(g,origin,aim,"harpoon")

static func blood_pulse(g,weapon: Dictionary,damage: float):
	var spent=0.0
	if g.hp>g.stats.maxHp*.3: spent=g.hp*.04;g.hp-=spent
	var radius=4.5*sqrt(size(g))
	var power=damage*(.7+spent*.12)
	var before=g.enemies.filter(func(e):return not e.dead and g.player.position.distance_to(g.melee_contact(e,g.player.position))<radius)
	for enemy in before: strike(g,enemy,weapon,"blood-pump",power)
	for enemy in before:
		if enemy.dead and g.rules.rng.randf()<.05: g.stats.maxHp+=1;g.hp+=1
	CombatInk.wave(g,g.player.position+Vector3.UP*.2,radius,Color("e8384f"))
	g.burst(g.player.position+Vector3.UP,Color("e8384f"),6)

static func melee(g,weapon: Dictionary,kind: String,origin: Vector3,target: Dictionary,damage: float,reach: float):
	var spec: Dictionary=MELEE[kind]
	var at=g.player.position+Vector3.UP*.9
	var aim=g.enemy_center(target)-at;aim.y=0;aim=aim.normalized()
	if kind=="grudge-blade": damage*=1.0+float(g.kills)*.0015
	var r=reach*sqrt(size(g))
	var aims=[aim,-aim] if spec.get("both",false) else [aim]
	for direction in aims:
		var swing={"origin":at,"target":at+direction*r*.8,"aim":direction,"reach":r,"damage":damage,"delay":.05,"weapon_id":str(weapon.id),"payload":mods(weapon).get("payload",""),"sweep_dot":spec.dot}
		for key in ["tip","push","execute","crit"]:
			if spec.has(key): swing[key]=spec[key]
		if kind=="snip-knife": swing.execute=minf(.2,.1+.02*(int(weapon.get("rank",1))-1))
		g.melee_attacks.append(swing)
	g.sound.effect("slash",at)
	var color=Color(str(spec.color))
	if kind=="scythe": CombatInk.wave(g,Vector3(at.x,g.player.position.y+.3,at.z),r,color)
	elif kind=="whip":
		for i in range(9):
			var f=float(i+1)/9.0;var bend=aim.rotated(Vector3.UP,sin(f*PI)*.35)
			spark(g,at+bend*r*f,Vector3.UP*.5,color,.28,1.6+f)
	if spec.get("wave",false):
		var node=Node3D.new();g.add_child(node);node.position=at
		ToonArt.ball(node,color,Vector3.ZERO,Vector3(1.6,.25,.5)*sqrt(size(g)))
		node.look_at(at+aim,Vector3.UP)
		live.append({"type":"wave","node":node,"velocity":aim*16.0,"life":maxf(.4,reach*1.6/16.0),"damage":damage*.7,"weapon":weapon,"hit":{}})

# --- Every frame ------------------------------------------------------------------

static func tick(g,delta: float):
	var ids={}
	for weapon in g.equipped: ids[str(weapon.id)]=true
	for id in state.keys():
		if not ids.has(id): drop_state(id)
	var resting=g.underside.active() or g.update.downed or g.hp<=0
	for weapon in g.equipped:
		if not passive(weapon): continue
		var kind=ContentExpansion.kind(str(weapon.id))
		var s: Dictionary=state.get(str(weapon.id),{})
		state[str(weapon.id)]=s
		match kind:
			"halo": halo(g,weapon,s,delta,resting)
			"orbit-lids": lids(g,weapon,s,delta,resting)
			"fire-trail","frost-trail": trail(g,weapon,kind,s,delta,resting)
			"bomb": mines(g,weapon,s,delta,resting)
	advance(g,delta)

static func drop_state(id: String):
	var s: Dictionary=state[id]
	if s.get("halo") is Node and is_instance_valid(s.halo): s.halo.queue_free()
	for n in s.get("lids",[]):
		if is_instance_valid(n): n.queue_free()
	state.erase(id)

static func rate(g,weapon: Dictionary) -> float: return maxf(.1,float(weapon.rate)*float(g.stat("rate")))

static func halo(g,weapon: Dictionary,s: Dictionary,delta: float,resting: bool):
	var radius=3.2*sqrt(size(g))
	if not s.has("halo") or not is_instance_valid(s.halo):
		s.halo=GroundRing.make(g,Vector3.ZERO,1.0,Color("b48cf2"),.2,false);g.add_child(s.halo)
	s.halo.visible=not resting
	s.halo.position=g.player.position+Vector3.UP*.05;s.halo.scale=Vector3(radius,1,radius)
	if resting: return
	s.tick=float(s.get("tick",0.0))-delta
	if s.tick>0: return
	s.tick=.25/rate(g,weapon)
	var damage=base(g,weapon)*.3
	for enemy in in_range(g,g.player.position,radius): g.hurt_enemy(enemy,damage,"aura",str(weapon.id))

static func lids(g,weapon: Dictionary,s: Dictionary,delta: float,resting: bool):
	var n=2+int(mods(weapon).get("extraShots",0))+mini(4,int(g.stats.multishot))
	var nodes: Array=s.get("lids",[])
	while nodes.size()<n:
		var lid=Node3D.new();g.add_child(lid)
		ToonArt.ball(lid,Color("c9d2dc"),Vector3.ZERO,Vector3(.9,.14,.9));ToonArt.ball(lid,Color("3a3040"),Vector3(0,.12,0),Vector3(.2,.12,.2))
		nodes.append(lid)
	while nodes.size()>n:
		var extra=nodes.pop_back()
		if is_instance_valid(extra): extra.queue_free()
	s.lids=nodes
	s.angle=fmod(float(s.get("angle",0.0))+delta*2.6*sqrt(rate(g,weapon)),TAU)
	var radius=2.4*sqrt(size(g))
	var hits: Dictionary=s.get("hits",{});s.hits=hits
	var damage=base(g,weapon)*.6
	for i in range(nodes.size()):
		var lid: Node3D=nodes[i]
		lid.visible=not resting
		var a=float(s.angle)+i*TAU/nodes.size()
		lid.position=g.player.position+Vector3(cos(a),0,sin(a))*radius+Vector3.UP*.9
		lid.rotation.y=-a;lid.scale=Vector3.ONE*sqrt(size(g))
		if resting: continue
		for enemy in in_range(g,lid.position,.55*sqrt(size(g))):
			var key=int(enemy.net_id)
			if g.elapsed<float(hits.get(key,-9.0)): continue
			hits[key]=g.elapsed+.35
			strike(g,enemy,weapon,"orbit-lids",damage)
			if not enemy.dead and not enemy.boss:
				var away=enemy.node.position-g.player.position;away.y=0
				enemy.node.move_and_collide(away.normalized()*1.2)
	if hits.size()>200: hits.clear()

static func trail(g,weapon: Dictionary,kind: String,s: Dictionary,delta: float,resting: bool):
	if resting: return
	s.clock=float(s.get("clock",0.0))-delta
	if s.clock>0: return
	s.clock=.22/sqrt(rate(g,weapon))
	var feet: Vector3=g.player.position
	var last: Vector3=s.get("last",Vector3.INF)
	if last!=Vector3.INF and last.distance_to(feet)<1.2*sqrt(size(g)): return
	s.last=feet
	var radius=1.5*sqrt(size(g))
	var p=Vector3(feet.x,g.world.height_at(feet.x,feet.z),feet.z)
	var node: Node3D
	if kind=="fire-trail": node=AreaVisual.make(g,"ignited",radius,p)
	else:
		node=GroundRing.make(g,p,radius,Color("9fe9ff"),.32);g.add_child(node);node.position=p
	live.append({"type":kind,"node":node,"life":3.0*duration(g),"radius":radius,"damage":base(g,weapon)*.32,"weapon":weapon,"tick":0.0})
	var mine=live.filter(func(item):return item.type==kind)
	if mine.size()>40:
		mine[0].life=0.0

static func mines(g,weapon: Dictionary,s: Dictionary,delta: float,resting: bool):
	if resting: return
	s.clock=float(s.get("clock",0.0))-delta
	if s.clock>0: return
	s.clock=1.0/rate(g,weapon)
	var back=-Vector3(g.player.velocity.x,0,g.player.velocity.z).normalized()
	if back.length()<.1: back=Vector3.BACK.rotated(Vector3.UP,g.rules.rng.randf()*TAU)
	for i in range(count(g,weapon,3)):
		var p: Vector3=g.player.position+back.rotated(Vector3.UP,(i-.5)*1.1)*(1.2+i*.6)
		p.y=g.world.height_at(p.x,p.z)
		var node=Node3D.new();g.add_child(node);node.position=p
		ToonArt.ball(node,Color("2a2340"),Vector3(0,.12,0),Vector3(.62,.26,.62))
		var light=ToonArt.ball(node,Color("ff3b3b"),Vector3(0,.28,0),Vector3(.14,.1,.14))
		live.append({"type":"mine","node":node,"light":light,"arm":clampf(float(mods(weapon).get("fuse",.5)),.25,1.0),"life":10.0*duration(g),"damage":base(g,weapon),"radius":3.2*float(g.stats.get("bombSize",1.0))*float(mods(weapon).get("areaScale",1.0))*sqrt(size(g)),"weapon":weapon})
	var all=live.filter(func(item):return item.type=="mine")
	for i in range(maxi(0,all.size()-18)): all[i].life=0.0

static func advance(g,delta: float):
	for item in live:
		if not is_instance_valid(item.get("node")): item.life=0.0;continue
		match item.type:
			"lob":
				item.t+=delta
				var f=clampf(item.t/item.dur,0,1)
				item.node.position=item.from.lerp(item.to,f)+Vector3.UP*sin(f*PI)*maxf(2.0,item.from.distance_to(item.to)*.3)
				item.node.rotation+=Vector3(7,5,3)*delta
				if f>=1: land(g,item);item.life=0.0
				else: item.life=1.0
			"rocket":
				item.life-=delta
				var target: Dictionary=item.target
				if target.is_empty() or target.dead or not is_instance_valid(target.get("node")):
					item.target=g.nearest_enemy(item.node.position,30.0);target=item.target
				var speed=float(g.stat("projectileSpeed"))*.75
				if not target.is_empty():
					var want=(g.enemy_center(target)-item.node.position).normalized()*speed
					item.velocity=item.velocity.lerp(want,1-exp(-delta*4.5))
					if item.node.position.distance_to(g.enemy_center(target))<float(target.get("radius",.6))+.7:
						strike(g,target,item.weapon,"rocket",item.damage);g.burst(item.node.position,Color("ff955c"),6);item.life=0.0
				item.node.position+=item.velocity*delta
				if item.velocity.length()>.1: item.node.look_at(item.node.position+item.velocity,Vector3.UP)
				spark(g,item.node.position,Vector3.ZERO,Color("ffd27a"),.2,.8)
			"ghost":
				item.timer-=delta
				if item.timer>0: continue
				item.timer=.12
				var next: Dictionary=item.next
				if next.is_empty() or next.dead or item.visited.has(next.net_id):
					# Through walls: nearest by distance alone.
					next={};var best=11.0
					for enemy in g.enemies:
						if enemy.dead or item.visited.has(enemy.net_id): continue
						var d=item.node.position.distance_to(g.enemy_center(enemy))
						if d<best: best=d;next=enemy
				if next.is_empty() or item.hops<=0: item.life=0.0;continue
				item.visited.append(next.net_id);item.hops-=1
				var from: Vector3=item.node.position
				item.node.position=g.enemy_center(next)
				CombatInk.beam(g,from,item.node.position,PowerIcon.color_for("ghost"),false,.6)
				strike(g,next,item.weapon,"ghost",item.damage)
				item.next={};item.life=1.0
			"wave":
				item.life-=delta
				item.node.position+=item.velocity*delta
				for enemy in in_range(g,item.node.position,1.4*sqrt(size(g))):
					if item.hit.has(enemy.net_id): continue
					item.hit[enemy.net_id]=true;strike(g,enemy,item.weapon,"hero-blade",item.damage)
			"fire-trail","frost-trail":
				item.life-=delta;item.tick-=delta
				if item.tick>0: continue
				item.tick=.25
				for enemy in in_range(g,item.node.position,item.radius):
					if item.type=="fire-trail":
						g.hurt_enemy(enemy,item.damage,"fire",str(item.weapon.id))
						if not enemy.dead: g.set_damage_status(enemy,"fire",6.0+float(g.stats.burn),g.coop.local_id);enemy.status_time=maxf(float(enemy.get("status_time",0)),2.0)
					else:
						g.hurt_enemy(enemy,item.damage*.7,"ice",str(item.weapon.id))
						if enemy.dead: continue
						enemy.slow=maxf(float(enemy.get("slow",0)),.45)
						enemy.frost=float(enemy.get("frost",0.0))+.25
						if enemy.frost>=1.0: enemy.frost=0.0;enemy.freeze=maxf(float(enemy.get("freeze",0)),.35 if enemy.boss else 1.2);g.career.bump("freezes")
						enemy.status_time=maxf(float(enemy.get("status_time",0)),1.0)
				if item.life<.5 and item.node is Node3D: item.node.scale=Vector3.ONE*maxf(.05,item.life/.5)
			"mine":
				item.life-=delta;item.arm-=delta
				if is_instance_valid(item.light): item.light.visible=item.arm>0 or fmod(g.elapsed,.5)<.25
				if item.arm>0: continue
				for enemy in g.enemies:
					if enemy.dead or not is_instance_valid(enemy.node): continue
					if item.node.position.distance_to(g.melee_contact(enemy,item.node.position))<1.1:
						g.damage_area(item.node.position+Vector3.UP*.3,item.radius,item.damage,"explosion",{},str(item.weapon.id))
						g.sound.effect("blast",item.node.position);item.life=0.0;break
	for item in live:
		if item.life<=0 and is_instance_valid(item.get("node")): item.node.queue_free()
	live=live.filter(func(item):return item.life>0)

static func land(g,item: Dictionary):
	var p: Vector3=item.to
	if item.what=="visual": return
	if item.what=="flask":
		var radius=2.6*sqrt(size(g))*float(mods(item.weapon).get("areaScale",1.0))
		var node=AreaVisual.make(g,"poison",radius,p)
		g.pools.append({"node":node,"life":3.5*duration(g),"radius":radius,"damage":item.damage*.8,"mechanic":str(item.weapon.id),"toxic":true,"tick":0.0})
		g.burst(p+Vector3.UP*.5,Color("8fff5a"),6);g.sound.effect("poison",p)
		return
	# The die: damage times the roll; luck can roll it again and keep the better.
	var roll=g.rules.rng.randi_range(1,6)
	if g.rules.rng.randf()<float(g.stat("luck"))*.5: roll=maxi(roll,g.rules.rng.randi_range(1,6))
	var target: Dictionary=item.target
	var power=item.damage*roll*.55
	if not target.is_empty() and not target.dead and p.distance_to(target.node.position)<2.5: strike(g,target,item.weapon,"dice",power)
	else: g.damage_area(p,1.2,power,"hit",{},str(item.weapon.id))
	if roll==6: g.damage_area(p,2.8*sqrt(size(g)),item.damage*2.0,"explosion",{},str(item.weapon.id))
	CombatInk.star(g,p+Vector3.UP*.4,.6+roll*.25,Color("ffe98a") if roll==6 else Color("fff6e6"),float(roll+2),.3)
	g.sound.effect("pop",p)

# --- Co-op: what friends see of my attacks (game.remote_weapon_effect) ----------

static func remote(g,id: String,origin: Vector3,target: Vector3) -> bool:
	var kind=ContentExpansion.kind(id)
	if id in KEEP: return false
	if kind=="lightning":
		CombatInk.beam(g,target+Vector3.UP*26,target,PowerIcon.color_for("lightning"),true,1.6);return true
	if kind=="flame":
		var aim=target-origin;aim.y=0;aim=aim.normalized()
		for i in range(4): spark(g,origin+aim*.4,aim.rotated(Vector3.UP,g.rules.rng.randf_range(-.5,.5))*11+Vector3.UP,PowerIcon.color_for("flame"),.4,1.4)
		return true
	if kind=="poison" or kind=="dice":
		var to=target;to.y=g.world.height_at(to.x,to.z)
		var node=g.shape(g.orb_mesh,Color("8fff5a") if kind=="poison" else Color("fff6e6"),g,origin,1.0);node.scale=Vector3.ONE*3
		live.append({"type":"lob","what":"visual","node":node,"from":origin,"to":to,"t":0.0,"dur":.5,"damage":0.0,"weapon":{},"target":{}})
		return true
	if MELEE.has(kind): g.slash_fx(origin,target);return true
	return false

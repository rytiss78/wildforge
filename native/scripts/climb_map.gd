extends RefCounted
class_name ClimbMap

# Big update MB, part 3 (user, November 2: "exploring maps should be like
# Megabonk: climb, jump, try to reach all the chests in time; the underworld
# must still exist"). Every biome map gets raised mesas with steep sides that
# a hero cannot simply walk up. Each is reached one of three ways:
#   ramp      a long sloped path up one side
#   steps     a spiral of stone pillars, each one jump higher than the last
#   pad       a glowing launch pad at the foot that throws the hero up
# A chest waits on top of every mesa, so the map is a race to reach them all
# before the clock runs out. Mesas are part of the terrain height (so drops,
# enemies and spawns follow them); the pillars and pads are separate pieces.
# The Red Moon arena has none.

const MESAS=10
const EDGE=3.0          # how wide a mesa's steep side is
const STEP=1.1          # pillar rise per step, under one plain jump (~1.5 m)
const PILLAR_RADIUS=1.5
const PAD_RADIUS=1.6

static func plan(world) -> Array:
	# Labyrinth maps climb their own terraces instead.
	if world.realm>=RealmWorld.ARENA or Labyrinth.active(world.realm): return []
	var rng=RandomNumberGenerator.new();rng.seed=int(world.seed_value)*13+int(world.realm)*977+5
	var mesas=[];var tries=0
	while mesas.size()<MESAS and tries<400:
		tries+=1
		var angle=rng.randf()*TAU;var edge=Vector3(cos(angle),0,sin(angle))
		var coast=RealmWorld.coast_radius(angle,world.seed_value,world.realm)
		var radius=rng.randf_range(15.0,24.0)
		var distance=rng.randf_range(60.0,coast-radius-60.0)
		var center=Vector2(edge.x,edge.z)*distance
		if mesas.any(func(m):return m.center.distance_to(center)<m.radius+radius+26.0): continue
		var near_landmark=false
		for slot in range(RealmWorld.BIOME_COUNT):
			var a=(slot+.5)*RealmWorld.BIOME_ARC-float(world.seed_value%23)*.03-world.realm*.4
			if center.distance_to(Vector2(cos(a),sin(a))*175.0)<radius+30.0: near_landmark=true
		if near_landmark: continue
		# Keep the walking routes between areas clear (RealmWorld.crossing_distance).
		if world.crossing_distance(Vector3(center.x,0,center.y))<radius+30.0: continue
		var kind=["ramp","steps","pad"][mesas.size()%3]
		var height=rng.randf_range(6.0,10.0) if kind=="steps" else rng.randf_range(8.0,14.0)
		var out=rng.randf()*TAU
		mesas.append({"center":center,"radius":radius,"height":height,"kind":kind,"dir":Vector2(cos(out),sin(out)),"length":height*2.8})
	return mesas

# Extra height from the mesas (and their ramps) at a point.
static func lift(mesas: Array,x: float,z: float) -> float:
	var best=0.0;var p=Vector2(x,z)
	for mesa in mesas:
		var to: Vector2=p-mesa.center;var d=to.length()
		if d>mesa.radius+mesa.length+8.0: continue
		var h=float(mesa.height)*(1.0-smoothstep(mesa.radius-EDGE,mesa.radius,d))
		if mesa.kind=="ramp":
			var along=to.dot(mesa.dir)-(mesa.radius-EDGE);var side=absf(to.dot(Vector2(-mesa.dir.y,mesa.dir.x)))
			if along>-EDGE and along<mesa.length and side<4.5:
				var slope=float(mesa.height)*clampf(1.0-along/mesa.length,0,1)*(1.0-smoothstep(3.0,4.5,side))
				h=maxf(h,slope)
		best=maxf(best,h)
	return best

# Where the chests go: the middle of every mesa top.
static func tops(world) -> Array:
	var result=[]
	for mesa in world.climb_mesas:
		var p=Vector3(mesa.center.x,0,mesa.center.y);p.y=world.height_at(p.x,p.z)
		result.append(p)
	return result

# Pillars for "steps" mesas and launch pads for "pad" mesas.
static func build_props(world):
	world.climb_pads.clear()
	var stone=StandardMaterial3D.new();stone.albedo_color=RealmWorld.COLORS[RealmWorld.biome_of(world.realm)].lerp(Color("8d8270"),.55);stone.roughness=.95
	var glow=StandardMaterial3D.new();glow.albedo_color=Color("7ff7ff");glow.emission_enabled=true;glow.emission=Color("44e6ff");glow.emission_energy_multiplier=2.2
	for mesa in world.climb_mesas:
		var base=Vector2(mesa.center)+Vector2(mesa.dir)*(float(mesa.radius)+2.5)
		var ground=world.height_at(base.x,base.y)
		if mesa.kind=="steps":
			var count=ceili((float(mesa.height)+.3)/STEP)
			for i in range(count):
				# A spiral round the mesa side, climbing toward its rim.
				var a=atan2(mesa.dir.y,mesa.dir.x)+i*.26
				var r=float(mesa.radius)+2.2+float(count-i)*.35
				var at=Vector2(mesa.center)+Vector2(cos(a),sin(a))*r
				var floor_y=world.height_at(at.x,at.y)
				var top=ground+STEP*(i+1)
				if top<=floor_y+.4: continue
				var body=StaticBody3D.new();body.collision_layer=1;body.name="ClimbPillar"
				var tall=top-floor_y+1.0
				var shape=CollisionShape3D.new();var cylinder=CylinderShape3D.new();cylinder.radius=PILLAR_RADIUS;cylinder.height=tall;shape.shape=cylinder;body.add_child(shape)
				var mesh=MeshInstance3D.new();var tube=CylinderMesh.new();tube.top_radius=PILLAR_RADIUS;tube.bottom_radius=PILLAR_RADIUS*1.12;tube.height=tall;tube.radial_segments=10;mesh.mesh=tube;mesh.material_override=stone;body.add_child(mesh)
				body.position=Vector3(at.x,floor_y-1.0+tall*.5,at.y);world.add_child(body)
		elif mesa.kind=="pad":
			var pad=MeshInstance3D.new();var disc=CylinderMesh.new();disc.top_radius=PAD_RADIUS;disc.bottom_radius=PAD_RADIUS*1.15;disc.height=.25;disc.radial_segments=18
			pad.mesh=disc;pad.material_override=glow;pad.name="LaunchPad";pad.position=Vector3(base.x,ground+.12,base.y);world.add_child(pad)
			var arrow=Label3D.new();arrow.text="⇧";arrow.font_size=160;arrow.pixel_size=.012;arrow.modulate=Color("b8fbff");arrow.billboard=BaseMaterial3D.BILLBOARD_ENABLED;arrow.position=Vector3(0,1.6,0);pad.add_child(arrow)
			var land=Vector2(mesa.center)+Vector2(mesa.dir)*float(mesa.radius)*.35
			world.climb_pads.append({"position":Vector3(base.x,ground,base.y),"target":Vector3(land.x,world.height_at(land.x,land.y),land.y)})

# Standing on a launch pad throws the hero in an arc onto the mesa top: the
# launch speed is worked out so the arc lands there (FLIGHT seconds), and the
# sideways part is held while airborne (the hero can still steer a little).
const FLIGHT=1.3
static var carry=Vector3.ZERO
static var carry_until=-1.0

static func tick(g):
	if carry_until>0:
		if g.elapsed<carry_until and not (g.player.is_on_floor() and g.elapsed>carry_until-FLIGHT+.25): g.knock_velocity=carry
		else: carry_until=-1.0;carry=Vector3.ZERO
	if g.underside.active() or g.update.downed: return
	for pad in g.world.climb_pads:
		var to: Vector3=g.player.position-pad.position
		if Vector2(to.x,to.z).length()<PAD_RADIUS and absf(to.y)<1.2 and g.player.velocity.y<=1.0 and carry_until<0:
			var target: Vector3=pad.target;var rise=target.y+.6-g.player.position.y
			g.player.velocity=Vector3(0,(rise+12.0*FLIGHT*FLIGHT)/FLIGHT,0)
			carry=Vector3(target.x-g.player.position.x,0,target.z-g.player.position.z)/FLIGHT;carry_until=g.elapsed+FLIGHT+.3
			g.knock_velocity=carry
			g.air_jumps=0;g.sound.effect("jump",g.player.position);g.burst(pad.position+Vector3.UP*.4,Color("7ff7ff"),12)
			return

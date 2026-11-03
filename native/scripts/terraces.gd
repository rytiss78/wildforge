extends RefCounted
class_name Terraces

# Megabonk-style terraced stages (user, November 3, with screenshots of
# Megabonk's forest: "you still don't get it"). The maze is the ground itself:
#   * big flat square plateaus (TILE = 32 m, far bigger than the hero) on a few
#     floors FLOOR = 8 m apart
#   * between two plateaus of different height a straight vertical cliff, earth
#     on the side with a grass lip on top; no walls standing on the ground
#   * the way up is a whole tile tilted into a ramp, from its parent plateau's
#     height up (or down) to its own
# Laid out like Megabonk's generator (names from its game files: tile grid,
# random spanning tree, a height walk along the tree with a Gaussian bias toward
# a high middle, slope tiles on the tree's height changes, walls where heights
# differ). Numbers and look are this game's own.
#
# A cliff sits on the lower plateau's side of an edge: the higher plateau
# reaches STRIP metres over it (one terrain vertex step), the terrain mesh
# slopes inside that strip, and a cliff block with collision covers it, so the
# face is vertical.

const TILE=32.0
const FLOOR=8.0
const LEVELS=4
const STRIP=4.0
const VOLATILITY=.5
const BIAS=.6
const LIP=.6
const START_CLEAR=50.0

# n×n tiles from origin; level per tile (-1 outside); slope: index of the tile
# this one ramps up from (-1 flat).
static func plan(seed_value: int,realm: int) -> Dictionary:
	var rng=RandomNumberGenerator.new();rng.seed=seed_value*7+realm*101+3
	var n=int(ceil(700.0/TILE))+2
	# A tile centred on the island's middle (the start).
	var origin=-(float(n/2)*TILE)-TILE*.5
	var level=PackedInt32Array();level.resize(n*n);level.fill(-1)
	var slope=PackedInt32Array();slope.resize(n*n);slope.fill(-1)
	var inside=[]
	for j in range(n):
		for i in range(n):
			var c=Vector2(origin+(i+.5)*TILE,origin+(j+.5)*TILE)
			var coast=RealmWorld.coast_radius(atan2(c.y,c.x),seed_value,realm)
			if c.length()<coast-40.0: inside.append(j*n+i)
	if inside.is_empty(): return {}
	# Start in the middle on the ground floor; grow a random spanning tree.
	var start=inside[0];var best=INF
	for c in inside:
		var d=Vector2(origin+(c%n+.5)*TILE,origin+(c/n+.5)*TILE).length()
		if d<best: best=d;start=c
	var inset={};for c in inside: inset[c]=true
	level[start]=0
	var stack=[start];var seen={start:true}
	while not stack.is_empty():
		var cur=stack[-1];var options=[]
		for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
			var ni=cur%n+d.x;var nj=cur/n+d.y
			if ni<0 or nj<0 or ni>=n or nj>=n: continue
			var nb=nj*n+ni
			if inset.has(nb) and not seen.has(nb): options.append(nb)
		if options.is_empty(): stack.pop_back();continue
		var nxt=options[rng.randi_range(0,options.size()-1)]
		seen[nxt]=true;stack.append(nxt)
		var at=Vector2(origin+(nxt%n+.5)*TILE,origin+(nxt/n+.5)*TILE)
		# Highest in a ring round the middle, falling off toward the coast.
		var target=roundi((LEVELS-1)*exp(-pow((at.length()-90.0)/140.0,2.0)))
		var step=0
		if rng.randf()<VOLATILITY: step=1 if rng.randf()<.5 else -1
		if level[cur]!=target and rng.randf()<BIAS: step=signi(target-level[cur])
		level[nxt]=clampi(level[cur]+step,0,LEVELS-1)
		# A change of floor along the tree: this tile is a ramp from its parent.
		if level[nxt]!=level[cur]:
			if slope[cur]>=0: level[nxt]=level[cur]  # no ramp straight off a ramp
			else: slope[nxt]=cur
	# The start: open flat ground on the ground floor.
	for c in inside:
		if Vector2(origin+(c%n+.5)*TILE,origin+(c/n+.5)*TILE).length()<START_CLEAR: level[c]=0;slope[c]=-1
	return {"terraces":true,"n":n,"origin":origin,"level":level,"slope":slope}

static func tile_at(lab: Dictionary,x: float,z: float) -> Vector2i:
	return Vector2i(int(floor((x-float(lab.origin))/TILE)),int(floor((z-float(lab.origin))/TILE)))

static func index(lab: Dictionary,t: Vector2i) -> int:
	var n: int=lab.n
	if t.x<0 or t.y<0 or t.x>=n or t.y>=n: return -1
	return t.y*n+t.x if lab.level[t.y*n+t.x]>=0 else -1

# The tile's own surface height at a point (clamped into the tile).
static func surface(lab: Dictionary,t: Vector2i,x: float,z: float) -> float:
	var k=index(lab,t)
	if k<0: return 0.0
	var own=float(lab.level[k])*FLOOR
	var from: int=lab.slope[k]
	if from<0: return own
	var n: int=lab.n
	var lo=Vector2(float(lab.origin)+t.x*TILE,float(lab.origin)+t.y*TILE)
	var px=clampf(x,lo.x,lo.x+TILE);var pz=clampf(z,lo.y,lo.y+TILE)
	var parent=Vector2i(from%n,from/n);var base=float(lab.level[from])*FLOOR
	var f=0.0
	if parent.x==t.x-1: f=(px-lo.x)/TILE
	elif parent.x==t.x+1: f=(lo.x+TILE-px)/TILE
	elif parent.y==t.y-1: f=(pz-lo.y)/TILE
	else: f=(lo.y+TILE-pz)/TILE
	return lerpf(base,own,f)

# Height over the flat base: the tile's surface, raised in the strip next to a
# higher neighbour (the cliff block's footprint).
static func lift(lab: Dictionary,x: float,z: float) -> float:
	return probe(lab,x,z).x

static func probe(lab: Dictionary,x: float,z: float) -> Vector2:
	var t=tile_at(lab,x,z)
	if index(lab,t)<0: return Vector2.ZERO
	var h=surface(lab,t,x,z);var top=h
	var lo=Vector2(float(lab.origin)+t.x*TILE,float(lab.origin)+t.y*TILE)
	for edge in [[Vector2i(-1,0),x-lo.x],[Vector2i(1,0),lo.x+TILE-x],[Vector2i(0,-1),z-lo.y],[Vector2i(0,1),lo.y+TILE-z]]:
		if edge[1]>=STRIP: continue
		var other: Vector2i=t+edge[0]
		var there=surface(lab,other,x,z) if index(lab,other)>=0 else 0.0
		if there>h+1.0: top=maxf(top,there)
	return Vector2(top,1.0 if top>h else 0.0)

# Every cliff: 4 m pieces along tile edges where the two sides differ. Each
# piece knows its two ends on the edge line, the side it drops toward, and the
# heights of the high and low side at both ends (so cliffs beside a ramp follow
# its slope instead of stepping).
static func cliffs(lab: Dictionary) -> Array:
	var result=[];var n: int=lab.n
	for j in range(-1,n):
		for i in range(-1,n):
			for d in [Vector2i(1,0),Vector2i(0,1)]:
				var a=Vector2i(i,j);var b=a+d
				if index(lab,a)<0 and index(lab,b)<0: continue
				var along_dir=Vector2(0,1) if d.x==1 else Vector2(1,0)
				var start=Vector2(float(lab.origin)+(i+1)*TILE,float(lab.origin)+j*TILE) if d.x==1 else Vector2(float(lab.origin)+i*TILE,float(lab.origin)+(j+1)*TILE)
				for k in range(int(TILE/STRIP)):
					var e0=start+along_dir*k*STRIP;var e1=e0+along_dir*STRIP;var mid=(e0+e1)*.5
					var ha=side_height(lab,a,mid);var hb=side_height(lab,b,mid)
					if absf(ha-hb)<=1.0: continue
					var high=a if ha>hb else b;var low=b if ha>hb else a
					var normal=Vector2(d.x,d.y)*(1.0 if ha>hb else -1.0)
					result.append({"e0":e0,"e1":e1,"normal":normal,"centre":mid+normal*STRIP*.5,
						"t0":side_height(lab,high,e0),"t1":side_height(lab,high,e1),"l0":side_height(lab,low,e0),"l1":side_height(lab,low,e1),
						"top":maxf(ha,hb),"low":minf(ha,hb)})
	return result

static func side_height(lab: Dictionary,t: Vector2i,p: Vector2) -> float:
	return surface(lab,t,p.x,p.y) if index(lab,t)>=0 else 0.0

static func quad(tool: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3,facing: Vector3):
	# Godot front faces: (v2-v0)x(v1-v0) points out; flip to face `facing`.
	if (c-a).cross(b-a).dot(facing)<0: var t=b;b=d;d=t
	for v in [a,b,c,a,c,d]: tool.add_vertex(v)

static func build(world):
	var lab: Dictionary=world.labyrinth
	var pieces=cliffs(lab)
	if pieces.is_empty(): return
	var root=StaticBody3D.new();root.name="TerraceCliffs";root.collision_layer=1;root.set_meta("terrain",true);world.add_child(root)
	# Earth sides in the map's colours; the top lip is the map's own ground.
	var tone: Color=RealmWorld.COLORS[RealmWorld.biome_of(world.realm)]
	var earth=StandardMaterial3D.new();earth.albedo_texture=load("res://assets/illustrated/terrain-stone-v2.png")
	earth.uv1_triplanar=true;earth.uv1_world_triplanar=true;earth.uv1_scale=Vector3.ONE*.12
	earth.albedo_color=tone.lerp(Color("6b4a32"),.6).darkened(.1);earth.roughness=1.0
	var sides=SurfaceTool.new();sides.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tops=SurfaceTool.new();tops.begin(Mesh.PRIMITIVE_TRIANGLES)
	for piece in pieces:
		var e0: Vector2=piece.e0;var e1: Vector2=piece.e1;var nrm: Vector2=piece.normal
		var f0=e0+nrm*STRIP;var f1=e1+nrm*STRIP
		var base=func(p: Vector2) -> float: return world.height_at(p.x,p.y)-lift(lab,p.x,p.y)
		var b0=float(base.call(f0))+minf(float(piece.l0),float(piece.l1))-2.0;var b1=b0
		var top0=float(base.call(e0))+float(piece.t0);var top1=float(base.call(e1))+float(piece.t1)
		var out=Vector3(nrm.x,0,nrm.y);var along=Vector3(e1.x-e0.x,0,e1.y-e0.y).normalized()
		var F0b=Vector3(f0.x,b0,f0.y);var F1b=Vector3(f1.x,b1,f1.y);var F0t=Vector3(f0.x,top0,f0.y);var F1t=Vector3(f1.x,top1,f1.y)
		var E0b=Vector3(e0.x,b0,e0.y);var E1b=Vector3(e1.x,b1,e1.y);var E0t=Vector3(e0.x,top0,e0.y);var E1t=Vector3(e1.x,top1,e1.y)
		var lip=Vector3(0,-LIP,0)
		quad(sides,F0b,F1b,F1t+lip,F0t+lip,out)       # the cliff face
		quad(sides,E0b,F0b,F0t,E0t,-along)             # end caps (hidden where pieces meet)
		quad(sides,F1b,E1b,E1t,F1t,along)
		quad(tops,E0t+Vector3.UP*.02,E1t+Vector3.UP*.02,F1t+Vector3.UP*.02,F0t+Vector3.UP*.02,Vector3.UP)  # top over the strip
		quad(tops,F0t+lip+out*.02,F1t+lip+out*.02,F1t+out*.02,F0t+out*.02,out)  # grass lip
		var shape=CollisionShape3D.new();var hull=ConvexPolygonShape3D.new()
		hull.points=PackedVector3Array([E0b,E1b,F0b,F1b,E0t,E1t,F0t,F1t]);shape.shape=hull;root.add_child(shape)
	sides.generate_normals();tops.generate_normals()
	var side_mesh=MeshInstance3D.new();side_mesh.mesh=sides.commit();side_mesh.material_override=earth;root.add_child(side_mesh)
	var top_mesh=MeshInstance3D.new();top_mesh.mesh=tops.commit();top_mesh.material_override=world.terrain_material;root.add_child(top_mesh)

# Minimap: 1-4 floors, 9 cliff.
static func cell_kind(lab: Dictionary,x: float,z: float) -> int:
	var t=tile_at(lab,x,z)
	if index(lab,t)<0: return 0
	if probe(lab,x,z).y>0: return 9
	return 1+int(round(surface(lab,t,x,z)/FLOOR))

# Flat ground on the tiles, easing back into the island's hills over 18 m.
static func flatness(lab: Dictionary,x: float,z: float) -> float:
	var t=tile_at(lab,x,z)
	if index(lab,t)>=0: return 1.0
	var nearest=INF
	for dj in [-1,0,1]:
		for di in [-1,0,1]:
			if index(lab,t+Vector2i(di,dj))<0: continue
			var lo=Vector2(float(lab.origin)+(t.x+di)*TILE,float(lab.origin)+(t.y+dj)*TILE)
			nearest=minf(nearest,Vector2(clampf(x,lo.x,lo.x+TILE),clampf(z,lo.y,lo.y+TILE)).distance_to(Vector2(x,z)))
	return 1.0-smoothstep(0.0,18.0,nearest) if nearest<INF else 0.0

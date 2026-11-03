extends RefCounted
class_name Labyrinth

# Multi-floor labyrinth maps (user, November 3: "look at Megabonk's maps: just
# one is flat, the others are more like multi-floor labyrinths; make some of
# yours like that"). Built the way Megabonk's procedural stages are (read from
# the names in its game files: a tile grid, a random spanning-tree maze, a
# height walk along the tree with a Gaussian centre bias, slopes on tree edges
# and walls where heights differ), with this game's own numbers and look:
#   1  a grid of 28 m tiles over the island's middle ring
#   2  a random spanning tree over the tiles (depth-first maze)
#   3  heights walked along the tree: each tile is its parent's floor, one
#      up or one down (volatility), pulled toward a target that is highest
#      near the middle and falls off like a Gaussian, so the island rises
#      into a terraced hill of up to five floors
#   4  a tree edge between two floors is a ramp; any other edge between two
#      floors is a cliff wall; tiles on the same floor are open to each other
# So it is plateaus joined by ramps, a climb to find the way up, not a
# corridor maze.
# Random chests land on every floor, so reaching them means finding the way
# up. It is all terrain height (World.height_at), so monsters, drops and
# the minimap follow it; the walls are too steep to walk up (about 50°).
#
# Laid on the terrain's 4 m vertex grid: cells are 28 m; a wall is the 8 m
# band either side of a closed cell edge; a ramp spans 8 m either side of an
# open edge between floors.

# Two kinds (user, November 3: "I like part of your labyrinth logic, leave one
# map with it, just make it flat"):
#   corridors  Junkyard Planet: one flat floor, a maze of tall scrap walls
#   terraces   Moon Craters, Starfall Space: the Megabonk-style hill of floors
const MAPS=[2,4,6]
const STYLES={2:"terraces",4:"corridors",6:"terraces"}
const CORRIDOR_WALL=5.0
const CELL=28.0
const FLOOR=5.0
# How far a cliff stands above the higher floor (a lip along the edge).
const WALL=.8
const LEVELS=5
const VOLATILITY=.45
const BIAS=.55
const WALL_BAND=4.5
const RAMP=8.0
# A ramp is a doorway: wall jambs this long at both ends of its edge, so ramps
# never meet at a corner.
const JAMB=8.0
const INNER=46.0
const OUTER_FRACTION=.74
static var cache={}

static func active(realm: int) -> bool: return realm in MAPS

# The maze for this run's map (the same on every machine: seeded).
static func plan(seed_value: int,realm: int) -> Dictionary:
	if not active(realm): return {}
	var key=str(seed_value)+":"+str(realm)
	if cache.has(key): return cache[key]
	var rng=RandomNumberGenerator.new();rng.seed=seed_value*7+realm*101+3
	# Terraces fill the whole island like a Megabonk stage (tiles to the coast);
	# the flat corridor maze keeps to the middle ring.
	var terraces=STYLES[realm]=="terraces"
	var outer=345.0 if terraces else 300.0*OUTER_FRACTION
	var n=int(ceil(outer*2/CELL))+2
	var origin=-n*CELL*.5;origin=floorf(origin/4.0)*4.0
	var maze=PackedByteArray();maze.resize(n*n)
	var level=PackedByteArray();level.resize(n*n)
	var east=PackedByteArray();east.resize(n*n)  # open edge to (i+1,j)
	var south=PackedByteArray();south.resize(n*n)  # open edge to (i,j+1)
	var cells=[]
	for j in range(n):
		for i in range(n):
			var c=Vector2(origin+(i+.5)*CELL,origin+(j+.5)*CELL)
			var r=c.length();var coast=RealmWorld.coast_radius(atan2(c.y,c.x),seed_value,realm)
			if r>INNER and r<minf(outer,coast-(48.0 if terraces else 70.0)):
				# Keep the seven landmark groves open ground.
				var near=false
				for slot in range(RealmWorld.BIOME_COUNT):
					var a=(slot+.5)*RealmWorld.BIOME_ARC-float(seed_value%23)*.03-realm*.4
					if c.distance_to(Vector2(cos(a),sin(a))*175.0)<40.0: near=true
				if not near: maze[j*n+i]=1;cells.append(j*n+i)
	# A random depth-first maze; the floor changes now and then along it.
	var seen={};var stack=[]
	if not cells.is_empty():
		var start=cells[rng.randi_range(0,cells.size()-1)];seen[start]=true;stack.append(start);level[start]=0
		while not stack.is_empty():
			var cur=stack[-1];var ci=cur%n;var cj=cur/n
			var options=[]
			for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]:
				var ni=ci+d.x;var nj=cj+d.y
				if ni<0 or nj<0 or ni>=n or nj>=n: continue
				var nb=nj*n+ni
				if maze[nb]==1 and not seen.has(nb): options.append(nb)
			if options.is_empty(): stack.pop_back();continue
			var nxt=options[rng.randi_range(0,options.size()-1)]
			seen[nxt]=true;stack.append(nxt)
			var step=0
			if rng.randf()<VOLATILITY: step=1 if rng.randf()<.5 else -1
			# Gaussian pull toward a hill in the middle.
			var at=Vector2(origin+(nxt%n+.5)*CELL,origin+(nxt/n+.5)*CELL)
			var target=roundi((LEVELS-1)*exp(-pow(at.length()/125.0,2.0)))
			if level[cur]!=target and rng.randf()<BIAS: step=signi(target-int(level[cur]))
			level[nxt]=0 if STYLES[realm]=="corridors" else clampi(int(level[cur])+step,0,LEVELS-1)
			open_edge(east,south,n,cur,nxt)
		# Cells the walk could not reach stay open ground.
		for c in cells:
			if not seen.has(c): maze[c]=0
	# Loops where floors match up, and ways in from the open ground.
	for j in range(n):
		for i in range(n):
			var c=j*n+i
			for d in [Vector2i(1,0),Vector2i(0,1)]:
				var ni=i+d.x;var nj=j+d.y
				if ni>=n or nj>=n: continue
				var nb=nj*n+ni
				if maze[c]==1 and maze[nb]==1 and STYLES[realm]=="corridors" and rng.randf()<.2: open_edge(east,south,n,c,nb)
				elif maze[c]==1 and maze[nb]==1 and absi(int(level[c])-int(level[nb]))==1 and rng.randf()<.12: open_edge(east,south,n,c,nb)
				elif maze[c]!=maze[nb]:
					var inside=c if maze[c]==1 else nb
					if level[inside]==0 and rng.randf()<.4: open_edge(east,south,n,c,nb)
	var corridors=STYLES[realm]=="corridors"
	var result={"n":n,"origin":origin,"maze":maze,"level":level,"east":east,"south":south,"corridors":corridors,"wall":CORRIDOR_WALL if corridors else WALL}
	cache[key]=result
	return result

static func open_edge(east: PackedByteArray,south: PackedByteArray,n: int,a: int,b: int):
	var lo=mini(a,b);var hi=maxi(a,b)
	if hi-lo==1: east[lo]=1
	else: south[lo]=1

static func floor_of(lab: Dictionary,i: int,j: int) -> float:
	var n: int=lab.n
	if i<0 or j<0 or i>=n or j>=n: return 0.0
	return float(lab.level[j*n+i])*FLOOR if lab.maze[j*n+i]==1 else 0.0

static func is_maze(lab: Dictionary,i: int,j: int) -> bool:
	var n: int=lab.n
	return i>=0 and j>=0 and i<n and j<n and lab.maze[j*n+i]==1

# Is the edge between cell (i,j) and its neighbour (i+di,j+dj) passable?
static func open(lab: Dictionary,i: int,j: int,di: int,dj: int) -> bool:
	var a=is_maze(lab,i,j);var b=is_maze(lab,i+di,j+dj)
	if not a and not b: return true
	var n: int=lab.n
	if di==1: return lab.east[j*n+i]==1
	if di==-1: return i-1>=0 and lab.east[j*n+i-1]==1
	if dj==1: return lab.south[j*n+i]==1
	return j-1>=0 and lab.south[(j-1)*n+i]==1

# Extra terrain height at a point.
static func lift(lab: Dictionary,x: float,z: float) -> float: return probe(lab,x,z).x

# x: extra height; y: 1 inside a wall band.
static func probe(lab: Dictionary,x: float,z: float) -> Vector2:
	if lab.is_empty(): return Vector2.ZERO
	var gx=(x-float(lab.origin))/CELL;var gz=(z-float(lab.origin))/CELL
	var i=int(floor(gx));var j=int(floor(gz))
	var n: int=lab.n
	if i<-1 or j<-1 or i>n or j>n: return Vector2.ZERO
	var corridors: bool=lab.get("corridors",false);var lip: float=lab.get("wall",WALL)
	var u=(gx-i)*CELL;var v=(gz-j)*CELL
	var here=floor_of(lab,i,j)
	var h=here
	var walls=0.0
	for edge in [[-1,0,u,v],[1,0,CELL-u,v],[0,-1,v,u],[0,1,CELL-v,u]]:
		var di: int=edge[0];var dj: int=edge[1];var d: float=edge[2];var along: float=edge[3]
		if d>RAMP: continue
		var there=floor_of(lab,i+di,j+dj)
		if corridors:
			if d<WALL_BAND and not open(lab,i,j,di,dj) and (is_maze(lab,i,j) or is_maze(lab,i+di,j+dj)): walls=maxf(walls,lip)
			continue
		if there==here: continue
		var jamb=along<JAMB or along>CELL-JAMB
		if not open(lab,i,j,di,dj) or jamb or absf(there-here)>FLOOR*1.5:
			if d<WALL_BAND: walls=maxf(walls,maxf(here,there)+lip)
		elif there!=here:
			h=lerpf(h,there,.5*(1.0-d/RAMP))
	return Vector2(maxf(h,walls),1.0 if walls>h else 0.0)

# For the minimap: 0 open ground, 1-5 floors, 9 cliff wall.
static func cell_kind(lab: Dictionary,x: float,z: float) -> int:
	var at=probe(lab,x,z)
	var gx=(x-float(lab.origin))/CELL;var gz=(z-float(lab.origin))/CELL
	var base=floor_of(lab,int(floor(gx)),int(floor(gz)))
	if at.y>0: return 9
	if not is_maze(lab,int(floor(gx)),int(floor(gz))): return 0
	return 1+int(round(base/FLOOR))

# Crisp walls over the terrain's wall bands (one MultiMesh, box collision for
# the hero) in the map's own ground, with a dark edge line along the top.
static func build_walls(world):
	var lab: Dictionary=world.labyrinth
	if lab.is_empty(): return
	var n: int=lab.n;var origin: float=lab.origin
	var segments=[]
	for j in range(-1,n):
		for i in range(-1,n):
			for d in [Vector2i(1,0),Vector2i(0,1)]:
				if not (is_maze(lab,i,j) or is_maze(lab,i+d.x,j+d.y)): continue
				var lip: float=lab.get("wall",WALL)
				var top=maxf(floor_of(lab,i,j),floor_of(lab,i+d.x,j+d.y))+lip
				var low=minf(floor_of(lab,i,j),floor_of(lab,i+d.x,j+d.y))
				if top-lip==low and not lab.get("corridors",false): continue
				var mid=Vector2(origin+(i+1)*CELL,origin+(j+.5)*CELL) if d.x==1 else Vector2(origin+(i+.5)*CELL,origin+(j+1)*CELL)
				if not open(lab,i,j,d.x,d.y): segments.append({"mid":mid,"along_x":d.x==0,"top":top,"low":low,"length":CELL+9.0})
				elif lab.get("corridors",false): continue
				elif top-lip-low>FLOOR*1.5: segments.append({"mid":mid,"along_x":d.x==0,"top":top,"low":low,"length":CELL+9.0})
				else:
					# A ramp doorway: jambs at both ends.
					var axis=Vector2(0,1) if d.x==1 else Vector2(1,0)
					for side in [-1,1]: segments.append({"mid":mid+axis*side*(CELL*.5-JAMB*.5+2.25),"along_x":d.x==0,"top":top,"low":low,"length":JAMB+4.5})
	if segments.is_empty(): return
	var root=StaticBody3D.new();root.name="LabyrinthWalls";root.collision_layer=1;world.add_child(root)
	# Walls wear the map's own ground (the terrain shader paints by world
	# position and this map's biome), so they read as part of the island, with a
	# slightly darker edge where the top meets the side (user, November 3: the
	# white walls did not belong to the map).
	var stone: ShaderMaterial=world.terrain_material.duplicate();stone.set_shader_parameter("shade",.78)
	var trim=StandardMaterial3D.new();trim.albedo_color=Color(0,0,0,.35);trim.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;trim.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	var parts=[[stone,1.0,0.0],[trim,.12,.62]]
	for part in parts:
		var multi=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.mesh=BoxMesh.new();multi.instance_count=segments.size()
		for k in range(segments.size()):
			var s: Dictionary=segments[k]
			var ground=world.height_at(s.mid.x,s.mid.y)-Labyrinth.lift(lab,s.mid.x,s.mid.y)
			var height=float(s.top)-float(s.low)+1.5
			var size=Vector3(float(s.length),height,9.0) if s.along_x else Vector3(9.0,height,float(s.length))
			var centre_y=ground+float(s.low)-1.5+height*.5
			if part[0]==trim: size=Vector3(size.x+.06 if s.along_x else 9.06,.25,size.z+.06 if not s.along_x else 9.06);centre_y=ground+float(s.top)-.2
			multi.set_instance_transform(k,Transform3D(Basis.from_scale(size),Vector3(s.mid.x,centre_y,s.mid.y)))
		var instance=MultiMeshInstance3D.new();instance.multimesh=multi;instance.material_override=part[0];root.add_child(instance)
	for s in segments:
		var ground=world.height_at(s.mid.x,s.mid.y)-Labyrinth.lift(lab,s.mid.x,s.mid.y)
		var height=float(s.top)-float(s.low)+1.5
		var shape=CollisionShape3D.new();var box=BoxShape3D.new()
		box.size=Vector3(float(s.length),height,9.0) if s.along_x else Vector3(9.0,height,float(s.length));shape.shape=box
		shape.position=Vector3(s.mid.x,ground+float(s.low)-1.5+height*.5,s.mid.y);root.add_child(shape)

# The ground under the maze is flat (user, November 3: "flat ground so the
# labyrinth does not clip into the mountains"): 1 on the maze's tiles, easing
# to 0 over FLAT_EASE metres beyond them, where the island's hills take over.
const FLAT_Y=1.0
const FLAT_EASE=18.0
static func flatness(lab: Dictionary,x: float,z: float) -> float:
	if lab.is_empty(): return 0.0
	var gx=(x-float(lab.origin))/CELL;var gz=(z-float(lab.origin))/CELL
	var i=int(floor(gx));var j=int(floor(gz))
	if is_maze(lab,i,j): return 1.0
	var nearest=INF
	for dj in [-1,0,1]:
		for di in [-1,0,1]:
			if not is_maze(lab,i+di,j+dj): continue
			var lo=Vector2(float(lab.origin)+(i+di)*CELL,float(lab.origin)+(j+dj)*CELL)
			var q=Vector2(clampf(x,lo.x,lo.x+CELL),clampf(z,lo.y,lo.y+CELL))
			nearest=minf(nearest,q.distance_to(Vector2(x,z)))
	return 1.0-smoothstep(0.0,FLAT_EASE,nearest) if nearest<INF else 0.0

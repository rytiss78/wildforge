extends Node3D
class_name RealmWorld

const EXTENT=400.0
const SPAWN_EXTENT=EXTENT-30.0
const DANGER_EXTENT=EXTENT-25.0
const CHUNK=64.0
const NAMES=["Sunlit Frontier","Wild Highlands","Skyward Reach","The Red Moon"]
const BIOMES=["Clover Woods","Puffcap Marsh","Moon Craters","Cloud City","Candy Hell","Starfall Space"]
const CREATURES=["acorn","toad","crab","penguin","lizard","beetle"]
const COLORS=[Color("326849"),Color("91b3ab"),Color("b4c5df"),Color("d9eaed"),Color("e69479"),Color("ab96c5")]
var realm=0
var seed_value=0
var noise=FastNoiseLite.new()
var height_vertices={}
var rng=RandomNumberGenerator.new()
var landmarks=[]
var building_sites=[]
var harvest_sites: Array[Vector3]=[]
var chunks={}
var pending=[]
var terrain_material: ShaderMaterial
var lava_material: StandardMaterial3D
var scenery_material: ShaderMaterial
var last_cell=Vector2i(999,999)
var stream_signature=""
var sky_paint: ShaderMaterial
var build_in_progress=false
var build_cells=[]
var build_cell_index=0
var sky_top=Color("111a2b")
var sky_horizon=Color("293b48")
var environment: Environment
var weather: GPUParticles3D
var active_biome=-1
var region_blend=0.0
var clouds=[]
var stars: MultiMeshInstance3D
var moon: MeshInstance3D
var border_steam=[]
var border_patches=[]
var edge_near=false
var eclipse=false
static var prop_meshes={}
const SKY_TOP=[Color("111a2b"),Color("151b28"),Color("18234d"),Color("254459"),Color("301824"),Color("16132d")]
const SKY_HORIZON=[Color("293b48"),Color("405149"),Color("536683"),Color("8aa8a8"),Color("944436"),Color("534577")]

static func coast_radius(angle: float,world_seed: int,world_realm: int) -> float:
	if world_realm==3: return 72.0
	var phase=float(world_seed%23)*.03+world_realm*.4
	return 344+24*sin(3*(angle+phase))+14*sin(5*(angle-phase))+8*cos(7*(angle+phase*.5))

func shore_radius(p: Vector3) -> float:
	return coast_radius(atan2(p.z,p.x),seed_value,realm)

func dangerous(p: Vector3) -> bool:
	return Vector2(p.x,p.z).length()>=shore_radius(p)

func weather_tick(delta: float,p: Vector3):
	if scenery_material:
		scenery_material.set_shader_parameter("hero_position",p)
		if scenery_material.next_pass: scenery_material.next_pass.set_shader_parameter("hero_position",p)
	# Eclipse: blood rain replaces normal rain entirely.
	var biome=biome_at(p)
	if active_biome!=biome:
		active_biome=biome
		for cloud in clouds: cloud.visible=biome in [1,3]
		stars.visible=biome in [2,5];moon.visible=biome==2
		weather.emitting=biome in [0,1,3,4,5]
		weather.amount=240 if biome==1 else 80 if biome in [3,4,5] else 38
		var material: ParticleProcessMaterial=weather.process_material
		# Marsh: rain in wind; cloud: drifting motes; hell: rising sparks.
		material.gravity=Vector3(3,-13,1) if biome==1 else Vector3(2,-.5,1) if biome==3 else Vector3(-2,4,0) if biome==4 else Vector3(-2,.7,0)
		material.initial_velocity_min=1.5;material.initial_velocity_max=4.0 if biome==1 else 2.5
		var paint=StandardMaterial3D.new();paint.albedo_color=Color("b5dfec") if biome==1 else Color("fff8ed") if biome==3 else Color("ffcb88") if biome==4 else Color("bd9af0") if biome==5 else Color("a0c681")
		paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		var mesh=SphereMesh.new();mesh.radius=.02 if biome==1 else .015 if biome==0 else .05;mesh.height=.9 if biome==1 else .06 if biome==0 else .18;mesh.material=paint;weather.draw_pass_1=mesh
	weather.emitting=not eclipse and biome in [0,1,3,4,5]
	weather.position=p+Vector3.UP*8
	sky_top=sky_top.lerp(Color("21192f") if eclipse else SKY_TOP[biome],1-exp(-delta*.6));sky_horizon=sky_horizon.lerp(Color("77556c") if eclipse else SKY_HORIZON[biome],1-exp(-delta*.6))
	sky_paint.set_shader_parameter("top_color",sky_top);sky_paint.set_shader_parameter("horizon_color",sky_horizon)
	for pair in [["moon_strength",biome==2],["space_strength",biome==5],["fire_strength",biome==4]]:
		var parameter=sky_paint.get_shader_parameter(pair[0]);var previous=float(parameter) if parameter!=null else 0.0;sky_paint.set_shader_parameter(pair[0],lerpf(previous,1.0 if pair[1] else 0.0,1-exp(-delta*.6)))
	environment.fog_light_color=sky_horizon
	environment.ambient_light_color=Color("a4b8ed") if biome==0 else Color("e6efff")
	environment.ambient_light_energy=.28 if biome==0 else .36
	environment.fog_depth_begin=lerpf(environment.fog_depth_begin,35.0 if biome in [1,3] else 45.0,1-exp(-delta*.6))
	environment.fog_depth_end=lerpf(environment.fog_depth_end,140.0 if biome in [1,3] else 165.0,1-exp(-delta*.6))
	edge_near=false
	var radius=Vector2(p.x,p.z).length();var coast=shore_radius(p)
	for index in range(border_steam.size()):
		var nearby=radius>coast-28;edge_near=edge_near or nearby
		border_steam[index].emitting=nearby;border_patches[index].visible=nearby
		if not nearby: continue
		var angle=atan2(p.z,p.x)+(index-.5)*.025
		var point=Vector3(cos(angle),0,sin(angle))*coast;point.y=.15
		border_steam[index].position=point;border_patches[index].position=point

func biome_at(p: Vector3) -> int:
	if realm==3: return 2
	if Vector2(p.x,p.z).length()<65: return 0
	return int(floor(fposmod(atan2(p.z,p.x)+float(seed_value%23)*.03+realm*.4,TAU)/(TAU/6)))

func crossing_distance(p: Vector3) -> float:
	var radius=Vector2(p.x,p.z).length()
	var angle=fposmod(atan2(p.z,p.x)+float(seed_value%23)*.03+realm*.4,TAU/6)
	return minf(absf(radius-65),radius*sin(minf(angle,TAU/6-angle)))

func height_at(x: float,z: float) -> float:
	# Match the actual four-metre terrain triangles used by collision exactly.
	var ox=floorf(x/4)*4;var oz=floorf(z/4)*4;var fx=(x-ox)/4;var fz=(z-oz)/4
	var a=raw_height_at(ox,oz);var b=raw_height_at(ox+4,oz);var c=raw_height_at(ox,oz+4)
	if fx+fz<=1: return a+(b-a)*fx+(c-a)*fz
	var d=raw_height_at(ox+4,oz+4)
	return d+(c-d)*(1-fx)+(b-d)*(1-fz)

func raw_height_at(x: float,z: float) -> float:
	# Physics, drops and terrain all share these immutable grid vertices.
	var key=Vector2(x,z)
	if height_vertices.has(key): return height_vertices[key]
	var value=compute_height_at(x,z)
	height_vertices[key]=value
	return value

func compute_height_at(x: float,z: float) -> float:
	if realm==3:
		var distance=Vector2(x,z).length()
		return 1.3+sin(x*.06)*cos(z*.06)*.4-maxf(0,distance-64)*.45
	var p=Vector3(x,0,z)
	var biome=biome_at(p)
	var angle=fposmod(atan2(z,x)+float(seed_value%23)*.03+realm*.4,TAU)/(TAU/6)
	# Reduced terrain amplitudes to keep slopes navigable for enemies.
	var amplitudes=[6.0,4.0,6.0,8.0,6.0,6.0]
	var index=int(floor(angle))
	var amplitude=lerpf(amplitudes[index],amplitudes[(index+1)%6],smoothstep(0.0,1.0,fposmod(angle,1.0)))
	# Smooth amplitudes near angular boundaries; no invisible height discontinuities.
	var base=noise.get_noise_2d(x,z)*6+sin(x*.012)*cos(z*.012)*3
	var mountain=maxf(0,noise.get_noise_2d(x+790,z-530))*12
	var blend=smoothstep(65.0,120.0,Vector2(x,z).length())
	var terrain=[sin(x*.06)*cos(z*.06)*1.5,-absf(sin(x*.025)*sin(z*.035))*3,-pow(maxf(0,noise.get_noise_2d(x*2,z*2)),2)*6,sin(x*.025)*cos(z*.025)*7,absf(sin(x*.032)+cos(z*.041))*4,sin(x*.018)*cos(z*.022)*9]
	var relief=lerpf(terrain[index],terrain[(index+1)%6],smoothstep(0.0,1.0,fposmod(angle,1.0)))
	var original=base+mountain*blend*(amplitude/28.0)+relief*blend
	var terrace=floorf(original/5.0)*5.0+smoothstep(.62,1.0,fposmod(original,5.0)/5.0)*5.0
	var route=1.0-smoothstep(4.0,12.0,crossing_distance(p))
	var inland=lerpf(terrace,original*.85,route)*smoothstep(0.0,28.0,Vector2(x,z).length())
	var edge=Vector2(x,z).length();var coast=shore_radius(p)
	var shore=2.0-maxf(0.0,edge-(coast-6.0))/3.0
	return lerpf(inland,shore,smoothstep(coast-32.0,coast-4.0,edge))

func portal_site() -> Vector3:
	if realm==3: return Vector3(0,1.5,48)
	var p=landmarks[(realm+1)%landmarks.size()]+Vector3(18,0,16)
	p.y=height_at(p.x,p.z)+.2
	return p

func model(name: String,height: float) -> Node3D:
	if name.begins_with("boss_"):
		var rig=ActorRig.new();rig.setup(name);rig.scale=Vector3.ONE*(height/3.0);return rig
	var asset=name if name.begins_with("creature_") else "count_duck" if name=="rubber_duck_toy" else "hero_"+name
	if ResourceLoader.exists("res://assets/style3d/"+asset+".glb"):
		var rig=ActorRig.new();rig.setup(name);var reference_height=1.65
		if name.begins_with("creature_") and ResourceLoader.exists("res://assets/style3d/baked/"+name+".res"):
			reference_height=load("res://assets/style3d/baked/"+name+".res").get_aabb().size.y
		rig.scale=Vector3.ONE*(height/maxf(.1,reference_height))
		return rig
	return ToonArt.make(name,height)

func build(index: int,world_seed: int):
	height_vertices.clear()
	realm=index;seed_value=world_seed;rng.seed=world_seed+index*763
	noise.seed=world_seed%2147483647;noise.frequency=.014;noise.fractal_octaves=3;noise.fractal_gain=.4
	for child in get_children():
		remove_child(child);child.queue_free()
	chunks.clear();pending.clear();landmarks.clear();building_sites.clear();harvest_sites.clear();last_cell=Vector2i(999,999);stream_signature=""
	clouds.clear();border_steam.clear();border_patches.clear()
	make_environment();make_material();make_boundaries();make_landmarks()
	# Large decorative halls are retired; landmarks and smaller scenery remain.
	# Frame-budgeted chunk building: schedule 49 chunks, process ~6 per frame
	build_in_progress=true
	build_cell_index=0
	build_cells=[]
	for x in range(-2,3):
		for z in range(-2,3):
			build_cells.append(Vector2i(x,z))
	stream(Vector3.ZERO)

func make_material():
	# Restrained glowing lava, separate from the terrain shader and its biome atlas.
	lava_material=StandardMaterial3D.new()
	lava_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	lava_material.albedo_color=Color("ed642c")
	lava_material.emission_enabled=true
	lava_material.emission=Color("ff8c32")
	lava_material.emission_energy_multiplier=2.0
	lava_material.cull_mode=BaseMaterial3D.CULL_DISABLED
	var shader=load("res://shaders/terrain.gdshader")
	terrain_material=ShaderMaterial.new();terrain_material.shader=shader;terrain_material.set_shader_parameter("phase",float(seed_value%23)*.03+realm*.4)
	terrain_material.set_shader_parameter("red_moon",realm==3)
	for i in range(6): terrain_material.set_shader_parameter("t"+str(i),load("res://assets/illustrated/forge-basalt-moss.png" if i==0 else "res://assets/illustrated/terrain-moss-v2.png" if i==1 else "res://assets/illustrated/terrain-stone-v2.png"))
	scenery_material=PaintedBatch.material()
	scenery_material.set_shader_parameter("fade_near",true)
	scenery_material.next_pass.set_shader_parameter("fade_near",true)

func make_chunk(cell: Vector2i):
	if chunks.has(cell): return
	var root=Node3D.new();root.position=Vector3(cell.x*CHUNK,0,cell.y*CHUNK);add_child(root);chunks[cell]=root
	var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var resolution=16
	var step=CHUNK/resolution
	for x in range(resolution):
		for z in range(resolution):
			var ox=cell.x*CHUNK+x*step;var oz=cell.y*CHUNK+z*step
			for v in [Vector2(ox,oz),Vector2(ox+step,oz),Vector2(ox,oz+step),Vector2(ox+step,oz),Vector2(ox+step,oz+step),Vector2(ox,oz+step)]:
				var color=Color.WHITE;color.a=float(biome_at(Vector3(v.x,0,v.y)))/5
				surface.set_color(color);surface.set_uv(v*.12)
				surface.add_vertex(Vector3(v.x-root.position.x,raw_height_at(v.x,v.y),v.y-root.position.z))
	surface.generate_normals()
	var terrain=MeshInstance3D.new();terrain.mesh=surface.commit();terrain.material_override=terrain_material;root.add_child(terrain)
	terrain.create_trimesh_collision()
	make_lava_chunk(root,cell)
	var scenery=[]
	var scenery_groups={}
	var local_rng=RandomNumberGenerator.new();local_rng.seed=seed_value+cell.x*73856093+cell.y*19349663
	for i in range(26):
		var p=Vector3(cell.x*CHUNK+local_rng.randf()*CHUNK,0,cell.y*CHUNK+local_rng.randf()*CHUNK)
		if Vector2(p.x,p.z).length()>shore_radius(p)-25: continue
		if realm==3 and Vector2(p.x,p.z).length()<38: continue
		var portal=portal_site()
		if Vector2(p.x-portal.x,p.z-portal.z).length()<14: continue
		if Vector2(p.x-60,p.z+35).length()<7: continue
		if Vector2(p.x,p.z).length()<13 or absf(p.x+sin(p.z*.035)*9)<6: continue
		if lava_at(p): continue  # Keep the molten channels legible and traversable.
		if crossing_distance(p)<12 and i%3!=0: continue
		if MassiveArchitecture.occupied(self,p): continue
		if harvest_sites.any(func(site):return Vector2(site.x-p.x,site.z-p.z).length()<4): continue
		p.y=height_at(p.x,p.z)
		var biome=biome_at(p)
		var prop=Node3D.new();prop.position=p-root.position;root.add_child(prop)
		if biome==2 and i%3==0:
			ToonArt.ball(prop,Color("e5cb70"),Vector3(0,.4,0),Vector3(2.2,.8,1.6))
			for bite in range(4): ToonArt.ball(prop,Color("9b874b"),Vector3(-.7+bite*.4,.7,.3 if bite%2==0 else -.2),Vector3(.22,.12,.22))

		# Keep greenery and terrain landmarks; large structures are sparse and smaller.
		var variant=local_rng.randi_range(0,3) if i%9!=8 else local_rng.randi_range(4,5)
		var model_path="res://assets/style3d/prop_%d_%d.glb" % [biome,variant]
		if ResourceLoader.exists(model_path):
			var baked_path="res://assets/style3d/baked/prop_%d_%d.res" % [biome,variant]
			var baked=ResourceLoader.exists(baked_path)
			var asset=Node3D.new() if baked else load(model_path).instantiate();prop.add_child(asset)
			var scale_value=local_rng.randf_range(.7,1.15) if variant<4 else local_rng.randf_range(1.05,1.4)
			if biome==3 and variant==0: scale_value=1.0
			asset.scale=Vector3.ONE*scale_value;prop.rotation.y=local_rng.randf()*TAU
			if baked:
				if not prop_meshes.has(baked_path): prop_meshes[baked_path]=load(baked_path)
				if not scenery_groups.has(baked_path): scenery_groups[baked_path]=[]
				scenery_groups[baked_path].append(prop.transform*asset.transform)
			var solid=StaticBody3D.new();prop.add_child(solid);solid.collision_layer=1
			var obstacle=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=(.35 if biome==0 and variant<2 else 1.05)*scale_value;capsule.height=maxf(capsule.radius*2,8.0*scale_value);obstacle.shape=capsule;obstacle.position.y=capsule.height*.5;solid.add_child(obstacle)
			var arch=(biome==2 and variant==1) or (biome==3 and variant==1) or (biome==4 and variant==1) or (biome==5 and variant in [0,4,5])
			if arch:
				obstacle.queue_free()
				for side in [-1,1]:
					var support=CollisionShape3D.new();var column=CapsuleShape3D.new();column.radius=.4*scale_value;column.height=5*scale_value;support.shape=column;support.position=Vector3(side*2.5*scale_value,2.5*scale_value,0);solid.add_child(support)
			elif biome==3 and variant==0:
				var platform=BoxShape3D.new();platform.size=Vector3(3.8,.5,2.8);obstacle.shape=platform;obstacle.position.y=2.25
				for stair in range(2):
					var step_asset=Node3D.new() if baked else load(model_path).instantiate();prop.add_child(step_asset);step_asset.scale=Vector3.ONE*(.35+stair*.3);step_asset.position=Vector3(-3.0+stair*1.3,.1,0)
					if baked: scenery_groups[baked_path].append(prop.transform*step_asset.transform)
					var step_shape=CollisionShape3D.new();var step_box=BoxShape3D.new();step_box.size=Vector3(1.6,.3,1.5);step_shape.shape=step_box;step_shape.position=Vector3(-3.0+stair*1.3,.9+stair*.7,0);solid.add_child(step_shape)
			elif variant in [4,5] and biome in [0,3]:
				var occlusion=OccluderInstance3D.new();var occluder=BoxOccluder3D.new();occluder.size=Vector3(1.25,7.0,1.15)*scale_value;occlusion.occluder=occluder;occlusion.position.y=4*scale_value;prop.add_child(occlusion)
			if i%9==8: preload("res://scripts/scenery_lights.gd").add_lamp(prop,biome)
			PaintedBatch.collect(prop,scenery)
			continue
		push_error("Missing required scenery model: "+model_path)
	for path in scenery_groups:
		var instances=MultiMesh.new();instances.transform_format=MultiMesh.TRANSFORM_3D;instances.mesh=prop_meshes[path];instances.instance_count=scenery_groups[path].size()
		for index in range(instances.instance_count): instances.set_instance_transform(index,scenery_groups[path][index])
		var combined=MultiMeshInstance3D.new();combined.multimesh=instances;combined.material_override=scenery_material;combined.visibility_range_end=105;combined.visibility_range_end_margin=15;root.add_child(combined)
	if not scenery.is_empty():
		var mesh=PaintedBatch.merge(root,scenery)
		for source in scenery: source.queue_free()
		var combined=MeshInstance3D.new();combined.mesh=mesh;combined.material_override=scenery_material;combined.visibility_range_end=105;combined.visibility_range_end_margin=15;root.add_child(combined)
	# Low batched ground details never conceal an ordinary enemy.
	var multimesh=MultiMesh.new();multimesh.transform_format=MultiMesh.TRANSFORM_3D;multimesh.use_colors=true
	var blade=PrismMesh.new();blade.size=Vector3(.08,.18,.07);multimesh.mesh=blade;multimesh.instance_count=80
	for i in range(80):
		var p=Vector3(cell.x*CHUNK+local_rng.randf()*CHUNK,0,cell.y*CHUNK+local_rng.randf()*CHUNK);p.y=height_at(p.x,p.z)+.08
		multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,p-root.position));multimesh.set_instance_color(i,COLORS[biome_at(p)].darkened(.17))
	var grass=MultiMeshInstance3D.new();grass.multimesh=multimesh
	grass.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material=ShaderMaterial.new();material.shader=preload("res://shaders/flora.gdshader");grass.material_override=material;root.add_child(grass)

# Candy Hell (biome 4): three deterministic winding lava streams.
# Render into terrain chunks so distant geometry is discarded with the chunk.
func lava_center(radius: float,lane: int) -> Vector3:
	var phase=float(seed_value%23)*.03+realm*.4
	var angle=4.5*TAU/6-phase+float(lane)*.17+sin(radius*.024+lane*1.7)*.035
	return Vector3(cos(angle)*radius,0,sin(angle)*radius)

func lava_at(p: Vector3) -> bool:
	if realm==3 or biome_at(p)!=4: return false
	var radius=Vector2(p.x,p.z).length()
	if radius<95 or radius>310: return false
	for lane in [-1,0,1]:
		var center=lava_center(radius,lane)
		if Vector2(center.x-p.x,center.z-p.z).length()<3.1: return true
	return false

func make_lava_chunk(root: Node3D,cell: Vector2i):
	if realm==3: return
	var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces=0
	for lane in [-1,0,1]:
		for distance in range(96,310,4):
			var a=lava_center(float(distance),lane)
			var b=lava_center(float(distance+4),lane)
			var mid=(a+b)*.5
			if biome_at(mid)!=4: continue
			if floori(mid.x/CHUNK)!=cell.x or floori(mid.z/CHUNK)!=cell.y: continue
			var forward=Vector2(b.x-a.x,b.z-a.z).normalized()
			var side=Vector2(-forward.y,forward.x)*2.65
			var left_a=Vector3(a.x-side.x,height_at(a.x-side.x,a.z-side.y)+.18,a.z-side.y)-root.position
			var right_a=Vector3(a.x+side.x,height_at(a.x+side.x,a.z+side.y)+.18,a.z+side.y)-root.position
			var left_b=Vector3(b.x-side.x,height_at(b.x-side.x,b.z-side.y)+.18,b.z-side.y)-root.position
			var right_b=Vector3(b.x+side.x,height_at(b.x+side.x,b.z+side.y)+.18,b.z+side.y)-root.position
			for vertex in [left_a,right_a,left_b,right_a,right_b,left_b]: surface.add_vertex(vertex)
			faces+=2
	if faces==0: return
	var river=MeshInstance3D.new();river.name="CandyLava";river.mesh=surface.commit()
	river.material_override=lava_material
	river.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(river)

func stream(position_value: Vector3,party: Array=[]):
	var centers=[Vector2i(floori(position_value.x/CHUNK),floori(position_value.z/CHUNK))]
	for p in party:
		var cell=Vector2i(floori(p.x/CHUNK),floori(p.z/CHUNK))
		if not centers.has(cell): centers.append(cell)
	var signature=str(centers)
	if signature!=stream_signature:
		stream_signature=signature;pending.clear()
		var wanted={}
		for cell in centers:
			for x in range(-2,3):
				for z in range(-2,3):
					var key=cell+Vector2i(x,z)
					if absi(key.x)<=ceili(EXTENT/CHUNK) and absi(key.y)<=ceili(EXTENT/CHUNK): wanted[key]=true
		for key in wanted:
			if not chunks.has(key): pending.append(key)
		pending.sort_custom(func(a,b):return a.distance_squared_to(centers[0])<b.distance_squared_to(centers[0]))
		for key in chunks.keys():
			if centers.all(func(c):return maxi(absi(key.x-c.x),absi(key.y-c.y))>3): chunks[key].queue_free();chunks.erase(key)
	if not pending.is_empty(): make_chunk(pending.pop_front())

# Frame-budgeted chunk building for realm transitions
func build_tick(delta: float):
	if not build_in_progress: return
	var budget=mini(2,int(delta*60))
	for i in range(budget):
		if build_cell_index<build_cells.size():
			make_chunk(build_cells[build_cell_index])
			build_cell_index+=1
		else: break
	if build_cell_index>=build_cells.size():
		build_in_progress=false
		build_cells.clear()
		build_cell_index=0

func ensure_ground(p: Vector3):
	make_chunk(Vector2i(floori(p.x/CHUNK),floori(p.z/CHUNK)))

func make_boundaries():
	var ocean=MeshInstance3D.new();ocean.name="DeadlySea"
	var sea_plane=PlaneMesh.new();sea_plane.size=Vector2(2800,2800);ocean.mesh=sea_plane
	var water=ShaderMaterial.new();water.shader=load("res://shaders/deadly_sea.gdshader");water.set_shader_parameter("red_moon",realm==3);water.set_shader_parameter("phase",float(seed_value%23)*.03+realm*.4);ocean.material_override=water;add_child(ocean)
	for side in [-1,1]:
		for axis in [0,2]:
			var mesh=BoxMesh.new();mesh.size=Vector3(16,100,EXTENT*2+24) if axis==0 else Vector3(EXTENT*2+24,100,16)
			var p=Vector3.ZERO;p[axis]=side*(EXTENT+8);p.y=36
			var ridge=ToonArt.part(self,mesh,Color("a7b6a2"),p);ridge.create_trimesh_collision();ridge.visible=false
	for axis in [0,2]:
		var steam=GPUParticles3D.new();steam.amount=32;steam.lifetime=3;steam.emitting=false;steam.visibility_aabb=AABB(Vector3(-10,-1,-10),Vector3(20,10,20));add_child(steam);border_steam.append(steam)
		var process=ParticleProcessMaterial.new();process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX;process.emission_box_extents=Vector3(5,.1,5);process.direction=Vector3.UP;process.spread=35;process.gravity=Vector3(0,.3,0);process.initial_velocity_min=.4;process.initial_velocity_max=1.5;process.scale_min=.4;process.scale_max=1.3;steam.process_material=process
		var puff=SphereMesh.new();puff.radius=.3;puff.height=.7;puff.radial_segments=8;puff.rings=4
		var paint=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;paint.albedo_color=Color(.91,.88,.78,.12);puff.material=paint;steam.draw_pass_1=puff
		var patch=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(14,14);patch.mesh=plane
		var ground=ShaderMaterial.new();ground.shader=load("res://shaders/boiling_ground.gdshader");ground.set_shader_parameter("paper",load("res://assets/illustrated/paper.png"));patch.material_override=ground;patch.visible=false;add_child(patch);border_patches.append(patch)

func make_environment():
	var env=Environment.new();env.background_mode=Environment.BG_SKY
	var sky=Sky.new();var gradient=ShaderMaterial.new();gradient.shader=load("res://shaders/biome_sky.gdshader");gradient.set_shader_parameter("paint",load("res://assets/illustrated/terrain-2.png"));sky.sky_material=gradient;sky.process_mode=Sky.PROCESS_MODE_REALTIME;env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("e6efff");env.ambient_light_energy=.36
	env.adjustment_enabled=true;env.adjustment_saturation=1.04;env.adjustment_contrast=1.03
	# Keep the playable foreground crisp; distant scenery still fades out.
	env.fog_enabled=true;env.fog_mode=Environment.FOG_MODE_DEPTH;env.fog_light_color=sky_horizon;env.fog_density=1.0;env.fog_depth_begin=35;env.fog_depth_end=155;env.fog_sky_affect=0
	var world_env=WorldEnvironment.new();world_env.environment=env;add_child(world_env)
	sky_paint=gradient;environment=env;active_biome=-1
	weather=GPUParticles3D.new();weather.amount=180;weather.lifetime=4;weather.visibility_aabb=AABB(Vector3(-40,-55,-40),Vector3(80,85,80));add_child(weather)
	var particles=ParticleProcessMaterial.new();particles.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX;particles.emission_box_extents=Vector3(14,4,14);particles.direction=Vector3.DOWN;particles.spread=35;weather.process_material=particles
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-35,0);sun.light_energy=1.05;sun.light_color=Color("ffe4b5");sun.shadow_enabled=true;sun.directional_shadow_max_distance=38;add_child(sun)
	for i in range(16):
		var cloud=Node3D.new();cloud.position=Vector3(cos(i*TAU/16)*370,60+sin(i)*15,sin(i*TAU/16)*370);add_child(cloud);clouds.append(cloud)
		for j in range(3): ToonArt.ball(cloud,Color("fff2de"),Vector3(j*6,0,0),Vector3(20,9,12))
	stars=MultiMeshInstance3D.new();var constellation=MultiMesh.new();constellation.transform_format=MultiMesh.TRANSFORM_3D;var star=SphereMesh.new();star.radius=.4;star.height=.8;star.radial_segments=6;star.rings=4;constellation.mesh=star;constellation.instance_count=180
	for i in range(180): constellation.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(cos(i*2.4)*390,80+rng.randf()*180,sin(i*2.4)*390)))
	stars.multimesh=constellation;var starlight=StandardMaterial3D.new();starlight.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;starlight.albedo_color=Color("fff1c8");stars.material_override=starlight;add_child(stars)
	moon=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=24;sphere.height=48;moon.mesh=sphere;moon.position=Vector3(220,110,-280);var paint=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;paint.albedo_texture=load("res://assets/illustrated/terrain-2.png");moon.material_override=paint;add_child(moon)

func make_landmarks():
	if realm==3:
		landmarks.append(Vector3.ZERO);return
	for biome in range(6):
		var angle=(biome+.5)*TAU/6-float(seed_value%23)*.03-realm*.4
		var p=Vector3(cos(angle)*175,0,sin(angle)*175)
		p.y=height_at(p.x,p.z)
		landmarks.append(p)
		preload("res://scripts/biome_landmarks.gd").build(self,biome,p)

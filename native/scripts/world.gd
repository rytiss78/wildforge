extends Node3D
class_name RealmWorld

const EXTENT=400.0
const SPAWN_EXTENT=EXTENT-30.0
const DANGER_EXTENT=EXTENT-25.0
const CHUNK=64.0
# Draw distance (user request, October 24: enemies and grass appeared right in
# front of the hero). Fog, camera range and new chunks' fade distances scale with
# view_scale, which the game raises while the frame rate has room (1.0 to 1.5).
const FOG_REACH=1.4
const GRASS_RANGE=100.0
const SCENERY_RANGE=170.0
const FOG_LIMIT=205.0
var view_scale=1.0
const NAMES=["Sunlit Frontier","Blighted Highlands","Ashen Reach","The Red Moon"]
# Each island looks harsher than the last: a different coastline, a darker sky
# tint, corrupted ground with glowing veins, and its own drifting air.
#   shape: coastline 4-lobe / 6-lobe amplitude and radius shift (also in the
#   terrain and sea shaders); mix: how strongly the island tint overrides biome skies.
const GRADE=[
	{"shape":Vector3.ZERO,"mix":0.0,"corruption":0.0},
	{"shape":Vector3(18,0,-12),"mix":.5,"corruption":.55,"top":Color("2b1642"),"horizon":Color("9a5a86"),"ambient":Color("d8b4ef"),"ambient_energy":.31,"sun":Color("ffb487"),"sun_energy":1.05,"vein":Color("c34dff"),"tint":Color("7a5a96"),"scenery":Vector3(.84,.72,.98),"air":Color("e7a0ff"),"air_rises":true,"title":"The Blight spreads · enemies are tougher"},
	{"shape":Vector3(8,22,-22),"mix":.68,"corruption":1.0,"top":Color("240806"),"horizon":Color("b2401f"),"ambient":Color("f3a888"),"ambient_energy":.27,"sun":Color("ff7448"),"sun_energy":.95,"vein":Color("ff5a14"),"tint":Color("4e3a34"),"scenery":Vector3(.7,.56,.5),"air":Color("b9aea6"),"air_rises":false,"title":"Ash and fire · the hardest island"},
	{"shape":Vector3.ZERO,"mix":0.0,"corruption":0.0},
]
# Seven biomes: six slices of the island plus Junkyard Planet (biome 6, user
# request October 27: a new biome), a rust-and-scrap slice under a smog sky.
const BIOME_COUNT=7
# Big update MB (user, November 2): one biome per map. Seven maps, one per
# biome (that biome's creatures only), played in a row in this order (by
# toughness), then the Red Moon arena (realm ARENA).
const MAPS=7
const ARENA=7
const MAP_BIOMES=[0,1,2,3,6,4,5]
const MAP_SECONDS=360.0
# Which harsher island look (GRADE) each map uses; the arena keeps its own.
# (Corrupted veins and harsher tints are gone from the maps, user November 3:
# "remove lines on map that appear in later maps"; each map has its own sky.)
const MAP_GRADES=[0,0,0,0,0,0,0]
static func biome_of(map: int) -> int: return 2 if map>=ARENA else MAP_BIOMES[clampi(map,0,MAPS-1)]
static func grade_of(map: int) -> int: return 3 if map>=ARENA else MAP_GRADES[clampi(map,0,MAPS-1)]
# Difficulty stage: 0 on the first map rising to 2 on the seventh, 3 in the arena
# (what the three-island run used as its realm number in balance formulas).
static func tier(map: int) -> float: return 3.0 if map>=ARENA else 2.0*float(clampi(map,0,MAPS-1))/float(MAPS-1)
static func map_name(map: int) -> String: return "The Red Moon" if map>=ARENA else BIOMES[biome_of(map)]
const BIOME_ARC=TAU/BIOME_COUNT
# Toughness and reward tier per biome (enemy health, damage, gold). Biomes 0-5
# keep their index; Junkyard Planet sits mid-pack instead of becoming the hardest.
const BIOME_TIER=[0,1,2,3,4,5,3]
const BIOMES=["Clover Woods","Puffcap Marsh","Moon Craters","Cloudwilds","Candy Hell","Starfall Space","Junkyard Planet"]
const CREATURES=["acorn","toad","crab","penguin","lizard","beetle","rat"]
const COLORS=[Color("326849"),Color("91b3ab"),Color("b4c5df"),Color("d9eaed"),Color("e69479"),Color("ab96c5"),Color("a8824e")]
var realm=0
var seed_value=0
var noise=FastNoiseLite.new()
var height_vertices={}
var rng=RandomNumberGenerator.new()
var landmarks=[]
var building_sites=[]
var harvest_sites: Array[Vector3]=[]
# Big update MB: climbing mesas (ClimbMap.plan) and their launch pads.
var climb_mesas=[]
# Multi-floor labyrinth of this map, if it has one (Labyrinth).
var labyrinth={}
var climb_pads=[]
var chunks={}
var pending=[]
var terrain_material: ShaderMaterial
var under_material: ShaderMaterial
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
var sun_light: DirectionalLight3D
var region_blend=0.0
var clouds=[]
var stars: MultiMeshInstance3D
var moon: MeshInstance3D
var border_steam=[]
var border_patches=[]
var low_mist=[]
var edge_near=false
var eclipse=false
var island_air: GPUParticles3D
static var prop_meshes={}
const SKY_TOP=[Color("111a2b"),Color("151b28"),Color("18234d"),Color("254459"),Color("301824"),Color("16132d"),Color("1f2614")]
# Horizons (and so fog) for biomes 2-5 were darkened in the October 23 per-biome pass:
# pale horizons washed the ground out through the fog.
const SKY_HORIZON=[Color("293b48"),Color("405149"),Color("34405e"),Color("5f8288"),Color("6a2a24"),Color("392c5a"),Color("5e5526")]
# Dark skies are lifted toward these brightnesses (luminance), by at most 1.6x at
# the top and 2.2x at the horizon; skies already that bright stay as they are.
const SKY_TOP_LIFT=Vector2(.13,1.6)
const SKY_HORIZON_LIFT=Vector2(.42,2.2)

static func scaled(color: Color,lift: Vector2) -> Color:
	var factor=clampf(lift.x/maxf(.01,color.get_luminance()),1.0,lift.y)
	return Color(minf(1,color.r*factor),minf(1,color.g*factor),minf(1,color.b*factor),color.a)

static func coast_radius(angle: float,world_seed: int,world_realm: int) -> float:
	if world_realm==RealmWorld.ARENA: return 72.0
	var phase=float(world_seed%23)*.03+world_realm*.4
	var shape: Vector3=GRADE[grade_of(world_realm)].shape
	return 344+24*sin(3*(angle+phase))+14*sin(5*(angle-phase))+8*cos(7*(angle+phase*.5))+shape.x*sin(4*(angle-phase*1.3))+shape.y*sin(6*(angle+phase))+shape.z

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
		stars.visible=biome in [2,5];moon.visible=biome==2 and not SkyLook.has(realm)
		SkyLook.apply(sky_paint,realm,biome)
		weather.emitting=biome in [0,1,3,4,5,6]
		weather.amount=240 if biome==1 else 80 if biome in [3,4,5,6] else 38
		var material: ParticleProcessMaterial=weather.process_material
		# Marsh: rain in wind; cloud: drifting motes; hell: rising sparks.
		# Junkyard: rust flakes drifting down through the smog.
		material.gravity=Vector3(3,-13,1) if biome==1 else Vector3(2,-.5,1) if biome==3 else Vector3(-2,4,0) if biome==4 else Vector3(1.5,-1.6,.6) if biome==6 else Vector3(-2,.7,0)
		material.initial_velocity_min=1.5;material.initial_velocity_max=4.0 if biome==1 else 2.5
		var paint=StandardMaterial3D.new();paint.albedo_color=Color("b5dfec") if biome==1 else Color("fff8ed") if biome==3 else Color("ffcb88") if biome==4 else Color("bd9af0") if biome==5 else Color("d8925a") if biome==6 else Color("a0c681")
		paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		var mesh=SphereMesh.new();mesh.radius=.02 if biome==1 else .015 if biome==0 else .05;mesh.height=.9 if biome==1 else .06 if biome==0 else .18;mesh.material=paint;weather.draw_pass_1=mesh
	weather.emitting=not eclipse and biome in [0,1,3,4,5,6]
	weather.position=p+Vector3.UP*8
	for i in range(low_mist.size()):
		var mist=low_mist[i];mist.visible=biome in [1,3] and not eclipse
		mist.emitting=mist.visible
		# Keep the immediate combat/loot area clear; wisps stay out in scenery.
		var site=p+Vector3(-14 if i==0 else 14,0,-12)
		mist.position=Vector3(site.x,height_at(site.x,site.z)+.18,site.z)
	sky_top=sky_top.lerp(Color("21192f") if eclipse else SkyLook.top(realm,biome),1-exp(-delta*.6));sky_horizon=sky_horizon.lerp(Color("77556c") if eclipse else SkyLook.horizon(realm,biome),1-exp(-delta*.6))
	var grade: Dictionary=GRADE[grade_of(realm)]
	if grade.mix>0 and not eclipse: sky_top=sky_top.lerp(grade.top,grade.mix*(1-exp(-delta*.6))*4.0);sky_horizon=sky_horizon.lerp(grade.horizon,grade.mix*(1-exp(-delta*.6))*4.0)
	# The sky itself is drawn brighter than its fog colour (user request, October 25:
	# the sunlit ground outshone a near-black sky). The fog keeps the darker horizon,
	# so distant ground still is not washed out, and sits as a dark band under the sky.
	sky_paint.set_shader_parameter("top_color",scaled(sky_top,SKY_TOP_LIFT));sky_paint.set_shader_parameter("horizon_color",scaled(sky_horizon,SKY_HORIZON_LIFT))
	for pair in [["moon_strength",biome==2],["space_strength",biome==5],["fire_strength",biome==4]]:
		var parameter=sky_paint.get_shader_parameter(pair[0]);var previous=float(parameter) if parameter!=null else 0.0;sky_paint.set_shader_parameter(pair[0],lerpf(previous,1.0 if pair[1] else 0.0,1-exp(-delta*.6)))
	environment.fog_light_color=sky_horizon
	BiomeLook.apply(self,biome,grade,1-exp(-delta*.6))
	if is_instance_valid(island_air):
		island_air.position=p+Vector3.UP*6
		if island_air.has_meta("embers"): island_air.get_meta("embers").position=p+Vector3.DOWN*1.0
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
	return biome_of(realm)

func crossing_distance(p: Vector3) -> float:
	var radius=Vector2(p.x,p.z).length()
	var angle=fposmod(atan2(p.z,p.x)+float(seed_value%23)*.03+realm*.4,BIOME_ARC)
	return minf(absf(radius-65),radius*sin(minf(angle,BIOME_ARC-angle)))

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
	if realm==RealmWorld.ARENA:
		var distance=Vector2(x,z).length()
		return 1.3+sin(x*.06)*cos(z*.06)*.4-maxf(0,distance-64)*.45
	var p=Vector3(x,0,z)
	var biome=biome_at(p)
	# Reduced terrain amplitudes to keep slopes navigable for enemies.
	var amplitudes=[6.0,4.0,6.0,8.0,6.0,6.0,5.0]
	var index=biome
	var amplitude=amplitudes[index]
	# Smooth amplitudes near angular boundaries; no invisible height discontinuities.
	var base=noise.get_noise_2d(x,z)*6+sin(x*.012)*cos(z*.012)*3
	var mountain=maxf(0,noise.get_noise_2d(x+790,z-530))*12
	var blend=smoothstep(65.0,120.0,Vector2(x,z).length())
	var terrain=[sin(x*.06)*cos(z*.06)*1.5,-absf(sin(x*.025)*sin(z*.035))*3,-pow(maxf(0,noise.get_noise_2d(x*2,z*2)),2)*6,sin(x*.025)*cos(z*.025)*7,absf(sin(x*.032)+cos(z*.041))*4,sin(x*.018)*cos(z*.022)*9,maxf(0.0,sin(x*.05+cos(z*.03))*cos(z*.045))*5.0-1.0]
	var relief=terrain[index]
	var original=base+mountain*blend*(amplitude/28.0)+relief*blend
	var terrace=floorf(original/5.0)*5.0+smoothstep(.62,1.0,fposmod(original,5.0)/5.0)*5.0
	var route=1.0-smoothstep(4.0,12.0,crossing_distance(p))
	var inland=lerpf(terrace,original*.85,route)*smoothstep(0.0,28.0,Vector2(x,z).length())
	# Flat ground under a labyrinth (Labyrinth.flatness).
	if not labyrinth.is_empty(): inland=lerpf(inland,Labyrinth.FLAT_Y,Labyrinth.flatness(labyrinth,x,z))
	var edge=Vector2(x,z).length();var coast=shore_radius(p)
	var shore=2.0-maxf(0.0,edge-(coast-6.0))/3.0
	if edge<=coast: return lerpf(inland,shore,smoothstep(coast-32.0,coast-4.0,edge))+ClimbMap.lift(climb_mesas,x,z)+Labyrinth.lift(labyrinth,x,z)
	# Past the coast the island ends in a rounded rocky rim (October 31: no sea; the
	# hero walks over it onto the underside, Underside).
	var over=clampf((edge-coast)/Underside.RIM,0.0,1.0)
	return shore-Underside.THICK*(1.0-cos(over*PI*.5))

# The underside's surface: a hanging rock belly, deepest under the middle, meeting
# the rim's lip at the coast plus Underside.RIM.
func under_height(x: float,z: float) -> float:
	var p=Vector3(x,0,z)
	var inside=maxf(0.0,shore_radius(p)+Underside.RIM-Vector2(x,z).length())
	var depth=minf(55.0,inside*.38)+noise.get_noise_2d(x*1.6,z*1.6)*2.5*smoothstep(0.0,12.0,inside)
	var lip=2.0-(Underside.RIM+6.0)/3.0-Underside.THICK  # the rim's foot, see compute_height_at
	return lip-depth

func portal_site() -> Vector3:
	if realm==RealmWorld.ARENA: return Vector3(0,1.5,48)
	var p=landmarks[(realm+1)%landmarks.size()]+Vector3(18,0,16)
	p.y=height_at(p.x,p.z)+.2
	return p

func model(name: String,height: float) -> Node3D:
	# The final boss is built at full size by its own rig (ColossusRig).
	if name=="boss_8":
		var colossus=ColossusRig.new();colossus.setup(name);return colossus
	if name.begins_with("boss_"):
		var rig=ActorRig.new();rig.setup(name);rig.scale=Vector3.ONE*(height/3.0);return rig
	# Ordinary enemies are cartoon creatures (CartoonBook), built to their height.
	if name.begins_with("creature_"):
		var creature=CartoonCreatureRig.new();creature.setup(name);creature.scale=Vector3.ONE*(height/maxf(.1,creature.model_height));return creature
	var asset=name if name.begins_with("creature_") else "count_duck" if name=="rubber_duck_toy" else "hero_"+name
	if ResourceLoader.exists("res://assets/style3d/"+asset+".glb") or CartoonHeroes.has(asset):
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
	labyrinth=Labyrinth.plan(seed_value,realm)
	climb_mesas=ClimbMap.plan(self)
	for child in get_children():
		remove_child(child);child.queue_free()
	chunks.clear();pending.clear();landmarks.clear();building_sites.clear();harvest_sites.clear();last_cell=Vector2i(999,999);stream_signature=""
	clouds.clear();border_steam.clear();border_patches.clear();low_mist.clear()
	make_environment();make_material();make_boundaries();make_landmarks()
	ClimbMap.build_props(self)
	Labyrinth.build_walls(self)
	# Natural landmarks and organic scenery replace decorative architecture.
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
	terrain_material.set_shader_parameter("red_moon",realm==RealmWorld.ARENA)
	terrain_material.set_shader_parameter("map_biome",float(biome_of(realm)) if realm<ARENA else -1.0)
	var grade: Dictionary=GRADE[grade_of(realm)]
	terrain_material.set_shader_parameter("shape",grade.shape);terrain_material.set_shader_parameter("corruption",grade.corruption)
	if grade.has("vein"): terrain_material.set_shader_parameter("vein_color",grade.vein);terrain_material.set_shader_parameter("blight_tint",grade.tint)
	for i in range(BIOME_COUNT): terrain_material.set_shader_parameter("t"+str(i),load("res://assets/illustrated/forge-basalt-moss.png" if i==0 else "res://assets/illustrated/terrain-moss-v2.png" if i==1 else "res://assets/illustrated/terrain-stone-v2.png"))
	scenery_material=PaintedBatch.material()
	if GRADE[grade_of(realm)].has("scenery"): scenery_material.set_shader_parameter("tint",GRADE[grade_of(realm)].scenery)
	scenery_material.set_shader_parameter("fade_near",true)
	scenery_material.next_pass.set_shader_parameter("fade_near",true)

func make_chunk(cell: Vector2i):
	if chunks.has(cell): return
	var root=Node3D.new();root.position=Vector3(cell.x*CHUNK,0,cell.y*CHUNK);add_child(root);chunks[cell]=root
	var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var resolution=16
	var step=CHUNK/resolution
	var belly=SurfaceTool.new();belly.begin(Mesh.PRIMITIVE_TRIANGLES);var belly_faces=0;var top_faces=0
	for x in range(resolution):
		for z in range(resolution):
			var ox=cell.x*CHUNK+x*step;var oz=cell.y*CHUNK+z*step
			var centre=Vector3(ox+step*.5,0,oz+step*.5)
			# Quads wholly past RIM_START are left to the smooth rim ring (make_rim).
			var beyond=Vector2(centre.x,centre.z).length()-step*.71-(shore_radius(centre)-RIM_START)
			if realm!=RealmWorld.ARENA and beyond>0.0: continue
			top_faces+=2
			for v in [Vector2(ox,oz),Vector2(ox+step,oz),Vector2(ox,oz+step),Vector2(ox+step,oz),Vector2(ox+step,oz+step),Vector2(ox,oz+step)]:
				var color=Color.WHITE;color.a=float(biome_at(Vector3(v.x,0,v.y)))/float(BIOME_COUNT-1)
				surface.set_color(color);surface.set_uv(v*.12)
				surface.add_vertex(Vector3(v.x-root.position.x,raw_height_at(v.x,v.y),v.y-root.position.z))
			if realm==RealmWorld.ARENA: continue
			# The belly, wound the other way so it faces down.
			belly_faces+=2
			for v in [Vector2(ox,oz),Vector2(ox,oz+step),Vector2(ox+step,oz),Vector2(ox+step,oz),Vector2(ox,oz+step),Vector2(ox+step,oz+step)]:
				belly.add_vertex(Vector3(v.x-root.position.x,under_height(v.x,v.y),v.y-root.position.z))
	if top_faces>0:
		surface.generate_normals()
		var terrain=MeshInstance3D.new();terrain.mesh=surface.commit();terrain.material_override=terrain_material;root.add_child(terrain)
		terrain.create_trimesh_collision();CrowdMover.mark_terrain(terrain)
	if belly_faces>0:
		belly.generate_normals()
		var underneath=MeshInstance3D.new();underneath.name="Underside";underneath.mesh=belly.commit();underneath.material_override=under_material
		underneath.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(underneath)
	make_lava_chunk(root,cell)
	var scenery_groups={}
	var local_rng=RandomNumberGenerator.new();local_rng.seed=seed_value+cell.x*73856093+cell.y*19349663
	for i in range(26):
		var p=Vector3(cell.x*CHUNK+local_rng.randf()*CHUNK,0,cell.y*CHUNK+local_rng.randf()*CHUNK)
		if Vector2(p.x,p.z).length()>shore_radius(p)-25: continue
		if realm==RealmWorld.ARENA and Vector2(p.x,p.z).length()<38: continue
		var portal=portal_site()
		if Vector2(p.x-portal.x,p.z-portal.z).length()<14: continue
		if Vector2(p.x-60,p.z+35).length()<7: continue
		if Vector2(p.x,p.z).length()<13 or absf(p.x+sin(p.z*.035)*9)<6: continue
		if lava_at(p): continue  # Keep the molten channels legible and traversable.
		if crossing_distance(p)<12 and i%3!=0: continue
		if MassiveArchitecture.occupied(self,p): continue
		# The landmark groves bring their own trees; stray ones would block the lane.
		if landmarks.any(func(site):return Vector2(site.x-p.x,site.z-p.z).length()<24): continue
		if harvest_sites.any(func(site):return Vector2(site.x-p.x,site.z-p.z).length()<4): continue
		p.y=height_at(p.x,p.z)
		var biome=biome_at(p)
		if biome==3 and i%2!=0: continue
		var prop=Node3D.new();prop.position=p-root.position;root.add_child(prop)
		# Cached organic meshes replace every old architectural prop variant.
		var variant=local_rng.randi_range(0,2)
		# Keep the Cloudwilds' large silhouettes in the distance rather than
		# filling the ordinary camera with overlapping trunks and roots.
		if biome==3 and variant==0 and i%6!=0: variant=local_rng.randi_range(1,2)
		if biome==3 and variant==0 and landmarks.any(func(site):return Vector2(site.x-p.x,site.z-p.z).length()<55):
			variant=local_rng.randi_range(1,2)
		var key=Vector2i(biome,variant)
		if not prop_meshes.has(key): prop_meshes[key]=NatureScenery.mesh(self,biome,variant)
		if not scenery_groups.has(key): scenery_groups[key]=[]
		var scale_value=local_rng.randf_range(.65,1.15) if biome!=3 else local_rng.randf_range(.55,.8)
		prop.rotation.y=local_rng.randf()*TAU
		scenery_groups[key].append(prop.transform.scaled_local(Vector3.ONE*scale_value))
		NatureScenery.collision(prop,biome,variant,scale_value)
		# Emissive sap is batched on all plants; only sparse plants cast local light.
		if i%9==8: NatureScenery.light(prop,biome)
	for path in scenery_groups:
		var instances=MultiMesh.new();instances.transform_format=MultiMesh.TRANSFORM_3D;instances.mesh=prop_meshes[path];instances.instance_count=scenery_groups[path].size()
		for index in range(instances.instance_count): instances.set_instance_transform(index,scenery_groups[path][index])
		var combined=MultiMeshInstance3D.new();combined.multimesh=instances;combined.material_override=scenery_material;combined.visibility_range_end=SCENERY_RANGE*view_scale;combined.visibility_range_end_margin=15;root.add_child(combined)
	GroundCover.build(self,root,cell,local_rng)

# Candy Hell (biome 4): three deterministic winding lava streams.
# Render into terrain chunks so distant geometry is discarded with the chunk.
func lava_center(radius: float,lane: int) -> Vector3:
	var phase=float(seed_value%23)*.03+realm*.4
	var angle=4.5*BIOME_ARC-phase+float(lane)*.17+sin(radius*.024+lane*1.7)*.035
	return Vector3(cos(angle)*radius,0,sin(angle)*radius)

func lava_at(p: Vector3) -> bool:
	if realm==RealmWorld.ARENA or biome_at(p)!=4: return false
	var radius=Vector2(p.x,p.z).length()
	if radius<95 or radius>310: return false
	for lane in [-1,0,1]:
		var center=lava_center(radius,lane)
		if Vector2(center.x-p.x,center.z-p.z).length()<3.1: return true
	return false

func make_lava_chunk(root: Node3D,cell: Vector2i):
	if realm==RealmWorld.ARENA: return
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
			# Three chunks out (192 m): the longer fog would show the edge of two.
			for x in range(-3,4):
				for z in range(-3,4):
					var key=cell+Vector2i(x,z)
					if absi(key.x)<=ceili(EXTENT/CHUNK) and absi(key.y)<=ceili(EXTENT/CHUNK): wanted[key]=true
		for key in wanted:
			if not chunks.has(key): pending.append(key)
		pending.sort_custom(func(a,b):return a.distance_squared_to(centers[0])<b.distance_squared_to(centers[0]))
		for key in chunks.keys():
			if centers.all(func(c):return maxi(absi(key.x-c.x),absi(key.y-c.y))>4): chunks[key].queue_free();chunks.erase(key)
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

# The island's edge as one smooth ring (October 31), built radially so the coast is
# round rather than the terrain grid's saw teeth: a band of ground from RIM_START
# metres inside the coast, the rounded rim, and a band of the belly back in to
# RIM_START. It sits a hair inside the chunk surfaces, so where both exist the
# chunks show and the ring fills the jagged gaps. It has collision for the band of
# ground the chunks leave out.
const RIM_START=10.0
const RIM_SEGMENTS=1440
func make_rim():
	var top=SurfaceTool.new();top.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wall=SurfaceTool.new();wall.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Profile offsets from the coast: ground, rim, then the belly heading back in.
	var ground=[-RIM_START,-7.5,-5.0,-3.0,-1.5,0.0]
	var rim=[0.0,.8,1.6,2.4,3.2,Underside.RIM]
	var belly=[Underside.RIM,2.0,0.0,-2.5,-5.0,-7.5,-RIM_START]
	var rows=[]
	for i in range(RIM_SEGMENTS+1):
		var angle=float(i)/RIM_SEGMENTS*TAU;var direction=Vector2(cos(angle),sin(angle))
		var coast=coast_radius(angle,seed_value,realm)
		var row={"ground":[],"rim":[],"belly":[]}
		for o in ground:
			var q=direction*(coast+o);row.ground.append(Vector3(q.x,height_at(q.x,q.y)-.06,q.y))
		# The rim's own curve, exactly (the grid's interpolation is too coarse here).
		for o in rim:
			var q=direction*(coast+o);row.rim.append(row.ground[-1] if o==0.0 else Vector3(q.x,compute_height_at(q.x,q.y)-.06,q.y))
		for o in belly:
			var q=direction*(coast+o);row.belly.append(Vector3(q.x,under_height(q.x,q.y)+.06,q.y))
		rows.append(row)
	# Ground and rim face up and out, the belly faces down.
	for i in range(RIM_SEGMENTS):
		var a=rows[i];var b=rows[i+1]
		strip(top,a.ground,b.ground,true)
		strip(wall,a.rim,b.rim,true)
		strip(wall,a.belly,b.belly,true)
	for pair in [[top,terrain_material,"RimGround"],[wall,under_material,"RimWall"]]:
		pair[0].generate_normals()
		var node=MeshInstance3D.new();node.name=pair[2];node.mesh=pair[0].commit();node.material_override=pair[1]
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if pair[2]=="RimWall" else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(node)
		if pair[2]=="RimGround": node.create_trimesh_collision();CrowdMover.mark_terrain(node)

# Two neighbouring profile rows joined into quads. With flip, the ground and rim
# face up and out and the belly faces down (Godot's front faces are clockwise).
func strip(surface: SurfaceTool,a: Array,b: Array,flip: bool):
	for k in range(a.size()-1):
		var quad=[a[k],b[k],a[k+1],b[k],b[k+1],a[k+1]] if not flip else [a[k],a[k+1],b[k],b[k],a[k+1],b[k+1]]
		for v in quad:
			var color=Color.WHITE;color.a=float(biome_at(v))/float(BIOME_COUNT-1)
			surface.set_color(color);surface.set_uv(Vector2(v.x,v.z)*.12);surface.add_vertex(v)

func make_boundaries():
	# No sea since October 31: the island floats (Underside). A soft light from below
	# shows its belly while the hero is under it.
	var under_light=DirectionalLight3D.new();under_light.name="UnderLight";under_light.rotation_degrees=Vector3(70,20,0)
	under_light.light_energy=.55;under_light.light_color=Color("ffe6c8");under_light.shadow_enabled=false;under_light.visible=false;add_child(under_light)
	under_material=ShaderMaterial.new();under_material.shader=load("res://shaders/island_underside.gdshader")
	under_material.set_shader_parameter("phase",float(seed_value%23)*.03+realm*.4)
	for i in range(BIOME_COUNT): under_material.set_shader_parameter("glow"+str(i),NatureScenery.GLOW[i])
	if realm!=RealmWorld.ARENA: make_rim()
	for side in [-1,1]:
		for axis in [0,2]:
			var mesh=BoxMesh.new();mesh.size=Vector3(16,100,EXTENT*2+24) if axis==0 else Vector3(EXTENT*2+24,100,16)
			var p=Vector3.ZERO;p[axis]=side*(EXTENT+8);p.y=36
			var ridge=ToonArt.part(self,mesh,Color("a7b6a2"),p);ridge.create_trimesh_collision();ridge.visible=false
	# The coast's boiling steam went with the sea; border_steam stays empty.

func make_environment():
	var env=Environment.new();env.background_mode=Environment.BG_SKY
	var sky=Sky.new();var gradient=ShaderMaterial.new();gradient.shader=load("res://shaders/biome_sky.gdshader");gradient.set_shader_parameter("paint",load("res://assets/illustrated/terrain-2.png"));sky.sky_material=gradient;sky.process_mode=Sky.PROCESS_MODE_REALTIME;env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("e6efff");env.ambient_light_energy=.36
	# Painterly grade: rich saturated midtones, firmer contrast, glowing hot accents.
	env.adjustment_enabled=true;env.adjustment_saturation=1.22;env.adjustment_contrast=1.1
	env.glow_enabled=true;env.glow_intensity=.55;env.glow_strength=.9;env.glow_bloom=.04;env.glow_hdr_threshold=1.05;env.glow_blend_mode=Environment.GLOW_BLEND_MODE_SOFTLIGHT
	# Keep the playable foreground crisp; distant scenery still fades out.
	env.fog_enabled=true;env.fog_mode=Environment.FOG_MODE_DEPTH;env.fog_light_color=sky_horizon;env.fog_density=1.0;env.fog_depth_begin=35;env.fog_depth_end=155;env.fog_sky_affect=0
	var world_env=WorldEnvironment.new();world_env.environment=env;add_child(world_env)
	sky_paint=gradient;environment=env;active_biome=-1
	weather=GPUParticles3D.new();weather.amount=180;weather.lifetime=4;weather.visibility_aabb=AABB(Vector3(-40,-55,-40),Vector3(80,85,80));add_child(weather)
	var particles=ParticleProcessMaterial.new();particles.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX;particles.emission_box_extents=Vector3(14,4,14);particles.direction=Vector3.DOWN;particles.spread=35;weather.process_material=particles
	make_low_mist()
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-35,0);sun.light_energy=1.2;sun.light_color=Color("ffe0ad");sun.shadow_enabled=true;sun.directional_shadow_max_distance=38;add_child(sun);sun_light=sun
	var grade: Dictionary=GRADE[grade_of(realm)]
	if grade.has("sun"): sun.light_color=grade.sun;sun.light_energy=float(grade.sun_energy);sun.rotation_degrees.x=-30.0 if realm==1 else -24.0
	if grade.has("air"): make_island_air(grade)
	for i in range(16):
		var cloud=Node3D.new();cloud.position=Vector3(cos(i*TAU/16)*370,60+sin(i)*15,sin(i*TAU/16)*370);add_child(cloud);clouds.append(cloud)
		for j in range(3): ToonArt.ball(cloud,Color("fff2de"),Vector3(j*6,0,0),Vector3(20,9,12))
	stars=MultiMeshInstance3D.new();var constellation=MultiMesh.new();constellation.transform_format=MultiMesh.TRANSFORM_3D;var star=SphereMesh.new();star.radius=.4;star.height=.8;star.radial_segments=6;star.rings=4;constellation.mesh=star;constellation.instance_count=180
	for i in range(180): constellation.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(cos(i*2.4)*390,80+rng.randf()*180,sin(i*2.4)*390)))
	stars.multimesh=constellation;var starlight=StandardMaterial3D.new();starlight.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;starlight.albedo_color=Color("fff1c8");stars.material_override=starlight;add_child(stars)
	moon=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=24;sphere.height=48;moon.mesh=sphere;moon.position=Vector3(220,110,-280);var paint=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;paint.albedo_texture=load("res://assets/illustrated/terrain-2.png");moon.material_override=paint;add_child(moon)

# Drifting air of the later islands around the hero: rising blight motes on the
# second, falling ash with a few embers on the third.
func make_island_air(grade: Dictionary):
	island_air=GPUParticles3D.new();island_air.amount=160;island_air.lifetime=5.0;island_air.local_coords=false
	island_air.visibility_aabb=AABB(Vector3(-40,-20,-40),Vector3(80,50,80))
	var process=ParticleProcessMaterial.new();process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX;process.emission_box_extents=Vector3(26,7,26)
	process.direction=Vector3.UP if grade.air_rises else Vector3.DOWN;process.spread=25.0
	process.initial_velocity_min=.4;process.initial_velocity_max=1.4
	process.gravity=Vector3(.6,.5,.2) if grade.air_rises else Vector3(.9,-1.2,.3)
	process.scale_min=.6;process.scale_max=1.4
	var ramp=Gradient.new();ramp.offsets=PackedFloat32Array([0,.2,.8,1])
	var air: Color=grade.air;ramp.colors=PackedColorArray([Color(air,0),Color(air,.9),Color(air,.7),Color(air,0)])
	var ramp_texture=GradientTexture1D.new();ramp_texture.gradient=ramp;process.color_ramp=ramp_texture
	island_air.process_material=process
	var mote=QuadMesh.new();mote.size=Vector2(.12,.12) if grade.air_rises else Vector2(.16,.1)
	var paint=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;paint.vertex_color_use_as_albedo=true
	paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;paint.billboard_mode=BaseMaterial3D.BILLBOARD_PARTICLES
	paint.emission_enabled=grade.air_rises;paint.emission=air
	mote.material=paint;island_air.draw_pass_1=mote;island_air.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(island_air);island_air.emitting=true
	if not grade.air_rises:
		# A few rising embers among the ash.
		var embers=island_air.duplicate();embers.amount=40;add_child(embers)
		var hot: ParticleProcessMaterial=process.duplicate();hot.direction=Vector3.UP;hot.gravity=Vector3(.4,1.2,0)
		var hot_ramp=Gradient.new();hot_ramp.offsets=PackedFloat32Array([0,.2,1]);hot_ramp.colors=PackedColorArray([Color(1,.6,.2,0),Color(1,.55,.15,1),Color(1,.2,.05,0)])
		var hot_texture=GradientTexture1D.new();hot_texture.gradient=hot_ramp;hot.color_ramp=hot_texture;embers.process_material=hot
		var spark=QuadMesh.new();spark.size=Vector2(.09,.09);var spark_paint=paint.duplicate();spark_paint.emission_enabled=true;spark_paint.emission=Color("ff8a3a");spark.material=spark_paint;embers.draw_pass_1=spark
		island_air.set_meta("embers",embers)

func make_landmarks():
	if realm==RealmWorld.ARENA:
		landmarks.append(Vector3.ZERO);return
	for slot in range(BIOME_COUNT):
		var angle=(slot+.5)*BIOME_ARC-float(seed_value%23)*.03-realm*.4
		var p=Vector3(cos(angle)*175,0,sin(angle)*175)
		p.y=height_at(p.x,p.z)
		landmarks.append(p)
		preload("res://scripts/biome_landmarks.gd").build(self,biome_of(realm),p)

func make_low_mist():
	var puff=SphereMesh.new();puff.radius=.6;puff.height=.10;puff.radial_segments=12;puff.rings=4
	var paint=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;paint.albedo_color=Color(.39,.72,.68,.09);puff.material=paint
	for i in range(2):
		var mist=GPUParticles3D.new();mist.name="LowMist_"+str(i);mist.amount=12;mist.lifetime=3
		mist.emitting=false;mist.visibility_aabb=AABB(Vector3(-7,-1,-7),Vector3(14,3,14));mist.draw_pass_1=puff
		mist.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material=ParticleProcessMaterial.new();material.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX
		material.emission_box_extents=Vector3(3,.03,3);material.direction=Vector3.RIGHT;material.spread=10
		material.gravity=Vector3.ZERO;material.initial_velocity_min=.15;material.initial_velocity_max=.35;material.scale_min=1.5;material.scale_max=3
		var gradient=Gradient.new();gradient.set_color(0,Color(1,1,1,0));gradient.set_color(1,Color(1,1,1,0));gradient.add_point(.3,Color.WHITE)
		var ramp=GradientTexture1D.new();ramp.gradient=gradient;material.color_ramp=ramp
		mist.process_material=material;add_child(mist);low_mist.append(mist)

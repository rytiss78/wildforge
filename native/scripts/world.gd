extends Node3D
class_name RealmWorld

const EXTENT=500.0
const CHUNK=64.0
const NAMES=["Sunlit Frontier","Wild Highlands","Skyward Reach"]
const BIOMES=["Clover Woods","Puffcap Marsh","Moon Craters","Cloud City","Candy Hell","Starfall Space"]
const CREATURES=["acorn","toad","crab","penguin","lizard","beetle"]
const COLORS=[Color("9cb88c"),Color("91b3ab"),Color("b4c5df"),Color("d9eaed"),Color("e69479"),Color("ab96c5")]
var realm=0
var seed_value=0
var noise=FastNoiseLite.new()
var height_vertices={}
var rng=RandomNumberGenerator.new()
var landmarks=[]
var chunks={}
var pending=[]
var terrain_material: ShaderMaterial
var scenery_material: ShaderMaterial
var last_cell=Vector2i(999,999)
var sky_paint: ShaderMaterial
var sky_top=Color("76c8e6")
var sky_horizon=Color("dfedda")
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
static var prop_meshes={}
const SKY_TOP=[Color("76c8e6"),Color("7fb7a9"),Color("18234d"),Color("83cdeb"),Color("f49a78"),Color("302457")]
const SKY_HORIZON=[Color("dfedda"),Color("c1d8b7"),Color("a3b8d9"),Color("fff7e2"),Color("ffd3a0"),Color("ba9bd5")]

func dangerous(p: Vector3) -> bool:
	return maxf(absf(p.x),absf(p.z))>=475

func weather_tick(delta: float,p: Vector3):
	var biome=biome_at(p)
	if active_biome!=biome:
		active_biome=biome
		for cloud in clouds: cloud.visible=biome in [0,1,3]
		stars.visible=biome in [2,5];moon.visible=biome==2
		weather.emitting=biome in [0,1,3,4,5]
		var material: ParticleProcessMaterial=weather.process_material
		material.gravity=Vector3(4,-12,1) if biome==1 else Vector3(2,-2,1) if biome==3 else Vector3(-3,1,0)
		material.initial_velocity_min=2;material.initial_velocity_max=5 if biome==1 else 2.5
		var paint=StandardMaterial3D.new();paint.albedo_color=Color("b5dfec") if biome==1 else Color("fff8ed") if biome==3 else Color("ffcb88") if biome==4 else Color("bd9af0") if biome==5 else Color("a0c681")
		paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		var mesh=SphereMesh.new();mesh.radius=.035 if biome==1 else .07;mesh.height=.6 if biome==1 else .14;mesh.material=paint;weather.draw_pass_1=mesh
	weather.position=p+Vector3.UP*8
	sky_top=sky_top.lerp(SKY_TOP[biome],1-exp(-delta*.6));sky_horizon=sky_horizon.lerp(SKY_HORIZON[biome],1-exp(-delta*.6))
	sky_paint.set_shader_parameter("top_color",sky_top);sky_paint.set_shader_parameter("horizon_color",sky_horizon)
	for pair in [["moon_strength",biome==2],["space_strength",biome==5],["fire_strength",biome==4]]:
		var parameter=sky_paint.get_shader_parameter(pair[0]);var previous=float(parameter) if parameter!=null else 0.0;sky_paint.set_shader_parameter(pair[0],lerpf(previous,1.0 if pair[1] else 0.0,1-exp(-delta*.6)))
	environment.fog_light_color=sky_horizon
	environment.fog_density=lerpf(environment.fog_density,.013 if biome in [1,3] else .007,1-exp(-delta*.6))
	edge_near=false
	for index in range(border_steam.size()):
		var axis=0 if index==0 else 2;var distance_value=absf(p[axis])
		var nearby=distance_value>435;edge_near=edge_near or nearby
		border_steam[index].emitting=nearby;border_patches[index].visible=nearby
		if not nearby: continue
		var point=p;point[axis]=signf(p[axis])*475;point.y=height_at(point.x,point.z)+.15
		border_steam[index].position=point;border_patches[index].position=point

func biome_at(p: Vector3) -> int:
	if Vector2(p.x,p.z).length()<65: return 0
	return int(floor(fposmod(atan2(p.z,p.x)+float(seed_value%23)*.03+realm*.4,TAU)/(TAU/6)))

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
	var p=Vector3(x,0,z)
	var biome=biome_at(p)
	var angle=fposmod(atan2(z,x)+float(seed_value%23)*.03+realm*.4,TAU)/(TAU/6)
	var amplitudes=[9.0,5.0,11.0,28.0,19.0,16.0]
	var index=int(floor(angle))
	var amplitude=lerpf(amplitudes[index],amplitudes[(index+1)%6],smoothstep(0.0,1.0,fposmod(angle,1.0)))
	# Smooth amplitudes near angular boundaries; no invisible height discontinuities.
	var base=noise.get_noise_2d(x,z)*9+sin(x*.012)*cos(z*.012)*4
	var mountain=maxf(0,noise.get_noise_2d(x+790,z-530))*25
	var blend=smoothstep(65.0,120.0,Vector2(x,z).length())
	var terrain=[sin(x*.06)*cos(z*.06)*1.5,-absf(sin(x*.025)*sin(z*.035))*3,-pow(maxf(0,noise.get_noise_2d(x*2,z*2)),2)*28,sin(x*.025)*cos(z*.025)*7,absf(sin(x*.032)+cos(z*.041))*4,sin(x*.018)*cos(z*.022)*9]
	var relief=lerpf(terrain[index],terrain[(index+1)%6],smoothstep(0.0,1.0,fposmod(angle,1.0)))
	return (base+mountain*blend*(amplitude/28.0)+relief*blend)*smoothstep(0.0,28.0,Vector2(x,z).length())+pow(clampf((maxf(absf(x),absf(z))-455)/45,0,1),2)*16

func model(name: String,height: float) -> Node3D:
	if ResourceLoader.exists("res://assets/illustrated/"+("creatures/" if name.begins_with("creature_") else "heroes/")+name+".png") or name in ["pipe_wrench","rubber_duck_toy","sweet_potato","marble_bust_01","street_rat","hamburger_buns","florist","acorn","toad","crab","penguin","lizard","beetle"]:
		var rig=ActorRig.new();rig.setup(name);rig.scale=Vector3.ONE*(height/1.65)
		return rig
	return ToonArt.make(name,height)

func build(index: int,world_seed: int):
	height_vertices.clear()
	realm=index;seed_value=world_seed;rng.seed=world_seed+index*763
	noise.seed=world_seed%2147483647;noise.frequency=.014;noise.fractal_octaves=3;noise.fractal_gain=.4
	for child in get_children():
		remove_child(child);child.queue_free()
	chunks.clear();pending.clear();landmarks.clear();last_cell=Vector2i(999,999)
	clouds.clear();border_steam.clear();border_patches.clear()
	make_environment();make_material();make_boundaries();make_landmarks()
	# Synchronous collision cover at spawn; later chunks are budgeted across frames.
	for x in range(-2,3):
		for z in range(-2,3): make_chunk(Vector2i(x,z))
	stream(Vector3.ZERO)

func make_material():
	var shader=load("res://shaders/terrain.gdshader")
	terrain_material=ShaderMaterial.new();terrain_material.shader=shader;terrain_material.set_shader_parameter("phase",float(seed_value%23)*.03+realm*.4)
	for i in range(6): terrain_material.set_shader_parameter("t"+str(i),load("res://assets/illustrated/terrain-"+str(i)+".png"))
	scenery_material=PaintedBatch.material()

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
	var scenery=[]
	var scenery_groups={}
	var local_rng=RandomNumberGenerator.new();local_rng.seed=seed_value+cell.x*73856093+cell.y*19349663
	for i in range(12):
		var p=Vector3(cell.x*CHUNK+local_rng.randf()*CHUNK,0,cell.y*CHUNK+local_rng.randf()*CHUNK)
		if Vector2(p.x,p.z).length()<13 or absf(p.x+sin(p.z*.035)*9)<6: continue
		p.y=height_at(p.x,p.z)
		var biome=biome_at(p)
		var prop=Node3D.new();prop.position=p-root.position;root.add_child(prop)
		# Keep greenery and terrain landmarks; large structures are sparse and smaller.
		var variant=local_rng.randi_range(0,3) if i<11 else local_rng.randi_range(4,5)
		var model_path="res://assets/style3d/prop_%d_%d.glb" % [biome,variant]
		if ResourceLoader.exists(model_path):
			var baked_path="res://assets/style3d/baked/prop_%d_%d.res" % [biome,variant]
			var baked=ResourceLoader.exists(baked_path)
			var asset=Node3D.new() if baked else load(model_path).instantiate();prop.add_child(asset)
			var scale_value=local_rng.randf_range(.9,1.7) if variant<4 else local_rng.randf_range(1.3,2.0)
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
			PaintedBatch.collect(prop,scenery)
			continue
		var art_path="res://assets/illustrated/scenery/prop_%d_%d.png" % [biome,i%4]
		if ResourceLoader.exists(art_path):
			var art=Sprite3D.new();art.texture=load(art_path);var size=local_rng.randf_range(3.5,7.5);art.pixel_size=size/256;art.position.y=size*.45;art.billboard=BaseMaterial3D.BILLBOARD_ENABLED;art.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD;art.alpha_scissor_threshold=.2;art.shaded=false;prop.add_child(art)
			var solid=StaticBody3D.new();prop.add_child(solid);solid.collision_layer=1
			var obstacle=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.5;capsule.height=2;obstacle.shape=capsule;obstacle.position.y=1;solid.add_child(obstacle)
			continue
		var tree_height=local_rng.randf_range(4,7)
		if biome==0:
			ToonArt.tube(prop,Color("b67552"),Vector3(0,tree_height*.35,0),.19,.32,tree_height*.7)
			for j in range(3):
				var leaf=ToonArt.ball(prop,Color("9fbe8c"),Vector3(sin(j*2)*.6,tree_height*.7+j*.4,cos(j*2)*.4),Vector3(2.6,2,2.4))
		elif biome==1:
			ToonArt.tube(prop,Color("e6d7ba"),Vector3(0,1,0),.19,.33,2)
			ToonArt.ball(prop,Color("bb8ca7"),Vector3(0,2.2,0),Vector3(2.7,1.0,2.7))
			for j in range(5): ToonArt.ball(prop,Color("f5e9c9"),Vector3(sin(j*2.4),2.45,cos(j*2.4)),Vector3(.24,.08,.24))
		elif biome==2:
			ToonArt.tube(prop,Color("9caf76"),Vector3(0,1.1,0),.20,.26,2.2)
			for side in [-1,1]:
				ToonArt.tube(prop,Color("9caf76"),Vector3(side*.55,1.4,0),.13,.16,.9)
				ToonArt.ball(prop,Color("e5ac95"),Vector3(side*.55,1.95,0),Vector3(.4,.2,.4))
		elif biome==3:
			ToonArt.tube(prop,Color("847d70"),Vector3(0,1.7,0),.17,.25,3.4)
			for j in range(3):
				ToonArt.tube(prop,Color("8ab5b6"),Vector3(0,2+j*.7,0),0,1.4-j*.25,1.7)
				ToonArt.tube(prop,Color("e9f0e2"),Vector3(0,2.3+j*.7,0),0,1.04-j*.18,1.25)
		elif biome==4:
			for j in range(3):
				ToonArt.ball(prop,Color("947f7d"),Vector3(cos(j*2)*.6,.6+j*.3,sin(j*2)*.4),Vector3(1.6,1.6,1.4))
				ToonArt.ball(prop,Color("e5a578"),Vector3(cos(j*2)*.6,.3,sin(j*2)*.4),Vector3(.7,.15,.7))
			ToonArt.tube(prop,Color("b9886b"),Vector3(1,1,0),.09,.18,2)
		else:
			var prism=PrismMesh.new();prism.size=Vector3(1.5,3.2,1.4)
			ToonArt.part(prop,prism,COLORS[biome].darkened(.1),Vector3(0,1.6,0))
			if biome==3: ToonArt.ball(prop,Color("fff2db"),Vector3(0,2,0),Vector3(1.7,.5,1.5))
			if biome==4: ToonArt.ball(prop,Color("eeaa75"),Vector3(0,.3,0),Vector3(1.8,.4,1.6))
		var obstacle=StaticBody3D.new();prop.add_child(obstacle)
		obstacle.collision_layer=1;obstacle.collision_mask=0
		var shape=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.4;capsule.height=2.8
		shape.shape=capsule;shape.position.y=1.4;obstacle.add_child(shape)
		PaintedBatch.collect(prop,scenery)
	for path in scenery_groups:
		var instances=MultiMesh.new();instances.transform_format=MultiMesh.TRANSFORM_3D;instances.mesh=prop_meshes[path];instances.instance_count=scenery_groups[path].size()
		for index in range(instances.instance_count): instances.set_instance_transform(index,scenery_groups[path][index])
		var combined=MultiMeshInstance3D.new();combined.multimesh=instances;combined.material_override=scenery_material;combined.visibility_range_end=160;combined.visibility_range_end_margin=20;root.add_child(combined)
	if not scenery.is_empty():
		var mesh=PaintedBatch.merge(root,scenery)
		for source in scenery: source.queue_free()
		var combined=MeshInstance3D.new();combined.mesh=mesh;combined.material_override=scenery_material;combined.visibility_range_end=220;combined.visibility_range_end_margin=20;root.add_child(combined)
	# Low batched ground details never conceal an ordinary enemy.
	var multimesh=MultiMesh.new();multimesh.transform_format=MultiMesh.TRANSFORM_3D;multimesh.use_colors=true
	var blade=PrismMesh.new();blade.size=Vector3(.08,.18,.07);multimesh.mesh=blade;multimesh.instance_count=80
	for i in range(80):
		var p=Vector3(cell.x*CHUNK+local_rng.randf()*CHUNK,0,cell.y*CHUNK+local_rng.randf()*CHUNK);p.y=height_at(p.x,p.z)+.08
		multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY,p-root.position));multimesh.set_instance_color(i,COLORS[biome_at(p)].darkened(.17))
	var grass=MultiMeshInstance3D.new();grass.multimesh=multimesh
	grass.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.roughness=1;grass.material_override=material;root.add_child(grass)

func stream(position_value: Vector3):
	var cell=Vector2i(floori(position_value.x/CHUNK),floori(position_value.z/CHUNK))
	if cell!=last_cell:
		last_cell=cell;pending.clear()
		for x in range(-2,3):
			for z in range(-2,3):
				var key=cell+Vector2i(x,z)
				if absi(key.x)<=8 and absi(key.y)<=8 and not chunks.has(key): pending.append(key)
		pending.sort_custom(func(a,b):return a.distance_squared_to(cell)<b.distance_squared_to(cell))
		for key in chunks.keys():
				if maxi(absi(key.x-cell.x),absi(key.y-cell.y))>3:
					chunks[key].queue_free();chunks.erase(key)
	if not pending.is_empty(): make_chunk(pending.pop_front())

func ensure_ground(p: Vector3):
	make_chunk(Vector2i(floori(p.x/CHUNK),floori(p.z/CHUNK)))

func make_boundaries():
	for side in [-1,1]:
		for axis in [0,2]:
			var mesh=BoxMesh.new();mesh.size=Vector3(16,100,1024) if axis==0 else Vector3(1024,100,16)
			var p=Vector3.ZERO;p[axis]=side*508;p.y=36
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
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("fff0d8");env.ambient_light_energy=.45
	env.fog_enabled=true;env.fog_light_color=sky_horizon;env.fog_density=.008;env.fog_sky_affect=0
	var world_env=WorldEnvironment.new();world_env.environment=env;add_child(world_env)
	sky_paint=gradient;environment=env;active_biome=-1
	weather=GPUParticles3D.new();weather.amount=180;weather.lifetime=4;weather.visibility_aabb=AABB(Vector3(-25,-15,-25),Vector3(50,40,50));add_child(weather)
	var particles=ParticleProcessMaterial.new();particles.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX;particles.emission_box_extents=Vector3(14,4,14);particles.direction=Vector3.DOWN;particles.spread=35;weather.process_material=particles
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-35,0);sun.light_energy=.9;sun.light_color=Color("ffedd5");sun.shadow_enabled=true;sun.directional_shadow_max_distance=65;add_child(sun)
	for i in range(16):
		var cloud=Node3D.new();cloud.position=Vector3(cos(i*TAU/16)*370,60+sin(i)*15,sin(i*TAU/16)*370);add_child(cloud);clouds.append(cloud)
		for j in range(3): ToonArt.ball(cloud,Color("fff2de"),Vector3(j*6,0,0),Vector3(20,9,12))
	stars=MultiMeshInstance3D.new();var constellation=MultiMesh.new();constellation.transform_format=MultiMesh.TRANSFORM_3D;var star=SphereMesh.new();star.radius=.4;star.height=.8;star.radial_segments=6;star.rings=4;constellation.mesh=star;constellation.instance_count=180
	for i in range(180): constellation.set_instance_transform(i,Transform3D(Basis.IDENTITY,Vector3(cos(i*2.4)*390,80+rng.randf()*180,sin(i*2.4)*390)))
	stars.multimesh=constellation;var starlight=StandardMaterial3D.new();starlight.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;starlight.albedo_color=Color("fff1c8");stars.material_override=starlight;add_child(stars)
	moon=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=24;sphere.height=48;moon.mesh=sphere;moon.position=Vector3(220,110,-280);var paint=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;paint.albedo_texture=load("res://assets/illustrated/terrain-2.png");moon.material_override=paint;add_child(moon)

func make_landmarks():
	# Tall towers, raised ruins and an overlook make exploration readable from a distance.
	for i in range(4):
		var angle = i*TAU/4+.4
		var p = Vector3(cos(angle)*145,0,sin(angle)*145)
		p.y = height_at(p.x,p.z)
		landmarks.append(p)
		var ruin = Node3D.new()
		ruin.position = p
		add_child(ruin)
		var stone = StandardMaterial3D.new()
		stone.albedo_color=Color("8ca7b1") if realm==0 else Color("bc8865") if realm==1 else Color("918bc0")
		stone.roughness = .85
		stone.albedo_texture=load("res://assets/illustrated/stone.png")
		stone.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
		for j in range(6):
			var pillar = MeshInstance3D.new()
			var cylinder = CylinderMesh.new()
			cylinder.top_radius = .6
			cylinder.bottom_radius = .8
			cylinder.height = 6.0 + float(j%2)*2
			cylinder.radial_segments = 24
			pillar.mesh = cylinder
			pillar.material_override = stone
			pillar.position = Vector3(cos(j*TAU/6)*8,cylinder.height*.5,sin(j*TAU/6)*8)
			ruin.add_child(pillar)
			pillar.create_convex_collision()
		var platform = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(11,.45,11)
		platform.mesh = box
		platform.material_override = stone
		platform.position = Vector3(0,1.5,0)
		ruin.add_child(platform)
		platform.create_trimesh_collision()
		# Jumpable stone steps reach the raised reward platform.
		for step in range(3):
			var stair = MeshInstance3D.new()
			var stair_mesh = BoxMesh.new()
			stair_mesh.size = Vector3(3,.5,2)
			stair.mesh = stair_mesh
			stair.material_override = stone
			stair.position = Vector3(0,.25+step*.5,8-step*1.8)
			ruin.add_child(stair)
			stair.create_convex_collision()

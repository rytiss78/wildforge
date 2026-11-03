extends RefCounted
class_name GroundCover

const COLORS=[Color("278b68"),Color("568e8b"),Color("648ab9"),Color("62bab2"),Color("b05a40"),Color("8f62ae"),Color("5e5d58")]
static var tufts={}
static var paints={}

static func mesh(kind: int=0) -> ArrayMesh:
	if tufts.has(kind): return tufts[kind]
	var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	if kind==2:
		# Mineral shards use opaque geometry and no wind, not grass recoloured blue.
		for i in range(7):
			var root=Vector3(sin(i*4.1),0,cos(i*3.3))*.5
			var tip=root+Vector3(.08,.12+float(i%3)*.09,.03)
			for side in range(4):
				var a=root+Vector3(cos(side*PI/2),0,sin(side*PI/2))*.10
				var b=root+Vector3(cos((side+1)*PI/2),0,sin((side+1)*PI/2))*.10
				for v in [a,tip,b]: surface.set_uv(Vector2(0,v.y/.3));surface.add_vertex(v)
	elif kind==1:
		# Broad low fronds break up the narrow grass silhouette in wet biomes.
		for i in range(9):
			var direction=Vector3(cos(i*2.399),0,sin(i*2.399))
			var side=direction.cross(Vector3.UP)*.11
			var middle=direction*.30+Vector3.UP*.28;var tip=direction*.62+Vector3.UP*.18
			for v in [Vector3.ZERO,middle-side,middle+side,middle-side,tip,middle+side]:
				surface.set_uv(Vector2(0,v.y/.35));surface.add_vertex(v)
	elif kind==0:
		for i in range(17):
			var angle=i*2.399
			var side=Vector3(cos(angle),0,sin(angle))*.055
			var root=Vector3(sin(i*4.1),0,cos(i*3.3))*.55
			var tip=root+Vector3(sin(angle)*.24,.35+float(i%3)*.13,cos(angle)*.24)
			var middle=root.lerp(tip,.55)+Vector3.UP*.07
			for v in [root-side,middle-side*.6,root+side,root+side,middle-side*.6,middle+side*.6,middle-side*.6,tip,middle+side*.6]:
				surface.set_uv(Vector2(0,v.y/.56));surface.add_vertex(v)
	elif kind==3:
		# Junkyard litter (October 31, replacing cone shards): a bent sheet of metal, a
		# bolt, a dented can and a nut, low on the ground.
		var parts=[
			[BoxMesh,Vector3(.7,.03,.45),Transform3D(Basis(Vector3.FORWARD,.12),Vector3(-.2,.04,0))],
			[BoxMesh,Vector3(.4,.03,.45),Transform3D(Basis(Vector3.FORWARD,-.7),Vector3(.24,.14,0))],
			[CylinderMesh,Vector3(.045,.32,.045),Transform3D(Basis(Vector3.RIGHT,PI*.5),Vector3(.1,.05,.42))],
			[CylinderMesh,Vector3(.09,.05,.09),Transform3D(Basis(Vector3.RIGHT,PI*.5),Vector3(.1,.07,.26))],
			[CylinderMesh,Vector3(.08,.2,.08),Transform3D(Basis(Vector3.FORWARD,PI*.5),Vector3(-.4,.08,-.38))],
			[TorusMesh,Vector3(.07,.07,.07),Transform3D(Basis.IDENTITY,Vector3(.42,.02,-.3))],
		]
		for part in parts:
			var shape=part[0].new()
			if shape is BoxMesh: shape.size=part[1]
			elif shape is CylinderMesh: shape.top_radius=part[1].x;shape.bottom_radius=part[1].x;shape.height=part[1].y;shape.radial_segments=6;shape.rings=1
			else: shape.inner_radius=part[1].x*.5;shape.outer_radius=part[1].x;shape.rings=6;shape.ring_segments=4
			var arrays=shape.get_mesh_arrays();var xform: Transform3D=part[2]
			var verts: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX];var index: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			for i in index:
				var v=xform*verts[i]
				# Lit like the top of a tuft, a little darker underneath.
				surface.set_uv(Vector2(0,.7+v.y*2.0));surface.add_vertex(v)
	surface.generate_normals();tufts[kind]=surface.commit()
	return tufts[kind]

static func build(world,root: Node3D,cell: Vector2i,rng: RandomNumberGenerator):
	# Small per-chunk batches cull independently. No colliders, alpha or grass shadows.
	var groups={}
	if world.realm==RealmWorld.ARENA: return
	var portal=world.portal_site()
	for i in range(1100):
		var p=Vector3(cell.x*world.CHUNK+rng.randf()*world.CHUNK,0,cell.y*world.CHUNK+rng.randf()*world.CHUNK)
		if Vector2(p.x,p.z).length()>world.shore_radius(p)-20 or world.lava_at(p): continue
		if absf(p.x+sin(p.z*.035)*9)<3.5 or Vector2(p.x-portal.x,p.z-portal.z).length()<10: continue
		var biome=world.biome_at(p)
		# Broken islands, not a uniform carpet. Candy Hell keeps small ground
		# fragments spread across open earth while lava and crossings stay clear.
		var patch=sin(p.x*.14+sin(p.z*.09)*2)+cos(p.z*.18+p.x*.03)
		if patch<(-.95 if biome==4 else -.25) or world.crossing_distance(p)<5: continue
		p.y=world.height_at(p.x,p.z)
		if absf(world.height_at(p.x+.6,p.z)-p.y)>.55 or absf(world.height_at(p.x,p.z+.6)-p.y)>.55: continue
		if biome==2 and i%2!=0: continue
		if biome==5 and i%2!=0: continue
		if biome==6 and i%3!=0: continue
		# Junkyard: shards of scrap and bolts rather than grass.
		var kind=3 if biome==6 else 2 if biome in [2,4,5] else 1 if biome in [1,3] else 0
		var scale_value=rng.randf_range(.55,.95) if kind==3 else rng.randf_range(1.15,1.75) if kind==2 else rng.randf_range(.78,1.28)
		var basis=Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_value)
		if not groups.has(kind): groups[kind]={"transforms":[],"colors":[]}
		groups[kind].transforms.append(Transform3D(basis,p-root.position))
		var color=COLORS[biome].lightened(rng.randf_range(0,.15))
		if i%19==0: color=NatureScenery.BLOOM[biome]
		# Junk comes in every faded paint, not one grey.
		if kind==3: color=NatureScenery.JUNK_PAINTS[rng.randi()%NatureScenery.JUNK_PAINTS.size()].darkened(rng.randf_range(.45,.65))
		groups[kind].colors.append(color.srgb_to_linear())
	for kind in groups:
		var transforms=groups[kind].transforms;var colors=groups[kind].colors
		var batch=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true;batch.mesh=mesh(kind);batch.instance_count=transforms.size()
		for i in range(transforms.size()): batch.set_instance_transform(i,transforms[i]);batch.set_instance_color(i,colors[i])
		if not paints.has(kind):
			var paint=ShaderMaterial.new();paint.shader=preload("res://shaders/flora.gdshader")
			paint.set_shader_parameter("wind_strength",0.0 if kind>=2 else 1.0);paints[kind]=paint
		var node=MultiMeshInstance3D.new();node.name="GroundCover";node.multimesh=batch;node.material_override=paints[kind]
		node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.visibility_range_end=world.GRASS_RANGE*world.view_scale;node.visibility_range_end_margin=8;root.add_child(node)

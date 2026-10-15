extends RefCounted
class_name GroundCover

const COLORS=[Color("278b68"),Color("568e8b"),Color("648ab9"),Color("62bab2"),Color("b05a40"),Color("8f62ae")]
static var tuft: ArrayMesh
static var paint: ShaderMaterial

static func mesh() -> ArrayMesh:
	if tuft!=null: return tuft
	var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(17):
		var angle=i*2.399
		var side=Vector3(cos(angle),0,sin(angle))*.055
		var root=Vector3(sin(i*4.1),0,cos(i*3.3))*.55
		var tip=root+Vector3(sin(angle)*.24,.35+float(i%3)*.13,cos(angle)*.24)
		var middle=root.lerp(tip,.55)+Vector3.UP*.07
		for v in [root-side,middle-side*.6,root+side,root+side,middle-side*.6,middle+side*.6,middle-side*.6,tip,middle+side*.6]:
			surface.set_uv(Vector2(0,v.y/.56));surface.add_vertex(v)
	surface.generate_normals();tuft=surface.commit()
	return tuft

static func build(world,root: Node3D,cell: Vector2i,rng: RandomNumberGenerator):
	# Small per-chunk batches cull independently. No colliders, alpha or grass shadows.
	var transforms=[];var colors=[]
	if world.realm==3: return
	var portal=world.portal_site()
	for i in range(900):
		var p=Vector3(cell.x*world.CHUNK+rng.randf()*world.CHUNK,0,cell.y*world.CHUNK+rng.randf()*world.CHUNK)
		if Vector2(p.x,p.z).length()>world.shore_radius(p)-20 or world.lava_at(p): continue
		if absf(p.x+sin(p.z*.035)*9)<3.5 or Vector2(p.x-portal.x,p.z-portal.z).length()<10: continue
		# Broken islands, not a uniform carpet. The low growth never conceals enemies.
		var patch=sin(p.x*.14+sin(p.z*.09)*2)+cos(p.z*.18+p.x*.03)
		if patch<.05 or world.crossing_distance(p)<5: continue
		p.y=world.height_at(p.x,p.z)
		if absf(world.height_at(p.x+.6,p.z)-p.y)>.55 or absf(world.height_at(p.x,p.z+.6)-p.y)>.55: continue
		var biome=world.biome_at(p)
		if biome in [2,4,5] and i%3!=0: continue
		var scale_value=rng.randf_range(.65,1.2)
		var basis=Basis(Vector3.UP,rng.randf()*TAU).scaled(Vector3.ONE*scale_value)
		transforms.append(Transform3D(basis,p-root.position))
		var color=COLORS[biome].lightened(rng.randf_range(0,.15))
		if i%19==0: color=NatureScenery.BLOOM[biome]
		colors.append(color.srgb_to_linear())
	if transforms.is_empty(): return
	var batch=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_3D;batch.use_colors=true;batch.mesh=mesh();batch.instance_count=transforms.size()
	for i in range(transforms.size()): batch.set_instance_transform(i,transforms[i]);batch.set_instance_color(i,colors[i])
	if paint==null: paint=ShaderMaterial.new();paint.shader=preload("res://shaders/flora.gdshader")
	var node=MultiMeshInstance3D.new();node.name="GroundCover";node.multimesh=batch;node.material_override=paint
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.visibility_range_end=65;node.visibility_range_end_margin=8;root.add_child(node)

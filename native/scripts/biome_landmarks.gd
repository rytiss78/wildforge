extends RefCounted
class_name BiomeLandmarks

const NAMES=["Heartroot Grove","Glowcap Hollow","Moonshard Thicket","The Weeping Sky","Emberroot Hollow","Astral Reef","The Scrap Crown"]
const COLORS=[Color("285b50"),Color("563661"),Color("344962"),Color("42626b"),Color("612b36"),Color("443465"),Color("5a3a24")]

static func cut_stone(root: Node3D,color: Color,p: Vector3,dimensions: Vector3) -> MeshInstance3D:
	var mesh=SphereMesh.new();mesh.radial_segments=7;mesh.rings=3;mesh.radius=.5;mesh.height=1
	var node=ToonArt.part(root,mesh,color,p);node.scale=dimensions
	return node

static func box(root: Node3D,color: Color,p: Vector3,size: Vector3,solid: bool=false) -> MeshInstance3D:
	var mesh=BoxMesh.new();mesh.size=size
	var node=ToonArt.part(root,mesh,color,p)
	if solid: node.create_convex_collision()
	return node

static func column(root: Node3D,color: Color,p: Vector3,radius: float,height: float):
	var node=ToonArt.tube(root,color,p,radius*.8,radius,height)
	node.create_convex_collision()

static func ring(root: Node3D,color: Color,p: Vector3,radius: float):
	var mesh=TorusMesh.new();mesh.inner_radius=radius-.32;mesh.outer_radius=radius+.32;mesh.rings=32;mesh.ring_segments=8
	return ToonArt.part(root,mesh,color,p)

static func build(world: Node3D,biome: int,p: Vector3):
	var root=Node3D.new();root.name="Landmark_"+str(biome);root.position=p;world.add_child(root)
	root.set_meta("natural_landmark",true)
	# Leave the original interaction/reward clearing open and at terrain height.
	# Three asymmetric growths form a grove rather than a house or a platform.
	for i in range(3):
		var growth=Node3D.new();root.add_child(growth)
		var offset=Vector3((i-1)*11,0,-18-abs(i-1)*5)
		offset.y=world.height_at(p.x+offset.x,p.z+offset.z)-p.y;growth.position=offset
		# Cloudwilds' willow canopy framed the whole view from normal play distance.
		var scale_value=(.55 if biome==3 else 2.25) if i==1 else 1.1
		var growth_variant=(1 if biome==3 and i==0 else 0 if i==1 else i)
		var plant=MeshInstance3D.new();plant.name="AncientGrowth"
		plant.mesh=NatureScenery.mesh(world,biome,growth_variant)
		plant.material_override=world.scenery_material;plant.scale=Vector3.ONE*scale_value;plant.rotation.y=i*1.7;growth.add_child(plant)
		NatureScenery.collision(growth,biome,growth_variant,scale_value)
		NatureScenery.light(growth,biome,3.0,true)

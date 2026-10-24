extends RefCounted
class_name ShotShapes

# Projectiles of their own for weapons whose look should not follow their
# archetype: the Moon Shuriken is a "disc" weapon, but it throws ninja stars,
# not saw discs. A star is built facing +Z: it turns to face the camera in flight
# (faces_camera), since a flat-spinning star reads edge-on from the gameplay camera.
static var meshes={}
static var paints={}

static func has(weapon_id: String) -> bool:
	return weapon_id in ["ninja-shuriken"]

static func faces_camera(weapon_id: String) -> bool:
	return weapon_id=="ninja-shuriken"

static func mesh(weapon_id: String) -> Mesh:
	if not meshes.has(weapon_id): meshes[weapon_id]=shuriken()
	return meshes[weapon_id]

static func material(weapon_id: String) -> Material:
	if not paints.has(weapon_id):
		var paint=StandardMaterial3D.new();paint.vertex_color_use_as_albedo=true;paint.metallic=.55;paint.roughness=.35
		paint.emission_enabled=true;paint.emission=Color("6f7f96");paint.emission_energy_multiplier=.35
		paint.cull_mode=BaseMaterial3D.CULL_DISABLED
		paints[weapon_id]=paint
	return paints[weapon_id]

# A four-pointed star: bright steel tips and edges, a dark centre hub.
static func shuriken() -> ArrayMesh:
	var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim=[]
	for i in range(8):
		var angle=i*TAU/8.0;var radius=.34 if i%2==0 else .1
		rim.append(Vector2(cos(angle),sin(angle))*radius)
	var steel=Color("dfe6ee");var hub=Color("2a2f3a");var edge=Color("aab4c2")
	for side in [1.0,-1.0]:
		var face=Vector3(0,0,.025*side)
		for i in range(8):
			var a=rim[i];var b=rim[(i+1)%8]
			var points=[face,Vector3(a.x,a.y,face.z*.4),Vector3(b.x,b.y,face.z*.4)]
			if side<0: points=[points[0],points[2],points[1]]
			var colors=[hub,steel if i%2==0 else edge,edge if i%2==0 else steel]
			if side<0: colors=[colors[0],colors[2],colors[1]]
			for k in range(3): tool.set_color(colors[k]);tool.add_vertex(points[k])
	# Thin edge walls between the two faces. Both faces are drawn so either side shows.
	for i in range(8):
		var a=rim[i];var b=rim[(i+1)%8]
		var top_a=Vector3(a.x,a.y,.01);var top_b=Vector3(b.x,b.y,.01);var low_a=Vector3(a.x,a.y,-.01);var low_b=Vector3(b.x,b.y,-.01)
		for p in [top_a,low_a,low_b,top_a,low_b,top_b]: tool.set_color(edge);tool.add_vertex(p)
	tool.generate_normals()
	return tool.commit()

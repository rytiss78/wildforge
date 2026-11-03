extends RefCounted
class_name AkModel

# Clutch's rifle (user, November 3: "Clutch needs an AK-47, a sharp HQ model").
# Built from many small parts in real proportions (about 0.88 m long), with
# metal, wood and bakelite materials instead of the flat cartoon paint, so it
# reads crisp up close in his first-person view: stamped steel receiver with
# its dust cover and rivets, barrel, gas tube, front and rear sights, slant
# muzzle brake, wooden handguards with grooves, pistol grip and stock, a
# curved banana magazine, trigger, guard, charging handle and selector.
# Forward is -Z, up is +Y. Returns the muzzle node.

static func material(color: Color,metal: float,rough: float) -> StandardMaterial3D:
	var m=StandardMaterial3D.new();m.albedo_color=color;m.metallic=metal;m.roughness=rough
	m.metallic_specular=.6;return m

static func box(parent: Node3D,mat: Material,center: Vector3,size: Vector3,rot: Vector3=Vector3.ZERO) -> MeshInstance3D:
	var mesh=BoxMesh.new();mesh.size=size
	var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=mat;node.position=center;node.rotation=rot;parent.add_child(node)
	return node

static func rod(parent: Node3D,mat: Material,from: Vector3,to: Vector3,radius: float,segments: int=16) -> MeshInstance3D:
	var mesh=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=from.distance_to(to);mesh.radial_segments=segments;mesh.rings=1
	var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=mat;parent.add_child(node)
	node.position=(from+to)*.5
	var axis=(to-from).normalized()
	var side=axis.cross(Vector3.RIGHT if absf(axis.dot(Vector3.RIGHT))<.9 else Vector3.UP).normalized()
	node.basis=Basis(side.cross(axis).normalized(),axis,side)
	return node

# A flat-sided solid from a side profile (points are (z, y)), width along X:
# smooth outlines like the banana magazine and the stock.
static func slab(parent: Node3D,mat: Material,profile: PackedVector2Array,width: float,x: float=0.0) -> MeshInstance3D:
	var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris=Geometry2D.triangulate_polygon(profile)
	for side in [-1.0,1.0]:
		for k in range(0,tris.size(),3):
			var order=[0,1,2] if side>0 else [0,2,1]
			for o in order:
				var p=profile[tris[k+o]];tool.add_vertex(Vector3(x+side*width*.5,p.y,p.x))
	for k in range(profile.size()):
		var a=profile[k];var b=profile[(k+1)%profile.size()]
		var a0=Vector3(x-width*.5,a.y,a.x);var a1=Vector3(x+width*.5,a.y,a.x);var b0=Vector3(x-width*.5,b.y,b.x);var b1=Vector3(x+width*.5,b.y,b.x)
		for v in [a0,b0,b1,a0,b1,a1]: tool.add_vertex(v)
	tool.generate_normals()
	var node=MeshInstance3D.new();node.mesh=tool.commit();node.material_override=mat;parent.add_child(node)
	return node

static func arc_profile(center: Vector2,inner: float,outer: float,from: float,to: float,steps: int=14) -> PackedVector2Array:
	var points=PackedVector2Array()
	for k in range(steps+1): points.append(center+Vector2.from_angle(lerpf(from,to,float(k)/steps))*outer)
	for k in range(steps,-1,-1): points.append(center+Vector2.from_angle(lerpf(from,to,float(k)/steps))*inner)
	return points

static func build(root: Node3D) -> Node3D:
	var steel=material(Color("2b2e33"),.85,.32);var dark=material(Color("17191c"),.7,.45)
	var wood=material(Color("9c4f24"),0,.48);var wood_dark=material(Color("6e3416"),0,.55)
	var bakelite=material(Color("7c2c14"),.05,.36);var bright=material(Color("8a9098"),.95,.22)
	# Receiver and dust cover.
	box(root,steel,Vector3(0,0,.08),Vector3(.054,.072,.30))
	var cover=rod(root,steel,Vector3(0,.038,-.05),Vector3(0,.038,.235),.027,20);cover.scale=Vector3(.95,1,.62)
	box(root,dark,Vector3(0,.02,.235),Vector3(.05,.05,.02))
	for z in [-.03,.03,.09,.15,.2]:
		for x in [-.0275,.0275]: rod(root,bright,Vector3(x,-.02,z),Vector3(x*1.08,-.02,z),.0035,8)
	# Rear sight block and leaf.
	box(root,steel,Vector3(0,.045,-.075),Vector3(.034,.03,.05))
	box(root,dark,Vector3(0,.064,-.07),Vector3(.022,.006,.055),Vector3(-.05,0,0))
	# Barrel, gas block, gas tube.
	rod(root,steel,Vector3(0,-.002,-.07),Vector3(0,-.002,-.52),.0115)
	box(root,steel,Vector3(0,.016,-.315),Vector3(.026,.048,.03))
	rod(root,dark,Vector3(0,.034,-.08),Vector3(0,.034,-.31),.0135)
	# Front sight tower and post.
	box(root,steel,Vector3(0,.012,-.455),Vector3(.022,.04,.03))
	box(root,steel,Vector3(0,.045,-.455),Vector3(.02,.026,.012))
	box(root,bright,Vector3(0,.06,-.455),Vector3(.003,.014,.003))
	# Slant muzzle brake.
	var brake=rod(root,dark,Vector3(0,-.002,-.52),Vector3(0,-.002,-.565),.0145);brake.rotation.z=0
	box(root,dark,Vector3(0,.012,-.56),Vector3(.03,.012,.018),Vector3(.5,0,0))
	# Wooden handguards: upper over the gas tube, lower round the barrel, grooves.
	box(root,wood,Vector3(0,.036,-.165),Vector3(.036,.026,.15))
	box(root,wood,Vector3(0,-.006,-.17),Vector3(.052,.054,.18))
	for k in range(4): box(root,wood_dark,Vector3(0,-.034,-.11-k*.04),Vector3(.054,.004,.012))
	box(root,steel,Vector3(0,-.006,-.08),Vector3(.056,.058,.012))
	box(root,steel,Vector3(0,-.006,-.262),Vector3(.054,.056,.01))
	# Curved banana magazine: a smooth arc bending forward, with ribs.
	var bend=Vector2(-.24,-.03)
	var mag=slab(root,bakelite,arc_profile(bend,.25,.318,-.02,-.62),.027);mag.name="Magazine"
	for k in range(5):
		var a=lerpf(-.08,-.56,k/4.0)
		var rib=PackedVector2Array([bend+Vector2.from_angle(a-.012)*.252,bend+Vector2.from_angle(a-.012)*.32,bend+Vector2.from_angle(a+.012)*.32,bend+Vector2.from_angle(a+.012)*.252])
		slab(root,wood_dark,rib,.0295)
	# Trigger guard and trigger.
	box(root,steel,Vector3(0,-.062,.135),Vector3(.009,.006,.08))
	box(root,steel,Vector3(0,-.05,.097),Vector3(.009,.026,.006))
	box(root,dark,Vector3(0,-.046,.128),Vector3(.006,.026,.007),Vector3(.25,0,0))
	# Pistol grip, leaning back, with finger swells.
	slab(root,wood_dark,PackedVector2Array([Vector2(.165,-.036),Vector2(.205,-.036),Vector2(.245,-.13),Vector2(.232,-.142),Vector2(.198,-.14),Vector2(.185,-.1),Vector2(.17,-.07)]),.032)
	# Stock: from the receiver, dropping and widening to a steel butt plate.
	slab(root,wood,PackedVector2Array([Vector2(.23,.028),Vector2(.4,.012),Vector2(.552,.0),Vector2(.552,-.122),Vector2(.48,-.1),Vector2(.36,-.06),Vector2(.23,-.034)]),.042)
	slab(root,wood_dark,PackedVector2Array([Vector2(.3,-.045),Vector2(.46,-.085),Vector2(.46,-.078),Vector2(.3,-.039)]),.044)
	slab(root,dark,PackedVector2Array([Vector2(.552,.002),Vector2(.566,.002),Vector2(.566,-.126),Vector2(.552,-.124)]),.047)
	# Charging handle and selector lever on the right side.
	rod(root,bright,Vector3(.028,.022,.03),Vector3(.05,.022,.03),.0055,10)
	box(root,steel,Vector3(.03,.016,.12),Vector3(.004,.012,.09),Vector3(0,0,0))
	var muzzle=Node3D.new();muzzle.name="Muzzle";root.add_child(muzzle);muzzle.position=Vector3(0,-.002,-.575)
	return muzzle

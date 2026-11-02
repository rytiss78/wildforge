extends RefCounted
class_name ClutchHands

# Clutch's first-person hands (user, November 2: "realistic, like a tactical
# shooter"). Two gloved hands with forearms and rolled sleeves, built from
# primitives in plain lit (not toon) materials: the right hand wraps the grip at
# the back of the held weapon, the left hand cups it further forward. Placed from
# the weapon model's bounds, so every weapon shape is held.

const GLOVE=Color("2e2f33")
const PAD=Color("1b1b1d")
const LEATHER=Color("6b5640")
const SLEEVE=Color("4f5a3a")
const CUFF=Color("3c4430")
const SKIN=Color("c99a76")

static func paint(color: Color,rough: float=.75) -> StandardMaterial3D:
	var m=StandardMaterial3D.new();m.albedo_color=color;m.roughness=rough;m.metallic=0.0
	m.specular_mode=BaseMaterial3D.SPECULAR_SCHLICK_GGX
	return m

# A tapered cylinder from a to b.
static func limb(parent: Node3D,a: Vector3,b: Vector3,r_a: float,r_b: float,material: Material) -> MeshInstance3D:
	var mesh=CylinderMesh.new();mesh.height=a.distance_to(b);mesh.bottom_radius=r_a;mesh.top_radius=r_b;mesh.radial_segments=14;mesh.rings=1
	var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=material;parent.add_child(node)
	node.transform=Transform3D(along(b-a),(a+b)*.5)
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

# A rounded capsule from a to b.
static func bone(parent: Node3D,a: Vector3,b: Vector3,radius: float,material: Material) -> MeshInstance3D:
	var mesh=CapsuleMesh.new();mesh.radius=radius;mesh.height=maxf(a.distance_to(b)+radius*2.0,radius*2.01);mesh.radial_segments=12;mesh.rings=4
	var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=material;parent.add_child(node)
	node.transform=Transform3D(along(b-a),(a+b)*.5)
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

# A squashed ball (palms, pads): rounder than a box.
static func pad(parent: Node3D,center: Vector3,size: Vector3,material: Material,basis: Basis=Basis.IDENTITY) -> MeshInstance3D:
	var mesh=SphereMesh.new();mesh.radius=.5;mesh.height=1.0;mesh.radial_segments=16;mesh.rings=8
	var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=material;parent.add_child(node)
	node.transform=Transform3D(basis.scaled_local(size),center);node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

static func block(parent: Node3D,center: Vector3,size: Vector3,material: Material,basis: Basis=Basis.IDENTITY) -> MeshInstance3D:
	var mesh=BoxMesh.new();mesh.size=size
	var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=material;parent.add_child(node)
	node.transform=Transform3D(basis,center);node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

# A basis whose Y axis points along dir.
static func along(dir: Vector3) -> Basis:
	var y=dir.normalized()
	var helper=Vector3.FORWARD if absf(y.dot(Vector3.FORWARD))<.95 else Vector3.RIGHT
	var x=y.cross(helper).normalized();var z=x.cross(y).normalized()
	return Basis(x,y,z)

# The weapon model's bounds in the view node's space.
static func bounds(view: Node3D,model: Node3D) -> AABB:
	var box=AABB();var first=true
	var to_view=view.global_transform.affine_inverse()
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		if not mesh.visible or mesh.mesh==null: continue
		var local: AABB=(to_view*mesh.global_transform)*mesh.get_aabb()
		if first: box=local;first=false
		else: box=box.merge(local)
	if first: box=AABB(Vector3(-.03,-.05,-.3),Vector3(.06,.1,.4))
	return box

# The weapon's surface points in the view node's space.
static func points(view: Node3D,model: Node3D) -> PackedVector3Array:
	var out=PackedVector3Array();var to_view=view.global_transform.affine_inverse()
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		if not mesh.is_visible_in_tree() or mesh.mesh==null: continue
		var xf=to_view*mesh.global_transform
		var faces=mesh.mesh.get_faces()
		for i in range(0,faces.size(),3): out.append(xf*faces[i])
	return out

# Where the hands go: the grip is the lowest part of the back half (the right
# hand wraps it a little above its bottom); the left hand cups the underside of
# the front half.
static func hold_points(view: Node3D,model: Node3D) -> Array:
	var box=bounds(view,model);var pts=points(view,model)
	var depth=box.size.z;var back=box.end.z-depth*.45
	var low=INF
	for p in pts:
		if p.z>back: low=minf(low,p.y)
	var grip=Vector3.ZERO;var n=0
	for p in pts:
		if p.z>back and p.y<low+box.size.y*.25: grip+=p;n+=1
	grip=grip/n if n>0 else Vector3(box.get_center().x,box.position.y,box.end.z-depth*.28)
	grip.y=low+box.size.y*.3 if low<INF else grip.y
	var front_a=box.position.z+depth*.3;var front_b=box.position.z+depth*.6
	var under=INF;var front=Vector3.ZERO;var m=0
	for p in pts:
		if p.z>front_a and p.z<front_b: under=minf(under,p.y)
	for p in pts:
		if p.z>front_a and p.z<front_b and p.y<under+.015: front+=p;m+=1
	front=front/m if m>0 else Vector3(box.get_center().x,box.position.y,box.position.z+depth*.32)
	front.y=under if under<INF else front.y
	return [grip,front]

# Builds both hands under `view`, around the weapon `model`. Returns the root.
static func build(view: Node3D,model: Node3D) -> Node3D:
	var root=Node3D.new();root.name="Hands";view.add_child(root)
	var box=bounds(view,model)
	var glove=paint(GLOVE,.85);var dark=paint(PAD,.6);var leather=paint(LEATHER,.7);var sleeve=paint(SLEEVE,.95);var cuff=paint(CUFF,.95);var skin=paint(SKIN,.6)
	var spots=hold_points(view,model)
	# Right hand: wraps the grip.
	var grip: Vector3=spots[0]
	var r=Node3D.new();r.name="Right";root.add_child(r);r.position=grip
	pad(r,Vector3(.026,-.02,.0),Vector3(.034,.09,.08),glove,Basis(Vector3.FORWARD,-.12))  # palm on the right of the grip
	pad(r,Vector3(.042,-.015,.0),Vector3(.01,.055,.05),dark)                             # back-of-hand pad
	for i in range(4):
		var y=.012-i*.022
		bone(r,Vector3(.03,y,-.03),Vector3(-.022,y-.004,-.036),.0115,glove)                  # fingers round the front
		bone(r,Vector3(-.022,y-.004,-.036),Vector3(-.03,y-.006,-.012),.0105,glove)           # finger tips on the far side
	bone(r,Vector3(.02,.03,.02),Vector3(-.02,.045,-.03),.012,glove)                          # thumb over the top
	limb(r,Vector3(.028,-.05,.035),Vector3(.03,-.075,.05),.03,.03,leather)                  # wrist strap
	var r_wrist=Vector3(.03,-.07,.05);var r_elbow=Vector3(.17,-.27,.34)
	limb(r,r_wrist,r_wrist.lerp(r_elbow,.35),.026,.03,skin)
	limb(r,r_wrist.lerp(r_elbow,.3),r_elbow,.04,.05,sleeve)                                  # rolled sleeve
	limb(r,r_wrist.lerp(r_elbow,.3),r_wrist.lerp(r_elbow,.4),.044,.045,cuff)
	# Left hand: cups the weapon further forward, fingers up its right side.
	var hold: Vector3=spots[1]+Vector3(0,-.014,0)
	var l=Node3D.new();l.name="Left";root.add_child(l);l.position=hold
	pad(l,Vector3(-.006,-.012,0),Vector3(.08,.03,.075),glove,Basis(Vector3.FORWARD,.25))  # palm under the weapon
	for i in range(4):
		var z=-.026+i*.017
		bone(l,Vector3(.03,-.008,z),Vector3(.045,.03,z),.0105,glove)                         # fingers curling up the right side
	bone(l,Vector3(-.03,-.004,.02),Vector3(-.036,.03,-.03),.012,glove)                       # thumb along the left side
	pad(l,Vector3(-.006,-.027,0),Vector3(.05,.01,.045),dark)
	var l_wrist=Vector3(-.03,-.035,.04);var l_elbow=Vector3(-.2,-.24,.3)
	limb(l,l_wrist,l_wrist.lerp(l_elbow,.3),.026,.03,skin)
	limb(l,l_wrist.lerp(l_elbow,.25),l_elbow,.04,.05,sleeve)
	limb(l,l_wrist.lerp(l_elbow,.25),l_wrist.lerp(l_elbow,.35),.044,.045,cuff)
	return root

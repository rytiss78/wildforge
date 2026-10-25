extends RefCounted
class_name CartoonScene

# Assembles a cartoon model (hero, boss or weapon) as the node layout StyleModel
# already animates: a Body with a Head, Leg*/Arm* joints, HandSocket1/2, an
# optional Muzzle, and one GlassCore orb. Each joint's geometry is a merged
# CartoonMesh with vertex-coloured paint; StyleModel adds toon shading and the
# ink outline. Nothing here is imported art.

var root=Node3D.new()
var body=Node3D.new()
var head: Node3D
var meshes=[]
var arms=[]
var legs=[]

func _init(): root.name="CartoonModel";body.name="Body";root.add_child(body)

func joint(name: String,parent: Node3D,position: Vector3) -> Node3D:
	var node=Node3D.new();node.name=name;node.position=position;parent.add_child(node);return node

# The CartoonMesh that draws a joint's geometry, in that joint's local space.
func paint(node: Node3D,name: String="Paint") -> CartoonMesh:
	var m=CartoonMesh.new();meshes.append([node,m,name]);return m

func make_head(position: Vector3) -> CartoonMesh:
	head=joint("Head",body,position);return paint(head,"HeadPaint")

# Two arms hanging from shoulders, a hand socket in each for the held weapons.
func make_arms(shoulder: Vector3,length: float,radius: float,sleeve: Color,hand: Color,hand_size: float=1.0):
	for i in range(2):
		var side=-1.0 if i==0 else 1.0
		var arm=joint("ArmL" if i==0 else "ArmR",body,Vector3(shoulder.x*side,shoulder.y,shoulder.z));arms.append(arm)
		var m=paint(arm,"ArmPaint"+str(i));var tip=Vector3(side*.05,-length,-.06)
		m.rod(Vector3.ZERO,tip,radius,sleeve);m.ball(tip+Vector3(0,-radius*.4,-.02),Vector3.ONE*radius*2.9*hand_size,hand)
		joint("HandSocket"+str(i+1),arm,tip+Vector3(0,-.02,-.08))

# Two legs from hips, with shoes.
func make_legs(hip: Vector3,length: float,radius: float,trouser: Color,shoe: Color):
	for i in range(2):
		var side=-1.0 if i==0 else 1.0
		var leg=joint("LegL" if i==0 else "LegR",root,Vector3(hip.x*side,hip.y,hip.z));legs.append(leg)
		var m=paint(leg,"LegPaint"+str(i))
		m.rod(Vector3.ZERO,Vector3(0,-length,0),radius,trouser);m.ball(Vector3(0,-length-radius*.3,-radius*.8),Vector3(radius*2.8,radius*1.4,radius*3.8),shoe)

# The health orb. As a body part (body_orb) it is used exactly as drawn and the
# model is built around it; otherwise it sits on the front at 1.6x the radius given.
const ORB_SCALE=1.6
func orb(position: Vector3,radius: float,parent: Node3D=null,body_orb: bool=false):
	var r=radius*(1.0 if body_orb else ORB_SCALE)
	var sphere=SphereMesh.new();sphere.radius=r;sphere.height=r*2;sphere.radial_segments=24;sphere.rings=12
	var node=MeshInstance3D.new();node.name="GlassCore";node.mesh=sphere
	node.position=position;(parent if parent!=null else body).add_child(node)

func muzzle(position: Vector3,parent: Node3D=null):
	joint("Muzzle",parent if parent!=null else body,position)

func finish() -> Node3D:
	var material=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.albedo_color=Color.WHITE
	for entry in meshes:
		var m: CartoonMesh=entry[1]
		if m.verts.is_empty(): continue
		var node=MeshInstance3D.new();node.name=entry[2];node.mesh=m.commit();node.mesh.surface_set_material(0,material);entry[0].add_child(node)
	return root

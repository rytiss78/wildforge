extends RefCounted
class_name CartoonMesh

# Builds one cartoon creature as a single merged mesh, so a crowd costs two draws
# per enemy (paint and ink outline). Every part carries its paint in COLOR and its
# animation in UV/UV2 (shaders/cartoon_creature.gdshaderinc): which kind of part
# it is, a phase, and its pivot. Primitive templates are generated once.

enum {BODY,LEG,STALK,JAW,WING,TAIL,PUPIL}
const INK=Color("16121c")
const WHITE=Color("fbfbf4")
const TOOTH=Color("fff1cf")
const MOUTH=Color("3b0c1c")
const TONGUE=Color("ff7aa0")
static var templates={}

var verts=PackedVector3Array()
var normals=PackedVector3Array()
var colors=PackedColorArray()
var uvs=PackedVector2Array()
var uv2s=PackedVector2Array()
var indices=PackedInt32Array()
var orb=Vector3(0,.6,-.5)
var orb_radius=.16
# True when the design is built around its health orb (the orb is a body part,
# seen from every side), false for an orb set on the body's front.
var orb_body=false

# The big glass health orb as a body part: the belly, torso or whole body.
func core(center: Vector3,radius: float):
	orb=center;orb_radius=radius;orb_body=true

static func template(kind: String) -> Array:
	if templates.has(kind): return templates[kind]
	var mesh: PrimitiveMesh
	match kind:
		"ball": mesh=SphereMesh.new();mesh.radius=.5;mesh.height=1.0;mesh.radial_segments=14;mesh.rings=7
		"rod": mesh=CapsuleMesh.new();mesh.radius=.5;mesh.height=2.0;mesh.radial_segments=8;mesh.rings=2
		"cone": mesh=CylinderMesh.new();mesh.top_radius=0.0;mesh.bottom_radius=.5;mesh.height=1.0;mesh.radial_segments=8;mesh.rings=1
		"can": mesh=CylinderMesh.new();mesh.top_radius=.5;mesh.bottom_radius=.5;mesh.height=1.0;mesh.radial_segments=12;mesh.rings=1
		"box": mesh=BoxMesh.new();mesh.size=Vector3.ONE
		"ring": mesh=TorusMesh.new();mesh.inner_radius=.36;mesh.outer_radius=.5;mesh.rings=18;mesh.ring_segments=6
	templates[kind]=mesh.get_mesh_arrays()
	return templates[kind]

# Adds a template under a transform, with its paint and animation data.
func add(kind: String,xform: Transform3D,color: Color,part: int=BODY,phase: float=0.0,pivot: Vector2=Vector2(0,1),glow: bool=false):
	var arrays=template(kind)
	var base=verts.size()
	var normal_basis=xform.basis.inverse().transposed()
	var paint=Color(color,.4 if glow else 1.0)
	for v in arrays[Mesh.ARRAY_VERTEX]: verts.append(xform*v)
	for n in arrays[Mesh.ARRAY_NORMAL]: normals.append((normal_basis*n).normalized())
	for i in range(arrays[Mesh.ARRAY_VERTEX].size()):
		colors.append(paint);uvs.append(pivot);uv2s.append(Vector2(part,phase))
	for index in arrays[Mesh.ARRAY_INDEX]: indices.append(base+index)

# A ball of the given full size (diameters), optionally turned.
func ball(center: Vector3,dimensions: Vector3,color: Color,part: int=BODY,phase: float=0.0,pivot: Vector2=Vector2(0,1),glow: bool=false,turn: Vector3=Vector3.ZERO):
	add("ball",Transform3D(Basis.from_euler(turn).scaled(dimensions),center),color,part,phase,pivot,glow)

func box(center: Vector3,dimensions: Vector3,color: Color,part: int=BODY,turn: Vector3=Vector3.ZERO):
	add("box",Transform3D(Basis.from_euler(turn).scaled(dimensions),center),color,part)

# A basis whose Y axis runs from a to b.
static func along(a: Vector3,b: Vector3) -> Basis:
	var y=(b-a).normalized()
	var helper=Vector3.FORWARD if absf(y.dot(Vector3.FORWARD))<.9 else Vector3.RIGHT
	var x=y.cross(helper).normalized();var z=x.cross(y)
	return Basis(x,y,z)

# A capsule from a to b.
func rod(a: Vector3,b: Vector3,radius: float,color: Color,part: int=BODY,phase: float=0.0,pivot: Vector2=Vector2(0,1)):
	var frame=along(a,b);var length=a.distance_to(b)
	add("rod",Transform3D(Basis(frame.x*radius*2,frame.y*(length+radius*2)*.5,frame.z*radius*2),(a+b)*.5),color,part,phase,pivot)

# A cone with its base at `base` and its point at `tip`.
func spike(base: Vector3,tip: Vector3,radius: float,color: Color,part: int=BODY,phase: float=0.0,pivot: Vector2=Vector2(0,1)):
	var frame=along(base,tip);var length=base.distance_to(tip)
	add("cone",Transform3D(Basis(frame.x*radius*2,frame.y*length,frame.z*radius*2),(base+tip)*.5),color,part,phase,pivot)

func can(a: Vector3,b: Vector3,radius: float,color: Color,part: int=BODY):
	var frame=along(a,b);var length=a.distance_to(b)
	add("can",Transform3D(Basis(frame.x*radius*2,frame.y*length,frame.z*radius*2),(a+b)*.5),color,part)

func ring(center: Vector3,radius: float,thickness: float,color: Color,turn: Vector3=Vector3.ZERO,part: int=BODY):
	# The template tube is .14 thick: scale it to `thickness`.
	add("ring",Transform3D(Basis.from_euler(turn).scaled(Vector3(radius*2,thickness/.14,radius*2)),center),color,part)

# An eyeball looking along `look`: white, an optional iris, a black pupil. Eyes on
# the body dart their pupils; eyes on stalks sway with the stalk.
func eye(center: Vector3,radius: float,look: Vector3=Vector3.FORWARD,iris: Color=Color(0,0,0,0),part: int=BODY,phase: float=0.0,pivot: Vector2=Vector2(0,1),glow_iris: bool=false):
	ball(center,Vector3.ONE*radius*2,WHITE,part,phase,pivot)
	var front=look.normalized()
	if iris.a>0: ball(center+front*radius*.72,Vector3.ONE*radius*1.05,iris,part,phase,pivot,glow_iris)
	var pupil_part=PUPIL if part==BODY else part
	ball(center+front*radius*(.86 if iris.a>0 else .82),Vector3.ONE*radius*(.5 if iris.a>0 else .62),INK,pupil_part,phase if part!=BODY else fposmod(center.x*7.31+center.y*3.17+center.z*5.03,1.0),pivot)

# An eye on a stalk rising from `base` to `top`.
func stalk_eye(base: Vector3,top: Vector3,radius: float,stalk: Color,look: Vector3=Vector3.FORWARD,iris: Color=Color(0,0,0,0),phase: float=0.0):
	var pivot=Vector2(base.y,1.0)
	rod(base,top,radius*.24,stalk,STALK,phase,pivot)
	eye(top+(top-base).normalized()*radius*.7,radius,look,iris,STALK,phase,pivot)

# A wide mouth: a dark cavity, crooked upper teeth, and a jaw with lower teeth and
# a tongue that drops open on an attack.
func grin(center: Vector3,width: float,height: float,teeth: int=6,tongue: bool=true,depth: float=.3):
	ball(center,Vector3(width,height,depth*width),MOUTH)
	for i in range(teeth):
		var x=lerpf(-width*.38,width*.38,float(i)/maxf(1,teeth-1));var long=height*(.32+.18*float((i*7)%3))
		var root=center+Vector3(x,height*.34,-depth*width*.36)
		spike(root,root+Vector3(0,-long,-.01),width*.045,TOOTH)
	for i in range(teeth-1):
		var x=lerpf(-width*.32,width*.32,float(i)/maxf(1,teeth-2));var long=height*(.25+.15*float((i*5)%3))
		var root=center+Vector3(x,-height*.36,-depth*width*.34)
		spike(root,root+Vector3(0,long,-.01),width*.04,TOOTH,JAW)
	if tongue: ball(center+Vector3(width*.1,-height*.3,-depth*width*.55),Vector3(width*.3,height*.22,width*.42),TONGUE,JAW,0.0,Vector2(0,1),false,Vector3(.35,0,0))

# Legs hanging from hips: each a capsule and a flat foot, swinging in turn.
func legs(hips: Array,drop: float,radius: float,color: Color,foot: Color):
	for i in range(hips.size()):
		var hip: Vector3=hips[i];var pivot=Vector2(hip.y,1.0);var phase=.5*float(i%2)+.25*float(i/2)
		rod(hip,hip-Vector3(0,drop,0),radius,color,LEG,phase,pivot)
		ball(hip-Vector3(0,drop+radius*.5,radius*.6),Vector3(radius*2.6,radius*1.1,radius*3.2),foot,LEG,phase,pivot)

# Bent legs splaying from a body: hip, knee up and out, foot on the ground.
func spider_legs(count: int,center: Vector3,span: float,knee: float,radius: float,color: Color,spread: float=PI*.85):
	for i in range(count):
		var side=-1.0 if i<count/2 else 1.0
		var k=float(i%(count/2))/maxf(1,count/2-1)-.5
		var out=Vector3(side,0,k*spread*.9).normalized()
		var hip=center+out*.15;var bend=center+out*span*.55+Vector3(0,knee,0);var foot=Vector3(center.x,0.0,center.z)+out*span
		var pivot=Vector2(hip.y,.6);var phase=float(i)*.37
		rod(hip,bend,radius,color,LEG,phase,pivot);rod(bend,foot,radius*.75,color,LEG,phase,pivot)

# Tentacles hanging from a ring: chains of shrinking balls that wave.
func tentacles(count: int,center: Vector3,ring_radius: float,length: float,radius: float,color: Color,tip: Color=Color(0,0,0,0)):
	for i in range(count):
		var angle=float(i)/count*TAU;var root=center+Vector3(cos(angle),0,sin(angle))*ring_radius
		var pivot=Vector2(root.y,1.0);var phase=float(i)/count
		for s in range(6):
			var t=float(s)/5.0;var p=root+Vector3(cos(angle),0,sin(angle))*length*.25*t-Vector3(0,length*t,0)
			var r=radius*(1.0-t*.6)
			ball(p,Vector3.ONE*r*2,tip if s==5 and tip.a>0 else color,TAIL,phase,pivot)

# A wing on each side: a flattened membrane on a bony edge, flapping at the tips.
func wings(root: Vector3,span: float,depth: float,color: Color,edge: Color,tilt: float=.25):
	for side in [-1.0,1.0]:
		var center=root+Vector3(side*span*.5,0,0);var pivot=Vector2(absf(root.x)+span*.12,1.0)
		ball(center,Vector3(span,span*.08,depth),color,WING,0.0,pivot,false,Vector3(0,0,side*tilt))
		rod(root,root+Vector3(side*span*.95,span*.2*1.0,-depth*.3),span*.05,edge,WING,0.0,pivot)

# An antenna with a glowing bulb.
func antenna(base: Vector3,top: Vector3,bulb: float,color: Color,glow_color: Color,phase: float=0.0):
	var pivot=Vector2(base.y,1.0)
	rod(base,top,bulb*.22,color,STALK,phase,pivot)
	ball(top,Vector3.ONE*bulb*2,glow_color,STALK,phase,pivot,true)

func spots(center: Vector3,radii: Vector3,color: Color,count: int,size: float,seed_value: int,glow: bool=false,upper_only: bool=true):
	var rng=RandomNumberGenerator.new();rng.seed=seed_value
	for i in range(count):
		var d=Vector3(rng.randf_range(-1,1),rng.randf_range(-.2 if upper_only else -1.0,1),rng.randf_range(-1,1)).normalized()
		if d.z<-.55: d.z=-d.z  # keep the face clear
		var p=center+d*radii*.97
		var patch=Basis.looking_at(d,Vector3.UP if absf(d.y)<.95 else Vector3.FORWARD).scaled(Vector3(size,size,size*.35))
		add("ball",Transform3D(patch,p),color,BODY,0.0,Vector2(0,1),glow)

func commit() -> ArrayMesh:
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=verts;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_COLOR]=colors
	arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_TEX_UV2]=uv2s;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func height() -> float:
	var top=0.0
	for v in verts: top=maxf(top,v.y)
	return top

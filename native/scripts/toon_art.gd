extends RefCounted
class_name ToonArt

static var palette = {}
static var outline: ShaderMaterial
static var shared_ball: SphereMesh

static func paint(color: Color) -> StandardMaterial3D:
	var key=color.to_html()
	if palette.has(key): return palette[key]
	var m=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=1
	m.metallic_specular=0
	m.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
	if color in [Color("b67552"),Color("c28445"),Color("c77f68"),Color("bd8465")]:
		m.albedo_texture=load("res://assets/illustrated/bark.png")
		m.albedo_color=Color("fff0db")
	elif color in [Color("849eb1"),Color("9bb4b9")]:
		m.albedo_texture=load("res://assets/illustrated/stone.png")
		m.albedo_color=Color("c0cbd1")
	if outline==null:
		outline=ShaderMaterial.new()
		var shader=Shader.new()
		shader.code="shader_type spatial;render_mode unshaded,cull_front;void vertex(){VERTEX+=NORMAL*0.012;}void fragment(){ALBEDO=vec3(.26,.20,.15);}"
		outline.shader=shader
	m.next_pass=outline
	palette[key]=m
	return m

static func part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, scale_value: Vector3=Vector3.ONE) -> MeshInstance3D:
	var node=MeshInstance3D.new()
	node.set_meta("paint_color",color)
	node.mesh=mesh;node.material_override=paint(color);node.position=pos;node.scale=scale_value
	parent.add_child(node)
	return node

static func ball(parent: Node3D, color: Color, pos: Vector3, scale_value: Vector3) -> MeshInstance3D:
	if shared_ball==null:
		shared_ball=SphereMesh.new();shared_ball.radius=.5;shared_ball.height=1;shared_ball.radial_segments=16;shared_ball.rings=8
	return part(parent,shared_ball,color,pos,scale_value)

static func tube(parent: Node3D,color: Color,pos: Vector3,top: float,bottom: float,height: float) -> MeshInstance3D:
	var mesh=CylinderMesh.new();mesh.top_radius=top;mesh.bottom_radius=bottom;mesh.height=height;mesh.radial_segments=12
	return part(parent,mesh,color,pos)

static func eyes(parent: Node3D,y: float,z: float,gap: float=.18):
	for x in [-gap,gap]:
		ball(parent,Color("fff8de"),Vector3(x,y,z),Vector3(.23,.29,.12))
		ball(parent,Color("17293d"),Vector3(x,y,z-.055),Vector3(.10,.15,.08))
		ball(parent,Color.WHITE,Vector3(x-.025,y+.035,z-.1),Vector3(.035,.04,.025))

static func make(name: String,height: float) -> Node3D:
	var root=Node3D.new()
	if name=="pine_tree_01" or name=="island_tree_01":
		tube(root,Color("b67552"),Vector3(0,.33,0),.055,.085,.66)
		for i in range(4):
			ball(root,Color("51b899") if name=="pine_tree_01" else Color("ecab8a"),Vector3(sin(i*2.4)*.17,.65+i*.075,cos(i*2.4)*.17),Vector3(.62,.48,.62))
	elif name=="coast_rocks_02":
		for i in range(3): ball(root,Color("849eb1") if i%2==0 else Color("9bb4b9"),Vector3(i*.3,.22,0),Vector3(.65,.45,.6))
	elif name=="old_military_crate":
		var mesh=BoxMesh.new();mesh.size=Vector3(.95,.48,.68)
		part(root,mesh,Color("c28445"),Vector3(0,.27,0))
		for x in [-.3,.3]:
			mesh=BoxMesh.new();mesh.size=Vector3(.08,.50,.72);part(root,mesh,Color("dfb771"),Vector3(x,.27,0))
		var lid=Node3D.new();lid.position=Vector3(0,.51,.34);root.add_child(lid);root.set_meta("lid",lid)
		mesh=BoxMesh.new();mesh.size=Vector3(.99,.14,.72);part(lid,mesh,Color("bd8465"),Vector3(0,.04,-.34))
		for x in [-.3,.3]:
			mesh=BoxMesh.new();mesh.size=Vector3(.08,.16,.75);part(lid,mesh,Color("dfb771"),Vector3(x,.04,-.34))
		mesh=BoxMesh.new();mesh.size=Vector3(.17,.23,.07);part(root,mesh,Color("fff1ac"),Vector3(0,.4,-.37))
	elif name=="rubber_duck_toy":
		ball(root,Color("ffd459"),Vector3(0,.55,0),Vector3(.9,.95,.85))
		ball(root,Color("ffe57d"),Vector3(0,1.1,-.06),Vector3(.72,.7,.7))
		eyes(root,1.18,-.38)
		ball(root,Color("ee9656"),Vector3(0,.99,-.51),Vector3(.48,.16,.42))
		for x in [-.48,.48]: ball(root,Color("f4bd49"),Vector3(x,.6,.04),Vector3(.19,.5,.5))
		var cape=PrismMesh.new();cape.size=Vector3(.85,.85,.12)
		part(root,cape,Color("815aaa"),Vector3(0,.65,.4))
	elif name=="florist":
		tube(root,Color("e5946f"),Vector3(0,.42,0),.4,.28,.72)
		tube(root,Color("f2b48c"),Vector3(0,.8,0),.45,.45,.12)
		tube(root,Color("5dae7c"),Vector3(0,1.05,0),.045,.06,.5)
		for i in range(8): ball(root,Color("f5a4cc"),Vector3(cos(i*TAU/8)*.32,1.3+sin(i*TAU/8)*.32,-.06),Vector3(.39,.39,.2))
		ball(root,Color("ffe38e"),Vector3(0,1.3,-.13),Vector3(.49,.49,.24))
		eyes(root,1.34,-.28,.115)
		for x in [-.46,.46]:
			var leaf=ball(root,Color("62bf86"),Vector3(x,.85,0),Vector3(.35,.15,.17));leaf.rotation.z=signf(x)*.5
	elif name=="sweet_potato":
		ball(root,Color("e2b781"),Vector3(0,.72,0),Vector3(1.0,1.45,.9))
		eyes(root,.96,-.42)
		for i in range(4): ball(root,Color("65b98a"),Vector3(sin(i*1.6)*.22,1.46,cos(i*1.6)*.2),Vector3(.25,.35,.2))
	elif name=="hamburger_buns":
		ball(root,Color("d19453"),Vector3(0,.6,0),Vector3(1.2,1.15,.75))
		ball(root,Color("ffe0a0"),Vector3(0,.64,-.11),Vector3(1.04,.95,.65))
		eyes(root,.81,-.4)
		ball(root,Color("8baac0"),Vector3(0,1.21,0),Vector3(1.03,.33,.78))
		for x in [-.23,0,.23]: ball(root,Color("b57545"),Vector3(x,1.04,-.38),Vector3(.08,.2,.08))
	elif name=="pipe_wrench":
		ball(root,Color("d9696c"),Vector3(0,.62,0),Vector3(.73,.87,.63))
		ball(root,Color("f8d4a5"),Vector3(0,1.19,0),Vector3(.57,.56,.54))
		eyes(root,1.21,-.28)
		ball(root,Color("f3c66a"),Vector3(0,1.43,0),Vector3(.71,.23,.62))
		tube(root,Color("8aa7bc"),Vector3(.49,.8,0),.045,.045,.92)
		for x in [.39,.59]: tube(root,Color("b5ccdb"),Vector3(x,1.35,0),.06,.06,.24)
	elif name=="street_rat":
		ball(root,Color("a38cc7"),Vector3(0,.48,0),Vector3(.85,.87,.7))
		ball(root,Color("b6a1d6"),Vector3(0,.9,-.05),Vector3(.62,.62,.6))
		for x in [-.28,.28]:
			ball(root,Color("a38cc7"),Vector3(x,1.13,0),Vector3(.36,.36,.14))
			ball(root,Color("e9afc1"),Vector3(x,1.13,-.05),Vector3(.22,.22,.08))
		eyes(root,.95,-.31,.145)
		ball(root,Color("efb6c9"),Vector3(0,.79,-.39),Vector3(.23,.14,.21))
		var tail=TorusMesh.new();tail.inner_radius=.19;tail.outer_radius=.25
		var t=part(root,tail,Color("c89cbe"),Vector3(.34,.2,.37));t.rotation.x=PI/2
	else:
		# Boss/Granny: a round, expressive crowned character rather than a scanned bust.
		ball(root,Color("7d84c3"),Vector3(0,.61,0),Vector3(.9,1.1,.75))
		ball(root,Color("f3ceab"),Vector3(0,1.23,0),Vector3(.64,.62,.63))
		for x in [-.32,.32]: ball(root,Color("dae8e7"),Vector3(x,1.46,0),Vector3(.32,.3,.3))
		eyes(root,1.27,-.31)
		ball(root,Color("eef2eb"),Vector3(0,1.49,.06),Vector3(.7,.27,.52))
	for x in [-.24,.24]: ball(root,Color("38475d"),Vector3(x,.12,-.12),Vector3(.28,.21,.4))
	root.scale=Vector3.ONE*height/1.65 if name not in ["pine_tree_01","island_tree_01","coast_rocks_02","old_military_crate"] else Vector3.ONE*height
	var wrapper=Node3D.new()
	wrapper.add_child(root)
	return wrapper

extends RefCounted
class_name NatureScenery

const GLOW=[Color("59edb9"),Color("b7e76b"),Color("75caff"),Color("8ee9ed"),Color("ff8451"),Color("cf8fff"),Color("b6ff3a")]
const BARK=[Color("506b57"),Color("675471"),Color("587b9c"),Color("547b86"),Color("603f4b"),Color("71507e"),Color("7a4a2c")]
const BLOOM=[Color("ef619b"),Color("e784be"),Color("b1a0f2"),Color("c5a7ef"),Color("f3ac4b"),Color("eb71bc"),Color("ffc93a")]
static var meshes={}

static func stone(root: Node3D,color: Color,p: Vector3,size: Vector3,glow: bool=false):
	var shape=SphereMesh.new();shape.radial_segments=7;shape.rings=3;shape.radius=.5;shape.height=1
	var node=ToonArt.part(root,shape,color,p,size)
	if glow: node.name="SpectralFlameSap"
	return node

static func branch(root: Node3D,a: Vector3,b: Vector3,radius: float,color: Color,tip: float=.55):
	var shape=CylinderMesh.new();shape.radial_segments=7;shape.top_radius=radius*tip;shape.bottom_radius=radius;shape.height=a.distance_to(b)
	var node=ToonArt.part(root,shape,color,(a+b)*.5)
	var direction=(b-a).normalized();var axis=Vector3.UP.cross(direction)
	if axis.length()>.001: node.quaternion=Quaternion(axis.normalized(),acos(clampf(Vector3.UP.dot(direction),-1,1)))
	return node

static func blossom(root: Node3D,p: Vector3,color: Color,size: float):
	for i in range(5):
		var angle=i*TAU/5
		var petal=stone(root,color,p+Vector3(cos(angle),.1,sin(angle))*size*.5,Vector3(size,.28*size,.6*size))
		petal.rotation.y=-angle;petal.rotation.z=.25
	stone(root,Color("ffdb71"),p+Vector3.UP*.2*size,Vector3.ONE*.3*size,true)

static func mesh(world: Node3D,biome: int,variant: int) -> ArrayMesh:
	var key=Vector2i(biome,variant)
	if meshes.has(key): return meshes[key]
	var root=Node3D.new();world.add_child(root)
	var glow=GLOW[biome];var bark=BARK[biome]
	var height=[9.0,6.0,3.0][variant]
	if biome==6:
		junk(root,variant,height,glow,bark)
	elif variant==2 and biome in [0,3,5]:
		for i in range(5):
			var tip=Vector3(cos(i*2.4)*1.3,1.1+float(i%3)*.55,sin(i*2.4)*1.3)
			branch(root,tip*Vector3(1,0,1),tip,.07,Color("4f9a73"))
			blossom(root,tip,BLOOM[biome],1.0)
			var leaf=stone(root,Color("3da77e"),tip*.5,Vector3(.4,.18,1.6));leaf.rotation.y=i*2.4
	elif biome in [0,3,4,5]:
		# Bent, tapering trunks and splayed roots, never a stacked cylinder tower.
		var previous=Vector3.ZERO
		for i in range(5):
			var next=Vector3(sin(i*.7+variant)*(.2+i*.22),height*(i+1)/5,cos(i*.85)*i*.18)
			branch(root,previous,next,.65-i*.1,bark,(.55-i*.1)/(.65-i*.1));previous=next
		for i in range(5):
			var direction=Vector3.RIGHT.rotated(Vector3.UP,i*TAU/5+variant)
			branch(root,direction*2.2+Vector3.UP*.08,Vector3(0,.85,0),.12,bark,3)
		for i in range(6):
			var angle=i*2.399+variant*.6;var start=previous*lerpf(.45,.9,float(i)/6)
			var elbow=start+Vector3(cos(angle)*1.8,1.2,sin(angle)*1.8)
			var tip=elbow+Vector3(cos(angle)*1.7,.8+sin(i),sin(angle)*1.7)
			branch(root,start,elbow,.24,bark);branch(root,elbow,tip,.14,bark)
			if biome==0:
				var leaf=stone(root,Color("48a978") if i%2==0 else Color("268b80"),tip,Vector3(3.6,1.1,2.1));leaf.rotation.y=angle;leaf.rotation.z=.3
				stone(root,glow,tip+Vector3(0,-.7,0),Vector3(.22,1.2,.22),true)
				if i%3==0: blossom(root,tip+Vector3.UP*.45,BLOOM[biome],1.0)
			elif biome==3:
				var crown=stone(root,Color("68aeb0"),tip,Vector3(2.5,.7,2));crown.rotation.y=angle
				if i%2==0: blossom(root,tip+Vector3.UP*.3,BLOOM[biome],.8)
				for j in range(3):
					var end=tip+Vector3(j*.28,-1.6-j*.65,0)
					branch(root,tip,end,.035,Color("497b82"))
					stone(root,glow,end,Vector3(.16,.55,.16),true)
			elif biome==4:
				branch(root,tip,tip+Vector3(.2,1.1,.2),.22,Color("87494b"),.05)
				stone(root,glow,elbow,Vector3(.18,.75,.18),true)
			else:
				stone(root,Color("9670b6"),tip,Vector3(1.8,.7,1.3))
				for j in range(3):
					var end=tip+Vector3(cos(j*2)*.8,.8+j*.35,sin(j*2)*.8)
					branch(root,tip,end,.12,Color("695078"),.2)
					stone(root,glow,end,Vector3(.4,.7,.4),true)
		# Small luminous shelf fungi at the base are the local light source.
		for i in range(4):
			var p=Vector3(cos(i*2.4)*.55,.6+i*.48,sin(i*2.4)*.55)
			stone(root,glow,p,Vector3(.7,.12,.5),true)
	elif biome==1:
		for i in range(4):
			var p=Vector3(cos(i*2.4)*i*.8,0,sin(i*2.4)*i*.8);var h=height*(1.0-i*.18)
			branch(root,p,p+Vector3(.5,h*.55,0),.35,bark)
			branch(root,p+Vector3(.5,h*.55,0),p+Vector3(.2,h,0),.23,bark)
			stone(root,Color("c465a2") if i%2==0 else Color("876bc6"),p+Vector3(.2,h,0),Vector3(h*.9,h*.25,h*.75))
			stone(root,glow,p+Vector3(.2,h-.3,0),Vector3(h*.7,.14,h*.56),true)
			for j in range(3): stone(root,glow,p+Vector3(cos(j*2)*h*.2,h+.4,sin(j*2)*h*.2),Vector3(.3,.16,.3),true)
	else:
		for i in range(5):
			var p=Vector3(cos(i*2.4)*i*.5,0,sin(i*2.4)*i*.5);var h=height*(1.0-i*.14)
			var tip=p+Vector3(sin(i*2.4)*h*.22,h,cos(i*2.4)*h*.1)
			branch(root,p,tip,.65,bark.lightened(.12),0)
			var light=branch(root,p+Vector3(.18,h*.12,.32),tip+Vector3(.08,-h*.12,.12),.10,glow,0)
			light.name="SpectralFlameCrystal"
	var parts=[];PaintedBatch.collect(root,parts)
	var result=PaintedBatch.merge(root,parts);root.free();meshes[key]=result
	return result

static func cube(root: Node3D,color: Color,p: Vector3,size: Vector3,turn: float=0.0,tilt: float=0.0) -> MeshInstance3D:
	var shape=BoxMesh.new();var node=ToonArt.part(root,shape,color,p,size)
	node.rotation=Vector3(tilt,turn,tilt*.5)
	return node

# Junkyard Planet scenery (reworked October 31, user: "trash looks too basic"):
# recognisable junk built from small parts rather than plain boxes.
#   0 a crane with a lattice mast, cab and counterweight dangling a car from its
#     magnet over a stack of crushed cars (windows, wheels, bumpers, lights)
#   1 a rusted car hulk with its bonnet up and a wheel off, a tyre stack with rims,
#     a fridge with its door hanging open and a TV whose screen still glows
#   2 a scrap heap: a ribbed toxic drum leaking into a glowing puddle, a gear, a
#     washing machine, bent pipes, sheet metal and a traffic cone
# No trees grow here.
const JUNK_PAINTS=[Color("d9b13e"),Color("4f8aa0"),Color("b8483a"),Color("7d8c4e"),Color("e7e1cf"),Color("7a5fa0")]
const JUNK_TYRE=Color("26252a")
const JUNK_STEEL=Color("8c9399")
const JUNK_GLASS=Color("2c4258")

# A group node placed and turned, so pieces can be built in their own frame.
static func piece(root: Node3D,at: Vector3,turn: Vector3=Vector3.ZERO) -> Node3D:
	var node=Node3D.new();root.add_child(node);node.position=at;node.rotation=turn
	return node

# A disc (wheel, lid, gear plate) lying in the plane given by the node's turn.
static func disc(root: Node3D,color: Color,p: Vector3,radius: float,thick: float,turn: Vector3=Vector3.ZERO) -> MeshInstance3D:
	var shape=CylinderMesh.new();shape.radial_segments=12;shape.rings=1;shape.top_radius=radius;shape.bottom_radius=radius;shape.height=thick
	var node=ToonArt.part(root,shape,color,p);node.rotation=turn
	return node

static func wheel(root: Node3D,p: Vector3,radius: float,turn: Vector3=Vector3(0,0,PI*.5)):
	var ring=TorusMesh.new();ring.inner_radius=.5;ring.outer_radius=1.0;ring.rings=14;ring.ring_segments=6
	var node=ToonArt.part(root,ring,JUNK_TYRE,p,Vector3(radius,radius*1.3,radius));node.rotation=turn
	disc(root,JUNK_STEEL,p,radius*.55,radius*.5,turn)

# A small car (about 2.6 m long), crushed flatter when crushed > 0.
static func car(root: Node3D,at: Vector3,turn: Vector3,paint: Color,rust: Color,crushed: float=0.0,glow: Color=Color.WHITE):
	var c=piece(root,at,turn);var squash=1.0-crushed*.55
	cube(c,paint,Vector3(0,.42*squash,0),Vector3(2.6,.5*squash,1.4))
	cube(c,paint.darkened(.12),Vector3(-.15,.86*squash,0),Vector3(1.3,.42*squash,1.24))
	cube(c,JUNK_GLASS,Vector3(-.15,.86*squash,0),Vector3(1.34,.2*squash,1.27))
	cube(c,rust,Vector3(.85,.69*squash,.1),Vector3(.6,.04,.7),.3)
	for end in [-1.0,1.0]:
		cube(c,JUNK_STEEL,Vector3(end*1.33,.3*squash,0),Vector3(.1,.14,1.42))
		for side in [-1.0,1.0]:
			stone(c,glow if end>0 else Color("ff5a4a"),Vector3(end*1.31,.48*squash,side*.5),Vector3(.08,.12,.2),end>0)
			wheel(c,Vector3(end*.82,.24,side*.72),.26,Vector3(PI*.5,0,0))

static func gear(root: Node3D,p: Vector3,radius: float,color: Color,turn: Vector3=Vector3.ZERO):
	var g=piece(root,p,turn)
	disc(g,color,Vector3.ZERO,radius,radius*.25)
	disc(g,color.darkened(.35),Vector3.ZERO,radius*.3,radius*.3)
	for i in range(8):
		var a=i*TAU/8
		cube(g,color,Vector3(cos(a),0,sin(a))*radius*1.08,Vector3(radius*.3,radius*.22,radius*.3),-a)

static func drum(root: Node3D,p: Vector3,color: Color,glow: Color,turn: Vector3=Vector3.ZERO):
	var d=piece(root,p,turn)
	disc(d,color,Vector3(0,.55,0),.42,1.1)
	for y in [.15,.55,.95]: disc(d,color.darkened(.25),Vector3(0,y,0),.45,.07)
	# A yellow hazard band with a dark mark, and a glowing leak at the lid.
	disc(d,Color("f2c230"),Vector3(0,.72,0),.43,.2)
	cube(d,JUNK_TYRE,Vector3(0,.72,-.42),Vector3(.18,.14,.04))
	stone(d,glow,Vector3(.12,1.12,-.1),Vector3(.3,.07,.3),true)

static func junk(root: Node3D,variant: int,height: float,glow: Color,rust: Color):
	match variant:
		0:
			# Crushed cars stacked unevenly; a rusted panel and tyres at the base.
			var y=0.0
			for i in range(4):
				car(root,Vector3(sin(i*1.7)*.3,y,cos(i*1.1)*.25),Vector3(0,i*.6-.4,(i%2-.5)*.07),JUNK_PAINTS[(i*2)%JUNK_PAINTS.size()],rust,.75,glow)
				y+=.62
			for i in range(3): wheel(root,Vector3(-1.9+i*.25,.25+i*.5,1.2),.42,Vector3(PI*.5,.3*i,0))
			cube(root,rust,Vector3(1.7,.45,-.9),Vector3(1.4,.9,.06),.6,.4)
			# The crane: a lattice mast, a cab and counterweight, a long jib, and a car
			# hanging from its magnet.
			var base=Vector3(1.6,0,1.4);var top=base+Vector3(0,height,0)
			for corner in [Vector3(-.22,0,-.22),Vector3(.22,0,-.22),Vector3(.22,0,.22),Vector3(-.22,0,.22)]:
				branch(root,base+corner,top+corner,.06,Color("e2ad2d"),1.0)
			for k in range(6):
				var h=height*(k+.5)/6.5;var h2=height*(k+1.4)/6.5
				branch(root,base+Vector3(-.22,h,-.22),base+Vector3(.22,h2,-.22),.03,Color("c28e1e"),1.0)
				branch(root,base+Vector3(.22,h,.22),base+Vector3(-.22,h2,.22),.03,Color("c28e1e"),1.0)
			cube(root,Color("e2ad2d"),top+Vector3(0,.35,0),Vector3(1.0,.7,.9))
			cube(root,JUNK_GLASS,top+Vector3(.2,.45,-.46),Vector3(.5,.3,.03))
			cube(root,JUNK_STEEL.darkened(.3),top+Vector3(-1.6,.2,0),Vector3(.8,.6,.8))
			branch(root,top+Vector3(-1.4,.25,0),top+Vector3(4.4,.55,0),.11,Color("e2ad2d"),.6)
			var hook=top+Vector3(4.0,.5,0)
			branch(root,hook,hook+Vector3(0,-2.4,0),.025,JUNK_TYRE,1.0)
			disc(root,JUNK_STEEL.darkened(.2),hook+Vector3(0,-2.5,0),.5,.18)
			car(root,hook+Vector3(0,-3.3,0),Vector3(.2,.9,.25),JUNK_PAINTS[1],rust,.2,glow)
			stone(root,glow,top+Vector3(0,.85,0),Vector3(.3,.3,.3),true)
		1:
			# A rusted car hulk with its bonnet propped up and one wheel off.
			car(root,Vector3(.9,0,0),Vector3(0,.3,.04),rust.lightened(.08),rust,0.0,glow)
			cube(root,rust,Vector3(2.25,1.15,.35),Vector3(.75,.04,1.3),.3,0.0).rotation.z=1.0
			wheel(root,Vector3(.2,.35,1.5),.3,Vector3(1.2,0,.2))
			# A tyre stack with steel rims.
			for i in range(4): wheel(root,Vector3(-1.5+sin(i)*.08,.2+i*.34,.2),.5,Vector3(0,0,0))
			# A fridge with its door hanging open, and a TV with a glowing screen.
			var fridge=piece(root,Vector3(-.5,0,-1.6),Vector3(0,.4,-.12))
			cube(fridge,JUNK_PAINTS[4],Vector3(0,.95,0),Vector3(.8,1.9,.7))
			cube(fridge,JUNK_PAINTS[4].darkened(.1),Vector3(.55,.95,-.55),Vector3(.06,1.8,.75),-1.1)
			cube(fridge,JUNK_STEEL,Vector3(-.3,1.3,-.36),Vector3(.05,.4,.05))
			var tv=piece(root,Vector3(-1.9,0,-.9),Vector3(.2,-.5,0))
			cube(tv,Color("5a4636"),Vector3(0,.35,0),Vector3(.8,.65,.6))
			stone(tv,glow,Vector3(0,.37,-.3),Vector3(.55,.42,.06),true)
			branch(tv,Vector3(-.15,.68,0),Vector3(-.35,1.05,0),.015,JUNK_STEEL,1.0)
			branch(tv,Vector3(.15,.68,0),Vector3(.35,1.05,0),.015,JUNK_STEEL,1.0)
		_:
			# A toxic drum leaking into a glowing puddle, a fallen second drum.
			drum(root,Vector3.ZERO,Color("3e6e52"),glow)
			drum(root,Vector3(-1.1,.42,.5),Color("b33a2a"),glow,Vector3(PI*.5,.8,0))
			stone(root,glow,Vector3(.3,.03,-.8),Vector3(1.5,.05,1.0),true)
			gear(root,Vector3(1.0,.35,.5),.45,JUNK_STEEL,Vector3(1.1,0,.2))
			# A washing machine with a round porthole door.
			var washer=piece(root,Vector3(.4,0,1.5),Vector3(0,-.6,0))
			cube(washer,JUNK_PAINTS[4],Vector3(0,.45,0),Vector3(.8,.9,.75))
			disc(washer,JUNK_GLASS,Vector3(0,.42,-.38),.26,.05,Vector3(PI*.5,0,0))
			disc(washer,JUNK_STEEL,Vector3(0,.42,-.37),.3,.03,Vector3(PI*.5,0,0))
			# Bent pipes, sheet metal and a traffic cone.
			branch(root,Vector3(-.5,.1,-1.0),Vector3(-1.6,.5,-1.4),.09,JUNK_STEEL,1.0)
			branch(root,Vector3(-1.6,.5,-1.4),Vector3(-1.9,.1,-.6),.09,JUNK_STEEL,1.0)
			cube(root,rust,Vector3(1.3,.2,-.6),Vector3(1.1,.04,.8),.7,.35)
			cube(root,JUNK_PAINTS[1],Vector3(-.3,.12,1.0),Vector3(.9,.04,.6),-.4,.2)
			var cone=CylinderMesh.new();cone.top_radius=.03;cone.bottom_radius=.22;cone.height=.6;cone.radial_segments=10;cone.rings=1
			ToonArt.part(root,cone,Color("ff7a1a"),Vector3(-1.4,.3,.9))
			disc(root,Color("f4f1e8"),Vector3(-1.4,.34,.9),.14,.08)
			cube(root,Color("ff7a1a"),Vector3(-1.4,.02,.9),Vector3(.5,.04,.5))

static func collision(parent: Node3D,biome: int,variant: int,scale_value: float):
	var body=StaticBody3D.new();body.collision_layer=1;body.set_meta("natural_obstacle",true);parent.add_child(body)
	var collider=CollisionShape3D.new();var trunk=CylinderShape3D.new()
	trunk.radius=(1.1 if biome==2 or biome==6 and variant<2 else .3 if variant==2 else .65)*scale_value;trunk.height=[9.0,6.0,3.0][variant]*scale_value
	collider.shape=trunk;collider.position.y=trunk.height*.5;body.add_child(collider)

static func light(parent: Node3D,biome: int,height: float=1.5,large: bool=false):
	var lamp=OmniLight3D.new();lamp.name="LivingGlow";lamp.position=Vector3(0,height,0)
	lamp.light_color=Color("ffd58c") if biome in [0,3] else GLOW[biome];lamp.light_energy=1.5 if large else .9;lamp.omni_range=13 if large else 7
	lamp.shadow_enabled=true;lamp.distance_fade_enabled=true;lamp.distance_fade_begin=26;lamp.distance_fade_length=12
	parent.add_child(lamp)

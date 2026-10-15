extends RefCounted
class_name NatureScenery

const GLOW=[Color("59edb9"),Color("b7e76b"),Color("75caff"),Color("8ee9ed"),Color("ff8451"),Color("cf8fff")]
const BARK=[Color("506b57"),Color("675471"),Color("587b9c"),Color("547b86"),Color("603f4b"),Color("71507e")]
const BLOOM=[Color("ef619b"),Color("e784be"),Color("b1a0f2"),Color("c5a7ef"),Color("f3ac4b"),Color("eb71bc")]
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
	if variant==2 and biome in [0,3,5]:
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

static func collision(parent: Node3D,biome: int,variant: int,scale_value: float):
	var body=StaticBody3D.new();body.collision_layer=1;body.set_meta("natural_obstacle",true);parent.add_child(body)
	var collider=CollisionShape3D.new();var trunk=CylinderShape3D.new()
	trunk.radius=(1.1 if biome==2 else .3 if variant==2 else .65)*scale_value;trunk.height=[9.0,6.0,3.0][variant]*scale_value
	collider.shape=trunk;collider.position.y=trunk.height*.5;body.add_child(collider)

static func light(parent: Node3D,biome: int,height: float=1.5,large: bool=false):
	var lamp=OmniLight3D.new();lamp.name="LivingGlow";lamp.position=Vector3(0,height,0)
	lamp.light_color=Color("ffd58c") if biome in [0,3] else GLOW[biome];lamp.light_energy=1.5 if large else .9;lamp.omni_range=13 if large else 7
	lamp.shadow_enabled=true;lamp.distance_fade_enabled=true;lamp.distance_fade_begin=26;lamp.distance_fade_length=12
	parent.add_child(lamp)

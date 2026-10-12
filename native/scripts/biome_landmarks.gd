extends RefCounted
class_name BiomeLandmarks

const NAMES=["The Big Bloom","Mushroom Manor","Crystal Moon Gate","Kite Castle","Sugar Volcano","Planet Garden"]
const COLORS=[Color("285b50"),Color("563661"),Color("344962"),Color("42626b"),Color("612b36"),Color("443465")]

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
	var accent=COLORS[biome]
	# The raised reward area stays clear of the tall central sculpture.
	box(root,accent.darkened(.24),Vector3(0,1.25,0),Vector3(10,.5,9),true)
	for step in range(3):
		box(root,accent.darkened(.08),Vector3(0,.25+step*.5,7-step*1.6),Vector3(3,.5,2),true)
	var art=Node3D.new();root.add_child(art);art.position=Vector3(0,world.height_at(p.x,p.z-17)-p.y,-17)
	match biome:
		0:
			column(art,Color("202833"),Vector3(0,7,0),1.7,14)
			for i in range(7):
				var angle=i*TAU/7
				cut_stone(art,accent if i%2==0 else Color("24854e"),Vector3(cos(angle)*4,13+sin(i)*1.3,sin(angle)*4),Vector3(8,7,8))
			for i in range(5):
				var angle=i*TAU/5
				cut_stone(art,Color("f13b7e"),Vector3(cos(angle)*3,18,sin(angle)*3),Vector3(4,2,4))
			cut_stone(art,Color("f9c942"),Vector3(0,18.7,0),Vector3(3,2.2,3))
		1:
			for i in range(3):
				var pos=Vector3((i-1)*6,0,-abs(i-1)*3);var height=15 if i==1 else 9
				column(art,Color("29373e"),pos+Vector3.UP*height*.5,1.4,height)
				cut_stone(art,accent if i==1 else Color("743a56"),pos+Vector3.UP*height,Vector3(11,4,11))
				for spot in range(5):
					var angle=spot*TAU/5
					cut_stone(art,Color("ffe9b0"),pos+Vector3(cos(angle)*3,height+1.3,sin(angle)*3),Vector3(1.4,.4,1.4))
		2:
			for side in [-1,1]:
				var crystal=PrismMesh.new();crystal.size=Vector3(4,21,4)
				var node=ToonArt.part(art,crystal,accent,Vector3(side*7,10.5,0));node.rotation.z=side*.12;node.create_convex_collision()
			var orbit=ring(art,Color("f5d075"),Vector3(0,14,0),6);orbit.rotation.x=PI/2
			cut_stone(art,Color("9dd7fa"),Vector3(0,14,0),Vector3(4,4,4))
		3:
			for i in range(3):
				var height=23 if i==1 else 16;var pos=Vector3((i-1)*6,height*.5,0)
				box(art,Color("314352"),pos,Vector3(3,height,3),true)
				ToonArt.tube(art,Color("866149"),Vector3(pos.x,height+2,0),0,3.5,4)
				box(art,Color("f6c946"),Vector3(pos.x+.9,height+5,0),Vector3(2.2,1.5,.2))
			box(art,Color("eee3c6"),Vector3(0,10,0),Vector3(14,1,4))
		4:
			var volcano=ToonArt.tube(art,Color("38212c"),Vector3(0,8,0),3,8,16);volcano.create_convex_collision()
			ring(art,Color("ffb83f"),Vector3(0,16,0),3)
			for i in range(6):
				var angle=i*TAU/6
				ToonArt.tube(art,Color("ff8b23"),Vector3(cos(angle)*1.6,18+float(i%2),sin(angle)*1.6),0,.9,5)
			for side in [-1,1]:
				column(art,Color("594e49"),Vector3(side*10,5,0),.7,10)
				cut_stone(art,Color("ad3659"),Vector3(side*10,11,0),Vector3(6,6,1.4))
		5:
			for side in [-1,1]: column(art,Color("6543a7"),Vector3(side*8,10,0),1.2,20)
			box(art,Color("7660c8"),Vector3(0,18,0),Vector3(18,1,3),true)
			cut_stone(art,Color("ad5ad7"),Vector3(0,17,0),Vector3(8,8,8))
			var orbit=ring(art,Color("f4bb64"),Vector3(0,17,0),6);orbit.rotation.z=.45
			cut_stone(art,Color("52bde6"),Vector3(-6,23,1),Vector3(3,3,3))
	# Readable door/window framing and small illustrated cracks on existing structures.
	for side in [-1,1]:
		box(art,Color("101a28"),Vector3(side*2.1,2.4,2.0),Vector3(1.1,1.5,.16))
		box(art,Color("ffd991"),Vector3(side*2.1,2.4,2.1),Vector3(.7,1.1,.08))
	box(art,Color("101a28"),Vector3(0,1.0,2.2),Vector3(1.6,2,.18))
	box(art,accent.lightened(.2),Vector3(0,1.0,2.32),Vector3(1.2,1.8,.08))
	for i in range(3):
		var crack=box(root,accent.darkened(.4),Vector3(-3+i*.24,1.52,1+i*.3),Vector3(.07,.02,.7));crack.rotation.y=.4 if i%2==0 else -.6
	# Gilt seams and stone buttresses frame the silhouette and reward platform.
	for side in [-1,1]:
		for j in range(3):
			var fin=box(art,Color("aa8550"),Vector3(side*(2.2+j*.6),3.5+j*.65,.3),Vector3(.16,4+j,.20));fin.rotation.z=-side*.25
		box(root,Color("a17d45"),Vector3(side*4.8,1.54,0),Vector3(.10,.035,8.5))
	var nodes=[];PaintedBatch.collect(root,nodes)
	var mesh=PaintedBatch.merge(root,nodes)
	for node in nodes:
		# Keep their collision children in the scene while replacing render geometry.
		node.visible=false
		for child in node.get_children():
			if child is StaticBody3D: child.reparent(root,true)
		node.queue_free()
	var paint=PaintedBatch.material();paint.set_shader_parameter("fade_near",false)
	paint.next_pass=paint.next_pass.duplicate();paint.next_pass.set_shader_parameter("fade_near",false)
	var combined=MeshInstance3D.new();combined.mesh=mesh;combined.material_override=paint;root.add_child(combined)
	var title=Label3D.new();title.text=NAMES[biome];title.position=Vector3(0,4,0);title.font_size=30;title.modulate=Color("fff0ca");title.billboard=BaseMaterial3D.BILLBOARD_ENABLED;title.visibility_range_end=55;root.add_child(title)

	var banner=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(1.4,2.2);plane.orientation=PlaneMesh.FACE_Z;banner.mesh=plane
	banner.position=Vector3(4,4,-2);var cloth=ShaderMaterial.new();cloth.shader=preload("res://shaders/banner.gdshader");cloth.set_shader_parameter("tint",accent);banner.material_override=cloth;root.add_child(banner)

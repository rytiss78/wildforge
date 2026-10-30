extends RefCounted
class_name MassiveArchitecture

const TITLES=["Verdant Archive","Drowned Pumpworks","Lunar Observatory","Cloud Exchange","Ember Foundry","Astral Hangar","Crusher Works"]
const STONE=[Color("304d44"),Color("3b4149"),Color("354459"),Color("4d646b"),Color("442c35"),Color("39334f"),Color("4a3a2c")]
const GLOW=[Color("75edac"),Color("c692f2"),Color("78cfff"),Color("f8d17c"),Color("ff713b"),Color("ab8fff"),Color("b6ff3a")]

static func box(root: Node3D,color: Color,p: Vector3,size: Vector3,solid: bool=true):
	var node=BiomeLandmarks.box(root,color,p,size)
	if solid:
		var body=StaticBody3D.new();root.add_child(body);body.position=p
		var collider=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;collider.shape=shape;body.add_child(collider)
	return node

static func build(world: RealmWorld):
	for biome in range(RealmWorld.BIOME_COUNT):
		var angle=(float(biome)+.5)*RealmWorld.BIOME_ARC-float(world.seed_value%23)*.03-world.realm*.4
		var p=Vector3(cos(angle)*248,0,sin(angle)*248)
		var root=Node3D.new();root.name="GreatHall_"+str(biome);world.add_child(root)
		root.rotation.y=atan2(p.x,p.z)
		# Foundations reach below all sampled terrain; the open courtyard keeps its natural floor.
		var top=-1000.0;var bottom=1000.0
		for x in [-29,0,29]:
			for z in [-20,0,20]:
				var q=p+Vector3(x,0,z).rotated(Vector3.UP,root.rotation.y)
				var h=world.height_at(q.x,q.z);top=maxf(top,h);bottom=minf(bottom,h)
		p.y=top;root.position=p;world.building_sites.append(root)
		var stone=STONE[biome];var bronze=Color("a98252");var ink=Color("111c2c");var glow=GLOW[biome].darkened(.32)
		var depth=top-bottom+4;var wall_height=19+depth
		for side in [-1,1]:
			# Broad inhabited wings, with a 20m-wide open route between them.
			box(root,stone,Vector3(side*20,(19-depth)*.5,0),Vector3(18,wall_height,34))
			box(root,ink,Vector3(side*20,19.3,0),Vector3(20,1.4,37))
			box(root,bronze,Vector3(side*20,18.5,17.1),Vector3(18,.25,.22),false)
			for z in [-14,-5,5,14]:
				box(root,stone.lightened(.09),Vector3(side*29,7,z),Vector3(2.4,24,3))
			for z in [-17.1,17.1]:
				for band in [2,5,16]:
					box(root,stone.lightened(.1),Vector3(side*20,band,z),Vector3(18,.35,.5),false)
				for x in [11.4,17,23,28.6]:
					box(root,stone.lightened(.14),Vector3(side*x,7,z),Vector3(.65,23,1.1),false)
				for x in [14,20,26]:
					box(root,ink,Vector3(side*x,10,z),Vector3(3.6,7,.4),false)
					var window=box(root,glow,Vector3(side*x,10,z*1.02),Vector3(2.3,5.8,.2),false)
					window.name="SpectralFlameWindow"
					box(root,bronze,Vector3(side*x,10,z*1.035),Vector3(.18,5.9,.22),false)
					box(root,bronze,Vector3(side*x,10,z*1.035),Vector3(2.4,.18,.22),false)
		# Elevated gallery joins the wings. Both ground-level entrances remain open.
		box(root,stone.lightened(.08),Vector3(0,15,-11),Vector3(24,5,9))
		box(root,bronze,Vector3(0,12.3,-6.4),Vector3(24,.22,.3),false)
		for side in [-1,1]:
			box(root,bronze,Vector3(side*10.7,6,16),Vector3(.3,12,.35),false)
		match biome:
			0:
				for side in [-1,1]:
					var roof=PrismMesh.new();roof.size=Vector3(22,8,39)
					ToonArt.part(root,roof,stone.lightened(.1),Vector3(side*20,24,0))
				for i in range(5):
					var leaf=BiomeLandmarks.cut_stone(root,Color("23634c"),Vector3(-27+i*13,21,-15),Vector3(8,3,5));leaf.rotation.z=.25
			1:
				for side in [-1,1]:
					ToonArt.tube(root,stone.lightened(.12),Vector3(side*20,23,0),7,8,8)
					BiomeLandmarks.ring(root,bronze,Vector3(side*20,27,0),7)
					box(root,ink,Vector3(side*20,28,0),Vector3(14,1.5,14))
				box(root,bronze,Vector3(0,22,0),Vector3(28,1.5,2),false)
			2:
				for side in [-1,1]:
					ToonArt.ball(root,stone.lightened(.14),Vector3(side*20,20,0),Vector3(19,15,29))
					var orbit=BiomeLandmarks.ring(root,bronze,Vector3(side*20,24,0),9);orbit.rotation.x=PI/2
				box(root,glow,Vector3(0,21,-11),Vector3(3,6,3),false).name="SpectralFlameLens"
			3:
				for side in [-1,1]:
					for z in [-13,13]:
						box(root,stone.lightened(.13),Vector3(side*20,24,z),Vector3(16,8,6))
						ToonArt.tube(root,bronze,Vector3(side*20,30,z),0,8,6)
				box(root,stone,Vector3(0,26,-11),Vector3(28,3,6))
			4:
				for side in [-1,1]:
					for z in [-9,9]:
						box(root,ink,Vector3(side*20,26,z),Vector3(7,14,7))
						box(root,bronze,Vector3(side*20,32,z),Vector3(8,1,8),false)
						box(root,glow,Vector3(side*20,32.6,z),Vector3(5,.3,5),false).name="SpectralFlameKiln"
			5:
				for side in [-1,1]:
					var roof=PrismMesh.new();roof.size=Vector3(22,10,37)
					ToonArt.part(root,roof,stone.lightened(.12),Vector3(side*20,24,0))
				var orbit=BiomeLandmarks.ring(root,bronze,Vector3(0,25,-11),8);orbit.rotation.x=PI/2;orbit.rotation.z=.4
				ToonArt.ball(root,glow,Vector3(0,25,-11),Vector3(4,4,4)).name="SpectralFlameCore"
			6:
				# Crusher Works: smokestacks and a hanging crusher plate over the gallery.
				for side in [-1,1]:
					for z in [-10,10]:
						ToonArt.tube(root,Color("6a3a24"),Vector3(side*22,27,z),2.2,2.8,16)
						box(root,ink,Vector3(side*22,35.2,z),Vector3(5.2,.8,5.2),false)
				box(root,Color("c9a23a"),Vector3(0,27,-11),Vector3(26,1.6,3))
				box(root,STONE[6].lightened(.18),Vector3(0,23,-11),Vector3(9,4,6))
				box(root,glow,Vector3(0,20.8,-11),Vector3(7,.3,4),false).name="SpectralFlameCrusher"
		for side in [-1,1]:
			var light=OmniLight3D.new();root.add_child(light);light.position=Vector3(side*9,8,13)
			light.light_color=glow;light.light_energy=2;light.omni_range=20;light.shadow_enabled=true
			light.distance_fade_enabled=true;light.distance_fade_begin=50;light.distance_fade_length=20
		var parts=[];PaintedBatch.collect(root,parts)
		var combined=MeshInstance3D.new();combined.mesh=PaintedBatch.merge(root,parts);combined.material_override=world.scenery_material;root.add_child(combined)
		combined.visibility_range_end=215;combined.visibility_range_end_margin=20
		for part in parts: part.queue_free()

static func occupied(world: RealmWorld,p: Vector3) -> bool:
	for root in world.building_sites:
		var q=root.to_local(p)
		if absf(q.x)<33 and absf(q.z)<23: return true
	return false

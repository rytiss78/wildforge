extends RefCounted

# Stonework beside the open route. Terrain heights and camera remain unchanged.
static func build(world: Node3D):
	var root=Node3D.new();root.name="ForgeClearing";world.add_child(root)
	var pigment=PaintedBatch.material()
	for side in [-1,1]:
		for row in range(3):
			var p=Vector3(side*(9.0+row*1.4),0,-8-row*14)
			p.y=world.height_at(p.x,p.z)
			var column=MeshInstance3D.new();column.mesh=load("res://assets/style3d/baked/prop_0_5.res");column.material_override=pigment;column.position=p;root.add_child(column)
			var body=StaticBody3D.new();body.collision_layer=1;body.position=p;root.add_child(body)
			var collider=CollisionShape3D.new();var shape=CylinderShape3D.new();shape.radius=.68;shape.height=8
			collider.shape=shape;collider.position.y=4;body.add_child(collider)
			var light=OmniLight3D.new();light.position=p+Vector3.UP*8.6;light.light_color=Color("38ff9e");light.light_energy=3.8;light.omni_range=14;root.add_child(light)
			# Low inset lamps cast isolated pools, with a visible source on each pillar.
			var lamp_position=p+Vector3(-side*.65,1.6,.48)
			var housing=BoxMesh.new();housing.size=Vector3(.35,.75,.25)
			ToonArt.part(root,housing,Color("101827"),lamp_position)
			var lens=BoxMesh.new();lens.size=Vector3(.21,.46,.04)
			var glow=ToonArt.part(root,lens,Color("52ffa2"),lamp_position+Vector3(0,0,.15))
			var flame=StandardMaterial3D.new();flame.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;flame.albedo_color=Color("77ffd4");flame.emission_enabled=true;flame.emission=Color("23ef8c");glow.material_override=flame
			var pool=OmniLight3D.new();pool.position=lamp_position+Vector3(0,0,.5);pool.light_color=Color("33fca3");pool.light_energy=2.4;pool.omni_range=6.5;root.add_child(pool)
			# Broken carved lintels stay above the existing walkable surface.
			for j in range(4):
				var block=BoxMesh.new();block.size=Vector3(1.8,.48,.8)
				var stone=ToonArt.part(root,block,Color("5c9690"),p+Vector3(side*(.7+j*1.8),6.7-j*.1,0))
				stone.rotation.z=side*.035
	# A thin engraved ground seal follows the existing terrain; no new step/collider.
	var mesh=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(64):
		for corner in [Vector2(i,5.0),Vector2(i+1,5.0),Vector2(i,5.12),Vector2(i,5.12),Vector2(i+1,5.0),Vector2(i+1,5.12)]:
			var angle=corner.x*TAU/64;var p=Vector3(cos(angle)*corner.y,0,-15+sin(angle)*corner.y);p.y=world.height_at(p.x,p.z)+.025
			mesh.add_vertex(p)
	mesh.generate_normals()
	var seal=MeshInstance3D.new();seal.mesh=mesh.commit();seal.material_override=ToonArt.paint(Color("e9bd63"));root.add_child(seal)

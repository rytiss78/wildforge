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
			var light=OmniLight3D.new();light.position=p+Vector3.UP*8.6;light.light_color=Color("62f0b2");light.light_energy=2.2;light.omni_range=13;root.add_child(light)
			# Broken carved lintels stay above the existing walkable surface.
			for j in range(4):
				var block=BoxMesh.new();block.size=Vector3(1.8,.48,.8)
				var stone=ToonArt.part(root,block,Color("324d47"),p+Vector3(side*(.7+j*1.8),6.7-j*.1,0))
				stone.rotation.z=side*.035
	# A thin engraved ground seal follows the existing terrain; no new step/collider.
	var mesh=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(64):
		for corner in [Vector2(i,5.0),Vector2(i+1,5.0),Vector2(i,5.12),Vector2(i,5.12),Vector2(i+1,5.0),Vector2(i+1,5.12)]:
			var angle=corner.x*TAU/64;var p=Vector3(cos(angle)*corner.y,0,-15+sin(angle)*corner.y);p.y=world.height_at(p.x,p.z)+.025
			mesh.add_vertex(p)
	mesh.generate_normals()
	var seal=MeshInstance3D.new();seal.mesh=mesh.commit();seal.material_override=ToonArt.paint(Color("a68c50"));root.add_child(seal)

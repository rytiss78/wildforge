extends SceneTree

func _initialize(): call_deferred("bake")

func bake():
	var stage=Node3D.new();root.add_child(stage)
	DirAccess.make_dir_recursive_absolute("res://assets/style3d/baked")
	var metadata={}
	for prefix in ["creature","prop"]:
		for biome in range(6):
			for index in range(6):
				var id="%s_%d_%d" % [prefix,biome,index]
				var scene=load("res://assets/style3d/"+id+".glb").instantiate();stage.add_child(scene)
				var nodes=[];PaintedBatch.collect(scene,nodes)
				if prefix=="creature":
					var orb=scene.find_child("GlassCore",true,false) as MeshInstance3D
					metadata[id]={"core_position":[orb.global_position.x,orb.global_position.y,orb.global_position.z],"radius":orb.mesh.get_aabb().size.y*.5}
					ResourceSaver.save(orb.mesh,"res://assets/style3d/baked/"+id+"-core.res")
					nodes=nodes.filter(func(node):return node.name!="GlassCore")
				var merged=PaintedBatch.merge(scene,nodes)
				var importer=ImporterMesh.new();importer.add_surface(Mesh.PRIMITIVE_TRIANGLES,merged.surface_get_arrays(0));importer.generate_lods(60,25,[])
				var mesh=importer.get_mesh();ResourceSaver.save(mesh,"res://assets/style3d/baked/"+id+".res")
				print("BAKED ",id," lods=",importer.get_surface_lod_count(0));scene.free()
	for asset in ["brass_bullet","weapon_boomerang","weapon_disc","weapon_bomb"]:
		var scene=load("res://assets/style3d/"+asset+".glb").instantiate();stage.add_child(scene)
		var nodes=[];PaintedBatch.collect(scene,nodes);var mesh=PaintedBatch.merge(scene,nodes);ResourceSaver.save(mesh,"res://assets/style3d/baked/"+asset+".res");scene.free()
	var file=FileAccess.open("res://assets/style3d/baked/cores.json",FileAccess.WRITE);file.store_string(JSON.stringify(metadata,"  "));file.close()
	stage.free();quit()

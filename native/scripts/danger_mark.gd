extends RefCounted

static func make(game,point: Vector3,radius: float,style: String) -> MeshInstance3D:
	var mesh=SurfaceTool.new();mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(48):
		for uv in [Vector2.ZERO,Vector2.RIGHT.rotated(i*TAU/48),Vector2.RIGHT.rotated((i+1)*TAU/48)]:
			var p=Vector3(uv.x*radius,0,uv.y*radius)
			p.y=game.world.height_at(point.x+p.x,point.z+p.z)-point.y+.09
			mesh.set_uv(uv*.5+Vector2.ONE*.5);mesh.add_vertex(p)
	mesh.generate_normals()
	var node=MeshInstance3D.new();node.mesh=mesh.commit();node.position=point
	var paint=ShaderMaterial.new();paint.shader=preload("res://shaders/danger_mark.gdshader")
	# "ally" marks the hero's own strikes in gold, apart from enemy warnings.
	paint.set_shader_parameter("ink",Color("ffd35a") if style=="ally" else Color("ff354f") if style=="annihilation" else Color("55bfff") if style=="orbital" else Color("b5a1ff") if style=="void" else Color("ed9455") if style in ["roots","lava","meteor"] else Color("72d5d8") if style=="storm" else Color("b5d775"))
	node.material_override=paint;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;game.add_child(node)
	return node

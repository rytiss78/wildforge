extends RefCounted
class_name DangerMark

const DANGER=Color("ff4a2e")

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
	# One language: danger red for every enemy attack, gold for the hero's own strikes,
	# pale blue for harmless hazards. Danger fills stay in the red family too (user
	# request, October 24: what hurts must read as red, what is safe must not).
	var ink=Color("ffd35a") if style=="ally" else Color("bfe6ff") if style=="caution" else DANGER
	paint.set_shader_parameter("ink",ink)
	paint.set_shader_parameter("fill",ink if style in ["ally","caution"] else Color("ff354f") if style=="annihilation" else Color("ff6a5a") if style=="orbital" else Color("ff4a7a") if style=="void" else Color("ff7a3d") if style in ["roots","lava","meteor"] else Color("ff5a4a") if style=="storm" else Color("e8402a"))
	node.material_override=paint;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;game.add_child(node)
	return node

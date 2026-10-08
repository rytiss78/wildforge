extends RefCounted
class_name AreaVisual

static func make(parent: Node3D, kind: String, radius: float, point: Vector3) -> Node3D:
	var root=Node3D.new();parent.add_child(root);root.position=point
	if kind=="gravity":
		var disk=MeshInstance3D.new();var mesh=PlaneMesh.new();mesh.size=Vector2.ONE*radius*2
		disk.mesh=mesh;disk.position.y=.15
		var paint=ShaderMaterial.new();paint.shader=preload("res://shaders/area_vortex.gdshader")
		disk.material_override=paint;disk.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(disk)
		var core=MeshInstance3D.new();var ball=SphereMesh.new();ball.radius=radius*.2;ball.height=radius*.4;ball.radial_segments=16;ball.rings=8;core.mesh=ball;core.position.y=radius*.15
		var black=StandardMaterial3D.new();black.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;black.albedo_color=Color("020408");core.material_override=black;core.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(core)
	else:
		for i in range(3):
			var cloud=MeshInstance3D.new();var mesh=QuadMesh.new();mesh.size=Vector2(radius*1.65,radius*1.1);cloud.mesh=mesh
			cloud.position=Vector3(cos(i*TAU/3)*radius*.3,radius*(.3+i*.1),sin(i*TAU/3)*radius*.3)
			var paint=ShaderMaterial.new();paint.shader=preload("res://shaders/area_mist.gdshader");paint.set_shader_parameter("phase",i*4.7)
			paint.set_shader_parameter("mist_color",Color("c78a32") if kind=="ignited" else Color("659e36"))
			cloud.material_override=paint;cloud.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(cloud)
	return root

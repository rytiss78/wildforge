extends RefCounted
class_name InkOverlay

# A full-screen quad on the camera that draws the shared ink outline and vignette.
static func attach(camera: Camera3D) -> MeshInstance3D:
	var quad=MeshInstance3D.new();quad.name="InkOverlay"
	var mesh=QuadMesh.new();mesh.size=Vector2(2,2);quad.mesh=mesh
	var paint=ShaderMaterial.new();paint.shader=preload("res://shaders/ink_overlay.gdshader")
	paint.render_priority=127;quad.material_override=paint
	quad.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The vertex shader places it over the whole view; never cull it.
	quad.extra_cull_margin=16384.0;quad.ignore_occlusion_culling=true
	camera.add_child(quad);quad.position=Vector3(0,0,-1)
	return quad

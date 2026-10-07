extends RefCounted

static func kind(node_name: String) -> int:
	var text=node_name.to_lower()
	for word in ["coat","cape","bowtie","wizardhat","hatcrown","hatbrim"]:
		if word in text: return 1
	for word in ["glove","bookspine","bookbinding","belt","boot"]:
		if word in text: return 2
	for word in ["gimbal","airtank","shower","helmet","suitpod","metal","cannon","track","tread","turret","rim"]:
		if word in text: return 3
	for word in ["tubside","tubfloor","teapot","ceramic"]:
		if word in text: return 4
	return 0

static func material(original: StandardMaterial3D, surface_kind: int, outline: Material) -> ShaderMaterial:
	var result=ShaderMaterial.new();result.shader=preload("res://shaders/hero_surface.gdshader")
	result.set_shader_parameter("base_color",original.albedo_color)
	result.set_shader_parameter("surface_kind",surface_kind);result.next_pass=outline
	return result

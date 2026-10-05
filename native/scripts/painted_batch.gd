extends RefCounted
class_name PaintedBatch

static func collect(node: Node3D,result: Array,skip_hidden: bool=true):
	for child in node.get_children():
		if child is MeshInstance3D:
			if not skip_hidden or child.visible: result.append(child)
		elif child is Node3D: collect(child,result,skip_hidden)

static var surface_cache={}
static var materials={}

static func merge(root: Node3D,nodes: Array) -> ArrayMesh:
	var vertices=PackedVector3Array();var normals=PackedVector3Array();var colors=PackedColorArray();var uvs=PackedVector2Array();var indices=PackedInt32Array()
	var root_inverse=root.global_transform.affine_inverse()
	for node in nodes:
		if node.mesh==null: continue
		var transform=root_inverse*node.global_transform
		var normal_transform=transform.basis.inverse().transposed()
		var color: Color=node.get_meta("paint_color",Color.WHITE)
		if node.material_override is StandardMaterial3D:
			if not node.has_meta("paint_color"): color=node.material_override.albedo_color
			if node.material_override.albedo_texture!=null:
				color.a=.4 if "bark" in node.material_override.albedo_texture.resource_path else .7
		var cache_key=node.mesh.get_instance_id()
		if node.mesh!=ToonArt.shared_ball:
			var arrays_list=[]
			for i in range(node.mesh.get_surface_count()): arrays_list.append(node.mesh.surface_get_arrays(i))
			surface_cache[cache_key]=arrays_list
		if not surface_cache.has(cache_key):
			var cached=[]
			for i in range(node.mesh.get_surface_count()): cached.append(node.mesh.surface_get_arrays(i))
			surface_cache[cache_key]=cached
		for surface in range(surface_cache[cache_key].size()):
			var arrays=surface_cache[cache_key][surface]
			var source_material=node.material_override if node.material_override!=null else node.get_surface_override_material(surface)
			if source_material==null: source_material=node.mesh.surface_get_material(surface)
			if source_material is StandardMaterial3D:
				color=source_material.albedo_color
				var texture=source_material.albedo_texture
				color.a=.4 if texture!=null and "bark" in texture.resource_path else .7 if texture!=null and "stone" in texture.resource_path else 1.0
			var source_uv=arrays[Mesh.ARRAY_TEX_UV]
			var source=arrays[Mesh.ARRAY_VERTEX];var source_normals=arrays[Mesh.ARRAY_NORMAL];var source_indices=arrays[Mesh.ARRAY_INDEX]
			var start=vertices.size()
			for i in range(source.size()):
				vertices.append(transform*source[i]);normals.append((normal_transform*source_normals[i]).normalized());colors.append(color);uvs.append(source_uv[i] if source_uv!=null and source_uv.size()>i else Vector2(source[i].x,source[i].y))
			if source_indices!=null and source_indices.size()>0:
				for index in source_indices: indices.append(start+index)
			else:
				for index in range(source.size()): indices.append(start+index)
		if node.mesh!=ToonArt.shared_ball: surface_cache.erase(cache_key)
	var output=[];output.resize(Mesh.ARRAY_MAX);output[Mesh.ARRAY_VERTEX]=vertices;output[Mesh.ARRAY_NORMAL]=normals;output[Mesh.ARRAY_COLOR]=colors;output[Mesh.ARRAY_TEX_UV]=uvs;output[Mesh.ARRAY_INDEX]=indices
	var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,output)
	return mesh

static func material(animated: bool=false) -> ShaderMaterial:
	if materials.has(animated): return materials[animated].duplicate()
	var shader=Shader.new()
	shader.code="""shader_type spatial;
uniform sampler2D paper:source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D bark:source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D stone:source_color,filter_linear_mipmap,repeat_enable;
uniform vec3 tint=vec3(1.0);
uniform bool fade_near=true;
uniform float clock=0.0;
uniform float moving=0.0;
uniform float attack=0.0;
uniform float airborne=0.0;
void vertex(){
	if(VERTEX.y<.45){VERTEX.z+=sin(clock*12.0+sign(VERTEX.x)*1.57)*.11*moving;}
	else{VERTEX.y+=sin(clock*12.0)*.025*moving;}
	if(abs(VERTEX.x)>.43&&VERTEX.y>.45&&VERTEX.y<1.16){VERTEX.z-=attack*.13;}
	if(abs(VERTEX.x)>.4){VERTEX.y+=sin(clock*8.0)*smoothstep(.4,1.2,abs(VERTEX.x))*.10*airborne;}
}
void fragment(){vec3 paint=COLOR.a<.5?texture(bark,UV*vec2(1.0,2.0)).rgb:COLOR.a<.8?texture(stone,UV).rgb:texture(paper,UV*.7).rgb;ALBEDO=pow(COLOR.rgb,vec3(2.2))*tint*mix(vec3(1.0),paint*1.3,.24);ROUGHNESS=1.0;SPECULAR=0.0;}
"""
	if not animated:
		shader.code=shader.code.replace("void vertex(){","varying vec3 world_position;void vertex(){world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;if(COLOR.g>COLOR.r*1.04 && VERTEX.y>2.0){VERTEX.x+=sin(TIME*1.3+VERTEX.z*.2)*.05;}")
		shader.code=shader.code.replace("void fragment(){","void fragment(){if(fade_near && (COLOR.g>COLOR.r*1.04 || (COLOR.r>.8 && COLOR.g>.85)) && distance(world_position,INV_VIEW_MATRIX[3].xyz)<2.8){discard;}")
		shader.code=shader.code.replace('if(VERTEX.y<.45)','if(false)').replace('else{VERTEX.y+=sin(clock*12.0)*.025*moving;}','').replace('if(abs(VERTEX.x)>.43','if(false&&abs(VERTEX.x)>.43')
	var material=ShaderMaterial.new();material.shader=shader;material.set_shader_parameter("paper",load("res://assets/illustrated/paper.png"))
	material.set_shader_parameter("bark",load("res://assets/illustrated/bark.png"));material.set_shader_parameter("stone",load("res://assets/illustrated/stone.png"))
	material.next_pass=ToonArt.outline
	if not animated:
		var contour=ShaderMaterial.new();var contour_shader=Shader.new()
		contour_shader.code="shader_type spatial;render_mode unshaded,cull_front;uniform bool fade_near=true;varying vec3 p;void vertex(){VERTEX+=NORMAL*.012;p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}void fragment(){if(fade_near && (COLOR.g>COLOR.r*1.04 || (COLOR.r>.8 && COLOR.g>.85)) && distance(p,INV_VIEW_MATRIX[3].xyz)<2.8){discard;}ALBEDO=vec3(.26,.20,.15);}"
		contour.shader=contour_shader;material.next_pass=contour
	materials[animated]=material
	return material

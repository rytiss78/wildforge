extends Node3D
class_name StyleModel

var model: Node3D
var body: Node3D
var head: Node3D
var jaw: Node3D
var cape: Node3D
var legs: Array[Node3D] = []
var arms: Array[Node3D] = []
var core_material: ShaderMaterial
var core_materials: Array[ShaderMaterial] = []
var armour_materials: Array[ShaderMaterial] = []
var armour_shells: Array[MeshInstance3D] = []
var prepared_materials = {}
var appendages=[]
var fill = 1.0
var shown_fill = 1.0
var hit_clock = 0.0
var clock = 0.0
var is_tank = false
var identity = ""
var outline: ShaderMaterial
var batched: ShaderMaterial
var previous_fill=-1.0
var previous_hit=-1.0
static var core_data={}

func setup_baked(asset: String, tank: bool):
	identity=asset;is_tank=tank
	model=Node3D.new();add_child(model);body=Node3D.new();model.add_child(body)
	var combined=MeshInstance3D.new();combined.mesh=load("res://assets/style3d/baked/"+asset+".res");batched=PaintedBatch.material(true);combined.material_override=batched;body.add_child(combined)
	if core_data.is_empty(): core_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/style3d/baked/cores.json"))
	var data=core_data[asset]
	var socket=Node3D.new();body.add_child(socket);socket.position=Vector3(data.core_position[0],data.core_position[1],data.core_position[2])
	var orb=MeshInstance3D.new();orb.name="GlassCore";orb.mesh=load("res://assets/style3d/baked/"+asset+"-core.res");socket.add_child(orb)
	orb.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	core_material=ShaderMaterial.new();core_material.shader=load("res://shaders/blood_core.gdshader");core_material.set_shader_parameter("radius",data.radius);orb.material_override=core_material;core_materials.append(core_material)

func setup(asset: String, tank: bool = false):
	if asset.begins_with("creature_") and ResourceLoader.exists("res://assets/style3d/baked/"+asset+".res"):
		setup_baked(asset,tank);return
	identity=asset;is_tank=tank
	model=load("res://assets/style3d/"+asset+".glb").instantiate()
	add_child(model)
	body=model.find_child("Body",true,false)
	if body==null: body=model
	head=model.find_child("Head",true,false)
	jaw=model.find_child("Jaw",true,false)
	cape=model.find_child("Cape",true,false)
	var shader=Shader.new()
	shader.code="shader_type spatial; render_mode unshaded,cull_front; uniform float width=0.009; void vertex(){VERTEX+=NORMAL*width;} void fragment(){ALBEDO=vec3(0.24,0.18,0.16);}"
	outline=ShaderMaterial.new();outline.shader=shader
	prepare_meshes(model)
	for core_name in ["GlassCore","RearGlass"]:
		var orb=model.find_child(core_name,true,false) as MeshInstance3D
		if orb==null: continue
		orb.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material=ShaderMaterial.new();material.shader=load("res://shaders/blood_core.gdshader")
		material.set_shader_parameter("radius",orb.mesh.get_aabb().size.y*.5)
		orb.set_surface_override_material(0,null);orb.material_override=material
		core_materials.append(material)
		if core_material==null: core_material=material
		if asset=="count_duck" or asset.begins_with("hero_"):
			var shell=MeshInstance3D.new();shell.name="ArmourGlass";shell.mesh=orb.mesh;shell.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			orb.add_child(shell);shell.scale=Vector3.ONE*1.045;shell.visible=false
			var coat=ShaderMaterial.new();coat.shader=preload("res://shaders/armour_glass.gdshader");coat.set_shader_parameter("radius",orb.mesh.get_aabb().size.y*.5)
			shell.material_override=coat;armour_materials.append(coat);armour_shells.append(shell)
	collect_joints(model)

func set_defense(armour: float,shield_value: float,shield_capacity: float):
	var protection=clampf(armour*6/(100+maxf(0,armour)*6),0,1)
	var shield_ratio=clampf(shield_value/maxf(1,shield_capacity),0,1)
	for coat in armour_materials:
		coat.set_shader_parameter("armour",protection);coat.set_shader_parameter("shield_fill",shield_ratio)
	for shell in armour_shells: shell.visible=protection>0 or shield_ratio>0

func prepare_meshes(node: Node):
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var original=node.mesh.surface_get_material(surface)
			if original is StandardMaterial3D:
				var key=original.get_instance_id()
				if not prepared_materials.has(key):
					var prepared=original.duplicate() as StandardMaterial3D
					prepared.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
					prepared.metallic_specular=0;prepared.roughness=1;prepared.next_pass=outline
					prepared_materials[key]=prepared
				var material=prepared_materials[key]
				node.set_surface_override_material(surface,material)
	for child in node.get_children(): prepare_meshes(child)

func collect_joints(node: Node):
	if node is Node3D:
		if node.name.begins_with("Leg") and not node is MeshInstance3D: legs.append(node)
		if node.name.begins_with("Arm") and not node is MeshInstance3D: arms.append(node)
		if not node is MeshInstance3D and (node.name.begins_with("Wing") or node.name.begins_with("Tentacle") or node.name.begins_with("Tail")): appendages.append({"node":node,"rotation":node.rotation})
	for child in node.get_children(): collect_joints(child)

func set_health(value: float, immediate: bool = false):
	fill=clampf(value,0,1)
	if immediate:
		shown_fill=fill
		for material in core_materials: material.set_shader_parameter("fill",shown_fill)
		previous_fill=shown_fill

func damage(value: float):
	set_health(fill-value);hit_clock=.25

func animate(delta: float, speed: float = 0, grounded: bool = true):
	clock+=delta;hit_clock=maxf(0,hit_clock-delta)
	shown_fill=move_toward(shown_fill,fill,delta*1.8)
	if not is_equal_approx(previous_fill,shown_fill):
		for material in core_materials: material.set_shader_parameter("fill",shown_fill)
		previous_fill=shown_fill
	if not is_equal_approx(previous_hit,hit_clock):
		for material in core_materials: material.set_shader_parameter("hit",hit_clock*4)
		previous_hit=hit_clock
	var walk=clampf(speed/5,0,1)
	for i in range(legs.size()):
		legs[i].rotation.x=sin(clock*11+i*PI)*.45*walk if grounded else -.3
	for i in range(arms.size()): arms[i].rotation.x=sin(clock*11+i*PI)*.14*walk
	for i in range(appendages.size()):
		var item=appendages[i];item.node.rotation=item.rotation+Vector3(sin(clock*5+i)*.12,0,sin(clock*7+i)*.08)
	body.position.y=absf(sin(clock*11))*.05*walk
	body.rotation.z=sin(clock*4)*.018+sin(hit_clock*70)*hit_clock*.35
	if jaw!=null: jaw.rotation.x=sin(clock*3)*.12+.1*walk
	if head!=null: head.rotation.y=sin(clock*1.8)*.06
	if cape!=null: cape.rotation.x=-.08*walk+sin(clock*2.3)*.035

func hand_socket() -> Node3D:
	return model.find_child("HandSocket1",true,false)

func muzzle() -> Node3D:
	return model.find_child("Muzzle",true,false)

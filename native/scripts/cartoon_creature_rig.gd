extends ActorRig
class_name CartoonCreatureRig

# An enemy from CartoonBook: one shared merged mesh per species, drawn with this
# rig's own paint material (shaders/cartoon_creature.gdshader) and ink outline, so
# every enemy costs two draws however detailed it looks. The game drives the same
# hooks as before: `batched` takes tint, corruption and dissolve; `attack` and
# `hurt` animate the jaw and the hit flash. Health shows in a glass orb.

static var paint_shader: Shader
static var ink_shader: Shader

var species={}
var mesh_node: MeshInstance3D
var orb_paint: ShaderMaterial
var health=1.0
var orb_fill=1.0
var model_height=1.0

func setup(model_name: String):
	identity=model_name
	var parts=model_name.trim_prefix("creature_").split("_")
	species=CartoonBook.get_model(int(parts[0]),int(parts[1]))
	skin=species.skin;model_height=float(species.height)
	body.free();head.free()
	body=Node3D.new();head=body;add_child(body)
	if paint_shader==null:
		paint_shader=load("res://shaders/cartoon_creature.gdshader");ink_shader=load("res://shaders/cartoon_creature_outline.gdshader")
	batched=ShaderMaterial.new();batched.shader=paint_shader
	var ink=ShaderMaterial.new();ink.shader=ink_shader;batched.next_pass=ink
	for material in [batched,ink]: material.set_shader_parameter("size",model_height)
	# Set explicitly: other systems read these back (Eclipse corruption, statuses).
	batched.set_shader_parameter("tint",Vector3.ONE);batched.set_shader_parameter("corruption",0.0)
	mesh_node=MeshInstance3D.new();mesh_node.mesh=species.mesh;mesh_node.material_override=batched;body.add_child(mesh_node)
	hit_material=StandardMaterial3D.new()
	# Designs built around their orb (orb_body) use it exactly as drawn: it is the
	# belly, torso or whole body, seen from every side. Older designs carry a 1.6x
	# orb on their front.
	var r=float(species.orb_radius)*(1.0 if species.get("orb_body",false) else CartoonScene.ORB_SCALE);var sphere=SphereMesh.new()
	sphere.radius=r;sphere.height=r*2;sphere.radial_segments=24;sphere.rings=12
	orb_paint=ShaderMaterial.new();orb_paint.shader=load("res://shaders/blood_core.gdshader");orb_paint.set_shader_parameter("radius",r)
	var orb=MeshInstance3D.new();orb.name="GlassCore";orb.mesh=sphere
	var at: Vector3=species.orb;orb.position=at
	orb.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;orb.material_override=orb_paint;body.add_child(orb)

func set_health(fraction: float,_tank: bool=false): health=clampf(fraction,0,1)
func set_defense(_armour: float,_shield_value: float,_shield_capacity: float): pass
func bake_enemy(): pass

func animate(delta: float,movement: Vector3,on_floor: bool=true,_slamming: bool=false):
	clock+=delta;attack=maxf(0,attack-delta);hurt=maxf(0,hurt-delta)
	var ink: ShaderMaterial=batched.next_pass
	var moving=clampf(Vector2(movement.x,movement.z).length()/3.0,0,1)
	for material in [batched,ink]:
		if material==null: continue
		material.set_shader_parameter("clock",clock);material.set_shader_parameter("moving",moving)
		material.set_shader_parameter("attack",clampf(attack*2.5,0,1));material.set_shader_parameter("airborne",0.0 if on_floor else 1.0)
		material.set_shader_parameter("hurt",clampf(hurt*3.0,0,1))
	orb_fill=move_toward(orb_fill,health,delta*.8)
	orb_paint.set_shader_parameter("fill",orb_fill);orb_paint.set_shader_parameter("hit",clampf(hurt*4.0,0,1))

# Statuses tint the paint (poison green, frozen blue, burning orange).
func statuses(fire: bool,poison: bool,frozen: bool,_blind: bool):
	var mask=int(fire)+int(poison)*2+int(frozen)*4
	if mask==previous_status: return
	previous_status=mask
	batched.set_shader_parameter("tint",Vector3(.7,1,.5) if poison else Vector3(.75,1,1.15) if frozen else Vector3(1.25,.8,.6) if fire else Vector3.ONE)

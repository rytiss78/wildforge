extends RefCounted
class_name OrbXray

# One health orb inside each creature, hero and boss, seen through its own body
# from the front and the back (user request, October 25). The body writes a
# stencil value where it is drawn; the orb ignores depth but draws only where that
# value is, so it shows through its own body and never through walls or terrain.
# Bodies get one of eight values in turn, so another creature in front usually
# hides the orb as it should. Shader variants are built once per value.

const SLOTS=8
const CREATURE_BASE=1
const CAST_BASE=20
static var counter=0
static var orb_shaders={}
static var body_shaders={}

static func next_ref(base: int) -> int:
	counter+=1
	return base+counter%SLOTS

static func orb_shader(ref: int) -> Shader:
	if orb_shaders.has(ref): return orb_shaders[ref]
	var code: String=load("res://shaders/blood_core.gdshader").code
	code=code.replace("render_mode diffuse_toon, specular_disabled;","render_mode diffuse_toon, specular_disabled, depth_test_disabled, depth_draw_never;\nstencil_mode read, compare_equal, %d;" % ref)
	# Transparent, so it is drawn after the opaque body has written the stencil.
	var end=code.rfind("}");code=code.substr(0,end)+"\tALPHA=1.0;\n}\n"
	var shader=Shader.new();shader.code=code;orb_shaders[ref]=shader
	return shader

static func creature_shader(ref: int) -> Shader:
	if body_shaders.has(ref): return body_shaders[ref]
	var code: String=load("res://shaders/cartoon_creature.gdshader").code
	code=code.replace("render_mode diffuse_toon, specular_disabled;","render_mode diffuse_toon, specular_disabled;\nstencil_mode write, compare_always, %d;" % ref)
	var shader=Shader.new();shader.code=code;body_shaders[ref]=shader
	return shader

# A built-in material that marks its pixels with `ref`.
static func mark(material: StandardMaterial3D,ref: int):
	material.stencil_mode=BaseMaterial3D.STENCIL_MODE_CUSTOM;material.stencil_flags=BaseMaterial3D.STENCIL_FLAG_WRITE
	material.stencil_compare=BaseMaterial3D.STENCIL_COMPARE_ALWAYS;material.stencil_reference=ref

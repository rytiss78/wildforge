extends RefCounted
class_name BiomeLook

# The per-biome half of the art bible (native/docs/art-direction.md): key light,
# ambient fill, fog reach and ink weight for each biome. Ground stays dark and
# quiet so heroes, enemies and effects carry the saturation. Islands 2 and 3
# blend their own grade on top (60%), so they keep their identity.
const LOOK=[
	# Clover Woods: warm late sun, cool fill, standard ink. The reference biome.
	{"sun":Color("ffe0ad"),"sun_energy":1.2,"sun_pitch":-42.0,"ambient":Color("a4b8ed"),"ambient_energy":.28,"fog":Vector2(45,165),"ink":Color(.035,.03,.045),"ink_thickness":1.25,"ink_strength":.9,"vignette":.42},
	# Puffcap Marsh: damp green-white light, teal fill, close fog, slightly heavier ink.
	{"sun":Color("e8f0c4"),"sun_energy":1.05,"sun_pitch":-40.0,"ambient":Color("a8d8c4"),"ambient_energy":.3,"fog":Vector2(35,140),"ink":Color(.02,.05,.04),"ink_thickness":1.35,"ink_strength":.95,"vignette":.48},
	# Moon Craters: a low, nearly neutral moon (long shadows), thin grey-blue fill, distant
	# fog, heavy navy ink. A blue key light turned the whole biome saturated blue.
	{"sun":Color("eef1f7"),"sun_energy":1.3,"sun_pitch":-26.0,"ambient":Color("8e98b0"),"ambient_energy":.2,"fog":Vector2(60,190),"ink":Color(.02,.03,.08),"ink_thickness":1.55,"ink_strength":1.0,"vignette":.5},
	# Cloudwilds: high bright daylight, soft fill, slate ink.
	{"sun":Color("fff0d8"),"sun_energy":1.2,"sun_pitch":-48.0,"ambient":Color("d8e6ef"),"ambient_energy":.26,"fog":Vector2(40,150),"ink":Color(.04,.06,.08),"ink_thickness":1.3,"ink_strength":.95,"vignette":.45},
	# Candy Hell: red-orange key over dark ground so the lava owns the brightness; maroon ink.
	{"sun":Color("ff9466"),"sun_energy":1.15,"sun_pitch":-34.0,"ambient":Color("f0a48a"),"ambient_energy":.22,"fog":Vector2(45,160),"ink":Color(.07,.012,.02),"ink_thickness":1.45,"ink_strength":1.0,"vignette":.52},
	# Starfall Space: cool lilac starlight, violet-black ink.
	{"sun":Color("d8c4ff"),"sun_energy":1.15,"sun_pitch":-38.0,"ambient":Color("b9a8f0"),"ambient_energy":.24,"fog":Vector2(50,175),"ink":Color(.035,.012,.07),"ink_thickness":1.45,"ink_strength":1.0,"vignette":.52},
]

# The Red Moon arena keeps its own original lighting (it reports itself as biome 2).
const RED_MOON={"sun":Color("ffe0ad"),"sun_energy":1.2,"sun_pitch":-42.0,"ambient":Color("e6efff"),"ambient_energy":.36,"fog":Vector2(45,165),"ink":Color(.035,.03,.045),"ink_thickness":1.25,"ink_strength":.9,"vignette":.42}

# Eases the world toward the biome's look; `rate` 1.0 snaps (used on arrival).
static func apply(world,biome: int,grade: Dictionary,rate: float):
	var look: Dictionary=RED_MOON if world.realm==3 else LOOK[clampi(biome,0,5)]
	var sun_color: Color=look.sun;var sun_energy=float(look.sun_energy);var ambient: Color=look.ambient;var ambient_energy=float(look.ambient_energy)
	if grade.has("sun"): sun_color=sun_color.lerp(grade.sun,.6);sun_energy=lerpf(sun_energy,float(grade.sun_energy),.6)
	if grade.has("ambient"): ambient=ambient.lerp(grade.ambient,.6);ambient_energy=lerpf(ambient_energy,float(grade.ambient_energy),.6)
	var pitch=float(look.sun_pitch)
	if grade.has("sun"): pitch=lerpf(pitch,-30.0 if world.realm==1 else -24.0,.6)
	var sun: DirectionalLight3D=world.sun_light
	if is_instance_valid(sun):
		sun.light_color=sun.light_color.lerp(sun_color,rate);sun.light_energy=lerpf(sun.light_energy,sun_energy,rate)
		sun.rotation_degrees.x=lerpf(sun.rotation_degrees.x,pitch,rate)
	var env: Environment=world.environment
	env.ambient_light_color=env.ambient_light_color.lerp(ambient,rate);env.ambient_light_energy=lerpf(env.ambient_light_energy,ambient_energy,rate)
	# The clear zone grows with view_scale; the far end stops at FOG_LIMIT, where the
	# loaded terrain ends (three chunks out).
	var reach=world.FOG_REACH*world.view_scale
	var fog_end=minf(look.fog.y*reach,world.FOG_LIMIT)
	env.fog_depth_begin=lerpf(env.fog_depth_begin,minf(look.fog.x*reach,fog_end-60.0),rate);env.fog_depth_end=lerpf(env.fog_depth_end,fog_end,rate)
	var camera=world.get_viewport().get_camera_3d() if world.is_inside_tree() else null
	var overlay=camera.get_node_or_null("InkOverlay") if camera!=null else null
	if overlay!=null:
		var paint: ShaderMaterial=overlay.material_override
		var ink=paint.get_shader_parameter("ink_color");var current=Color(ink.x,ink.y,ink.z) if ink is Vector3 else Color(ink) if ink!=null else look.ink
		var target: Color=look.ink;var next=current.lerp(target,rate)
		paint.set_shader_parameter("ink_color",Vector3(next.r,next.g,next.b))
		for key in [["thickness","ink_thickness"],["strength","ink_strength"],["vignette","vignette"]]:
			var value=paint.get_shader_parameter(key[0]);paint.set_shader_parameter(key[0],lerpf(float(value) if value!=null else float(look[key[1]]),float(look[key[1]]),rate))

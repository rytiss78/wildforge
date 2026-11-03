extends RefCounted
class_name SkyLook

# Every map has its own sky (user, November 3: "inspired by Destiny 2"). The
# moods borrow from that game's worlds; the skies themselves are this game's:
#   Clover Woods     golden dusk under a great pale pearl hanging over the trees
#   Puffcap Marsh    a teal-green sky over a huge rust-and-cream banded giant
#   Moon Craters     black sky, hard stars and a blue home world on the rim
#   Cloudwilds       a lilac sky with aurora curtains and a white crystal moon
#   Candy Hell       crimson haze around an eclipsed black sun's corona
#   Starfall Space   an icy night filled by a vast banded gas giant, aurora
#   Junkyard Planet  orange smog with a ringed giant through the haze
# The Red Moon arena keeps its own sky.
const LOOKS={
	0:{"top":Color("4f86b8"),"horizon":Color("d9a86a"),"giant_dir":Vector3(-.45,.5,-.75),"giant_radius":.15,"giant_tint":Color("f4efe4"),"giant_band":Color("ffffff"),"giant_bands":0.0,"giant_glow":Color("ffe9c4")},
	1:{"top":Color("1f5a57"),"horizon":Color("8fc4a1"),"giant_dir":Vector3(.55,.14,-.82),"giant_radius":.34,"giant_tint":Color("b8523a"),"giant_band":Color("f1cf96"),"giant_bands":1.0,"giant_glow":Color("ffb27a"),"small_dir":Vector3(-.65,.42,-.6),"small_radius":.045,"small_tint":Color("dfe8d8")},
	2:{"top":Color("04050a"),"horizon":Color("1b2130"),"star_field":1.4,"giant_dir":Vector3(.32,.2,-.92),"giant_radius":.2,"giant_tint":Color("2f63b8"),"giant_band":Color("e8f2ff"),"giant_bands":.55,"giant_glow":Color("7fb8ff")},
	3:{"top":Color("5a3e94"),"horizon":Color("efb3d6"),"aurora":1.0,"aurora_a":Color("4ff2d0"),"aurora_b":Color("ff7ad9"),"small_dir":Vector3(-.3,.62,-.72),"small_radius":.06,"small_tint":Color("eef8ff"),"star_field":.3},
	4:{"top":Color("3a0608"),"horizon":Color("c2361c"),"black_sun":1.0,"sun_dir":Vector3(-.15,.32,-.94),"corona":Color("ff7a24")},
	5:{"top":Color("07102a"),"horizon":Color("5f8fc4"),"star_field":1.0,"aurora":.45,"aurora_a":Color("6fb8ff"),"aurora_b":Color("b48cff"),"giant_dir":Vector3(-.45,.36,-.82),"giant_radius":.46,"giant_tint":Color("c08a5c"),"giant_band":Color("f3e2c2"),"giant_bands":1.0,"giant_glow":Color("ffd9a8")},
	6:{"top":Color("6a4423"),"horizon":Color("e39a52"),"giant_dir":Vector3(.58,.3,-.76),"giant_radius":.17,"giant_tint":Color("e3c27f"),"giant_band":Color("f6e2b2"),"giant_bands":.7,"giant_ring":1.0,"giant_glow":Color("ffc37a")},
}
const OFF={"base_bodies":0.0,"giant_radius":0.0,"small_radius":0.0,"aurora":0.0,"black_sun":0.0,"star_field":0.0}

static func has(realm: int) -> bool: return realm<RealmWorld.ARENA

static func top(realm: int,biome: int) -> Color: return LOOKS[biome].top if has(realm) else RealmWorld.SKY_TOP[biome]
static func horizon(realm: int,biome: int) -> Color: return LOOKS[biome].horizon if has(realm) else RealmWorld.SKY_HORIZON[biome]

static func apply(sky: ShaderMaterial,realm: int,biome: int):
	if not has(realm):
		sky.set_shader_parameter("base_bodies",1.0)
		for key in ["giant_radius","small_radius","aurora","black_sun","star_field"]: sky.set_shader_parameter(key,0.0)
		return
	var look: Dictionary=OFF.duplicate();look.merge(LOOKS[biome],true)
	for key in look:
		if key in ["top","horizon"]: continue
		var value=look[key]
		sky.set_shader_parameter(key,value)

extends RefCounted
class_name CartoonBook

# The enemy roster in a gross-out cartoon sci-fi style (user request, October 25:
# inspired by adult sci-fi cartoons, very diverse, health in an orb). Every creature
# here is an original design. Ten per biome, one per CreatureBook species slot,
# keeping that slot's role: 0 chaser, 1 swooper, 2 armoured, 3 spitter, 4
# skitterer, 5 charger, 6 stalker, and three body-horror humanoid mutants (user
# request, October 25): 7 a shambler, 8 a fused brute, 9 a spitter. Flyers (CreatureBook.FLYING) have wings, jets
# or tentacles instead of legs. Colours are picked to stand out from each biome's
# ground: warm bodies on Clover green, cool bodies on Candy Hell red.

const NAMES=[
	["Gloop Gazer","Flapjack Flutterface","Shellby Grunk","Spitzle Sprout","Buzzlord Mini","Hornbelly Brute","Tall Gerald","Melty Mel","Two-Torso Terry","Gob Mother"],
	["Mushmouth","Slurp Frog","Snailbert","Puffboy","Gnatquito","Tusk Hog","Mire Mouthpole","Fungus Phil","Toadman Todd","Spore Sneezer"],
	["Crater Clod","Moonray","Gorbo Block","Saucer Sam","Glowworm Zip","Ram Moonbeast","The Watcher Stack","Crab Hands Craig","Moonhead Morris","Eyeball Eddie"],
	["Sunpuff","Beakface","Snowslug Gus","Jellyfloat","Kitebat","Wurmo","Stilt Strider","Leggy Lou","Puffer Pete","Beakmouth Bea"],
	["Gumdrop Goon","Taffy Snapper","Jawbreaker Joe","Lollipop Larry","Frostfly","Bubblegut","Cinder Grinner","Gummy Gary","Fistbody Frank","Tongue Tina"],
	["Brainy Blorp","Orbitopus","Ringthing","Mantoid Zap","Twinkle Tick","Crabzilla Jr.","Antenna Annie","Tentacle Ted","Brainbuster Bob","Mirror Mike"]]
const UP=Vector3.UP
const FRONT=Vector3.FORWARD
const INK=CartoonMesh.INK
const TOOTH=CartoonMesh.TOOTH
const MOUTH=CartoonMesh.MOUTH
static var cache={}

static func c(hex: String) -> Color: return Color(hex)

static func mirror(v: Vector3) -> Vector3: return Vector3(-v.x,v.y,v.z)

# A cartoon person about 1.8 m tall for the humanoid mutants (slots 7-9), which
# then twist it: the flags leave parts out, `hunch` bends the upper body forward,
# `fat` widens the belly. Returns the anchor points the twists build on.
static func person(m: CartoonMesh,skin: Color,shirt: Color,pants: Color,shoes: Color,flags: Dictionary={}) -> Dictionary:
	var hunch=float(flags.get("hunch",0.0));var fat=float(flags.get("fat",0.0));var lean=Vector3(0,0,-hunch)
	var a={"hip":Vector3(0,.9,0),"chest":Vector3(0,1.2,0)+lean*.12,"neck":Vector3(0,1.48,0)+lean*.22,"head":Vector3(0,1.66,0)+lean*.3,
		"shoulders":[Vector3(-.33,1.4,0)+lean*.2,Vector3(.33,1.4,0)+lean*.2],"hands":[Vector3(-.42,.98,-.05)+lean*.25,Vector3(.42,.98,-.05)+lean*.25]}
	if not flags.get("no_legs",false):
		m.legs([Vector3(-.14,.86,0),Vector3(.14,.86,0)],.72,.11,pants,shoes)
	m.ball(a.hip,Vector3(.52+fat*.3,.32,.36+fat*.2),pants)
	m.ball(a.chest,Vector3(.62+fat*.5,.66,.42+fat*.55),shirt)
	if not flags.get("no_arms",false):
		for i in range(2):
			var pivot=Vector2(a.shoulders[i].y,.5)
			m.rod(a.shoulders[i],a.hands[i],.085,shirt if flags.get("sleeves",true) else skin,CartoonMesh.LEG,.5*float(1-i),pivot)
			m.ball(a.hands[i]-Vector3(0,.05,0),Vector3(.17,.19,.17),skin,CartoonMesh.LEG,.5*float(1-i),pivot)
	if not flags.get("no_head",false):
		m.rod(a.neck-Vector3(0,.05,0),a.neck+Vector3(0,.06,0),.07,skin)
		m.ball(a.head,Vector3(.42,.46,.42),skin)
		if not flags.get("no_face",false):
			m.eye(a.head+Vector3(-.08,.04,-.19),.06);m.eye(a.head+Vector3(.08,.04,-.19),.06,Vector3(.2,0,-1))
			m.grin(a.head+Vector3(0,-.1,-.18),.18,.07,4,false,.3)
	return a

# {mesh, height, orb, orb_radius, skin} for one species, built once.
static func get_model(biome: int,index: int) -> Dictionary:
	var key=biome*10+index
	if cache.has(key): return cache[key]
	var m=CartoonMesh.new()
	var skin=build(m,biome,index)
	cache[key]={"mesh":m.commit(),"height":m.height(),"orb":m.orb,"orb_radius":m.orb_radius,"skin":skin}
	return cache[key]

static func build(m: CartoonMesh,biome: int,index: int) -> Color:
	match biome*10+index:
		0:  # Gloop Gazer: a lime blob, three eyes on stalks, a crooked grin.
			var body=c("a6e04a")
			m.ball(Vector3(0,.62,0),Vector3(1.25,.95,1.1),body);m.spots(Vector3(0,.62,0),Vector3(.62,.47,.55),c("6aa338"),7,.2,1)
			m.grin(Vector3(0,.64,-.48),.62,.26,6)
			m.stalk_eye(Vector3(0,1.0,-.08),Vector3(-.05,1.3,-.12),.19,body,FRONT,Color(0,0,0,0),.1)
			m.stalk_eye(Vector3(-.3,.92,0),Vector3(-.48,1.16,0),.13,body,Vector3(-.4,.1,-1),Color(0,0,0,0),.5)
			m.stalk_eye(Vector3(.3,.94,.04),Vector3(.5,1.14,.06),.11,body,Vector3(.5,-.2,-1),Color(0,0,0,0),.8)
			m.legs([Vector3(-.36,.3,-.22),Vector3(.36,.3,-.22),Vector3(-.34,.3,.26),Vector3(.34,.3,.26)],.2,.1,c("8fd14f"),c("4c8a2b"))
			m.orb=Vector3(0,.34,-.5);m.orb_radius=.15;return body
		1:  # Flapjack Flutterface: a flying pancake with one huge eye and bat wings.
			var body=c("ff9a3c")
			m.ball(Vector3(0,.72,0),Vector3(1.0,.36,1.0),body);m.spots(Vector3(0,.72,0),Vector3(.5,.18,.5),c("ffd36a"),6,.16,2)
			m.eye(Vector3(0,.92,-.12),.26,Vector3(0,.2,-1),c("5a2bd6"))
			m.grin(Vector3(0,.6,-.42),.4,.14,4,false)
			m.wings(Vector3(0,.76,.05),.9,.7,c("ff6fb5"),c("b23a7a"))
			m.tentacles(2,Vector3(0,.56,0),.18,.32,.06,c("e07a2c"))
			m.orb=Vector3(0,.58,-.3);m.orb_radius=.12;return body
		2:  # Shellby Grunk: a spiked purple shell with a big-nosed head poking out.
			var shell=c("8a4fd6");var skin=c("ffc27a")
			m.ball(Vector3(0,.95,.15),Vector3(1.6,1.2,1.7),shell);m.ring(Vector3(0,.55,.15),.82,.22,c("5b2a9e"))
			for p in [Vector3(0,1.55,.1),Vector3(-.45,1.4,-.15),Vector3(.45,1.4,-.1),Vector3(-.4,1.35,.6),Vector3(.42,1.38,.55),Vector3(0,1.4,.75)]: m.spike(p,p+(p-Vector3(0,.95,.15)).normalized()*.32,.11,c("ffd84a"))
			m.ball(Vector3(0,.6,-.75),Vector3(.7,.6,.7),skin);m.ball(Vector3(0,.58,-1.12),Vector3(.34,.28,.38),c("ff8a6a"))
			m.eye(Vector3(-.12,.82,-.98),.1);m.eye(Vector3(.12,.82,-.98),.1,Vector3(.3,0,-1))
			m.grin(Vector3(0,.42,-1.0),.34,.12,4,false)
			m.legs([Vector3(-.6,.35,-.4),Vector3(.6,.35,-.4),Vector3(-.65,.35,.15),Vector3(.65,.35,.15),Vector3(-.6,.35,.7),Vector3(.6,.35,.7)],.22,.11,skin,c("c4875a"))
			m.orb=Vector3(0,1.05,-.58);m.orb_radius=.17;return shell
		3:  # Spitzle Sprout: a yellow bean with a petal-ringed spitting snout.
			var body=c("ffd23f")
			m.rod(Vector3(0,.4,0),Vector3(0,1.05,0),.32,body)
			m.can(Vector3(0,.95,-.22),Vector3(0,.95,-.6),.14,c("e0b52f"));m.ball(Vector3(0,.95,-.6),Vector3(.2,.2,.06),MOUTH)
			for i in range(6): m.ball(Vector3(0,.95,-.6)+Vector3(cos(i*TAU/6),sin(i*TAU/6),0)*.2,Vector3(.18,.18,.08),c("ff5f9e"))
			m.stalk_eye(Vector3(-.15,1.3,0),Vector3(-.25,1.55,0),.12,body,FRONT,c("2b8a3a"),.2)
			m.stalk_eye(Vector3(.15,1.3,0),Vector3(.27,1.5,0),.14,body,Vector3(.3,0,-1),c("2b8a3a"),.7)
			m.ball(Vector3(0,1.42,.12),Vector3(.42,.06,.22),c("5fbf3a"),CartoonMesh.STALK,.4,Vector2(1.35,1),false,Vector3(0,0,.3))
			m.legs([Vector3(-.2,.3,-.05),Vector3(.2,.3,-.05),Vector3(0,.3,.22)],.2,.08,c("d9a82a"),c("8a6a1a"))
			m.orb=Vector3(0,.6,-.32);m.orb_radius=.14;return body
		4:  # Buzzlord Mini: a striped fuzzball with four eyes and a stinger.
			var body=c("ffe14a")
			m.ball(Vector3(0,.65,0),Vector3(.7,.62,.7),body)
			for y in [.55,.76]: m.ring(Vector3(0,y,0),.34,.08,c("2a1f2a"))
			for x in [-.21,-.07,.07,.21]: m.eye(Vector3(x,.8,-.29),.07,FRONT,c("ff2b2b"))
			m.wings(Vector3(0,.9,.1),.5,.32,c("cfefff"),c("8fb8d0"),.5)
			m.spike(Vector3(0,.55,.3),Vector3(0,.48,.62),.08,INK)
			m.antenna(Vector3(-.1,.94,-.15),Vector3(-.2,1.15,-.26),.05,body,c("7dfffb"),.2);m.antenna(Vector3(.1,.94,-.15),Vector3(.2,1.15,-.26),.05,body,c("7dfffb"),.6)
			m.grin(Vector3(0,.57,-.32),.2,.08,3,false)
			m.orb=Vector3(0,.46,-.28);m.orb_radius=.09;return body
		5:  # Hornbelly Brute: a red pear of muscle with one horn and tusks.
			var body=c("ff5a36")
			m.ball(Vector3(0,1.05,0),Vector3(1.6,1.7,1.4),body);m.ball(Vector3(0,.85,-.42),Vector3(1.1,1.0,.62),c("ffb07a"))
			m.spike(Vector3(0,1.55,-.55),Vector3(0,1.95,-1.25),.2,TOOTH)
			m.eye(Vector3(-.22,1.7,-.5),.1,FRONT,c("ffd23f"));m.eye(Vector3(.22,1.7,-.5),.1,FRONT,c("ffd23f"))
			m.box(Vector3(-.22,1.83,-.55),Vector3(.26,.06,.06),INK,CartoonMesh.BODY,Vector3(0,0,-.4));m.box(Vector3(.22,1.83,-.55),Vector3(.26,.06,.06),INK,CartoonMesh.BODY,Vector3(0,0,.4))
			m.grin(Vector3(0,1.15,-.68),.8,.3,7)
			for s in [-1.0,1.0]:
				m.spike(Vector3(s*.3,1.0,-.75),Vector3(s*.42,1.42,-.92),.07,TOOTH)
				m.rod(Vector3(s*.75,1.2,-.1),Vector3(s*.95,.85,-.35),.12,body);m.ball(Vector3(s*.98,.78,-.4),Vector3.ONE*.28,c("e04a2c"))
			m.legs([Vector3(-.4,.5,0),Vector3(.4,.5,0)],.38,.2,c("e04a2c"),c("8a2a1a"))
			m.orb=Vector3(0,.72,-.78);m.orb_radius=.2;return body
		6:  # Tall Gerald: a lanky lavender stalker with one eye on a long stalk.
			var body=c("b58cff")
			m.rod(Vector3(0,1.35,0),Vector3(0,2.05,0),.26,body)
			m.legs([Vector3(-.12,1.2,0),Vector3(.12,1.2,0)],1.12,.06,c("9a72e6"),c("5d3ea0"))
			for s in [-1.0,1.0]:
				m.rod(Vector3(s*.28,1.95,0),Vector3(s*.45,1.1,-.12),.05,body,CartoonMesh.TAIL,.3,Vector2(1.95,.6))
				for f in range(3): m.ball(Vector3(s*(.42+f*.04),1.02,-.1-f*.04),Vector3(.06,.14,.06),c("9a72e6"),CartoonMesh.TAIL,.3,Vector2(1.95,.6))
			m.ball(Vector3(0,2.35,0),Vector3(.42,.38,.42),c("c9a5ff"))
			m.stalk_eye(Vector3(0,2.5,0),Vector3(0,2.84,-.1),.2,c("c9a5ff"),FRONT,c("ff3b6b"),.3)
			m.box(Vector3(0,2.26,-.2),Vector3(.24,.03,.02),INK)
			for i in range(5): m.spike(Vector3(-.1+i*.05,2.25,-.21),Vector3(-.1+i*.05,2.21,-.22),.012,TOOTH)
			m.orb=Vector3(0,1.7,-.27);m.orb_radius=.13;return body
		10:  # Mushmouth: a red-capped mushroom with a grin in its stem.
			var stem=c("f3e3c3")
			m.ball(Vector3(0,.55,0),Vector3(.8,.9,.75),stem);m.ball(Vector3(0,1.05,0),Vector3(1.3,.6,1.3),c("ff3b4a"))
			m.spots(Vector3(0,1.05,0),Vector3(.65,.3,.65),c("fffaf0"),8,.22,10)
			m.grin(Vector3(0,.55,-.34),.5,.24,5)
			m.eye(Vector3(-.15,.86,-.3),.1);m.eye(Vector3(.16,.85,-.3),.12,Vector3(.3,0,-1))
			m.legs([Vector3(-.2,.2,0),Vector3(.2,.2,0)],.1,.1,stem,c("c9b08a"))
			m.orb=Vector3(0,.28,-.33);m.orb_radius=.12;return c("ff3b4a")
		11:  # Slurp Frog: a wide teal toad, bulging eyes and a long tongue.
			var body=c("2fd3b8")
			m.ball(Vector3(0,.5,0),Vector3(1.3,.75,1.1),body);m.ball(Vector3(0,.42,-.25),Vector3(1.0,.5,.7),c("b8ffe9"))
			m.grin(Vector3(0,.5,-.52),.9,.22,0,false)
			m.ball(Vector3(0,.4,-.85),Vector3(.18,.08,.6),CartoonMesh.TONGUE,CartoonMesh.JAW)
			m.eye(Vector3(-.32,.95,-.2),.17,Vector3(-.2,0,-1),c("ffd23f"));m.eye(Vector3(.32,.95,-.2),.17,Vector3(.2,0,-1),c("ffd23f"))
			for s in [-1.0,1.0]: m.ball(Vector3(s*.55,.4,.3),Vector3(.45,.45,.6),c("22a892"))
			m.legs([Vector3(-.4,.3,-.35),Vector3(.4,.3,-.35),Vector3(-.6,.25,.45),Vector3(.6,.25,.45)],.17,.09,body,c("1f8a78"))
			m.orb=Vector3(0,.9,.12);m.orb_radius=.14;return body
		12:  # Snailbert: a yellow slug under a curling orange shell.
			var body=c("ffe066")
			m.rod(Vector3(0,.25,-.6),Vector3(0,.25,.6),.25,body);m.rod(Vector3(0,.25,-.6),Vector3(0,.8,-.75),.22,body)
			m.ball(Vector3(0,1.0,.2),Vector3.ONE*1.1,c("ff8a2b"));m.ring(Vector3(0,1.0,.2),.48,.12,c("c25a1a"),Vector3(0,0,PI*.5))
			m.ball(Vector3(.05,1.32,-.02),Vector3.ONE*.6,c("ffb05a"));m.ball(Vector3(.08,1.5,.25),Vector3.ONE*.38,c("c25a1a"))
			m.stalk_eye(Vector3(-.1,.95,-.8),Vector3(-.22,1.4,-.9),.1,body,FRONT,c("6b3bff"),.1)
			m.stalk_eye(Vector3(.1,.95,-.8),Vector3(.24,1.45,-.88),.12,body,Vector3(.3,.1,-1),c("6b3bff"),.6)
			m.grin(Vector3(0,.62,-.94),.3,.1,4,false)
			for z in [-.3,.1,.5]: m.ball(Vector3(-.26,.08,z),Vector3(.12,.08,.16),c("b8ff7a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.orb=Vector3(0,1.0,-.38);m.orb_radius=.17;return c("ff8a2b")
		13:  # Puffboy: a floating pink balloon with a puckered spitting mouth.
			var body=c("ff7ad9")
			m.ball(Vector3(0,1.0,0),Vector3.ONE*1.1,body);m.spots(Vector3(0,1.0,0),Vector3.ONE*.55,c("fff0fb"),5,.14,13,true)
			m.can(Vector3(0,.95,-.48),Vector3(0,.95,-.74),.12,c("d9479e"));m.ball(Vector3(0,.95,-.75),Vector3(.16,.16,.06),MOUTH)
			for s in [-1.0,1.0]:
				m.eye(Vector3(s*.22,1.24,-.42),.13);m.ball(Vector3(s*.22,1.33,-.43),Vector3(.3,.14,.28),c("d9479e"))
			m.ball(Vector3(0,.42,0),Vector3(.18,.14,.18),c("d9479e"))
			m.tentacles(4,Vector3(0,.5,0),.25,.45,.06,c("ffb3ec"))
			m.orb=Vector3(0,.66,-.42);m.orb_radius=.13;return body
		14:  # Gnatquito: an orange mosquito, three eyes and a needle nose.
			var body=c("ff9a3c")
			m.ball(Vector3(0,.7,0),Vector3(.4,.4,.5),body);m.ball(Vector3(0,.65,.4),Vector3(.36,.32,.6),c("ffcf3f"));m.ring(Vector3(0,.65,.42),.17,.06,INK,Vector3(PI*.5,0,0))
			m.ball(Vector3(0,.78,-.32),Vector3(.34,.32,.32),body)
			m.eye(Vector3(-.1,.86,-.45),.07,FRONT,c("ff2b2b"));m.eye(Vector3(.1,.86,-.45),.07,FRONT,c("ff2b2b"));m.eye(Vector3(0,.96,-.42),.06,FRONT,c("ff2b2b"))
			m.spike(Vector3(0,.74,-.48),Vector3(0,.6,-.95),.03,INK)
			m.wings(Vector3(0,.86,0),.55,.25,c("cff6ff"),c("7ab8c9"),.4);m.wings(Vector3(0,.82,.15),.45,.2,c("cff6ff"),c("7ab8c9"),.2)
			for s in [-1.0,1.0]:
				for z in [-.1,.05,.2]: m.rod(Vector3(s*.12,.6,z),Vector3(s*.3,.25,z*1.4),.02,INK,CartoonMesh.LEG,z+.5,Vector2(.6,.5))
			m.orb=Vector3(0,.56,-.14);m.orb_radius=.09;return body
		15:  # Tusk Hog: a cyan boar with tusks and mushrooms on its back.
			var body=c("4fd6ff")
			m.ball(Vector3(0,1.1,0),Vector3(1.6,1.3,2.0),body)
			for p in [Vector3(-.3,1.7,.2),Vector3(.25,1.72,.45),Vector3(0,1.68,-.2)]:
				m.can(p-Vector3(0,.05,0),p+Vector3(0,.2,0),.06,c("f3e3c3"));m.ball(p+Vector3(0,.25,0),Vector3(.32,.16,.32),c("ff3b4a"))
			m.can(Vector3(0,1.0,-.95),Vector3(0,1.0,-1.25),.22,c("ffb3c7"))
			for s in [-1.0,1.0]:
				m.ball(Vector3(s*.08,1.02,-1.26),Vector3(.07,.1,.03),INK)
				m.spike(Vector3(s*.25,.85,-1.0),Vector3(s*.38,1.25,-1.3),.08,TOOTH)
				m.eye(Vector3(s*.3,1.45,-.85),.11,FRONT,c("ff3b3b"))
				m.box(Vector3(s*.3,1.58,-.9),Vector3(.3,.06,.06),INK,CartoonMesh.BODY,Vector3(0,0,s*.4))
			m.grin(Vector3(0,.78,-.95),.6,.2,5,false)
			m.legs([Vector3(-.5,.55,-.55),Vector3(.5,.55,-.55),Vector3(-.5,.55,.55),Vector3(.5,.55,.55)],.35,.17,body,c("2a8fb0"))
			m.orb=Vector3(0,.62,-.85);m.orb_radius=.17;return body
		16:  # Mire Mouthpole: a swaying pole with a lamprey mouth ringed by eyes.
			var body=c("6fe0c8")
			m.rod(Vector3(0,.3,0),Vector3(0,1.5,0),.18,body);m.ball(Vector3(0,1.75,0),Vector3(.75,.75,.7),body)
			m.ring(Vector3(0,1.75,-.33),.27,.2,c("ff5f8a"),Vector3(PI*.5,0,0));m.ball(Vector3(0,1.75,-.3),Vector3(.42,.42,.12),MOUTH)
			for i in range(8):
				var a=i*TAU/8;var o=Vector3(cos(a),sin(a),0)
				m.spike(Vector3(0,1.75,-.36)+o*.2,Vector3(0,1.75,-.38)+o*.08,.03,TOOTH)
			for i in range(5):
				var a=PI*.15+i*PI*.175;m.eye(Vector3(0,1.75,-.28)+Vector3(cos(a),sin(a),0)*.4,.06,FRONT,c("ffd23f"))
			for s in [Vector3(.4,0,.4),Vector3(-.4,0,.4),Vector3(.4,0,-.4),Vector3(-.4,0,-.4)]: m.rod(Vector3(0,.35,0),s,.06,c("2fb39b"))
			m.tentacles(3,Vector3(0,1.42,.05),.2,.5,.05,c("2fb39b"))
			m.orb=Vector3(0,.9,-.19);m.orb_radius=.13;return body
		20:  # Crater Clod: a cyan cyclops pocked with craters.
			var body=c("40e0ff")
			m.ball(Vector3(0,.65,0),Vector3(1.2,1.0,1.1),body);m.spots(Vector3(0,.65,0),Vector3(.6,.5,.55),c("1f9ac0"),8,.22,20)
			m.eye(Vector3(0,.9,-.45),.24,FRONT,c("ff4fd8"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.grin(Vector3(0,.5,-.5),.55,.2,5)
			m.legs([Vector3(-.35,.3,-.2),Vector3(.35,.3,-.2),Vector3(-.35,.3,.25),Vector3(.35,.3,.25)],.2,.1,c("2bb8d6"),c("16708a"))
			m.orb=Vector3(0,.28,-.48);m.orb_radius=.12;return body
		21:  # Moonray: a lilac manta with glowing spots and a whip tail.
			var body=c("c39bff")
			m.ball(Vector3(0,.7,0),Vector3(.8,.28,1.1),body);m.wings(Vector3(0,.7,0),1.0,.9,c("a77bf0"),c("6d45c0"),.1)
			m.spots(Vector3(0,.7,0),Vector3(.4,.14,.55),c("fff27d"),6,.12,21,true)
			m.rod(Vector3(0,.7,.55),Vector3(0,.72,1.3),.04,c("6d45c0"),CartoonMesh.TAIL,0.0,Vector2(.75,1));m.spike(Vector3(0,.72,1.3),Vector3(0,.75,1.5),.07,c("fff27d"),CartoonMesh.TAIL,0.0,Vector2(.75,1))
			m.eye(Vector3(-.15,.85,-.35),.09,FRONT,c("7dfffb"),CartoonMesh.BODY,0.0,Vector2(0,1),true);m.eye(Vector3(.15,.85,-.35),.09,FRONT,c("7dfffb"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.grin(Vector3(0,.6,-.5),.3,.08,3,false)
			m.orb=Vector3(0,.87,-.08);m.orb_radius=.12;return body
		22:  # Gorbo Block: a yellow cube with mismatched eyes and a big grin.
			var body=c("fff07a")
			m.box(Vector3(0,.9,0),Vector3(1.2,1.2,1.1),body)
			m.eye(Vector3(-.27,1.15,-.56),.17);m.eye(Vector3(.3,1.2,-.56),.11,Vector3(.3,.2,-1),c("3b7dff"))
			m.grin(Vector3(0,.68,-.57),.75,.22,7)
			m.antenna(Vector3(0,1.5,0),Vector3(.05,1.85,.05),.08,c("b9b9c9"),c("ff4f4f"))
			for s in [-1.0,1.0]:
				m.ball(Vector3(s*.62,.9,0),Vector3.ONE*.14,c("b9b9c9"))
				m.rod(Vector3(s*.6,.95,-.1),Vector3(s*.85,.6,-.3),.08,body);m.ball(Vector3(s*.88,.55,-.32),Vector3.ONE*.2,c("e0c84a"))
			m.legs([Vector3(-.38,.32,-.3),Vector3(.38,.32,-.3),Vector3(-.38,.32,.3),Vector3(.38,.32,.3)],.2,.11,c("e0c84a"),c("8a7a2a"))
			m.orb=Vector3(0,.44,-.56);m.orb_radius=.13;return body
		23:  # Saucer Sam: a little flying saucer with a big-eyed pilot in the hatch.
			var hull=c("cfd6e8")
			m.ball(Vector3(0,.9,0),Vector3(1.3,.3,1.3),hull);m.ring(Vector3(0,.9,0),.62,.16,c("8a94b0"))
			for i in range(8): m.ball(Vector3(cos(i*TAU/8),0,sin(i*TAU/8))*.66+Vector3(0,.9,0),Vector3.ONE*.11,c("7dff6a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.ring(Vector3(0,1.05,0),.3,.1,c("8a94b0"))
			m.ball(Vector3(0,1.25,0),Vector3(.42,.48,.42),c("8fff5a"))
			m.ball(Vector3(-.1,1.32,-.16),Vector3(.14,.18,.08),INK,CartoonMesh.BODY,0.0,Vector2(0,1),false,Vector3(0,0,-.3));m.ball(Vector3(.1,1.32,-.16),Vector3(.14,.18,.08),INK,CartoonMesh.BODY,0.0,Vector2(0,1),false,Vector3(0,0,.3))
			m.box(Vector3(0,1.15,-.2),Vector3(.1,.02,.02),INK)
			m.spike(Vector3(0,.78,0),Vector3(0,.6,0),.2,c("ffe34a"),CartoonMesh.BODY,0.0,Vector2(0,1))
			m.antenna(Vector3(0,1.48,0),Vector3(0,1.62,.05),.04,c("8fff5a"),c("ff4fd8"))
			m.orb=Vector3(0,.86,-.66);m.orb_radius=.12;return hull
		24:  # Glowworm Zip: a glowing magenta orb with six eyes and a trailing tail.
			var body=c("ff4fd8")
			m.ball(Vector3(0,.7,0),Vector3.ONE*.55,body,CartoonMesh.BODY,0.0,Vector2(0,1),true)
			for p in [Vector3(-.12,.8,-.24),Vector3(0,.82,-.26),Vector3(.12,.8,-.24),Vector3(-.08,.7,-.27),Vector3(.08,.7,-.27),Vector3(0,.64,-.27)]: m.eye(p,.045)
			m.wings(Vector3(0,.85,.05),.4,.25,c("ffd0f5"),c("c03fa0"),.4)
			for i in range(5): m.ball(Vector3(0,.68-i*.02,.3+i*.15),Vector3.ONE*(.22-i*.035),c("ffa0ec"),CartoonMesh.TAIL,0.0,Vector2(.75,1),true)
			m.grin(Vector3(0,.58,-.25),.2,.07,3,false)
			m.orb=Vector3(0,.5,-.18);m.orb_radius=.08;return body
		25:  # Ram Moonbeast: a fluffy white ram with a dark three-eyed face.
			var wool=c("f4f6ff");var face=c("2a2340")
			m.ball(Vector3(0,1.15,0),Vector3(1.6,1.3,1.9),wool)
			for p in [Vector3(-.6,1.55,.3),Vector3(.6,1.55,.2),Vector3(0,1.75,.5),Vector3(-.5,1.2,.85),Vector3(.5,1.25,.8),Vector3(0,1.4,1.0),Vector3(-.7,1.0,-.3),Vector3(.7,1.0,-.35)]: m.ball(p,Vector3.ONE*.6,wool)
			m.ball(Vector3(0,1.2,-1.0),Vector3(.75,.8,.6),face)
			m.eye(Vector3(-.17,1.35,-1.25),.09,FRONT,c("fff27d"),CartoonMesh.BODY,0.0,Vector2(0,1),true);m.eye(Vector3(.17,1.35,-1.25),.09,FRONT,c("fff27d"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.eye(Vector3(0,1.5,-1.22),.07,FRONT,c("fff27d"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.grin(Vector3(0,1.0,-1.25),.45,.15,5)
			for s in [-1.0,1.0]:
				for i in range(5):
					var a=i*.9;m.ball(Vector3(s*(.42+.22*sin(a)),1.55+.25*cos(a)-.1*i,-.8+.08*i),Vector3.ONE*(.28-i*.03),c("ffb84a"))
			m.legs([Vector3(-.5,.6,-.55),Vector3(.5,.6,-.55),Vector3(-.5,.6,.55),Vector3(.5,.6,.55)],.4,.14,face,INK)
			m.orb=Vector3(0,.7,-.92);m.orb_radius=.18;return wool
		26:  # The Watcher Stack: three different heads stacked into a totem.
			var low=c("ff6b6b");var mid=c("ffd84a");var top=c("6bd5ff")
			m.ball(Vector3(0,.75,0),Vector3(1.0,.9,.9),low);m.grin(Vector3(0,.68,-.42),.55,.2,6)
			m.ball(Vector3(0,1.55,0),Vector3(.85,.8,.8),mid)
			for x in [-.22,0.0,.22]: m.eye(Vector3(x,1.6,-.36),.09,Vector3(x,0,-1),c("ff3b3b"))
			m.box(Vector3(0,1.4,-.4),Vector3(.3,.03,.02),INK)
			m.ball(Vector3(0,2.25,0),Vector3(.7,.65,.65),top);m.eye(Vector3(0,2.3,-.3),.16,FRONT,c("6b2bff"))
			m.antenna(Vector3(0,2.55,0),Vector3(-.1,2.85,.05),.06,top,c("fff27d"))
			for s in [-1.0,1.0]:
				m.rod(Vector3(s*.48,.85,0),Vector3(s*.8,1.1,-.25),.07,low,CartoonMesh.TAIL,.2,Vector2(.85,.6));m.ball(Vector3(s*.84,1.14,-.28),Vector3.ONE*.18,low,CartoonMesh.TAIL,.2,Vector2(.85,.6))
			m.legs([Vector3(-.25,.35,0),Vector3(.25,.35,0)],.25,.1,low,c("a83a3a"))
			m.orb=Vector3(0,1.15,-.38);m.orb_radius=.14;return mid
		30:  # Sunpuff: a grumpy yellow cloud with puffed cheeks.
			var body=c("ffcf2a")
			m.ball(Vector3(0,.85,0),Vector3(1.0,.85,.9),body)
			for p in [Vector3(-.45,.95,.1),Vector3(.45,.95,.1),Vector3(0,1.25,.1),Vector3(-.3,1.15,.35),Vector3(.3,1.15,.35),Vector3(0,.9,.45)]: m.ball(p,Vector3.ONE*.5,body)
			for s in [-1.0,1.0]:
				m.eye(Vector3(s*.2,.95,-.42),.1,FRONT,c("ff5a1f"));m.box(Vector3(s*.2,1.08,-.45),Vector3(.2,.05,.05),INK,CartoonMesh.BODY,Vector3(0,0,s*.45))
				m.ball(Vector3(s*.32,.75,-.33),Vector3.ONE*.3,c("ff9a3c"))
			m.grin(Vector3(0,.72,-.45),.3,.1,4,false)
			m.wings(Vector3(0,.95,.32),.45,.3,c("fff6c9"),c("e0a82a"),.3)
			m.orb=Vector3(0,.55,-.36);m.orb_radius=.12;return body
		31:  # Beakface: a violet ball with a huge beak and one eye on a stalk.
			var body=c("8f5cff")
			m.ball(Vector3(0,.75,0),Vector3.ONE*.85,body)
			m.spike(Vector3(0,.78,-.36),Vector3(0,.68,-1.05),.17,c("ffa22a"));m.spike(Vector3(0,.68,-.34),Vector3(0,.6,-.85),.12,c("e07a12"),CartoonMesh.JAW)
			m.stalk_eye(Vector3(0,1.1,-.1),Vector3(0,1.4,-.15),.17,body,FRONT,c("2adfff"),.4)
			m.wings(Vector3(0,.85,.05),.85,.5,c("b89cff"),c("5c34c9"))
			for i in range(3): m.spike(Vector3((i-1)*.1,.85,.38),Vector3((i-1)*.25,1.15,.65),.06,c("ffa22a"))
			m.orb=Vector3(0,.55,-.35);m.orb_radius=.11;return body
		32:  # Snowslug Gus: a pink slug with a ridge of ice spikes.
			var body=c("ff7ab0")
			m.rod(Vector3(0,.35,.7),Vector3(0,.4,-.5),.38,body);m.ball(Vector3(0,.65,-.7),Vector3(.8,.75,.7),body)
			for i in range(6): var z=.6-i*.22;m.spike(Vector3(0,.7+(.1 if i>3 else 0.0),z),Vector3(0,1.05+(.1 if i>3 else 0.0),z+.05),.1,c("9fe9ff"))
			m.stalk_eye(Vector3(-.15,.95,-.75),Vector3(-.25,1.35,-.85),.11,body,FRONT,c("3b7dff"),.2)
			m.stalk_eye(Vector3(.15,.95,-.75),Vector3(.25,1.35,-.85),.11,body,Vector3(.3,0,-1),c("3b7dff"),.7)
			m.grin(Vector3(0,.55,-1.0),.45,.2,4)
			m.orb=Vector3(0,.25,-.85);m.orb_radius=.12;return body
		33:  # Jellyfloat: a magenta jellyfish with a face and glowing tentacle tips.
			var body=c("ff4fb0")
			m.ball(Vector3(0,1.15,0),Vector3(1.1,.8,1.1),body)
			for i in range(10): m.ball(Vector3(cos(i*TAU/10),0,sin(i*TAU/10))*.52+Vector3(0,.86,0),Vector3.ONE*.2,c("ff8fcf"))
			m.tentacles(7,Vector3(0,.85,0),.35,.65,.06,c("ffb0dc"),c("fff27d"))
			m.eye(Vector3(-.2,1.25,-.5),.1,FRONT,c("3b2bff"));m.eye(Vector3(.2,1.25,-.5),.1,FRONT,c("3b2bff"))
			m.grin(Vector3(0,1.0,-.52),.3,.12,3,false)
			m.orb=Vector3(0,1.46,-.38);m.orb_radius=.12;return body
		34:  # Kitebat: a red diamond kite with a face and a bow-knot tail.
			var body=c("ff3b3b")
			m.box(Vector3(0,.75,0),Vector3(.65,.65,.12),body,CartoonMesh.BODY,Vector3(0,0,PI*.25));m.box(Vector3(0,.75,-.07),Vector3(.3,.3,.02),c("ffe14a"),CartoonMesh.BODY,Vector3(0,0,PI*.25))
			m.eye(Vector3(-.1,.83,-.1),.08);m.eye(Vector3(.1,.83,-.1),.08)
			m.grin(Vector3(0,.66,-.09),.2,.07,3,false,.2)
			for i in range(6): m.ball(Vector3(0,.3-i*.03,.05+i*.12),Vector3(.16,.08,.08),c("ffe14a") if i%2==0 else c("3b7dff"),CartoonMesh.TAIL,0.0,Vector2(.45,1))
			m.wings(Vector3(0,.75,.05),.5,.2,c("ffb0b0"),c("c02a2a"),.3)
			m.orb=Vector3(0,.55,-.08);m.orb_radius=.07;return body
		35:  # Wurmo: a rearing orange worm with a round mouth full of teeth.
			var body=c("ff8a2b");var band=c("ffb35a")
			var segments=[[Vector3(0,.45,1.2),.7],[Vector3(0,.6,.6),.8],[Vector3(0,.9,.05),.9],[Vector3(0,1.3,-.4),1.0]]
			for i in range(segments.size()): m.ball(segments[i][0],Vector3.ONE*segments[i][1],body if i%2==0 else band)
			m.ball(Vector3(0,1.75,-.75),Vector3.ONE*1.1,body)
			m.ring(Vector3(0,1.7,-1.25),.32,.18,c("ff4f6a"),Vector3(PI*.5,0,0));m.ball(Vector3(0,1.7,-1.2),Vector3(.5,.5,.15),MOUTH)
			for i in range(8): var o=Vector3(cos(i*TAU/8),sin(i*TAU/8),0);m.spike(Vector3(0,1.7,-1.27)+o*.24,Vector3(0,1.7,-1.3)+o*.1,.04,TOOTH)
			m.eye(Vector3(-.22,2.15,-.95),.09,FRONT,c("1f9aff"));m.eye(Vector3(.22,2.15,-.95),.09,FRONT,c("1f9aff"))
			for p in [Vector3(0,.12,1.2),Vector3(0,.2,.6)]:
				for s in [-1.0,1.0]: m.ball(p+Vector3(s*.25,0,0),Vector3(.15,.12,.2),c("c25a1a"))
			m.orb=Vector3(0,1.15,-.85);m.orb_radius=.17;return body
		36:  # Stilt Strider: a little yellow bird-body on four long stilts.
			var body=c("ffd23f")
			m.ball(Vector3(0,1.35,0),Vector3(.6,.45,.6),body)
			m.spider_legs(4,Vector3(0,1.35,0),.7,.35,.045,c("ff9a3c"))
			m.spike(Vector3(0,1.35,-.3),Vector3(0,1.25,-.75),.1,c("ff5a1f"))
			m.stalk_eye(Vector3(-.12,1.55,-.1),Vector3(-.25,1.85,-.15),.1,body,FRONT,c("3b7dff"),.3)
			m.stalk_eye(Vector3(.12,1.55,-.1),Vector3(.25,1.85,-.15),.1,body,Vector3(.3,.1,-1),c("3b7dff"),.8)
			for i in range(3): m.spike(Vector3((i-1)*.08,1.4,.28),Vector3((i-1)*.2,1.6,.55),.05,c("ff5a1f"))
			m.orb=Vector3(0,1.18,-.25);m.orb_radius=.1;return body
		40:  # Gumdrop Goon: a teal sugar-dusted gumdrop with mismatched eyes.
			var body=c("2fe0c8")
			m.ball(Vector3(0,.6,0),Vector3(1.0,1.1,1.0),body);m.spike(Vector3(0,.95,0),Vector3(0,1.3,0),.32,body)
			m.spots(Vector3(0,.7,0),Vector3(.5,.55,.5),c("ffffff"),12,.08,40)
			m.grin(Vector3(0,.55,-.45),.55,.22,6)
			m.eye(Vector3(-.17,.86,-.4),.11);m.eye(Vector3(.17,.84,-.41),.08,Vector3(.4,0,-1))
			m.legs([Vector3(-.22,.2,0),Vector3(.22,.2,0)],.12,.1,body,c("1a8a7a"))
			m.orb=Vector3(0,.28,-.44);m.orb_radius=.12;return body
		41:  # Taffy Snapper: a mint crocodile with a snapping candy-striped jaw.
			var body=c("7dffb0")
			m.rod(Vector3(0,.4,.7),Vector3(0,.45,-.3),.3,body);m.ball(Vector3(0,.5,-.75),Vector3(.55,.35,.9),body)
			for i in range(5):
				for s in [-1.0,1.0]: m.spike(Vector3(s*.22,.42,-.45-i*.15),Vector3(s*.22,.33,-.45-i*.15),.03,TOOTH)
			m.ball(Vector3(0,.34,-.75),Vector3(.5,.15,.85),c("4fd68a"),CartoonMesh.JAW)
			m.eye(Vector3(-.15,.72,-.5),.1,FRONT,c("ffd23f"));m.eye(Vector3(.15,.72,-.5),.1,FRONT,c("ffd23f"))
			m.spots(Vector3(0,.45,.2),Vector3(.3,.3,.6),c("ff5fa0"),7,.14,41)
			for i in range(4): m.ball(Vector3(0,.42-i*.03,1.05+i*.25),Vector3.ONE*(.4-i*.08),body,CartoonMesh.TAIL,0.0,Vector2(.6,1))
			m.legs([Vector3(-.3,.3,-.15),Vector3(.3,.3,-.15),Vector3(-.3,.3,.5),Vector3(.3,.3,.5)],.17,.08,body,c("3aa86a"))
			m.orb=Vector3(0,.76,-.08);m.orb_radius=.12;return body
		42:  # Jawbreaker Joe: a striped candy ball with a tiny face and tiny legs.
			var body=c("f8f4ff")
			m.ball(Vector3(0,.95,0),Vector3.ONE*1.6,body)
			m.ring(Vector3(0,.95,0),.79,.22,c("3b7dff"),Vector3(0,0,.3));m.ring(Vector3(0,.95,0),.79,.22,c("ff4fd8"),Vector3(0,0,-.5));m.ring(Vector3(0,.95,0),.79,.2,c("4fff7a"),Vector3(PI*.5,.6,0))
			m.eye(Vector3(-.15,1.15,-.78),.08);m.eye(Vector3(.15,1.15,-.78),.08)
			for i in range(4): m.box(Vector3(-.09+i*.06,.9+(.02 if i%2==0 else -.02),-.79),Vector3(.07,.02,.02),INK,CartoonMesh.BODY,Vector3(0,0,.6 if i%2==0 else -.6))
			m.legs([Vector3(-.35,.25,-.3),Vector3(.35,.25,-.3),Vector3(-.35,.25,.3),Vector3(.35,.25,.3)],.12,.1,body,c("c9c4e0"))
			m.orb=Vector3(0,.58,-.72);m.orb_radius=.15;return body
		43:  # Lollipop Larry: a swirl-candy head on a stick, one eye in the middle.
			var head=c("3bd6ff")
			m.rod(Vector3(0,.3,0),Vector3(0,.95,0),.1,c("ffffff"));m.ball(Vector3(0,1.25,0),Vector3(.95,.95,.25),head)
			m.ring(Vector3(0,1.25,-.1),.36,.06,c("ffe14a"),Vector3(PI*.5,0,0));m.ring(Vector3(0,1.25,-.11),.22,.06,c("ff4fd8"),Vector3(PI*.5,0,0))
			m.eye(Vector3(0,1.25,-.15),.12,FRONT,c("ff3b3b"))
			m.grin(Vector3(0,1.0,-.12),.3,.1,4,false,.4)
			for s in [-1.0,1.0]: m.rod(Vector3(s*.08,.75,0),Vector3(s*.4,.95,-.15),.04,c("ffffff"),CartoonMesh.TAIL,.3,Vector2(.75,.6))
			m.legs([Vector3(-.12,.3,0),Vector3(.12,.3,0)],.2,.07,c("ffffff"),head)
			m.orb=Vector3(0,.7,-.1);m.orb_radius=.11;return head
		44:  # Frostfly: a cyan fly with two huge glossy compound eyes.
			var body=c("3bf0ff")
			m.ball(Vector3(0,.7,0),Vector3(.45,.4,.7),body)
			for s in [-1.0,1.0]:
				m.ball(Vector3(s*.17,.8,-.3),Vector3.ONE*.28,c("6b2bff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.spike(Vector3(s*.05,.65,-.35),Vector3(s*.03,.52,-.5),.03,INK)
				for z in [-.1,.08,.25]: m.rod(Vector3(s*.12,.6,z),Vector3(s*.3,.28,z*1.3),.02,INK,CartoonMesh.LEG,z+.5,Vector2(.6,.5))
			m.wings(Vector3(0,.85,.05),.6,.3,c("e8fbff"),c("6fd0e0"),.35)
			m.orb=Vector3(0,.55,-.2);m.orb_radius=.09;return body
		45:  # Bubblegut: a huge purple belly with a mouth, a tiny head on top.
			var body=c("b46bff")
			m.ball(Vector3(0,1.0,0),Vector3(1.8,1.6,1.6),body);m.grin(Vector3(0,.95,-.76),1.0,.45,8)
			m.ball(Vector3(0,1.95,-.1),Vector3(.5,.45,.45),c("c99bff"))
			m.eye(Vector3(-.1,2.0,-.3),.07);m.eye(Vector3(.1,2.0,-.3),.07,Vector3(.4,0,-1))
			for s in [-1.0,1.0]:
				m.rod(Vector3(s*.85,1.3,-.1),Vector3(s*1.25,1.65,-.3),.1,body,CartoonMesh.TAIL,.25,Vector2(1.3,.5));m.ball(Vector3(s*1.3,1.72,-.32),Vector3.ONE*.24,c("c99bff"),CartoonMesh.TAIL,.25,Vector2(1.3,.5))
			m.legs([Vector3(-.45,.35,0),Vector3(.45,.35,0)],.25,.18,body,c("6b3bb0"))
			m.orb=Vector3(0,1.55,-.62);m.orb_radius=.17;return body
		46:  # Cinder Grinner: a blue beanpole whose grin is wider than its head.
			var body=c("4f5bff")
			m.rod(Vector3(0,.6,0),Vector3(0,1.3,0),.18,body);m.ball(Vector3(0,1.6,0),Vector3(.6,.55,.55),body)
			m.grin(Vector3(0,1.55,-.3),.9,.32,9,false,.15)
			for s in [-1.0,1.0]:
				m.ball(Vector3(s*.15,1.82,-.25),Vector3(.16,.1,.08),c("ffef5a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.rod(Vector3(s*.18,1.25,0),Vector3(s*.45,.8,-.1),.04,body,CartoonMesh.TAIL,.3,Vector2(1.25,.6))
			m.legs([Vector3(-.1,.6,0),Vector3(.1,.6,0)],.5,.05,body,c("2a2fa0"))
			m.orb=Vector3(0,1.0,-.2);m.orb_radius=.11;return body
		50:  # Brainy Blorp: a giant exposed brain on a mint body with tentacle feet.
			var body=c("5affd0");var brain=c("ff8fc0")
			m.ball(Vector3(0,.45,0),Vector3(.7,.5,.65),body)
			m.ball(Vector3(0,.95,0),Vector3(.95,.7,.85),brain)
			for p in [Vector3(-.25,1.15,-.1),Vector3(.25,1.15,-.1),Vector3(-.3,1.05,.25),Vector3(.3,1.05,.25),Vector3(0,1.25,.1),Vector3(-.15,1.2,.35),Vector3(.15,1.22,-.25),Vector3(0,1.1,-.3)]: m.ball(p,Vector3(.38,.26,.38),c("ff6fae"))
			m.eye(Vector3(-.15,.55,-.3),.08);m.eye(Vector3(.15,.55,-.3),.08);m.eye(Vector3(0,.66,-.32),.1,FRONT,c("ff3b3b"))
			m.grin(Vector3(0,.38,-.3),.3,.1,3,false)
			m.tentacles(4,Vector3(0,.3,0),.25,.3,.07,c("3ad6a8"))
			m.orb=Vector3(0,.95,-.42);m.orb_radius=.13;return brain
		51:  # Orbitopus: a floating orange octopus with glowing freckles.
			var body=c("ff8a2b")
			m.ball(Vector3(0,.9,0),Vector3(.9,1.0,.9),body);m.spots(Vector3(0,.9,0),Vector3(.45,.5,.45),c("fff27d"),6,.12,51,true)
			m.eye(Vector3(-.18,.85,-.4),.12,FRONT,c("2adfff"));m.eye(Vector3(.18,.85,-.4),.12,FRONT,c("2adfff"))
			m.spike(Vector3(0,.7,-.4),Vector3(0,.62,-.55),.05,INK)
			m.tentacles(8,Vector3(0,.5,0),.32,.55,.07,c("ffb35a"),c("ff5a1f"))
			m.orb=Vector3(0,1.2,-.36);m.orb_radius=.11;return body
		52:  # Ringthing: a little planet with a ring, a face and two moons.
			var body=c("ffd23f")
			m.ball(Vector3(0,1.0,0),Vector3.ONE*1.2,body);m.ring(Vector3(0,1.0,0),.95,.12,c("ff6bd5"),Vector3(.35,0,.2))
			m.eye(Vector3(-.2,1.15,-.55),.12);m.eye(Vector3(.2,1.15,-.55),.1,Vector3(.3,0,-1))
			m.grin(Vector3(0,.85,-.57),.45,.16,5)
			m.ball(Vector3(-.95,1.45,.2),Vector3.ONE*.2,c("c9c9ff"));m.ball(Vector3(.9,.6,-.2),Vector3.ONE*.15,c("c9c9ff"))
			m.orb=Vector3(0,.62,-.5);m.orb_radius=.14;return body
		53:  # Mantoid Zap: a green mantis with glowing eyes and scythe arms.
			var body=c("6bff5a")
			m.rod(Vector3(0,.6,.2),Vector3(0,1.1,-.1),.14,body);m.ball(Vector3(0,.55,.55),Vector3(.45,.4,.8),body)
			m.ball(Vector3(0,1.3,-.2),Vector3(.55,.35,.35),body)
			for s in [-1.0,1.0]:
				m.ball(Vector3(s*.25,1.35,-.25),Vector3.ONE*.2,c("ff3bf0"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.rod(Vector3(s*.12,1.05,-.2),Vector3(s*.2,.85,-.55),.05,body,CartoonMesh.JAW);m.spike(Vector3(s*.2,.85,-.55),Vector3(s*.18,1.15,-.8),.05,c("c9ff9a"),CartoonMesh.JAW)
				m.antenna(Vector3(s*.08,1.45,-.25),Vector3(s*.25,1.75,-.4),.03,body,c("c9ff9a"),.3)
			m.ball(Vector3(0,1.2,-.38),Vector3.ONE*.1,c("7dfffb"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.spider_legs(4,Vector3(0,.6,.3),.6,.25,.03,c("3ab82a"))
			m.orb=Vector3(0,.85,-.2);m.orb_radius=.1;return body
		54:  # Twinkle Tick: a little five-pointed star with one eye.
			var body=c("ffe14a")
			m.ball(Vector3(0,.7,0),Vector3(.45,.45,.25),body,CartoonMesh.BODY,0.0,Vector2(0,1),true)
			for i in range(5):
				var a=PI*.5+i*TAU/5;var o=Vector3(cos(a),sin(a),0)
				m.spike(Vector3(0,.7,0)+o*.18,Vector3(0,.7,0)+o*.5,.13,body,CartoonMesh.WING,0.0,Vector2(.1,.4))
			m.eye(Vector3(0,.72,-.15),.12,FRONT,c("7a3bff"))
			m.grin(Vector3(0,.56,-.12),.16,.05,3,false)
			m.orb=Vector3(0,.42,-.08);m.orb_radius=.07;return body
		55:  # Crabzilla Jr.: a big cyan crab with stalk eyes and giant claws.
			var body=c("3bd6ff")
			m.ball(Vector3(0,1.0,0),Vector3(1.8,.8,1.3),body)
			for s in [-1.0,1.0]:
				m.rod(Vector3(s*.8,1.0,-.4),Vector3(s*1.1,1.2,-.9),.12,body,CartoonMesh.JAW)
				m.ball(Vector3(s*1.15,1.3,-1.1),Vector3(.6,.4,.5),body,CartoonMesh.JAW);m.spike(Vector3(s*1.15,1.45,-1.3),Vector3(s*1.12,1.5,-1.65),.12,c("2a9ac0"),CartoonMesh.JAW)
				m.stalk_eye(Vector3(s*.25,1.35,-.45),Vector3(s*.35,1.8,-.55),.12,body,FRONT,c("ff3b3b"),.3+s*.2)
			m.grin(Vector3(0,.95,-.62),.6,.18,6)
			m.spider_legs(6,Vector3(0,.9,0),1.1,.3,.07,c("2a9ac0"))
			m.orb=Vector3(0,.68,-.6);m.orb_radius=.16;return body
		56:  # Antenna Annie: an orange spider with a dish for a head and a cluster of eyes.
			var body=c("ff6b3b")
			m.ball(Vector3(0,1.3,0),Vector3(.9,.7,.9),body)
			m.ball(Vector3(0,1.62,-.4),Vector3(.8,.8,.12),c("e8e8f8"),CartoonMesh.BODY,0.0,Vector2(0,1),false,Vector3(.3,0,0))
			m.antenna(Vector3(0,1.62,-.42),Vector3(0,1.66,-.7),.05,c("b9b9c9"),c("7dff6a"))
			for p in [Vector3(-.15,1.32,-.42),Vector3(0,1.36,-.44),Vector3(.15,1.32,-.42),Vector3(-.08,1.2,-.42),Vector3(.08,1.2,-.42),Vector3(0,1.25,-.45)]: m.eye(p,.055,FRONT,c("ff2b2b"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.antenna(Vector3(0,1.6,.1),Vector3(.1,2.0,.2),.06,body,c("7dff6a"),.5)
			m.spider_legs(8,Vector3(0,1.3,0),1.2,.45,.05,c("c94a2a"))
			m.orb=Vector3(0,1.02,-.4);m.orb_radius=.13;return body
		7:  # Melty Mel: a person whose face has slid down onto the chest.
			var skin=c("ffb3a0");var a=person(m,skin,c("2fd3b8"),c("3b4a8a"),c("2a2340"),{"no_face":true,"hunch":.3})
			m.ball(a.head+Vector3(0,-.12,-.05),Vector3(.36,.5,.34),skin)
			for i in range(4): m.ball(a.head+Vector3(-.12+i*.08,-.32-float(i%2)*.08,-.12),Vector3(.07,.16,.07),skin,CartoonMesh.TAIL,.2*i,Vector2(a.head.y,.6))
			m.eye(a.chest+Vector3(-.12,.12,-.2),.07,Vector3(-.3,-.2,-1));m.eye(a.chest+Vector3(.1,.05,-.21),.09,Vector3(.4,.3,-1))
			m.grin(a.chest+Vector3(0,-.15,-.2),.28,.12,5)
			m.orb=a.hip+Vector3(0,.02,-.18);m.orb_radius=.09;return skin
		8:  # Two-Torso Terry: two upper bodies fused onto one pair of legs.
			var skin=c("ffd27a");var shirt=c("ff5f9e");var pants=c("6b3bb0")
			m.legs([Vector3(-.16,.86,0),Vector3(.16,.86,0)],.72,.1,pants,c("2a2340"))
			m.ball(Vector3(0,.92,0),Vector3(.6,.36,.4),pants)
			for s in [-1.0,1.0]:
				var tilt=Vector3(s*.32,0,0);var chest=Vector3(s*.2,1.25,0)+tilt*.6;var head=Vector3(s*.42,1.72,0)+tilt*.5
				m.rod(Vector3(0,.98,0),chest,.2,shirt);m.ball(chest,Vector3(.42,.55,.34),shirt)
				m.rod(chest+Vector3(s*.05,.25,0),head,.06,skin);m.ball(head,Vector3(.3,.33,.3),skin)
				m.eye(head+Vector3(-.06,.03,-.14),.045);m.eye(head+Vector3(.06,.03,-.14),.045,Vector3(s*.5,0,-1))
				m.grin(head+Vector3(0,-.08,-.13),.13,.05,3,false,.3)
				for arm in [chest+Vector3(s*.22,.18,0),chest+Vector3(-s*.18,.2,-.05)]:
					var hand=arm+Vector3(s*.25,-.42,-.08);var pivot=Vector2(arm.y,.5)
					m.rod(arm,hand,.06,shirt,CartoonMesh.LEG,.5 if s>0 else 0.0,pivot);m.ball(hand,Vector3.ONE*.14,skin,CartoonMesh.LEG,.5 if s>0 else 0.0,pivot)
			m.orb=Vector3(0,1.12,-.2);m.orb_radius=.11;return shirt
		9:  # Gob Mother: a tiny body under a huge head that is mostly lips.
			var skin=c("c9a5ff");var a=person(m,skin,c("ffe14a"),c("ff6b3b"),c("2a2340"),{"no_head":true})
			var head=Vector3(0,1.85,-.05)
			m.rod(a.neck,head-Vector3(0,.3,0),.07,skin);m.ball(head,Vector3(.75,.7,.65),skin)
			m.ball(head+Vector3(0,.42,.12),Vector3(.38,.3,.38),c("ff4fd8"))
			m.ring(head+Vector3(0,-.1,-.3),.2,.12,c("ff3b6b"),Vector3(PI*.5,0,0));m.ball(head+Vector3(0,-.1,-.3),Vector3(.26,.16,.1),CartoonMesh.MOUTH)
			m.eye(head+Vector3(-.17,.15,-.27),.1,Vector3(-.2,0,-1),c("2fd3b8"));m.eye(head+Vector3(.17,.15,-.27),.1,Vector3(.2,0,-1),c("2fd3b8"))
			m.orb=a.chest+Vector3(0,0,-.2);m.orb_radius=.09;return skin
		17:  # Fungus Phil: a hunched man overgrown with mushrooms.
			var skin=c("ffe3c3");var a=person(m,skin,c("4f5bff"),c("2a8fb0"),c("1a1a2a"),{"hunch":.45})
			for q in [[a.head+Vector3(-.05,.2,.02),.36],[a.shoulders[0]+Vector3(-.03,.1,0),.24],[a.shoulders[1]+Vector3(.04,.08,.05),.2],[a.chest+Vector3(.1,.15,.22),.28]]:
				m.can(q[0]-Vector3(0,.04,0),q[0]+Vector3(0,.1,0),.04,c("f3e3c3"));m.ball(q[0]+Vector3(0,.14,0),Vector3(q[1],q[1]*.45,q[1]),c("ff3b4a"))
				m.spots(q[0]+Vector3(0,.16,0),Vector3(q[1]*.5,q[1]*.2,q[1]*.5),c("fffaf0"),3,.06,int(q[1]*100))
			m.ball(a.head+Vector3(.07,.04,-.15),Vector3(.13,.13,.06),c("b8ff7a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.orb=a.chest+Vector3(0,-.05,-.22);m.orb_radius=.09;return c("ff3b4a")
		18:  # Toadman Todd: a pot-bellied man with a giant toad's head.
			var skin=c("7ad65a");var a=person(m,skin,c("ff9a3c"),c("6b3bb0"),c("2a2340"),{"no_head":true,"fat":.6,"sleeves":false})
			var head=a.neck+Vector3(0,.3,-.05)
			m.ball(head,Vector3(.75,.45,.6),skin);m.grin(head+Vector3(0,-.08,-.28),.6,.12,0,false)
			m.ball(head+Vector3(0,-.15,-.42),Vector3(.12,.05,.4),CartoonMesh.TONGUE,CartoonMesh.JAW)
			m.eye(head+Vector3(-.22,.22,-.12),.13,Vector3(-.3,0,-1),c("ffd23f"));m.eye(head+Vector3(.22,.22,-.12),.13,Vector3(.3,0,-1),c("ffd23f"))
			m.spots(a.chest,Vector3(.35,.35,.35),c("4a9a3a"),7,.09,18)
			m.orb=a.chest+Vector3(0,-.12,-.36);m.orb_radius=.11;return skin
		19:  # Spore Sneezer: a woman with a trunk of a nose that sprays spores.
			var skin=c("ffb3c7");var a=person(m,skin,c("8fff5a"),c("3b2bff"),c("2a2340"),{"no_face":true})
			var nose=a.head+Vector3(0,0,-.15)
			for i in range(5): m.ball(nose+Vector3(0,-.03*i,-.08*i),Vector3.ONE*(.14-i*.012),skin,CartoonMesh.TAIL,0.0,Vector2(a.head.y+.1,.4))
			m.ball(nose+Vector3(0,-.13,-.4),Vector3(.12,.12,.05),CartoonMesh.MOUTH)
			m.eye(a.head+Vector3(-.08,.07,-.14),.05);m.eye(a.head+Vector3(.08,.07,-.14),.05)
			for s in [-1.0,1.0]: m.ball(a.head+Vector3(s*.12,-.04,-.1),Vector3.ONE*.12,c("ff6fae"))
			m.spots(a.chest,Vector3(.27,.31,.2),c("eaff7a"),6,.07,19,true)
			m.orb=a.chest+Vector3(0,0,-.2);m.orb_radius=.09;return c("8fff5a")
		27:  # Crab Hands Craig: eye stalks for a head and giant crab claws for hands.
			var skin=c("ff8a6a");var a=person(m,skin,c("40e0ff"),c("2a2340"),c("fff07a"),{"no_head":true,"no_arms":true,"hunch":.25})
			for i in range(2):
				var s=-1.0 if i==0 else 1.0;var claw=a.hands[i]+Vector3(s*.1,.1,-.15)
				m.rod(a.shoulders[i],claw,.07,skin,CartoonMesh.LEG,.5*float(i),Vector2(a.shoulders[i].y,.4))
				m.ball(claw,Vector3(.3,.22,.34),c("ff5a36"),CartoonMesh.LEG,.5*float(i),Vector2(a.shoulders[i].y,.4))
				m.spike(claw+Vector3(0,.06,-.12),claw+Vector3(s*.02,.08,-.32),.06,c("ff5a36"),CartoonMesh.LEG,.5*float(i),Vector2(a.shoulders[i].y,.4))
				m.stalk_eye(a.neck+Vector3(s*.07,0,0),a.neck+Vector3(s*.16,.38,-.05),.09,skin,Vector3(s*.3,0,-1),c("3b7dff"),.4*float(i)+.1)
			m.grin(a.chest+Vector3(0,.22,-.2),.22,.08,4,false)
			m.orb=a.chest+Vector3(0,-.08,-.2);m.orb_radius=.09;return c("40e0ff")
		28:  # Moonhead Morris: a cratered moon for a head on a tiny body.
			var head_c=c("e8e8f8");var a=person(m,c("c9a5ff"),c("ff4fd8"),c("3b2bff"),c("1a1a2a"),{"no_head":true})
			var head=a.neck+Vector3(0,.55,0)
			m.ball(head,Vector3.ONE*1.0,head_c);m.spots(head,Vector3.ONE*.5,c("a8a8c8"),8,.2,28,false,false)
			m.eye(head+Vector3(-.17,.1,-.44),.1);m.eye(head+Vector3(.17,.08,-.45),.12,Vector3(.3,0,-1))
			m.grin(head+Vector3(0,-.18,-.44),.4,.14,5)
			m.orb=a.chest+Vector3(0,0,-.2);m.orb_radius=.09;return head_c
		29:  # Eyeball Eddie: one giant eye for a head, a mouth in each palm.
			var skin=c("8fff5a");var a=person(m,skin,c("ff6b3b"),c("2a2340"),c("ffe14a"),{"no_head":true})
			var head=a.neck+Vector3(0,.32,0)
			m.eye(head,.3,Vector3.FORWARD,c("ff4fd8"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			for i in range(3): m.rod(head+Vector3(-.1+i*.1,-.15,.2),head+Vector3(-.15+i*.15,-.3,.34),.02,c("ff3b3b"))
			for hand in a.hands: m.grin(hand+Vector3(0,-.08,-.08),.12,.06,3,false,.4)
			m.orb=a.chest+Vector3(0,0,-.2);m.orb_radius=.09;return skin
		37:  # Leggy Lou: walks on its hands, legs flailing overhead, face in the belly.
			var skin=c("ffd23f");var shirt=c("8f5cff");var pants=c("ff7ab0")
			m.legs([Vector3(-.2,.75,-.05),Vector3(.2,.75,-.05)],.65,.07,skin,skin)
			m.ball(Vector3(0,1.05,0),Vector3(.55,.65,.38),shirt);m.ball(Vector3(0,1.42,0),Vector3(.46,.3,.32),pants)
			for s in [-1.0,1.0]:
				var hip=Vector3(s*.13,1.5,0);var foot=hip+Vector3(s*.25,.6,.15)
				m.rod(hip,foot,.08,pants,CartoonMesh.STALK,.5 if s>0 else 0.0,Vector2(1.5,1.6));m.ball(foot+Vector3(0,.06,-.05),Vector3(.14,.12,.24),c("2a2340"),CartoonMesh.STALK,.5 if s>0 else 0.0,Vector2(1.5,1.6))
			m.eye(Vector3(-.1,1.15,-.19),.07);m.eye(Vector3(.1,1.15,-.19),.07,Vector3(.3,0,-1));m.grin(Vector3(0,.95,-.19),.24,.1,5)
			m.ball(Vector3(0,.68,0),Vector3(.26,.24,.24),skin)
			m.orb=Vector3(0,1.42,-.17);m.orb_radius=.08;return shirt
		38:  # Puffer Pete: a man blown up like a spiky balloon, tiny limbs.
			var skin=c("ffb07a");var body=c("3bf0ff")
			m.legs([Vector3(-.15,.45,0),Vector3(.15,.45,0)],.32,.07,c("2a2340"),c("2a2340"))
			m.ball(Vector3(0,1.05,0),Vector3.ONE*1.2,body)
			for i in range(10):
				var d=Vector3(cos(i*2.4),sin(i*1.7)*.8,sin(i*2.4)).normalized()
				if d.z<-.5: d.z=-d.z
				m.spike(Vector3(0,1.05,0)+d*.55,Vector3(0,1.05,0)+d*.8,.06,c("fff1cf"))
			m.ball(Vector3(0,1.78,-.05),Vector3(.3,.32,.3),skin);m.eye(Vector3(-.06,1.8,-.19),.045);m.eye(Vector3(.06,1.8,-.19),.045)
			m.ball(Vector3(0,1.71,-.19),Vector3(.08,.08,.04),CartoonMesh.MOUTH)
			for s in [-1.0,1.0]: m.rod(Vector3(s*.55,1.15,0),Vector3(s*.78,1.0,-.1),.05,skin,CartoonMesh.LEG,.5 if s>0 else 0.0,Vector2(1.15,.5))
			m.orb=Vector3(0,1.0,-.6);m.orb_radius=.13;return body
		39:  # Beakmouth Bea: a long-necked woman with a bird's beak and feather hair.
			var skin=c("ff7ab0");var a=person(m,skin,c("ffe14a"),c("3b7dff"),c("2a2340"),{"no_head":true})
			var head=a.neck+Vector3(0,.55,-.05)
			m.rod(a.neck,head,.06,skin,CartoonMesh.STALK,.3,Vector2(a.neck.y,.5));m.ball(head,Vector3(.3,.3,.32),skin,CartoonMesh.STALK,.3,Vector2(a.neck.y,.5))
			m.spike(head+Vector3(0,0,-.13),head+Vector3(0,-.05,-.48),.08,c("ff9a3c"),CartoonMesh.STALK,.3,Vector2(a.neck.y,.5))
			m.eye(head+Vector3(-.09,.06,-.11),.05,Vector3.FORWARD,Color(0,0,0,0),CartoonMesh.STALK,.3,Vector2(a.neck.y,.5));m.eye(head+Vector3(.09,.06,-.11),.05,Vector3.FORWARD,Color(0,0,0,0),CartoonMesh.STALK,.3,Vector2(a.neck.y,.5))
			for i in range(4): m.spike(head+Vector3(-.09+i*.06,.1,.05),head+Vector3(-.15+i*.1,.38,.18),.04,c("3bd6ff"),CartoonMesh.STALK,.3,Vector2(a.neck.y,.5))
			m.orb=a.chest+Vector3(0,0,-.2);m.orb_radius=.09;return skin
		47:  # Gummy Gary: a melting gummy-candy man, dripping as he walks.
			var gum=c("4fff7a");var a=person(m,gum,gum,c("2fd3b8"),c("2fd3b8"),{"no_face":true,"hunch":.15,"sleeves":false})
			m.ball(a.head+Vector3(0,-.1,0),Vector3(.38,.3,.36),gum)
			m.eye(a.head+Vector3(-.08,-.02,-.15),.06,Vector3(-.3,-.4,-1));m.eye(a.head+Vector3(.09,-.08,-.15),.05,Vector3(.4,-.5,-1))
			m.grin(a.head+Vector3(0,-.16,-.15),.15,.05,0,false,.3)
			for q in [a.hands[0],a.hands[1],a.chest+Vector3(.15,-.25,-.15),a.chest+Vector3(-.1,-.3,-.16),a.head+Vector3(.12,-.2,-.1)]:
				m.ball(q-Vector3(0,.12,0),Vector3(.07,.18,.07),gum,CartoonMesh.TAIL,q.x,Vector2(q.y,.5))
			m.orb=a.chest+Vector3(0,0,-.2);m.orb_radius=.09;return gum
		48:  # Fistbody Frank: a huge torso, a tiny head and six arms with fists.
			var skin=c("6b9bff");var a=person(m,skin,c("ffffff"),c("2a2340"),c("1a1a2a"),{"no_head":true,"no_arms":true,"fat":.8})
			m.ball(a.chest+Vector3(0,.15,0),Vector3(1.1,.8,.7),skin)
			m.ball(a.chest+Vector3(0,.62,-.08),Vector3(.24,.26,.24),skin);m.eye(a.chest+Vector3(-.05,.65,-.19),.035);m.eye(a.chest+Vector3(.05,.65,-.19),.035)
			for row in range(3):
				for s in [-1.0,1.0]:
					var shoulder=a.chest+Vector3(s*.5,.35-row*.22,0);var fist=shoulder+Vector3(s*.35,-.3,-.2-row*.05);var pivot=Vector2(shoulder.y,.5)
					m.rod(shoulder,fist,.07,skin,CartoonMesh.LEG,.33*row+(.5 if s>0 else 0.0),pivot);m.ball(fist,Vector3.ONE*.2,c("ffb3c7"),CartoonMesh.LEG,.33*row+(.5 if s>0 else 0.0),pivot)
			m.orb=a.chest+Vector3(0,.05,-.37);m.orb_radius=.12;return skin
		49:  # Tongue Tina: four eyes and a tongue three times her height.
			var skin=c("ffe14a");var a=person(m,skin,c("b46bff"),c("2fd3b8"),c("2a2340"),{"no_face":true})
			for e in [[-.08,.08],[.08,.08],[-.1,0],[.1,0]]: m.eye(a.head+Vector3(e[0],e[1],-.14),.035)
			m.ball(a.head+Vector3(0,-.08,-.15),Vector3(.16,.1,.06),CartoonMesh.MOUTH)
			for i in range(7): m.ball(a.head+Vector3(0,-.1-i*.06,-.2-i*.11),Vector3(.1,.04,.14),CartoonMesh.TONGUE,CartoonMesh.TAIL,.1*i,Vector2(a.head.y,.8))
			m.orb=a.chest+Vector3(0,0,-.2);m.orb_radius=.09;return c("b46bff")
		57:  # Tentacle Ted: a man from the waist up, an octopus from the waist down.
			var skin=c("ff9ec7");var a=person(m,skin,c("ffd23f"),c("ff8a2b"),c("ff8a2b"),{"no_legs":true,"no_face":true})
			m.tentacles(6,a.hip-Vector3(0,.05,0),.14,.8,.08,c("ff8a2b"),c("ff5a1f"))
			m.eye(a.head+Vector3(-.065,.05,-.15),.05,Vector3.FORWARD,c("2adfff"));m.eye(a.head+Vector3(.065,.05,-.15),.05,Vector3.FORWARD,c("2adfff"))
			for i in range(5): m.ball(a.head+Vector3(-.08+i*.04,-.15-float(i%2)*.04,-.12),Vector3(.04,.14,.04),c("ff5a1f"),CartoonMesh.TAIL,.15*i,Vector2(a.head.y,.7))
			m.orb=a.chest+Vector3(0,0,-.2);m.orb_radius=.09;return skin
		58:  # Brainbuster Bob: a brain three times his size, veined and pulsing.
			var skin=c("5affd0");var a=person(m,skin,c("3b2bff"),c("2a2340"),c("1a1a2a"),{"no_face":true})
			var brain=a.head+Vector3(0,.45,.05)
			m.ball(brain,Vector3(1.0,.75,.9),c("ff8fc0"))
			for q in [Vector3(-.28,.15,-.15),Vector3(.28,.15,-.15),Vector3(-.3,.05,.25),Vector3(.3,.05,.25),Vector3(0,.3,.05),Vector3(0,.2,-.32)]: m.ball(brain+q,Vector3(.4,.28,.4),c("ff6fae"))
			for i in range(4): m.rod(brain+Vector3(-.3+i*.2,-.3,-.35),brain+Vector3(-.25+i*.18,0,-.45),.02,c("ff3b6b"))
			m.eye(a.head+Vector3(-.065,0,-.15),.04,Vector3.FORWARD,c("ff3b3b"),CartoonMesh.BODY,0.0,Vector2(0,1),true);m.eye(a.head+Vector3(.065,0,-.15),.04,Vector3.FORWARD,c("ff3b3b"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.orb=a.chest+Vector3(0,0,-.2);m.orb_radius=.09;return c("ff8fc0")
		59:  # Mirror Mike: three faces, front, back and one in the chest, all glowing.
			var skin=c("c9c9ff");var a=person(m,skin,c("ff6bd5"),c("2a2340"),c("ffe14a"))
			m.eye(a.head+Vector3(-.065,.03,.15),.045,Vector3.BACK);m.eye(a.head+Vector3(.065,.03,.15),.045,Vector3.BACK)
			m.ball(a.head+Vector3(0,-.08,.15),Vector3(.12,.05,.04),c("7dff6a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.eye(a.chest+Vector3(-.09,.12,-.2),.06,Vector3.FORWARD,c("7dff6a"),CartoonMesh.BODY,0.0,Vector2(0,1),true);m.eye(a.chest+Vector3(.09,.12,-.2),.06,Vector3.FORWARD,c("7dff6a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.grin(a.chest+Vector3(0,-.08,-.2),.24,.1,5)
			m.orb=a.hip+Vector3(0,0,-.18);m.orb_radius=.09;return c("ff6bd5")
	return Color.WHITE

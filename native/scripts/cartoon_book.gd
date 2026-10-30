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
	["Brainy Blorp","Orbitopus","Ringthing","Mantoid Zap","Twinkle Tick","Crabzilla Jr.","Antenna Annie","Tentacle Ted","Brainbuster Bob","Mirror Mike"],
	["Trashcan Stan","Propeller Pidge","Tank Tortoise","Hose Nose","Bolt Bug","Bulldozer Bruno","Lamp Lurker","Wrenchhand Wendy","Tire Torso Tony","Battery Betty"]]
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
	# The torso is the big glass health orb, with a shirt yoke over the shoulders
	# and a collar band (October 25: every model is built around its orb).
	var torso=.33+fat*.12
	m.core(a.chest,torso)
	m.ball(a.chest+Vector3(0,torso*.95,0),Vector3(.7+fat*.4,.2,.44+fat*.3),shirt);m.ring(a.chest,torso*1.02,.05,shirt)
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
	cache[key]={"mesh":m.commit(),"height":m.height(),"orb":m.orb,"orb_radius":m.orb_radius,"orb_body":m.orb_body,"skin":skin}
	return cache[key]

static func build(m: CartoonMesh,biome: int,index: int) -> Color:
	match biome*10+index:
		0:  # Gloop Gazer: a lime blob whose belly is a big glass orb held in a fleshy frame.
			var body=c("a6e04a");var dark=c("6aa338")
			m.core(Vector3(0,.66,0),.42)
			m.ball(Vector3(0,1.1,0),Vector3(1.05,.5,.95),body);m.spots(Vector3(0,1.1,0),Vector3(.52,.25,.47),dark,6,.14,1)
			m.ball(Vector3(0,.26,0),Vector3(.86,.26,.8),body)
			for side in [-1.0,1.0]: m.rod(Vector3(side*.43,.28,0),Vector3(side*.43,1.0,0),.06,body)
			m.ring(Vector3(0,.66,0),.43,.05,dark)
			m.grin(Vector3(0,1.06,-.45),.58,.22,6)
			m.stalk_eye(Vector3(0,1.3,-.1),Vector3(-.05,1.55,-.14),.17,body,FRONT,Color(0,0,0,0),.1)
			m.stalk_eye(Vector3(-.3,1.25,0),Vector3(-.48,1.45,0),.12,body,Vector3(-.4,.1,-1),Color(0,0,0,0),.5)
			m.stalk_eye(Vector3(.3,1.26,.04),Vector3(.5,1.44,.06),.1,body,Vector3(.5,-.2,-1),Color(0,0,0,0),.8)
			m.legs([Vector3(-.3,.2,-.2),Vector3(.3,.2,-.2),Vector3(-.3,.2,.22),Vector3(.3,.2,.22)],.13,.09,c("8fd14f"),c("4c8a2b"))
			return body
		1:  # Flapjack Flutterface: a glass orb in a pancake brim, one huge eye on top, bat wings.
			var body=c("ff9a3c")
			m.core(Vector3(0,.72,0),.32)
			m.ring(Vector3(0,.72,0),.42,.12,body);m.ball(Vector3(0,1.02,-.02),Vector3(.42,.16,.4),body)
			m.eye(Vector3(0,1.12,-.08),.2,Vector3(0,.2,-1),c("5a2bd6"))
			m.grin(Vector3(0,.62,-.4),.36,.12,4,false)
			m.wings(Vector3(0,.76,.05),.9,.7,c("ff6fb5"),c("b23a7a"))
			m.tentacles(2,Vector3(0,.42,0),.12,.3,.06,c("e07a2c"))
			return body
		2:  # Shellby Grunk: its shell is a big glass orb ringed with spikes; a big-nosed head pokes out.
			var shell=c("8a4fd6");var skin=c("ffc27a")
			m.core(Vector3(0,.98,.15),.62)
			m.ring(Vector3(0,.6,.15),.62,.2,c("5b2a9e"));m.ring(Vector3(0,.98,.15),.63,.06,shell,Vector3(PI*.5,0,0))
			for a in range(6): var d=Vector3(cos(a*TAU/6),0,sin(a*TAU/6));m.spike(Vector3(0,.62,.15)+d*.6,Vector3(0,.75,.15)+d*.85,.1,c("ffd84a"))
			m.ball(Vector3(0,.6,-.72),Vector3(.7,.6,.7),skin);m.ball(Vector3(0,.58,-1.1),Vector3(.34,.28,.38),c("ff8a6a"))
			m.eye(Vector3(-.12,.82,-.96),.1);m.eye(Vector3(.12,.82,-.96),.1,Vector3(.3,0,-1))
			m.grin(Vector3(0,.42,-.98),.34,.12,4,false)
			m.legs([Vector3(-.55,.38,-.3),Vector3(.55,.38,-.3),Vector3(-.6,.38,.2),Vector3(.6,.38,.2),Vector3(-.5,.38,.6),Vector3(.5,.38,.6)],.24,.11,skin,c("c4875a"))
			return shell
		3:  # Spitzle Sprout: a glass orb belly under a yellow bean head with a petal-ringed snout.
			var body=c("ffd23f")
			m.core(Vector3(0,.55,0),.32)
			m.rod(Vector3(0,.92,0),Vector3(0,1.12,0),.3,body);m.ring(Vector3(0,.82,0),.27,.07,body)
			m.can(Vector3(0,1.0,-.22),Vector3(0,1.0,-.58),.13,c("e0b52f"));m.ball(Vector3(0,1.0,-.58),Vector3(.2,.2,.06),MOUTH)
			for i in range(6): m.ball(Vector3(0,1.0,-.58)+Vector3(cos(i*TAU/6),sin(i*TAU/6),0)*.19,Vector3(.17,.17,.08),c("ff5f9e"))
			m.stalk_eye(Vector3(-.15,1.36,0),Vector3(-.25,1.6,0),.12,body,FRONT,c("2b8a3a"),.2)
			m.stalk_eye(Vector3(.15,1.36,0),Vector3(.27,1.56,0),.14,body,Vector3(.3,0,-1),c("2b8a3a"),.7)
			m.legs([Vector3(-.18,.26,-.05),Vector3(.18,.26,-.05),Vector3(0,.26,.2)],.16,.08,c("d9a82a"),c("8a6a1a"))
			return body
		4:  # Buzzlord Mini: a striped glass orb with four eyes, wings and a stinger.
			var body=c("ffe14a")
			m.core(Vector3(0,.66,0),.32)
			for y in [.53,.79]: m.ring(Vector3(0,y,0),.27,.07,c("2a1f2a"))
			m.ball(Vector3(0,.96,-.05),Vector3(.42,.16,.38),body)
			for x in [-.21,-.07,.07,.21]: m.eye(Vector3(x,.98,-.2),.065,FRONT,c("ff2b2b"))
			m.wings(Vector3(0,.92,.1),.5,.32,c("cfefff"),c("8fb8d0"),.5)
			m.spike(Vector3(0,.6,.3),Vector3(0,.52,.62),.08,INK)
			m.antenna(Vector3(-.1,1.03,-.1),Vector3(-.2,1.22,-.22),.05,body,c("7dfffb"),.2);m.antenna(Vector3(.1,1.03,-.1),Vector3(.2,1.22,-.22),.05,body,c("7dfffb"),.6)
			m.grin(Vector3(0,.88,-.2),.2,.07,3,false)
			return body
		5:  # Hornbelly Brute: a red brute whose huge gut is a glass orb; horn and tusks above.
			var body=c("ff5a36")
			m.core(Vector3(0,.82,0),.58)
			m.ball(Vector3(0,1.5,0),Vector3(1.5,.95,1.15),body);m.ring(Vector3(0,.82,0),.59,.07,c("e04a2c"))
			m.spike(Vector3(0,1.75,-.45),Vector3(0,2.15,-1.1),.2,TOOTH)
			m.eye(Vector3(-.22,1.78,-.48),.1,FRONT,c("ffd23f"));m.eye(Vector3(.22,1.78,-.48),.1,FRONT,c("ffd23f"))
			m.box(Vector3(-.22,1.9,-.53),Vector3(.26,.06,.06),INK,CartoonMesh.BODY,Vector3(0,0,-.4));m.box(Vector3(.22,1.9,-.53),Vector3(.26,.06,.06),INK,CartoonMesh.BODY,Vector3(0,0,.4))
			m.grin(Vector3(0,1.42,-.55),.75,.28,7)
			for s in [-1.0,1.0]:
				m.spike(Vector3(s*.3,1.28,-.55),Vector3(s*.42,1.66,-.75),.07,TOOTH)
				m.rod(Vector3(s*.72,1.45,-.1),Vector3(s*.95,.95,-.35),.12,body);m.ball(Vector3(s*.98,.88,-.4),Vector3.ONE*.28,c("e04a2c"))
			m.legs([Vector3(-.4,.42,0),Vector3(.4,.42,0)],.3,.2,c("e04a2c"),c("8a2a1a"))
			return body
		6:  # Tall Gerald: a lanky lavender stalker with a glass orb torso and one eye on a stalk.
			var body=c("b58cff")
			m.core(Vector3(0,1.68,0),.3)
			m.rod(Vector3(0,1.28,0),Vector3(0,1.38,0),.18,body);m.ball(Vector3(0,2.02,0),Vector3(.5,.14,.4),body)
			m.legs([Vector3(-.12,1.25,0),Vector3(.12,1.25,0)],1.15,.06,c("9a72e6"),c("5d3ea0"))
			for s in [-1.0,1.0]:
				m.rod(Vector3(s*.28,1.98,0),Vector3(s*.45,1.1,-.12),.05,body,CartoonMesh.TAIL,.3,Vector2(1.95,.6))
				for f in range(3): m.ball(Vector3(s*(.42+f*.04),1.02,-.1-f*.04),Vector3(.06,.14,.06),c("9a72e6"),CartoonMesh.TAIL,.3,Vector2(1.95,.6))
			m.ball(Vector3(0,2.35,0),Vector3(.42,.38,.42),c("c9a5ff"))
			m.stalk_eye(Vector3(0,2.5,0),Vector3(0,2.84,-.1),.2,c("c9a5ff"),FRONT,c("ff3b6b"),.3)
			m.box(Vector3(0,2.26,-.2),Vector3(.24,.03,.02),INK)
			return body
		10:  # Mushmouth: a glass orb stem under a red spotted cap; the face sits under the cap.
			var stem=c("f3e3c3")
			m.core(Vector3(0,.5,0),.38)
			m.ball(Vector3(0,1.05,0),Vector3(1.35,.62,1.35),c("ff3b4a"));m.spots(Vector3(0,1.05,0),Vector3(.67,.31,.67),c("fffaf0"),8,.22,10)
			m.ball(Vector3(0,.84,0),Vector3(.8,.12,.8),stem)
			m.eye(Vector3(-.16,.98,-.6),.1);m.eye(Vector3(.17,.97,-.6),.12,Vector3(.3,0,-1))
			m.grin(Vector3(0,.82,-.5),.44,.16,5)
			m.legs([Vector3(-.2,.16,0),Vector3(.2,.16,0)],.08,.1,stem,c("c9b08a"))
			return c("ff3b4a")
		11:  # Slurp Frog: a teal toad head over a glass orb belly, bulging eyes and a long tongue.
			var body=c("2fd3b8")
			m.core(Vector3(0,.42,.05),.38)
			m.ball(Vector3(0,.8,-.08),Vector3(1.2,.46,.95),body)
			m.grin(Vector3(0,.76,-.5),.85,.2,0,false)
			m.ball(Vector3(0,.66,-.85),Vector3(.18,.08,.6),CartoonMesh.TONGUE,CartoonMesh.JAW)
			m.eye(Vector3(-.32,1.05,-.25),.17,Vector3(-.2,0,-1),c("ffd23f"));m.eye(Vector3(.32,1.05,-.25),.17,Vector3(.2,0,-1),c("ffd23f"))
			for s in [-1.0,1.0]: m.ball(Vector3(s*.5,.35,.3),Vector3(.38,.4,.55),c("22a892"))
			m.legs([Vector3(-.35,.25,-.3),Vector3(.35,.25,-.3),Vector3(-.55,.22,.45),Vector3(.55,.22,.45)],.14,.09,body,c("1f8a78"))
			return body
		12:  # Snailbert: a yellow slug carrying a big glass orb for a shell.
			var body=c("ffe066")
			m.rod(Vector3(0,.25,-.6),Vector3(0,.25,.65),.25,body);m.rod(Vector3(0,.25,-.6),Vector3(0,.8,-.75),.22,body)
			m.core(Vector3(0,.98,.22),.55)
			m.ring(Vector3(0,.98,.22),.56,.08,c("c25a1a"),Vector3(0,0,PI*.5));m.ball(Vector3(.05,1.5,.35),Vector3.ONE*.26,c("ff8a2b"))
			m.stalk_eye(Vector3(-.1,.95,-.8),Vector3(-.22,1.4,-.9),.1,body,FRONT,c("6b3bff"),.1)
			m.stalk_eye(Vector3(.1,.95,-.8),Vector3(.24,1.45,-.88),.12,body,Vector3(.3,.1,-1),c("6b3bff"),.6)
			m.grin(Vector3(0,.62,-.94),.3,.1,4,false)
			for z in [-.3,.1,.5]: m.ball(Vector3(-.26,.08,z),Vector3(.12,.08,.16),c("b8ff7a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			return c("ff8a2b")
		13:  # Puffboy: a floating glass balloon of an orb with a face stuck on the glass.
			var skin=c("ff7ad9");var dark=c("d9479e")
			m.core(Vector3(0,1.0,0),.52)
			m.ring(Vector3(0,1.0,0),.53,.04,dark)
			m.can(Vector3(0,.92,-.5),Vector3(0,.92,-.72),.11,dark);m.ball(Vector3(0,.92,-.73),Vector3(.15,.15,.06),MOUTH)
			for side in [-1.0,1.0]:
				m.eye(Vector3(side*.2,1.2,-.48),.12,Vector3(side*.1,0,-1));m.ball(Vector3(side*.2,1.28,-.49),Vector3(.28,.12,.24),skin)
			m.ball(Vector3(0,1.52,0),Vector3(.3,.16,.3),skin);m.spike(Vector3(0,1.58,0),Vector3(.12,1.75,0),.06,skin)
			m.ball(Vector3(0,.47,0),Vector3(.42,.14,.42),skin)
			m.tentacles(4,Vector3(0,.42,0),.18,.42,.06,c("ffb3ec"))
			return skin
		14:  # Gnatquito: an orange mosquito whose swollen belly is a glass orb.
			var body=c("ff9a3c")
			m.ball(Vector3(0,.72,-.05),Vector3(.38,.36,.42),body);m.core(Vector3(0,.66,.38),.27)
			m.ring(Vector3(0,.66,.38),.27,.05,INK,Vector3(PI*.5,0,0))
			m.ball(Vector3(0,.8,-.34),Vector3(.32,.3,.3),body)
			m.eye(Vector3(-.1,.88,-.46),.07,FRONT,c("ff2b2b"));m.eye(Vector3(.1,.88,-.46),.07,FRONT,c("ff2b2b"));m.eye(Vector3(0,.98,-.43),.06,FRONT,c("ff2b2b"))
			m.spike(Vector3(0,.76,-.48),Vector3(0,.62,-.95),.03,INK)
			m.wings(Vector3(0,.88,-.02),.55,.25,c("cff6ff"),c("7ab8c9"),.4);m.wings(Vector3(0,.84,.12),.45,.2,c("cff6ff"),c("7ab8c9"),.2)
			for s in [-1.0,1.0]:
				for z in [-.12,0.0,.12]: m.rod(Vector3(s*.12,.62,z),Vector3(s*.3,.27,z*1.4),.02,INK,CartoonMesh.LEG,z+.5,Vector2(.6,.5))
			return body
		15:  # Tusk Hog: a cyan boar with a big glass orb for a barrel body and a tusked head.
			var body=c("4fd6ff")
			m.core(Vector3(0,1.05,.15),.62)
			m.ball(Vector3(0,1.15,-.62),Vector3(.95,.9,.65),body);m.ball(Vector3(0,1.08,.82),Vector3(.7,.62,.3),body)
			for p in [Vector3(-.2,1.55,-.55),Vector3(.25,1.5,-.6)]:
				m.can(p,p+Vector3(0,.16,0),.05,c("f3e3c3"));m.ball(p+Vector3(0,.2,0),Vector3(.28,.14,.28),c("ff3b4a"))
			m.can(Vector3(0,1.02,-.92),Vector3(0,1.02,-1.2),.21,c("ffb3c7"))
			for s in [-1.0,1.0]:
				m.ball(Vector3(s*.08,1.04,-1.21),Vector3(.07,.1,.03),INK)
				m.spike(Vector3(s*.25,.88,-.92),Vector3(s*.38,1.26,-1.22),.08,TOOTH)
				m.eye(Vector3(s*.28,1.38,-.88),.11,FRONT,c("ff3b3b"))
				m.box(Vector3(s*.28,1.51,-.92),Vector3(.3,.06,.06),INK,CartoonMesh.BODY,Vector3(0,0,s*.4))
			m.grin(Vector3(0,.82,-.9),.5,.18,5,false)
			m.legs([Vector3(-.45,.55,-.45),Vector3(.45,.55,-.45),Vector3(-.45,.55,.6),Vector3(.45,.55,.6)],.36,.17,body,c("2a8fb0"))
			return body
		16:  # Mire Mouthpole: a swaying pole with a glass orb in its middle and a lamprey mouth on top.
			var body=c("6fe0c8")
			m.rod(Vector3(0,.3,0),Vector3(0,.55,0),.18,body);m.core(Vector3(0,.88,0),.33);m.rod(Vector3(0,1.2,0),Vector3(0,1.45,0),.16,body)
			m.ball(Vector3(0,1.75,0),Vector3(.75,.75,.7),body)
			m.ring(Vector3(0,1.75,-.33),.27,.2,c("ff5f8a"),Vector3(PI*.5,0,0));m.ball(Vector3(0,1.75,-.3),Vector3(.42,.42,.12),MOUTH)
			for i in range(8):
				var a=i*TAU/8;var o=Vector3(cos(a),sin(a),0)
				m.spike(Vector3(0,1.75,-.36)+o*.2,Vector3(0,1.75,-.38)+o*.08,.03,TOOTH)
			for i in range(5):
				var a=PI*.15+i*PI*.175;m.eye(Vector3(0,1.75,-.28)+Vector3(cos(a),sin(a),0)*.4,.06,FRONT,c("ffd23f"))
			for s in [Vector3(.4,0,.4),Vector3(-.4,0,.4),Vector3(.4,0,-.4),Vector3(-.4,0,-.4)]: m.rod(Vector3(0,.35,0),s,.06,c("2fb39b"))
			m.tentacles(3,Vector3(0,1.42,.05),.2,.5,.05,c("2fb39b"))
			return body
		20:  # Crater Clod: a cyan cyclops cap on a glass orb belly.
			var body=c("40e0ff")
			m.core(Vector3(0,.55,0),.42)
			m.ball(Vector3(0,1.0,0),Vector3(1.1,.48,1.0),body);m.spots(Vector3(0,1.0,0),Vector3(.55,.24,.5),c("1f9ac0"),7,.18,20)
			m.ball(Vector3(0,.2,0),Vector3(.8,.18,.75),body)
			m.eye(Vector3(0,1.08,-.42),.2,FRONT,c("ff4fd8"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.grin(Vector3(0,.88,-.44),.5,.16,5)
			m.legs([Vector3(-.3,.18,-.2),Vector3(.3,.18,-.2),Vector3(-.3,.18,.25),Vector3(.3,.18,.25)],.1,.1,c("2bb8d6"),c("16708a"))
			return body
		21:  # Moonray: a lilac manta built around a glass orb, glowing spots and a whip tail.
			var body=c("c39bff")
			m.core(Vector3(0,.72,0),.27)
			m.wings(Vector3(0,.72,0),1.0,.9,c("a77bf0"),c("6d45c0"),.1)
			m.ball(Vector3(0,.95,-.05),Vector3(.38,.12,.36),body);m.spots(Vector3(0,.72,0),Vector3(.8,.1,.5),c("fff27d"),6,.1,21,true)
			m.rod(Vector3(0,.72,.28),Vector3(0,.74,1.3),.04,c("6d45c0"),CartoonMesh.TAIL,0.0,Vector2(.75,1));m.spike(Vector3(0,.74,1.3),Vector3(0,.77,1.5),.07,c("fff27d"),CartoonMesh.TAIL,0.0,Vector2(.75,1))
			m.eye(Vector3(-.12,1.0,-.15),.08,FRONT,c("7dfffb"),CartoonMesh.BODY,0.0,Vector2(0,1),true);m.eye(Vector3(.12,1.0,-.15),.08,FRONT,c("7dfffb"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.grin(Vector3(0,.55,-.24),.26,.07,3,false)
			return body
		22:  # Gorbo Block: a yellow cube cage around a glass orb, mismatched eyes and a grin.
			var body=c("fff07a")
			m.core(Vector3(0,.92,0),.5)
			m.box(Vector3(0,1.48,0),Vector3(1.2,.24,1.1),body);m.box(Vector3(0,.36,0),Vector3(1.2,.2,1.1),body)
			for x in [-.55,.55]:
				for z in [-.5,.5]: m.box(Vector3(x,.92,z),Vector3(.12,1.0,.12),body)
			m.eye(Vector3(-.27,1.5,-.56),.15);m.eye(Vector3(.3,1.52,-.56),.1,Vector3(.3,.2,-1),c("3b7dff"))
			m.grin(Vector3(0,.36,-.56),.7,.16,7)
			m.antenna(Vector3(0,1.6,0),Vector3(.05,1.95,.05),.08,c("b9b9c9"),c("ff4f4f"))
			for s in [-1.0,1.0]:
				m.rod(Vector3(s*.6,1.0,-.1),Vector3(s*.85,.65,-.3),.08,body);m.ball(Vector3(s*.88,.6,-.32),Vector3.ONE*.2,c("e0c84a"))
			m.legs([Vector3(-.38,.28,-.3),Vector3(.38,.28,-.3),Vector3(-.38,.28,.3),Vector3(.38,.28,.3)],.16,.11,c("e0c84a"),c("8a7a2a"))
			return body
		23:  # Saucer Sam: a little flying saucer whose cockpit dome is a big glass orb.
			var hull=c("cfd6e8")
			m.ball(Vector3(0,.86,0),Vector3(1.3,.26,1.3),hull);m.ring(Vector3(0,.86,0),.62,.14,c("8a94b0"))
			for i in range(8): m.ball(Vector3(cos(i*TAU/8),0,sin(i*TAU/8))*.66+Vector3(0,.86,0),Vector3.ONE*.11,c("7dff6a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.core(Vector3(0,1.15,0),.36)
			m.ball(Vector3(0,1.56,0),Vector3(.32,.34,.32),c("8fff5a"))
			m.ball(Vector3(-.08,1.6,-.13),Vector3(.11,.14,.06),INK,CartoonMesh.BODY,0.0,Vector2(0,1),false,Vector3(0,0,-.3));m.ball(Vector3(.08,1.6,-.13),Vector3(.11,.14,.06),INK,CartoonMesh.BODY,0.0,Vector2(0,1),false,Vector3(0,0,.3))
			m.antenna(Vector3(0,1.72,0),Vector3(0,1.86,.05),.04,c("8fff5a"),c("ff4fd8"))
			m.spike(Vector3(0,.74,0),Vector3(0,.56,0),.2,c("ffe34a"))
			return hull
		24:  # Glowworm Zip: a glowing glass orb with six eyes, wings and a trailing tail.
			var body=c("ff4fd8")
			m.core(Vector3(0,.7,0),.3)
			m.ball(Vector3(0,.96,0),Vector3(.3,.12,.28),body)
			for p in [Vector3(-.12,.98,-.1),Vector3(0,1.0,-.12),Vector3(.12,.98,-.1)]: m.eye(p,.045)
			m.wings(Vector3(0,.88,.05),.45,.25,c("ffd0f5"),c("c03fa0"),.4)
			for i in range(5): m.ball(Vector3(0,.68-i*.02,.32+i*.15),Vector3.ONE*(.2-i*.03),c("ffa0ec"),CartoonMesh.TAIL,0.0,Vector2(.75,1),true)
			m.grin(Vector3(0,.42,-.2),.18,.06,3,false)
			return body
		25:  # Ram Moonbeast: a big glass orb wrapped in fluffy wool, a dark three-eyed face.
			var wool=c("f4f6ff");var face=c("2a2340")
			m.core(Vector3(0,1.12,.1),.6)
			for p in [Vector3(-.6,1.4,.2),Vector3(.6,1.4,.15),Vector3(-.55,.95,.1),Vector3(.55,.95,.05),Vector3(0,1.72,.1),Vector3(-.35,1.65,.35),Vector3(.35,1.65,.4)]: m.ball(p,Vector3.ONE*.55,wool)
			m.ball(Vector3(0,1.2,-.75),Vector3(.72,.78,.55),face)
			m.eye(Vector3(-.17,1.35,-1.0),.09,FRONT,c("fff27d"),CartoonMesh.BODY,0.0,Vector2(0,1),true);m.eye(Vector3(.17,1.35,-1.0),.09,FRONT,c("fff27d"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.eye(Vector3(0,1.5,-.97),.07,FRONT,c("fff27d"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.grin(Vector3(0,1.0,-1.0),.42,.14,5)
			for s in [-1.0,1.0]:
				for i in range(5):
					var a=i*.9;m.ball(Vector3(s*(.42+.22*sin(a)),1.55+.25*cos(a)-.1*i,-.6+.08*i),Vector3.ONE*(.28-i*.03),c("ffb84a"))
			m.legs([Vector3(-.45,.6,-.45),Vector3(.45,.6,-.45),Vector3(-.45,.6,.6),Vector3(.45,.6,.6)],.4,.14,face,INK)
			return wool
		26:  # The Watcher Stack: a totem of three heads; the middle one is a big glass orb with eyes.
			var low=c("ff6b6b");var top=c("6bd5ff")
			m.ball(Vector3(0,.75,0),Vector3(1.0,.9,.9),low);m.grin(Vector3(0,.68,-.42),.55,.2,6)
			m.core(Vector3(0,1.55,0),.44)
			for x in [-.2,0.0,.2]: m.eye(Vector3(x,1.68,-.38),.08,Vector3(x,0,-1),c("ff3b3b"))
			m.ring(Vector3(0,1.55,0),.45,.06,c("ffd84a"))
			m.ball(Vector3(0,2.25,0),Vector3(.7,.65,.65),top);m.eye(Vector3(0,2.3,-.3),.16,FRONT,c("6b2bff"))
			m.antenna(Vector3(0,2.55,0),Vector3(-.1,2.85,.05),.06,top,c("fff27d"))
			for s in [-1.0,1.0]:
				m.rod(Vector3(s*.48,.85,0),Vector3(s*.8,1.1,-.25),.07,low,CartoonMesh.TAIL,.2,Vector2(.85,.6));m.ball(Vector3(s*.84,1.14,-.28),Vector3.ONE*.18,low,CartoonMesh.TAIL,.2,Vector2(.85,.6))
			m.legs([Vector3(-.25,.35,0),Vector3(.25,.35,0)],.25,.1,low,c("a83a3a"))
			return c("ffd84a")
		30:  # Sunpuff: a glass orb in a ring of grumpy yellow cloud puffs.
			var body=c("ffcf2a")
			m.core(Vector3(0,.85,0),.42)
			for p in [Vector3(-.48,.95,0),Vector3(.48,.95,0),Vector3(0,1.3,0),Vector3(-.35,1.2,.05),Vector3(.35,1.2,.05),Vector3(-.4,.6,0),Vector3(.4,.6,0)]: m.ball(p,Vector3.ONE*.42,body)
			for s in [-1.0,1.0]:
				m.eye(Vector3(s*.16,1.2,-.34),.09,FRONT,c("ff5a1f"));m.box(Vector3(s*.16,1.32,-.37),Vector3(.18,.05,.05),INK,CartoonMesh.BODY,Vector3(0,0,s*.45))
				m.ball(Vector3(s*.42,.9,-.25),Vector3.ONE*.26,c("ff9a3c"))
			m.grin(Vector3(0,1.08,-.38),.26,.08,4,false)
			m.wings(Vector3(0,.95,.35),.45,.3,c("fff6c9"),c("e0a82a"),.3)
			return body
		31:  # Beakface: a violet-ringed glass orb with a huge beak and one eye on a stalk.
			var body=c("8f5cff")
			m.core(Vector3(0,.75,0),.42)
			m.ring(Vector3(0,.75,0),.43,.07,body);m.ball(Vector3(0,1.1,0),Vector3(.5,.16,.45),body)
			m.spike(Vector3(0,.8,-.38),Vector3(0,.7,-1.05),.17,c("ffa22a"));m.spike(Vector3(0,.7,-.36),Vector3(0,.62,-.85),.12,c("e07a12"),CartoonMesh.JAW)
			m.stalk_eye(Vector3(0,1.15,-.05),Vector3(0,1.45,-.1),.17,body,FRONT,c("2adfff"),.4)
			m.wings(Vector3(0,.85,.05),.85,.5,c("b89cff"),c("5c34c9"))
			for i in range(3): m.spike(Vector3((i-1)*.1,.85,.4),Vector3((i-1)*.25,1.15,.67),.06,c("ffa22a"))
			return body
		32:  # Snowslug Gus: a pink slug; its middle is a big glass orb ridged with ice spikes.
			var body=c("ff7ab0")
			m.rod(Vector3(0,.34,.95),Vector3(0,.38,.45),.32,body);m.core(Vector3(0,.48,.05),.45)
			m.ball(Vector3(0,.62,-.65),Vector3(.75,.72,.68),body)
			for z in [-.1,.1,.3]: m.spike(Vector3(0,.88,z),Vector3(0,1.15,z+.05),.08,c("9fe9ff"))
			for z in [.6,.85]: m.spike(Vector3(0,.62,z),Vector3(0,.88,z+.05),.08,c("9fe9ff"))
			m.stalk_eye(Vector3(-.15,.92,-.72),Vector3(-.25,1.32,-.82),.11,body,FRONT,c("3b7dff"),.2)
			m.stalk_eye(Vector3(.15,.92,-.72),Vector3(.25,1.32,-.82),.11,body,Vector3(.3,0,-1),c("3b7dff"),.7)
			m.grin(Vector3(0,.52,-.98),.42,.18,4)
			return body
		33:  # Jellyfloat: a glass orb jellyfish with a face, a frilled rim and glowing tentacle tips.
			var body=c("ff4fb0")
			m.core(Vector3(0,1.15,0),.52)
			for i in range(10): m.ball(Vector3(cos(i*TAU/10),0,sin(i*TAU/10))*.5+Vector3(0,.8,0),Vector3.ONE*.18,c("ff8fcf"))
			m.ball(Vector3(0,1.62,0),Vector3(.36,.14,.36),body)
			m.tentacles(7,Vector3(0,.76,0),.32,.65,.06,c("ffb0dc"),c("fff27d"))
			m.eye(Vector3(-.2,1.32,-.46),.1,FRONT,c("3b2bff"));m.eye(Vector3(.2,1.32,-.46),.1,FRONT,c("3b2bff"))
			m.grin(Vector3(0,1.08,-.5),.28,.1,3,false)
			return body
		34:  # Kitebat: a red diamond kite frame around a glass orb, with a bow-knot tail.
			var body=c("ff3b3b")
			m.core(Vector3(0,.75,0),.24)
			var tips=[Vector3(0,1.15,0),Vector3(.38,.75,0),Vector3(0,.3,0),Vector3(-.38,.75,0)]
			for i in range(4): m.rod(tips[i],tips[(i+1)%4],.04,body)
			m.rod(tips[0],tips[2],.025,c("ffe14a"));m.rod(tips[1],tips[3],.025,c("ffe14a"))
			m.eye(Vector3(-.08,.85,-.2),.06);m.eye(Vector3(.08,.85,-.2),.06)
			m.grin(Vector3(0,.68,-.21),.16,.05,3,false,.2)
			for i in range(6): m.ball(Vector3(0,.25-i*.03,.05+i*.12),Vector3(.16,.08,.08),c("ffe14a") if i%2==0 else c("3b7dff"),CartoonMesh.TAIL,0.0,Vector2(.45,1))
			m.wings(Vector3(0,.75,.05),.5,.2,c("ffb0b0"),c("c02a2a"),.3)
			return body
		35:  # Wurmo: a rearing orange worm; its fattest segment is a big glass orb.
			var body=c("ff8a2b");var band=c("ffb35a")
			m.ball(Vector3(0,.4,1.25),Vector3.ONE*.7,body);m.ball(Vector3(0,.55,.65),Vector3.ONE*.82,band)
			m.core(Vector3(0,.92,.02),.48)
			for z in [-.42,.46]: m.ball(Vector3(0,.92,.02+z),Vector3(.78,.78,.16),band)
			m.ball(Vector3(0,1.38,-.48),Vector3.ONE*.9,band)
			m.ball(Vector3(0,1.78,-.8),Vector3.ONE*1.05,body)
			m.ring(Vector3(0,1.72,-1.28),.3,.17,c("ff4f6a"),Vector3(PI*.5,0,0));m.ball(Vector3(0,1.72,-1.24),Vector3(.48,.48,.15),MOUTH)
			for i in range(8): var o=Vector3(cos(i*TAU/8),sin(i*TAU/8),0);m.spike(Vector3(0,1.72,-1.3)+o*.22,Vector3(0,1.72,-1.33)+o*.09,.04,TOOTH)
			m.eye(Vector3(-.22,2.16,-.98),.09,FRONT,c("1f9aff"));m.eye(Vector3(.22,2.16,-.98),.09,FRONT,c("1f9aff"))
			for p in [Vector3(0,.08,1.25),Vector3(0,.16,.65)]:
				for s in [-1.0,1.0]: m.ball(p+Vector3(s*.25,0,0),Vector3(.15,.12,.2),c("c25a1a"))
			return body
		36:  # Stilt Strider: a glass orb body on four long stilts, a beak and stalk eyes.
			var body=c("ffd23f")
			m.core(Vector3(0,1.35,0),.3)
			m.ball(Vector3(0,1.6,0),Vector3(.4,.14,.36),body);m.ring(Vector3(0,1.35,0),.31,.05,c("ff9a3c"))
			m.spider_legs(4,Vector3(0,1.2,0),.7,.35,.045,c("ff9a3c"))
			m.spike(Vector3(0,1.4,-.28),Vector3(0,1.3,-.72),.1,c("ff5a1f"))
			m.stalk_eye(Vector3(-.12,1.62,-.05),Vector3(-.25,1.9,-.1),.1,body,FRONT,c("3b7dff"),.3)
			m.stalk_eye(Vector3(.12,1.62,-.05),Vector3(.25,1.9,-.1),.1,body,Vector3(.3,.1,-1),c("3b7dff"),.8)
			for i in range(3): m.spike(Vector3((i-1)*.08,1.42,.28),Vector3((i-1)*.2,1.62,.55),.05,c("ff5a1f"))
			return body
		40:  # Gumdrop Goon: a teal sugar-dusted gumdrop cap on a glass orb belly.
			var body=c("2fe0c8")
			m.core(Vector3(0,.52,0),.42)
			m.spike(Vector3(0,.86,0),Vector3(0,1.42,0),.42,body);m.spots(Vector3(0,1.08,0),Vector3(.26,.26,.26),c("ffffff"),10,.06,40)
			m.eye(Vector3(-.13,1.04,-.24),.1);m.eye(Vector3(.13,1.02,-.25),.075,Vector3(.4,0,-1))
			m.grin(Vector3(0,.9,-.34),.4,.12,5)
			m.ball(Vector3(0,.14,0),Vector3(.6,.12,.55),body)
			m.legs([Vector3(-.2,.14,0),Vector3(.2,.14,0)],.08,.1,body,c("1a8a7a"))
			return body
		41:  # Taffy Snapper: a mint crocodile whose belly is a big glass orb.
			var body=c("7dffb0")
			m.core(Vector3(0,.48,.2),.4)
			m.ball(Vector3(0,.5,-.62),Vector3(.55,.35,.9),body)
			for i in range(5):
				for s in [-1.0,1.0]: m.spike(Vector3(s*.22,.42,-.35-i*.15),Vector3(s*.22,.33,-.35-i*.15),.03,TOOTH)
			m.ball(Vector3(0,.34,-.62),Vector3(.5,.15,.85),c("4fd68a"),CartoonMesh.JAW)
			m.eye(Vector3(-.15,.72,-.38),.1,FRONT,c("ffd23f"));m.eye(Vector3(.15,.72,-.38),.1,FRONT,c("ffd23f"))
			for i in range(4): m.ball(Vector3(0,.42-i*.03,.7+i*.25),Vector3.ONE*(.4-i*.08),body,CartoonMesh.TAIL,0.0,Vector2(.6,1))
			m.legs([Vector3(-.3,.3,-.15),Vector3(.3,.3,-.15),Vector3(-.3,.3,.5),Vector3(.3,.3,.5)],.17,.08,body,c("3aa86a"))
			return body
		42:  # Jawbreaker Joe: the jawbreaker is the glass orb itself, striped, with a tiny face.
			var body=c("f8f4ff")
			m.core(Vector3(0,.95,0),.78)
			m.ring(Vector3(0,.95,0),.79,.08,c("3b7dff"),Vector3(0,0,.3));m.ring(Vector3(0,.95,0),.79,.08,c("ff4fd8"),Vector3(0,0,-.5));m.ring(Vector3(0,.95,0),.79,.08,c("4fff7a"),Vector3(PI*.5,.6,0))
			m.eye(Vector3(-.16,1.2,-.73),.09);m.eye(Vector3(.16,1.2,-.73),.09)
			for i in range(4): m.box(Vector3(-.09+i*.06,.98+(.02 if i%2==0 else -.02),-.77),Vector3(.07,.02,.02),INK,CartoonMesh.BODY,Vector3(0,0,.6 if i%2==0 else -.6))
			m.legs([Vector3(-.35,.25,-.3),Vector3(.35,.25,-.3),Vector3(-.35,.25,.3),Vector3(.35,.25,.3)],.12,.1,body,c("c9c4e0"))
			return body
		43:  # Lollipop Larry: a swirl-ringed glass orb lollipop on a stick, one eye in the middle.
			var head=c("3bd6ff")
			m.rod(Vector3(0,.3,0),Vector3(0,.8,0),.1,c("ffffff"));m.core(Vector3(0,1.25,0),.46)
			m.ring(Vector3(0,1.25,0),.47,.08,head,Vector3(PI*.5,0,0));m.ring(Vector3(0,1.25,0),.47,.06,c("ffe14a"),Vector3(PI*.5,.8,0))
			m.eye(Vector3(0,1.3,-.44),.12,FRONT,c("ff3b3b"))
			m.grin(Vector3(0,1.07,-.43),.26,.08,4,false,.4)
			for s in [-1.0,1.0]: m.rod(Vector3(s*.08,.7,0),Vector3(s*.4,.92,-.15),.04,c("ffffff"),CartoonMesh.TAIL,.3,Vector2(.7,.6))
			m.legs([Vector3(-.12,.3,0),Vector3(.12,.3,0)],.2,.07,c("ffffff"),head)
			return head
		44:  # Frostfly: a cyan fly whose body is a glass orb, with two huge glossy eyes.
			var body=c("3bf0ff")
			m.core(Vector3(0,.7,.06),.27)
			m.ball(Vector3(0,.78,-.24),Vector3(.32,.26,.24),body)
			for s in [-1.0,1.0]:
				m.ball(Vector3(s*.15,.84,-.32),Vector3.ONE*.24,c("6b2bff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.spike(Vector3(s*.05,.7,-.36),Vector3(s*.03,.56,-.5),.03,INK)
				for z in [-.1,.08,.25]: m.rod(Vector3(s*.12,.55,z),Vector3(s*.3,.25,z*1.3),.02,INK,CartoonMesh.LEG,z+.5,Vector2(.6,.5))
			m.wings(Vector3(0,.92,.05),.6,.3,c("e8fbff"),c("6fd0e0"),.35)
			return body
		45:  # Bubblegut: a huge glass gut seen through its lips, a tiny head on top.
			var body=c("b46bff")
			m.core(Vector3(0,1.0,0),.8)
			m.ring(Vector3(0,1.0,-.55),.45,.18,c("ff3b6b"),Vector3(PI*.5,0,0))
			for i in range(10):
				var a=i*TAU/10;var o=Vector3(cos(a),sin(a),0)
				m.spike(Vector3(0,1.0,-.62)+o*.4,Vector3(0,1.0,-.66)+o*.28,.04,TOOTH)
			m.ball(Vector3(0,1.85,0),Vector3(.62,.24,.6),body);m.ball(Vector3(0,2.05,-.05),Vector3(.45,.42,.42),c("c99bff"))
			m.eye(Vector3(-.09,2.1,-.24),.065);m.eye(Vector3(.09,2.1,-.24),.065,Vector3(.4,0,-1))
			for s in [-1.0,1.0]:
				m.rod(Vector3(s*.75,1.35,0),Vector3(s*1.2,1.7,-.25),.1,body,CartoonMesh.TAIL,.25,Vector2(1.35,.5));m.ball(Vector3(s*1.25,1.76,-.27),Vector3.ONE*.24,c("c99bff"),CartoonMesh.TAIL,.25,Vector2(1.35,.5))
			m.ball(Vector3(0,.22,0),Vector3(1.0,.2,.9),body)
			m.legs([Vector3(-.4,.25,0),Vector3(.4,.25,0)],.18,.18,body,c("6b3bb0"))
			return body
		46:  # Cinder Grinner: a blue beanpole with a glass orb torso and a grin wider than its head.
			var body=c("4f5bff")
			m.rod(Vector3(0,.62,0),Vector3(0,.72,0),.14,body);m.core(Vector3(0,.98,0),.28);m.ball(Vector3(0,1.28,0),Vector3(.42,.14,.34),body)
			m.ball(Vector3(0,1.6,0),Vector3(.6,.55,.55),body)
			m.grin(Vector3(0,1.55,-.3),.9,.32,9,false,.15)
			for s in [-1.0,1.0]:
				m.ball(Vector3(s*.15,1.82,-.25),Vector3(.16,.1,.08),c("ffef5a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.rod(Vector3(s*.2,1.26,0),Vector3(s*.45,.8,-.1),.04,body,CartoonMesh.TAIL,.3,Vector2(1.25,.6))
			m.legs([Vector3(-.1,.62,0),Vector3(.1,.62,0)],.52,.05,body,c("2a2fa0"))
			return body
		50:  # Brainy Blorp: a giant brain on a glass orb body with tentacle feet.
			var brain=c("ff8fc0")
			m.core(Vector3(0,.45,0),.36)
			m.ball(Vector3(0,.95,0),Vector3(.95,.66,.85),brain)
			for p in [Vector3(-.25,1.15,-.1),Vector3(.25,1.15,-.1),Vector3(-.3,1.05,.25),Vector3(.3,1.05,.25),Vector3(0,1.25,.1),Vector3(-.15,1.2,.35),Vector3(.15,1.22,-.25),Vector3(0,1.1,-.3)]: m.ball(p,Vector3(.38,.26,.38),c("ff6fae"))
			m.eye(Vector3(-.17,.82,-.38),.08);m.eye(Vector3(.17,.82,-.38),.08);m.eye(Vector3(0,.88,-.42),.1,FRONT,c("ff3b3b"))
			m.grin(Vector3(0,.68,-.36),.28,.08,3,false)
			m.tentacles(4,Vector3(0,.14,0),.22,.16,.07,c("3ad6a8"))
			return brain
		51:  # Orbitopus: a floating octopus whose head is a big glass orb.
			var body=c("ff8a2b")
			m.core(Vector3(0,.95,0),.5)
			m.ball(Vector3(0,1.42,0),Vector3(.45,.16,.42),body);m.ball(Vector3(0,.5,0),Vector3(.7,.2,.65),body)
			m.eye(Vector3(-.18,.98,-.45),.12,FRONT,c("2adfff"));m.eye(Vector3(.18,.98,-.45),.12,FRONT,c("2adfff"))
			m.spike(Vector3(0,.78,-.46),Vector3(0,.7,-.6),.05,INK)
			m.tentacles(8,Vector3(0,.45,0),.3,.55,.07,c("ffb35a"),c("ff5a1f"))
			return body
		52:  # Ringthing: a little planet that is one big glass orb, with a ring and two moons.
			var body=c("ffd23f")
			m.core(Vector3(0,1.0,0),.62)
			m.ring(Vector3(0,1.0,0),.95,.12,c("ff6bd5"),Vector3(.35,0,.2))
			m.eye(Vector3(-.2,1.18,-.56),.12);m.eye(Vector3(.2,1.18,-.56),.1,Vector3(.3,0,-1))
			m.grin(Vector3(0,.9,-.6),.4,.14,5)
			m.ball(Vector3(-.95,1.45,.2),Vector3.ONE*.2,c("c9c9ff"));m.ball(Vector3(.9,.6,-.2),Vector3.ONE*.15,c("c9c9ff"))
			return body
		53:  # Mantoid Zap: a green mantis whose abdomen is a big glass orb.
			var body=c("6bff5a")
			m.rod(Vector3(0,.62,.2),Vector3(0,1.1,-.1),.14,body);m.core(Vector3(0,.58,.55),.32)
			m.ball(Vector3(0,1.3,-.2),Vector3(.55,.35,.35),body)
			for s in [-1.0,1.0]:
				m.ball(Vector3(s*.25,1.35,-.25),Vector3.ONE*.2,c("ff3bf0"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.rod(Vector3(s*.12,1.05,-.2),Vector3(s*.2,.85,-.55),.05,body,CartoonMesh.JAW);m.spike(Vector3(s*.2,.85,-.55),Vector3(s*.18,1.15,-.8),.05,c("c9ff9a"),CartoonMesh.JAW)
				m.antenna(Vector3(s*.08,1.45,-.25),Vector3(s*.25,1.75,-.4),.03,body,c("c9ff9a"),.3)
			m.spider_legs(4,Vector3(0,.62,.2),.6,.25,.03,c("3ab82a"))
			return body
		54:  # Twinkle Tick: a little five-pointed star around a glass orb, one eye on top.
			var body=c("ffe14a")
			m.core(Vector3(0,.7,0),.24)
			for i in range(5):
				var a=PI*.5+i*TAU/5;var o=Vector3(cos(a),sin(a),0)
				m.spike(Vector3(0,.7,0)+o*.2,Vector3(0,.7,0)+o*.52,.12,body,CartoonMesh.WING,0.0,Vector2(.1,.4))
			m.eye(Vector3(0,.98,-.1),.09,FRONT,c("7a3bff"))
			return body
		55:  # Crabzilla Jr.: a big cyan crab whose shell is a glass orb in a wide rim.
			var body=c("3bd6ff")
			m.core(Vector3(0,1.02,0),.58)
			m.ring(Vector3(0,.95,0),.68,.22,body)
			for s in [-1.0,1.0]:
				m.rod(Vector3(s*.75,.95,-.35),Vector3(s*1.1,1.2,-.9),.12,body,CartoonMesh.JAW)
				m.ball(Vector3(s*1.15,1.3,-1.1),Vector3(.6,.4,.5),body,CartoonMesh.JAW);m.spike(Vector3(s*1.15,1.45,-1.3),Vector3(s*1.12,1.5,-1.65),.12,c("2a9ac0"),CartoonMesh.JAW)
				m.stalk_eye(Vector3(s*.25,1.5,-.42),Vector3(s*.35,1.92,-.52),.12,body,FRONT,c("ff3b3b"),.3+s*.2)
			m.grin(Vector3(0,.9,-.68),.5,.16,6)
			m.spider_legs(6,Vector3(0,.9,0),1.1,.3,.07,c("2a9ac0"))
			return body
		56:  # Antenna Annie: an orange-ringed glass orb spider with a dish for a head.
			var body=c("ff6b3b")
			m.core(Vector3(0,1.3,.05),.46)
			m.ring(Vector3(0,1.3,.05),.47,.08,body);m.ball(Vector3(0,1.72,.05),Vector3(.4,.14,.4),body)
			m.ball(Vector3(0,1.5,-.48),Vector3(.7,.7,.12),c("e8e8f8"),CartoonMesh.BODY,0.0,Vector2(0,1),false,Vector3(.3,0,0))
			m.antenna(Vector3(0,1.5,-.5),Vector3(0,1.54,-.78),.05,c("b9b9c9"),c("7dff6a"))
			for p in [Vector3(-.12,1.56,-.55),Vector3(.12,1.56,-.55),Vector3(-.16,1.42,-.56),Vector3(.16,1.42,-.56),Vector3(0,1.36,-.58)]: m.eye(p,.05,FRONT,c("ff2b2b"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.antenna(Vector3(0,1.76,.1),Vector3(.1,2.1,.2),.06,body,c("7dff6a"),.5)
			m.spider_legs(8,Vector3(0,1.2,.05),1.2,.45,.05,c("c94a2a"))
			return body
		7:  # Melty Mel: a shambler whose torso is a big glass orb, face melting off its head.
			var skin=c("ffb3a0");var shirt=c("2fd3b8")
			var chest=Vector3(0,1.15,-.05)
			m.core(chest,.34)
			m.legs([Vector3(-.14,.82,0),Vector3(.14,.82,0)],.68,.11,c("3b4a8a"),c("2a2340"))
			m.ball(Vector3(0,.86,0),Vector3(.5,.26,.36),c("3b4a8a"))
			m.ball(chest+Vector3(0,.33,0),Vector3(.72,.18,.42),shirt);m.ring(chest,.35,.05,shirt)
			for side in [-1.0,1.0]:
				var shoulder=chest+Vector3(side*.36,.24,0);var hand=shoulder+Vector3(side*.12,-.55,-.15)
				m.rod(shoulder,hand,.085,shirt,CartoonMesh.LEG,.5 if side>0 else 0.0,Vector2(shoulder.y,.5));m.ball(hand,Vector3.ONE*.18,skin,CartoonMesh.LEG,.5 if side>0 else 0.0,Vector2(shoulder.y,.5))
			var head=chest+Vector3(0,.66,-.05)
			m.rod(chest+Vector3(0,.38,0),head,.07,skin);m.ball(head,Vector3(.44,.5,.42),skin)
			m.eye(head+Vector3(-.1,-.08,-.19),.07,Vector3(-.3,-.3,-1));m.eye(head+Vector3(.09,-.16,-.19),.08,Vector3(.4,.2,-1))
			m.grin(head+Vector3(0,-.27,-.12),.2,.08,4,false)
			for i in range(4): m.ball(head+Vector3(-.12+i*.08,-.34-float(i%2)*.08,-.1),Vector3(.07,.16,.07),skin,CartoonMesh.TAIL,.2*i,Vector2(head.y,.6))
			return skin
		8:  # Two-Torso Terry: two upper bodies fused at a big glass orb, on one pair of legs.
			var skin=c("ffd27a");var shirt=c("ff5f9e");var pants=c("6b3bb0")
			m.legs([Vector3(-.16,.82,0),Vector3(.16,.82,0)],.7,.1,pants,c("2a2340"))
			m.ball(Vector3(0,.86,0),Vector3(.55,.24,.38),pants)
			m.core(Vector3(0,1.15,0),.32)
			for s in [-1.0,1.0]:
				var tilt=Vector3(s*.32,0,0);var chest=Vector3(s*.3,1.45,0)+tilt*.6;var head=Vector3(s*.52,1.85,0)+tilt*.5
				m.rod(Vector3(s*.18,1.35,0),chest,.17,shirt);m.ball(chest,Vector3(.36,.4,.3),shirt)
				m.rod(chest+Vector3(s*.05,.18,0),head,.06,skin);m.ball(head,Vector3(.3,.33,.3),skin)
				m.eye(head+Vector3(-.06,.03,-.14),.045);m.eye(head+Vector3(.06,.03,-.14),.045,Vector3(s*.5,0,-1))
				m.grin(head+Vector3(0,-.08,-.13),.13,.05,3,false,.3)
				for arm in [chest+Vector3(s*.18,.1,0),chest+Vector3(-s*.14,.12,-.05)]:
					var hand=arm+Vector3(s*.25,-.42,-.08);var pivot=Vector2(arm.y,.5)
					m.rod(arm,hand,.06,shirt,CartoonMesh.LEG,.5 if s>0 else 0.0,pivot);m.ball(hand,Vector3.ONE*.14,skin,CartoonMesh.LEG,.5 if s>0 else 0.0,pivot)
			return shirt
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
			m.orb=a.chest+Vector3(0,-.12,-.36);m.orb_radius=.11;return skin
		19:  # Spore Sneezer: a woman with a trunk of a nose that sprays spores.
			var skin=c("ffb3c7");var a=person(m,skin,c("8fff5a"),c("3b2bff"),c("2a2340"),{"no_face":true})
			var nose=a.head+Vector3(0,0,-.15)
			for i in range(5): m.ball(nose+Vector3(0,-.03*i,-.08*i),Vector3.ONE*(.14-i*.012),skin,CartoonMesh.TAIL,0.0,Vector2(a.head.y+.1,.4))
			m.ball(nose+Vector3(0,-.13,-.4),Vector3(.12,.12,.05),CartoonMesh.MOUTH)
			m.eye(a.head+Vector3(-.08,.07,-.14),.05);m.eye(a.head+Vector3(.08,.07,-.14),.05)
			for s in [-1.0,1.0]: m.ball(a.head+Vector3(s*.12,-.04,-.1),Vector3.ONE*.12,c("ff6fae"))
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
		37:  # Leggy Lou: walks on its hands, legs flailing overhead, a glass orb belly with a face.
			var skin=c("ffd23f");var pants=c("ff7ab0")
			m.legs([Vector3(-.2,.75,-.05),Vector3(.2,.75,-.05)],.65,.07,skin,skin)
			m.core(Vector3(0,1.05,0),.33);m.ball(Vector3(0,1.42,0),Vector3(.46,.3,.32),pants);m.ball(Vector3(0,.7,0),Vector3(.26,.2,.24),skin)
			for s in [-1.0,1.0]:
				var hip=Vector3(s*.13,1.5,0);var foot=hip+Vector3(s*.25,.6,.15)
				m.rod(hip,foot,.08,pants,CartoonMesh.STALK,.5 if s>0 else 0.0,Vector2(1.5,1.6));m.ball(foot+Vector3(0,.06,-.05),Vector3(.14,.12,.24),c("2a2340"),CartoonMesh.STALK,.5 if s>0 else 0.0,Vector2(1.5,1.6))
			m.eye(Vector3(-.11,1.15,-.3),.07);m.eye(Vector3(.11,1.15,-.3),.07,Vector3(.3,0,-1));m.grin(Vector3(0,.95,-.3),.22,.08,5)
			return c("8f5cff")
		38:  # Puffer Pete: a man blown up into a big spiky glass orb, tiny limbs and head.
			var skin=c("ffb07a");var spike_c=c("fff1cf")
			m.legs([Vector3(-.15,.45,0),Vector3(.15,.45,0)],.32,.07,c("2a2340"),c("2a2340"))
			m.core(Vector3(0,1.05,0),.6)
			for i in range(10):
				var d=Vector3(cos(i*2.4),sin(i*1.7)*.8,sin(i*2.4)).normalized()
				m.spike(Vector3(0,1.05,0)+d*.58,Vector3(0,1.05,0)+d*.82,.06,spike_c)
			m.ball(Vector3(0,1.78,-.05),Vector3(.3,.32,.3),skin);m.eye(Vector3(-.06,1.8,-.19),.045);m.eye(Vector3(.06,1.8,-.19),.045)
			m.ball(Vector3(0,1.71,-.19),Vector3(.08,.08,.04),MOUTH)
			for s in [-1.0,1.0]: m.rod(Vector3(s*.58,1.15,0),Vector3(s*.8,1.0,-.1),.05,skin,CartoonMesh.LEG,.5 if s>0 else 0.0,Vector2(1.15,.5))
			return c("3bf0ff")
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
		48:  # Fistbody Frank: a big glass orb torso with six arms ending in fists, a tiny head.
			var skin=c("6b9bff");var a=person(m,skin,c("ffffff"),c("2a2340"),c("1a1a2a"),{"no_head":true,"no_arms":true,"fat":.8})
			m.ball(a.chest+Vector3(0,.55,-.05),Vector3(.24,.26,.24),skin);m.eye(a.chest+Vector3(-.05,.58,-.16),.035);m.eye(a.chest+Vector3(.05,.58,-.16),.035)
			for row in range(3):
				for s in [-1.0,1.0]:
					var shoulder=a.chest+Vector3(s*.4,.25-row*.2,0);var fist=shoulder+Vector3(s*.35,-.3,-.2-row*.05);var pivot=Vector2(shoulder.y,.5)
					m.rod(shoulder,fist,.07,skin,CartoonMesh.LEG,.33*row+(.5 if s>0 else 0.0),pivot);m.ball(fist,Vector3.ONE*.2,c("ffb3c7"),CartoonMesh.LEG,.33*row+(.5 if s>0 else 0.0),pivot)
			return skin
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
		# Junkyard Planet (biome 6, October 27): scrap-built critters in bright paint,
		# so they read against the rust-brown ground.
		60:  # Trashcan Stan: a dented teal bin whose middle is a glass orb; the lid is a toothy mouth.
			var tin=c("3fd0c9");var dark=c("23857f")
			m.core(Vector3(0,.72,0),.4)
			m.can(Vector3(0,.2,0),Vector3(0,.36,0),.46,tin);m.ring(Vector3(0,.72,0),.43,.06,dark);m.can(Vector3(0,1.06,0),Vector3(0,1.2,0),.46,tin)
			m.ball(Vector3(0,1.3,-.08),Vector3(1.0,.14,.95),dark,CartoonMesh.TAIL,0.0,Vector2(1.25,.6),false,Vector3(-.25,0,0))
			m.grin(Vector3(0,1.17,-.44),.62,.16,7)
			m.stalk_eye(Vector3(-.18,1.28,-.1),Vector3(-.28,1.6,-.2),.14,c("ff9a3c"),FRONT,c("2b2bff"),.2)
			m.stalk_eye(Vector3(.2,1.28,-.08),Vector3(.34,1.55,-.16),.11,c("ff9a3c"),Vector3(.4,0,-1),c("2b2bff"),.6)
			m.ball(Vector3(.3,1.38,.2),Vector3(.3,.08,.2),c("c9e85a"))  # a banana peel on the lid
			m.legs([Vector3(-.24,.2,-.15),Vector3(.24,.2,-.15),Vector3(0,.2,.25)],.16,.08,c("ff9a3c"),c("8a4a2a"))
			return tin
		61:  # Propeller Pidge: a flying glass orb with a rusty propeller cap, a beak and bolt eyes.
			var paint=c("ffcf3a")
			m.core(Vector3(0,.8,0),.34)
			m.ring(Vector3(0,.8,0),.36,.07,c("c4542a"))
			m.ball(Vector3(0,1.12,0),Vector3(.5,.18,.5),paint);m.rod(Vector3(0,1.2,0),Vector3(0,1.4,0),.04,c("5b5f63"))
			for i in range(3): m.box(Vector3(0,1.42,0)+Vector3(cos(i*TAU/3),0,sin(i*TAU/3))*.35,Vector3(.7,.03,.12),c("c4542a"),CartoonMesh.TAIL,Vector3(0,-i*TAU/3,.15))
			m.spike(Vector3(0,.82,-.32),Vector3(0,.76,-.62),.11,c("ff8a2b"))
			m.eye(Vector3(-.14,.98,-.26),.09,FRONT,c("5b5f63"));m.eye(Vector3(.14,.98,-.26),.08,Vector3(.3,0,-1),c("5b5f63"))
			m.wings(Vector3(0,.84,.05),.7,.45,c("9fe0ff"),c("4f7a8a"),.4)
			return paint
		62:  # Tank Tortoise: a riveted hull around a big glass orb, treads for legs, a periscope eye.
			var hull=c("6fd06a");var plate=c("3e8a3a")
			m.core(Vector3(0,.95,.1),.6)
			m.ring(Vector3(0,.62,.1),.62,.18,plate);m.ring(Vector3(0,.95,.1),.62,.06,hull,Vector3(PI*.5,0,0))
			for i in range(8): var d=Vector3(cos(i*TAU/8),0,sin(i*TAU/8));m.ball(Vector3(0,.62,.1)+d*.62,Vector3.ONE*.08,c("dfe3e6"))
			for s in [-1.0,1.0]: m.box(Vector3(s*.66,.28,.1),Vector3(.32,.36,1.5),c("2b2a2c"),CartoonMesh.LEG)
			m.ball(Vector3(0,.62,-.72),Vector3(.6,.5,.55),c("ffd23f"))
			m.eye(Vector3(-.12,.76,-.95),.08);m.eye(Vector3(.13,.74,-.96),.1,Vector3(.3,0,-1))
			m.grin(Vector3(0,.52,-.96),.3,.1,4,false)
			m.rod(Vector3(0,1.5,.1),Vector3(0,1.95,.1),.06,c("5b5f63"));m.eye(Vector3(0,2.0,0),.12,FRONT,c("ff3b3b"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			return hull
		63:  # Hose Nose: a glass orb on a tripod, a long ribbed hose snout ending in a brass nozzle.
			var body=c("ff7ab0")
			m.core(Vector3(0,.82,0),.36)
			m.ball(Vector3(0,1.22,0),Vector3(.62,.3,.56),body);m.ring(Vector3(0,.82,0),.38,.06,c("c4467e"))
			for i in range(6): m.ring(Vector3(0,1.15-i*.02,-.32-i*.1),.09,.04,c("4fd0ff") if i%2==0 else c("2b8ad6"),Vector3(PI*.5,0,0))
			m.can(Vector3(0,1.03,-.95),Vector3(0,1.0,-1.12),.08,c("e0b52f"))
			m.eye(Vector3(-.15,1.36,-.2),.1);m.eye(Vector3(.16,1.34,-.2),.08,Vector3(.4,0,-1))
			m.legs([Vector3(-.25,.5,-.15),Vector3(.25,.5,-.15),Vector3(0,.5,.28)],.42,.06,c("5b5f63"),c("2b2a2c"))
			return body
		64:  # Bolt Bug: a tiny buzzing glass orb on wire legs with spark-plug antennae.
			var shell=c("ff9a3c")
			m.core(Vector3(0,.62,0),.28)
			m.ball(Vector3(0,.86,0),Vector3(.44,.16,.4),shell);m.ring(Vector3(0,.62,0),.29,.05,c("2b2a2c"))
			for x in [-.12,.12]: m.eye(Vector3(x,.88,-.18),.07,FRONT,c("7dfffb"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.antenna(Vector3(-.1,.94,-.05),Vector3(-.22,1.2,-.12),.06,c("5b5f63"),c("b6ff3a"),.2);m.antenna(Vector3(.1,.94,-.05),Vector3(.22,1.2,-.12),.06,c("5b5f63"),c("b6ff3a"),.7)
			m.wings(Vector3(0,.84,.08),.45,.3,c("e6fbff"),c("9ab8c4"),.5)
			m.spider_legs(6,Vector3(0,.5,0),.42,.18,.025,c("5b5f63"))
			return shell
		65:  # Bulldozer Bruno: a huge glass-orb gut behind a dozer blade, an exhaust stack for a horn.
			var paint=c("ffd23f");var rust=c("b0552c")
			m.core(Vector3(0,.95,0),.6)
			m.ball(Vector3(0,1.6,.1),Vector3(1.3,.75,1.1),paint);m.ring(Vector3(0,.95,0),.61,.07,rust)
			m.box(Vector3(0,.55,-.82),Vector3(1.7,.7,.12),c("5b5f63"),CartoonMesh.BODY,Vector3(-.2,0,0))
			for s in [-1.0,1.0]: m.rod(Vector3(s*.55,.8,-.45),Vector3(s*.6,.6,-.78),.08,rust)
			m.can(Vector3(.35,1.9,.3),Vector3(.38,2.45,.3),.1,c("2b2a2c"));m.ball(Vector3(.38,2.55,.3),Vector3(.22,.14,.22),c("8f8f8f"),CartoonMesh.TAIL)
			m.eye(Vector3(-.22,1.82,-.42),.11,FRONT,c("ff3b3b"));m.eye(Vector3(.2,1.8,-.42),.1,FRONT,c("ff3b3b"))
			m.grin(Vector3(0,1.5,-.5),.7,.24,6)
			m.legs([Vector3(-.45,.4,0),Vector3(.45,.4,0)],.3,.22,rust,c("2b2a2c"))
			return paint
		66:  # Lamp Lurker: a tall bent street lamp whose lantern is the glass orb, one bulb eye.
			var pole=c("4fd0ff")
			m.core(Vector3(0,2.0,-.35),.3)
			m.rod(Vector3(0,.15,0),Vector3(0,1.6,.1),.09,pole);m.rod(Vector3(0,1.6,.1),Vector3(0,2.35,-.1),.08,pole)
			m.ring(Vector3(0,2.0,-.35),.31,.05,c("2b8ad6"));m.ball(Vector3(0,2.36,-.35),Vector3(.5,.16,.5),c("2b8ad6"))
			m.eye(Vector3(0,1.98,-.68),.12,FRONT,c("fff36a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.grin(Vector3(0,1.72,-.62),.3,.1,4,false)
			m.legs([Vector3(-.22,.25,0),Vector3(.22,.25,0)],.2,.08,pole,c("2b2a2c"))
			return pole
		67:  # Wrenchhand Wendy: a shambling mechanic whose hands are giant wrenches.
			var skin=c("ffb07a");var a=person(m,skin,c("3b7dff"),c("2a4a8a"),c("2a2340"),{"no_arms":true,"hunch":.2})
			for i in range(2):
				var tip=a.hands[i]+Vector3((-1.0 if i==0 else 1.0)*.05,-.05,-.12)
				m.rod(a.shoulders[i],tip,.075,c("3b7dff"),CartoonMesh.LEG,.5*float(i),Vector2(a.shoulders[i].y,.5))
				m.rod(tip,tip+Vector3(0,-.35,-.1),.06,c("c9ced6"),CartoonMesh.LEG,.5*float(i),Vector2(a.shoulders[i].y,.5))
				m.ring(tip+Vector3(0,-.42,-.12),.11,.05,c("c9ced6"),Vector3(PI*.5,0,0),CartoonMesh.LEG)
			m.ball(a.head+Vector3(0,.2,0),Vector3(.46,.12,.46),c("ff3b3b"))  # a red cap
			m.orb=a.chest+Vector3(0,0,-.2);m.orb_radius=.09;return c("3b7dff")
		68:  # Tire Torso Tony: two heads fused on one body, a giant tyre round the glass-orb belly.
			var skin=c("8fff5a");var a=person(m,skin,c("ff4fd8"),c("2a2340"),c("1a1a2a"),{"no_head":true,"fat":.5})
			m.ring(a.chest+Vector3(0,-.1,0),.52,.14,c("2b2a2c"))
			for s in [-1.0,1.0]:
				var head=a.neck+Vector3(s*.18,.22,0)
				m.ball(head,Vector3(.34,.38,.34),skin);m.eye(head+Vector3(-.05,.04,-.15),.045);m.eye(head+Vector3(.05,.04,-.15),.05,Vector3(s*.4,0,-1))
				m.grin(head+Vector3(0,-.09,-.15),.14,.05,3,false,.3)
			return c("ff4fd8")
		69:  # Battery Betty: a battery for a head that spits acid, a glowing terminal on top.
			var skin=c("ffe14a");var a=person(m,skin,c("b6ff3a"),c("2a2340"),c("2a2340"),{"no_head":true})
			var head=a.neck+Vector3(0,.3,0)
			m.can(head-Vector3(0,.2,0),head+Vector3(0,.2,0),.2,c("2e3a2e"));m.ring(head+Vector3(0,.12,0),.21,.05,c("c9a23a"))
			m.can(head+Vector3(0,.2,0),head+Vector3(0,.28,0),.07,c("b6ff3a"));m.ball(head+Vector3(0,.3,0),Vector3.ONE*.1,c("b6ff3a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			m.eye(head+Vector3(-.07,.03,-.19),.05);m.eye(head+Vector3(.07,.03,-.19),.05)
			m.grin(head+Vector3(0,-.09,-.19),.16,.06,4,false,.3)
			m.orb=a.chest+Vector3(0,0,-.2);m.orb_radius=.09;return c("b6ff3a")
	return Color.WHITE

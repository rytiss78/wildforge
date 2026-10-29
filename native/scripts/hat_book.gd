extends RefCounted
class_name HatBook

# Hats (user request, October 29): achievement rewards you wear. Each hat is
# unlocked by an achievement (any one of its list); the chosen hat sits on the
# hero's head in every run and co-op friends see it (pose "hat"). Nothing is
# stored apart from the choice: a hat is owned while its achievement is.

const HATS=[
	{"id":"party","name":"Party Hat","achievements":["WF_TRIPLE_WEAPON"],"how":"Full Hands: equip three different weapons"},
	{"id":"cone","name":"Traffic Cone","achievements":["WF_BUILD_ENGINEERING"],"how":"Union Approved: five engineering upgrades"},
	{"id":"propeller","name":"Propeller Cap","achievements":["WF_BUILD_MOBILITY"],"how":"Late For Everything: five mobility upgrades"},
	{"id":"chef","name":"Chef Hat","achievements":["WF_BUILD_VAMPIRIC"],"how":"Dinner Is Served: five vampiric upgrades"},
	{"id":"wizard","name":"Wizard Hat","achievements":["WF_BUILD_ARCANE"],"how":"Wizard Without A Hat: five arcane upgrades"},
	{"id":"viking","name":"Viking Helmet","achievements":["WF_BUILD_BERSERKER"],"how":"Bad Mood, Big Damage: five berserker upgrades"},
	{"id":"tophat","name":"Top Hat","achievements":["WF_BUILD_ECONOMY"],"how":"Financially Dangerous: five economy upgrades"},
	{"id":"cowboy","name":"Cowboy Hat","achievements":["WF_LONG_WALK"],"how":"Scenic Route: explore the outer edge of a world"},
	{"id":"pirate","name":"Pirate Hat","achievements":["WF_LEGENDARY"],"how":"Disco In A Box: reveal legendary treasure"},
	{"id":"goggles","name":"Lab Goggles","achievements":["WF_reaction"],"how":"Questionable Chemistry: trigger an elemental reaction"},
	{"id":"halo","name":"Halo","achievements":["WF_rescue"],"how":"Helping Hand: rescue a downed party member"},
	{"id":"crown","name":"Crown","achievements":["WF_NO_HIT_BOSS"],"how":"Not A Scratch: beat a boss without losing health"},
	{"id":"noggin","name":"Little Noggin","achievements":["WF_WIN_WRENCH","WF_WIN_DUCK","WF_WIN_BROCCOLI","WF_WIN_GRANDMA","WF_WIN_GOBLIN","WF_WIN_LOAF","WF_WIN_FLORIST"],"how":"Win a run with any of the first seven heroes"},
]

static func entry(id: String) -> Dictionary:
	for hat in HATS:
		if hat.id==id: return hat
	return {}

static func owned(unlocked: Dictionary,id: String) -> bool:
	var hat=entry(id)
	return not hat.is_empty() and hat.achievements.any(func(a):return unlocked.has(a))

# Hats unlocked by this achievement (for the unlock toast).
static func unlocked_by(achievement_id: String) -> Array:
	return HATS.filter(func(h):return h.achievements.has(achievement_id))

# Puts the hat on a hero rig (or takes it off for ""). It sits on the top of the
# Head joint, sized to the head; a model without a head wears it on top.
static func wear(rig: Node3D,id: String):
	if not is_instance_valid(rig): return
	var old=rig.find_child("Hat",true,false)
	if old!=null: old.get_parent().remove_child(old);old.queue_free()
	if entry(id).is_empty(): return
	var head: Node3D=rig.find_child("Head",true,false)
	var mount: Node3D=head if head!=null else rig
	var box=bounds(mount)
	if box.size==Vector3.ZERO: box=AABB(Vector3(-.25,0,-.25),Vector3(.5,1.7,.5))
	var hat=build(id);hat.name="Hat";mount.add_child(hat)
	var width=maxf(.2,minf(box.size.x,box.size.z))
	hat.position=Vector3(box.get_center().x,box.end.y-width*.12,box.get_center().z)
	hat.scale=Vector3.ONE*clampf(width/.5,.4,2.5)

# The head's meshes in the mount's own space.
static func bounds(mount: Node3D) -> AABB:
	var box=AABB();var first=true
	for node in mount.find_children("*","MeshInstance3D",true,false):
		if node.name=="GlassCore": continue
		var local=mount.global_transform.affine_inverse()*node.global_transform*node.get_aabb()
		box=local if first else box.merge(local);first=false
	return box

# Each hat sized for a head about 0.5 m wide, its brim at y=0.
static func build(id: String) -> Node3D:
	var scene=CartoonScene.new();var m=scene.paint(scene.body)
	match id:
		"party":
			m.rod(Vector3(0,0,0),Vector3(0,.42,0),.17,Color("ff4fa3"));m.ball(Vector3(0,.05,0),Vector3(.36,.06,.36),Color("ff4fa3"))
			m.spots(Vector3(0,.18,0),Vector3(.13,.18,.13),Color("ffe14d"),6,.05,4)
			m.ball(Vector3(0,.46,0),Vector3(.12,.12,.12),Color("6be0ff"))
			m.rod(Vector3(-.08,.4,-.08),Vector3(-.03,.44,-.03),.02,Color("ffe14d"))
		"cone":
			m.rod(Vector3(0,0,0),Vector3(0,.5,0),.18,Color("ff7a1f"));m.ball(Vector3(0,.02,0),Vector3(.5,.05,.5),Color("ff7a1f"))
			m.ring(Vector3(0,.2,0),.13,.03,Color("ffffff"));m.ring(Vector3(0,.34,0),.09,.025,Color("ffffff"))
		"propeller":
			m.ball(Vector3(0,.05,0),Vector3(.5,.24,.5),Color("3a8dff"));m.ball(Vector3(0,.04,-.24),Vector3(.3,.04,.18),Color("ff4040"))
			m.rod(Vector3(0,.15,0),Vector3(0,.26,0),.025,Color("cccccc"))
			m.ball(Vector3(0,.27,0),Vector3(.52,.025,.08),Color("ffe14d"));m.ball(Vector3(0,.27,0),Vector3(.08,.025,.52),Color("ff4040"))
		"chef":
			m.rod(Vector3(0,0,0),Vector3(0,.22,0),.2,Color("ffffff"))
			for i in range(5): m.ball(Vector3(cos(i*1.26)*.12,.3,sin(i*1.26)*.12),Vector3(.2,.18,.2),Color("ffffff"))
			m.ball(Vector3(0,.34,0),Vector3(.24,.2,.24),Color("ffffff"))
		"wizard":
			m.ball(Vector3(0,.02,0),Vector3(.7,.05,.7),Color("4b2ea8"));m.rod(Vector3(0,0,0),Vector3(.05,.6,.08),.17,Color("4b2ea8"))
			m.rod(Vector3(.05,.6,.08),Vector3(.15,.72,.18),.07,Color("4b2ea8"))
			m.spots(Vector3(0,.25,0),Vector3(.15,.25,.15),Color("ffe14d"),7,.04,9,true,false)
		"viking":
			m.ball(Vector3(0,.04,0),Vector3(.52,.32,.52),Color("9aa3ad"));m.ring(Vector3(0,.04,0),.26,.04,Color("7a5a2e"))
			for side in [-1.0,1.0]:
				m.rod(Vector3(side*.24,.12,0),Vector3(side*.36,.3,0),.05,Color("f4ecd2"));m.rod(Vector3(side*.36,.3,0),Vector3(side*.34,.44,0),.03,Color("f4ecd2"))
		"tophat":
			m.ball(Vector3(0,.02,0),Vector3(.62,.04,.62),Color("1d1d24"));m.rod(Vector3(0,0,0),Vector3(0,.42,0),.19,Color("1d1d24"))
			m.ring(Vector3(0,.08,0),.2,.03,Color("c4263b"))
		"cowboy":
			m.ball(Vector3(0,.03,0),Vector3(.9,.05,.75),Color("a8733d"));m.ball(Vector3(0,.16,0),Vector3(.42,.28,.4),Color("a8733d"))
			m.ring(Vector3(0,.08,0),.21,.025,Color("5a3a1a"))
		"pirate":
			m.ball(Vector3(0,.1,0),Vector3(.8,.24,.36),Color("1d1d24"));m.ball(Vector3(0,.16,0),Vector3(.5,.24,.42),Color("1d1d24"))
			m.ball(Vector3(0,.18,-.2),Vector3(.12,.12,.04),Color("ffffff"))
			m.ring(Vector3(0,.07,0),.3,.02,Color("e6b64a"))
		"goggles":
			m.ring(Vector3(0,-.1,0),.27,.035,Color("3d3d46"))
			for side in [-1.0,1.0]: m.ball(Vector3(side*.11,-.06,-.25),Vector3(.15,.15,.08),Color("6be0ff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
		"halo":
			m.ring(Vector3(0,.22,0),.22,.035,Color("ffe98a"))
		"crown":
			m.ring(Vector3(0,.03,0),.22,.06,Color("f2c230"))
			for i in range(5):
				var a=i*TAU/5;m.rod(Vector3(cos(a)*.21,.04,sin(a)*.21),Vector3(cos(a)*.2,.22,sin(a)*.2),.035,Color("f2c230"))
				m.ball(Vector3(cos(a)*.2,.23,sin(a)*.2),Vector3(.06,.06,.06),Color("e8384f"))
		"noggin":
			m.ball(Vector3(0,.18,0),Vector3(.36,.34,.36),Color("f2b68f"))
			for side in [-1.0,1.0]:
				m.eye(Vector3(side*.07,.21,-.16),.06,Vector3(side*.2,0,-1),Color("ff4040"));m.ball(Vector3(side*.18,.18,0),Vector3(.06,.1,.05),Color("e39b78"))
			m.grin(Vector3(0,.1,-.16),.16,.05,4,false)
	return scene.finish()

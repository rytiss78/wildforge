extends Node3D
class_name Pet

# A pet (user request, October 29): a small cartoon creature that follows the
# hero, flies off to fetch coins lying beyond the hero's pickup reach, and evolves
# as it brings them back: bigger, quicker and further-reaching, with new parts.
# One of three species per run (seeded). In co-op every player sees the others'
# pets follow them (pose "pet"), but only your own pet fetches your coins.

const KINDS=["blip","fuzzbat","zorbo"]
const NAMES={"blip":"Blip","fuzzbat":"Fuzzbat","zorbo":"Zorbo"}
const EVOLVE_AT=[0,20,70]  # coins fetched to reach each stage
const SPEED=[8.0,10.5,13.0]
const REACH=[12.0,15.0,19.0]
const SIZE=[.55,.75,.95]

var game: Node3D
var leader: Node3D
var facing: Node3D  # whose turn sets the follow spot (the local hero's avatar)
var kind="blip"
var stage=0
var fetched=0
var fetching=true  # false for another player's pet
var state="follow"
var coin={}
var scan=0.0
var clock=0.0
var model: Node3D

static func pick(seed_value: int) -> String: return KINDS[absi(seed_value*7919+13)%KINDS.size()]

static func create(owner_game: Node3D,follow: Node3D,pet_kind: String,pet_stage: int=0,fetches: bool=true) -> Pet:
	var pet=Pet.new();pet.game=owner_game;pet.leader=follow;pet.kind=pet_kind;pet.stage=pet_stage;pet.fetching=fetches
	owner_game.add_child(pet);pet.position=follow.position+Vector3(1.2,1,1.2);pet.rebuild()
	return pet

func rebuild():
	if is_instance_valid(model): model.queue_free()
	model=build(kind,stage);add_child(model)

# The three species, each growing new parts at stages 1 and 2.
static func build(pet_kind: String,pet_stage: int) -> Node3D:
	var scene=CartoonScene.new();var m=scene.paint(scene.body)
	match pet_kind:
		"blip":  # a lime slime drop with one huge eye
			var body=Color("9be05a")
			m.ball(Vector3(0,.42,0),Vector3(.8,.72,.75),body);m.ball(Vector3(0,.16,0),Vector3(.95,.3,.9),body.darkened(.12))
			m.eye(Vector3(0,.55,-.32),.2,Vector3.FORWARD,Color("2a7bd6"))
			m.grin(Vector3(0,.3,-.36),.3,.1,2,true)
			if pet_stage>=1:
				for side in [-1.0,1.0]: m.stalk_eye(Vector3(side*.2,.72,-.05),Vector3(side*.34,1.05,-.08),.09,body,Vector3(side*.3,0,-1))
			if pet_stage>=2:
				m.spots(Vector3(0,.42,0),Vector3(.4,.36,.38),Color("f6ff8a"),7,.09,3,true)
				for i in range(5): m.rod(Vector3(0,.78,.05),Vector3(cos(i*1.26)*.18,1.0,.05+sin(i*1.26)*.18),.04,Color("ffd23f"))
		"fuzzbat":  # a pink puffball with bat wings
			var body=Color("ff8ac6")
			m.ball(Vector3(0,.5,0),Vector3(.7,.68,.66),body)
			for side in [-1.0,1.0]: m.eye(Vector3(side*.14,.58,-.3),.11,Vector3(side*.2,0,-1),Color("341b4a"))
			m.grin(Vector3(0,.4,-.32),.24,.08,2,false)
			m.wings(Vector3(0,.55,.08),.55+pet_stage*.2,.35+pet_stage*.1,Color("c44fa0"),Color("6b2058"))
			if pet_stage>=1:
				for side in [-1.0,1.0]: m.rod(Vector3(side*.2,.8,0),Vector3(side*.3,1.02,.05),.05,Color("fff2c2"))
			if pet_stage>=2:
				m.tentacles(3,Vector3(0,.2,.1),.12,.35,.05,body.darkened(.2),Color("ffd23f"))
				m.ball(Vector3(0,.5,-.02),Vector3(.74,.2,.7),Color("ffd8ee"))
		_:  # zorbo: a little blue saucer bug on stalk eyes
			var body=Color("5ec8ff")
			m.ball(Vector3(0,.42,0),Vector3(.9,.36,.9),body);m.ring(Vector3(0,.42,0),.46,.05,Color("2a6fa8"))
			m.ball(Vector3(0,.6,0),Vector3(.45,.3,.45),Color("c9f3ff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			for side in [-1.0,1.0]: m.stalk_eye(Vector3(side*.15,.68,-.1),Vector3(side*.2,.92,-.16),.08,body,Vector3(side*.2,0,-1))
			if pet_stage>=1:
				m.legs([Vector3(-.25,.3,-.15),Vector3(.25,.3,-.15),Vector3(-.25,.3,.18),Vector3(.25,.3,.18)],.22,.04,body.darkened(.2),Color("1d3f66"))
			if pet_stage>=2:
				m.ring(Vector3(0,1.05,0),.26,.04,Color("ffd23f"));m.spots(Vector3(0,.42,0),Vector3(.45,.18,.45),Color("ffffff"),8,.06,5,true)
	var root=scene.finish();root.scale=Vector3.ONE*SIZE[clampi(pet_stage,0,2)]
	return root

func flies() -> bool: return kind!="blip"

func _process(delta: float):
	if not is_instance_valid(leader): queue_free();return
	clock+=delta
	var goal: Vector3
	match state:
		"fetch":
			if not live(coin) or coin.get("attracted",false): drop();state="follow";goal=home()
			else:
				goal=coin.node.position
				if position.distance_to(goal)<.7: coin.carried=true;state="return"
		"return":
			goal=leader.position+Vector3.UP*.9
			if not live(coin): state="follow"
			else:
				coin.node.position=position+Vector3.UP*(.35*SIZE[stage])+(-basis.z)*.3
				if position.distance_to(goal)<2.2: deliver()
		_:
			goal=home()
			scan-=delta
			if fetching and scan<=0: scan=.3;look_for_coin()
	if position.distance_to(leader.position)>45: position=leader.position+Vector3.UP  # left behind (new island)
	var speed=SPEED[stage]*(1.6 if state!="follow" else 1.0)
	var to=goal-position
	var step=to.limit_length(speed*delta*(1.0 if to.length()>.3 else to.length()/.3))
	position+=step
	var ground=game.world.height_at(position.x,position.z)
	# Flyers bob in the air; Blip hops along the ground.
	if flies(): position.y=maxf(position.y,ground+.6)+sin(clock*6.0)*.01
	else: position.y=maxf(ground+absf(sin(clock*9.0))*.35*minf(1.0,step.length()/maxf(.001,speed*delta)),minf(position.y,ground+.4))
	if Vector2(to.x,to.z).length()>.2: rotation.y=lerp_angle(rotation.y,atan2(-to.x,-to.z),minf(1.0,delta*10.0))
	if is_instance_valid(model): model.position.y=sin(clock*(12.0 if flies() else 0.0))*.05

func home() -> Vector3:
	var turn: Node3D=facing if is_instance_valid(facing) else leader
	var side=turn.global_basis.x;var back=turn.global_basis.z
	return leader.position+side*1.3+back*.9+Vector3.UP*(1.3 if flies() else 0.0)

static func live(pickup: Dictionary) -> bool: return not pickup.is_empty() and pickup.get("age",-1)>=0 and is_instance_valid(pickup.get("node"))

# The nearest settled coin the hero would not pick up anyway, within reach.
func look_for_coin():
	var best=REACH[stage];var reach=float(game.stats.get("coinRadius",2.0))+.5;coin={}
	for pickup in game.pickups:
		if pickup.kind!="gold" or not pickup.get("settled",false) or pickup.get("attracted",false) or pickup.get("carried",false) or pickup.age<0: continue
		var from_hero=pickup.node.position.distance_to(leader.position)
		if from_hero>reach and from_hero<best: best=from_hero;coin=pickup
	if not coin.is_empty(): state="fetch"

func drop():
	if live(coin): coin.carried=false
	coin={}

# Back at the hero: the coin flies in like any other and counts toward evolving.
func deliver():
	coin.carried=false;coin.attracted=true;coin={};state="follow"
	fetched+=1
	if stage<2 and fetched>=EVOLVE_AT[stage+1]: evolve()

func evolve():
	stage+=1;rebuild()
	game.burst(position,Color("fff38a"),16);game.burst(position,Color.WHITE,8)
	game.sound.effect("level",position)
	game.Journey.announce(game,"%s EVOLVED!" % NAMES[kind].to_upper(),"Stage %d · faster, and it fetches from further away" % (stage+1))

func label() -> String: return "%s:%d" % [kind,stage]

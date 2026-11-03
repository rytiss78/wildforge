extends Node3D
class_name Pet

# A pet (user request, October 29; reworked October 30: "not sure what they do or
# how many there are; let the player choose one with the hero, and upgrade it with
# drops"). The player picks one of three pets on the hero screen; each has a job:
#   Glint  fetcher  darts off for coins and Pet Treats beyond the hero's reach
#   Sting  biter    darts at the nearest enemy and stings it
#   Halo   medic    pulses a healing ring when the hero is hurt
# Pet Treats drop only from the final boss (October 31) and are kept between runs,
# per pet (settings.pet_treats): 4 treats evolve a pet to stage 2, 12 to stage 3.
# Pets are glowing wisps floating at the hero's shoulder (see build).
# In co-op every player sees the others' pets follow them (pose "pet"), but only
# your own pet works for you.

const KINDS=["blip","fuzzbat","zorbo","ward","mote","rime"]
# Three more (user, November 2): Ward shields you, Mote pulls XP orbs in, Rime
# chills enemies near you.
# Wisp names (October 31): Glint grabs shiny things, Sting bites, Halo heals.
# The ids stay blip/fuzzbat/zorbo so saved choices and treats carry over.
const NAMES={"blip":"Glint","fuzzbat":"Sting","zorbo":"Halo","ward":"Ward","mote":"Mote","rime":"Rime"}
const ROLES={"blip":"FETCHER","fuzzbat":"BITER","zorbo":"MEDIC","ward":"GUARD","mote":"MAGNET","rime":"FROST"}
const JOBS={
	"blip":"Fetches coins and Pet Treats lying beyond your pickup reach.",
	"fuzzbat":"Darts at the nearest enemy and stings it, over and over.",
	"zorbo":"Pulses a healing ring when you are hurt.",
	"ward":"Wraps you in a bubble of shield every few seconds.",
	"mote":"Pulls XP orbs to you from far away.",
	"rime":"Chills enemies close to you, slowing them.",
}
const WARD_SHIELD=[6.0,10.0,16.0]
const WARD_EVERY=[8.0,7.0,6.0]
const PULL_REACH=[9.0,12.0,16.0]
const RIME_REACH=[4.0,5.0,6.5]
const RIME_SLOW=[.25,.35,.45]
const TREATS_AT=[0,4,12]  # Pet Treats eaten to reach each stage

# What the pet does at a stage, in numbers (hero screen).
static func benefit(pet_kind: String,pet_stage: int) -> String:
	match pet_kind:
		"blip": return "Fetches coins up to %d m away" % roundi(REACH[pet_stage])
		"fuzzbat": return "Stings for %d damage every %.1f s" % [roundi(BITE[pet_stage]),BITE_EVERY[pet_stage]]
		"zorbo": return "Heals %d%% ♥ every %d s while you are hurt" % [roundi(HEAL[pet_stage]*100),roundi(HEAL_EVERY[pet_stage])]
		"ward": return "+%d shield every %d s" % [roundi(WARD_SHIELD[pet_stage]),roundi(WARD_EVERY[pet_stage])]
		"mote": return "Pulls XP orbs to you from %d m" % roundi(PULL_REACH[pet_stage])
		"rime": return "Slows enemies within %d m by %d%%" % [roundi(RIME_REACH[pet_stage]),roundi(RIME_SLOW[pet_stage]*100)]
	return JOBS.get(pet_kind,"")
const SPEED=[8.0,10.5,13.0]
const REACH=[12.0,15.0,19.0]
const SIZE=[.85,1.0,1.2]
const FINAL_BOSS_TREATS=4
const BITE=[9.0,16.0,26.0]  # per bite, before island scaling
const BITE_EVERY=[1.4,1.1,.8]
const HEAL=[.04,.06,.09]  # share of max HP per pulse
const HEAL_EVERY=[6.0,5.0,4.0]

var game: Node3D
var leader: Node3D
var facing: Node3D  # whose turn sets the follow spot (the local hero's avatar)
var kind="blip"
var stage=0
var treats=0
var fetched=0
var fetching=true  # false for another player's pet: it only follows
var state="follow"
var coin={}
var target={}
var scan=0.0
var clock=0.0
var work=0.0
var model: Node3D

static func pick(seed_value: int) -> String: return KINDS[absi(seed_value*7919+13)%KINDS.size()]

# The pet chosen on the hero screen (career settings), Glint if none yet.
static func chosen(settings: Dictionary) -> String:
	var value=str(settings.get("pet",""))
	return value if KINDS.has(value) else "blip"

# Treats a pet has eaten over all runs, and the stage that makes.
static func saved_treats(settings: Dictionary,pet_kind: String) -> int:
	return int(settings.get("pet_treats",{}).get(pet_kind,0))

static func stage_for(eaten: int) -> int:
	return 2 if eaten>=TREATS_AT[2] else 1 if eaten>=TREATS_AT[1] else 0

static func create(owner_game: Node3D,follow: Node3D,pet_kind: String,pet_stage: int=0,fetches: bool=true) -> Pet:
	var pet=Pet.new();pet.game=owner_game;pet.leader=follow;pet.kind=pet_kind;pet.stage=pet_stage;pet.fetching=fetches
	owner_game.add_child(pet);pet.position=follow.position+Vector3(1.2,1,1.2);pet.rebuild()
	return pet

func rebuild():
	if is_instance_valid(model): model.queue_free()
	model=build(kind,stage);add_child(model)

# Wisps (October 31, user: "pets should look like wisps floating over the shoulder,
# like in MMORPGs"): a bright core in a soft glow with a fading trail. Each kind has
# its own colour and a small mark: Glint one big eye, Sting two flickering flame
# wings, Halo an orbiting ring. Growing a stage adds orbiting motes (two, then
# four) and a brighter, larger glow.
const COLORS={"blip":Color("b6ff5a"),"fuzzbat":Color("ff7ac8"),"zorbo":Color("6fd2ff"),"ward":Color("ffd23f"),"mote":Color("c69bff"),"rime":Color("dff8ff")}
static var halo_texture: Texture2D

static func glow_paint(color: Color,alpha: float,additive: bool=true) -> StandardMaterial3D:
	var paint=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color=Color(color,alpha);paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive: paint.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
	paint.disable_receive_shadows=true
	return paint

static func halo(color: Color,size: float,alpha: float) -> MeshInstance3D:
	if halo_texture==null:
		var ramp=Gradient.new();ramp.offsets=PackedFloat32Array([0.0,.35,1.0]);ramp.colors=PackedColorArray([Color(1,1,1,1),Color(1,1,1,.35),Color(1,1,1,0)])
		var texture=GradientTexture2D.new();texture.gradient=ramp;texture.fill=GradientTexture2D.FILL_RADIAL;texture.fill_from=Vector2(.5,.5);texture.fill_to=Vector2(1,.5);texture.width=64;texture.height=64
		halo_texture=texture
	var quad=QuadMesh.new();quad.size=Vector2(size,size)
	var paint=glow_paint(color,alpha);paint.albedo_texture=halo_texture;paint.billboard_mode=BaseMaterial3D.BILLBOARD_ENABLED
	var node=MeshInstance3D.new();node.mesh=quad;node.material_override=paint;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

static func ball(radius: float,paint: Material) -> MeshInstance3D:
	var sphere=SphereMesh.new();sphere.radius=radius;sphere.height=radius*2;sphere.radial_segments=14;sphere.rings=7
	var node=MeshInstance3D.new();node.mesh=sphere;node.material_override=paint;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node

static func build(pet_kind: String,pet_stage: int) -> Node3D:
	var color: Color=COLORS.get(pet_kind,Color.WHITE);var grown=clampi(pet_stage,0,2)
	var root=Node3D.new();root.name="Wisp"
	var core_paint=StandardMaterial3D.new();core_paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;core_paint.albedo_color=color.lerp(Color.WHITE,.4)
	root.add_child(ball(.075,core_paint))
	root.add_child(ball(.125,glow_paint(color,.35)))
	var glow=halo(color,.7+grown*.22,.5+grown*.1);glow.name="Halo";root.add_child(glow)
	var eye_paint=StandardMaterial3D.new();eye_paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;eye_paint.albedo_color=Color("1b1530")
	match pet_kind:
		"blip":
			var eye=ball(.035,eye_paint);eye.position=Vector3(0,.015,-.07);root.add_child(eye)
		"fuzzbat":
			for side in [-1.0,1.0]:
				var eye=ball(.02,eye_paint);eye.position=Vector3(side*.03,.02,-.07);root.add_child(eye)
				var wing=halo(color.lerp(Color("ffd0f0"),.3),.28,.8);wing.name="Wing";wing.position=Vector3(side*.15,.04,.02);wing.scale=Vector3(1,.55,1);root.add_child(wing)
		"ward":
			for side in [-1.0,1.0]:
				var eye=ball(.02,eye_paint);eye.position=Vector3(side*.03,.02,-.07);root.add_child(eye)
			var plate=MeshInstance3D.new();plate.name="Shield";var diamond=BoxMesh.new();diamond.size=Vector3(.2,.2,.02);plate.mesh=diamond
			plate.material_override=glow_paint(color.lerp(Color.WHITE,.3),.7);plate.rotation.z=PI*.25;plate.position=Vector3(0,0,-.16);root.add_child(plate)
		"mote":
			var eye=ball(.03,eye_paint);eye.position=Vector3(0,.015,-.07);root.add_child(eye)
			var swirl=Node3D.new();swirl.name="Ring";root.add_child(swirl)
			for k in range(6):
				var spark=halo(color.lerp(Color.WHITE,.3),.1,.9);var a=k*1.05;spark.position=Vector3(cos(a)*(.1+k*.03),0,sin(a)*(.1+k*.03));swirl.add_child(spark)
		"rime":
			for side in [-1.0,1.0]:
				var eye=ball(.02,eye_paint);eye.position=Vector3(side*.03,.02,-.07);root.add_child(eye)
			var flake=Node3D.new();flake.name="Ring";root.add_child(flake)
			for k in range(3):
				var spoke=MeshInstance3D.new();var rod=BoxMesh.new();rod.size=Vector3(.42,.018,.018);spoke.mesh=rod
				spoke.material_override=glow_paint(Color(.85,.97,1.0),.9);spoke.rotation.y=k*PI/3.0;flake.add_child(spoke)
		_:
			for side in [-1.0,1.0]:
				var eye=ball(.02,eye_paint);eye.position=Vector3(side*.03,.02,-.07);root.add_child(eye)
			var ring=TorusMesh.new();ring.inner_radius=.17;ring.outer_radius=.19;ring.rings=24;ring.ring_segments=6
			var band=MeshInstance3D.new();band.name="Ring";band.mesh=ring;band.material_override=glow_paint(color.lerp(Color.WHITE,.4),.85);band.rotation=Vector3(.5,0,.3);root.add_child(band)
	# Orbiting motes, more as it grows.
	var motes=Node3D.new();motes.name="Motes";root.add_child(motes)
	for i in range([0,2,4][grown]):
		var mote=ball(.022,core_paint);var a=float(i)/[1,2,4][grown]*TAU
		mote.position=Vector3(cos(a)*.24,sin(a*2.0)*.05,sin(a)*.24);motes.add_child(mote)
		var spark=halo(color,.14,.7);spark.position=mote.position;motes.add_child(spark)
	# A short fading trail in the world, so it leaves a streak as it moves.
	var trail=GPUParticles3D.new();trail.name="Trail";trail.amount=20;trail.lifetime=.55;trail.local_coords=false
	trail.visibility_aabb=AABB(Vector3(-3,-3,-3),Vector3(6,6,6));trail.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var process=ParticleProcessMaterial.new();process.gravity=Vector3(0,.25,0);process.initial_velocity_min=0.0;process.initial_velocity_max=.15;process.spread=180.0
	var curve=Curve.new();curve.add_point(Vector2(0,1));curve.add_point(Vector2(1,0));var shrink=CurveTexture.new();shrink.curve=curve;process.scale_curve=shrink
	trail.process_material=process
	var dot=QuadMesh.new();dot.size=Vector2(.1,.1);var dot_paint=glow_paint(color,.8);dot_paint.albedo_texture=null;dot_paint.billboard_mode=BaseMaterial3D.BILLBOARD_PARTICLES
	if halo_texture!=null: dot_paint.albedo_texture=halo_texture
	dot.material=dot_paint;trail.draw_pass_1=dot;root.add_child(trail)
	var lamp=OmniLight3D.new();lamp.light_color=color;lamp.light_energy=.5+grown*.2;lamp.omni_range=3.0;lamp.shadow_enabled=false;root.add_child(lamp)
	root.scale=Vector3.ONE*SIZE[grown]
	return root

# The wisp's own motion: motes circle, wings flicker, the ring spins.
func animate_wisp(delta: float):
	if not is_instance_valid(model): return
	model.position.y=sin(clock*2.4)*.07
	var motes=model.get_node_or_null("Motes")
	if motes!=null: motes.rotation.y+=delta*2.2
	var ring=model.get_node_or_null("Ring")
	if ring!=null: ring.rotation.y+=delta*3.0
	for wing in model.get_children():
		if wing.name.begins_with("Wing"): wing.scale.y=.4+absf(sin(clock*14.0))*.35

func flies() -> bool: return true

func _process(delta: float):
	if not is_instance_valid(leader): queue_free();return
	clock+=delta;work-=delta
	animate_wisp(delta)
	# The hero went under the island: the pet waits on top.
	if leader==game.player and game.underside.active(): return
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
		"bite":
			if target.is_empty() or target.get("dead",true) or not is_instance_valid(target.get("node")): target={};state="follow";goal=home()
			else:
				goal=target.node.position+Vector3.UP*1.0
				if position.distance_to(goal)<1.3: bite()
				elif position.distance_to(leader.position)>REACH[stage]+6: target={};state="follow"
		_:
			goal=home()
			scan-=delta
			if fetching and scan<=0: scan=.3;duty()
	if position.distance_to(leader.position)>45: position=leader.position+Vector3.UP  # left behind (new island)
	var speed=SPEED[stage]*(1.6 if state!="follow" else 1.0)
	var to=goal-position
	var step=to.limit_length(speed*delta*(1.0 if to.length()>.3 else to.length()/.3))
	position+=step
	var ground=game.world.height_at(position.x,position.z)
	# Wisps float: never below knee height.
	position.y=maxf(position.y,ground+.6)
	if Vector2(to.x,to.z).length()>.2: rotation.y=lerp_angle(rotation.y,atan2(-to.x,-to.z),minf(1.0,delta*10.0))
	elif is_instance_valid(facing): rotation.y=lerp_angle(rotation.y,facing.global_rotation.y,minf(1.0,delta*4.0))

# What the pet does when it is free, by species.
func duty():
	match kind:
		"blip": look_for_coin()
		"fuzzbat":
			if work>0 or game.mode!="playing": return
			var best=REACH[stage];target={}
			for enemy in game.enemies:
				if enemy.dead or enemy.get("behavior","")=="turret": continue
				var d=enemy.node.position.distance_to(leader.position)
				if d<best: best=d;target=enemy
			if not target.is_empty(): state="bite"
		"zorbo":
			if work>0 or game.mode!="playing" or game.hp<=0 or game.hp>=game.stats.maxHp*.97: return
			work=HEAL_EVERY[stage]
			game.heal(game.stats.maxHp*HEAL[stage])
			CombatInk.wave(game,leader.position+Vector3.UP*.1,2.4,Color("7dffb0"))
			game.burst(position,Color("7dffb0"),8)
		"ward":
			if work>0 or game.mode!="playing" or game.hp<=0: return
			work=WARD_EVERY[stage]
			var bonus=WARD_SHIELD[stage]
			game.shield_hp=minf(game.shield_hp+bonus,maxf(float(game.stats.shield),bonus*2.0))
			game.burst(leader.position+Vector3.UP*1.0,Color("ffe27a"),8)
		"mote":
			var reach=PULL_REACH[stage]
			for pickup in game.pickups:
				if pickup.kind=="xp" and pickup.age>=0 and pickup.get("settled",false) and not pickup.get("attracted",false) and pickup.node.position.distance_to(leader.position)<reach:
					pickup.attracted=true;fetched+=1
		"rime":
			var reach=RIME_REACH[stage]
			for enemy in game.enemies:
				if enemy.dead or enemy.node.position.distance_to(leader.position)>reach: continue
				enemy.slow=maxf(float(enemy.slow),RIME_SLOW[stage]*(.5 if enemy.boss else 1.0));enemy.status_time=maxf(float(enemy.status_time),.6)
			if work<=0: work=1.2;CombatInk.wave(game,leader.position+Vector3.UP*.1,reach,Color("bfeaff"))

func bite():
	var damage=BITE[stage]*(1.0+float(game.tier)*.6)
	game.hurt_enemy(target,damage,"melee")
	game.burst(position,Color("ff8ac6"),6)
	work=BITE_EVERY[stage];target={};state="follow"

func home() -> Vector3:
	var turn: Node3D=facing if is_instance_valid(facing) else leader
	# Just over the right shoulder, a little behind, drifting in a slow loop.
	var side=turn.global_basis.x.normalized();var back=turn.global_basis.z.normalized()
	var drift=Vector3(sin(clock*.9)*.18,sin(clock*1.3)*.12,cos(clock*.7)*.15)
	return leader.position+side*.7+back*.15+Vector3.UP*1.55+drift

static func live(pickup: Dictionary) -> bool: return not pickup.is_empty() and pickup.get("age",-1)>=0 and is_instance_valid(pickup.get("node"))

# The nearest settled coin or treat the hero would not pick up anyway, within reach.
func look_for_coin():
	var best=REACH[stage];var reach=float(game.stats.get("coinRadius",2.0))+.5;coin={}
	for pickup in game.pickups:
		if pickup.kind not in ["gold","treat"] or not pickup.get("settled",false) or pickup.get("attracted",false) or pickup.get("carried",false) or pickup.age<0: continue
		var from_hero=pickup.node.position.distance_to(leader.position)
		if from_hero>reach and from_hero<best: best=from_hero;coin=pickup
	if not coin.is_empty(): state="fetch"

func drop():
	if live(coin): coin.carried=false
	coin={}

# Back at the hero: the coin flies in like any other.
func deliver():
	coin.carried=false;coin.attracted=true;coin={};state="follow"
	fetched+=1

# Pet Treats were collected: count them (kept between runs) and evolve.
func feed(amount: int=1):
	treats+=maxi(1,amount)
	var store: Dictionary=game.career.data.settings.get("pet_treats",{})
	store[kind]=treats;game.career.data.settings.pet_treats=store;game.career.dirty=true;game.career.save()
	game.burst(position,Color("ff9ad6"),8)
	if stage<2 and treats>=TREATS_AT[stage+1]: evolve()

# "· 3 / 4 treats to stage 2", or "is fully grown".
func progress() -> String:
	if stage>=2: return "is fully grown"
	return "· %d / %d treats to stage %d" % [treats,TREATS_AT[stage+1],stage+2]

func evolve():
	stage+=1;rebuild()
	game.burst(position,Color("fff38a"),16);game.burst(position,Color.WHITE,8)
	game.sound.effect("level",position)
	game.Journey.announce(game,"%s EVOLVED!" % NAMES[kind].to_upper(),"★".repeat(stage+1))
	# A pet that just grew a stage may already have the treats for the next.
	if stage<2 and treats>=TREATS_AT[stage+1]: evolve()

func label() -> String: return "%s:%d" % [kind,stage]

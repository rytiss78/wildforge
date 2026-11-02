extends RefCounted
class_name HeroPlay

# Hero-specific play (user list, November 2). HeroRules says who breaks which
# rule; this does the work each frame:
#   White Supra    drives: twice the usual speed, Space is a handbrake drift with
#                  a tyre squeal, skid marks and smoke; a hit is a car crash
#   Smoker, Bee    hover over the ground (lava and ground hazards miss them)
#   Honey Hustler  sips nectar from wild flowers for XP (a little from Florist's)
#   Admiral Bubbles no health: the bubble shield is his life (see game.take_damage)
#   Turbo Snail    leaves a lasting slime trail that slows enemies crossing it
#   Prickle Rick   no limbs or weapon: lies on his side, rolls slowly, gets shoved
#                  about by enemies, and draws them to him (CoopSession.target)

const SUPRA_GRIP=9.0
const DRIFT_GRIP=1.4
const HOVER={"smoker":.45,"bee":1.0}
const TRAIL_STEP=.9
const TRAIL_CELL=1.2
const TRAIL_MAX=6000
const TRAIL_SLOW=.5
const NECTAR_COUNT=34
const NECTAR_REGROW=40.0
const AGGRO=.25  # a taunting hero counts as this much nearer to enemies (distance²)

static var drifting=false
static var drift_sound: AudioStreamPlayer3D
static var skid_clock=0.0
static var trail_cells={}
static var trail_points=0
static var trail_mesh: MultiMeshInstance3D
static var last_trail=Vector3.INF
static var trail_clock=0.0
static var nectar=[]
static var sip_clock=0.0
static var roll=Vector3.ZERO  # Prickle Rick's rolling momentum
const ROLL_FRICTION=7.0
const ROLL_MAX=8.0

static func id(g) -> String: return str(g.hero.get("id",""))

# At the start of a run: cards the hero cannot use leave the pool, the cactus
# drops his weapon, and per-run state is cleared.
static func start(g):
	# Every card the hero cannot use (HeroRules.card_fits: jump, slam and dash
	# cards for heroes without them, health cards for the shield-only hero,
	# weapon cards for the unarmed) and every mutation that fires on an action he
	# never makes leave the pool.
	for card in g.rules.data.loot:
		var key=str(card.effects[0].key) if not card.get("effects",[]).is_empty() else ""
		if not key.is_empty() and not HeroRules.card_fits(g.hero,card) and not g.rules.banished.has(key): g.rules.banished.append(key)
	if HeroRules.no_health(g.hero):
		for key in ["maxHp","regen","lifesteal","coinHeal","chestHeal","landingHeal","slamHeal"]:
			if not g.rules.banished.has(key): g.rules.banished.append(key)
	for mutation_id in MutationBook.all():
		if not HeroRules.mutation_fits(g.hero,mutation_id) and not g.rules.banished.has("mut:"+mutation_id): g.rules.banished.append("mut:"+mutation_id)
	g.rules.no_weapons=not HeroRules.armed(g.hero)
	if g.rules.no_weapons:
		for weapon in g.equipped:
			if is_instance_valid(weapon.get("node")): weapon.node.queue_free()
		g.equipped.clear();g.avatar.sync_equipment(g.equipped)
	drifting=false;roll=Vector3.ZERO;spin=0.0;rock=0.0;clear_trail(g)

# Each island starts a fresh trail and fresh nectar flowers.
static func realm_started(g):
	clear_trail(g)
	for flower in nectar:
		if is_instance_valid(flower.node): flower.node.queue_free()
	nectar.clear()
	if id(g)=="bee" and g.realm<3: plant_nectar(g)
	lay_down(g)

# Called on each hero change too (the hero screen preview uses its own model).
static func lay_down(g):
	if not is_instance_valid(g.avatar): return
	HeroRules.lie(g.avatar,g.hero)
	# No health, no glass health orb on the hero.
	for core in g.avatar.find_children("GlassCore*","",true,false): core.visible=not HeroRules.no_health(g.hero)

static func tick(g,delta: float):
	var hero=id(g)
	var hover=float(HOVER.get(hero,0.0))
	if is_instance_valid(g.avatar):
		g.avatar.position.y=lerpf(g.avatar.position.y,hover+sin(g.elapsed*2.2)*.08*signf(hover),minf(1.0,delta*6.0)) if hover>0 else 0.0
	if hero=="white-supra": drift_fx(g,delta)
	elif is_instance_valid(drift_sound): drift_sound.stop()
	if hero=="snail": lay_trail(g,delta)
	if not trail_cells.is_empty(): slow_on_trail(g,delta)
	if hero=="bee": sip(g,delta)
	if hero=="cactus": shoved(g,delta)
	if hero=="mole" or not roots.is_empty(): update_roots(g,delta)

# --- White Supra -----------------------------------------------------------

# Car handling: the velocity turns towards the wanted one with tyre grip; holding
# Space (the jump key) cuts the grip, so the car slides through turns at speed.
static func drive(g,running: Vector3,delta: float) -> Vector3:
	if id(g)=="clutch": var sneak=ClutchPlay.speed_scale(g);return Vector3(running.x*sneak,running.y,running.z*sneak)
	# Prickle Rick: his own slow wobble plus the momentum enemies and hits gave him.
	if id(g)=="cactus": return Vector3(running.x+roll.x,running.y,running.z+roll.z)
	if id(g)!="white-supra": return running
	var held=Input.is_action_pressed("jump") or g.get_meta("test_drift",false)
	var now=Vector3(g.player.velocity.x,0,g.player.velocity.z)
	var want=Vector3(running.x,0,running.z)
	var v=now.lerp(want,1.0-exp(-(DRIFT_GRIP if held else SUPRA_GRIP)*delta))
	if held and now.length()>4.0: v=v.normalized()*maxf(v.length(),now.length()*.99)
	drifting=held and v.length()>5.0 and (want.length()<.5 or absf(now.signed_angle_to(want,Vector3.UP))>.2)
	return Vector3(v.x,running.y,v.z)

static func drift_fx(g,delta: float):
	if not is_instance_valid(drift_sound):
		drift_sound=AudioStreamPlayer3D.new();drift_sound.name="DriftSound"
		var stream: AudioStreamWAV=load("res://assets/audio/effects/drift-loop.wav").duplicate()
		stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=0;stream.loop_end=int(stream.data.size()/2)
		drift_sound.stream=stream;drift_sound.unit_size=8;g.player.add_child(drift_sound)
	if drifting and not drift_sound.playing: drift_sound.play()
	if not drifting and drift_sound.playing: drift_sound.stop()
	drift_sound.volume_db=linear_to_db(maxf(.0001,float(g.sound.settings.get("sfx",.65))))-4
	if not drifting: return
	skid_clock-=delta
	if skid_clock>0: return
	skid_clock=.06
	var back=g.player.position-Vector3(g.player.velocity.x,0,g.player.velocity.z).normalized()*.9
	for side in [-.45,.45]:
		var across=Vector3(g.player.velocity.z,0,-g.player.velocity.x).normalized()*side
		var mark=MeshInstance3D.new();var quad=PlaneMesh.new();quad.size=Vector2(.22,.5);mark.mesh=quad
		mark.material_override=skid_paint();mark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.add_child(mark);var at=back+across;at.y=g.world.height_at(at.x,at.z)+.03;mark.position=at
		mark.rotation.y=atan2(g.player.velocity.x,g.player.velocity.z)
		g.effects.append({"node":mark,"life":3.0,"velocity":Vector3.ZERO,"stationary":true})
	if randf()<.5: g.burst(back+Vector3.UP*.3,Color("d8d8d8"),2)

static var skid_material: StandardMaterial3D
static func skid_paint() -> StandardMaterial3D:
	if skid_material==null:
		skid_material=StandardMaterial3D.new();skid_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		skid_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;skid_material.albedo_color=Color(.08,.07,.08,.55)
	return skid_material

# The car's "voice" when hit.
static func hurt_sound(g) -> bool:
	if id(g)!="white-supra": return false
	g.sound.effect("car-crash",g.player.position)
	return true

# --- Turbo Snail -------------------------------------------------------------

static func clear_trail(g):
	trail_cells.clear();trail_points=0;last_trail=Vector3.INF
	if is_instance_valid(trail_mesh): trail_mesh.queue_free()
	trail_mesh=null

static func lay_trail(g,_delta: float):
	var p=g.player.position
	if g.underside.active() or trail_points>=TRAIL_MAX or p.y>g.world.height_at(p.x,p.z)+.35: return
	if last_trail!=Vector3.INF and Vector2(p.x-last_trail.x,p.z-last_trail.z).length()<TRAIL_STEP: return
	var heading=Vector2(p.x-last_trail.x,p.z-last_trail.z) if last_trail!=Vector3.INF else Vector2.UP
	last_trail=p
	trail_cells[Vector2i(floori(p.x/TRAIL_CELL),floori(p.z/TRAIL_CELL))]=true
	if trail_mesh==null:
		trail_mesh=MultiMeshInstance3D.new();trail_mesh.name="SlimeTrail";trail_mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
		var blob=SphereMesh.new();blob.radius=.55;blob.height=.08;blob.radial_segments=12;blob.rings=3;mm.mesh=blob
		mm.instance_count=TRAIL_MAX;mm.visible_instance_count=0;trail_mesh.multimesh=mm
		var slime=StandardMaterial3D.new();slime.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;slime.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		slime.albedo_color=Color(.62,1.0,.45,.38);slime.emission_enabled=true;slime.emission=Color("8dff5a");slime.emission_energy_multiplier=.25
		trail_mesh.material_override=slime;g.add_child(trail_mesh)
	var spot=Transform3D(Basis(Vector3.UP,atan2(heading.x,heading.y)).scaled(Vector3(.8,1,1.3)),Vector3(p.x,g.world.height_at(p.x,p.z)+.02,p.z))
	trail_mesh.multimesh.set_instance_transform(trail_points,spot);trail_points+=1;trail_mesh.multimesh.visible_instance_count=trail_points

static func on_trail(p: Vector3) -> bool:
	return trail_cells.has(Vector2i(floori(p.x/TRAIL_CELL),floori(p.z/TRAIL_CELL)))

static func slow_on_trail(g,delta: float):
	trail_clock-=delta
	if trail_clock>0: return
	trail_clock=.2
	for enemy in g.enemies:
		if enemy.dead or enemy.get("flying",false) or not on_trail(enemy.node.position): continue
		if float(enemy.slow)<TRAIL_SLOW: g.sound.enemy_effect("slime",enemy.node.position)
		enemy.slow=maxf(float(enemy.slow),TRAIL_SLOW*(.5 if enemy.boss else 1.0));enemy.status_time=maxf(float(enemy.status_time),.6)

# --- Honey Hustler -------------------------------------------------------------

static func plant_nectar(g):
	var rng=RandomNumberGenerator.new();rng.seed=g.seed_value+g.realm*911
	var tries=0
	while nectar.size()<NECTAR_COUNT and tries<600:
		tries+=1
		var angle=rng.randf()*TAU;var radius=rng.randf_range(10,RealmWorld.SPAWN_EXTENT-40)
		var p=Vector3(cos(angle)*radius,0,sin(angle)*radius)
		if radius>g.world.shore_radius(p)-26 or g.world.lava_at(p): continue
		p.y=g.world.height_at(p.x,p.z)
		var node=Node3D.new();node.name="Nectar";g.add_child(node);node.position=p
		var colors=[Color("ff7ac8"),Color("ffd23f"),Color("9fe9ff"),Color("c69bff")]
		for k in range(5):
			var at=Vector3(cos(k*1.3)*.5,0,sin(k*1.3)*.5)*(k%3)
			ToonArt.tube(node,Color("3f9a3a"),at+Vector3(0,.3,0),.03,.03,.6)
			NatureScenery.blossom(node,at+Vector3(0,.62,0),colors[(k+nectar.size())%colors.size()],.38)
		PotionBook.tag(node,"✿ XP",Color("ffd23f"),1.3)
		nectar.append({"node":node,"ready":0.0})

static func sip(g,delta: float):
	sip_clock-=delta
	if sip_clock>0: return
	sip_clock=.25
	var p=g.player.position
	for flower in nectar:
		if not is_instance_valid(flower.node): continue
		var ready=g.elapsed>=float(flower.ready)
		flower.node.scale=flower.node.scale.lerp(Vector3.ONE if ready else Vector3(.55,.35,.55),.3)
		if not ready: continue
		var at: Vector3=flower.node.position
		if Vector2(at.x-p.x,at.z-p.z).length()<2.6:
			flower.ready=g.elapsed+NECTAR_REGROW
			g.spawn_pickup(p+Vector3.UP*.5,"xp",6+g.realm*4)
			g.burst(at+Vector3.UP*.8,Color("ffd23f"),6);g.sound.effect("heal",at)
	# Florist flowers give a little too, each once in a while.
	for flower in g.flowers:
		if not is_instance_valid(flower.get("node")): continue
		var at: Vector3=flower.node.position
		if Vector2(at.x-p.x,at.z-p.z).length()<2.2 and g.elapsed>=float(flower.get("sipped",-99.0))+15.0:
			flower.sipped=g.elapsed;g.spawn_pickup(p+Vector3.UP*.5,"xp",1)

# --- Prickle Rick ----------------------------------------------------------------

# He lies on his side and is pushed about with some physics (user, November 2):
# each enemy pressing on him adds momentum away from it (bosses push harder) and,
# pressing off-centre, turns him about; hits shove him too (game.take_damage's
# knock). He is a long, curved pickle, not a wheel: he slides lengthways more
# easily than sideways, only rocks a little about his long axis, and friction
# soon stops him. Walls bounce him back.
const ACROSS_FRICTION=2.4  # sideways friction, times ROLL_FRICTION
static var spin=0.0
static var rock=0.0

# He never turns to face enemies (game.gd skips its facing turn); pushes spin him.
static func turns_himself(g) -> bool: return id(g)=="cactus"
static func hugs(g) -> bool: return id(g)=="cactus"

# Enemies touching him are poisoned (the "Toxic Hug"; poison cards add to it).
static func hug(g,enemy: Dictionary):
	if id(g)!="cactus" or float(g.stats.poison)<=0: return
	g.set_damage_status(enemy,"poison",float(g.stats.poison),g.coop.local_id)
	enemy.status_time=maxf(float(enemy.status_time),3.0)

static func shoved(g,delta: float):
	var p=g.player.position;var push=Vector3.ZERO;var torque=0.0
	var axis=Vector3.RIGHT
	if is_instance_valid(g.avatar): axis=(g.avatar.global_basis.x*Vector3(1,0,1)).normalized()
	for enemy in g.enemies:
		if enemy.dead: continue
		var away=p-enemy.node.position;away.y=0
		var reach=float(enemy.radius)+1.0
		if away.length_squared()<reach*reach:
			var weight=3.0 if enemy.boss else 1.0+float(enemy.get("height",1.7))*.3
			var force=(away.normalized() if away.length_squared()>.0001 else Vector3.RIGHT)*(reach-away.length())*weight
			push+=force
			# Pressing near one end turns him about his middle.
			var lever=axis*clampf((-away).dot(axis),-.8,.8)
			torque+=lever.cross(force).y
	roll+=push.limit_length(3.0)*12.0*delta
	spin=clampf(spin+torque*3.0*delta,-3.0,3.0)*exp(-delta*3.0)
	# A hit's knock-back becomes sliding momentum instead of a short hop.
	if g.knock_velocity.length()>.1: roll+=g.knock_velocity*.35;g.knock_velocity=Vector3.ZERO
	if g.player.is_on_wall():
		var wall=g.player.get_wall_normal();wall.y=0
		if roll.dot(wall)<0: roll=roll.bounce(wall.normalized())*.4
	# Lengthways he slides; sideways the curve and bumps drag.
	var along=axis*roll.dot(axis);var across=roll-along
	along=along.move_toward(Vector3.ZERO,ROLL_FRICTION*delta);across=across.move_toward(Vector3.ZERO,ROLL_FRICTION*ACROSS_FRICTION*delta)
	roll=(along+across).limit_length(ROLL_MAX)
	if is_instance_valid(g.avatar): g.avatar.rotation.y+=spin*delta
	# The lying model only rocks a little toward the side he is pushed to.
	var model=g.avatar.find_child("CartoonModel",true,false) if is_instance_valid(g.avatar) else null
	if model!=null:
		var side=Vector3.UP.cross(axis).normalized()
		var lean=clampf(Vector3(g.player.velocity.x,0,g.player.velocity.z).dot(side)*.07,-.35,.35)+sin(g.elapsed*2.3)*.02
		rock=lerpf(rock,lean,minf(1.0,delta*6.0));model.rotation.x=rock

# --- Flower roots under the island (Digby Mole) ---------------------------------

# Every flower grows roots down through the island (user, November 2). Only
# Digby Mole sees them, glowing green on the belly, and eats them to heal.
# Each island also has its own wild roots hanging from the belly (user: "I saw
# no flower roots in the underworld"), which grow back ROOT_REGROW s after a munch.
const ROOT_REACH=2.4
const ROOT_HEAL=.08
const WILD_ROOTS=18
const ROOT_REGROW=40.0
static var roots={}
static var root_clock=0.0
static var root_material: StandardMaterial3D

static func update_roots(g,delta: float,force_under: bool=false):
	root_clock-=delta
	if root_clock>0 and not force_under: return
	root_clock=.3
	var mole=id(g)=="mole"
	var sources={}
	if mole:
		for flower in g.flowers:
			if is_instance_valid(flower.get("node")): sources["l"+str(flower.node.get_instance_id())]=flower.node.position
		for key in g.coop.flower_visuals:
			if is_instance_valid(g.coop.flower_visuals[key]): sources["r"+str(key)]=g.coop.flower_visuals[key].position
		if g.world.realm!=3:
			var rng=RandomNumberGenerator.new();rng.seed=int(g.seed_value)*31+int(g.world.realm)
			for i in range(WILD_ROOTS):
				var a=rng.randf()*TAU;var edge=Vector3(cos(a),0,sin(a))
				var reach=g.world.shore_radius(edge*40.0)-Underside.INSET*2.0
				var spot=edge*reach*sqrt(rng.randf_range(.04,1.0))
				sources["w%d_%d_%d" % [int(g.seed_value),int(g.world.realm),i]]=spot
	for key in roots.keys():
		if not sources.has(key):
			if is_instance_valid(roots[key].node): roots[key].node.queue_free()
			roots.erase(key)
	for key in sources:
		if not roots.has(key): roots[key]={"node":grow_root(g,sources[key]),"eaten":false,"eaten_at":0.0}
		elif roots[key].eaten and str(key).begins_with("w") and g.elapsed-float(roots[key].get("eaten_at",0.0))>ROOT_REGROW:
			roots[key].eaten=false
			if is_instance_valid(roots[key].node): roots[key].node.visible=true
	if not mole or not (force_under or g.underside.flipped()): return
	var p=g.player.position
	for key in roots:
		var root=roots[key]
		if root.eaten or not is_instance_valid(root.node): continue
		var at: Vector3=root.node.position
		if Vector2(at.x-p.x,at.z-p.z).length()<ROOT_REACH:
			root.eaten=true;root.eaten_at=g.elapsed;root.node.visible=false
			g.heal(g.stats.maxHp*ROOT_HEAL);g.burst(at+Vector3.DOWN*.8,Color("7dff6a"),8);g.sound.effect("heal",at)
			HeroTricks.word(g,"MUNCH! +%d ♥" % roundi(g.stats.maxHp*ROOT_HEAL),Color("9dff7a"))

static func grow_root(g,top: Vector3) -> Node3D:
	if root_material==null:
		root_material=StandardMaterial3D.new();root_material.albedo_color=Color("5a8a3a");root_material.emission_enabled=true
		root_material.emission=Color("6dff4a");root_material.emission_energy_multiplier=1.6
	var node=Node3D.new();node.name="FlowerRoot";g.add_child(node)
	node.position=Vector3(top.x,g.world.under_height(top.x,top.z),top.z)
	for k in range(7):
		var a=k*.9;var length=1.2+.35*(k%3)
		var strand=MeshInstance3D.new();var tube=CylinderMesh.new();tube.top_radius=.14;tube.bottom_radius=.03;tube.height=length;tube.radial_segments=6;tube.rings=1
		strand.mesh=tube;strand.material_override=root_material;strand.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(strand);strand.position=Vector3(cos(a)*.22,-length*.5,sin(a)*.22);strand.rotation=Vector3(sin(a)*.4,0,cos(a)*.4)
	# A glowing bulb at the tip: the bit Digby munches.
	var bulb=MeshInstance3D.new();var ball=SphereMesh.new();ball.radius=.3;ball.height=.55;ball.radial_segments=10;ball.rings=6
	bulb.mesh=ball;bulb.material_override=root_material;bulb.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(bulb);bulb.position=Vector3(0,-1.5,0)
	return node

static func taunts(hero_id: String) -> bool: return hero_id=="cactus"

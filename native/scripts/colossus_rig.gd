extends ActorRig
class_name ColossusRig

# The Ashen Colossus, the final boss, as a towering cartoon horror (user request,
# October 25: the golem was not good enough; an original design matching the
# cartoon roster). A squat mountain of flesh whose horror sits at eye level: a
# mouth across its whole belly, crooked teeth and a lolling tongue; seven
# mismatched glowing eyes on its chest around the glass health orb; two huge
# clawed arms and two tiny ones flapping on its chest; stubby legs; a spiked
# tail; and, on top, a tiny dumb head with an antenna. Its three phases repaint
# it purple, then icy blue, then magma red; the orb changes colour with them.
# ColossusFight picks the actions; this rig poses every part so each blow lands
# as its red marks go off. Built about 6.3 units tall, scaled to 17 m.

const MODEL_HEIGHT=6.3
const HEIGHT=17.0
const ORB_COLORS=[Color(.98,.025,.08),Color(.25,.7,1.0),Color(1.0,.42,.04)]
# Per phase: body, belly, spots, spikes and claws, glowing eyes, limbs, the little head.
const PAINTS=[
	{"body":"9b3fd6","belly":"ff7ad9","spot":"5b1f8a","spike":"ffe14a","glow":"7dff6a","limb":"7f2fb8","head":"ffb3c7"},
	{"body":"2f8fe0","belly":"9fe9ff","spot":"14508a","spike":"ffffff","glow":"ff4fd8","limb":"2470c0","head":"c9f3ff"},
	{"body":"e0401a","belly":"ffb35a","spot":"7a1a08","spike":"fff27d","glow":"fff27d","limb":"b82a0a","head":"ffd27a"}]

static var paint_shader: Shader
static var ink_shader: Shader
static var group_meshes={}

var model=Node3D.new()
var torso=Node3D.new()
var head_node=Node3D.new()
var jaw=Node3D.new()
var arms_nodes=[]
var elbows=[]
var legs_nodes=[]
var tail=[]
var skins=[]
var parts={}
var paint: ShaderMaterial
var ink: ShaderMaterial
var orb_paint: ShaderMaterial
var orb_fill=1.0
var phase_index=0
var health=1.0
var dead=false
var dead_time=0.0
# Current action: name, its wind-up, active and recovery seconds, time into it.
var action=""
var action_time=0.0
var windup=1.0
var active=.4
var recover=1.0
var exposed=false
var open_after=false
var roar_player=AudioStreamPlayer3D.new()

func setup(model_name: String):
	identity=model_name;skin=Color(PAINTS[0].body)
	body.free();head.free()
	add_child(model);model.scale=Vector3.ONE*HEIGHT/MODEL_HEIGHT
	body=torso;head=head_node
	if paint_shader==null:
		paint_shader=load("res://shaders/cartoon_creature.gdshader");ink_shader=load("res://shaders/cartoon_creature_outline.gdshader")
	paint=ShaderMaterial.new();paint.shader=paint_shader;ink=ShaderMaterial.new();ink.shader=ink_shader;paint.next_pass=ink
	for material in [paint,ink]: material.set_shader_parameter("size",MODEL_HEIGHT*.4)
	# Strong colours, little glow: the giant must not wash out to white.
	ink.set_shader_parameter("width",.016);paint.set_shader_parameter("self_light",.06);paint.set_shader_parameter("rim_strength",.45)
	batched=paint;hit_material=StandardMaterial3D.new()
	# The skeleton of nodes the actions pose. The jaw is the belly mouth's lower lip.
	model.add_child(torso);torso.position=Vector3(0,1.2,0)
	torso.add_child(head_node);head_node.position=Vector3(0,3.75,-.2)
	torso.add_child(jaw);jaw.position=Vector3(0,1.05,-1.1)
	for side in [-1.0,1.0]:
		var shoulder=Node3D.new();shoulder.position=Vector3(side*1.95,2.9,0);torso.add_child(shoulder);arms_nodes.append(shoulder)
		var elbow=Node3D.new();elbow.position=Vector3(side*.5,-1.4,-.3);shoulder.add_child(elbow);elbows.append(elbow)
		var hip=Node3D.new();hip.position=Vector3(side*1.1,1.2,0);model.add_child(hip);legs_nodes.append(hip)
	var parent: Node3D=torso
	for i in range(5):
		var segment=Node3D.new();segment.position=Vector3(0,.7,1.45) if i==0 else Vector3(0,-.05,.6);parent.add_child(segment);tail.append(segment);parent=segment
	for i in range(3): skins.append(i)
	paint_phase(0)
	# The glass health orb sits among the chest eyes, like a heart.
	var orb=MeshInstance3D.new();orb.name="GlassCore";var sphere=SphereMesh.new();sphere.radius=.42;sphere.height=.84;orb.mesh=sphere
	orb.position=Vector3(0,2.62,-1.42);orb.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;torso.add_child(orb)
	orb_paint=ShaderMaterial.new();orb_paint.shader=load("res://shaders/blood_core.gdshader");orb_paint.set_shader_parameter("radius",.42)
	orb_paint.set_shader_parameter("liquid_color",ORB_COLORS[0]);orb.material_override=orb_paint
	add_child(roar_player);roar_player.unit_size=40;roar_player.max_distance=220;roar_player.max_db=4
	var roar_sound=load("res://assets/audio/colossus/roar.wav")
	if roar_sound!=null: roar_player.stream=roar_sound

# --- the giant's parts, one merged mesh per moving group and phase -------------
static func group(phase: int,name: String) -> ArrayMesh:
	var key=name+str(phase)
	if group_meshes.has(key): return group_meshes[key]
	var p=PAINTS[phase];var m=CartoonMesh.new()
	var body_c=Color(p.body);var belly=Color(p.belly);var spot=Color(p.spot);var spike=Color(p.spike);var glow=Color(p.glow);var limb=Color(p.limb);var little=Color(p.head)
	match name:
		"torso":
			m.ball(Vector3(0,1.9,0),Vector3(4.0,3.6,3.0),body_c);m.ball(Vector3(0,1.55,-.85),Vector3(3.0,2.6,1.4),belly)
			m.spots(Vector3(0,1.9,0),Vector3(2.0,1.8,1.5),spot,12,.55,808)
			m.spots(Vector3(0,2.0,.2),Vector3(2.0,1.8,1.5),glow,8,.22,809,true)
			# The belly mouth: its cavity and upper teeth (the jaw is its own node).
			m.ball(Vector3(0,1.3,-1.35),Vector3(2.5,1.2,.8),CartoonMesh.MOUTH)
			for i in range(9):
				var x=-1.0+i*.25;var long=.22+.16*float((i*5)%3)
				m.spike(Vector3(x,1.82,-1.62),Vector3(x+.03,1.82-long,-1.66),.09,CartoonMesh.TOOTH)
			# Seven mismatched eyes on the chest, around the orb.
			for e in [[Vector3(-.75,2.8,-1.3),.42,Vector3(-.3,.1,-1)],[Vector3(.78,2.95,-1.25),.32,Vector3(.4,-.1,-1)],[Vector3(-.2,3.3,-1.15),.2,Vector3(0,.4,-1)],[Vector3(.35,3.35,-1.1),.16,Vector3(.5,.5,-1)],[Vector3(-1.3,2.35,-1.0),.2,Vector3(-.8,0,-1)],[Vector3(1.3,2.4,-1.0),.24,Vector3(.8,.1,-1)],[Vector3(0,2.15,-1.45),.15,Vector3(0,-.5,-1)]]:
				m.eye(e[0],e[1],e[2],glow,CartoonMesh.BODY,0.0,Vector2(0,1),true)
			# Two tiny vestigial arms flapping on the chest.
			for side in [-1.0,1.0]:
				var root=Vector3(side*.55,2.3,-1.4);var hand=root+Vector3(side*.35,-.25,-.35);var pivot=Vector2(root.y,1.0)
				m.rod(root,hand,.07,little,CartoonMesh.TAIL,.5 if side>0 else 0.0,pivot);m.ball(hand,Vector3.ONE*.18,little,CartoonMesh.TAIL,.5 if side>0 else 0.0,pivot)
			for i in range(6):
				var at=Vector3(0,3.4-i*.5,.9+i*.25);m.spike(at,at+Vector3(0,.55,.5),.24,spike)
		"head":
			m.ball(Vector3(0,.4,0),Vector3(1.1,1.0,1.0),little)
			m.eye(Vector3(-.2,.55,-.42),.16,Vector3(-.3,.2,-1));m.eye(Vector3(.22,.5,-.42),.11,Vector3(.5,-.2,-1))
			m.ball(Vector3(0,.22,-.47),Vector3(.3,.1,.06),CartoonMesh.MOUTH)
			m.ball(Vector3(.12,.12,-.48),Vector3(.05,.16,.05),Color("d4f6ff"),CartoonMesh.TAIL,.3,Vector2(.2,.5))
			m.antenna(Vector3(0,.85,0),Vector3(.15,1.35,.05),.12,little,glow)
		"jaw":
			m.ball(Vector3(0,-.15,-.3),Vector3(2.7,.62,1.0),belly)
			for i in range(8):
				var x=-.88+i*.25;var long=.18+.14*float((i*7)%3)
				m.spike(Vector3(x,.05,-.68),Vector3(x,.05+long,-.7),.08,CartoonMesh.TOOTH)
			for i in range(6): m.ball(Vector3(.25,-.1-i*.12,-.75-i*.2),Vector3(.55-i*.04,.14,.32),CartoonMesh.TONGUE,CartoonMesh.TAIL,0.0,Vector2(0,.4))
		"upper_l","upper_r":
			var s=-1.0 if name=="upper_l" else 1.0
			m.rod(Vector3.ZERO,Vector3(s*.5,-1.4,-.3),.5,limb);m.ball(Vector3.ZERO,Vector3.ONE*1.15,body_c)
		"fore_l","fore_r":
			var s=-1.0 if name=="fore_l" else 1.0
			m.rod(Vector3.ZERO,Vector3(s*.2,-1.5,-.6),.45,limb);m.ball(Vector3(s*.22,-1.8,-.72),Vector3(1.2,.95,1.2),body_c)
			for f in range(3):
				var dx=(f-1)*.33;m.spike(Vector3(s*.22+dx,-2.1,-1.0),Vector3(s*.22+dx*1.3,-2.6,-1.35),.15,spike)
		"leg":
			m.rod(Vector3.ZERO,Vector3(0,-.95,0),.6,limb);m.ball(Vector3(0,-1.1,-.3),Vector3(1.45,.5,1.7),body_c)
			for f in range(3):
				var dx=(f-1)*.42;m.spike(Vector3(dx,-1.15,-1.05),Vector3(dx,-1.2,-1.45),.14,spike)
		"tail":
			m.ball(Vector3.ZERO,Vector3.ONE*.8,body_c);m.spike(Vector3(0,.3,0),Vector3(0,.75,.2),.16,spike)
		"tip":
			m.ball(Vector3.ZERO,Vector3.ONE*.5,body_c);m.spike(Vector3(0,0,.15),Vector3(0,.1,.9),.22,spike)
	group_meshes[key]=m.commit()
	return group_meshes[key]

func piece(parent: Node3D,phase: int,name: String,key: String):
	var node: MeshInstance3D=parts.get(key)
	if node==null:
		node=MeshInstance3D.new();node.material_override=paint;parent.add_child(node);parts[key]=node
	node.mesh=group(phase,name)

func paint_phase(phase: int):
	piece(torso,phase,"torso","torso");piece(head_node,phase,"head","head");piece(jaw,phase,"jaw","jaw")
	for i in range(2):
		piece(arms_nodes[i],phase,"upper_l" if i==0 else "upper_r","upper"+str(i));piece(elbows[i],phase,"fore_l" if i==0 else "fore_r","fore"+str(i))
		piece(legs_nodes[i],phase,"leg","leg"+str(i))
	for i in range(tail.size()):
		piece(tail[i],phase,"tip" if i==tail.size()-1 else "tail","tail"+str(i))
		tail[i].scale=Vector3.ONE*(1.0-i*.12)
	skin=Color(PAINTS[phase].body)

# --- ActorRig interface ------------------------------------------------------
func set_health(fraction: float,_tank: bool=false):
	health=clampf(fraction,0,1)
	if health<=0 and not dead: dead=true;action=""

func set_defense(_armour: float,_shield_value: float,_shield_capacity: float): pass
func statuses(_fire: bool,_poison: bool,_frozen: bool,_blind: bool): pass

func set_phase(index: int):
	phase_index=clampi(index,0,2)
	paint_phase(phase_index)
	orb_paint.set_shader_parameter("liquid_color",ORB_COLORS[phase_index])
	scale=Vector3.ONE*(1.0+phase_index*.05)

# Starts an action; animate() poses it so the blow lands at the end of the wind-up.
func play(name: String,windup_seconds: float,active_seconds: float,recover_seconds: float,open_after_blow: bool=false):
	if dead: return
	action=name;action_time=0.0;windup=maxf(.1,windup_seconds);active=maxf(.05,active_seconds);recover=maxf(.1,recover_seconds);exposed=false;open_after=open_after_blow
	if name=="roar": roar()

func roar():
	if roar_player.stream!=null: roar_player.play()

# Wind-up 0 -> 1, strike 0 -> 1, then recovery 1 -> 0.
func stages() -> Vector3:
	var t=action_time
	var coil=clampf(t/windup,0,1);var strike=clampf((t-windup)/active,0,1)
	var back=1.0-clampf((t-windup-active)/recover,0,1) if t>windup+active else 1.0
	return Vector3(smoothstep(0,1,coil),smoothstep(0,1,strike),back)

func animate(delta: float,movement: Vector3,_on_floor: bool=true,_slamming: bool=false):
	clock+=delta;hurt=maxf(0,hurt-delta);attack=maxf(0,attack-delta)
	var walk=clampf(Vector2(movement.x,movement.z).length()/3.0,0,1)
	for material in [paint,ink]:
		material.set_shader_parameter("clock",clock);material.set_shader_parameter("moving",0.0);material.set_shader_parameter("hurt",clampf(hurt*3.0,0,.12))
	# Rest pose: breathing, swaying arms, a lazy tail, a wobbling little head.
	var breathe=sin(clock*1.4)
	torso.rotation=Vector3(.05+breathe*.02,0,sin(clock*.7)*.03);torso.position=Vector3(0,1.2+breathe*.05,0)
	head_node.rotation=Vector3(sin(clock*.9)*.08,sin(clock*.6)*.25,sin(clock*1.3)*.1);jaw.rotation=Vector3(.08+sin(clock*1.8)*.06,0,0)
	for i in range(2):
		var s=-1.0 if i==0 else 1.0
		arms_nodes[i].rotation=Vector3(sin(clock*1.1+i)*.08,0,s*(.18+breathe*.03));elbows[i].rotation=Vector3(-.25,0,0)
		legs_nodes[i].rotation=Vector3(sin(clock*4.5+i*PI)*.45*walk,0,0)
	for i in range(tail.size()): tail[i].rotation=Vector3(-.2+sin(clock*1.3+i*.6)*.08,sin(clock*1.1+i*.7)*.25,0)
	model.rotation=Vector3.ZERO;model.position=Vector3.ZERO
	if dead:
		dead_time+=delta
		var fall=smoothstep(0,1,dead_time/1.6)
		model.rotation.x=-fall*1.35;model.position.y=-fall*1.2;jaw.rotation.x=.6*fall
	elif action!="":
		action_time+=delta
		pose(stages())
		exposed=open_after and action_time>windup+active
		if action_time>=windup+active+recover: action="";exposed=false
	orb_fill=move_toward(orb_fill,health,delta*.6)
	orb_paint.set_shader_parameter("fill",orb_fill)
	orb_paint.set_shader_parameter("hit",clampf(hurt*4.0+(.35+.25*sin(clock*12.0) if exposed else 0.0),0,1))

# Each action's pose: k.x is the wind-up, k.y the strike, k.z fades back to rest.
func pose(k: Vector3):
	var w=k.x*k.z;var s=k.y*k.z
	match action:
		"sweep":
			# Right arm hauls back, then sweeps across from right to left.
			arms_nodes[1].rotation=Vector3(-1.2*w,lerpf(.9*w,-1.6,s)*k.z,.25+1.1*w-.6*s)
			torso.rotation.y=.35*w-.7*s
		"slam","leap":
			# Both arms rise overhead, then come crashing down.
			for i in range(2): arms_nodes[i].rotation=Vector3(-2.6*w+2.9*s,0,(-1.0 if i==0 else 1.0)*.3)
			torso.rotation.x=.05-.25*w+.5*s
			if action=="leap":
				for leg in legs_nodes: leg.rotation.x=-.6*w+.6*s
		"stomp":
			legs_nodes[1].rotation.x=-1.0*w+1.0*s;torso.rotation.x=.05+.15*s;torso.position.y=1.2+.25*w-.35*s
		"lunge":
			torso.rotation.x=.05+.5*maxf(w,s)
			for i in range(2): arms_nodes[i].rotation.x=-1.3*maxf(w,s)
		"breath":
			# Rears back, then the belly mouth gapes.
			torso.rotation.x=-.2*w+.15*s;jaw.rotation.x=.08+.75*maxf(w*.4,s)
		"tail":
			model.rotation.y=-TAU*s+.4*w
			for segment in tail: segment.rotation.y+=.5*s
		"roar":
			jaw.rotation.x=.08+.8*maxf(w,s);head_node.rotation.z=sin(clock*30.0)*.2*maxf(w,s)
			for i in range(2): arms_nodes[i].rotation.z=(-1.0 if i==0 else 1.0)*(.2+1.0*maxf(w,s))
			torso.position.x=sin(clock*40.0)*.03*s
	if action in ["sweep","slam","stomp","roar"]: jaw.rotation.x=maxf(jaw.rotation.x,.08+.45*s)

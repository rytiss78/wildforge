extends ActorRig
class_name ColossusRig

# The final boss as a colossal head floating in the sky (user request, October 26;
# an original design): a bald giant head rising out of a glowing portal ring, big
# ears, a bulbous nose, a heavy wrinkled brow and a huge mouth of square teeth.
# Its two huge glass eyes ARE its health orbs: their liquid drains as it is hurt
# and changes colour with the phase (red, icy blue, orange); lids blink over them.
# Two giant floating hands do the sweeps and slams; the head itself head-butts the
# ground, spins, lunges and roars. Its skin repaints with the phase. ColossusFight
# picks the actions; this rig poses the head and hands so each blow lands as its
# red marks go off. Built about 6.3 units tall, scaled to 17 m.

const MODEL_HEIGHT=6.3
const HEIGHT=17.0
const ORB_COLORS=[Color(.98,.025,.08),Color(.25,.7,1.0),Color(1.0,.42,.04)]
# Per phase: skin, shadow (brow, ears, lips), portal glow, teeth.
const PAINTS=[
	{"skin":"8fd6a0","shade":"5fa874","glow":"c97aff","lip":"3f7a52"},
	{"skin":"7ab8ff","shade":"4a86d6","glow":"7dfffb","lip":"2f5aa8"},
	{"skin":"ff8a4a","shade":"d0582a","glow":"fff27d","lip":"8a2a10"}]
const HEAD_CENTER=Vector3(0,4.2,0)
const EYE_RADIUS=1.0
# Big bulging eyes, set forward of the face so the whole orb reads.
const EYES=[Vector3(-1.02,.32,-1.78),Vector3(1.02,.32,-1.78)]
const HAND_REST=[Vector3(-3.3,2.2,-1.2),Vector3(3.3,2.2,-1.2)]

static var paint_shader: Shader
static var ink_shader: Shader
static var group_meshes={}

var model=Node3D.new()
var floater=Node3D.new()
var head_node=Node3D.new()
var jaw=Node3D.new()
var portal=Node3D.new()
var hands=[]
var lids=[]
var eyes=[]
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
var blink_clock=2.0
# Current action: name, its wind-up, active and recovery seconds, time into it.
var action=""
var action_time=0.0
var windup=1.0
var active=.4
var recover=1.0
var exposed=false
var open_after=false
# Seconds left of cracked eyes after a successful performance (they flash, open).
var crack_time=0.0
var roar_player=AudioStreamPlayer3D.new()

func setup(model_name: String):
	identity=model_name;skin=Color(PAINTS[0].skin)
	body.free();head.free()
	add_child(model);model.scale=Vector3.ONE*HEIGHT/MODEL_HEIGHT
	model.add_child(floater);floater.add_child(head_node);head_node.position=HEAD_CENTER
	head_node.add_child(jaw);jaw.position=Vector3(0,-1.25,-1.05)
	floater.add_child(portal);portal.position=Vector3(0,1.55,0)
	body=head_node;head=head_node
	if paint_shader==null:
		paint_shader=load("res://shaders/cartoon_creature.gdshader");ink_shader=load("res://shaders/cartoon_creature_outline.gdshader")
	paint=ShaderMaterial.new();paint.shader=paint_shader;ink=ShaderMaterial.new();ink.shader=ink_shader;paint.next_pass=ink
	for material in [paint,ink]: material.set_shader_parameter("size",MODEL_HEIGHT*.4)
	# Strong colours, little glow: the giant must not wash out to white.
	ink.set_shader_parameter("width",.016);paint.set_shader_parameter("self_light",.06);paint.set_shader_parameter("rim_strength",.45)
	batched=paint;hit_material=StandardMaterial3D.new()
	for i in range(2):
		var hand=Node3D.new();hand.position=HAND_REST[i];floater.add_child(hand);hands.append(hand)
		var lid=Node3D.new();lid.position=EYES[i];head_node.add_child(lid);lids.append(lid)
	for i in range(3): skins.append(i)
	paint_phase(0)
	# The two eyes are the health orbs: one liquid, filled together.
	var sphere=SphereMesh.new();sphere.radius=EYE_RADIUS;sphere.height=EYE_RADIUS*2;sphere.radial_segments=32;sphere.rings=16
	orb_paint=ShaderMaterial.new();orb_paint.shader=load("res://shaders/blood_core.gdshader");orb_paint.set_shader_parameter("radius",EYE_RADIUS)
	orb_paint.set_shader_parameter("liquid_color",ORB_COLORS[0])
	for i in range(2):
		var eye=MeshInstance3D.new();eye.name="GlassCore" if i==0 else "GlassCoreRight";eye.mesh=sphere;eye.position=EYES[i]
		eye.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;eye.material_override=orb_paint;head_node.add_child(eye);eyes.append(eye)
	add_child(roar_player);roar_player.unit_size=40;roar_player.max_distance=220;roar_player.max_db=4
	var roar_sound=load("res://assets/audio/colossus/roar.wav")
	if roar_sound!=null: roar_player.stream=roar_sound

# --- the head's parts, one merged mesh per moving group and phase -------------
static func group(phase: int,name: String) -> ArrayMesh:
	var key=name+str(phase)
	if group_meshes.has(key): return group_meshes[key]
	var p=PAINTS[phase];var m=CartoonMesh.new()
	var skin_c=Color(p.skin);var shade=Color(p.shade);var glow=Color(p.glow);var lip=Color(p.lip)
	match name:
		"head":
			# A big bald dome, slightly pear-shaped, wider at the cheeks.
			m.ball(Vector3(0,.25,0),Vector3(4.4,4.6,4.0),skin_c);m.ball(Vector3(0,-.75,-.35),Vector3(4.0,2.4,3.4),skin_c)
			# A heavy brow above the eyes (not over them), with wrinkles above it.
			for side in [-1.0,1.0]: m.ball(Vector3(side*1.0,1.5,-1.62),Vector3(1.7,.42,.8),shade,CartoonMesh.BODY,0.0,Vector2(0,1),false,Vector3(0,0,side*-.18))
			for k in range(3): m.rod(Vector3(-1.0+k*.1,1.95+k*.24,-1.4+k*.1),Vector3(1.0-k*.1,1.95+k*.24,-1.4+k*.1),.045,shade)
			for side in [-1.0,1.0]:
				# A rim round each eye where it bulges out of the face.
				m.ring(Vector3(side*1.02,.32,-1.62),EYE_RADIUS*1.0,.16,shade,Vector3(PI*.5,0,0))
				# A black pupil on the front of each glass eye; the liquid shows all round it.
				m.ball(EYES[0 if side<0 else 1]+Vector3(side*.08,-.05,-EYE_RADIUS*.97),Vector3(.42,.46,.12),CartoonMesh.INK)
				m.ball(EYES[0 if side<0 else 1]+Vector3(side*.08-.08,.08,-EYE_RADIUS*1.0),Vector3(.12,.12,.05),Color("ffffff"))
				# Big ears.
				m.ball(Vector3(side*2.15,.0,.1),Vector3(.55,1.3,.95),skin_c);m.ball(Vector3(side*2.3,0,.05),Vector3(.25,.9,.6),shade)
			# A bulbous nose with nostrils.
			m.ball(Vector3(0,-.55,-2.1),Vector3(.95,.8,.85),skin_c)
			for side in [-1.0,1.0]: m.ball(Vector3(side*.2,-.8,-2.4),Vector3(.2,.12,.12),CartoonMesh.INK)
			# The upper lip, the mouth cavity and a row of big square teeth.
			m.ball(Vector3(0,-1.05,-1.75),Vector3(2.5,.42,.7),lip);m.ball(Vector3(0,-1.32,-1.55),Vector3(2.2,.55,.6),CartoonMesh.MOUTH)
			for i in range(8): m.box(Vector3(-.84+i*.24,-1.18,-1.95),Vector3(.21,.26,.12),CartoonMesh.TOOTH)
			# Cheeks with a glow of freckles.
			for side in [-1.0,1.0]: m.ball(Vector3(side*1.35,-.55,-1.4),Vector3(.75,.55,.5),shade)
			m.spots(Vector3(0,1.2,.3),Vector3(1.9,.9,1.6),glow,6,.18,909,true)
		"jaw":
			m.ball(Vector3(0,-.18,-.25),Vector3(2.4,.7,1.1),skin_c);m.ball(Vector3(0,.06,-.62),Vector3(2.3,.32,.5),lip)
			for i in range(8): m.box(Vector3(-.84+i*.24,.22,-.82),Vector3(.21,.24,.12),CartoonMesh.TOOTH)
			m.ball(Vector3(.2,.12,-.55),Vector3(.9,.18,.7),CartoonMesh.TONGUE)
		"lid":
			# An upper eyelid: a skin shell over the top of the eye, lowered to blink.
			m.ball(Vector3(0,EYE_RADIUS*.72,.05),Vector3(EYE_RADIUS*2.25,EYE_RADIUS*.62,EYE_RADIUS*2.25),skin_c)
		"hand_l","hand_r":
			var s=-1.0 if name=="hand_l" else 1.0
			m.ball(Vector3.ZERO,Vector3(1.25,.48,1.15),skin_c)
			for f in range(4):
				var root=Vector3(s*(-.36+f*.24),0,-.45);m.rod(root,root+Vector3(s*(-.08+f*.05),-.22,-.75),.12,skin_c);m.ball(root+Vector3(s*(-.08+f*.05),-.24,-.8),Vector3.ONE*.24,shade)
			m.rod(Vector3(-s*.55,0,-.1),Vector3(-s*1.05,-.15,-.45),.14,skin_c)
			m.ring(Vector3(0,.0,.45),.5,.12,glow,Vector3(PI*.5,0,0))
		"portal":
			# The glowing ring the head rises out of.
			m.ring(Vector3.ZERO,2.3,.35,glow);m.ring(Vector3(0,.05,0),1.9,.12,Color("ffffff"))
			for i in range(10): m.ball(Vector3(cos(i*TAU/10),0,sin(i*TAU/10))*2.3,Vector3.ONE*.28,Color("ffffff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
	group_meshes[key]=m.commit()
	return group_meshes[key]

func piece(parent: Node3D,phase: int,name: String,key: String):
	var node: MeshInstance3D=parts.get(key)
	if node==null:
		node=MeshInstance3D.new();node.material_override=paint;parent.add_child(node);parts[key]=node
	node.mesh=group(phase,name)

func paint_phase(phase: int):
	piece(head_node,phase,"head","head");piece(jaw,phase,"jaw","jaw");piece(portal,phase,"portal","portal")
	for i in range(2):
		piece(hands[i],phase,"hand_l" if i==0 else "hand_r","hand"+str(i));piece(lids[i],phase,"lid","lid"+str(i))
	skin=Color(PAINTS[phase].skin)

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

# A successful performance cracks its eyes: they flash and stay wide open.
func crack(seconds: float):
	crack_time=seconds

# Wind-up 0 -> 1, strike 0 -> 1, then recovery 1 -> 0.
func stages() -> Vector3:
	var t=action_time
	var coil=clampf(t/windup,0,1);var strike=clampf((t-windup)/active,0,1)
	var back=1.0-clampf((t-windup-active)/recover,0,1) if t>windup+active else 1.0
	return Vector3(smoothstep(0,1,coil),smoothstep(0,1,strike),back)

func animate(delta: float,movement: Vector3,_on_floor: bool=true,_slamming: bool=false):
	clock+=delta;hurt=maxf(0,hurt-delta);attack=maxf(0,attack-delta)
	var glide=clampf(Vector2(movement.x,movement.z).length()/3.0,0,1)
	for material in [paint,ink]:
		material.set_shader_parameter("clock",clock);material.set_shader_parameter("moving",0.0);material.set_shader_parameter("hurt",clampf(hurt*3.0,0,.12))
	# Rest pose: the head bobs in the air and leans into its glide; the hands drift.
	model.rotation=Vector3.ZERO;model.position=Vector3.ZERO
	floater.position=Vector3(0,sin(clock*.8)*.18,0);floater.rotation=Vector3(.06*glide,0,sin(clock*.5)*.04)
	head_node.position=HEAD_CENTER;head_node.rotation=Vector3(sin(clock*.7)*.04,sin(clock*.45)*.12,0)
	jaw.rotation=Vector3(.05+sin(clock*1.6)*.05,0,0)
	portal.rotation.y+=delta*.6;portal.scale=Vector3.ONE*(1.0+sin(clock*2.0)*.04)
	for i in range(2):
		var s=-1.0 if i==0 else 1.0
		hands[i].position=HAND_REST[i]+Vector3(0,sin(clock*1.1+i*1.7)*.25,sin(clock*.8+i)*.15)
		hands[i].rotation=Vector3(sin(clock*.9+i)*.1,s*.25,s*sin(clock*1.3)*.1)
	# Blink now and then; the lids also close when hurt and when it is dead.
	blink_clock-=delta
	if blink_clock<-.18: blink_clock=randf_range(2.5,5.5)
	var lid_down=1.0 if blink_clock<0 or dead else clampf(hurt*5.0,0,.6)
	# At rest the lids are rolled back over the top of the eyes, so the whole orb shows.
	# (A positive turn about X rolls the lid towards the back of the head.)
	for lid in lids: lid.rotation.x=lerpf(lid.rotation.x,1.2-lid_down*1.9,1-exp(-delta*25))
	if dead:
		dead_time+=delta
		var fall=smoothstep(0,1,dead_time/2.0)
		floater.position.y=-fall*2.6;floater.rotation.z=fall*.5;jaw.rotation.x=.7*fall
		for i in range(2): hands[i].position.y=lerpf(hands[i].position.y,.3,fall)
		portal.scale=Vector3.ONE*(1.0-fall*.9)
	elif action!="":
		action_time+=delta
		pose(stages())
		exposed=open_after and action_time>windup+active
		if action_time>=windup+active+recover: action="";exposed=false
	crack_time=maxf(0,crack_time-delta)
	if crack_time>0:
		exposed=true
		for lid in lids: lid.rotation.x=1.2
	orb_fill=move_toward(orb_fill,health,delta*.6)
	orb_paint.set_shader_parameter("fill",orb_fill)
	orb_paint.set_shader_parameter("hit",clampf(hurt*4.0+(.35+.25*sin(clock*12.0) if exposed else 0.0),0,1))

# Each action's pose: k.x is the wind-up, k.y the strike, k.z fades back to rest.
func pose(k: Vector3):
	var w=k.x*k.z;var s=k.y*k.z
	match action:
		"sweep":
			# The right hand hauls back, then sweeps across from right to left.
			hands[1].position=HAND_REST[1].lerp(Vector3(4.2,1.4,.6),w).lerp(Vector3(-4.0,.8,-2.6),s)
			hands[1].rotation.z=.6*w-.4*s;head_node.rotation.y=.35*w-.6*s
		"slam","leap":
			# Both hands rise high, then come crashing down in front.
			for i in range(2):
				var side=-1.0 if i==0 else 1.0
				hands[i].position=HAND_REST[i].lerp(Vector3(side*2.2,6.5,-1.5),w).lerp(Vector3(side*1.3,.3,-3.2),s)
			head_node.rotation.x=-.2*w+.3*s
			if action=="leap": floater.position.y+=1.4*w-1.4*s
		"stomp":
			# A head-butt: the whole head rears up, then drops onto the ground.
			floater.position.y+=1.0*w-3.2*s;head_node.rotation.x=-.3*w+.45*s
		"lunge":
			floater.rotation.x=.45*maxf(w,s);floater.position.z=-1.2*s
			for i in range(2): hands[i].position.z=HAND_REST[i].z-2.2*maxf(w,s)
		"breath":
			# Rears back, then the mouth gapes wide.
			head_node.rotation.x=-.3*w+.15*s;jaw.rotation.x=.05+.85*maxf(w*.3,s)
		"tail":
			# The whole head spins round with its hands out like blades.
			model.rotation.y=-TAU*s+.4*w
			for i in range(2): hands[i].position.x=HAND_REST[i].x*(1.0+.5*maxf(w,s))
		"perform":
			# It conducts the show: hands beat time, the head bobs, the mouth sings.
			var beat=maxf(w,s)
			for i in range(2):
				var side=-1.0 if i==0 else 1.0
				hands[i].position=HAND_REST[i].lerp(Vector3(side*2.6,3.6+sin(action_time*4.83+i*PI)*1.2,-2.2),beat)
				hands[i].rotation.z=side*sin(action_time*4.83)*.4*beat
			floater.position.y+=absf(sin(action_time*4.83))*.35*beat
			head_node.rotation.z=sin(action_time*2.4)*.12*beat
			jaw.rotation.x=.08+(.3+.25*sin(action_time*9.66))*beat
		"roar":
			jaw.rotation.x=.05+.9*maxf(w,s);head_node.rotation.z=sin(clock*30.0)*.06*maxf(w,s)
			for i in range(2): hands[i].position.y=HAND_REST[i].y+2.0*maxf(w,s)
	if action in ["sweep","slam","stomp","roar"]: jaw.rotation.x=maxf(jaw.rotation.x,.05+.45*s)

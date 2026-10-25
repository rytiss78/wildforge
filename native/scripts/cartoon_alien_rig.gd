extends ActorRig
class_name CartoonAlienRig

# A test enemy in a gross-out cartoon sci-fi style (user request, October 25): an
# original creature, the Gloop Gazer, not a copy of any show's character. A squat
# lime blob with three eyes on wobbly stalks looking every which way, a wide mouth
# of crooked teeth with a lolling tongue and drool, stubby legs, and bold black
# cartoon outlines (shaders/cartoon_outline.gdshader). Its health shows in a glass
# gut-sac under the mouth, like every enemy's orb. Built at 1.45 m, the Briar
# Beetle's height, from primitives so it animates without a skeleton.

const HEIGHT=1.45
const COLORS={"body":Color("8fd14f"),"spot":Color("5f9e35"),"mouth":Color("3b0c1c"),"tooth":Color("fff3d2"),"tongue":Color("ff7aa0"),"leg":Color("79bd42"),"foot":Color("4c8a2b"),"white":Color("ffffff"),"pupil":Color("121014"),"drool":Color("d4f6ff"),"wart":Color("b4e46a")}
# Eye stalks: base position on the head, lean (x, z) and eyeball radius.
const EYES=[[Vector3(0,.96,-.08),Vector2(-.15,0),.2],[Vector3(-.3,.9,0),Vector2(-.05,.45),.13],[Vector3(.29,.92,.04),Vector2(.05,-.5),.11]]
static var paints={}
static var outline: Shader

var squash=Node3D.new()
var jaw=Node3D.new()
var mouth: MeshInstance3D
var tongue: MeshInstance3D
var drool=[]
var stalks=[]
var eyeballs=[]
var pupils=[]
var looks=[]
var look_clock=0.0
var orb_paint: ShaderMaterial
var health=1.0
var orb_fill=1.0

func setup(model_name: String):
	identity=model_name;skin=COLORS.body
	body.free();head.free()
	body=squash;head=squash;add_child(squash)
	hit_material=paint(COLORS.body)
	# Body: a squat pear of a blob, with darker spots and a few warts.
	part(squash,sphere(.5),"body",Vector3(0,.62,0),Vector3(1.25,.95,1.1))
	for spot in [[Vector3(.42,.78,.18),.11],[Vector3(-.45,.66,.22),.09],[Vector3(.2,.95,.35),.08],[Vector3(-.25,.98,.3),.1],[Vector3(.5,.55,-.1),.07],[Vector3(-.12,.5,.48),.09]]:
		# Flattened against the body: the disc faces out from the body's centre.
		var patch=part(squash,sphere(spot[1]),"spot",spot[0])
		patch.basis=Basis.looking_at(spot[0]-Vector3(0,.62,0),Vector3.UP).scaled(Vector3(1,1,.4))
	for wart in [Vector3(.36,1.0,-.12),Vector3(-.4,.86,-.28),Vector3(.1,1.06,.22)]: part(squash,sphere(.045),"wart",wart)
	# Mouth: a wide dark cavity, crooked upper teeth, and a jaw holding the lower
	# teeth and the tongue, which drops open on an attack.
	mouth=part(squash,sphere(.5),"mouth",Vector3(0,.66,-.43),Vector3(.7,.28,.3))
	var upper=[[-.27,.07],[-.17,.1],[-.07,.06],[.04,.11],[.15,.07],[.25,.09]]
	for tooth in upper: part(squash,cone(.035,tooth[1]),"tooth",Vector3(tooth[0],.75-tooth[1]*.5,-.56),Vector3.ONE,Vector3(PI,0,0))
	squash.add_child(jaw);jaw.position=Vector3(0,.64,-.4)
	for tooth in [[-.22,.06],[-.1,.08],[.02,.05],[.13,.09],[.23,.06]]: part(jaw,cone(.03,tooth[1]),"tooth",Vector3(tooth[0],-.06+tooth[1]*.5,-.17))
	tongue=part(jaw,sphere(.5),"tongue",Vector3(.07,-.06,-.26),Vector3(.2,.07,.34))
	tongue.rotation.x=.35
	for side in [-.24,.27]:
		var drop=part(squash,sphere(.5),"drool",Vector3(side,.52,-.52),Vector3(.045,.16,.045));drool.append(drop)
	# The glass gut-sac carries the health, like every enemy's orb.
	var orb=MeshInstance3D.new();orb.name="GlassCore";orb.mesh=sphere(.15);orb.position=Vector3(0,.36,-.44);orb.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;squash.add_child(orb)
	orb_paint=ShaderMaterial.new();orb_paint.shader=load("res://shaders/blood_core.gdshader");orb_paint.set_shader_parameter("radius",.15);orb_paint.set_shader_parameter("liquid_color",Color(.98,.025,.08));orb.material_override=orb_paint
	# Three eyes on stalks of different heights, each with its own darting pupil.
	for eye in EYES:
		var stalk=Node3D.new();stalk.position=eye[0];stalk.rotation=Vector3(eye[1].x,0,eye[1].y);squash.add_child(stalk);stalks.append(stalk)
		var length=.3+eye[2]*.8
		part(stalk,cylinder(.04,length),"body",Vector3(0,length*.5,0))
		var ball=part(stalk,sphere(eye[2]),"white",Vector3(0,length+eye[2]*.8,0));eyeballs.append(ball)
		var pupil=part(ball,sphere(eye[2]*.32),"pupil",Vector3(0,0,-eye[2]*.92));pupils.append(pupil);looks.append(Vector2.ZERO)
	# Four stubby legs with flat feet.
	for corner in [Vector2(-.36,-.22),Vector2(.36,-.22),Vector2(-.34,.26),Vector2(.34,.26)]:
		var leg=Node3D.new();leg.position=Vector3(corner.x,.3,corner.y);add_child(leg);legs.append(leg)
		part(leg,capsule(.1,.34),"leg",Vector3(0,-.12,0))
		part(leg,sphere(.5),"foot",Vector3(0,-.27,-.04),Vector3(.24,.1,.3))
	# Status effects reuse ActorRig's markers.
	for i in range(3):
		var flame=ToonArt.ball(squash,Color("ffad61"),Vector3((i-1)*.23,1.1,0),Vector3(.18,.4,.17));flame.visible=false;fire_nodes.append(flame)
		var droplet=ToonArt.ball(squash,Color("9cdc73"),Vector3((i-1)*.27,1.0,0),Vector3(.12,.14,.12));droplet.visible=false;poison_nodes.append(droplet)
		var crystal=ToonArt.tube(squash,Color("b2e6ee"),Vector3((i-1)*.22,.3,.1),0,.12,.4);crystal.visible=false;ice_nodes.append(crystal)
	blind_node=block(squash,Color("746382"),Vector3(0,1.45,0),Vector3(.5,.05,.05));blind_node.visible=false

# --- parts -------------------------------------------------------------------
static func paint(color: Color) -> StandardMaterial3D:
	var key=color.to_html()
	if paints.has(key): return paints[key]
	if outline==null: outline=load("res://shaders/cartoon_outline.gdshader")
	var material=StandardMaterial3D.new();material.albedo_color=color
	material.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON;material.specular_mode=BaseMaterial3D.SPECULAR_TOON;material.roughness=.55
	material.rim_enabled=true;material.rim=.35;material.rim_tint=.2
	var ink=ShaderMaterial.new();ink.shader=outline;material.next_pass=ink
	paints[key]=material
	return material

func part(parent: Node3D,mesh: Mesh,color_key: String,position_value: Vector3,scale_value: Vector3=Vector3.ONE,rotation_value: Vector3=Vector3.ZERO) -> MeshInstance3D:
	var node=MeshInstance3D.new();node.mesh=mesh;node.material_override=paint(COLORS[color_key])
	node.position=position_value;node.scale=scale_value;node.rotation=rotation_value;parent.add_child(node)
	return node

static func sphere(radius: float) -> SphereMesh:
	var mesh=SphereMesh.new();mesh.radius=radius;mesh.height=radius*2;mesh.radial_segments=24;mesh.rings=12;return mesh

static func cone(radius: float,height: float) -> CylinderMesh:
	var mesh=CylinderMesh.new();mesh.top_radius=0;mesh.bottom_radius=radius;mesh.height=height;mesh.radial_segments=8;mesh.rings=1;return mesh

static func cylinder(radius: float,height: float) -> CylinderMesh:
	var mesh=CylinderMesh.new();mesh.top_radius=radius*.8;mesh.bottom_radius=radius;mesh.height=height;mesh.radial_segments=10;mesh.rings=2;return mesh

static func capsule(radius: float,height: float) -> CapsuleMesh:
	var mesh=CapsuleMesh.new();mesh.radius=radius;mesh.height=height;mesh.radial_segments=12;mesh.rings=4;return mesh

# --- ActorRig interface ------------------------------------------------------
func set_health(fraction: float,_tank: bool=false): health=clampf(fraction,0,1)
func set_defense(_armour: float,_shield_value: float,_shield_capacity: float): pass
func bake_enemy(): pass

func animate(delta: float,movement: Vector3,on_floor: bool=true,_slamming: bool=false):
	clock+=delta;attack=maxf(0,attack-delta);hurt=maxf(0,hurt-delta)
	var walk=clampf(Vector2(movement.x,movement.z).length()/4.0,0,1)
	# A jelly wobble when idle, a bouncing hop when walking.
	var wobble=sin(clock*3.2)*.045+absf(sin(clock*9.0))*.06*walk
	squash.scale=Vector3(1-wobble*.6,1+wobble,1-wobble*.6)
	squash.position.y=absf(sin(clock*9.0))*.07*walk if on_floor else .05
	squash.rotation.z=sin(clock*1.7)*.035+(sin(hurt*45)*.12 if hurt>0 else 0.0)
	for i in range(legs.size()): legs[i].rotation.x=sin(clock*9.0+i*PI*.5+float(i%2)*PI)*.55*walk
	# Stalks sway out of step; pupils dart to a new spot now and then.
	look_clock-=delta
	if look_clock<=0:
		look_clock=randf_range(.5,1.4)
		for i in range(looks.size()): looks[i]=Vector2(randf_range(-.55,.55),randf_range(-.45,.4))
	for i in range(stalks.size()):
		var lean: Vector2=EYES[i][1]
		stalks[i].rotation=Vector3(lean.x+sin(clock*2.3+i*2.1)*.12,sin(clock*1.3+i)*.2,lean.y+sin(clock*1.9+i*1.3)*.16)
		var radius: float=EYES[i][2];var look: Vector2=looks[i]
		var target=Vector3(look.x,look.y,-.92).normalized()*radius*.92
		pupils[i].position=pupils[i].position.lerp(target,1-exp(-delta*14))
		# Squeezed shut when hurt, wide open on an attack.
		eyeballs[i].scale=Vector3.ONE*(1.15 if attack>0 else 1.0)*Vector3(1,.35 if hurt>0 else 1.0,1)
	# The jaw drops open on an attack; the tongue flops; the drool stretches.
	var open=clampf(attack*2.5,0,1)
	jaw.rotation.x=lerpf(jaw.rotation.x,.75*open+sin(clock*2.0)*.04,1-exp(-delta*16))
	mouth.scale=Vector3(.7,.28+.22*open,.3)
	tongue.rotation.x=.35+sin(clock*4.0)*.12+open*.5
	for i in range(drool.size()):
		var stretch=fmod(clock*.6+i*.5,1.0)
		drool[i].scale=Vector3(.045,.1+stretch*.22,.045);drool[i].position.y=.54-stretch*.11
	orb_fill=move_toward(orb_fill,health,delta*.8)
	orb_paint.set_shader_parameter("fill",orb_fill)
	orb_paint.set_shader_parameter("hit",clampf(hurt*4.0,0,1))

func statuses(fire: bool,poison: bool,frozen: bool,blind: bool):
	for i in range(3):
		fire_nodes[i].visible=fire;poison_nodes[i].visible=poison;ice_nodes[i].visible=frozen
		poison_nodes[i].position.y=1.0+fmod(clock*.7+i*.3,1.0)
	blind_node.visible=blind

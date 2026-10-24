extends ActorRig
class_name ColossusRig

# The Ashen Colossus, the final boss: OpenGameArt's Fire/Ice/Stone Golem
# (umask007, CC-BY 3.0; textures by yughues, CC0), converted by
# scripts/blender/convert_golem.py and scaled to 17 m. Its phases wear the golem's
# three materials: stone, then ice, then fire. A glass health orb rides on its
# chest and changes colour with the phase. ColossusFight drives the actions; this
# rig times the golem's own animations so each blow lands as its red marks go off.

const MODEL="res://assets/boss/golem/golem.glb"
const MODEL_HEIGHT=6.2
const HEIGHT=17.0
const PHASE_SKINS=["stone","ice","fire"]
# The health orb's liquid: red, then icy blue, then fire orange.
const ORB_COLORS=[Color(.98,.025,.08),Color(.25,.7,1.0),Color(1.0,.42,.04)]
# Each action's animation and the fraction of it where the blow lands.
const MOVES={"sweep":["attack2",.55],"slam":["attack",.6],"stomp":["attack",.6],"leap":["attack",.6],"breath":["attack2",.55],"tail":["attack2",.55],"lunge":["walk",.5],"roar":["flinch",.5]}

var model: Node3D
var player: AnimationPlayer
var mesh: MeshInstance3D
var skins=[]
var orb_paint: ShaderMaterial
var orb_fill=1.0
var phase_index=0
var health=1.0
var dead=false
# Current action: name, its wind-up, active and recovery seconds, time into it.
var action=""
var action_time=0.0
var windup=1.0
var active=.4
var recover=1.0
var exposed=false
var roar_player=AudioStreamPlayer3D.new()

func setup(model_name: String):
	identity=model_name;skin=Color("4a4448")
	# ActorRig's default body and head are replaced by the golem.
	body.free();head.free()
	model=load(MODEL).instantiate();add_child(model)
	model.scale=Vector3.ONE*HEIGHT/MODEL_HEIGHT
	# The golem is authored facing +Z; the game's actors face -Z.
	model.rotation.y=PI
	body=model;head=model
	player=model.find_child("AnimationPlayer",true,false)
	for name in ["idle","walk"]:
		if player!=null and player.has_animation(name): player.get_animation(name).loop_mode=Animation.LOOP_LINEAR
	for node in model.find_children("*","MeshInstance3D",true,false):
		mesh=node;break
	for name in PHASE_SKINS: skins.append(skin_material(name))
	if mesh!=null: mesh.material_override=skins[0]
	hit_material=skins[0]
	attach_orb()
	if player!=null: player.play("idle")
	add_child(roar_player);roar_player.unit_size=40;roar_player.max_distance=220;roar_player.max_db=4
	var roar_sound=load("res://assets/audio/colossus/roar.wav")
	if roar_sound!=null: roar_player.stream=roar_sound

func skin_material(name: String) -> StandardMaterial3D:
	var material=StandardMaterial3D.new()
	material.albedo_texture=load("res://assets/boss/golem/"+name+".png")
	material.normal_enabled=true;material.normal_texture=load("res://assets/boss/golem/"+name+"_normal.png")
	material.roughness=.85
	# A warm rim like the other enemies, so the silhouette reads in the Red Moon dark.
	material.rim_enabled=true;material.rim=.5;material.rim_tint=.4
	if name=="fire":
		material.emission_enabled=true;material.emission_texture=material.albedo_texture;material.emission=Color(1,.5,.2);material.emission_energy_multiplier=.9
	elif name=="ice":
		material.emission_enabled=true;material.emission=Color(.35,.7,1.0);material.emission_energy_multiplier=.25
	return material

# A glass health orb set into the chest, like every enemy's, only huge.
func attach_orb():
	var skeleton: Skeleton3D=model.find_child("Skeleton3D",true,false)
	var socket: Node3D=self
	if skeleton!=null and skeleton.find_bone("chest")>=0:
		var attachment=BoneAttachment3D.new();attachment.bone_name="chest";skeleton.add_child(attachment);socket=attachment
	var orb=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=.42;sphere.height=.84;orb.mesh=sphere;orb.name="GlassCore"
	orb.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;socket.add_child(orb)
	orb.position=Vector3(0,.55,.55) if socket!=self else Vector3(0,9,-2)
	orb_paint=ShaderMaterial.new();orb_paint.shader=load("res://shaders/blood_core.gdshader");orb_paint.set_shader_parameter("radius",.42)
	orb_paint.set_shader_parameter("liquid_color",ORB_COLORS[0]);orb.material_override=orb_paint

# --- ActorRig interface ------------------------------------------------------
func set_health(fraction: float,_tank: bool=false):
	health=clampf(fraction,0,1)
	if health<=0 and not dead:
		dead=true;action=""
		if player!=null and player.has_animation("die"): player.play("die",.2,.6)

func set_defense(_armour: float,_shield_value: float,_shield_capacity: float): pass
func statuses(_fire: bool,_poison: bool,_frozen: bool,_blind: bool): pass

func set_phase(index: int):
	phase_index=clampi(index,0,2)
	if mesh!=null: mesh.material_override=skins[phase_index]
	orb_paint.set_shader_parameter("liquid_color",ORB_COLORS[phase_index])
	scale=Vector3.ONE*(1.0+phase_index*.05)

# Starts an action: its animation is sped up or slowed so the blow lands at the end
# of the wind-up, when the red marks go off.
func play(name: String,windup_seconds: float,active_seconds: float,recover_seconds: float,open_after: bool=false):
	if dead: return
	action=name;action_time=0.0;windup=maxf(.1,windup_seconds);active=maxf(.05,active_seconds);recover=maxf(.1,recover_seconds);exposed=false
	if open_after: set_meta("open_after",true)
	elif has_meta("open_after"): remove_meta("open_after")
	if name=="roar": roar()
	var move=MOVES.get(name,["attack",.6])
	if player==null or not player.has_animation(move[0]): return
	var length=player.get_animation(move[0]).length
	var speed=2.4 if name=="lunge" else .5 if name=="roar" else clampf(length*float(move[1])/windup,.25,3.0)
	player.play(move[0],.15,speed)

func roar():
	if roar_player.stream!=null: roar_player.play()

func animate(delta: float,movement: Vector3,_on_floor: bool=true,_slamming: bool=false):
	clock+=delta;hurt=maxf(0,hurt-delta);attack=maxf(0,attack-delta)
	if not dead and action!="":
		action_time+=delta
		exposed=has_meta("open_after") and action_time>windup+active
		if action_time>=windup+active+recover: action="";exposed=false
	# Between actions: idle, or walk at a pace that matches its speed.
	if not dead and action=="" and player!=null:
		var speed=Vector2(movement.x,movement.z).length()
		var wanted="walk" if speed>.4 else "idle"
		if player.current_animation!=wanted: player.play(wanted,.3)
		player.speed_scale=clampf(speed/3.0,.5,1.6) if wanted=="walk" else 1.0
	elif player!=null: player.speed_scale=1.0
	# The orb drains with its health and flashes when hit or open after a heavy blow.
	orb_fill=move_toward(orb_fill,health,delta*.6)
	orb_paint.set_shader_parameter("fill",orb_fill)
	orb_paint.set_shader_parameter("hit",clampf(hurt*4.0+(.35+.25*sin(clock*12.0) if exposed else 0.0),0,1))

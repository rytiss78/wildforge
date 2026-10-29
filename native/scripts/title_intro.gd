extends Node
class_name TitleIntro

# The title intro (user request, October 29): a short comic scene before the main
# menu on a normal launch. Five heroes stand about, The Grand Noggin rises out of
# its portal behind them, roars, the heroes jump and spin round, and the title
# slams in while the Noggin booms. About nine seconds; any key or click skips.

const LENGTH=9.2
const RISE=Vector2(1.6,4.0)  # the Noggin rises between these times
const ROAR=4.1
const TITLE=5.9
const FADE=8.4

var game: Node3D
var time=0.0
var stage=Vector3.ZERO
var heroes=[]
var noggin: ColossusRig
var layer: CanvasLayer
var title: Label
var tagline: Label
var skip: Label
var shade: ColorRect
var roared=false
var titled=false
var done=false
var captures={}  # review: time -> file name
var review=false

static func play(g: Node3D,review: bool=false) -> TitleIntro:
	var intro=TitleIntro.new();intro.game=g;g.add_child(intro);intro.begin()
	intro.review=review
	if review: intro.captures={1.2:"intro-1",3.4:"intro-2",4.7:"intro-3",6.6:"intro-4"}
	return intro

func begin():
	game.hud.root.visible=false;game.hud.modal.visible=false
	game.camera_locked=true
	stage=game.player.position+Vector3(0,0,-14)
	stage.y=game.world.height_at(stage.x,stage.z)
	var lineup=game.rules.data.heroes.slice(0,5)
	for i in range(lineup.size()):
		var item=lineup[i];var rig=game.world.model(item.model,float(item.get("height",1.65)))
		game.add_child(rig);var at=stage+Vector3((i-2)*1.6,0,(absi(i-2))*.3)
		at.y=game.world.height_at(at.x,at.z);rig.position=at
		heroes.append({"rig":rig,"base":at,"phase":i*.7})
	noggin=game.world.model("boss_8",9.0);game.add_child(noggin)
	noggin.position=stage+Vector3(0,-24,-12);noggin.rotation.y=PI  # its face toward the heroes and camera
	layer=CanvasLayer.new();layer.layer=50;add_child(layer)
	shade=ColorRect.new();shade.color=Color(0,0,0,1);shade.set_anchors_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(shade)
	title=text("WILDFORGE",132,Color("ffd23f"),.17);tagline=text("Grow strange. Fight hard. Start again.",38,Color("f7f2e3"),.85)
	title.modulate.a=0.0;tagline.modulate.a=0.0
	skip=text("Press any key to skip",20,Color(1,1,1,.7),.93);skip.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;skip.offset_right=-40
	camera_at(0.0)

func text(value: String,font_size: int,color: Color,height: float) -> Label:
	var label=Label.new();label.text=value;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",color)
	label.add_theme_color_override("font_outline_color",Color("1b1a24"));label.add_theme_constant_override("outline_size",maxi(6,font_size/7))
	label.anchor_left=0;label.anchor_right=1;label.anchor_top=height;label.anchor_bottom=height
	label.offset_top=-font_size*.6;label.offset_bottom=font_size*.6;label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.pivot_offset=Vector2(960,font_size*.6);layer.add_child(label)
	return label

# The camera starts low on the heroes and tilts up as the Noggin rises.
func camera_at(t: float):
	var rise=smoothstep(RISE.x,RISE.y+.6,t)
	var eye=stage+Vector3(0,1.8+rise*1.8,8.5+rise*3.5)
	var look=stage+Vector3(0,1.2,0).lerp(Vector3(0,6.0,-12),rise*.75)
	var shake=Vector3(randf_range(-1,1),randf_range(-1,1),0)*.18*clampf(1.0-(t-ROAR)/1.2,0,1)*float(t>ROAR)
	game.camera.position=eye+shake;game.camera.look_at(look,Vector3.UP)

func _process(delta: float):
	if done: return
	time+=delta
	camera_at(time)
	shade.color.a=clampf(1.0-time/.6,0,1)+clampf((time-FADE)/.6,0,1)
	# Heroes idle and bob; after the roar they jump, spin round to face it, and cower.
	for h in heroes:
		var rig: Node3D=h.rig;var t=time+h.phase
		var hop=0.0;var turn=0.0
		if time>ROAR: hop=absf(sin((time-ROAR)*7.0))*.9*clampf(1.0-(time-ROAR)/1.6,0,1);turn=smoothstep(ROAR,ROAR+.5,time)*PI
		rig.position=h.base+Vector3(0,hop+absf(sin(t*3.0))*.06,0);rig.rotation.y=turn
		if rig.has_method("animate"): rig.animate(delta,Vector3.ZERO,hop<.05)
	# The Noggin rises out of its portal, then roars.
	var rise=smoothstep(RISE.x,RISE.y,time)
	noggin.position=stage+Vector3(0,lerpf(-24.0,-1.0,rise)+sin(time*1.4)*.2,-12)
	noggin.animate(delta,Vector3.ZERO,true)
	if time>=ROAR and not roared:
		roared=true;noggin.play("roar",.2,1.4,.8)
		CreatureVoice.noggin(game,"roar",noggin.global_position+Vector3.UP*4.2,-8.0)
	if time>=TITLE and not titled:
		titled=true;CreatureVoice.noggin(game,"bravo",noggin.global_position+Vector3.UP*4.2,-8.0)
	# The title slams in from big, then settles with a bounce.
	var slam=clampf((time-TITLE)/.35,0,1)
	var bounce=sin(clampf(time-TITLE-.35,0,1)*PI*3.0)*.06 if slam>=1.0 else 0.0
	title.modulate.a=slam;title.scale=Vector2.ONE*lerpf(2.6,1.0,slam)*(1.0+bounce)
	title.rotation=sin(time*2.0)*.03
	tagline.modulate.a=clampf((time-TITLE-.5)/.5,0,1)
	for at in captures.keys():
		if time>=at: capture(captures[at]);captures.erase(at)
	if time>=LENGTH: finish()

func capture(name: String):
	await RenderingServer.frame_post_draw
	game.get_viewport().get_texture().get_image().save_png("user://"+name+".png")

func _input(event: InputEvent):
	if done or not captures.is_empty(): return
	if (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton) and event.is_pressed():
		get_viewport().set_input_as_handled();finish()

# Back to the menu with everything put away.
func finish():
	if done: return
	done=true
	for h in heroes:
		if is_instance_valid(h.rig): h.rig.queue_free()
	if is_instance_valid(noggin): noggin.queue_free()
	game.camera_locked=false;game.hud.root.visible=true
	game.hud.start_menu()
	if review:
		var files=["intro-1","intro-2","intro-3","intro-4"]
		print("INTRO_REVIEW "+JSON.stringify({"checks":{"captured":files.all(func(f):return FileAccess.file_exists("user://"+f+".png")),"roared":roared,"titled":titled,"menu":game.mode=="start" and game.hud.modal.visible,"camera_free":not game.camera_locked}}))
		game.get_tree().quit()
	queue_free()

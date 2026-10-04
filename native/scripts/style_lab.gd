extends Node3D

const Model=preload("res://scripts/style_model.gd")
var camera=Camera3D.new()
var player=CharacterBody3D.new()
var duck: Node3D
var gun: Node3D
var target: Node3D
var samples=[]
var bullets=[]
var effects=[]
var shot_clock=0.0
var recoil=0.0
var clock=0.0
var yaw=0.0
var pitch=.38
var distance=10.0
var captured=false
var sound=RunSound.new()
var hp_label: Label
var check_mode=false
var inspection=false
var checks={}
var device=-1
var trigger_down=false
var ui: CanvasLayer
var review_camera=false
var model_view=false

func _ready():
	check_mode=OS.get_cmdline_user_args().has("--style-check")
	inspection=OS.get_cmdline_user_args().has("--style-inspect")
	var environment=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("acd5d9")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("fff0d5");environment.environment.ambient_light_energy=.45
	environment.environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	add_child(environment)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-32,0);sun.light_color=Color("fff0da");sun.light_energy=.75;sun.shadow_enabled=true;add_child(sun)
	var floor_body=StaticBody3D.new();add_child(floor_body)
	var floor_mesh=MeshInstance3D.new();var plane=PlaneMesh.new();plane.size=Vector2(34,32);floor_mesh.mesh=plane
	var material=StandardMaterial3D.new();material.albedo_texture=load("res://assets/illustrated/grass.png");material.uv1_scale=Vector3(12,12,1);material.roughness=1;material.metallic_specular=0;material.diffuse_mode=BaseMaterial3D.DIFFUSE_TOON
	floor_mesh.material_override=material;floor_body.add_child(floor_mesh)
	var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(34,.3,32);shape.shape=box;shape.position.y=-.15;floor_body.add_child(shape)
	for pos in [Vector3(-9,0,-5),Vector3(9,0,-5),Vector3(-11,0,4),Vector3(11,0,4),Vector3(-7,0,-10),Vector3(7,0,-10)]:
		var tree=Model.new();tree.setup("storybook_tree");tree.position=pos;tree.rotation.y=pos.x*.15;add_child(tree)
		var obstacle=StaticBody3D.new();tree.add_child(obstacle)
		var collision=CollisionShape3D.new();var cylinder=CylinderShape3D.new();cylinder.radius=.45;cylinder.height=3;collision.shape=cylinder;collision.position.y=1.5;obstacle.add_child(collision)
	add_child(player);player.position=Vector3(0,.1,4.5);player.floor_snap_length=.3;player.collision_layer=2;player.collision_mask=5;player.platform_floor_layers=1
	var collider=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.4;capsule.height=1.65;collider.shape=capsule;collider.position.y=.825;player.add_child(collider)
	duck=Model.new();duck.setup("count_duck");player.add_child(duck)
	gun=Model.new();gun.setup("mint_pistol");duck.hand_socket().add_child(gun);gun.scale=Vector3.ONE*1.3;gun.rotation.x=-.12
	for i in range(4):
		var sample=Model.new();sample.setup("bottlebite",i==3);sample.position=Vector3((i-1.5)*3.4,0,-4.3);sample.rotation.y=PI
		var values=[1.0,.5,.15,1.0];sample.set_health(values[i],true);add_child(sample);samples.append(sample)
		world_label(sample,["FULL","HALF","CRITICAL","LARGE CREATURE"][i],2.5)
	target=Model.new();target.setup("bottlebite");target.position=Vector3(0,0,0);target.rotation.y=PI;add_child(target)
	var target_body=AnimatableBody3D.new();target_body.sync_to_physics=false;target_body.collision_layer=4;target_body.collision_mask=2;target.add_child(target_body)
	var target_shape=CollisionShape3D.new();var target_capsule=CapsuleShape3D.new();target_capsule.radius=.72;target_capsule.height=1.85;target_shape.shape=target_capsule;target_shape.position.y=.94;target_body.add_child(target_shape)
	world_label(target,"BOTTLEBITE  ·  SHOOT ME",2.5)
	add_child(camera);camera.current=true;camera.fov=55;camera.far=85
	var listener=AudioListener3D.new();camera.add_child(listener);listener.make_current()
	add_child(sound);sound.setup({"music":.15,"sfx":.65,"voice":.5,"genre":"metal"})
	build_ui()
	if check_mode: call_deferred("run_checks")
	if inspection: call_deferred("capture_review")
	if OS.get_cmdline_user_args().has("--style-roundtrip"): call_deferred("roundtrip_return")

func roundtrip_return():
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().set_meta("style_roundtrip_stage",2)
	leave()

func world_label(node: Node3D,text: String,height: float):
	var label=Label3D.new();label.text=text;label.position.y=height;label.font_size=25;label.pixel_size=.007;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=Color("fff1d1");label.outline_modulate=Color("493d3a");label.outline_size=8;node.add_child(label)

func plate(color: Color=Color("f6eddc")) -> StyleBoxFlat:
	var box=StyleBoxFlat.new();box.bg_color=color;box.border_color=Color("76634f");box.set_border_width_all(2);box.set_corner_radius_all(3)
	box.shadow_color=Color("574536");box.shadow_size=2;box.shadow_offset=Vector2(0,2)
	box.content_margin_left=14;box.content_margin_right=14;box.content_margin_top=9;box.content_margin_bottom=9
	return box

func text_label(text: String,size: int=16) -> Label:
	var label=Label.new();label.text=text;label.add_theme_font_size_override("font_size",size);label.add_theme_color_override("font_color",Color("574536"));return label

func build_ui():
	ui=CanvasLayer.new();add_child(ui)
	var panel=PanelContainer.new();panel.position=Vector2(22,18);panel.add_theme_stylebox_override("panel",plate());ui.add_child(panel)
	var column=VBoxContainer.new();panel.add_child(column)
	column.add_child(text_label("WILDFORGE  /  3D STYLE LAB",24))
	column.add_child(text_label("First art prototype · Career progress is untouched",14))
	var bottom=PanelContainer.new();bottom.position=Vector2(22,715);bottom.add_theme_stylebox_override("panel",plate());ui.add_child(bottom)
	var info=VBoxContainer.new();bottom.add_child(info)
	hp_label=text_label("",16);info.add_child(hp_label)
	info.add_child(text_label("WASD / LS Move    F / A Jump    Space / RT Fire    E / X Heal core",15))
	info.add_child(text_label("Hold RMB / RS Orbit    Wheel / D-pad Zoom    R / Y Reset    Esc / B Menu",15))
	var tools=HBoxContainer.new();tools.position=Vector2(790,24);tools.add_theme_constant_override("separation",8);ui.add_child(tools)
	for data in [["View models",toggle_model_view],["Reset core",reset_core],["Empty core",empty_core],["Main menu",leave]]:
		var button=Button.new();button.text=data[0];button.custom_minimum_size=Vector2(130,32)
		button.add_theme_color_override("font_color",Color("574536"));button.add_theme_color_override("font_hover_color",Color("574536"));button.add_theme_color_override("font_pressed_color",Color("574536"))
		button.add_theme_stylebox_override("normal",plate());button.add_theme_stylebox_override("hover",plate(Color("ead1a7")));button.add_theme_stylebox_override("focus",plate(Color("ead1a7")));button.pressed.connect(data[1]);tools.add_child(button)
	var reference=PanelContainer.new();reference.position=Vector2(1220,80);reference.custom_minimum_size=Vector2(180,0);reference.add_theme_stylebox_override("panel",plate());ui.add_child(reference)
	var ref_column=VBoxContainer.new();reference.add_child(ref_column);ref_column.add_child(text_label("ART REFERENCE",14))
	for path in ["heroes/rubber_duck_toy","weapons/gun"]:
		var image=TextureRect.new();image.texture=load("res://assets/illustrated/"+path+".png");image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;image.custom_minimum_size=Vector2(150,150);ref_column.add_child(image)

func _input(event):
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT:
		captured=event.pressed;Input.mouse_mode=Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and captured:
		yaw-=event.relative.x*.005;pitch=clampf(pitch+event.relative.y*.004,.08,1.1)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP: distance=maxf(5,distance-1)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN: distance=minf(18,distance+1)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F: jump()
			KEY_SPACE: shoot()
			KEY_E: target.set_health(minf(1,target.fill+.25))
			KEY_R: reset_core()
			KEY_TAB: toggle_model_view()
			KEY_ESCAPE: leave()
	if event is InputEventJoypadButton and event.pressed:
		device=event.device
		match event.button_index:
			JOY_BUTTON_A: jump()
			JOY_BUTTON_B: leave()
			JOY_BUTTON_X: target.set_health(minf(1,target.fill+.25))
			JOY_BUTTON_Y: reset_core()
			JOY_BUTTON_DPAD_UP: distance=maxf(5,distance-1)
			JOY_BUTTON_DPAD_DOWN: distance=minf(18,distance+1)

func axis(value: float) -> float:
	return value if absf(value)>.18 else 0.0

func _physics_process(delta: float):
	clock+=delta;shot_clock=maxf(0,shot_clock-delta);recoil=maxf(0,recoil-delta*8)
	var pads=Input.get_connected_joypads()
	device=pads[0] if not pads.is_empty() else -1
	var movement=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	if device>=0:
		movement+=Vector2(axis(Input.get_joy_axis(device,JOY_AXIS_LEFT_X)),axis(Input.get_joy_axis(device,JOY_AXIS_LEFT_Y)))
		yaw-=axis(Input.get_joy_axis(device,JOY_AXIS_RIGHT_X))*delta*2.5;pitch=clampf(pitch+axis(Input.get_joy_axis(device,JOY_AXIS_RIGHT_Y))*delta*1.5,.08,1.1)
		var down=Input.get_joy_axis(device,JOY_AXIS_TRIGGER_RIGHT)>.4
		if down: shoot()
		trigger_down=down
	if Input.is_physical_key_pressed(KEY_SPACE): shoot()
	if model_view: movement=Vector2.ZERO
	var velocity=Vector3(movement.x,0,movement.y).limit_length(1).rotated(Vector3.UP,yaw)*5
	player.velocity.x=velocity.x;player.velocity.z=velocity.z
	if not player.is_on_floor(): player.velocity.y-=delta*22
	if not review_camera and not model_view: player.move_and_slide()
	player.position.x=clampf(player.position.x,-14,14);player.position.z=clampf(player.position.z,-12,12)
	if velocity.length()>.1: duck.rotation.y=lerp_angle(duck.rotation.y,atan2(-velocity.x,-velocity.z),delta*12)
	duck.animate(delta,velocity.length(),player.is_on_floor());gun.position.z=recoil*.12;gun.rotation.x=-.12+recoil*.18
	target.animate(delta,1.2)
	if not review_camera and not model_view: target.position.x=sin(clock*.6)*1.3 if not inspection else 0.0
	for sample in samples: sample.animate(delta)
	if not review_camera:
		var focus=Vector3(.7,1.1,0) if model_view else player.position+Vector3(0,1.3,-1.7)
		camera.position=(focus if model_view else player.position+Vector3(0,1.5,0))+Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*distance
		camera.look_at(focus)
	hp_label.text="Bottlebite core: %d%%   ·   E / X heals 25%%   ·   Empty core stays empty until reset" % roundi(target.fill*100)
	update_effects(delta)

func jump():
	if player.is_on_floor() and not model_view: player.velocity.y=8.5

func reset_core():
	target.set_health(1);target.hit_clock=0

func empty_core():
	target.set_health(0)

func toggle_model_view():
	model_view=not model_view
	for sample in samples: sample.visible=not model_view
	player.position=Vector3(0,.1,0) if model_view else Vector3(0,.1,4.5);player.reset_physics_interpolation()
	player.velocity=Vector3.ZERO;duck.rotation.y=0
	target.position=Vector3(2.2,0,-.5) if model_view else Vector3.ZERO;target.rotation.y=0 if model_view else PI;target.reset_physics_interpolation()
	for label in target.find_children("*","Label3D",true,false): label.visible=not model_view
	yaw=PI+.35 if model_view else 0;pitch=.25 if model_view else .38;distance=6 if model_view else 10

func leave():
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://main.tscn")

func shoot():
	if shot_clock>0: return
	shot_clock=.2;recoil=1
	duck.rotation.y=atan2(player.position.x-target.position.x,player.position.z-target.position.z)
	var start=gun.muzzle().global_position
	var destination=target.position+Vector3(0,1.15,0)
	var mesh=Model.new();mesh.setup("brass_bullet");add_child(mesh);mesh.global_position=start;mesh.look_at(destination)
	bullets.append({"node":mesh,"destination":destination,"age":0.0})
	sound.effect("gun",start)
	if device>=0: Input.start_joy_vibration(device,.18,.32,.08)

func update_effects(delta: float):
	for bullet in bullets:
		bullet.age+=delta;bullet.node.position=bullet.node.position.move_toward(bullet.destination,delta*30)
		if bullet.node.position.distance_to(bullet.destination)<.1:
			target.damage(.2);burst(bullet.destination);sound.effect("shell_bump",bullet.destination);bullet.node.queue_free();bullet.age=10
		elif bullet.age>=2: bullet.node.queue_free()
	bullets=bullets.filter(func(b):return b.age<2)
	for effect in effects:
		effect.age+=delta
		if effect.kind=="ring": effect.node.scale=Vector3.ONE*(.15+effect.age*3.2)
		else: effect.node.position+=effect.velocity*delta;effect.velocity.y-=delta*6;effect.node.scale=Vector3.ONE*maxf(.02,1-effect.age*2)
		if effect.age>.45: effect.node.queue_free()
	effects=effects.filter(func(e):return e.age<=.45)

func burst(pos: Vector3):
	var ring=MeshInstance3D.new();var torus=TorusMesh.new();torus.inner_radius=.8;torus.outer_radius=1;torus.rings=24;torus.ring_segments=8;ring.mesh=torus;ring.rotation.x=PI*.5
	var paint=StandardMaterial3D.new();paint.albedo_texture=load("res://assets/illustrated/paper.png");paint.albedo_color=Color("efb36b");paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ring.material_override=paint
	ring.position=pos;add_child(ring);effects.append({"node":ring,"age":0.0,"kind":"ring"})
	for i in range(7):
		var spark=MeshInstance3D.new();var mesh=PrismMesh.new();mesh.size=Vector3(.06,.14,.05);spark.mesh=mesh;spark.material_override=ToonArt.paint(Color("e38f67"));spark.position=pos;spark.rotation=Vector3(i,i*.7,i*.9);add_child(spark)
		effects.append({"node":spark,"age":0.0,"kind":"spark","velocity":Vector3(cos(i*TAU/7)*2,sin(i*3.0)+1.5,sin(i*TAU/7)*2)})

func run_checks():
	await get_tree().physics_frame
	checks.real_meshes=duck.model.find_children("*","MeshInstance3D",true,false).size()>40 and target.model.find_children("*","MeshInstance3D",true,false).size()>40
	checks.no_character_billboards=duck.model.find_children("*","Sprite3D",true,false).is_empty() and target.model.find_children("*","Sprite3D",true,false).is_empty()
	checks.held_weapon=gun.get_parent()==duck.hand_socket() and gun.muzzle()!=null
	checks.core_states=samples[0].fill==1 and samples[1].fill==.5 and samples[2].fill==.15 and samples[3].is_tank
	target.damage(.25);for i in range(40): await get_tree().physics_frame
	checks.draining_core=is_equal_approx(target.fill,.75) and is_equal_approx(target.shown_fill,.75)
	target.set_health(0);for i in range(40): await get_tree().physics_frame
	checks.empty_core=target.shown_fill==0 and target.core_material.get_shader_parameter("fill")==0
	reset_core();for i in range(40): await get_tree().physics_frame
	checks.healing_core=target.shown_fill==1
	shoot();for i in range(40): await get_tree().physics_frame
	checks.shooting=target.fill<1
	checks.ground=player.is_on_floor()
	jump();await get_tree().physics_frame;checks.jump=player.velocity.y>0
	var previous_yaw=yaw;captured=true
	var motion=InputEventMouseMotion.new();motion.relative=Vector2(20,10);_input(motion);captured=false
	checks.mouse_orbit=yaw!=previous_yaw
	var damage_button=InputEventJoypadButton.new();damage_button.button_index=JOY_BUTTON_X;damage_button.pressed=true;damage_button.device=0
	target.set_health(.5,true);_input(damage_button);checks.controller_heal=target.fill==.75
	toggle_model_view();checks.model_view=model_view and not samples[0].visible
	toggle_model_view();checks.arena_view=not model_view and samples[0].visible
	checks.opaque_ui=true
	for panel in ui.find_children("*","PanelContainer",true,false):
		if panel.get_theme_stylebox("panel").bg_color.a!=1: checks.opaque_ui=false
	var file=FileAccess.open("user://style-check-results.json",FileAccess.WRITE);file.store_string(JSON.stringify(checks,"\t"));file.close()
	print("STYLE_CHECK ",JSON.stringify(checks))
	get_tree().quit(0 if checks.values().all(func(value):return value) else 1)

func capture_review():
	await get_tree().create_timer(2).timeout
	if DisplayServer.get_name()=="headless": get_tree().quit(1);return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://style-review.png")
	review_camera=true
	for sample in samples: sample.visible=false
	player.position=Vector3.ZERO;player.reset_physics_interpolation();duck.rotation.y=0
	player.velocity=Vector3.ZERO
	target.position=Vector3(2.2,0,-.5);target.rotation.y=0;target.reset_physics_interpolation()
	for label in target.find_children("*","Label3D",true,false): label.visible=false
	camera.position=Vector3(-2.6,2.7,-5.8);camera.look_at(Vector3(.6,1.05,0))
	await get_tree().create_timer(.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("user://style-character-review.png")
	get_tree().quit()

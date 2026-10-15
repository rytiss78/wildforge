extends Node3D
class_name ActorRig

static var enemy_meshes={}
static var sculpt_meshes={}
var body=Node3D.new()
var head=Node3D.new()
var legs=[]
var arms=[]
var held=[]
var equipment_signature=""
var clock=0.0
var recoil=0.0
var attack=0.0
var previous_status=-1
var hurt=0.0
var identity=""
var skin=Color("ffce75")
var hit_material: StandardMaterial3D
var fire_nodes=[]
var poison_nodes=[]
var ice_nodes=[]
var batched: ShaderMaterial
var blind_node: MeshInstance3D
var illustration: Sprite3D
var illustrated=false
var paint_tint=Color.WHITE
var solid: StyleModel
var melee={}
var melee_side=1.0
var reach_links=[]
var reach_glove: MeshInstance3D
var thumb_clock=0.0
var thumb_glove: Node3D

func setup_solid(model_name: String) -> bool:
	var asset=model_name if model_name.begins_with("creature_") or model_name.begins_with("boss_") else "count_duck" if model_name=="rubber_duck_toy" else "hero_"+model_name
	if model_name=="boss_8": asset="boss_8_baron"
	if not ResourceLoader.exists("res://assets/style3d/"+asset+".glb"): return false
	solid=StyleModel.new();solid.setup(asset);add_child(solid)
	head.free();body.free()
	body=solid.body;head=solid.head if solid.head!=null else body
	legs=solid.legs;arms=solid.arms
	batched=solid.batched
	for arm in arms:
		var socket=arm.find_child("HandSocket*",true,false)
		if socket==null:
			socket=Node3D.new();arm.add_child(socket);socket.position=Vector3(0,-.3,-.2)
		arm.set_meta("hand",socket)
	hit_material=ToonArt.paint(skin).duplicate()
	for i in range(3):
		var flame=ToonArt.ball(body,Color("ffad61"),Vector3((i-1)*.23,.6+i*.13,-.34),Vector3(.18,.4,.17));flame.visible=false;fire_nodes.append(flame)
		var droplet=ToonArt.ball(body,Color("9cdc73"),Vector3((i-1)*.27,.8,0),Vector3(.12,.14,.12));droplet.visible=false;poison_nodes.append(droplet)
		var crystal=ToonArt.tube(body,Color("b2e6ee"),Vector3((i-1)*.22,.08,.1),0,.12,.4);crystal.visible=false;ice_nodes.append(crystal)
	if model_name=="boss_8": preload("res://scripts/baron_steam.gd").attach(self)
	blind_node=block(body,Color("746382"),Vector3(0,1.6,0),Vector3(.36,.045,.045));blind_node.visible=false
	return true

func set_health(fraction: float, tank: bool=false):
	if solid==null: return
	solid.set_health(fraction,fraction<=0)
	if solid.is_tank!=tank:
		solid.is_tank=tank

func set_defense(armour: float,shield_value: float,shield_capacity: float):
	if solid!=null: solid.set_defense(armour,shield_value,shield_capacity)

func block(parent: Node3D,color: Color,pos: Vector3,dimensions: Vector3):
	var mesh=BoxMesh.new();mesh.size=dimensions
	return ToonArt.part(parent,mesh,color,pos)

func setup(model_name: String):
	identity=model_name
	skin={"rubber_duck_toy":Color("ffd265"),"pipe_wrench":Color("da8a66"),"sweet_potato":Color("bd9263"),"marble_bust_01":Color("b9b8bf"),"street_rat":Color("b2a3ca"),"hamburger_buns":Color("dda76b"),"florist":Color("eab295"),"acorn":Color("bb986d"),"toad":Color("9ebe81"),"crab":Color("d6a175"),"penguin":Color("82aabd"),"lizard":Color("e9a279"),"beetle":Color("bfa0d6")}.get(model_name,Color("abafc5"))
	if setup_solid(model_name): return
	push_error("Missing required actor model: "+model_name)
	add_child(body);body.add_child(head)

func add_arm(side: int):
	var arm=Node3D.new()
	arm.position=Vector3(side*.46,.93,0) if side!=0 else Vector3(.62,1.70,.24)
	body.add_child(arm)
	if not illustrated or side==0:
		ToonArt.tube(arm,skin,Vector3(0,-.18,0),.065,.07,.36)
		ToonArt.ball(arm,skin,Vector3(0,-.39,-.04),Vector3(.15,.14,.17))
	var hand=Node3D.new();hand.position=Vector3(0,-.36,-.14);arm.add_child(hand)
	arm.set_meta("hand",hand)
	arms.append(arm)
	return arm

func sync_equipment(weapons: Array):
	var signature=""
	for weapon in weapons: signature+=weapon.id+str(weapon.rank)+";"
	if signature==equipment_signature: return
	var previous_third_rank=held[2].rank if held.size()==3 else 0
	finish_melee()
	equipment_signature=signature
	body.rotation=Vector3.ZERO
	for model in held: model.queue_free()
	held.clear()
	if weapons.size()==3 and arms.size()<3:
		var extra=add_arm(0);extra.scale=Vector3.ONE*.02
		create_tween().tween_property(extra,"scale",Vector3.ONE,.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if arms.size()>2: arms[2].visible=weapons.size()==3
	for i in range(weapons.size()):
		var weapon=WeaponModel.new();weapon.setup(weapons[i].id);weapon.rank=int(weapons[i].rank)
		weapon.position.y=.18
		arms[i].get_meta("hand").add_child(weapon)
		held.append(weapon)
	if weapons.size()==3 and previous_third_rank>0 and weapons[2].rank>previous_third_rank: third_hand_cheer()

func third_hand_cheer():
	if held.size()!=3 or arms.size()<3: return
	if is_instance_valid(thumb_glove): thumb_glove.queue_free()
	thumb_clock=.7;held[2].visible=false
	thumb_glove=Node3D.new();arms[2].get_meta("hand").add_child(thumb_glove)
	thumb_glove.position=Vector3(.08,.18,-.08)
	ToonArt.ball(thumb_glove,skin,Vector3.ZERO,Vector3(.24,.27,.17))
	for i in range(3): ToonArt.ball(thumb_glove,skin.darkened(.12),Vector3(.06,.07-i*.065,-.08),Vector3(.14,.06,.09))
	ToonArt.tube(thumb_glove,skin,Vector3(-.09,.16,-.02),.048,.06,.22)
	ToonArt.ball(thumb_glove,skin,Vector3(-.09,.28,-.02),Vector3(.095,.1,.10))
	thumb_glove.scale=Vector3.ONE*.05
	thumb_glove.create_tween().tween_property(thumb_glove,"scale",Vector3.ONE,.16).set_trans(Tween.TRANS_BACK)

func tick_thumb(delta: float):
	if not is_instance_valid(thumb_glove): return
	thumb_clock=maxf(0,thumb_clock-delta)
	if thumb_clock>0:
		if arms.size()>2: arms[2].rotation.x=-1.15
	else:
		thumb_glove.queue_free();thumb_glove=null
		if held.size()==3: held[2].visible=true

func shot(id: String):
	for model in held:
		if model.id==id: model.shoot()

func begin_melee(id: String,target: Vector3,duration: float=.44):
	if not melee.is_empty(): return
	for i in range(held.size()):
		if held[i].id!=id: continue
		var hand=arms[i].get_meta("hand")
		if reach_links.is_empty():
			for part in range(2):
				var cylinder=CylinderMesh.new();cylinder.top_radius=.065;cylinder.bottom_radius=.085;cylinder.height=1;cylinder.radial_segments=8
				var link=MeshInstance3D.new();link.mesh=cylinder;link.material_override=ToonArt.paint(skin);add_child(link);reach_links.append(link)
		if reach_glove==null: reach_glove=ToonArt.ball(self,skin,Vector3.ZERO,Vector3(.18,.18,.20))
		for link in reach_links: link.visible=true
		reach_glove.visible=true;melee_side=-melee_side
		melee={"model":held[i],"hand":hand,"rest":hand.transform,"arm":arms[i],"target":target,"elapsed":0.0,"duration":duration,"side":melee_side}
		return

func finish_melee():
	if not melee.is_empty() and is_instance_valid(melee.hand): melee.hand.transform=melee.rest
	melee.clear()
	for link in reach_links: link.visible=false
	if is_instance_valid(reach_glove): reach_glove.visible=false

func tick_melee(delta: float):
	if melee.is_empty(): return
	if not is_instance_valid(melee.model) or not is_instance_valid(melee.hand): finish_melee();return
	melee.elapsed+=delta
	var t=clampf(melee.elapsed/melee.duration,0,1)
	var shoulder: Vector3=melee.arm.global_position+Vector3.DOWN*.12
	var rest: Vector3=melee.hand.get_parent().global_transform*melee.rest.origin
	var offset: Vector3=melee.target-shoulder
	var extension=smoothstep(0,.40,t)*(1-smoothstep(.68,1,t))
	var sweep=clampf((t-.5)/.28,-1,1)*.8*melee.side
	var direction=(offset.normalized() if offset.length()>.01 else Vector3.FORWARD).rotated(Vector3.UP,sweep)
	var contact=shoulder+direction*maxf(.2,offset.length()-.30)
	melee.hand.global_position=rest.lerp(contact,extension)
	melee.model.look_at(melee.hand.global_position+direction)
	var elbow=shoulder.lerp(melee.hand.global_position,.5)+Vector3.UP*(.12+.22*(1-extension))
	var points=[shoulder,elbow,melee.hand.global_position]
	for i in range(2):
		var a: Vector3=points[i];var b: Vector3=points[i+1];var segment=b-a
		reach_links[i].global_transform=Transform3D(Basis(Quaternion(Vector3.UP,segment.normalized()))*Basis.from_scale(Vector3(1,maxf(.02,segment.length()),1)),(a+b)*.5)
	reach_glove.global_position=melee.hand.global_position
	if t>=1: finish_melee()

func animate(delta: float,movement: Vector3,on_floor: bool=true,slamming: bool=false):
	clock+=delta
	attack=maxf(0,attack-delta)
	if solid!=null:
		solid.hit_clock=maxf(solid.hit_clock,hurt)
		solid.animate(delta,movement.length() if batched==null else 0.0,on_floor)
		if identity.begins_with("boss_"):
			BossBook.animate(self,clock,movement.length(),clampf(attack,0,1));hurt=maxf(0,hurt-delta);return
	if batched!=null:
		batched.set_shader_parameter("clock",clock)
		batched.set_shader_parameter("moving",clampf(movement.length()/8,0,1))
		batched.set_shader_parameter("attack",1 if attack>0 else 0)
		batched.set_shader_parameter("airborne",0 if on_floor else 1)
		hurt=maxf(0,hurt-delta)
		# Hit flash
		if has_meta("flash_timer") and get_meta("flash_timer")>0:
			var ft=get_meta("flash_timer")
			set_meta("flash_timer",ft-delta)
			hit_material.albedo_color=Color.WHITE
		return
	var walk=clampf(Vector2(movement.x,movement.z).length()/8,0,1)
	if illustrated:
		illustration.scale=Vector3(1+sin(clock*12)*.035*walk,1-sin(clock*12)*.045*walk,1)
		if hurt>0: illustration.modulate=Color(1.5,.6,.5);illustration.offset.x=sin(hurt*90)*8
		else: illustration.offset.x=0;illustration.modulate=paint_tint
	body.position.y=sin(clock*12)*.035*walk if on_floor else .04
	body.rotation.z=sin(clock*6)*.025*(1-walk)
	body.rotation.x=lerpf(body.rotation.x,.16 if slamming else -.12 if not on_floor and movement.y>0 else 0.0,delta*10)
	for i in range(legs.size()): legs[i].rotation.x=sin(clock*12+i*PI)*.65*walk if on_floor else -.35 if movement.y>0 else .12
	for i in range(arms.size()):
		arms[i].rotation.x=lerpf(arms[i].rotation.x,.06 if held.size()>i else -1.0 if attack>0 else sin(clock*12+i*PI)*.30*walk,delta*10)
		arms[i].rotation.z=lerpf(arms[i].rotation.z,-.75 if i==2 else 0.0,delta*10)
	for model in held: model.tick(delta)
	tick_thumb(delta)
	tick_melee(delta)
	if illustrated and not identity.begins_with("creature_"):
		var view=get_viewport().get_camera_3d()
		if view!=null:
			for i in range(arms.size()):
				var side=-.45 if i==0 else .45 if i==1 else .75
				arms[i].global_position=global_position+Vector3.UP*(1.12 if i<2 else 1.8)+view.global_basis.x*side+view.global_basis.z*.5
	hurt=maxf(0,hurt-delta)
	if hurt>0: head.rotation.z=sin(hurt*40)*.10
	else:
		head.rotation.z=sin(clock*2)*(.03 if identity=="marble_bust_01" else .015)
		if identity=="street_rat": head.rotation.y=sin(clock*3)*.045
		if identity=="hamburger_buns": body.rotation.z+=sin(clock*2)*.015

func statuses(fire: bool,poison: bool,frozen: bool,blind: bool):
	var mask=int(fire)+int(poison)*2+int(frozen)*4+int(blind)*8
	if illustrated: paint_tint=Color("9be477") if poison else Color("acf1ff") if frozen else Color("ffb895") if fire else Color.WHITE
	if mask==0 and previous_status==0: return
	previous_status=mask
	if illustrated and hurt<=0: illustration.modulate=paint_tint
	if batched!=null: batched.set_shader_parameter("tint",Vector3(.7,1,.5) if poison else Vector3(.75,1,1.15) if frozen else Vector3.ONE)
	hit_material.albedo_color=skin.lerp(Color("91d467"),.7) if poison else skin.lerp(Color("b9e9f1"),.6) if frozen else skin
	for i in range(3):
		fire_nodes[i].visible=fire
		fire_nodes[i].scale=Vector3(.18,.28+sin(clock*18+i)*.12,.17)
		poison_nodes[i].visible=poison
		poison_nodes[i].position.y=.5+fmod(clock*.7+i*.3,1.0)
		ice_nodes[i].visible=frozen
	blind_node.visible=blind
	blind_node.rotation.y=clock*3

func aim_weapon(id: String,target: Vector3):
	for model in held:
		if model.id==id and model.global_position.distance_squared_to(target)>.1:
			model.look_at(target,Vector3.UP)
			model.rotation.x=clampf(model.rotation.x,-.75,.75)
			model.rotation.y=clampf(model.rotation.y,-1.35,1.35)
			model.rotation.z=0

func muzzle_position(id: String) -> Vector3:
	for model in held:
		if model.id==id: return model.muzzle.global_position
	return global_position+Vector3.UP

func finale(win: bool):
	if win:
		for arm in arms: create_tween().tween_property(arm,"rotation:x",PI,.45)
		create_tween().tween_property(head,"rotation:z",.15,.3)
	else: create_tween().tween_property(body,"rotation:z",1.4,.5).set_trans(Tween.TRANS_BOUNCE)


func bake_enemy():
	if batched!=null: return
	if illustrated: return
	var nodes=[];PaintedBatch.collect(self,nodes)
	nodes=nodes.filter(func(node): return node.name not in ["GlassCore","RearGlass"])
	if not enemy_meshes.has(identity): enemy_meshes[identity]=PaintedBatch.merge(self,nodes)
	var mesh=enemy_meshes[identity]
	for node in nodes: node.queue_free()
	var combined=MeshInstance3D.new();combined.mesh=mesh;batched=PaintedBatch.material(true);combined.material_override=batched;add_child(combined)

func sculpt(parent: Node3D,color: Color,p: Vector3,dimensions: Vector3,kind: String) -> MeshInstance3D:
	if not sculpt_meshes.has(kind):
		var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		var heights=[-.5,-.40,-.20,0.0,.22,.40,.5]
		var widths=[.10,.70,1.03,1.0,.86,.58,.08] if kind=="body" else [.07,.68,1.0,1.04,.94,.64,.06]
		for ring in range(heights.size()-1):
			for slice in range(18):
				for corner in [Vector2i(ring,slice),Vector2i(ring,slice+1),Vector2i(ring+1,slice),Vector2i(ring+1,slice),Vector2i(ring,slice+1),Vector2i(ring+1,slice+1)]:
					var angle=float(corner.y)*TAU/18
					var radius=widths[corner.x]*.5
					surface.set_uv(Vector2(float(corner.y)/18,float(corner.x)/6))
					surface.add_vertex(Vector3(cos(angle)*radius,heights[corner.x],sin(angle)*radius*(1+sin(angle*3)*.03)))
		surface.generate_normals();sculpt_meshes[kind]=surface.commit()
	return ToonArt.part(parent,sculpt_meshes[kind],color,p,dimensions)

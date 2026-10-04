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

func setup_solid(model_name: String) -> bool:
	var asset=model_name if model_name.begins_with("creature_") else "count_duck" if model_name=="rubber_duck_toy" else "hero_"+model_name
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
	blind_node=block(body,Color("746382"),Vector3(0,1.6,0),Vector3(.36,.045,.045));blind_node.visible=false
	return true

func set_health(fraction: float, tank: bool=false):
	if solid==null: return
	solid.set_health(fraction,fraction<=0)
	if solid.is_tank!=tank:
		solid.is_tank=tank

func set_defense(armour: float,shield_value: float,shield_capacity: float):
	if solid!=null: solid.set_defense(armour,shield_value,shield_capacity)

func setup_painted(model_name: String) -> bool:
	var path="res://assets/illustrated/"+("creatures/" if model_name.begins_with("creature_") else "heroes/")+model_name+".png"
	if not ResourceLoader.exists(path): return false
	illustrated=true;identity=model_name
	add_child(body);body.add_child(head);head.position.y=1.13
	illustration=Sprite3D.new();illustration.texture=load(path);illustration.pixel_size=1.95/256;illustration.position.y=.92
	illustration.billboard=BaseMaterial3D.BILLBOARD_ENABLED;illustration.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD;illustration.alpha_scissor_threshold=.15;illustration.shaded=false
	illustration.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;body.add_child(illustration)
	hit_material=ToonArt.paint(skin).duplicate()
	if not model_name.begins_with("creature_"):
		for side in [-1,1]: add_arm(side)
	for i in range(3):
		var flame=ToonArt.ball(body,Color("ffad61"),Vector3((i-1)*.23,.6+i*.13,-.34),Vector3(.18,.4,.17));flame.visible=false;fire_nodes.append(flame)
		var droplet=ToonArt.ball(body,Color("9cdc73"),Vector3((i-1)*.27,.8,0),Vector3(.12,.14,.12));droplet.visible=false;poison_nodes.append(droplet)
		var crystal=ToonArt.tube(body,Color("b2e6ee"),Vector3((i-1)*.22,.08,.1),0,.12,.4);crystal.visible=false;ice_nodes.append(crystal)
	blind_node=block(body,Color("746382"),Vector3(0,1.6,0),Vector3(.36,.045,.045));blind_node.visible=false
	return true

func block(parent: Node3D,color: Color,pos: Vector3,dimensions: Vector3):
	var mesh=BoxMesh.new();mesh.size=dimensions
	return ToonArt.part(parent,mesh,color,pos)

func setup(model_name: String):
	identity=model_name
	skin={"rubber_duck_toy":Color("ffd265"),"pipe_wrench":Color("da8a66"),"sweet_potato":Color("bd9263"),"marble_bust_01":Color("b9b8bf"),"street_rat":Color("b2a3ca"),"hamburger_buns":Color("dda76b"),"florist":Color("eab295"),"acorn":Color("bb986d"),"toad":Color("9ebe81"),"crab":Color("d6a175"),"penguin":Color("82aabd"),"lizard":Color("e9a279"),"beetle":Color("bfa0d6")}.get(model_name,Color("abafc5"))
	if setup_solid(model_name): return
	if setup_painted(model_name): return
	add_child(body)
	var torso=sculpt(body,skin,Vector3(0,.70,0),Vector3(.8,.85,.62),"body")
	hit_material=ToonArt.paint(skin).duplicate()
	torso.material_override=hit_material
	body.add_child(head);head.position.y=1.13
	sculpt(head,skin,Vector3.ZERO,Vector3(.73,.68,.61),"head")
	ToonArt.eyes(head,.08,-.30,.17)
	ToonArt.ball(head,Color("cf826d"),Vector3(0,-.14,-.30),Vector3(.12,.055,.025))
	for side in [-1,1]:
		var leg=Node3D.new();leg.position=Vector3(side*.22,.4,0);body.add_child(leg);legs.append(leg)
		ToonArt.tube(leg,skin,Vector3(0,-.12,0),.09,.10,.30)
		ToonArt.ball(leg,Color("62594e"),Vector3(0,-.32,-.09),Vector3(.25,.16,.37))
		add_arm(side)
	if model_name=="rubber_duck_toy":
		ToonArt.ball(head,Color("e6a261"),Vector3(0,-.15,-.42),Vector3(.44,.13,.34))
		var cape=block(body,Color("a68bbe"),Vector3(0,.72,.32),Vector3(.62,.70,.06));cape.rotation.x=.18
		block(body,Color("eee1ba"),Vector3(0,.91,-.32),Vector3(.09,.15,.03))
	elif model_name in ["street_rat","toad","acorn","crab","penguin","lizard","beetle"]:
		if model_name=="street_rat":
			for side in [-1,1]: ToonArt.ball(head,skin,Vector3(side*.30,.30,0),Vector3(.25,.29,.14))
		elif model_name=="beetle":
			for side in [-1,1]: ToonArt.tube(head,Color("806893"),Vector3(side*.18,.42,0),.035,.04,.30)
		if model_name=="street_rat":
			ToonArt.ball(head,Color("dbaab1"),Vector3(0,-.1,-.4),Vector3(.18,.15,.15))
			block(body,Color("e9bd68"),Vector3(0,.72,-.32),Vector3(.1,.28,.04))
			ToonArt.ball(body,Color("e5cfaa"),Vector3(.36,.5,0),Vector3(.10,.20,.21))
		elif model_name=="acorn":
			ToonArt.tube(head,Color("7f654e"),Vector3(0,.30,0),.28,.4,.2)
			ToonArt.tube(head,Color("7f654e"),Vector3(0,.46,0),.03,.07,.2)
		elif model_name=="toad":
			for x in [-.27,.27]: ToonArt.ball(head,Color("f5e6ba"),Vector3(x,.20,-.24),Vector3(.27,.31,.18))
			for x in [-.18,.18]: ToonArt.ball(body,Color("dcc796"),Vector3(x,.67,-.28),Vector3(.12,.14,.08))
		elif model_name=="crab":
			for side in [-1,1]: ToonArt.ball(body,Color("e3b16d"),Vector3(side*.58,.60,-.1),Vector3(.28,.35,.26))
		elif model_name=="penguin":
			ToonArt.ball(body,Color("fff0d9"),Vector3(0,.72,-.29),Vector3(.50,.64,.14))
			ToonArt.ball(head,Color("efb46c"),Vector3(0,-.1,-.37),Vector3(.2,.12,.25))
		elif model_name=="lizard":
			for i in range(3): ToonArt.tube(head,Color("e6c17c"),Vector3(0,.3,.15-i*.15),0,.07,.24)
		else:
			ToonArt.ball(body,Color("a892ca"),Vector3(0,.74,.23),Vector3(.93,.92,.35))
	elif model_name=="pipe_wrench":
		ToonArt.tube(head,Color("c97658"),Vector3(0,.31,0),.31,.40,.18)
		block(body,Color("738f96"),Vector3(0,.6,-.30),Vector3(.55,.50,.05))
		for x in [-.2,.2]: ToonArt.ball(body,Color("e8c98a"),Vector3(x,.83,-.35),Vector3(.06,.06,.03))
	elif model_name=="sweet_potato":
		ToonArt.tube(head,Color("939f96"),Vector3(0,.29,0),.15,.40,.2)
		for x in [-.2,.2]: ToonArt.ball(head,Color("93b78d"),Vector3(x,.47,0),Vector3(.22,.40,.13))
		block(body,Color("a5b6a6"),Vector3(0,.67,-.31),Vector3(.52,.46,.07))
	elif model_name=="marble_bust_01":
		for side in [-1,1]: ToonArt.ball(head,Color("f5e5d1"),Vector3(side*.31,.23,.04),Vector3(.32,.29,.29))
		for x in [-.17,.17]:
			var ring=TorusMesh.new();ring.inner_radius=.1;ring.outer_radius=.125
			var lens=ToonArt.part(head,ring,Color("8a6656"),Vector3(x,.08,-.35));lens.rotation.x=PI*.5
		block(body,Color("af8ba3"),Vector3(0,.71,-.32),Vector3(.57,.18,.08))
	elif model_name=="hamburger_buns":
		ToonArt.tube(head,Color("b3815b"),Vector3(0,.27,0),.28,.37,.15)
		for i in range(7): ToonArt.ball(head,Color("fff0ba"),Vector3(sin(i*2.4)*.23,.31,cos(i*2.4)*.23),Vector3(.04,.025,.08))
		block(body,Color("9eab9c"),Vector3(0,.68,-.29),Vector3(.58,.40,.08))
	else:
		ToonArt.tube(head,Color("d3af78"),Vector3(0,.31,0),.34,.51,.12)
		ToonArt.tube(head,Color("9fbf87"),Vector3(0,.43,0),.18,.29,.18)
		for i in range(5): ToonArt.ball(head,Color("eda1b8"),Vector3(.27+cos(i*TAU/5)*.11,.40+sin(i*TAU/5)*.11,-.20),Vector3(.14,.14,.10))
		block(body,Color("8eae82"),Vector3(0,.62,-.30),Vector3(.54,.52,.06))
	for i in range(3):
		var flame=ToonArt.ball(body,Color("ffad61"),Vector3((i-1)*.23,.6+i*.13,-.34),Vector3(.18,.4,.17));flame.visible=false;fire_nodes.append(flame)
		var droplet=ToonArt.ball(body,Color("9cdc73"),Vector3((i-1)*.27,.8,.0),Vector3(.12,.14,.12));droplet.visible=false;poison_nodes.append(droplet)
		var crystal=ToonArt.tube(body,Color("b2e6ee"),Vector3((i-1)*.22,.08,.1),0,.12,.4);crystal.visible=false;ice_nodes.append(crystal)
	blind_node=block(body,Color("746382"),Vector3(0,1.6,0),Vector3(.36,.045,.045));blind_node.visible=false

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
	if batched!=null:
		batched.set_shader_parameter("clock",clock)
		batched.set_shader_parameter("moving",clampf(movement.length()/8,0,1))
		batched.set_shader_parameter("attack",1 if attack>0 else 0)
		batched.set_shader_parameter("airborne",0 if on_floor else 1)
		hurt=maxf(0,hurt-delta)
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

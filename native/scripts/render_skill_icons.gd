extends SceneTree
var stage: Node3D
var gold=Color("dbad55")
var ink=Color("283d4c")

func part(parent,mesh: Mesh,p: Vector3,color: Color,metal: float=0.0):
	var node=MeshInstance3D.new();node.mesh=mesh;node.position=p
	var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.metallic=metal;mat.roughness=.3;node.material_override=mat;parent.add_child(node);return node
func box(parent,p: Vector3,size: Vector3,color: Color,metal: float=0.0):
	var mesh=BoxMesh.new();mesh.size=size;return part(parent,mesh,p,color,metal)
func ball(parent,p: Vector3,r: float,color: Color):
	var mesh=SphereMesh.new();mesh.radius=r;mesh.height=r*2;return part(parent,mesh,p,color)
func tube(parent,p: Vector3,r: float,h: float,color: Color,top: float=-1):
	var mesh=CylinderMesh.new();mesh.bottom_radius=r;mesh.top_radius=r if top<0 else top;mesh.height=h;return part(parent,mesh,p,color,.55)
func ring(parent,p: Vector3,r: float,color: Color):
	var mesh=TorusMesh.new();mesh.inner_radius=r*.8;mesh.outer_radius=r;return part(parent,mesh,p,color,.65)
func model(key: String,id: String):
	var root=Node3D.new();stage.add_child(root)
	var hue=Color.from_hsv(float(posmod(hash(id),1048573))/1048573.,.48,.8)
	var k=key.to_lower();var color=PowerIcon.color_for(key)
	var weapon_kinds={"bombpower":"bomb","bombsize":"bomb","boomerang":"boomerang","boomerangpierce":"boomerang","boomerangpower":"boomerang","discbounces":"disc","discpower":"disc","bubblepower":"bubble","harpoonpower":"harpoon","harpoonpull":"harpoon","hornpower":"horn","hornstun":"horn","meteorpower":"meteor","meteorcount":"meteor"}
	if weapon_kinds.has(k):
		var weapon=WeaponModel.new();weapon.setup(weapon_kinds[k]);root.add_child(weapon);weapon.position=Vector3(0,.25,0);weapon.rotation.y=-.4
		for i in range(3): ring(root,Vector3(0,-.12+i*.06,0),.3+i*.06,hue)
		if k in ["bombsize","hornstun","meteorcount"]: weapon.scale=Vector3.ONE*1.2
		if k=="boomerangpierce":
			for i in range(3): tube(root,Vector3(-.25+i*.25,.45,0),.05,.2,gold,0)
		if k=="boomerang": weapon.rotation.z=.4
		return root
	if k.contains("jump") or k in ["speed","aircontrol","dashcooldown","fallthreshold","fallguard","airdamage"]:
		for x in [-.25,.25]:
			box(root,Vector3(x,.15,0),Vector3(.34,.16,.65),ink)
			box(root,Vector3(x,.37,.13),Vector3(.31,.4,.3),hue)
			var toe=ball(root,Vector3(x,.25,-.2),.17,hue.lightened(.15));toe.scale=Vector3(1,.7,1.2)
			for y in [.32,.46,.6]:
				for dx in [-.12,.12]: ball(root,Vector3(x+dx,y,-.035),.025,gold)
			box(root,Vector3(x,.1,-.18),Vector3(.35,.06,.37),gold)
			for y in [.35,.45,.55]: box(root,Vector3(x,y,-.035),Vector3(.22,.025,.04),gold)
			for y in range(4): ring(root,Vector3(x,-.04-y*.065,0),.13,gold)
		if k.contains("height") or k=="aircontrol":
			for x in [-1,1]:
				for i in range(4): box(root,Vector3(x*(.42+i*.06),.42+i*.06,.1),Vector3(.1,.045,.38-i*.055),Color("e9f3ec")).rotation.z=x*-.4
		if k=="fallguard" or k=="fallthreshold":
			for i in range(6):
				var feather=ball(root,Vector3(.45+i*.02,.3+i*.06,0),.1,Color("e4eee3"));feather.scale=Vector3(.35,.3,1.7)
		if k=="airjumps":
			for y in range(3): ring(root,Vector3(0,.78+y*.12,0),.13+y*.055,Color("7bcedb"))
	elif k.contains("poison") or k in ["pools","potionpower","potionduration","potionchance","regen","maxhp","revive","repair","salvage","landingheal","slamheal","lifesteal"]:
		var liquid=Color("70b643") if k.contains("poison") or k=="pools" else Color("d95468")
		ball(root,Vector3(0,.22,0),.37,liquid);tube(root,Vector3(0,.6,0),.15,.25,Color("cedde0"));tube(root,Vector3(0,.76,0),.17,.1,gold)
		ring(root,Vector3(0,.44,0),.3,gold);box(root,Vector3(0,.24,-.355),Vector3(.1,.32,.045),Color("fff2ce"));box(root,Vector3(0,.24,-.36),Vector3(.27,.09,.045),Color("fff2ce"))
		for i in range(6): ball(root,Vector3(sin(i*2.4)*.36,.75+i*.055,cos(i*2.4)*.2),.035,liquid.lightened(.3))
	elif k.contains("slampower") or k.contains("slamradius") or k=="bouncejump":
		var rock=SphereMesh.new();rock.radius=.34;rock.height=.65;rock.radial_segments=6;rock.rings=3;part(root,rock,Vector3(0,.45,0),Color("7a929d"))
		for i in range(4 if k=="slamradius" else 2): ring(root,Vector3(0,-.05-i*.045,0),.16+i*(.14 if k=="slamradius" else .08),gold)
		for i in range(5): box(root,Vector3(sin(i*2.4)*.42,0,cos(i*2.4)*.42),Vector3(.1,.1,.12),ink)
	elif k.contains("armor") or k.contains("shield") or k in ["dodge","thorns"]:
		var shield=ball(root,Vector3(0,.4,0),.48,ink);shield.scale=Vector3(.85,1,.25)
		var plate=ball(root,Vector3(0,.4,-.09),.41,color);plate.scale=Vector3(.85,1,.2)
		box(root,Vector3(0,.4,-.18),Vector3(.055,.65,.07),gold);box(root,Vector3(0,.48,-.18),Vector3(.5,.055,.07),gold)
		for i in range(8): ball(root,Vector3(cos(i*TAU/8)*.31,.4+sin(i*TAU/8)*.37,-.16),.035,gold)
	elif k.contains("pull") or k.contains("push") or k in ["pickup","coinradius","gravitysize","gravitypower"]:
		for x in [-.3,.3]:
			box(root,Vector3(x,.35,0),Vector3(.18,.65,.22),Color("bd5354"));box(root,Vector3(x,.72,0),Vector3(.19,.15,.23),Color("dbe2dd"))
		box(root,Vector3(0,.03,0),Vector3(.75,.2,.24),Color("bd5354"))
		for i in range(3): ring(root,Vector3(0,.42+i*.17,-.1),.15+i*.075,Color("81d4e3"))
		if k.contains("push"): root.rotation.z=PI;root.position.y=.7
	elif k.contains("gold") or k in ["luck","crit","critpower","xpgain","discount"]:
		for i in range(9):
			var p=Vector3((i%3-1)*.25,.05+(i/3)*.14,(i%2)*.2);tube(root,p,.2,.09,gold);ring(root,p+Vector3.UP*.052,.16,Color("f6dc83"))
		var gem=SphereMesh.new();gem.radius=.24;gem.height=.5;gem.radial_segments=5;gem.rings=2;part(root,gem,Vector3(0,.58,0),hue)
	elif k.contains("flower"):
		for i in range(3):
			var p=Vector3((i-1)*.32,.35+i*.12,0);tube(root,p-Vector3.UP*.22,.025,.6,Color("4c7951"));ball(root,p,.11,gold)
			for j in range(6): ball(root,p+Vector3(cos(j*TAU/6)*.16,sin(j*TAU/6)*.16,0),.11,hue)
	elif k in ["freeze","slow","chain","storm","nova","stun","burn","explosion","splash","slamfire","jumpblast","dashblast"]:
		var fire=k in ["burn","explosion","splash","slamfire","jumpblast","dashblast"]
		var shade=Color("e97336") if fire else Color("64bde0")
		for i in range(7):
			var mesh=CylinderMesh.new();mesh.top_radius=0;mesh.bottom_radius=.13;mesh.height=.45+float(i%3)*.18;mesh.radial_segments=5
			var node=part(root,mesh,Vector3(sin(i*2.4)*.24,.3,cos(i*2.4)*.24),shade.lightened(i*.035));node.rotation.z=sin(i)*.4
		ring(root,Vector3(0,-.04,0),.46,gold)
	elif k.contains("turret") or k.contains("drone"):
		tube(root,Vector3(0,.02,0),.4,.13,ink);ball(root,Vector3(0,.38,0),.3,hue)
		for x in [-.13,.13]: tube(root,Vector3(x,.45,-.34),.085,.6,gold).rotation.x=PI/2
		for x in [-.3,.3]: box(root,Vector3(x,.17,0),Vector3(.15,.3,.5),ink)
	elif k in ["range","projectilespeed","multishot","pierce","ricochet","size"]:
		for i in range(3 if k=="multishot" else 1):
			var x=(i-1)*.25 if k=="multishot" else 0.
			tube(root,Vector3(x,.3,0),.1,.55,gold);tube(root,Vector3(x,.65,0),.1,.2,Color("cfdde0"),0)
			for j in range(3): box(root,Vector3(x-.2,.05-j*.08,0),Vector3(.035,.14,.035),Color("89cee1"))
		if k in ["range","pierce"]: ring(root,Vector3(0,.35,-.1),.4,ink).rotation.x=PI/2
	elif k in ["ghost","blind","burrow"]:
		var body=ball(root,Vector3(0,.4,0),.35,Color("d3d5d4"));body.scale.y=1.25
		for x in [-.12,.12]: ball(root,Vector3(x,.52,-.3),.065,ink)
		for i in range(5): tube(root,Vector3((i-2)*.13,.02,0),.085,.2,Color("d3d5d4"),0)
	elif k in ["chestbonus","chestheal","coinheal"]:
		box(root,Vector3(0,.24,0),Vector3(.72,.44,.45),Color("88613e"))
		for x in [-.25,.25]: box(root,Vector3(x,.24,-.24),Vector3(.07,.5,.05),gold)
		box(root,Vector3(0,.25,-.25),Vector3(.13,.16,.055),gold);ball(root,Vector3(0,.27,-.29),.025,ink)
	elif k=="banana":
		for i in range(10): ball(root,Vector3((i-4.5)*.075,pow((i-4.5)*.13,2),0),.09,Color("e6be49"))
	elif k in ["rate","bubbletime"]:
		var face=tube(root,Vector3(0,.4,0),.43,.15,gold);face.rotation.x=PI/2
		var dial=tube(root,Vector3(0,.4,-.09),.36,.03,Color("ece3c6"));dial.rotation.x=PI/2
		box(root,Vector3(0,.51,-.12),Vector3(.045,.24,.035),ink);box(root,Vector3(.1,.4,-.12),Vector3(.2,.04,.035),ink)
		for i in range(12): ball(root,Vector3(sin(i*TAU/12)*.3,.4+cos(i*TAU/12)*.3,-.12),.02,ink)
	else:
		# A forged blade and impact fragments communicate offensive upgrades.
		box(root,Vector3(0,.05,0),Vector3(.1,.38,.12),ink);box(root,Vector3(0,.24,0),Vector3(.5,.09,.18),gold)
		var blade=box(root,Vector3(0,.58,0),Vector3(.2,.6,.055),Color("cbdde1"));blade.rotation.z=-.15
		box(root,Vector3(-.02,.6,-.04),Vector3(.025,.48,.02),hue)
		for i in range(4): ball(root,Vector3(.28+i*.05,.35+i*.12,0),.045,gold)
	# Distinct ornament arrangement per named card, without losing the main silhouette.
	for i in range(2+posmod(hash(id),4)): ball(root,Vector3(-.48+i*.13,-.18,-.2),.032,hue)
	return root

func _initialize(): call_deferred("render_icons")
func render_icons():
	var viewport=SubViewport.new();viewport.size=Vector2i(256,256);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_4X;root.add_child(viewport)
	stage=Node3D.new();viewport.add_child(stage)
	var env=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("f4e8cf");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy=.45;stage.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,-35,0);sun.light_energy=1.2;stage.add_child(sun)
	var rim=DirectionalLight3D.new();rim.rotation_degrees=Vector3(20,140,0);rim.light_color=Color("8bbbd5");rim.light_energy=.55;stage.add_child(rim)
	var camera=Camera3D.new();stage.add_child(camera);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=1.6;camera.position=Vector3(1,1.0,-2.4);camera.look_at(Vector3(0,.3,0))
	DirAccess.make_dir_recursive_absolute("res://assets/illustrated/skill-icons")
	var catalog=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"));var count=0
	for entry in catalog.loot:
		if entry.kind!="skill": continue
		var key=str(entry.effects[0].key);var model_key=key.get_slice("-",2) if key.begins_with("augment-") else key
		var object=model(model_key,entry.id)
		if key.begins_with("augment-"):
			var condition=key.get_slice("-",1)
			var token=Node3D.new();object.add_child(token);token.position=Vector3(.38,.05,-.28);token.scale=Vector3.ONE*.3
			if condition in ["air","dash"]:
				for j in range(4): box(token,Vector3(j*.16,j*.1,0),Vector3(.25,.06,.7-j*.1),Color("edf2df"))
			elif condition in ["healthy","hurt","low"]:
				box(token,Vector3.ZERO,Vector3(.18,.65,.1),Color("d96a72"));box(token,Vector3.ZERO,Vector3(.6,.18,.1),Color("d96a72"))
			elif condition=="ground": box(token,Vector3.ZERO,Vector3(.65,.3,.5),Color("947b60"))
			else:
				var token_count={"alone":1,"crowd":3,"boss":4,"shield":2,"flower":5,"turret":6}.get(condition,2)
				for j in range(token_count): tube(token,Vector3((j-token_count/2.)*.15,0,0),.08,.35,gold)

		await process_frame;await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
		if viewport.get_texture().get_image().save_png("res://assets/illustrated/skill-icons/"+entry.id+".png")!=OK: quit(1);return
		object.queue_free();await process_frame;count+=1
	print("SKILL_ICONS_COMPLETE "+str(count));quit()

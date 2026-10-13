extends SceneTree

var viewport: SubViewport
var stage: Node3D
var camera: Camera3D
var group: Node3D
var captures=[]
var checks={"hero_orbs":true,"enemy_orbs":true,"harvestables":true,"icons":true}

func _initialize(): call_deferred("run")

func shot(name: String):
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	var path="user://roster-"+name+".png"
	if viewport.get_texture().get_image().save_png(path)!=OK: checks.icons=false
	captures.append(path)

func clear_group():
	if is_instance_valid(group): group.free()
	group=Node3D.new();stage.add_child(group)

func caption(parent: Node3D,text: String):
	var label=Label3D.new();label.text=text;label.font_size=24;label.pixel_size=.009;label.position=Vector3(0,-.25,-.7);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;parent.add_child(label)

func run():
	viewport=SubViewport.new();viewport.size=Vector2i(1440,900);viewport.own_world_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;viewport.msaa_3d=Viewport.MSAA_4X;root.add_child(viewport)
	stage=Node3D.new();viewport.add_child(stage)
	var environment=WorldEnvironment.new();environment.environment=Environment.new();environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("101a29");environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color("adc6e2");environment.environment.ambient_light_energy=.4;stage.add_child(environment)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-35,-25,0);sun.light_energy=1.15;stage.add_child(sun)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=17;stage.add_child(camera);camera.position=Vector3(0,4,-20);camera.look_at(Vector3(0,3,0))
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	clear_group();camera.position=Vector3(0,2,-20);camera.look_at(Vector3(0,1,0))
	for i in range(data.heroes.size()):
		var rig=ActorRig.new();rig.setup(data.heroes[i].model);rig.scale=Vector3.ONE*float(data.heroes[i].height)/1.65;group.add_child(rig);rig.position=Vector3((i%7-3)*2.25,(1.5-i/7)*2.4,0);rig.set_health(.5);rig.animate(1,Vector3.ZERO,true)
		checks.hero_orbs=checks.hero_orbs and rig.solid.core_materials.size()==1 and rig.solid.hand_socket()!=null
		caption(rig,data.heroes[i].name)
	await shot("heroes-front");camera.position.z=20;camera.look_at(Vector3(0,1,0));await shot("heroes-back");camera.position=Vector3(0,4,-20);camera.look_at(Vector3(0,3,0))
	for page in range(3):
		clear_group()
		for i in range(18):
			var index=page*18+i
			if index>=42: break
			var model=StyleModel.new();model.setup("creature_%d_%d" % [index/7,index%7]);group.add_child(model);model.position=Vector3((i%6-2.5)*2.4,(2-i/6)*2.7,0);model.set_health(.5,true)
			checks.enemy_orbs=checks.enemy_orbs and model.core_materials.size()==1;caption(model,"%s %d" % [RealmWorld.BIOMES[index/7],index%7+1])
		await shot("enemies-"+str(page))
	for biome in range(6):
		clear_group()
		for i in range(6):
			var model=StyleModel.new();model.setup("prop_%d_%d" % [biome,i]);group.add_child(model);model.scale=Vector3.ONE*.5;model.position=Vector3((i%3-1)*5.4,(1-i/3)*4.8,0)
		var plant=HarvestBook.make_model(biome);group.add_child(plant);plant.position=Vector3(6,-.2,-.2);plant.scale=Vector3.ONE*2;caption(plant,HarvestBook.TYPES[biome].name)
		checks.harvestables=checks.harvestables and plant.get_child_count()>0
		await shot("biome-"+str(biome))
	clear_group()
	var canvas=Control.new();viewport.add_child(canvas)
	var entries=data.loot+data.weapons
	for page in range(ceili(entries.size()/80.0)):
		for child in canvas.get_children(): child.free()
		for i in range(80):
			var index=page*80+i
			if index>=entries.size(): break
			var entry=entries[index];var icon=TextureRect.new();icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.texture=IllustratedIcons.texture(entry.id,not entry.has("effects"));canvas.add_child(icon);icon.position=Vector2(i%10*144+16,i/10*112+2);icon.size=Vector2(104,88)
			checks.icons=checks.icons and icon.texture!=null
			var label=Label.new();label.text=entry.get("title",entry.get("name",entry.id));label.position=Vector2(i%10*144+4,i/10*112+90);label.size=Vector2(138,20);label.clip_text=true;label.add_theme_font_size_override("font_size",11);canvas.add_child(label)
		await shot("icons-"+str(page))
	canvas.free();stage.free();viewport.queue_free();await process_frame
	print("ROSTER_REVIEW "+JSON.stringify({"checks":checks,"captures":captures,"heroes":data.heroes.size(),"enemies":42,"props":36,"icons":entries.size()}));quit(0 if not checks.values().has(false) else 1)

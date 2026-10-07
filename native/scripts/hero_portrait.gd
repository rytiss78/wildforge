extends TextureRect
class_name HeroPortrait

var preview_actor: Node3D
var preview_view: SubViewport
var idle_time=0.0

func _process(delta: float):
	if not is_instance_valid(preview_actor): return
	preview_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
	if not is_visible_in_tree(): return
	idle_time+=delta
	preview_actor.rotation.y=.28+sin(idle_time*.55)*.22
	preview_actor.animate(delta,Vector3.ZERO,true)

func setup(model_name: String,weapon: String="gun",armour: float=0,shield_capacity: float=0):
	expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var path="res://assets/illustrated/heroes/"+model_name+".png"
	var asset="count_duck" if model_name=="rubber_duck_toy" else "hero_"+model_name
	if not ResourceLoader.exists("res://assets/style3d/"+asset+".glb") and ResourceLoader.exists(path): texture=load(path);return
	var viewport=SubViewport.new()
	viewport.size=Vector2i(512,512)
	viewport.own_world_3d=true
	viewport.transparent_bg=true
	preview_view=viewport
	viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	viewport.msaa_3d=Viewport.MSAA_2X
	add_child(viewport)
	var stage=Node3D.new()
	viewport.add_child(stage)
	var hero=ActorRig.new()
	preview_actor=hero
	hero.setup(model_name)
	hero.rotation.y=.28
	stage.add_child(hero)
	hero.set_defense(armour,shield_capacity,shield_capacity)
	hero.sync_equipment([{"id":weapon,"rank":1}]);hero.arms[0].rotation.x=.06
	var floor_mesh=CylinderMesh.new()
	floor_mesh.top_radius=1.2;floor_mesh.bottom_radius=1.2;floor_mesh.height=.06
	ToonArt.part(stage,floor_mesh,Color("a3b6a2"),Vector3(0,-.03,0))
	var env=WorldEnvironment.new()
	env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color("e4e8ce")
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color=Color("fff2d7")
	env.environment.ambient_light_energy=.55
	viewport.add_child(env)
	var sun=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-40,-35,0)
	sun.light_energy=.9;sun.shadow_enabled=true
	viewport.add_child(sun)
	var camera=Camera3D.new()
	viewport.add_child(camera)
	camera.position=Vector3(2.0,1.8,-4.5)
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=2.65
	camera.look_at(Vector3(0,.8,0))
	texture=viewport.get_texture()

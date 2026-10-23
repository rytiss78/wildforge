extends RefCounted
class_name DeathFx

# How enemies die, picked by the killing blow:
#   ink dissolve  the body darkens and erodes top-down into an ink blot while
#                 dark wisps rise (most kills; slower and larger for bosses)
#   shatter       frost, crits, explosions, slams and meteors burst the body into
#                 tumbling shards in its own colour
# Purely visual. Entries live in g.death_fx and are ticked by update_combat.
const SHATTER_CAUSES=["ice","crit","explosion","slam","meteor","sonic"]
const INK=Color("16121f")
const MAX_SHARDS=180
static var shard_mesh: PrismMesh
static var shard_paints={}
static var blot_mesh: QuadMesh
static var blot_paint: StandardMaterial3D

static func start(g,enemy: Dictionary,cause: String,landing: Vector3):
	var node: Node3D=enemy.node;var rig=node.get_meta("rig") if node.has_meta("rig") else null
	var shatter=not enemy.boss and (cause in SHATTER_CAUSES or float(enemy.get("freeze",0))>0)
	var size=clampf(float(enemy.get("height",1.7))/1.7,.6,3.0)
	if shatter:
		shards(g,node.position+Vector3.UP*.7*size,rig,size,cause=="ice" or float(enemy.get("freeze",0))>0)
		node.visible=false
		g.death_fx.append({"kind":"gone","node":node,"life":.4})
		return
	var duration=1.4 if enemy.boss else .6
	var paint: ShaderMaterial=rig.batched if rig!=null and rig.get("batched")!=null else null
	if paint!=null: paint.next_pass=null  # no outline left behind as a ghost
	g.death_fx.append({"kind":"ink","node":node,"rig":rig,"paint":paint,"age":0.0,"life":duration,"from":node.position,"to":landing-Vector3.UP*.35*size})
	blot(g,landing,size*(2.2 if enemy.boss else 1.0))
	for i in range(int(clampf(4*EffectDetail.particles,2,6))):
		var wisp=CombatInk.star(g,landing+Vector3(randf_range(-.5,.5),.4+i*.25,randf_range(-.5,.5))*size,.5*size,Color("2a1f3a"),5.0,.6,1.0,"trail")
		if wisp!=null: wisp.fall=-2.2

static func shards(g,center: Vector3,rig,size: float,frozen: bool=false):
	if shard_mesh==null: shard_mesh=PrismMesh.new();shard_mesh.size=Vector3(.22,.32,.12)
	var color: Color=rig.skin if rig!=null else Color("c9b28a")
	if frozen: color=color.lerp(Color("bfeaff"),.7)
	var key=color.to_html()+("ice" if frozen else "")
	if not shard_paints.has(key):
		var paint=StandardMaterial3D.new();paint.albedo_color=color;paint.roughness=1.0
		# Ice reads as ice in any light: unshaded and pale. Other shards keep the stone grain.
		if frozen: paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;paint.albedo_color=Color("d8f4ff")
		else: paint.albedo_texture=load("res://assets/illustrated/stone.png")
		shard_paints[key]=paint
	var live=g.death_fx.filter(func(e):return e.kind=="shard").size()
	var count=mini(int(clampf(9*EffectDetail.particles,3,12)),MAX_SHARDS-live)
	for i in range(count):
		var piece=MeshInstance3D.new();piece.mesh=shard_mesh;piece.material_override=shard_paints[key];piece.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.add_child(piece);piece.position=center+Vector3(randf_range(-.3,.3),randf_range(-.3,.3),randf_range(-.3,.3))*size
		piece.scale=Vector3.ONE*size*randf_range(.7,1.3);piece.rotation=Vector3(randf()*TAU,randf()*TAU,randf()*TAU)
		var out=Vector3(randf_range(-1,1),0,randf_range(-1,1)).normalized()*randf_range(2.5,5.5)+Vector3.UP*randf_range(3.0,6.5)
		g.death_fx.append({"kind":"shard","node":piece,"velocity":out,"spin":Vector3(randf_range(-9,9),randf_range(-9,9),randf_range(-9,9)),"age":0.0,"life":randf_range(.7,1.1),"scale":piece.scale})
	CombatInk.star(g,center,1.2*size,color.lightened(.3),7.0,.2)

# A flat ink splat on the ground that spreads, then fades.
static func blot(g,at: Vector3,size: float):
	if blot_mesh==null:
		blot_mesh=QuadMesh.new();blot_mesh.size=Vector2(2.0,2.0);blot_mesh.orientation=PlaneMesh.FACE_Y
		blot_paint=StandardMaterial3D.new();blot_paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;blot_paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		# A soft round splat: radial alpha, dense centre, ragged-looking falloff.
		var ramp=Gradient.new();ramp.offsets=PackedFloat32Array([0.0,.55,.8,1.0]);ramp.colors=PackedColorArray([Color(INK,.9),Color(INK,.8),Color(INK,.35),Color(INK,0.0)])
		var splat=GradientTexture2D.new();splat.gradient=ramp;splat.fill=GradientTexture2D.FILL_RADIAL;splat.fill_from=Vector2(.5,.5);splat.fill_to=Vector2(1.0,.5);splat.width=128;splat.height=128
		blot_paint.albedo_texture=splat;blot_paint.albedo_color=Color.WHITE
	var node=MeshInstance3D.new();node.mesh=blot_mesh;node.material_override=blot_paint;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	g.add_child(node);node.position=Vector3(at.x,g.world.height_at(at.x,at.z)+.06,at.z);node.rotation.y=randf()*TAU;node.scale=Vector3.ONE*.2*size
	g.death_fx.append({"kind":"blot","node":node,"age":0.0,"life":2.2,"size":size})

static func tick(g,delta: float):
	if g.death_fx.is_empty(): return
	for entry in g.death_fx:
		entry.life-=delta;entry.age=float(entry.get("age",0))+delta
		var node: Node3D=entry.node
		if not is_instance_valid(node): entry.life=0.0;continue
		match entry.kind:
			"ink":
				var t=clampf(entry.age/(entry.age+entry.life),0,1)
				node.position=entry.from.lerp(entry.to,t*t)
				if entry.paint!=null:
					entry.paint.set_shader_parameter("dissolve",t*1.05)
					entry.paint.set_shader_parameter("tint",Vector3.ONE.lerp(Vector3(.25,.22,.3),t))
				elif entry.rig!=null and entry.rig.illustrated:
					entry.rig.illustration.modulate=Color(1,1,1,1).lerp(Color(INK,0.0),t)
				else: node.scale=Vector3.ONE.lerp(Vector3(.9,.08,.9),t)
			"shard":
				entry.velocity.y-=20.0*delta
				var p: Vector3=node.position+entry.velocity*delta;var ground=g.world.height_at(p.x,p.z)+.08
				if p.y<ground: p.y=ground;entry.velocity*=Vector3(.45,-.25,.45);entry.spin*=.5
				node.position=p;node.rotation+=entry.spin*delta
				node.scale=entry.scale*clampf(entry.life/.35,0,1)
			"blot":
				node.scale=Vector3.ONE*entry.size*lerpf(.2,1.0,1.0-pow(1.0-clampf(entry.age/.35,0,1),3.0))
				node.transparency=1.0-clampf(entry.life/1.0,0,1)
	for entry in g.death_fx:
		if entry.life<=0 and is_instance_valid(entry.node): entry.node.queue_free()
	g.death_fx=g.death_fx.filter(func(e):return e.life>0)

static func clear(g):
	for entry in g.death_fx:
		if is_instance_valid(entry.node): entry.node.queue_free()
	g.death_fx.clear()

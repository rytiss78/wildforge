extends RefCounted
class_name Lava

# Lava (user request, November 1): the Candy Hell rivers and the lava-vent pools
# set whoever stands in them on fire for a moment. The hero burns for HERO_BURN
# seconds and shows real flames; monsters catch fire; bosses only smoulder (a
# little burn damage); gold and XP orbs that land in lava sizzle away.

const HERO_BURN=2.5
const MONSTER_BURN=2.5
static var clock=0.0

# Rivers (RealmWorld.lava_at) or a spreading lava pool (BiomeMechanics).
static func at(g,p: Vector3) -> bool:
	if g.world.lava_at(p): return true
	for zone in g.biome_zones:
		if zone.kind=="lava" and BiomeMechanics.live(zone) and BiomeMechanics.inside(zone,p): return true
	return false

static func ignite(g,enemy: Dictionary):
	if enemy.dead or enemy.get("flying",false): return
	var heat=(2.0+g.realm) if enemy.boss else (8.0+g.realm*3.0)
	g.set_damage_status(enemy,"fire",heat,g.coop.local_id);enemy.status_time=maxf(float(enemy.status_time),MONSTER_BURN)

# Monsters wading through the rivers (pools ignite them in BiomeMechanics).
static func tick(g,delta: float):
	clock-=delta
	if clock>0: return
	clock=.5
	if g.coop.active and not g.coop.hosting: return
	for enemy in g.enemies:
		if not enemy.dead and g.world.lava_at(enemy.node.position): ignite(g,enemy)
	# Drops lying where a lava pool has spread since they landed.
	for pickup in g.pickups:
		if pickup.age>=0 and pickup.get("settled",false) and not pickup.get("attracted",false): burns_drop(g,pickup)

# Gold and XP orbs that come to rest in lava burn up. XP is the host's to remove.
static func burns_drop(g,pickup: Dictionary) -> bool:
	if not pickup.kind in ["gold","xp"] or pickup.get("magnet_heap",false): return false
	if pickup.kind=="xp" and g.coop.active and not g.coop.hosting: return false
	var p: Vector3=pickup.node.position
	if not at(g,p): return false
	g.burst(p+Vector3.UP*.3,Color("ff7a2a"),6);g.burst(p+Vector3.UP*.6,Color("4a3a3a"),4)
	pickup.node.queue_free();pickup.age=-1
	return true

# Flames on the burning hero: a flickering column of fire and a warm light.
static func hero_flames(g,on: bool):
	var flames: GPUParticles3D=g.player.get_node_or_null("HeroFlames")
	if flames==null:
		if not on: return
		flames=make_flames(float(g.hero.get("height",1.65)));g.player.add_child(flames)
	flames.emitting=on
	var lamp=flames.get_node_or_null("Glow")
	if lamp!=null: lamp.visible=on

static var flame_texture: Texture2D

static func make_flames(height: float) -> GPUParticles3D:
	var flames=GPUParticles3D.new();flames.name="HeroFlames";flames.amount=40;flames.lifetime=.5
	flames.local_coords=false;flames.position=Vector3(0,height*.3,0);flames.emitting=false
	flames.visibility_aabb=AABB(Vector3(-2,-1,-2),Vector3(4,4,4));flames.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var motion=ParticleProcessMaterial.new()
	motion.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_BOX;motion.emission_box_extents=Vector3(.42,height*.3,.42)
	motion.direction=Vector3.UP;motion.spread=12.0;motion.initial_velocity_min=2.2;motion.initial_velocity_max=3.4;motion.gravity=Vector3(0,2.0,0)
	var shrink=Curve.new();shrink.add_point(Vector2(0,.6));shrink.add_point(Vector2(.3,1.0));shrink.add_point(Vector2(1,0))
	var shrink_texture=CurveTexture.new();shrink_texture.curve=shrink;motion.scale_curve=shrink_texture
	var heat=Gradient.new();heat.offsets=PackedFloat32Array([0.0,.35,.75,1.0])
	heat.colors=PackedColorArray([Color(1,.88,.35,.95),Color(1,.5,.1,.9),Color(.85,.15,.04,.6),Color(.25,.08,.04,0)])
	var heat_texture=GradientTexture1D.new();heat_texture.gradient=heat;motion.color_ramp=heat_texture
	flames.process_material=motion
	if flame_texture==null:
		var soft=Gradient.new();soft.offsets=PackedFloat32Array([0.0,.45,1.0]);soft.colors=PackedColorArray([Color(1,1,1,1),Color(1,1,1,.85),Color(1,1,1,0)])
		var tex=GradientTexture2D.new();tex.gradient=soft;tex.fill=GradientTexture2D.FILL_RADIAL;tex.fill_from=Vector2(.5,.5);tex.fill_to=Vector2(1,.5);tex.width=64;tex.height=64
		flame_texture=tex
	var quad=QuadMesh.new();quad.size=Vector2(.42,.7)
	var paint=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.vertex_color_use_as_albedo=true;paint.albedo_texture=flame_texture
	paint.billboard_mode=BaseMaterial3D.BILLBOARD_PARTICLES;paint.disable_receive_shadows=true
	quad.material=paint;flames.draw_pass_1=quad
	var lamp=OmniLight3D.new();lamp.name="Glow";lamp.light_color=Color("ff8a2a");lamp.light_energy=1.6;lamp.omni_range=4.0;lamp.shadow_enabled=false;lamp.visible=false
	flames.add_child(lamp)
	return flames

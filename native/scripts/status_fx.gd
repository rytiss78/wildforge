extends RefCounted
class_name StatusFx

# Readable enemy statuses: flame tongues licking a burning body, toxic bubbles
# rising from a poisoned one, frost glints and an ice shell on a frozen one, and
# dark motes over a blinded one. A flare marks the moment a status catches, so
# fire and poison visibly spread through a group; a burning or poisoned enemy
# bursts into embers or a toxic puff when it dies. Purely visual.
const LOOK={
	"fire":{"shape":0.0,"amount":16,"life":.6,"rise":2.0,"size":1.6,"colors":[Color(1,.82,.3,1),Color(1,.42,.08,.95),Color(.7,.1,.04,0)]},
	"poison":{"shape":1.0,"amount":14,"life":1.0,"rise":1.2,"size":1.3,"colors":[Color(.9,1,.3,.85),Color(.72,1,.16,1),Color(.45,.8,.08,0)]},
	"ice":{"shape":2.0,"amount":8,"life":.8,"rise":.3,"size":.7,"colors":[Color(1,1,1,.8),Color(.8,.97,1,1),Color(.55,.85,1,0)]},
	"blind":{"shape":3.0,"amount":8,"life":1.0,"rise":.4,"size":.45,"colors":[Color(.3,.22,.4,.7),Color(.25,.18,.35,.9),Color(.1,.08,.15,0)]},
}
static var paints={}

static func paint(id: String) -> ShaderMaterial:
	if not paints.has(id):
		var material=ShaderMaterial.new();material.shader=preload("res://shaders/status_mote.gdshader");material.set_shader_parameter("shape",LOOK[id].shape);paints[id]=material
	return paints[id]

static func make(g: Node3D,enemy: Dictionary,id: String) -> GPUParticles3D:
	var look=LOOK[id]
	var radius=clampf(float(enemy.get("radius",.7)),.4,3.0);var height=clampf(float(enemy.get("height",1.7)),.8,9.0)
	var node=GPUParticles3D.new()
	var process=ParticleProcessMaterial.new()
	# Emit from the body's surface (an upright ellipsoid) so effects are not hidden inside it.
	var shell_radius=maxf(radius,height*.45)
	process.emission_shape=ParticleProcessMaterial.EMISSION_SHAPE_SPHERE_SURFACE if id!="blind" else ParticleProcessMaterial.EMISSION_SHAPE_RING
	process.emission_sphere_radius=shell_radius*.85
	process.emission_shape_scale=Vector3(radius/shell_radius,height*.5/shell_radius,radius/shell_radius) if id!="blind" else Vector3.ONE
	if id=="blind": process.emission_ring_radius=radius*.7;process.emission_ring_inner_radius=radius*.5;process.emission_ring_height=.1;process.emission_ring_axis=Vector3.UP
	process.direction=Vector3.UP;process.spread=12.0
	process.initial_velocity_min=look.rise*.6;process.initial_velocity_max=look.rise
	process.gravity=Vector3.ZERO if id!="ice" else Vector3(0,-.4,0)
	var size=clampf(radius*float(look.size),.3,2.8)
	process.scale_min=size*.55;process.scale_max=size
	var curve=Curve.new();curve.add_point(Vector2(0,.5));curve.add_point(Vector2(.3,1));curve.add_point(Vector2(1,.25 if id=="fire" else .8))
	var scale_texture=CurveTexture.new();scale_texture.curve=curve;process.scale_curve=scale_texture
	var ramp=Gradient.new();ramp.offsets=PackedFloat32Array([0,.35,1]);ramp.colors=PackedColorArray(look.colors)
	var ramp_texture=GradientTexture1D.new();ramp_texture.gradient=ramp;process.color_ramp=ramp_texture
	if id=="blind": process.orbit_velocity_min=.6;process.orbit_velocity_max=.9
	node.process_material=process
	node.amount=int(look.amount*clampf(radius/.7,1.0,2.5));node.lifetime=look.life;node.local_coords=false
	node.draw_pass_1=QuadMesh.new();node.material_override=paint(id).duplicate()
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.position=Vector3(0,height*(.5 if id!="blind" else 1.12),0)
	node.visibility_aabb=AABB(Vector3(-radius-2,-height,-radius-2),Vector3(radius*2+4,height*2+4,radius*2+4))
	if id=="ice":
		# A translucent ice shell reads as "frozen solid" from any angle.
		var shell=MeshInstance3D.new();var sphere=SphereMesh.new();sphere.radius=1.0;sphere.height=2.0;sphere.radial_segments=12;sphere.rings=6;shell.mesh=sphere
		shell.scale=Vector3(radius*1.25,height*.62,radius*1.25)
		var ice=StandardMaterial3D.new();ice.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ice.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		ice.albedo_color=Color(.72,.93,1,.26);ice.rim_enabled=false;ice.cull_mode=BaseMaterial3D.CULL_BACK;ice.no_depth_test=false
		shell.material_override=ice;shell.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.add_child(shell)
	node.amount_ratio=snappedf(EffectDetail.status_ratio,.1)
	node.emitting=true
	return node

# The moment a status starts on an enemy.
static func caught(g: Node3D,enemy: Dictionary,id: String):
	var center: Vector3=g.enemy_center(enemy)
	var size=clampf(float(enemy.get("radius",.7))*2.2,1.3,4.0)
	match id:
		"fire":
			var root=CombatInk.star(g,center,size,Color("ff6a1c"),7.0,.34,1.0,"status")
			if root!=null: root.shards(Color("ffb347"),5,2.6);root.fall=-4.0
		"poison":
			var root=CombatInk.star(g,center,size*.9,Color("7fd844"),9.0,.36,1.0,"status")
			if root!=null: root.shards(Color("b6f06a"),5,2.2);root.fall=6.0
		"ice":
			var root=CombatInk.star(g,center,size,Color("c8f6ff"),4.0,.34,1.0,"status")
			if root!=null: root.shards(Color("eafcff"),6,2.4)
		"blind":
			CombatInk.star(g,center+Vector3.UP*float(enemy.get("height",1.7))*.5,size*.7,Color("4a3a5c"),5.0,.34,1.0,"status")

# A burning enemy bursts into embers; a poisoned one into a toxic puff.
static func death(g: Node3D,enemy: Dictionary):
	if not is_instance_valid(enemy.get("node")): return
	var center: Vector3=g.enemy_center(enemy)
	var size=clampf(float(enemy.get("radius",.7))*3.0,1.8,5.0)
	if float(enemy.get("fire",0))>0:
		var root=CombatInk.star(g,center,size,Color("ff5a14"),8.0,.45,1.0,"status")
		if root!=null: root.shards(Color("ffb347"),9,3.6);root.fall=-2.5
	if float(enemy.get("poison",0))>0:
		var root=CombatInk.star(g,center,size,Color("6fcf38"),10.0,.5,1.0,"status")
		if root!=null: root.shards(Color("a6ec5c"),8,3.0);root.fall=5.0
		ShotFx.splat(g,center,Color("5fae2c"),size*.8)

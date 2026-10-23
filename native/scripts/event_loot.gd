extends RefCounted
class_name EventLoot

# Chests from events (warden and guardian kills, a won hunt) are worth walking
# to: a gold beacon beam reaches into the sky, the chest glows, and opening one
# rolls rare-or-better cards with a guaranteed mutation. The beacon fades once
# the chest is opened.
const MIN_TIER=2
static var beam_mesh: CylinderMesh

static func beacon(g,chest: Dictionary):
	if beam_mesh==null:
		beam_mesh=CylinderMesh.new();beam_mesh.top_radius=.35;beam_mesh.bottom_radius=.75;beam_mesh.height=1.0;beam_mesh.cap_top=false;beam_mesh.cap_bottom=false;beam_mesh.radial_segments=16;beam_mesh.rings=1
	var root=Node3D.new();chest.node.add_child(root)
	var beam=MeshInstance3D.new();beam.mesh=beam_mesh;beam.scale=Vector3(1,60,1);beam.position.y=30
	var paint=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.albedo_color=Color(1,.86,.42,.32);paint.cull_mode=BaseMaterial3D.CULL_DISABLED;paint.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
	beam.material_override=paint;beam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(beam)
	var core=MeshInstance3D.new();core.mesh=beam_mesh;core.scale=Vector3(.35,60,.35);core.position.y=30
	var hot=paint.duplicate();hot.albedo_color=Color(1,.97,.8,.55);core.material_override=hot;core.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;root.add_child(core)
	var glow=OmniLight3D.new();glow.light_color=Color("ffd36a");glow.light_energy=2.2;glow.omni_range=6.0;glow.position.y=1.2;root.add_child(glow)
	chest.beacon=root
	var ring=CombatInk.star(g,chest.node.position+Vector3.UP*1.2,4.0,Color("ffd36a"),8.0,.8)
	if ring!=null: ring.shards(Color("fff0b0"),12,4.0);ring.fall=-2.0
	CombatInk.wave(g,chest.node.position,4.0,Color("ffd36a"))

# Called from the chest loop: pulse while waiting, fade out once opened.
static func tick(chest: Dictionary,delta: float):
	var root=chest.get("beacon")
	if not is_instance_valid(root): return
	if chest.opened:
		root.scale.x=maxf(0.0,root.scale.x-delta*1.5);root.scale.z=root.scale.x
		if root.scale.x<=.01: root.queue_free();chest.erase("beacon")
	else:
		var pulse=1.0+sin(Time.get_ticks_msec()*.004)*.08;root.scale=Vector3(pulse,1,pulse)

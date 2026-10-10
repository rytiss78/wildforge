extends RefCounted
class_name EclipseCorruption

static var thorn_mesh: ArrayMesh
static var thorn_paint: StandardMaterial3D

static func thorns() -> ArrayMesh:
	if thorn_mesh!=null: return thorn_mesh
	var surface=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in range(5):
		var side=-1. if index%2==0 else 1.
		var root=Vector3(side*.27,.60+index*.12,.20)
		var tip=root+Vector3(side*(.22+index*.025),.32+index*.025,.12)
		for face in range(5):
			var a=face*TAU/5;var b=(face+1)*TAU/5
			for vertex in [root+Vector3(cos(a),0,sin(a))*.13,root+Vector3(cos(b),0,sin(b))*.13,tip]:
				surface.set_color(Color("eead68") if vertex==tip else Color("423b50"));surface.add_vertex(vertex)
	surface.generate_normals();thorn_mesh=surface.commit()
	thorn_paint=StandardMaterial3D.new();thorn_paint.vertex_color_use_as_albedo=true;thorn_paint.roughness=1.;thorn_paint.cull_mode=BaseMaterial3D.CULL_DISABLED
	return thorn_mesh

static func apply(enemy: Dictionary,stage: int):
	if enemy.dead or stage<=0 or int(enemy.get("corruption",0))==stage: return
	enemy["corruption"]=stage
	var rig=enemy.node.get_meta("rig")
	if rig==null: return
	var intensity=clampf(.22+stage*.065+(.18 if enemy.elite else .10 if enemy.boss else 0.),0,.85)
	if not rig.has_meta("uncorrupted_scale"): rig.set_meta("uncorrupted_scale",rig.scale)
	# Mild whole-rig distortion retains health-core alignment and collision readability.
	rig.scale=rig.get_meta("uncorrupted_scale")*Vector3(1+intensity*.10,1+intensity*.22,1-intensity*.06)
	enemy.corruption_lean=intensity*.075*(-1 if int(enemy.get("net_id",0))%2==0 else 1)
	rig.rotation.z=enemy.corruption_lean
	if rig.batched!=null: rig.batched.set_shader_parameter("corruption",intensity)
	if not rig.has_meta("corruption_thorns"):
		var crown=MeshInstance3D.new();crown.mesh=thorns();crown.material_override=thorn_paint
		crown.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;rig.add_child(crown);rig.set_meta("corruption_thorns",crown)
	var crown=rig.get_meta("corruption_thorns")
	if crown==null: return
	var local_height=float(enemy.height)/float(rig.get_meta("uncorrupted_scale").y)
	crown.scale=Vector3.ONE*local_height*.65*(.7+intensity*.5)
	crown.position.y=local_height*.32

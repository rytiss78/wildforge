extends RefCounted
class_name GroundRing

# A flat area marker: a soft fill and a bright rim, following the ground (or flat,
# for spots under the island), so an area effect reads at a glance. Used by the
# pulsing turrets and the Florist's flowers.
static var paints={}

static func paint(color: Color,alpha: float) -> StandardMaterial3D:
	var key=color.to_html()+str(alpha)
	if not paints.has(key):
		var m=StandardMaterial3D.new();m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color=Color(color,alpha);m.cull_mode=BaseMaterial3D.CULL_DISABLED;m.disable_receive_shadows=true
		paints[key]=m
	return paints[key]

# Returns a node to be placed at `at` (local positions are relative to it).
static func make(g,at: Vector3,radius: float,color: Color,fill: float=.14,follow_ground: bool=true) -> Node3D:
	var root=Node3D.new()
	var lift=func(x: float,z: float) -> float:
		return (g.world.height_at(at.x+x,at.z+z)-at.y+.08) if follow_ground else .06
	var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rim=SurfaceTool.new();rim.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps=36
	# A plain fill, a touch stronger towards the edge; no outline (user request,
	# November 1: "ground indicators should not have edge lines").
	for i in range(steps):
		var a=Vector2.RIGHT.rotated(i*TAU/steps);var b=Vector2.RIGHT.rotated((i+1)*TAU/steps)
		for uv in [Vector2.ZERO,a*.7,b*.7]:
			var p=Vector3(uv.x*radius,0,uv.y*radius);p.y=lift.call(p.x,p.z);tool.add_vertex(p)
		for uv in [a*.7,a,b,a*.7,b,b*.7]:
			var q=Vector3(uv.x*radius,0,uv.y*radius);q.y=lift.call(q.x,q.z)+.005;rim.add_vertex(q)
	var disc=MeshInstance3D.new();disc.name="Fill";disc.mesh=tool.commit();disc.material_override=paint(color,fill);disc.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var outer=MeshInstance3D.new();outer.name="Outer";outer.mesh=rim.commit();outer.material_override=paint(color,fill*1.6);outer.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(disc);root.add_child(outer)
	return root

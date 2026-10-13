extends Node3D
class_name CombatInk

# One lifetime belongs to the game's effects list. Children and lights are freed
# with it on expiry, realm changes and restart; no independent processing/timers.
var duration=.5
var age=0.0
var parts=[]
var paints: Array[ShaderMaterial]=[]
var flash: OmniLight3D
var flash_energy=0.0
static var shard_mesh: ArrayMesh

static func begin(g: Node3D,point: Vector3,seconds: float) -> CombatInk:
	if g.effects.size()>220 or g.effects.filter(func(e):return e.get("ink_fx",false)).size()>=28: return null
	var root=CombatInk.new();root.duration=seconds;g.add_child(root);root.position=point
	g.effects.append({"node":root,"life":seconds,"velocity":Vector3.ZERO,"stationary":true,"ink_fx":true})
	return root

func mesh_part(mesh: Mesh,paint: Material) -> MeshInstance3D:
	var part=MeshInstance3D.new();part.mesh=mesh;part.material_override=paint;part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(part);return part

func pigment(shader: Shader,color: Color) -> ShaderMaterial:
	var paint=ShaderMaterial.new();paint.shader=shader;paint.set_shader_parameter("pigment",color);paints.append(paint);return paint

func lamp(g: Node3D,color: Color,energy: float,radius: float,offset: Vector3):
	# Only a few bursts illuminate the scene at once. Particle count cannot spawn lights.
	if g.effects.filter(func(e):return e.get("ink_fx",false) and is_instance_valid(e.node.flash)).size()>=3: return
	flash=OmniLight3D.new();flash.light_color=color;flash.light_energy=energy;flash.omni_range=radius;flash.position=offset;flash.shadow_enabled=false;add_child(flash);flash_energy=energy

static func shard() -> ArrayMesh:
	if shard_mesh!=null: return shard_mesh
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(0,.65,0),Vector3(-.13,-.2,0),Vector3(0,-.48,0),Vector3(.13,-.2,0)])
	arrays[Mesh.ARRAY_TEX_UV]=PackedVector2Array([Vector2(.5,0),Vector2(0,.65),Vector2(.5,1),Vector2(1,.65)])
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,1,2,0,2,3]);shard_mesh=ArrayMesh.new();shard_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);return shard_mesh

func shards(color: Color,count: int,spread: float):
	var paint=pigment(preload("res://shaders/ink_spark.gdshader"),color)
	for i in range(count):
		var angle=i*2.39996;var direction=Vector3(cos(angle),.2+float(i%3)*.2,sin(angle)).normalized()
		var node=mesh_part(shard(),paint);var width=.32+float(i%3)*.13
		node.scale=Vector3(width,.7+float(i%4)*.3,width)
		node.look_at_from_position(global_position,global_position+direction,Vector3.UP);node.rotate_object_local(Vector3.RIGHT,PI/2)
		parts.append({"node":node,"velocity":direction*spread,"scale":node.scale})

static func burst(g: Node3D,point: Vector3,color: Color,count: int):
	var root=begin(g,point,.42)
	if root==null: return
	var saturated=Color.from_hsv(color.h,maxf(.58,color.s) if color.s>.08 else color.s,minf(1.0,maxf(.72,color.v)))
	root.shards(saturated,clampi(count,1,12),4.5)

static func blast(g: Node3D,point: Vector3,radius: float):
	var root=begin(g,point,.62)
	if root==null: return
	var paint=root.pigment(preload("res://shaders/ink_blast.gdshader"),Color("ff481b"))
	var quad=QuadMesh.new();quad.size=Vector2.ONE*radius*2.0
	var cloud=root.mesh_part(quad,paint);cloud.position.y=radius*.52
	var ring=PlaneMesh.new();ring.size=Vector2.ONE*radius*2.0
	root.mesh_part(ring,root.pigment(preload("res://shaders/ink_wave.gdshader"),Color("ff8b23"))).position.y=.10
	root.shards(Color("ff8b23"),9,radius*4.0)
	root.lamp(g,Color("ff8c28"),5.5,minf(14.0,radius*2.4+2),Vector3.UP*1.4)

static func wave(g: Node3D,point: Vector3,radius: float,color: Color):
	var root=begin(g,point,.55)
	if root==null: return
	var wave=preload("res://scripts/danger_mark.gd").make(g,point,radius,"storm")
	wave.reparent(root,true)
	wave.material_override=root.pigment(preload("res://shaders/ink_wave.gdshader"),color)
	root.shards(color,12,radius*2.5)
	root.lamp(g,color,4.5,minf(14,radius*2),Vector3.UP)

static func ribbon(points: Array,width: float,camera: Camera3D) -> ArrayMesh:
	var vertices=PackedVector3Array();var uvs=PackedVector2Array();var indices=PackedInt32Array()
	for i in range(points.size()):
		var direction: Vector3=points[mini(i+1,points.size()-1)]-points[maxi(0,i-1)]
		var side=direction.cross(camera.global_basis.z).normalized()
		if side.length_squared()<.01: side=camera.global_basis.x
		var taper=.6 if i==0 or i==points.size()-1 else 1.0
		vertices.append(points[i]-side*width*taper);vertices.append(points[i]+side*width*taper)
		uvs.append(Vector2(0,float(i)/points.size()));uvs.append(Vector2(1,float(i)/points.size()))
		if i<points.size()-1: indices.append_array([i*2,i*2+1,i*2+2,i*2+1,i*2+3,i*2+2])
	var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_TEX_UV]=uvs;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);return mesh

static func beam(g: Node3D,from: Vector3,to: Vector3,color: Color,jagged: bool=false,width_scale: float=1.0):
	if from.distance_squared_to(to)<.001: return
	var root=begin(g,from,.24 if jagged else .16)
	if root==null: return
	var direction=(to-from).normalized();var side=direction.cross(Vector3.UP).normalized()
	if side.length_squared()<.01: side=Vector3.RIGHT
	var points=[];var segments=8 if jagged else 1
	for i in range(segments+1):
		var t=float(i)/segments;var point=(to-from)*t
		if jagged and i>0 and i<segments: point+=side*sin(i*2.17)*.70+Vector3.UP*cos(i*3.9)*.22
		points.append(point)
	root.mesh_part(ribbon(points,(.12 if jagged else .075)*width_scale,g.camera),root.pigment(preload("res://shaders/ink_spark.gdshader"),color))
	root.mesh_part(ribbon(points,(.032 if jagged else .021)*width_scale,g.camera),root.pigment(preload("res://shaders/ink_spark.gdshader"),Color("fff9d4")))
	if jagged:
		root.lamp(g,color,2.4,5,to-from)
		var sparks=begin(g,to,.27)
		if sparks!=null: sparks.shards(color,5,3.5)

func advance(delta: float):
	age+=delta;var fraction=clampf(age/duration,0,1)
	for paint in paints: paint.set_shader_parameter("age",fraction)
	for part in parts:
		part.node.position=part.velocity*age+Vector3.DOWN*age*age*3.0
		part.node.scale=part.scale*(1.0-smoothstep(.18,1.0,fraction))
	if is_instance_valid(flash): flash.light_energy=flash_energy*pow(1.0-fraction,3.0)

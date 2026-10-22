extends RefCounted
class_name ShotFx

# The look of each weapon archetype's shots: a camera-facing tracer that follows
# the projectile, a muzzle flash, puffs left behind in flight, and the impact.
# Purely visual; the tracer is a child of the shot node and is freed with it.
# Turret and themed weapons map onto these archetypes by their kind.
const STYLE={
	"gun":{"color":Color("ffe39a"),"length":1.8,"width":.09,"impact":"spark"},
	"shotgun":{"color":Color("ffad55"),"length":1.1,"width":.08,"impact":"spark"},
	"rail":{"color":Color("8ff1ff"),"length":6.5,"width":.16,"impact":"pierce"},
	"harpoon":{"color":Color("d9b78c"),"length":3.4,"width":.06,"impact":"spark"},
	"flame":{"color":Color("ff7424"),"length":1.6,"width":.42,"impact":"fire","puff":"ember"},
	"poison":{"color":Color("88e04a"),"length":1.4,"width":.32,"impact":"toxic","puff":"drip"},
	"ice":{"color":Color("bdf3ff"),"length":2.0,"width":.18,"impact":"ice","puff":"frost"},
	"lightning":{"color":Color("79c6ff"),"length":2.2,"width":.16,"impact":"shock"},
	"rocket":{"color":Color("ffb055"),"length":1.4,"width":.26,"impact":"none","puff":"smoke"},
	"ghost":{"color":Color("c49bff"),"length":2.2,"width":.32,"impact":"ghost","puff":"wisp"},
	"bubble":{"color":Color("bfe9f3"),"length":0.0,"width":0.0,"impact":"pop"},
	"boomerang":{"color":Color("fff0d2"),"length":1.2,"width":.22,"impact":"slash"},
	"disc":{"color":Color("fff0d2"),"length":1.2,"width":.22,"impact":"slash"},
	"bomb":{"color":Color("ffcf6a"),"length":0.0,"width":0.0,"impact":"none","puff":"fuse"},
}
const PUFF_EVERY={"ember":.045,"drip":.07,"frost":.08,"smoke":.035,"wisp":.06,"fuse":.07}
static var tracer_quad: QuadMesh
static var tracer_paints={}

static func style(kind: String) -> Dictionary:
	if STYLE.has(kind): return STYLE[kind]
	for key in ["fire","poison","ice","lightning","rocket"]:
		if kind.contains(key): return STYLE["flame" if key=="fire" else key]
	return STYLE.gun

static func tracer_paint(color: Color) -> ShaderMaterial:
	var key=color.to_html()
	if not tracer_paints.has(key):
		var paint=ShaderMaterial.new();paint.shader=preload("res://shaders/ink_tracer.gdshader");paint.set_shader_parameter("pigment",color);tracer_paints[key]=paint
	return tracer_paints[key]

# Called once when a projectile (or a remote co-op shot) is created.
static func launch(shot: Dictionary,kind: String,critical: bool=false):
	var look=style(kind)
	shot.fx_kind=kind;shot.fx_start=shot.node.position;shot.puff_clock=0.0
	if look.width<=0: return
	if tracer_quad==null: tracer_quad=QuadMesh.new()
	var trail=MeshInstance3D.new();trail.mesh=tracer_quad;trail.top_level=true
	trail.material_override=tracer_paint(Color("ffd35a") if critical else look.color)
	trail.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;trail.visible=false
	shot.node.add_child(trail);shot.trail=trail;shot.trail_width=look.width*(1.5 if critical else 1.0)

# Called every frame after the shot moved.
static func follow(g: Node3D,shot: Dictionary,velocity: Vector3,delta: float):
	var look=style(str(shot.get("fx_kind","gun")))
	var head: Vector3=shot.node.position
	var trail=shot.get("trail")
	if is_instance_valid(trail) and velocity.length_squared()>.01:
		var direction=velocity.normalized()
		var length=minf(look.length,head.distance_to(shot.fx_start))
		trail.visible=length>.08
		if trail.visible:
			var side=direction.cross(Vector3.UP)
			if side.length_squared()<.001: side=Vector3.RIGHT
			side=side.normalized()
			trail.global_transform=Transform3D(Basis(side*shot.trail_width,direction*length,side.cross(direction).normalized()*shot.trail_width),head-direction*length*.5)
	if not look.has("puff"): return
	shot.puff_clock=float(shot.get("puff_clock",0))-delta
	if shot.puff_clock>0: return
	shot.puff_clock=PUFF_EVERY[look.puff]
	puff(g,look.puff,head,velocity)

static func puff(g: Node3D,kind: String,point: Vector3,velocity: Vector3):
	var drift=-velocity.normalized()*.6
	match kind:
		"ember":
			var root=CombatInk.star(g,point,.55,Color("ff8a2a"),5.0,.28,1.0,"trail")
			if root!=null: root.shards(Color("ffb347"),2,1.4);root.fall=-2.0
		"drip":
			var root=CombatInk.star(g,point,.42,Color("7fd844"),8.0,.36,1.0,"trail")
			if root!=null: root.shards(Color("a6ec5c"),2,.8);root.fall=6.0
		"frost":
			var root=CombatInk.star(g,point,.38,Color("d7f8ff"),4.0,.3,1.0,"trail")
			if root!=null: root.fall=0.0
		"smoke":
			var root=CombatInk.star(g,point+drift,.7,Color("8f8a86"),9.0,.5,1.0,"trail")
			if root!=null: root.fall=-1.0
		"wisp":
			var root=CombatInk.star(g,point,.6,Color("a77cff"),3.0,.4,1.8,"trail")
			if root!=null: root.fall=-1.5
		"fuse":
			var root=CombatInk.star(g,point+Vector3.UP*.55,.4,Color("ffd25a"),6.0,.16,1.0,"trail")
			if root!=null: root.shards(Color("ffe08a"),2,1.8)

static func muzzle(g: Node3D,origin: Vector3,aim: Vector3,kind: String):
	var look=style(kind)
	if look.impact=="pop" or kind.contains("bomb"): return
	var size=1.6 if kind in ["rail","rocket"] or kind.contains("rocket") else 1.1 if look.width>.25 else .85
	var root=CombatInk.star(g,origin+aim*.25,size,look.color,5.0 if look.width>.25 else 4.0,.12)
	if root!=null:
		root.shards(look.color,3,3.0)
		for part in root.parts: part.velocity=(aim*2.5+part.velocity*.4)

static func impact(g: Node3D,point: Vector3,kind: String,critical: bool,direction: Vector3=Vector3.ZERO):
	var look=style(kind)
	var scale=1.45 if critical else 1.0
	match look.impact:
		"spark":
			var root=CombatInk.star(g,point,1.3*scale,look.color,6.0,.22)
			if root!=null: root.shards(look.color.lightened(.3),5,3.6)
		"pierce":
			var root=CombatInk.star(g,point,1.6*scale,look.color,4.0,.24,2.2)
			if root!=null: root.shards(Color("e8fdff"),6,5.0)
			if direction!=Vector3.ZERO: CombatInk.beam(g,point,point+direction.normalized()*2.2,look.color,false,1.6)
		"fire":
			var root=CombatInk.star(g,point,1.4*scale,Color("ff6a1c"),7.0,.3)
			if root!=null: root.shards(Color("ffb347"),6,3.2);root.fall=-3.0
		"toxic":
			var root=CombatInk.star(g,point,1.3*scale,Color("7fd844"),9.0,.32)
			if root!=null: root.shards(Color("b6f06a"),6,2.8);root.fall=7.0
			splat(g,point,Color("6fbe36"),1.5)
		"ice":
			var root=CombatInk.star(g,point,1.3*scale,Color("c8f6ff"),4.0,.3)
			if root!=null: root.shards(Color("eafcff"),7,3.0)
			CombatInk.wave(g,point+Vector3.DOWN*.5,1.1,Color("9fe8ff"))
		"shock":
			var root=CombatInk.star(g,point,1.2*scale,look.color,8.0,.2)
			if root!=null: root.shards(Color("d8f0ff"),4,4.0)
			for i in range(3):
				var angle=i*TAU/3.0+point.x
				CombatInk.beam(g,point,point+Vector3(cos(angle),.35,sin(angle))*1.1,look.color,true,.6)
		"ghost":
			CombatInk.star(g,point,1.5*scale,look.color,3.0,.34,1.6)
			CombatInk.wave(g,point+Vector3.DOWN*.5,1.3,look.color)
		"pop":
			var root=CombatInk.star(g,point,1.2*scale,look.color,12.0,.22)
			if root!=null: root.shards(Color("eafcff"),5,2.5)
		"slash":
			var root=CombatInk.star(g,point,1.7*scale,look.color,2.0,.18,3.0)
			if root!=null: root.shards(look.color,4,4.0)
	if critical and look.impact!="none": CombatInk.star(g,point,2.2,Color("ffd35a"),10.0,.26)

# A paint splat on the ground, fading with the effects list.
static func splat(g: Node3D,point: Vector3,color: Color,size: float):
	if g.effects.size()>200: return
	var mesh=PlaneMesh.new();mesh.size=Vector2.ONE*size
	var paint=ShaderMaterial.new();paint.shader=preload("res://shaders/melee_marks.gdshader");paint.set_shader_parameter("color",color);paint.set_shader_parameter("splatter",true)
	var stain=MeshInstance3D.new();stain.mesh=mesh;stain.material_override=paint;stain.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;g.add_child(stain)
	stain.position=point;stain.position.y=g.world.height_at(point.x,point.z)+.04;stain.rotation.y=fmod(absf(point.x*3.7+point.z*1.3),TAU)
	g.effects.append({"node":stain,"life":1.4,"lifetime":1.4,"velocity":Vector3.ZERO,"stationary":true,"mark_paint":paint})

extends Node3D
class_name WeaponModel

var id="gun"
var rank=1
var tank: MeshInstance3D
var kick=0.0
var muzzle=Node3D.new()
var flash: MeshInstance3D
var barrel: MeshInstance3D
var base=Node3D.new()
var saw_parts=[]

func block(parent: Node3D,color: Color,pos: Vector3,dimensions: Vector3):
	var mesh=BoxMesh.new();mesh.size=dimensions
	return ToonArt.part(parent,mesh,color,pos)

func setup(weapon_id: String):
	id=weapon_id
	add_child(base)
	var asset="mint_pistol" if id=="gun" else "weapon_"+id
	if ResourceLoader.exists("res://assets/style3d/"+asset+".glb"):
		var solid=StyleModel.new();solid.setup(asset);base.add_child(solid)
		if id=="saw":
			for node in solid.model.find_children("*","MeshInstance3D",true,false):
				if str(node.name).begins_with("Disc") or str(node.name).begins_with("Tooth"): saw_parts.append({"node":node,"rest":node.transform})
		muzzle.free()
		muzzle=solid.muzzle()
		if muzzle==null:
			muzzle=Node3D.new();base.add_child(muzzle);muzzle.position=Vector3(0,.08,-.59)
		flash=ToonArt.ball(muzzle,PowerIcon.color_for(id).lightened(.2),Vector3.ZERO,Vector3(.16,.16,.26));flash.visible=false
		return
	var sprite_path="res://assets/illustrated/weapons/"+("turret" if id.contains("turret") else id)+".png"
	if ResourceLoader.exists(sprite_path):
		var painted=Sprite3D.new();painted.texture=load(sprite_path);painted.pixel_size=.90/128;painted.position=Vector3(0,.08,-.15);painted.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		painted.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD;painted.alpha_scissor_threshold=.15;painted.shaded=false;painted.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;base.add_child(painted)
		base.add_child(muzzle);muzzle.position=Vector3(0,.08,-.59)
		flash=ToonArt.ball(muzzle,PowerIcon.color_for(id).lightened(.2),Vector3.ZERO,Vector3(.16,.16,.26));flash.visible=false
		return
	var color=PowerIcon.color_for(id)
	var steel=Color("585b64")
	var brass=Color("dda85f")
	var wood=Color("bd8465")
	if id=="flowers":
		ToonArt.tube(base,wood,Vector3(0,0,0),.19,.12,.28)
		ToonArt.tube(base,brass,Vector3(0,.17,0),.2,.2,.05)
		for i in range(6): ToonArt.ball(base,Color("efa0b8"),Vector3(cos(i*TAU/6)*.14,.29,sin(i*TAU/6)*.14),Vector3(.18,.15,.18))
		ToonArt.ball(base,brass,Vector3(0,.31,0),Vector3(.13,.15,.13))
	elif id=="saw":
		block(base,wood,Vector3(0,-.02,.08),Vector3(.14,.18,.3))
		barrel=ToonArt.tube(base,steel,Vector3(0,.1,-.24),.28,.28,.045)
		barrel.rotation.x=PI*.5
		for i in range(12):
			var tooth=block(barrel,brass,Vector3(cos(i*TAU/12)*.28,0,sin(i*TAU/12)*.28),Vector3(.09,.08,.1))
			tooth.rotation.y=-i*TAU/12
	elif id.contains("turret"):
		block(base,steel,Vector3.ZERO,Vector3(.35,.28,.34))
		for x in [-.2,.2]: block(base,brass,Vector3(x,-.16,.05),Vector3(.06,.32,.08)).rotation.z=x
		ToonArt.ball(base,color,Vector3(0,.17,-.04),Vector3(.32,.30,.32))
		var tube=ToonArt.tube(base,steel,Vector3(0,.17,-.27),.065,.075,.4);tube.rotation.x=PI*.5
	else:
		block(base,color,Vector3(0,.06,-.07),Vector3(.25,.20,.42))
		block(base,wood,Vector3(0,-.12,.06),Vector3(.15,.25,.14)).rotation.x=-.25
		var count=3 if id=="shotgun" else 1
		for i in range(count):
			var tube=ToonArt.tube(base,steel,Vector3((i-(count-1)*.5)*.08,.06,-.38),.045,.055,.4 if id!="rail" else .72)
			tube.rotation.x=PI*.5
			var rim=ToonArt.tube(base,brass,Vector3((i-(count-1)*.5)*.08,.06,-.54),.06,.06,.055);rim.rotation.x=PI*.5
		for z in [-.15,-.02,.11]: block(base,brass,Vector3(.13,.07,z),Vector3(.018,.12,.025))
		if id in ["flame","poison","ice","lightning","ghost"]:
			tank=ToonArt.tube(base,brass,Vector3(0,.25,0),.095,.095,.25)
			ToonArt.ball(base,color,Vector3(0,.42,0),Vector3(.17,.19,.17))
		if id=="rail": block(base,steel,Vector3(0,.25,-.09),Vector3(.10,.10,.32))
		if id=="rocket":
			var rocket=ToonArt.tube(base,Color("ec977c"),Vector3(0,.07,-.65),0,.12,.24);rocket.rotation.x=PI*.5
	base.add_child(muzzle);muzzle.position=Vector3(0,.08,-.59)
	flash=ToonArt.ball(muzzle,PowerIcon.color_for(id).lightened(.2),Vector3.ZERO,Vector3(.16,.16,.26))
	flash.visible=false

func shoot():
	kick=1.0

func tick(delta: float):
	kick=maxf(0,kick-delta*9)
	base.position.z=kick*(.2 if id in ["shotgun","rocket"] else .1)
	base.rotation.x=kick*.14
	flash.visible=kick>.55 and id not in ["saw","flowers"]
	if flash.visible: flash.scale=Vector3(.14,.14,.32 if id=="rail" else .20)*(1+kick)*(1+minf(.5,rank*.05))
	if tank!=null: tank.scale.y=1+sin(kick*PI)*.18
	if id=="saw" and barrel!=null: barrel.rotation.z+=delta*16
	if id=="saw":
		for part in saw_parts:
			var center=Vector3(0,.07,-.27);var spin=Basis(Vector3.FORWARD,Time.get_ticks_msec()*.018)
			part.node.transform=Transform3D(spin*part.rest.basis,center+spin*(part.rest.origin-center))

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
var rank_parts=Node3D.new()
var shown_rank=0
var variant_base: Node3D
var recoil=0.05
# Evolved weapons wear a slowly turning gold halo with three orbiting sparks.
var evolved=false
var halo: Node3D

func block(parent: Node3D,color: Color,pos: Vector3,dimensions: Vector3):
	var mesh=BoxMesh.new();mesh.size=dimensions
	return ToonArt.part(parent,mesh,color,pos)

func setup(weapon_id: String):
	id=weapon_id
	add_child(base)
	base.add_child(rank_parts)
	if SkillBook.build_model(self): return
	var definition=ContentExpansion.weapon(id)
	if definition.has("archetype") and not ResourceLoader.exists("res://assets/style3d/weapon_"+id+".glb"):
		var original=WeaponModel.new();variant_base=original;original.setup(str(definition.archetype));base.add_child(original)
		muzzle.free();muzzle=original.muzzle
		# Each variant wears bright rounded add-ons in its own colour (cartoon style,
		# October 25), so it reads apart from its base weapon in the hand and the icon.
		var recipe=definition.art;var variant=int(recipe.condition)-18
		var palette=[Color("ff3b6b"),Color("ffd23f"),Color("3bd6ff"),Color("8fff5a"),Color("c97aff"),Color("ff8a2b"),Color("ff6bd5"),Color("2fe0c8"),Color("6b7bff"),Color("ffef5a")]
		var own: Color=palette[absi(hash(id))%palette.size()];var accent=palette[(absi(hash(id))/palette.size())%palette.size()]
		if variant==0:
			for i in range(2+int(recipe.shape)%3):
				var fin=CylinderMesh.new();fin.top_radius=0;fin.bottom_radius=.05;fin.height=.2;fin.radial_segments=8
				var part=ToonArt.part(base,fin,accent,Vector3(.15+i*.04,.2+i*.05,-.1-i*.08));part.rotation=Vector3(-.6,0,-.5)
			ToonArt.ball(base,own,Vector3(0,.34,-.1),Vector3(.2,.2,.2))
		else:
			for side in [-1,1]: ToonArt.ball(base,accent,Vector3(side*.17,.1,-.22),Vector3(.12,.16,.22))
			var hoop=TorusMesh.new();hoop.inner_radius=.13;hoop.outer_radius=.18
			var ring=ToonArt.part(base,hoop,own,Vector3(0,.08,-.47));ring.rotation.x=PI*.5
		flash=ToonArt.ball(muzzle,Color("ffe6a4"),Vector3.ZERO,Vector3(.16,.16,.26));flash.visible=false
		return
	var asset="mint_pistol" if id=="gun" else "weapon_"+id
	if ResourceLoader.exists("res://assets/style3d/"+asset+".glb"):
		var solid=StyleModel.new();solid.setup(asset);base.add_child(solid)
		# The cartoon gadgets (CartoonWeapons) carry their own details.
		if not CartoonWeapons.has(asset): preload("res://scripts/weapon_identity.gd").apply(id,solid)
		if id=="saw":
			for node in solid.model.find_children("*","MeshInstance3D",true,false):
				if str(node.name).begins_with("Disc") or str(node.name).begins_with("Tooth"): saw_parts.append({"node":node,"rest":node.transform})
		muzzle.free()
		muzzle=solid.muzzle()
		if muzzle==null:
			muzzle=Node3D.new();base.add_child(muzzle);muzzle.position=Vector3(0,.08,-.59)
		flash=ToonArt.ball(muzzle,PowerIcon.color_for(id).lightened(.2),Vector3.ZERO,Vector3(.16,.16,.26));flash.visible=false
		return
	push_error("Missing required weapon model: "+id)
	base.add_child(muzzle)

func shoot():
	kick=1.0

func transform_rank():
	if shown_rank==rank: return
	shown_rank=rank
	if rank_parts.get_parent()==null: base.add_child(rank_parts)
	for child in rank_parts.get_children(): child.queue_free()
	var stage=mini(3,int(rank/3))
	for i in range(stage):
		var plate=block(rank_parts,PowerIcon.color_for(id).lightened(.15*i),Vector3(.15,.12+i*.07,-.12),Vector3(.08,.05,.3))
		var material=plate.material_override.duplicate();material.albedo_texture=load("res://assets/illustrated/stone.png");plate.material_override=material
	if stage>1:
		var ring=ToonArt.tube(rank_parts,Color("edbf56"),Vector3(0,.14,-.35),.10,.10,.06);ring.rotation.x=PI*.5
	if stage>2: ToonArt.ball(rank_parts,PowerIcon.color_for(id),Vector3(0,.34,0),Vector3(.18,.18,.18))

func build_halo():
	halo=Node3D.new();halo.name="EvolvedHalo";base.add_child(halo);halo.position=Vector3(0,.14,-.25)
	var paint=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;paint.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
	paint.albedo_color=Color(1,.86,.45,1.0);paint.cull_mode=BaseMaterial3D.CULL_DISABLED
	var hoop=TorusMesh.new();hoop.inner_radius=.40;hoop.outer_radius=.47;hoop.rings=24;hoop.ring_segments=6
	var ring=MeshInstance3D.new();ring.mesh=hoop;ring.material_override=paint;ring.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;ring.rotation.x=PI*.5;halo.add_child(ring)
	var gem=SphereMesh.new();gem.radius=.08;gem.height=.16;gem.radial_segments=8;gem.rings=4
	for i in range(3):
		var spark=MeshInstance3D.new();spark.mesh=gem;spark.material_override=paint;spark.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		spark.position=Vector3(cos(i*TAU/3),sin(i*TAU/3),0)*.44;halo.add_child(spark)

func tick(delta: float):
	if variant_base!=null: variant_base.tick(delta)
	transform_rank()
	if evolved and halo==null: build_halo()
	if halo!=null:
		halo.visible=evolved;halo.rotation.z+=delta*1.6
		halo.scale=Vector3.ONE*(1.0+sin(Time.get_ticks_msec()*.005)*.06)
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

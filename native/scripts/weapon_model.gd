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

func block(parent: Node3D,color: Color,pos: Vector3,dimensions: Vector3):
	var mesh=BoxMesh.new();mesh.size=dimensions
	return ToonArt.part(parent,mesh,color,pos)

func setup(weapon_id: String):
	id=weapon_id
	add_child(base)
	base.add_child(rank_parts)
	var definition=ContentExpansion.weapon(id)
	if definition.has("archetype") and not ResourceLoader.exists("res://assets/style3d/weapon_"+id+".glb"):
		var original=WeaponModel.new();variant_base=original;original.setup(str(definition.archetype));base.add_child(original)
		muzzle.free();muzzle=original.muzzle
		var paint=load("res://assets/illustrated/content/textures/"+id+".svg")
		var recipe=definition.art;var variant=int(recipe.condition)-18
		var parts=[]
		if variant==0:
			for i in range(2+int(recipe.shape)%3):
				var fin=block(base,Color("e1b867"),Vector3(.19,.16+i*.06,-.12-i*.04),Vector3(.11,.04,.24));fin.rotation.z=.2;parts.append(fin)
			parts.append(ToonArt.ball(base,PowerIcon.color_for(str(definition.archetype)),Vector3(0,.34,-.1),Vector3(.24,.2,.24)))
		else:
			for side in [-1,1]:
				var guard=block(base,Color("8db2bb"),Vector3(side*.19,.08,-.25),Vector3(.07,.3,.27));guard.rotation.z=side*.3;parts.append(guard)
			var hoop=TorusMesh.new();hoop.inner_radius=.14;hoop.outer_radius=.18
			var ring=ToonArt.part(base,hoop,Color("efd19a"),Vector3(0,.08,-.47));ring.rotation.x=PI*.5;parts.append(ring)
		for part in parts:
			var material=part.material_override.duplicate();material.albedo_texture=paint;part.material_override=material
		flash=ToonArt.ball(muzzle,Color("ffe6a4"),Vector3.ZERO,Vector3(.16,.16,.26));flash.visible=false
		return
	var asset="mint_pistol" if id=="gun" else "weapon_"+id
	if ResourceLoader.exists("res://assets/style3d/"+asset+".glb"):
		var solid=StyleModel.new();solid.setup(asset);base.add_child(solid)
		preload("res://scripts/weapon_identity.gd").apply(id,solid)
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

func tick(delta: float):
	if variant_base!=null: variant_base.tick(delta)
	transform_rank()
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

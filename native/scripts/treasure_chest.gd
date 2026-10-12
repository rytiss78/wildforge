extends Node3D

static func create(elite: bool=false) -> Node3D:
	var chest=Node3D.new();var wood=Color("263a42");var metal=Color("f2c56b") if elite else Color("ad8550")
	part(chest,Vector3(1.66,.86,1.05),Vector3(0,.43,0),wood)
	for i in range(4):
		part(chest,Vector3(.37,.78,.035),Vector3(-.6+i*.4,.45,-.54),wood.lightened(.04+i*.025))
	for x in [-.6,.6]: part(chest,Vector3(.13,.9,1.12),Vector3(x,.45,0),metal)
	part(chest,Vector3(1.76,.10,1.13),Vector3(0,.08,0),Color("101a29"))
	for side in [-1,1]:
		var inlay=part(chest,Vector3(.04,.52,.045),Vector3(side*.30,.46,-.58),metal);inlay.rotation.z=side*.55
	var seal=part(chest,Vector3(.20,.20,.06),Vector3(0,.43,-.60),Color("69e8b4") if elite else Color("ad354f"));seal.rotation.z=PI*.25
	var lid=Node3D.new();lid.position=Vector3(0,.88,.52);chest.add_child(lid);chest.set_meta("lid",lid)
	part(lid,Vector3(1.76,.30,1.12),Vector3(0,.15,-.52),wood.lightened(.16))
	for x in [-.6,.6]: part(lid,Vector3(.14,.32,1.16),Vector3(x,.15,-.52),metal)
	part(lid,Vector3(.25,.34,.09),Vector3(0,-.04,-1.11),metal)
	part(lid,Vector3(.07,.14,.03),Vector3(0,-.05,-1.17),Color("342a28"))
	for x in [-.75,.75]:
		for y in [.22,.70]:
			var stud=SphereMesh.new();stud.radius=.045;stud.height=.09;stud.radial_segments=8;stud.rings=4
			ToonArt.part(chest,stud,metal,Vector3(x,y,-.57))
	return chest

static func part(parent: Node3D,size_value: Vector3,position_value: Vector3,color: Color):
	var mesh=BoxMesh.new();mesh.size=size_value
	return ToonArt.part(parent,mesh,color,position_value)

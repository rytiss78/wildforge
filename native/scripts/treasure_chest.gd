extends Node3D

# Bright so they read from afar (user request, October 25): warm orange wood,
# glowing gold bands and a small warm light. They used to be dark teal.
static var glow_metal={}

static func create(elite: bool=false) -> Node3D:
	var chest=Node3D.new();var wood=Color("c86a2a");var metal=Color("ffe07a") if elite else Color("ffc23d")
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
	# The gold glows: an emissive copy of the metal paint.
	var key=metal.to_html()
	if not glow_metal.has(key):
		var paint: StandardMaterial3D=ToonArt.paint(metal).duplicate();paint.emission_enabled=true;paint.emission=metal;paint.emission_energy_multiplier=1.6
		glow_metal[key]=paint
	for node in chest.find_children("*","MeshInstance3D",true,false):
		if node.get_meta("paint_color",Color.BLACK)==metal: node.material_override=glow_metal[key]
	var light=OmniLight3D.new();light.light_color=Color("ffc861");light.light_energy=1.8;light.omni_range=5.5;light.position=Vector3(0,1.6,-.4);light.shadow_enabled=false;chest.add_child(light)
	return chest

static func part(parent: Node3D,size_value: Vector3,position_value: Vector3,color: Color):
	var mesh=BoxMesh.new();mesh.size=size_value
	return ToonArt.part(parent,mesh,color,position_value)

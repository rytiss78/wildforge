extends RefCounted
# These details are part of the held model and therefore also its rendered icon.
static func apply(id: String,solid: StyleModel):
	if id.ends_with("-turret"): id=id.trim_suffix("-turret")
	if id=="fire": id="flame"
	var colors={"gun":"79aaa4","shotgun":"ae744b","flame":"c36a3d","poison":"729849","ice":"4b99d5","rail":"596e92","lightning":"6959a3","rocket":"a65c43","ghost":"7b9b93"}
	if not colors.has(id): return
	var paint=Color(colors[id]);var root=solid.model
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		var name=str(mesh.name)
		if name.begins_with("Tank") and id in ["ice","flame","poison","lightning","ghost"]: mesh.visible=false
		if name.begins_with("ShapedReceiver") or name in ["FoldedTurretBody","TurretSensor"]:
			var material=ToonArt.paint(paint).duplicate();material.roughness=.45;material.metallic_specular=.35;mesh.material_override=material
	var steel=Color("465363");var gold=Color("dab377")
	if id=="ice":
		# Faceted frozen muzzle, recognizable from the previous illustrated ice gun.
		for i in range(3):
			var crystal=CylinderMesh.new();crystal.top_radius=0;crystal.bottom_radius=.12 if i==0 else .065;crystal.height=.38 if i==0 else .25;crystal.radial_segments=5
			var node=ToonArt.part(root,crystal,Color("9fe9ff") if i==0 else Color("d0f7ff"),Vector3((i-1)*.12,.1,-.62));node.rotation.x=-PI/2;node.rotation.z=(i-1)*.25
		ToonArt.tube(root,paint,Vector3(0,.24,-.02),.1,.12,.22)
	elif id=="flame":
		for side in [-1,1]:
			ToonArt.tube(root,Color("b74735"),Vector3(side*.14,.21,.02),.085,.085,.27)
			ToonArt.tube(root,gold,Vector3(side*.14,.36,.02),.06,.06,.035)
		var nozzle=ToonArt.tube(root,steel,Vector3(0,.08,-.59),.14,.1,.22);nozzle.rotation.x=PI/2
		var pilot=ToonArt.tube(root,Color("ffb755"),Vector3(0,.08,-.74),0,.07,.15);pilot.rotation.x=-PI/2
	elif id=="poison":
		ToonArt.tube(root,Color("b3e774"),Vector3(0,.3,-.02),.11,.13,.32)
		for y in [.15,.47]: ToonArt.tube(root,gold,Vector3(0,y,-.02),.13,.13,.045)
		for y in [.25,.34]: ToonArt.ball(root,Color("edf4b7"),Vector3(.08,y,-.09),Vector3(.07,.07,.07))
	elif id=="lightning":
		for side in [-1,1]:
			ToonArt.tube(root,gold,Vector3(side*.13,.27,-.05),.035,.035,.3)
			ToonArt.ball(root,Color("a4eaff"),Vector3(side*.13,.45,-.05),Vector3(.12,.12,.12))
		for z in [-.3,-.4,-.5]:
			var hoop=TorusMesh.new();hoop.inner_radius=.08;hoop.outer_radius=.105
			var ring=ToonArt.part(root,hoop,Color("b5d5f2"),Vector3(0,.08,z));ring.rotation.x=PI/2
	elif id=="rail":
		for side in [-1,1]:
			var rail=BoxMesh.new();rail.size=Vector3(.045,.055,.67);ToonArt.part(root,rail,Color("a5dcea"),Vector3(side*.095,.12,-.43))
		var scope=ToonArt.tube(root,steel,Vector3(0,.28,-.07),.065,.065,.3);scope.rotation.x=PI/2
	elif id=="ghost":
		ToonArt.ball(root,Color("b9f1d9"),Vector3(0,.3,-.02),Vector3(.27,.3,.27))
		for side in [-1,1]:
			var strut=BoxMesh.new();strut.size=Vector3(.035,.36,.035);ToonArt.part(root,strut,gold,Vector3(side*.14,.3,-.02))
	elif id=="rocket":
		for side in [-1,1]:
			var fin=BoxMesh.new();fin.size=Vector3(.2,.035,.16);ToonArt.part(root,fin,Color("e1b464"),Vector3(side*.15,.08,-.56))

extends ActorRig
# Uses the normal enemy combat contract, including health orbs and hit feedback.
var core: MeshInstance3D
var orb: MeshInstance3D
var paint: StandardMaterial3D
func setup(model_name: String):
	identity=model_name
	add_child(body);body.add_child(head)
	for side in [-1,1]:
		var foot=block(body,Color("283444"),Vector3(side*.65,.22,0),Vector3(.5,.4,1.6))
		foot.rotation.z=side*.18
	ToonArt.tube(body,Color("566782"),Vector3(0,.55,0),.65,.9,.55)
	core=block(body,Color("8c3655"),Vector3(0,1.15,0),Vector3(1.25,.85,.85))
	for side in [-1,1]:
		block(body,Color("152332"),Vector3(side*.38,1.2,-.8),Vector3(.22,.24,1.1))
		var muzzle=block(body,Color("ff724c"),Vector3(side*.38,1.2,-1.36),Vector3(.26,.26,.1))
		muzzle.material_override=ToonArt.paint(Color("ff724c")).duplicate()
		muzzle.material_override.emission_enabled=true;muzzle.material_override.emission=Color("ff724c")
	ToonArt.tube(body,Color("d2a969"),Vector3(0,2.15,0),.31,.31,.10)
	orb=ToonArt.ball(body,Color("f13764"),Vector3(0,2.15,0),Vector3(.48,.48,.48))
	paint=ToonArt.paint(Color("f13764")).duplicate();orb.material_override=paint
	paint.emission_enabled=true;paint.emission=Color("f13764");paint.emission_energy_multiplier=1.4
func set_health(fraction: float,_tank: bool=false):
	if is_instance_valid(orb): orb.scale=Vector3.ONE*maxf(.04,pow(clampf(fraction,0,1),1.0/3.0));orb.visible=fraction>0
func animate(delta: float,_movement: Vector3,_on_floor: bool=true,_slamming: bool=false):
	hurt=maxf(0,hurt-delta);attack=maxf(0,attack-delta)
	if is_instance_valid(core): core.scale=Vector3.ONE*(1+hurt*.3)
func statuses(_fire: bool,_poison: bool,_frozen: bool,_blind: bool): pass
func bake_enemy(): pass

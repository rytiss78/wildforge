extends RefCounted

static func attach(rig: Node3D):
	# Sixty-four particles total, venting well above ground-level attack marks.
	var puff=SphereMesh.new();puff.radius=.12;puff.height=.48;puff.radial_segments=8;puff.rings=4
	var paint=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;paint.albedo_color=Color(.76,.86,.90,.25);puff.material=paint
	# Place vents on the robe's front surface; negative local Z faces the arena after the model's half-turn.
	for point in [Vector3(-1.05,2.1,-.58),Vector3(1.05,2.1,-.58),Vector3(-.7,1.4,-.78),Vector3(.7,1.4,-.78)]:
		var steam=GPUParticles3D.new();steam.name="BaronSteam_"+str(rig.get_child_count());steam.amount=16;steam.lifetime=3.0;steam.emitting=true
		steam.position=point;steam.local_coords=true;steam.visibility_aabb=AABB(Vector3(-1,-.3,-1),Vector3(2,2,2))
		steam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;steam.draw_pass_1=puff
		var process=ParticleProcessMaterial.new();process.direction=Vector3(point.x*.35,1,.2);process.spread=28
		process.gravity=Vector3(0,.03,0);process.initial_velocity_min=.10;process.initial_velocity_max=.24
		process.scale_min=.35;process.scale_max=.7
		var gradient=Gradient.new();gradient.set_color(0,Color(1,1,1,0));gradient.set_color(1,Color(1,1,1,0));gradient.add_point(.2,Color.WHITE)
		var ramp=GradientTexture1D.new();ramp.gradient=gradient;process.color_ramp=ramp
		steam.process_material=process;rig.add_child(steam)

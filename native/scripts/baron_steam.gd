extends RefCounted

static func attach(rig: Node3D):
	# Sixty-four particles total, venting well above ground-level attack marks.
	var puff=SphereMesh.new();puff.radius=.1;puff.height=.2;puff.radial_segments=10;puff.rings=5
	var paint=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	# Particle colour carries the fade-in/out ramp, so puffs soften instead of popping as beads.
	paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;paint.albedo_color=Color(.86,.93,.97,.3);paint.vertex_color_use_as_albedo=true;puff.material=paint
	# Steam rises off the chest and the hanging belly; negative local Z faces the arena after the model's half-turn.
	for point in [Vector3(-.50,2.10,-.58),Vector3(.50,2.10,-.58),Vector3(-.62,1.30,-1.02),Vector3(.62,1.30,-1.02)]:
		var steam=GPUParticles3D.new();steam.name="BaronSteam_"+str(rig.get_child_count());steam.amount=16;steam.lifetime=3.0;steam.emitting=true
		steam.position=point;steam.local_coords=true;steam.visibility_aabb=AABB(Vector3(-1,-.3,-1),Vector3(2,2,2))
		steam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;steam.draw_pass_1=puff
		var process=ParticleProcessMaterial.new();process.direction=Vector3(point.x*.35,1,.2);process.spread=28
		process.gravity=Vector3(0,.03,0);process.initial_velocity_min=.24;process.initial_velocity_max=.52
		process.scale_min=.62;process.scale_max=1.0
		var growth=Curve.new();growth.add_point(Vector2(0,.6));growth.add_point(Vector2(1,2.4))
		var swell=CurveTexture.new();swell.curve=growth;process.scale_curve=swell
		var gradient=Gradient.new();gradient.set_color(0,Color(1,1,1,0));gradient.set_color(1,Color(1,1,1,0));gradient.add_point(.2,Color.WHITE)
		var ramp=GradientTexture1D.new();ramp.gradient=gradient;process.color_ramp=ramp
		steam.process_material=process;rig.add_child(steam)

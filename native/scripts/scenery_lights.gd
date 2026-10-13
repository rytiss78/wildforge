extends RefCounted

static func add_lamp(parent: Node3D,biome: int):
	var colors=[Color("34efaa"),Color("91e24b"),Color("70baff"),Color("ffe0a0"),Color("ff5428"),Color("bc74ff")]
	var lamp=OmniLight3D.new();lamp.name="SceneryLantern";lamp.position=Vector3(0,2.8,0)
	lamp.light_color=colors[biome];lamp.light_energy=1.7;lamp.omni_range=10
	lamp.shadow_enabled=true;lamp.distance_fade_enabled=true;lamp.distance_fade_begin=27;lamp.distance_fade_length=12
	parent.add_child(lamp)
	var material=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color=colors[biome];material.emission_enabled=true;material.emission=colors[biome];material.emission_energy_multiplier=2
	var crystal=MeshInstance3D.new();var mesh=PrismMesh.new();mesh.size=Vector3(.38,.9,.38)
	crystal.name="SpectralFlameLantern";crystal.mesh=mesh;crystal.material_override=material;crystal.position=lamp.position;parent.add_child(crystal)

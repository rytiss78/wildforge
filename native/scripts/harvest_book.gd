extends RefCounted
class_name HarvestBook

# IDs match RealmWorld.BIOMES, including the central Clover Woods clearing.
const TYPES=[
	{"name":"Cloverheart","color":"71c566","description":"A healing herb of Clover Woods.","effect":"Restore 12 HP","key":"","bonus":12.0,"duration":0},
	{"name":"Marsh Puffcap","color":"ce87de","description":"Spotted mushrooms native to Puffcap Marsh.","effect":"+2 HP/sec for 20s","key":"regen","bonus":2.0,"duration":20},
	{"name":"Moon Quartz","color":"89cbf0","description":"Shield-bearing crystals from Moon Craters.","effect":"+2 shield capacity this run","key":"shield","bonus":2.0,"duration":0},
	{"name":"Cloud Blossom","color":"d8f6ff","description":"A buoyant flower found in Cloud City.","effect":"+1 air jump for 20s","key":"airJumps","bonus":1.0,"duration":20},
	{"name":"Ember Pepper","color":"ff9355","description":"A fiery seed pod from Candy Hell.","effect":"+15% damage for 20s","key":"damage","bonus":.15,"duration":20},
	{"name":"Starfall Pearl","color":"d6b3ff","description":"A star-shaped shell holding a luminous pearl.","effect":"+25% enemy gold for 20s","key":"goldGain","bonus":.25,"duration":20}
]

static func value(game,key: String,base: float) -> float:
	var result=base
	for id in game.harvest_buffs:
		var entry=TYPES[int(id)]
		if entry.key!=key: continue
		result=result+entry.bonus if key in ["regen","airJumps"] else result*(1+entry.bonus)
	return result

static func tick(game,delta: float):
	for id in game.harvest_buffs.keys():
		game.harvest_buffs[id]-=delta
		if game.harvest_buffs[id]<=0: game.harvest_buffs.erase(id)

static func spawn(game):
	for biome in range(6):
		var placed=0
		for attempt in range(1200):
			if placed>=8: break
			var angle=game.rules.rng.randf()*TAU
			var radius=game.rules.rng.randf_range(12 if biome==0 else 76,RealmWorld.SPAWN_EXTENT-35)
			var p=Vector3(cos(angle)*radius,0,sin(angle)*radius)
			if game.world.biome_at(p)!=biome or radius>game.world.shore_radius(p)-24: continue
			if game.harvestables.any(func(h):return h.node.position.distance_to(p)<7): continue
			if game.world.landmarks.any(func(site):return Vector2(site.x-p.x,site.z-p.z).length()<16): continue
			p.y=game.world.height_at(p.x,p.z)
			var flat=true
			for offset in [Vector3(2,0,0),Vector3(-2,0,0),Vector3(0,0,2),Vector3(0,0,-2)]:
				if absf(game.world.height_at(p.x+offset.x,p.z+offset.z)-p.y)>.45: flat=false
			if not flat: continue
			var cell=Vector2i(floori(p.x/RealmWorld.CHUNK),floori(p.z/RealmWorld.CHUNK))
			if game.world.chunks.has(cell):
				var obstructed=false
				for child in game.world.chunks[cell].get_children():
					if child is Node3D and child.get_child_count()>0 and Vector2(child.global_position.x-p.x,child.global_position.z-p.z).length()<4: obstructed=true
				if obstructed: continue
			game.world.harvest_sites.append(p)
			var node=make_model(biome);game.add_child(node);node.position=p
			var title=Label3D.new();title.text=TYPES[biome].name;title.font_size=32;title.outline_size=6
			title.position.y=1.7;title.billboard=BaseMaterial3D.BILLBOARD_ENABLED;title.visibility_range_end=18;node.add_child(title)
			game.harvestables.append({"node":node,"type":TYPES[biome],"biome":biome,"picked":false});placed+=1

static func pick(game,harvest: Dictionary):
	if harvest.is_empty() or harvest.get("picked",false) or not game.harvestables.has(harvest): return
	var entry=harvest.type;var id=int(harvest.biome);var p=harvest.node.position
	harvest.picked=true;harvest.node.queue_free();game.harvestables.erase(harvest)
	if id==0: game.heal(entry.bonus)
	elif id==2:
		game.stats.shield+=entry.bonus;game.shield_hp=minf(game.stats.shield,game.shield_hp+entry.bonus)
	else: game.harvest_buffs[id]=float(entry.duration)
	game.condition_times.harvest=game.elapsed
	game.hud.tell(entry.name+" · "+entry.effect,3)
	game.sound.ui_effect("garden" if id in [0,1,3] else "magic")
	game.burst(p+Vector3.UP*.55,Color(entry.color),14)
	# Existing pot-economy upgrades now enhance harvest coins; no dead upgrade.
	game.spawn_pickup(p+Vector3.UP*.6,"gold",roundi(3*game.stats.potGold))

static func make_model(id: int) -> Node3D:
	var root=Node3D.new();root.name="Harvest"+str(id)
	var color=Color(TYPES[id].color)
	ToonArt.ball(root,Color("65705c") if id<2 else Color("66798c"),Vector3(0,.08,0),Vector3(.95,.18,.8))
	match id:
		0:
			for i in range(7):
				var angle=i*TAU/7;var leaf=ToonArt.ball(root,color.lightened((i%2)*.12),Vector3(sin(angle)*.28,.3+float(i%3)*.1,cos(angle)*.28),Vector3(.22,.65,.1))
				leaf.rotation=Vector3(.35,angle,.3)
			for i in range(4): ToonArt.ball(root,Color("fff1b4"),Vector3(sin(i*TAU/4)*.12,.7,cos(i*TAU/4)*.12),Vector3(.21,.12,.21))
		1:
			for i in range(3):
				var p=Vector3((i-1)*.3,.0,(i%2)*.25);var height=.55+float(i%2)*.35
				ToonArt.tube(root,Color("e3dcc7"),p+Vector3.UP*height*.5,.06,.09,height)
				ToonArt.ball(root,color,p+Vector3.UP*height,Vector3(.58,.28,.58))
				for j in range(5): ToonArt.ball(root,Color("f5e6c7"),p+Vector3(sin(j*TAU/5)*.17,height+.11,cos(j*TAU/5)*.17),Vector3(.075,.04,.075))
		2:
			for i in range(5):
				var crystal=CylinderMesh.new();crystal.top_radius=0;crystal.bottom_radius=.16;crystal.height=.65+float(i%3)*.2;crystal.radial_segments=5
				var part=ToonArt.part(root,crystal,color.lightened((i%2)*.25),Vector3(sin(i*2.4)*.3,crystal.height*.5,cos(i*2.4)*.3));part.rotation.z=(i-2)*.12
		3:
			ToonArt.tube(root,Color("7caa9a"),Vector3(0,.4,0),.04,.07,.8)
			for i in range(6): ToonArt.ball(root,color,Vector3(sin(i*TAU/6)*.25,.83,cos(i*TAU/6)*.25),Vector3(.35,.14,.35))
			ToonArt.ball(root,Color("f5d781"),Vector3(0,.86,0),Vector3(.3,.2,.3))
			for i in range(3): ToonArt.ball(root,Color("edfaff"),Vector3((i-1)*.22,.25,0),Vector3(.4,.23,.35))
		4:
			for i in range(5):
				var leaf=ToonArt.ball(root,Color("78482e"),Vector3(sin(i*TAU/5)*.23,.25,cos(i*TAU/5)*.23),Vector3(.22,.55,.13));leaf.rotation.z=.6
			var pepper=ToonArt.ball(root,color,Vector3(0,.6,0),Vector3(.48,.8,.4));pepper.rotation.z=-.2
			ToonArt.tube(root,Color("7aa357"),Vector3(.05,1.02,0),.04,.07,.22)
			ToonArt.ball(root,Color("ffe597"),Vector3(-.12,.65,-.17),Vector3(.08,.35,.05))
		5:
			for i in range(5):
				var shell=ToonArt.ball(root,Color("b891cf"),Vector3(sin(i*TAU/5)*.3,.22,cos(i*TAU/5)*.3),Vector3(.24,.16,.65));shell.rotation.y=i*TAU/5
			var pearl=ToonArt.ball(root,Color("fff4df"),Vector3(0,.48,0),Vector3(.5,.5,.5))
			var mat=ToonArt.paint(Color("fff4df")).duplicate();mat.emission_enabled=true;mat.emission=Color("d6b3ff");mat.emission_energy_multiplier=.6;pearl.material_override=mat
	return root

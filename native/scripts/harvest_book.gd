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
	var model=StyleModel.new();model.setup("harvest_"+str(id));root.add_child(model)
	return root

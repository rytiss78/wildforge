extends RefCounted
class_name Dropai

# Dyleris and the dropai (user, November 2): the travelling shop is now Dyleris.
# The first time you talk to him on an island he marks where three dropai lie
# hidden under the island (minimap markers, glowing beams under the rock). They
# only appear after that talk, cost nothing, and you must go under the island to
# take them. Each changes the run for good. Kept per player (local nodes).

const ITEMS=[
	{"id":"anchor","name":"Gravity Anchor","glyph":"⚓","color":"9fb6ff","text":"No fall damage · slams hit 50% harder","effects":[["fallGuard",.95,"add"],["slamPower",.5,"multiply"]]},
	{"id":"lantern","name":"Sun Lantern","glyph":"☀","color":"ffd23f","text":"+8 armour","effects":[["armor",8,"add"]]},
	{"id":"pickaxe","name":"Golden Pickaxe","glyph":"⛏","color":"ffb84a","text":"Pots and plants drop double coins","effects":[["potGold",1,"multiply"]]},
	{"id":"compass","name":"Moon Compass","glyph":"☾","color":"c6d8ff","text":"+30% XP","effects":[["xpGain",.3,"multiply"]]},
	{"id":"hourglass","name":"Hourglass","glyph":"⌛","color":"e6c685","text":"Potions last 50% longer","effects":[["potionDuration",.5,"multiply"]]},
	{"id":"rain","name":"Rain Cloud","glyph":"☁","color":"8fd0ff","text":"Lava cools under your feet: it no longer hurts or burns you","effects":[]},
	{"id":"bell","name":"Echo Bell","glyph":"♪","color":"c69bff","text":"+15% fire rate","effects":[["rate",.15,"multiply"]]},
	{"id":"heart","name":"Second Heart","glyph":"♥","color":"ff6b7a","text":"One free revive","effects":[["revive",1,"add"]]},
	{"id":"ledger","name":"Merchant's Ledger","glyph":"$","color":"9dff7a","text":"Boxes and Dyleris cost 25% less","effects":[["discount",.25,"add"]]},
	{"id":"seed","name":"World Seed","glyph":"✿","color":"7dff9a","text":"+20% damage and +20 health","effects":[["damage",.2,"multiply"],["maxHp",20,"add"]]},
]
const PER_ISLAND=3
const REACH=2.6

static var found=[]   # ids taken this run
static var hidden=[]  # {"id","node","position","taken"} on this island
static var revealed=false

static func reset():
	found.clear();clear_island()

static func clear_island():
	for item in hidden:
		if is_instance_valid(item.get("node")): item.node.queue_free()
	hidden.clear();revealed=false

static func owns(id: String) -> bool: return found.has(id)

static func entry(id: String) -> Dictionary:
	for item in ITEMS:
		if item.id==id: return item
	return {}

# Talking to Dyleris for the first time on this island hides three dropai.
static func reveal(g) -> bool:
	if revealed or g.realm>=3: return false
	revealed=true
	var pool=ITEMS.filter(func(i):return not found.has(i.id))
	var rng=RandomNumberGenerator.new();rng.seed=g.seed_value+g.realm*4099+g.coop.local_id
	for k in range(mini(PER_ISLAND,pool.size())):
		var item=pool.pop_at(rng.randi_range(0,pool.size()-1))
		var spot=Vector3.ZERO
		for attempt in range(40):
			var angle=rng.randf()*TAU;var radius=rng.randf_range(40,RealmWorld.SPAWN_EXTENT-60)
			spot=Vector3(cos(angle)*radius,0,sin(angle)*radius)
			if radius<g.world.shore_radius(spot)-30 and hidden.all(func(h):return h.position.distance_to(spot)>60): break
		spot.y=g.world.under_height(spot.x,spot.z)
		hidden.append({"id":item.id,"node":make(g,item,spot),"position":spot,"taken":false})
	g.Journey.announce(g,"DYLERIS","%d DROPAI UNDER THE ISLAND" % hidden.size())
	return true

# A glowing gift hanging from the rock, with a beam down from it.
static func make(g,item: Dictionary,spot: Vector3) -> Node3D:
	var node=Node3D.new();node.name="Dropai";g.add_child(node);node.position=spot
	var color=Color(item.color)
	var paint=StandardMaterial3D.new();paint.albedo_color=color;paint.emission_enabled=true;paint.emission=color;paint.emission_energy_multiplier=2.0
	var gem=MeshInstance3D.new();var shape=PrismMesh.new();shape.size=Vector3(.7,.9,.7);gem.mesh=shape;gem.material_override=paint;gem.position=Vector3(0,-1.3,0);gem.rotation.z=PI;gem.name="Gem";node.add_child(gem)
	var beam=MeshInstance3D.new();var tube=CylinderMesh.new();tube.top_radius=.12;tube.bottom_radius=.35;tube.height=14.0;tube.radial_segments=10;beam.mesh=tube
	var glow=StandardMaterial3D.new();glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;glow.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glow.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
	glow.albedo_color=Color(color,.28);glow.cull_mode=BaseMaterial3D.CULL_DISABLED;beam.material_override=glow;beam.position=Vector3(0,-8.0,0);beam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.add_child(beam)
	var label=Label3D.new();label.text=str(item.glyph);label.font_size=96;label.pixel_size=.01;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=color.lightened(.3);label.position=Vector3(0,-2.3,0);node.add_child(label)
	var lamp=OmniLight3D.new();lamp.light_color=color;lamp.light_energy=1.5;lamp.omni_range=7.0;lamp.position=Vector3(0,-1.6,0);node.add_child(lamp)
	return node

static func tick(g,delta: float):
	if hidden.is_empty(): return
	for item in hidden:
		if item.taken or not is_instance_valid(item.node): continue
		var gem=item.node.get_node_or_null("Gem")
		if gem!=null: gem.rotation.y+=delta*1.5
		if not g.underside.flipped(): continue
		var p=g.player.position
		if Vector2(item.position.x-p.x,item.position.z-p.z).length()<REACH: take(g,item)

static func take(g,item: Dictionary):
	if item.taken: return
	item.taken=true
	var data=entry(item.id);found.append(item.id)
	var effects=data.effects.map(func(e):return {"key":e[0],"amount":e[1],"mode":e[2]})
	if not effects.is_empty(): g.rules.apply_effects(g.stats,effects)
	if item.id=="heart": g.hp=minf(g.stats.maxHp,g.hp)
	if is_instance_valid(item.node):
		g.burst(item.node.position+Vector3.DOWN*1.3,Color(data.color),14);item.node.queue_free()
	g.sound.effect("level",g.player.position)
	HeroTricks.word(g,"%s %s" % [data.glyph,str(data.text).to_upper()],Color(data.color).lightened(.2))

# Markers for the minimap (untaken ones).
static func markers() -> Array:
	return hidden.filter(func(h):return not h.taken).map(func(h):return h.position)

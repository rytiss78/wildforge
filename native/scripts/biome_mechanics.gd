extends RefCounted
class_name BiomeMechanics

# One fight mechanic per biome, appearing near each hero while they fight there:
#   0 Clover Woods    clover rings: stand inside to heal and shed burn and poison
#   1 Puffcap Marsh   spore fog: a drifting cloud that poisons everything inside
#   2 Moon Craters    ice floors: heroes slide, enemies are slowed and slip
#   3 Cloudwilds      wind gusts: a telegraphed gust shoves heroes and enemies
#   4 Candy Hell      lava vents: erupt into a spreading pool that burns everyone
#   5 Starfall Space  gravity rifts: pull everything in, then implode on enemies
# The host (or a solo game) rolls each event and broadcasts it, so every player
# sees the same zone; each player applies its effect to their own hero, and only
# the host moves, statuses and damages enemies. Not on the Red Moon.
const KINDS={
	0:{"id":"clover","every":22.0,"warn":0.0,"life":10.0,"radius":3.2,"color":Color("8ff27e"),"intro":"CLOVER RINGS · stand inside to heal and shed burn and poison"},
	1:{"id":"spores","every":9.0,"warn":1.2,"life":7.0,"radius":4.5,"color":Color("9fd451"),"intro":"SPORE FOG · poisons everything inside, enemies too"},
	2:{"id":"ice","every":11.0,"warn":.8,"life":14.0,"radius":5.5,"color":Color("bfeaff"),"intro":"ICE FLOORS · you slide; enemies slow down and slip"},
	3:{"id":"gust","every":10.0,"warn":1.4,"life":2.5,"radius":9.0,"color":Color("e6f6ff"),"intro":"WIND GUSTS · watch the streaks; the gust shoves everyone"},
	4:{"id":"lava","every":8.0,"warn":1.6,"life":8.0,"radius":4.5,"color":Color("ff7a2a"),"intro":"LAVA VENTS · pools spread and burn everyone inside"},
	5:{"id":"rift","every":12.0,"warn":1.2,"life":3.0,"radius":6.5,"color":Color("b38cff"),"intro":"GRAVITY RIFTS · pulled in, then the rift implodes on enemies"},
}
const LABELS={"clover":"+ HEAL ZONE","spores":"POISON FOG","ice":"ICE · SLIPPERY","gust":"WIND","lava":"LAVA","rift":"GRAVITY RIFT"}
const MAX_ZONES=8
static var disc_paints={}

# Spore fog poisons, lava burns and a rift implodes on whoever is at its centre: these
# zones wear the danger red. Clover heals, ice and wind only move you.
static func hurts_hero(biome: int) -> bool:
	return biome in [1,4,5]

static func active(g) -> bool:
	return g.run_active and g.realm<3 and g.mode=="playing"

static func clear(g):
	for zone in g.biome_zones:
		if is_instance_valid(zone.get("node")): zone.node.queue_free()
	g.biome_zones.clear();g.biome_clocks.clear()

# Host / solo: roll the next event near each hero, in that hero's biome. The
# first 40 s on an island stay clear so arrivals are not ambushed.
static func schedule(g,delta: float):
	if g.coop.active and not g.coop.hosting: return
	# Reviews switch ambient spawns off with a huge spawn clock; biome events follow it.
	if g.realm_time<40.0 or g.spawn_clock>=1e8: return
	var heroes={str(g.coop.local_id):g.player.position}
	if g.coop.active:
		for id in g.coop.members:
			var p=CoopSession.vector(g.coop.members[id].get("position",[]))
			if p!=Vector3.ZERO: heroes[str(id)]=p
	for key in heroes:
		var p: Vector3=heroes[key];var biome=g.world.biome_at(p);var info=KINDS[biome]
		var clock=float(g.biome_clocks.get(key,info.every*.5))-delta
		if clock>0: g.biome_clocks[key]=clock;continue
		g.biome_clocks[key]=info.every*g.rules.rng.randf_range(.85,1.2)
		if g.biome_zones.size()>=MAX_ZONES: continue
		# Ahead of or beside the hero, inside the fight rather than on top of them.
		var angle=g.rules.rng.randf()*TAU;var distance=g.rules.rng.randf_range(4.0,9.0) if biome!=3 else 0.0
		var at=p+Vector3(cos(angle),0,sin(angle))*distance
		if Vector2(at.x,at.z).length()>g.world.shore_radius(at)-8: at=p
		var event={"type":"biome_event","realm":g.realm,"biome":biome,"pos":[at.x,at.z],"dir":[cos(angle+PI*.5),sin(angle+PI*.5)],"serial":int(g.rules.rng.randi()%1000000)}
		spawn(g,event)
		if g.coop.active: g.coop.broadcast(event)

static func spawn(g,event: Dictionary):
	if int(event.get("realm",-1))!=g.realm: return
	var biome=int(event.biome);var info=KINDS[biome]
	var at=Vector3(float(event.pos[0]),0,float(event.pos[1]));at.y=g.world.height_at(at.x,at.z)
	var zone={"kind":info.id,"biome":biome,"pos":at,"dir":Vector3(float(event.dir[0]),0,float(event.dir[1])).normalized(),"age":0.0,"warn":float(info.warn),"life":float(info.warn)+float(info.life),"radius":float(info.radius),"fx":0.0}
	if zone.warn>0: zone.mark=preload("res://scripts/danger_mark.gd").make(g,at,zone.radius,{"spores":"toxic","ice":"caution","gust":"caution","lava":"lava","rift":"void"}.get(zone.kind,"ally"))
	if zone.has("mark"): zone.mark.material_override.set_shader_parameter("flash_from",clampf(1.0-.25/maxf(.3,zone.warn),0,1))
	if zone.kind=="lava": zone.built=1.0
	zone.node=disc(g,at,1.0 if zone.kind=="lava" else zone.radius,info.color,biome)
	name_tag(zone)
	g.biome_zones.append(zone)
	# The first event of each kind in a run says what it does.
	var seen: Dictionary=g.get_meta("biome_seen_mechanics",{})
	if not seen.has(zone.kind):
		seen[zone.kind]=true;g.set_meta("biome_seen_mechanics",seen)
		g.hud.tell(RealmWorld.BIOMES[biome].to_upper()+" · "+str(info.intro),4)

# A floating name says what the circle is (user request, October 25: "green
# circles on the ground, what are they?"). Green for help, red for harm.
static func name_tag(zone: Dictionary):
	var tag=Label3D.new();tag.text=LABELS[zone.kind];tag.font_size=44;tag.outline_size=10;tag.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	tag.modulate=Color("8dff7a") if zone.kind=="clover" else DangerMark.DANGER.lightened(.25) if hurts_hero(int(zone.biome)) else Color("e8f4ff")
	tag.pixel_size=.018;tag.outline_modulate=Color(0,0,0,.85);tag.position.y=2.6;tag.visibility_range_end=45;zone.node.add_child(tag)

# A terrain-hugging disc in the zone's colour; lava and ice are opaque-ish
# floors, the rest glow faintly. Spores and rifts add their existing area looks.
static func disc(g,at: Vector3,radius: float,color: Color,biome: int) -> Node3D:
	var root=Node3D.new();g.add_child(root);root.position=at
	var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(40):
		for uv in [Vector2.ZERO,Vector2.RIGHT.rotated(i*TAU/40),Vector2.RIGHT.rotated((i+1)*TAU/40)]:
			var p=Vector3(uv.x*radius,0,uv.y*radius);p.y=g.world.height_at(at.x+p.x,at.z+p.z)-at.y+(.16 if biome==4 else .07)
			tool.set_uv(uv*.5+Vector2.ONE*.5);tool.add_vertex(p)
	tool.generate_normals()
	var floor_disc=MeshInstance3D.new();floor_disc.name="Floor";floor_disc.mesh=tool.commit();floor_disc.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var key=str(biome)
	if not disc_paints.has(key):
		var paint=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		var fill: Color=Color("ffc24a") if biome==4 else color
		if hurts_hero(biome): fill=fill.lerp(DangerMark.DANGER,.45)
		paint.albedo_color=Color(fill,{0:.42,1:.22,2:.55,3:.0,4:.92,5:.25}[biome]);paint.cull_mode=BaseMaterial3D.CULL_DISABLED
		if biome==4: paint.emission_enabled=true;paint.emission=Color("ffb02e");paint.emission_energy_multiplier=2.4
		disc_paints[key]=paint
	floor_disc.material_override=disc_paints[key];root.add_child(floor_disc)
	# A bright edge (a dark crust for lava) so the zone reads against any ground.
	var rim=SurfaceTool.new();rim.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(48):
		var a=Vector2.RIGHT.rotated(i*TAU/48);var b=Vector2.RIGHT.rotated((i+1)*TAU/48)
		for uv in [a*.9,a,b,a*.9,b,b*.9]:
			var q=Vector3(uv.x*radius,0,uv.y*radius);q.y=g.world.height_at(at.x+q.x,at.z+q.z)-at.y+(.18 if biome==4 else .09);rim.add_vertex(q)
	var edge=MeshInstance3D.new();edge.name="Rim";edge.mesh=rim.commit();edge.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not disc_paints.has(key+"rim"):
		var line=StandardMaterial3D.new();line.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;line.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;line.cull_mode=BaseMaterial3D.CULL_DISABLED
		line.albedo_color=Color(DangerMark.DANGER,.95) if hurts_hero(biome) else Color(color.lightened(.35),.9)
		disc_paints[key+"rim"]=line
	edge.material_override=disc_paints[key+"rim"];edge.visible=biome!=3;floor_disc.add_child(edge)
	if biome==1: AreaVisual.make(root,"danger_poison",radius,Vector3.ZERO)
	if biome==5: AreaVisual.make(root,"gravity",radius*.55,Vector3.ZERO)
	floor_disc.visible=biome!=3
	return root

static func inside(zone: Dictionary,p: Vector3) -> bool:
	return Vector2(p.x-zone.pos.x,p.z-zone.pos.z).length()<zone_radius(zone)

static func live(zone: Dictionary) -> bool:
	return zone.age>=zone.warn and zone.life>0

# Lava pools spread from 1 m to full size over 4 s.
static func zone_radius(zone: Dictionary) -> float:
	if zone.kind=="lava": return lerpf(1.0,zone.radius,clampf((zone.age-zone.warn)/4.0,0,1))
	return zone.radius

static func tick(g,delta: float):
	if not active(g):
		return
	schedule(g,delta)
	var authority=not g.coop.active or g.coop.hosting
	for zone in g.biome_zones:
		zone.age+=delta;zone.life-=delta;zone.fx-=delta
		if zone.has("mark") and is_instance_valid(zone.mark):
			zone.mark.material_override.set_shader_parameter("progress",clampf(zone.age/maxf(.01,zone.warn),0,1))
			if zone.age>=zone.warn: zone.mark.queue_free();zone.erase("mark")
		look(g,zone,delta)
		if not live(zone): continue
		var hero=g.player.position
		match zone.kind:
			"clover":
				if inside(zone,hero): g.heal(2.0*delta+(g.stats.maxHp*.02*delta));g.player_fire=0.0;g.player_poison=0.0
			"spores":
				zone.pos+=zone.dir*delta*1.0;zone.node.position=zone.pos
				if inside(zone,hero): g.player_poison=maxf(g.player_poison,1.0)
				if authority:
					for enemy in near(g,zone): g.set_damage_status(enemy,"poison",5.0+g.realm*2.0,g.coop.local_id);enemy.status_time=maxf(float(enemy.status_time),2.0)
			"ice":
				if authority:
					for enemy in near(g,zone):
						enemy.slow=maxf(float(enemy.slow),.45)
						if g.rules.rng.randf()<delta*.25 and g.realm_time>float(enemy.get("slip_until",-3))+2.0: enemy.slip_until=g.realm_time+.7;enemy.freeze=maxf(float(enemy.freeze),.25 if enemy.boss else .7)
			"gust":
				if authority:
					for enemy in near(g,zone):
						if not enemy.boss: enemy.node.move_and_collide(zone.dir*7.0*delta)
			"lava":
				if inside(zone,hero) and g.player.is_on_floor():
					zone.burn=float(zone.get("burn",0))+delta
					if zone.burn>=1.0: zone.burn-=1.0;g.take_damage(maxf(5.0,g.stats.maxHp*.05),hero,"fire")
				if authority:
					for enemy in near(g,zone): g.set_damage_status(enemy,"fire",6.0+g.realm*2.0,g.coop.local_id);enemy.status_time=maxf(float(enemy.status_time),2.0)
			"rift":
				if authority:
					for enemy in near(g,zone,1.6):
						var pull: Vector3=(zone.pos-enemy.node.position)*Vector3(1,0,1)
						if not enemy.boss and pull.length()>.8: SkillBook.pull(enemy,pull.normalized()*6.0)
				if zone.life<=delta:
					CombatInk.star(g,zone.pos+Vector3.UP*1.2,zone.radius*1.4,KINDS[5].color,10.0,.45);CombatInk.wave(g,zone.pos,zone.radius,KINDS[5].color)
					g.sound.effect("blast",zone.pos)
					if authority: g.damage_area(zone.pos,zone.radius*.8,g.stat("damage")*2.5,"explosion")
					if Vector2(hero.x-zone.pos.x,hero.z-zone.pos.z).length()<1.8: g.take_damage(12.0+g.realm*4.0,zone.pos,"blast")
	for zone in g.biome_zones:
		if zone.life<=0:
			if is_instance_valid(zone.get("node")): zone.node.queue_free()
			if is_instance_valid(zone.get("mark")): zone.mark.queue_free()
	g.biome_zones=g.biome_zones.filter(func(zone):return zone.life>0)

static func near(g,zone: Dictionary,scale: float=1.0) -> Array:
	var r=zone_radius(zone)*scale
	return g.enemies.filter(func(e):return not e.dead and Vector2(e.node.position.x-zone.pos.x,e.node.position.z-zone.pos.z).length()<r)

# Per-frame look: growth, fading, sparks, gust streaks.
static func look(g,zone: Dictionary,delta: float):
	if not is_instance_valid(zone.get("node")): return
	var fade=clampf(zone.life/1.0,0,1)*clampf((zone.age-zone.warn+.4)/.4,0,1) if zone.kind!="clover" else clampf(zone.life,0,1)*clampf(zone.age*2.0,0,1)
	var floor_disc: MeshInstance3D=zone.node.get_node("Floor")
	floor_disc.transparency=1.0-fade
	# A spreading pool is rebuilt at its new size: scaling would lift the
	# terrain-following disc off the slope or sink it into the ground.
	if zone.kind=="lava" and absf(zone_radius(zone)-float(zone.get("built",zone.radius)))>.3:
		zone.built=zone_radius(zone);zone.node.queue_free();zone.node=disc(g,zone.pos,zone.built,KINDS[4].color,4);name_tag(zone)
	if zone.fx>0 or not live(zone): return
	zone.fx=.18/maxf(.25,EffectDetail.particles)
	var color: Color=KINDS[zone.biome].color
	var spot=zone.pos+Vector3(g.rules.rng.randf_range(-1,1),0,g.rules.rng.randf_range(-1,1)).limit_length(1.0)*zone_radius(zone);spot.y=g.world.height_at(spot.x,spot.z)
	match zone.kind:
		"clover":
			var star=CombatInk.star(g,spot+Vector3.UP*.4,.7,color,6.0,.5,1.0,"trail")
			if star!=null: star.fall=-1.5
		"ice":
			CombatInk.star(g,spot+Vector3.UP*.15,.5,Color("f2fcff"),4.0,.3,1.0,"trail")
		"lava":
			var star=CombatInk.star(g,spot+Vector3.UP*.3,.55,Color("ffb347"),5.0,.4,1.0,"trail")
			if star!=null: star.shards(Color("ffd27a"),2,1.2);star.fall=-2.5
		"gust":
			for streak in range(3):
				var from=zone.pos+Vector3(g.rules.rng.randf_range(-1,1),0,g.rules.rng.randf_range(-1,1)).limit_length(1.0)*zone.radius-zone.dir*3.0
				from.y=g.world.height_at(from.x,from.z)+g.rules.rng.randf_range(.4,2.0)
				CombatInk.beam(g,from,from+zone.dir*6.0,Color(color,.9),false,1.1)
		"rift":
			var star=CombatInk.star(g,spot+Vector3.UP*.5,.5,color,5.0,.35,1.0,"trail")
			if star!=null: star.fall=0.0

# The hero's horizontal velocity: ice keeps momentum, gusts and rifts push.
static func steer(g,desired: Vector3,previous: Vector3,delta: float) -> Vector3:
	var result=desired
	for zone in g.biome_zones:
		if not live(zone) or not inside(zone,g.player.position): continue
		match zone.kind:
			"ice":
				if g.player.is_on_floor(): result=Vector3(previous.x,0,previous.z).lerp(desired,1.0-exp(-delta*1.5))
			"gust": result+=zone.dir*6.0
			"rift":
				var pull: Vector3=(zone.pos-g.player.position)*Vector3(1,0,1)
				if pull.length()>.5: result+=pull.normalized()*3.2
	return result

# Zones that hurt the hero, for the playtest bot's steering.
static func harmful(g) -> Array:
	return g.biome_zones.filter(func(zone):return zone.kind in ["spores","lava"] and zone.age>=zone.warn*.5)

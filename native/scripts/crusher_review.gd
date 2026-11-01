extends RefCounted

# Crusher review (November 1): in a real run on Junkyard Planet a scrap crusher
# drops next to the hero with a few monsters under it. The plate rests as a step,
# the hero jumps on, and it lifts the hero and the monsters standing on it, holds
# them up high, then lets go; the hero lands without fall damage. Captures: the
# plate resting, mid-ride and at the top.

static func shot(g,name: String) -> bool:
	await RenderingServer.frame_post_draw
	return g.get_viewport().get_texture().get_image().save_png("user://crusher-"+name+".png")==OK

static func frames(g,count: int):
	for i in range(count):
		g.realm_time=0.0;g.spawn_clock=1e9
		await g.get_tree().physics_frame

static func run(g):
	AudioServer.set_bus_volume_db(0,-80)
	var checks={}
	g.start_run(91);g.spawn_clock=1e9
	await g.get_tree().create_timer(.5).timeout
	g.clear_entities()
	var p=g.world.landmarks[6]+Vector3(0,0,16);p.y=g.world.height_at(p.x,p.z)+.3
	g.world.ensure_ground(p);g.player.position=p;g.player.velocity=Vector3.ZERO;g.player.reset_physics_interpolation()
	g.yaw=0.0;g.pitch=.32
	await frames(g,30)
	checks.junkyard=g.world.biome_at(p)==6
	var forward=Vector3(-sin(g.yaw),0,-cos(g.yaw))
	var at=p+forward*6.0;at.y=g.world.height_at(at.x,at.z)
	# Under the plate: three monsters (tough, harmless), a boss, and the hero.
	var squashed=[]
	for i in range(3):
		g.spawn_enemy(6);var e=g.enemies[-1];var spot=at+Vector3((i-1)*1.4,0,.6);spot.y=g.world.height_at(spot.x,spot.z)
		e.node.position=spot;e.speed=0.0;e.attack=1e9;e.contact=1e9;e.damage=0.0;e.hp=1e7;e.maxHp=1e7;e.elite=false;e.home=spot;squashed.append(e)
	g.spawn_enemy(6,true);var boss=g.enemies[-1];var boss_at=at+Vector3(-1.0,0,-1.2);boss_at.y=g.world.height_at(boss_at.x,boss_at.z)
	boss.node.position=boss_at;boss.speed=0.0;boss.attack=1e9;boss.contact=1e9;boss.damage=0.0;var boss_hp=float(boss.hp)
	var hero_at=at+Vector3(.8,0,-.5);hero_at.y=g.world.height_at(hero_at.x,hero_at.z)+.1
	BiomeMechanics.spawn(g,{"type":"biome_event","realm":g.realm,"biome":6,"pos":[at.x,at.z],"dir":[1,0]})
	var zone=g.biome_zones[-1]
	while zone.age<zone.warn-.1:
		g.player.position=hero_at;g.player.velocity=Vector3.ZERO;await frames(g,1)
	g.invulnerable=0.0;var hp_struck=g.hp
	while zone.age<zone.warn+.6: await frames(g,1)
	checks.struck=zone.get("struck",false)
	var half=zone.radius*.85
	var clear_of=func(q: Vector3) -> bool: return not BiomeMechanics.under(zone,q)
	checks.monsters_squashed=squashed.all(func(e):return e.dead)
	checks.boss_hurt_and_pushed=not boss.dead and float(boss.hp)<boss_hp and clear_of.call(boss.node.position)
	checks.hero_hurt_and_pushed=g.hp<hp_struck and clear_of.call(g.player.position) and g.player.position.y<BiomeMechanics.plate_top(zone)
	checks.rest=await shot(g,"rest")
	# A monster climbs on (dropped onto the slab) to ride along.
	var riders=[]
	g.spawn_enemy(6);var rider=g.enemies[-1];rider.node.position=Vector3(at.x-1.2,BiomeMechanics.plate_top(zone)+.6,at.z+1.0)
	rider.speed=0.0;rider.attack=1e9;rider.contact=1e9;rider.damage=0.0;rider.hp=1e7;rider.maxHp=1e7;rider.home=rider.node.position;riders.append(rider)
	g.invulnerable=0.0;var hp_before=g.hp
	# Jump onto the resting plate.
	var top=BiomeMechanics.plate_top(zone)
	g.player.position=Vector3(at.x+.6,top+1.6,at.z-.6);g.player.velocity=Vector3.ZERO;g.player.reset_physics_interpolation()
	await frames(g,40)
	checks.on_plate=g.player.is_on_floor() and absf(g.player.position.y-BiomeMechanics.plate_top(zone))<.35
	var ground=g.world.height_at(at.x,at.z)
	while zone.age<zone.warn+BiomeMechanics.LIFT_REST+BiomeMechanics.LIFT_RISE*.5: await frames(g,1)
	checks.ride=await shot(g,"ride")
	while zone.age<zone.warn+BiomeMechanics.LIFT_REST+BiomeMechanics.LIFT_RISE+.4: await frames(g,1)
	checks.hero_lifted=g.player.position.y>ground+BiomeMechanics.LIFT_TOP-.5 and zone.get("lifted_hero",false)
	checks.monsters_lifted=riders.any(func(e):return not e.dead and e.node.position.y>ground+BiomeMechanics.LIFT_TOP-1.0)
	checks.top=await shot(g,"top")
	# It lets go: everyone drops back down, the hero without fall damage.
	while zone.life>0: await frames(g,1)
	await frames(g,60)
	checks.landed=g.player.is_on_floor() and g.player.position.y<ground+1.5
	checks.no_fall_damage=g.hp>=hp_before
	checks.monsters_down=riders.all(func(e):return e.dead or e.node.position.y<ground+2.0)
	print("CRUSHER_REVIEW "+JSON.stringify({"checks":checks,"lifted":int(zone.get("lifted",0))}))
	g.get_tree().quit()

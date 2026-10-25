extends RefCounted

# The cartoon enemy roster (CartoonBook, CartoonCreatureRig). Captures:
#   cartoon-roster.png  every biome's ten creatures, one cell per biome
#   cartoon-ingame.png  real enemies spawned by the game around the hero, with HUD
# Checks that every species builds, carries its health orb and the shared batched
# material, and that the game's own spawn path makes cartoon creatures.

const CELL=Vector2i(720,405)

static func frame(g) -> Image:
	await RenderingServer.frame_post_draw
	var image=g.get_viewport().get_texture().get_image();image.convert(Image.FORMAT_RGBA8);image.resize(CELL.x,CELL.y,Image.INTERPOLATE_LANCZOS);return image

static func ground(g,p: Vector3) -> Vector3:
	return Vector3(p.x,g.world.height_at(p.x,p.z),p.z)

# Fixed 60 Hz steps, so a pose does not depend on how fast frames render.
static func play(g,rigs: Array,seconds: float,movement: Vector3=Vector3.ZERO):
	for step in range(maxi(1,int(seconds*60))):
		if g.mode=="paused": g.hud.close()
		for rig in rigs: rig.animate(1.0/60.0,movement,true)
		await g.get_tree().process_frame

static func run(g):
	AudioServer.set_bus_volume_db(0,-80)
	var checks={"species":true,"orbs":true,"materials":true}
	g.start_run(151);g.set_physics_process(false);g.camera_locked=true;g.clear_entities();g.spawn_clock=1e9
	await play(g,[],.4)
	g.hud.visible=false;g.player.visible=false
	var origin: Vector3=g.player.position
	var sheet=Image.create(CELL.x*2,CELL.y*3,false,Image.FORMAT_RGBA8)
	for biome in range(6):
		var rigs=[]
		for index in range(CreatureBook.WEIGHTS.size()):
			var entry=CreatureBook.entry(biome,index)
			var rig=g.world.model(entry.model,entry.height);g.add_child(rig)
			# Two rows of five: the animals in front, the humanoid mutants behind.
			var spot=origin+Vector3((index%5-2)*2.7,0,-6.0-float(index/5)*3.4)
			rig.position=ground(g,spot)+Vector3.UP*(.8 if entry.flying else 0.0);rig.rotation.y=PI-.25+.08*index
			rigs.append(rig)
			checks.species=checks.species and rig is CartoonCreatureRig and rig.species.mesh.get_surface_count()==1
			checks.orbs=checks.orbs and rig.find_child("GlassCore",true,false)!=null
			checks.materials=checks.materials and rig.batched!=null and rig.batched.next_pass!=null
		g.camera.position=origin+Vector3(0,3.0,1.6);g.camera.look_at(origin+Vector3(0,1.0,-7.6))
		await play(g,rigs,.5,Vector3(0,0,1.5) if biome%2==0 else Vector3.ZERO)
		sheet.blit_rect(await frame(g),Rect2i(Vector2i.ZERO,CELL),Vector2i((biome%2)*CELL.x,(biome/2)*CELL.y))
		for rig in rigs: rig.queue_free()
		await g.get_tree().process_frame
	checks.roster=sheet.save_png("user://cartoon-roster.png")==OK
	# The same Clover Woods line seen from behind: the one orb inside shows through.
	var rear=[]
	for index in range(CreatureBook.WEIGHTS.size()):
		var entry=CreatureBook.entry(0,index)
		var rig=g.world.model(entry.model,entry.height);g.add_child(rig)
		rig.position=ground(g,origin+Vector3((index%5-2)*2.7,0,-6.0-float(index/5)*3.4))+Vector3.UP*(.8 if entry.flying else 0.0);rig.rotation.y=.25-.05*index;rear.append(rig)
		checks.orbs=checks.orbs and rig.find_child("RearGlass",true,false)==null and rig.orb_paint.shader.code.contains("stencil_mode read")
	g.camera.position=origin+Vector3(0,3.0,1.6);g.camera.look_at(origin+Vector3(0,1.0,-7.6))
	await play(g,rear,.4)
	await RenderingServer.frame_post_draw
	checks.rear=g.get_viewport().get_texture().get_image().save_png("user://cartoon-rear.png")==OK
	for rig in rear: rig.queue_free()
	await g.get_tree().process_frame
	# Close-ups of the humanoid mutants, three per biome.
	var mutants=Image.create(CELL.x*2,CELL.y*3,false,Image.FORMAT_RGBA8)
	for biome in range(6):
		var rigs=[]
		for index in [7,8,9]:
			var entry=CreatureBook.entry(biome,index)
			var rig=g.world.model(entry.model,entry.height);g.add_child(rig)
			rig.position=ground(g,origin+Vector3((index-8)*1.9,0,-4.2));rig.rotation.y=PI-.3+.3*(index-7);rigs.append(rig)
		g.camera.position=origin+Vector3(0,1.9,.4);g.camera.look_at(origin+Vector3(0,1.15,-4.2))
		await play(g,rigs,.5,Vector3(0,0,1.5))
		mutants.blit_rect(await frame(g),Rect2i(Vector2i.ZERO,CELL),Vector2i((biome%2)*CELL.x,(biome/2)*CELL.y))
		for rig in rigs: rig.queue_free()
		await g.get_tree().process_frame
	checks.mutants=mutants.save_png("user://cartoon-mutants.png")==OK
	# The heroes, five to a cell, in the game's own light.
	var heroes=Image.create(CELL.x*2,CELL.y*3,false,Image.FORMAT_RGBA8)
	var list=g.rules.data.heroes
	checks.heroes=true
	for cell in range(5):
		var rigs=[]
		for k in range(5):
			var index=cell*5+k
			if index>=list.size(): break
			var rig=g.world.model(str(list[index].model),1.65);g.add_child(rig)
			rig.position=ground(g,origin+Vector3((k-2)*1.5,0,-4.0));rig.rotation.y=PI-.2+.1*k;rigs.append(rig)
			checks.heroes=checks.heroes and rig.solid!=null and rig.solid.core_materials.size()==1 and rig.solid.hand_socket()!=null
		g.camera.position=origin+Vector3(0,1.6,.6);g.camera.look_at(origin+Vector3(0,.9,-4.0))
		await play(g,rigs,.4,Vector3(0,0,2.0))
		heroes.blit_rect(await frame(g),Rect2i(Vector2i.ZERO,CELL),Vector2i((cell%2)*CELL.x,(cell/2)*CELL.y))
		for rig in rigs: rig.queue_free()
		await g.get_tree().process_frame
	checks.hero_sheet=heroes.save_png("user://cartoon-heroes.png")==OK
	# The eight realm bosses, one at a time.
	var bosses=Image.create(CELL.x*4,CELL.y*2,false,Image.FORMAT_RGBA8)
	checks.bosses=true
	for id in range(8):
		var entry=BossBook.entry(id)
		var rig=g.world.model("boss_"+str(id),float(entry.height));g.add_child(rig)
		rig.position=ground(g,origin+Vector3(0,0,-float(entry.height)*1.25));rig.rotation.y=PI-.35
		checks.bosses=checks.bosses and rig.solid!=null and rig.solid.core_material!=null and not rig.legs.is_empty()
		g.camera.position=origin+Vector3(0,float(entry.height)*.45,0);g.camera.look_at(rig.position+Vector3.UP*float(entry.height)*.5)
		await play(g,[rig],.4,Vector3(0,0,1.5))
		bosses.blit_rect(await frame(g),Rect2i(Vector2i.ZERO,CELL),Vector2i((id%4)*CELL.x,(id/4)*CELL.y))
		rig.queue_free();await g.get_tree().process_frame
	checks.boss_sheet=bosses.save_png("user://cartoon-bosses.png")==OK
	# The real spawn path, seen through the game camera with the HUD.
	g.hud.visible=true;g.player.visible=true;g.camera_locked=false;g.set_physics_process(true)
	g.invulnerable=1e9
	for i in range(14): g.spawn_enemy(randf_range(6,12))
	checks.spawned_cartoon=g.enemies.all(func(e):return e.boss or e.node.get_meta("rig") is CartoonCreatureRig)
	for i in range(150):
		if g.mode=="paused": g.hud.close()
		g.invulnerable=1e9;g.hp=g.stats.maxHp
		await g.get_tree().process_frame
	await RenderingServer.frame_post_draw
	checks.ingame=g.get_viewport().get_texture().get_image().save_png("user://cartoon-ingame.png")==OK
	print("CARTOON_REVIEW "+JSON.stringify({"checks":checks}))
	g.get_tree().quit(0 if not checks.values().has(false) else 1)

extends RefCounted

# The final boss (The Grand Noggin): the real Red Moon entry, its rise, every action with its red
# marks, lunge and leap movement, both phase changes, the open-window damage bonus
# and the boss bar. Rendered captures: colossus-intro.png and colossus-sheet.png
# (seven actions caught mid-blow, plus phase III).

const CELL=Vector2i(480,270)

static func frame(g) -> Image:
	await RenderingServer.frame_post_draw
	var image=g.get_viewport().get_texture().get_image();image.convert(Image.FORMAT_RGBA8);image.resize(CELL.x,CELL.y,Image.INTERPOLATE_LANCZOS);return image

# The game pauses when its window loses focus; the review resumes it at once.
static func wait(g,seconds: float):
	var end=Time.get_ticks_msec()+seconds*1000
	while Time.get_ticks_msec()<end:
		if g.mode=="paused": g.hud.close()
		# The test hero stands in every blow; keep it alive.
		g.invulnerable=1e9;g.hp=g.stats.maxHp
		await g.get_tree().process_frame

static func run(g):
	AudioServer.set_bus_volume_db(0,-80)
	var checks={}
	g.start_run(407);g.invulnerable=1e9
	await wait(g,.3)
	g.enter_realm(3)
	await wait(g,5.0)
	var bosses=g.enemies.filter(func(e):return e.get("boss_id",-1)==8 and not e.dead)
	checks.spawned=bosses.size()==1
	if bosses.is_empty():
		print("COLOSSUS_REVIEW "+JSON.stringify({"checks":checks}));g.get_tree().quit(1);return
	var boss=bosses[0];var body=boss.node.get_meta("rig")
	checks.rig=body is ColossusRig and boss.height==17.0 and is_equal_approx(boss.radius,4.2)
	checks.risen=not g.events.get("final_intro",true) and is_equal_approx(boss.node.scale.x,1.0)
	g.player.position=boss.node.position+Vector3(0,0,22);g.player.position.y=g.world.height_at(g.player.position.x,g.player.position.z)+.5
	g.yaw=0.0;g.pitch=.32
	await wait(g,.6)
	# No boss bar: the health orb in its chest shows health and, by colour, the phase.
	checks.orb=body.orb_paint!=null and body.find_child("GlassCore",true,false)!=null
	g.get_viewport().get_texture().get_image().save_png("user://colossus-intro.png")
	var sheet=Image.create(CELL.x*4,CELL.y*2,false,Image.FORMAT_RGBA8)
	var actions=["sweep","slam","stomp","lunge","leap","breath","tail"]
	var marks_ok=true;var moved=true
	for i in range(actions.size()):
		boss.recovery=0;g.hazards.clear()
		var before=boss.node.position
		var target=g.player.position
		ColossusFight.start(g,boss,actions[i],target)
		marks_ok=marks_ok and g.hazards.size()>=5
		# Catch it just into the strike.
		await wait(g,body.windup+body.active*.5)
		sheet.blit_rect(await frame(g),Rect2i(Vector2i.ZERO,CELL),Vector2i((i%4)*CELL.x,(i/4)*CELL.y))
		if actions[i] in ["lunge","leap"]:
			await wait(g,body.active)
			moved=moved and boss.node.position.distance_to(before)>4.0
		await wait(g,body.recover*.6)
		boss.node.position=before;boss.erase("colossus_move")
		g.hp=g.stats.maxHp
	checks.actions_mark=marks_ok
	checks.lunge_leap_move=moved
	# Open window: heavy blows leave it taking more damage, ordinary time does not.
	boss.open_from=g.realm_time-1;boss.open_until=g.realm_time+1
	checks.open_bonus=is_equal_approx(ColossusFight.damage_scale(g,boss),ColossusFight.OPEN_DAMAGE)
	boss.open_until=g.realm_time-.1
	checks.closed_normal=is_equal_approx(ColossusFight.damage_scale(g,boss),1.0)
	# Its blows hit DEADLY times harder than their base damage.
	g.hazards.clear();ColossusFight.hazard(g,boss.node.position,3.0,1.0,100.0,"annihilation")
	checks.deadly=g.hazards.size()==1 and is_equal_approx(g.hazards[0].damage,100.0*ColossusFight.DEADLY)
	g.hazards.clear()
	# Health potions: three shed round it once a minute, drunk by walking into one.
	boss.next_potions=g.realm_time-.1;var before_drops=g.consumables.size()
	ColossusFight.potions(g,boss)
	var drops=g.consumables.filter(func(d):return d.kind=="health")
	checks.potions_drop=g.consumables.size()==before_drops+ColossusFight.POTIONS and drops.size()==ColossusFight.POTIONS and float(boss.next_potions)>g.realm_time+50
	var potion=drops[0] if not drops.is_empty() else {}
	if not potion.is_empty():
		g.invulnerable=1e9;g.hp=g.stats.maxHp*.3;var low=g.hp
		g.player.position=potion.node.position;g.player.velocity=Vector3.ZERO
		for i in range(6):
			g.player.position=potion.node.position if is_instance_valid(potion.node) else g.player.position
			await g.get_tree().process_frame
		checks.potion_heals=g.hp>low+g.stats.maxHp*.3 and not g.consumables.has(potion)
	else: checks.potion_heals=false
	# Phases at 65% and 30% health.
	g.hurt_enemy(boss,boss.hp-boss.maxHp*.6,"hit")
	checks.phase_two=ColossusFight.phase(boss)==1 and body.phase_index==1
	await wait(g,3.5)
	g.hurt_enemy(boss,boss.hp-boss.maxHp*.25,"hit")
	checks.phase_three=ColossusFight.phase(boss)==2 and body.phase_index==2
	await wait(g,1.2)
	sheet.blit_rect(await frame(g),Rect2i(Vector2i.ZERO,CELL),Vector2i(3*CELL.x,CELL.y))
	checks.sheet=sheet.save_png("user://colossus-sheet.png")==OK
	print("COLOSSUS_REVIEW "+JSON.stringify({"checks":checks,"phase":ColossusFight.phase(boss),"hp":boss.hp/boss.maxHp}))
	g.get_tree().quit(0 if not checks.values().has(false) else 1)

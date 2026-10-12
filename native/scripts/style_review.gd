extends RefCounted

# A short art review, not a substitute for the end-of-overhaul regression suite.
static func capture(g: Node3D,name: String) -> bool:
	for i in range(3): await g.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return g.get_viewport().get_texture().get_image().save_png("user://style-"+name+".png")==OK

static func run(g: Node3D):
	if DisplayServer.get_name()=="headless": g.get_tree().quit(1);return
	AudioServer.set_bus_volume_db(0,-80);g.hud.menu_start.pressed.emit()
	g.start_run(407);g.invulnerable=1000;g.spawn_clock=99999;g.xp_target=100000
	for i in range(210): await g.get_tree().process_frame
	g.set_physics_process(false);g.set_process(false)
	for enemy in g.enemies: enemy.node.queue_free()
	g.enemies.clear()
	for i in range(5):
		g.spawn_enemy(12+i)
		var enemy=g.enemies[-1];enemy.node.position=Vector3(-4+i*2.2,0,-9-float(i%2)*2)
		enemy.node.position.y=g.world.height_at(enemy.node.position.x,enemy.node.position.z)
		enemy.node.look_at(Vector3(g.player.position.x,enemy.node.position.y,g.player.position.z))
	for effect in g.effects:
		if is_instance_valid(effect.node): effect.node.queue_free()
	g.effects.clear();g.projectiles.map(func(p):p.node.queue_free());g.projectiles.clear()
	for i in range(180): g._process(1.0/60.0)
	var checks={"camera":g.camera.fov==70 and g.camera_distance==12 and is_equal_approx(g.pitch,.3) and not g.camera_locked}
	checks.idle=await capture(g,"idle")
	var point=g.enemies[3].node.position
	g.warn_at(point+Vector3.LEFT*4,1.8,2.0,8,"lava")
	checks.warning=await capture(g,"warning")
	var previous_damage=float(g.damage_sources.get("effect:explosion",0.0))
	var previous_hp=float(g.enemies[3].hp)
	g.damage_area(point,3.2,4,"explosion")
	g._process(.025);checks.impact=await capture(g,"impact")
	checks.damage_path=float(g.damage_sources.get("effect:explosion",0.0))>previous_damage and g.enemies[3].hp<previous_hp
	g._process(.115);checks.expansion=await capture(g,"expansion")
	g._process(.30);checks.recovery=await capture(g,"recovery")
	g._process(.8)
	g.lightning_bolt(point+Vector3.UP*10,point+Vector3.UP*.8)
	g.slash_fx(g.player.position+Vector3.UP,point)
	g._process(.025);checks.electric=await capture(g,"electric")
	g._process(1.0)
	checks.effects_expired=not g.effects.any(func(e):return e.get("ink_fx",false))
	for kind in ["gravity","poison"]:
		var node=AreaVisual.make(g,kind,2.5,point)
		checks[kind]=await capture(g,kind);node.queue_free()
	var result={"checks":checks,"note":"Focused color/shape/lifetime review; full integration, co-op, performance and export testing deferred by user."}
	print("STYLE_REVIEW "+JSON.stringify(result));g.get_tree().quit(0 if not checks.values().has(false) else 1)

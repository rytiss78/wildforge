extends RefCounted

# The hero's damage (red), shield damage (blue) and healing (green) numbers fall
# from under the health panel. Rendered capture: hero-numbers.png.

static func run(g):
	AudioServer.set_bus_volume_db(0,-80)
	var checks={}
	g.start_run(407);g.spawn_clock=1e9
	for i in range(30): await g.get_tree().process_frame
	g.stats.shield=20;g.shield_hp=12;g.invulnerable=0
	g.take_damage(30.0)
	await g.get_tree().create_timer(.4).timeout
	g.invulnerable=0;g.take_damage(9.0)
	await g.get_tree().create_timer(.4).timeout
	g.heal(15.0)
	await g.get_tree().create_timer(.25).timeout
	var kinds={}
	for entry in g.hud.hero_numbers: kinds[entry.kind]=int(kinds.get(entry.kind,0))+1
	checks.kinds=kinds.has("damage") and kinds.has("shield") and kinds.has("heal")
	var shown=g.hud.hero_labels.filter(func(l):return l.visible)
	checks.below_panel=not shown.is_empty() and shown.all(func(l):return l.position.y>=g.hud.VITALS.end.y)
	checks.heal_not_in_old_numbers=not g.damage_numbers.any(func(d):return d.cause=="heal")
	await RenderingServer.frame_post_draw
	checks.capture=g.get_viewport().get_texture().get_image().save_png("user://hero-numbers.png")==OK
	print("HERO_NUMBERS_REVIEW "+JSON.stringify({"checks":checks,"numbers":g.hud.hero_numbers.map(func(e):return [e.kind,roundi(e.amount)])}))
	g.get_tree().quit(0 if not checks.values().has(false) else 1)

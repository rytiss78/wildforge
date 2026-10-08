extends RefCounted

static func run(game) -> Dictionary:
	var checks={};var data=game.rules.data
	checks.content_count=data.loot.size()==696 and data.weapons.size()==65 and data.augments.size()==360
	checks.unique_ids=(data.loot+data.weapons).map(func(i):return i.id).size()==761
	var positions=game.chests.map(func(c):return c.node.position)
	var per_biome=[0,0,0,0,0,0];var spacing=1000.0
	for p in positions:
		per_biome[game.world.biome_at(p)]+=1
		for q in positions:
			if p!=q: spacing=minf(spacing,Vector2(p.x-q.x,p.z-q.z).length())
	checks.chest_distribution=positions.size()==24 and per_biome.all(func(n):return n==4) and spacing>25
	var hashes={};var icons=true
	for item in data.loot+data.weapons:
		var texture=IllustratedIcons.texture(item.id,not item.has("effects"))
		var code=hash(texture.get_image().get_data())
		icons=icons and not hashes.has(code);hashes[code]=true
	checks.distinct_rendered_icons=icons and hashes.size()==761
	for kind in ["item","skill","weapon"]:
		for sample in range(12):
			var choices=game.rules.offers(kind,0,false,game.stats,game.equipped)
			checks.five_choices=checks.get("five_choices",true) and choices.size()==5 and choices.map(func(i):return i.id).all(func(id):return choices.filter(func(i):return i.id==id).size()==1)
	# Conditional health/shield/economy bonuses must turn off again without subtracting owned power.
	var initial=game.stats.duplicate(true);var hp=game.hp;var gold=game.gold
	game.stats["augment-low-damage"]=.25;game.hp=initial.maxHp*.2
	ContentExpansion.refresh(game);var active=game.stat("damage")
	game.hp=initial.maxHp;ContentExpansion.refresh(game)
	checks.conditional_health=is_equal_approx(active,initial.damage*1.25) and is_equal_approx(game.stat("damage"),initial.damage)
	game.stats["augment-rich-goldGain"]=.2;game.gold=50;ContentExpansion.refresh(game);var wealthy=game.stat("goldGain")
	game.gold=49;ContentExpansion.refresh(game)
	checks.conditional_gold=is_equal_approx(wealthy,initial.goldGain*1.2) and is_equal_approx(game.stat("goldGain"),initial.goldGain)
	game.stats["augment-dash-rate"]=.22;game.condition_times.dash=game.elapsed;ContentExpansion.refresh(game);var fast=game.stat("rate")
	game.condition_times.dash=game.elapsed-4;ContentExpansion.refresh(game)
	checks.conditional_expiry=is_equal_approx(fast,initial.rate*1.22) and is_equal_approx(game.stat("rate"),initial.rate)
	game.stats=initial;game.hp=hp;game.gold=gold;game.condition_times.clear();ContentExpansion.refresh(game)
	# All 40 behavioral variants create their actual held model and exercise their firing branch.
	var originals=game.equipped.duplicate(true);var variants=data.weapons.filter(func(w):return w.has("archetype"))
	var exercised=0
	game.clear_entities();game.player.position=Vector3(0,game.world.height_at(0,0)+.2,0)
	for definition in variants:
		game.equipped.clear();game.avatar.finish_melee();game.melee_attacks.clear()
		var item=definition.duplicate(true);item.kind="weapon";item.strength=1;item.tier=0
		game.equip_weapon(item)
		game.spawn_enemy(4);var enemy=game.enemies[-1];enemy.node.position=game.player.position+Vector3(0,0,-4);enemy.hp=100000;enemy.maxHp=100000
		var before=game.projectiles.size()+game.pools.size()+game.hazards.size()+game.melee_attacks.size();var health=enemy.hp
		game.fire(game.equipped[0],game.player.position+Vector3.UP)
		if game.projectiles.size()+game.pools.size()+game.hazards.size()+game.melee_attacks.size()>before or enemy.hp<health: exercised+=1
		game.clear_entities()
		await game.get_tree().process_frame
	checks.weapon_branches=exercised==40
	game.equipped=originals;game.avatar.finish_melee();game.avatar.sync_equipment(game.equipped)
	# A sheet reviews both conditional object/glyph combinations and behavioral weapon badges.
	if DisplayServer.get_name()!="headless":
		var panel=PanelContainer.new();panel.position=Vector2(80,35);panel.size=Vector2(1260,730);game.hud.add_child(panel)
		var grid=GridContainer.new();grid.columns=10;panel.add_child(grid)
		var samples=variants+data.loot.filter(func(i):return i.has("art")).filter(func(i):return int(i.art.condition)<2).slice(0,30)
		for item in samples:
			var column=VBoxContainer.new();grid.add_child(column)
			var icon=TextureRect.new();icon.texture=IllustratedIcons.texture(item.id);icon.custom_minimum_size=Vector2(88,74);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;column.add_child(icon)
			var label=Label.new();label.text=item.name;label.add_theme_font_size_override("font_size",10);label.custom_minimum_size.x=120;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;column.add_child(label)
		await game.get_tree().process_frame;await RenderingServer.frame_post_draw
		game.get_viewport().get_texture().get_image().save_png("user://content-art.png");panel.queue_free()
	game.enter_realm(0);game.set_physics_process(false);game.spawn_clock=99999;game.invulnerable=10000
	return checks

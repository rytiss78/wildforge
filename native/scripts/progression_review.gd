extends RefCounted

static func capture(game,name: String) -> bool:
	for i in range(4): await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return game.get_viewport().get_texture().get_image().save_png("user://progression-"+name+".png")==OK

static func run(game):
	seed(831);AudioServer.set_bus_volume_db(0,-80)
	game.start_run(831);game.set_physics_process(false);game.spawn_clock=99999
	var checks={};game.rules.rng.seed=831
	var jumps=0;var rare_jump=false
	for i in range(12000):
		var item=game.rules.roll("skill",0,1 if i%2==0 else 0)
		if item.effects[0].key=="airJumps":
			jumps+=1
			if item.tier>0: rare_jump=item.effects[0].amount>=2
	checks.jump_available=jumps>=40;checks.rare_jump_scales=rare_jump
	var reachable=[]
	for kind in game.rules.mechanic_pools:
		for pool in game.rules.mechanic_pools[kind].values(): reachable.append_array(pool.map(func(i):return i.id))
	checks.every_card_reachable=reachable.size()==game.rules.data.loot.size() and game.rules.data.loot.all(func(i):return reachable.has(i.id))
	game.rules.banished=["airJumps"]
	checks.banished=true
	for i in range(20): checks.banished=checks.banished and game.rules.offers("skill",0,false,game.stats,game.equipped).all(func(item):return item.kind=="weapon" or item.effects[0].key!="airJumps")
	game.rules.banished=[]
	var capped=game.stats.duplicate(true);capped.airJumps=8
	checks.capped=true
	for i in range(20): checks.capped=checks.capped and game.rules.offers("skill",0,false,capped,game.equipped).all(func(item):return item.kind=="weapon" or item.effects[0].key!="airJumps")
	game.clear_entities();game.spawn_enemy(8);var enemy=game.enemies[0]
	enemy.node.position=game.player.position+Vector3(6,0,0);enemy.node.position.y=game.world.height_at(enemy.node.position.x,enemy.node.position.z)+.2
	var before=enemy.node.position.distance_to(game.player.position)
	ForcePulse.apply(game,game.player.position,"enemyPull",2)
	checks.pull=enemy.node.position.distance_to(game.player.position)<before-.5
	before=enemy.node.position.distance_to(game.player.position)
	ForcePulse.apply(game,game.player.position,"enemyPush",3)
	checks.push=enemy.node.position.distance_to(game.player.position)>before+.5
	game.rules.apply_effects(game.stats,[{"key":"enemyPull","amount":2},{"key":"enemyPush","amount":3},{"key":"damage","amount":.25,"mode":"multiply"}])
	game.activate_consumable("fire");game.stats["augment-healthy-damage"]=.25;ContentExpansion.refresh(game)
	var rows=RunReport.stat_rows(game)
	checks.stat_totals=rows.all(func(r):return is_equal_approx(r.base+r.hero+r.gear+r.buff+r.augment,r.total))
	game.hud.build_menu();checks.stats_capture=await capture(game,"stats")
	var first_icon=IllustratedIcons.texture("attraction-pulse-skill");var second_icon=IllustratedIcons.texture("repulsion-pulse-skill")
	checks.distinct_icons=hash(first_icon.get_image().get_data())!=hash(second_icon.get_image().get_data())
	var choices=[]
	for id in ["attraction-pulse-skill","repulsion-pulse-skill","extra-hop-skill","jump-boots-skill","feather-soles-skill"]:
		var card=game.rules.loot_by_id[id].duplicate(true);card.tier=0;card.strength=1;card.name=card.title;choices.append(card)
	game.hud.show_offers(choices,"level");checks.cards_capture=await capture(game,"cards")
	var gallery=game.hud.open("MOBILITY ICONS","Items and skills depict their actual movement effect")
	var grid=GridContainer.new();grid.columns=6;gallery.add_child(grid)
	for kind in ["item","skill"]:
		for id in ["jump-boots","extra-hop","feather-soles","slam-stone","wide-slam","bounce-pad"]:
			var column=VBoxContainer.new();column.custom_minimum_size=Vector2(145,195);grid.add_child(column)
			var icon=TextureRect.new();icon.texture=IllustratedIcons.texture(id+"-"+kind);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(132,140);column.add_child(icon)
			column.add_child(game.hud.label(game.rules.loot_by_id[id+"-"+kind].name,14));column.add_child(game.hud.label(kind.capitalize(),12))
	checks.mobility_capture=await capture(game,"mobility")
	game.damage_sources.clear();game.update.run_damage=0;enemy.hp=10;enemy.maxHp=10
	game.hurt_enemy(enemy,50,"hit","gun")
	checks.credited_not_overkill=is_equal_approx(game.damage_sources.get("gun",0),10) and is_equal_approx(game.update.run_damage,10)
	checks.kill_types=game.kill_types.values().reduce(func(a,b):return a+b,0)==game.kills
	game.elapsed=120;game.gold=55;game.record_run(false)
	var loaded=CareerProfile.new(game.rules.data,true)
	checks.persisted=loaded.data.scores.any(func(r):return r.id==game.run_id and r.get("damageSources",{}).get("gun",0)==10 and not r.get("killTypes",{}).is_empty())
	game.hud.run_report_menu();checks.recap_capture=await capture(game,"recap")
	print("PROGRESSION_REVIEW "+JSON.stringify({"checks":checks,"jump_rolls":jumps,"rolls":12000}));game.get_tree().quit(0 if checks.values().all(func(v):return v) else 1)

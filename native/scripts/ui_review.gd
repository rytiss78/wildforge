extends RefCounted

static func capture(game, name: String) -> bool:
	for frame in range(4): await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path="user://ui-"+name+".png"
	var error=game.get_viewport().get_texture().get_image().save_png(path)
	print("UI_CAPTURE "+name+" "+str(error))
	return error==OK

static func run(game):
	if DisplayServer.get_name()=="headless": game.get_tree().quit(1);return
	AudioServer.set_bus_volume_db(0,-80)
	game.set_physics_process(false)
	var okay=await capture(game,"menu")
	var about=game.hud.menu_controls().filter(func(c):return c is Button and c.text=="About Wildforge")[0]
	about.pressed.emit();okay=await capture(game,"about") and okay
	game.hud.menu_controls().filter(func(c):return c is Button and c.text=="BACK")[0].pressed.emit()
	game.hud.menu_controls().filter(func(c):return c is Button and c.text=="About Wildforge")[0].pressed.emit()
	game.hud.menu_controls().filter(func(c):return c is Button and c.text=="BACK")[0].pressed.emit()
	await game.get_tree().process_frame
	game.hud.coop_menu()
	okay=game.hud.lobby_ready.disabled and game.hud.lobby_start.disabled and okay
	game.coop.host_lan();game.hud.update_lobby_controls()
	okay=not game.hud.lobby_ready.disabled and game.hud.lobby_start.disabled and okay
	game.hud.lobby_ready.grab_focus();game.hud.controller_accept();game.hud.update_lobby_controls()
	okay=game.coop.local_ready and not game.hud.lobby_start.disabled and okay
	okay=await capture(game,"coop") and okay
	var coop_hero=game.hud.menu_controls().filter(func(c):return c is Button and c.text=="Tank Potato")[0]
	coop_hero.pressed.emit()
	for frame in range(4): await game.get_tree().process_frame
	okay=is_instance_valid(game.hud.portrait) and game.hud.portrait.is_inside_tree() and game.hero.name=="Tank Potato" and okay
	okay=game.hud.lobby_specialty.text.contains(game.hero.description) and okay
	game.hud.update_lobby_controls()
	okay=not game.coop.local_ready and game.hud.lobby_start.disabled and okay
	okay=await capture(game,"coop") and okay
	game.coop.leave()
	game.hud.start_menu()
	var original_hero=game.hero
	var hero_button=game.hud.menu_controls().filter(func(c):return c is Button and c.text=="Tank Potato")[0]
	hero_button.grab_focus();game.hud.controller_accept()
	for frame in range(4): await game.get_tree().process_frame
	okay=game.get_viewport().gui_get_focus_owner().text=="Tank Potato" and game.hero.name=="Tank Potato" and okay
	okay=await capture(game,"hero") and okay
	game.select_hero(game.rules.data.heroes.filter(func(h):return h.weapon=="ice")[0]);game.hud.start_menu()
	okay=await capture(game,"ice-match") and okay
	game.select_hero(original_hero)
	game.start_run(407);game.set_physics_process(false);game.spawn_clock=99999
	game.player.position=Vector3(0,.2,0);game.camera.position=Vector3(0,10,15)
	game.camera.look_at(Vector3(0,0,-5));game.gold=75;game.hp=game.stats.maxHp*.7
	game.hud.update(0)
	okay=await capture(game,"hud") and okay
	game.hud.build_menu();okay=await capture(game,"build") and okay;game.hud.close()
	for kind in ["speed","xp","stone","fire"]: game.activate_consumable(kind)
	game.hud.update(0)
	okay=await capture(game,"potions") and okay
	var saved_equipped=game.equipped
	var flowers=ContentExpansion.weapon("flowers").duplicate(true);flowers.rank=1;flowers.power=1
	game.equipped=[flowers];game.buffs={"hands":25.0,"lucky":25.0,"bite":25.0};game.hud.update(0)
	okay=await capture(game,"buff-compatibility") and game.hud.buff_widgets.hands.text.contains("No benefit") and game.hud.buff_widgets.bite.text.contains("Active") and okay
	game.equipped=saved_equipped
	game.buffs.clear();game.hud.update(0)
	game.make_chest(Vector3(1,game.world.height_at(1,0),0),false)
	game.gold=1000;game.camera.position=Vector3(5,4,6);game.camera.look_at(Vector3(1,.7,0))
	game.buy_chest(game.chests[-1])
	await game.get_tree().create_timer(.35).timeout
	okay=await capture(game,"chest-opening") and okay
	game.reveal_clock=.8+(game.reveal_duration-.8)*.72
	okay=await capture(game,"chest-reels") and okay
	game.finish_reveal();game.hud.close()
	var offers=[]
	for pair in [["jump-boots-item",0],["augment-air-damage",1],["augment-dash-rate",2],["jump-boots-skill",3],["augment-kill-speed",1]]:
		var item=game.rules.loot_by_id[pair[0]].duplicate(true)
		item.tier=pair[1];item.strength=[1.0,2.0,3.5,5.5][pair[1]]
		for effect in item.effects: effect.amount*=item.strength
		offers.append(item)
	game.offers=offers;game.mode="offer";game.offer_kind="item";game.offer_source="level"
	game.hud.show_offers(offers,"level",false)
	okay=await capture(game,"offers") and okay
	for card in game.hud.cards:
		var icons=card.find_children("*","PowerIcon",true,false)
		okay=icons.size()==1 and icons[0].is_visible_in_tree() and icons[0].size.x>0 and okay
	game.hud.controller_move(Vector2.RIGHT)
	okay=game.hud.cards[1].has_focus() and game.update.focused_offer==1 and okay
	okay=await capture(game,"focus") and okay
	var fit_offers=[]
	for key in ["turretDamage","flowerHeal","damage","pierce","augment-air-rate"]:
		var item=game.rules.data.loot.filter(func(entry):return entry.effects[0].key==key)[0].duplicate(true)
		item.name=item.title;item.tier=0;item.strength=1;fit_offers.append(item)
	game.offers=fit_offers;game.hud.show_offers(fit_offers,"level",false)
	okay=await capture(game,"compatibility") and okay
	okay=game.hud.cards[0].find_child("LoadoutBenefit",true,false).text.contains("NO CURRENT BENEFIT") and game.hud.cards[2].find_child("LoadoutBenefit",true,false).text.contains("WORKS WITH") and okay
	var weapons=[]
	for id in ["flame","popcorn-repeater","gravity","horn","lightning"]:
		var item=game.rules.data.weapons.filter(func(w):return w.id==id)[0].duplicate(true)
		item.kind="weapon";item.tier=2;item.strength=3.5;weapons.append(item)
	game.offers=weapons;game.hud.show_offers(weapons,"chest",false)
	okay=await capture(game,"weapons") and game.hud.offer_layout_fits() and okay
	var gallery=game.hud.open("POTION ICON REVIEW","Bottle colors match world pickups; badges show the effect")
	var grid=GridContainer.new();grid.columns=7;gallery.add_child(grid)
	for kind in PotionBook.TYPES:
		var column=VBoxContainer.new();column.custom_minimum_size=Vector2(126,166);grid.add_child(column)
		var icon=TextureRect.new();icon.texture=load("res://assets/illustrated/potions/"+str(kind)+".svg");icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(112,112);column.add_child(icon)
		column.add_child(game.hud.label(PotionBook.TYPES[kind].name,14))
	okay=await capture(game,"potion-icons") and okay
	game.hud.pause_menu();okay=await capture(game,"pause") and okay
	game.hud.pause_menu(true);okay=await capture(game,"ended") and okay
	game.hud.close();game.hud._ach_note_queue.clear();game.hud._ach_note_active=false
	game.set_process(false)
	var saved_camera=game.camera.transform;var saved_player=game.player.position
	for biome in range(6):
		var harvest=game.harvestables.filter(func(h):return h.biome==biome)[0]
		game.world.ensure_ground(harvest.node.position)
		game.player.position=harvest.node.position+Vector3(1.4,.2,0);game.current_biome=biome
		for chunk in range(25): game.world.stream(game.player.position)
		game.camera.position=harvest.node.position+Vector3(2.6,2.4,3.2);game.camera.look_at(harvest.node.position+Vector3.UP*.65)
		game.hud.update(0)
		okay=await capture(game,"harvest-"+str(biome)) and game.hud.prompt.text.contains(harvest.type.name) and okay
	game.camera.transform=saved_camera;game.player.position=saved_player;game.current_biome=game.world.biome_at(game.player.position)
	game.world.ensure_ground(game.player.position)
	for chunk in range(25): game.world.stream(game.player.position)
	game.harvest_buffs={1:18.0,4:14.0};game.hud.update(0)
	okay=await capture(game,"harvest-buffs") and okay
	game.harvest_buffs.clear();game.damage_numbers.clear()
	for i in range(4):
		game.record_damage_number(10000+i,[42,128,12,85][i],["melee","crit","heal","fire"][i],game.player.position+Vector3((i-1.5)*1.1,1.5,0))
	game.hud.update(.2)
	okay=await capture(game,"damage-text") and okay
	game.damage_numbers.clear()
	game.career.on_unlock.call(game.career.achievements[0]);game.hud.update(.1)
	okay=await capture(game,"achievement-icon") and okay
	okay=game.hud._ach_note_panel.size.x<120 and game.hud._ach_note_text.modulate.a==0 and okay
	game.hud.update(.8)
	okay=await capture(game,"achievement") and okay
	var banner=game.hud._ach_note_panel
	okay=banner.visible and banner.size.x==640 and game.hud._ach_note_text.modulate.a==1 and game.get_viewport().get_visible_rect().encloses(banner.get_global_rect()) and okay
	var chime=game.sound.achievement_voice.stream as AudioStreamWAV
	okay=chime!=null and chime.resource_path.is_empty() and okay
	if not OS.has_feature("editor"):
		okay=not ResourceLoader.exists("res://assets/audio/local/xbox360-achievement.mp3") and okay
	if chime!=null:
		okay=chime.save_to_wav("user://achievement-modern.wav")==OK and okay
		print("ACHIEVEMENT_SOUND: original-synth length="+str(chime.get_length()))
	print("UI_REVIEW_SAVED: "+("OK" if okay else "FAILED"))
	game.get_tree().quit(0 if okay else 1)

extends RefCounted

static func expect(value: bool,label: String) -> bool:
	if not value: print("UI_ASSERT_FAILED: "+label)
	return value

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
	var version=game.hud.modal.find_child("ReleaseVersion",true,false)
	okay=expect(version!=null and version.text.contains(str(ProjectSettings.get_setting("application/config/version"))) and version.text.contains("BUILD "+str(ProjectSettings.get_setting("application/config/build_number"))),"main menu version/build metadata") and okay
	okay=expect(version!=null and game.get_viewport().get_visible_rect().encloses(version.get_global_rect()),"version label within viewport") and okay
	var about=game.hud.menu_controls().filter(func(c):return c is Button and c.text=="About Wildforge")[0]
	about.pressed.emit();okay=expect(await capture(game,"about"),"ui assertion 17") and okay
	game.hud.menu_controls().filter(func(c):return c is Button and c.text=="BACK")[0].pressed.emit()
	game.hud.menu_controls().filter(func(c):return c is Button and c.text=="About Wildforge")[0].pressed.emit()
	game.hud.menu_controls().filter(func(c):return c is Button and c.text=="BACK")[0].pressed.emit()
	await game.get_tree().process_frame
	game.hud.coop_menu()
	okay=expect(game.hud.lobby_ready.disabled and game.hud.lobby_start.disabled,"ui assertion 23") and okay
	game.coop.host_lan();game.hud.update_lobby_controls()
	okay=expect(not game.hud.lobby_ready.disabled and game.hud.lobby_start.disabled,"ui assertion 25") and okay
	game.hud.lobby_ready.grab_focus();game.hud.controller_accept();game.hud.update_lobby_controls()
	okay=expect(game.coop.local_ready and not game.hud.lobby_start.disabled,"ui assertion 27") and okay
	okay=expect(await capture(game,"coop"),"ui assertion 28") and okay
	var coop_hero=game.hud.menu_controls().filter(func(c):return c is Button and c.text=="Tank Potato")[0]
	coop_hero.pressed.emit()
	for frame in range(4): await game.get_tree().process_frame
	okay=expect(is_instance_valid(game.hud.portrait) and game.hud.portrait.is_inside_tree() and game.hero.name=="Tank Potato","ui assertion 32") and okay
	okay=expect(game.hud.lobby_specialty.text.contains(game.hero.description),"ui assertion 33") and okay
	game.hud.update_lobby_controls()
	okay=expect(not game.coop.local_ready and game.hud.lobby_start.disabled,"ui assertion 35") and okay
	okay=expect(await capture(game,"coop"),"ui assertion 36") and okay
	game.coop.leave()
	game.hud.start_menu()
	var original_hero=game.hero
	var hero_button=game.hud.menu_controls().filter(func(c):return c is Button and c.text=="Tank Potato")[0]
	hero_button.grab_focus();game.hud.controller_accept()
	for frame in range(4): await game.get_tree().process_frame
	okay=expect(game.get_viewport().gui_get_focus_owner().text=="Tank Potato" and game.hero.name=="Tank Potato","ui assertion 43") and okay
	okay=expect(await capture(game,"hero"),"ui assertion 44") and okay
	game.select_hero(game.rules.data.heroes.filter(func(h):return h.weapon=="ice")[0]);game.hud.start_menu()
	okay=expect(await capture(game,"ice-match"),"ui assertion 46") and okay
	game.select_hero(original_hero)
	game.start_run(407);game.set_physics_process(false);game.spawn_clock=99999
	game.player.position=Vector3(0,.2,0);game.camera.position=Vector3(0,10,15)
	game.camera.look_at(Vector3(0,0,-5));game.gold=75;game.hp=game.stats.maxHp*.7
	game.hud.update(0)
	okay=expect(await capture(game,"hud"),"ui assertion 52") and okay
	game.hud.build_menu();okay=await capture(game,"build") and okay;game.hud.close()
	for kind in ["speed","xp","stone","fire"]: game.activate_consumable(kind)
	game.hud.update(0)
	okay=expect(await capture(game,"potions"),"ui assertion 56") and okay
	var saved_equipped=game.equipped
	var flowers=ContentExpansion.weapon("flowers").duplicate(true);flowers.rank=1;flowers.power=1
	game.equipped=[flowers];game.buffs={"hands":25.0,"lucky":25.0,"bite":25.0};game.hud.update(0)
	okay=expect(await capture(game,"buff-compatibility") and game.hud.buff_widgets.hands.text.contains("No benefit") and game.hud.buff_widgets.bite.text.contains("Active"),"ui assertion 60") and okay
	game.equipped=saved_equipped
	game.buffs.clear();game.hud.update(0)
	game.make_chest(Vector3(1,game.world.height_at(1,0),0),false)
	game.gold=1000;game.camera.position=Vector3(5,4,6);game.camera.look_at(Vector3(1,.7,0))
	game.buy_chest(game.chests[-1])
	await game.get_tree().create_timer(.35).timeout
	okay=expect(await capture(game,"chest-opening"),"ui assertion 67") and okay
	game.reveal_clock=.8+(game.reveal_duration-.8)*.72
	okay=expect(await capture(game,"chest-reels"),"ui assertion 69") and okay
	game.finish_reveal();game.hud.close()
	var offers=[]
	for pair in [["jump-boots-item",0],["augment-air-damage",1],["augment-dash-rate",2],["jump-boots-skill",3],["augment-kill-speed",1]]:
		var item=game.rules.loot_by_id[pair[0]].duplicate(true)
		item.tier=pair[1];item.strength=[1.0,2.0,3.5,5.5][pair[1]]
		for effect in item.effects: effect.amount*=item.strength
		offers.append(item)
	game.offers=offers;game.mode="offer";game.offer_kind="item";game.offer_source="level"
	game.hud.show_offers(offers,"level",false)
	okay=expect(await capture(game,"offers"),"ui assertion 79") and okay
	for card in game.hud.cards:
		var icons=card.find_children("*","PowerIcon",true,false)
		okay=expect(icons.size()==1 and icons[0].is_visible_in_tree() and icons[0].size.x>0,"ui assertion 82") and okay
	game.hud.controller_move(Vector2.RIGHT)
	okay=expect(game.hud.cards[1].has_focus() and game.update.focused_offer==1,"ui assertion 84") and okay
	okay=expect(await capture(game,"focus"),"ui assertion 85") and okay
	var fit_offers=[]
	for key in ["turretDamage","flowerHeal","damage","pierce","augment-air-rate"]:
		var item=game.rules.data.loot.filter(func(entry):return entry.effects[0].key==key)[0].duplicate(true)
		item.name=item.title;item.tier=0;item.strength=1;fit_offers.append(item)
	game.offers=fit_offers;game.hud.show_offers(fit_offers,"level",false)
	okay=expect(await capture(game,"compatibility"),"ui assertion 91") and okay
	okay=expect(game.hud.cards[0].find_child("LoadoutBenefit",true,false).text.contains("NO CURRENT BENEFIT") and game.hud.cards[2].find_child("LoadoutBenefit",true,false).text.contains("WORKS WITH"),"ui assertion 92") and okay
	var weapons=[]
	for id in ["flame","popcorn-repeater","gravity","horn","lightning"]:
		var item=game.rules.data.weapons.filter(func(w):return w.id==id)[0].duplicate(true)
		item.kind="weapon";item.tier=2;item.strength=3.5;weapons.append(item)
	game.offers=weapons;game.hud.show_offers(weapons,"chest",false)
	okay=expect(await capture(game,"weapons") and game.hud.offer_layout_fits(),"ui assertion 98") and okay
	var gallery=game.hud.open("POTION ICON REVIEW","Bottle colors match world pickups; badges show the effect")
	var grid=GridContainer.new();grid.columns=7;gallery.add_child(grid)
	for kind in PotionBook.TYPES:
		var column=VBoxContainer.new();column.custom_minimum_size=Vector2(126,166);grid.add_child(column)
		var icon=TextureRect.new();icon.texture=load("res://assets/illustrated/potions/"+str(kind)+".svg");icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(112,112);column.add_child(icon)
		column.add_child(game.hud.label(PotionBook.TYPES[kind].name,14))
	okay=expect(await capture(game,"potion-icons"),"ui assertion 105") and okay
	game.hud.pause_menu();okay=expect(await capture(game,"pause"),"ui assertion 106") and okay
	game.hud.pause_menu(true);okay=expect(await capture(game,"ended"),"ui assertion 107") and okay
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
		okay=expect(await capture(game,"harvest-"+str(biome)) and game.hud.prompt.text.contains(harvest.type.name),"ui assertion 118") and okay
	game.camera.transform=saved_camera;game.player.position=saved_player;game.current_biome=game.world.biome_at(game.player.position)
	game.world.ensure_ground(game.player.position)
	for chunk in range(25): game.world.stream(game.player.position)
	game.harvest_buffs={1:18.0,4:14.0};game.hud.update(0)
	okay=expect(await capture(game,"harvest-buffs"),"ui assertion 123") and okay
	game.harvest_buffs.clear();game.damage_numbers.clear()
	for i in range(4):
		game.record_damage_number(10000+i,[42,128,12,85][i],["melee","crit","heal","fire"][i],game.player.position+Vector3((i-1.5)*1.1,1.5,0))
	game.hud.update(.2)
	okay=expect(await capture(game,"damage-text"),"ui assertion 128") and okay
	game.damage_numbers.clear()
	game.career.on_unlock.call(game.career.achievements[0]);game.hud.update(.1)
	okay=expect(await capture(game,"achievement-icon"),"ui assertion 131") and okay
	okay=expect(game.hud._ach_note_panel.size.x<120 and game.hud._ach_note_text.modulate.a==0,"ui assertion 132") and okay
	game.hud.update(.8)
	okay=expect(await capture(game,"achievement"),"ui assertion 134") and okay
	var banner=game.hud._ach_note_panel
	okay=expect(banner.visible and banner.size.x==640 and game.hud._ach_note_text.modulate.a==1 and game.get_viewport().get_visible_rect().encloses(banner.get_global_rect()),"ui assertion 136") and okay
	var chime=game.sound.achievement_voice.stream as AudioStreamWAV
	okay=expect(chime!=null and chime.resource_path.is_empty(),"ui assertion 138") and okay
	if not OS.has_feature("editor"):
		okay=expect(not ResourceLoader.exists("res://assets/audio/local/xbox360-achievement.mp3"),"ui assertion 140") and okay
	if chime!=null:
		okay=expect(chime.save_to_wav("user://achievement-modern.wav")==OK,"ui assertion 142") and okay
		print("ACHIEVEMENT_SOUND: original-synth length="+str(chime.get_length()))
	print("UI_REVIEW_SAVED: "+("OK" if okay else "FAILED"))
	game.get_tree().quit(0 if okay else 1)

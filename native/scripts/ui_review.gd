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

static func seed_party_options(game, options: Array, source: String):
	game.party_seen.clear()
	for player_id in range(1,5):
		var player_options=[]
		for offset in range(options.size()):
			var item=options[(offset+player_id)%options.size()]
			player_options.append({"id":str(item.id),"name":str(item.name)})
		game.party_seen[str(player_id)]={"player_id":player_id,"name":"Review Player "+str(player_id),"reward_id":game.party_reward_id,"source":source,"options":player_options,"selected_id":str(player_options[1].id),"selected_name":str(player_options[1].name)}

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
	game.hud.coop_name_input.text="UI Host";game.hud.coop_name_input.text_submitted.emit("UI Host")
	okay=expect(game.career.data.settings.name=="UI Host","co-op player name saves from the lobby field") and okay
	okay=expect(not game.hud.lobby_ready.disabled and game.hud.lobby_start.disabled,"ui assertion 25") and okay
	game.hud.lobby_ready.grab_focus();game.hud.controller_accept();game.hud.update_lobby_controls()
	okay=expect(game.coop.local_ready and not game.hud.lobby_start.disabled,"ui assertion 27") and okay
	okay=expect(await capture(game,"coop"),"ui assertion 28") and okay
	var coop_hero=game.hud.menu_controls().filter(func(c):return c is Button and c.text=="Tank Potato")[0]
	coop_hero.pressed.emit()
	for frame in range(4): await game.get_tree().process_frame
	okay=expect(game.hud.coop_name_input.text=="UI Host","co-op name remains when rebuilding the lobby menu") and okay
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
	okay=expect(game.coop.local_nameplate==null,"solo runs do not show a co-op nameplate") and okay
	game.career.data.settings.name="UI Runner";game.coop.active=true;game.coop.sync_local_nameplate()
	okay=expect(is_instance_valid(game.coop.local_nameplate) and game.coop.local_nameplate.text=="UI Runner","co-op nameplate shows the custom player name") and okay
	okay=expect(await capture(game,"coop-nameplate"),"co-op nameplate capture") and okay
	game.events.boss_focus_id=game.coop.local_id;game.events.boss_focus_until=game.elapsed+4.0;game.coop.sync_local_nameplate()
	game.hud.tell("BARON MARKS UI RUNNER · MOVE",4)
	okay=expect(game.coop.local_nameplate.text.contains("TARGET"),"co-op Baron focus is marked above the targeted hero") and okay
	okay=expect(await capture(game,"coop-boss-target"),"co-op boss target cue capture") and okay
	game.events.erase("boss_focus_id");game.events.erase("boss_focus_until")
	game.career.data.cosmetics=["mastery_crown","party_banner"];game.career.data.settings.cosmetic="party_banner";game.coop.sync_local_nameplate()
	okay=expect(game.coop.local_nameplate.text=="⚑ UI Runner" and game.coop.local_nameplate.modulate==Color("b6d6ff"),"achievement-earned cosmetic style applies to the co-op nameplate") and okay
	okay=expect(await capture(game,"achievement-nameplate-style"),"achievement nameplate cosmetic capture") and okay
	game.coop.members[2]={"name":"Review Guest","build":{"weapons":[{"id":"gun","rank":2}],"skills":["Ice Shield"]}}
	game.hud.party_builds_menu()
	okay=expect(game.career.data.total.get("party_builds_viewed",0)>=1 and game.hud.modal.find_children("*","Label",true,false).any(func(node):return node.text.contains("Review Guest")),"complete teammate build view awards its achievement") and okay
	okay=expect(await capture(game,"party-builds"),"shared party-build capture") and okay
	game.hud.close();game.coop.members.clear()
	game.hud.settings_menu()
	var cosmetic_picker=game.hud.achievement_cosmetic_picker
	okay=expect(is_instance_valid(cosmetic_picker) and cosmetic_picker.item_count>=3 and str(cosmetic_picker.get_item_metadata(cosmetic_picker.selected))=="party_banner","settings menu selects an earned cosmetic") and okay
	okay=expect(await capture(game,"achievement-cosmetics"),"achievement cosmetics settings capture") and okay
	game.hud.close();game.career.data.settings.cosmetic="";game.coop.sync_local_nameplate()
	game.coop.active=false;game.coop.sync_local_nameplate()
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
	game.coop.active=true;game.coop.hosting=true;game.coop.local_id=1;game.party_reward_id="ui-review-level"
	game.hud.show_offers(offers,"level",false)
	seed_party_options(game,offers,"level")
	game.coop.publish_reward_choice(offers[2],"level")
	okay=expect(await capture(game,"coop-level-options"),"co-op level options capture") and okay
	okay=expect(game.hud.party_overlay.visible and game.hud.party_overlay.get_global_rect().position.x>game.hud.content.get_parent().get_global_rect().end.x,"co-op teammate panel sits beside choices") and okay
	game.coop.publish_reward_skip("level")
	okay=expect(await capture(game,"coop-level-skip"),"co-op skip highlight capture") and okay
	okay=expect(game.hud.party_overlay.find_children("*","Label",true,false).any(func(node):return node.text=="✓  Kept weapons"),"co-op skip choice is highlighted") and okay
	# Teammate picks that arrive after this player chose must not reopen the
	# panel over gameplay or over another full-width screen.
	game.hud.cards[0].pressed.emit()
	okay=expect(game.mode=="playing" and not game.hud.modal.visible,"co-op choice closes the reward screen") and okay
	game.coop.apply_reward_choice(3,game.party_reward_id,str(offers[1].id),str(offers[1].name),"level","Review Player 3")
	game.hud.update(0)
	okay=expect(await capture(game,"coop-after-choice"),"co-op after-choice capture") and okay
	okay=expect(not game.hud.party_overlay.visible,"team panel stays hidden after this player chose") and okay
	game.hud.pause_menu()
	game.coop.apply_reward_choice(4,game.party_reward_id,str(offers[2].id),str(offers[2].name),"level","Review Player 4")
	game.hud.update(0)
	okay=expect(await capture(game,"coop-pause-after-choice"),"co-op pause capture") and okay
	okay=expect(not game.hud.party_overlay.visible,"team panel never covers the pause menu") and okay
	game.hud.close()
	game.coop.active=false;game.coop.hosting=false;game.hud.party_overlay.visible=false;game.hud.close()
	game.coop.active=true;game.coop.hosting=true;game.coop.local_id=1;game.party_reward_id="ui-review-chest"
	game.hud.show_offers(offers,"chest",false)
	seed_party_options(game,offers,"chest")
	game.coop.publish_reward_choice(offers[3],"chest")
	okay=expect(await capture(game,"coop-chest-options"),"co-op chest options capture") and okay
	game.coop.active=false;game.coop.hosting=false;game.hud.party_overlay.visible=false;game.hud.close()
	game.coop.leave()
	game.mode="offer";game.offer_kind="item";game.offer_source="level"
	game.hud.show_offers(offers,"level",false)
	okay=expect(await capture(game,"offers"),"ui assertion 79") and okay
	for card in game.hud.cards:
		var icons=card.find_children("*","PowerIcon",true,false)
		okay=expect(icons.size()==1 and icons[0].is_visible_in_tree() and icons[0].size.x>0,"ui assertion 82") and okay
	game.hud.controller_move(Vector2.RIGHT)
	okay=expect(game.hud.cards[1].has_focus() and game.update.focused_offer==1,"ui assertion 84") and okay
	# Mutation cards: one per group, each with a drawn strain medallion.
	for id in ["ember_dash","frost_kill"]: game.mutations[id]=1
	var mutation_cards=[MutationBook.card("storm_crit",1),MutationBook.card("ember_dash",2),MutationBook.card("frost_shatter",1),MutationBook.card("hy_thermal",1),MutationBook.card("wild_echo",1)]
	game.offers=mutation_cards;game.mode="offer";game.offer_kind="skill";game.offer_source="level"
	game.hud.show_offers(mutation_cards,"level",false)
	okay=expect(await capture(game,"mutation-offers"),"mutation offer capture") and okay
	okay=expect(game.hud.cards.size()==5 and game.hud.cards.all(func(card):return card.find_children("*","PowerIcon",true,false).size()==1),"mutation cards carry icons") and okay
	game.hud.cards[1].pressed.emit()
	okay=expect(game.mutations.get("ember_dash",0)==2 and game.mode=="playing","mutation card choice levels the mutation") and okay
	game.hud.update(0)
	okay=expect(await capture(game,"mutation-hud"),"mutation HUD capture") and okay
	game.mutations.clear();game.owned=game.owned.filter(func(item):return item.kind!="mutation")
	# Weapon evolution: a chest offer led by the gold EVOLVE card, then the evolved
	# weapon's gilded slot, held halo and shots in play.
	var evolving=game.equipped[0];evolving.rank=WeaponEvolution.RANK
	var catalyst=WeaponEvolution.form(evolving.id).catalyst
	game.owned=game.owned.filter(func(i):return not (i.effects[0].key==catalyst or game.rules.data.augments.has(i.effects[0].key) and game.rules.data.augments[i.effects[0].key].stat==catalyst))
	var key_offers=WeaponEvolution.inject(game,game.rules.offers("item",0,false,game.stats,game.equipped),"chest")
	game.offers=key_offers;game.mode="offer";game.offer_kind="item";game.offer_source="chest"
	game.hud.show_offers(key_offers,"chest",false);game.hud.cards[-1].grab_focus()
	okay=expect(await capture(game,"evolution-key"),"evolution key capture") and okay
	okay=expect(key_offers[-1].has("catalyst_for"),"a full-rank weapon without its catalyst is offered the key card") and okay
	game.hud.close()
	game.owned.append(game.rules.data.loot.filter(func(i):return i.effects[0].key==catalyst or game.rules.data.augments.has(i.effects[0].key) and game.rules.data.augments[i.effects[0].key].stat==catalyst)[0].duplicate(true))
	var evolution_offers=WeaponEvolution.inject(game,game.rules.offers("item",0,false,game.stats,game.equipped),"chest")
	game.offers=evolution_offers;game.mode="offer";game.offer_kind="item";game.offer_source="chest"
	game.hud.show_offers(evolution_offers,"chest",false)
	okay=expect(await capture(game,"evolution-offer"),"evolution offer capture") and okay
	okay=expect(evolution_offers[0].kind=="evolution" and game.hud.cards[0].find_children("*","PowerIcon",true,false).size()==1,"evolution card leads the chest offer with the weapon icon") and okay
	game.hud.cards[0].pressed.emit()
	okay=expect(evolving.get("evolved",false) and game.mode=="playing","evolution card evolves the weapon") and okay
	for i in range(4):
		game.spawn_enemy(8);game.enemies[-1].node.position=game.player.position+Vector3(-3+i*2,0,-7-i)
	for volley in range(3):
		game.fire(evolving,game.player.position+Vector3.UP)
		for frame in range(4): await game.get_tree().process_frame
	game.hud.update(0)
	okay=expect(await capture(game,"evolution-hud"),"evolved weapon HUD capture") and okay
	# Every upgrade draws a stat medallion; a contact sheet shows one per stat and condition.
	okay=expect(game.rules.data.loot.all(func(item):return not StatGlyphs.resolve(str(item.id)).is_empty()),"every upgrade has a stat medallion") and okay
	var sheet_keys=[];var shown={}
	for item in game.rules.data.loot:
		var info=StatGlyphs.resolve(str(item.id))
		# One card per stat, plus one per condition badge.
		var slot="if:"+info.condition if not info.condition.is_empty() else "stat:"+info.stat
		if shown.has(slot): continue
		shown[slot]=true;sheet_keys.append(item)
	var sheet=game.hud.open("UPGRADE ICON REVIEW","Colour = what it affects · symbol = stat · corner badge = condition")
	var icon_grid=GridContainer.new();icon_grid.columns=14;icon_grid.add_theme_constant_override("h_separation",6);icon_grid.add_theme_constant_override("v_separation",4);sheet.add_child(icon_grid)
	for item in sheet_keys.slice(0,126):
		var cell=VBoxContainer.new();cell.custom_minimum_size=Vector2(118,0);icon_grid.add_child(cell)
		var icon=PowerIcon.new();icon.key=str(item.id);icon.custom_minimum_size=Vector2(64,64);cell.add_child(icon)
		var caption=game.hud.label(str(item.name).left(16),10);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;cell.add_child(caption)
	okay=expect(await capture(game,"upgrade-icons"),"upgrade icon sheet capture") and okay
	game.hud.close()
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
	# Twelve non-weapon numbers: they should spread across the whole screen width.
	for i in range(12):
		game.record_damage_number(10000+i,[42,128,12,85,31,66,240,18,57,9,144,73][i],["melee","crit","heal","fire","poison","explosion","crit","ice","lightning","heal","slam","sonic"][i],game.player.position+Vector3((i-5.5)*.6,1.5,0))
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

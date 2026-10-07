extends CanvasLayer
class_name RunHUD

var game
var root = Control.new()
var modal = Control.new()
var content: VBoxContainer
var clock = RunClock.new()
var map_view = ExploreMap.new()
var xp: ProgressBar
var xp_text: Label
var coins: Label
var status: Label
var weapons: WeaponBar
var control_hints: HBoxContainer
var hint_device = ""
var turret_hints = HBoxContainer.new()
var prompt: Label
var alert: Label
var toast: Label
var toast_time = 0.0
var blast: ColorRect
var blast_time = 0.0
var cards = []
var buff_icons: HBoxContainer
var buff_widgets={}
var buff_label: Label
var biome_label: Label
var level_plate: Label
var offer_detail: VBoxContainer
var menu_start: Button
var ink=ThemeTokens.INK_RUNTIME
var paper=ThemeTokens.PAPER_RUNTIME
var box_counter: Label
var party_label: Label
var party_list: VBoxContainer
var party_list_key=""
var offer_tween: Tween
var preview_id=""
var health_text: Label
var health_bar: ProgressBar
var hints_until=25.0
var player_locator: Control
var journey_overlay: Control

func menu_controls(node: Node=modal) -> Array:
	var result=[]
	for child in node.get_children():
		if child.is_queued_for_deletion(): continue
		if child is Control and child.is_visible_in_tree() and child.focus_mode!=Control.FOCUS_NONE and (child is BaseButton or child is Range or child is LineEdit or child is TextEdit):
			if not (child is BaseButton and child.disabled): result.append(child)
		result.append_array(menu_controls(child))
	return result

func controller_move(direction: Vector2):
	var controls=menu_controls()
	if controls.is_empty(): return
	var focused=get_viewport().gui_get_focus_owner()
	if focused==null or not controls.has(focused): controls[0].grab_focus();return
	if focused is Range and direction.x!=0:
		focused.value+=direction.x*maxf(focused.step,(focused.max_value-focused.min_value)/20);return
	var origin=focused.get_global_rect().get_center()
	var next=null;var score=INF
	for control in controls:
		if control==focused: continue
		var offset=control.get_global_rect().get_center()-origin
		var forward=offset.dot(direction)
		if forward<=1: continue
		var cross=absf(offset.cross(direction))
		var candidate=forward+cross*4
		if candidate<score: score=candidate;next=control
	if next!=null:
		next.grab_focus()
		var ancestor=next.get_parent()
		while ancestor!=null:
			if ancestor is ScrollContainer: ancestor.ensure_control_visible(next);break
			ancestor=ancestor.get_parent()

func controller_accept():
	var focused=get_viewport().gui_get_focus_owner()
	var controls=menu_controls()
	if focused==null or not controls.has(focused):
		if controls.is_empty(): return
		focused=controls[0];focused.grab_focus()
	if focused is BaseButton and not focused.disabled:
		if focused.toggle_mode: focused.set_pressed(not focused.button_pressed)
		focused.pressed.emit()

func label(text: String, font_size: int = 18, color: Color = ThemeTokens.INK_RUNTIME) -> Label:
	var item = Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size",font_size)
	item.add_theme_color_override("font_color",color.lerp(ink,.65) if color.get_luminance()>.45 else color)
	item.add_theme_color_override("font_outline_color",ThemeTokens.INK_RUNTIME)
	item.add_theme_constant_override("outline_size",0)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item

func style(color: Color = ThemeTokens.PAPER_RUNTIME, border: Color = Color("a99070"), radius: int = 3) -> StyleBoxFlat:
	var box=StyleBoxFlat.new()
	# Every UI surface is opaque; only the surface colour conveys selection.
	box.bg_color=Color(color.r,color.g,color.b,1)
	box.border_color=Color(border.r,border.g,border.b,1) if border.a>.7 else Color("b9a58a")
	box.set_border_width_all(1)
	box.border_width_bottom=2
	box.shadow_color=ThemeTokens.SHADOW.color;box.shadow_size=ThemeTokens.SHADOW.size;box.shadow_offset=ThemeTokens.SHADOW.offset
	box.set_corner_radius_all(radius)
	box.content_margin_left=ThemeTokens.MARGINS.left
	box.content_margin_right=ThemeTokens.MARGINS.right
	box.content_margin_top=ThemeTokens.MARGINS.top
	box.content_margin_bottom=ThemeTokens.MARGINS.bottom
	return box

func button(text: String, action: Callable, accent: bool = false, radius_key: String = "small") -> Button:
	var item=Button.new()
	item.text=text
	item.custom_minimum_size.y=32
	item.add_theme_font_size_override("font_size",16)
	var bg = Color("e3ba86") if accent else paper
	var r = ThemeTokens.RADIUS[radius_key] if radius_key in ThemeTokens.RADIUS else ThemeTokens.RADIUS.small
	item.add_theme_stylebox_override("normal",style(bg,Color("c8d9c23c"),r))
	item.add_theme_stylebox_override("hover",style(Color("efd3a7"),Color("977657"),r))
	item.add_theme_stylebox_override("pressed",style(Color("dcb48a"),Color("70543b"),r))
	var focus=StyleBoxFlat.new();focus.bg_color=Color.TRANSPARENT;focus.border_color=ThemeTokens.INK;focus.set_border_width_all(3);focus.set_corner_radius_all(r)
	item.add_theme_stylebox_override("focus",focus)
	item.add_theme_color_override("font_color",ink)
	item.add_theme_color_override("font_hover_color",ink)
	item.add_theme_color_override("font_focus_color",ink)
	item.add_theme_color_override("font_pressed_color",ink)
	item.pressed.connect(action)
	return item

func setup(owner_game):
	game = owner_game
	player_locator=preload("res://scripts/player_locator.gd").new();player_locator.game=game;player_locator.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(player_locator)
	buff_icons=HBoxContainer.new();buff_icons.position=Vector2(750,685);root.add_child(buff_icons)
	buff_label=label("",14);buff_label.position=Vector2(760,702);root.add_child(buff_label)
	biome_label=label("",16);biome_label.position=Vector2(24,188);root.add_child(biome_label)
	level_plate=label("",30);level_plate.position=Vector2(550,250);root.add_child(level_plate)
	level_plate.add_theme_stylebox_override("normal",style(paper,ThemeTokens.EARTH_TERRACOTTA))
	add_child(root)
	var desktop_theme=Theme.new()
	desktop_theme.default_font_size=16
	for type in ["Button","CheckButton","Label","TextEdit","LineEdit","TooltipLabel"]:
		for state in ["font_color","font_hover_color","font_pressed_color","font_hover_pressed_color","font_focus_color","font_disabled_color"]:
			desktop_theme.set_color(state,type,ink)
	desktop_theme.set_color("font_placeholder_color","TextEdit",Color("8c7861"))
	desktop_theme.set_stylebox("normal","TextEdit",style(paper))
	desktop_theme.set_stylebox("focus","TextEdit",style(paper,Color("b87953")))
	desktop_theme.set_stylebox("panel","TooltipPanel",style(paper))
	root.theme=desktop_theme
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clock.position = Vector2(24,20)
	clock.scale=Vector2.ONE*.75
	clock.size = Vector2(300,112)
	root.add_child(clock)
	var health_panel=PanelContainer.new();health_panel.position=Vector2(24,92);health_panel.custom_minimum_size=Vector2(254,54)
	health_panel.add_theme_stylebox_override("panel",style(paper,Color("8eac93"),10));root.add_child(health_panel)
	var health_column=VBoxContainer.new();health_panel.add_child(health_column)
	health_text=label("",16);health_column.add_child(health_text)
	health_bar=ProgressBar.new();health_bar.custom_minimum_size.y=9;health_bar.show_percentage=false
	health_bar.add_theme_stylebox_override("background",style(Color("d5d9c8"),Color.TRANSPARENT,4))
	health_bar.add_theme_stylebox_override("fill",style(Color("559c78"),Color.TRANSPARENT,4));health_column.add_child(health_bar)
	journey_overlay=preload("res://scripts/journey_hud.gd").new();journey_overlay.game=game;journey_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(journey_overlay)
	map_view.position = Vector2(1180,24)
	map_view.size = Vector2(230,230)
	root.add_child(map_view)
	var header = label("ISLAND MAP",13)
	header.position = Vector2(1244,10)
	root.add_child(header)
	var info = PanelContainer.new()
	info.add_theme_stylebox_override("panel",style())
	info.position = Vector2(24,705)
	info.custom_minimum_size = Vector2(265,49)
	root.add_child(info)
	var info_box = VBoxContainer.new()
	info.add_child(info_box)
	status = label("",14)
	info_box.add_child(status)
	xp_text=label("XP  0 / 41 to next level",12);info_box.add_child(xp_text)
	xp = ProgressBar.new()
	xp.custom_minimum_size.y = 5
	xp.show_percentage = false
	xp.add_theme_stylebox_override("fill",style(Color("a5de9d"),Color.TRANSPARENT,3))
	info_box.add_child(xp)
	coins = label("GOLD  0    BOX PRICE  30",15,ThemeTokens.STAR_GOLD)
	coins.position = Vector2(24,151)
	coins.add_theme_stylebox_override("normal",style())
	root.add_child(coins)
	box_counter=label("",15);box_counter.position=Vector2(24,199);box_counter.add_theme_stylebox_override("normal",style());root.add_child(box_counter)
	weapons = WeaponBar.new()
	weapons.game = game
	weapons.position = Vector2(320,690)
	weapons.add_theme_constant_override("separation",10)
	root.add_child(weapons)
	control_hints = HBoxContainer.new()
	control_hints.position = Vector2(24,775)
	control_hints.add_theme_constant_override("separation",10)
	root.add_child(control_hints)
	turret_hints.position=Vector2(1050,735)
	root.add_child(turret_hints)
	add_prompts(turret_hints,[["T","LB","Place"],["G","RB","Next turret"]])
	prompt = label("",18,ThemeTokens.BIOME_ACCENTS.verdant.petal)
	prompt.position = Vector2(560,650)
	prompt.add_theme_stylebox_override("normal",style())
	root.add_child(prompt)
	alert = label("",21,ThemeTokens.EARTH_TERRACOTTA)
	alert.position = Vector2(460,30)
	alert.add_theme_stylebox_override("normal",style())
	root.add_child(alert)
	toast = label("",16,ThemeTokens.BIOME_ACCENTS.verdant.leaf)
	toast.position = Vector2(440,540)
	toast.add_theme_stylebox_override("normal",style())
	root.add_child(toast)
	blast = ColorRect.new()
	blast.color = Color(1,.8,.3,0)
	blast.visible=false
	blast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(blast)
	blast.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.visible = false

func open(title: String, subtitle: String = "") -> VBoxContainer:
	if offer_tween!=null and offer_tween.is_valid(): offer_tween.kill()
	preview_id=""
	for child in modal.get_children(): child.queue_free()
	modal.visible = true
	var panel = PanelContainer.new()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.position = Vector2(220,80)
	panel.size = Vector2(1000,640)
	var shade=ColorRect.new();shade.color=Color(.025,.05,.08,.72);modal.add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel",style(paper,Color("a99070"),22))
	modal.add_child(panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation",10)
	panel.add_child(content)
	var heading = label(title,28)
	content.add_child(heading)
	content.add_child(label(subtitle,17,ThemeTokens.BIOME_ACCENTS.verdant.pine))
	cards.clear()
	return content

func close():
	if offer_tween!=null and offer_tween.is_valid(): offer_tween.kill()
	modal.visible = false
	game.mode = "playing"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if not game.smoke else Input.MOUSE_MODE_VISIBLE

func tell(text: String, duration: float = 3.0):
	toast.text = text
	toast_time = duration

func level_flash():
	blast_time = .65
	game.sound.effect("level")

func update(delta: float):
	player_locator.queue_redraw()
	journey_overlay.queue_redraw()
	for widget in root.get_children():
		if widget is CanvasItem and widget!=modal and widget!=blast: widget.visible=not modal.visible
	level_plate.visible=game.mode=="level_reveal"
	level_plate.text="LEVEL %d  ·  NEW POWER!" % game.level
	biome_label.text=RealmWorld.BIOMES[game.current_biome]
	if is_instance_valid(party_label): party_label.text=game.coop.status
	if game.mode=="coop" and is_instance_valid(party_list): update_party_list()
	var active_buffs=[]
	for key in game.buffs:
		active_buffs.append("%s  %ds" % [PotionBook.TYPES[key].name,ceil(game.buffs[key])])
	buff_label.text=""
	for key in buff_widgets.keys():
		if not game.buffs.has(key): buff_widgets[key].get_parent().get_parent().queue_free();buff_widgets.erase(key)
	for key in game.buffs:
		if not buff_widgets.has(key):
			var panel=PanelContainer.new();panel.add_theme_stylebox_override("panel",style());buff_icons.add_child(panel)
			var column=VBoxContainer.new();panel.add_child(column)
			var icon=TextureRect.new();icon.texture=load("res://assets/illustrated/potions/"+str(key)+".svg");icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(40,40);column.add_child(icon)
			var timer=label("",12);timer.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(timer);buff_widgets[key]=timer
		buff_widgets[key].text="%s\n%ds" % [PotionBook.TYPES[key].name,ceil(game.buffs[key])]
	health_text.text="HP  %d / %d" % [ceili(game.hp),roundi(game.stats.maxHp)]
	if game.shield_hp>0: health_text.text+="   +%d shield" % ceili(game.shield_hp)
	health_bar.max_value=game.stats.maxHp;health_bar.value=game.hp
	health_bar.modulate=Color("ef8c7e") if game.hp/game.stats.maxHp<.3 else Color.WHITE
	clock.seconds = maxf(0,600.0-game.realm_time)
	clock.realm = game.realm
	clock.bosses = game.realm_bosses
	clock.queue_redraw()
	xp.max_value = game.xp_target
	xp.value = game.xp
	status.text = "LEVEL %d   ·   %s" % [game.level,game.hero.name]
	xp_text.text="XP  %d / %d to next level" % [floori(game.xp),game.xp_target]
	coins.text = "%d gold  ·  Chest %d  ·  %d left" % [game.gold,game.rules.chest_price(game.paid_chests,game.stats.discount),game.chests.filter(func(c):return not c.opened and not c.get("destroyed",false)).size()]
	box_counter.visible=false
	weapons.refresh()
	turret_hints.visible=not modal.visible and game.equipped.any(func(w):return w.turret)
	if hint_device != game.input_kind:
		hint_device = game.input_kind;hints_until=game.elapsed+8
		for child in control_hints.get_children():
			control_hints.remove_child(child)
			child.queue_free()
		control_hints.add_child(label("Menu · Pause / controls" if game.input_kind=="xbox" else "Esc · Pause / controls",12))
		# InputGlyph updates itself; rebuilding choices here resets controller focus.
	control_hints.visible=not modal.visible
	prompt.visible=not modal.visible and not game.interaction_hint().is_empty()
	prompt.text = game.interaction_hint().replace("E / X", "X" if game.input_kind=="xbox" else "E")
	alert.visible=false
	alert.text = "☠  %s" % game.boss_name if game.boss_active() else ""
	if game.coop.frozen() and game.mode=="playing": alert.text="PARTY PAUSED  ·  A FRIEND IS CHOOSING";alert.visible=true
	map_view.configure(game.world.seed_value,game.world.realm)
	map_view.interactables.clear()
	var hunt_shrine=game.Hunt.shrine(game)
	if hunt_shrine and game.Hunt.state(game) in ["idle","active"]: map_view.interactables.append({"position":hunt_shrine.position,"kind":"hunt"})
	if is_instance_valid(game.update.merchant): map_view.interactables.append({"position":game.update.merchant.position,"kind":"merchant"})
	if is_instance_valid(game.update.beacon) and game.update.beacon_state in ["idle","defending"]: map_view.interactables.append({"position":game.update.beacon_position,"kind":"supply"})
	if game.Hunt.state(game)=="active":
		for enemy in game.enemies:
			if not enemy.dead and enemy.net_id in game.events.get("hunt_ids",[]): map_view.interactables.append({"position":enemy.node.position,"kind":"hunt_target"})
	for landmark in game.world.landmarks: map_view.interactables.append({"position":landmark,"kind":"landmark"})
	for pot in game.pots:
		if is_instance_valid(pot.node): map_view.interactables.append({"position":pot.node.position,"kind":"pot"})
	for drop in game.consumables:
		if is_instance_valid(drop.node): map_view.interactables.append({"position":drop.node.position,"kind":"potion"})
	map_view.camera_yaw=game.yaw
	map_view.party=game.coop.members.values().filter(func(m):return m.has("position")).map(func(m):return CoopSession.vector(m.position))
	map_view.pings=game.update.pings.map(func(p):return p.position)
	map_view.hero_position = game.player.position
	map_view.gate = game.gate_position
	map_view.gate_open = game.Journey.state(game) in ["ready","cleared"]
	var cell = Vector2i(roundi(game.player.position.x/8),roundi(game.player.position.z/8))
	map_view.visited[cell] = game.current_biome
	map_view.known_chests.clear()
	for chest in game.chests:
		if not chest.opened and not chest.get("destroyed",false): map_view.known_chests.append(chest.node.position)
	map_view.queue_redraw()
	toast.visible=not modal.visible and toast_time>0
	if toast_time > 0:
		toast_time -= delta
		if toast_time <= 0: toast.text = ""
	if blast_time > 0:
		blast_time -= delta
		blast.color.a = 0
	else: blast.color.a = 0

func start_menu(focus_hero: bool=false):
	game.mode="start"
	game.run_active=false
	for child in modal.get_children():
		modal.remove_child(child)
		child.queue_free()
	modal.visible=true
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	var background=preload("res://scripts/menu_backdrop.gd").new()
	modal.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title=label("WILDFORGE",64)
	title.add_theme_color_override("font_color",Color("f4da9e"))
	title.position=Vector2(86,62)
	modal.add_child(title)
	var strap=label("Grow strange. Fight hard. Start again.",18)
	strap.position=Vector2(90,141)
	strap.add_theme_color_override("font_color",Color("d6e2d4"))
	modal.add_child(strap)
	var nav=VBoxContainer.new()
	nav.position=Vector2(90,235)
	nav.custom_minimum_size=Vector2(245,0)
	nav.add_theme_constant_override("separation",9)
	modal.add_child(nav)
	menu_start=button("START RUN",func():
		if game.coop.active and not game.coop.hosting: tell("The party host starts the run.")
		else: game.start_run()
	,true)
	nav.add_child(menu_start)
	nav.add_child(button("Achievements",func(): career_menu(false)))
	nav.add_child(button("Local scores",func(): career_menu(true)))
	nav.add_child(button("Play with friends",coop_menu))
	nav.add_child(button("Sound & controls",settings_menu))
	nav.add_child(button("Quit",func(): game.career.save();game.get_tree().quit()))
	var hero_panel=PanelContainer.new()
	hero_panel.position=Vector2(400,208)
	hero_panel.size=Vector2(950,470)
	hero_panel.add_theme_stylebox_override("panel",style(Color("efe8cf"),Color("b5aa80"),18))
	modal.add_child(hero_panel)
	var columns=HBoxContainer.new()
	columns.add_theme_constant_override("separation",22)
	hero_panel.add_child(columns)
	var hero_list=VBoxContainer.new()
	hero_list.custom_minimum_size.x=170
	hero_list.add_theme_constant_override("separation",6)
	var hero_scroll=ScrollContainer.new();hero_scroll.custom_minimum_size=Vector2(185,435);hero_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;columns.add_child(hero_scroll);hero_scroll.add_child(hero_list)
	hero_list.add_child(label("CHOOSE YOUR HERO",13))
	var selected_hero: Button
	for item in game.rules.data.heroes:
		var pick=button(item.name,func():game.select_hero(item);start_menu(true))
		if item.id==game.hero.id: selected_hero=pick
		if item.id==game.hero.id: pick.add_theme_stylebox_override("normal",style(ThemeTokens.BIOME_ACCENTS.verdant.blossom,ThemeTokens.EARTH_TERRACOTTA))
		hero_list.add_child(pick)
	var portrait=HeroPortrait.new()
	portrait.custom_minimum_size=Vector2(320,420)
	columns.add_child(portrait)
	var preview_stats=game.rules.data.stats.duplicate(true);game.rules.apply_effects(preview_stats,game.hero.effects)
	portrait.setup(game.hero.model,game.hero.weapon,float(preview_stats.armor),float(preview_stats.shield))
	var bio=VBoxContainer.new()
	bio.custom_minimum_size.x=310
	bio.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	bio.add_theme_constant_override("separation",8)
	columns.add_child(bio)
	bio.add_child(label(game.hero.name,29))
	var description=label(game.hero.title,17)
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	bio.add_child(description)
	var perk=label(game.hero.perk,19,ThemeTokens.EARTH_TERRACOTTA);bio.add_child(perk)
	var perk_description=label(game.hero.description,15);perk_description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;bio.add_child(perk_description)
	var bonuses=game.hero.effects.map(func(effect):return game.rules.describe(effect))
	var bonus_text=label("  •  ".join(bonuses),13);bonus_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;bio.add_child(bonus_text)
	var starter=HBoxContainer.new()
	var icon=PowerIcon.new()
	icon.key=game.hero.weapon;icon.weapon_icon=true
	icon.custom_minimum_size=Vector2(72,72)
	starter.add_child(icon)
	var weapon_name=game.rules.data.weapons.filter(func(w):return w.id==game.hero.weapon)[0].name
	starter.add_child(label("Starts with
"+weapon_name,16))
	bio.add_child(starter)
	var mechanics=label(WeaponDetails.describe(game.hero.weapon),16)
	mechanics.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	bio.add_child(mechanics)
	var rules=label("3 weapon slots   •   3 worlds   •   One choice per chest",16)
	rules.position=Vector2(424,704)
	rules.add_theme_color_override("font_color",Color("d6e2d4"))
	modal.add_child(rules)
	var footer=HBoxContainer.new()
	footer.position=Vector2(90,748)
	modal.add_child(footer)
	add_prompts(footer,[["↑↓","D-pad","Navigate"],["Enter","A","Select"]])
	var version=label("DEVELOPMENT ALPHA  /  NATIVE PC",12)
	version.position=Vector2(1080,770)
	version.add_theme_color_override("font_color",Color("b4c9bc"))
	modal.add_child(version)
	if focus_hero and is_instance_valid(selected_hero):
		selected_hero.grab_focus()
		hero_scroll.ensure_control_visible.call_deferred(selected_hero)
	else: menu_start.grab_focus()

func coop_menu():
	game.mode="coop"
	var box=open("PLAY WITH FRIENDS","Up to 4 heroes · Shared enemies · Personal loot · Party pauses for choices")
	party_label=label(game.coop.status,16);party_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(party_label)
	var host=button("HOST PARTY",func():game.coop.host_lan());box.add_child(host)
	box.add_child(button("COPY HOST ADDRESS",func():
		var addresses=game.coop.local_addresses()
		if not addresses.is_empty(): DisplayServer.clipboard_set(addresses[0]);game.hud.tell("Host address copied")
	))
	var row=HBoxContainer.new();box.add_child(row)
	var address=LineEdit.new();address.text=game.career.data.settings.get("coopAddress","");address.placeholder_text="Host IP / hostname / VPN address";address.custom_minimum_size=Vector2(360,32);row.add_child(address)
	row.add_child(button("JOIN ADDRESS",func():game.coop.join_lan(address.text)))
	address.text_submitted.connect(func(value):game.coop.join_lan(value))
	box.add_child(label("SAME-NETWORK PARTIES",14));party_list=VBoxContainer.new();box.add_child(party_list);party_list_key=""
	game.coop.begin_discovery();update_party_list()
	var help=label("Same Wi-Fi/LAN: join a party below. Remote friends: use the host's public IP with UDP 29736 forwarded, or a shared VPN address. Allow Wildforge through the firewall.",14)
	help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(help)
	box.add_child(button("Leave party",func():game.coop.leave();game.coop.status="Solo"))
	box.add_child(button("Back to hero selection",start_menu))
	host.grab_focus()

func update_party_list():
	var entries=[]
	for address in game.coop.discovered:
		var entry=game.coop.discovered[address]
		entries.append({"address":address,"name":entry.name,"players":entry.players,"playing":entry.playing})
	entries.sort_custom(func(a,b):return a.address<b.address)
	var key=JSON.stringify(entries)
	if key==party_list_key: return
	party_list_key=key
	for child in party_list.get_children(): child.queue_free()
	if entries.is_empty(): party_list.add_child(label("Looking for nearby parties… You can also join an address above.",14));return
	for entry in entries.slice(0,3):
		var join=button("%s · %s · %d / 4%s" % [entry.name,entry.address,entry.players," · RUNNING" if entry.playing else ""],func():game.coop.join_lan(entry.address))
		join.disabled=entry.playing or entry.players>=4;party_list.add_child(join)

func pause_menu(ended: bool = false, win: bool = false):
	game.mode = "ended" if ended else "paused"
	var box = open("YOU WON" if win else "TRY AGAIN" if ended else "PAUSED", "%s · %d coins · %d enemies · ★ %d" % [game.hero.name,game.gold,game.kills,game.level])
	if ended: box.add_child(label(game.update.recap(),15))
	if not ended: box.add_child(button("▶  CONTINUE",close,true))
	box.add_child(button("↻  NEW RUN",game.start_run,ended))
	box.add_child(button("★  ACHIEVEMENTS",func(): career_menu(false)))
	box.add_child(button("♛  LOCAL SCORES",func(): career_menu(true)))
	box.add_child(button("♫  SOUND / CONTROLS",settings_menu))
	box.add_child(button("←  HEROES",func(): game.record_run(false,true); start_menu()))
	box.add_child(button("QUIT",func(): game.record_run(false,true); game.career.save(); game.get_tree().quit()))
	for control in box.get_children():
		if control is Button and not control.disabled: control.grab_focus();break

func icon_key(item: Dictionary) -> String:
	return item.id

func offer_card(item: Dictionary, index: int, select: Callable) -> Button:
	var card=button("",select,false,"large")
	var accent=RunRules.COLORS[item.tier]
	card.custom_minimum_size=Vector2(0,360)
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var normal=style(paper.lerp(accent,.08),accent,12);normal.border_width_top=6
	card.add_theme_stylebox_override("normal",normal)
	var hover=style(paper.lerp(accent,.18),accent,12);hover.set_border_width_all(3);hover.border_width_top=6
	card.add_theme_stylebox_override("hover",hover)
	card.add_theme_stylebox_override("pressed",hover)
	var focus=StyleBoxFlat.new();focus.bg_color=Color.TRANSPARENT;focus.border_color=ink;focus.set_border_width_all(3);focus.set_corner_radius_all(12)
	focus.shadow_color=Color(accent,.45);focus.shadow_size=8
	card.add_theme_stylebox_override("focus",focus)
	var column=VBoxContainer.new();card.add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left=16;column.offset_right=-16;column.offset_top=18;column.offset_bottom=-18
	column.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_theme_constant_override("separation",10)
	var rarity=label(RunRules.RARITIES[item.tier].to_upper()+"   /   "+str(index+1),13,accent.darkened(.48))
	column.add_child(rarity)
	var icon=PowerIcon.new();icon.key=icon_key(item);icon.weapon_icon=item.kind=="weapon"
	icon.custom_minimum_size=Vector2(96,96);icon.size_flags_horizontal=Control.SIZE_SHRINK_CENTER;column.add_child(icon)
	var title=label(item.name,20);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.custom_minimum_size.y=48
	column.add_child(title)
	var text=WeaponDetails.describe(item.id) if item.kind=="weapon" else game.rules.describe(item.effects[0])
	var description=label(text,15);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;description.max_lines_visible=4;description.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;card.tooltip_text=text;description.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(description)
	var note=item.kind.capitalize()+" · "+str(item.get("family","Weapon"))
	if item.kind=="weapon":
		var owned=game.equipped.filter(func(w):return w.id==item.id)
		note="Rank %d → %d" % [owned[0].rank,owned[0].rank+1] if not owned.is_empty() else "Choose a slot to replace" if game.equipped.size()>=3 else "New weapon"
	var footer=label(note,12);footer.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(footer)
	card.mouse_entered.connect(func():
		if game.input_kind!="xbox": card.grab_focus()
	)
	card.focus_entered.connect(func(): preview_offer(item))
	cards.append(card)
	return card

func preview_offer(item: Dictionary):
	game.update.focused_offer=game.offers.find(item)
	if not is_instance_valid(offer_detail): return
	var signature=item.id+":"+str(item.tier)+":"+str(item.get("strength",1))
	if signature==preview_id: return
	preview_id=signature
	for child in offer_detail.get_children(): offer_detail.remove_child(child);child.queue_free()
	offer_detail.add_child(label("SELECTED  ·  "+item.name,18))
	var comparison=""
	if item.kind=="weapon":
		var owned=game.equipped.filter(func(w):return w.id==item.id)
		var before=float(owned[0].power) if not owned.is_empty() else 0.0
		var after=before+item.strength*.3 if before>0 else item.strength
		comparison="Weapon power %.2f → %.2f  ·  " % [before,after]+("Upgrades your equipped weapon" if before>0 else "Uses one of three weapon slots")+"  ·  "+WeaponDetails.describe(item.id)
	else:
		var candidate=game.stats.duplicate(true);game.rules.apply_effects(candidate,item.effects)
		var effect=item.effects[0];var source=game.rules.loot_by_id.get(item.id,{})
		comparison=game.rules.describe(effect)
		if not str(effect.key).begins_with("augment-"): comparison+="  ·  Current %s → %s" % [snappedf(game.stats.get(effect.key,0),.01),snappedf(candidate.get(effect.key,0),.01)]
		if not source.is_empty() and item.tier>0: comparison+="  ·  Common version: "+game.rules.describe(source.effects[0])
	var detail=label(comparison,15);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;offer_detail.add_child(detail)

func show_offers(items: Array, source: String,animate: bool=true):
	var box=open("LEVEL %d · CHOOSE YOUR NEXT POWER" % game.level if source=="level" else "TREASURE FOUND", "Choose one reward. Shape your next fight.")
	var panel=box.get_parent();panel.position=Vector2(60,62);panel.size=Vector2(1320,686)
	panel.add_theme_stylebox_override("panel",style(ThemeTokens.INK,Color("9b855e"),22))
	box.get_child(0).add_theme_color_override("font_color",ThemeTokens.PAPER)
	box.get_child(1).add_theme_color_override("font_color",Color("b5c5cf"))
	box.add_theme_constant_override("separation",16)
	var choices=HBoxContainer.new();choices.add_theme_constant_override("separation",16);box.add_child(choices)
	for i in range(items.size()): choices.add_child(offer_card(items[i],i,func():game.choose_offer(i)))
	var detail_panel=PanelContainer.new();detail_panel.custom_minimum_size.y=95
	detail_panel.add_theme_stylebox_override("panel",style(paper,Color("a99070"),12));box.add_child(detail_panel)
	offer_detail=VBoxContainer.new();offer_detail.add_theme_constant_override("separation",6);detail_panel.add_child(offer_detail)
	var actions=HBoxContainer.new();actions.add_theme_constant_override("separation",12);box.add_child(actions)
	var reroll=button("Reroll · %d gold" % game.reroll_price(),func():game.reroll_offers(),true,"large")
	reroll.custom_minimum_size=Vector2(220,44);reroll.disabled=game.gold<game.reroll_price();actions.add_child(reroll)
	if game.update.banish_charges>0 and items.any(func(i):return i.kind!="weapon"):
		actions.add_child(button("Banish selected · %d left" % game.update.banish_charges,func():game.update.banish(game.update.focused_offer),false,"large"))
	if items.any(func(item):return item.kind=="weapon"):
		actions.add_child(button("Keep my weapons",func():game.skip_offer(),false,"large"))
	var hints=label("1–5 choose   ·   ← → / D-pad browse   ·   Enter / A confirm   ·   R / Y reroll",14,Color("b5c5cf"));hints.add_theme_color_override("font_color",Color("b5c5cf"));box.add_child(hints)
	if not cards.is_empty(): cards[0].grab_focus();preview_offer(items[0])
	if animate: animate_offers()

func offer_layout_fits() -> bool:
	if cards.is_empty(): return false
	var bounds=get_viewport().get_visible_rect()
	for card in cards:
		if not bounds.encloses(card.get_global_rect()): return false
		if card.size.x<180 or card.size.y<220: return false
		for other in cards:
			if other!=card and card.get_global_rect().intersection(other.get_global_rect()).get_area()>1: return false
	return true

func animate_offers():
	var panel=content.get_parent();panel.pivot_offset=panel.size*.5;panel.scale=Vector2(.98,.98)
	panel.create_tween().tween_property(panel,"scale",Vector2.ONE,.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	offer_tween=create_tween().set_parallel(true)
	for i in range(cards.size()):
		var card=cards[i];card.pivot_offset=Vector2(120,180);card.scale=Vector2(.96,.96)
		offer_tween.tween_property(card,"scale",Vector2.ONE,.16).set_delay(i*.035).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func chest_reveal(tier: int, progress_value: float):
	if not modal.visible: open("TREASURE REELS", "Items from exploration · Choose one lasting bonus")
	if content.get_child_count() <= 2:
		var display=preload("res://scripts/chest_show.gd").new()
		display.tier=tier;display.sound=game.sound
		display.custom_minimum_size=Vector2(920,340)
		display.setup(game.offers)
		content.add_child(display)
		content.add_child(label("",28,RunRules.COLORS[tier]))
	content.get_child(2).animate(progress_value)
	content.get_child(3).text="●".repeat(tier+1)+"  "+RunRules.RARITIES[tier].to_upper()
	blast.color=Color(0,0,0,0)

func replace_menu(item: Dictionary):
	var box = open("⚔  THREE WEAPONS", "Choose a weapon to replace. Your other items stay.")
	for i in range(game.equipped.size()):
		var weapon = game.equipped[i]
		box.add_child(button("%s ★%d   →   %s" % [weapon.name,weapon.rank,item.name],func(): game.replace_weapon(i,item),true))
	box.add_child(button("←  CHOOSE ANOTHER",func(): game.mode="offer"; show_offers(game.offers,game.offer_source)))
	box.get_child(2).grab_focus()

func build_menu():
	game.mode = "build"
	var box = open("⚔  YOUR BUILD", "Weapons use three slots. Items and skills are unlimited.")
	for weapon in game.equipped:
		box.add_child(label("⚔  %s  ·  Lv. %d" % [weapon.name,weapon.rank],21,Color("e8d08a")))
		var mechanic=label(WeaponDetails.describe(weapon.id),16)
		mechanic.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		box.add_child(mechanic)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 180
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var rows = VBoxContainer.new()
	scroll.add_child(rows)
	for item in game.owned:
		var descriptions = []
		for effect in item.effects: descriptions.append(game.rules.describe(effect))
		rows.add_child(label("%s  ·  %s" % [item.name," / ".join(descriptions)],17,RunRules.COLORS[item.tier]))
	box.add_child(button("▶  BACK",close,true))

func settings_menu():
	game.mode = "settings"
	var box = open("♫  SOUND / CONTROLS", "Nova · Warm female tactical voice. No kill-streak chatter.")
	for channel in ["music","sfx","voice"]:
		var row = HBoxContainer.new()
		row.add_child(label(channel.capitalize(),21))
		var slider = HSlider.new()
		slider.min_value = 0
		slider.max_value = 1
		slider.step = .05
		slider.value = game.career.data.settings[channel]
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value_changed.connect(func(value): game.career.data.settings[channel]=value;game.career.dirty=true)
		row.add_child(slider)
		box.add_child(row)
	var genres = HBoxContainer.new()
	for genre in ["metal","cyber"]: genres.add_child(button("HEAVY METAL" if genre == "metal" else "CYBERPUNK",func(): game.career.data.settings.genre=genre;game.career.dirty=true;game.sound.start(randi())))
	box.add_child(genres)
	var rumble = CheckButton.new()
	rumble.text = "Xbox vibration"
	rumble.add_theme_color_override("font_color",ink)
	rumble.add_theme_color_override("font_hover_color",ink)
	rumble.add_theme_color_override("font_focus_color",ink)
	rumble.button_pressed = game.career.data.settings.rumble
	rumble.toggled.connect(func(value): game.career.data.settings.rumble=value;game.career.dirty=true)
	box.add_child(rumble)
	box.add_child(button("TEST VOICE + VIBRATION",func(): game.sound.say("boss",0);game.vibrate(.5,.4,.3)))
	var look_settings = HBoxContainer.new()
	look_settings.add_child(label("Camera sensitivity",18))
	var sensitivity = HSlider.new()
	sensitivity.min_value=.3
	sensitivity.max_value=2.0
	sensitivity.step=.1
	sensitivity.value=game.career.data.settings.lookSensitivity
	sensitivity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	sensitivity.value_changed.connect(func(value): game.career.data.settings.lookSensitivity=value;game.career.dirty=true)
	look_settings.add_child(sensitivity)
	box.add_child(look_settings)
	var invert=CheckButton.new()
	invert.text="Invert camera up / down"
	invert.add_theme_color_override("font_color",ink)
	invert.add_theme_color_override("font_hover_color",ink)
	invert.add_theme_color_override("font_focus_color",ink)
	invert.button_pressed=game.career.data.settings.invertLook
	invert.toggled.connect(func(value): game.career.data.settings.invertLook=value;game.career.dirty=true)
	box.add_child(invert)
	var prompts=HBoxContainer.new()
	box.add_child(prompts)
	add_prompts(prompts,[["WASD","LS","Move"],["Mouse","RS","Look"],["Space","A","Jump"],["Ctrl","B","Slam"],["Shift","RT","Dash"],["E","X","Interact"],["F","R3","Ping"]])
	var secondary=HBoxContainer.new()
	box.add_child(secondary)
	add_prompts(secondary,[["B","Y","Build"],["T","LB","Place turret"],["G","RB","Next turret"],["Esc","Menu","Pause"]])
	box.add_child(button("←  BACK",func(): game.career.save(); start_menu() if not game.run_active else pause_menu(game.run_recorded),true))

func career_menu(scores: bool):
	game.mode = "career"
	var box = open("♛  LOCAL SCORES" if scores else "★  %d / %d ACHIEVEMENTS" % [game.career.data.unlocked.size(),game.career.achievements.size()], "Saved on this PC")
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size.y = 430
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)
	var rows = VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	if scores:
		for i in range(mini(25,game.career.data.scores.size())):
			var entry = game.career.data.scores[i]
			rows.add_child(label("%d.  %s  ·  %s  ·  %d  ·  %02d:%02d  ·  %s" % [i+1,entry.get("player","Hero"),entry.hero,entry.score,int(entry.seconds)/60,int(entry.seconds)%60,"WIN" if entry.win else "END"],20))
		if game.career.data.scores.is_empty(): rows.add_child(label("Finish a run to add your score.",22))
	else:
		for achievement in game.career.achievements:
			var unlocked = game.career.data.unlocked.has(achievement.id)
			var value = minf(achievement.target,float(game.career.data[achievement.scope].get(achievement.key,0)))
			var row=HBoxContainer.new();rows.add_child(row)
			var icon=TextureRect.new();icon.custom_minimum_size=Vector2(54,54);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			var tile=AtlasTexture.new();tile.atlas=load("res://assets/illustrated/achievements.png" if unlocked else "res://assets/illustrated/achievements-locked.png")
			var index=game.career.achievements.find(achievement)
			if index>=100:
				icon.texture=IllustratedIcons.texture(["turretCount","goldGain","luck","poison","revive","range","speed","jumpHeight"][index-100])
				if not unlocked: icon.modulate=Color(.6,.6,.6)
			else: tile.region=Rect2((index%10)*96,(index/10)*96,96,96);icon.texture=tile
			row.add_child(icon)
			var text=VBoxContainer.new();row.add_child(text)
			text.add_child(label(achievement.name+"  ·  "+str(int(value))+" / "+str(int(achievement.target)),17))
			text.add_child(label(achievement.description,14))

func add_prompts(parent: HBoxContainer, bindings: Array):
	parent.add_theme_constant_override("separation",8)
	for binding in bindings:
		var glyph = InputGlyph.new()
		glyph.game = game
		glyph.keyboard_key = binding[0]
		glyph.xbox_key = binding[1]
		glyph.xbox = game.input_kind == "xbox"
		glyph.key = binding[1] if glyph.xbox else binding[0]
		glyph.custom_minimum_size = Vector2(48 if glyph.key.length()>2 else 34,30)
		parent.add_child(glyph)
		var caption=label(binding[2],13)
		var backdrop=style()
		backdrop.set_border_width_all(0)
		backdrop.content_margin_left=3;backdrop.content_margin_right=6
		caption.add_theme_stylebox_override("normal",backdrop)
		parent.add_child(caption)

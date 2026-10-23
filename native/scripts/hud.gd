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
var rescue_meter: ProgressBar
var rescue_text: Label
var coins: Label
var status: Label
var weapons: WeaponBar
var control_hints: HBoxContainer
var hint_device = ""
var turret_hints = HBoxContainer.new()
var turret_status: Label
var slam_status: Label
var damage_feedback: Control
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
var harvest_status: Label
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
var party_overlay: PanelContainer
var party_rows: VBoxContainer
var party_panel_open=false
var party_split=false   # true only while this player's co-op reward screen leaves room for the team panel
var offer_tween: Tween
var preview_id=""
var health_text: Label
var health_orb: Control
var shield_text: Label
var armor_text: Label
var portrait: HeroPortrait
var hints_until=25.0
var player_locator: Control
var journey_overlay: Control
var lobby_ready: Button
var lobby_start: Button
var lobby_roster_label: Label
var lobby_specialty: Label
var coop_name_input: LineEdit
var achievement_cosmetic_picker: OptionButton
var damage_font=SystemFont.new()
var damage_labels: Array[Label]=[]
var damage_overlay: Control
var flash_overlay: ColorRect
var skill_strip=HBoxContainer.new()
var skill_strip_key=""
var binding_action=""
var binding_device=""
var binding_status: Label
var binding_axes={}
var binding_buttons={}

# Achievement notification system (Xbox-style overlay)
var _ach_note_panel: Panel = null
var _ach_note_name: Label = null
var _ach_note_desc: Label = null
var _ach_note_timer: float = 0.0
var _ach_note_alpha: float = 0.0
var _ach_note_active: bool = false
var _ach_note_queue: Array[Dictionary] = []
var _ach_note_header: Label
var _ach_note_row: HBoxContainer
var _ach_note_text: VBoxContainer
const ACHIEVEMENT_DURATION=5.0

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
	item.add_theme_color_override("font_color",color.lerp(ThemeTokens.PAPER,.72) if color.get_luminance()<.35 else color)
	item.add_theme_color_override("font_outline_color",ThemeTokens.INK_RUNTIME)
	item.add_theme_constant_override("outline_size",0)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item

func style(color: Color = ThemeTokens.PAPER_RUNTIME, border: Color = Color("a99070"), radius: int = 3) -> StyleBoxFlat:
	var box=StyleBoxFlat.new()
	# Quiet opaque surfaces; focus and rarity use a thin accent edge.
	box.bg_color=Color(color.r,color.g,color.b,1) if color.get_luminance()<.18 else ThemeTokens.PAPER_RUNTIME.lerp(color,.10)
	box.border_color=Color(border.r,border.g,border.b,1) if border.a>.7 else Color("b9a58a")
	box.set_border_width_all(1)
	box.border_width_bottom=1
	box.shadow_color=ThemeTokens.SHADOW.color;box.shadow_size=2;box.shadow_offset=ThemeTokens.SHADOW.offset
	box.set_corner_radius_all(mini(radius,3))
	box.content_margin_left=ThemeTokens.MARGINS.left
	box.content_margin_right=ThemeTokens.MARGINS.right
	box.content_margin_top=ThemeTokens.MARGINS.top
	box.content_margin_bottom=ThemeTokens.MARGINS.bottom
	return box

func button(text: String, action: Callable, accent: bool = false, radius_key: String = "small") -> Button:
	var item=Button.new()
	item.text=text
	item.custom_minimum_size.y=42
	item.add_theme_font_size_override("font_size",16)
	var bg = Color("e3ba86") if accent else paper
	var r = ThemeTokens.RADIUS[radius_key] if radius_key in ThemeTokens.RADIUS else ThemeTokens.RADIUS.small
	item.add_theme_stylebox_override("normal",style(bg,Color("c8d9c23c"),r))
	item.add_theme_stylebox_override("hover",style(Color("efd3a7"),Color("977657"),r))
	item.add_theme_stylebox_override("pressed",style(Color("dcb48a"),Color("70543b"),r))
	var focus=StyleBoxFlat.new();focus.bg_color=Color.TRANSPARENT;focus.border_color=ThemeTokens.STAR_GOLD;focus.set_border_width_all(3);focus.set_corner_radius_all(r)
	item.add_theme_stylebox_override("focus",focus)
	item.add_theme_color_override("font_color",ink)
	item.add_theme_color_override("font_hover_color",ink)
	item.add_theme_color_override("font_focus_color",ink)
	item.add_theme_color_override("font_pressed_color",ink)
	item.pressed.connect(action)
	return item

const VITALS=Rect2(22,18,352,150)
const LOADOUT=Rect2(676,900,568,140)
const MAP_CLOCK=Vector2(1613,332)

# A framed backing plate in the in-game window style, drawn behind its cluster.
func cluster_plate(area: Rect2):
	var plate=Panel.new();plate.position=area.position;plate.size=area.size;plate.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var look=style(ThemeTokens.INK,Color("9b855e"),8);look.bg_color=Color(ThemeTokens.INK,.82);plate.add_theme_stylebox_override("panel",look)
	root.add_child(plate);root.move_child(plate,0)
	var frame=preload("res://scripts/forge_frame.gd").new();frame.panel=plate;frame.position=area.position;frame.size=area.size;frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(frame);root.move_child(frame,1)

func setup(owner_game):
	game = owner_game
	# HUD clusters (1920×1080 logical): vitals top-left, map + run clock top-right,
	# loadout (skills, weapons, slam/turret, level/XP) bottom-centre.
	skill_strip.position=Vector2(LOADOUT.position.x+34,LOADOUT.position.y+8);skill_strip.add_theme_constant_override("separation",3);root.add_child(skill_strip)
	player_locator=preload("res://scripts/player_locator.gd").new();player_locator.game=game;player_locator.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(player_locator)
	buff_icons=HBoxContainer.new();buff_icons.position=Vector2(VITALS.position.x,VITALS.end.y+10);buff_icons.add_theme_constant_override("separation",6);root.add_child(buff_icons)
	buff_label=label("",14);buff_label.position=Vector2(VITALS.position.x,VITALS.end.y+10);root.add_child(buff_label)
	biome_label=label("",16);biome_label.position=Vector2(MAP_CLOCK.x,MAP_CLOCK.y+68);biome_label.custom_minimum_size.x=254;biome_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;root.add_child(biome_label)
	harvest_status=label("",17);harvest_status.position=Vector2(VITALS.position.x,VITALS.end.y+104);harvest_status.custom_minimum_size.x=VITALS.size.x
	harvest_status.add_theme_stylebox_override("normal",style(paper,Color("74a876"),10));root.add_child(harvest_status)
	level_plate=label("",30);level_plate.position=Vector2(733,333);root.add_child(level_plate)
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
	# The run clock docks under the minimap with the biome name below it.
	clock.position = MAP_CLOCK
	clock.scale=Vector2.ONE*.75
	clock.size = Vector2(400,149)
	root.add_child(clock)
	for area in [VITALS,LOADOUT]: cluster_plate(area)
	var health_panel=PanelContainer.new();health_panel.position=VITALS.position+Vector2(12,10);health_panel.custom_minimum_size=Vector2(VITALS.size.x-24,76)
	health_panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new());root.add_child(health_panel)
	var health_row=HBoxContainer.new();health_panel.add_child(health_row)
	health_orb=preload("res://scripts/hud_vessel.gd").new();health_orb.custom_minimum_size=Vector2(60,60);health_row.add_child(health_orb)
	var health_column=VBoxContainer.new();health_column.add_theme_constant_override("separation",0);health_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL;health_row.add_child(health_column)
	health_text=label("",18);health_column.add_child(health_text)
	shield_text=label("",13,Color("70c9df"));health_column.add_child(shield_text)
	armor_text=label("",12,ink);health_column.add_child(armor_text)
	journey_overlay=preload("res://scripts/journey_hud.gd").new();journey_overlay.game=game;journey_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(journey_overlay)
	# Larger, frameless rotating minimap; the hero remains centered.
	map_view.position=Vector2(1592,26)
	map_view.size=Vector2(296,296)
	map_view.clip_contents=true
	root.add_child(map_view)
	status=label("",16,ThemeTokens.STAR_GOLD);root.add_child(status)
	# Level and XP values frame the loadout, just above the full-width XP meter.
	status.name="EdgeLevel";status.set_anchors_preset(Control.PRESET_BOTTOM_LEFT);status.offset_left=LOADOUT.position.x+14;status.offset_top=-34;status.offset_bottom=-12
	xp_text=label("",14);root.add_child(xp_text)
	xp_text.name="EdgeXP";xp_text.set_anchors_preset(Control.PRESET_BOTTOM_LEFT);xp_text.offset_left=LOADOUT.end.x-360;xp_text.offset_right=LOADOUT.end.x-14;xp_text.offset_top=-34;xp_text.offset_bottom=-12
	xp_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	# Bottom-edge full-viewport XP meter, independent of the compact stat panel.
	xp = ProgressBar.new()
	xp.show_percentage = false
	xp.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var xp_bg=StyleBoxFlat.new();xp_bg.bg_color=Color("121b23")
	var xp_fill=StyleBoxFlat.new();xp_fill.bg_color=Color("62c69b")
	xp.add_theme_stylebox_override("background",xp_bg)
	xp.add_theme_stylebox_override("fill",xp_fill)
	root.add_child(xp)
	xp.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	xp.offset_left=0;xp.offset_right=0;xp.offset_top=-10;xp.offset_bottom=0
	xp.z_index=12
	# Co-op revive state is driven by the host-authoritative rescue progress.
	rescue_text=label("",17,ThemeTokens.STAR_GOLD)
	rescue_text.position=Vector2(780,742)
	rescue_text.size=Vector2(360,24)
	rescue_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(rescue_text)
	rescue_meter=ProgressBar.new()
	rescue_meter.position=Vector2(780,774);rescue_meter.size=Vector2(360,10)
	rescue_meter.max_value=3.0;rescue_meter.show_percentage=false
	rescue_meter.mouse_filter=Control.MOUSE_FILTER_IGNORE
	rescue_meter.add_theme_stylebox_override("background",xp_bg)
	var rescue_fill=StyleBoxFlat.new();rescue_fill.bg_color=Color("e4be78")
	rescue_meter.add_theme_stylebox_override("fill",rescue_fill)
	root.add_child(rescue_meter)
	coins = label("GOLD  0    BOX PRICE  30",18,ThemeTokens.STAR_GOLD)
	box_counter=label("",15);box_counter.position=Vector2(32,243);box_counter.add_theme_stylebox_override("normal",style());root.add_child(box_counter)
	# Coins sit in the vitals plate under a thin gilt divider.
	var coins_panel=PanelContainer.new();coins_panel.position=VITALS.position+Vector2(12,94);coins_panel.custom_minimum_size=Vector2(VITALS.size.x-24,40)
	var divider=StyleBoxFlat.new();divider.bg_color=Color.TRANSPARENT;divider.border_color=Color(ThemeTokens.STAR_GOLD,.45);divider.border_width_top=1
	divider.content_margin_left=8;divider.content_margin_top=6;coins_panel.add_theme_stylebox_override("panel",divider);root.add_child(coins_panel)
	coins.add_theme_color_override("font_color",ink);coins_panel.add_child(coins)
	weapons = WeaponBar.new()
	weapons.game = game
	weapons.position = LOADOUT.position+Vector2(14,44)
	weapons.add_theme_constant_override("separation",10)
	root.add_child(weapons)
	control_hints = HBoxContainer.new()
	control_hints.position = Vector2(32,1033)
	control_hints.add_theme_constant_override("separation",10)
	root.add_child(control_hints)
	# Ability readouts sit beside the weapon slots inside the loadout plate.
	turret_hints.position=LOADOUT.position+Vector2(400,86)
	root.add_child(turret_hints)
	turret_status=label("",14,ThemeTokens.STAR_GOLD);turret_hints.add_child(turret_status)
	slam_status=label("",14,ThemeTokens.STAR_GOLD);slam_status.position=LOADOUT.position+Vector2(400,56);root.add_child(slam_status)
	damage_feedback=preload("res://scripts/damage_feedback.gd").new();damage_feedback.game=game;damage_feedback.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(damage_feedback)
	prompt = label("",18,ThemeTokens.BIOME_ACCENTS.verdant.petal)
	prompt.position = Vector2(540,682);prompt.size=Vector2(840,42)
	prompt.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;prompt.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_stylebox_override("normal",style())
	root.add_child(prompt)
	alert = label("",21,ThemeTokens.EARTH_TERRACOTTA)
	alert.position = Vector2(613,40)
	alert.add_theme_stylebox_override("normal",style())
	root.add_child(alert)
	toast = label("",16,ThemeTokens.BIOME_ACCENTS.verdant.leaf)
	toast.position = Vector2(586,606)
	toast.add_theme_stylebox_override("normal",style())
	root.add_child(toast)
	blast = ColorRect.new()
	blast.color = Color(1,.8,.3,0)
	blast.visible=false
	blast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(blast)
	blast.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Damage number overlay — a transparent container for 3D-to-2D projected labels
	damage_overlay=Control.new()
	damage_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	damage_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(damage_overlay)
	# Screen flash overlay
	flash_overlay=ColorRect.new()
	flash_overlay.color=Color(1,1,1,0)
	flash_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	root.add_child(flash_overlay)
	flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Modern console banner: icon first, expanding green panel, then text.
	_ach_note_panel = Panel.new()
	_ach_note_panel.visible = false
	_ach_note_panel.clip_contents=true
	_ach_note_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ach_note_panel.z_index=100
	var achievement_style=StyleBoxFlat.new()
	achievement_style.bg_color=Color("12322c");achievement_style.border_color=ThemeTokens.STAR_GOLD
	achievement_style.set_border_width_all(1);achievement_style.set_corner_radius_all(3)
	achievement_style.shadow_color=Color(0,0,0,.3);achievement_style.shadow_size=8;achievement_style.shadow_offset=Vector2(0,4)
	_ach_note_panel.add_theme_stylebox_override("panel",achievement_style)
	_ach_note_row=HBoxContainer.new();_ach_note_row.mouse_filter=Control.MOUSE_FILTER_IGNORE
	_ach_note_row.position=Vector2(14,14);_ach_note_row.size=Vector2(612,80)
	_ach_note_row.add_theme_constant_override("separation",20);_ach_note_panel.add_child(_ach_note_row)
	var badge=preload("res://scripts/achievement_badge.gd").new();badge.custom_minimum_size=Vector2(76,80);_ach_note_row.add_child(badge)
	var ach_vbox = VBoxContainer.new()
	_ach_note_text=ach_vbox
	ach_vbox.size_flags_horizontal=Control.SIZE_EXPAND_FILL;ach_vbox.alignment=BoxContainer.ALIGNMENT_CENTER
	ach_vbox.mouse_filter=Control.MOUSE_FILTER_IGNORE;ach_vbox.add_theme_constant_override("separation",3)
	_ach_note_row.add_child(ach_vbox)
	_ach_note_header=label("ACHIEVEMENT UNLOCKED",15)
	_ach_note_header.add_theme_color_override("font_color",Color("c7efd0"));ach_vbox.add_child(_ach_note_header)
	_ach_note_name = label("", 25)
	_ach_note_name.add_theme_color_override("font_color",Color("ffffff"))
	_ach_note_name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	ach_vbox.add_child(_ach_note_name)
	_ach_note_desc = label("", 16)
	_ach_note_desc.add_theme_color_override("font_color",Color("e1f3e5"))
	_ach_note_desc.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	ach_vbox.add_child(_ach_note_desc)
	root.add_child(_ach_note_panel)
	root.add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# A small companion panel above the ordinary HUD (and reward modal).
	party_overlay=PanelContainer.new()
	party_overlay.anchor_left=.68;party_overlay.anchor_right=.99
	party_overlay.anchor_top=.035;party_overlay.anchor_bottom=.965
	party_overlay.mouse_filter=Control.MOUSE_FILTER_IGNORE
	party_overlay.z_index=8
	party_overlay.add_theme_stylebox_override("panel",style(Color("182d30"),ThemeTokens.STAR_GOLD,10))
	party_rows=VBoxContainer.new()
	party_rows.add_theme_constant_override("separation",3)
	party_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	party_rows.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var party_scroll=ScrollContainer.new()
	party_scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	party_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	party_overlay.add_child(party_scroll)
	party_scroll.add_child(party_rows)
	root.add_child(party_overlay)
	party_overlay.visible=false
	modal.visible = false

func open(title: String, subtitle: String = "") -> VBoxContainer:
	binding_action=""
	if offer_tween!=null and offer_tween.is_valid(): offer_tween.kill()
	preview_id="";party_split=false
	for child in modal.get_children(): child.queue_free()
	modal.visible = true
	var vp_size = get_viewport().get_visible_rect().size
	var panel = PanelContainer.new()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var panel_w := 1333.0; var panel_h := 853.0
	panel.position = Vector2((vp_size.x-panel_w)/2,(vp_size.y-panel_h)/2)
	panel.size = Vector2(panel_w,panel_h)
	var shade=ColorRect.new();shade.color=Color(.025,.05,.08,.72);modal.add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel",style(paper,Color("a99070"),22))
	modal.add_child(panel)
	var frame=preload("res://scripts/forge_frame.gd").new();frame.panel=panel;frame.position=panel.position;frame.size=panel.size;frame.z_index=2;modal.add_child(frame)
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
	modal.visible = false;party_split=false;party_panel_open=false
	game.mode = "playing"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if not game.smoke else Input.MOUSE_MODE_VISIBLE

func tell(text: String, duration: float = 3.0):
	toast.text = text
	toast_time = duration

func show_party_panel(selections: Dictionary):
	if not is_instance_valid(party_rows): return
	for child in party_rows.get_children(): child.queue_free()
	var source=""
	for person in selections.values():
		if person is Dictionary and not str(person.get("source","")).is_empty(): source=str(person.source);break
	var title="TEAM LEVEL-UP OPTIONS" if source=="level" else "TEAM CHEST OPTIONS" if source=="chest" else "TEAM OPTIONS"
	party_rows.add_child(label(title,17,ThemeTokens.STAR_GOLD))
	if selections.is_empty():
		party_rows.add_child(label("Waiting for teammate options…",13))
	var ids=selections.keys();ids.sort_custom(func(a,b):return int(a)<int(b))
	for index in range(ids.size()):
		var person=selections[ids[index]]
		if not person is Dictionary: continue
		var is_local=int(person.get("player_id",ids[index]))==game.coop.local_id
		var heading=label(("YOU" if is_local else "PLAYER "+str(index+1))+" · "+str(person.get("name","Player")).left(26),14,ThemeTokens.PAPER)
		heading.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		party_rows.add_child(heading)
		var options=person.get("options",[]);var selected_id=str(person.get("selected_id",""))
		if options.is_empty():
			party_rows.add_child(label("Waiting for options…",12,Color("a9b7b8")))
		else:
			for option_index in range(options.size()):
				var option=options[option_index];var chosen=str(option.get("id", ""))==selected_id and not selected_id.is_empty()
				var row=PanelContainer.new();row.custom_minimum_size.y=18
				row.add_theme_stylebox_override("panel",style(Color("574b2b") if chosen else Color("223538"),ThemeTokens.STAR_GOLD if chosen else Color("526568"),4))
				var text=label(("✓  " if chosen else str(option_index+1)+"  ")+str(option.get("name","Reward")).left(48),12,ThemeTokens.STAR_GOLD if chosen else Color("d4ddda"))
				text.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
				text.tooltip_text=str(option.get("name","Reward"))
				row.add_child(text);party_rows.add_child(row)
		if selected_id=="__skip__":
			var skipped=PanelContainer.new();skipped.custom_minimum_size.y=18
			skipped.add_theme_stylebox_override("panel",style(Color("574b2b"),ThemeTokens.STAR_GOLD,4))
			skipped.add_child(label("✓  Kept weapons",12,ThemeTokens.STAR_GOLD));party_rows.add_child(skipped)
	party_overlay.visible=party_visible()

# Teammate updates only refresh the rows; the panel shows beside this player's
# own reward choice and never over gameplay or another full-width screen.
func party_visible() -> bool:
	return party_panel_open and party_split and modal.visible and game.coop.active and game.run_active

func party_panel_toggle():
	party_panel_open=not party_panel_open
	if party_panel_open: show_party_panel(game.party_seen)
	else: party_overlay.visible=false

func show_achievement_notification(ach_name: String, ach_desc: String):
	_ach_note_queue.append({"name":ach_name,"description":ach_desc})

func update_achievement_notification(delta: float):
	# Keep queued unlocks (and their sound) until the game is visible again.
	if modal.visible:
		_ach_note_panel.visible=false
		return
	if not _ach_note_active and not _ach_note_queue.is_empty():
		var achievement=_ach_note_queue.pop_front()
		_ach_note_name.text=achievement.name;_ach_note_desc.text=achievement.description
		_ach_note_timer=ACHIEVEMENT_DURATION;_ach_note_active=true
		game.sound.achievement_unlocked()
	if not _ach_note_active:
		_ach_note_panel.visible=false
		return
	_ach_note_timer=maxf(0,_ach_note_timer-delta)
	if _ach_note_timer<=0:
		_ach_note_active=false;_ach_note_alpha=0;_ach_note_panel.visible=false
		return
	var age=ACHIEVEMENT_DURATION-_ach_note_timer
	_ach_note_alpha=minf(clampf(age/.16,0,1),clampf(_ach_note_timer/.28,0,1))
	var ease=1-pow(1-_ach_note_alpha,3)
	var viewport_size=get_viewport().get_visible_rect().size
	var full_width=minf(640,viewport_size.x-48)
	var expansion=minf(clampf((age-.18)/.48,0,1),clampf((_ach_note_timer-.12)/.36,0,1))
	var width=lerpf(104,full_width,1-pow(1-expansion,3))
	_ach_note_row.size=Vector2(full_width-28,80)
	_ach_note_text.modulate.a=minf(clampf((age-.44)/.22,0,1),clampf((_ach_note_timer-.3)/.18,0,1))
	_ach_note_panel.size=Vector2(width,108)
	_ach_note_panel.position=Vector2((viewport_size.x-width)*.5,viewport_size.y-300+(1-ease)*18)
	_ach_note_panel.modulate.a=_ach_note_alpha;_ach_note_panel.visible=true

func level_flash():
	blast_time = .65
	game.sound.effect("level")

func update(delta: float):
	player_locator.queue_redraw()
	update_skill_strip()
	journey_overlay.queue_redraw()
	for widget in root.get_children():
		if widget is CanvasItem and widget!=modal and widget!=blast and widget!=_ach_note_panel and widget!=party_overlay: widget.visible=not modal.visible
	party_overlay.visible=party_visible()
	_ach_note_panel.visible=_ach_note_active and not modal.visible
	level_plate.visible=game.mode=="level_reveal"
	level_plate.text="LEVEL %d  ·  NEW POWER!" % game.level
	biome_label.text="The Red Moon" if game.realm==3 else RealmWorld.BIOMES[game.current_biome]
	var harvest_lines=[]
	for id in game.harvest_buffs:
		var entry=HarvestBook.TYPES[int(id)]
		harvest_lines.append("%s · %ds\n%s" % [entry.name,ceili(game.harvest_buffs[id]),entry.effect.replace(" for 20s","")])
	harvest_status.text="\n".join(harvest_lines);harvest_status.visible=not modal.visible and not harvest_lines.is_empty()
	if is_instance_valid(party_label): party_label.text=game.coop.status
	if game.mode=="coop" and is_instance_valid(party_list): update_party_list();update_lobby_controls()
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
		var benefit=UpgradeFit.for_key(game,str(PotionBook.TYPES[key].key))
		buff_widgets[key].text="%s\n%ds · %s" % [PotionBook.TYPES[key].name,ceil(game.buffs[key]),"Active" if benefit.useful else "No benefit"]
		buff_widgets[key].add_theme_color_override("font_color",ink if benefit.useful else Color("f49b86"))
		buff_widgets[key].get_parent().get_parent().tooltip_text=benefit.text
	health_text.text="HP  %d / %d" % [ceili(game.hp),roundi(game.stats.maxHp)]
	health_orb.fill=clampf(game.hp/maxf(1,game.stats.maxHp),0,1)
	health_orb.shield_fill=clampf(game.shield_hp/maxf(1,game.stats.shield),0,1);health_orb.queue_redraw()
	shield_text.text="SHIELD  %d / %d" % [ceili(game.shield_hp),ceili(game.stats.shield)]
	shield_text.visible=true
	armor_text.text="ARMOR  %d" % ceili(game.stats.armor)
	armor_text.visible=true
	clock.seconds = game.realm_time if game.realm==3 else maxf(0,600.0-game.realm_time)
	clock.realm = game.realm
	clock.bosses = game.realm_bosses
	clock.queue_redraw()
	xp.max_value = game.xp_target
	xp.value = game.xp
	status.text = "LV. %d" % game.level
	xp_text.text="%d / %d XP" % [floori(game.xp),game.xp_target]
	if game.xp>=game.xp_target and game.level_choice_cooldown>0:
		xp_text.text="Level ready in %ds · %d XP saved" % [ceili(game.level_choice_cooldown),floori(game.xp)]
	# The host is the source of truth for rescue progress; party snapshots
	# mirror it to clients. A meter is shown both for helper and downed hero.
	var rescue_id=0
	if game.coop.active:
		rescue_id=game.coop.local_id if game.update.downed else game.update.rescue_target(game.player.position,game.coop.local_id)
	var rescue_visible=rescue_id>0 and not modal.visible
	rescue_text.visible=rescue_visible
	rescue_meter.visible=rescue_visible
	if rescue_visible:
		var progress=float(game.update.rescue_progress.get(rescue_id,game.update.rescue_progress.get(str(rescue_id),0.0)))
		rescue_meter.value=clampf(progress,0,3)
		rescue_text.text=("BEING REVIVED" if game.update.downed else "REVIVING FRIEND")+"  ·  %.1f / 3.0s" % progress
	coins.text = "%d gold  ·  Chest %d  ·  %d left" % [game.gold,game.rules.chest_price(game.paid_chests,game.stats.discount),game.chests.filter(func(c):return not c.opened and not c.get("destroyed",false)).size()]
	box_counter.visible=false
	weapons.refresh()
	slam_status.visible=not modal.visible and game.mode=="playing"
	slam_status.text="[%s] SLAM · %s" % [ControlBindings.display(game.career.data.settings,"slam","controller" if game.input_kind=="xbox" else "keyboard"),"READY" if game.slam_cooldown<=0 else "%.1fs" % game.slam_cooldown]
	var turrets=game.equipped.filter(func(w):return w.turret)
	turret_hints.visible=not modal.visible and not turrets.is_empty()
	if turret_hints.visible:
		var selected=turrets[game.selected_turret%turrets.size()];var device="controller" if game.input_kind=="xbox" else "keyboard"
		var readiness="READY" if selected.deploy_clock<=0 else "%.1fs" % selected.deploy_clock
		turret_status.text="%s · %s\n[%s] Deploy   [%s] Switch turret" % [selected.name,readiness,ControlBindings.display(game.career.data.settings,"deploy",device),ControlBindings.display(game.career.data.settings,"next_turret",device)]
	if hint_device != game.input_kind:
		hint_device = game.input_kind;hints_until=game.elapsed+8
		var device="controller" if game.input_kind=="xbox" else "keyboard"
		for child in control_hints.get_children():
			control_hints.remove_child(child)
			child.queue_free()
		control_hints.add_child(label("Menu · Pause / controls" if game.input_kind=="xbox" else "Esc · Pause / controls",12))
		# InputGlyph updates itself; rebuilding choices here resets controller focus.
	control_hints.visible=not modal.visible
	prompt.visible=not modal.visible and not game.interaction_hint().is_empty()
	prompt.text = game.interaction_hint().replace("E / X", ControlBindings.display(game.career.data.settings,"interact","controller" if game.input_kind=="xbox" else "keyboard"))
	alert.visible=false
	alert.text = ""
	if game.coop.frozen() and game.mode=="playing": alert.text="PARTY PAUSED  ·  A FRIEND IS CHOOSING";alert.visible=true
	map_view.configure(game.world.seed_value,game.world.realm)
	map_view.interactables.clear()
	var hunt_shrine=game.Hunt.shrine(game)
	if hunt_shrine and game.Hunt.state(game) in ["idle","active"]: map_view.interactables.append({"position":hunt_shrine.position,"kind":"hunt"})
	if is_instance_valid(game.update.merchant): map_view.interactables.append({"position":game.update.merchant.position,"kind":"merchant"})
	if is_instance_valid(game.update.beacon) and game.update.beacon_state in ["idle","defending"]: map_view.interactables.append({"position":game.update.beacon_position,"kind":"supply"})
	if is_instance_valid(game.update.magnet_node) and not game.update.magnet_active: map_view.interactables.append({"position":game.update.magnet_node.position,"kind":"magnet"})
	if game.Hunt.state(game)=="active":
		for enemy in game.enemies:
			if not enemy.dead and enemy.net_id in game.events.get("hunt_ids",[]): map_view.interactables.append({"position":enemy.node.position,"kind":"hunt_target"})
	# Landmark groves are scenery now (the old ruins had rewards); they get no map flag.
	for pot in game.pots:
		if is_instance_valid(pot.node): map_view.interactables.append({"position":pot.node.position,"kind":"pot"})
	for drop in game.consumables:
		if is_instance_valid(drop.node): map_view.interactables.append({"position":drop.node.position,"kind":"potion"})
	map_view.camera_yaw=atan2(game.camera.global_basis.z.x,game.camera.global_basis.z.z)
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
	# Render damage numbers (2D UI - rise from bottom)
	for damage_label in damage_labels: damage_label.visible=false
	if game.damage_numbers and not modal.visible:
		for index in range(game.damage_numbers.size()):
			var dn=game.damage_numbers[index]
			# Color by damage type (from game.gd source of truth)
			var num_color = dn.get("color", Color("ffdd44"))
			var life_ratio = dn.life / dn.maxLife
			var val_text = str(dn.value)
			if index>=damage_labels.size():
				var pooled=Label.new();pooled.mouse_filter=Control.MOUSE_FILTER_IGNORE
				damage_font.font_names=PackedStringArray(["Segoe UI","Arial"]);damage_font.font_weight=800
				pooled.add_theme_font_override("font",damage_font)
				damage_overlay.add_child(pooled);damage_labels.append(pooled)
			var label=damage_labels[index]
			label.visible=true
			label.text = val_text
			# Font size: base 20, boosted for crit/slam, scaled by damage value
			var base_size = 42 if dn.get("size_boost",false) else 34
			label.add_theme_font_size_override("font_size", base_size + (3 if dn.value > 100 else (2 if dn.value > 50 else 0)))
			# Color: crit flashes red/gold, heal flashes green, others use source color
			if dn.cause=="crit": num_color=Color("ffe36a");label.text+="!"
			elif dn.cause=="heal": num_color=Color("a0ffb0");label.text="+"+label.text
			label.add_theme_color_override("font_color", num_color)
			# Outline color: darker version for contrast
			var outline_color = Color("222222")
			if dn.cause=="heal":
				outline_color = Color("114411")
			label.add_theme_color_override("font_outline_color", outline_color)
			label.add_theme_constant_override("outline_size", 6)
			label.add_theme_color_override("font_shadow_color",Color(0,0,0,.8))
			label.add_theme_constant_override("shadow_offset_y",3)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			# Emit above the occupied lower HUD, independent of actor/camera position.
			var screen_size=get_viewport().get_visible_rect().size
			var label_size=label.get_combined_minimum_size()
			var band_bottom=screen_size.y-210.0-floorf(float(dn.get("lane",0))/8.0)*56.0
			var rise=(1.0-life_ratio)*190.0*float(dn.get("fly_speed",1.0))
			label.position=Vector2(clampf(screen_size.x*dn.screen_x-label_size.x*.5,32,screen_size.x-label_size.x-32),band_bottom-label_size.y-rise)
			# A weapon's own hits rise from its slot icon; all other damage keeps the band above.
			var slot=weapons.slot_rect(str(dn.get("weapon_id",""))) if not str(dn.get("weapon_id","")).is_empty() else Rect2()
			if slot.size!=Vector2.ZERO:
				var top=damage_overlay.get_global_transform().affine_inverse()*Vector2(slot.get_center().x,slot.position.y)
				var spread=float(int(dn.get("lane",0))%3-1)*30.0
				var drawn=label.size.max(label_size)
				label.position=Vector2(top.x-drawn.x*.5+spread,top.y-drawn.y-rise)

			# Numbers pop in at full strength and fade out smoothly; crits shake briefly.
			label.modulate.a = smoothstep(0.0,.45,life_ratio)
			if dn.cause=="crit":
				var shake=clampf((life_ratio-.55)/.45,0.0,1.0)
				var t=Time.get_ticks_msec()*.001
				label.position+=Vector2(sin(t*71.0+index)*5.0,cos(t*53.0+index)*3.0)*shake

	if blast_time > 0:
		blast_time -= delta
		blast.color.a = 0
	else: blast.color.a = 0
	update_achievement_notification(delta)

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
	title.position=Vector2(114,82)
	modal.add_child(title)
	var strap=label("Grow strange. Fight hard. Start again.",18)
	strap.position=Vector2(120,188)
	strap.add_theme_color_override("font_color",Color("d6e2d4"))
	modal.add_child(strap)
	# Menu panels share the in-game window treatment: ink panel plus gilt forge frame.
	var nav_panel=PanelContainer.new()
	nav_panel.add_theme_stylebox_override("panel",style(ThemeTokens.INK,Color("9b855e"),12))
	modal.add_child(nav_panel)
	var nav=VBoxContainer.new()
	nav.custom_minimum_size=Vector2(326,0)
	nav.add_theme_constant_override("separation",12)
	nav_panel.add_child(nav)
	menu_start=button("START RUN",func():
		if game.coop.active and not game.coop.hosting: tell("The party host starts the run.")
		else: game.start_run()
	,true)
	nav.add_child(menu_start)
	nav.add_child(button("Achievements",func(): career_menu(false)))
	nav.add_child(button("Local scores",func(): career_menu(true)))
	if not game.career.data.lastRun.is_empty(): nav.add_child(button("Last run",last_run_menu))
	nav.add_child(button("Play with friends",coop_menu))
	nav.add_child(button("Sound & controls",settings_menu))
	nav.add_child(button("About Wildforge",about_menu))
	nav.add_child(button("Quit",func(): game.career.save();game.get_tree().quit()))
	nav_panel.position=Vector2(96,289);nav_panel.size=Vector2(374,nav.get_child_count()*54+36)
	var hero_panel=PanelContainer.new()
	hero_panel.position=Vector2(533,277)
	hero_panel.size=Vector2(1266,626)
	hero_panel.add_theme_stylebox_override("panel",style(ThemeTokens.INK,Color("9b855e"),12))
	modal.add_child(hero_panel)
	for framed in [nav_panel,hero_panel]:
		var frame=preload("res://scripts/forge_frame.gd").new();frame.panel=framed;frame.position=framed.position;frame.size=framed.size;frame.z_index=2;frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;modal.add_child(frame)
	var columns=HBoxContainer.new()
	columns.add_theme_constant_override("separation",29)
	hero_panel.add_child(columns)
	var hero_list=VBoxContainer.new()
	hero_list.custom_minimum_size.x=226
	hero_list.add_theme_constant_override("separation",6)
	var hero_scroll=ScrollContainer.new();hero_scroll.custom_minimum_size=Vector2(246,580);hero_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;columns.add_child(hero_scroll);hero_scroll.add_child(hero_list)
	hero_list.add_child(label("CHOOSE YOUR HERO",13))
	var selected_hero: Button
	for item in game.rules.data.heroes:
		var pick=button(item.name,func():game.select_hero(item);start_menu(true))
		if item.id==game.hero.id: selected_hero=pick
		if item.id==game.hero.id: pick.add_theme_stylebox_override("normal",style(ThemeTokens.BIOME_ACCENTS.verdant.blossom,ThemeTokens.EARTH_TERRACOTTA))
		hero_list.add_child(pick)
	portrait = HeroPortrait.new()
	portrait.custom_minimum_size=Vector2(426,560)
	columns.add_child(portrait)
	var preview_stats=game.rules.data.stats.duplicate(true);game.rules.apply_effects(preview_stats,game.hero.effects)
	portrait.setup(game.hero.model,game.hero.weapon,float(preview_stats.armor),float(preview_stats.shield))
	var bio=VBoxContainer.new()
	bio.custom_minimum_size.x=413
	bio.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	bio.add_theme_constant_override("separation",8)
	columns.add_child(bio)
	bio.add_child(label(game.hero.name,29))
	var description=label(game.hero.title,17)
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	bio.add_child(description)
	var perk=label(game.hero.perk,19,ThemeTokens.EARTH_TERRACOTTA);bio.add_child(perk)
	var perk_description=label(game.hero.description,15);perk_description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;bio.add_child(perk_description)
	var bonuses=game.hero.effects.filter(func(effect):return effect.key not in ["speed","jumpHeight"]).map(func(effect):return game.rules.describe(effect))
	var bonus_text=label("  •  ".join(bonuses),13);bonus_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;bio.add_child(bonus_text)
	var starter=HBoxContainer.new()
	var icon=PowerIcon.new()
	icon.key=game.hero.weapon;icon.weapon_icon=true
	icon.custom_minimum_size=Vector2(96,96)
	starter.add_child(icon)
	var weapon_name=game.rules.data.weapons.filter(func(w):return w.id==game.hero.weapon)[0].name
	starter.add_child(label("Starts with
"+weapon_name,16))
	bio.add_child(starter)
	var mechanics=label(WeaponDetails.describe(game.hero.weapon),16)
	mechanics.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	bio.add_child(mechanics)
	# Keep hero selection focused on the selected hero; repeat rules in Help only.
	var footer=HBoxContainer.new()
	footer.position=Vector2(120,997)
	modal.add_child(footer)
	add_prompts(footer,[["↑↓","D-pad","Navigate"],["Enter","A","Select"]])
	var version=label("v%s  ·  BUILD %d  ·  DEVELOPMENT ALPHA" % [ProjectSettings.get_setting("application/config/version"),ProjectSettings.get_setting("application/config/build_number",0)],14)
	version.name="ReleaseVersion";version.position=Vector2(1280,1026);version.size=Vector2(570,28);version.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	version.add_theme_color_override("font_color",Color("b4c9bc"))
	modal.add_child(version)
	if focus_hero and is_instance_valid(selected_hero):
		selected_hero.grab_focus()
		reveal_selection.call_deferred(hero_scroll,selected_hero)
	else: menu_start.grab_focus()

func coop_menu():
	game.mode="coop"
	var box=open("PLAY WITH FRIENDS","Choose a hero → Ready up → Host starts · Up to 4 players")
	var columns=HBoxContainer.new();columns.add_theme_constant_override("separation",32);box.add_child(columns)
	var heroes=VBoxContainer.new();heroes.custom_minimum_size.x=333;columns.add_child(heroes)
	heroes.add_child(label("YOUR HERO",14))
	portrait = HeroPortrait.new()
	portrait.custom_minimum_size=Vector2(333,220);heroes.add_child(portrait)
	portrait.setup(game.hero.model,game.hero.weapon,0,0)
	var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(333,300);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;heroes.add_child(scroll)
	var choices=VBoxContainer.new();choices.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(choices)
	var selected: Button
	for hero in game.rules.data.heroes:
		var pick=button(("✓ " if hero.id==game.hero.id else "")+hero.name,func():game.select_hero(hero);coop_menu())
		pick.disabled=game.run_active;choices.add_child(pick)
		if hero.id==game.hero.id: selected=pick
	var connection=VBoxContainer.new();connection.size_flags_horizontal=Control.SIZE_EXPAND_FILL;connection.add_theme_constant_override("separation",10);columns.add_child(connection)
	connection.add_child(label(game.hero.name+" · "+game.hero.perk,24))
	lobby_specialty=label(game.hero.description+"\n"+" · ".join(game.hero.effects.map(func(effect):return game.rules.describe(effect))),17)
	lobby_specialty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;connection.add_child(lobby_specialty)
	var starter=ContentExpansion.weapon(game.hero.weapon)
	var loadout=label("STARTING WEAPON · "+str(starter.get("name",game.hero.weapon))+"\n"+WeaponDetails.describe(game.hero.weapon),15)
	loadout.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;connection.add_child(loadout)
	party_label=label(game.coop.status,14);party_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;connection.add_child(party_label)
	connection.add_child(label("PLAYER NAME · SHOWN ABOVE YOU IN CO-OP",13))
	coop_name_input=LineEdit.new();coop_name_input.text=game.coop.player_name();coop_name_input.placeholder_text="Player name";coop_name_input.max_length=24;coop_name_input.custom_minimum_size=Vector2(340,36);connection.add_child(coop_name_input)
	coop_name_input.text_submitted.connect(func(value):save_coop_player_name(value))
	coop_name_input.focus_exited.connect(func():save_coop_player_name(coop_name_input.text) if is_instance_valid(coop_name_input) else null)
	var hosting_row=HBoxContainer.new();connection.add_child(hosting_row)
	hosting_row.add_child(button("HOST PARTY",func():save_coop_player_name(coop_name_input.text);game.coop.host_lan();game.coop.open_internet()))
	hosting_row.add_child(button("COPY INVITE CODE",func():
		if not game.coop.invite.is_empty(): DisplayServer.clipboard_set(game.coop.invite);tell("Invite code copied: "+game.coop.invite);return
		var addresses=game.coop.local_addresses()
		if game.coop.hosting and not addresses.is_empty(): DisplayServer.clipboard_set(addresses[0]);tell("No internet invite code · local address copied")
		else: tell("Host a party first")
	))
	var row=HBoxContainer.new();connection.add_child(row)
	var address=LineEdit.new();address.text=game.career.data.settings.get("coopAddress","");address.placeholder_text="Invite code (WF-…) or host IP";address.custom_minimum_size=Vector2(300,32);row.add_child(address)
	row.add_child(button("JOIN",func():save_coop_player_name(coop_name_input.text);game.coop.join_lan(address.text)))
	address.text_submitted.connect(func(value):save_coop_player_name(coop_name_input.text);game.coop.join_lan(value))
	connection.add_child(label("NEARBY PARTIES",13));party_list=VBoxContainer.new();connection.add_child(party_list);party_list_key=""
	game.coop.begin_discovery();update_party_list()
	connection.add_child(label("PARTY · HERO / STATUS",14))
	lobby_roster_label=label("",16);lobby_roster_label.custom_minimum_size.y=98;connection.add_child(lobby_roster_label)
	var actions=HBoxContainer.new();connection.add_child(actions)
	lobby_ready=button("READY",func():game.coop.set_ready(not game.coop.local_ready));actions.add_child(lobby_ready)
	lobby_start=button("START GAME",func():game.coop.start_party(),true);actions.add_child(lobby_start)
	connection.add_child(button("Leave party",func():game.coop.leave();game.coop.status="Solo"))
	var help=label("Internet: the host shares the invite code shown after HOST PARTY; friends paste it into Join. Same network: pick a nearby party. Friends can join a run already in progress. Hero changes clear your Ready status.",13)
	help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(help)
	box.add_child(button("Back",start_menu))
	update_lobby_controls()
	if selected!=null: selected.grab_focus();reveal_selection.call_deferred(scroll,selected)

func update_lobby_controls():
	if not is_instance_valid(lobby_ready): return
	lobby_ready.disabled=not game.coop.active or game.run_active or (not game.coop.hosting and not game.coop.welcomed)
	lobby_ready.text="READY ✓ · CANCEL" if game.coop.local_ready else "READY"
	lobby_start.disabled=not game.coop.can_start()
	lobby_start.text="START GAME" if game.coop.hosting else "HOST STARTS GAME"
	var lines=[]
	for member in game.coop.lobby_roster:
		lines.append(("Host" if member.host else "Player")+" · "+str(member.name)+" ("+str(member.get("hero","Hero"))+") · "+("READY" if member.ready else "Not ready"))
	lobby_roster_label.text="Host or join a party to ready up." if lines.is_empty() else "\n".join(lines)

func save_coop_player_name(value: String):
	var cleaned=game.coop.clean_player_name(value)
	if game.career.data.settings.get("name","")==cleaned: return
	game.career.data.settings.name=cleaned;game.career.dirty=true;game.career.save()
	if is_instance_valid(coop_name_input) and coop_name_input.text!=cleaned: coop_name_input.text=cleaned
	game.coop.name_changed()

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
	var extra=" · Deaths %d" % game.death_count
	var score=game.career.data.scores.filter(func(entry):return entry.id==game.run_id)
	if not score.is_empty():
		extra+=" · Best run %02d:%02d" % [int(game.career.data.best.get("best_seconds",0))/60,int(game.career.data.best.get("best_seconds",0))%60]
		extra+=" · Level %d" % game.career.data.best.get("max_level",0)
		extra+=" · %d kills" % game.career.data.total.get("kills",0)
	var box = open("YOU WON" if win else "TRY AGAIN" if ended else "PAUSED", "%s · %d coins · %d enemies · ★ %d%s" % [game.hero.name,game.gold,game.kills,game.level,extra])
	if ended: box.add_child(label(game.update.recap(),15))
	if not ended: box.add_child(button("▶  CONTINUE",close,true))
	box.add_child(button("HERO STATS & EQUIPMENT",func():build_menu(true)))
	box.add_child(button("RUN REPORT",run_report_menu))
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
	var compact=game.coop.active and game.run_active
	var accent=RunRules.COLORS[item.tier]
	card.custom_minimum_size=Vector2(0,390 if compact and get_viewport().get_visible_rect().size.y<850 else 440 if compact else 480)
	card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	# Rarity glow: inner shadow + colored top bar
	var normal=style(paper.lerp(accent,.06),accent,12);normal.border_width_top=5
	normal.shadow_color=Color(accent,.35);normal.shadow_size=6;normal.shadow_offset=Vector2i(0,3)
	card.add_theme_stylebox_override("normal",normal)
	var hover=style(paper.lerp(accent,.14),accent,12);hover.set_border_width_all(3);hover.border_width_top=5
	hover.shadow_color=Color(accent,.5);hover.shadow_size=10;hover.shadow_offset=Vector2i(0,4)
	card.add_theme_stylebox_override("hover",hover)
	card.add_theme_stylebox_override("pressed",hover)
	var focus=StyleBoxFlat.new();focus.bg_color=Color(accent,.08);focus.border_color=accent;focus.set_border_width_all(4);focus.set_corner_radius_all(3)
	focus.shadow_color=Color(accent,.6);focus.shadow_size=14;focus.shadow_offset=Vector2i(0,0)
	card.add_theme_stylebox_override("focus",focus)
	var column=VBoxContainer.new();card.add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left=10 if compact else 21;column.offset_right=-10 if compact else -21;column.offset_top=12 if compact else 18;column.offset_bottom=-12 if compact else -18
	column.mouse_filter=Control.MOUSE_FILTER_IGNORE;column.add_theme_constant_override("separation",5 if compact else 8)
	# Rarity bar with glow
	var rarity=label(RunRules.RARITIES[item.tier].to_upper()+"   ·   #"+str(index+1),12,accent.darkened(.4))
	rarity.add_theme_color_override("font_outline_color",accent);rarity.add_theme_color_override("font_outline_color",accent)
	rarity.add_theme_font_size_override("font_size",12)
	rarity.add_theme_color_override("font_color",accent.lightened(.3))
	column.add_child(rarity)
	# Icon with subtle background
	var icon_bg=ColorRect.new()
	icon_bg.color=Color(paper.r,paper.g,paper.b,.85)
	icon_bg.custom_minimum_size=Vector2(76,92) if compact else Vector2(138,176)
	var radius=StyleBoxFlat.new();radius.bg_color=Color(accent,.12);radius.set_corner_radius_all(8);radius.set_border_width_all(1);radius.border_color=accent.darkened(.3)
	icon_bg.add_theme_stylebox_override("normal",radius)
	column.add_child(icon_bg)
	var icon=PowerIcon.new();icon.key=icon_key(item);icon.weapon_icon=item.kind=="weapon"
	icon_bg.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left=10;icon.offset_top=10;icon.offset_right=-10;icon.offset_bottom=-10
	var title=label(item.name,16 if compact else 20);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.custom_minimum_size.y=44 if compact else 58
	title.add_theme_color_override("font_outline_color",ink);title.add_theme_color_override("font_outline_color",ink)
	column.add_child(title)
	var effect_desc=""
	if item.kind!="weapon" and item.has("effects") and item.effects.size()>0: effect_desc=game.rules.describe(item.effects[0])
	var text=WeaponDetails.describe(item.id) if item.kind=="weapon" else effect_desc
	var description=label(text,11 if compact else 14);description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;description.max_lines_visible=4;description.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;card.tooltip_text=text;description.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(description)
	var note=item.kind.capitalize()+" · "+str(item.get("family","Weapon"))
	if item.kind=="weapon":
		var owned=game.equipped.filter(func(w):return w.id==item.id)
		if not owned.is_empty():
			note="Equipped: Rank %d → %d" % [owned[0].rank,owned[0].rank+1]
		elif game.equipped.size()>=3:
			note="New weapon — full slot required"
		else:
			note="New weapon — fills empty slot"
	var useful=true
	if item.kind!="weapon":
		var fit=UpgradeFit.describe(game,item);note=fit.text;useful=fit.useful
	var footer=label(note,12 if compact else 15,Color("8ee4b3") if useful else Color("973426"))
	footer.name="LoadoutBenefit";footer.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;footer.custom_minimum_size.y=48 if compact else 68
	footer.max_lines_visible=4;footer.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(footer);card.tooltip_text+="\n"+note
	# Hover scale-up via tween
	card.mouse_entered.connect(func():
		if game.input_kind!="xbox": card.grab_focus()
		card.create_tween().tween_property(card,"scale",Vector2(1.03,1.03),.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	)
	card.mouse_exited.connect(func():
		if game.input_kind!="xbox": card.create_tween().tween_property(card,"scale",Vector2.ONE,.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
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
		var candidate=game.stats.duplicate(true);game.rules.apply_effects(candidate,item.get("effects",[]))
		var effects=item.get("effects",[])
		var effect={} if effects.is_empty() else effects[0]
		var source=game.rules.loot_by_id.get(item.id,{})
		comparison=game.rules.describe(effect) if effect else ""
		comparison+=" · "+UpgradeFit.describe(game,item).text
		if effect and not str(effect.key).begins_with("augment-") and not str(effect.key).begins_with("mut:"): comparison+="  ·  Current %s → %s" % [snappedf(game.stats.get(effect.key,0),.01),snappedf(candidate.get(effect.key,0),.01)]
		if not source.is_empty() and item.tier>0 and source.has("effects") and source.effects.size()>0: comparison+="  ·  Common version: "+game.rules.describe(source.effects[0])
	var detail=label(comparison,15);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;offer_detail.add_child(detail)

func show_offers(items: Array, source: String,animate: bool=true):
	var coop_split=game.coop.active and game.run_active
	var box=open("LEVEL %d · CHOOSE YOUR NEXT POWER" % game.level if source=="level" else "TREASURE FOUND", "Choose one reward. Shape your next fight.")
	if coop_split: game.coop.publish_reward_options(items,source,game.offer_kind,game.offer_elite)
	var panel=box.get_parent();panel.position=Vector2(80,83);panel.size=Vector2(1760,914)
	if coop_split:
		var viewport=get_viewport().get_visible_rect().size
		panel.position=Vector2(16,16);panel.size=Vector2(viewport.x*.65,viewport.y-32)
		for frame in modal.get_children():
			if frame.get_script()!=null and str(frame.get_script().resource_path).ends_with("forge_frame.gd"): frame.position=panel.position;frame.size=panel.size
		party_panel_open=true;party_split=true;show_party_panel(game.party_seen)
	panel.add_theme_stylebox_override("panel",style(ThemeTokens.INK,Color("9b855e"),22))
	box.get_child(0).add_theme_color_override("font_color",ThemeTokens.PAPER)
	box.get_child(1).add_theme_color_override("font_color",Color("b5c5cf"))
	box.add_theme_constant_override("separation",8 if coop_split else 16)
	var choices=HBoxContainer.new();choices.add_theme_constant_override("separation",8 if coop_split else 16);box.add_child(choices)
	for i in range(items.size()): choices.add_child(offer_card(items[i],i,func():game.choose_offer(i)))
	var detail_panel=PanelContainer.new();detail_panel.custom_minimum_size.y=64 if coop_split else 95
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
		if card.size.x<150 or card.size.y<220: return false
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
		display.custom_minimum_size=Vector2(1226,453)
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

func report_scroll(box: VBoxContainer) -> VBoxContainer:
	var scroll=ScrollContainer.new();scroll.custom_minimum_size.y=420;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(scroll)
	var rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",8);scroll.add_child(rows)
	var paging=HBoxContainer.new();box.add_child(paging)
	paging.add_child(button("PAGE UP",func():scroll.scroll_vertical=maxi(0,scroll.scroll_vertical-300)))
	paging.add_child(button("PAGE DOWN",func():scroll.scroll_vertical+=300))
	return rows

func stat_table_row(rows: VBoxContainer, values: Array, heading: bool=false):
	var row=HBoxContainer.new();rows.add_child(row)
	for i in range(values.size()):
		var cell=label(str(values[i]),14 if heading else 15)
		cell.custom_minimum_size.x=210 if i==0 else 105
		row.add_child(cell)

func build_menu(return_to_pause: bool=false,detailed: bool=false):
	game.mode="build"
	var box=open("YOUR HERO","Current combat stats and equipment" if not detailed else "Base + Hero + Gear/run + Buffs + Augments = Total")
	var rows=report_scroll(box)
	rows.add_child(label("%s · HP %d / %d · Shield %d" % [game.hero.name,game.hp,game.stats.maxHp,game.shield_hp],20))
	if detailed:
		stat_table_row(rows,["STAT","BASE","HERO","GEAR/RUN","BUFFS","AUGMENTS","TOTAL"],true)
		for entry in RunReport.stat_rows(game): stat_table_row(rows,[entry.name,snappedf(entry.base,.01),snappedf(entry.hero,.01),snappedf(entry.gear,.01),snappedf(entry.buff,.01),snappedf(entry.augment,.01),snappedf(entry.total,.01)])
	else:
		var grid=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",28);rows.add_child(grid)
		for entry in RunReport.stat_rows(game):
			if entry.key in ["damage","rate","speed","armor","regen","airJumps"]:
				var stat_label=label({"rate":"Attack rate","speed":"Move speed","regen":"Regeneration"}.get(entry.key,entry.name)+"   "+str(snappedf(entry.total,.01)),18);stat_label.custom_minimum_size.x=275;grid.add_child(stat_label)
	box.add_child(button("SHOW ALL STAT DETAILS" if not detailed else "SIMPLE VIEW",func():build_menu(return_to_pause,not detailed)))
	rows.add_child(label("WEAPONS",18))
	for i in range(game.equipped.size()):
		var weapon=game.equipped[i]
		var kind=ContentExpansion.kind(weapon.id)
		var power=game.stat("damage")*weapon.damage*weapon.power*float(game.stats.get(kind+"Power",1))*(game.stat("turretDamage") if weapon.turret else 1.)
		var rate=weapon.rate*game.stat("turretRate" if weapon.turret else "rate")
		var reach=weapon.range*game.stat("range")/18.*(game.stat("turretRange") if weapon.turret else 1.)
		icon_text_row(rows,weapon.id,true,"%s · Rank %d" % [weapon.name,weapon.rank])
		if detailed: rows.add_child(label("Power %.1f · Rate %.2f/s · Reach %.1fm" % [power,rate,reach],16))
		if detailed:
			var detail=label(WeaponDetails.describe(weapon.id),14);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;rows.add_child(detail)
	rows.add_child(label("OWNED ITEMS & SKILLS",18))
	for item in game.owned:
		icon_text_row(rows,icon_key(item),false,item.name+(" · "+game.rules.describe(item.effects[0]) if detailed else ""))
	var back=button("BACK",func():pause_menu(game.run_recorded) if return_to_pause else close(),true);box.add_child(back);back.grab_focus()

func run_report_menu():
	game.mode="build"
	if game.run_recorded and game.run_active: game.career.bump("run_reports_viewed")
	var score=game.career.data.scores.filter(func(entry):return entry.id==game.run_id)
	var summary="%d:%02d played · %d kills · %d gold · Deaths %d" % [int(game.elapsed)/60,int(game.elapsed)%60,game.kills,game.gold,game.death_count]
	if not score.is_empty():
		summary+=" · Score %d · Local rank #%d" % [score[0].score,game.career.data.scores.find(score[0])+1]
	var box=open("RUN REPORT",summary);var rows=report_scroll(box)
	rows.add_child(label("SURVIVED %02d:%02d · %d BOSS PHASES · %d REVIVES · %d RESCUES" % [int(game.elapsed)/60,int(game.elapsed)%60,game.boss_phases_reached,game.update.run_revives,game.update.run_rescues],16))
	rows.add_child(label("YOUR CONTRIBUTION · %d damage · PARTY TOTAL %d damage" % [game.update.run_damage,game.update.party_damage],15))
	rows.add_child(label("YOUR DAMAGE BY WEAPON / EFFECT",18))
	for entry in RunReport.ranked_damage(game):
		var weapon=game.rules.data.weapons.any(func(w):return w.id==entry.source)
		var key=str(entry.source).trim_prefix("effect:")
		key={"fire":"burn","stomp":"slamPower","melee":"damage","hit":"damage"}.get(key,key)
		if not weapon:
			var matching=game.rules.data.loot.filter(func(i):return i.kind=="skill" and i.effects[0].key==key)
			if not matching.is_empty(): key=matching[0].id
		icon_text_row(rows,key,weapon,"%s · %d damage" % [entry.name,entry.amount])
	rows.add_child(label("CHOSEN SKILLS",18))
	for item in game.owned:
		if item.kind=="skill": icon_text_row(rows,icon_key(item),false,item.name)

	if game.damage_sources.is_empty(): rows.add_child(label("No damage recorded yet.",16))
	rows.add_child(label("ENEMIES DEFEATED",18))
	if game.kill_types.is_empty(): rows.add_child(label("No enemies defeated.",16))
	else:
		for key in game.kill_types: rows.add_child(label("%s · %d" % [key,game.kill_types[key]],16))
	rows.add_child(label("Score: 20×kills + gold + 2×seconds + level/boss/chest/victory bonuses.",14))
	var back=button("BACK",func():pause_menu(game.run_recorded,not score.is_empty() and score[0].win),true);box.add_child(back);back.grab_focus()

func party_builds_menu():
	if not game.coop.active: return
	game.mode="build"
	var members=game.coop.party_builds()
	var complete=members.size()>1
	for member in members:
		if int(member.id)!=game.coop.local_id and (not member.build is Dictionary or not member.build.has("weapons") or not member.build.has("skills")): complete=false
	if complete: game.career.bump("party_builds_viewed")
	var box=open("PARTY BUILDS", "Current weapons and skills · refreshed from each player")
	var rows=report_scroll(box)
	for member in members:
		var build=member.build if member.build is Dictionary else {}
		rows.add_child(label(str(member.name)+(" · YOU" if int(member.id)==game.coop.local_id else ""),20))
		var weapon_names=[]
		for item in build.get("weapons",[]):
			var catalog=game.rules.data.weapons.filter(func(weapon):return weapon.id==str(item.get("id","")))
			weapon_names.append((str(catalog[0].name) if not catalog.is_empty() else str(item.get("id","Weapon"))+" · UNKNOWN")+" R"+str(item.get("rank",1)))
		rows.add_child(label("WEAPONS · "+(" · ".join(weapon_names) if not weapon_names.is_empty() else "None yet"),16))
		rows.add_child(label("SKILLS · "+(" · ".join(build.get("skills",[])) if not build.get("skills",[]).is_empty() else "None yet"),15))
	if not complete and members.size()>1: rows.add_child(label("Waiting for a teammate’s next status update…",14))
	rows.add_child(label("Achievement: inspect every teammate’s build · %d / 1" % int(game.career.data.total.get("party_builds_viewed",0)),14))
	var back=button("BACK",func():close(),true);box.add_child(back);back.grab_focus()

func last_run_menu():
	game.mode="build"
	var run=game.career.data.lastRun
	if run.is_empty(): start_menu();return
	var heroes=game.rules.data.heroes.filter(func(h):return h.id==run.hero)
	var hero_name=heroes[0].name if not heroes.is_empty() else str(run.hero).capitalize()
	var outcome="VICTORY" if run.get("win",false) else "LEFT RUN" if run.get("abandoned",false) else "DEFEATED"
	var summary="%s · %s · %d:%02d · Level %d · Deaths %d" % [hero_name,outcome,int(run.seconds)/60,int(run.seconds)%60,run.level,run.get("deaths",0)]
	var box=open("LAST RUN",summary);var rows=report_scroll(box)
	rows.add_child(label("%s · %d kills · %d coins · Score %d" % [run.get("date",""),run.kills,run.get("gold",0),run.score],18))
	rows.add_child(label("%d boss phases · %d revives · %d rescues · %d damage dealt · %d party damage" % [int(run.get("bossPhases",0)),int(run.get("revives",0)),int(run.get("rescues",0)),int(run.get("localDamage",0)),int(run.get("partyDamage",0))],15))
	rows.add_child(label("YOUR DAMAGE BY WEAPON / EFFECT",18))
	var sources=run.get("damageSources",{});var keys=sources.keys()
	keys.sort_custom(func(a,b):return sources[a]>sources[b])
	for key in keys: rows.add_child(label("%s · %d damage" % [RunReport.source_name(game,key),sources[key]],16))
	if sources.is_empty(): rows.add_child(label("No damage recorded.",16))
	rows.add_child(label("ENEMIES DEFEATED",18))
	var kills_by_type=run.get("killTypes",{})
	if kills_by_type.is_empty(): rows.add_child(label("No enemies defeated.",16))
	else:
		for key in kills_by_type: rows.add_child(label("%s · %d" % [key,kills_by_type[key]],16))
	var back=button("BACK",start_menu,true);box.add_child(back);back.grab_focus()

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
	for genre in ["metal","cyber"]: genres.add_child(button("PHONK" if genre == "metal" else "PHONK SOFT",func(): game.career.data.settings.genre=genre;game.career.dirty=true;game.sound.start(randi())))
	box.add_child(genres)
	var cosmetic_row=HBoxContainer.new();box.add_child(cosmetic_row)
	cosmetic_row.add_child(label("ACHIEVEMENT STYLE · %d / 8 EARNED" % mini(8,game.career.data.cosmetics.size()),16))
	var cosmetics={"mastery_crown":"Mastery Crown","formation_gold":"Formation Gold","biome_prism":"Biome Prism","ping_star":"Ping Star","party_banner":"Party Banner","comeback_flame":"Comeback Flame","scout_visor":"Scout Visor","recap_medal":"Recap Medal"}
	var picker=OptionButton.new();achievement_cosmetic_picker=picker;picker.add_item("Default");picker.set_item_metadata(0,"")
	for id in cosmetics:
		if game.career.data.cosmetics.has(id): picker.add_item(cosmetics[id]);picker.set_item_metadata(picker.item_count-1,id)
	for index in range(picker.item_count):
		if str(picker.get_item_metadata(index))==str(game.career.data.settings.get("cosmetic","")): picker.select(index)
	picker.disabled=picker.item_count==1
	picker.item_selected.connect(func(index):game.career.data.settings.cosmetic=str(picker.get_item_metadata(index));game.career.dirty=true;game.career.save();game.coop.sync_local_nameplate())
	cosmetic_row.add_child(picker)
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
	# Comfort and performance: one compact row so the menu still fits at 720p.
	var effects=HBoxContainer.new();effects.add_theme_constant_override("separation",10);box.add_child(effects)
	effects.add_child(label("Effects",18))
	for setting in [["shake","Shake",0.0],["flashes","Flashes",0.0],["particles","Particles",.25]]:
		effects.add_child(label(setting[1],15))
		var amount=HSlider.new();amount.min_value=setting[2];amount.max_value=1;amount.step=.05
		amount.value=float(game.career.data.settings.get(setting[0],1.0));amount.custom_minimum_size.x=150;amount.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		amount.value_changed.connect(func(value): game.career.data.settings[setting[0]]=value;game.career.dirty=true;EffectDetail.load_settings(game.career.data.settings))
		effects.add_child(amount)
	box.add_child(button("REMAP KEYBOARD / CONTROLLER",bindings_menu))
	box.add_child(label("Mouse: look · Escape / Menu: pause or back · Enter / A: select",16))
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
			icon.texture=load("res://assets/illustrated/achievements/"+achievement.id+".svg")
			if not unlocked: icon.modulate=Color(.42,.49,.52)
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

func bindings_menu(message: String="",focus_key: String=""):
	game.mode="bindings"
	var box=open("CONTROLS","Select an input to change it. Conflicts swap. Escape / Menu always pause or go back.")
	binding_buttons.clear()
	var rows=report_scroll(box)
	var heading=HBoxContainer.new();rows.add_child(heading)
	for caption in ["ACTION","KEYBOARD / MOUSE","CONTROLLER"]:
		var title=label(caption,15);title.custom_minimum_size.x=280;heading.add_child(title)
	for action in ControlBindings.KEYS:
		var row=HBoxContainer.new();rows.add_child(row)
		var name_label=label(ControlBindings.LABELS[action],17);name_label.custom_minimum_size.x=280;row.add_child(name_label)
		for device in ["keyboard","controller"]:
			var pick=button(ControlBindings.display(game.career.data.settings,action,device),func():begin_binding(action,device))
			pick.custom_minimum_size.x=280;row.add_child(pick);binding_buttons[action+":"+device]=pick
	binding_status=label(message if message!="" else "Choose a binding above. Press Escape or Menu to cancel capture.",15);box.add_child(binding_status)
	var actions=HBoxContainer.new();box.add_child(actions)
	actions.add_child(button("RESET DEFAULTS",func():
		game.career.data.settings.bindings={};ControlBindings.apply(game.career.data.settings);game.career.dirty=true;game.career.save();hint_device="";bindings_menu("Default controls restored")
	))
	actions.add_child(button("BACK",settings_menu))
	if binding_buttons.has(focus_key): binding_buttons[focus_key].grab_focus()
	else: binding_buttons["move_left:keyboard"].grab_focus()

func begin_binding(action: String,device: String):
	binding_action=action;binding_device=device;binding_axes.clear()
	for axis in range(6): binding_axes[axis]=absf(Input.get_joy_axis(game.controller_id,axis))<.25
	binding_buttons[action+":"+device].text="Press an input…"
	binding_status.text="Press a key or mouse button. Escape cancels." if device=="keyboard" else "Press a controller button or move a stick / trigger. Menu cancels."

func capture_binding(event: InputEvent) -> bool:
	if binding_action=="": return false
	if event is InputEventKey and event.pressed and event.physical_keycode==KEY_ESCAPE or event is InputEventJoypadButton and event.pressed and event.button_index==JOY_BUTTON_START:
		bindings_menu("Binding unchanged",binding_action+":"+binding_device);return true
	var value={}
	if binding_device=="keyboard":
		if event is InputEventKey and event.pressed and not event.echo: value={"type":"key","code":event.physical_keycode if event.physical_keycode!=0 else event.keycode}
		elif event is InputEventMouseButton and event.pressed and event.button_index in [1,2,3,8,9]: value={"type":"mouse","code":event.button_index}
	else:
		if event is InputEventJoypadButton and event.pressed: value={"type":"button","code":event.button_index}
		elif event is InputEventJoypadMotion:
			if absf(event.axis_value)<.25: binding_axes[event.axis]=true
			elif absf(event.axis_value)>.75 and binding_axes.get(event.axis,false): value={"type":"axis","code":event.axis,"sign":1 if event.axis_value>0 else -1}
	if not value.is_empty():
		var key=binding_action+":"+binding_device
		var result=ControlBindings.bind(game.career.data.settings,binding_action,binding_device,value)
		game.career.dirty=true;game.career.save();hint_device="";bindings_menu(result,key)
	return true

func icon_text_row(rows: VBoxContainer,key: String,weapon: bool,text: String):
	var row=HBoxContainer.new();rows.add_child(row)
	var icon=PowerIcon.new();icon.key=key;icon.weapon_icon=weapon;icon.custom_minimum_size=Vector2(38,38);row.add_child(icon)
	var title=label(text,17);title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(title)

func update_skill_strip():
	skill_strip.visible=not modal.visible and game.run_active
	var skills={}
	# Mutations first: they define how this run plays.
	for kind in ["mutation","skill"]:
		for item in game.owned:
			if item.kind==kind:
				if not skills.has(item.id): skills[item.id]={"item":item,"count":0}
				skills[item.id].count+=1
	var signature=str(skills.keys())+str(skills.values().map(func(v):return v.count))
	if signature==skill_strip_key: return
	skill_strip_key=signature
	for child in skill_strip.get_children(): skill_strip.remove_child(child);child.queue_free()
	var index=0
	for entry in skills.values():
		if index>=18: break
		var tile=Control.new();tile.custom_minimum_size=Vector2(30,34);tile.tooltip_text=str(entry.item.get("title",entry.item.name))+(" · Lv " if entry.item.kind=="mutation" else " ×")+str(entry.count);skill_strip.add_child(tile)
		var icon=PowerIcon.new();icon.key=icon_key(entry.item);icon.size=Vector2(30,30);tile.add_child(icon)
		if entry.count>1:
			var count_label=label(str(entry.count),12);count_label.position=Vector2(20,20);tile.add_child(count_label)
		index+=1
	if skills.size()>18: skill_strip.add_child(label("+"+str(skills.size()-18),14))

func about_menu():
	var box=open("ABOUT WILDFORGE", "Grow strange. Fight hard. Start again.")
	box.add_child(label("Version %s · Build %d" % [ProjectSettings.get_setting("application/config/version"),ProjectSettings.get_setting("application/config/build_number",0)],24,ThemeTokens.STAR_GOLD))
	for text in ["25 heroes · 69 weapons · %d mutations · 738 upgrades · 6 biomes · 9 bosses" % MutationBook.all().size(), "Original angular artwork, engraved icons and vivid combat effects.", "Hero and enemy health is shown in glass orbs. Your camera controls stay familiar.", "Created by Rytis with AI-assisted code and original procedural artwork.", "Original synthesized achievement chime. Voice attribution and licenses ship with the game."]:
		var line=label(text,20);line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;box.add_child(line)
	box.add_child(button("BACK",start_menu,true));box.get_child(box.get_child_count()-1).grab_focus()

func reveal_selection(scroll: ScrollContainer,selected: Control):
	# The rebuilt list needs its container layout before its scroll range is valid.
	await get_tree().process_frame
	await get_tree().process_frame
	if is_instance_valid(scroll) and is_instance_valid(selected): scroll.ensure_control_visible(selected)

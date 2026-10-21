extends HBoxContainer
class_name WeaponBar

var signature = ""
var game

# Screen rectangle of an equipped weapon's slot; damage numbers rise from it.
func slot_rect(weapon_id: String) -> Rect2:
	for panel in get_children():
		if panel.get_meta("weapon_id","")==weapon_id and not panel.is_queued_for_deletion(): return panel.get_global_rect()
	return Rect2()

func refresh():
	var turrets=game.equipped.filter(func(w):return w.turret)
	var selected=turrets[game.selected_turret%turrets.size()] if not turrets.is_empty() else {}
	var next = str(selected.get("id",""))+":"+str(ceili(selected.get("deploy_clock",0)))+":"
	for weapon in game.equipped: next += weapon.id+str(weapon.rank)+";"
	if next==signature and get_child_count()==3: return
	# Track which slots are newly filled for entrance animation
	var new_slots: Array[int]=[]
	if next!=signature:
		for i in range(3):
			if i<game.equipped.size() and (i>=signature.split(";",false).size()):
				new_slots.append(i)
	signature = next
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for i in range(3):
		var filled = i < game.equipped.size()
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(116,78)
		panel.add_theme_stylebox_override("panel",game.hud.style(ThemeTokens.PAPER_RUNTIME,Color("a7885c") if filled else Color("b9ad93"),12))
		# Subtle entrance pop for newly equipped weapons
		if filled and new_slots.has(i):
			panel.scale=Vector2(.88,.88)
			panel.create_tween().tween_property(panel,"scale",Vector2.ONE,.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		add_child(panel)
		var column = VBoxContainer.new()
		column.add_theme_constant_override("separation",0)
		panel.add_child(column)
		if filled:
			var weapon = game.equipped[i]
			panel.set_meta("weapon_id",weapon.id)
			if weapon.id==selected.get("id",""):
				var selected_style=game.hud.style(ThemeTokens.PAPER_RUNTIME,ThemeTokens.STAR_GOLD,3);selected_style.set_border_width_all(2)
				panel.add_theme_stylebox_override("panel",selected_style);panel.set_meta("selected_turret",true)
				var selected_label=game.hud.label("SELECTED",11,ThemeTokens.STAR_GOLD);selected_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;column.add_child(selected_label)
			panel.tooltip_text = weapon.name+" · Level "+str(weapon.rank)+"\n"+WeaponDetails.describe(weapon.id)
			var icon = PowerIcon.new()
			icon.key = weapon.id
			icon.weapon_icon = true
			icon.color = PowerIcon.color_for(icon.key)
			icon.custom_minimum_size = Vector2(88,48)
			column.add_child(icon)
			var badge = game.hud.label("Lv. %d" % weapon.rank,13,ThemeTokens.STAR_GOLD)
			badge.position=Vector2(65,0)
			icon.add_child(badge)
			var name_label = game.hud.label(weapon.name,12)
			name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			column.add_child(name_label)
		else:
			var empty=game.hud.label("+\nEMPTY SLOT",12,Color("a1ada8"))
			empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			column.add_child(empty)

extends HBoxContainer
class_name WeaponBar

var signature = ""
var game

func refresh():
	var next = ""
	for weapon in game.equipped: next += weapon.id+str(weapon.rank)+";"
	if next == signature: return
	signature = next
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for i in range(3):
		var filled = i < game.equipped.size()
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(116,78)
		panel.add_theme_stylebox_override("panel",game.hud.style(Color("f6eddc"),Color("a7885c") if filled else Color("b9ad93"),12))
		add_child(panel)
		var column = VBoxContainer.new()
		column.add_theme_constant_override("separation",0)
		panel.add_child(column)
		if filled:
			var weapon = game.equipped[i]
			panel.tooltip_text = weapon.name+" · Level "+str(weapon.rank)+"\n"+WeaponDetails.describe(weapon.id)
			var icon = PowerIcon.new()
			icon.key = weapon.id
			icon.weapon_icon = true
			icon.color = PowerIcon.color_for(icon.key)
			icon.custom_minimum_size = Vector2(88,48)
			column.add_child(icon)
			var badge = game.hud.label("Lv. %d" % weapon.rank,13,Color("574536"))
			badge.position=Vector2(65,0)
			icon.add_child(badge)
			var name_label = game.hud.label(weapon.name,12)
			name_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			column.add_child(name_label)
		else:
			var empty=game.hud.label("+\nEMPTY SLOT",12,Color("8c7861"))
			empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			column.add_child(empty)

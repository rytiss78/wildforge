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
	for weapon in game.equipped: next += weapon.id+str(weapon.rank)+("*" if weapon.get("evolved",false) else "!" if WeaponEvolution.ready(game,weapon) else "")+";"
	if next==signature and get_child_count()==RunRules.WEAPON_CAP: return
	# Track which slots are newly filled for entrance animation
	var new_slots: Array[int]=[]
	if next!=signature:
		for i in range(RunRules.WEAPON_CAP):
			if i<game.equipped.size() and (i>=signature.split(";",false).size()):
				new_slots.append(i)
	signature = next
	for child in get_children():
		remove_child(child)
		child.queue_free()
	# Four slots since big update MB, a little narrower to fit beside the key hints.
	# Minimal tiles like the card slots (user, November 3: "the four card slots
	# are very minimal, I like that; make the weapons minimal too"): the weapon's
	# picture and its level, nothing written; the name and details in the tooltip.
	for i in range(RunRules.WEAPON_CAP):
		var filled = i < game.equipped.size()
		var panel = PanelContainer.new()
		panel.custom_minimum_size = TILE
		panel.add_theme_stylebox_override("panel",tile_style(ThemeTokens.STAR_GOLD if filled else Color(ThemeTokens.STAR_GOLD,.3),.85 if filled else .35,2))
		if filled and new_slots.has(i):
			panel.pivot_offset=TILE*.5;panel.scale=Vector2(.8,.8)
			panel.create_tween().tween_property(panel,"scale",Vector2.ONE,.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		add_child(panel)
		if not filled:
			var empty=game.hud.label("+",20,Color(1,1,1,.25))
			empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;empty.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
			panel.add_child(empty)
			continue
		var weapon = game.equipped[i]
		panel.set_meta("weapon_id",weapon.id)
		panel.tooltip_text = weapon.name+" · Level "+str(weapon.rank)+"\n"+WeaponDetails.describe(weapon.id)
		var recipe=WeaponEvolution.recipe(game,weapon)
		if not recipe.is_empty(): panel.tooltip_text+="\n"+recipe
		var spell_name=SpellSynergy.SPELL_NAMES.get(ContentExpansion.kind(weapon.id),"")
		for line in SpellSynergy.lines(game):
			if not spell_name.is_empty() and line.contains(spell_name): panel.tooltip_text+="\n"+line
		var evolved=weapon.get("evolved",false)
		if weapon.id==selected.get("id",""):
			panel.add_theme_stylebox_override("panel",tile_style(Color("fff0c9"),.85,3));panel.set_meta("selected_turret",true)
		# Evolved: a thick gold frame with a glow. Ready to evolve: a thin glow.
		if evolved or WeaponEvolution.ready(game,weapon):
			var gilded=tile_style(WeaponEvolution.GOLD,.85,3 if evolved else 2)
			gilded.shadow_color=Color(WeaponEvolution.GOLD,.45);gilded.shadow_size=8 if evolved else 4
			panel.add_theme_stylebox_override("panel",gilded)
		var holder=Control.new();holder.mouse_filter=Control.MOUSE_FILTER_IGNORE;panel.add_child(holder)
		var icon = PowerIcon.new()
		icon.key = weapon.id
		icon.weapon_icon = true
		icon.color = PowerIcon.color_for(icon.key)
		icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		icon.position=Vector2(2,4);icon.size=Vector2(TILE.x-8,TILE.y-28)
		holder.add_child(icon)
		var level=game.hud.label(str(weapon.rank),17,Color("fff0c9"))
		level.add_theme_color_override("font_outline_color",Color(0,0,0,.85));level.add_theme_constant_override("outline_size",4)
		level.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;level.position=Vector2(-4,TILE.y-28);level.size=Vector2(TILE.x,20)
		holder.add_child(level)
		if evolved or WeaponEvolution.ready(game,weapon):
			var tag=game.hud.label("★" if evolved else "✦",12,WeaponEvolution.GOLD);tag.name="EvolveTag"
			tag.add_theme_color_override("font_outline_color",ThemeTokens.INK);tag.add_theme_constant_override("outline_size",4)
			tag.position=Vector2(TILE.x-20,-4);holder.add_child(tag)

const TILE=Vector2(76,84)

func tile_style(border: Color,fill: float,width: int) -> StyleBoxFlat:
	var look=StyleBoxFlat.new();look.bg_color=Color(.1,.12,.16,fill);look.border_color=border
	look.set_border_width_all(width);look.set_corner_radius_all(8)
	look.content_margin_left=2;look.content_margin_right=2;look.content_margin_top=2;look.content_margin_bottom=2
	return look

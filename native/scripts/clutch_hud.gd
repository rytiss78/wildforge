extends Control
class_name ClutchHud

# Clutch's own screen (first person): a gapped crosshair with hit markers,
# health with armour, shield and evasion in big digits bottom left, the weapon
# slots with their number keys bottom right, and the Rope / Lock-On / Sneak
# readouts. Kills count on the game's usual combo meter (right edge). Our own
# tactical-shooter style; drawn, no assets. No dark plates (user, November 3:
# minimal HUD): every line carries its own outline.

var game: Node3D
const GREEN=Color("6dff7a")
const WHITE=Color("f2f2ea")
const DIM=Color(.95,.95,.9,.55)
const INK=Color(0,0,0,.85)
const ROW=40.0
const ROW_W=330.0
const MARGIN=40.0
const BOTTOM=76.0  # clear of the XP meter and the key hint along the bottom edge

func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(_delta: float):
	visible=is_instance_valid(game) and ClutchPlay.first_person(game) and not game.hud.modal.visible
	if visible: queue_redraw()

func view_size() -> Vector2: return size if size.x>0 else get_viewport_rect().size

# Screen rectangle of a held weapon's row; his gun damage rises from it, as
# other heroes' numbers rise from their weapon tiles.
func slot_rect(weapon_id: String) -> Rect2:
	var hands=ClutchPlay.held(game);var view=view_size()
	for i in range(hands.size()):
		if str(hands[i].id)!=weapon_id: continue
		var y=view.y-BOTTOM-(hands.size()-1-i)*ROW
		var local=Rect2(Vector2(view.x-MARGIN-ROW_W,y-30),Vector2(ROW_W,36))
		return get_global_transform()*local
	return Rect2()

func text(font: Font,at: Vector2,value: String,font_size: int,color: Color,align:=HORIZONTAL_ALIGNMENT_LEFT,width:=-1.0):
	draw_string_outline(font,at,value,align,width,font_size,maxi(4,font_size/5),INK)
	draw_string(font,at,value,align,width,font_size,color)

func _draw():
	var view=view_size()
	var font=ThemeDB.fallback_font
	var c=view*.5
	# Crosshair: four short bars with a gap; a hit marker on hits.
	var gap=6.0+(4.0 if ClutchPlay.sneaking else 0.0);var bar=9.0
	for d in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
		draw_line(c+d*gap,c+d*(gap+bar),Color(0,0,0,.6),4.0);draw_line(c+d*gap,c+d*(gap+bar),GREEN,2.0)
	if ClutchPlay.hit_flash>0:
		var mark=Color(1,.25,.2) if ClutchPlay.head_flash>0 else WHITE
		for d in [Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]:
			draw_line(c+d*7,c+d*15,Color(mark,clampf(ClutchPlay.hit_flash*6,0,1)),2.5)
	if game.elapsed<ClutchPlay.lock_until:
		draw_arc(c,30,0,TAU,40,Color(1,.3,.25,.8),2.0)
	# Health, then armour, shield and evasion, bottom left.
	var base=Vector2(MARGIN,view.y-BOTTOM)
	text(font,base,"✚",34,WHITE)
	text(font,base+Vector2(40,0),str(ceili(game.hp)),40,WHITE if game.hp>game.stats.maxHp*.25 else Color(1,.35,.3))
	draw_rect(Rect2(base+Vector2(40,6),Vector2(110,4)),Color(0,0,0,.5))
	draw_rect(Rect2(base+Vector2(40,6),Vector2(110*clampf(game.hp/maxf(1,game.stats.maxHp),0,1),4)),WHITE)
	var x=180.0
	for part in [["⛨",str(roundi(game.stat("armor")))],["◈",str(ceili(game.shield_hp))],["≋","%d%%" % roundi(game.stat("dodge")*100)]]:
		text(font,base+Vector2(x,0),part[0],28,WHITE);text(font,base+Vector2(x+30,0),part[1],30,WHITE)
		x+=30.0+font.get_string_size(part[1],HORIZONTAL_ALIGNMENT_LEFT,-1,30).x+22.0
	# Weapon slots, bottom right; the active one bright.
	var hands=ClutchPlay.held(game);var right=view.x-MARGIN
	for i in range(hands.size()):
		var y=view.y-BOTTOM-(hands.size()-1-i)*ROW
		var on=i==ClutchPlay.active_slot
		var label="%s   %d" % [str(hands[i].name).to_upper(),i+1]
		if ClutchPlay.is_ak(hands[i]): label="AK-47   %s   %d" % ["RELOAD" if ClutchPlay.reloading() else "%d/%d" % [ClutchPlay.ammo,ClutchPlay.MAG],i+1]
		text(font,Vector2(right-ROW_W,y),label,24 if on else 20,WHITE if on else DIM,HORIZONTAL_ALIGNMENT_RIGHT,ROW_W)
		if on: draw_rect(Rect2(Vector2(right+8,y-22),Vector2(4,24)),GREEN)
	# Rope (C), Lock-On (V) and Sneak (Shift).
	var device="controller" if game.input_kind=="xbox" else "keyboard"
	var settings=game.career.data.settings
	var lock="[%s] LOCK-ON  %s" % [ControlBindings.display(settings,"trick",device),"READY" if game.trick_cooldown<=0 else "%.0fs" % game.trick_cooldown]
	text(font,base+Vector2(-4,-58),lock,18,GREEN if game.trick_cooldown<=0 else DIM)
	var sneak="[%s] SNEAK" % ControlBindings.display(settings,"dash",device)
	text(font,base+Vector2(-4,-82),sneak,18,GREEN if ClutchPlay.sneaking else (DIM if ClutchPlay.stealth_cooldown>0 else WHITE))
	var bar_at=base+Vector2(font.get_string_size(sneak,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x+10,-90)
	draw_rect(Rect2(bar_at,Vector2(100,5)),Color(0,0,0,.5))
	draw_rect(Rect2(bar_at,Vector2(100*ClutchPlay.stealth_left/ClutchPlay.STEALTH,5)),GREEN if ClutchPlay.stealth_cooldown<=0 else DIM)
	var rope="[%s] %s" % [ControlBindings.display(settings,"carry",device),"TOSS" if Lasso.mine>=0 else "ROPE" if Lasso.cooldown<=0 else "ROPE  %.1fs" % Lasso.cooldown]
	text(font,base+Vector2(-4,-106),rope,18,WHITE if Lasso.cooldown<=0 else DIM)

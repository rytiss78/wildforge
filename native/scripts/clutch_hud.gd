extends Control
class_name ClutchHud

# Clutch's own screen (first person): a gapped crosshair with hit markers,
# health and armour in big digits bottom left, the weapon slots with their
# number keys bottom right, a kill row of skulls for the current streak, and the
# Lock-On / Sneak readouts. Our own tactical-shooter style; drawn, no assets.

var game: Node3D
const GREEN=Color("6dff7a")
const WHITE=Color("f2f2ea")
const DIM=Color(.95,.95,.9,.45)
const BACK=Color(0,0,0,.42)

func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(_delta: float):
	visible=is_instance_valid(game) and ClutchPlay.first_person(game) and not game.hud.modal.visible
	if visible: queue_redraw()

func _draw():
	var view=size if size.x>0 else get_viewport_rect().size
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
	# Health and armour, bottom left.
	var base=Vector2(40,view.y-46)
	draw_rect(Rect2(base-Vector2(14,44),Vector2(360,58)),BACK)
	draw_string(font,base,"✚",HORIZONTAL_ALIGNMENT_LEFT,-1,34,WHITE)
	draw_string(font,base+Vector2(40,0),str(ceili(game.hp)),HORIZONTAL_ALIGNMENT_LEFT,-1,40,WHITE if game.hp>game.stats.maxHp*.25 else Color(1,.35,.3))
	draw_rect(Rect2(base+Vector2(40,6),Vector2(110*clampf(game.hp/maxf(1,game.stats.maxHp),0,1),4)),WHITE)
	draw_string(font,base+Vector2(180,0),"⛨",HORIZONTAL_ALIGNMENT_LEFT,-1,32,WHITE)
	draw_string(font,base+Vector2(216,0),str(ceili(game.shield_hp+float(game.stats.armor))),HORIZONTAL_ALIGNMENT_LEFT,-1,40,WHITE)
	# Weapon slots, bottom right; the active one bright.
	var hands=ClutchPlay.held(game);var right=view.x-40
	for i in range(hands.size()):
		var y=view.y-40-(hands.size()-1-i)*40
		var on=i==ClutchPlay.active_slot
		var text="%s   %d" % [str(hands[i].name).to_upper(),i+1]
		draw_rect(Rect2(Vector2(right-330,y-30),Vector2(330,36)),Color(0,0,0,.55) if on else BACK)
		draw_string(font,Vector2(right-322,y),text,HORIZONTAL_ALIGNMENT_RIGHT,310,24 if on else 20,WHITE if on else DIM)
	# Kill streak: one skull per kill in the last five seconds.
	var kills=mini(ClutchPlay.kill_times.size(),10)
	if kills>0:
		var top=Vector2(view.x*.5-kills*16,96)
		for i in range(kills): draw_string(font,top+Vector2(i*32,0),"☠",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color(1,.85,.3) if i==kills-1 else WHITE)
	# Lock-On (V) and Sneak (Shift).
	var device="controller" if game.input_kind=="xbox" else "keyboard"
	var lock="[%s] LOCK-ON  %s" % [ControlBindings.display(game.career.data.settings,"trick",device),"READY" if game.trick_cooldown<=0 else "%.0fs" % game.trick_cooldown]
	draw_string(font,base+Vector2(-4,-64),lock,HORIZONTAL_ALIGNMENT_LEFT,-1,18,GREEN if game.trick_cooldown<=0 else DIM)
	var sneak="[%s] SNEAK" % ControlBindings.display(game.career.data.settings,"dash",device)
	draw_string(font,base+Vector2(-4,-88),sneak,HORIZONTAL_ALIGNMENT_LEFT,-1,18,GREEN if ClutchPlay.sneaking else (DIM if ClutchPlay.stealth_cooldown>0 else WHITE))
	draw_rect(Rect2(base+Vector2(110,-100),Vector2(100*ClutchPlay.stealth_left/ClutchPlay.STEALTH,5)),GREEN if ClutchPlay.stealth_cooldown<=0 else DIM)

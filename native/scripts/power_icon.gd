extends Control
class_name PowerIcon

var key = "damage"
var color = Color("65cbea")
var tier = 0
var weapon_icon = false

func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	if key=="banana": queue_redraw();return
	var art=TextureRect.new()
	art.texture=IllustratedIcons.texture(key,weapon_icon)
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# An opaque paper square keeps the illustration crisp on every panel.

static func color_for(name: String) -> Color:
	if name in ["burn","flame","fire","fire-turret","explosion","splash","rocket","rocket-turret"]: return Color("ff955c")
	if name in ["poison","pools","poison-turret"]: return Color("8bdd6e")
	if name in ["freeze","slow","ice","ice-turret"]: return Color("76d9f6")
	if name in ["lifesteal","maxHp","regen","salvage","repair"]: return Color("f77b98")
	if name in ["ghost","blind","burrow","nova","orbitDamage"]: return Color("bda0f4")
	if name in ["goldGain","discount","keyPower","walkGold","hurtGold","interest","coinRadius","potGold"]: return Color("f6d178")
	if name in ["armor","shield","dodge"]: return Color("81b5de")
	return Color("a1dccc")

func _draw():
	if key!="banana": return
	var c=size*.5;var scale=minf(size.x,size.y)/64.0
	draw_rect(Rect2(Vector2.ZERO,size),Color("fff3dd"))
	var points=PackedVector2Array()
	for i in range(25):
		var a=.12+float(i)/24*2.7
		points.append(c+Vector2(cos(a),sin(a))*25*scale-Vector2(0,10)*scale)
	for i in range(24,-1,-1):
		var a=.12+float(i)/24*2.7
		points.append(c+Vector2(cos(a),sin(a))*15*scale-Vector2(0,10)*scale)
	draw_colored_polygon(points,Color("efbf44"));points.append(points[0]);draw_polyline(points,Color("715238"),2*scale,true)
	draw_arc(c-Vector2(0,10)*scale,21*scale,.25,2.75,32,Color("ffe184"),3*scale,true)
	draw_line(c+Vector2(23,-9)*scale,c+Vector2(27,-17)*scale,Color("8b6b3e"),5*scale,true)

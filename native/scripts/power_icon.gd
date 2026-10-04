extends Control
class_name PowerIcon

var key = "damage"
var color = Color("65cbea")
var tier = 0
var weapon_icon = false

func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
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

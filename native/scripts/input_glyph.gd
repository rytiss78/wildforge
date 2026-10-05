extends Control
class_name InputGlyph

var key = "E"
var xbox = false
var game
var keyboard_key = ""
var xbox_key = ""

func _process(_delta):
	if game == null: return
	var active = game.input_kind == "xbox"
	var next = xbox_key if active else keyboard_key
	if active != xbox or next != key:
		xbox=active
		key=next
		queue_redraw()

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(38,34)

func _draw():
	var center = size*.5
	var colors = {"A":Color("78dc96"),"B":Color("ff8187"),"X":Color("77bcff"),"Y":Color("ffdd7d")}
	var face = xbox and colors.has(key)
	var ink = Color("fff3d4")
	if face:
		draw_circle(center,15,Color("0a1423"))
		draw_circle(center-Vector2(0,2),13,colors[key])
		ink = Color("142238")
	elif xbox and key in ["LS","RS","R3"]:
		draw_circle(center,15,Color("fff3d4"))
		draw_circle(center,12,Color("34435f"))
		draw_arc(center,17,-PI*.8,PI*.8,24,Color("e7b967"),2,true)
	else:
		var box = StyleBoxFlat.new()
		box.bg_color = Color("fff1cd")
		box.border_color = Color("bb985d")
		box.set_border_width_all(1)
		box.border_width_bottom = 4
		box.set_corner_radius_all(7 if not xbox else 10)
		draw_style_box(box,Rect2(Vector2(2,2),size-Vector2(4,4)))
		ink = Color("26334d")
	var font = ThemeDB.fallback_font
	var text_size = 13 if key.length()>2 else 17
	if key == "D-pad":
		draw_rect(Rect2(center-Vector2(4,11),Vector2(8,22)),ink)
		draw_rect(Rect2(center-Vector2(11,4),Vector2(22,8)),ink)
	elif key=="R3":
		draw_string(font,center+Vector2(-9,4),"RS",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("fff3d4"))
		draw_line(center+Vector2(0,9),center+Vector2(0,15),Color("fff3d4"),2)
		draw_line(center+Vector2(-3,12),center+Vector2(0,15),Color("fff3d4"),2)
		draw_line(center+Vector2(3,12),center+Vector2(0,15),Color("fff3d4"),2)
	elif key == "Menu":
		for y in [-5,0,5]: draw_line(center+Vector2(-7,y),center+Vector2(7,y),ink,2,true)
	elif key == "Mouse":
		draw_rect(Rect2(center-Vector2(7,10),Vector2(14,20)),ink,false,2)
		draw_line(center+Vector2(0,-10),center,ink,2)
	else:
		var width = font.get_string_size(key,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size).x
		draw_string(font,center+Vector2(-width*.5,5),key,HORIZONTAL_ALIGNMENT_LEFT,-1,text_size,ink)

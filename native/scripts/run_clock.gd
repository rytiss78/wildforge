extends Control
class_name RunClock
var seconds = 600.0
var duration = 600.0
var bosses = 0
var realm = 0

func _draw():
	var font=ThemeDB.fallback_font
	var text="%02d:%02d" % [int(seconds)/60,int(seconds)%60]
	var frame_time=Engine.get_frame_time_msec()*TAU/30000.0
	var plate=StyleBoxFlat.new();plate.bg_color=Color("17293d");plate.set_corner_radius_all(9)
	# Warning glow when time is low
	if seconds<60:
		var pulse=.25+sin(frame_time*3)*.12
		plate.shadow_color=Color(1,.25,.15,pulse);plate.shadow_size=12;plate.shadow_offset=Vector2.ZERO
		draw_style_box(plate,Rect2(0,0,339,82))
		draw_circle(Vector2(169,41),42,Color(1,.25,.15,pulse*.6))
	else:
		plate.shadow_color=ThemeTokens.SHADOW.color;plate.shadow_size=ThemeTokens.SHADOW.size;plate.shadow_offset=ThemeTokens.SHADOW.offset
		draw_style_box(plate,Rect2(0,0,339,82))
	draw_string(font,Vector2(14,40),text,HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("ffdf9a") if seconds<60 else Color("fff8de"))
	draw_string(font,Vector2(137,28),"WORLD %d / 3" % (realm+1),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("c9d7c4"))
	draw_string(font,Vector2(137,54),"Wardens %d / 2" % mini(bosses,2),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("c9d7c4"))
	draw_rect(Rect2(14,67,310,4),Color("42545f"));draw_rect(Rect2(14,67,310*clampf(seconds/duration,0,1),4),Color("dfb869"))

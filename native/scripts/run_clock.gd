extends Control
class_name RunClock
var seconds = 600.0
var duration = 600.0
var bosses = 0
var realm = 0

func _draw():
	var font=ThemeDB.fallback_font
	var text="%02d:%02d" % [int(seconds)/60,int(seconds)%60]
	var frame_time=Time.get_ticks_msec()*TAU/30000.0
	# No plate or border (user, November 3): outlined text on the scene, and a
	# red glow behind the time when it runs low.
	if seconds<60 and realm<3:
		var pulse=.25+sin(frame_time*3)*.12
		draw_circle(Vector2(60,28),40,Color(1,.25,.15,pulse*.6))
	var ink=Color(0,0,0,.85)
	draw_string_outline(font,Vector2(14,40),text,HORIZONTAL_ALIGNMENT_LEFT,-1,34,6,ink)
	draw_string(font,Vector2(14,40),text,HORIZONTAL_ALIGNMENT_LEFT,-1,34,Color("ffdf9a") if seconds<60 and realm<3 else Color("fff8de"))
	var top="RED MOON" if realm==3 else "WORLD %d / 3" % (realm+1);var bottom="SURVIVE" if realm==3 else "Wardens %d / 2" % mini(bosses,2)
	draw_string_outline(font,Vector2(137,28),top,HORIZONTAL_ALIGNMENT_LEFT,-1,17,5,ink);draw_string(font,Vector2(137,28),top,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("e6efe2"))
	draw_string_outline(font,Vector2(137,54),bottom,HORIZONTAL_ALIGNMENT_LEFT,-1,17,5,ink);draw_string(font,Vector2(137,54),bottom,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("e6efe2"))
	draw_rect(Rect2(13,66,312,6),Color(0,0,0,.55));draw_rect(Rect2(14,67,310*clampf(seconds/duration,0,1),4),Color("dfb869"))

extends Control
class_name RunClock
var seconds = 600.0
var duration = 600.0
var bosses = 0
var realm = 0

func _draw():
	var center = Vector2(56,56)
	var ratio = clampf(seconds/duration,0.0,1.0)
	var color = Color("f27c68") if seconds < 60 else Color("eac77e") if seconds < 180 else Color("96d9b0")
	draw_circle(center,51,Color("f6eddc"))
	draw_arc(center,48,-PI/2,TAU-PI/2,70,Color("d8c8ab"),6,true)
	draw_arc(center,48,-PI/2,-PI/2+ratio*TAU,70,color,6,true)
	draw_line(center,center+Vector2(0,-21).rotated(-ratio*TAU),color,3,true)
	draw_circle(center,4,color)
	var font = ThemeDB.fallback_font
	var text = "%02d:%02d" % [int(seconds)/60,int(seconds)%60]
	draw_string(font,Vector2(118,57),text,HORIZONTAL_ALIGNMENT_LEFT,-1,38,Color("574536"))
	for i in range(3): draw_circle(Vector2(133+i*26,88),6,Color("edd185") if i <= realm else Color("c4b89c"))
	for i in range(2):
		var p = Vector2(230+i*28,86)
		draw_circle(p,8,Color("9bdfaf") if bosses > i else Color("f8987d"))
		draw_circle(p+Vector2(-2,-1),2,Color("142c2f"))
		draw_circle(p+Vector2(2,-1),2,Color("142c2f"))

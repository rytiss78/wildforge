extends Control

# Original vector architecture; independent of gameplay camera and collisions.
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw():
	draw_set_transform(Vector2.ZERO,0,size/Vector2(1440,810))
	for row in range(81):
		draw_rect(Rect2(0,row*10,1440,11),Color("080f17").lerp(Color("194137"),float(row)/80))
	for i in range(23):
		var x=i*69.0-30;var roof=170+fmod(i*137,250)
		draw_colored_polygon(PackedVector2Array([Vector2(x,720),Vector2(x,roof+36),Vector2(x+31,roof),Vector2(x+65,roof+36),Vector2(x+65,720)]),Color("0b1a21"))
		for j in range(4):
			var y=roof+64+j*68
			draw_rect(Rect2(x+24,y,9,24),Color("4f9a68") if (i+j)%3==0 else Color("20352e"))
	for side in [0,1]:
		var x=28.0+side*1250
		draw_rect(Rect2(x,0,132,810),Color("080e13"))
		draw_rect(Rect2(x+16,0,100,810),Color("24332e"))
		for rib in range(4):
			draw_rect(Rect2(x+25+rib*22,0,5,810),Color("101d21"))
		for y in [40,110,675,747]:
			draw_rect(Rect2(x-10,y,152,25),Color("0a1319"))
			draw_line(Vector2(x-10,y+2),Vector2(x+142,y+2),Color("927749"),2)
		var flame=Vector2(x+66,625)
		for glow in range(8,0,-1): draw_circle(flame,glow*13,Color(.15,.8,.46,.013))
		draw_colored_polygon(PackedVector2Array([flame+Vector2(-24,15),flame+Vector2(-16,-18),flame+Vector2(5,-80),flame+Vector2(9,-25),flame+Vector2(24,-43),flame+Vector2(20,15)]),Color("48d792"))
		draw_colored_polygon(PackedVector2Array([flame+Vector2(-10,12),flame+Vector2(5,-48),flame+Vector2(13,12)]),Color("d0ffc0"))
		draw_colored_polygon(PackedVector2Array([flame+Vector2(-31,12),flame+Vector2(31,12),flame+Vector2(18,30),flame+Vector2(-18,30)]),Color("9b7a43"))
	for y in range(720,811,22): draw_line(Vector2(0,y),Vector2(1440,y),Color("243d34"),2)
	for x in range(-300,1801,120): draw_line(Vector2(720+(x-720)*.7,710),Vector2(x,810),Color("0b151b"),3)

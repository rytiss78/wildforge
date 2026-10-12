extends Control

# Original trophy and laurel artwork, without console logos or a 360 medallion.
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw():
	var center=size*.5
	var radius=minf(size.x,size.y)*.46
	var white=Color("ffffff")
	var s=radius/42.0
	draw_set_transform(center,0,Vector2.ONE*s)
	for side in [-1,1]:
		var stem=PackedVector2Array([Vector2(side*9,31),Vector2(side*25,20),Vector2(side*32,2),Vector2(side*29,-20)])
		draw_polyline(stem,Color("caedd4"),1.7,true)
		for leaf in range(4):
			var y=18-leaf*11
			var x=side*(25+sin(float(leaf)/3*PI)*6)
			draw_colored_polygon(PackedVector2Array([Vector2(x,y+5),Vector2(x+side*9,y),Vector2(x+side*8,y-8),Vector2(x,y-2)]),Color("caedd4"))
	draw_colored_polygon(PackedVector2Array([Vector2(-16,-19),Vector2(16,-19),Vector2(13,0),Vector2(6,8),Vector2(-6,8),Vector2(-13,0)]),white)
	draw_polyline(PackedVector2Array([Vector2(-15,-14),Vector2(-25,-14),Vector2(-23,-2),Vector2(-11,3)]),white,4,true)
	draw_polyline(PackedVector2Array([Vector2(15,-14),Vector2(25,-14),Vector2(23,-2),Vector2(11,3)]),white,4,true)
	draw_rect(Rect2(-3,6,6,14),white)
	draw_line(Vector2(-12,22),Vector2(12,22),white,5,true)

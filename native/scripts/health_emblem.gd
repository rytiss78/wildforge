extends RefCounted

static func draw(canvas: CanvasItem,center: Vector2,radius: float,fraction: float):
	var fill=clampf(fraction,0,1)
	canvas.draw_circle(center,radius+3,Color("080f14"))
	canvas.draw_circle(center,radius,Color("203934"))
	if fill>0:
		var level=1.0-2.0*fill
		var start=asin(clampf(level,-1,1))
		var points=PackedVector2Array()
		for i in range(49):
			var angle=lerpf(start,PI-start,float(i)/48)
			points.append(center+Vector2(cos(angle),sin(angle))*radius)
		canvas.draw_colored_polygon(points,Color("cc3651"))
	canvas.draw_arc(center,radius+1,0,TAU,48,ThemeTokens.STAR_GOLD,2,true)
	canvas.draw_arc(center,radius-4,PI*1.10,PI*1.46,12,Color("f6e5bc"),2,true)

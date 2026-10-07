extends Control

# Native vector scenery keeps the menu crisp at every window size.
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE

func _draw():
	var canvas=Vector2(1440,810)
	for row in range(81):
		draw_rect(Rect2(0,row*10,canvas.x,11),Color("142638").lerp(Color("365b59"),float(row)/80))
	var moon=Vector2(1206,128)
	draw_circle(moon,67,Color("efcf8b"))
	draw_circle(moon+Vector2(-20,-15),66,Color("1b3140"))
	for i in range(45):
		var point=Vector2(fmod(i*173.7+41,1440),fmod(i*71.3+23,300))
		draw_circle(point,1.1+fmod(i,3)*.4,Color("adbfac"))
	for layer in range(3):
		var points=PackedVector2Array([Vector2(0,810)])
		for x in range(0,1457,16):
			points.append(Vector2(x,490+layer*91+sin(x*.004+layer*2)*53+cos(x*.009+layer)*18))
		points.append(Vector2(1440,810))
		draw_colored_polygon(points,[Color("2c4e52"),Color("223f46"),Color("19323d")][layer])
	for i in range(20):
		var x=float(i)*83-27;var height=90+fmod(i*31,104);var y=785+sin(i*1.8)*24
		draw_line(Vector2(x,y),Vector2(x,y-height),Color("122d36"),6)
		for crown in range(3):
			var top=Vector2(x,y-height+crown*height*.23)
			var width=height*(.17+crown*.06)
			draw_colored_polygon(PackedVector2Array([top,top+Vector2(-width,height*.49),top+Vector2(width,height*.49)]),Color("122d36"))
	for i in range(14):
		var point=Vector2(fmod(i*137.2+63,1440),688+fmod(i*41.2,105))
		draw_circle(point,2,Color("ddbd7e"))

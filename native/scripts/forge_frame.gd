extends Control

var panel: Control

func _process(_delta: float):
	if is_instance_valid(panel):
		position=panel.position
		size=panel.size

# Original engraved corner-work shared by large menu and reward panels.
func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw():
	var gold=ThemeTokens.STAR_GOLD
	for corner in [Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)]:
		var direction=Vector2(1 if corner.x==0 else -1,1 if corner.y==0 else -1)
		var origin=corner+direction*7
		var points=PackedVector2Array([origin+Vector2(0,36)*direction,origin,origin+Vector2(36,0)*direction])
		draw_polyline(points,gold,2,true)
		var center=origin+direction*7
		draw_colored_polygon(PackedVector2Array([center+Vector2(0,-4),center+Vector2(4,0),center+Vector2(0,4),center+Vector2(-4,0)]),gold)
	draw_line(Vector2(52,7),Vector2(size.x-52,7),Color(gold,.35),1,true)
	draw_line(Vector2(52,size.y-7),Vector2(size.x-52,size.y-7),Color(gold,.35),1,true)

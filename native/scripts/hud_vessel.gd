extends Control

var fill=1.0
var shield_fill=0.0

func _ready(): mouse_filter=Control.MOUSE_FILTER_IGNORE

func _draw():
	var c=size*.5;var radius=minf(size.x,size.y)*.34
	preload("res://scripts/health_emblem.gd").draw(self,c,radius,fill)
	for side in [-1,1]:
		var p=c+Vector2(side*(radius+8),0)
		draw_colored_polygon(PackedVector2Array([p+Vector2(0,-15),p+Vector2(side*6,0),p+Vector2(0,15),p+Vector2(-side*4,0)]),ThemeTokens.STAR_GOLD)
	if shield_fill>0: draw_arc(c,radius+7,-PI*.5,-PI*.5+TAU*shield_fill,48,Color("70d9ee"),3,true)

extends Control
class_name BloodGauge
var fill=1.0
var tank=false

func _draw():
	var c=size*.5;var r=minf(size.x,size.y)*.43
	draw_circle(c,r+2,Color("b9956b"));draw_circle(c,r,Color("aed3ca"))
	var points=PackedVector2Array();var level=c.y+r-fill*2*r
	for i in range(65):
		var p=c+Vector2(cos(i*TAU/64),sin(i*TAU/64))*r
		p.y=maxf(level,p.y);points.append(p)
	if fill>.001: draw_colored_polygon(points,Color("c35c69"))
	draw_arc(c,r,0,TAU,64,Color("7b6353"),1.0,true)
	draw_arc(c+Vector2(1,1),r*.77,PI,PI*1.5,16,Color("f9efd6"),2.0,true)
	if fill<.65: draw_polyline(PackedVector2Array([c+Vector2(-r*.4,-r*.5),c+Vector2(-r*.55,-r*.1),c+Vector2(-r*.25,r*.2)]),Color("728c88"),1.0,true)

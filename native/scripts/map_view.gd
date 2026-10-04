extends Control
class_name ExploreMap
var hero_position = Vector3.ZERO
var known_chests = []
var gate = Vector3.ZERO
var gate_open = false
var visited = {}

func _draw():
	var center = size*.5
	var radius = minf(size.x,size.y)*.46
	draw_circle(center,radius,Color("efe4ce"))
	draw_arc(center,radius,0,TAU,60,Color("947956"),2,true)
	for cell in visited:
		var p = center + Vector2(cell.x,cell.y)*8 * radius/510.0
		if p.distance_to(center)<radius: draw_circle(p,3,RealmWorld.COLORS[int(visited[cell])])
	for chest in known_chests:
		var p = center + Vector2(chest.x,chest.z)*radius/510.0
		if p.distance_to(center)>radius-9: p=center+(p-center).normalized()*(radius-9)
		draw_rect(Rect2(p-Vector2(6,5),Vector2(12,10)),Color("574536"))
		draw_rect(Rect2(p-Vector2(4,3),Vector2(8,6)),Color("edbf56"))
		draw_line(p+Vector2(-4,-1),p+Vector2(4,-1),Color("574536"),1)
		draw_rect(Rect2(p-Vector2(1,1),Vector2(2,4)),Color("fff5da"))
	var gp = center+Vector2(gate.x,gate.z)*radius/510.0
	draw_arc(gp,5,0,TAU,12,Color("9bdcb9") if gate_open else Color("967cac"),2,true)
	var hp = center+Vector2(hero_position.x,hero_position.z)*radius/510.0
	draw_circle(hp,4,Color("574536"))

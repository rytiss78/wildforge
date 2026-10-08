extends Control

var game

func _draw():
	if game==null or game.mode!="playing" or game.hp<=0 or game.hud.modal.visible: return
	draw_pings()
	var head=game.player.position+Vector3.UP*2.15
	if game.camera.is_position_behind(head): return
	var marker=get_global_transform().affine_inverse()*game.camera.unproject_position(head)
	var points=PackedVector2Array([marker+Vector2(-8,-9),marker+Vector2(8,-9),marker+Vector2(0,1)])
	draw_colored_polygon(points,ThemeTokens.STAR_GOLD)
	draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[0]]),ThemeTokens.INK,2,true)

func draw_pings():
	var bounds=Rect2(70,220,1300,450)
	var center=Vector2(720,405)
	for ping in game.update.pings:
		var target=ping.position+Vector3.UP*2
		var behind=game.camera.is_position_behind(target)
		var projected=get_global_transform().affine_inverse()*game.camera.unproject_position(target)
		if not behind and bounds.has_point(projected): continue
		var local=game.camera.global_transform.affine_inverse()*target
		var direction=Vector2(local.x,-local.y)
		if direction.length()<.01: direction=Vector2.DOWN
		direction=direction.normalized()
		var edge=center+direction*minf(620/maxf(.01,absf(direction.x)),210/maxf(.01,absf(direction.y)))
		var side=Vector2(-direction.y,direction.x)
		var triangle=PackedVector2Array([edge+direction*13,edge-direction*8+side*8,edge-direction*8-side*8])
		draw_colored_polygon(triangle,Color("ffe17d"))
		draw_polyline(PackedVector2Array([triangle[0],triangle[1],triangle[2],triangle[0]]),Color("263642"),2,true)
		draw_string(ThemeDB.fallback_font,edge-direction*32+Vector2(-25,20),"PING %dm" % game.player.position.distance_to(ping.position),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("ffe17d"))

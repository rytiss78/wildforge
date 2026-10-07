extends Control

var game

func _draw():
	if game==null or game.mode!="playing" or game.hp<=0 or game.hud.modal.visible: return
	var head=game.player.position+Vector3.UP*2.15
	if game.camera.is_position_behind(head): return
	var marker=get_global_transform().affine_inverse()*game.camera.unproject_position(head)
	var points=PackedVector2Array([marker+Vector2(-8,-9),marker+Vector2(8,-9),marker+Vector2(0,1)])
	draw_colored_polygon(points,ThemeTokens.STAR_GOLD)
	draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[0]]),ThemeTokens.INK,2,true)

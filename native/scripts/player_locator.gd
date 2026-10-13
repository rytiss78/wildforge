extends Control

var game

func _draw():
	if game==null or game.mode!="playing" or game.hp<=0 or game.hud.modal.visible: return
	draw_pings()
	draw_down_markers()
	draw_boss_marker()
	var head=game.player.position+Vector3.UP*2.15
	if game.camera.is_position_behind(head): return
	var marker=get_global_transform().affine_inverse()*game.camera.unproject_position(head)
	var points=PackedVector2Array([marker+Vector2(-8,-9),marker+Vector2(8,-9),marker+Vector2(0,1)])
	draw_colored_polygon(points,ThemeTokens.STAR_GOLD)
	draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[0]]),ThemeTokens.INK,2,true)

func draw_down_markers():
	# Off-screen markers remain visible even when a corpse is behind the camera.
	if not game.coop.active: return
	var screen=get_viewport_rect().size
	var margin=Vector2(75,100)
	for id in game.update.downed_ids:
		var peer_id=int(id)
		if peer_id==game.coop.local_id: continue
		var member=game.coop.members.get(peer_id,{})
		if not member.has("position"): continue
		var pos=CoopSession.vector(member.position)
		var target=pos+Vector3.UP*2.2
		var behind=game.camera.is_position_behind(target)
		var projected=get_global_transform().affine_inverse()*game.camera.unproject_position(target)
		var direction=projected-screen*.5
		if behind: direction=-direction
		if direction.length_squared()<.1: direction=Vector2.UP
		var edge=screen*.5+direction.normalized()*minf((screen.x*.5-margin.x)/maxf(.01,absf(direction.normalized().x)),(screen.y*.5-margin.y)/maxf(.01,absf(direction.normalized().y)))
		var marker=Vector2(clampf(projected.x,margin.x,screen.x-margin.x),clampf(projected.y,margin.y,screen.y-margin.y)) if not behind else edge
		var color=Color("55d2ee")
		draw_arc(marker,11,0,TAU,20,color,2.5,true)
		draw_line(marker+Vector2(-6,0),marker+Vector2(6,0),color,2)
		draw_line(marker+Vector2(0,-6),marker+Vector2(0,6),color,2)
		draw_string(ThemeDB.fallback_font,marker+Vector2(-46,29),"REVIVE %dm" % roundi(game.player.position.distance_to(pos)),HORIZONTAL_ALIGNMENT_LEFT,-1,14,color)

func draw_boss_marker():
	# In-world boss health orbs remain the only HP indicator; this marks location.
	var closest={}
	var distance=INF
	for enemy in game.enemies:
		if enemy.dead or not enemy.boss or not is_instance_valid(enemy.node): continue
		var candidate=game.player.position.distance_to(enemy.node.position)
		if candidate<distance: closest=enemy;distance=candidate
	if closest.is_empty(): return
	var target=closest.node.global_position+Vector3.UP*float(closest.get("height",3))
	var bounds=get_viewport_rect().size
	var center=bounds*.5
	var behind=game.camera.is_position_behind(target)
	var projected=get_global_transform().affine_inverse()*game.camera.unproject_position(target)
	var visible_rect=Rect2(Vector2(45,70),bounds-Vector2(90,155))
	var marker=projected
	if behind or not visible_rect.has_point(projected):
		var camera_local=game.camera.global_transform.affine_inverse()*target
		var direction=Vector2(camera_local.x,-camera_local.y)
		if behind: direction=-direction
		if direction.length_squared()<.0001: direction=Vector2.UP
		direction=direction.normalized()
		marker=center+direction*minf((center.x-72)/maxf(.01,absf(direction.x)),(center.y-90)/maxf(.01,absf(direction.y)))
	var tone=Color("ffab70")
	var triangle=PackedVector2Array([marker+Vector2(0,-9),marker+Vector2(7,5),marker+Vector2(-7,5)])
	draw_colored_polygon(triangle,tone)
	draw_polyline(PackedVector2Array([triangle[0],triangle[1],triangle[2],triangle[0]]),Color("17232a"),2,true)
	draw_string(ThemeDB.fallback_font,marker+Vector2(-33,25),"BOSS %dm" % roundi(distance),HORIZONTAL_ALIGNMENT_LEFT,-1,14,tone)

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

extends Control
var game
func _draw():
	if game==null or game.mode not in ["playing","level_reveal"]: return
	var font=ThemeDB.fallback_font
	var bosses=game.enemies.filter(func(e):return e.boss and not e.dead)
	if not bosses.is_empty():
		var boss=bosses[-1];var width=520.0
		draw_style_box(game.hud.style(Color("17293d"),Color("bc925d"),8),Rect2(460,20,width,54))
		draw_string(font,Vector2(476,43),str(boss.get("title",game.boss_name)),HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("ffdf9a"))
		draw_rect(Rect2(476,54,width-32,9),Color("3f414a"));draw_rect(Rect2(476,54,(width-32)*clampf(boss.hp/boss.maxHp,0,1),9),Color("d76c72"))
	if game.elapsed<float(game.events.get("announcement_until",-1)):
		draw_style_box(game.hud.style(Color("17293d"),Color("d6b474"),12),Rect2(380,92,680,85))
		draw_string(font,Vector2(400,124),str(game.events.get("announcement","")),HORIZONTAL_ALIGNMENT_LEFT,-1,27,Color("ffdf9a"))
		draw_string(font,Vector2(400,154),str(game.events.get("announcement_detail","")),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("fff8de"))
	if game.realm_time>=600:
		draw_style_box(game.hud.style(Color("592e47"),Color("e38d6c"),5),Rect2(24,274,254,30))
		draw_string(font,Vector2(34,296),"ECLIPSE · threat %d" % (1+int((game.realm_time-600)/30)),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ffdf9a"))
	var offset=game.gate_position-game.player.position;var distance=offset.length()
	if distance<8: return
	var relative=offset.rotated(Vector3.UP,-game.yaw)
	var direction=Vector2(relative.x,relative.z).normalized()
	var marker=Vector2(720,420)+direction*Vector2(365,208)
	var angle=atan2(direction.x,-direction.y)
	var points=PackedVector2Array()
	for p in [Vector2(0,-12),Vector2(-8,7),Vector2(8,7)]: points.append(marker+p.rotated(angle))
	draw_colored_polygon(points,Color("ffd767"));draw_polyline(PackedVector2Array([points[0],points[1],points[2],points[0]]),Color("17293d"),2,true)
	draw_string_outline(font,marker+Vector2(-44,29),"PORTAL %dm" % distance,HORIZONTAL_ALIGNMENT_LEFT,-1,14,3,Color("17293d"))
	draw_string(font,marker+Vector2(-44,29),"PORTAL %dm" % distance,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ffdf9a"))

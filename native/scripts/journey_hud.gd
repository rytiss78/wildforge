extends Control
var game
func _draw():
	if game==null or game.mode not in ["playing","level_reveal"]: return
	var font=ThemeDB.fallback_font
	if game.elapsed<float(game.events.get("announcement_until",-1)):
		draw_style_box(game.hud.style(Color("17293d"),Color("d6b474"),12),Rect2(32,380,680,70))
		draw_string(font,Vector2(48,408),str(game.events.get("announcement","")),HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("ffdf9a"))
		draw_string(font,Vector2(48,435),str(game.events.get("announcement_detail","")),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("fff8de"))
	if game.events.get("eclipse",false):
		draw_style_box(game.hud.style(Color("592e47"),Color("e38d6c"),5),Rect2(32,332,310,30))
		draw_string(font,Vector2(42,354),"ECLIPSE · threat %d" % (int(game.events.get("eclipse_stage",1))),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ffdf9a"))
	if game.Hunt.state(game)=="active":
		draw_style_box(game.hud.style(Color("362742"),Color("c094d9"),5),Rect2(32,278,310,44))
		draw_string(font,Vector2(42,298),"HUNT  %d / 3    ·    %ds" % [game.events.get("hunt_kills",[]).size(),maxi(0,ceili(float(game.events.get("hunt_deadline",0))-game.realm_time))],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("efcaff"))
		draw_string(font,Vector2(42,314),"Defeat the violet-marked foes",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("fff8de"))
	if game.realm==3: return
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

extends Control
var game

func _process(delta: float):
	if game==null: return
	game.damage_feedback_time=maxf(0,game.damage_feedback_time-delta)
	queue_redraw()

func _draw():
	if game==null or game.mode not in ["playing","level_reveal"]: return
	var bounds=get_viewport_rect().size
	var t=game.damage_feedback_time/.65
	var low=clampf(1-game.hp/maxf(1,game.stats.maxHp)/.28,0,1)
	var pulse=low*(.045+.02*sin(Time.get_ticks_msec()*.005))
	var alpha=t*t*game.damage_feedback_strength*.48+pulse
	if alpha<.005: return
	# Feathered edges leave enemies, aiming and ground warnings fully visible.
	for i in range(8):
		var inset=float(i)*8;var paint=Color(.95,.025,.07,alpha*(1-float(i)/8))
		draw_rect(Rect2(Vector2.ONE*inset,bounds-Vector2.ONE*inset*2),paint,false,8)
	# The amount itself falls from under the health panel (hud.hero_number).
	if t>.05:
		if game.damage_feedback_source!=Vector3.ZERO:
			var toward=(game.damage_feedback_source-game.player.position).rotated(Vector3.UP,-game.yaw)
			var angle=atan2(toward.x,-toward.z)
			var center=bounds*.5+Vector2(0,-155).rotated(angle)
			var points=PackedVector2Array()
			for p in [Vector2(0,-18),Vector2(-12,8),Vector2(12,8)]:points.append(center+p.rotated(angle))
			draw_colored_polygon(points,Color(1,.16,.12,t))

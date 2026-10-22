extends Control
var tier=0
var progress=0.0
var items=[]
var textures=[]
var sound: RunSound
var last_lock=-1
var last_tick=-1
func setup(offers: Array):
	mouse_filter=Control.MOUSE_FILTER_IGNORE;items=offers
	# Mutations have drawn medallions rather than texture files.
	for item in items: textures.append(null if item.kind=="mutation" or item.kind!="weapon" and not StatGlyphs.resolve(item.id).is_empty() else IllustratedIcons.texture(item.id,item.kind=="weapon"))
func animate(value: float):
	progress=value
	var locked=clampi(int(floor((progress-.48)/.095))+1,0,5)
	var tick=int(progress*26)
	if sound:
		if locked>last_lock and locked>0: sound.ui_effect("reel_lock")
		elif tick>last_tick and locked<5: sound.ui_effect("reel_tick")
	last_lock=locked;last_tick=tick
	queue_redraw()
func _draw():
	if items.is_empty(): return
	var font=ThemeDB.fallback_font;var start=(size.x-850)*.5;var frame=Time.get_ticks_msec()*TAU/2000.0
	draw_style_box(box(Color("17293d"),Color("bd9864")),Rect2(start-18,15,886,286))
	for i in range(5):
		var stop=.48+i*.095;var locked=progress>=stop
		var rect=Rect2(start+i*172,53,162,180)
		var box_color=Color("fff8de");var border=RunRules.COLORS[items[i].tier] if locked else Color("756951")
		# Glowing border for locked items
		var sb:StyleBoxFlat
		if locked:
			var pulse=.25+sin(frame*4+i*.8)*.08
			sb=box(box_color,RunRules.COLORS[items[i].tier].lerp(Color(1,1,1),pulse*.3))
			sb.shadow_color=Color(border.r,border.g,border.b,pulse*.4);sb.shadow_size=6+pulse*4;sb.shadow_offset=Vector2.ZERO
		else:
			sb=box(box_color,border)
			sb.shadow_color=Color("3a2f1e",.2);sb.shadow_size=8
		draw_style_box(sb,rect)
		var index=i if locked else (int(progress*48*(1-progress*.5))+i*3)%textures.size()
		var shift=0.0 if locked else sin(progress*160+i)*15*(1-progress)
		if textures[index]!=null: draw_texture_rect(textures[index],Rect2(rect.position+Vector2(22,24+shift),Vector2(118,118)),false)
		elif items[index].kind!="mutation": StatGlyphs.draw_medallion(self,str(items[index].id),rect.position+Vector2(81,83+shift),56)
		else: PowerIcon.draw_mutation(self,str(items[index].id),rect.position+Vector2(81,83+shift),56)
		draw_string(font,rect.position+Vector2(9,170),"LOCKED" if locked else "ROLLING",HORIZONTAL_ALIGNMENT_CENTER,144,13,Color("274052"))
		draw_string(font,Vector2(start+i*172,264),items[i].name if locked else "?",HORIZONTAL_ALIGNMENT_CENTER,162,15,Color("fff0c9"))
		for bulb in range(5): draw_circle(Vector2(start+i*172+16+bulb*31,34),3,RunRules.COLORS[items[i].tier] if locked else Color("6c735f"))
	draw_string(font,Vector2(start,330),"Five prizes revealed · Choose ONE to keep",HORIZONTAL_ALIGNMENT_CENTER,850,18,Color("374e56"))
func box(color: Color,border: Color) -> StyleBoxFlat:
	var style=StyleBoxFlat.new();style.bg_color=color;style.border_color=border;style.set_border_width_all(3);style.set_corner_radius_all(12);style.shadow_color=Color("3a2f1e",.32);style.shadow_size=16;return style

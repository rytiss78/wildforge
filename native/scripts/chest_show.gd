extends Control

var tier = 0
var progress = 0.0
var icons = []

func setup(items: Array):
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	for i in range(12):
		var icon=PowerIcon.new()
		var item=items[i%items.size()]
		icon.key=item.effects[0].key
		icon.color=PowerIcon.color_for(icon.key)
		icon.size=Vector2(62,62)
		add_child(icon)
		icons.append(icon)

func animate(value: float):
	progress=value
	var center=size*.5
	for i in range(icons.size()):
		var angle=i*TAU/icons.size()+progress*(TAU*(2+tier))
		var radius=105+sin(progress*PI)*tier*20
		icons[i].position=center+Vector2(cos(angle)*radius*2.3,sin(angle)*radius*.65)-Vector2(31,31)
		icons[i].modulate.a=clampf(progress*5,0,1)*(.5+.5*sin(angle)*sin(angle))
	queue_redraw()

func _draw():
	var center=size*.5
	var accent=RunRules.COLORS[tier]
	var energy=sin(progress*PI)
	draw_circle(center,100+energy*20,Color(accent,.13))
	for i in range(8+tier*8):
		var a=i*TAU/(8+tier*8)+progress*.9
		var ray=Vector2.from_angle(a)
		draw_line(center+ray*65,center+ray*(130+energy*70),Color(accent,energy*.28),3+tier,true)
	# Coins burst from a rising lid; rarity controls rays, confetti and bloom.
	for i in range(14+tier*20):
		var t=fmod(progress*1.6+i*.067,1.0)
		var angle=i*2.39996
		var point=center+Vector2(cos(angle)*t*(150+tier*50),-sin(t*PI)*(80+tier*30)+t*t*105)
		if progress>.25:
			draw_circle(point,3.5+float(i%3),Color(accent,(1-t)*energy))
	var chest=Rect2(center+Vector2(-75,-15),Vector2(150,92))
	draw_style_box(box(Color("815326"),accent),chest)
	for x in [-45,45]: draw_line(center+Vector2(x,-15),center+Vector2(x,77),Color("f4d290"),9,true)
	var lid_y=-15-smoothstep(.3,.85,progress)*78
	draw_style_box(box(Color("af783c"),accent),Rect2(center+Vector2(-79,lid_y-24),Vector2(158,35)))
	draw_rect(Rect2(center+Vector2(-12,12),Vector2(24,31)),accent)
	if tier>=2:
		for i in range(18+tier*12):
			var t=fmod(progress+i*.031,1.0)
			var p=Vector2(fmod(i*91.7,size.x),t*size.y)
			draw_line(p,p+Vector2(sin(i)*8,5),Color(accent,energy*.7),3,true)

func box(color: Color, border: Color) -> StyleBoxFlat:
	var style=StyleBoxFlat.new()
	style.bg_color=color
	style.border_color=border
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	return style

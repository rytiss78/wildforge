extends Control
class_name ComboMeter

# The combo meter (user request, October 29: "just a meter, no benefits"). Every
# kill adds one; losing health breaks it. It shows the count on the right of the
# screen, punches on each kill, warms from white to gold to red as it grows, and
# shatters with "COMBO LOST" when you are hit. The best combo of the run goes into
# the run report.

const SHOW_FROM=3  # small counts stay hidden
const COLORS=[[0,Color("ffffff")],[10,Color("ffd75e")],[25,Color("ff9a3c")],[50,Color("ff4a4a")],[100,Color("e46bff")]]

var count=0
var best=0
var punch=0.0
var lost_time=0.0
var number: Label
var caption: Label
var lost: Label

func _init():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	number=Label.new();number.add_theme_font_size_override("font_size",54);number.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	number.add_theme_color_override("font_outline_color",Color(0,0,0,.85));number.add_theme_constant_override("outline_size",10)
	number.size=Vector2(200,64);number.pivot_offset=Vector2(170,34);add_child(number)
	caption=Label.new();caption.text="COMBO";caption.add_theme_font_size_override("font_size",16);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	caption.add_theme_color_override("font_outline_color",Color(0,0,0,.85));caption.add_theme_constant_override("outline_size",6)
	caption.position=Vector2(0,58);caption.size=Vector2(200,20);add_child(caption)
	lost=Label.new();lost.add_theme_font_size_override("font_size",20);lost.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	lost.add_theme_color_override("font_color",Color("ff5a5a"));lost.add_theme_color_override("font_outline_color",Color(0,0,0,.85));lost.add_theme_constant_override("outline_size",6)
	lost.position=Vector2(0,80);lost.size=Vector2(200,26);add_child(lost)
	for child in get_children(): child.mouse_filter=Control.MOUSE_FILTER_IGNORE
	refresh()

func reset():
	count=0;best=0;punch=0.0;lost_time=0.0;refresh()

func kill():
	count+=1;best=maxi(best,count);punch=1.0;refresh()

# The hero lost health: the combo breaks (a short one silently).
func hit():
	if count>=SHOW_FROM:
		lost.text="COMBO LOST · %d" % count;lost_time=1.6
	count=0;refresh()

static func color_for(value: int) -> Color:
	var result=COLORS[0][1]
	for step in COLORS:
		if value>=step[0]: result=step[1]
	return result

func refresh():
	number.text="x%d" % count
	number.add_theme_color_override("font_color",color_for(count))
	caption.add_theme_color_override("font_color",color_for(count).lerp(Color.WHITE,.4))
	number.visible=count>=SHOW_FROM;caption.visible=number.visible

func tick(delta: float):
	punch=maxf(0.0,punch-delta*5.0)
	var grow=1.0+.35*punch*punch+minf(.25,count*.004)
	number.scale=Vector2(grow,grow)
	# A big combo trembles a little.
	number.rotation=sin(Time.get_ticks_msec()*.03)*.04*clampf((count-25)/50.0,0,1)
	lost_time=maxf(0.0,lost_time-delta)
	lost.visible=lost_time>0
	lost.modulate.a=clampf(lost_time/.5,0,1)
	lost.position.x=sin(lost_time*40.0)*4.0*clampf(lost_time-1.2,0,1)/.4

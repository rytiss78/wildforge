extends Control
class_name OfferSpin

# Card rolls (user, November 2: "a stronger slot machine feel"). On a level-up
# or a reroll each card starts as a dark slot window spinning prize symbols;
# the cards stop left to right with a clunk, an epic or legendary card crawls
# to a stop first, and the stop sound, a flash, rays and a rarity tag show how
# rare it is. Then the window fades away and the card is there to pick. Sits
# on top of its card and ignores the mouse.

var item={}
var symbols=[]       # items whose icons spin past
var textures=[]
var stop_at=.5
var crawl=.0
var sound: RunSound
var index=0
var clock=0.0
var stopped=false
var tensed=false
var last=false        # the last card to stop turns the spin sound off
var window: Control   # the dark spinning window (fades out as a whole)

const SPEED=12.0
const SYMBOL=120.0
const FADE=.28

static func total_time(items: Array) -> float:
	var at=0.0
	for i in range(items.size()): at=stop_time(items,i)
	return at+FADE

static func stop_time(items: Array,i: int) -> float:
	var at=.3
	for k in range(i+1):
		if k>0: at+=.16
		if int(items[k].tier)>=2: at+=.35+.15*(int(items[k].tier)-2)
	return at

func setup(offer: Dictionary,pool: Array,i: int,all: Array,run_sound: RunSound):
	item=offer;index=i;sound=run_sound;mouse_filter=Control.MOUSE_FILTER_IGNORE
	stop_at=stop_time(all,i);crawl=.25 if int(offer.tier)<2 else .6+.15*(int(offer.tier)-2)
	last=i==all.size()-1
	var rng=RandomNumberGenerator.new();rng.seed=hash(str(offer.id))+i
	for k in range(int(SPEED*stop_at)+4): symbols.append(pool[rng.randi_range(0,pool.size()-1)] if not pool.is_empty() else offer)
	symbols.append(offer)
	for symbol in symbols: textures.append(ChestShow.symbol_texture(symbol))
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	window=SpinWindow.new();window.spin=self;window.clip_contents=true;window.show_behind_parent=true;window.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(window);window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float):
	clock+=delta
	var t=int(item.tier)
	if not tensed and t>=2 and clock>=stop_at-crawl:
		tensed=true
		if sound: sound.slot("slot-tension",1.1+.1*(t-2),-6.0)
	if not stopped and clock>=stop_at:
		stopped=true
		if sound:
			sound.slot("slot-stop-%d" % t,1.05+index*.03,-3.0)
			if last: sound.slot_spin(false)
	queue_redraw();window.queue_redraw()
	window.modulate.a=1.0-(clampf((clock-stop_at)/FADE,0,1) if stopped else 0.0)
	if clock>=stop_at+FADE+(.5 if t>=1 else 0.0): queue_free()

func _exit_tree():
	if last and sound: sound.slot_spin(false)

func pos_at(t: float) -> float:
	var final=float(symbols.size()-1);var left=stop_at-t
	if left<=0: return final-sin(-left*22.0)*exp(left*9.0)*.12
	var remaining=SPEED*left-SPEED*crawl*.5 if left>crawl else SPEED/(2.0*crawl)*left*left
	return final-remaining

func _draw():
	var t=int(item.tier);var color=RunRules.COLORS[t];var c=size*.5
	# On stopping: a flash, rays for rare and better, and the rarity tag.
	if stopped and t>=1:
		var age=clock-stop_at
		var glow=clampf(1.0-age/.6,0,1)
		draw_rect(Rect2(Vector2.ZERO,size),Color(color,.22*glow))
		var now=Time.get_ticks_msec()*.001
		for r in range(6+t*4):
			var a=now*(.8+t*.3)+r*TAU/(6+t*4);var reach=(80.0+t*40.0)*clampf(age*4.0,0,1)
			var side=Vector2(-sin(a),cos(a))*(8+t*4)
			var tip=c+Vector2(cos(a),sin(a))*reach
			draw_colored_polygon(PackedVector2Array([c,tip+side,tip-side]),Color(color,(.12+.05*t)*glow))
		var font=ThemeDB.fallback_font;var size_px=int((16+t*5)*(1.0+maxf(0,.4-age)*1.5))
		var tag=ChestShow.TAGS[t]
		# The tag stays readable until the roll leaves the card.
		var tag_alpha=clampf((stop_at+FADE+.5-clock)/.2,0,1)
		draw_string_outline(font,Vector2(0,c.y-90),tag,HORIZONTAL_ALIGNMENT_CENTER,size.x,size_px,6,Color(0,0,0,.85*tag_alpha))
		draw_string(font,Vector2(0,c.y-90),tag,HORIZONTAL_ALIGNMENT_CENTER,size.x,size_px,Color(color.lightened(.3),tag_alpha))

# The dark window with the spinning strip; clipped to the card.
class SpinWindow extends Control:
	var spin
	func _draw():
		var t=int(spin.item.tier);var color=RunRules.COLORS[t];var c=size*.5
		var shade=StyleBoxFlat.new();shade.bg_color=Color(.08,.1,.14);shade.set_corner_radius_all(12)
		shade.border_color=color if spin.stopped else Color("756951");shade.set_border_width_all(4)
		draw_style_box(shade,Rect2(Vector2.ZERO,size))
		var step=size.y*.42;var pos: float=spin.pos_at(spin.clock);var base=floori(pos)
		var left: float=spin.stop_at-spin.clock
		var speed=0.0 if spin.stopped else (spin.SPEED if left>spin.crawl else spin.SPEED*left/maxf(.01,spin.crawl))
		for j in range(base-2,base+3):
			if j<0 or j>=spin.symbols.size(): continue
			var y=c.y+(pos-float(j))*step
			if y<-step or y>size.y+step: continue
			ChestShow.draw_item(self,spin.symbols[j],spin.textures[j],Vector2(c.x,y),minf(52.0,size.x*.22))
		if speed>2.0: draw_rect(Rect2(4,4,size.x-8,size.y-8),Color(.08,.1,.14,clampf((speed-2.0)/spin.SPEED,0,1)*.5))
		# Glass shading so symbols fade at the window's top and bottom.
		for k in range(12):
			var a=.5*(1.0-float(k)/12.0)
			draw_rect(Rect2(4,4+k*5,size.x-8,5),Color(.08,.1,.14,a));draw_rect(Rect2(4,size.y-4-(k+1)*5,size.x-8,5),Color(.08,.1,.14,a))
		draw_line(Vector2(8,c.y),Vector2(20,c.y),Color(.8,.2,.2,.8),3);draw_line(Vector2(size.x-20,c.y),Vector2(size.x-8,c.y),Color(.8,.2,.2,.8),3)

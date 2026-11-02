extends Control
class_name ChestShow

# The chest reels as a real slot machine (user, November 2: "a stronger slot
# machine feel; rarer items very apparent from the opening animation and sound").
# Five reel windows spin a strip of prize symbols downward with motion blur and
# stop one by one, left to right, with a bounce and a clunk. A reel holding an
# epic or legendary prize slows right down first (a rising whine), then its
# window bursts into its rarity colour with rays and sparkles, a rarity tag pops
# over it and a bigger stop sound plays; a legendary also shakes the machine and
# flashes it gold, and the machine ends on a jackpot. Marquee bulbs chase while
# it spins and blink in the best prize's colour when it is done.
#
# hud.chest_reveal drives it with progress 0..1 over the reveal's reel time.

var tier=0
var progress=0.0
var items=[]
var textures=[]
var sound: RunSound
var span=2.0         # seconds of reel time (the reveal duration minus the latch)
var stops=[]         # seconds at which each reel stops
var decels=[]        # seconds of slow-down before each stop
var strips=[]        # symbol indices into items, per reel; the last is the prize
var reels=[]         # Reel controls
var stopped=[]
var tensed=[]
var shake=0.0
var flash=0.0
var flash_color=Color.WHITE
var started=false
var finished=false

const WINDOW=Vector2(162,200)
const GAP=172.0
const SYMBOL=150.0
const SPEED=13.0     # symbols a second at full spin
const TAGS=["","RARE","EPIC!","LEGENDARY!!"]

func setup(offers: Array,reel_seconds: float=2.0):
	mouse_filter=Control.MOUSE_FILTER_IGNORE;items=offers;span=maxf(1.0,reel_seconds)
	# Mutations have drawn medallions rather than texture files.
	for item in items: textures.append(symbol_texture(item))
	# Stop times: left to right; a reel with an epic or legendary prize gets a long
	# slow crawl first, which pushes the later reels back.
	var at=span*.30;var plan=[]
	for i in range(items.size()):
		var t=int(items[i].tier);var slow=.35 if t<2 else (.95 if t==2 else 1.35)
		at+=(span*.09 if i>0 else 0.0)+(slow-.35)
		plan.append([at,slow])
	var last=float(plan[plan.size()-1][0]) if not plan.is_empty() else span
	var squeeze=minf(1.0,span*.9/maxf(.01,last))
	var rng=RandomNumberGenerator.new();rng.seed=hash(str(items.map(func(x):return x.id)))
	for i in range(items.size()):
		stops.append(float(plan[i][0])*squeeze);decels.append(float(plan[i][1])*squeeze)
		var strip=[]
		var length=int(SPEED*stops[i])+6
		for k in range(length): strip.append(rng.randi_range(0,items.size()-1))
		strip.append(i);strips.append(strip)
		stopped.append(false);tensed.append(false)
		var reel=Reel.new();reel.show=self;reel.index=i;reel.clip_contents=true;reel.mouse_filter=Control.MOUSE_FILTER_IGNORE
		reel.size=WINDOW;add_child(reel);reels.append(reel)
	resized.connect(place_reels);place_reels()

func place_reels():
	var start=(size.x-GAP*items.size()+10)*.5
	for i in range(reels.size()): reels[i].position=Vector2(start+i*GAP,58)

func _exit_tree():
	if sound: sound.slot_spin(false)

func animate(value: float):
	progress=value
	var t=progress*span
	if not started and sound: started=true;sound.slot_spin(true)
	for i in range(reels.size()):
		var item_tier=int(items[i].tier)
		if not tensed[i] and item_tier>=2 and t>=stops[i]-decels[i]:
			tensed[i]=true
			if sound: sound.slot("slot-tension",1.0+.1*(item_tier-2),-2.0)
		if not stopped[i] and t>=stops[i]:
			stopped[i]=true
			if sound: sound.slot("slot-stop-%d" % item_tier,1.0+i*.025)
			if item_tier>=2: flash=1.0;flash_color=RunRules.COLORS[item_tier]
			if item_tier>=3: shake=1.0
	if not finished and stopped.all(func(s):return s):
		finished=true
		if sound:
			sound.slot_spin(false)
			if tier>=3: sound.slot("slot-jackpot")
	elif sound and started and not finished:
		# The spin slows as fewer reels are left turning.
		sound.slot_spin(true,.8+.4*float(stopped.count(false))/maxf(1,stopped.size()))
	for reel in reels: reel.queue_redraw()
	queue_redraw()

func _process(delta: float):
	shake=maxf(0,shake-delta*1.6);flash=maxf(0,flash-delta*2.2)
	if shake>0 or flash>0 or finished: queue_redraw()
	for reel in reels: reel.queue_redraw()
	position.x=(sin(Time.get_ticks_msec()*.09)*7.0*shake) if shake>0 else 0.0

# Reel position in symbols at time t (spin, ease-out to the prize, bounce).
func reel_pos(i: int,t: float) -> float:
	var final=float(strips[i].size()-1);var stop=float(stops[i]);var d=float(decels[i])
	if t>=stop:
		var after=t-stop
		return final-sin(after*22.0)*exp(-after*9.0)*.14
	var left=stop-t
	var v=SPEED
	var remaining=v*left-v*d*.5 if left>d else v/(2.0*d)*left*left
	return final-remaining

func reel_speed(i: int,t: float) -> float:
	var left=float(stops[i])-t;var d=float(decels[i])
	if left<=0: return 0.0
	return SPEED if left>d else SPEED*left/d

func since_stop(i: int) -> float: return progress*span-float(stops[i])

func _draw():
	if items.is_empty(): return
	var font=ThemeDB.fallback_font;var start=(size.x-GAP*items.size()+10)*.5;var now=Time.get_ticks_msec()*.001
	var width=GAP*items.size()+26;var top_color=RunRules.COLORS[tier]
	# Cabinet.
	var cabinet=Rect2(start-18,8,width,316)
	draw_style_box(box(Color("15202e"),top_color.lerp(Color("bd9864"),.5) if finished else Color("bd9864"),6),cabinet)
	if flash>0: draw_rect(cabinet.grow(-4),Color(flash_color,flash*.35))
	# Marquee bulbs along the top and bottom: a chase while spinning, all
	# blinking in the best prize's colour when done.
	var bulbs=34;var perimeter=[]
	for k in range(bulbs):
		var f=float(k)/bulbs;var p: Vector2
		if f<.5: p=Vector2(cabinet.position.x+12+(cabinet.size.x-24)*f*2.0,cabinet.position.y+10)
		else: p=Vector2(cabinet.end.x-12-(cabinet.size.x-24)*(f-.5)*2.0,cabinet.end.y-10)
		perimeter.append(p)
	for k in range(bulbs):
		var lit: bool
		var color: Color
		if finished: lit=int(now*6.0)%2==0 or k%2==0;color=top_color
		else: lit=(k+int(now*18.0))%5==0;color=Color("ffe58a")
		draw_circle(perimeter[k],4.0 if lit else 3.0,color if lit else Color("4a4436"))
		if lit: draw_circle(perimeter[k],8.0,Color(color,.18))
	# Rays behind each rare+ window once it has stopped; the rarest on top.
	var order=range(items.size());order.sort_custom(func(a,b):return int(items[a].tier)<int(items[b].tier))
	for i in order:
		var item_tier=int(items[i].tier)
		if not stopped[i] or item_tier<1: continue
		var c=Rect2(start+i*GAP,58,WINDOW.x,WINDOW.y).get_center();var rays=8+item_tier*4;var reach=110.0+item_tier*45.0
		var grow=clampf(since_stop(i)*3.0,0,1)
		for r in range(rays):
			var a=now*(.6+item_tier*.25)+r*TAU/rays
			var tip=c+Vector2(cos(a),sin(a))*reach*grow;var side=Vector2(-sin(a),cos(a))*(10+item_tier*5)
			draw_colored_polygon(PackedVector2Array([c,tip+side,tip-side]),Color(RunRules.COLORS[item_tier],.10+.06*item_tier))
	for i in range(items.size()):
		var rect=Rect2(start+i*GAP,58,WINDOW.x,WINDOW.y)
		var item_tier=int(items[i].tier);var color=RunRules.COLORS[item_tier]
		var done=stopped[i];var age=since_stop(i)
		var frame=color if done else Color("756951")
		var sb=box(Color("fff8de"),frame,4 if done and item_tier>0 else 3)
		if done:
			sb.shadow_color=Color(color,.45+.25*sin(now*5+i));sb.shadow_size=8+item_tier*6;sb.shadow_offset=Vector2.ZERO
		draw_style_box(sb,rect)
		# The prize name, and a rarity tag that pops when the reel stops.
		draw_string(font,Vector2(rect.position.x,rect.end.y+30),str(items[i].name) if done else "?",HORIZONTAL_ALIGNMENT_CENTER,WINDOW.x,15,Color("fff0c9"))
		if done and item_tier>0:
			var pop=1.0+maxf(0,.4-age)*.8
			var tag_size=int((14+item_tier*3)*pop)
			draw_string_outline(font,Vector2(rect.position.x-20,rect.position.y-8),TAGS[item_tier],HORIZONTAL_ALIGNMENT_CENTER,WINDOW.x+40,tag_size,6,Color(0,0,0,.8))
			draw_string(font,Vector2(rect.position.x-20,rect.position.y-8),TAGS[item_tier],HORIZONTAL_ALIGNMENT_CENTER,WINDOW.x+40,tag_size,color.lightened(.25))
		# Sparkles round a legendary.
		if done and item_tier>=3:
			for s in range(10):
				var a=s*2.4+now*1.7;var d=60+sin(now*3+s)*30
				var p=rect.get_center()+Vector2(cos(a),sin(a))*d
				var r=2.5+sin(now*9+s)*1.5
				draw_line(p-Vector2(r*2,0),p+Vector2(r*2,0),Color(1,.95,.6,.9),2);draw_line(p-Vector2(0,r*2),p+Vector2(0,r*2),Color(1,.95,.6,.9),2)
	var line="Choose ONE prize to keep" if finished else "Spinning…"
	draw_string(font,Vector2(start,cabinet.end.y+42),line,HORIZONTAL_ALIGNMENT_CENTER,width-26,18,Color("d9c9a3"))

# A prize's picture: a texture for weapons and most items; stat items and
# mutations draw a medallion instead (null here).
static func symbol_texture(item: Dictionary) -> Texture2D:
	if item.kind=="evolution": return IllustratedIcons.texture(str(item.weapon_id),true)
	if item.kind=="mutation" or item.kind!="weapon" and not StatGlyphs.resolve(item.id).is_empty(): return null
	return IllustratedIcons.texture(item.id,item.kind=="weapon")

static func draw_item(canvas: CanvasItem,item: Dictionary,texture: Texture2D,at: Vector2,radius: float,alpha: float=1.0):
	if texture!=null: canvas.draw_texture_rect(texture,Rect2(at-Vector2(radius,radius)*1.08,Vector2(radius,radius)*2.16),false,Color(1,1,1,alpha))
	elif item.kind!="mutation": StatGlyphs.draw_medallion(canvas,str(item.id),at,radius)
	else: PowerIcon.draw_mutation(canvas,str(item.id),at,radius)

# The chest opening in the world: a light beam of the best prize's colour rises
# from the chest, taller and brighter the rarer it is; a legendary adds a gold
# light and a second burst.
static func beam(g,at: Vector3,best: int):
	if best<1: return
	var color=RunRules.COLORS[best]
	var node=MeshInstance3D.new();var tube=CylinderMesh.new();tube.top_radius=.15+best*.12;tube.bottom_radius=.5+best*.25;tube.height=5.0+best*5.0;tube.radial_segments=14
	node.mesh=tube;node.position=at+Vector3.UP*tube.height*.5;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var glow=StandardMaterial3D.new();glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;glow.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glow.blend_mode=BaseMaterial3D.BLEND_MODE_ADD
	glow.albedo_color=Color(color,.55);glow.cull_mode=BaseMaterial3D.CULL_DISABLED;node.material_override=glow
	g.add_child(node)
	var tween=node.create_tween();node.scale=Vector3(.2,.05,.2)
	tween.tween_property(node,"scale",Vector3.ONE,.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(glow,"albedo_color:a",0.0,2.2+best*.4)
	tween.tween_callback(node.queue_free)
	if best>=3:
		var lamp=OmniLight3D.new();lamp.light_color=color;lamp.light_energy=4.0;lamp.omni_range=14.0;lamp.position=at+Vector3.UP*2.0;g.add_child(lamp)
		var fade=lamp.create_tween();fade.tween_property(lamp,"light_energy",0.0,3.0);fade.tween_callback(lamp.queue_free)
		g.burst(at+Vector3.UP*1.5,color,30)

func box(color: Color,border: Color,width: int=3) -> StyleBoxFlat:
	var style=StyleBoxFlat.new();style.bg_color=color;style.border_color=border;style.set_border_width_all(width);style.set_corner_radius_all(12);style.shadow_color=Color("3a2f1e",.32);style.shadow_size=16;return style

# One reel window: a clipped strip of symbols scrolling downward.
class Reel extends Control:
	var show
	var index=0
	func _draw():
		var t=show.progress*show.span
		var pos: float=show.reel_pos(index,t);var speed: float=show.reel_speed(index,t)
		var c=size*.5
		var base=floori(pos)
		for j in range(base-1,base+3):
			if j<0 or j>=show.strips[index].size(): continue
			var y=c.y+(pos-float(j))*show.SYMBOL
			var symbol: int=show.strips[index][j]
			draw_symbol(symbol,Vector2(c.x,y),1.0)
		# Motion blur: the window mists over while the reel spins fast.
		if speed>2.0: draw_rect(Rect2(Vector2.ZERO,size),Color(1,.97,.87,clampf((speed-2.0)/show.SPEED,0,1)*.55))
		# Glass shading top and bottom, like a real reel window.
		for k in range(10):
			var a=.32*(1.0-float(k)/10.0)
			draw_rect(Rect2(0,k*4,size.x,4),Color(0,0,0,a));draw_rect(Rect2(0,size.y-(k+1)*4,size.x,4),Color(0,0,0,a))
		draw_line(Vector2(6,c.y),Vector2(14,c.y),Color(.8,.2,.2,.7),3);draw_line(Vector2(size.x-14,c.y),Vector2(size.x-6,c.y),Color(.8,.2,.2,.7),3)
	func draw_symbol(symbol: int,at: Vector2,alpha: float):
		ChestShow.draw_item(self,show.items[symbol],show.textures[symbol],at,52,alpha)

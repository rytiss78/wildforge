extends Control
class_name HellFlight

# The fall through the island (user, November 3). Hell is not a place you
# fly over: it is the hollow inside every island, and Digby falls straight
# through it on his way to the other side. While he tunnels (Underside.dig)
# this painted fall covers the view, looking along the way he falls:
#   crust    rock rings rush past as he breaks into the hollow
#   hollow   a vast burning shaft, no floor: walls of fire far around, lava
#            pouring inward, embers streaking past, wailing souls spiralling
#            up around him, the glow of the deep ahead
#   breach   rock again, then light from the far side opening ahead
# Going down the far side is the dark under the island, coming up it is day.

var duration=1.6
var age=0.0
var down=true
var souls=[]
var sparks=[]
var rings=[]
var rng=RandomNumberGenerator.new()
var wails=[]

static func start(game,going_down: bool,seconds: float) -> HellFlight:
	var flight=HellFlight.new();flight.duration=seconds;flight.down=going_down;flight.name="HellFlight"
	flight.mouse_filter=Control.MOUSE_FILTER_IGNORE
	game.hud.root.add_child(flight);game.hud.root.move_child(flight,0)
	flight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.sound.slot("hell-flight",1.0 if going_down else 1.08,-4.0)
	flight.wails=[[.3,0],[.7,1 if going_down else 2],[1.05,2 if going_down else 0]]
	flight.set_meta("game",game)
	return flight

func _ready():
	rng.seed=7719 if down else 4411
	# Each rock ring has its own jagged outline.
	for k in range(40):
		var shape=PackedFloat32Array()
		for j in range(18): shape.append(rng.randf_range(.82,1.15))
		rings.append({"shape":shape,"turn":rng.randf()*TAU})
	for i in range(16): souls.append({"at":rng.randf_range(.1,duration*.75),"angle":rng.randf()*TAU,"spin":rng.randf_range(1.5,3.0)*(1 if i%2==0 else -1),"size":rng.randf_range(.8,1.3)})
	for i in range(80): sparks.append(Vector3(rng.randf()*TAU,rng.randf(),rng.randf_range(.6,1.6)))

func _process(delta: float):
	age+=delta
	var game=get_meta("game") if has_meta("game") else null
	for wail in wails:
		if wail[0]>=0 and age>=wail[0]:
			if game: game.sound.slot("soul-wail-"+str(wail[1]),rng.randf_range(.9,1.12),-7.0)
			wail[0]=-1.0
	if age>=duration: queue_free();return
	queue_redraw()

func fade() -> float: return clampf(age/.12,0,1)*clampf((duration-age)/.22,0,1)

# How much of the view is the open hollow (0 in the rock crusts at each end).
func hollow() -> float:
	var t=age/duration
	return smoothstep(.12,.3,t)*(1.0-smoothstep(.72,.88,t))

func _draw():
	var a=fade();var w=size.x;var h=size.y;var c=size*.5;var t=age/duration
	var reach=Vector2(w,h).length()*.6
	var open=hollow()
	# The deep ahead: dark rim to a glowing furnace heart (or the far side's
	# light as he breaks through).
	var exit=smoothstep(.8,.97,t)
	var heart=Color(1.0,.62,.2).lerp(Color(.55,.75,1.0) if not down else Color(.05,.05,.12),exit)
	draw_rect(Rect2(Vector2.ZERO,size),Color(.06,.0,.0,a))
	for k in range(14):
		var f=1.0-k/14.0
		draw_circle(c,reach*f,Color(.12,.0,.0).lerp(Color(.55,.05,.02),(1.0-f)*open).lerp(heart,pow(1.0-f,3.2)*(.5+.5*open+exit)))
	# Walls of fire far around the shaft, flickering bands.
	for k in range(36):
		var ang=k*TAU/36.0+age*.4
		var flick=.7+.3*sin(age*9.0+k*1.7)
		var r0=reach*(.55+.15*sin(k*2.1));var r1=reach*1.1
		var p0=c+Vector2.from_angle(ang)*r0;var p1=c+Vector2.from_angle(ang)*r1
		draw_line(p0,p1,Color(1,.35+.2*flick,.08,.25*open*a*flick),reach*.09)
	# Lava pouring inward from the walls toward the deep.
	for k in range(8):
		var ang=k*TAU/8.0+.3+sin(age+k)*.05
		var from=c+Vector2.from_angle(ang)*reach*1.05
		var to=c+Vector2.from_angle(ang)*reach*(.25+.1*sin(age*2+k))
		draw_line(from,to,Color(1,.45,.1,.35*open*a),18.0);draw_line(from,to,Color(1,.8,.35,.8*open*a),5.0)
	# Rock rings rushing past (thick in the crusts, sparse in the hollow).
	var travel=age*7.0
	for k in range(rings.size()):
		var z=fmod(k*.45-travel+60.0,6.0)+.15
		var crust=1.0-open
		if crust<.05 and k%4!=0: continue
		var r=reach*.32/z;if r>reach*1.6: continue
		var ring: Dictionary=rings[k];var outline=PackedVector2Array()
		for j in range(ring.shape.size()+1):
			var ang=j*TAU/ring.shape.size()+ring.turn
			outline.append(c+Vector2.from_angle(ang)*r*ring.shape[j%ring.shape.size()])
		var near=clampf(1.5-z*.35,0,1)
		draw_polyline(outline,Color(.1,.02,.01,a*(.45+.55*crust)*near),clampf(r*.22,2,140))
		draw_polyline(outline,Color(1,.4,.1,a*.6*near*(.3+.7*open)),clampf(r*.02,1,8))
	# Embers streaking past outward (he is falling toward them).
	for s in sparks:
		var d=fmod(s.y+age*1.4*s.z,1.0)
		var from=c+Vector2.from_angle(s.x)*reach*pow(d,2.0)
		var to=c+Vector2.from_angle(s.x)*reach*pow(minf(1,d+.06),2.0)
		draw_line(from,to,Color(1,.65,.25,a*(.35+.65*open)*d),1.0+d*3.0)
	# Wailing souls spiralling up past him, mouths open.
	for soul in souls:
		var life=(age-float(soul.at))/.8
		if life<0.0 or life>1.0: continue
		var ang=float(soul.angle)+life*float(soul.spin)
		var dist=reach*.15*exp(life*2.2)
		var centre=c+Vector2.from_angle(ang)*dist
		var r=clampf(h*.02*float(soul.size)*exp(life*2.0),3.0,h*.2)
		var alpha=a*open*clampf(life*4.0,0,1)*clampf((1.0-life)*4.0,0,1)
		var back=c+Vector2.from_angle(ang-float(soul.spin)*.15)*dist*.7
		draw_polygon(PackedVector2Array([centre+(centre-back).orthogonal().normalized()*r*.8,centre-(centre-back).orthogonal().normalized()*r*.8,back]),PackedColorArray([Color(.75,.95,1,.5*alpha),Color(.75,.95,1,.5*alpha),Color(.6,.9,1,0)]))
		draw_circle(centre,r*1.3,Color(.6,.9,1,.18*alpha))
		draw_circle(centre,r,Color(.86,.98,1,.85*alpha))
		draw_circle(centre+Vector2(-r*.35,-r*.15),r*.18,Color(.05,.05,.12,alpha))
		draw_circle(centre+Vector2(r*.35,-r*.15),r*.18,Color(.05,.05,.12,alpha))
		draw_set_transform(centre+Vector2(0,r*.38),0,Vector2(1,1.5));draw_circle(Vector2.ZERO,r*.2,Color(.05,.05,.12,alpha));draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	# Dark edges.
	for k in range(6):
		var inset=k*h*.025
		draw_rect(Rect2(inset,inset,w-inset*2,h-inset*2),Color(0,0,0,.12*a),false,h*.03)

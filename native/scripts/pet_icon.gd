extends Control
class_name PetIcon

# A pet wisp drawn for the pet picker (November 1, user: "make pets visible in
# selection, not names"): the same glowing core, halo and mark as the in-game wisp
# (pet.gd build), so the choice is made by look. Glint has one big eye, Sting two
# flickering flame wings, Halo an orbiting ring; orbiting motes show its stage.

var kind="blip"
var stage=0
var selected=false
var clock=0.0

func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clock=randf()*TAU

func _process(delta: float):
	if not is_visible_in_tree(): return
	clock+=delta;queue_redraw()

func _draw():
	var color: Color=Pet.COLORS.get(kind,Color.WHITE)
	var center=size*.5+Vector2(0,sin(clock*2.4)*size.y*.03)
	var r=minf(size.x,size.y)*.62
	var glow=(.6+.08*stage)*r
	# Soft halo: stacked translucent discs fading outward.
	for i in range(10):
		var t=1.0-float(i)/10.0
		draw_circle(center,glow*t,Color(color,.07+.05*(1.0-t)))
	draw_circle(center,r*.3,Color(color,.55))
	draw_circle(center,r*.2,color.lerp(Color.WHITE,.4))
	var ink=Color("1b1530")
	match kind:
		"blip":
			draw_circle(center+Vector2(0,-r*.02),r*.09,Color.WHITE);draw_circle(center+Vector2(r*.015,-r*.01),r*.055,ink)
		"fuzzbat":
			var flap=.45+absf(sin(clock*9.0))*.35
			for side in [-1.0,1.0]:
				var wing=PackedVector2Array()
				for k in range(13):
					var a=float(k)/12.0*TAU
					wing.append(center+Vector2(side*r*.38+cos(a)*r*.2,sin(a)*r*.2*flap-r*.05))
				draw_colored_polygon(wing,Color(color.lerp(Color("ffd0f0"),.3),.75))
				draw_circle(center+Vector2(side*r*.06,-r*.02),r*.035,ink)
		_:
			for side in [-1.0,1.0]: draw_circle(center+Vector2(side*r*.06,-r*.02),r*.035,ink)
			var ring=PackedVector2Array();var tilt=.32+sin(clock*1.5)*.06
			for k in range(41):
				var a=float(k)/40.0*TAU
				ring.append(center+Vector2(cos(a)*r*.46,sin(a)*r*.46*tilt))
			draw_polyline(ring,color.lerp(Color.WHITE,.4),maxf(2.0,r*.05),true)
	# Orbiting motes: two at stage 2, four at stage 3.
	var motes=[0,2,4][clampi(stage,0,2)]
	for i in range(motes):
		var a=clock*2.2+float(i)/motes*TAU
		var at=center+Vector2(cos(a)*r*.5,sin(a)*r*.18)
		draw_circle(at,r*.09,Color(color,.35));draw_circle(at,r*.045,color.lerp(Color.WHITE,.5))
	if selected:
		draw_arc(size*.5,minf(size.x,size.y)*.47,0,TAU,48,Color("f4da9e"),maxf(2.0,r*.05),true)

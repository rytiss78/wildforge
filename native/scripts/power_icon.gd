extends Control
class_name PowerIcon

var key = "damage"
var color = Color("65cbea")
var tier = 0
var weapon_icon = false
var drawn_stat = false

func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	if str(key).begins_with("mut:"): resized.connect(queue_redraw);return
	# Stat upgrades draw their own octagonal medallion instead of a picture.
	if not weapon_icon and not StatGlyphs.resolve(str(key)).is_empty(): drawn_stat=true;resized.connect(queue_redraw);return
	var art=TextureRect.new()
	art.texture=IllustratedIcons.texture(key,weapon_icon)
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Engraved vector symbols share the same dark frame as reward cards.

# Mutation medallion: the ring and fill name the strain (element), the large
# glyph names the trigger, so a card reads at a glance without its text.
func _draw():
	if drawn_stat: StatGlyphs.draw_medallion(self,str(key),size*.5,minf(size.x,size.y)*.46);return
	if not str(key).begins_with("mut:"): return
	draw_mutation(self,str(key),size*.5,minf(size.x,size.y)*.46)

static func draw_mutation(ci: CanvasItem,key: String,c: Vector2,r: float):
	var definition=MutationBook.entry(key.trim_prefix("mut:"))
	if definition.is_empty(): return
	var ink=Color("10161a");var light=Color("fff4dc")
	if definition.has("pair"):
		var a=MutationBook.STRAINS[definition.pair[0]].color;var b=MutationBook.STRAINS[definition.pair[1]].color
		ci.draw_circle(c,r,ink)
		draw_arc_fill(ci,c,r*.9,PI*.5,PI*1.5,a.darkened(.35));draw_arc_fill(ci,c,r*.9,-PI*.5,PI*.5,b.darkened(.35))
		ci.draw_arc(c,r*.9,0,TAU,48,light,maxf(1.5,r*.06))
		emblem(ci,definition.pair[0],c+Vector2(-r*.36,0),r*.36,light);emblem(ci,definition.pair[1],c+Vector2(r*.36,0),r*.36,light)
		return
	var tone=MutationBook.STRAINS[definition.strain].color if definition.has("strain") else Color("e6c36a")
	ci.draw_circle(c,r,ink);ci.draw_circle(c,r*.9,tone.darkened(.45))
	ci.draw_arc(c,r*.9,0,TAU,48,tone,maxf(2.0,r*.1))
	if definition.group=="core": glyph(ci,MutationBook.TRIGGERS[definition.trigger].glyph,c,r*.55,light)
	elif definition.group=="rule": emblem(ci,definition.strain,c,r*.6,light);ci.draw_arc(c,r*.72,0,TAU,48,Color(tone,.8),maxf(1.0,r*.04))
	else: starburst(ci,c,r*.62,light,8)

static func draw_arc_fill(ci: CanvasItem,c: Vector2,r: float,from: float,to: float,color: Color):
	var points=PackedVector2Array([c])
	for i in range(25):
		var a=lerpf(from,to,i/24.0);points.append(c+Vector2(cos(a),sin(a))*r)
	ci.draw_colored_polygon(points,color)

static func starburst(ci: CanvasItem,c: Vector2,r: float,color: Color,points_count: int):
	var points=PackedVector2Array()
	for i in range(points_count*2):
		var a=-PI*.5+i*PI/points_count;points.append(c+Vector2(cos(a),sin(a))*(r if i%2==0 else r*.42))
	ci.draw_colored_polygon(points,color)

static func arrow(ci: CanvasItem,c: Vector2,r: float,direction: Vector2,color: Color):
	var side=Vector2(-direction.y,direction.x);var w=maxf(2.0,r*.28)
	ci.draw_line(c-direction*r*.8,c+direction*r*.2,color,w)
	ci.draw_colored_polygon(PackedVector2Array([c+direction*r,c+direction*r*.1+side*r*.6,c+direction*r*.1-side*r*.6]),color)

static func glyph(ci: CanvasItem,name: String,c: Vector2,r: float,color: Color):
	var w=maxf(2.0,r*.22)
	match name:
		"hit":
			ci.draw_line(c+Vector2(-r,r),c+Vector2(r*.8,-r*.8),color,w)
			ci.draw_line(c+Vector2(-r*.75,r*.15),c+Vector2(-r*.15,r*.75),color,w)
		"crit": starburst(ci,c,r*1.1,color,4)
		"kill":
			ci.draw_circle(c+Vector2(0,-r*.15),r*.8,color);ci.draw_rect(Rect2(c+Vector2(-r*.45,r*.35),Vector2(r*.9,r*.55)),color)
			ci.draw_circle(c+Vector2(-r*.32,-r*.2),r*.2,Color("10161a"));ci.draw_circle(c+Vector2(r*.32,-r*.2),r*.2,Color("10161a"))
		"dash":
			arrow(ci,c+Vector2(r*.15,0),r,Vector2.RIGHT,color)
			ci.draw_line(c+Vector2(-r,-r*.5),c+Vector2(-r*.35,-r*.5),color,w*.6);ci.draw_line(c+Vector2(-r,r*.5),c+Vector2(-r*.35,r*.5),color,w*.6)
		"jump": arrow(ci,c,r,Vector2.UP,color)
		"slam": arrow(ci,c+Vector2(0,-r*.2),r*.85,Vector2.DOWN,color);ci.draw_line(c+Vector2(-r,r*.95),c+Vector2(r,r*.95),color,w)
		"hurt":
			ci.draw_circle(c+Vector2(-r*.42,-r*.25),r*.48,color);ci.draw_circle(c+Vector2(r*.42,-r*.25),r*.48,color)
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-r*.88,-r*.1),c+Vector2(r*.88,-r*.1),c+Vector2(0,r)]),color)
			ci.draw_polyline(PackedVector2Array([c+Vector2(0,-r*.55),c+Vector2(-r*.15,-r*.1),c+Vector2(r*.15,r*.2),c+Vector2(0,r*.6)]),Color("10161a"),maxf(1.5,w*.5))
		"pulse":
			ci.draw_circle(c,r*.3,color);ci.draw_arc(c,r*.65,0,TAU,32,color,w*.6);ci.draw_arc(c,r,0,TAU,32,Color(color,.7),w*.5)
		"pickup":
			ci.draw_circle(c,r,Color("f6d178"));ci.draw_arc(c,r*.7,0,TAU,32,Color("8a5a12"),w*.5)
			ci.draw_line(c+Vector2(0,-r*.45),c+Vector2(0,r*.45),Color("8a5a12"),w*.6)

# Element emblems for strain rules and hybrids.
static func emblem(ci: CanvasItem,strain: String,c: Vector2,r: float,color: Color):
	var w=maxf(2.0,r*.2)
	match strain:
		"bloom":
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(0,-r),c+Vector2(r*.7,-r*.1),c+Vector2(0,r),c+Vector2(-r*.7,-r*.1)]),color)
			ci.draw_line(c+Vector2(0,-r*.6),c+Vector2(0,r*.9),Color("10161a"),w*.4)
		"venom":
			ci.draw_circle(c+Vector2(0,r*.25),r*.62,color)
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(0,-r),c+Vector2(r*.55,r*.05),c+Vector2(-r*.55,r*.05)]),color)
		"frost":
			for i in range(3):
				var d=Vector2.from_angle(i*PI/3)*r;ci.draw_line(c-d,c+d,color,w)
		"storm":
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(r*.2,-r),c+Vector2(-r*.55,r*.1),c+Vector2(-r*.05,r*.1),c+Vector2(-r*.25,r),c+Vector2(r*.55,-r*.15),c+Vector2(r*.05,-r*.15)]),color)
		"ember":
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(0,-r),c+Vector2(r*.6,r*.1),c+Vector2(r*.45,r*.8),c+Vector2(-r*.45,r*.8),c+Vector2(-r*.6,r*.1)]),color)
			ci.draw_circle(c+Vector2(0,r*.45),r*.3,Color("10161a"))
		"comet":
			starburst(ci,c+Vector2(r*.25,-r*.25),r*.6,color,5)
			ci.draw_line(c+Vector2(-r*.9,r*.9),c+Vector2(-r*.05,r*.05),color,w)

static func color_for(name: String) -> Color:
	if name in ["burn","flame","fire","fire-turret","explosion","splash","rocket","rocket-turret"]: return Color("ff955c")
	if name in ["poison","pools","poison-turret"]: return Color("8bdd6e")
	if name in ["freeze","slow","ice","ice-turret"]: return Color("76d9f6")
	if name in ["lifesteal","maxHp","regen","salvage","repair"]: return Color("f77b98")
	if name in ["ghost","blind","burrow","nova","orbitDamage"]: return Color("bda0f4")
	if name in ["goldGain","discount","keyPower","walkGold","hurtGold","interest","coinRadius","potGold"]: return Color("f6d178")
	if name in ["armor","shield","dodge"]: return Color("81b5de")
	return Color("a1dccc")


extends RefCounted
class_name ItemArt

# Cards look like cards, items look like things (user, November 3: "card icons
# should be cards, so it is clear what is a card and what is an item you can
# take any number of; items should be items, not just a coloured icon").
#   draw_card  a small upright playing card: parchment face, a frame in the
#              stat's colour, the stat symbol in the middle, corner pips
#   draw_item  a cartoon object: a potion, ring, boots, shield, pouch, gem...
#              picked by what the item does, painted in its stat's colour, the
#              stat symbol engraved on it and the condition badge in a corner.
# Weapon upgrades keep their weapon picture medallion (StatGlyphs).

const INK=Color("10161a")
const PAPER=Color("f3e6c8")
# category -> object
const BY_CATEGORY={"offense":"gauntlet","fire":"jar","toxic":"potion","frost":"gem","storm":"battery","shadow":"mask",
	"defense":"shield","recovery":"potion","mobility":"boots","fortune":"pouch","arcane":"scroll","engineering":"gear","garden":"seed"}
# stat -> object, where the category's object would not fit
const BY_STAT={"crit":"gem","critPower":"gauntlet","luck":"ring","xpGain":"scroll","pickup":"horseshoe","maxHp":"amulet","regen":"potion",
	"lifesteal":"amulet","dodge":"feather","speed":"boots","jumpHeight":"feather","airJumps":"feather","armor":"shield","shield":"orb",
	"thorns":"ring","goldGain":"pouch","chestBonus":"key","keyPower":"key","revive":"amulet","multishot":"gauntlet","size":"orb",
	"range":"scroll","rate":"battery","damage":"gauntlet","burn":"jar","poison":"potion","freeze":"gem","chain":"battery","storm":"battery",
	"relicClose":"knuckles","relicPickle":"pickle","relicStew":"stew","relicTwin":"shards","relicReceipt":"receipt","relicTrophy":"jar",
	"relicBelt":"belt","relicShell":"shell","relicHeels":"skate","relicRockets":"rocket","relicOvercrit":"prism","relicBonk":"mallet",
	"relicPillow":"pillow","relicWisps":"lantern","relicHourglass":"hourglass","curse":"mask","chaos":"gem"}

static func object_of(stat: String) -> String:
	if BY_STAT.has(stat): return BY_STAT[stat]
	var entry=StatGlyphs.STATS.get(stat,["arcane","star"])
	return BY_CATEGORY.get(entry[0],"orb")

static func tone_of(stat: String) -> Color:
	var entry=StatGlyphs.STATS.get(stat,["arcane","star"])
	return StatGlyphs.CATEGORY.get(entry[0],Color("c38cf0"))

# --- cards -----------------------------------------------------------------
static func draw_card(ci: CanvasItem,stat: String,c: Vector2,r: float,tier_color: Color=Color.TRANSPARENT):
	var tone=tone_of(stat);var frame=tone if tier_color==Color.TRANSPARENT else tier_color
	var half=Vector2(r*.72,r*.98);var rect=Rect2(c-half,half*2)
	var back=StyleBoxFlat.new();back.bg_color=INK;back.set_corner_radius_all(int(r*.16));ci.draw_style_box(back,rect.grow(maxf(1.5,r*.06)))
	var face=StyleBoxFlat.new();face.bg_color=PAPER;face.set_corner_radius_all(int(r*.14));face.border_color=frame;face.set_border_width_all(maxi(2,int(r*.09)))
	ci.draw_style_box(face,rect)
	var inner=rect.grow(-r*.2);var plate=StyleBoxFlat.new();plate.bg_color=tone.darkened(.45);plate.set_corner_radius_all(int(r*.1))
	ci.draw_style_box(plate,inner)
	var entry=StatGlyphs.STATS.get(stat,["arcane","star"])
	StatGlyphs.glyph(ci,entry[1],c,r*.42,Color("fff4dc"))
	# Corner pips like a playing card.
	for corner in [rect.position+Vector2(r*.2,r*.2),rect.end-Vector2(r*.2,r*.2)]:
		ci.draw_colored_polygon(PackedVector2Array([corner+Vector2(0,-r*.11),corner+Vector2(r*.08,0),corner+Vector2(0,r*.11),corner+Vector2(-r*.08,0)]),frame)

# --- items -----------------------------------------------------------------
static func draw_item(ci: CanvasItem,key: String,c: Vector2,r: float) -> bool:
	var info=StatGlyphs.resolve(key)
	if info.is_empty(): return false
	if not str(info.weapon).is_empty(): return StatGlyphs.draw_medallion(ci,key,c,r)
	var stat=str(info.stat);var tone=tone_of(stat);var dark=tone.darkened(.45);var light=tone.lightened(.35)
	var w=maxf(1.5,r*.08)
	match object_of(stat):
		"potion":
			ci.draw_circle(c+Vector2(0,r*.2),r*.62,INK);ci.draw_circle(c+Vector2(0,r*.2),r*.54,tone)
			ci.draw_rect(Rect2(c+Vector2(-r*.2,-r*.75),Vector2(r*.4,r*.5)),INK);ci.draw_rect(Rect2(c+Vector2(-r*.13,-r*.7),Vector2(r*.26,r*.45)),Color("d8eef2"))
			ci.draw_rect(Rect2(c+Vector2(-r*.24,-r*.92),Vector2(r*.48,r*.2)),Color("8a5a32"))
			ci.draw_circle(c+Vector2(-r*.2,r*.02),r*.13,Color(1,1,1,.55))
		"ring":
			ci.draw_arc(c+Vector2(0,r*.15),r*.55,0,TAU,28,INK,r*.32);ci.draw_arc(c+Vector2(0,r*.15),r*.55,0,TAU,28,Color("e8c25a"),r*.2)
			ci.draw_colored_polygon(diamond(c+Vector2(0,-r*.45),r*.34),INK);ci.draw_colored_polygon(diamond(c+Vector2(0,-r*.45),r*.26),tone)
		"amulet":
			ci.draw_arc(c+Vector2(0,-r*.1),r*.7,PI*1.05,TAU-PI*.05,20,INK,w*2.6);ci.draw_arc(c+Vector2(0,-r*.1),r*.7,PI*1.05,TAU-PI*.05,20,Color("e8c25a"),w*1.4)
			ci.draw_circle(c+Vector2(0,r*.25),r*.52,INK);ci.draw_circle(c+Vector2(0,r*.25),r*.44,Color("e8c25a"));ci.draw_circle(c+Vector2(0,r*.25),r*.34,tone)
			ci.draw_circle(c+Vector2(-r*.12,r*.12),r*.1,Color(1,1,1,.6))
		"boots":
			var boot=PackedVector2Array([c+Vector2(-r*.45,-r*.8),c+Vector2(r*.1,-r*.8),c+Vector2(r*.15,r*.15),c+Vector2(r*.8,r*.3),c+Vector2(r*.8,r*.7),c+Vector2(-r*.5,r*.7)])
			ci.draw_colored_polygon(grow(boot,c,1.12),INK);ci.draw_colored_polygon(boot,tone)
			ci.draw_rect(Rect2(c+Vector2(-r*.5,r*.5),Vector2(r*1.3,r*.2)),dark)
		"shield":
			var crest=PackedVector2Array([c+Vector2(-r*.7,-r*.75),c+Vector2(r*.7,-r*.75),c+Vector2(r*.65,r*.05),c+Vector2(0,r*.85),c+Vector2(-r*.65,r*.05)])
			ci.draw_colored_polygon(grow(crest,c,1.12),INK);ci.draw_colored_polygon(crest,tone);ci.draw_colored_polygon(grow(crest,c,.72),dark)
		"pouch":
			ci.draw_circle(c+Vector2(0,r*.25),r*.62,INK);ci.draw_circle(c+Vector2(0,r*.25),r*.54,Color("b9884c"))
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-r*.3,-r*.35),c+Vector2(r*.3,-r*.35),c+Vector2(r*.45,-r*.8),c+Vector2(-r*.45,-r*.8)]),Color("9a6c38"))
			ci.draw_line(c+Vector2(-r*.35,-r*.35),c+Vector2(r*.35,-r*.35),tone,w*1.6)
		"gem","prism":
			var cut=PackedVector2Array([c+Vector2(0,-r*.85),c+Vector2(r*.7,-r*.2),c+Vector2(r*.42,r*.75),c+Vector2(-r*.42,r*.75),c+Vector2(-r*.7,-r*.2)])
			if object_of(stat)=="prism": cut=PackedVector2Array([c+Vector2(0,-r*.85),c+Vector2(r*.8,r*.7),c+Vector2(-r*.8,r*.7)])
			ci.draw_colored_polygon(grow(cut,c,1.14),INK);ci.draw_colored_polygon(cut,tone)
			ci.draw_colored_polygon(PackedVector2Array([cut[0],cut[1],c]),light)
		"scroll":
			ci.draw_rect(Rect2(c+Vector2(-r*.6,-r*.55),Vector2(r*1.2,r*1.1)),INK);ci.draw_rect(Rect2(c+Vector2(-r*.52,-r*.5),Vector2(r*1.04,r*1.0)),PAPER)
			for y in [-.6,.6]: ci.draw_rect(Rect2(c+Vector2(-r*.72,r*y-r*.12),Vector2(r*1.44,r*.24)),Color("a2743e"))
		"gauntlet","knuckles":
			# A clenched armoured fist: knuckles on top, thumb across, a cuff below.
			var hand=StyleBoxFlat.new();hand.bg_color=tone;hand.set_corner_radius_all(int(r*.28));hand.border_color=INK;hand.set_border_width_all(maxi(2,int(w)))
			ci.draw_style_box(hand,Rect2(c+Vector2(-r*.62,-r*.55),Vector2(r*1.24,r*.95)))
			for k in range(4):
				var knuckle=c+Vector2(-r*.42+k*r*.28,-r*.5)
				ci.draw_circle(knuckle,r*.17,INK);ci.draw_circle(knuckle,r*.12,Color("e8c25a") if object_of(stat)=="knuckles" else light)
			for k in range(3): ci.draw_line(c+Vector2(-r*.28+k*r*.28,-r*.38),c+Vector2(-r*.28+k*r*.28,-r*.05),dark,w)
			var thumb=StyleBoxFlat.new();thumb.bg_color=light;thumb.set_corner_radius_all(int(r*.14));thumb.border_color=INK;thumb.set_border_width_all(maxi(1,int(w*.8)))
			ci.draw_style_box(thumb,Rect2(c+Vector2(-r*.55,-r*.08),Vector2(r*.85,r*.3)))
			var cuff=StyleBoxFlat.new();cuff.bg_color=dark;cuff.set_corner_radius_all(int(r*.08));cuff.border_color=INK;cuff.set_border_width_all(maxi(1,int(w*.8)))
			ci.draw_style_box(cuff,Rect2(c+Vector2(-r*.5,r*.4),Vector2(r*1.0,r*.42)))
		"battery":
			ci.draw_rect(Rect2(c+Vector2(-r*.42,-r*.7),Vector2(r*.84,r*1.5)),INK);ci.draw_rect(Rect2(c+Vector2(-r*.34,-r*.62),Vector2(r*.68,r*1.34)),tone)
			ci.draw_rect(Rect2(c+Vector2(-r*.16,-r*.88),Vector2(r*.32,r*.2)),INK)
		"mask":
			ci.draw_circle(c,r*.72,INK);ci.draw_circle(c,r*.64,tone)
			ci.draw_circle(c+Vector2(-r*.25,-r*.1),r*.16,INK);ci.draw_circle(c+Vector2(r*.25,-r*.1),r*.16,INK)
		"gear":
			for k in range(8): ci.draw_rect(Rect2(c+Vector2.from_angle(k*TAU/8)*r*.62-Vector2.ONE*r*.15,Vector2.ONE*r*.3),INK)
			ci.draw_circle(c,r*.6,INK);ci.draw_circle(c,r*.52,tone);ci.draw_circle(c,r*.18,INK)
		"seed":
			ci.draw_rect(Rect2(c+Vector2(-r*.55,-r*.75),Vector2(r*1.1,r*1.5)),INK);ci.draw_rect(Rect2(c+Vector2(-r*.47,-r*.67),Vector2(r*.94,r*1.34)),PAPER)
			ci.draw_circle(c+Vector2(0,r*.1),r*.32,tone)
		"feather":
			var vane=PackedVector2Array([c+Vector2(-r*.6,r*.75),c+Vector2(-r*.4,-r*.1),c+Vector2(r*.3,-r*.8),c+Vector2(r*.45,-r*.55),c+Vector2(0,r*.3)])
			ci.draw_colored_polygon(grow(vane,c,1.12),INK);ci.draw_colored_polygon(vane,tone);ci.draw_line(c+Vector2(-r*.7,r*.85),c+Vector2(r*.35,-r*.65),light,w)
		"orb","lantern":
			ci.draw_rect(Rect2(c+Vector2(-r*.4,r*.45),Vector2(r*.8,r*.3)),Color("7a5a3a"))
			ci.draw_circle(c,r*.62,INK);ci.draw_circle(c,r*.54,tone);ci.draw_circle(c+Vector2(-r*.2,-r*.22),r*.15,Color(1,1,1,.6))
		"horseshoe":
			ci.draw_arc(c,r*.55,PI*.95,TAU+PI*.05,20,INK,r*.42);ci.draw_arc(c,r*.55,PI*.95,TAU+PI*.05,20,Color("c8ced6"),r*.28)
			for x in [-1,1]: ci.draw_rect(Rect2(c+Vector2(x*r*.55-r*.14,0),Vector2(r*.28,r*.3)),tone)
		"key":
			ci.draw_circle(c+Vector2(-r*.35,-r*.3),r*.38,INK);ci.draw_circle(c+Vector2(-r*.35,-r*.3),r*.28,Color("e8c25a"));ci.draw_circle(c+Vector2(-r*.35,-r*.3),r*.12,INK)
			ci.draw_line(c+Vector2(-r*.1,-r*.05),c+Vector2(r*.65,r*.7),Color("e8c25a"),r*.18);ci.draw_line(c+Vector2(r*.4,r*.45),c+Vector2(r*.6,r*.25),Color("e8c25a"),r*.14)
		"jar":
			# A glass jar with something glowing inside and a cork lid.
			var glass=StyleBoxFlat.new();glass.bg_color=Color("cfe6ea");glass.set_corner_radius_all(int(r*.3));glass.border_color=INK;glass.set_border_width_all(maxi(2,int(w)))
			ci.draw_style_box(glass,Rect2(c+Vector2(-r*.55,-r*.5),Vector2(r*1.1,r*1.3)))
			var fill=StyleBoxFlat.new();fill.bg_color=tone;fill.set_corner_radius_all(int(r*.24))
			ci.draw_style_box(fill,Rect2(c+Vector2(-r*.45,-r*.1),Vector2(r*.9,r*.8)))
			ci.draw_rect(Rect2(c+Vector2(-r*.4,-r*.75),Vector2(r*.8,r*.28)),Color("8a5a32"));ci.draw_rect(Rect2(c+Vector2(-r*.4,-r*.75),Vector2(r*.8,r*.28)),INK,false,w*.8)
			ci.draw_line(c+Vector2(-r*.35,-r*.35),c+Vector2(-r*.35,r*.5),Color(1,1,1,.6),w*1.2)
		"stew":
			ci.draw_circle(c+Vector2(0,-r*.05),r*.66,INK)
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-r*.8,-r*.1),c+Vector2(r*.8,-r*.1),c+Vector2(r*.5,r*.65),c+Vector2(-r*.5,r*.65)]),Color("b9884c"))
			ci.draw_set_transform(c+Vector2(0,-r*.1),0,Vector2(1,.3));ci.draw_circle(Vector2.ZERO,r*.78,tone);ci.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
			for k in range(3): ci.draw_arc(c+Vector2(-r*.3+k*r*.3,-r*.55),r*.12,PI*.5,PI*1.5,8,Color(1,1,1,.6),w)
		"pickle":
			ci.draw_set_transform(c,-.5,Vector2(1.0,.5));ci.draw_circle(Vector2.ZERO,r*.85,INK);ci.draw_circle(Vector2.ZERO,r*.76,Color("6fae3a"))
			for k in range(5): ci.draw_circle(Vector2(-r*.5+k*r*.25,-r*.2+(k%2)*r*.35),r*.07,Color("a6d86a"))
			ci.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
		"mallet":
			ci.draw_line(c+Vector2(-r*.55,r*.75),c+Vector2(r*.2,-r*.1),Color("8a5a32"),r*.2)
			var head=PackedVector2Array([c+Vector2(-r*.05,-r*.85),c+Vector2(r*.85,-r*.05),c+Vector2(r*.45,r*.35),c+Vector2(-r*.45,-r*.45)])
			ci.draw_colored_polygon(grow(head,c+Vector2(r*.2,-r*.25),1.12),INK);ci.draw_colored_polygon(head,tone)
		"pillow":
			var puff=Rect2(c+Vector2(-r*.75,-r*.5),Vector2(r*1.5,r*1.0))
			var box=StyleBoxFlat.new();box.bg_color=tone.lightened(.2);box.set_corner_radius_all(int(r*.4));box.border_color=INK;box.set_border_width_all(maxi(2,int(w)))
			ci.draw_style_box(box,puff)
		"hourglass":
			ci.draw_rect(Rect2(c+Vector2(-r*.6,-r*.85),Vector2(r*1.2,r*.18)),Color("8a5a32"));ci.draw_rect(Rect2(c+Vector2(-r*.6,r*.67),Vector2(r*1.2,r*.18)),Color("8a5a32"))
			for s in [-1,1]: ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-r*.45,s*r*.67),c+Vector2(r*.45,s*r*.67),c]),tone)
		"belt":
			ci.draw_rect(Rect2(c+Vector2(-r*.85,-r*.25),Vector2(r*1.7,r*.5)),INK);ci.draw_rect(Rect2(c+Vector2(-r*.8,-r*.2),Vector2(r*1.6,r*.4)),Color("8a5a32"))
			ci.draw_rect(Rect2(c+Vector2(-r*.3,-r*.38),Vector2(r*.6,r*.76)),Color("e8c25a"));ci.draw_rect(Rect2(c+Vector2(-r*.16,-r*.22),Vector2(r*.32,r*.44)),INK)
		"shell":
			var fan=PackedVector2Array([c+Vector2(0,r*.75)])
			for k in range(9): fan.append(c+Vector2.from_angle(PI+k*PI/8)*r*.8)
			ci.draw_colored_polygon(grow(fan,c,1.1),INK);ci.draw_colored_polygon(fan,tone)
			for k in range(1,8): ci.draw_line(c+Vector2(0,r*.75),c+Vector2.from_angle(PI+k*PI/8)*r*.75,dark,w)
		"skate":
			var boot=PackedVector2Array([c+Vector2(-r*.4,-r*.8),c+Vector2(r*.1,-r*.8),c+Vector2(r*.15,0),c+Vector2(r*.75,r*.15),c+Vector2(r*.75,r*.45),c+Vector2(-r*.45,r*.45)])
			ci.draw_colored_polygon(grow(boot,c,1.1),INK);ci.draw_colored_polygon(boot,tone)
			for x in [-.25,.5]: ci.draw_circle(c+Vector2(r*x,r*.7),r*.18,INK)
		"rocket":
			var body=PackedVector2Array([c+Vector2(0,-r*.9),c+Vector2(r*.3,-r*.4),c+Vector2(r*.3,r*.5),c+Vector2(-r*.3,r*.5),c+Vector2(-r*.3,-r*.4)])
			ci.draw_colored_polygon(grow(body,c,1.12),INK);ci.draw_colored_polygon(body,tone)
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-r*.2,r*.5),c+Vector2(r*.2,r*.5),c+Vector2(0,r*.9)]),Color("ffb347"))
		"receipt":
			var paper=PackedVector2Array([c+Vector2(-r*.5,-r*.85),c+Vector2(r*.5,-r*.85),c+Vector2(r*.5,r*.75),c+Vector2(r*.25,r*.6),c+Vector2(0,r*.75),c+Vector2(-r*.25,r*.6),c+Vector2(-r*.5,r*.75)])
			ci.draw_colored_polygon(grow(paper,c,1.1),INK);ci.draw_colored_polygon(paper,PAPER)
			for k in range(3): ci.draw_line(c+Vector2(-r*.3,-r*.5+k*r*.25),c+Vector2(r*.3,-r*.5+k*r*.25),Color("9a8a6a"),w)
		"shards":
			for s in [-1,1]:
				var shard=PackedVector2Array([c+Vector2(s*r*.3,-r*.85),c+Vector2(s*r*.3+r*.32,r*.1),c+Vector2(s*r*.3,r*.75),c+Vector2(s*r*.3-r*.32,r*.1)])
				ci.draw_colored_polygon(grow(shard,c+Vector2(s*r*.3,0),1.15),INK);ci.draw_colored_polygon(shard,tone)
		_:
			ci.draw_circle(c,r*.62,INK);ci.draw_circle(c,r*.54,tone)
	# The stat symbol engraved small, the condition badge in its corner.
	var entry=StatGlyphs.STATS.get(stat,["arcane","star"])
	if not object_of(stat) in ["pickle","receipt","key","horseshoe"]:
		ci.draw_circle(c+Vector2(r*.55,r*.55),r*.3,INK);ci.draw_circle(c+Vector2(r*.55,r*.55),r*.25,dark)
		StatGlyphs.glyph(ci,entry[1],c+Vector2(r*.55,r*.55),r*.16,Color("fff4dc"))
	if not str(info.condition).is_empty():
		var badge=c+Vector2(-r*.62,-r*.62);var spec=StatGlyphs.CONDITIONS.get(info.condition,["one",Color("fff4dc")])
		ci.draw_circle(badge,r*.3,INK);ci.draw_circle(badge,r*.25,spec[1].darkened(.35));StatGlyphs.glyph(ci,spec[0],badge,r*.15,Color("fff4dc"))
	return true

static func diamond(c: Vector2,r: float) -> PackedVector2Array:
	return PackedVector2Array([c+Vector2(0,-r),c+Vector2(r*.8,0),c+Vector2(0,r),c+Vector2(-r*.8,0)])

static func drop(c: Vector2,r: float) -> PackedVector2Array:
	var points=PackedVector2Array([c+Vector2(0,-r*1.1)])
	for k in range(13): points.append(c+Vector2.from_angle(-PI*.15+k*PI*1.3/12)*r*.8)
	return points

static func grow(points: PackedVector2Array,c: Vector2,f: float) -> PackedVector2Array:
	var out=PackedVector2Array()
	for p in points: out.append(c+(p-c)*f)
	return out

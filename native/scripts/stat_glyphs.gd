extends RefCounted
class_name StatGlyphs

# Upgrade card icons drawn as octagonal medallions: the colour names what an
# upgrade affects (offense, fire, defense, healing...), the large symbol names the
# exact stat, and a corner badge names the condition of conditional upgrades.
# Weapon-specific upgrades show that weapon's own icon. Mutations keep their
# round medallions (power_icon.gd), so the two kinds read apart at a glance.

const INK=Color("10161a")
const LIGHT=Color("fff4dc")
const CATEGORY={
	"offense":Color("e86b4f"),"fire":Color("ff8a3d"),"toxic":Color("8bd65a"),"frost":Color("76d9f6"),
	"storm":Color("6fa8ff"),"shadow":Color("b48cf2"),"defense":Color("8fb3d9"),"recovery":Color("f27a98"),
	"mobility":Color("4fd1b5"),"fortune":Color("f2c75c"),"arcane":Color("c38cf0"),"engineering":Color("d49a5a"),
	"garden":Color("9bd36a"),"weapon":Color("e0b45e")}
# stat -> [category, glyph]
const STATS={
	"damage":["offense","sword"],"rate":["offense","clock"],"crit":["offense","star"],"critPower":["offense","burst"],
	"bossDamage":["offense","crown"],"execute":["offense","skull"],"berserk":["offense","fist"],"airDamage":["offense","wing"],
	"size":["offense","grow"],"projectileSpeed":["offense","bullet"],"range":["offense","target"],"multishot":["offense","triple"],
	"pierce":["offense","pierce"],"ricochet":["offense","bounce"],"boomerang":["offense","bounce"],"splash":["offense","burst"],"explosion":["offense","burst"],
	"dashBlast":["offense","burst"],"jumpBlast":["offense","burst"],"knockback":["offense","push"],
	"burn":["fire","flame"],"slamFire":["fire","flame"],"poison":["toxic","drop"],"pools":["toxic","drop"],"slamPoison":["toxic","drop"],
	"freeze":["frost","snow"],"slow":["frost","slow"],"chain":["storm","bolt"],"storm":["storm","bolt"],
	"blind":["shadow","eye"],"ghost":["shadow","ghost"],"burrow":["shadow","spade"],"stun":["shadow","spiral"],
	"armor":["defense","shield"],"dodge":["defense","swirl"],"shield":["defense","bubble"],"jumpShield":["defense","bubble"],
	"fallGuard":["defense","feather"],"fallThreshold":["defense","feather"],"thorns":["defense","thorn"],
	"maxHp":["recovery","heart"],"regen":["recovery","heal"],"lifesteal":["recovery","fang"],"salvage":["recovery","heal"],
	"revive":["recovery","ankh"],"landingHeal":["recovery","heal"],"slamHeal":["recovery","heal"],"coinHeal":["recovery","heal"],
	"chestHeal":["recovery","heal"],"flowerHeal":["garden","heal"],
	"speed":["mobility","wind"],"dashCooldown":["mobility","dash"],"jumpHeight":["mobility","jump"],"airJumps":["mobility","jump"],
	"bounceJump":["mobility","jump"],"airControl":["mobility","wing"],"slamPower":["mobility","slam"],"slamRadius":["mobility","slam"],
	"slamRecovery":["mobility","slam"],
	"goldGain":["fortune","coin"],"walkGold":["fortune","coin"],"hurtGold":["fortune","coin"],"potGold":["fortune","coin"],
	"interest":["fortune","coin"],"discount":["fortune","tag"],"keyPower":["fortune","key"],"coinRadius":["fortune","magnet"],
	"chestBonus":["fortune","chest"],"luck":["fortune","clover"],"banana":["fortune","banana"],
	"xpGain":["arcane","xp"],"pickup":["arcane","magnet"],"potionDuration":["arcane","potion"],"potionPower":["arcane","potion"],
	"potionChance":["arcane","potion"],"auraDamage":["arcane","ring"],"nova":["arcane","ring"],"enemyPull":["arcane","pull"],
	"enemyPush":["arcane","push"],"orbitDamage":["arcane","ring"],"drones":["engineering","turret"],
	"turretDamage":["engineering","turret"],"turretRate":["engineering","turret"],"turretRange":["engineering","turret"],
	"turretCount":["engineering","turret"],"turretLife":["engineering","turret"],"repair":["engineering","wrench"],
	"flowerPower":["garden","flower"],"flowerRoots":["garden","flower"],"flowerPollen":["garden","flower"],"flowerSeeds":["garden","flower"]}
const WEAPON_STATS={"discBounces":"disc","boomerangPierce":"boomerang","harpoonPull":"harpoon","gravitySize":"gravity",
	"hornStun":"horn","bubbleTime":"bubble","meteorCount":"meteor","bombSize":"bomb"}
# condition -> [glyph, badge colour]
const CONDITIONS={"air":["jump",Color("9fe7ff")],"ground":["ground",Color("c9b48a")],"moving":["wind",Color("4fd1b5")],
	"still":["pause",Color("c9c2b0")],"low":["heart",Color("f27a98")],"healthy":["heart",Color("8bd65a")],
	"shield":["bubble",Color("8fb3d9")],"bare":["unshield",Color("c9c2b0")],"dash":["dash",Color("43eaff")],
	"slam":["slam",Color("ffbd35")],"kill":["skull",Color("e86b4f")],"hurt":["crack",Color("f27a98")],
	"boss":["crown",Color("ffd36b")],"alone":["one",Color("c9c2b0")],"crowd":["three",Color("e86b4f")],
	"flower":["flower",Color("9bd36a")],"turret":["turret",Color("d49a5a")],"rich":["coin",Color("f2c75c")],
	"eclipse":["moon",Color("b48cf2")],"guardian":["gate",Color("e0b45e")]}

static var loot={}
static var augments={}

static func load_catalog():
	if not loot.is_empty(): return
	var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	for item in data.loot: loot[item.id]=str(item.effects[0].key)
	augments=data.augments

# Resolves an upgrade id (or a stat key) to what its icon shows; empty if unknown.
static func resolve(key: String) -> Dictionary:
	load_catalog()
	var stat=str(loot.get(key,key));var condition=""
	if augments.has(stat): condition=str(augments[stat].condition);stat=str(augments[stat].stat)
	var weapon=""
	if WEAPON_STATS.has(stat): weapon=WEAPON_STATS[stat]
	elif stat.ends_with("Power") and stat.trim_suffix("Power") in ["boomerang","disc","harpoon","gravity","horn","bubble","meteor","bomb"]+SkillBook.KINDS: weapon=stat.trim_suffix("Power")
	if weapon.is_empty() and not STATS.has(stat): return {}
	return {"stat":stat,"condition":condition,"weapon":weapon}

static func octagon(c: Vector2,r: float) -> PackedVector2Array:
	var points=PackedVector2Array()
	for i in range(8): points.append(c+Vector2.from_angle(PI/8+i*TAU/8)*r)
	return points

static func draw_medallion(ci: CanvasItem,key: String,c: Vector2,r: float) -> bool:
	var info=resolve(key)
	if info.is_empty(): return false
	var tone=CATEGORY.weapon if not info.weapon.is_empty() else CATEGORY[STATS[info.stat][0]]
	ci.draw_colored_polygon(octagon(c,r),INK)
	# Weapon pictures sit on a lighter plate so the weapon reads clearly.
	ci.draw_colored_polygon(octagon(c,r*.9),tone.darkened(.5) if info.weapon.is_empty() else Color("e9dcc0"))
	var rim=octagon(c,r*.9);rim.append(rim[0]);ci.draw_polyline(rim,tone,maxf(2.0,r*.09))
	if not info.weapon.is_empty():
		var texture=IllustratedIcons.texture(info.weapon,true)
		if texture: ci.draw_texture_rect(texture,Rect2(c-Vector2.ONE*r*.8,Vector2.ONE*r*1.6),false)
		ci.draw_circle(c+Vector2(r*.6,r*.6),r*.27,tone.darkened(.3));plus(ci,c+Vector2(r*.6,r*.6),r*.16,LIGHT)
	else:
		glyph(ci,STATS[info.stat][1],c,r*.55,LIGHT)
	if not info.condition.is_empty():
		var badge=c+Vector2(r*.68,-r*.68);var spec=CONDITIONS.get(info.condition,["one",LIGHT])
		ci.draw_circle(badge,r*.34,INK);ci.draw_circle(badge,r*.29,spec[1].darkened(.35))
		ci.draw_arc(badge,r*.29,0,TAU,24,spec[1],maxf(1.5,r*.05))
		glyph(ci,spec[0],badge,r*.17,LIGHT)
	return true

static func plus(ci: CanvasItem,c: Vector2,r: float,color: Color):
	var w=maxf(2.0,r*.4);ci.draw_line(c-Vector2(r,0),c+Vector2(r,0),color,w);ci.draw_line(c-Vector2(0,r),c+Vector2(0,r),color,w)

static func arrow(ci: CanvasItem,c: Vector2,r: float,direction: Vector2,color: Color):
	var side=Vector2(-direction.y,direction.x);var w=maxf(1.5,r*.28)
	ci.draw_line(c-direction*r*.8,c+direction*r*.2,color,w)
	ci.draw_colored_polygon(PackedVector2Array([c+direction*r,c+direction*r*.1+side*r*.6,c+direction*r*.1-side*r*.6]),color)

static func star(ci: CanvasItem,c: Vector2,r: float,points: int,inner: float,color: Color):
	var shape=PackedVector2Array()
	for i in range(points*2): shape.append(c+Vector2.from_angle(-PI/2+i*PI/points)*(r if i%2==0 else r*inner))
	ci.draw_colored_polygon(shape,color)

static func heart(ci: CanvasItem,c: Vector2,r: float,color: Color):
	ci.draw_circle(c+Vector2(-r*.42,-r*.25),r*.48,color);ci.draw_circle(c+Vector2(r*.42,-r*.25),r*.48,color)
	ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-r*.88,-r*.1),c+Vector2(r*.88,-r*.1),c+Vector2(0,r)]),color)

static func coin(ci: CanvasItem,c: Vector2,r: float):
	ci.draw_circle(c,r,Color("f6d178"));ci.draw_arc(c,r*.72,0,TAU,24,Color("8a5a12"),maxf(1.5,r*.12))
	ci.draw_line(c+Vector2(0,-r*.45),c+Vector2(0,r*.45),Color("8a5a12"),maxf(1.5,r*.16))

static func glyph(ci: CanvasItem,name: String,c: Vector2,r: float,color: Color):
	var w=maxf(1.5,r*.2)
	match name:
		"sword":
			ci.draw_line(c+Vector2(-r*.85,r*.85),c+Vector2(r*.75,-r*.75),color,w*1.2)
			ci.draw_line(c+Vector2(-r*.7,r*.2),c+Vector2(-r*.2,r*.7),color,w)
		"clock":
			ci.draw_arc(c,r*.85,0,TAU,32,color,w);ci.draw_line(c,c+Vector2(0,-r*.6),color,w);ci.draw_line(c,c+Vector2(r*.45,0),color,w)
		"star": star(ci,c,r,4,.4,color)
		"burst": star(ci,c,r*1.05,8,.45,color)
		"crown":
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-r*.9,r*.6),c+Vector2(-r*.9,-r*.4),c+Vector2(-r*.45,r*.05),c+Vector2(0,-r*.7),c+Vector2(r*.45,r*.05),c+Vector2(r*.9,-r*.4),c+Vector2(r*.9,r*.6)]),color)
		"skull":
			ci.draw_circle(c+Vector2(0,-r*.15),r*.75,color);ci.draw_rect(Rect2(c+Vector2(-r*.42,r*.3),Vector2(r*.84,r*.5)),color)
			ci.draw_circle(c+Vector2(-r*.3,-r*.18),r*.2,INK);ci.draw_circle(c+Vector2(r*.3,-r*.18),r*.2,INK)
		"fist":
			ci.draw_rect(Rect2(c+Vector2(-r*.7,-r*.45),Vector2(r*1.4,r*.95)),color)
			for i in range(4): ci.draw_line(c+Vector2(-r*.7+i*r*.35,-r*.45),c+Vector2(-r*.7+i*r*.35,r*.05),INK,maxf(1.0,w*.4))
			ci.draw_rect(Rect2(c+Vector2(-r*.45,r*.5),Vector2(r*.9,r*.4)),color)
		"wing":
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-r*.9,r*.5),c+Vector2(-r*.2,-r*.9),c+Vector2(r*.9,-r*.6),c+Vector2(r*.3,-r*.1),c+Vector2(r*.7,r*.1),c+Vector2(0,r*.4)]),color)
		"grow":
			ci.draw_circle(c,r*.35,color);ci.draw_arc(c,r*.85,0,TAU,32,color,w*.6)
			for d in [Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]: arrow(ci,c+d.normalized()*r*.55,r*.32,d.normalized(),color)
		"bullet":
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-r*.8,-r*.32),c+Vector2(r*.4,-r*.32),c+Vector2(r*.9,0),c+Vector2(r*.4,r*.32),c+Vector2(-r*.8,r*.32)]),color)
			ci.draw_line(c+Vector2(-r,-r*.65),c+Vector2(-r*.45,-r*.65),color,w*.5);ci.draw_line(c+Vector2(-r,r*.65),c+Vector2(-r*.45,r*.65),color,w*.5)
		"target":
			ci.draw_arc(c,r*.85,0,TAU,32,color,w*.7);ci.draw_arc(c,r*.45,0,TAU,24,color,w*.7);ci.draw_circle(c,r*.15,color)
		"triple":
			for dy in [-.55,0.0,.55]: arrow(ci,c+Vector2(0,dy*r),r*.75,Vector2.RIGHT,color)
		"pierce":
			ci.draw_rect(Rect2(c+Vector2(-r*.12,-r*.85),Vector2(r*.24,r*1.7)),color.darkened(.35));arrow(ci,c,r*.95,Vector2.RIGHT,color)
		"bounce":
			ci.draw_polyline(PackedVector2Array([c+Vector2(-r*.9,-r*.6),c+Vector2(-r*.3,r*.6),c+Vector2(r*.3,-r*.2)]),color,w);arrow(ci,c+Vector2(r*.5,-r*.45),r*.45,Vector2(1,-.7).normalized(),color)
		"push":
			ci.draw_circle(c+Vector2(-r*.55,0),r*.35,color)
			for dy in [-.45,0.0,.45]: ci.draw_line(c+Vector2(-r*.05,dy*r),c+Vector2(r*.85,dy*r),color,w*.6)
		"pull":
			ci.draw_circle(c,r*.3,color)
			for d in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]: arrow(ci,c+d*r*.85,r*.4,-d,color)
		"flame":
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(0,-r),c+Vector2(r*.65,r*.05),c+Vector2(r*.45,r*.8),c+Vector2(-r*.45,r*.8),c+Vector2(-r*.65,r*.05)]),color)
			ci.draw_circle(c+Vector2(0,r*.42),r*.3,INK)
		"drop":
			ci.draw_circle(c+Vector2(0,r*.25),r*.6,color);ci.draw_colored_polygon(PackedVector2Array([c+Vector2(0,-r),c+Vector2(r*.53,r*.05),c+Vector2(-r*.53,r*.05)]),color)
		"snow":
			for i in range(3):
				var d=Vector2.from_angle(i*PI/3)*r;ci.draw_line(c-d,c+d,color,w)
		"slow":
			for dy in [-.45,.15]: ci.draw_polyline(PackedVector2Array([c+Vector2(-r*.7,dy*r),c+Vector2(0,dy*r+r*.45),c+Vector2(r*.7,dy*r)]),color,w)
		"bolt":
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(r*.2,-r),c+Vector2(-r*.55,r*.1),c+Vector2(-r*.05,r*.1),c+Vector2(-r*.25,r),c+Vector2(r*.55,-r*.15),c+Vector2(r*.05,-r*.15)]),color)
		"eye":
			ci.draw_arc(c,r*.75,PI*1.15,PI*1.85,16,color,w);ci.draw_arc(c,r*.75,PI*.15,PI*.85,16,color,w);ci.draw_circle(c,r*.25,color)
			ci.draw_line(c+Vector2(-r*.85,r*.75),c+Vector2(r*.85,-r*.75),color,w)
		"ghost":
			ci.draw_circle(c+Vector2(0,-r*.2),r*.6,color);ci.draw_rect(Rect2(c+Vector2(-r*.6,-r*.2),Vector2(r*1.2,r*.95)),color)
			ci.draw_circle(c+Vector2(-r*.22,-r*.3),r*.13,INK);ci.draw_circle(c+Vector2(r*.22,-r*.3),r*.13,INK)
		"spade":
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(0,r),c+Vector2(-r*.55,r*.15),c+Vector2(-r*.35,-r*.15),c+Vector2(r*.35,-r*.15),c+Vector2(r*.55,r*.15)]),color)
			ci.draw_line(c+Vector2(0,-r*.15),c+Vector2(0,-r),color,w)
		"spiral":
			var points=PackedVector2Array()
			for i in range(40): points.append(c+Vector2.from_angle(i*.35)*r*(.1+i*.022))
			ci.draw_polyline(points,color,w*.7)
		"shield":
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-r*.8,-r*.75),c+Vector2(r*.8,-r*.75),c+Vector2(r*.7,r*.15),c+Vector2(0,r),c+Vector2(-r*.7,r*.15)]),color)
		"swirl":
			ci.draw_arc(c,r*.85,-PI*.2,PI*1.1,24,color,w);ci.draw_arc(c,r*.45,PI*.8,PI*2.1,20,color,w)
		"bubble":
			ci.draw_arc(c,r*.85,0,TAU,32,color,w);ci.draw_arc(c,r*.55,PI*1.1,PI*1.5,12,color,w*.7)
		"unshield":
			ci.draw_arc(c,r*.85,0,TAU,32,color,w);ci.draw_line(c+Vector2(-r*.85,r*.85),c+Vector2(r*.85,-r*.85),color,w)
		"feather":
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(r*.7,-r*.9),c+Vector2(r*.3,r*.2),c+Vector2(-r*.5,r*.6),c+Vector2(-r*.1,-r*.3)]),color)
			ci.draw_line(c+Vector2(r*.7,-r*.9),c+Vector2(-r*.8,r*.9),INK,maxf(1.0,w*.4))
		"thorn":
			for a in [0.0,TAU/3,TAU*2/3]: ci.draw_colored_polygon(PackedVector2Array([c+Vector2.from_angle(a)*r,c+Vector2.from_angle(a+.5)*r*.3,c+Vector2.from_angle(a-.5)*r*.3]),color)
			ci.draw_circle(c,r*.3,color)
		"heart": heart(ci,c,r,color)
		"heal": heart(ci,c+Vector2(-r*.15,r*.1),r*.8,color);plus(ci,c+Vector2(r*.6,-r*.6),r*.32,Color("9cffb6"))
		"fang":
			# Two fangs over a drop of blood.
			for s in [-1,1]: ci.draw_colored_polygon(PackedVector2Array([c+Vector2(s*r*.75,-r*.85),c+Vector2(s*r*.15,-r*.85),c+Vector2(s*r*.45,r*.05)]),color)
			ci.draw_circle(c+Vector2(0,r*.55),r*.3,Color("ff5a72"));ci.draw_colored_polygon(PackedVector2Array([c+Vector2(0,r*.05),c+Vector2(r*.27,r*.45),c+Vector2(-r*.27,r*.45)]),Color("ff5a72"))
		"ankh":
			ci.draw_arc(c+Vector2(0,-r*.45),r*.35,0,TAU,20,color,w);ci.draw_line(c+Vector2(0,-r*.1),c+Vector2(0,r),color,w);ci.draw_line(c+Vector2(-r*.55,r*.15),c+Vector2(r*.55,r*.15),color,w)
		"wind":
			# A boot with speed lines behind it.
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-r*.15,-r*.9),c+Vector2(r*.35,-r*.9),c+Vector2(r*.35,r*.2),c+Vector2(r*.95,r*.45),c+Vector2(r*.95,r*.85),c+Vector2(-r*.15,r*.85)]),color)
			for i in range(3): ci.draw_line(c+Vector2(-r*.95,(i-1)*r*.42+r*.1),c+Vector2(-r*.4,(i-1)*r*.42+r*.1),color,w*.6)
		"dash":
			arrow(ci,c+Vector2(r*.15,0),r,Vector2.RIGHT,color);ci.draw_line(c+Vector2(-r,-r*.5),c+Vector2(-r*.35,-r*.5),color,w*.6);ci.draw_line(c+Vector2(-r,r*.5),c+Vector2(-r*.35,r*.5),color,w*.6)
		"jump": arrow(ci,c,r,Vector2.UP,color)
		"slam": arrow(ci,c+Vector2(0,-r*.2),r*.85,Vector2.DOWN,color);ci.draw_line(c+Vector2(-r,r*.95),c+Vector2(r,r*.95),color,w)
		"coin": coin(ci,c,r)
		"tag":
			ci.draw_colored_polygon(PackedVector2Array([c+Vector2(-r*.9,-r*.2),c+Vector2(-r*.2,-r*.9),c+Vector2(r*.9,-r*.9),c+Vector2(r*.9,r*.2),c+Vector2(-r*.2,r*.9)]),color)
			ci.draw_circle(c+Vector2(r*.5,-r*.5),r*.15,INK)
		"key":
			ci.draw_arc(c+Vector2(-r*.45,0),r*.38,0,TAU,20,color,w);ci.draw_line(c+Vector2(-r*.07,0),c+Vector2(r*.9,0),color,w)
			ci.draw_line(c+Vector2(r*.55,0),c+Vector2(r*.55,r*.35),color,w);ci.draw_line(c+Vector2(r*.85,0),c+Vector2(r*.85,r*.35),color,w)
		"magnet":
			ci.draw_arc(c+Vector2(0,-r*.1),r*.6,PI,TAU,20,color,w*1.4)
			for s in [-1,1]: ci.draw_line(c+Vector2(s*r*.6,-r*.1),c+Vector2(s*r*.6,r*.7),color,w*1.4);ci.draw_line(c+Vector2(s*r*.6,r*.45),c+Vector2(s*r*.6,r*.75),Color("ff6a5a"),w*1.4)
		"chest":
			ci.draw_rect(Rect2(c+Vector2(-r*.85,-r*.2),Vector2(r*1.7,r*.95)),color);ci.draw_rect(Rect2(c+Vector2(-r*.85,-r*.65),Vector2(r*1.7,r*.4)),color.lightened(.2))
			ci.draw_rect(Rect2(c+Vector2(-r*.12,-r*.3),Vector2(r*.24,r*.3)),INK)
		"clover":
			for d in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]: ci.draw_circle(c+d*r*.42,r*.4,color)
			ci.draw_line(c,c+Vector2(r*.5,r),color,w*.6)
		"banana":
			ci.draw_arc(c+Vector2(0,-r*.4),r*.95,PI*.2,PI*.8,16,color,w*1.6)
		"xp":
			var font=ThemeDB.fallback_font;ci.draw_string(font,c+Vector2(-r*1.05,r*.42),"XP",HORIZONTAL_ALIGNMENT_CENTER,r*2.1,int(r*1.25),color)
		"potion":
			ci.draw_circle(c+Vector2(0,r*.3),r*.62,color);ci.draw_rect(Rect2(c+Vector2(-r*.2,-r*.85),Vector2(r*.4,r*.6)),color)
			ci.draw_rect(Rect2(c+Vector2(-r*.28,-r*.98),Vector2(r*.56,r*.2)),Color("b78a52"))
		"ring":
			ci.draw_arc(c,r*.85,0,TAU,32,color,w);ci.draw_circle(c,r*.25,color)
			for i in range(4): ci.draw_circle(c+Vector2.from_angle(i*TAU/4+PI/4)*r*.85,r*.14,color)
		"turret":
			ci.draw_rect(Rect2(c+Vector2(-r*.6,r*.2),Vector2(r*1.2,r*.7)),color);ci.draw_circle(c+Vector2(0,r*.05),r*.42,color)
			ci.draw_line(c+Vector2(0,r*.05),c+Vector2(r*.95,-r*.55),color,w*1.2)
		"wrench":
			ci.draw_line(c+Vector2(-r*.7,r*.7),c+Vector2(r*.3,-r*.3),color,w*1.4);ci.draw_arc(c+Vector2(r*.45,-r*.45),r*.38,-PI*.25,PI*1.25,16,color,w*1.2)
		"flower":
			for i in range(5): ci.draw_circle(c+Vector2.from_angle(i*TAU/5-PI/2)*r*.5,r*.32,color)
			ci.draw_circle(c,r*.28,Color("ffd36b"))
		"ground": ci.draw_rect(Rect2(c+Vector2(-r,r*.25),Vector2(r*2,r*.45)),color);arrow(ci,c+Vector2(0,-r*.3),r*.55,Vector2.DOWN,color)
		"pause": ci.draw_rect(Rect2(c+Vector2(-r*.55,-r*.7),Vector2(r*.35,r*1.4)),color);ci.draw_rect(Rect2(c+Vector2(r*.2,-r*.7),Vector2(r*.35,r*1.4)),color)
		"crack": heart(ci,c,r,color);ci.draw_polyline(PackedVector2Array([c+Vector2(0,-r*.55),c+Vector2(-r*.15,-r*.1),c+Vector2(r*.15,r*.2),c+Vector2(0,r*.6)]),INK,maxf(1.0,w*.5))
		"one": ci.draw_circle(c,r*.45,color)
		"three":
			for d in [Vector2(-.55,.35),Vector2(.55,.35),Vector2(0,-.5)]: ci.draw_circle(c+d*r,r*.33,color)
		"moon": ci.draw_circle(c,r*.85,color);ci.draw_circle(c+Vector2(r*.4,-r*.25),r*.7,INK)
		"gate":
			ci.draw_arc(c+Vector2(0,r*.1),r*.7,PI,TAU,16,color,w*1.2)
			for s in [-1,1]: ci.draw_line(c+Vector2(s*r*.7,r*.1),c+Vector2(s*r*.7,r*.9),color,w*1.2)

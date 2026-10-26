extends RefCounted
class_name CartoonWeapons

# The 29 base weapon models rebuilt in the cartoon style (user request, October 25):
# chunky sci-fi gadgets with glowing cores, rings and dials, in each weapon's own
# colour (PowerIcon). Held weapons point along -Z from the grip; turrets stand on
# a tripod and look out with one goofy eye. The weapon icons are rendered from
# these models (render_weapon_icons.gd). Every other weapon builds on one of these.

const INK=CartoonMesh.INK
const ASSETS=["mint_pistol","weapon_shotgun","weapon_flame","weapon_poison","weapon_ice","weapon_rail","weapon_lightning","weapon_saw","weapon_rocket","weapon_ghost","weapon_flowers","weapon_turret","weapon_fire-turret","weapon_ice-turret","weapon_poison-turret","weapon_lightning-turret","weapon_rocket-turret","weapon_boomerang","weapon_disc","weapon_harpoon","weapon_gravity","weapon_horn","weapon_bubble","weapon_meteor","weapon_bomb","weapon_ninja-shuriken","weapon_smoke-censer","weapon_bottle-barrage","weapon_supra-backfire","spell_tornado","spell_blackhole","spell_thunderstorm","spell_inferno"]

static func c(hex: String) -> Color: return Color(hex)

static func has(asset: String) -> bool: return asset in ASSETS

# Grip, a rounded body with a dial and a glowing core, and a barrel ending at z.
static func gadget(m: CartoonMesh,body: Color,glow: Color,barrel_end: float=-.55,barrel_radius: float=.06,trim: Color=Color("ffd23f")):
	m.rod(Vector3(0,-.02,.08),Vector3(0,-.2,.14),.05,c("3a3040"))
	m.ball(Vector3(0,.08,-.08),Vector3(.2,.18,.36),body)
	m.ball(Vector3(0,.19,-.02),Vector3.ONE*.11,glow,CartoonMesh.BODY,0.0,Vector2(0,1),true)
	m.ring(Vector3(0,.19,-.02),.07,.03,trim)
	m.can(Vector3(0,.08,-.2),Vector3(0,.08,barrel_end),barrel_radius,body.darkened(.25))
	m.ring(Vector3(0,.08,barrel_end+.04),barrel_radius*1.35,.04,trim,Vector3(PI*.5,0,0))
	m.ball(Vector3(.11,.08,-.06),Vector3(.04,.07,.07),c("ff3b3b"))

static func scene(asset: String) -> Node3D:
	var s=CartoonScene.new();var m=s.paint(s.body,"WeaponPaint")
	var id="gun" if asset=="mint_pistol" else asset.trim_prefix("weapon_").trim_prefix("spell_")
	var hue: Color=PowerIcon.color_for(id.trim_suffix("-turret") if id.ends_with("-turret") else id)
	var muzzle=Vector3(0,.08,-.59)
	if asset.begins_with("spell_"):
		# The spells (SkillBook) are wand-gadgets: a grip, a shaft and a goofy little
		# character at the tip, where the spell comes out.
		var tip=Vector3(0,.42,-.2)
		m.rod(Vector3(0,.08,-.02),Vector3(0,.3,-.15),.04,c("6b4a8a"));m.ring(Vector3(0,.3,-.15),.07,.04,c("ffd23f"),Vector3(.45,0,0))
		m.ball(Vector3(0,.06,-.01),Vector3.ONE*.09,c("ffd23f"))
		match id:
			"tornado":
				for i in range(5): m.ring(tip+Vector3(sin(i*1.3)*.02,i*.06-.08,0),.04+i*.035,.035,c("dffbff") if i%2==0 else c("9fe9ff"))
				m.ball(tip+Vector3(0,-.02,0),Vector3.ONE*.08,c("7dfffb"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.eye(tip+Vector3(-.06,.18,-.15),.04);m.eye(tip+Vector3(.06,.17,-.15),.035,Vector3(.4,0,-1))
			"blackhole":
				m.ball(tip,Vector3.ONE*.24,c("17121f"));m.ring(tip,.2,.04,c("c97aff"),Vector3(.5,0,.3))
				m.spots(tip,Vector3.ONE*.2,c("ff6bd5"),5,.04,61,true,false)
				for k in range(3): var a=k*TAU/3;m.spike(Vector3(0,.3,-.15)+Vector3(cos(a),0,sin(a))*.05,tip+Vector3(cos(a),-.3,sin(a))*.14,.02,c("c0c0c8"))
			"thunderstorm":
				for q in [Vector3(-.09,0,0),Vector3(.09,.01,0),Vector3(0,.07,0),Vector3(0,-.02,.05)]: m.ball(tip+q,Vector3(.17,.14,.15),c("8d97a8"))
				m.eye(tip+Vector3(-.05,.02,-.1),.03);m.eye(tip+Vector3(.05,.02,-.1),.03)
				for side in [-1.0,1.0]: m.box(tip+Vector3(side*.05,.06,-.11),Vector3(.06,.012,.012),CartoonMesh.INK,CartoonMesh.BODY,Vector3(0,0,side*.5))
				m.spike(tip+Vector3(.02,-.08,-.02),tip+Vector3(-.04,-.24,-.04),.035,c("ffe36a"),CartoonMesh.BODY,0.0,Vector2(0,1))
			"inferno":
				m.ball(tip,Vector3.ONE*.2,c("ffb347"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				for i in range(6):
					var o=Vector3(cos(i*TAU/6),sin(i*TAU/6),0);m.spike(tip+o*.09,tip+o*.2,.045,c("ff6a1c"))
				m.eye(tip+Vector3(-.04,.03,-.09),.025);m.eye(tip+Vector3(.04,.03,-.09),.025)
				m.grin(tip+Vector3(0,-.04,-.08),.08,.03,3,false)
		muzzle=tip
	elif id.ends_with("-turret") or id=="turret":
		# A tripod sentry with one eye; its gun sits on top.
		for i in range(3):
			var a=i*TAU/3+PI*.5;m.rod(Vector3(0,-.05,0),Vector3(cos(a)*.3,-.42,sin(a)*.3),.03,c("3a3040"))
		m.ball(Vector3(0,.0,0),Vector3(.34,.3,.34),hue)
		m.eye(Vector3(0,.04,-.15),.09,Vector3.FORWARD,c("ff3b3b"))
		var kind=id.trim_suffix("-turret") if id!="turret" else "gun"
		m.can(Vector3(0,.16,-.05),Vector3(0,.16,-.5),.06,hue.darkened(.3));m.ring(Vector3(0,.16,-.46),.08,.04,c("ffd23f"),Vector3(PI*.5,0,0))
		match kind:
			"fire": m.ball(Vector3(0,.3,.1),Vector3.ONE*.18,c("ff8a2b"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			"ice": for k in range(3): m.spike(Vector3((k-1)*.05,.16,-.5),Vector3((k-1)*.1,.18,-.65),.04,c("bff6ff"))
			"poison": m.ball(Vector3(0,.3,.1),Vector3(.14,.2,.14),c("8fff5a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			"lightning": m.antenna(Vector3(0,.15,.08),Vector3(0,.42,.1),.05,c("c0c0c8"),c("c97aff"))
			"rocket": m.spike(Vector3(0,.16,-.5),Vector3(0,.16,-.68),.07,c("ff3b3b"))
		muzzle=Vector3(0,.16,-.56)
	else:
		match id:
			"gun":
				gadget(m,c("5affd0"),c("7dff6a"),-.5,.055);m.ball(Vector3(0,.08,-.53),Vector3.ONE*.09,c("7dff6a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			"shotgun":
				m.rod(Vector3(0,.0,.1),Vector3(0,-.12,.3),.06,c("a86a3a"));m.ball(Vector3(0,.07,-.05),Vector3(.24,.16,.32),hue)
				for x in [-.045,.045]: m.can(Vector3(x,.09,-.15),Vector3(x,.09,-.5),.045,hue.darkened(.3))
				m.spike(Vector3(0,.09,-.62),Vector3(0,.09,-.48),.11,c("ffd23f"))
			"flame":
				gadget(m,hue,c("ff8a2b"),-.48,.06);m.ball(Vector3(0,.28,.05),Vector3(.18,.24,.18),c("ff6a2a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.spike(Vector3(0,.08,-.62),Vector3(0,.08,-.48),.1,c("3a3040"))
			"poison":
				gadget(m,hue,c("8fff5a"),-.5,.04);m.ball(Vector3(0,.3,.0),Vector3(.18,.22,.18),c("8fff5a"),CartoonMesh.BODY,0.0,Vector2(0,1),true);m.can(Vector3(0,.4,0),Vector3(0,.46,0),.05,c("a86a3a"))
				m.spike(Vector3(0,.08,-.5),Vector3(0,.08,-.68),.02,c("dff6ff"))
			"ice":
				gadget(m,hue,c("bff6ff"),-.45,.06)
				for k in range(3): m.spike(Vector3((k-1)*.05,.08,-.45),Vector3((k-1)*.12,.1+k*.02,-.66),.05,c("bff6ff"))
			"rail":
				gadget(m,hue,c("7dfffb"),-.7,.045)
				for k in range(3): m.ring(Vector3(0,.08,-.3-k*.13),.09,.05,c("7dfffb"),Vector3(PI*.5,0,0))
				muzzle=Vector3(0,.08,-.74)
			"lightning":
				gadget(m,hue,c("c97aff"),-.4,.05);m.ball(Vector3(0,.08,-.48),Vector3.ONE*.14,c("e8c8ff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				for k in range(3): m.spike(Vector3(0,.12,-.48),Vector3(cos(k*2.1)*.12,.16+sin(k*2.1)*.1,-.55),.02,c("fff27d"))
			"saw":
				m.rod(Vector3(0,-.02,.1),Vector3(0,-.2,.16),.05,c("3a3040"));m.ball(Vector3(0,.07,0),Vector3(.18,.16,.26),hue)
				var disc=s.paint(s.body,"Disc")
				disc.can(Vector3(-.02,.07,-.27),Vector3(.02,.07,-.27),.2,c("d8e0ee"));disc.ball(Vector3(0,.07,-.27),Vector3(.08,.08,.08),c("ff3b3b"))
				for k in range(10):
					var a=k*TAU/10;var o=Vector3(0,cos(a),sin(a))
					disc.spike(Vector3(0,.07,-.27)+o*.18,Vector3(0,.07,-.27)+o*.25+Vector3(0,sin(a),-cos(a))*.03,.03,c("ffffff"))
			"rocket":
				m.can(Vector3(0,.12,.25),Vector3(0,.12,-.45),.1,hue);m.ring(Vector3(0,.12,-.42),.12,.05,c("ffd23f"),Vector3(PI*.5,0,0))
				m.spike(Vector3(0,.12,-.45),Vector3(0,.12,-.62),.08,c("ff3b3b"));m.rod(Vector3(0,.02,0),Vector3(0,-.16,.05),.05,c("3a3040"))
				m.eye(Vector3(.1,.22,-.1),.05)
				muzzle=Vector3(0,.12,-.64)
			"ghost":
				gadget(m,hue,c("bfffee"),-.4,.07);m.ball(Vector3(0,.32,.0),Vector3(.24,.28,.22),c("dffff4"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.eye(Vector3(-.04,.34,-.1),.03);m.eye(Vector3(.05,.34,-.1),.035)
			"flowers":
				m.ball(Vector3(0,.1,0),Vector3(.3,.24,.3),c("ff7ad9"));m.rod(Vector3(0,.1,-.12),Vector3(0,.2,-.45),.035,c("ff7ad9"));m.ring(Vector3(0,.25,.12),.08,.03,c("ff7ad9"),Vector3(0,PI*.5,PI*.5))
				for k in range(5): var a=k*TAU/5;m.ball(Vector3(cos(a)*.06,.32+sin(a)*.06,-.02),Vector3.ONE*.07,c("ffd23f"))
				muzzle=Vector3(0,.2,-.48)
			"boomerang":
				m.rod(Vector3(0,.08,0),Vector3(.22,.08,-.3),.05,hue);m.rod(Vector3(0,.08,0),Vector3(-.22,.08,-.3),.05,hue);m.ball(Vector3(0,.08,0),Vector3.ONE*.12,c("ff3b3b"))
				muzzle=Vector3(0,.08,-.32)
			"disc":
				gadget(m,hue,c("7dfffb"),-.3,.06);m.ball(Vector3(0,.12,-.42),Vector3(.32,.05,.32),c("ff6bd5"));m.ring(Vector3(0,.12,-.42),.16,.03,c("ffffff"))
				muzzle=Vector3(0,.12,-.58)
			"harpoon":
				gadget(m,hue,c("7dfffb"),-.5,.04);m.spike(Vector3(0,.08,-.5),Vector3(0,.08,-.72),.06,c("d8e0ee"))
				for x in [-.04,.04]: m.spike(Vector3(x,.08,-.56),Vector3(x*2.5,.08,-.5),.02,c("d8e0ee"))
				m.ring(Vector3(0,.0,.04),.07,.04,c("c9a06a"),Vector3(0,0,PI*.5))
				muzzle=Vector3(0,.08,-.74)
			"gravity":
				gadget(m,hue,c("c97aff"),-.25,.06)
				m.ball(Vector3(0,.08,-.42),Vector3.ONE*.18,c("6b2bff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				for k in range(3): var a=k*TAU/3;m.spike(Vector3(cos(a)*.06,.08+sin(a)*.06,-.26),Vector3(cos(a)*.14,.08+sin(a)*.14,-.42),.025,c("c0c0c8"))
				muzzle=Vector3(0,.08,-.52)
			"horn":
				m.rod(Vector3(0,-.02,.1),Vector3(0,-.18,.14),.045,c("3a3040"));m.can(Vector3(0,.08,.05),Vector3(0,.08,-.3),.05,c("ffd23f"))
				m.spike(Vector3(0,.08,-.6),Vector3(0,.08,-.28),.17,c("ffd23f"));m.ring(Vector3(0,.08,-.58),.17,.04,c("e0a82a"),Vector3(PI*.5,0,0))
				muzzle=Vector3(0,.08,-.62)
			"bubble":
				m.rod(Vector3(0,-.15,.08),Vector3(0,.15,-.2),.03,c("ff7ad9"));m.ring(Vector3(0,.25,-.3),.12,.04,c("ff7ad9"),Vector3(PI*.5,0,0))
				m.ball(Vector3(0,.25,-.42),Vector3.ONE*.18,c("bff6ff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				muzzle=Vector3(0,.25,-.5)
			"meteor":
				gadget(m,hue,c("ff8a2b"),-.3,.07);m.ball(Vector3(0,.1,-.45),Vector3.ONE*.24,c("8a6a5a"));m.spots(Vector3(0,.1,-.45),Vector3.ONE*.12,c("ff8a2b"),5,.06,77,true,false)
				muzzle=Vector3(0,.1,-.6)
			"bomb":
				m.ball(Vector3(0,.12,-.15),Vector3.ONE*.32,c("2a2340"));m.can(Vector3(0,.27,-.15),Vector3(0,.33,-.15),.05,c("8a94b0"))
				m.rod(Vector3(0,.33,-.15),Vector3(.05,.42,-.2),.012,c("c9a06a"));m.ball(Vector3(.06,.44,-.21),Vector3.ONE*.06,c("ffd23f"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.eye(Vector3(-.05,.16,-.3),.04);m.eye(Vector3(.06,.15,-.3),.035);m.rod(Vector3(0,-.04,-.1),Vector3(0,-.18,0),.04,c("3a3040"))
				muzzle=Vector3(0,.12,-.33)
			"ninja-shuriken":
				for k in range(4):
					var a=k*PI*.5;var o=Vector3(cos(a),sin(a),0)
					m.spike(Vector3(0,.1,-.2)+o*.04,Vector3(0,.1,-.2)+o*.24,.07,c("d8e0ee"))
				m.ball(Vector3(0,.1,-.2),Vector3(.1,.1,.04),c("ff3b3b"));m.rod(Vector3(0,-.02,0),Vector3(0,-.18,.05),.04,c("2a2340"))
				muzzle=Vector3(0,.1,-.3)
			"smoke-censer":
				m.rod(Vector3(0,-.15,.05),Vector3(0,.15,-.15),.025,c("c9a06a"));m.ball(Vector3(0,.05,-.35),Vector3(.2,.24,.2),c("c9a06a"))
				for k in range(3): m.ball(Vector3(.03*k,.22+k*.08,-.35),Vector3.ONE*(.1+k*.03),c("e8e8f0"),CartoonMesh.STALK,.2*k,Vector2(.15,1))
				muzzle=Vector3(0,.12,-.45)
			"bottle-barrage":
				m.can(Vector3(0,.0,-.05),Vector3(0,.0,-.35),.08,c("3aa86a"));m.can(Vector3(0,.0,-.35),Vector3(0,.0,-.5),.035,c("3aa86a"));m.can(Vector3(0,.0,-.5),Vector3(0,.0,-.56),.04,c("c9a06a"))
				m.box(Vector3(0,.0,-.2),Vector3(.17,.1,.12),c("fff3d2"))
				muzzle=Vector3(0,0,-.58)
			"supra-backfire":
				m.can(Vector3(0,.08,.1),Vector3(0,.08,-.45),.07,c("d8e0ee"));m.ring(Vector3(0,.08,-.44),.09,.04,c("8a94b0"),Vector3(PI*.5,0,0))
				m.spike(Vector3(0,.08,-.5),Vector3(0,.08,-.68),.07,c("ff8a2b"))
				m.rod(Vector3(0,-.02,.05),Vector3(0,-.18,.1),.045,c("3a3040"))
				muzzle=Vector3(0,.08,-.7)
	s.muzzle(muzzle)
	return s.finish()

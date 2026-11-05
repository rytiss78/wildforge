extends RefCounted
class_name CartoonWeapons

# The 29 base weapon models rebuilt in the cartoon style (user request, October 25):
# chunky sci-fi gadgets with glowing cores, rings and dials, in each weapon's own
# colour (PowerIcon). Held weapons point along -Z from the grip; turrets stand on
# a tripod and look out with one goofy eye. The weapon icons are rendered from
# these models (render_weapon_icons.gd). Every other weapon builds on one of these.

const INK=CartoonMesh.INK
const ASSETS=["mint_pistol","weapon_shotgun","weapon_flame","weapon_poison","weapon_ice","weapon_rail","weapon_lightning","weapon_saw","weapon_rocket","weapon_ghost","weapon_flowers","weapon_turret","weapon_fire-turret","weapon_pulse-turret","weapon_heal-turret","weapon_lightning-turret","weapon_rocket-turret","weapon_boomerang","weapon_disc","weapon_harpoon","weapon_gravity","weapon_horn","weapon_bubble","weapon_meteor","weapon_bomb","weapon_ninja-shuriken","weapon_smoke-censer","weapon_bottle-barrage","weapon_supra-backfire","spell_tornado","spell_blackhole","spell_thunderstorm","spell_inferno",
	"weapon_halo","weapon_orbit-lids","weapon_fire-trail","weapon_frost-trail","weapon_dice","weapon_blood-pump","weapon_whip","weapon_snip-knife","weapon_katana","weapon_scythe","weapon_hero-blade","weapon_grudge-blade"]

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
		if not kind in ["heal","pulse"]: m.can(Vector3(0,.16,-.05),Vector3(0,.16,-.5),.06,hue.darkened(.3));m.ring(Vector3(0,.16,-.46),.08,.04,c("ffd23f"),Vector3(PI*.5,0,0))
		match kind:
			"fire": m.ball(Vector3(0,.3,.1),Vector3.ONE*.18,c("ff8a2b"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			"ice": for k in range(3): m.spike(Vector3((k-1)*.05,.16,-.5),Vector3((k-1)*.1,.18,-.65),.04,c("bff6ff"))
			"poison": m.ball(Vector3(0,.3,.1),Vector3(.14,.2,.14),c("8fff5a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			"heal":
				# Mender: a big glowing green cross standing on its head, no barrel.
				var green=c("3dff9a")
				m.rod(Vector3(0,.12,0),Vector3(0,.32,0),.04,c("c0c0c8"));m.box(Vector3(0,.5,0),Vector3(.44,.14,.12),green);m.box(Vector3(0,.5,0),Vector3(.14,.44,.12),green)
				m.ball(Vector3(0,.5,0),Vector3(.12,.12,.14),c("e8fff2"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			"pulse":
				# Thumper: a big speaker cone facing up, with rings like sound waves.
				m.can(Vector3(0,.16,0),Vector3(0,.3,0),.24,c("3a3040"))
				m.ring(Vector3(0,.32,0),.24,.045,c("8fd0ff"));m.ring(Vector3(0,.33,0),.15,.035,c("dff6ff"))
				m.ball(Vector3(0,.33,0),Vector3(.12,.06,.12),c("8fd0ff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.ring(Vector3(0,.48,0),.3,.025,c("8fd0ff"));m.ring(Vector3(0,.6,0),.36,.02,c("bfe6ff"))
			"lightning": m.antenna(Vector3(0,.15,.08),Vector3(0,.42,.1),.05,c("c0c0c8"),c("c97aff"))
			"rocket": m.spike(Vector3(0,.16,-.5),Vector3(0,.16,-.68),.07,c("ff3b3b"))
		muzzle=Vector3(0,.16,-.56)
	else:
		match id:
			"gun":
				# Compact pistol: blocky grip, short barrel, top sight, trigger guard
				m.ball(Vector3(0,.05,-.05),Vector3(.16,.14,.28),c("5a6a70"))
				m.rod(Vector3(0,-.08,.05),Vector3(0,-.2,.02),.05,c("3a4550"))
				m.can(Vector3(0,.08,-.15),Vector3(0,.08,-.52),.045,c("4a5a60"))
				m.ring(Vector3(0,.08,-.55),.055,.02,c("ffd23f"),Vector3(PI*.5,0,0))
				m.ball(Vector3(0,.15,-.15),Vector3.ONE*.03,c("7dff6a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.rod(Vector3(.06,-.05,.08),Vector3(.06,-.05,.15),.015,c("3a4550"))
				m.ball(Vector3(0,.14,-.48),Vector3.ONE*.02,c("ff6a6a"))
			"shotgun":
				# Pump-action shotgun: stock, receiver, pump grip, long barrel
				m.can(Vector3(0,.08,.1),Vector3(0,.08,-.1),.055,c("6a4a2a"))
				m.ball(Vector3(0,.1,-.15),Vector3(.18,.16,.22),c("7a5a3a"))
				m.rod(Vector3(0,0,.05),Vector3(0,0,-.35),.035,c("5a3a1a"))
				m.ball(Vector3(0,0,-.35),Vector3.ONE*.06,c("4a2a1a"))
				m.can(Vector3(0,.12,-.2),Vector3(0,.12,-.62),.04,c("6a5a4a"))
				m.ring(Vector3(0,.12,-.65),.05,.025,c("ffd23f"),Vector3(PI*.5,0,0))
				m.rod(Vector3(0,.2,-.2),Vector3(0,.2,-.58),.02,c("5a5a5a"))
				m.ball(Vector3(0,.22,-.58),Vector3.ONE*.025,c("7dff6a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			"flame":
				# Flamethrower: fuel tank on back, wide nozzle, gas canister
				m.ball(Vector3(0,.25,.05),Vector3(.18,.24,.18),c("ff6a2a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.ball(Vector3(0,.1,-.05),Vector3(.2,.18,.3),c("7a4a2a"))
				m.rod(Vector3(0,-.05,.1),Vector3(0,-.18,.08),.05,c("3a4550"))
				m.can(Vector3(0,.08,-.15),Vector3(0,.08,-.48),.06,c("5a4a3a"))
				for x in [-.08,.08]: m.can(Vector3(x,.18,.02),Vector3(x,.28,.02),.04,c("6a3a1a"))
				m.ring(Vector3(0,.08,-.52),.07,.03,c("ffd23f"),Vector3(PI*.5,0,0))
				m.ball(Vector3(0,.08,-.56),Vector3(.1,.04,.1),c("ff8a2b"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			"poison":
				# Flask launcher: bottle-shaped body, narrow neck, glass vial on top
				m.ball(Vector3(0,.1,-.05),Vector3(.18,.2,.28),c("4a6a3a"))
				m.ball(Vector3(0,.3,.0),Vector3(.18,.22,.18),c("8fff5a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.can(Vector3(0,.08,-.15),Vector3(0,.08,-.5),.04,c("3a5a2a"))
				m.ring(Vector3(0,.08,-.53),.05,.02,c("a8e878"),Vector3(PI*.5,0,0))
				m.ball(Vector3(.08,.15,.05),Vector3(.05,.08,.05),c("9fe97a"))
				m.rod(Vector3(0,-.06,.08),Vector3(0,-.18,.06),.045,c("3a4550"))
				m.ball(Vector3(-.06,.22,.05),Vector3(.04,.06,.04),c("edf4b7"))
			"ice":
				# Ice gun: crystalline barrel, faceted frost head, cold glow
				m.ball(Vector3(0,.1,-.05),Vector3(.18,.18,.3),c("4a7a9a"))
				m.can(Vector3(0,.12,-.15),Vector3(0,.12,-.45),.06,c("3a5a7a"))
				for k in range(3):
					m.spike(Vector3((k-1)*.06,.12,-.45),Vector3((k-1)*.14,.16+sin(k)*.05,-.64),.04,c("bff6ff"))
				m.ring(Vector3(0,.12,-.48),.07,.03,c("dff6ff"),Vector3(PI*.5,0,0))
				m.ball(Vector3(0,.2,-.02),Vector3(.08,.08,.06),c("dff6ff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.rod(Vector3(0,-.06,.06),Vector3(0,-.18,.04),.05,c("3a4550"))
				m.ball(Vector3(0,.12,-.52),Vector3(.06,.03,.06),c("c8f6ff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			"rail":
				# Railgun: twin parallel rails, large body, scope, energy glow between rails
				m.ball(Vector3(0,.1,-.05),Vector3(.2,.16,.32),c("4a5a6a"))
				m.box(Vector3(-.1,.12,-.25),Vector3(.04,.06,.5),c("a5dcea"))
				m.box(Vector3(.1,.12,-.25),Vector3(.04,.06,.5),c("a5dcea"))
				m.ball(Vector3(0,.08,-.3),Vector3(.15,.08,.1),c("3a4550"))
				m.can(Vector3(0,.24,-.1),Vector3(0,.24,-.25),.05,c("3a4550"))
				m.ball(Vector3(0,.24,-.28),Vector3(.06,.06,.04),c("3a4550"))
				m.ball(Vector3(0,.12,-.35),Vector3(.08,.04,.2),c("7dfffb"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.rod(Vector3(0,-.05,.1),Vector3(0,-.18,.08),.05,c("3a4550"))
				m.ball(Vector3(0,.1,.15),Vector3(.12,.1,.06),c("4a5a6a"))
				muzzle=Vector3(0,.12,-.74)
			"lightning":
				# Lightning gun: two prongs, antenna tip, coiled conductors
				m.ball(Vector3(0,.1,-.05),Vector3(.18,.18,.3),c("5a5a7a"))
				m.rod(Vector3(0,-.06,.06),Vector3(0,-.18,.04),.05,c("3a4550"))
				for side in [-1,1]:
					m.rod(Vector3(side*.13,.2,-.05),Vector3(side*.13,.38,-.05),.035,c("c97aff"))
					m.ball(Vector3(side*.13,.45,-.05),Vector3(.12,.12,.12),c("a4eaff"))
				for z in [-.2,-.3,-.4]: m.ring(Vector3(0,.08,z),.08,.03,c("b5d5f2"),Vector3(PI*.5,0,0))
				m.ball(Vector3(0,.08,-.48),Vector3(.14,.14,.14),c("c97aff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
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
				# Ghost: translucent floating orb with eyes, wispy tail
				m.ball(Vector3(0,.2,-.02),Vector3(.28,.32,.28),c("dffff4"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.ball(Vector3(0,.08,-.05),Vector3(.2,.18,.28),c("bfffee"))
				m.eye(Vector3(-.06,.24,-.12),.035);m.eye(Vector3(.06,.24,-.12),.04)
				m.ball(Vector3(0,.38,0),Vector3(.06,.06,.06),c("b48cf2"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.rod(Vector3(0,-.05,.08),Vector3(0,-.18,.06),.05,c("3a4550"))
				for k in range(3): m.ball(Vector3(0,.08+k*.02,-.4-k*.04),Vector3(.03,.03,.03),c("c49bff"),CartoonMesh.STALK,.1*k,Vector2(.15,1))
			"flowers":
				m.ball(Vector3(0,.1,0),Vector3(.3,.24,.3),c("ff7ad9"));m.rod(Vector3(0,.1,-.12),Vector3(0,.2,-.45),.035,c("ff7ad9"));m.ring(Vector3(0,.25,.12),.08,.03,c("ff7ad9"),Vector3(0,PI*.5,PI*.5))
				for k in range(5): var a=k*TAU/5;m.ball(Vector3(cos(a)*.06,.32+sin(a)*.06,-.02),Vector3.ONE*.07,c("ffd23f"))
				muzzle=Vector3(0,.2,-.48)
			"boomerang":
				m.rod(Vector3(0,.08,0),Vector3(.22,.08,-.3),.05,hue);m.rod(Vector3(0,.08,0),Vector3(-.22,.08,-.3),.05,hue);m.ball(Vector3(0,.08,0),Vector3.ONE*.12,c("ff3b3b"))
				muzzle=Vector3(0,.08,-.32)
			"disc":
				# Disc thrower: launcher with flat disc chamber, spring-loaded
				m.ball(Vector3(0,.1,-.05),Vector3(.16,.16,.26),c("5a5a7a"))
				m.can(Vector3(0,.12,-.15),Vector3(0,.12,-.3),.06,c("4a4a6a"))
				m.ball(Vector3(0,.12,-.42),Vector3(.32,.05,.32),c("ff6bd5"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.ring(Vector3(0,.12,-.42),.16,.03,c("ffffff"))
				m.rod(Vector3(0,-.05,.08),Vector3(0,-.18,.06),.05,c("3a4550"))
				m.ball(Vector3(0,.2,-.02),Vector3(.08,.06,.06),c("b48cf2"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				muzzle=Vector3(0,.12,-.58)
			"harpoon":
				# Harpoon gun: heavy industrial launcher, visible spike, side handle
				m.ball(Vector3(0,.1,-.08),Vector3(.2,.18,.28),c("5a5a6a"))
				m.can(Vector3(0,.12,-.2),Vector3(0,.12,-.55),.055,c("4a4a5a"))
				m.spike(Vector3(0,.12,-.55),Vector3(0,.12,-.85),.04,c("c0c8d0"))
				m.ball(Vector3(0,.12,-.88),Vector3(.06,.06,.06),c("d0d8e0"))
				for side in [-1,1]: m.ball(Vector3(side*.05,.1,-.82),Vector3(.04,.03,.04),c("c0c8d0"))
				m.rod(Vector3(0,-.05,.05),Vector3(0,-.18,.03),.055,c("4a4a5a"))
				m.ring(Vector3(0,.12,-.35),.07,.025,c("7dfffb"),Vector3(PI*.5,0,0))
				m.rod(Vector3(.12,0,-.15),Vector3(.15,0,-.3),.02,c("5a5a6a"))
				muzzle=Vector3(0,.12,-.88)
			"gravity":
				# Gravity well: spherical core with orbiting rings, distortion waves
				m.ball(Vector3(0,.1,-.05),Vector3(.2,.18,.3),c("4a4a6a"))
				m.ball(Vector3(0,.08,-.42),Vector3(.18,.18,.18),c("6b2bff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				for k in range(3):
					var a=k*TAU/3;m.spike(Vector3(cos(a)*.06,.08+sin(a)*.06,-.26),Vector3(cos(a)*.14,.08+sin(a)*.14,-.42),.025,c("c0c0c8"))
				m.rod(Vector3(0,-.05,.08),Vector3(0,-.18,.06),.05,c("3a4550"))
				m.ring(Vector3(0,.08,-.15),.15,.03,c("b48cf2"),Vector3(0,0,PI*.3))
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
				# Meteor caller: heavy launcher with crater plates, glowing core
				m.ball(Vector3(0,.1,-.05),Vector3(.2,.2,.32),c("6a5a4a"))
				m.ball(Vector3(0,.1,-.45),Vector3(.24,.24,.24),c("8a6a5a"))
				m.spots(Vector3(0,.1,-.45),Vector3.ONE*.12,c("ff8a2b"),5,.06,77,true,false)
				m.rod(Vector3(0,-.05,.08),Vector3(0,-.18,.06),.055,c("3a4550"))
				m.ball(Vector3(0,.2,-.02),Vector3(.08,.06,.06),c("ff6a1c"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				m.ring(Vector3(0,.1,-.62),.18,.04,c("ffd23f"),Vector3(PI*.5,0,0))
				muzzle=Vector3(0,.1,-.7)
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
			# The twelve weapons that attack in their own ways (WeaponActs, November 3).
			"halo":
				m.rod(Vector3(0,-.15,.05),Vector3(0,.2,-.1),.035,c("6b4a8a"))
				m.ring(Vector3(0,.36,-.16),.17,.04,c("b48cf2"),Vector3(.5,0,0));m.ring(Vector3(0,.36,-.16),.11,.025,c("e8d8ff"),Vector3(.5,0,0))
				m.ball(Vector3(0,.36,-.16),Vector3.ONE*.1,c("d8b8ff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				muzzle=Vector3(0,.36,-.2)
			"orbit-lids":
				m.rod(Vector3(0,-.15,.05),Vector3(0,.12,-.1),.04,c("3a3040"))
				for k in range(2): m.ball(Vector3((k-.5)*.18,.2+k*.05,-.2-k*.08),Vector3(.3,.05,.3),c("c9d2dc"));m.ball(Vector3((k-.5)*.18,.24+k*.05,-.2-k*.08),Vector3(.08,.05,.08),c("3a3040"))
				muzzle=Vector3(0,.25,-.3)
			"fire-trail","frost-trail":
				# A chunky boot with a glowing sole.
				var tone=c("ff8a2b") if id=="fire-trail" else c("9fe9ff")
				m.ball(Vector3(0,.12,0),Vector3(.24,.34,.26),c("a86a3a") if id=="fire-trail" else c("e8f4ff"))
				m.ball(Vector3(0,-.04,-.14),Vector3(.26,.18,.44),c("a86a3a") if id=="fire-trail" else c("e8f4ff"))
				m.ball(Vector3(0,-.14,-.14),Vector3(.28,.06,.46),tone,CartoonMesh.BODY,0.0,Vector2(0,1),true)
				if id=="fire-trail":
					for k in range(3): m.spike(Vector3((k-1)*.08,-.1,.02-k*.1),Vector3((k-1)*.1,.06,.12-k*.1),.04,c("ffd56b"))
				else:
					for k in range(3): m.spike(Vector3((k-1)*.09,-.14,-.14),Vector3((k-1)*.13,-.3,-.16),.03,c("dff6ff"))
				muzzle=Vector3(0,-.14,-.36)
			"dice":
				m.box(Vector3(0,.12,-.15),Vector3.ONE*.3,c("fff6e6"),CartoonMesh.BODY,Vector3(.4,.5,.2))
				for q in [Vector3(0,.12,-.31),Vector3(.1,.22,-.27),Vector3(-.1,.02,-.27)]: m.ball(q,Vector3.ONE*.05,c("e8384f"))
				m.rod(Vector3(0,-.02,.05),Vector3(0,-.18,.1),.04,c("3a3040"))
				muzzle=Vector3(0,.12,-.32)
			"blood-pump":
				m.rod(Vector3(0,-.15,.05),Vector3(0,.05,-.05),.04,c("3a3040"))
				m.ball(Vector3(0,.18,-.12),Vector3(.28,.3,.26),c("b02a3a"));m.ball(Vector3(-.06,.26,-.22),Vector3.ONE*.08,c("ff8a9a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				for k in range(2): m.can(Vector3((k-.5)*.12,.3,-.08),Vector3((k-.5)*.14,.42,-.04),.04,c("7a1a2a"))
				m.ring(Vector3(0,.18,-.12),.15,.025,c("ffd23f"),Vector3(PI*.5,0,0))
				muzzle=Vector3(0,.18,-.28)
			"whip":
				m.rod(Vector3(0,-.15,.08),Vector3(0,.05,-.05),.05,c("6b4a8a"))
				var last=Vector3(0,.05,-.05)
				for k in range(7):
					var q=Vector3(sin(k*.9)*.09,.05+k*.03,-.12-k*.09);m.rod(last,q,.04-k*.004,c("c97aff"));last=q
				m.ball(last,Vector3.ONE*.08,c("ff6bd5"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				muzzle=last
			"snip-knife","katana","hero-blade","grudge-blade":
				var blade={"snip-knife":c("d8e0ee"),"katana":c("e8f4ff"),"hero-blade":c("fff2b8"),"grudge-blade":c("6a2a3a")}[id]
				var guard={"snip-knife":c("3a3040"),"katana":c("e8384f"),"hero-blade":c("ffd23f"),"grudge-blade":c("b04060")}[id]
				var length={"snip-knife":.32,"katana":.7,"hero-blade":.6,"grudge-blade":.62}[id]
				m.rod(Vector3(0,-.16,.08),Vector3(0,.02,-.02),.035,c("3a3040"))
				m.box(Vector3(0,.04,-.04),Vector3(.2 if id!="katana" else .1,.05,.06),guard)
				m.box(Vector3(0,.05,-.06-length*.5),Vector3(.035,.1 if id!="katana" else .06,length),blade,CartoonMesh.BODY)
				m.spike(Vector3(0,.05,-.06-length),Vector3(0,.05,-.14-length),.045,blade)
				if id=="hero-blade": m.ball(Vector3(0,.05,-.04),Vector3.ONE*.07,c("7dfffb"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				if id=="grudge-blade":
					for k in range(3): m.spike(Vector3(0,.09,-.16-k*.16),Vector3(0,.18,-.2-k*.16),.025,c("b04060"))
					m.ball(Vector3(0,.05,-.04),Vector3.ONE*.07,c("ff3b6b"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				muzzle=Vector3(0,.05,-.14-length)
			"scythe":
				m.rod(Vector3(0,-.25,.12),Vector3(0,.35,-.15),.035,c("6b4a3a"))
				var tip=Vector3(0,.35,-.15)
				for k in range(6):
					var a=k*.28;var q=tip+Vector3(0,-sin(a)*.12,-cos(a)*.0)+Vector3(0,-.02*k,-.08*k)
					m.box(q,Vector3(.03,.08-.008*k,.1),c("c8d4dc"))
				m.ball(tip,Vector3.ONE*.06,c("9fe0c0"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				muzzle=tip+Vector3(0,-.12,-.45)
	s.muzzle(muzzle)
	return s.finish()

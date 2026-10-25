extends RefCounted
class_name CartoonBosses

# The eight realm bosses rebuilt in the cartoon style (user request, October 25),
# each an original design matching its name and fight. Built about 3 units tall
# (ActorRig scales bosses to their height) with the Body/Head/Leg/Arm joints
# BossBook.animate moves, and one glass health orb in plain view.

const INK=CartoonMesh.INK
const TOOTH=CartoonMesh.TOOTH
const MOUTH=CartoonMesh.MOUTH

static func c(hex: String) -> Color: return Color(hex)

static func has(asset: String) -> bool:
	return asset.begins_with("boss_") and asset.length()==6 and int(asset.right(1)) in range(8)

static func scene(asset: String) -> Node3D:
	var s=CartoonScene.new();var b=s.paint(s.body,"BodyPaint")
	match int(asset.right(1)):
		0:  # The Last Receiver: a TV-headed alien, one eye on a glowing screen.
			var suit=c("6b7bff")
			b.rod(Vector3(0,.8,0),Vector3(0,1.6,0),.42,suit);b.ball(Vector3(0,1.15,-.35),Vector3(.5,.5,.1),c("ffd23f"))
			var h=s.make_head(Vector3(0,2.2,0))
			h.box(Vector3.ZERO,Vector3(1.25,.9,.8),c("c9d6e8"));h.box(Vector3(0,0,-.4),Vector3(.95,.66,.04),c("7dfffb"))
			h.eye(Vector3(0,.02,-.46),.24,Vector3.FORWARD,c("ff3b6b"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			for y in [-.22,.22]: h.box(Vector3(0,y,-.43),Vector3(.9,.025,.01),c("bffcff"))
			for side in [-1.0,1.0]: h.antenna(Vector3(side*.2,.45,0),Vector3(side*.55,1.05,.1),.08,c("8a94b0"),c("ff4fd8"),.5+side*.2)
			for k in range(3): h.ball(Vector3(.45,-.25+k*.12,-.41),Vector3.ONE*.07,c("ff3b3b"))
			s.make_arms(Vector3(.6,1.6,0),.95,.1,c("8a94b0"),c("ffd23f"),1.3);s.make_legs(Vector3(.22,.8,0),.7,.14,suit,c("2a2340"))
			s.orb(Vector3(0,1.15,-.42),.22)
		1:  # Mourning Bell: a crying brass bell with a clapper for a tongue.
			var brass=c("ffc23f")
			b.ball(Vector3(0,2.0,0),Vector3(1.3,1.0,1.3),brass);b.spike(Vector3(0,.75,0),Vector3(0,2.2,0),.85,brass);b.ring(Vector3(0,.78,0),.86,.16,c("e0a020"))
			b.can(Vector3(0,2.45,0),Vector3(0,2.7,0),.14,c("a86a3a"));b.ring(Vector3(0,2.8,0),.16,.06,c("a86a3a"),Vector3(PI*.5,0,0))
			var h=s.make_head(Vector3(0,1.55,-.55))
			for side in [-1.0,1.0]:
				h.eye(Vector3(side*.22,.1,0),.14,Vector3(side*.1,-.4,-1),c("3b7dff"));h.box(Vector3(side*.22,.3,-.02),Vector3(.32,.06,.06),INK,CartoonMesh.BODY,Vector3(0,0,-side*.35))
				for k in range(3): h.ball(Vector3(side*.26,-.08-k*.16,-.02),Vector3(.07,.11,.05),c("7dd6ff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			h.grin(Vector3(0,-.25,0),.4,.1,0,false)
			var clapper=s.joint("TailClapper",s.body,Vector3(0,.95,0));var cm=s.paint(clapper,"ClapperPaint")
			cm.rod(Vector3.ZERO,Vector3(0,-.55,0),.06,c("8a6a3a"));cm.ball(Vector3(0,-.65,0),Vector3.ONE*.3,c("ff7aa0"))
			s.make_arms(Vector3(.8,1.4,0),.6,.08,brass,c("ffffff"));s.make_legs(Vector3(.35,.75,0),.55,.1,c("a86a3a"),INK)
			s.orb(Vector3(0,2.1,-.62),.2)
		2:  # Lantern Ossuary: a bony giant whose head is a lantern with a fire eye.
			var bone=c("fff3d2")
			for k in range(5): b.ring(Vector3(0,.95+k*.2,0),.42-absf(k-2)*.04,.06,bone)
			b.rod(Vector3(0,.8,.1),Vector3(0,1.95,.12),.07,bone);b.ball(Vector3(0,.78,0),Vector3(.7,.3,.5),bone)
			var h=s.make_head(Vector3(0,2.35,0))
			h.box(Vector3(0,.45,0),Vector3(.8,.1,.8),c("2a2340"));h.box(Vector3(0,-.4,0),Vector3(.8,.1,.8),c("2a2340"))
			for x in [-.36,.36]:
				for z in [-.36,.36]: h.box(Vector3(x,0,z),Vector3(.07,.8,.07),c("2a2340"))
			h.ball(Vector3.ZERO,Vector3.ONE*.55,c("ff8a2b"),CartoonMesh.BODY,0.0,Vector2(0,1),true);h.eye(Vector3(0,0,-.26),.13,Vector3.FORWARD,c("fff27d"))
			h.ring(Vector3(0,.62,0),.12,.05,c("2a2340"),Vector3(PI*.5,0,0))
			s.make_arms(Vector3(.55,1.8,0),1.05,.06,bone,bone,1.6);s.make_legs(Vector3(.22,.75,0),.68,.07,bone,bone)
			s.orb(Vector3(0,1.35,-.42),.2)
		3:  # The Hollow Procession: a tall robe wearing three hollow masks.
			var robe=c("4b3b8b")
			b.spike(Vector3(0,.3,0),Vector3(0,2.6,0),.7,robe);b.ball(Vector3(0,.4,0),Vector3(1.4,.3,1.3),c("3b2b6b"))
			for k in range(3):
				var y=1.3+k*.55;var x=[-.2,.25,0.0][k];var mask=Vector3(x,y,-.45+k*.12)
				b.ball(mask,Vector3(.5,.58,.18),c("fffaf0"))
				for side in [-1.0,1.0]: b.ball(mask+Vector3(side*.1,.06,-.07),Vector3(.1,.13,.06),INK)
				b.ball(mask+Vector3(0,-.15,-.07),Vector3(.12,.08,.05),INK)
			var h=s.make_head(Vector3(0,2.7,0));h.ball(Vector3.ZERO,Vector3(.6,.6,.6),robe);h.ball(Vector3(0,-.02,-.22),Vector3(.38,.42,.2),INK)
			for x in [-.08,.08]: h.ball(Vector3(x,0,-.3),Vector3(.07,.05,.03),c("ffef5a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			s.make_arms(Vector3(.5,1.9,0),.9,.1,robe,c("c9a5ff"));s.make_legs(Vector3(.3,.3,0),.22,.1,c("3b2b6b"),INK)
			s.orb(Vector3(0,.95,-.55),.2)
		4:  # Witness of Knots: a giant eyeball wrapped in knotted tentacles.
			var flesh=c("8fff5a")
			b.ball(Vector3(0,1.7,0),Vector3.ONE*1.6,c("fbfbf4"))
			b.ball(Vector3(0,1.75,-.62),Vector3(.8,.8,.4),c("2fd38a"),CartoonMesh.BODY,0.0,Vector2(0,1),true);b.ball(Vector3(0,1.75,-.78),Vector3(.38,.38,.12),INK)
			for k in range(4): b.rod(Vector3(-.4+k*.25,2.35,-.3),Vector3(-.3+k*.2,2.1,-.65),.025,c("ff3b3b"))
			for k in range(3): b.ring(Vector3(0,1.7,0),.82,.14,flesh,Vector3(.6*k,.9*k,.3))
			for i in range(6):
				var a=i*TAU/6;var t=s.joint("Tentacle"+str(i),s.body,Vector3(cos(a)*.6,1.0,sin(a)*.6));var m=s.paint(t,"TentaclePaint"+str(i))
				for k in range(6): m.ball(Vector3(cos(a)*k*.08,-k*.15,sin(a)*k*.08),Vector3.ONE*(.24-k*.03),flesh)
			s.head=s.joint("Head",s.body,Vector3(0,1.7,0))
			s.make_arms(Vector3(.85,1.6,0),.8,.1,flesh,c("2fd38a"));s.make_legs(Vector3(.3,.9,0),.8,.12,flesh,c("2fd38a"))
			s.orb(Vector3(.62,2.25,-.5),.18)
		5:  # The Drowned Spire: a towering anglerfish eel with a lantern lure.
			var scale_c=c("2fa8ff")
			for k in range(4): b.ball(Vector3(0,.5+k*.48,.0),Vector3.ONE*(1.0-k*.08),scale_c if k%2==0 else c("2470c0"))
			b.spots(Vector3(0,1.2,0),Vector3(.45,.9,.45),c("d8e0ee"),10,.1,605)
			var h=s.make_head(Vector3(0,2.45,-.1))
			h.ball(Vector3.ZERO,Vector3(1.0,.85,1.0),scale_c);h.grin(Vector3(0,-.12,-.45),.8,.4,9,false)
			h.eye(Vector3(-.3,.25,-.36),.1,Vector3(-.3,0,-1),c("fff27d"));h.eye(Vector3(.32,.22,-.36),.13,Vector3(.3,0,-1),c("fff27d"))
			h.antenna(Vector3(0,.4,-.1),Vector3(0,.9,-.6),.12,c("2470c0"),c("fff27d"))
			for side in [-1.0,1.0]: h.spike(Vector3(side*.48,0,0),Vector3(side*.85,.25,.2),.18,c("7dfffb"))
			s.make_arms(Vector3(.55,1.6,0),.6,.08,c("7dfffb"),c("7dfffb"),1.4);s.make_legs(Vector3(.25,.4,0),.3,.12,scale_c,c("2470c0"))
			s.orb(Vector3(0,1.5,-.45),.2)
		6:  # Gallows Appetite: a walking giant mouth on chicken legs.
			var lips=c("ff3b4a")
			b.ball(Vector3(0,1.7,0),Vector3(1.8,1.3,1.4),lips);b.ball(Vector3(0,1.6,-.62),Vector3(1.4,.75,.3),MOUTH)
			for k in range(9):
				var x=-.6+k*.15;b.spike(Vector3(x,1.95,-.68),Vector3(x,1.95-.2-.12*float(k%2),-.7),.06,TOOTH);b.spike(Vector3(x+.07,1.25,-.68),Vector3(x+.07,1.43+.08*float(k%3),-.7),.05,TOOTH)
			b.ball(Vector3(.1,1.3,-.85),Vector3(.5,.14,.6),CartoonMesh.TONGUE)
			var h=s.make_head(Vector3(0,2.3,0))
			h.stalk_eye(Vector3(-.3,0,0),Vector3(-.5,.5,-.1),.14,lips,Vector3(-.3,0,-1),c("ffd23f"),.2);h.stalk_eye(Vector3(.3,0,0),Vector3(.45,.6,-.12),.11,lips,Vector3(.4,0,-1),c("ffd23f"),.7)
			s.make_arms(Vector3(.9,1.6,0),.4,.07,lips,c("ffb3c7"));s.make_legs(Vector3(.4,1.05,0),.95,.08,c("ffb02a"),c("ffb02a"))
			s.orb(Vector3(0,2.25,-.5),.18)
		7:  # Antler Reliquary: a mossy giant with a deer skull and branching antlers.
			var moss=c("4fc94a")
			b.ball(Vector3(0,1.35,0),Vector3(1.4,1.6,1.1),moss);b.spots(Vector3(0,1.35,0),Vector3(.7,.8,.55),c("2a8a2a"),10,.2,707)
			b.spots(Vector3(0,1.35,0),Vector3(.7,.8,.55),c("fff27d"),6,.08,708,true)
			var h=s.make_head(Vector3(0,2.3,-.2))
			h.ball(Vector3.ZERO,Vector3(.65,.6,.75),c("fff3d2"));h.ball(Vector3(0,-.15,-.38),Vector3(.38,.3,.35),c("fff3d2"))
			for side in [-1.0,1.0]:
				h.ball(Vector3(side*.16,.05,-.32),Vector3(.16,.18,.08),INK);h.ball(Vector3(side*.16,.05,-.35),Vector3.ONE*.08,c("7dff6a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				var base=Vector3(side*.25,.25,0);var tip=base+Vector3(side*.6,.8,.1)
				h.rod(base,tip,.06,c("c9a06a"))
				for k in range(3):
					var at=base.lerp(tip,.35+k*.25);h.rod(at,at+Vector3(side*.25,.3,-.1+k*.05),.04,c("c9a06a"))
			for k in range(3): h.spike(Vector3(-.1+k*.1,-.28,-.5),Vector3(-.1+k*.1,-.4,-.52),.03,TOOTH)
			s.make_arms(Vector3(.75,1.8,0),.95,.12,c("8a6a3a"),moss,1.2);s.make_legs(Vector3(.35,.7,0),.62,.15,c("8a6a3a"),c("5a4a2a"))
			s.orb(Vector3(0,1.25,-.56),.22)
	return s.finish()

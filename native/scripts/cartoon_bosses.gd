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
		0:  # The Last Receiver: a TV-headed alien whose torso is a big glass orb.
			var suit=c("6b7bff")
			b.rod(Vector3(0,.8,0),Vector3(0,.82,0),.32,suit);b.ball(Vector3(0,1.78,0),Vector3(1.0,.24,.7),suit);b.ring(Vector3(0,1.28,0),.5,.08,c("ffd23f"))
			var h=s.make_head(Vector3(0,2.25,0))
			h.box(Vector3.ZERO,Vector3(1.25,.9,.8),c("c9d6e8"));h.box(Vector3(0,0,-.4),Vector3(.95,.66,.04),c("7dfffb"))
			h.eye(Vector3(0,.02,-.46),.24,Vector3.FORWARD,c("ff3b6b"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			for y in [-.22,.22]: h.box(Vector3(0,y,-.43),Vector3(.9,.025,.01),c("bffcff"))
			for side in [-1.0,1.0]: h.antenna(Vector3(side*.2,.45,0),Vector3(side*.55,1.05,.1),.08,c("8a94b0"),c("ff4fd8"),.5+side*.2)
			s.make_arms(Vector3(.6,1.72,0),.95,.1,c("8a94b0"),c("ffd23f"),1.3);s.make_legs(Vector3(.22,.82,0),.72,.14,suit,c("2a2340"))
			s.orb(Vector3(0,1.28,0),.52,null,true)
		1:  # Mourning Bell: a crying glass bell, brass rims, a clapper for a tongue.
			var brass=c("ffc23f")
			b.ring(Vector3(0,.95,0),.72,.18,brass);b.ring(Vector3(0,1.7,0),.74,.08,brass)
			b.ball(Vector3(0,2.38,0),Vector3(.6,.22,.6),brass);b.can(Vector3(0,2.45,0),Vector3(0,2.68,0),.14,c("a86a3a"));b.ring(Vector3(0,2.78,0),.16,.06,c("a86a3a"),Vector3(PI*.5,0,0))
			var h=s.make_head(Vector3(0,1.9,-.6))
			for side in [-1.0,1.0]:
				h.eye(Vector3(side*.22,.1,0),.14,Vector3(side*.1,-.4,-1),c("3b7dff"));h.box(Vector3(side*.22,.3,-.02),Vector3(.32,.06,.06),INK,CartoonMesh.BODY,Vector3(0,0,-side*.35))
				for k in range(3): h.ball(Vector3(side*.26,-.08-k*.16,-.02),Vector3(.07,.11,.05),c("7dd6ff"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
			h.grin(Vector3(0,-.25,0),.4,.1,0,false)
			var clapper=s.joint("TailClapper",s.body,Vector3(0,.95,0));var cm=s.paint(clapper,"ClapperPaint")
			cm.rod(Vector3.ZERO,Vector3(0,-.5,0),.06,c("8a6a3a"));cm.ball(Vector3(0,-.6,0),Vector3.ONE*.3,c("ff7aa0"))
			s.make_arms(Vector3(.8,1.5,0),.6,.08,brass,c("ffffff"));s.make_legs(Vector3(.35,.8,0),.6,.1,c("a86a3a"),INK)
			s.orb(Vector3(0,1.6,0),.72,null,true)
		2:  # Lantern Ossuary: a bony giant with a big glass orb inside its ribcage.
			var bone=c("fff3d2")
			for k in range(5): b.ring(Vector3(0,.95+k*.2,0),.5-absf(k-2)*.05,.06,bone)
			b.rod(Vector3(0,.8,.5),Vector3(0,1.95,.5),.07,bone);b.ball(Vector3(0,.78,0),Vector3(.7,.25,.5),bone);b.ball(Vector3(0,1.98,0),Vector3(.8,.18,.5),bone)
			var h=s.make_head(Vector3(0,2.38,0))
			h.box(Vector3(0,.45,0),Vector3(.8,.1,.8),c("2a2340"));h.box(Vector3(0,-.4,0),Vector3(.8,.1,.8),c("2a2340"))
			for x in [-.36,.36]:
				for z in [-.36,.36]: h.box(Vector3(x,0,z),Vector3(.07,.8,.07),c("2a2340"))
			h.ball(Vector3.ZERO,Vector3.ONE*.55,c("ff8a2b"),CartoonMesh.BODY,0.0,Vector2(0,1),true);h.eye(Vector3(0,0,-.26),.13,Vector3.FORWARD,c("fff27d"))
			s.make_arms(Vector3(.55,1.85,0),1.05,.06,bone,bone,1.6);s.make_legs(Vector3(.22,.75,0),.68,.07,bone,bone)
			s.orb(Vector3(0,1.36,0),.46,null,true)
		3:  # The Hollow Procession: a robed figure with a big glass orb chest and three hollow masks.
			var robe=c("4b3b8b")
			b.spike(Vector3(0,.3,0),Vector3(0,1.05,0),.7,robe);b.ball(Vector3(0,.4,0),Vector3(1.4,.3,1.3),c("3b2b6b"));b.ball(Vector3(0,2.2,0),Vector3(1.0,.26,.7),robe)
			for k in range(2):
				var mask=Vector3(-.62 if k==0 else .62,1.6,-.15)
				b.ball(mask,Vector3(.42,.5,.16),c("fffaf0"),CartoonMesh.BODY,0.0,Vector2(0,1),false,Vector3(0,(1 if k==0 else -1)*.5,0))
				for side in [-1.0,1.0]: b.ball(mask+Vector3(side*.08,.06,-.06),Vector3(.09,.12,.05),INK)
			var h=s.make_head(Vector3(0,2.6,0));h.ball(Vector3.ZERO,Vector3(.6,.6,.6),robe);h.ball(Vector3(0,0,-.25),Vector3(.44,.5,.14),c("fffaf0"))
			for x in [-.09,.09]: h.ball(Vector3(x,.05,-.31),Vector3(.09,.12,.04),INK)
			h.ball(Vector3(0,-.13,-.31),Vector3(.1,.07,.04),INK)
			s.make_arms(Vector3(.6,2.05,0),.9,.1,robe,c("c9a5ff"));s.make_legs(Vector3(.3,.3,0),.22,.1,c("3b2b6b"),INK)
			s.orb(Vector3(0,1.6,0),.6,null,true)
		4:  # Witness of Knots: its giant eyeball is the glass orb, wrapped in knotted tentacles.
			var flesh=c("8fff5a")
			b.ball(Vector3(0,1.72,-.74),Vector3(.6,.6,.12),c("2fd38a"),CartoonMesh.BODY,0.0,Vector2(0,1),true);b.ball(Vector3(0,1.72,-.8),Vector3(.3,.3,.08),INK)
			for k in range(3): b.ring(Vector3(0,1.7,0),.8,.14,flesh,Vector3(.6*k+.4,.9*k,.3))
			for i in range(6):
				var a=i*TAU/6;var t=s.joint("Tentacle"+str(i),s.body,Vector3(cos(a)*.6,1.0,sin(a)*.6));var m=s.paint(t,"TentaclePaint"+str(i))
				for k in range(6): m.ball(Vector3(cos(a)*k*.08,-k*.15,sin(a)*k*.08),Vector3.ONE*(.24-k*.03),flesh)
			s.head=s.joint("Head",s.body,Vector3(0,1.7,0))
			s.make_arms(Vector3(.85,1.6,0),.8,.1,flesh,c("2fd38a"));s.make_legs(Vector3(.3,.9,0),.8,.12,flesh,c("2fd38a"))
			s.orb(Vector3(0,1.7,0),.78,null,true)
		5:  # The Drowned Spire: a towering anglerfish eel; its middle segment is a big glass orb.
			var scale_c=c("2fa8ff")
			b.ball(Vector3(0,.5,0),Vector3.ONE*.95,scale_c);b.ball(Vector3(0,1.8,0),Vector3.ONE*.82,c("2470c0"))
			b.ring(Vector3(0,1.15,0),.5,.08,c("2470c0"))
			var h=s.make_head(Vector3(0,2.45,-.1))
			h.ball(Vector3.ZERO,Vector3(1.0,.85,1.0),scale_c);h.grin(Vector3(0,-.12,-.45),.8,.4,9,false)
			h.eye(Vector3(-.3,.25,-.36),.1,Vector3(-.3,0,-1),c("fff27d"));h.eye(Vector3(.32,.22,-.36),.13,Vector3(.3,0,-1),c("fff27d"))
			h.antenna(Vector3(0,.4,-.1),Vector3(0,.9,-.6),.12,c("2470c0"),c("fff27d"))
			for side in [-1.0,1.0]: h.spike(Vector3(side*.48,0,0),Vector3(side*.85,.25,.2),.18,c("7dfffb"))
			s.make_arms(Vector3(.55,1.8,0),.6,.08,c("7dfffb"),c("7dfffb"),1.4);s.make_legs(Vector3(.25,.4,0),.3,.12,scale_c,c("2470c0"))
			s.orb(Vector3(0,1.15,0),.55,null,true)
		6:  # Gallows Appetite: a walking giant mouth whose big glass orb belly sits behind it.
			var lips=c("ff3b4a")
			b.ball(Vector3(0,1.75,-.35),Vector3(1.7,1.2,.75),lips);b.ball(Vector3(0,1.65,-.7),Vector3(1.3,.7,.25),MOUTH)
			for k in range(9):
				var x=-.6+k*.15;b.spike(Vector3(x,1.98,-.74),Vector3(x,1.98-.2-.12*float(k%2),-.76),.06,TOOTH);b.spike(Vector3(x+.07,1.32,-.74),Vector3(x+.07,1.5+.08*float(k%3),-.76),.05,TOOTH)
			b.ball(Vector3(.1,1.36,-.9),Vector3(.5,.14,.6),CartoonMesh.TONGUE)
			var h=s.make_head(Vector3(0,2.38,-.2))
			h.stalk_eye(Vector3(-.3,0,0),Vector3(-.5,.5,-.1),.14,lips,Vector3(-.3,0,-1),c("ffd23f"),.2);h.stalk_eye(Vector3(.3,0,0),Vector3(.45,.6,-.12),.11,lips,Vector3(.4,0,-1),c("ffd23f"),.7)
			s.make_arms(Vector3(.9,1.6,0),.4,.07,lips,c("ffb3c7"));s.make_legs(Vector3(.4,1.05,0),.95,.08,c("ffb02a"),c("ffb02a"))
			s.orb(Vector3(0,1.7,.45),.68,null,true)
		7:  # Antler Reliquary: a mossy frame around a big glass orb, a deer skull with antlers on top.
			var moss=c("4fc94a")
			b.ball(Vector3(0,.62,0),Vector3(1.2,.35,1.0),moss);b.ball(Vector3(0,2.05,0),Vector3(1.3,.4,1.0),moss)
			for side in [-1.0,1.0]: b.rod(Vector3(side*.62,.7,0),Vector3(side*.62,2.0,0),.12,moss)
			b.spots(Vector3(0,2.05,0),Vector3(.65,.2,.5),c("2a8a2a"),6,.18,707);b.spots(Vector3(0,.62,0),Vector3(.6,.17,.5),c("fff27d"),5,.07,708,true)
			var h=s.make_head(Vector3(0,2.45,-.2))
			h.ball(Vector3.ZERO,Vector3(.65,.6,.75),c("fff3d2"));h.ball(Vector3(0,-.15,-.38),Vector3(.38,.3,.35),c("fff3d2"))
			for side in [-1.0,1.0]:
				h.ball(Vector3(side*.16,.05,-.32),Vector3(.16,.18,.08),INK);h.ball(Vector3(side*.16,.05,-.35),Vector3.ONE*.08,c("7dff6a"),CartoonMesh.BODY,0.0,Vector2(0,1),true)
				var base=Vector3(side*.25,.25,0);var tip=base+Vector3(side*.6,.8,.1)
				h.rod(base,tip,.06,c("c9a06a"))
				for k in range(3):
					var at=base.lerp(tip,.35+k*.25);h.rod(at,at+Vector3(side*.25,.3,-.1+k*.05),.04,c("c9a06a"))
			s.make_arms(Vector3(.75,1.95,0),.95,.12,c("8a6a3a"),moss,1.2);s.make_legs(Vector3(.35,.62,0),.55,.15,c("8a6a3a"),c("5a4a2a"))
			s.orb(Vector3(0,1.35,0),.62,null,true)
	return s.finish()

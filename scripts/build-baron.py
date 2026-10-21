"""Original stylized floating Baron: colossal, bald, pale and bare, with heavy fat
folds and short dangling legs. Authored from primitives; no third-party model,
texture, reference image or actor likeness. The runtime floats and bobs him.
"""
import importlib.util, math
from pathlib import Path
spec=importlib.util.spec_from_file_location('forge',Path(__file__).with_name('build-forge-slice.py'))
f=importlib.util.module_from_spec(spec);spec.loader.exec_module(f)
s=f.s

SKIN='cfc8b8';SHADE='a8a092';FOLD='8f887c';LESION='8a706a';LIP='7d6f6c';EYE='1c1e20';BROW='9b9488'

def build():
 a=f.Asset('boss_8_baron');root=a.node('Root');body=a.node('Body',root);head=a.node('Head',body)
 # An enormous pear-shaped trunk: the belly sags forward and down, wider than he is tall.
 profile=[(0.0,.42,.40),(.06,.70,.66),(.16,1.02,.94),(.30,1.16,1.06),(.44,1.14,1.02),(.58,1.04,.90),(.72,.92,.78),(.84,.80,.66),(.94,.56,.48),(1.0,.40,.36)]
 def bare_torso(u,v):
  angle=u*math.tau;width,depth=profile[-1][1],profile[-1][2]
  for i in range(len(profile)-1):
   if v<=profile[i+1][0]:
    t=(v-profile[i][0])/(profile[i+1][0]-profile[i][0])
    width=profile[i][1]+(profile[i+1][1]-profile[i][1])*t;depth=profile[i][2]+(profile[i+1][2]-profile[i][2])*t;break
  front=max(0,-math.sin(angle))
  # Belly hangs forward low; the back stays flatter.
  sag=.22*front**2*math.exp(-((v-.28)/.18)**2)
  return (math.cos(angle)*width,.40+v*1.90,math.sin(angle)*depth-sag)
 s.grid(a,'BareTorso',bare_torso,40,80,SKIN,body)
 # Deep fat folds wrap the trunk; each is a darker crease with a pale roll above it.
 for y,r in [(.86,1.06),(1.18,1.10),(1.52,1.00),(1.84,.84)]:
  s.organic(a,'FatCrease',(0,y,-r*.86),(r*.70,.025,.06),FOLD,body,segments=32)
  s.organic(a,'FatRoll',(0,y+.07,-r*.80),(r*.72,.09,.14),SHADE,body,segments=32)
 s.organic(a,'Navel',(0,1.02,-1.25),(.06,.08,.03),FOLD,body,segments=16)
 for side in [-1,1]:
  # Heavy sagging chest and back fat.
  s.organic(a,'ChestFold',(side*.40,1.98,-.66),(.40,.26,.22),SKIN,body,segments=32)
  s.organic(a,'SideRoll',(side*1.02,1.30,.05),(.18,.34,.40),SHADE,body,segments=28)
  for k,(x,y,z,r) in enumerate([(.55,1.55,-.86,.05),(.30,1.20,-1.08,.04),(.75,1.00,-.80,.035),(.20,2.05,-.80,.03)]):
   s.organic(a,'Lesion',(side*x,y,z),(r,r*.8,.01),LESION,body,segments=12)
  # Thick hanging arms with heavy wrists and small hands.
  arm=a.node('Arm'+str(side),body,(side*.92,2.02,-.05))
  f.beam(a,'UpperArm',[(0,0,0),(side*.20,-.40,-.02),(side*.26,-.80,-.10)],[.36,.34,.26],SKIN,arm)
  s.organic(a,'ArmFold',(side*.18,-.42,.10),(.30,.22,.24),SHADE,arm,segments=24)
  f.beam(a,'Forearm',[(side*.26,-.74,-.10),(side*.30,-1.06,-.22)],[.25,.18],SKIN,arm)
  s.organic(a,'Hand',(side*.31,-1.16,-.26),(.14,.16,.11),SKIN,arm,segments=24)
  for finger in range(4):
   x=side*(.22+finger*.06);f.beam(a,'Finger',[(x,-1.20,-.30),(x,-1.32,-.32)],[.032,.022],SKIN,arm)
  # Short legs dangle beneath him while he floats.
  leg=a.node('Leg'+str(side),body,(side*.42,.62,.02))
  f.beam(a,'Thigh',[(0,0,0),(side*.04,-.22,-.08),(side*.05,-.40,-.05)],[.34,.28,.20],SKIN,leg)
  f.beam(a,'Calf',[(side*.05,-.38,-.05),(side*.04,-.62,.02)],[.18,.12],SKIN,leg)
  s.organic(a,'Foot',(side*.04,-.68,-.04),(.10,.12,.16),SHADE,leg,segments=20)
 # Thick neck folds and double chin under a small, round, bald head.
 s.organic(a,'ThickNeck',(0,2.30,-.06),(.46,.24,.40),SHADE,head,segments=40)
 s.organic(a,'NeckCrease',(0,2.33,-.40),(.34,.02,.06),FOLD,head,segments=24)
 s.organic(a,'DoubleChin',(0,2.36,-.30),(.30,.14,.20),SKIN,head,segments=32)
 s.organic(a,'BaldHead',(0,2.66,-.10),(.32,.34,.31),SKIN,head,segments=48)
 jaw=a.node('Jaw',head,(0,2.46,-.22))
 s.organic(a,'JawJowl',(0,0,-.02),(.34,.15,.24),SKIN,jaw,segments=40)
 f.beam(a,'Mouth',[(-.11,.02,-.23),(0,.01,-.255),(.11,.02,-.23)],[.012,.016,.012],LIP,jaw)
 for side in [-1,1]:
  s.organic(a,'Jowl',(side*.22,2.50,-.22),(.14,.16,.13),SKIN,head,segments=28)
  s.organic(a,'Ear',(side*.32,2.64,-.08),(.055,.10,.05),SHADE,head,segments=20)
  s.organic(a,'EyeSocket',(side*.12,2.70,-.375),(.085,.045,.025),BROW,head,segments=20)
  s.organic(a,'Eye',(side*.12,2.70,-.395),(.035,.016,.008),EYE,head,segments=16)
  f.beam(a,'HeavyBrow',[(side*.03,2.755,-.385),(side*.12,2.76,-.40),(side*.22,2.745,-.37)],[.03,.04,.016],BROW,head)
  for k in range(2):
   s.organic(a,'ScalpLesion',(side*(.08+k*.12),2.90-k*.05,-.20+k*.08),(.035,.01,.03),LESION,head,segments=12)
 s.organic(a,'NoseBridge',(0,2.64,-.40),(.06,.10,.06),SKIN,head,segments=28)
 s.organic(a,'NoseTip',(0,2.58,-.45),(.08,.05,.05),SKIN,head,segments=28)
 height=3.0
 a.doc["nodes"][root]["scale"]=[3/height]*3
 return a.save()

if __name__=='__main__': print(build())

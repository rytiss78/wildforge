"""Authored stylized Baron-inspired fallback; no third-party model or texture.
Writes a separate asset so the previous Observatory artwork remains available.
"""
import importlib.util, math
from pathlib import Path
spec=importlib.util.spec_from_file_location('forge',Path(__file__).with_name('build-forge-slice.py'))
f=importlib.util.module_from_spec(spec);spec.loader.exec_module(f)
s=f.s

def build():
 a=f.Asset('boss_8_baron');root=a.node('Root');body=a.node('Body',root);head=a.node('Head',body)
 robe='20252c';fold='353e47';skin='b8b4a4';shade='8e8e84';lip='777571'
 # A single tailored drape, broad heavy shoulders, tapering suspended hem.
 def drape(u,v):
  angle=u*math.tau;y=.18+v*2.05
  width=.70+math.sin(v*math.pi*.8)*.43
  depth=.41+math.sin(v*math.pi)*.30
  pleat=(.022+.04*(1-v))*math.cos(angle*17+v*.5)
  return (math.cos(angle)*(width+pleat),y,math.sin(angle)*(depth+pleat)-.07*math.sin(v*math.pi))
 s.grid(a,'SuspendedRobe',drape,28,64,robe,body)
 s.organic(a,'HeavyShoulders',(0,2.04,.02),(1.05,.30,.57),robe,body,segments=48)
 # An exposed neck and chin blend the head into the sunken black collar.
 s.organic(a,'ThickNeck',(0,2.35,-.10),(.42,.26,.31),shade,head,segments=40)
 s.organic(a,'BaldHead',(0,2.67,-.12),(.33,.36,.31),skin,head,segments=48)
 s.organic(a,'Jaw',(0,2.48,-.22),(.36,.20,.27),skin,head,segments=40)
 s.organic(a,'ChinFold',(0,2.35,-.25),(.30,.09,.20),shade,head,segments=40)
 for side in [-1,1]:
  s.organic(a,'Ear',(side*.33,2.63,-.10),(.06,.11,.055),shade,head,segments=24)
  s.organic(a,'Cheek',(side*.20,2.57,-.34),(.15,.17,.13),skin,head,segments=32)
  s.organic(a,'EyeSocket',(side*.135,2.70,-.401),(.095,.055,.028),'585f5e',head,segments=24)
  s.organic(a,'Eye',(side*.133,2.697,-.425),(.047,.018,.009),'a9b8b8',head,segments=24)
  s.organic(a,'Pupil',(side*.133,2.697,-.434),(.013,.016,.004),'202326',head,segments=16)
  f.beam(a,'HeavyBrow',[(side*.04,2.756,-.407),(side*.13,2.759,-.425),(side*.235,2.74,-.395)],[.028,.04,.014],shade,head)
  f.beam(a,'NasalCrease',[(side*.07,2.61,-.459),(side*.11,2.55,-.438),(side*.14,2.49,-.405)],[.009,.007,.003],shade,head)
  arm=a.node('Arm'+str(side),body,(side*.89,2.06,.04))
  f.beam(a,'HeavySleeve',[(0,0,0),(side*.24,-.32,-.04),(side*.26,-.82,-.13)],[.28,.27,.18],robe,arm)
  s.organic(a,'Hand',(side*.26,-.89,-.14),(.18,.22,.12),skin,arm,segments=28)
  for finger in range(4):
   x=side*(.13+finger*.075)
   f.beam(a,'Finger',[(x,-.98,-.16),(x,-1.13,-.19),(x-side*.025,-1.19,-.21)],[.035,.03,.017],skin,arm)
  f.beam(a,'Thumb',[(side*.10,-.86,-.16),(side*.035,-1.0,-.23)],[.05,.028],shade,arm)
  # Thin seams catch warm arena light without turning the robe into armour.
  f.beam(a,'RobeSeam',[(side*.34,2.16,-.54),(side*.59,1.6,-.66),(side*.45,.3,-.42)],[.014,.012,.008],fold,body)
 s.organic(a,'NoseBridge',(0,2.66,-.421),(.065,.11,.063),skin,head,segments=32)
 s.organic(a,'NoseTip',(0,2.60,-.478),(.092,.046,.055),skin,head,segments=32)
 f.beam(a,'Mouth', [(-.12,2.48,-.438),(0,2.497,-.467),(.12,2.48,-.438)],[.01,.014,.01],lip,head)
 s.organic(a,'LowerLip',(0,2.475,-.454),(.09,.021,.018),shade,head,segments=24)
 f.core(a,body,(0,1.61,-.744),.17)
 a.doc["nodes"][root]["scale"]=[3/2.85]*3
 a.doc["nodes"][root]["translation"]=[0,-.18*3/2.85,0]
 return a.save()

if __name__=='__main__': print(build())

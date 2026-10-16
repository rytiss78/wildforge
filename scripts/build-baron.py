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
 skin='b8b4a4';shade='8e8e84';lip='777571'
 # A continuous skin surface gives the torso a rounded chest and heavy abdomen.
 profile=[(0.0,.30,.32),(.08,.39,.40),(.22,.59,.53),(.42,.82,.66),(.56,.91,.69),(.68,.81,.62),(.82,.63,.51),(.94,.40,.37),(1.0,.34,.33)]
 def bare_torso(u,v):
  angle=u*math.tau
  width,depth=profile[-1][1],profile[-1][2]
  for index in range(len(profile)-1):
   if v<=profile[index+1][0]:
    start,end=profile[index],profile[index+1]
    amount=(v-start[0])/(end[0]-start[0])
    width=start[1]+(end[1]-start[1])*amount
    depth=start[2]+(end[2]-start[2])*amount
    break
  x=math.cos(angle)*width
  z=math.sin(angle)*depth-.07*max(0,-math.sin(angle))**6*math.exp(-((v-.49)/.20)**2)
  return (x,.20+v*2.0,z)
 s.grid(a,'BareTorso',bare_torso,36,72,skin,body)
 s.organic(a,'Navel',(0,1.18,-.69),(.045,.065,.025),shade,body,segments=16)
 # A thick exposed neck joins the bare shoulders to the bald head.
 s.organic(a,'ThickNeck',(0,2.32,-.10),(.40,.27,.31),shade,head,segments=40)
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
  arm=a.node('Arm'+str(side),body,(side*.72,1.86,.02))
  f.beam(a,'UpperArm',[(0,0,0),(side*.12,-.37,-.03),(side*.16,-.76,-.12)],[.34,.30,.24],skin,arm)
  f.beam(a,'Forearm',[(side*.16,-.65,-.12),(side*.22,-.96,-.18)],[.23,.17],skin,arm)
  s.organic(a,'Hand',(side*.22,-1.04,-.19),(.17,.20,.12),skin,arm,segments=28)
  for finger in range(4):
   x=side*(.13+finger*.075)
   f.beam(a,'Finger',[(x,-1.07,-.21),(x,-1.22,-.24),(x-side*.025,-1.28,-.26)],[.035,.03,.017],skin,arm)
  f.beam(a,'Thumb',[(side*.12,-.99,-.20),(side*.04,-1.10,-.27)],[.05,.028],skin,arm)
  leg=a.node('Leg'+str(side),body,(side*.39,.56,.06))
  f.beam(a,'Thigh',[(0,0,0),(side*.025,-.27,.02),(side*.03,-.55,-.01)],[.33,.29,.24],skin,leg)
  f.beam(a,'Calf',[(side*.03,-.48,-.01),(side*.02,-.80,-.05)],[.24,.16],skin,leg)
  s.organic(a,'Foot',(side*.02,-.87,-.18),(.20,.11,.32),skin,leg,segments=28)
 s.organic(a,'NoseBridge',(0,2.66,-.421),(.065,.11,.063),skin,head,segments=32)
 s.organic(a,'NoseTip',(0,2.60,-.478),(.092,.046,.055),skin,head,segments=32)
 f.beam(a,'Mouth', [(-.12,2.48,-.438),(0,2.497,-.467),(.12,2.48,-.438)],[.01,.014,.01],lip,head)
 s.organic(a,'LowerLip',(0,2.475,-.454),(.09,.021,.018),shade,head,segments=24)
 a.doc["nodes"][root]["scale"]=[3/2.85]*3
 a.doc["nodes"][root]["translation"]=[0,-.18*3/2.85,0]
 return a.save()

if __name__=='__main__': print(build())

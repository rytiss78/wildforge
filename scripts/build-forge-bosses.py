"""Eight original uncanny bosses. Shared GLB writer, authored silhouettes/joints.
Every model is normalized to exactly three metres before runtime scaling.
"""
import importlib.util,json,math
from pathlib import Path
sp=importlib.util.spec_from_file_location('forge',Path(__file__).with_name('build-forge-slice.py'))
f=importlib.util.module_from_spec(sp);sp.loader.exec_module(f)
s=f.s;sin=math.sin;cos=math.cos
I='16243c';S='689e99';G='efbb58';B='f4e4b7';R='b9365b';E='64ffc1'

def mask(a,parent,p,wide=.2):
 f.slab(a,'Mask',[(-wide,0),(-wide*.8,.3),(0,.42),(wide*.8,.3),(wide,0),(0,-.16)],.13,B,parent,p)
 for side in [-1,1]:f.plate(a,'EyeSlit',(p[0]+side*wide*.45,p[1]+.19,p[2]-.08),(wide*.42,.025,.03),I,parent)

def limb(a,parent,side,height=1.6,span=.42):
 n=a.node('Leg'+str(side),parent,(side*span,height,0))
 f.beam(a,'LongShin',[(0,0,0),(side*.18,-height*.55,.12),(side*.08,-height+.08,-.08)],[.10,.065,.035],S,n)
 f.plate(a,'Hoof',(side*.08,-height+.05,-.15),(.19,.10,.4),I,n)
 return n

def cage(a,parent,cy=1.5,width=.50):
 f.core(a,parent,(0,cy,-.03),.33)
 for side in [-1,1]:
  f.beam(a,'OpenRib',[(side*.1,cy-.43,0),(side*width,cy-.22,.04),(side*width,cy+.28,.04),(side*.15,cy+.50,0)],[.05,.075,.07,.04],B,parent)
  f.beam(a,'GiltRib',[(side*.12,cy-.40,-.05),(side*(width-.04),cy-.20,-.08),(side*(width-.04),cy+.25,-.08)],[.014,.022,.015],G,parent)

def boss(index):
 a=f.Asset('boss_'+str(index));root=a.node('BossRoot');body=a.node('Body',root);head=a.node('Head',body)
 if index==0: # Signal-tower giant: forked acoustic crown, cable spine, long arms.
  for side in [-1,1]:
   limb(a,body,side,1.45,.23)
   arm=a.node('Arm'+str(side),body,(side*.37,2.13,0))
   f.beam(a,'HangingCableArm',[(0,0,0),(side*.17,-.8,.05),(side*.28,-1.51,-.10)],[.065,.045,.02],I,arm)
   for finger in range(3):f.beam(a,'WireFinger',[(side*.28,-1.51,-.10),(side*(.22+finger*.055),-1.72,-.19)],[.015,.003],B,arm)
  cage(a,body,1.68,.37)
  f.beam(a,'CableSpine',[(0,1.19,.2),(.05,2.27,.12),(0,2.70,.08)],[.12,.08,.065],I,body)
  for j in range(7):f.plate(a,'Vertebra',(0,1.23+j*.20,.24),(.20,.04,.06),G,body)
  for side in [-1,1]:
   p=(side*.35,2.7,0)
   f.slab(a,'Resonator',[(-.27,-.14),(-.31,.23),(-.15,.32),(.22,.25),(.29,-.14)],.30,S,head,p)
   f.slab(a,'BlackThroat',[(-.21,-.09),(-.23,.18),(-.12,.24),(.16,.18),(.21,-.09)],.035,I,head,(p[0],p[1],-.18))
   for line in range(4): f.plate(a,'ResonatorGrille',(p[0]-.15+line*.10,p[1]+.055,-.207),(.02,.22,.018),G,head)
  f.beam(a,'Aerial',[(0,2.6,.08),(.02,3.14,.08)],[.02,.002],G,head)
 elif index==1: # Bell-crowned stilt walker.
  for side in [-1,1]:limb(a,body,side,1.35,.48)
  cage(a,body,1.57,.44)
  s.profile(a,'GreatBell',[(1.93,.70,.55,0),(2.03,.72,.57,0),(2.15,.47,.39,0),(2.67,.32,.30,0),(2.85,.04,.04,0)],G,head,segments=12)
  s.profile(a,'BellLip',[(1.88,.75,.58,0),(1.98,.75,.58,0)],I,head,segments=12)
  for i in range(7):
   x=(i-3)*.20
   f.beam(a,'Chain',[(x,1.93,-.29),(x+.05,.85+abs(x)*.3,-.3)],[.015,.015],B,body)
  f.slab(a,'CrownTines',[(-.4,2.58),(-.43,3.02),(-.12,2.76),(0,3.20),(.12,2.76),(.43,3.02),(.4,2.58)],.14,I,head)
 elif index==2: # Ribbed lantern sentinel, wide shoulders and hooked halberds.
  for side in [-1,1]:
   limb(a,body,side,1.0,.40)
   arm=a.node('Arm'+str(side),body,(side*.62,1.88,0))
   f.beam(a,'HalberdArm',[(0,0,0),(side*.28,-.45,0),(side*.32,-1.56,-.16)],[.15,.09,.03],S,arm)
   f.slab(a,'HookBlade',[(side*.25,-.65),(side*.71,-.50),(side*.64,-1.16),(side*.33,-.99)],.12,G,arm)
  cage(a,body,1.4,.65)
  for side in [-1,1]:f.slab(a,'LanternShoulder',[(side*.2,2.02),(side*.8,2.18),(side*.69,1.70),(side*.45,1.85)],.4,I,body)
  f.slab(a,'Hood',[(-.35,2.03),(-.31,2.65),(0,3.06),(.31,2.65),(.35,2.03)],.46,I,head)
  mask(a,head,(0,2.35,-.26),.17)
  f.plate(a,'HaloCross',(0,2.52,.02),(.95,.05,.06),G,head)
 elif index==3: # Hollow procession: three masks carried on an architectural arch.
  cage(a,body,1.25,.52)
  for side in [-1,1]:
   limb(a,body,side,1.15,.66)
   f.beam(a,'ProcessionArch',[(side*.72,.85,0),(side*.80,2.3,0),(side*.5,2.78,0),(0,2.97,0)],[.14,.13,.12,.04],S,body)
   for j in range(4):f.plate(a,'ArchInlay',(side*.80,1.0+j*.35,-.13),(.09,.20,.018),G,body)
  for i in range(3):
   p=((i-1)*.43,2.28-abs(i-1)*.14,-.16);mask(a,head,p,.17)
   f.beam(a,'Suspension',[(p[0],2.77,0),(p[0],p[1]+.3,0)],[.017,.017],G,head)
  f.slab(a,'FuneralDrape',[(-.58,1.03),(-.38,.3),(0,.7),(.38,.3),(.58,1.03)],.13,R,body,(0,0,.26))
 elif index==4: # Many-jointed watcher, wide low strider with asymmetrical eyes.
  cage(a,body,1.1,.47)
  for side in [-1,1]:
   for j in range(3):
    n=a.node('Leg'+str(side)+'_'+str(j),body,(side*.28,1.2,(j-1)*.23))
    f.beam(a,'WatcherLimb',[(0,0,0),(side*(.52+j*.13),.45,.1),(side*(.72+j*.15),-.65,.20),(side*(.99+j*.12),-1.16,-.03)],[.07,.085,.05,.008],B,n)
    s.organic(a,'Knee',(side*(.52+j*.13),.45,.1),(.1,.1,.1),G,n,segments=10)
  for j in range(5):
   p=((j-2)*.20,1.95+(.7 if j==2 else .30 if j%2 else 0),-.02)
   f.beam(a,'EyeStalk',[(0,1.35,.20),(p[0],p[1],p[2])],[.06,.035],I,head)
   mask(a,head,p,.14)
   s.organic(a,'Iris',(p[0],p[1]+.06,-.13),(.05,.08,.025),E,head,segments=12)
 elif index==5: # Drowned spire: coiled masonry tower and trailing kelp, no humanoid head.
  cage(a,body,1.28,.43)
  for side in [-1,1]:limb(a,body,side,.7,.43)
  for j in range(7):
   y=1.53+j*.19;w=.48-j*.049;x=sin(j*.55)*.12
   f.slab(a,'SunkMasonry',[(-w,y),(-w*.8,y+.22),(w*.7,y+.27),(w,y)],.43,S,head,(x,0,.15))
   f.plate(a,'SpireSlit',(x,y+.13,-.09),(w*.8,.025,.02),E,head)
  for side in [-1,1]:
   for j in range(3):
    n=a.node('Tentacle'+str(side)+'_'+str(j),body)
    f.beam(a,'KelpRibbon',[(side*.3,1.9,.13),(side*(.55+j*.11),1.4,-.06),(side*(.5+j*.14),.35,.05)],[.075,.06,.002],R if j==1 else I,n)
  f.beam(a,'BrokenSpire',[(.01,2.68,.14),(-.1,3.15,.05)],[.17,.001],G,head)
 elif index==6: # Hanging maw: overhead gallows suspends an oversized toothed jaw.
  for side in [-1,1]:
   limb(a,body,side,2.4,.84)
   f.beam(a,'Gallows',[(side*.84,2.4,0),(side*.70,2.86,0),(0,3.0,0)],[.15,.15,.1],I,body)
   f.beam(a,'JawChain',[(side*.6,2.83,-.1),(side*.5,1.63,-.1)],[.025,.025],G,head)
  f.core(a,body,(0,2.37,-.1),.28)
  f.slab(a,'UpperMaw',[(-.7,1.90),(-.64,2.10),(.64,2.10),(.7,1.90),(.4,1.83),(-.4,1.83)],.57,S,head)
  jaw=a.node('Jaw',body)
  f.slab(a,'LowerMaw',[(-.70,1.45),(-.55,1.18),(0,1.05),(.55,1.18),(.70,1.45),(.38,1.32),(-.38,1.32)],.54,R,jaw)
  for j in range(9):
   x=(j-4)*.135
   f.beam(a,'UpperTooth',[(x,1.9,-.24),(x*.98,1.58+(j%2)*.08,-.26)],[.045,.001],B,head)
   f.beam(a,'LowerTooth',[(x,1.32,-.25),(x,1.56,-.26)],[.038,.001],B,jaw)
 elif index==7: # Antlered monument: squat stone torso, four root legs, huge branching crown.
  cage(a,body,1.27,.55)
  for side in [-1,1]:
   for j in range(2):
    n=a.node('Leg'+str(side)+'_'+str(j),body)
    f.beam(a,'RootButtress',[(side*.32,1.05,.1),(side*.65,.4,(j-.5)*.45),(side*.9,.04,(j-.5)*.8)],[.17,.11,.01],S,n)
   f.beam(a,'AntlerStem',[(side*.18,1.95,0),(side*.47,2.30,0),(side*.8,2.62,0),(side*1.02,3.15,.05)],[.15,.11,.06,.002],B,head)
   for j in range(3):
    f.beam(a,'AntlerTine',[(side*(.39+j*.2),2.24+j*.23,0),(side*(.26+j*.18),2.77+j*.15,-.08)],[.055,.003],G,head)
  mask(a,head,(0,1.97,-.16),.26)
  for side in [-1,1]:f.slab(a,'MonumentPauldrons',[(side*.25,1.7),(side*.75,1.9),(side*.8,1.35),(side*.48,1.05)],.58,I,body)
 # Compute authored scene bounds from accessor bounds and cumulative translations.
 lo=1e9;hi=-1e9
 def visit(n,offset=0):
  nonlocal lo,hi
  node=a.doc['nodes'][n];y=offset+node.get('translation',[0,0,0])[1]
  if 'mesh' in node:
   for prim in a.doc['meshes'][node['mesh']]['primitives']:
    accessor=a.doc['accessors'][prim['attributes']['POSITION']];lo=min(lo,y+accessor['min'][1]);hi=max(hi,y+accessor['max'][1])
  for child in node.get('children',[]):visit(child,y)
 visit(root);scale=3/(hi-lo);a.doc['nodes'][root]['scale']=[scale]*3;a.doc['nodes'][root]['translation']=[0,-lo*scale,0]
 report=a.save();report['reference_height']=3;return report

if __name__=='__main__':
 report=[boss(i) for i in range(8)]
 (s.OUT/'forge-boss-manifest.json').write_text(json.dumps({'generator':'scripts/build-forge-bosses.py','assets':report},indent=2)+'\n',encoding='utf8')
 print(json.dumps(report,indent=2))

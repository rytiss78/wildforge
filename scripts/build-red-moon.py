"""Original Red Moon expansion models. Only writes the fifteen named new assets."""
import importlib.util,json,math
from pathlib import Path
spec=importlib.util.spec_from_file_location('forge',Path(__file__).with_name('build-forge-slice.py'))
f=importlib.util.module_from_spec(spec);spec.loader.exec_module(f)
s=f.s;I=f.INK;B=f.BONE;G=f.GOLD;R=f.RED;E=f.GREEN

def normalize(a,root,height):
 bounds=[]
 def visit(n,y=0):
  node=a.doc['nodes'][n];y+=node.get('translation',[0,0,0])[1]
  if 'mesh' in node:
   for p in a.doc['meshes'][node['mesh']]['primitives']:
    accessor=a.doc['accessors'][p['attributes']['POSITION']];bounds.extend([y+accessor['min'][1],y+accessor['max'][1]])
  for child in node.get('children',[]):visit(child,y)
 visit(root);lo,hi=min(bounds),max(bounds);scale=height/(hi-lo)
 a.doc['nodes'][root]['scale']=[scale]*3;a.doc['nodes'][root]['translation']=[0,-lo*scale,0]

def hero(kind):
 a=f.Asset('hero_'+kind);root=a.node('Root');body=a.node('Body',root);head=a.node('Head',body)
 if kind=='white-supra':
  # Low white coupe, broad bonnet, rear wing and four wheel arches; no logos.
  f.plate(a,'Chassis',(0,.32,0),(1.32,.35,2.45),I,body)
  f.plate(a,'WhiteBonnet',(0,.58,-.67),(1.38,.23,1.06),'eeebdc',body)
  f.slab(a,'Cabin',[(-.49,.67),(-.39,.96),(.39,.96),(.51,.67)],.91,'dadbca',body,(0,0,.23))
  f.plate(a,'Windshield',(0,.84,-.235),(.89,.21,.035),'163f53',body)
  f.plate(a,'RearDeck',(0,.57,.9),(1.36,.22,.45),'eeebdc',body)
  for side in [-1,1]:
   for z in [-.76,.78]:
    s.organic(a,'Wheel',(side*.67,.28,z),(.22,.28,.28),I,body,segments=12)
    f.plate(a,'AlloyHub',(side*.86,.28,z),(.018,.26,.24),G,body)
   f.plate(a,'Headlamp',(side*.43,.57,-1.21),(.35,.1,.025),E,body)
   f.plate(a,'WingPylon',(side*.46,.79,.95),(.065,.42,.07),I,body)
   arm=a.node('Arm'+str(side),body,(side*.51,.65,.98));a.node('HandSocket'+str(side),arm,(0,0,0))
  f.plate(a,'RearWing',(0,1.03,.95),(1.65,.09,.34),I,body)
  f.core(a,body,(0,.71,-.76),.3)
 else:
  coat={'ninja':I,'smoker':'67776d','alcoholic':'773751'}[kind]
  wide=.33 if kind=='ninja' else .38 if kind=='smoker' else .53
  f.core(a,body,(0,.88,-.16),.28)
  for side in [-1,1]:
   f.slab(a,'SplitCoat',[(side*.13,.43),(side*(wide+.14),.34),(side*wide,1.27),(side*.13,1.2)],.36,coat,body,(0,0,.1))
   leg=a.node('Leg'+str(side),body,(side*.2,.43,0))
   f.beam(a,'Boot',[(0,0,0),(0,-.28,0),(0,-.32,-.13)],[.10,.08,.12],I,leg)
   arm=a.node('Arm'+str(side),body,(side*wide,1.15,0))
   f.beam(a,'Sleeve',[(0,0,0),(side*.08,-.25,0),(side*.03,-.42,-.16)],[.12,.10,.08],coat,arm)
   a.node('HandSocket'+str(side),arm,(side*.03,-.42,-.18))
  s.organic(a,'Skull',(0,1.5,0),(.26,.3,.25),B if kind!='ninja' else I,head,segments=10)
  if kind=='ninja':
   f.plate(a,'Mask',(0,1.49,-.235),(.46,.17,.035),R,head)
   for side in [-1,1]:f.plate(a,'Eye',(side*.11,1.55,-.27),(.11,.035,.02),E,head)
   cape=a.node('Cape',body);f.slab(a,'Scarf',[(-.13,1.36),(-.75,1.51),(-1.0,1.25),(-.63,1.3),(-.12,1.18)],.055,R,cape,(0,0,.26))
  elif kind=='smoker':
   f.plate(a,'HatBrim',(0,1.75,0),(.72,.08,.64),I,head)
   f.plate(a,'ChimneyHat',(0,1.99,.04),(.36,.46,.36),I,head)
   for j in range(3):s.organic(a,'AshSmoke',(math.sin(j)*.13,2.27+j*.15,.03),(.12+j*.035,.13,.1),'a4b8a0',head,segments=8)
   f.beam(a,'LongPipe',[(.16,1.39,-.2),(.43,1.35,-.42),(.45,1.57,-.43)],[.04,.035,.07],G,head)
   f.plate(a,'HollowEyes',(0,1.54,-.246),(.31,.035,.022),I,head)
  else:
   f.slab(a,'CrookedCap',[(-.3,1.69),(-.23,1.9),(.16,1.82),(.34,1.67)],.42,I,head)
   f.plate(a,'Nose',(0,1.47,-.26),(.13,.17,.16),R,head)
   for side in [-1,1]:f.plate(a,'TiredEye',(side*.14,1.58,-.235),(.13,.035,.02),I,head)
   for side in [-1,1]:f.plate(a,'FlaskPouch',(side*.45,.68,-.14),(.17,.28,.2),G,body)
 normalize(a,root,1.65);return a.save()

def creature(biome):
 a=f.Asset('creature_'+str(biome)+'_6');root=a.node('Root');body=a.node('Body',root);head=a.node('Head',body)
 colors=['65968e','739649','8194ad','c5e0e1','c25439','9272b6'];c=colors[biome]
 f.core(a,body,(0,.97,-.22),.26)
 # Six distinct silhouettes: bell on stilts, hunched reed listener, stone eye,
 # hanging veil, enormous jaw crawler, and a radial antenna widow.
 if biome==0:
  for side in [-1,1]:
   f.beam(a,'Stilt',[(side*.22,1.2,0),(side*.45,.7,.03),(side*.4,.02,-.13)],[.09,.055,.016],B,body)
   f.beam(a,'Antler',[(side*.19,1.75,0),(side*.5,2.02,0),(side*.64,2.36,0)],[.08,.04,.003],G,head)
  f.slab(a,'Bell',[(-.5,1.25),(-.3,1.87),(0,2.05),(.3,1.87),(.5,1.25),(.3,1.34),(-.3,1.34)],.43,c,head)
  f.plate(a,'FaceVoid',(0,1.6,-.235),(.25,.33,.03),I,head)
 elif biome==1:
  f.beam(a,'HunchedBack',[(0,.4,.3),(0,1.3,.45),(0,1.72,-.25)],[.34,.43,.19],c,body)
  for side in [-1,1]:
   f.beam(a,'LongForearm',[(side*.3,1.35,0),(side*.8,.66,-.16),(side*.61,.08,-.5)],[.13,.08,.02],B,body)
   for j in range(3):f.beam(a,'ListeningReed',[(side*.18,1.55,0),(side*(.4+j*.1),1.9+j*.18,.1)],[.03,.006],G,head)
  f.plate(a,'BlindBand',(0,1.62,-.42),(.43,.12,.035),I,head)
 elif biome==2:
  s.loop(a,'BrokenEye',(0,1.68,0),.57,.16,c,head)
  f.plate(a,'VerticalPupil',(0,1.67,-.08),(.07,.55,.05),E,head)
  for side in [-1,1]:
   f.beam(a,'Tripod',[(side*.3,1.15,.1),(side*.67,.6,.1),(side*.82,.03,-.2)],[.18,.12,.035],I,body)
  f.beam(a,'RearFoot',[(0,1.1,.22),(0,.04,.8)],[.15,.03],I,body)
 elif biome==3:
  for j in range(6):
   x=(j-2.5)*.2
   f.slab(a,'Veil',[(x-.12,1.8),(x+.15,2.13),(x+.12,.48+(j%2)*.3),(x-.1,.16)],.07,c if j%2 else I,body,(0,0,.2+j*.015))
  f.plate(a,'AbsentFace',(0,1.65,-.03),(.3,.28,.04),I,head)
  for side in [-1,1]:f.beam(a,'HangingHand',[(side*.44,1.5,0),(side*.78,.75,-.2),(side*.8,.3,-.4)],[.06,.035,.006],B,body)
 elif biome==4:
  f.slab(a,'GreatJaw',[(-.68,1.5),(-.5,1.07),(0,.88),(.5,1.07),(.68,1.5),(.44,1.32),(-.44,1.32)],.54,c,head)
  for j in range(9):
   x=(j-4)*.12;f.beam(a,'GrinTooth',[(x,1.28,-.26),(x,1.6-(j%2)*.12,-.26)],[.04,.002],B,head)
  for side in [-1,1]:
   for z in [-.2,.4]:f.beam(a,'CrawlerArm',[(side*.3,.96,z),(side*.84,.55,z),(side*.76,.03,z-.25)],[.1,.065,.015],I,body)
 else:
  for j in range(6):
   angle=j*math.tau/6;x,z=math.sin(angle),math.cos(angle)
   f.beam(a,'SpiderAntenna',[(x*.2,.95,z*.2),(x*.87,1.55,z*.7),(x*1.05,.03,z*.85)],[.09,.055,.008],c,body)
   f.plate(a,'Receiver',(x*.86,1.52,z*.7),(.12,.13,.12),G,body)
  f.slab(a,'SignalMask',[(-.28,1.4),(0,2.15),(.28,1.4),(0,1.15)],.24,I,head)
  for j in range(4):f.plate(a,'SignalSlit',(0,1.42+j*.12,-.14),(.26-j*.045,.025,.025),E,head)
 normalize(a,root,1.65);return a.save()

def boss():
 a=f.Asset('boss_8');root=a.node('Root');body=a.node('Body',root);head=a.node('Head',body)
 # A ruined cathedral carried by six skeletal stilts. No sphere torso or circular crown.
 # The small abdominal blood vessel is the only rounded focal shape.
 slate='243041';rust='704135';bone='c6b69a';gilt='bb8351';hot='ee6248'
 f.core(a,body,(0,2.16,-.57),.30)
 f.beam(a,'BrokenSpine',[(0,1.65,.3),(0,2.8,.5),(0,3.65,.32),(0,4.18,.12)],[.22,.3,.24,.14],slate,body)
 for side in [-1,1]:
  # Hollow breast armour: a pointed cage around the orb, rather than an orb-shaped body.
  f.slab(a,'BreastPlate',[(side*.25,1.73),(side*.78,2.17),(side*.9,3.2),(side*.4,3.8),(side*.16,3.16),(side*.44,2.78)],.58,slate,body,(0,0,.05))
  f.beam(a,'GiltRibEdge',[(side*.28,1.82,-.43),(side*.65,2.23,-.43),(side*.73,3.15,-.36),(side*.4,3.55,-.28)],[.022,.034,.025,.009],gilt,body)
  for rib in range(5):
   y=2.52+rib*.2
   f.beam(a,'ExposedRib',[(side*.14,y,-.22),(side*(.57+rib*.035),y-.14,-.50),(side*(.72+rib*.02),y+.06,.02)],[.038,.052,.025],bone,body)
  # Three articulated legs each side; splayed claws visibly anchor the immense mass.
  for j in range(3):
   z=(j-1)*.83;hip=(side*.67,2.58,z*.5);leg=a.node('Leg'+str(side)+'_'+str(j),body,hip)
   f.beam(a,'ShinBone',[(0,0,0),(side*.72,-.95,z*.42),(side*1.02,-2.40,z*.64)],[.18,.13,.065],bone,leg)
   f.slab(a,'KneeBlade',[(side*.52,-.65),(side*.88,-.93),(side*.78,-1.62),(side*.65,-1.05)],.25,slate,leg)
   f.beam(a,'ShinEtching',[(side*.73,-1.03,-.13+z*.42),(side*.99,-2.3,-.1+z*.64)],[.022,.012],gilt,leg)
   for toe in range(3):
    f.beam(a,'TalonedFoot',[(side*1.02,-2.4,z*.64),(side*(1.22+toe*.08),-2.53,z*.64-.18+toe*.18),(side*(1.41+toe*.10),-2.53,z*.64-.38+toe*.24)],[.065,.04,.001],slate,leg)
  # Asymmetric elongated execution arms, blade fingers, and carved shoulder batteries.
  arm=a.node('Arm'+str(side),body,(side*.95,3.42,0))
  length=1.0 if side==1 else 1.19
  f.beam(a,'ExecutionArm',[(0,0,0),(side*.72,-.45,-.12),(side*.55,-1.70*length,-.6)],[.24,.19,.12],slate,arm)
  f.beam(a,'ArmBoneInlay',[(side*.10,-.10,-.23),(side*.65,-.51,-.30),(side*.53,-1.59*length,-.73)],[.025,.032,.013],bone,arm)
  f.slab(a,'ShoulderBlade',[(-.35,-.12),(-.46,.38),(-.2,.68),(.19,.58),(.44,.13),(.2,-.24)],.7,rust,arm)
  for digit in range(4):
   x=side*(.39+digit*.13);y=-1.64*length
   f.beam(a,'BladeFinger',[(x,y,-.56),(x+side*.05,y-.42,-.73),(x-side*.11,y-.68,-.88)],[.055,.035,.001],bone,arm)
  for barrel in range(3):
   x=side*(.15+barrel*.19)
   f.slab(a,'CannonShroud',[(-.1,-.12),(-.13,.16),(0,.27),(.13,.16),(.1,-.12)],.67,slate,arm,(x,.2,-.38))
   f.plate(a,'CannonBore',(x,.24,-.723),(.09,.13,.015),hot,arm)
  # Serrated flying buttress silhouettes rising behind the skull; different break heights.
  for tower in range(3):
   x=side*(.52+tower*.32);h=5.7-tower*.46+(0.27 if side==1 and tower==1 else 0)
   f.slab(a,'CathedralSpire',[(x-side*.17,3.1),(x-side*.17,h-.56),(x,h),(x+side*.14,h-.7),(x+side*.25,3.35)],.35,slate,body,(0,0,.62+tower*.09))
   f.slab(a,'SpireFacet',[(x,3.45),(x,h-.1),(x+side*.1,h-.71),(x+side*.15,3.5)],.02,rust,body,(0,0,.425+tower*.09))
   for pane in range(3):f.plate(a,'SpireSlit',(x,3.78+pane*.31,.407+tower*.09),(.037,.17,.016),hot,body)
  for shard in range(4):
   x=side*(.46+shard*.26)
   f.slab(a,'ShatteredRobe',[(x,3.25),(x+side*.24,3.42),(x+side*.34,1.8-shard*.12),(x+side*.14,2.06),(x,1.64)],.045,rust,body,(0,0,.88))
 # Long faceted skull, split jaw, asymmetric horns and tiny hostile eyes.
 f.slab(a,'SkullMask',[(-.39,4.69),(-.52,4.23),(-.27,3.88),(0,3.71),(.31,3.91),(.48,4.27),(.23,4.75)],.72,bone,head,(0,0,-.2))
 f.slab(a,'MaskShadow',[(-.1,4.67),(-.19,4.13),(0,3.8),(.17,4.15),(.04,4.7)],.025,slate,head,(0,0,-.578))
 for side in [-1,1]:
  f.slab(a,'EyeSocket',[(side*.1,4.38),(side*.37,4.48),(side*.30,4.19),(side*.08,4.2)],.03,slate,head,(0,0,-.583))
  f.beam(a,'BurningEye',[(side*.12,4.30,-.61),(side*.28,4.36,-.61)],[.026,.011],hot,head)
  f.beam(a,'BrokenAntler',[(side*.32,4.6,0),(side*.72,4.98,.1),(side*.84,5.53,.02),(side*1.0,5.82 if side==1 else 5.45,-.12)],[.11,.08,.045,.001],bone,head)
  f.beam(a,'AntlerHook',[(side*.69,4.95,.1),(side*1.01,5.14,.03),(side*1.15,5.48,-.12)],[.055,.045,.001],slate,head)
  f.beam(a,'LowerMandible',[(side*.25,4.0,-.47),(side*.31,3.72,-.5),(side*.07,3.58,-.68)],[.075,.06,.008],bone,head)
  for tooth in range(3):f.beam(a,'IronTooth',[(side*(.09+tooth*.065),3.91+tooth*.07,-.59),(side*(.08+tooth*.055),3.69+tooth*.1,-.63)],[.027,.001],slate,head)
 normalize(a,root,3);return a.save()

def weapon(kind):
 a=f.Asset('weapon_'+kind);root=a.node('Body')
 if kind=='ninja-shuriken':
  for j in range(4):
   angle=j*math.pi/2;cx,cy=math.cos(angle),math.sin(angle)
   f.slab(a,'StarBlade',[(cx*.05-cy*.1,cy*.05+cx*.1),(cx*.53-cy*.08,cy*.53+cx*.08),(cx*.2+cy*.06,cy*.2-cx*.06)],.07,B,root,(0,.15,-.25))
  s.loop(a,'StarHub',(0,.15,-.3),.10,.025,G,root)
 elif kind=='smoke-censer':
  f.plate(a,'Grip',(0,-.1,.03),(.13,.32,.15),I,root)
  s.organic(a,'Censer',(0,.18,-.23),(.22,.26,.25),'66896d',root,segments=10)
  for z in [-.4,-.23,-.06]:f.plate(a,'CageBand',(0,.2,z),(.47,.07,.035),G,root)
  f.beam(a,'Chimney',[(0,.32,-.23),(0,.52,-.31),(0,.53,-.57)],[.09,.075,.09],I,root)
 elif kind=='bottle-barrage':
  s.organic(a,'Bottle',(0,.05,-.13),(.19,.3,.18),'b07b39',root,segments=10)
  f.plate(a,'Neck',(0,.43,-.13),(.12,.28,.12),'678857',root)
  f.plate(a,'Label',(0,.02,-.315),(.26,.28,.02),B,root)
  f.beam(a,'Fuse',[(0,.56,-.13),(.14,.63,-.16),(.18,.57,-.2)],[.025,.02,.015],R,root)
 else:
  for side in [-1,1]:
   f.plate(a,'Exhaust',(side*.13,.08,-.22),(.18,.2,.62),I,root)
   f.plate(a,'ChromeLip',(side*.13,.08,-.54),(.22,.24,.065),B,root)
   f.plate(a,'FlameBore',(side*.13,.08,-.58),(.13,.15,.025),R,root)
  f.plate(a,'HeatShield',(0,.23,-.15),(.52,.05,.44),G,root)
 a.node('Muzzle',root,(0,.12,-.62));return a.save()

if __name__=='__main__':
 reports=[hero(k) for k in ['ninja','smoker','alcoholic','white-supra']]+[creature(i) for i in range(6)]+[boss()]+[weapon(k) for k in ['ninja-shuriken','smoke-censer','bottle-barrage','supra-backfire']]
 (s.OUT/'red-moon-manifest.json').write_text(json.dumps(reports,indent=2)+'\n',encoding='utf8');print('Authored',len(reports),'new models')

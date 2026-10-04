"""Original orb-first articulated 3D heroes. No sprite conversion or mesh cutting."""
import importlib.util
import json
import math
from pathlib import Path

spec=importlib.util.spec_from_file_location('world',Path(__file__).with_name('build-world-models.py'))
w=importlib.util.module_from_spec(spec);spec.loader.exec_module(w)
A=w.A;organic=w.organic;profile=w.profile;sweep=w.sweep;loop=w.loop;solid=w.solid
sin=math.sin;cos=math.cos;TAU=math.tau

def arc(a,name,parent,radius,tube,color,start=0,end=TAU,z=0,y=.82):
    points=[(sin(start+(end-start)*i/32)*radius,y+cos(start+(end-start)*i/32)*radius,z) for i in range(33)]
    return sweep(a,name,points,[tube]*33,[tube]*33,color,parent)

def eyes(a,parent,y=1.44,z=-.20,gap=.13,size=.09):
    for side in [-1,1]:
        organic(a,'Eye'+str(side),(side*gap,y,z),(size,size*1.16,.045),'fff0d2',parent,segments=16)
        organic(a,'Pupil'+str(side),(side*gap+.014,y-.014,z-.044),(size*.38,size*.52,.02),'35303c',parent,segments=12)
        organic(a,'Spark'+str(side),(side*gap-.006,y+.012,z-.06),(.012,.013,.008),'ffffff',parent,segments=8)

def limbs(a,body,color,feet_color=None,kind='boots'):
    for side in [-1,1]:
        leg=a.node('Leg'+str(side),body,(side*.25,.36,.02))
        sweep(a,'Shin'+str(side),[(0,0,0),(side*.02,-.15,0),(side*.03,-.24,-.03)],[.075,.065,.06],[.08,.07,.07],color,leg)
        organic(a,'Foot'+str(side),(side*.025,-.27,-.09),(.18 if kind=='web' else .13,.09,.25 if kind=='web' else .19),feet_color or color,leg,segments=16)

def arms(a,body,color,kind='gloves'):
    for side in [-1,1]:
        arm=a.node('Arm'+str(side),body,(side*.48,1.02,.04))
        sweep(a,'UpperArm'+str(side),[(0,0,0),(side*.08,-.14,-.02),(side*.09,-.29,-.10)],[.09,.08,.065],[.095,.08,.065],color,arm)
        organic(a,'Elbow'+str(side),(side*.08,-.16,-.02),(.085,.085,.085),color,arm,segments=12)
        organic(a,'Glove'+str(side),(side*.09,-.35,-.15),(.11,.10,.11),color,arm,segments=16)
        for finger in range(3): organic(a,'Finger%s_%s'%(side,finger),(side*.09+(finger-1)*.045,-.38,-.23),(.027,.055,.025),color,arm,segments=8)
        a.node('HandSocket'+str(side),arm,(side*.09,-.32,-.23))

def orb(a,body):
    socket=a.node('CoreSocket',body,(0,.82,0))
    organic(a,'GlassCore',(0,0,0),(.335,.335,.335),'91cfc7',socket,segments=40)
    # The chassis is authored around this volume; nothing is cut out afterwards.

def build(identity):
    a=A('count_duck' if identity=='rubber_duck_toy' else 'hero_'+identity)
    body=a.node('Body');head=a.node('Head',body);orb(a,body)
    color='a7aabb';boot='6c6262'
    if identity=='pipe_wrench':
        color='be825e';boot='668a92'
        arc(a,'GearBody',body,.41,.075,'7b9aa0')
        for i in range(12):
            angle=i*TAU/12;solid(a,'GearTooth'+str(i),(sin(angle)*.47,.82+cos(angle)*.47,0),(.13,.13,.16),'bd9a67',body)
        solid(a,'WrenchHeadStem',(0,1.44,0),(.22,.46,.20),'9bb4b9',head)
        for side in [-1,1]:
            solid(a,'Jaw'+str(side),(side*.19,1.65,0),(.18,.33,.20),'9bb4b9',head)
            solid(a,'JawTip'+str(side),(side*.14,1.82,0),(.22,.10,.20),'9bb4b9',head)
        eyes(a,head,1.48,-.13,.085,.065)
        solid(a,'ToolBelt',(0,.41,0),(.66,.10,.18),'826548',body)
        for i in range(3): solid(a,'PocketBolt'+str(i),((i-1)*.20,.42,-.11),(.10,.12,.08),'c5d4cc',body)
    elif identity=='rubber_duck_toy':
        color='efc264';boot='df9f45'
        for side in [-1,1]: arc(a,'OpenCoat'+str(side),body,.43,.13,'3f354c',.18 if side==1 else math.pi+.18,math.pi-.18 if side==1 else TAU-.18,z=.04)
        organic(a,'DuckHead',(0,1.47,-.02),(.38,.32,.28),'efc264',head,segments=32)
        organic(a,'Bill',(0,1.34,-.32),(.30,.075,.21),'e3a34e',head,segments=24)
        eyes(a,head,1.51,-.27,.19,.105)
        for side in [-1,1]:profile(a,'Fang'+str(side),[(1.26,.002,.002,-.43),(1.38,.032,.035,-.43)],'fff1ce',head,segments=8);a.doc['nodes'][-1]['translation'][0]=side*.13
        cape=a.node('Cape',body)
        for side in [-1,1]:sweep(a,'SplitCape'+str(side),[(side*.44,1.30,.30),(side*.60,.97,.39),(side*.69,.51,.34),(side*.80,.31,.20)],[.16,.20,.21,.07],[.07,.06,.05,.02],'a44758',cape)
        solid(a,'BowTie',(0,1.14,-.24),(.22,.12,.08),'a44758',head)
    elif identity=='sweet_potato':
        color='b9976c';boot='879884'
        for i in range(8):
            angle=i*TAU/8;organic(a,'PotatoRind'+str(i),(sin(angle)*.42,.82+cos(angle)*.42,.02),(.16,.18,.23),'bb966b',body)
            organic(a,'RootKnuckle'+str(i),(sin(angle)*.51,.82+cos(angle)*.51,0),(.08,.08,.09),'d1b083',body,segments=12)
        organic(a,'PotatoHead',(0,1.49,0),(.29,.26,.25),'c5a072',head);eyes(a,head,1.53,-.23,.13,.095)
        for i in range(4):sweep(a,'Sprout'+str(i),[(0,1.67,0),(sin(i*1.8)*.19,1.94,cos(i*1.8)*.12)],[.045,.004],[.035,.002],'8ba67d',head)
        for side in [-1,1]:organic(a,'ShoulderShield'+str(side),(side*.52,1.1,0),(.23,.17,.24),'8dada0',body)
    elif identity=='marble_bust_01':
        color='c0c6bc';boot='9a8799'
        for side in [-1,1]:sweep(a,'RockingChair'+str(side),[(side*.39,.32,.07),(side*.44,.80,.07),(side*.36,1.24,.07)],[.095,.085,.075],[.10,.10,.08],'b5b8b4',body)
        arc(a,'ShawlArch',body,.42,.07,'ae89a1',-1.35,1.35,z=.03)
        organic(a,'GrannyHead',(0,1.53,-.01),(.25,.26,.22),'d1d2c7',head);eyes(a,head,1.55,-.22,.115,.07)
        for i in range(9):organic(a,'HairRoll'+str(i),(sin(i*TAU/9)*.25,1.70+cos(i*TAU/9)*.08,.06),(.09,.09,.09),'eee6d0',head,segments=12)
        for side in [-1,1]:loop(a,'Glasses'+str(side),(side*.115,1.55,-.27),.085,.012,'9c7c51',head)
        organic(a,'CookieNose',(0,1.44,-.25),(.06,.07,.06),'bbaca1',head)
    elif identity=='street_rat':
        color='aa96bb';boot='736386'
        arc(a,'CoinLedger',body,.405,.065,'d7b46c')
        for side in [-1,1]:solid(a,'VestSide'+str(side),(side*.38,.82,.03),(.13,.69,.23),'736187',body)
        organic(a,'RatHead',(0,1.48,0),(.27,.25,.22),color,head)
        for side in [-1,1]:organic(a,'Ear'+str(side),(side*.31,1.73,.03),(.21,.23,.07),color,head);organic(a,'EarPink'+str(side),(side*.31,1.73,-.028),(.14,.16,.017),'d8aab8',head)
        organic(a,'Snout',(0,1.36,-.26),(.14,.08,.19),'c1a2b6',head);eyes(a,head,1.51,-.205,.13,.08)
        sweep(a,'Tail',[(0,.43,.15),(.36,.30,.24),(.65,.39,.17),(.74,.58,.04),(.65,.69,0)],[.05,.047,.035,.023,.003],[.05,.047,.035,.023,.003],color,body)
        solid(a,'TaxBag',(.57,.58,.10),(.24,.30,.22),'d8b17c',body,texture=1)
    elif identity=='hamburger_buns':
        color='dbb077';boot='78959b'
        arc(a,'CroissantBody',body,.415,.12,'cb965e',-.15,TAU-.15)
        for i in range(8):
            angle=i*TAU/8;organic(a,'BreadFold'+str(i),(sin(angle)*.42,.82+cos(angle)*.42,-.08),(.105,.13,.08),'eed097',body,segments=12)
        profile(a,'BreadHead',[(1.25,.21,.18,0),(1.67,.26,.20,0),(1.80,.02,.02,0)],'e4bd80',head,segments=16)
        eyes(a,head,1.50,-.195,.13,.09)
        for i in [-1,0,1]:solid(a,'CrustScore'+str(i),(i*.10,1.69,-.17),(.035,.12,.02),'aa764d',head)
        w.cap(a,head,(0,1.73,0),'839da5',.36)
    elif identity=='florist':
        color='81a478';boot='b48c6f'
        for i in range(9):
            angle=i*TAU/9;organic(a,'BloomPetal'+str(i),(sin(angle)*.44,.82+cos(angle)*.44,.07),(.19,.21,.075),'dfa3b6' if i%2 else 'eed093',body)
        for side in [-1,1]:sweep(a,'Root'+str(side),[(side*.34,.63,0),(side*.32,.43,0),(side*.15,.29,0)],[.07,.065,.02],[.07,.06,.02],color,body)
        organic(a,'BudFace',(0,1.58,0),(.23,.26,.20),'e5c871',head);eyes(a,head,1.61,-.185,.10,.075)
        for i in range(6):organic(a,'CrownLeaf'+str(i),(sin(i*TAU/6)*.18,1.82+cos(i*TAU/6)*.05,0),(.10,.17,.045),color,head,skew=sin(i)*.05)
    elif identity=='teapot':
        color='c3dacd';boot='96ada7'
        arc(a,'ChinaCage',body,.40,.08,color)
        loop(a,'Handle',(.63,.88,.02),.26,.065,'c7dbd0',body)
        sweep(a,'Spout',[(-.36,.72,0),(-.65,.86,0),(-.72,1.17,0),(-.60,1.27,0)],[.13,.12,.095,.085],[.12,.10,.08,.07],color,body)
        profile(a,'LidFace',[(1.24,.20,.18,0),(1.49,.29,.22,0),(1.59,.23,.17,0)],color,head)
        eyes(a,head,1.46,-.22,.13,.08);w.cap(a,head,(0,1.59,0),'d5e6d4',.33)
        organic(a,'LidKnob',(0,1.88,0),(.07,.08,.07),'d2b876',head)
    elif identity=='octopus':
        color='ab8eb9';boot=color
        arc(a,'PirateBelt',body,.42,.10,'866381')
        for i in range(6):
            angle=i*TAU/6;leg=a.node('Leg'+str(i),body,(sin(angle)*.30,.55,cos(angle)*.14))
            sweep(a,'CurledTentacle'+str(i),[(0,0,0),(sin(angle)*.18,-.24,cos(angle)*.12),(sin(angle)*.35,-.43,cos(angle)*.25),(sin(angle)*.44,-.32,cos(angle)*.28)],[.12,.10,.055,.008],[.12,.10,.055,.008],color,leg)
            for j in range(3):organic(a,'Sucker%s_%s'%(i,j),(sin(angle)*(.08+j*.09),-.1-j*.10,-.09),(.035,.025,.025),'d6b4cf',leg,segments=8)
        organic(a,'SquidFace',(0,1.52,0),(.36,.29,.25),color,head);eyes(a,head,1.55,-.24,.17,.095)
        solid(a,'EyePatch',(.17,1.55,-.30),(.20,.16,.03),'443b51',head)
        w.cap(a,head,(0,1.74,0),'443b51',.49)
    elif identity=='astronaut':
        color='d9e1d8';boot='8fa7ad'
        for i in range(4):
            angle=(i+.5)*TAU/4;organic(a,'SuitPod'+str(i),(sin(angle)*.37,.82+cos(angle)*.37,.04),(.17,.16,.20),color,body)
        arc(a,'OxygenGimbal',body,.42,.048,'d8bc7f',z=.05)
        organic(a,'Helmet',(0,1.56,0),(.35,.35,.30),color,head)
        organic(a,'Visor',(0,1.54,-.24),(.27,.23,.10),'70959f',head);eyes(a,head,1.54,-.33,.115,.07)
        for side in [-1,1]:profile(a,'AirTank'+str(side),[(.58,.11,.11,0),(1.1,.11,.11,0)],'90a7ae',body,segments=12);a.doc['nodes'][-1]['translation']=[side*.47,0,.22]
    elif identity=='cactus':
        color='89aa79';boot='8e7459'
        arc(a,'LivingCactus',body,.42,.115,color)
        for i in range(20):
            angle=i*TAU/20;start=(sin(angle)*.51,.82+cos(angle)*.51,0);end=(sin(angle)*.63,.82+cos(angle)*.63,-.02)
            sweep(a,'Spine'+str(i),[start,end],[.022,.001],[.022,.001],'efdeb2',body)
        organic(a,'CactusFace',(0,1.57,0),(.25,.30,.22),color,head);eyes(a,head,1.57,-.215,.12,.085)
        for i in range(5):organic(a,'PinkFlower'+str(i),(sin(i*TAU/5)*.10,1.87+cos(i*TAU/5)*.07,0),(.10,.08,.05),'dc9fb7',head)
    elif identity=='book':
        color='9e86ae';boot='706080'
        for side in [-1,1]:solid(a,'BookSpine'+str(side),(side*.41,.82,0),(.16,.86,.24),'8c749e',body);solid(a,'PageStack'+str(side),(side*.34,.82,-.11),(.09,.70,.12),'ecdcb9',body)
        for y in [.41,1.22]:solid(a,'BookBinding'+str(y),(0,y,0),(.91,.12,.25),'8c749e',body)
        profile(a,'WizardFace',[(1.24,.23,.17,0),(1.66,.21,.17,0)],'b099be',head);eyes(a,head,1.49,-.18,.12,.085)
        profile(a,'WizardHat',[(1.65,.38,.28,0),(1.74,.29,.23,0),(2.10,.01,.01,.12)],'76638a',head,segments=16)
        for i in range(4):solid(a,'Rune'+str(i),((i-1.5)*.18,1.22,-.145),(.05,.065,.025),'d9b978',body)
    elif identity=='snail':
        color='b1c28d';boot='859569'
        arc(a,'OpenShell',body,.44,.11,'c7a07d',z=.06)
        for i in range(11):
            angle=i*TAU/11;organic(a,'ShellRidge'+str(i),(sin(angle)*.46,.82+cos(angle)*.46,.08),(.10,.09,.16),'ab805f',body,segments=12)
        for side in [-1,1]:
            sweep(a,'EyeStalk'+str(side),[(side*.16,1.18,0),(side*.24,1.51,0),(side*.27,1.76,-.05)],[.07,.065,.055],[.07,.06,.05],color,head)
            organic(a,'StalkEye'+str(side),(side*.27,1.77,-.06),(.13,.15,.10),'f4eccd',head)
            organic(a,'StalkPupil'+str(side),(side*.27,1.77,-.15),(.05,.065,.02),'454638',head)
        sweep(a,'SlimeTail',[(0,.37,.07),(0,.22,.39),(0,.18,.64)],[.18,.13,.01],[.18,.12,.01],color,body)
    elif identity=='bee':
        color='dcc269';boot='8c694f'
        arc(a,'HoneyRing',body,.415,.095,'dcbf66')
        for i in range(8):
            angle=i*TAU/8;organic(a,'BlackStripe'+str(i),(sin(angle)*.44,.82+cos(angle)*.44,0),(.08,.075,.10),'615145',body,segments=12)
        for side in [-1,1]:organic(a,'Wing'+str(side),(side*.60,1.2,.24),(.32,.52,.055),'e2e4c8',body);sweep(a,'Antenna'+str(side),[(side*.11,1.71,0),(side*.25,2.0,0)],[.025,.012],[.025,.012],'695442',head)
        organic(a,'BeeHead',(0,1.55,0),(.29,.26,.22),color,head);eyes(a,head,1.56,-.22,.14,.09)
    elif identity=='sushi':
        color='abc08c';boot='67865e'
        arc(a,'SeaweedWrap',body,.43,.12,'446c53')
        for i in range(18):
            angle=i*TAU/18;organic(a,'Rice'+str(i),(sin(angle)*.43,.82+cos(angle)*.43,-.08),(.035,.057,.032),'eee5c6',body,segments=8)
        profile(a,'SushiFace',[(1.30,.24,.18,0),(1.65,.27,.22,0)],'ecdfb7',head,segments=16);eyes(a,head,1.48,-.21,.13,.085)
        solid(a,'SalmonHat',(0,1.71,0),(.65,.16,.43),'df9d88',head)
        for i in range(4):solid(a,'SalmonStripe'+str(i),((i-1.5)*.13,1.80,-.04),(.03,.01,.39),'edc4ad',head)
    elif identity=='mushroom':
        color='d8c9a6';boot='a58c72'
        for side in [-1,1]:sweep(a,'HollowStem'+str(side),[(side*.22,.38,0),(side*.43,.76,0),(side*.31,1.30,0)],[.10,.09,.075],[.12,.09,.08],color,body)
        organic(a,'MushroomFace',(0,1.43,0),(.24,.22,.20),color,head);eyes(a,head,1.45,-.19,.11,.08)
        profile(a,'ChefCap',[(1.63,.61,.48,0),(1.72,.66,.50,0),(1.99,.42,.35,0),(2.08,.02,.02,0)],'b87c69',head)
        for i in range(7):organic(a,'CapSpot'+str(i),(sin(i*2.4)*.45,1.81+(i%2)*.08,cos(i*2.4)*.28),(.07,.035,.05),'e7c796',head,segments=12)
    elif identity=='clock':
        color='bc975c';boot='826d49'
        arc(a,'ClockCase',body,.43,.08,'ad8550')
        for i in range(12):
            angle=i*TAU/12;organic(a,'ClockNumber'+str(i),(sin(angle)*.45,.82+cos(angle)*.45,-.09),(.032,.045,.02),'efe0b5',body,segments=8)
        organic(a,'AlarmHead',(0,1.51,0),(.29,.24,.20),'d9c384',head);eyes(a,head,1.51,-.20,.13,.08)
        for side in [-1,1]:organic(a,'Bell'+str(side),(side*.23,1.74,0),(.17,.11,.16),'c29a59',head)
        sweep(a,'WindUpKey',[(0,1.57,.20),(0,1.57,.39)],[.06,.06],[.06,.06],'ae905f',head)
    elif identity=='icecream':
        color='d5a1b1';boot='b19373'
        arc(a,'WaffleBowl',body,.43,.09,'caab80',math.pi/2,math.pi*1.5)
        for side in [-1,1]:sweep(a,'ConeSide'+str(side),[(side*.27,.39,0),(side*.44,.87,0),(side*.36,1.16,0)],[.085,.08,.05],[.10,.08,.045],'cbab81',body)
        organic(a,'ScoopHead',(0,1.55,0),(.32,.30,.25),'d9adc0',head);eyes(a,head,1.55,-.25,.14,.09)
        organic(a,'Cherry',(0,1.89,0),(.095,.10,.095),'bb6471',head)
        sweep(a,'CherryStem',[(0,1.96,0),(.11,2.08,0)],[.017,.008],[.017,.008],'829771',head)
        for i in range(5):organic(a,'Drip'+str(i),((i-2)*.105,1.33,-.12),(.05,.12,.045),'e5bbc9',head)
    elif identity=='bathtub':
        color='bcced1';boot='869eaa'
        # Open miniature bathtub around the core, with taps and a duck captain.
        for side in [-1,1]:solid(a,'TubSide'+str(side),(side*.42,.74,.02),(.13,.58,.46),'dbe2d9',body)
        solid(a,'TubFloor',(0,.43,.02),(.94,.11,.46),'c5d4d1',body)
        arc(a,'RoundWindow',body,.36,.035,'dbb875',z=-.18)
        organic(a,'CaptainHead',(0,1.50,0),(.28,.28,.22),'e1c184',head);organic(a,'DuckBill',(0,1.40,-.26),(.20,.055,.14),'cfa261',head);eyes(a,head,1.53,-.21,.13,.08)
        w.cap(a,head,(0,1.70,0),'5f7d88',.36)
        sweep(a,'Shower',[(.43,.98,.15),(.50,1.72,.15),(.31,1.86,.15)],[.027,.027,.027],[.027,.027,.027],'c5af7e',body)
        for i in range(4):organic(a,'SoapBubble'+str(i),((i-1.5)*.16,1.16+(i%2)*.07,.03),(.065,.065,.065),'dce6d9',body,segments=12)
    elif identity=='peacock':
        color='78a9ac';boot='547f83'
        arc(a,'FeatherVest',body,.405,.07,'5b9497')
        for i in range(9):
            angle=(i-4)*.30;x=sin(angle)*.83;y=.85+cos(angle)*.75
            feather=a.node('TailFeather'+str(i),body,(x,y,.27))
            organic(a,'Feather'+str(i),(0,0,0),(.16,.35,.045),'80a384',feather)
            organic(a,'GoldenEye'+str(i),(0,.14,-.05),(.08,.10,.016),'dcc888',feather)
            organic(a,'BlueEye'+str(i),(0,.15,-.067),(.045,.065,.01),'719ca4',feather)
        organic(a,'PeacockFace',(0,1.55,0),(.22,.27,.20),color,head);eyes(a,head,1.57,-.19,.105,.07)
        organic(a,'Beak',(0,1.45,-.26),(.075,.045,.12),'d7bc75',head)
        for i in range(3):sweep(a,'Crest'+str(i),[((i-1)*.06,1.78,0),((i-1)*.12,1.98,0)],[.02,.01],[.02,.01],color,head)
    elif identity=='toaster':
        color='bea27f';boot='8b7663'
        for side in [-1,1]:solid(a,'ToasterWall'+str(side),(side*.40,.82,0),(.16,.89,.42),'c4a786',body)
        for y in [.41,1.24]:solid(a,'ToasterRail'+str(y),(0,y,0),(.94,.13,.43),'bca17f',body)
        loop(a,'HeatWindow',(0,.82,-.14),.36,.035,'d9bd8f',body)
        solid(a,'ToastFace',(0,1.54,0),(.48,.40,.16),'e5c48c',head);eyes(a,head,1.54,-.11,.115,.08)
        for side in [-1,1]:organic(a,'CrustTop'+str(side),(side*.15,1.77,0),(.17,.12,.09),'bd925e',head)
        for i in range(3):solid(a,'ToastMark'+str(i),((i-1)*.11,1.66,-.09),(.035,.07,.015),'bb915f',head)
        solid(a,'Lever',(.54,1.05,0),(.18,.09,.11),'806b57',body)
    else: raise ValueError(identity)
    if identity!='octopus': limbs(a,body,color,boot,'web' if identity=='rubber_duck_toy' else 'boots')
    arms(a,body,color)
    return a.save()

if __name__=='__main__':
    roster=['pipe_wrench','rubber_duck_toy','sweet_potato','marble_bust_01','street_rat','hamburger_buns','florist','teapot','octopus','astronaut','cactus','book','snail','bee','sushi','mushroom','clock','icecream','bathtub','peacock','toaster']
    report=[build(identity) for identity in roster]
    (w.OUT/'hero-core-manifest.json').write_text(json.dumps({'source':'Original orb-first 3D geometry; no converted images, reused hero meshes, or cutout retrofit','assets':report},indent=2)+'\n')
    print(json.dumps({'heroes':len(report),'triangles':sum(r['triangles'] for r in report),'source_mib':sum(r['bytes'] for r in report)/1048576},indent=2))

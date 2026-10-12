"""Biome-specific carved scenery and harvestables. Uses shared GLB writer."""
import importlib.util,json,math
from pathlib import Path
spec=importlib.util.spec_from_file_location('roster',Path(__file__).with_name('build-forge-roster.py'));r=importlib.util.module_from_spec(spec);spec.loader.exec_module(r)
f=r.f;s=r.s;w=r.w
INK=r.INK;GOLD=r.GOLD;BONE=r.BONE

def pillar(a,parent,p,height,color):
    f.plate(a,'Foundation',(p[0],p[1]+.16,p[2]),(1.3,.32,1.2),INK,parent)
    for y,wide in [(.38,1.1),(height-.3,1.1),(height,1.35)]:f.plate(a,'Cornice',(p[0],p[1]+y,p[2]),(wide,.14,wide*.85),GOLD if y==.38 else INK,parent)
    s.profile(a,'StoneShaft',[(p[1]+.4,.43,.4,p[2]),(p[1]+height-.3,.40,.35,p[2])],color,parent,segments=8)
    for side in [-1,1]:f.plate(a,'Flute',(p[0]+side*.24,p[1]+height*.51,p[2]-.38),(.07,height-.8,.03),INK,parent)

def scenery(biome,index):
    a=r.Asset(f'prop_{biome}_{index}');root=a.node('Scenery');main,accent,light=r.PALETTES[biome]
    arch=(biome==2 and index==1) or (biome==3 and index==1) or (biome==4 and index==1) or (biome==5 and index in [0,4,5])
    if arch:
        for side in [-1,1]:
            f.beam(a,'ArchPier',[(side*2.5,0,0),(side*2.5,4.5,0),(side*1.7,6.9,0),(0,7.7,0)],[.44,.4,.35,.20],main,root)
            f.beam(a,'ArchInlay',[(side*2.5,.4,-.41),(side*2.5,4.5,-.39),(side*1.7,6.9,-.34),(0,7.7,-.21)],[.025,.025,.025,.02],GOLD,root)
            f.slab(a,'Crown',[(side*2.4,6),(side*3.1,7.7),(side*2.1,7.1),(side*1.7,8.4),(side*1.2,6.8)],.35,accent,root)
        f.slab(a,'ArchSeal',[(-.35,6.7),(0,7.25),(.35,6.7),(0,6.2)],.14,light,root)
        if biome==5:
            s.loop(a,'Astrolabe',(0,5.3,.15),1.5,.06,GOLD,root)
            f.beam(a,'HangingStar',[(0,7.4,0),(0,6.8,0)],[.025,.025],GOLD,root)
        return a.save()
    if biome==3 and index==0:
        f.slab(a,'CloudPlatform',[(-1.9,2),(-1.7,2.5),(1.7,2.5),(1.9,2),(1.3,1.65),(.3,1.8),(-.7,1.52)],2.8,main,root)
        f.plate(a,'PlatformTop',(0,2.47,0),(3.6,.08,2.7),BONE,root)
        for side in [-1,1]:f.slab(a,'FeatherUnderside',[(side*.2,1.8),(side*1.2,1.65),(side*1.4,.65),(side*.6,1.10)],.25,GOLD,root)
        return a.save()
    if biome==1:
        for j in range(1 if index<2 else 3):
            x=(j-1)*.6 if index>=2 else 0;height=4.8+j*.9+index*.25
            f.beam(a,'FungalStem',[(x,0,0),(x+.15,height*.5,.05),(x,height,0)],[.42,.28,.19],main,root)
            cap=s.profile(a,'FungalCap',[(height-.5,1.25,1.05,0),(height-.2,1.5,1.2,0),(height+.5,.95,.8,0),(height+.9,.06,.06,0)],accent,root,segments=7)
            a.doc['nodes'][cap]['translation'][0]=x
            for k in range(7):
                angle=k*math.tau/7
                f.beam(a,'FungalGill',[(x+math.sin(angle)*.3,height-.2,math.cos(angle)*.3),(x+math.sin(angle)*1.35,height-.35,math.cos(angle)*1.1)],[.04,.02],light,root)
        if index>=4:
            f.slab(a,'ShrineDoor',[(-.4,0),(-.4,2.1),(0,2.6),(.4,2.1),(.4,0)],.10,INK,root,(0,0,-.48))
            for side in [-1,1]:f.plate(a,'SpectralFlame',(side*.5,2.7,-.5),(.13,.35,.06),light,root)
    elif biome==2:
        for j in range(3 if index<3 else 5):
            angle=j*2.4;height=3.2+(j%3)*1.4+index*.3
            f.beam(a,'MoonShard',[(math.sin(angle)*.45,0,math.cos(angle)*.4),(math.sin(angle)*.65,height*.7,math.cos(angle)*.5),(math.sin(angle)*.85,height,math.cos(angle)*.5)],[.5,.45,.003],main if j%2 else accent,root)
            f.beam(a,'CrystalVein',[(math.sin(angle)*.45,.2,-.45),(math.sin(angle)*.65,height*.7,-.45)],[.02,.008],light,root)
        if index in [0,5]:
            s.loop(a,'MoonDial',(0,6.2,0),1.3,.10,GOLD,root)
            for j in range(4):f.plate(a,'MoonDialMark',((j-1.5)*.25,6.2,-.13),(.06,.6,.04),light,root)
    elif biome==3:
        pillar(a,root,(0,0,0),6.5+index*.25,main)
        for side in [-1,1]:
            f.slab(a,'WingedCapital',[(side*.25,6.0),(side*1.1,6.3),(side*1.7,7.7),(side*.9,7.1),(side*.8,7.7)],.16,BONE,root)
            for j in range(3):f.beam(a,'WingGold',[(side*.5,6.3+j*.2,-.10),(side*(1.2-j*.12),7.1+j*.15,-.10)],[.023,.006],GOLD,root)
        f.slab(a,'HangingBanner',[(-.4,5.8),(.4,5.8),(.34,3.8),(0,3.4),(-.34,3.8)],.035,'398b9d',root,(0,0,-.43))
    elif biome==4:
        s.profile(a,'Furnace',[(0,1.0,.8,0),(1.3,.85,.75,0),(5.2,.6,.6,0),(6.4,.37,.34,0),(7.7,.02,.02,0)],main,root,segments=6)
        for j in range(3+index%3):
            y=1.3+j*1.05
            f.slab(a,'FurnaceMouth',[(-.45,y),(-.35,y+.5),(0,y+.7),(.35,y+.5),(.45,y)],.05,INK,root,(0,0,-.64))
            f.slab(a,'SpectralFlame',[(-.22,y+.05),(-.14,y+.34),(0,y+.52),(.21,y+.05)],.055,light,root,(0,0,-.68))
        for side in [-1,1]:f.beam(a,'SugarHorn',[(side*.7,3.9,0),(side*1.25,5.4,0),(side*.9,6.8,0)],[.19,.14,.002],accent,root)
    else:
        f.beam(a,'StarObelisk',[(0,0,0),(.12,3,0),(0,6.1,0)],[.8,.5,.12],main,root)
        for j in range(3+index%3):
            angle=j*math.tau/(3+index%3)
            f.slab(a,'StarBlade',[(0,5),(math.sin(angle)*.7,5.8+math.cos(angle)*.7),(math.sin(angle)*1.6,5.8+math.cos(angle)*1.6),(math.sin(angle+.4)*.6,5.8+math.cos(angle+.4)*.6)],.14,accent,root)
        s.loop(a,'OrbitRim',(0,5.8,-.15),.75,.045,GOLD,root)
        f.slab(a,'SpectralFlame',[(-.2,5.8),(0,6.2),(.2,5.8),(0,5.4)],.15,light,root,(0,0,-.2))
    return a.save()

def harvest(biome):
    a=r.Asset('harvest_'+str(biome));root=a.node('Body');main,accent,light=r.PALETTES[biome]
    s.profile(a,'OfferingBowl',[(0,.3,.3,0),(.13,.43,.43,0),(.23,.36,.36,0)],INK,root,segments=8)
    s.loop(a,'BowlRim',(0,.15,0),.36,.018,GOLD,root);a.doc['nodes'][-1]['rotation']=[math.sin(math.pi/4),0,0,math.cos(math.pi/4)]
    if biome in [0,3]:
        for j in range(6):
            n=f.slab(a,'Leaf',[(0,.18),(-.10,.55),(-.05,.96),(.13,.61)],.04,light if biome==3 else '48ad77',root,(0,0,.18));angle=j*math.tau/6;a.doc['nodes'][n]['rotation']=[0,math.sin(angle/2),0,math.cos(angle/2)]
        r.angular(a,'Seed',(0,.60,0),(.13,.17,.13),GOLD,root)
    elif biome==1:
        for j in range(3):
            x=(j-1)*.23;height=.45+.20*(j%2)
            f.beam(a,'FungusStem',[(x,.16,0),(x,height,0)],[.045,.03],BONE,root)
            n=s.profile(a,'MedicCap',[(height,.24,.23,0),(height+.1,.22,.21,0),(height+.28,.03,.03,0)],accent,root,segments=7);a.doc['nodes'][n]['translation'][0]=x
    elif biome==2:
        for j in range(5):f.beam(a,'Crystal',[(math.sin(j*2.4)*.2,.15,math.cos(j*2.4)*.2),(math.sin(j*2.4)*.26,.65+j*.1,math.cos(j*2.4)*.24)],[.13,.001],light,root)
    elif biome==4:
        f.beam(a,'Pepper',[(0,.2,0),(-.14,.4,0),(-.12,.75,0),(.07,.9,0)],[.025,.16,.19,.065],'ea583a',root)
        f.beam(a,'PepperStem',[(.07,.88,0),(.14,1.07,0),(.26,1.05,0)],[.04,.026,.008],'549662',root)
    else:
        for j in range(5):
            angle=j*math.tau/5
            f.beam(a,'PearlProng',[(math.sin(angle)*.13,.15,math.cos(angle)*.13),(math.sin(angle)*.40,.45,math.cos(angle)*.40),(math.sin(angle)*.20,.57,math.cos(angle)*.20)],[.09,.05,.002],accent,root)
        s.organic(a,'SpectralFlame',(0,.44,0),(.20,.20,.20),light,root,segments=16)
    return a.save()

if __name__=='__main__':
    props=[scenery(b,i) for b in range(1,6) for i in range(6)]
    plants=[harvest(b) for b in range(6)]
    (s.OUT/'forge-biomes-manifest.json').write_text(json.dumps({'generator':'scripts/build-forge-biomes.py','props':props,'harvestables':plants},indent=2)+'\n',encoding='utf8');print('30 scenery models and 6 harvestables rebuilt')

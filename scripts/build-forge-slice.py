"""Original carved forest slice. Reuses the project's GLB writer and mesh helpers.

Only named slice assets are written. Camera, collision geometry and catalogs are
owned by the runtime and are not generated here. No reference images are shipped.
"""
import importlib.util
import json
import math
from pathlib import Path

spec=importlib.util.spec_from_file_location('world',Path(__file__).with_name('build-world-models.py'))
w=importlib.util.module_from_spec(spec);spec.loader.exec_module(w)
s=w.s;TAU=math.tau;sin=math.sin;cos=math.cos
INK='15253b';STONE='65968e';BONE='fff0bf';GOLD='efba50';GREEN='58f8a4';RED='c62f58'

class Asset(s.Asset):
    def material(self,color,texture=0):
        # New silhouettes use flat pigment; carving is supplied by runtime ink shading.
        index=super().material(color,texture)
        self.doc['materials'][index]['pbrMetallicRoughness'].pop('baseColorTexture',None)
        return index

def slab(a,name,points,depth,color,parent,p=(0,0,0)):
    # Normalize winding and triangulate concave silhouettes so front faces survive culling.
    points=list(points)
    if sum(x*points[(i+1)%len(points)][1]-points[(i+1)%len(points)][0]*y for i,(x,y) in enumerate(points))<0:
        points.reverse()
    def cross2(a,b,c):return (b[0]-a[0])*(c[1]-a[1])-(b[1]-a[1])*(c[0]-a[0])
    indices=list(range(len(points)));faces=[]
    while len(indices)>3:
        for j,b in enumerate(indices):
            c=indices[(j+1)%len(indices)];v=indices[j-1]
            if cross2(points[v],points[b],points[c])<=1e-9:continue
            if any(all(cross2(points[k],points[l],points[q])>=-1e-9 for k,l in [(v,b),(b,c),(c,v)]) for q in indices if q not in [v,b,c]):continue
            faces.append((v,b,c));indices.pop(j);break
        else:raise ValueError('Invalid silhouette: '+name)
    faces.append(tuple(indices));count=len(points)
    vertices=[(x,y,-depth/2) for x,y in points]+[(x,y,depth/2) for x,y in points]
    triangles=[]
    for v,b,c in faces:triangles.extend([(v,c,b),(v+count,b+count,c+count)])
    for i in range(count):
        j=(i+1)%count;triangles.extend([(i,j,count+i),(j,count+j,count+i)])
    xs=[x for x,y in points];ys=[y for x,y in points]
    uv=[((x-min(xs))/max(.01,max(xs)-min(xs)),(y-min(ys))/max(.01,max(ys)-min(ys))) for x,y,z in vertices]
    n=a.mesh(name,vertices,triangles,uv,color,parent);w.place(a,n,p);return n

def beam(a,name,points,radii,color,parent):
    return s.sweep(a,name,points,radii,radii,color,parent)

def plate(a,name,p,size,color,parent): return w.solid(a,name,p,size,color,parent)

def core(a,parent,p,r=.29):
    socket=a.node('CoreSocket',parent,p)
    s.organic(a,'GlassCore',(0,0,0),(r,r,r),GREEN,socket,segments=24)
    for z in [-r*.65,r*.65]: s.loop(a,'GiltOrbRim',(0,0,z),r*.83,.025,GOLD,socket)

def hero():
    a=Asset('count_duck');body=a.node('Body');head=a.node('Head',body)
    core(a,body,(0,.82,0),.32)
    # Open cuirass and long split cloak frame the visible health vessel.
    for side in [-1,1]:
        beam(a,'MetalCuirass',[(side*.18,.39,.08),(side*.42,.65,.08),(side*.43,1.05,.06),(side*.20,1.24,.03)],[.08,.09,.13,.06],INK,body)
        beam(a,'CuirassInlay',[(side*.18,.39,-.02),(side*.39,.65,-.06),(side*.39,1.04,-.06)],[.016,.022,.022],GOLD,body)
        cape=a.node('Cape' if side==1 else 'CapeLeft',body)
        slab(a,'Cloak',[(side*.10,1.24),(side*.40,1.38),(side*.69,.91),(side*.79,.22),(side*.42,.34),(side*.25,.16)],.06,RED,cape,(0,0,.22))
        slab(a,'CloakShadow',[(side*.40,1.22),(side*.54,.8),(side*.71,.3),(side*.45,.4)],.065,INK,cape,(0,0,.25))
        arm=a.node('Arm'+str(side),body,(side*.43,1.04,0))
        beam(a,'WingGauntlet',[(0,0,0),(side*.09,-.2,-.03),(side*.09,-.34,-.14)],[.11,.075,.09],GOLD,arm)
        slab(a,'ShoulderCrest',[(-.16,0),(-.12,.2),(.07,.26),(.23,.02),(.10,-.10)],.22,INK,arm)
        a.node('HandSocket'+str(side),arm,(side*.09,-.32,-.23))
        leg=a.node('Leg'+str(side),body,(side*.24,.36,.02))
        beam(a,'BootShin',[(0,0,0),(0,-.20,0)],[.065,.085],INK,leg)
        plate(a,'WebbedBoot',(0,-.25,-.08),(.24,.12,.33),GOLD,leg)
    s.profile(a,'DuckSkull',[(1.22,.16,.14,0),(1.35,.30,.24,0),(1.57,.31,.22,0),(1.72,.14,.13,0),(1.76,.01,.01,0)],'caa65e',head,segments=12)
    slab(a,'Beak',[(-.26,1.38),(-.19,1.47),(.19,1.47),(.26,1.36),(.12,1.31),(-.17,1.31)],.33,GOLD,head,(0,0,-.30))
    for side in [-1,1]:
        slab(a,'EyeMask',[(side*.07,1.51),(side*.10,1.65),(side*.29,1.58),(side*.25,1.47)],.035,INK,head,(0,0,-.23))
        plate(a,'EyeGlint',(side*.17,1.555,-.258),(.065,.037,.018),GREEN,head)
        beam(a,'IvoryFang',[(side*.13,1.35,-.44),(side*.12,1.23,-.46)],[.028,.001],BONE,head)
    slab(a,'CrownFeather',[(-.11,1.69),(-.15,1.87),(0,1.80),(.10,1.97),(.12,1.70)],.10,INK,head)
    return a.save()

def pistol():
    a=Asset('mint_pistol');root=a.node('Body')
    slab(a,'CarvedReceiver',[(-.15,-.10),(-.18,.13),(-.07,.25),(.13,.20),(.17,-.05),(.06,-.13)],.47,INK,root,(0,.05,-.12))
    for z in [-.12,-.30,-.47]:
        plate(a,'GiltBand',(0,.11,z),(.30,.28,.045),GOLD,root)
    plate(a,'Barrel',(0,.10,-.51),(.19,.16,.37),STONE,root)
    plate(a,'MuzzleRim',(0,.10,-.70),(.25,.22,.05),GOLD,root)
    plate(a,'Bore',(0,.10,-.729),(.13,.10,.013),INK,root)
    slab(a,'CarvedGrip',[(-.08,.03),(.08,.03),(.13,-.30),(.01,-.34),(-.10,-.26)],.18,RED,root,(0,0,.11))
    for side in [-1,1]:
        slab(a,'WingEtching',[(-.10,0),(-.06,.15),(.07,.23),(.02,.08),(.13,.12),(.06,-.01)],.016,GOLD,root,(side*.177,.05,-.15))
    plate(a,'EmeraldSight',(0,.265,-.23),(.08,.05,.15),GREEN,root)
    a.node('Muzzle',root,(0,.10,-.74))
    return a.save()

def creature(index):
    a=Asset('creature_0_'+str(index));body=a.node('Body')
    core(a,body,(0,.84,-.26),.23 if index<5 else .28)
    if index==0: # Briar Beetle: pointed split carapace, six hooked legs.
        for side in [-1,1]:
            slab(a,'BriarShell',[(side*.03,.38),(side*.50,.55),(side*.52,1.10),(side*.21,1.42),(side*.04,1.2)],.52,STONE,body,(0,0,.12))
            beam(a,'ShellRidge',[(side*.10,.5,-.17),(side*.39,.84,-.17),(side*.20,1.32,-.17)],[.025,.035,.01],GOLD,body)
            for j in range(3): beam(a,'HookLeg',[(side*.32,.70,j*.22-.12),(side*.68,.45,j*.25-.12),(side*.51,.05,j*.34-.17)],[.08,.055,.015],BONE,body)
    elif index in [1,4]: # Leaf Ray / Four-Eye Moth: leaf spears vs divided moth wings.
        for side in [-1,1]:
            points=[(side*.15,.55),(side*.96,1.24),(side*.78,.58),(side*.47,.24),(side*.21,.38)]
            if index==4: points=[(side*.12,.72),(side*.75,1.48),(side*.97,1.14),(side*.56,.8),(side*.88,.36),(side*.51,.18)]
            slab(a,'Wing',points,.065,STONE if index==1 else RED,body,(0,0,.1))
            beam(a,'WingVein',[(side*.12,.6,0),(side*.53,.8,0),(side*.82,1.2,0)],[.035,.022,.004],GOLD,body)
            if index==4:
                for y in [.56,1.16]: s.organic(a,'FalseEye',(side*.57,y,-.025),(.09,.09,.028),GREEN,body,segments=8)
        beam(a,'Tail',[(0,.7,.16),(0,.34,.55),(0,.15,.9)],[.12,.06,.005],BONE,body)
    elif index==2: # Antler Snail: ridged shell, low body, branched antlers.
        s.profile(a,'Shell',[(.3,.23,.30,.16),(.50,.62,.43,.16),(1.1,.54,.43,.16),(1.5,.18,.16,.16),(1.55,.01,.01,.16)],STONE,body,segments=10)
        for j in range(5): s.loop(a,'ShellGrowth',(0,.9,-.22-j*.015),.16+j*.07,.021,GOLD,body)
        plate(a,'Foot',(0,.17,-.13),(.87,.18,.88),INK,body)
        for side in [-1,1]:
            beam(a,'Antler',[(side*.20,1.2,-.23),(side*.34,1.56,-.14),(side*.28,1.83,-.14)],[.055,.028,.003],BONE,body)
            beam(a,'AntlerFork',[(side*.33,1.53,-.14),(side*.52,1.69,-.12)],[.024,.002],BONE,body)
    elif index==3: # Thorn Flower: radial blades around the exposed crimson orb.
        for j in range(7):
            angle=j*TAU/7;cx=sin(angle);cy=cos(angle)
            pts=[(cx*.22,cy*.22+.84),(cx*.57-cy*.1,cy*.57+cx*.1+.84),(cx*.72,cy*.72+.84),(cx*.57+cy*.1,cy*.57-cx*.1+.84)]
            slab(a,'PetalBlade',pts,.11,STONE if j%2 else BONE,body,(0,0,-.14))
        for side in [-1,1]:beam(a,'RootFoot',[(0,.8,.1),(side*.12,.22,.1),(side*.48,.07,-.13)],[.09,.07,.005],INK,body)
    else: # Pine Spider: inverted tree-crown with six long angular legs.
        s.profile(a,'SpireShell',[(.75,.40,.34,.12),(1.05,.47,.32,.12),(1.37,.24,.21,.12),(1.8,.04,.04,.12)],INK,body,segments=8)
        for side in [-1,1]:
            for j in range(3): beam(a,'Stilt',[(side*.24,1.10,j*.23),(side*.91,1.32,j*.34),(side*.73,.04,j*.47-.12)],[.11,.065,.014],BONE,body)
            for j in range(3): beam(a,'SpireBranch',[(side*.12,1.17+j*.18,.12),(side*(.55-j*.12),1.32+j*.16,.12)],[.06,.002],GOLD,body)
    # Paired slit eyes replace round toy eyes while preserving a facing cue.
    for side in [-1,1]:plate(a,'EyeSlit',(side*.115,1.13,-.35),(.12,.035,.04),GREEN,body)
    return a.save()

def prop(index):
    a=Asset('prop_0_'+str(index));root=a.node('Body')
    if index<2:
        beam(a,'TwistedTrunk',[(0,0,0),(.1,1.8,0),(-.1,3.8,0),(.05,6.5,0)],[.33,.25,.18,.015],INK,root)
        for j in range(7):
            angle=j*2.4;side=1 if j%2 else -1;y=2+j*.48
            beam(a,'DeadBranch',[(0,y,0),(sin(angle)*1.1,y+.4,cos(angle)*1.1),(sin(angle)*1.8,y+1.1,cos(angle)*1.8)],[.10,.07,.002],STONE,root)
            if index==0:
                node=slab(a,'BladeFoliage',[(-1.3,0),(-.6,.8),(0,1.2),(.7,.3),(1.2,0),(.3,-.18)],.11,'259b6b',root,(sin(angle),y+.6,cos(angle)))
                a.doc['nodes'][node]['rotation']=[0,sin(angle/2),0,cos(angle/2)]
    else:
        height=[0,0,2.8,3.7,7.0,8.0][index]
        plate(a,'Plinth',(0,.17,0),(1.7,.34,1.5),INK,root)
        plate(a,'PlinthGold',(0,.38,0),(1.6,.08,1.4),GOLD,root)
        s.profile(a,'CarvedPillar',[(.42,.67,.59,0),(.65,.51,.46,0),(height-.3,.46,.42,0),(height,.64,.55,0)],STONE,root,segments=8)
        for side in [-1,1]:
            plate(a,'Fluting',(side*.30,height*.5,-.46),(.09,height-.8,.06),INK,root)
            plate(a,'GiltFluting',(side*.32,height*.5,-.495),(.022,height-1,.014),GOLD,root)
        for y in [.6,height-.3]: plate(a,'Cornice',(0,y,0),(1.55,.18,1.35),INK,root)
        slab(a,'CarvedEye',[(-.31,height*.60),(0,height*.70),(.31,height*.60),(0,height*.53)],.055,GOLD,root,(0,0,-.49))
        slab(a,'EyeInset',[(-.18,height*.60),(0,height*.65),(.18,height*.60),(0,height*.57)],.057,GREEN,root,(0,0,-.52))
        if index in [3,5]:
            s.profile(a,'Brazier',[(height,.30,.3,0),(height+.3,.62,.62,0),(height+.40,.62,.62,0)],GOLD,root,segments=8)
            for j in range(3):beam(a,'SpectralFlame',[(sin(j*2.4)*.21,height+.35,cos(j*2.4)*.21),(sin(j*2.4)*.25,height+.85,0),(.06,height+1.4-j*.2,0)],[.20,.11,.001],GREEN,root)
        else:
            slab(a,'SplitCrown',[(-.65,height),(-.48,height+.9),(-.20,height+.3),(0,height+.65),(.2,height+.3),(.48,height+.9),(.65,height)],.55,INK,root)
    return a.save()

if __name__=='__main__':
    report=[hero(),pistol()]+[creature(i) for i in range(6)]+[prop(i) for i in range(6)]
    (s.OUT/'forge-slice-manifest.json').write_text(json.dumps({'generator':'scripts/build-forge-slice.py','assets':report},indent=2)+'\n')
    print(json.dumps(report,indent=2))

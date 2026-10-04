"""Extend the approved slice into the editable Wildforge 0.7 mesh roster.

Uses original authored geometry and existing approved painted texture swatches.
No raster images are modified. Rigid pivots are retained for native animation.
"""
import importlib.util
import json
import math
import struct
from math import sin, cos
from pathlib import Path

spec=importlib.util.spec_from_file_location("style",Path(__file__).with_name("build-style-models.py"))
s=importlib.util.module_from_spec(spec);spec.loader.exec_module(s)
A, organic, profile, sweep, loop, panel, grid=s.Asset,s.organic,s.profile,s.sweep,s.loop,s.panel,s.grid
TAU=math.tau
OUT=s.OUT

HERO_CORE_Y={"octopus":.99,"snail":.68,"bee":.72,"teapot":.59,"bathtub":.60,"icecream":.65,"count_duck":.69}

def rebuild_hero_core(a):
    """Cut a real through-hole, retaining interpolated UVs/normals, then mount one orb."""
    centre=HERO_CORE_Y.get(a.name.removeprefix("hero_"),.70)
    def read(index):
        acc=a.doc['accessors'][index];view=a.doc['bufferViews'][acc['bufferView']]
        width={'SCALAR':1,'VEC2':2,'VEC3':3}[acc['type']]
        fmt='I' if acc['componentType']==5125 else 'f'
        values=struct.unpack_from('<'+fmt*(acc['count']*width),a.data,view.get('byteOffset',0))
        return [tuple(values[i:i+width]) for i in range(0,len(values),width)]
    parents={child:i for i,node in enumerate(a.doc['nodes']) for child in node.get('children',[])}
    body=next(i for i,node in enumerate(a.doc['nodes']) if node['name']=='Body')
    for index,node in enumerate(a.doc['nodes']):
        if 'mesh' not in node: continue
        chain=[];cursor=index;offset=[0.,0.,0.]
        while cursor in parents:
            chain.append(a.doc['nodes'][cursor]['name'])
            for axis,value in enumerate(a.doc['nodes'][cursor].get('translation',[0,0,0])): offset[axis]+=value
            cursor=parents[cursor]
        if cursor!=body or any(name.startswith(('Head','Arm','Leg','Core','Rear','Glass')) for name in chain): continue
        primitive=a.doc['meshes'][node['mesh']]['primitives'][0]
        positions=read(primitive['attributes']['POSITION']);normals=read(primitive['attributes']['NORMAL']);uvs=read(primitive['attributes']['TEXCOORD_0'])
        triangles=[v[0] for v in read(primitive['indices'])];out=[];indices=[]
        # Convex polygon subtraction partitions each triangle into retained outer pieces.
        for start in range(0,len(triangles),3):
            inside=[positions[i]+normals[i]+uvs[i] for i in triangles[start:start+3]]
            for side in range(18):
                angle=(side+.5)*TAU/18;nx,ny=cos(angle),sin(angle)
                def distance(v): return nx*(v[0]+offset[0])+ny*(v[1]+offset[1]-centre)-.25
                def clip(poly,keep_outside):
                    result=[]
                    for j,current in enumerate(poly):
                        previous=poly[j-1];d1=distance(previous);d2=distance(current)
                        k1=d1>=0 if keep_outside else d1<=0;k2=d2>=0 if keep_outside else d2<=0
                        if k1!=k2:
                            t=d1/(d1-d2);result.append(tuple(x+(y-x)*t for x,y in zip(previous,current)))
                        if k2: result.append(current)
                    return result
                outside=clip(inside,True)
                for j in range(1,len(outside)-1):
                    indices.extend(range(len(out),len(out)+3));out.extend([outside[0],outside[j],outside[j+1]])
                inside=clip(inside,False)
                if not inside: break
        if not out: node.pop('mesh');continue
        primitive['attributes']={'POSITION':a.accessor([v[:3] for v in out],'VEC3'),'NORMAL':a.accessor([s.normalized(v[3:6]) for v in out],'VEC3'),'TEXCOORD_0':a.accessor([v[6:] for v in out],'VEC2')}
        primitive['indices']=a.accessor(indices,'SCALAR',5125)
        a.triangles+=len(indices)//3-len(triangles)//3
    socket=a.node('CoreSocket',body,(0,centre,0))
    organic(a,'GlassCore',(0,0,0),(.285,.285,.46),'91cfc7',socket,segments=32)
    for side in [-1,1]: loop(a,'CoreFrame'+str(side),(0,0,side*.34),.27,.026,'d7b372',socket)

class HeroAsset(A):
    def save(self):
        rebuild_hero_core(self)
        return super().save()


def place(a,node,p): a.doc["nodes"][node]["translation"]=list(p)


def solid(a,name,p,size,color,parent,texture=0):
    # Beveled rectangular silhouette: pages, machines, architecture, armour plates.
    x,y,z=size; bevel=min(x,y)*.12
    poly=[(-x/2+bevel,-y/2),(x/2-bevel,-y/2),(x/2,-y/2+bevel),(x/2,y/2-bevel),
          (x/2-bevel,y/2),(-x/2+bevel,y/2),(-x/2,y/2-bevel),(-x/2,-y/2+bevel)]
    node=panel(a,name,poly,z,color,parent,texture);place(a,node,p);return node


def face(a,parent,p=(0,1.24,-.35),gap=.15,eyes=.10,mouth=True):
    for side in [-1,1]:
        organic(a,"EyeWhite"+str(side),(p[0]+side*gap,p[1],p[2]),(eyes,eyes*1.12,.045),"fff0d2",parent,segments=16)
        organic(a,"Pupil"+str(side),(p[0]+side*gap,p[1]-.01,p[2]-.045),(eyes*.38,eyes*.58,.016),"302d37",parent,segments=12)
        organic(a,"Spark"+str(side),(p[0]+side*gap-.014,p[1]+.025,p[2]-.06),(.012,.017,.008),"ffffff",parent,segments=8)
    if mouth: organic(a,"Smirk",(p[0],p[1]-.16,p[2]),(.105,.025,.021),"704f43",parent,segments=12)


def core(a,parent,p=(0,1,-.43),radius=.29):
    socket=a.node("CoreSocket",parent,p)
    organic(a,"GlassCore",(0,0,0),(radius,radius,radius),"91cfc7",socket,segments=24)
    loop(a,"CoreFrame",(0,0,-radius*.44),radius*.92,.035,"d7b372",socket)
    for i in range(6):
        angle=i/6*TAU
        organic(a,"CoreRivet"+str(i),(math.cos(angle)*radius,math.sin(angle)*radius,-radius*.46),(.026,.026,.022),"f5d6a5",socket,segments=8)


def hero_limbs(a,body,color="b89570",feet="735851",y=.92):
    for side in [-1,1]:
        leg=a.node("Leg"+str(side),body,(side*.22,.30,0))
        sweep(a,"BootLeg"+str(side),[(0,0,0),(0,-.15,-.015),(0,-.23,-.03)],[.07,.08,.08],[.07,.07,.08],color,leg)
        organic(a,"Shoe"+str(side),(side*.02,-.23,-.09),(.14,.08,.21),feet,leg,segments=16)
        arm=a.node("Arm"+str(side),body,(side*.43,y,0))
        sweep(a,"Sleeve"+str(side),[(0,.02,0),(side*.04,-.12,-.04),(side*.035,-.26,-.12)],[.09,.09,.075],[.085,.09,.07],color,arm)
        organic(a,"Cuff"+str(side),(side*.035,-.26,-.12),(.09,.035,.09),"f4e4c7",arm,segments=12)
        organic(a,"Hand"+str(side),(side*.035,-.32,-.16),(.09,.08,.085),color,arm,segments=12)
        a.node("HandSocket"+str(side),arm,(side*.035,-.29,-.22))


def cap(a,parent,p=(0,1.6,0),color="98684e",radius=.42):
    holder=a.node("Hat",parent,p)
    profile(a,"HatBrim",[(0,radius,radius*.85,0),(.05,radius,radius*.85,0)],color,holder)
    profile(a,"HatCrown",[(.04,radius*.65,radius*.60,0),(.23,radius*.45,radius*.45,0),(.29,.05,.05,0)],color,holder)
    return holder


def spiral(a,name,parent,p,rad=.48,color="b78665",turns=2.5):
    centers=[];widths=[];depths=[]
    for i in range(43):
        t=i/42;angle=t*TAU*turns;r=rad*(.08+.92*t)
        centers.append((p[0]+math.cos(angle)*r,p[1]+math.sin(angle)*r,p[2]))
        widths.append(.025+.085*t);depths.append(.03+.14*t)
    # A swept coil through an XY plane needs its cross section rotated to each tangent.
    pts=[];uv=[];tri=[];segments=8
    for j,c in enumerate(centers):
        tangent=s.normalized(s.sub(centers[min(42,j+1)],centers[max(0,j-1)]));normal=(-tangent[1],tangent[0],0)
        for i in range(segments+1):
            angle=i/segments*TAU
            pts.append((c[0]+normal[0]*math.cos(angle)*widths[j],c[1]+normal[1]*math.cos(angle)*widths[j],c[2]+math.sin(angle)*depths[j]));uv.append((i/segments,j/42))
    for j in range(42):
        for i in range(segments):
            v=j*(segments+1)+i;tri.extend([(v,v+1,v+segments+1),(v+1,v+segments+2,v+segments+1)])
    a.mesh(name,pts,tri,uv,color,parent)


def hero(identity):
    a=HeroAsset("hero_"+identity);body=a.node("Body");head=a.node("Head",body)
    if identity=="pipe_wrench":
        profile(a,"Overalls",[(.3,.05,.05,0),(.42,.32,.25,0),(.8,.36,.25,0),(1,.27,.20,0)],"6996a2",body)
        organic(a,"EngineerFace",(0,1.30,0),(.30,.30,.27),"dfa881",head)
        face(a,head,(0,1.32,-.25));cap(a,head,(0,1.54,0),"b66551",.39)
        solid(a,"ApronPocket",(0,.67,-.25),(.22,.18,.04),"a0bfbb",body)
        for side in [-1,1]:
            solid(a,"Strap"+str(side),(side*.19,.87,-.23),(.075,.30,.045),"adbaaa",body)
            organic(a,"StrapButton"+str(side),(side*.19,.85,-.26),(.03,.03,.02),"efc578",body)
        hero_limbs(a,body,"c17c59")
    elif identity=="sweet_potato":
        profile(a,"PotatoBody",[(.28,.07,.06,0),(.40,.39,.30,0),(.8,.48,.37,0),(1.3,.40,.31,0),(1.54,.21,.19,0),(1.6,.02,.02,0)],"be9369",body)
        face(a,head,(0,1.23,-.30),.19,.115)
        for i in range(5): organic(a,"Sprout"+str(i),(math.cos(i*2.4)*.17,1.62+math.sin(i)*.04,math.sin(i*2.4)*.13),(.10,.24,.055),"8faa78",head,skew=.05)
        solid(a,"Breastplate",(0,.73,-.35),(.60,.36,.08),"8aa196",body)
        for side in [-1,1]: organic(a,"ShoulderPlate"+str(side),(side*.42,.94,0),(.20,.17,.25),"9eafa0",body)
        hero_limbs(a,body,"b78f6a","5e695c")
    elif identity=="marble_bust_01":
        profile(a,"StonePlinth",[(.08,.37,.28,0),(.14,.37,.28,0),(.3,.24,.20,0),(.6,.31,.25,0),(1.0,.34,.24,0),(1.1,.14,.14,0)],"b8bcb5",body,texture=2)
        organic(a,"GrannyHead",(0,1.35,0),(.28,.31,.26),"ced0c6",head,texture=2)
        for i in range(9): organic(a,"HairCurl"+str(i),(math.cos(i*TAU/9)*.26,1.54+math.sin(i*TAU/9)*.12,.08+math.sin(i*3)*.07),(.10,.10,.10),"efe4d0",head,segments=12)
        face(a,head,(0,1.37,-.25),.13,.08)
        for side in [-1,1]:loop(a,"Spectacle"+str(side),(side*.13,1.37,-.30),.105,.013,"96754d",head)
        solid(a,"Shawl",(0,.90,-.24),(.59,.15,.055),"9d7c98",body)
        hero_limbs(a,body,"b3b8ae","776b76")
    elif identity=="street_rat":
        profile(a,"RatCoat",[(.29,.05,.05,.02),(.42,.31,.24,0),(.81,.34,.26,0),(1.03,.19,.16,0)],"6e5e87",body)
        organic(a,"RatHead",(0,1.27,0),(.30,.27,.24),"ac9bbe",head)
        organic(a,"LongSnout",(0,1.15,-.28),(.19,.11,.21),"ba9eaf",head)
        organic(a,"Nose",(0,1.19,-.45),(.07,.045,.035),"dbaeb8",head)
        face(a,head,(0,1.32,-.23),.15,.085,False)
        for side in [-1,1]:
            organic(a,"Ear"+str(side),(side*.29,1.52,0),(.18,.23,.07),"a18cad",head)
            organic(a,"EarLining"+str(side),(side*.29,1.52,-.055),(.12,.16,.022),"d8a4b1",head)
        sweep(a,"CurledTail",[(0,.43,.22),(.28,.3,.40),(.52,.25,.43),(.69,.33,.37),(.67,.48,.27)],[.065,.06,.04,.03,.005],[.06,.05,.04,.025,.005],"b590ac",body)
        solid(a,"CoinSatchel",(.36,.53,-.04),(.20,.24,.18),"d2b386",body,texture=1)
        hero_limbs(a,body,"ae9abb")
    elif identity=="hamburger_buns":
        profile(a,"BreadKnight",[(.28,.08,.06,0),(.45,.42,.28,0),(.9,.48,.31,0),(1.36,.36,.27,0),(1.55,.12,.08,0)],"d9ac6f",body)
        organic(a,"BreadFront",(0,1.04,-.15),(.36,.46,.18),"f3d296",body)
        face(a,head,(0,1.18,-.32),.16,.095)
        for i in [-1,0,1]: solid(a,"ToastScore"+str(i),(i*.16,1.44,-.22),(.055,.15,.04),"a8754a",head)
        cap(a,head,(0,1.48,0),"869ba4",.45)
        solid(a,"KnightTabard",(0,.65,-.30),(.63,.25,.06),"8fa5a4",body)
        hero_limbs(a,body,"b79a73","667d83")
    elif identity=="florist":
        profile(a,"TerracottaPot",[(.27,.28,.24,0),(.78,.40,.34,0),(.84,.44,.37,0),(.91,.44,.37,0)],"c78d6c",body,texture=1)
        sweep(a,"FlowerStem",[(0,.85,0),(0,1.1,0),(0,1.33,0)],[.065,.06,.045],[.055,.05,.04],"72986d",body)
        for i in range(9):
            angle=i/9*TAU;organic(a,"Petal"+str(i),(math.cos(angle)*.28,1.35+math.sin(angle)*.28,-.06),(.20,.21,.07),"dc9ab1" if i%2 else "edb1bf",head,segments=16)
        organic(a,"FlowerFace",(0,1.35,-.10),(.23,.23,.085),"edcb77",head);face(a,head,(0,1.39,-.18),.095,.065)
        for side in [-1,1]:organic(a,"Leaf"+str(side),(side*.28,1.06,0),(.23,.07,.08),"8daf79",body,skew=side*.09)
        hero_limbs(a,body,"759d72","815d49")
    elif identity=="teapot":
        profile(a,"ChinaPot",[(.29,.12,.12,0),(.4,.39,.29,0),(.82,.43,.32,0),(1.13,.28,.25,0),(1.17,.22,.19,0)],"b8d4ca",body)
        face(a,head,(0,.88,-.30),.17,.095)
        sweep(a,"TeaSpout",[(-.27,.79,0),(-.48,.83,0),(-.60,1.02,0),(-.57,1.16,0)],[.11,.11,.095,.105],[.10,.10,.07,.08],"c9dfd0",body)
        handle=loop(a,"PorcelainHandle",(.43,.79,0),.25,.053,"c9dfd0",body);a.doc["nodes"][handle]["rotation"]=[0,math.sin(math.pi/4),0,math.cos(math.pi/4)]
        profile(a,"Lid",[(1.17,.26,.23,0),(1.21,.31,.26,0),(1.29,.04,.04,0)],"d5e3cd",head)
        organic(a,"LidKnob",(0,1.32,0),(.08,.09,.08),"d5b377",head)
        for i in range(6):organic(a,"ChinaFlower"+str(i),(math.cos(i*TAU/6)*.15,.58+math.sin(i*TAU/6)*.10,-.31),(.04,.035,.018),"dba2ab",body,segments=8)
        hero_limbs(a,body,"c8dbc9","acbcb1",.81)
    elif identity=="octopus":
        profile(a,"PirateHead",[(.7,.16,.12,0),(.9,.38,.29,0),(1.35,.42,.32,0),(1.57,.27,.25,0),(1.63,.015,.015,0)],"ae9abd",body)
        for i in range(6):
            angle=i/6*TAU;x,z=math.cos(angle),math.sin(angle)
            tentacle=a.node("Leg"+str(i),body,(x*.22,.79,z*.17))
            sweep(a,"Tentacle"+str(i),[(0,0,0),(x*.20,-.23,z*.17),(x*.30,-.58,z*.29),(x*.42,-.64,z*.35),(x*.44,-.51,z*.39)],
                  [.11,.12,.09,.05,.004],[.11,.12,.09,.05,.004],"b39fc1",tentacle)
        face(a,head,(0,1.22,-.30),.17,.11)
        solid(a,"EyePatch",(.17,1.22,-.35),(.21,.18,.03),"3d3547",head)
        hat=cap(a,head,(0,1.49,0),"434254",.50)
        solid(a,"HatBadge",(0,.17,-.26),(.11,.10,.02),"e7ce9d",hat)
        hero_limbs(a,body,"b39fc1","b39fc1",1.05)
    elif identity=="astronaut":
        profile(a,"SpaceSuit",[(.29,.06,.06,0),(.43,.28,.24,0),(.8,.31,.25,0),(1.02,.27,.21,0)],"d3dbcf",body)
        organic(a,"Helmet",(0,1.29,0),(.39,.39,.33),"dbe5da",head)
        organic(a,"TintedVisor",(0,1.28,-.22),(.30,.26,.16),"6d8f9b",head)
        face(a,head,(0,1.29,-.365),.11,.07)
        loop(a,"HelmetRim",(0,1.29,-.31),.31,.034,"cfb484",head)
        solid(a,"OxygenPack",(0,.78,.30),(.49,.45,.22),"879aa2",body)
        solid(a,"ControlPanel",(0,.80,-.26),(.25,.18,.05),"91adb2",body)
        for i in range(3):organic(a,"SuitButton"+str(i),((i-1)*.06,.82,-.30),(.016,.016,.01),"e9ad76",body,segments=8)
        hero_limbs(a,body,"d1d8cc","8fa3a4")
    elif identity=="cactus":
        profile(a,"CactusBody",[(.27,.07,.07,0),(.36,.31,.26,0),(1.19,.32,.27,0),(1.48,.22,.20,0),(1.54,.015,.015,0)],"8fac77",body)
        face(a,head,(0,1.22,-.25),.14,.09)
        for i in range(18):
            angle=i*2.4;y=.55+(i%5)*.16
            sweep(a,"Spine"+str(i),[(math.cos(angle)*.30,y,math.sin(angle)*.25),(math.cos(angle)*.39,y+.06,math.sin(angle)*.34)], [.024,.001],[.02,.001],"ecd5a0",body)
        for i in range(5):organic(a,"CactusBloom"+str(i),(math.cos(i*TAU/5)*.10,1.54+math.sin(i*TAU/5)*.08,-.03),(.09,.08,.04),"d49aaf",head)
        hero_limbs(a,body,"87a572","8c7057")
    elif identity=="book":
        solid(a,"Hardback",(0,.99,0),(.76,1.23,.29),"897596",body)
        solid(a,"CreamPages",(.025,.99,-.12),(.66,1.07,.16),"e7d7b7",body)
        solid(a,"FrontCover",(0,.99,-.22),(.79,1.26,.05),"93819f",body)
        for y in [.45,1.53]:solid(a,"CoverTrim"+str(y),(0,y,-.25),(.66,.035,.015),"d8b77e",body)
        for x in [-.32,.32]:solid(a,"SideTrim"+str(x),(x,.99,-.25),(.035,1.10,.015),"d8b77e",body)
        face(a,head,(0,1.26,-.27),.18,.115)
        solid(a,"Bookmark",(.24,.57,-.28),(.07,.46,.025),"b36167",body)
        for i in range(3):solid(a,"SpineBand"+str(i),(-.40,.64+i*.32,0),(.045,.04,.32),"cfb17e",body)
        hero_limbs(a,body,"9a83a1","665775")
    elif identity=="snail":
        profile(a,"SnailFront",[(.23,.20,.30,-.10),(.37,.36,.32,-.08),(.74,.22,.22,-.09),(1.08,.18,.16,-.09)],"a8b98c",body)
        organic(a,"ShellBack",(0,.99,.18),(.47,.54,.30),"caa07c",body,texture=1)
        spiral(a,"ShellCoil",body,(0,1.0,-.02),.46,"b28268")
        for side in [-1,1]:
            sweep(a,"EyeStalk"+str(side),[(side*.12,.88,-.23),(side*.19,1.19,-.26),(side*.20,1.40,-.26)],[.04,.035,.045],[.04,.035,.04],"9eaf83",head)
            organic(a,"StalkEye"+str(side),(side*.20,1.43,-.27),(.095,.095,.085),"e8e3bd",head)
        face(a,head,(0,1.42,-.33),.20,.07,False)
        hero_limbs(a,body,"a0b183","8b9a78",.73)
    elif identity=="bee":
        profile(a,"StripedBee",[(.3,.02,.02,0),(.44,.26,.23,0),(.63,.37,.29,0),(.89,.32,.26,0),(1.05,.20,.19,0)],"e1bc65",body)
        for y,r in [(.55,.34),(.77,.35),(.96,.25)]:profile(a,"BeeStripe"+str(y),[(y,r,.275,0),(y+.08,r,.275,0)],"4f4340",body)
        organic(a,"BeeHead",(0,1.30,-.025),(.28,.28,.24),"e7c776",head);face(a,head,(0,1.32,-.25),.13,.09)
        for side in [-1,1]:
            wing=a.node("Wing"+str(side),body,(side*.23,.96,.12))
            organic(a,"BeeWing"+str(side),(side*.26,.19,.07),(.29,.43,.055),"c4dad2",wing)
            sweep(a,"Antenna"+str(side),[(side*.12,1.50,0),(side*.18,1.69,0),(side*.22,1.72,-.03)],[.025,.018,.028],[.025,.018,.027],"514644",head)
        hero_limbs(a,body,"bd9656","594b41")
    elif identity=="sushi":
        profile(a,"NoriRoll",[(.32,.23,.20,0),(.45,.37,.28,0),(1.20,.37,.28,0),(1.28,.32,.26,0)],"426857",body)
        profile(a,"RiceTop",[(1.22,.34,.26,0),(1.28,.34,.26,0),(1.34,.26,.20,0)],"eadfc6",head)
        for i in range(12):organic(a,"RiceGrain"+str(i),(math.cos(i*2.4)*.25,1.31,math.sin(i*2.4)*.20),(.05,.035,.03),"fff0d2",head,segments=8)
        solid(a,"SalmonSlice",(0,1.34,-.02),(.45,.075,.25),"d78a78",head)
        face(a,head,(0,1.04,-.28),.16,.085)
        profile(a,"Headband",[(1.14,.385,.29,0),(1.20,.385,.29,0)],"b6605c",body)
        solid(a,"SwordSheath",(.36,.78,.17),(.055,.79,.075),"6d5150",body)
        hero_limbs(a,body,"567660","4d5c4d")
    elif identity=="mushroom":
        profile(a,"ChefStem",[(.3,.17,.15,0),(.55,.29,.22,0),(1.22,.23,.20,0),(1.34,.14,.12,0)],"e1cfaa",body)
        profile(a,"WideChefCap",[(1.23,.47,.38,0),(1.30,.59,.43,0),(1.49,.50,.39,0),(1.70,.25,.23,0),(1.74,.02,.02,0)],"b97563",head)
        for i in range(8):organic(a,"CapSpot"+str(i),(math.cos(i*2.4)*.32,1.5+(i%3)*.065,math.sin(i*2.4)*.28),(.065,.025,.065),"f2dfb8",head,segments=12)
        face(a,head,(0,1.09,-.20),.12,.08)
        solid(a,"ChefApron",(0,.73,-.21),(.44,.42,.04),"eff0d6",body)
        hero_limbs(a,body,"d4ba92","a17c5b")
    elif identity=="clock":
        solid(a,"ClockCase",(0,.87,0),(.71,1.16,.31),"a07a5b",body,texture=1)
        organic(a,"ClockFace",(0,1.18,-.17),(.32,.32,.035),"ede0b9",head)
        loop(a,"ClockBezel",(0,1.18,-.19),.31,.027,"d4b777",head)
        face(a,head,(0,1.22,-.22),.14,.075)
        for i in range(12):organic(a,"HourMark"+str(i),(math.sin(i*TAU/12)*.255,1.18+math.cos(i*TAU/12)*.255,-.22),(.012,.019,.01),"806342",head,segments=8)
        solid(a,"ClockHand",(0,1.32,-.25),(.015,.18,.025),"72583d",head)
        organic(a,"Pendulum",(0,.64,-.18),(.11,.12,.027),"d7b375",body)
        solid(a,"PendulumRod",(0,.79,-.17),(.018,.23,.023),"d7b375",body)
        hero_limbs(a,body,"ad8562","876b52")
    elif identity=="icecream":
        profile(a,"WaffleCone",[(.3,.11,.10,0),(.40,.19,.17,0),(1.0,.34,.28,0)],"c7a06b",body,texture=1)
        for i in range(6):profile(a,"WaffleBand"+str(i),[(.43+i*.08,.20+i*.02,.18+i*.016,0),(.45+i*.08,.205+i*.02,.185+i*.016,0)],"a77d50",body)
        organic(a,"PinkScoop",(0,1.23,0),(.39,.37,.30),"d9a4b4",head)
        organic(a,"MintScoop",(.16,1.49,.025),(.23,.23,.20),"b2caaa",head)
        organic(a,"Cherry",(.19,1.70,0),(.085,.09,.075),"b96267",head)
        face(a,head,(0,1.22,-.28),.16,.09)
        hero_limbs(a,body,"d1a5a8","796d9e")
    elif identity=="bathtub":
        profile(a,"BathHull",[(.26,.13,.12,0),(.37,.45,.30,0),(.71,.59,.37,0),(.89,.61,.38,0),(.95,.58,.36,0)],"b5caca",body)
        profile(a,"BathRim",[(.87,.62,.39,0),(.96,.62,.39,0),(.96,.54,.31,0),(.9,.54,.31,0)],"e8e5d1",body)
        organic(a,"AdmiralHead",(0,1.17,-.09),(.24,.25,.20),"d1b890",head);face(a,head,(0,1.19,-.28),.11,.075)
        cap(a,head,(0,1.36,-.02),"456d82",.34)
        for i in range(6):organic(a,"Bubble"+str(i),((i%3-1)*.24,.98+(i//3)*.11,.03),(.10,.10,.10),"d1e1d5",body,segments=12)
        sweep(a,"ShowerPipe",[(.47,.70,.18),(.50,1.1,.18),(.50,1.44,.18),(.35,1.49,.15)],[.027,.027,.025,.05],[.027,.027,.025,.06],"ccb77f",body)
        hero_limbs(a,body,"a2b8bc","6d8899",.77)
    elif identity=="peacock":
        profile(a,"PeacockWaistcoat",[(.29,.06,.06,0),(.43,.27,.23,0),(.83,.34,.26,0),(1.10,.16,.13,0)],"4f8c92",body)
        organic(a,"PeacockHead",(0,1.33,0),(.24,.29,.22),"629ca0",head)
        organic(a,"Beak",(0,1.22,-.27),(.105,.045,.11),"d7b66f",head);face(a,head,(0,1.37,-.205),.12,.075,False)
        for i in range(7):
            angle=(i-3)*.29;x=math.sin(angle)*.73;y=.92+math.cos(angle)*.55
            feather=a.node("TailFeather"+str(i),body,(x,y,.30))
            organic(a,"Feather"+str(i),(0,0,0),(.17,.44,.055),"6c9b7d",feather)
            organic(a,"FeatherEye"+str(i),(0,.15,-.05),(.09,.12,.014),"d5bf7d",feather)
            organic(a,"FeatherDot"+str(i),(0,.16,-.065),(.05,.065,.009),"587f97",feather)
        hero_limbs(a,body,"73999a","9e9a74")
    elif identity=="toaster":
        solid(a,"ToasterCase",(0,.90,0),(.75,.94,.48),"bd9e7e",body)
        solid(a,"ToasterFront",(0,.89,-.255),(.62,.73,.05),"d6b28d",body)
        face(a,head,(0,1.05,-.29),.16,.10)
        for z in [-.11,.11]:
            solid(a,"ToastSlot"+str(z),(0,1.38,z),(.55,.025,.072),"594b44",head)
            solid(a,"ToastSlice"+str(z),(0,1.52,z),(.39,.27,.057),"d0a169",head)
            solid(a,"ToastCrumb"+str(z),(0,1.53,z-.035),(.31,.18,.012),"e8c790",head)
        organic(a,"ToastLever",(.43,.99,0),(.045,.045,.11),"786957",body)
        for i in range(4):solid(a,"ToastVent"+str(i),((i-1.5)*.10,.66,-.30),(.04,.07,.015),"86705b",body)
        hero_limbs(a,body,"a78b6e","6d6057")
    return a.save()


CREATURES=[
 ["beetle","ray","snail","flower","moth","spider"],
 ["toad","cap","lily","jelly","axolotl","turtle"],
 ["crab","octopus","grub","eye","star","snail"],
 ["puffer","owl","slug","jelly","dragon","worm"],
 ["lobster","crawler","clam","volcano","bat","hydra"],
 ["nautilus","jelly","squid","mantis","starfly","coral"]]
COLORS=[("86ab7c","c39161","b9c894"),("9c8ca4","a3b998","d5b69c"),("889ab8","bd9da6","c6bbd4"),
        ("b3cad0","819eb5","d4dfd0"),("bf7767","987983","e2b47a"),("a18bb7","79aab0","d7b2bd")]


def enemy_legs(a,body,count=6,color="c49a75",height=.72,width=.58):
    for i in range(count):
        side=-1 if i<count/2 else 1;z=((i%(count//2))/max(1,count//2-1)-.5)*.7
        pivot=a.node("Leg"+str(i),body,(side*width,height,z))
        sweep(a,"LegSegment"+str(i),[(0,0,0),(side*.25,-height*.30,.03),(side*.37,-height*.85,-.04),(side*.39,-height,-.15)],
              [.10,.12,.055,.004],[.10,.09,.055,.004],color,pivot)


def wing(a,parent,side,color,kind="ray"):
    pivot=a.node("Wing"+str(side),parent,(side*.22,1.03,.08))
    polygon=[(0,0),(.35,.52),(1.14,.41),(1.33,.12),(.9,-.16),(.55,-.37),(.18,-.21)] if kind!="bat" else [(0,0),(.28,.65),(1.1,.72),(.86,.18),(1.2,-.15),(.64,-.04),(.47,-.42),(.13,-.23)]
    part=panel(a,"WingSail"+str(side),polygon,.07,color,pivot)
    if side<0:a.doc["nodes"][part]["scale"]=[-1,1,1]
    for i in range(3):
        sweep(a,"WingVein%s_%s"%(side,i),[(0,.03,-.046),(side*(.55+i*.21),.35-i*.17,-.046)], [.023,.008],[.015,.008],"e4ccaa",pivot)


def creature(biome,index):
    kind=CREATURES[biome][index];main,accent,light=COLORS[biome]
    a=A("creature_%d_%d"%(biome,index));body=a.node("Body");head=a.node("Head",body)
    if kind in ["beetle","spider","crawler","mantis"]:
        organic(a,"ArmouredAbdomen",(0,.94,.33),(.61,.52,.58),main,body)
        for side in [-1,1]:
            organic(a,"SplitCarapace"+str(side),(side*.30,1.13,.26),(.33,.42,.53),accent,body)
            for j in range(3):organic(a,"ShellDot%s_%s"%(side,j),(side*.44,1.18+j*.09,.04+j*.12),(.04,.025,.04),light,body,segments=8)
        enemy_legs(a,body,8 if kind=="spider" else 6,accent)
        core(a,body,(0,1.05,-.38),.30)
        face(a,head,(0,1.51,-.30),.20,.115,False)
        for side in [-1,1]:sweep(a,"Antenna"+str(side),[(side*.20,1.4,-.15),(side*.34,1.72,-.18),(side*.45,1.79,-.23)],[.03,.02,.006],[.03,.02,.006],accent,head)
        if kind=="mantis":
            for side in [-1,1]:
                claw=a.node("Claw"+str(side),body,(side*.58,1.15,-.35))
                blade=panel(a,"MantisBlade"+str(side),[(0,0),(.23,.40),(.32,-.03),(.06,-.53),(.03,-.10)],.10,light,claw)
                if side<0:a.doc["nodes"][blade]["scale"]=[-1,1,1]
    elif kind in ["ray","moth","starfly","bat","owl","dragon","axolotl"]:
        profile(a,"WingedBody",[(.42,.05,.04,0),(.58,.25,.22,0),(1.06,.30,.27,0),(1.47,.20,.19,0),(1.63,.025,.025,0)],main,body)
        for side in [-1,1]:wing(a,body,side,accent,"bat" if kind in ["bat","dragon"] else "ray")
        core(a,body,(0,.92,-.29),.27);face(a,head,(0,1.42,-.17),.12,.10,False)
        enemy_legs(a,body,4,light,height=.51,width=.20)
        if kind in ["moth","starfly"]:
            for side in [-1,1]:
                organic(a,"WingEye"+str(side),(side*.84,1.20,0),(.19,.22,.04),main,body)
                sweep(a,"Feelers"+str(side),[(side*.11,1.51,0),(side*.25,1.8,0),(side*.36,1.84,-.03)],[.02,.02,.006],[.02,.02,.006],light,head)
        if kind=="owl":
            for side in [-1,1]:loop(a,"OwlEyeRing"+str(side),(side*.13,1.42,-.22),.12,.022,light,head)
        if kind in ["dragon","axolotl","ray"]:
            sweep(a,"LongTail",[(0,.77,.15),(0,.65,.52),(.12,.72,.90),(.18,.59,1.22),(.28,.56,1.39)],[.15,.12,.08,.04,.002],[.13,.10,.07,.035,.002],accent,body)
        if kind=="axolotl":
            for side in [-1,1]:
                for j in range(3):organic(a,"Gill%s_%s"%(side,j),(side*(.29+j*.07),1.39+j*.08,0),(.09,.055,.045),light,head)
    elif kind in ["snail","slug","grub","worm"]:
        for i in range(5):organic(a,"BodySegment"+str(i),(sin(i*.6)*.12,.44+i*.045,i*.23),(.34-i*.025,.36-i*.018,.31),main if i%2 else accent,body)
        core(a,body,(0,.64,-.27),.27)
        if kind=="snail":
            organic(a,"Shell",(0,1.09,.42),(.55,.54,.31),accent,body,texture=2 if biome==2 else 1)
            spiral(a,"CoiledShell",body,(0,1.10,.10),.50,light)
        for side in [-1,1]:
            sweep(a,"Stalk"+str(side),[(side*.11,.80,-.07),(side*.19,1.11,-.11),(side*.22,1.21,-.15)],[.035,.035,.04],[.035,.035,.04],accent,head)
        face(a,head,(0,1.24,-.18),.22,.09,False)
    elif kind in ["flower","lily","cap","jelly","hydra","octopus","squid","nautilus"]:
        if kind in ["flower","lily","hydra"]:
            sweep(a,"RootStem",[(0,.05,0),(.09,.47,0),(0,1.07,0)],[.16,.12,.08],[.13,.12,.07],main,body)
            for i in range(9):
                angle=i/9*TAU;organic(a,"Petal"+str(i),(math.cos(angle)*.43,1.18+math.sin(angle)*.43,0),(.23,.26,.095),accent if i%2 else light,head,segments=16)
            core(a,body,(0,1.18,-.09),.34)
            for side in [-1,1]:organic(a,"RootLeaf"+str(side),(side*.35,.51,0),(.39,.09,.15),main,body,skew=side*.12)
            face(a,head,(0,1.59,-.10),.22,.095,False)
            if kind=="hydra":
                for side in [-1,1]:
                    neck=a.node("Neck"+str(side),body,(side*.35,.87,.11))
                    sweep(a,"HydraNeck"+str(side),[(0,0,0),(side*.20,.30,0),(side*.39,.53,-.04)],[.10,.09,.065],[.10,.09,.065],main,neck)
                    organic(a,"HydraBud"+str(side),(side*.39,.58,-.04),(.21,.18,.16),accent,neck)
                    face(a,neck,(side*.39,.60,-.19),.08,.05)
        else:
            if kind in ["cap","jelly"]:
                profile(a,"UmbrellaHood",[(1.27,.61,.47,0),(1.35,.60,.47,0),(1.61,.41,.32,0),(1.77,.15,.13,0),(1.8,.01,.01,0)],accent,head)
            else:organic(a,"CephalopodMantle",(0,1.22,.12),(.44,.51,.32),main,body)
            for i in range(8):
                angle=i/8*TAU;x,z=math.cos(angle),math.sin(angle)
                tentacle=a.node("Leg"+str(i),body,(x*.24,.88,z*.22))
                sweep(a,"TrailingTentacle"+str(i),[(0,0,0),(x*.21,-.19,z*.14),(x*.30,-.49,z*.22),(x*.41,-.63,z*.29),(x*.46,-.51,z*.33)],
                      [.08,.075,.055,.029,.002],[.075,.075,.055,.029,.002],accent,tentacle)
            core(a,body,(0,1.06,-.30),.30);face(a,head,(0,1.48,-.25),.18,.105,False)
            if kind=="nautilus":
                organic(a,"NautilusShell",(0,1.17,.35),(.70,.65,.38),light,body,texture=2)
                spiral(a,"NautilusCoil",body,(0,1.21,-.02),.62,accent)
            if biome==5:
                loop(a,"OrbitRing",(0,1.07,.03),.75,.035,light,body)
    elif kind in ["toad","turtle","volcano","puffer"]:
        organic(a,"BroadBack",(0,.95,.12),(.70,.57,.53),main,body)
        enemy_legs(a,body,4,accent,height=.58,width=.52)
        core(a,body,(0,1.02,-.40),.34);face(a,head,(0,1.50,-.31),.30,.145,False)
        if kind in ["turtle","volcano"]:
            organic(a,"ShellDome",(0,1.15,.24),(.79,.59,.52),accent,body,texture=2)
            for side in [-1,1]:
                for j in range(3):solid(a,"ShellTile%s_%s"%(side,j),(side*.43,1.32,.0+j*.22),(.26,.10,.23),light,body)
            if kind=="volcano":profile(a,"VolcanoVent",[(1.45,.29,.26,.21),(1.88,.19,.18,.21),(1.96,.14,.13,.21),(1.96,.095,.09,.21),(1.78,.095,.09,.21)],"d68c67",head)
        elif kind=="puffer":
            for i in range(14):
                angle=i/14*TAU
                sweep(a,"PufferSpine"+str(i),[(math.cos(angle)*.65,.95+math.sin(angle)*.5,0),(math.cos(angle)*.88,.95+math.sin(angle)*.72,0)],[.045,.001],[.04,.001],light,body)
        else:
            for i in range(7):organic(a,"ToadWart"+str(i),(math.sin(i*2.4)*.58,1.21+(i%3)*.1,.12),(.06,.06,.06),light,body,segments=8)
    elif kind in ["crab","lobster","coral","clam"]:
        organic(a,"CrustaceanBack",(0,1.02,.15),(.62,.46,.45),main,body)
        enemy_legs(a,body,6,accent,height=.67,width=.50)
        core(a,body,(0,1.04,-.31),.31);face(a,head,(0,1.52,-.20),.24,.105,False)
        for side in [-1,1]:
            claw=a.node("Claw"+str(side),body,(side*.51,1.06,-.10))
            sweep(a,"ClawArm"+str(side),[(0,0,0),(side*.21,.11,-.18),(side*.24,.04,-.37)],[.105,.105,.085],[.10,.105,.08],accent,claw)
            organic(a,"Pincer"+str(side),(side*.24,.10,-.44),(.20,.23,.15),light,claw)
            solid(a,"PincerGap"+str(side),(side*.24,.26,-.46),(.055,.14,.17),main,claw)
        if kind=="clam":
            organic(a,"UpperShell",(0,1.42,.17),(.73,.23,.54),light,head)
            for i in range(7):sweep(a,"ShellRib"+str(i),[((i-3)*.13,1.43,-.25),((i-3)*.11,1.60,.12),((i-3)*.06,1.49,.54)],[.02,.02,.014],[.02,.02,.014],accent,head)
        if kind=="coral":
            for i in range(5):sweep(a,"CoralGrowth"+str(i),[(sin(i*2.4)*.44,1.31,.13),(sin(i*2.4)*.56,1.63,.18),(sin(i*2.4)*.60,1.75,.16)],[.06,.045,.017],[.06,.045,.015],light,head)
    elif kind in ["eye","star"]:
        if kind=="eye":
            organic(a,"OrbitEye",(0,1.1,0),(.61,.61,.43),light,body)
            core(a,body,(0,1.1,-.34),.37)
            for i in range(5):sweep(a,"EyeTendril"+str(i),[(math.cos(i*TAU/5)*.4,1.1+math.sin(i*TAU/5)*.4,.10),(math.cos(i*TAU/5)*.67,1.1+math.sin(i*TAU/5)*.67,.12)],[.08,.015],[.07,.01],accent,body)
        else:
            for i in range(5):
                angle=i/5*TAU
                points=[(math.cos(angle-.5)*.30,1.10+math.sin(angle-.5)*.30),(math.cos(angle)*.93,1.10+math.sin(angle)*.93),(math.cos(angle+.5)*.30,1.10+math.sin(angle+.5)*.30)]
                panel(a,"StarArm"+str(i),points,.24,accent,body)
            core(a,body,(0,1.1,-.10),.37)
    return a.save()


def weapon(identity):
    a=A("weapon_"+identity);root=a.node("Gun");steel="637d87";brass="d9b77a";wood="a47a59"
    palettes={"shotgun":"d29a70","flame":"bb7768","poison":"92aa7d","ice":"8cb8cc","rail":"a58bb4","lightning":"d7b85f","ghost":"b59aba","rocket":"cb907a"}
    color=palettes.get(identity,"9fbba8")
    grip=profile(a,"Grip",[(-.30,.06,.06,.12),(-.22,.09,.09,.10),(-.02,.08,.07,.02)],wood,root,segments=12,texture=1)
    if identity in ["boomerang","disc","saw"]:
        if identity=="boomerang":
            part=panel(a,"CurvedBoomerang",[(-.38,.04),(-.23,.20),(0,.10),(.24,.25),(.40,.15),(.10,-.12),(-.06,-.09)],.07,"b98c64",root,texture=1)
            place(a,part,(0,.08,-.25))
            for x in [-.26,.26]:solid(a,"BladeTrim"+str(x),(x,.11,-.29),(.12,.045,.02),brass,root)
        else:
            loop(a,"DiscRim",(0,.07,-.27),.29,.04,steel,root)
            organic(a,"DiscHub",(0,.07,-.27),(.14,.14,.055),brass,root)
            for i in range(12):
                angle=i/12*TAU
                tooth=panel(a,"Tooth"+str(i),[(0,0),(.09,.02),(.02,.11)],.05,brass,root)
                place(a,tooth,(math.cos(angle)*.30,.07+math.sin(angle)*.30,-.27))
    elif identity in ["flowers","bubble","gravity"]:
        profile(a,"Chamber",[(-.04,.11,.12,-.11),(.09,.15,.16,-.11),(.29,.12,.13,-.11),(.33,.08,.09,-.11)],"bea181",root)
        organic(a,"PowerGlobe",(0,.29,-.10),(.16,.19,.16),"b6cbd0" if identity=="bubble" else "aa96bd" if identity=="gravity" else "dea5b7",root)
        if identity=="flowers":
            for i in range(6):organic(a,"FlowerPetal"+str(i),(math.cos(i*TAU/6)*.14,.31+math.sin(i*TAU/6)*.11,-.19),(.085,.075,.05),"dea5b7",root,segments=12)
        else:
            loop(a,"RoundNozzle",(0,.09,-.40),.15,.025,brass,root)
            for side in [-1,1]:solid(a,"GlobeBrace"+str(side),(side*.15,.20,-.10),(.025,.25,.03),steel,root)
    elif identity=="horn":
        profile_id=profile(a,"HornBell",[(0,.05,.05,0),(.22,.07,.07,0),(.39,.21,.21,0),(.42,.24,.24,0),(.42,.20,.20,0),(.20,.035,.035,0)],brass,root,segments=20)
        a.doc["nodes"][profile_id]["rotation"]=[-math.sin(math.pi/4),0,0,math.cos(math.pi/4)]
        place(a,profile_id,(0,.10,-.10))
        loop(a,"HornLoop",(0,.06,.05),.13,.018,"ad8a58",root)
    elif identity=="bomb":
        organic(a,"BombMagazine",(0,.10,-.15),(.19,.20,.19),"6e747b",root)
        sweep(a,"LitFuse",[(0,.25,-.15),(.04,.37,-.15),(.08,.42,-.15)],[.02,.018,.012],[.02,.018,.012],brass,root)
        for side in [-1,1]:solid(a,"BombCradle"+str(side),(side*.19,.01,-.15),(.05,.16,.36),wood,root,texture=1)
    elif "turret" in identity:
        solid(a,"FoldedTurretBody",(0,.07,-.10),(.30,.24,.27),steel,root)
        for side in [-1,1]:solid(a,"FoldedLeg"+str(side),(side*.19,-.15,.05),(.065,.35,.08),brass,root)
        organic(a,"TurretSensor",(0,.25,-.12),(.12,.11,.12),color,root)
        barrel=profile(a,"TurretBarrel",[(0,.065,.065,0),(.43,.065,.065,0),(.43,.04,.04,0),(.04,.04,.04,0)],steel,root,segments=12)
        a.doc["nodes"][barrel]["rotation"]=[-math.sin(math.pi/4),0,0,math.cos(math.pi/4)];place(a,barrel,(0,.11,-.20))
    else:
        solid(a,"ShapedReceiver",(0,.08,-.12),(.23,.20,.39),color,root)
        count=3 if identity=="shotgun" else 1
        for i in range(count):
            x=(i-(count-1)*.5)*.083;length=.78 if identity in ["rail","harpoon"] else .51
            barrel=profile(a,"HollowBarrel"+str(i),[(0,.046,.046,0),(length,.052,.052,0),(length,.032,.032,0),(.02,.032,.032,0)],steel,root,segments=12)
            a.doc["nodes"][barrel]["rotation"]=[-math.sin(math.pi/4),0,0,math.cos(math.pi/4)];place(a,barrel,(x,.08,-.13))
            loop(a,"BarrelCuff"+str(i),(x,.08,-.13-length),.055,.014,brass,root)
        for z in [-.22,-.1,.02]:solid(a,"ReceiverBand"+str(z),(0,.08,z),(.25,.025,.025),brass,root)
        if identity in ["flame","poison","ice","lightning","ghost","meteor"]:
            profile(a,"Tank",[(.14,.085,.085,.03),(.40,.085,.085,.03)],brass,root,segments=12)
            organic(a,"TankCharge",(0,.44,.03),(.10,.11,.10),color,root)
        if identity=="harpoon":
            tip=panel(a,"HarpoonHead",[(-.075,0),(-.04,.17),(0,.24),(.04,.17),(.075,0),(0,.07)],.035,brass,root)
            a.doc["nodes"][tip]["rotation"]=[-math.sin(math.pi/4),0,0,math.cos(math.pi/4)];place(a,tip,(0,.08,-.85))
        if identity=="rocket":
            r=profile(a,"ReadyRocket",[(0,.09,.09,0),(.23,.085,.085,0),(.34,.002,.002,0)],"ce9076",root,segments=12)
            a.doc["nodes"][r]["rotation"]=[-math.sin(math.pi/4),0,0,math.cos(math.pi/4)];place(a,r,(0,.08,-.62))
    a.node("Muzzle",root,(0,.08,-.62 if identity not in ["rail","harpoon"] else -.95))
    return a.save()


def special_scenery(a,root,biome,variant,main,accent,light):
    if biome==2 and variant<2:
        # Broken lunar radar and a moon gate, rather than recoloured trees.
        if variant==0:
            profile(a,"RadarPillar",[(0,.65,.55,0),(5,.45,.4,0),(6,.15,.15,0)],main,root,segments=12,texture=2)
            dish=a.node("RadarDish",root,(0,6.5,0))
            grid(a,"DishBowl",lambda t,u:((.4+2.0*t)*cos(u*TAU),(.4+2.0*t)*sin(u*TAU),.8*t*t),8,24,light,dish)
            loop(a,"DishRim",(0,0,.8),2.4,.1,accent,dish)
            sweep(a,"Receiver",[(0,0,0),(0,0,-1.2)],[.13,.06],[.13,.06],accent,dish)
            for i in range(4):solid(a,"MoonPanel"+str(i),((i-1.5)*.58,2,-.5),(.4,.9,.09),"7586ac",root)
        else:
            loop(a,"MoonArch",(0,5,0),3.0,.43,main,root,depth=.65)
            for side in [-1,1]:profile(a,"ArchFoot"+str(side),[(0,.65,.55,0),(4.8,.45,.43,0)],accent,root,segments=10);place(a,len(a.doc["nodes"])-1,(side*2.8,0,0))
            for i in range(9):organic(a,"MoonRune"+str(i),(cos(i*TAU/9)*3,5+sin(i*TAU/9)*3,-.28),(.12,.12,.05),light,root,segments=8)
    elif biome==3 and variant in [1,2,3]:
        # Cloud bergs and tall floating archways with gilded rims.
        for i in range(6):organic(a,"CloudBerg"+str(i),(sin(i*2.4)*.6,1.5+i*1.1,cos(i*2.4)*.4),(1.4-i*.09,.95,1.2-i*.08),"dae5dd",root,segments=16)
        if variant==1:
            loop(a,"CloudGate",(0,6.5,-.1),2.2,.17,"d4b58b",root)
            for side in [-1,1]:sweep(a,"CloudSupport"+str(side),[(side*2.2,0,0),(side*2,3,0),(side*2.1,6,0)],[.25,.18,.12],[.25,.18,.12],main,root)
        else:
            organic(a,"CloudCrown",(0,7.5,0),(2.5,.6,1.7),"f1ead5",root,segments=20)
    elif biome==4 and variant in [0,1,5]:
        if variant==0:
            profile(a,"Volcano",[(0,2.3,2,0),(2.4,1.7,1.6,0),(4.2,1.1,1.0,0),(4.5,.8,.75,0)],"796472",root,segments=12,texture=2)
            loop(a,"LavaRim",(0,4.4,0),1.0,.15,"edb078",root);a.doc["nodes"][-1]["rotation"]=[sin(math.pi/4),0,0,cos(math.pi/4)]
            for side in [-1,1]:sweep(a,"LavaStream"+str(side),[(side*.4,4.4,-.8),(side*.9,3,-1.3),(side*1.2,.2,-2)],[.09,.15,.18],[.04,.04,.04],"e4a06f",root)
        elif variant==1:
            loop(a,"BoneArch",(0,4.2,0),2.7,.4,"d8c09e",root,depth=.7)
            for side in [-1,1]:sweep(a,"HornTower"+str(side),[(side*2.4,0,0),(side*2.6,4,0),(side*2.9,7,0),(side*1.8,8.3,0)],[.55,.43,.2,.01],[.5,.4,.16,.01],accent,root)
        else:
            profile(a,"HugeKettle",[(0,.7,.6,0),(1.2,2.0,1.8,0),(4,1.7,1.6,0),(4.5,1.6,1.5,0)],main,root,segments=16)
            loop(a,"KettleHandle",(0,5.6,0),2.4,.16,accent,root)
            sweep(a,"KettleSpout",[(1.3,3,0),(2.5,3.6,0),(3.2,5,0)],[.55,.4,.25],[.48,.37,.22],light,root)
            for i in range(3):organic(a,"EmberBubble"+str(i),((i-1)*.8,4.9+i*.8,0),(.35,.5,.35),"eaba78",root,segments=12)
    elif biome==5 and variant in [0,1,4,5]:
        if variant==1:
            for i in range(5):
                x=sin(i*2.4)*1.6;z=cos(i*2.4)*1.2
                sweep(a,"AlienCoral"+str(i),[(0,0,0),(x*.7,3,z*.7),(x,6+i*.4,z)],[.4,.27,.10],[.35,.24,.08],main if i%2 else accent,root)
                organic(a,"CoralPearl"+str(i),(x,6+i*.4,z),(.5,.5,.4),light,root,segments=16)
        else:
            loop(a,"OrbitalRing",(0,5.4,0),3.4,.24,accent,root)
            loop(a,"InnerOrbit",(0,5.4,.05),2.7,.09,light,root)
            for side in [-1,1]:sweep(a,"OrbitPylon"+str(side),[(side*2,0,0),(side*2.9,2,0),(side*3.3,5,0)],[.65,.4,.14],[.5,.3,.12],main,root,texture=2)
            if variant==0:organic(a,"OrbitPlanet",(0,5.4,0),(1.7,1.7,1.7),"b6a2c6",root,texture=2,segments=20)
            for i in range(8):organic(a,"OrbitLamp"+str(i),(cos(i*TAU/8)*3.4,5.4+sin(i*TAU/8)*3.4,-.22),(.12,.12,.09),light,root,segments=8)
    elif biome==1 and variant in [4,5]:
        profile(a,"MushroomHouse",[(0,1.25,1.1,0),(4.3,1.1,1.0,0)],"d9c6a7",root,texture=1)
        profile(a,"HouseCap",[(4.0,2.4,2.1,0),(4.7,2.1,1.8,0),(6.5,.2,.2,0)],accent,root)
        solid(a,"Door",(0,1.2,-1.05),(.75,2.1,.08),"7d7185",root)
        for side in [-1,1]:loop(a,"RoundWindow"+str(side),(side*.7,3,-.9),.35,.07,light,root)
        for i in range(6):organic(a,"RoofSpot"+str(i),(sin(i*2.4)*1.4,4.9,cos(i*2.4)*1.2),(.25,.07,.25),light,root,segments=12)
    else:return False
    return True

def scenery(biome,variant):
    a=A("prop_%d_%d"%(biome,variant));root=a.node("Scenery");main,accent,light=COLORS[biome]
    if special_scenery(a,root,biome,variant,main,accent,light):return a.save()
    if biome==0 and variant<2:
        sweep(a,"TallTrunk",[(0,0,0),(.18,1.6,.05),(-.1,3.2,.11),(.12,5,.04),(.05,6.4,0)],[.48,.35,.26,.19,.02],[.45,.33,.25,.19,.02],"cea785",root,texture=1)
        for side in [-1,1]:
            sweep(a,"Branch"+str(side),[(0,3.9,.05),(side*.87,4.4,.05),(side*1.38,5.0,0)],[.21,.14,.025],[.19,.13,.02],"cea785",root,texture=1)
        for i,(p,size) in enumerate([((0,6.0,0),(1.4,1.6,1.2)),((1.1,4.9,0),(1.3,1.2,1.1)),((-.99,5.0,0),(1.4,1.1,1.2))]):
            organic(a,"LeafCrown"+str(i),p,size,main if i%2 else light,root,segments=20)
            for j in range(7):organic(a,"LeafInk%s_%s"%(i,j),(p[0]+sin(j*2.4)*size[0]*.7,p[1]+cos(j*2.4)*size[1]*.7,p[2]-size[2]*.75),(.10,.05,.023),"698970",root,segments=8)
    elif biome==1 and variant<3:
        profile(a,"GiantStem",[(0,.31,.29,0),(3.4,.28,.26,0),(4.2,.19,.18,0)],"d1c5a4",root)
        profile(a,"GiantMushroom",[(3.5,1.75,1.5,0),(3.65,1.95,1.7,0),(4.3,1.64,1.4,0),(5,.65,.59,0),(5.1,.02,.02,0)],accent,root)
        for i in range(10):organic(a,"CapSpot"+str(i),(sin(i*2.4)*1.2,4.10+(i%3)*.20,cos(i*2.4)*1.1),(.14,.035,.13),light,root,segments=12)
    elif biome==3 and variant==0:
        for i in range(5):organic(a,"SolidCloud"+str(i),(sin(i*2.4)*1.0,1.9+(i%2)*.2,cos(i*2.4)*.7),(1.2,.65,1.0),"dae5dd",root,segments=16)
    elif variant in [2,3]:
        # Cliffs/columns with irregular profiles obstruct sight and have authored ledges.
        height=7 if biome in [2,5] else 6
        profile(a,"Crag",[(0,1.7,1.2,0),(1,1.8,1.35,.1),(2.5,1.4,1.15,.2),(height*.7,1.5,.8,.05),(height,1.0,.6,.0),(height+.3,.3,.25,.05)],accent,root,segments=7,texture=2)
        for i in range(3):solid(a,"StoneLayer"+str(i),(0,1.5+i*1.6,.12),(3.1-i*.35,.16,2.3-i*.3),light,root,texture=2)
        if biome==4:
            for i in range(3):sweep(a,"LavaSeam"+str(i),[(sin(i)*.8,.3,-1.2),(sin(i)*.7,2,-1),(sin(i)*.6,3.1,-.75)],[.045,.03,.018],[.024,.02,.015],"e5a66e",root)
    elif variant in [4,5] or biome==3:
        # Painted tower/observatory/furnace: substantially taller than enemies.
        profile(a,"TowerBody",[(0,1.35,1.2,0),(1.0,1.35,1.2,0),(7.9,.95,.9,0),(8.2,1.12,1.0,0)],main,root,segments=10,texture=2)
        for level in range(4):
            profile(a,"TowerBelt"+str(level),[(1+level*1.8,1.40-level*.09,1.23-level*.07,0),(1.18+level*1.8,1.40-level*.09,1.23-level*.07,0)],light,root,segments=10)
            for side in [-1,1]:solid(a,"Window%s_%s"%(side,level),(side*.52,1.75+level*1.8,-1.11+level*.075),(.27,.57,.06),"536e78" if biome!=4 else "dc9b71",root)
        profile(a,"TowerRoof",[(8.2,1.65,1.45,0),(10.4,.02,.02,0)],accent,root,segments=10)
        if variant==5:
            for side in [-1,1]:solid(a,"Buttress"+str(side),(side*1.35,2.5,.12),(.31,5,1.3),accent,root,texture=2)
        if biome==2:loop(a,"ObservatoryRing",(0,8.7,0),1.0,.07,light,root)
    else:
        for i in range(3):profile(a,"Crystal"+str(i),[(0,.45,.38,0),(3+i*.8,.50,.42,0),(5+i*.9,.015,.015,0)],main if i%2 else light,root,segments=5)
        for i in range(3):place(a,len(a.doc["nodes"])-3+i,((i-1)*.74,0,0))
    return a.save()


if __name__=="__main__":
    heroes=["pipe_wrench","sweet_potato","marble_bust_01","street_rat","hamburger_buns","florist","teapot","octopus","astronaut","cactus","book","snail","bee","sushi","mushroom","clock","icecream","bathtub","peacock","toaster"]
    weapons=["shotgun","flame","poison","ice","rail","lightning","saw","rocket","ghost","flowers","turret","fire-turret","ice-turret","poison-turret","lightning-turret","rocket-turret","boomerang","disc","harpoon","gravity","horn","bubble","meteor","bomb"]
    import sys
    orb_spec=importlib.util.spec_from_file_location('orb_heroes',Path(__file__).with_name('build-orb-heroes.py'))
    orb_module=importlib.util.module_from_spec(orb_spec);orb_spec.loader.exec_module(orb_module)
    report=[orb_module.build(h) for h in ['rubber_duck_toy']+heroes]
    if '--heroes-only' not in sys.argv: report+=[creature(b,i) for b in range(6) for i in range(6)]+[weapon(w) for w in weapons]+[scenery(b,i) for b in range(6) for i in range(6)]
    manifest="hero-core-manifest.json" if '--heroes-only' in sys.argv else "world-model-manifest.json"
    (OUT/manifest).write_text(json.dumps({"source":"Original authored profiles, UVs and articulated pivots; approved texture reuse","assets":report},indent=2)+"\n")
    print(json.dumps({"assets":len(report),"triangles":sum(r["triangles"] for r in report),"source_mib":sum(r["bytes"] for r in report)/1048576},indent=2))

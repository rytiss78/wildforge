"""Full 1.0 roster: carved planes, tailored silhouettes, and semantic inlays.
The existing identity recipes supply recognizable anatomy and rigid pivots;
this authoritative pass rebuilds their surfaces and adds authored costumes.
"""
import importlib.util, json, math, colorsys
from pathlib import Path

def module(name,file):
    spec=importlib.util.spec_from_file_location(name,Path(__file__).with_name(file));m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
f=module('forge','build-forge-slice.py');h=module('orb','build-orb-heroes.py');w=f.w;s=f.s
INK='111b2b';GOLD='c69a51';BONE='e4d5ac';RED='a93654';EMERALD='48db9e'
PALETTES=[('355647','7a6943','9cc08b'),('414654','905083','96ca9f'),('38465f','667ca1','8bdaed'),('52626e','ba985f','c2dad5'),('482f39','9d503e','f59a4b'),('3e345c','806298','bcb1e8')]
class Asset(f.Asset):
    def material(self,color,texture=0):
        # Explicit palette roles are used for new costume pieces. Existing anatomy
        # gets stronger pigment and lower midtones, retaining identity hues.
        if color not in [INK,GOLD,BONE,RED,EMERALD]+[c for p in PALETTES for c in p]:
            r,g,b=[int(color[i:i+2],16)/255 for i in (0,2,4)];hh,ss,vv=colorsys.rgb_to_hsv(r,g,b)
            if vv>.9 and ss<.25:color=BONE
            elif vv<.42:color=INK
            else:
                rr=colorsys.hsv_to_rgb(hh,min(.8,ss*1.5+.06),max(.28,vv*.78));color=''.join(f'{round(c*255):02x}' for c in rr)
        return super().material(color,texture)

def angular(a,name,center,scale,color,parent=None,texture=0,skew=0,segments=12):
    if 'Core' in name:return s.organic(a,name,center,scale,color,parent,segments=28)
    x,y,z=center;rx,ry,rz=scale
    rings=[(y-ry,.01,.01,z),(y-ry*.66,rx*.71,rz*.70,z),(y-ry*.05,rx,rz,z),(y+ry*.62,rx*.79,rz*.75,z),(y+ry,.01,.01,z)]
    n=s.profile(a,name,rings,color,parent,segments=8)
    a.doc['nodes'][n]['translation'][0]=x
    return n

def slit(a,parent,y=1.44,z=-.20,gap=.13,size=.09):
    for side in [-1,1]:
        f.slab(a,'InkEye',[(-size*1.2,-size*.45),(-size*.9,size*.7),(size*1.2,size*.35),(size*.8,-size*.45)],.022,INK,parent,(side*gap,y,z-.014))
        f.plate(a,'EyeGlint',(side*gap,y,z-.038),(size*.85,size*.40,.014),BONE,parent)

def garment(a,body,identity):
    botanical=identity in ['sweet_potato','florist','cactus','mushroom']
    scholar=identity in ['book','marble_bust_01','teapot','clock']
    pirate=identity in ['octopus','street_rat','peacock']
    color=RED if pirate else '385568' if scholar else '33654d' if botanical else INK
    # The orb is never covered: panels begin outside its .335 m radius.
    for side in [-1,1]:
        pivot=a.node('CapePanel'+str(side),body)
        outline=[(side*.34,1.25),(side*.58,1.12),(side*.68,.36),(side*.49,.20),(side*.37,.40)]
        if botanical:outline=[(side*.34,1.26),(side*.69,1.45),(side*.60,.94),(side*.89,.51),(side*.46,.31)]
        if scholar:outline=[(side*.34,1.20),(side*.62,1.34),(side*.57,.28),(side*.39,.12),(side*.38,.51)]
        if pirate:outline=[(side*.36,1.21),(side*.58,1.18),(side*.86,.65),(side*.73,.34),(side*.60,.50),(side*.47,.18)]
        f.slab(a,'TailoredCoat',outline,.045,color,pivot,(0,0,.25))
        f.beam(a,'GiltSeam',[(side*.42,1.17,.215),(side*.54,.79,.215),(side*.48,.35,.215)],[.018,.019,.004],GOLD,pivot)
        f.slab(a,'ShoulderGuard',[(-.13,0),(-.17,.16),(0,.24),(.23,.03),(.12,-.08)],.20,INK,body,(side*.48,1.04,.02))
    for i in range(4):
        angle=(i+.5)*math.tau/4
        f.slab(a,'VesselClasp',[(-.045,0),(0,.09),(.045,0),(0,-.07)],.04,GOLD,body,(math.sin(angle)*.37,.82+math.cos(angle)*.37,-.12))
    head=next(i for i,n in enumerate(a.doc['nodes']) if n['name']=='Head')
    if identity=='pipe_wrench':
        for side in [-1,1]:f.slab(a,'SpannerJaw',[(-.09,0),(-.13,.38),(.04,.51),(.04,.24),(.14,.13)],.25,GOLD,head,(side*.25,1.58,.01))
    elif identity=='sweet_potato':
        for i in range(3):f.slab(a,'RootCrown',[(-.06,0),(-.13,.32),(.02,.57),(.09,.21)],.05,EMERALD,head,((i-1)*.17,1.69,0))
    elif identity=='marble_bust_01':
        f.slab(a,'MourningVeil',[(-.32,1.81),(.32,1.81),(.45,1.1),(.30,1.29),(-.31,1.28),(-.45,1.1)],.055,INK,head,(0,0,.18))
    elif identity=='street_rat':
        f.slab(a,'LedgerVisor',[(-.37,1.58),(-.23,1.74),(.34,1.73),(.42,1.59),(.08,1.62)],.06,GOLD,head,(0,0,-.22))
    elif identity=='hamburger_buns':
        f.slab(a,'ChefCrest',[(-.35,1.80),(-.41,2.06),(-.20,2.14),(0,2.03),(.20,2.15),(.39,2.06),(.33,1.80)],.22,BONE,head)
    elif identity=='florist':
        for side in [-1,1]:f.slab(a,'RoseThorn',[(-.09,0),(-.20,.27),(.02,.49),(.15,.12)],.09,RED,head,(side*.20,1.71,0))
    elif identity=='teapot':
        f.slab(a,'PorcelainFinial',[(-.24,1.72),(-.12,1.96),(0,1.86),(.12,1.96),(.24,1.72)],.14,GOLD,head)
    elif identity=='octopus':
        f.slab(a,'AdmiralHat',[(-.54,1.74),(-.38,2.11),(0,1.92),(.40,2.1),(.54,1.74)],.30,INK,head)
        f.slab(a,'HatInsignia',[(-.08,1.88),(0,2.00),(.08,1.88),(0,1.80)],.03,GOLD,head,(0,0,-.17))
    elif identity=='astronaut':
        for side in [-1,1]:f.slab(a,'HelmetRidge',[(-.07,0),(-.10,.32),(0,.48),(.09,.25),(.06,0)],.22,GOLD,head,(side*.31,1.43,.04))
    elif identity=='cactus':
        for side in [-1,1]:f.beam(a,'DesertHorn',[(side*.21,1.7,0),(side*.44,1.94,0),(side*.40,2.10,0)],[.08,.045,.002],BONE,head)
    elif identity=='book':
        f.slab(a,'SplitWizardCrest',[(-.36,1.67),(-.25,2.22),(-.08,2.01),(.10,2.34),(.22,1.79),(.4,1.67)],.18,'52436f',head)
    elif identity=='snail':
        for side in [-1,1]:f.beam(a,'StalkAntler',[(side*.29,1.82,.04),(side*.46,2.04,.04),(side*.53,1.96,.04)],[.035,.018,.002],GOLD,head)
    elif identity=='bee':
        for side in [-1,1]:f.slab(a,'LanceWing',[(side*.4,.83),(side*.90,1.14),(side*1.1,1.80),(side*.64,1.50)],.035,BONE,body,(0,0,.19))
    elif identity=='sushi':
        f.slab(a,'KnifeHeadband',[(-.43,1.7),(-.29,1.80),(.40,1.81),(.35,1.68)],.24,RED,head)
    elif identity=='mushroom':
        f.slab(a,'CapGills',[(-.64,1.70),(-.50,1.59),(-.33,1.69),(-.16,1.59),(0,1.7),(.16,1.59),(.33,1.69),(.50,1.59),(.64,1.70)],.32,BONE,head)
    elif identity=='clock':
        f.beam(a,'ClockHand',[(0,1.84,-.05),(0,2.20,-.05)],[.035,.007],GOLD,head)
        for side in [-1,1]:f.slab(a,'BellEar',[(-.15,0),(-.12,.26),(0,.32),(.12,.26),(.15,0)],.22,GOLD,head,(side*.27,1.72,0))
    elif identity=='icecream':
        for i in range(3):f.slab(a,'SugarShard',[(-.05,0),(-.10,.40),(.05,.52),(.08,0)],.06,BONE,head,((i-1)*.16,1.77,.10))
    elif identity=='bathtub':
        for side in [-1,1]:f.slab(a,'BathSail',[(0,0),(side*.17,.64),(side*.54,.21)],.04,'4d98a4',body,(side*.27,1.0,.25))
    elif identity=='peacock':
        for i in range(7):
            angle=(i-3)*.32
            pts=[(math.sin(angle)*.35,.8+math.cos(angle)*.35),(math.sin(angle)*1.15-.07,.8+math.cos(angle)*1.15),(math.sin(angle)*1.40,.8+math.cos(angle)*1.40),(math.sin(angle)*1.15+.07,.8+math.cos(angle)*1.15)]
            f.slab(a,'TailBlade',pts,.03,'329785',body,(0,0,.28))
    elif identity=='toaster':
        f.slab(a,'ToastCrown',[(-.33,1.69),(-.30,2.02),(-.09,1.87),(0,2.1),(.09,1.87),(.30,2.02),(.33,1.69)],.15,GOLD,head)

class HeroAsset(Asset):
    def save(self):
        garment(self,next(i for i,n in enumerate(self.doc['nodes']) if n['name']=='Body'),self.name.removeprefix('hero_'))
        return super().save()

# Strong silhouettes replace round toy eyes and softly rounded decorative forms.
h.A=HeroAsset;h.organic=angular;h.eyes=slit
w.A=Asset;w.organic=angular
w.COLORS=PALETTES

def enemy_face(a,parent,p=(0,1.24,-.35),gap=.15,eyes=.10,mouth=True):slit(a,parent,p[1],p[2],gap,eyes)
w.face=enemy_face

def blade_wing(a,parent,side,color,kind='ray'):
    pivot=a.node('Wing'+str(side),parent,(side*.2,1.05,.08))
    points=[(0,-.3),(side*.36,-.08),(side*.92,.42),(side*.73,.65),(side*.21,.28)] if kind=='ray' else [(0,-.25),(side*.31,-.02),(side*.39,-.2),(side*.61,.17),(side*.89,.09),(side*.98,.72),(side*.31,.39)]
    f.slab(a,'WingMembrane',points,.055,color,pivot)
    f.beam(a,'WingRib',[(0,-.2,-.04),(side*.34,.15,-.04),(side*.91,.57,-.04)],[.035,.025,.003],GOLD,pivot)
w.wing=blade_wing

def creatures():
    result=[]
    for biome in range(1,6):
        for index in range(6):result.append(w.creature(biome,index))
    return result

if __name__=='__main__':
    data=json.loads((s.ROOT/'native/data/catalog.json').read_text(encoding='utf8'))
    heroes=[h.build(v['model']) for v in data['heroes'] if v['model']!='rubber_duck_toy']
    mobs=creatures()
    weapons=[w.weapon(v['id']) for v in data['weapons'] if not v.get('archetype') and v['id']!='gun']
    (s.OUT/'forge-roster-manifest.json').write_text(json.dumps({'generator':'scripts/build-forge-roster.py','heroes':heroes,'creatures':mobs,'weapons':weapons},indent=2)+'\n',encoding='utf8')
    print(json.dumps({'heroes':len(heroes),'creatures':len(mobs),'weapons':len(weapons)}))

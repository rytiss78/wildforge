"""Author the first illustrated 3D slice as editable mesh profiles and export GLB.

No bitmap assets are generated or modified. Materials reuse the approved paper,
wood and stone textures. Mesh nodes retain pivots for articulated animation.
"""
import json
import math
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "native/assets/style3d"
OUT.mkdir(parents=True, exist_ok=True)
TAU = math.tau


def sub(a, b): return tuple(x-y for x, y in zip(a, b))
def cross(a, b): return (a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0])
def normalized(v):
    n = math.sqrt(sum(x*x for x in v))
    return tuple(x/max(n, 1e-8) for x in v)
def rgb(h):
    # glTF factors are linear; the approved palette is expressed as sRGB hex.
    values = [int(h[i:i+2], 16)/255 for i in (0, 2, 4)]
    return [x/12.92 if x <= .04045 else ((x+.055)/1.055)**2.4 for x in values]+[1]


class Asset:
    def __init__(self, name):
        self.name = name
        self.doc = {"asset": {"version": "2.0", "generator": "Wildforge authored profile mesh pipeline"},
                    "scene": 0, "scenes": [{"nodes": []}], "nodes": [], "meshes": [],
                    "materials": [], "accessors": [], "bufferViews": [], "buffers": [],
                    "images": [{"uri": "../illustrated/paper.png"}, {"uri": "../illustrated/bark.png"},
                               {"uri": "../illustrated/stone.png"}],
                    "textures": [{"source": i, "sampler": 0} for i in range(3)],
                    "samplers": [{"magFilter": 9729, "minFilter": 9987, "wrapS": 10497, "wrapT": 10497}]}
        self.data = bytearray()
        self.materials = {}
        self.triangles = 0

    def material(self, color, texture=0):
        key = (color, texture)
        if key not in self.materials:
            self.materials[key] = len(self.doc["materials"])
            self.doc["materials"].append({"name": f"Paint_{color}_{texture}", "doubleSided": False,
                "pbrMetallicRoughness": {"baseColorFactor": rgb(color), "metallicFactor": 0,
                                        "roughnessFactor": 1, "baseColorTexture": {"index": texture}}})
        return self.materials[key]

    def accessor(self, values, kind, component=5126):
        flat = [x for row in values for x in row] if kind != "SCALAR" else values
        while len(self.data) % 4: self.data.append(0)
        start = len(self.data)
        fmt = "f" if component == 5126 else "I"
        self.data.extend(struct.pack("<" + fmt*len(flat), *flat))
        vi = len(self.doc["bufferViews"])
        self.doc["bufferViews"].append({"buffer": 0, "byteOffset": start, "byteLength": len(self.data)-start})
        accessor = {"bufferView": vi, "componentType": component, "count": len(values), "type": kind}
        if kind == "VEC3":
            accessor["min"] = [min(v[i] for v in values) for i in range(3)]
            accessor["max"] = [max(v[i] for v in values) for i in range(3)]
        self.doc["accessors"].append(accessor)
        return len(self.doc["accessors"])-1

    def node(self, name, parent=None, translation=(0, 0, 0)):
        n = len(self.doc["nodes"])
        self.doc["nodes"].append({"name": name, "translation": list(translation)})
        if parent is None: self.doc["scenes"][0]["nodes"].append(n)
        else: self.doc["nodes"][parent].setdefault("children", []).append(n)
        return n

    def mesh(self, name, vertices, triangles, uvs, color, parent=None, texture=0):
        normals = [[0., 0., 0.] for _ in vertices]
        for tri in triangles:
            a, b, c = (vertices[i] for i in tri)
            normal = cross(sub(b, a), sub(c, a))
            for v in tri:
                for axis in range(3): normals[v][axis] += normal[axis]
        normals = [normalized(n) for n in normals]
        indices = [x for tri in triangles for x in tri]
        primitive = {"attributes": {"POSITION": self.accessor(vertices, "VEC3"),
                                    "NORMAL": self.accessor(normals, "VEC3"),
                                    "TEXCOORD_0": self.accessor(uvs, "VEC2")},
                     "indices": self.accessor(indices, "SCALAR", 5125), "material": self.material(color, texture)}
        self.doc["meshes"].append({"name": name, "primitives": [primitive]})
        n = self.node(name, parent)
        self.doc["nodes"][n]["mesh"] = len(self.doc["meshes"])-1
        self.triangles += len(triangles)
        return n

    def save(self):
        self.doc["buffers"] = [{"byteLength": len(self.data)}]
        js = json.dumps(self.doc, separators=(",", ":")).encode()
        while len(js) % 4: js += b" "
        while len(self.data) % 4: self.data.append(0)
        total = 12+8+len(js)+8+len(self.data)
        with (OUT / (self.name+".glb")).open("wb") as f:
            f.write(struct.pack("<III", 0x46546C67, 2, total))
            f.write(struct.pack("<II", len(js), 0x4E4F534A)); f.write(js)
            f.write(struct.pack("<II", len(self.data), 0x004E4942)); f.write(self.data)
        return {"asset": self.name, "triangles": self.triangles, "mesh_nodes": len(self.doc["meshes"]), "bytes": total}


def grid(asset, name, fn, rows, columns, color, parent=None, texture=0, reverse=False):
    points, uv, tri = [], [], []
    for j in range(rows+1):
        for i in range(columns+1):
            u, v = i/columns, j/rows
            points.append(fn(u, v)); uv.append((u, v))
    for j in range(rows):
        for i in range(columns):
            a = j*(columns+1)+i; b = a+1; c = a+columns+1; d = c+1
            tri.extend([(a, c, b), (b, c, d)] if not reverse else [(a, b, c), (b, d, c)])
    return asset.mesh(name, points, tri, uv, color, parent, texture)


def profile(asset, name, rings, color, parent=None, segments=24, texture=0):
    # Each hand-authored ring is (height, half-width, half-depth, z-offset).
    pts, uv, tri = [], [], []
    for j, (y, rx, rz, dz) in enumerate(rings):
        for i in range(segments+1):
            a = TAU*i/segments
            pts.append((math.cos(a)*rx, y, math.sin(a)*rz+dz)); uv.append((i/segments, j/(len(rings)-1)))
    for j in range(len(rings)-1):
        for i in range(segments):
            a=j*(segments+1)+i; b=a+1; c=a+segments+1; d=c+1
            tri.extend([(a,c,b),(b,c,d)])
    return asset.mesh(name, pts, tri, uv, color, parent, texture)


def organic(asset, name, center, scale, color, parent=None, texture=0, skew=0, segments=24):
    # Shaped, UV-authored organic surface. Slight asymmetry prevents toy sphere silhouettes.
    def fn(u, v):
        a, p = u*TAU, v*math.pi
        r=math.sin(p)
        shape=1+.045*math.sin(a*3+p*2)*r
        return (center[0]+math.cos(a)*r*scale[0]*shape+skew*r*r,
                center[1]+math.cos(p)*scale[1],
                center[2]+math.sin(a)*r*scale[2]*shape)
    return grid(asset, name, fn, 12, segments, color, parent, texture, reverse=True)


def sweep(asset, name, centers, widths, depths, color, parent=None, texture=0):
    pts, uv, tri=[],[],[]
    n=10
    for j, c in enumerate(centers):
        for i in range(n+1):
            a=i/n*TAU
            pts.append((c[0]+math.cos(a)*widths[j], c[1], c[2]+math.sin(a)*depths[j]));uv.append((i/n,j/(len(centers)-1)))
    for j in range(len(centers)-1):
        for i in range(n):
            a=j*(n+1)+i;b=a+1;c=a+n+1;d=c+1
            tri.extend([(a,c,b),(b,c,d)] if centers[-1][1]>=centers[0][1] else [(a,b,c),(b,d,c)])
    return asset.mesh(name,pts,tri,uv,color,parent,texture)


def loop(asset, name, center, radius, tube, color, parent=None, depth=1):
    def fn(u,v):
        a,b=u*TAU,v*TAU
        rr=radius+tube*math.cos(b)
        return (center[0]+rr*math.cos(a),center[1]+rr*math.sin(a),center[2]+tube*math.sin(b)*depth)
    return grid(asset,name,fn,10,40,color,parent,reverse=True)


def panel(asset,name,polygon,depth,color,parent=None,texture=0):
    # Extruded custom silhouette, including closed end caps; not a scaled primitive.
    pts=[(x,y,-depth/2) for x,y in polygon]+[(x,y,depth/2) for x,y in polygon]
    n=len(polygon);tri=[]
    for i in range(1,n-1): tri.extend([(0,i+1,i),(n,n+i,n+i+1)])
    for i in range(n):
        j=(i+1)%n;tri.extend([(i,j,n+i),(j,n+j,n+i)])
    xs=[p[0] for p in polygon];ys=[p[1] for p in polygon]
    uv=[((p[0]-min(xs))/max(.01,max(xs)-min(xs)),(p[1]-min(ys))/max(.01,max(ys)-min(ys))) for p in pts]
    return asset.mesh(name,pts,tri,uv,color,parent,texture)


def duck():
    a=Asset("count_duck")
    body=a.node("Body")
    profile(a,"TailoredCoat",[(.3,.05,.04,.10),(.40,.40,.27,.08),(.55,.49,.34,.08),(.86,.47,.36,0),(1.02,.32,.23,0),(1.08,.06,.05,0)],"34313f",body)
    # Back cape consists of curved draped panels with scalloped, curling hems.
    cape=a.node("Cape",body)
    def cape_fn(u,v):
        angle=(u-.5)*2.9
        radius=.33+v*.62
        return (math.sin(angle)*radius,1.14-v*.86+.065*math.cos(u*TAU*4)*v**4,
                .22+math.cos(angle)*(.12+v*.48)+.035*math.sin(v*math.pi))
    grid(a,"VelvetCape",cape_fn,14,32,"912b3c",cape,reverse=True)
    # Two-sided fabric lining is actual geometry rather than a billboard.
    grid(a,"CapeLining",lambda u,v:tuple(c+(0.015 if i==2 else 0) for i,c in enumerate(cape_fn(u,v))),14,32,"bd4c50",cape)
    collar=a.node("Collar",body)
    for s in [-1,1]:
        p=panel(a,"HighCollar"+str(s),[(0,0),(.13,.18),(.60,.30),(.43,-.12),(.08,-.15)],.045,"262632",collar)
        a.doc["nodes"][p]["translation"]=[s*.07,1.1,.09]
        if s<0:a.doc["nodes"][p]["scale"]=[-1,1,1]
    head=a.node("Head",body,(0,1.36,-.04))
    profile(a,"DuckHead",[(-.3,.04,.04,0),(-.25,.28,.25,-.025),(-.13,.37,.30,-.03),(.05,.39,.30,0),(.23,.30,.25,.015),(.30,.12,.11,.02),(.32,.01,.01,.02)],"f5c456",head,segments=32)
    beak=a.node("Bill",head,(0,-.14,-.34))
    profile(a,"BroadUpperBill",[(-.06,.18,.13,-.04),(-.025,.28,.20,-.05),(.045,.27,.19,-.03),(.09,.13,.09,0)],"e7a24b",beak)
    profile(a,"LowerBill",[(-.09,.10,.08,-.04),(-.08,.25,.17,-.04),(-.062,.25,.17,-.04)],"a36537",beak)
    for s in [-1,1]:
        organic(a,"Nostril"+str(s),(s*.12,.065,-.17),(.025,.014,.035),"60452f",beak)
        organic(a,"EyeWhite"+str(s),(s*.23,.06,-.245),(.135,.115,.055),"fff2d3",head)
        organic(a,"Pupil"+str(s),(s*.24,.04,-.298),(.045,.068,.025),"342d35",head)
        organic(a,"EyeShine"+str(s),(s*.24-.012,.065,-.319),(.012,.018,.009),"ffffff",head)
        eyebrow=panel(a,"AngryBrow"+str(s),[(-.14,.02),(.13,-.03),(.14,.015),(-.12,.08)],.038,"674832",head)
        a.doc["nodes"][eyebrow]["translation"]=[s*.23,.16,-.29]
        if s>0:a.doc["nodes"][eyebrow]["scale"]=[-1,1,1]
    # Gold hair tuft, little crown, lace ruff and embroidered waistcoat.
    for i in range(3):
        sweep(a,"HairCurl"+str(i),[(0,.27,.02),(-.02+i*.025,.39,.015),(.07+i*.025,.42,-.02),(.09+i*.025,.37,-.02)],[.055,.035,.025,.003],[.045,.03,.02,.003],"d69b38",head)
    for s in [-1,0,1]:
        panel_id=panel(a,"CrownPoint"+str(s),[(-.04,0),(.04,0),(.025,.08),(0,.16),(-.02,.07)],.045,"e2b861",head)
        a.doc["nodes"][panel_id]["translation"]=[s*.075,.3,.12]
    for i in range(8):
        x=(i-3.5)*.046;y=1.03-abs(x)*.26
        organic(a,"LaceRuff"+str(i),(x,y,-.27),(.06,.085,.025),"f6ebd2",body)
    panel_id=panel(a,"CreamCravat",[(-.08,0),(.08,0),(.13,-.29),(.035,-.24),(0,-.34),(-.06,-.23),(-.12,-.28)],.05,"f4dfbb",body)
    a.doc["nodes"][panel_id]["translation"]=[0,1.02,-.38]
    organic(a,"GoldBrooch",(0,1.055,-.405),(.065,.075,.025),"d8a64e",body)
    for s in [-1,1]:
        for i in range(3):organic(a,"CoatButton%s_%s"%(s,i),(s*.16,.55+i*.12,-.315),(.03,.03,.025),"e0b35c",body)
        leg=a.node("Leg"+str(s),body,(s*.22,.30,0))
        sweep(a,"Ankle"+str(s),[(0,0,0),(0,-.1,-.02),(0,-.18,-.03)],[.07,.08,.08],[.065,.07,.08],"dca04b",leg)
        organic(a,"WebbedFoot"+str(s),(s*.025,-.22,-.11),(.21,.07,.26),"e5a444",leg,skew=s*.035)
        for j in [-1,0,1]:
            sweep(a,"Toe%s_%s"%(s,j),[(j*.075,-.24,-.11),(j*.11,-.24,-.26),(j*.12,-.24,-.32)],[.03,.025,.002],[.025,.03,.005],"a96e34",leg)
        arm=a.node("Arm"+str(s),body,(s*.44,.95,0))
        sweep(a,"CoatSleeve"+str(s),[(0,.02,0),(s*.04,-.15,-.05),(s*.04,-.28,-.15)],[.11,.12,.085],[.12,.13,.09],"34313f",arm)
        organic(a,"LaceCuff"+str(s),(s*.04,-.27,-.15),(.10,.045,.10),"f6ebd2",arm)
        organic(a,"Hand"+str(s),(s*.04,-.33,-.18),(.10,.085,.09),"f3c358",arm)
        a.node("HandSocket"+str(s),arm,(s*.04,-.30,-.24))
    return a.save()


def bottlebite():
    a=Asset("bottlebite")
    body=a.node("Body")
    # A true open ring-body: the core is visible through its front AND back.
    loop(a,"HollowShell",(0,1.15,0),.60,.22,"429b92",body,depth=1.75)
    loop(a,"FrontBrassLip",(0,1.15,-.34),.55,.047,"d7ac65",body)
    loop(a,"RearBrassLip",(0,1.15,.34),.55,.047,"d7ac65",body)
    core=a.node("CoreSocket",body,(0,1.15,0))
    organic(a,"GlassCore",(0,0,0),(.50,.50,.50),"91cfc7",core,segments=40)
    for i in range(12):
        angle=i/12*TAU
        organic(a,"ShellStud"+str(i),(math.cos(angle)*.61,1.15+math.sin(angle)*.61,-.36),(.043,.043,.038),"f1d5a1",body)
    # Eyestalks and hilariously suspicious eyebrows leave the core unobstructed.
    for s in [-1,1]:
        eye=a.node("Eye"+str(s),body,(s*.38,1.78,-.20))
        sweep(a,"EyeStem"+str(s),[(0,-.14,.13),(s*.035,-.02,.03),(s*.045,.15,0)],[.055,.05,.075],[.055,.05,.06],"deab6c",eye)
        organic(a,"EyeWhite"+str(s),(s*.045,.18,-.025),(.18,.16,.13),"fff0ce",eye)
        organic(a,"Pupil"+str(s),(s*.025,.17,-.145),(.06,.085,.026),"383444",eye)
        organic(a,"EyeShine"+str(s),(s*.025-.02,.2,-.167),(.018,.02,.009),"ffffff",eye)
        b=panel(a,"Brow"+str(s),[(-.17,.0),(.15,-.04),(.17,.02),(-.16,.09)],.04,"a45648",eye)
        a.doc["nodes"][b]["translation"]=[s*.045,.29,-.09]
        if s>0:a.doc["nodes"][b]["scale"]=[-1,1,1]
    jaw=a.node("Jaw",body,(0,.56,-.27))
    profile(a,"SnappingJaw",[(-.10,.05,.03,-.05),(-.05,.39,.15,-.06),(.015,.47,.20,-.07),(.09,.43,.14,-.06)],"c9725f",jaw)
    for i in range(7):
        x=(i-3)*.10
        profile(a,"Tooth"+str(i),[(.06,.039,.037,-.19),(.19 if i%2 else .15,.002,.002,-.20)],"f6e6c0",jaw,segments=8)
        a.doc["nodes"][-1]["translation"]=[x,0,0]
    for s in [-1,1]:
        for z in [-.23,.27]:
            leg=a.node("Leg%s_%s"%(s,z),body,(s*.65,.88,z))
            sweep(a,"SegmentedLeg%s_%s"%(s,z),[(0,0,0),(s*.16,-.10,z*.2),(s*.29,-.36,0),(s*.20,-.75,-.09),(s*.16,-.86,-.18)],
                  [.09,.12,.12,.065,.005],[.09,.10,.10,.07,.005],"c6755d",leg)
            organic(a,"Knee%s_%s"%(s,z),(s*.29,-.36,0),(.12,.13,.12),"e4b978",leg)
    # Cork horns and shell vents make the object feel assembled around the bottle.
    for s in [-1,1]:
        sweep(a,"Horn"+str(s),[(s*.65,1.48,.15),(s*.91,1.56,.18),(s*1.04,1.73,.18)],[.105,.08,.002],[.11,.09,.002],"c99b60",body,texture=1)
        for i in range(3):
            organic(a,"Vent%s_%s"%(s,i),(s*.77,1.1+i*.12,.03),(.018,.037,.11),"285b61",body)
    return a.save()


def pistol():
    a=Asset("mint_pistol")
    root=a.node("Gun")
    # Modeled from the approved mint/brass pistol silhouette. Forward is -Z.
    grip=a.node("Grip",root,(0,-.07,.05))
    profile(a,"CarvedWoodGrip",[(-.30,.055,.07,.07),(-.28,.09,.09,.07),(-.16,.09,.075,.03),(-.03,.085,.07,0),(.04,.04,.04,0)],"a7754c",grip,segments=16,texture=1)
    for y in [-.20,-.07]:organic(a,"GripPin"+str(y),(.092,y,.025),(.015,.022,.023),"edc78b",grip)
    frame=a.node("Frame",root)
    # A shaped receiver profile, hollow barrel and cuffs rather than a textured card.
    profile(a,"MintReceiver",[(-.055,.07,.19,-.09),(-.025,.105,.25,-.10),(.11,.105,.25,-.10),(.15,.075,.20,-.10)],"76b4b1",frame,segments=12)
    barrel=a.node("Barrel",root,(0,.075,-.27))
    # Orient a lathed hollow tube along the gun's forward direction.
    tube=profile(a,"HollowBarrel",[(0,.10,.10,0),(.31,.10,.10,0),(.34,.12,.12,0),(.38,.12,.12,0),(.38,.074,.074,0),(.03,.074,.074,0)],"82c4bf",barrel,segments=24)
    a.doc["nodes"][tube]["rotation"]=[-math.sin(math.pi/4),0,0,math.cos(math.pi/4)]
    for z in [-.02,-.24,-.60]:
        ring=loop(a,"BrassCuff"+str(z),(0,.075,z),.105,.017,"e3bb79",root)
    loop(a,"TriggerGuard",(0,-.115,-.055),.065,.012,"cca164",root,depth=4)
    for s in [-1,1]:
        organic(a,"ReceiverScrew"+str(s),(s*.108,.02,-.13),(.012,.022,.023),"eac587",root)
        organic(a,"SideRivet"+str(s),(s*.10,.10,-.27),(.012,.017,.017),"536b68",root)
    a.node("Muzzle",root,(0,.075,-.66))
    return a.save()


def tree():
    a=Asset("storybook_tree")
    root=a.node("Tree")
    sweep(a,"TwistedTrunk",[(0,0,0),(.12,1,.04),(-.1,2.1,.08),(.13,3.2,.04),(.08,4.2,0)],
          [.43,.30,.25,.17,.035],[.40,.32,.23,.18,.04],"d8b38b",root,texture=1)
    for s in [-1,1]:
        sweep(a,"Root"+str(s),[(0,.35,0),(s*.45,.16,.15),(s*.83,.015,.27)],
              [.25,.18,.015],[.27,.22,.02],"caa079",root,texture=1)
        sweep(a,"Branch"+str(s),[(0,2.6,.04),(s*.64,3,.03),(s*1.0,3.5,0)],
              [.20,.12,.02],[.20,.14,.03],"d8b38b",root,texture=1)
    for i,(c,sz) in enumerate([((0,4.4,0),(1.1,1.0,.90)),((-.85,3.6,0),(.95,.83,.86)),((.95,3.75,.05),(1.0,.92,.9)),((.20,3.6,.65),(.95,.75,.70))]):
        organic(a,"LeafCrown"+str(i),c,sz,["79a68d","91b399","699780","a4bea0"][i],root,segments=20)
        for j in range(5):
            angle=j/5*TAU
            organic(a,"LeafDetail%s_%s"%(i,j),(c[0]+math.cos(angle)*sz[0]*.65,c[1]+math.sin(angle)*sz[1]*.65,c[2]-sz[2]*.7),(.13,.09,.025),"c4cea5",root,segments=12)
    return a.save()


def bullet():
    a=Asset("brass_bullet")
    root=a.node("Bullet")
    mesh=profile(a,"PaintedSlug",[(0,.018,.018,0),(.13,.025,.025,0),(.24,.012,.012,0),(.29,.001,.001,0)],"f5cf8b",root,segments=12)
    a.doc["nodes"][mesh]["rotation"]=[-math.sin(math.pi/4),0,0,math.cos(math.pi/4)]
    return a.save()


if __name__ == "__main__":
    report=[duck(),bottlebite(),pistol(),tree(),bullet()]
    (OUT/"model-manifest.json").write_text(json.dumps({"pipeline":"authored mesh profiles / reused approved textures", "assets":report},indent=2)+"\n")
    print(json.dumps(report,indent=2))

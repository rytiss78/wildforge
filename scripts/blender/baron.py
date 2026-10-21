"""Blender pipeline: original floating Baron as fused, sculpt-like forms.

Run: blender -b --factory-startup -P scripts/blender/baron.py -- native/assets/style3d/boss_8_baron.glb
Metaballs fuse soft volumes into one continuous body; negative elements carve fat
creases. Each part is voxel-remeshed, decimated and smooth-shaded, and a cavity
pass bakes darker creases into vertex colours. Parts hang from pivot empties
named for the game's rig (Body, Head, Arm-1/Arm1, Leg-1/Leg1). Face is +Y here,
which glTF exports as -Z. No third-party mesh, texture or likeness is used.
"""
import sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
import forge

SKIN='d1c9b8';EYE='1a1c1e';LIP='7a6a66'

def build(out):
    forge.reset()
    body=forge.pivot('Body',(0,0,0))
    head=forge.pivot('Head',(0,0,2.30),body)
    torso=forge.blob('BareTorso',[
        # Pear-shaped trunk: the belly sags forward and down, wider than he is tall.
        ('ellipsoid',(0,.18,1.12),1.0,(1.08,1.0,.88)),
        ('ellipsoid',(0,.40,.86),.78,(1.0,.85,.62)),
        ('ellipsoid',(0,.10,1.72),.86,(1.02,.82,.62)),
        ('ellipsoid',(0,-.25,1.45),.82,(1.0,.72,.95)),
        ('ellipsoid',(0,-.04,.76),.80,(.98,.82,.55)),
        ('ellipsoid',(-.38,.58,1.78),.34,(1,.8,.75)),('ellipsoid',(.38,.58,1.78),.34,(1,.8,.75)),
        ('ellipsoid',(-.98,0,1.25),.36,(.8,1,1.1)),('ellipsoid',(.98,0,1.25),.36,(.8,1,1.1)),
        ('ellipsoid',(-.84,0,2.02),.42,(1,1,.85)),('ellipsoid',(.84,0,2.02),.42,(1,1,.85)),
        ('ellipsoid',(0,.04,2.22),.48,(1.05,.95,.62)),
        # Negative capsules carve the belly and chest folds.
        ('crease',(0,1.02,1.28),.09,.62,0),('crease',(0,.98,.98),.08,.55,0),
        ('crease',(0,.84,1.56),.07,.58,0),('crease',(0,.62,1.92),.06,.42,0),
        ('crease',(-.95,.25,1.08),.06,.22,1.2),('crease',(.95,.25,1.08),.06,.22,-1.2),
        # Chest separation, navel and a collarbone hollow give the mass structure.
        ('carve',(0,.86,1.62),(0,.80,1.95),.05),
        ('hollow',(0,1.17,1.10),.06,(1,1,1.3)),
        ('carve',(-.55,.42,2.16),(-.18,.52,2.12),.04),('carve',(.55,.42,2.16),(.18,.52,2.12),.04),
    ],SKIN,body,cavity=1.35,voxel=.022,ratio=.12)
    forge.blob('BaldHead',[
        # Large bald cranium over heavy jowls and a double chin.
        ('ellipsoid',(0,.02,2.74),.38,(.92,.98,1.0)),
        ('ellipsoid',(-.21,.20,2.52),.20,(1,1,1.05)),('ellipsoid',(.21,.20,2.52),.20,(1,1,1.05)),
        ('ellipsoid',(0,.20,2.37),.25,(1.5,1.0,.62)),
        ('ellipsoid',(0,.16,2.29),.30,(1.6,1.0,.45)),
        # Heavy brow, sunken eyes, broad nose, lips and mouth line.
        ('segment',(-.20,.32,2.79),(.20,.32,2.79),.065),
        ('hollow',(-.12,.38,2.70),.06,(1.3,.8,.8)),('hollow',(.12,.38,2.70),.06,(1.3,.8,.8)),
        ('ellipsoid',(0,.41,2.62),.085,(1,1.25,1.15)),
        ('ellipsoid',(-.05,.43,2.575),.04,(1,1,.9)),('ellipsoid',(.05,.43,2.575),.04,(1,1,.9)),
        ('segment',(-.09,.40,2.49),(.09,.40,2.49),.035),
        ('carve',(-.13,.43,2.465),(.13,.43,2.465),.016),
        ('carve',(-.20,.35,2.56),(-.15,.42,2.47),.015),('carve',(.20,.35,2.56),(.15,.42,2.47),.015),
        ('ellipsoid',(-.36,.02,2.68),.08,(.5,1,1.45)),('ellipsoid',(.36,.02,2.68),.08,(.5,1,1.45)),
    ],SKIN,head,cavity=1.6,voxel=.01,ratio=.25)
    for side in [-1,1]:
        forge.ball('Eye',(side*.12,.36,2.70),(.032,.014,.02),EYE,head)
        arm=forge.pivot('Arm'+str(side),(side*.92,0,2.0),body)
        forge.blob('Arm',[
            ('segment',(side*.92,0,2.0),(side*1.12,.05,1.25),.33),
            ('ellipsoid',(side*1.05,-.12,1.55),.26,(1,1,1.3)),
            ('segment',(side*1.12,.05,1.25),(side*1.20,.18,.74),.22),
            ('ellipsoid',(side*1.22,.24,.56),.15,(.85,1.1,1.15)),
            ('carve',(side*1.0,.30,1.28),(side*1.25,.20,1.24),.035),
        ]+[('segment',(side*(1.17+f*.035),.30,.50),(side*(1.17+f*.04),.36,.36),.035) for f in range(4)],SKIN,arm,cavity=1.2,voxel=.014,ratio=.18)
        leg=forge.pivot('Leg'+str(side),(side*.42,0,.62),body)
        forge.blob('Leg',[
            ('segment',(side*.42,0,.62),(side*.47,.08,.26),.30),
            ('segment',(side*.47,.08,.26),(side*.47,.0,.06),.17),
            ('ellipsoid',(side*.47,.08,.03),.11,(.9,1.5,.6)),
        ],SKIN,leg,cavity=1.2,voxel=.016,ratio=.18)
    forge.export(out,height=3.0)

if __name__=='__main__':
    build(sys.argv[sys.argv.index('--')+1])


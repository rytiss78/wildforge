"""Render a before/after close-up of GLB models for quick visual review.

Run: blender -b --factory-startup -P scripts/blender/preview.py -- out.png left.glb right.glb [...pairs]
Each pair is shown side by side (left = original, right = refined), front three-quarter view.
"""
import math
import sys
import bpy
from mathutils import Vector

def frame(objs):
    corners=[o.matrix_world@Vector(c) for o in objs if o.type=='MESH' for c in o.bound_box]
    low=Vector((min(c.x for c in corners),min(c.y for c in corners),min(c.z for c in corners)))
    high=Vector((max(c.x for c in corners),max(c.y for c in corners),max(c.z for c in corners)))
    return low,high

def main():
    args=sys.argv[sys.argv.index('--')+1:];out=args[0];models=args[1:]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene=bpy.context.scene
    x=0.0;spacing=0.0
    for path in models:
        before=set(scene.objects)
        bpy.ops.import_scene.gltf(filepath=path)
        new=[o for o in scene.objects if o not in before]
        roots=[o for o in new if o.parent is None]
        low,high=frame(new);size=max(high-low)
        scale=2.0/size
        for root in roots:
            root.scale=root.scale*scale
        bpy.context.view_layer.update()
        low,high=frame(new)
        for root in roots:
            root.location.x+=x-(low.x+high.x)/2;root.location.z-=low.z
        x+=2.6
    camera=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));scene.collection.objects.link(camera)
    width=x-2.6
    # Models face +Y (glTF -Z); look back at them from a front three-quarter view.
    distance=max(6.0,width*1.05+3.5)
    camera.location=(width/2,distance,1.6);camera.rotation_euler=(math.radians(88),0,math.radians(180))
    camera.data.lens=45
    scene.camera=camera
    sun=bpy.data.objects.new('Sun',bpy.data.lights.new('Sun','SUN'));sun.data.energy=3.0
    sun.rotation_euler=(math.radians(50),math.radians(10),math.radians(35));scene.collection.objects.link(sun)
    world=bpy.data.worlds.new('World');world.use_nodes=True;world.node_tree.nodes['Background'].inputs['Color'].default_value=(.06,.08,.11,1);world.node_tree.nodes['Background'].inputs['Strength'].default_value=1.2;scene.world=world
    scene.render.engine='BLENDER_EEVEE' if 'BLENDER_EEVEE' in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items] else 'BLENDER_EEVEE_NEXT'
    scene.render.resolution_x=1800;scene.render.resolution_y=640
    scene.render.filepath=out;bpy.ops.render.render(write_still=True)
    print('PREVIEW',out)

main()

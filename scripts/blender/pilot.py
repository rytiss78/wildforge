"""Model pilot (Phase E): Count Duck and the Briar Beetle rebuilt by hand-directed
subdivision modelling instead of metaballs or profile sweeps.

Each part is a blocked low-poly cage (lathed rings or an extruded outline) with
creased edges, smoothed by a Subdivision Surface, then painted per vertex with a
top-down light gradient and baked cavity (forge.paint). Node names, pivots, hand
sockets and the GlassCore health orb match the shipped models, so the pilot can
drop into StyleModel unchanged for a side-by-side at the gameplay camera.

Run: blender -b --factory-startup -P scripts/blender/pilot.py -- <output folder>
Blender axes: x right, y front, z up (glTF -Z front after export).
"""
import math
import os
import sys
import bmesh
import bpy
from mathutils import Vector, Matrix

sys.path.append(os.path.dirname(__file__))
import forge

TAU = math.tau


def mesh_object(name, bm, parent):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(name); bm.to_mesh(mesh); bm.free()
    obj = bpy.data.objects.new(name, mesh); bpy.context.scene.collection.objects.link(obj)
    forge.attach(obj, parent)
    return obj


def smooth(obj, level, color, cavity=1.0, light=.32):
    if level > 0: forge.apply(obj, 'SUBSURF', levels=level, render_levels=level)
    forge.finish(obj, color, None, cavity)
    # Painted light from above: the lower part of each form a little darker.
    mesh = obj.data; attribute = mesh.color_attributes['Col']
    zs = [(obj.matrix_world @ v.co).z for v in mesh.vertices]; low, high = min(zs), max(zs)
    for i, z in enumerate(zs):
        f = (1 - light) + light * ((z - low) / max(high - low, 1e-4)) * 1.4
        r, g, b, a = attribute.data[i].color
        attribute.data[i].color = (min(1, r * f), min(1, g * f), min(1, b * f), a)
    return obj


def crease(bm, edges, value):
    # The layer is created with the BMesh: adding a layer later invalidates element references.
    layer = bm.edges.layers.float.get('crease_edge')
    for e in edges: e[layer] = value


def lathe(name, rings, color, parent=None, segments=12, level=2, creased=(), crease_value=.8, arc=None, cavity=1.0, light=.32):
    """rings: (z, rx, ry, cy): an elliptical ring at height z, centred cy along y."""
    bm = bmesh.new(); bm.edges.layers.float.new('crease_edge'); loops = []
    for z, rx, ry, cy in rings:
        loop = []
        for i in range(segments):
            a = TAU * i / segments if arc is None else arc[0] + (arc[1] - arc[0]) * i / (segments - 1)
            loop.append(bm.verts.new((math.cos(a) * rx, cy + math.sin(a) * ry, z)))
        loops.append(loop)
    closed = arc is None
    for k in range(len(loops) - 1):
        for i in range(segments if closed else segments - 1):
            j = (i + 1) % segments
            bm.faces.new((loops[k][i], loops[k][j], loops[k + 1][j], loops[k + 1][i]))
    if closed:
        bm.faces.new(list(reversed(loops[0]))); bm.faces.new(loops[-1])
    bm.edges.ensure_lookup_table()
    for k in creased:
        ring = set(loops[k]); crease(bm, [e for e in bm.edges if e.verts[0] in ring and e.verts[1] in ring], crease_value)
    return smooth(mesh_object(name, bm, parent), level, color, cavity, light)


def slab(name, outline, thickness, color, parent=None, plane='xy', at=(0, 0, 0), level=2, crease_value=.65, cavity=.8, light=.25):
    """An outline extruded into a slab. plane 'xy': outline (x,y) extruded up z;
    'xz': outline (x,z) extruded back along -y."""
    bm = bmesh.new(); bm.edges.layers.float.new('crease_edge'); ax, ay, az = at
    if plane == 'xy': verts = [bm.verts.new((ax + u, ay + v, az)) for u, v in outline]; push = Vector((0, 0, thickness))
    else: verts = [bm.verts.new((ax + u, ay, az + v)) for u, v in outline]; push = Vector((0, -thickness, 0))
    face = bm.faces.new(verts)
    result = bmesh.ops.extrude_face_region(bm, geom=[face])
    moved = [g for g in result['geom'] if isinstance(g, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=push, verts=moved)
    bm.edges.ensure_lookup_table()
    # Crease the outline rings (front and back caps) so the slab keeps its drawn edge.
    caps = [f for f in bm.faces if len(f.verts) == len(outline)]
    if len(caps) < 2: print('PILOT_WARNING open slab', name)
    crease(bm, [e for f in caps for e in f.edges], crease_value)
    return smooth(mesh_object(name, bm, parent), level, color, cavity, light)


def ellipsoid(name, center, size, color, parent=None, light=.2):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, location=center)
    obj = bpy.context.view_layer.objects.active; obj.name = name; obj.scale = size
    bpy.ops.object.transform_apply(scale=True)
    forge.attach(obj, parent)
    return smooth(obj, 0, color, 0.0, light)


def tube(name, a, b, r0, r1, color, parent=None):
    a = Vector(a); b = Vector(b); d = b - a
    bpy.ops.mesh.primitive_cone_add(vertices=10, radius1=r0, radius2=r1, depth=d.length, location=(a + b) / 2)
    obj = bpy.context.view_layer.objects.active; obj.name = name
    obj.rotation_mode = 'QUATERNION'; obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized())
    bpy.ops.object.transform_apply(rotation=True)
    forge.attach(obj, parent)
    return smooth(obj, 1, color, .6, .2)


def cone(name, base, tip, radius, color, parent=None):
    base = Vector(base); tip = Vector(tip); d = tip - base
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=radius, radius2=0.0, depth=d.length, location=(base + tip) / 2)
    obj = bpy.context.view_layer.objects.active; obj.name = name
    obj.rotation_mode = 'QUATERNION'; obj.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized())
    bpy.ops.object.transform_apply(rotation=True)
    forge.attach(obj, parent)
    return smooth(obj, 0, color, 0.0, .15)


def torus(name, center, major, minor, color, parent=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=32, minor_segments=8, location=center, rotation=(math.pi / 2, 0, 0))
    obj = bpy.context.view_layer.objects.active; obj.name = name
    bpy.ops.object.transform_apply(rotation=True)
    forge.attach(obj, parent)
    return smooth(obj, 0, color, 0.0, .1)


def core(socket, radius, rim_offset, rim_major):
    """The GlassCore health orb and its two gilt rims, as in the shipped models."""
    c = socket.location
    ellipsoid('GlassCore', c, (radius, radius, radius), '7fd0c0', socket)
    for s in (1, -1): torus('GiltOrbRim', (c.x, c.y + s * rim_offset, c.z), rim_major, .028, 'd6a84e', socket)


def grid_shell(name, fn, nu, nv, thickness, color, parent=None):
    """A surface from fn(u,v) with real thickness, then subdivided."""
    bm = bmesh.new(); rows = [[bm.verts.new(fn(i / nu, j / nv)) for i in range(nu + 1)] for j in range(nv + 1)]
    for j in range(nv):
        for i in range(nu): bm.faces.new((rows[j][i], rows[j][i + 1], rows[j + 1][i + 1], rows[j + 1][i]))
    obj = mesh_object(name, bm, parent)
    forge.apply(obj, 'SOLIDIFY', thickness=thickness, offset=0.0)
    return smooth(obj, 1, color, .9, .35)


def mirror(outline, s):
    return [(u * s, v) for u, v in outline] if s > 0 else [(-u, v) for u, v in reversed(outline)]


def duck(out):
    """Version 2: planes and points, subdivision only to soften corners."""
    forge.reset()
    body = forge.pivot('Body', (0, 0, 0))
    head = forge.pivot('Head', (0, 0, 0), body)
    lathe('DuckSkull', [(1.22, .2, .18, .02), (1.32, .29, .25, .02), (1.50, .30, .25, .02), (1.64, .25, .21, 0), (1.72, .14, .12, -.01), (1.765, .03, .03, -.01)], 'f2c14e', head, segments=10, level=1, creased=(2,), crease_value=.5)
    # A broad flat bill wider than the face, with a small hooked tip.
    slab('Beak', [(-.2, .12), (-.29, .24), (-.25, .36), (-.08, .44), (0, .47), (.08, .44), (.25, .36), (.29, .24), (.2, .12)], .08, 'e8973f', head, 'xy', (0, 0, 1.36), level=1, crease_value=.85)
    slab('LowerBill', [(-.16, .14), (-.21, .26), (0, .36), (.21, .26), (.16, .14)], .05, 'a8622e', head, 'xy', (0, 0, 1.31), level=1)
    for s in (-1, 1):
        # An angular mask piece per eye, pointed up and out: a vampire scowl.
        slab('EyeMask', mirror([(-.03, 0), (.15, .0), (.21, .13), (.09, .1), (-.02, .07)], s), .03, '1f1b26', head, 'xz', (s * .03, .29, 1.47), level=1, crease_value=.9)
        ellipsoid('EyeGlint', (s * .135, .295, 1.515), (.05, .015, .028), '46e0a8', head)
        cone('IvoryFang', (s * .09, .34, 1.315), (s * .085, .35, 1.235), .024, 'f4ecd8', head)
    for x, h, lean in [(-.08, .2, -.07), (0, .27, 0), (.08, .2, .07)]:
        slab('CrownFeather', [(-.04, 0), (.04, 0), (lean + .01, h)], .035, '1f1b26', head, 'xz', (x, .02, 1.71), level=1, crease_value=.9)
    # Torso: broad chest, narrow waist; shallow enough for the orb to stand proud.
    lathe('MetalCuirass', [(.30, .26, .21, 0), (.40, .29, .22, 0), (.62, .35, .24, .0), (.86, .46, .26, 0), (1.02, .40, .23, -.01), (1.12, .2, .15, -.02)], '2b2838', body, segments=8, level=1, creased=(0, 3), crease_value=.85)
    lathe('CuirassInlay', [(.375, .3, .23, 0), (.415, .3, .23, 0)], 'c99a45', body, segments=8, level=1, light=.1)
    for s in (-1, 1):
        slab('CuirassInlay', mirror([(.06, 0), (.13, 0), (.36, .36), (.29, .38)], s), .025, 'c99a45', body, 'xz', (0, .27, .5), level=1, crease_value=.9)
    socket = forge.pivot('CoreSocket', (0, 0, .82), body)
    core(socket, .30, .205, .275)
    # A high pointed vampire collar behind the head.
    for s in (-1, 1):
        slab('HighCollar', mirror([(.04, 0), (.34, .02), (.46, .44), (.22, .3), (.06, .2)], s), .045, '3a0f1c', body, 'xz', (0, -.12, 1.06), level=1, crease_value=.9)
    # Cloak panels with a pointed, scalloped hem.
    for side, name in ((-1, 'CapeLeft'), (1, 'Cape')):
        cape = forge.pivot(name, (0, 0, 0), body)
        def cloak(u, v, side=side):
            hem = .09 * abs(math.sin(u * math.pi * 3)) * v ** 6
            return (side * (.1 + u * (.42 + .32 * v)), -.21 - .1 * math.sin(math.pi * u) - .06 * v, 1.36 - v * 1.18 - hem)
        grid_shell('Cloak', cloak, 9, 10, .03, '8e2234', cape)
    for s in (-1, 1):
        arm = forge.pivot('Arm' + str(s), (s * .43, 0, 1.04), body)
        # Arms are wing blades ending in three feather tips; weapons hang from HandSocket.
        slab('WingGauntlet', mirror([(-.07, .08), (.1, .1), (.15, -.12), (.12, -.36), (.07, -.3), (.04, -.4), (-.01, -.32), (-.05, -.38), (-.08, -.22)], s), .12, '2b2838', arm, 'xz', (s * .46, .07, .96), level=1, crease_value=.8)
        ellipsoid('ShoulderCrest', (s * .45, 0, 1.08), (.17, .15, .065), 'c99a45', arm)
        forge.pivot('HandSocket' + str(s), (s * .52, .23, .72), arm)
        leg = forge.pivot('Leg' + str(s), (s * .24, -.02, .36), body)
        shin = lathe('BootShin', [(.36, .075, .075, 0), (.24, .07, .07, .01), (.13, .065, .065, .03)], '2b2838', leg, segments=8, level=1)
        shin.location.x = s * .24; shin.location.y = -.02
        slab('WebbedBoot', [(-.12, -.1), (-.14, .08), (-.09, .2), (-.03, .17), (0, .23), (.03, .17), (.09, .2), (.14, .08), (.12, -.1)], .09, 'e0a040', leg, 'xy', (s * .24, .06, .02), level=1, crease_value=.85)
    forge.export(os.path.join(out, 'pilot_count_duck.glb'))


def beetle(out):
    """Version 2: broad curved wing plates over a dark body, mid-value teal."""
    forge.reset()
    body = forge.pivot('Body', (0, 0, 0))
    ellipsoid('Thorax', (0, -.1, .8), (.36, .38, .44), '14302a', body)
    for s in (-1, 1):
        # A wing plate wraps the outer side from front to back and peaks at the top;
        # its lower edge is scalloped. The open inner edge leaves the dark split.
        def plate(u, v, s=s):
            a = math.pi / 2 + u * math.pi
            rx = .31 * (1 - v ** 2.4) + .03; ry = .36 * (1 - v ** 2) + .05
            z = .36 + v * 1.06 + (.06 * abs(math.sin(u * math.pi * 3)) if v < .05 else 0)
            return (s * (.24 - math.cos(a) * rx), -.1 + math.sin(a) * ry, z)
        grid_shell('BriarShell', plate, 12, 10, .05, '2f6f5f', body)
        def rim(u, v, s=s):
            a = math.pi / 2 + u * math.pi
            return (s * (.24 - math.cos(a) * .345), -.1 + math.sin(a) * .415, .4 + v * .05)
        grid_shell('ShellRidge', rim, 12, 1, .02, 'c99a45', body)
        for z, y in [(.72, -.02), (.95, -.1), (1.16, -.14)]:
            cone('Thorn', (s * .52, y, z), (s * .7, y - .04, z + .08), .045, '9ab85a', body)
        ellipsoid('Berry', (s * .33, .2, 1.02), (.05, .05, .05), 'd2384a', body)
    for s in (-1, 1):
        for y in (.18, -.08, -.34):
            hip = (s * .36, y, .5); knee = (s * .62, y + .02, .64); foot = (s * .74, y + .06, 0.02)
            tube('HookLeg', hip, knee, .065, .05, 'd8cfaa', body)
            tube('HookLeg', knee, foot, .05, .022, 'd8cfaa', body)
        slab('EyeSlit', mirror([(-.07, 0), (.06, .01), (.07, .045), (-.06, .03)], s), .02, '46e0a8', body, 'xz', (s * .12, .3, 1.11), level=0)
        cone('Mandible', (s * .1, .25, .46), (s * .02, .46, .36), .045, 'd8cfaa', body)
    socket = forge.pivot('CoreSocket', (0, .26, .84), body)
    core(socket, .22, .15, .205)
    forge.export(os.path.join(out, 'pilot_briar_beetle.glb'))


if __name__ == '__main__':
    out = sys.argv[sys.argv.index('--') + 1] if '--' in sys.argv else '.'
    os.makedirs(out, exist_ok=True)
    duck(out); beetle(out)

"""Shared Blender helpers for Wildforge asset scripts (run inside blender -b).

blob() turns a list of metaball elements into one smooth, sculpt-like mesh:
metaballs fuse, voxel remesh gives clean topology, a smoothing pass removes
voxel steps, decimation keeps the game budget and a cavity pass bakes darker
creases into vertex colours. Colours are given as sRGB hex.
"""
import math
import bpy
import bmesh
from mathutils import Vector, Quaternion

def srgb(hex_value):
    def channel(c):
        c=int(c,16)/255.0
        return c/12.92 if c<=.04045 else ((c+.055)/1.055)**2.4
    return tuple(channel(hex_value[i:i+2]) for i in (0,2,4))

def reset():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete()
    for block in (bpy.data.meshes,bpy.data.metaballs,bpy.data.materials):
        for item in list(block): block.remove(item)

def attach(obj,parent):
    if parent is None: return
    bpy.context.view_layer.update()
    obj.parent=parent;obj.matrix_parent_inverse=parent.matrix_world.inverted()

def pivot(name,location,parent=None):
    empty=bpy.data.objects.new(name,None);bpy.context.scene.collection.objects.link(empty)
    empty.location=location;attach(empty,parent);return empty

def material(name,hex_value):
    mat=bpy.data.materials.get(name)
    if mat: return mat
    mat=bpy.data.materials.new(name);mat.use_nodes=True
    nodes=mat.node_tree.nodes;shader=nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=(*srgb(hex_value),1)
    attribute=nodes.new('ShaderNodeVertexColor');attribute.layer_name='Col'
    mat.node_tree.links.new(attribute.outputs['Color'],shader.inputs['Base Color'])
    shader.inputs['Roughness'].default_value=.72
    return mat

def element(ball,spec):
    kind=spec[0]
    if kind in ('ellipsoid','hollow'):
        _,co,r,size=spec;e=ball.elements.new(type='ELLIPSOID');e.co=co;e.radius=r
        e.size_x,e.size_y,e.size_z=size;e.use_negative=kind=='hollow'
    elif kind in ('capsule','crease'):
        _,co,r,half,yaw=spec;e=ball.elements.new(type='CAPSULE');e.co=co;e.radius=r;e.size_x=half
        e.rotation=Quaternion((0,0,1),yaw);e.use_negative=kind=='crease'
    elif kind in ('segment','carve'):
        _,a,b,r=spec;a=Vector(a);b=Vector(b);e=ball.elements.new(type='CAPSULE')
        e.co=(a+b)/2;e.radius=r;e.size_x=(b-a).length/2
        e.rotation=Vector((1,0,0)).rotation_difference((b-a).normalized());e.use_negative=kind=='carve'
    return e

def apply(obj,kind,**settings):
    modifier=obj.modifiers.new(kind.lower(),kind)
    for key,value in settings.items(): setattr(modifier,key,value)
    bpy.context.view_layer.objects.active=obj;bpy.ops.object.modifier_apply(modifier=modifier.name)

def paint(obj,hex_value,cavity):
    """Vertex colours: base colour darkened in creases, lifted on convex rolls."""
    mesh=obj.data;bm=bmesh.new();bm.from_mesh(mesh);bm.normal_update()
    curvature=[0.0]*len(bm.verts)
    for v in bm.verts:
        total=0.0
        for edge in v.link_edges:
            other=edge.other_vert(v);direction=(other.co-v.co)
            if direction.length>1e-6: total+=v.normal.dot(direction.normalized())
        curvature[v.index]=total/max(1,len(v.link_edges))
    for _ in range(2):
        curvature=[(curvature[v.index]+sum(curvature[e.other_vert(v).index] for e in v.link_edges))/(1+len(v.link_edges)) for v in bm.verts]
    bm.free()
    base=srgb(hex_value)
    attribute=mesh.color_attributes.new('Col','FLOAT_COLOR','POINT')
    for i,c in enumerate(curvature):
        crease=min(1.0,max(0.0,c*cavity*6));lift=min(1.0,max(0.0,-c*cavity*6))
        shade=(1-.5*crease)*(1+.14*lift)
        # Creases warm slightly, like blood under thin skin.
        attribute.data[i].color=(min(1,base[0]*shade*(1+.08*crease)),min(1,base[1]*shade),min(1,base[2]*shade*(1-.06*crease)),1)
    mesh.color_attributes.active_color=attribute
    mesh.materials.append(material('Flesh_'+hex_value,hex_value))

def finish(obj,hex_value,parent,cavity):
    for poly in obj.data.polygons: poly.use_smooth=True
    paint(obj,hex_value,cavity);attach(obj,parent)
    return obj

def blob(name,elements,hex_value,parent=None,cavity=1.0,voxel=.02,ratio=.4,resolution=.03):
    ball=bpy.data.metaballs.new(name);ball.resolution=resolution;ball.threshold=.1
    for spec in elements: element(ball,spec)
    # Metaballs sharing a base name fuse; convert immediately so parts stay separate.
    obj=bpy.data.objects.new(name,ball);bpy.context.scene.collection.objects.link(obj)
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
    bpy.ops.object.convert(target='MESH');obj=bpy.context.view_layer.objects.active;obj.name=name
    apply(obj,'REMESH',mode='VOXEL',voxel_size=voxel)
    apply(obj,'SMOOTH',factor=.6,iterations=4)
    apply(obj,'DECIMATE',ratio=ratio)
    return finish(obj,hex_value,parent,cavity)

def ball(name,center,size,hex_value,parent=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16,ring_count=10,location=center)
    obj=bpy.context.view_layer.objects.active;obj.name=name;obj.scale=size
    bpy.ops.object.transform_apply(scale=True)
    return finish(obj,hex_value,parent,0.0)

def export(path,height=None):
    bpy.context.view_layer.update()
    meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    corners=[o.matrix_world@Vector(c) for o in meshes for c in o.bound_box]
    low=min(c.z for c in corners);high=max(c.z for c in corners)
    root=pivot('Root',(0,0,0))
    for obj in bpy.context.scene.objects:
        if obj.parent is None and obj is not root: attach(obj,root)
    if height:
        scale=height/(high-low);root.scale=(scale,scale,scale);root.location=(0,0,-low*scale)
    bpy.context.view_layer.update()
    triangles=sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons)
    options=dict(filepath=path,export_format='GLB',export_apply=True,export_yup=True)
    try: bpy.ops.export_scene.gltf(export_vertex_color='ACTIVE',**options)
    except TypeError: bpy.ops.export_scene.gltf(**options)
    print('FORGE_EXPORT',path,'triangles',triangles,'meshes',len(meshes))

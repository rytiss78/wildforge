"""Converts OpenGameArt's Fire/Ice/Stone Golem (umask007, CC-BY 3.0; textures by
yughues, CC0) for Wildforge: one GLB with the mesh, skeleton and its six
animations, plus the stone, ice and fire textures as PNG for the phase materials.
Run: blender -b --factory-startup --disable-autoexec golem_0.blend --python export_golem.py -- <out dir>
"""
import os
import sys
import bpy

out = sys.argv[sys.argv.index("--") + 1]
os.makedirs(out, exist_ok=True)
scene = bpy.context.scene
scene.render.image_settings.file_format = 'PNG'

# 1. The textures for the three phases.
for name, file in [("stoneBaked", "stone"), ("stoneNormal", "stone_normal"), ("iceDiffuse", "ice"),
                   ("iceNormal.001", "ice_normal"), ("fire_diffuse", "fire"), ("fire_normal", "fire_normal")]:
    image = bpy.data.images[name]
    image.save_render(os.path.join(out, file + ".png"))
    print("saved", file, tuple(image.size))

# 2. A clean stone material on the mesh (the 2.68 materials do not convert).
mesh = bpy.data.objects["stone"]
material = bpy.data.materials.new("golem")
material.use_nodes = True
nodes = material.node_tree.nodes
links = material.node_tree.links
bsdf = nodes.get("Principled BSDF")
color = nodes.new("ShaderNodeTexImage"); color.image = bpy.data.images["stoneBaked"]
links.new(color.outputs["Color"], bsdf.inputs["Base Color"])
normal_image = nodes.new("ShaderNodeTexImage"); normal_image.image = bpy.data.images["stoneNormal"]
normal_image.image.colorspace_settings.name = "Non-Color"
normal_map = nodes.new("ShaderNodeNormalMap")
links.new(normal_image.outputs["Color"], normal_map.inputs["Color"])
links.new(normal_map.outputs["Normal"], bsdf.inputs["Normal"])
bsdf.inputs["Roughness"].default_value = .85
mesh.data.materials.clear()
mesh.data.materials.append(material)

# 3. Only the rig and the mesh; every named action becomes a glTF animation.
for obj in bpy.data.objects:
    obj.select_set(obj.name in ("Armature", "stone"))
armature = bpy.data.objects["Armature"]
bpy.context.view_layer.objects.active = armature
keep = ["attack", "attack2", "die", "flinch", "idle", "walk"]
for action in list(bpy.data.actions):
    if action.name not in keep:
        bpy.data.actions.remove(action)
for action in bpy.data.actions:
    action.use_fake_user = True
    print("action", action.name, tuple(action.frame_range))
armature.animation_data_create()
armature.animation_data.action = bpy.data.actions["idle"]

bpy.ops.export_scene.gltf(filepath=os.path.join(out, "golem.glb"), export_format='GLB', use_selection=True,
                          export_apply=True, export_animations=True, export_animation_mode='ACTIONS',
                          export_force_sampling=True, export_image_format='AUTO')
print("exported", os.path.join(out, "golem.glb"))

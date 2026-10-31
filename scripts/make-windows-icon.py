"""Builds native/icon.ico (the Windows window, taskbar and exe icon) from
native/icon.svg. Godot rasterises the SVG at each size (scripts/rasterise_icon.gd,
so the small sizes are drawn sharp rather than shrunk), then this packs them.

Usage: python scripts/make-windows-icon.py   (needs Pillow)
"""
import os
import subprocess
import tempfile

from PIL import Image

ROOT = os.path.normpath(os.path.join(os.path.dirname(__file__), '..'))
GODOT = os.path.join(ROOT, 'tools', 'godot', 'Godot_v4.7.2-stable_win64_console.exe')
SIZES = [256, 128, 64, 48, 32, 24, 16]

with tempfile.TemporaryDirectory() as out:
    env = dict(os.environ, ICON_OUT=out)
    subprocess.run([GODOT, '--headless', '--path', os.path.join(ROOT, 'native'), '--script', 'res://scripts/rasterise_icon.gd'], env=env, check=True, capture_output=True)
    images = [Image.open(os.path.join(out, f'icon-{s}.png')).convert('RGBA') for s in SIZES]
    target = os.path.join(ROOT, 'native', 'icon.ico')
    images[0].save(target, format='ICO', sizes=[(s, s) for s in SIZES], append_images=images[1:])
    print('wrote', target)

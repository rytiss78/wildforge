"""Give the eight first-discovery achievements their own illustrated badges.

create-achievement-icons.py predates these eight (added in 0.8.2) and
export-achievements.mjs used to byte-copy existing badges onto them, which
breaks the 108-distinct-icons invariant that tests/native-content.test.js
enforces.  This script renders each one from the same approved illustrated
atlas and paper texture, with a source tile that matches the discovery it
celebrates.  The per-ID stitched stitches keep every API ID stable.
"""
from pathlib import Path
import json, hashlib
from PIL import Image, ImageDraw, ImageOps

ROOT = Path(__file__).resolve().parents[1]
data = json.loads((ROOT / 'native/data/catalog.json').read_text(encoding='utf8'))
by_id = {a['id']: a for a in data['achievements']}
source = Image.open(ROOT / 'native/assets/illustrated/icons.png').convert('RGB')
tex = Image.open(ROOT / 'native/assets/illustrated/paper.png').convert('RGB')
output = ROOT / 'community/achievement-icons'
output.mkdir(exist_ok=True)

# id -> source atlas tile, chosen to read as the event itself.
BADGES = {
    'WF_beacon':   11,   # supply turret
    'WF_merchant': 17,   # gold coins
    'WF_mimic':    19,   # boots — it runs
    'WF_reaction': 12,   # fire charm
    'WF_rescue':   15,   # heart / revival
    'WF_ping':     6,    # lightning ping
    'WF_banana':   3,    # poison sprayer
    'WF_terrace':  18,   # key — raised route
}


def stitch_pattern(a_id):
    return int.from_bytes(hashlib.sha256(a_id.encode()).digest()[:2], 'big')


def stamp(canvas, index, box):
    x = (index % 6) * 128
    y = (index // 6) * 128
    tile = source.crop((x + 6, y + 6, x + 122, y + 122)).resize(
        (box[2] - box[0], box[3] - box[1]), Image.Resampling.LANCZOS)
    canvas.paste(tile, (box[0], box[1]))


# Sanity: the eight tiles must be distinct from each other.
assert len(set(BADGES.values())) == len(BADGES), 'duplicate badge tiles'

for a_id, primary in BADGES.items():
    a = by_id[a_id]
    image = tex.resize((256, 256)).copy()
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((6, 6, 249, 249), radius=25, outline='#795d47', width=5)
    draw.rounded_rectangle((16, 16, 239, 239), radius=20, outline='#c7a77e', width=2)
    stamp(image, primary, (32, 29, 224, 221))
    draw = ImageDraw.Draw(image)
    # Discovery motif: little flag on a trail, matching the explore motif family.
    draw.line([(25, 228), (50, 218), (78, 230), (97, 215)], fill='#94745c', width=4)
    draw.polygon([(199, 43), (199, 15), (225, 22), (199, 31)], fill='#dfa48c',
                 outline='#795d47', width=2)
    draw.line([(199, 13), (199, 49)], fill='#795d47', width=3)
    pattern = stitch_pattern(a_id)
    for i in range(8):
        if pattern & (1 << i):
            draw.line([(14, 65 + i * 17), (21, 68 + i * 17)], fill='#a38468', width=2)
    locked = ImageOps.colorize(ImageOps.grayscale(image), '#8d8175', '#eadfc9')
    for state, icon in enumerate([image, locked]):
        suffix = 'unlocked' if state == 0 else 'locked'
        icon.save(output / f"{a_id.lower()}-{suffix}.png", optimize=True)
    print(f'{a_id}: tile {primary}, stitches {bin(pattern)}')
print(f'{len(BADGES)} first-discovery badges rendered with distinct source tiles.')

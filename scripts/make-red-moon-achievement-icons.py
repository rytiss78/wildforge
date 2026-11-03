"""Achievement icons for the November 3 Red Moon achievements (same frame as the
others in native/assets/illustrated/achievements). The six that gift a mustache
show it, in that mustache's colour, under a small sign of the deed."""
from pathlib import Path
out=Path('G:/game/native/assets/illustrated/achievements')
FRAME='<path d="M64 3 116 31v57l-52 37-52-37V31z" fill="#111c2a" stroke="#ccaa68" stroke-width="3"/><path d="m22 35 6 18-4 9 9 13-2 10 14 7m61-57-6 18 4 9-9 13 2 10-14 7" fill="none" stroke="#678575" stroke-width="3"/>'
STACHE='<path d="M64 74c-8-10-21-12-31-4-6 5-11 3-13-3 0 11 10 17 22 13 10-3 15-4 22-6 7 2 12 3 22 6 12 4 22-2 22-13-2 6-7 8-13 3-10-8-23-6-31 4z" fill="{c}" stroke="#07111d" stroke-width="3" stroke-linejoin="round"/>'
def svg(body): return '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 128 128">'+FRAME+body+'</svg>'
icons={
 'WF_NOGGIN':STACHE.format(c='#7a4a26')+'<circle cx="64" cy="40" r="15" fill="#f2b68f" stroke="#07111d" stroke-width="3"/><circle cx="58" cy="38" r="3" fill="#e8384f"/><circle cx="70" cy="38" r="3" fill="#e8384f"/>',
 'WF_NOGGIN_ONE':STACHE.format(c='#2a2628')+'<path d="M58 30l9-6v32" fill="none" stroke="#d6b878" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"/>',
 'WF_NOGGIN_DARE':STACHE.format(c='#e8452c')+'<path d="M64 22c10 10 12 18 6 26 0-6-3-9-6-11 1 6-2 9-6 11-4-8 0-17 6-26z" fill="#ffc34a" stroke="#07111d" stroke-width="3" stroke-linejoin="round"/>',
 'WF_SPOTLESS':STACHE.format(c='#f6f4ef')+'<path d="M64 20l5 13 13 5-13 5-5 13-5-13-13-5 13-5z" fill="#c8f0ff" stroke="#07111d" stroke-width="3" stroke-linejoin="round"/>',
 'WF_ECLIPSE':STACHE.format(c='#c9c4bc')+'<circle cx="64" cy="40" r="16" fill="#ffc357" stroke="#07111d" stroke-width="3"/><circle cx="70" cy="36" r="14" fill="#111c2a"/>',
 'WF_ROSTER':STACHE.format(c='#f2c230')+''.join('<circle cx="%d" cy="%d" r="8" fill="#d6b878" stroke="#07111d" stroke-width="3"/>' % (x,y) for x,y in [(46,44),(64,36),(82,44)]),
 'WF_RED_MOON':'<circle cx="64" cy="62" r="30" fill="#e0484a" stroke="#07111d" stroke-width="3"/><circle cx="54" cy="54" r="6" fill="#b5303a"/><circle cx="74" cy="72" r="8" fill="#b5303a"/><circle cx="72" cy="50" r="4" fill="#b5303a"/>',
 'WF_EVOLVE':'<path d="M64 26l22 26H72v30H56V52H42z" fill="#9ff0d2" stroke="#07111d" stroke-width="3" stroke-linejoin="round"/><path d="M88 82l3 8 8 3-8 3-3 8-3-8-8-3 8-3z" fill="#ffe98a" stroke="#07111d" stroke-width="2"/>',
 'WF_LEGEND_HOARD':''.join('<path d="M{x} {y}l10-10h14l10 10-17 20z" fill="#ffd36b" stroke="#07111d" stroke-width="3" stroke-linejoin="round"/>'.format(x=x,y=y) for x,y in [(30,70),(66,70),(48,46)]),
 'WF_CROWD':''.join('<circle cx="%d" cy="%d" r="7" fill="#ffba72" stroke="#07111d" stroke-width="2.5"/>' % (x,y) for x,y in [(40,46),(56,40),(72,40),(88,46),(34,64),(50,60),(66,58),(82,60),(96,64),(44,80),(60,78),(76,78),(90,82)])+'<path d="M38 96l52-62" stroke="#e8384f" stroke-width="7" stroke-linecap="round"/>',
 'WF_COOP_NOGGIN':'<circle cx="48" cy="50" r="13" fill="#82beff" stroke="#07111d" stroke-width="3"/><circle cx="80" cy="50" r="13" fill="#d6b878" stroke="#07111d" stroke-width="3"/><path d="M28 92c2-14 12-22 20-22s14 4 16 10c2-6 8-10 16-10s18 8 20 22z" fill="#678575" stroke="#07111d" stroke-width="3" stroke-linejoin="round"/>',
}
for name,body in icons.items():
    (out/(name+'.svg')).write_text(svg(body),encoding='utf-8')
print(len(icons),'icons')

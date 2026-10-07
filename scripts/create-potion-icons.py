"""Native SVG potion icons: bottle palette matches PotionBook/world pickups."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/"native/assets/illustrated/potions"
ROOT.mkdir(parents=True,exist_ok=True)
items={
"poison":("8bb773",'<path d="M51 85c0-16 26-16 26 0v9h-6v8H57v-8h-6z"/><path d="M57 85h2m10 0h2" stroke="#fff4d6" stroke-width="5"/>'),
"fire":("e59b73",'<path d="M64 70c15 15 20 23 9 31-17 11-34-7-20-20-1 12 8 12 8 3z"/>'),
"speed":("99cbce",'<path d="m46 77 12 11-12 11m18-22 12 11-12 11" fill="none" stroke-width="7"/>'),
"xp":("ccacd7",'<path d="m46 77 14 23m0-23-14 23m22 0V77h8c13 0 13 13 0 13h-8" fill="none" stroke-width="5"/>'),
"stone":("a0a8b8",'<path d="m64 73 17 6-3 17-14 10-14-10-3-17z"/><path d="m56 87 6 6 12-12" fill="none" stroke="#fff4d6" stroke-width="4"/>'),
"bite":("e89793",'<path d="M45 77h38v17l-9 8H54l-9-8z"/><path d="m51 78 4 12 6-12m6 0 6 12 5-12" stroke="#fff4d6" stroke-width="3" fill="#fff4d6"/>'),
"hands":("e6c685",'<path d="M52 103 44 86l5-3 6 9V75h5v13-17h5v17-15h5v16-10h5v18l-7 8z"/>'),
"lucky":("a8ce84",'<rect x="47" y="73" width="34" height="32" rx="6"/><g fill="#fff4d6" stroke="none"><circle cx="55" cy="81" r="3"/><circle cx="73" cy="81" r="3"/><circle cx="64" cy="89" r="3"/><circle cx="55" cy="97" r="3"/><circle cx="73" cy="97" r="3"/></g>'),
"reach":("a6b7dc",'<path d="m47 93 26-19 8 12-26 18z"/><path d="m46 94 10 9m16-27 8 10" stroke="#fff4d6" stroke-width="3"/>'),
"coins":("e6bc61",'<ellipse cx="60" cy="97" rx="16" ry="7"/><ellipse cx="60" cy="89" rx="16" ry="7"/><circle cx="72" cy="81" r="12"/><path d="M72 75v12m-4-6h8" stroke="#fff4d6" stroke-width="3"/>'),
"magnet":("89c3db",'<path d="M48 75v17c0 21 32 21 32 0V75H69v17c0 7-10 7-10 0V75z"/><path d="M48 82h11m10 0h11" stroke="#fff4d6" stroke-width="4"/>'),
"jump":("c5a4e0",'<path d="m64 71-18 18h11v15h14V89h11z"/>'),
"feather":("e6d8bd",'<path d="M49 105c-4-33 17-37 33-35-2 21-15 29-27 26z"/><path d="m53 98 21-22m-16 9 8 2" stroke="#fff4d6" stroke-width="3"/>'),
"blood":("d791a7",'<path d="M64 103C34 84 47 68 64 81c17-13 30 3 0 22z"/>')}
for key,(color,symbol) in items.items():
 svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
<defs><linearGradient id="glass" x1="0" x2="1" y1="0" y2="1"><stop stop-color="#fffde8"/><stop offset=".35" stop-color="#{color}"/><stop offset="1" stop-color="#425369"/></linearGradient></defs>
<ellipse cx="65" cy="117" rx="35" ry="7" fill="#273847" opacity=".18"/>
<path d="M47 22h34v22c1 8 18 14 20 32l-2 28c-3 14-67 14-70 0l-2-28c2-18 19-24 20-32z" fill="url(#glass)" stroke="#35414c" stroke-width="4"/>
<path d="M35 75q29 7 58 0l-1 28q-27 12-56 0z" fill="#{color}"/>
<rect x="44" y="12" width="40" height="17" rx="4" fill="#9c704c" stroke="#35414c" stroke-width="4"/>
<path d="M52 16v8m9-8v8m10-8v8" stroke="#d6b184" stroke-width="3"/>
<path d="M39 65q4-11 14-15V35" fill="none" stroke="#ffffff" stroke-opacity=".7" stroke-width="5" stroke-linecap="round"/>
<rect x="41" y="68" width="46" height="42" rx="9" fill="#fff4d6" stroke="#b99d70" stroke-width="2"/>
<g fill="#35414c" stroke="#35414c" stroke-width="2" stroke-linejoin="round" stroke-linecap="round">{symbol}</g>
</svg>'''
 (ROOT/(key+'.svg')).write_text(svg)
print(f"Wrote {len(items)} distinct potion icons")

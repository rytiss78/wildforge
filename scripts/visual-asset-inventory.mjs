// Read-only inventory: dynamic resource roots remain live until individually replaced.
import {readdirSync, readFileSync, writeFileSync, statSync} from 'node:fs';
import {createHash} from 'node:crypto';
const walk = dir => readdirSync(dir,{withFileTypes:true}).flatMap(e=>e.isDirectory()?walk(`${dir}/${e.name}`):[`${dir}/${e.name}`]);
const sources = [...walk('native/scripts'),...walk('native/shaders'),...walk('scripts')].filter(p=>/\.(gd|gdshader|py|mjs)$/.test(p));
const refs = sources.flatMap(path=>readFileSync(path,'utf8').split(/\r?\n/).flatMap((text,i)=> /res:\/\/assets|\.glb|\.res["']|Mesh\.new|shader\.code|_draw\(/.test(text)?[{path,line:i+1,text:text.trim()}]:[]));
const families = [
  ['native/assets/style3d/baked/','PaintedBatch / StyleModel / RealmWorld','scripts/build-forge-roster.py; scripts/build-forge-biomes.py; native/scripts/bake_models.gd'],
  ['native/assets/style3d/','StyleModel / WeaponModel / RealmWorld','scripts/build-forge-slice.py; scripts/build-forge-roster.py; scripts/build-forge-biomes.py'],
  ['native/assets/illustrated/content/','IllustratedIcons / WeaponModel','scripts/create-content-art.mjs'],
  ['native/assets/illustrated/effects/','IllustratedIcons compact semantic symbols','scripts/create-content-art.mjs'],
  ['native/assets/illustrated/achievements/','Achievement menu seals','scripts/create-content-art.mjs'],
  ['native/assets/illustrated/weapon-icons/','IllustratedIcons primary weapon art','native/scripts/render_weapon_icons.gd'],
  ['native/assets/illustrated/','Shared terrain, portrait render targets, potions and UI','scripts/prepare-illustrations.py; scripts/create-*-icons.py'],
  ['native/assets/','Runtime auxiliary assets; audio preserved','existing family generators'],
];
const assets=walk('native/assets').filter(p=>!p.includes('/local/')).map(path=>{
  const family=families.find(([root])=>path.startsWith(root));
  return {path,bytes:statSync(path).size,sha256:createHash('sha256').update(readFileSync(path)).digest('hex'),owner:family?.[1],generator:family?.[2],replacement:'active runtime family; see visual-rollout-1.0.0.md',deletion:'retain'};
});
const embedded=sources.filter(p=>p.startsWith('native/')).filter(p=>/Mesh\.new|shader\.code|_draw\(/.test(readFileSync(p,'utf8')));
writeFileSync('native/docs/visual-asset-manifest.json',JSON.stringify({version:1,policy:'No deletion is authorized by this inventory alone. Dynamic roots and import sidecars require runtime/export validation.',families,embedded,refs,assets},null,2)+'\n');
console.log(JSON.stringify({assets:assets.length,embedded:embedded.length,references:refs.length}));

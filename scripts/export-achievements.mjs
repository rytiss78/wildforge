import {writeFile,mkdir,readFile,stat} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const {achievements:ACHIEVEMENTS}=JSON.parse(await readFile(new URL('../native/data/catalog.json',import.meta.url),'utf8'));
await mkdir(new URL('../community/',import.meta.url),{recursive:true});
// Badge PNGs are rendered by scripts/create-achievement-icons.py (first 100)
// and scripts/create-discovery-badges.py (the eight first-discovery badges).
// The export must never overwrite them: every API ID needs its own distinct
// unlocked icon, which tests/native-content.test.js enforces.
const hashes=new Map();
for(const a of ACHIEVEMENTS){
 for(const state of ['unlocked','locked']){
  const path=new URL(`../community/achievement-icons/${a.id.toLowerCase()}-${state}.png`,import.meta.url);
  try{await stat(path);}catch{throw new Error(`Missing achievement icon: ${path}. Run scripts/create-achievement-icons.py and scripts/create-discovery-badges.py first.`);}
  const hash=createHash('sha256').update(await readFile(path)).digest('hex');
  if(state!=='unlocked')continue;
  if(hashes.has(hash))throw new Error(`Duplicate achievement icon for ${a.id} (also used by ${hashes.get(hash)}). Re-render distinct badges before exporting.`);
  hashes.set(hash,a.id);
 }
}
await writeFile(new URL('../community/achievements.json',import.meta.url),JSON.stringify({schemaVersion:1,count:ACHIEVEMENTS.length,achievements:ACHIEVEMENTS.map(a=>({apiName:a.id,displayName:a.name,description:a.description,hidden:a.hidden,iconUnlocked:`achievement-icons/${a.id.toLowerCase()}-unlocked.png`,iconLocked:`achievement-icons/${a.id.toLowerCase()}-locked.png`,condition:{key:a.key,target:a.target,scope:a.scope}}))},null,2));
const quote=value=>'"'+String(value).replaceAll('"','""')+'"';
await writeFile(new URL('../community/achievements.csv',import.meta.url),['ID,Display Name,Description,Hidden',...ACHIEVEMENTS.map(a=>[a.id,a.name,a.description,a.hidden?1:0].map(quote).join(','))].join('\n'));
console.log(`Exported ${ACHIEVEMENTS.length} standalone achievement definitions. Unlocks are saved locally by the native game.`);

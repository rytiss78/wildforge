import {writeFile,mkdir,copyFile} from 'node:fs/promises';
import {readFile} from 'node:fs/promises';
const {achievements:ACHIEVEMENTS}=JSON.parse(await readFile(new URL('../native/data/catalog.json',import.meta.url),'utf8'));
await mkdir(new URL('../community/',import.meta.url),{recursive:true});
// Reuse approved illustrated badges for discovery exports; keep stable ID filenames.
const discoveryBadges={beacon:'mix_turret',merchant:'interest',mimic:'legendary',reaction:'combo_burn_poison',rescue:'comeback',ping:'long_walk',banana:'walk_pay',terrace:'airtime'};
for(const [id,source] of Object.entries(discoveryBadges)){
  for(const state of ['unlocked','locked']){
    await copyFile(new URL(`../community/achievement-icons/wf_${source}-${state}.png`,import.meta.url),new URL(`../community/achievement-icons/wf_${id}-${state}.png`,import.meta.url));
  }
}
await writeFile(new URL('../community/achievements.json',import.meta.url),JSON.stringify({schemaVersion:1,count:ACHIEVEMENTS.length,achievements:ACHIEVEMENTS.map(a=>({apiName:a.id,displayName:a.name,description:a.description,hidden:a.hidden,iconUnlocked:`achievement-icons/${a.id.toLowerCase()}-unlocked.png`,iconLocked:`achievement-icons/${a.id.toLowerCase()}-locked.png`,condition:{key:a.key,target:a.target,scope:a.scope}}))},null,2));
const quote=value=>'"'+String(value).replaceAll('"','""')+'"';
await writeFile(new URL('../community/achievements.csv',import.meta.url),['ID,Display Name,Description,Hidden',...ACHIEVEMENTS.map(a=>[a.id,a.name,a.description,a.hidden?1:0].map(quote).join(','))].join('\n'));
console.log(`Exported ${ACHIEVEMENTS.length} standalone achievement definitions. Unlocks are saved locally by the native game.`);

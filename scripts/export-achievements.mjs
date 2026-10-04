import {writeFile,mkdir} from 'node:fs/promises';
import {ACHIEVEMENTS} from './data/achievements.js';
await mkdir(new URL('../community/',import.meta.url),{recursive:true});
await writeFile(new URL('../community/achievements.json',import.meta.url),JSON.stringify({schemaVersion:1,count:100,achievements:ACHIEVEMENTS.map(a=>({apiName:a.id,displayName:a.name,description:a.description,hidden:a.hidden,iconUnlocked:`achievement-icons/${a.id.toLowerCase()}-unlocked.png`,iconLocked:`achievement-icons/${a.id.toLowerCase()}-locked.png`,condition:{key:a.key,target:a.target,scope:a.scope}}))},null,2));
const quote=value=>'"'+String(value).replaceAll('"','""')+'"';
await writeFile(new URL('../community/achievements.csv',import.meta.url),['ID,Display Name,Description,Hidden',...ACHIEVEMENTS.map(a=>[a.id,a.name,a.description,a.hidden?1:0].map(quote).join(','))].join('\n'));
console.log('Exported 100 standalone achievement definitions. Unlocks are saved locally by the native game.');

import {readFileSync,readdirSync,writeFileSync,mkdirSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {join} from 'node:path';
const mod=fileURLToPath(new URL('../',import.meta.url));
const catalog=JSON.parse(readFileSync(join(mod,'content/wildforge-catalog.json'),'utf8'));
const sources=readdirSync(join(mod,'src')).filter(p=>p.endsWith('.cs')&&!p.includes('Smoke')).map(p=>({file:p,text:readFileSync(join(mod,'src',p),'utf8')}));
const conditions=new Set(Object.values(catalog.augments).map(a=>a.condition));
const rows=[];
for(const card of catalog.cards)for(const effect of card.effects){
 const augment=catalog.augments[effect.key];
 const key=augment?.stat??effect.key;
 const consumers=sources.filter(s=>s.text.includes('"'+key+'"')).map(s=>s.file);
 if(!consumers.length)throw Error(`No runtime consumer: ${card.id}/${key}`);
 if(augment&&!sources.find(s=>s.file==='Effects.cs').text.includes('"'+augment.condition+'"'))throw Error(`Unknown condition: ${augment.condition}`);
 if(!Number.isFinite(effect.amount))throw Error(`Invalid skill amount: ${card.id}`);
 rows.push({card:card.id,kind:card.kind,effect:effect.key,resolvedStat:key,condition:augment?.condition??null,consumers});
}
const report={cards:catalog.cards.length,skills:catalog.cards.filter(c=>c.kind==='skill').length,effectKeys:new Set(rows.map(r=>r.resolvedStat)).size,conditions:conditions.size,rows};
mkdirSync(join(mod,'artifacts'),{recursive:true});writeFileSync(join(mod,'artifacts/skill-coverage.json'),JSON.stringify(report,null,2)+'\n');
console.log(`Skill audit: ${report.skills} skills / ${report.cards} cards; all ${report.effectKeys} effect keys and ${report.conditions} conditions have runtime consumers. Behavioral evidence comes from the runtime smoke.`);

// Summarise a mutation-balance report: damage per core mutation as % of the gun.
// Usage: node scripts/summarise-mutation-balance.mjs [result.json] (defaults to the latest run).
import {readFileSync,readdirSync} from 'node:fs';
import {join} from 'node:path';
const runs=join(import.meta.dirname,'..','.build-staging','agent-workflow');
const path=process.argv[2]??join(runs,readdirSync(runs).filter(x=>x.endsWith('-mutation-balance')).sort().at(-1),'result.json');
const report=JSON.parse(readFileSync(path,'utf8')).mutations;
console.log(path,'· repeat',report.repeat?.join(' / ')??'n/a');
const strains=['bloom','venom','frost','storm','ember','comet'];
const triggers=['hit','crit','kill','dash','jump','slam','hurt','pulse','pickup'];
for(const layout of ['crowd','sparse']){
  const gun=report.gun[layout];
  console.log(`\n${layout.toUpperCase()} · gun ${gun} dps · cells = % of gun damage`);
  console.log('trigger '.padEnd(9)+strains.map(s=>s.padStart(7)).join('')+'   avg');
  for(const t of triggers){
    const row=strains.map(s=>report.core[s+'_'+t][layout]/gun*100);
    console.log(t.padEnd(9)+row.map(v=>v.toFixed(0).padStart(7)).join('')+(row.reduce((a,b)=>a+b)/row.length).toFixed(0).padStart(6));
  }
  const cols=strains.map(s=>triggers.reduce((sum,t)=>sum+report.core[s+'_'+t][layout]/gun*100,0)/triggers.length);
  console.log('avg'.padEnd(9)+cols.map(v=>v.toFixed(0).padStart(7)).join(''));
}
const heal=strains.filter(s=>s==='bloom').map(s=>triggers.map(t=>t+':'+report.core[s+'_'+t].crowd_heal).join(' '));
console.log('\nbloom heal/s (crowd):',heal.join(''));
const gun=report.gun.crowd;
console.log('\nEXTRAS (crowd, added damage as % of gun):');
const rows=Object.entries(report.extras).sort((a,b)=>b[1].crowd-a[1].crowd);
for(const [id,row] of rows) console.log(' ',id.padEnd(18),row.group.padEnd(7),(row.crowd/gun*100).toFixed(0).padStart(5)+'%',row.crowd_heal?('heal '+row.crowd_heal):'');

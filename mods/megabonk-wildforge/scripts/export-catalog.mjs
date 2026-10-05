import {readFileSync,writeFileSync,mkdirSync,existsSync,readdirSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
import {join} from 'node:path';
const root=fileURLToPath(new URL('../../../',import.meta.url));
const catalog=JSON.parse(readFileSync(join(root,'native/data/catalog.json'),'utf8'));
const names=[['Briar Beetle','Leaf Ray','Antler Snail','Thorn Flower','Four-Eye Moth','Pine Spider'],['Balloon Toad','Tentacle Cap','Bite Lily','Umbrella Jelly','Winged Axolotl','Moss Turtle'],['Crater Crab','Moon Octopus','Crescent Grub','Meteor Eye','Crystal Star','Moon Snail'],['Cloud Puffer','Six-Wing Owl','Frost Slug','Snow Jelly','Kite Dragon','Frost Worm'],['Lava Lobster','Coal Crawler','Fire Clam','Volcano Turtle','Ember Bat','Bloom Hydra'],['Galaxy Nautilus','Orbit Jelly','Ring Squid','Prism Mantis','Starfly','Coral Crab']];
const flying=[[1,4],[3,4],[1,3,4],[0,1,3,4],[4],[1,2,4]];
const legacy={'fang-0':87001,'clover-0':87002,'boots-0':87003};
const heroes=catalog.heroes.map((h,i)=>({...h,turretType:h.turret??null,turret:false,runtimeId:87000+i,asset:h.id==='duck'?'count_duck':'hero_'+h.model,portrait:'illustrated/heroes/'+h.model+'.png'}));
const cards=catalog.loot.map((c,i)=>({...c,runtimeId:legacy[c.id]??88000+i,rarity:Math.max(0,Number(c.id.match(/-(\d+)$/)?.[1]??0)%4),portrait:'illustrated/content/'+c.id+'.png'}));
const weapons=catalog.weapons.map((w,i)=>({...w,runtimeId:87000+i,portrait:existsSync(join(root,'native/assets/illustrated/content/weapon-'+w.id+'.png'))?'illustrated/content/weapon-'+w.id+'.png':existsSync(join(root,'native/assets/illustrated/weapons/'+w.id+'.png'))?'illustrated/weapons/'+w.id+'.png':'illustrated/weapon-icons/'+w.id+'.png'}));
const enemies=names.flatMap((row,b)=>row.map((name,s)=>({id:`creature_${b}_${s}`,name,asset:`creature_${b}_${s}`,runtimeId:89000+b*6+s,biome:b,species:s,health:[1,.75,1.8,1.25,.65,3.1][s],speed:[1,1.4,.7,1,1.65,.65][s],damage:[1,.75,1.4,1.25,.7,1.8][s],height:[2.1,1.85,3,2.4,1.75,4.1][s],radius:[.65,.48,.9,.7,.46,1.2][s],weight:[34,24,14,10,14,4][s],behavior:['chase','swoop','armored','spit','skitter','charge'][s],flying:flying[b].includes(s),portrait:`illustrated/creatures/creature_${b}_${s}.png`})));
for(let realm=0;realm<3;realm++) for(let biome=0;biome<6;biome++) enemies.push({id:`boss_${realm}_${biome}`,name:['World Maw','Sun Breaker','Star Eater'][realm],asset:`creature_${biome}_5`,runtimeId:89036+realm*6+biome,biome,species:5,boss:true,realm,health:500+realm*400,speed:1,damage:2+realm,height:9+realm*2,radius:2.8+realm*.5,weight:0,behavior:'boss',flying:false,portrait:`illustrated/creatures/creature_${biome}_5.png`});
const models=[...heroes,...enemies];
for(const m of models) if(!existsSync(join(root,'native/assets/style3d/'+m.asset+'.glb'))) throw Error('Missing model '+m.asset);
for(const c of [...heroes,...cards,...enemies]) if(!existsSync(join(root,'native/assets/'+c.portrait))) throw Error('Missing icon '+c.id);
// Weapon aliases use the matching family icon if their own drawing is absent.
for(const w of weapons) if(!existsSync(join(root,'native/assets/'+w.portrait))) {
 const base=weapons.find(x=>x.family===w.family&&existsSync(join(root,'native/assets/'+x.portrait)));
 w.portrait=base?.portrait??heroes[1].portrait;
}
const icons=[];
function walk(path,rel='') {for(const f of readdirSync(path,{withFileTypes:true})) f.isDirectory()?walk(join(path,f.name),rel+f.name+'/'):f.name.endsWith('.png')&&icons.push('illustrated/'+rel+f.name);}
walk(join(root,'native/assets/illustrated'));
const manifest={version:catalog.version,heroes,cards,weapons,enemies,augments:catalog.augments,stats:catalog.stats,labels:catalog.labels,icons};
const out=join(root,'mods/megabonk-wildforge/content');mkdirSync(out,{recursive:true});
writeFileSync(join(out,'wildforge-catalog.json'),JSON.stringify(manifest,null,2)+'\n');
console.log(`Exported ${heroes.length} heroes/perks, ${cards.length} cards, ${weapons.length} weapons, ${enemies.length} enemies and ${icons.length} icons.`);

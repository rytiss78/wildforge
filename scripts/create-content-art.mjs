// Editable SVG assets extend the native icon system. No raster placeholders or downloads.
import {readFile,mkdir,writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
const root=new URL('../native/assets/illustrated/content/',import.meta.url);
await mkdir(root,{recursive:true});await mkdir(new URL('textures/',root),{recursive:true});
const data=JSON.parse(await readFile(new URL('../native/data/catalog.json',import.meta.url),'utf8'));
const palette=['#de7256','#65a5ab','#8eac59','#d6a647','#7988c2','#ca7395'];
const shapes=[
 '<path d="M40 85V54l8-14 10 9 5-18 12 4 8 22 13 8-7 30-34 2z"/><path d="M45 72h39M56 52v20M68 48v24" fill="none"/>',
 '<path d="M37 95l15-66h26l15 66z"/><path d="M51 45h28M45 81h38M66 83l11-35" fill="none"/><circle cx="66" cy="83" r="5"/>',
 '<path d="M46 34h30v38l22 9v17H38V76h8z"/><path d="M48 47h25M45 82h28M76 84h16" fill="none"/>',
 '<path d="M37 51h48v33Q63 108 37 84z"/><path d="M86 55q28-2 12 27H84M38 98h52M48 42q-8-10 0-20M65 42q-8-10 0-20" fill="none"/>',
 '<path d="M65 27l33 13-4 37-29 25-30-25-3-37z"/><path d="M65 37v52M44 58h41" fill="none"/>',
 '<path d="M65 28q-21 4-25 23L28 93l27-8 10 14 11-14 25 8-12-42q-5-20-24-23z"/><path d="M54 52l11 12 12-12M42 82l13-15M88 82L76 67" fill="none"/>',
 '<circle cx="60" cy="59" r="26"/><path d="M79 78l24 24-8 8-24-24M42 48q13-17 28-2" fill="none"/>',
 '<path d="M35 86l-6-41 24 16 13-32 13 32 22-16-5 41z"/><path d="M36 97h60" fill="none"/><circle cx="66" cy="78" r="7"/>',
 '<circle cx="66" cy="66" r="35"/><path d="M55 77l5-30 20 8z"/><path d="M66 29v10M66 94v9M29 66h10M94 66h10" fill="none"/>',
 '<path d="M28 88l50-50-6-12 35 4-1 34-12-9-50 50z"/><path d="M43 85l-15-7M52 77l-13-7" fill="none"/>',
 '<ellipse cx="65" cy="53" rx="30" ry="35"/><path d="M63 88l-5 9h13l-6-9M65 98q-15 13 0 19M46 39q9-14 20-12" fill="none"/>',
 '<path d="M51 49l13 15-26 42-13-9z"/><path d="M42 28l20-12 33 26-18 26z"/><path d="M68 30l17 14" fill="none"/>',
 '<path d="M43 29q55-9 47 40L62 104l-9-25q-27-17-10-50z"/><path d="M59 34q16 11 9 43" fill="none"/>',
 '<path d="M52 55l15-38 16 38-15 12z"/><path d="M68 62v49M43 75h51" fill="none"/>',
 '<path d="M65 42q-20-18-41-10v66q20-9 41 7 20-16 40-7V32q-20-8-40 10z"/><path d="M65 43v61M35 49l18 3M77 52l17-4M35 67l18 3M77 70l17-4" fill="none"/>',
 '<path d="M46 39l10 12h22l10-12-9-12H55zM49 52q-31 44-13 51h58q18-7-15-51z"/><path d="M53 79h24M65 68v27" fill="none"/>',
 '<path d="M28 36h24v39q13 20 26 0V36h24v43q-37 58-74 0z"/><path d="M28 56h24M78 56h24" fill="none"/>',
 '<path d="M29 48h77l-15 24H76v22h20v12H36V94h20V72H39z"/><path d="M37 39h43v10" fill="none"/>',
 '<path d="M43 30l7 11 14-4 4 17 16 7-10 13 4 17-18 3-8 13-13-10-17 3-3-17-10-12 12-13 2-16 16-1z"/><circle cx="48" cy="72" r="15"/><circle cx="92" cy="39" r="15"/>',
 '<path d="M32 49l61-22 14 26-61 27z"/><path d="M67 70l-7 22M59 87l-22 20M62 87l27 20M39 48l12 29M83 32l13 28" fill="none"/>'
];
const glyphs=[
 '<path d="M8 23l10-15 10 15M9 28h19"/>', '<path d="M8 27h24M13 18v9M24 18v9"/>',
 '<path d="M7 16h14M5 23h12M16 28l16-9"/>','<path d="M10 11v17M22 11v17"/>',
 '<path d="M10 12l19 18M29 12L10 30"/>','<path d="M8 20l8 9 16-19"/>',
 '<path d="M9 9l21 4-3 15-8 5-9-5z"/>','<path d="M9 9l21 4-3 15-8 5-9-5zM7 32L31 8"/>',
 '<path d="M7 18h14l-3-8 15 13-15 10 3-8H7"/>','<path d="M10 10l21 18M8 30h27M20 25l-6 8M27 25l7 8"/>',
 '<path d="M9 28L29 8M9 9l20 20M7 29h7M29 7v7"/>','<path d="M21 6l-9 15h9l-3 13 14-18H21z"/>',
 '<path d="M7 31V9l8 10 7-11 7 11 6-10v22z"/>','<circle cx="21" cy="21" r="5"/><circle cx="21" cy="21" r="14"/>',
 '<circle cx="12" cy="13" r="5"/><circle cx="29" cy="13" r="5"/><circle cx="12" cy="29" r="5"/><circle cx="29" cy="29" r="5"/>',
 '<path d="M21 18v17M21 20l-11 6M21 24l11-5"/><circle cx="21" cy="12" r="8"/>',
 '<path d="M10 30h23M14 30V18h14v12M21 18V9h13"/>','<circle cx="21" cy="21" r="13"/><path d="M16 16h9M16 25h9M21 11v20"/>',
 '<path d="M10 28L21 8l11 20zM10 32h22"/>','<path d="M8 8h26v26H8zM8 8l26 26M8 34L34 8"/>'
];
function legacyArtwork(key){
 const paths={
  burn:'<path d="M65 108Q26 93 38 65l18-37q-2 29 13 29l10-27q42 59 3 77z"/><path d="M62 100q-18-15 6-35 18 24-6 35z" fill="#ffe1a1"/>',
  poison:'<path d="M52 22h25v28l20 36q7 26-31 26-38 0-30-26l16-36z"/><path d="M48 72h36M53 32h24" fill="none"/><circle cx="63" cy="84" r="8"/>',
  freeze:'<path d="M65 22l30 36-30 53-30-53zM35 58h60M65 22v89M47 40l18 18 18-18"/>',
  ghost:'<path d="M32 100V54q31-55 65 0v46l-16-10-15 17-17-17z"/><circle cx="53" cy="63" r="5"/><circle cx="77" cy="63" r="5"/>',
  maxHp:'<path d="M65 105Q10 67 35 38q18-13 30 8 18-22 34-5 24 23-34 64z"/><path d="M40 62h15l6-12 8 25 7-12h15" fill="none"/>',
  chain:'<path d="M77 18L37 73h22l-8 41 42-58H70z"/>',
  keyPower:'<circle cx="52" cy="48" r="23"/><circle cx="52" cy="48" r="9"/><path d="M67 66l33 36-11 9-11-12 8-9-12-8z"/>',
  flowerPower:'<path d="M65 106V57M65 86q-35 0-25-24 22 1 25 24M65 78q30-6 28-25-23 2-28 25"/><circle cx="65" cy="42" r="13"/><circle cx="45" cy="42" r="15"/><circle cx="85" cy="42" r="15"/><circle cx="65" cy="22" r="15"/><circle cx="65" cy="62" r="15"/>',
  thorns:'<path d="M30 107l69-76M41 90l-10-19 23 4M61 70l-8-24 24 8M80 49l1-23 18 7" fill="none"/>',
  explosion:'<path d="M65 24l13 27 32-11-19 28 21 22-33-1-14 24-14-24-31 1 18-22-17-28 31 11z"/>',
  auraDamage:'<circle cx="65" cy="66" r="13"/><circle cx="65" cy="66" r="27" fill="none"/><circle cx="65" cy="66" r="40" fill="none"/>',
  goldGain:'<ellipse cx="66" cy="77" rx="34" ry="19"/><path d="M32 77v15q33 26 68 0V77M40 56h52v20H40z"/><ellipse cx="66" cy="56" rx="26" ry="15"/><path d="M61 48v17M72 48v17" fill="none"/>'
 };
 const alias={splash:'explosion',dashBlast:'explosion',jumpBlast:'explosion',slamFire:'burn',flame:'burn',pools:'poison',slamPoison:'poison',slow:'freeze',shield:'armor',lifesteal:'maxHp',regen:'maxHp',repair:'maxHp',chestHeal:'maxHp',coinHeal:'maxHp',revive:'maxHp',flowerHeal:'flowerPower',flowerPollen:'flowerPower',flowerRoots:'flowerPower',flowerSeeds:'flowerPower',storm:'chain',nova:'explosion',blind:'ghost',burrow:'ghost',discount:'goldGain',interest:'goldGain',walkGold:'goldGain',hurtGold:'goldGain',potGold:'goldGain'};
 key=alias[key]||key;
 return paths[key]||shapes[({damage:0,rate:1,speed:2,armor:4,dodge:5,crit:6,critPower:7,range:8,projectileSpeed:9,size:10,knockback:11,bossDamage:13,xpGain:14,pickup:16,turretDamage:17,turretRate:18,turretRange:19,jumpHeight:2,airJumps:2,slamPower:11,ricochet:8,pierce:9,multishot:9})[key]??14];
}
function weaponShape(w){
 const k=w.archetype||w.id;
 if(k==='saw')return '<circle cx="65" cy="61" r="33"/><circle cx="65" cy="61" r="11"/><path d="M49 90l-15 25M34 115l-9-6"/>';
 if(['gravity','ghost','bubble','meteor','bomb'].includes(k))return `<path d="M39 101l7-56h39l9 56z"/><circle cx="66" cy="57" r="29"/><path d="M51 54l15-18 15 18-15 24z"/><path d="M43 101h47"/>`;
 if(k==='horn')return '<path d="M25 65l39-15 29-21v72L64 79 25 74z"/><path d="M52 81l10 26h19L67 84M102 43l11-8M102 62h16M102 83l11 8"/>';
 if(k==='boomerang')return '<path d="M27 101l18-69 52-12 11 19-46 9-18 61z"/>';
 if(k==='disc')return '<circle cx="65" cy="65" r="39"/><circle cx="65" cy="65" r="16"/><circle cx="65" cy="65" r="5"/><path d="M40 44q22-17 40 0M42 86q19 14 37-1" fill="none"/>';
 if(k==='flowers')return '<path d="M40 92h51l-9 24H49zM65 92V56"/><circle cx="65" cy="47" r="14"/><circle cx="42" cy="47" r="15"/><circle cx="87" cy="47" r="15"/><circle cx="65" cy="26" r="15"/><circle cx="65" cy="68" r="15"/>';
 const index=Math.max(0,data.weapons.findIndex(x=>x.id===k));const barrels=k==='shotgun'?3:1;
 return `<path d="M25 50h68v29H69l-8 30H42l4-30H25z"/>${Array.from({length:barrels},(_,i)=>`<path d="M83 ${45+i*13}h31v8H83z"/>`).join('')}<path d="M31 57h${18+index%5*5}M34 69h17" fill="none"/>${k.includes('turret')?'<path d="M40 80l-18 30M75 80l24 30M35 110h67"/>':`<circle cx="66" cy="38" r="${8+index%4*3}"/>`}`;
}
function weaponAccent(w){
 const m=w.modifiers||{};
 if(m.payload==='fire')return '<path d="M83 109q-21-17 3-37-4 16 10 17 9-15 5-25 30 28-5 47z" fill="#eb8056"/>';
 if(m.payload==='poison')return '<path d="M86 79V65h15v14l12 26q-17 16-34 0z" fill="#a2c26b"/><circle cx="95" cy="95" r="5"/>';
 if(m.payload==='ice')return '<path d="M96 68l17 20-17 26-17-26zM79 88h34M96 68v46" fill="#8ed4e0"/>';
 if(m.payload==='bubble')return '<circle cx="98" cy="96" r="18" fill="#a1dfe4"/><circle cx="84" cy="77" r="8"/>';
 if(m.extraShots)return Array.from({length:3},(_,i)=>`<path d="M${81+i*10} 109V86q4-15 8 0v23z" fill="#dfbf62"/>`).join('');
 if(m.extraPierce)return '<path d="M80 108l25-36M92 73l15-4-1 17M81 94l-8 4M93 89l12-2" fill="none"/>';
 if(m.extraBounce)return '<path d="M74 112l16-28 10 16 14-33M104 70l12-6 2 15" fill="none"/>';
 if(m.returning)return '<path d="M85 83q31-10 25 14-3 17-23 8M88 96l-8 10 12 6" fill="none"/>';
 if(m.shotScale||m.areaScale)return '<circle cx="96" cy="96" r="18" fill="none"/><path d="M96 68v10M96 113v9M69 96h9M113 96h9" fill="none"/>';
 if(m.durationScale)return '<path d="M80 74h31l-25 35h25zM80 112h31M80 74l25 35" fill="#e4c66d"/>';
 if(m.coneDot!==undefined)return '<path d="M77 96l35-22v43zM102 84v24" fill="#efd996"/>';
 if(m.stunBonus)return '<path d="M97 72l5 13 14 1-10 10 3 14-12-8-12 8 3-14-10-10 14-1z" fill="#efd996"/>';
 if(m.extraMeteors)return '<path d="M78 91l12-17M91 91l12-17M101 106l12-17" fill="none"/><circle cx="78" cy="96" r="7"/><circle cx="91" cy="96" r="7"/><circle cx="101" cy="112" r="7"/>';
 if(m.fuse)return `<circle cx="98" cy="101" r="15"/><path d="M98 84q${m.fuse>1?25:-14}-18 8-22" fill="none"/>`;
 if(m.sweepDot!==undefined)return '<path d="M78 88q35-35 37 12M76 88l1-12M78 88l12 2" fill="none"/>';
 return '';
}
const manifest=[];
for(const [i,item] of [...data.loot,...data.weapons].entries()){
 const digest=createHash('sha256').update(item.id).digest();const weapon=!item.effects;
 const shape=item.art?.shape??digest[0]%20;const condition=item.art?.condition??digest[1]%20;
 const color=palette[shape%palette.length];const emblem=glyphs[condition];
 const artwork=weapon?weaponShape(item)+weaponAccent(item):item.art?shapes[shape]:legacyArtwork(item.effects[0].key);
 const engraving=Array.from({length:5},(_,j)=>`<path d="M${39+j*11} 118l${digest[j+2]%7-3} -${4+digest[j+3]%6}"/>`).join('');
 const source=`<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><defs><linearGradient id="paint" x2=".8" y2="1"><stop stop-color="${color}"/><stop offset="1" stop-color="#f5db94"/></linearGradient></defs><rect x="3" y="3" width="122" height="122" rx="19" fill="#fcf0d7" stroke="#805c47" stroke-width="3"/><g transform="translate(1 3)" fill="#9b7558" opacity=".25">${artwork}</g><g fill="url(#paint)" stroke="#5e4539" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">${artwork}</g><rect x="3" y="3" width="38" height="38" rx="10" fill="#f7e4b8" stroke="#805c47" stroke-width="2"/><g fill="none" stroke="#5e4539" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round">${emblem}${engraving}</g></svg>`;
 await writeFile(new URL(item.id+'.svg',root),source);
 if(weapon){
  const pattern=`<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><rect width="128" height="128" fill="${color}"/><g fill="#f4d596" stroke="#674f49" stroke-width="2">${Array.from({length:9},(_,n)=>`<g transform="translate(${n%3*42} ${Math.floor(n/3)*42}) scale(.3)">${artwork}</g>`).join('')}</g><path d="M0 4h128M0 124h128" stroke="#efcc91" stroke-width="5"/></svg>`;
  await writeFile(new URL('textures/'+item.id+'.svg',root),pattern);
 }
 manifest.push({id:item.id,path:`res://assets/illustrated/content/${item.id}.svg`,shape,condition,source:'Original editable vector geometry',sha256:createHash('sha256').update(source).digest('hex')});
}
if(new Set(manifest.map(x=>x.sha256)).size!==manifest.length)throw Error('Duplicate icon composition');
await writeFile(new URL('manifest.json',root),JSON.stringify(manifest,null,2));
console.log(`${manifest.length} distinct editable icons; ${data.weapons.length} patterned weapon textures`);

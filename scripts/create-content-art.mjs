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

// The emblem encodes a real condition. Identical effects deliberately share a
// symbol; file hashes are never treated as proof of visual distinctness.
const conditionNames=['air','ground','moving','still','low','healthy','shield','bare','dash','slam','kill','crit','boss','near','crowd','flower','turret','gold'];
const statNames=['damage','rate','speed','regen','armor','dodge','crit','critPower','range','projectileSpeed','size','knockback','lifesteal','bossDamage','xpGain','goldGain','pickup','turretDamage','turretRate','turretRange'];
const semantic={
 multishot:'<path d="M30 104V62l9-17 9 17v42zM57 104V37l9-19 9 19v67zM84 104V62l9-17 9 17v42z"/>',
 ricochet:'<path d="m25 104 30-65 22 34 26-52M83 27l23-9 4 23M20 111h90" fill="none"/>',
 stun:'<path d="m65 20 9 27 29-9-15 26 20 22-30-2-13 27-12-27-30 2 19-22-15-26 29 9z"/><path d="M62 43v30m0 10v8" fill="none"/>',
 repair:'<path d="m45 21 11 24 16 1 11-24q27 40-7 54l-3 36H52l-1-36Q18 59 45 21z"/><path d="M59 82v17" fill="none"/>',
 revive:'<path d="M40 52q-3-30 25-30 33 0 26 32l-13 16v17H51V70z"/><path d="M29 92h24V70h23v22h24v20H29z"/><path d="M53 47h4m17 0h4" fill="none"/>',
 luck:'<path d="M65 62Q17 39 33 24q26-14 32 25 10-41 35-25 19 17-23 38 39 9 22 34-21 15-34-20-10 35-31 22-19-21 19-32z"/><path d="M65 66v45" fill="none"/>',
 chestBonus:'<path d="M25 57q0-34 40-34t40 34v48H25zM25 62h80M65 25v80"/><path d="M56 57h18v21H56z" fill="#eab84f"/>',
 shield:'<path d="m65 21 37 17-7 43-30 27-30-27-7-43z"/><path d="m65 37 21 10-5 27-16 14-16-14-5-27z" fill="#132a36"/>',
 dashCooldown:'<path d="M70 25a37 37 0 1 1-31 17M23 42h21V22M69 37v28l19 12M20 88h28M13 101h32" fill="none"/>',
 banana:'<path d="M32 20q40 91 75 30-1 67-52 54Q17 90 32 20z"/><path d="M36 40q-7 56 43 60" fill="none"/>',
 enemyPull:'<path d="M19 39l27 25-27 25M111 39 84 64l27 25M18 64h34M112 64H78" fill="none"/><circle cx="65" cy="64" r="12"/>',
 enemyPush:'<path d="m46 39-27 25 27 25M84 39l27 25-27 25M18 64h34M112 64H78" fill="none"/><circle cx="65" cy="64" r="12"/>',
 potionPower:'<path d="M52 21h27v30l23 39q6 23-36 23-41 0-35-23l21-39z"/><path d="M43 76h45M62 83v22M51 94h22M49 31h32" fill="none"/>'
};
const aliases={execute:'bossDamage',berserk:'damage',salvage:'repair',coinRadius:'pickup',airControl:'speed',fallThreshold:'armor',jumpShield:'shield',fallGuard:'armor',landingHeal:'maxHp',slamHeal:'maxHp',potionChance:'luck',potionDuration:'rate',enemyPull:'enemyPull',enemyPush:'enemyPush'};
function symbol(key){
 key=aliases[key]||key;
 if(semantic[key])return semantic[key];
 const w={boomerangPower:'boomerang',boomerangPierce:'boomerang',discPower:'disc',discBounces:'disc',harpoonPower:'harpoon',harpoonPull:'harpoon',gravityPower:'gravity',gravitySize:'gravity',hornPower:'horn',hornStun:'horn',bubblePower:'bubble',bubbleTime:'bubble',meteorPower:'meteor',meteorCount:'meteor',bombPower:'bomb',bombSize:'bomb'}[key];
 if(w)return weaponShape({id:w});
 return legacyArtwork(key);
}
const familyColors={'Mobility':'#75dcb7','Defense':'#81b9d7','Arcane':'#bb87ee','Engineering':'#dcae68','Ballistics':'#ddbd82','Explosives':'#f68849','Nature':'#84c963','Economy':'#efc05e'};
const manifest=[];
for(const item of [...data.loot,...data.weapons]){
 const weapon=!item.effects;const key=item.effects?.[0]?.key;const shape=item.art?.shape??statNames.indexOf(key);
 const condition=item.art && !weapon?item.art.condition:null;
 const color=familyColors[item.family]||palette[Math.max(0,shape)%palette.length];
 const artwork=weapon?weaponShape(item)+weaponAccent(item):item.art?shapes[shape]:symbol(key);
 const emblem=condition!==null?glyphs[condition]:item.kind==='skill'?'<path d="m21 5 5 11 11 5-11 5-5 11-5-11-11-5 11-5z"/>':'<path d="m21 7 14 8v15l-14 7-14-7V15zM7 15l14 8 14-8M21 23v14"/>';
 const additional=item.effects?.slice(1,3).map((e,i)=>`<g transform="translate(${76+i*22} 94) scale(.20)" fill="${color}" stroke="#080e19" stroke-width="5">${symbol(e.key)}</g>`).join('')||'';
 const source=`<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 128 128"><path d="M17 3h94l14 14v94l-14 14H17L3 111V17z" fill="#0a141d" stroke="#987b48" stroke-width="2"/><path d="M22 10h84l12 12v84l-12 12H22l-12-12V22z" fill="#1b2931" stroke="#42584f"/><path d="M14 44v-21l9-9h23m36 0h23l9 9v21M14 84v21l9 9h23m36 0h23l9-9V84" fill="none" stroke="#e1b978" stroke-width="1"/><circle cx="66" cy="66" r="43" fill="none" stroke="#3c4947"/><g transform="translate(3 4)" fill="#050b14" stroke="#050b14" stroke-width="5">${artwork}</g><g fill="${color}" stroke="#07111e" stroke-width="3.4" stroke-linejoin="miter" stroke-linecap="square">${artwork}</g><path d="m55 112 11 4 11-4" fill="none" stroke="#e9ce90" stroke-width="2"/><path d="M4 4h33l6 7v26l-7 6H11l-7-7z" fill="#09141e" stroke="#b38b54"/><g fill="none" stroke="#f4d79b" stroke-width="2.8" stroke-linecap="square" stroke-linejoin="miter">${emblem}</g>${additional}</svg>`;
 await writeFile(new URL(item.id+'.svg',root),source+'\n');
 if(weapon){const pattern=`<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128"><rect width="128" height="128" fill="#18232f"/><path d="M0 9h128M0 119h128M8 0v128M120 0v128" stroke="#bc995e" stroke-width="4"/><path d="m64 24 24 40-24 40-24-40z" fill="${color}" stroke="#07111e" stroke-width="5"/><path d="m64 42 12 22-12 22-12-22z" fill="#15232c"/></svg>`;await writeFile(new URL('textures/'+item.id+'.svg',root),pattern);}
 manifest.push({id:item.id,path:`res://assets/illustrated/content/${item.id}.svg`,semantic:key||item.archetype||item.id,shape,condition:condition===null?item.kind:conditionNames[condition],source:'Original semantic vector geometry; intentional shared effect symbols',sha256:createHash('sha256').update(source).digest('hex')});
}
await writeFile(new URL('manifest.json',root),JSON.stringify(manifest,null,2));
console.log(`${manifest.length} semantic engraved icons; ${data.weapons.length} weapon inlay textures`);
// Achievement art shares the same semantic vocabulary as rewards.
await mkdir(new URL('../achievements/',root),{recursive:true});
const familyKey={Engineering:'turretDamage',Ballistics:'multishot',Explosives:'explosion',Fire:'burn',Frost:'freeze',Electric:'chain',Toxic:'poison',Defense:'shield',Recovery:'regen',Mobility:'speed',Vampiric:'lifesteal',Scavenging:'pickup',Fortune:'luck',Precision:'crit',Assassin:'bossDamage',Aura:'auraDamage',Spectral:'ghost',Burrowing:'burrow',Shadow:'blind',Berserker:'damage',Storm:'chain',Arcane:'nova',Nature:'thorns',Economy:'goldGain',Garden:'flowerPower'};
const heroKey={wrench:'repair',duck:'lifesteal',broccoli:'shield',grandma:'bombPower',goblin:'goldGain',loaf:'damage',florist:'flowerPower'};
for(const a of data.achievements){
 let keys=[];if(a.key.startsWith('combo_'))keys=a.key.slice(6).split('_');
 else if(a.key.startsWith('family_'))keys=[familyKey[a.key.slice(7)]];
 else if(/^(play|win)_/.test(a.key))keys=[heroKey[a.key.split('_')[1]]];
 else {const k=a.key.toLowerCase();keys=[k.includes('boss')?'bossDamage':k.includes('flower')||k.includes('garden')?'flowerPower':k.includes('coin')||k.includes('merchant')?'goldGain':k.includes('ice')?'freeze':k.includes('ghost')?'ghost':k.includes('rescue')||k.includes('revive')?'revive':k.includes('banana')?'banana':k.includes('key')||k.includes('gate')?'keyPower':k.includes('turret')?'turretDamage':k.includes('walk')||k.includes('air')||k.includes('terrace')?'speed':k.includes('reaction')?'chain':'chestBonus'];}
 const art=keys.map((k,i)=>`<g transform="${keys.length>1?`translate(${i*46+3} ${i*20+12}) scale(.65)`:'translate(0 0)'}">${symbol(k)}</g>`).join('');
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 128 128"><path d="M64 3 116 31v57l-52 37-52-37V31z" fill="#111c2a" stroke="#ccaa68" stroke-width="3"/><path d="m22 35 6 18-4 9 9 13-2 10 14 7m61-57-6 18 4 9-9 13 2 10-14 7" fill="none" stroke="#678575" stroke-width="3"/><g fill="#d6b878" stroke="#07111d" stroke-width="3">${art}</g>${a.key.startsWith('win_')?'<path d="m45 21 3-13 11 7 5-12 6 12 11-7 3 13z" fill="#fff0ad"/>':''}</svg>`;
 await writeFile(new URL('../achievements/'+a.id+'.svg',root),svg+'\n');
}
console.log(`${data.achievements.length} achievement seals`);

// Effect keys are used by buff rows and compact HUD symbols, outside card IDs.
await mkdir(new URL('../effects/',root),{recursive:true});
const runtime=await readFile(new URL('../native/scripts/illustrated_icons.gd',import.meta.url),'utf8');
const effectKeys=new Set(['banana','magnetPulse','enemyPull','enemyPush',...data.loot.flatMap(i=>i.effects.map(e=>e.key)),...runtime.matchAll(/"([A-Za-z]+)":\d/g)].map(x=>typeof x==='string'?x:x[1]));
for(const key of effectKeys){
 const svg=`<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><path d="M20 4h88l16 16v88l-16 16H20L4 108V20z" fill="#12212c" stroke="#b69760" stroke-width="3"/><g fill="#d4b674" stroke="#09111e" stroke-width="3">${symbol(key)}</g></svg>`;
 await writeFile(new URL('../effects/'+key+'.svg',root),svg+'\n');
}

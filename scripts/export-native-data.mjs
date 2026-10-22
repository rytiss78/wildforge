import {writeFile,mkdir} from 'node:fs/promises';

import {ITEMS,PERKS,HEROES,createStats,STAT_LABELS} from './data/content.js';

import {ACHIEVEMENTS} from './data/achievements.js';

import {CHEST_PRICES,WEAPON_CAP} from './data/run-rules.js';
import {expandContent} from './data/expansion.js';

const labels={damage:'Power',rate:'Speed',speed:'Move',maxHp:'Health',pickup:'Magnet',size:'Big Shots',range:'Reach',projectileSpeed:'Fast Shots',armor:'Armor',dodge:'Dodge',lifesteal:'Vampire',regen:'Heal',crit:'Critical',critPower:'Big Critical',pierce:'Pierce',splash:'Blast',chain:'Lightning',multishot:'More Shots',burn:'Fire',poison:'Poison',slow:'Ice',knockback:'Push',execute:'Finish',thorns:'Thorns',explosion:'Boom',xpGain:'Learn',luck:'Lucky',chestBonus:'Lucky',dashCooldown:'Quick Dash',dashBlast:'Dash Blast',orbitDamage:'Orbit',magnetPulse:'Magnet',turretDamage:'Turret Power',turretRate:'Turret Speed',turretRange:'Turret Reach',turretLife:'Turret Life',turretCount:'Turret Power',repair:'Repair',auraDamage:'Aura',stun:'Stun',salvage:'Heal',drones:'Drone',revive:'Extra Life',bossDamage:'Boss Power',ghost:'Ghost',burrow:'Mole',blind:'Blind',freeze:'Freeze',shield:'Shield',berserk:'Rage',ricochet:'Bounce',storm:'Storm',nova:'Nova',pools:'Poison Cloud',boomerang:'Return'};

const families={Engineering:'Turret',Ballistics:'Shots',Explosives:'Boom',Fire:'Fire',Frost:'Ice',Electric:'Lightning',Toxic:'Poison',Defense:'Tank',Recovery:'Heal',Mobility:'Dash',Vampiric:'Vampire',Scavenging:'Magnet',Fortune:'Lucky',Precision:'Critical',Assassin:'Finish',Aura:'Aura',Orbitals:'Orbit',Spectral:'Ghost',Burrowing:'Mole',Shadow:'Blind',Berserker:'Rage',Storm:'Storm',Arcane:'Magic',Nature:'Thorns',Chaos:'Magic'};

const loot=[...ITEMS,...PERKS].filter(t=>!t.turret).flatMap(t=>t.effects.map((effect,index)=>({...t,id:t.id+'-'+index,name:labels[effect.key]||families[t.family],title:labels[effect.key]||t.name,kind:PERKS.includes(t)?'skill':'item',effects:[{...effect}]})));

for (const t of loot) for (const e of t.effects) { if(e.key==='turretCount'||e.key==='turretLife') {e.key='turretDamage';e.amount=.2;e.mode='multiply';} if(e.key==='drones') {e.key='chain';e.amount=1;e.mode='add';} if(e.key==='orbitDamage') {e.key='auraDamage';e.mode='add';} if(e.key==='magnetPulse') {e.key='pickup';e.amount=1;e.mode='add';} }

const add=(id,name,key,amount,mode='add')=>loot.push({id,name,title:name,family:'Economy',kind:'item',effects:[{key,amount,mode}]});

add('gold-glove','Gold','goldGain',.3,'multiply');add('cheap-chest','Sale','discount',.12);add('free-key','Key','keyPower',.1);add('gold-boots','Coin Boots','walkGold',.12);add('gold-heart','Gold Heart','hurtGold',1);add('piggy-bank','Savings','interest',.01);add('coin-magnet','Coin Magnet','coinRadius',.5,'multiply');add('pot-finder','Pot Gold','potGold',.3,'multiply');

const weapons=[

 ['flowers','Flowers','Garden',1,1,18],['gun','Gun','Shots',1,1,24],['shotgun','Shotgun','Shots',.6,.65,17],['flame','Fire Gun','Fire',.65,1.3,18],['poison','Poison Gun','Poison',.7,1,22],['ice','Ice Gun','Ice',.7,1,24],['rail','Rail Gun','Shots',2.4,.5,36],['lightning','Lightning','Lightning',1.1,.8,26],['saw','Saw','Thorns',1.6,1,8],['rocket','Rocket','Boom',2,.55,30],['ghost','Ghost Ball','Ghost',1.1,1,26],['turret','Turret','Engineering',1,1.5,25],['fire-turret','Fire Turret','Fire',.8,1.4,18],['ice-turret','Ice Turret','Frost',.8,1.1,22],['poison-turret','Poison Turret','Toxic',.8,1.1,22],['lightning-turret','Storm Turret','Electric',1.2,.9,26],['rocket-turret','Rocket Turret','Explosives',2.3,.5,30]

].map(([id,name,family,damage,rate,range])=>({id,name,family,damage,rate,range,turret:id.includes('turret')}));

const names={wrench:'Wrench',duck:'Count Duck',broccoli:'Tank Potato',grandma:'Stone Granny',goblin:'Tax Rat',loaf:'Sir Loaf'};
weapons.push(...[
 ['boomerang','Boomerang','Shots',1.1,.7,25],['disc','Disc','Shots',.8,.8,28],
 ['harpoon','Harpoon','Shots',1.8,.6,30],['gravity','Gravity Jar','Ghost',.7,.65,25],
 ['horn','Horn','Magic',1.1,.8,14],['bubble','Bubble Gun','Ice',.85,.8,24],
 ['meteor','Meteor Gun','Fire',2.5,.45,32],['bomb','Rolling Bomb','Boom',2.2,.5,25]
].map(([id,name,family,damage,rate,range])=>({id,name,family,damage,rate,range,turret:false})));
const models={wrench:'pipe_wrench',duck:'rubber_duck_toy',broccoli:'sweet_potato',grandma:'marble_bust_01',goblin:'street_rat',loaf:'hamburger_buns'};

const heroes=HEROES.map(h=>({...h,name:names[h.id],model:models[h.id],weapon:h.id==='wrench'?'turret':h.id==='grandma'?'rocket':h.id==='loaf'?'saw':'gun'}));

for(const h of heroes) for(const e of h.effects) if(e.key==='turretCount'){e.key='turretDamage';e.amount=.25;e.mode='multiply';}
heroes.push({id:'florist',name:'Florist',title:'Petal Punk — your footsteps plant a living garden',model:'florist',weapon:'flowers',effects:[]});
for(const [id,name,title,weapon,key,amount,mode] of [
 ['teapot','Queen Tea','Royal china. Unreasonably tough.','ice','armor',5,'add'],
 ['octopus','Captain Eight','Eight arms. Three weapons. Six complaints.','shotgun','multishot',1,'add'],
 ['astronaut','Space Cadet','Lost the spaceship. Kept the laser.','rail','range',.2,'multiply'],
 ['cactus','Prickle Rick','Hugs are a contact sport.','saw','thorns',8,'add'],
 ['book','Bookworm','The spellbook learned to walk.','lightning','chain',1,'add'],
 ['snail','Turbo Snail','Late to everything except trouble.','poison','speed',.15,'multiply'],
 ['bee','Honey Hustler','Buzzing all the way to the bank.','gun','goldGain',.2,'multiply'],
 ['sushi','Roll Ronin','Freshly sliced. Never defeated.','saw','crit',.12,'add'],
 ['mushroom','Chef Cap','Season the enemy. Serve hot.','flame','burn',6,'add'],
 ['clock','Sir Snooze','Five more minutes. One more run.','ice','slow',.15,'add'],
 ['icecream','Disco Scoop','Staying cool under pressure.','ice','freeze',.15,'add'],
 ['bathtub','Admiral Bubbles','Sailing on dry land since breakfast.','rocket','shield',15,'add'],
 ['peacock','Fancy Pants','Show off. Show them all.','ghost','luck',.15,'add'],
 ['toaster','Toastmaster','Breakfast comes with explosions.','flame','explosion',8,'add']
]) heroes.push({id,name,title,model:id,weapon,effects:[{key,amount,mode}]});

// Explicit native hero identities; menu descriptions and gameplay share these effects.
const heroPerks={
 wrench:['Fix It','Turrets hit 35% harder. Heal 2 health per second near your turret.',[['turretDamage',.35,'multiply'],['repair',2,'add']]],
 duck:['Blood Bank','Heal for 8% of the damage your weapons deal.',[['lifesteal',.08,'add']]],
 broccoli:['Iron Potato','Start with 6 armour and 40% more health.',[['armor',6,'add'],['maxHp',.4,'multiply']]],
 grandma:['Granny Splash','Shots splash nearby enemies. Deal 25% more damage to bosses.',[['splash',.45,'add'],['bossDamage',.25,'multiply']]],
 goblin:['Tax Refund','Boxes cost 20% less. Earn 1% interest on saved coins each minute.',[['discount',.2,'add'],['interest',.01,'add']]],
 loaf:['Bread Rush','Dashing blasts nearby enemies for 30 damage.',[['dashBlast',30,'add']]],
 florist:['Flower Power','Plant an extra seed with each step patch. Blooms hit 25% harder and heal 2 extra health.',[['flowerSeeds',1,'add'],['flowerPower',.25,'multiply'],['flowerHeal',2,'add']]],
 teapot:['Tea Break','Regenerate 2 health per second.',[['regen',2,'add']]],
 octopus:['Eight Shot','Fire one extra projectile with each shot.',[['multishot',1,'add']]],
 astronaut:['Moon Boots','Start with a double jump. Deal 25% more weapon damage while airborne.',[['airJumps',1,'add'],['airDamage',.25,'add']]],
 cactus:['Bad Hug','Enemies touching you take 12 thorn damage twice per second.',[['thorns',12,'add']]],
 book:['Chain Letter','Hits chain lightning to two extra enemies.',[['chain',2,'add']]],
 snail:['Slime Trail','Weapon hits poison enemies for 8 damage per second. A sturdy shell adds 3 armour.',[['poison',8,'add']]],
 bee:['Honey Money','Walking earns 0.25 coins per metre. Each coin drop heals 0.5 health.',[['walkGold',.25,'add'],['coinHeal',.5,'add']]],
 sushi:['Sharp Slice','20% chance for weapon hits to deal double damage.',[['crit',.2,'add']]],
 mushroom:['Hot Seasoning','Weapon hits burn enemies for 8 damage per second.',[['burn',8,'add']]],
 clock:['Slow Time','Weapon hits slow enemies by 30%.',[['slow',.3,'add']]],
 icecream:['Brain Freeze','20% chance for weapon hits to freeze an enemy.',[['freeze',.2,'add']]],
 bathtub:['Bubble Bath','Start with 25 shield. It recharges after avoiding damage.',[['shield',25,'add']]],
 peacock:['Show Off','Start with +25% luck. Opening a box heals 12 health.',[['luck',.25,'add'],['chestHeal',12,'add']]],
 toaster:['Pop Goes Toast','Defeated enemies explode for 12 damage.',[['explosion',12,'add']]]
};
for(const h of heroes){const [perk,description,effects]=heroPerks[h.id];h.perk=perk;h.description=description;h.effects=effects.map(([key,amount,mode])=>({key,amount,mode}));}

// Class weapons reuse proven projectile behavior with their own geometry and modifiers.
for(const [id,name,archetype,damage,rate,modifiers,description] of [
 ['ninja-shuriken','Moon Shuriken','disc',.60,.95,{extraShots:1,spread:.12,extraPierce:1},'Twin piercing stars ricochet between enemies.'],
 ['smoke-censer','Smoke Censer','poison',.38,.9,{extraShots:2,spread:.22,shotScale:1.5},'Three heavy toxic shots spread out and poison enemies.'],
 ['bottle-barrage','Last Orders','bomb',1.5,.7,{fuse:.8,areaScale:1.3,payload:'fire'},'Explosive bottles burst after a short fuse.'],
 ['supra-backfire','Turbo Backfire','flame',.42,1.3,{extraShots:1,spread:.18},'Twin exhaust jets burn a broad lane.']
]) {const base=weapons.find(w=>w.id===archetype);weapons.push({...base,id,name,archetype,damage,rate,modifiers,description,icon:id,art:{shape:weapons.length%20,condition:18}});}
for(const [id,name,title,weapon,perk,description,effects] of [
 ['ninja','Ninja','A small shadow with a very large grudge.','ninja-shuriken','Afterimage','Fast feet, high jumps and 12% dodge, with 15% less health.',['dodge',.12,'add']],
 ['smoker','Smoker','An ash-grey coat and an ill-tempered chimney.','smoke-censer','Secondhand Hex','Poison hits deal 10 extra damage per second.',['poison',10,'add']],
 ['alcoholic','Alcoholic','Last call. First into trouble.','bottle-barrage','Last Orders','Bottle explosions and 30% more health.',['maxHp',.3,'multiply']],
 ['white-supra','White Supra','The white coupe has entered the dungeon.','supra-backfire','Turbocharged','Very fast, wide, low-jumping; dashes blast for 24 damage.',['dashBlast',24,'add']]
]) heroes.push({id,name,title,model:id,weapon,perk,description,effects:[{key:effects[0],amount:effects[1],mode:effects[2]}]});
// Screen-filling spells (native/scripts/skill_book.gd): each cast is a large area
// that grows with rank and Size, and multiplies with extra shots. Added after the
// class weapons so their generated art (indexed by list position) is unchanged.
weapons.push(...[
 ['tornado','Twister Totem','Magic',1,.55,20,'Releases wandering twisters that drag enemies in and shred them.'],
 ['blackhole','Void Orb','Ghost',1,.4,26,'Opens a black hole that pulls a crowd together, then collapses in a blast.'],
 ['thunderstorm','Storm Crown','Lightning',1.2,.45,26,'Calls a volley of sky lightning down on every nearby enemy.'],
 ['inferno','Inferno Halo','Fire',1.6,.5,12,'Sends a ring of fire sweeping outward that sets everything alight.']
].map(([id,name,family,damage,rate,range,description])=>({id,name,family,damage,rate,range,turret:false,description})));
// Physical profiles are shared by local collision, remote visuals and selection descriptions.
const physiques={
 wrench:[1.7,.43,.96,.95],duck:[1.5,.38,1.02,1.1],broccoli:[2.05,.57,.82,.8],grandma:[1.85,.48,.86,.85],goblin:[1.2,.31,1.17,1.25],loaf:[1.5,.46,1.05,1.05],
 florist:[1.7,.4,1,1.05],teapot:[1.65,.49,.92,.9],octopus:[1.85,.53,.94,1.15],astronaut:[1.8,.42,.96,1.35],cactus:[1.95,.48,.9,.9],book:[1.35,.36,1.07,1.2],
 snail:[1.25,.47,.85,.7],bee:[1.2,.3,1.2,1.35],sushi:[1.4,.38,1.12,1.15],mushroom:[1.6,.47,.98,1.1],clock:[1.75,.44,.95,1],icecream:[1.9,.39,1.03,1.2],
 bathtub:[1.35,.58,.84,.7],peacock:[2,.48,1.08,1.15],toaster:[1.35,.45,.96,.9],ninja:[1.4,.32,1.24,1.45],smoker:[2.1,.43,.92,.9],alcoholic:[1.75,.53,.88,.8],'white-supra':[1.05,.7,1.42,.55]
};
for(const h of heroes){const [height,radius,speed,jump]=physiques[h.id];Object.assign(h,{height,radius});if(h.id==='ninja')h.effects.push({key:'maxHp',amount:-.15,mode:'multiply'});if(h.id==='snail')h.effects.push({key:'armor',amount:3,mode:'add'});h.effects.push({key:'speed',amount:speed-1,mode:'multiply'},{key:'jumpHeight',amount:jump-1,mode:'multiply'});h.description+=` Height ${height.toFixed(2)} m · Move ${Math.round(speed*100)}% · Jump ${Math.round(jump*100)}%.`;}

for(const [id,name,key,amount] of [['bloom','Big Bloom','flowerPower',.35],['roots','Roots','flowerRoots',.2],['pollen','Pollen','flowerPollen',5],['nectar','Nectar','flowerHeal',2],['seed','Seeds','flowerSeeds',1]]) for(const kind of ['item','skill']) loot.push({id:id+'-'+kind,name,title:name,family:'Garden',kind,effects:[{key,amount,mode:key==='flowerPower'?'multiply':'add'}]});

for(const [id,name,key,amount,mode] of [['jump-boots','Jump Boots','jumpHeight',.2,'multiply'],['extra-hop','Extra Hop','airJumps',1,'add'],['feather-soles','Feather Soles','fallGuard',.2,'add'],['slam-stone','Slam Stone','slamPower',.3,'multiply'],['wide-slam','Wide Slam','slamRadius',.2,'multiply'],['bounce-pad','Bounce Pad','bounceJump',.25,'add']]) for(const kind of ['item','skill']) loot.push({id:id+'-'+kind,name,title:name,family:'Mobility',kind,effects:[{key,amount,mode}]});

Object.assign(labels,{jumpHeight:'Jump Boots',airJumps:'Extra Hop',fallGuard:'Feather Soles',slamPower:'Slam Stone',slamRadius:'Wide Slam',bounceJump:'Bounce Pad',flowerPower:'Big Bloom',flowerRoots:'Roots',flowerPollen:'Pollen',flowerHeal:'Nectar',flowerSeeds:'Seeds'});

const stats={...createStats(),damage:15,rate:1.65,speed:8,maxHp:100,turretCount:1,goldGain:1,discount:0,keyPower:0,walkGold:0,hurtGold:0,interest:0,coinRadius:4,potGold:1,flowerPower:1,flowerRoots:.25,flowerPollen:4,flowerHeal:1,flowerSeeds:0,jumpHeight:1,airJumps:0,fallGuard:0,slamPower:1,slamRadius:1,bounceJump:0};

// A bonus has one common baseline across families; rarity always improves that baseline.
const moreCards=[
 ...['boomerang','disc','harpoon','gravity','horn','bubble','meteor','bomb','tornado','blackhole','thunderstorm','inferno'].map(id=>[id+'-power',weapons.find(w=>w.id===id).name+' Power',id+'Power',.25,'multiply',1]),
 ['disc-bounce','Disc Bounce','discBounces',1,'add',0],['blade-pierce','Blade Pierce','boomerangPierce',1,'add',0],
 ['harpoon-pull','Strong Hook','harpoonPull',.3,'add',0],['big-well','Big Well','gravitySize',.25,'multiply',1],
 ['loud-horn','Loud Horn','hornStun',.3,'add',0],['long-bubble','Long Bubble','bubbleTime',.3,'multiply',1],
 ['meteor-shower','Meteor Shower','meteorCount',1,'add',0],['big-bomb','Big Bomb','bombSize',.25,'multiply',1],
 ['air-power','Air Power','airDamage',.25,'add',0],['soft-heal','Soft Heal','landingHeal',2,'add',0],
 ['rebound-gear','Rebound Gear','slamRecovery',.30,'add',0],['slam-heal','Slam Heal','slamHeal',3,'add',0],['air-steer','Air Steer','airControl',.2,'add',0],
 ['safe-fall','Safe Fall','fallThreshold',1,'add',0],['long-potion','Long Potion','potionDuration',.2,'multiply',1],
 ['strong-potion','Strong Potion','potionPower',.2,'multiply',1],['potion-luck','Potion Luck','potionChance',.15,'add',0],
 ['jump-shield','Jump Shield','jumpShield',2,'add',0],['jump-blast','Jump Blast','jumpBlast',4,'add',0],
 ['slam-fire','Slam Fire','slamFire',4,'add',0],['slam-poison','Slam Poison','slamPoison',4,'add',0],
 ['coin-heal','Coin Heal','coinHeal',.5,'add',0],['chest-heal','Chest Heal','chestHeal',8,'add',0]
];
for(const [id,name,key,amount,mode,base] of moreCards) {
 stats[key]=base;labels[key]=name;
 for(const kind of ['item','skill']) loot.push({id:id+'-'+kind,name,title:name,family:key.startsWith('potion')?'Fortune':'Arcane',kind,effects:[{key,amount,mode}]});
}
stats.banana=0;labels.banana='Banana Business';
for(const kind of ['item','skill']) loot.push({id:'banana-'+kind,name:'Banana Business',title:'Banana Business',family:'Mobility',kind,effects:[{key:'banana',amount:.12,mode:'add'}]});
stats.enemyPull=0;stats.enemyPush=0;labels.enemyPull='Attraction Pulse';labels.enemyPush='Repulsion Pulse';
for(const [id,title,key,amount] of [['attraction-pulse','Attraction Pulse','enemyPull',2],['repulsion-pulse','Repulsion Pulse','enemyPush',3]]) loot.push({id:id+'-skill',name:title,title,family:'Arcane',kind:'skill',effects:[{key,amount,mode:'add'}]});
const discoveries=[['BEACON','Signal Served','Defend an explored supply beacon.'],['MERCHANT','Window Shopping','Buy a positive upgrade from the wandering merchant.'],['MIMIC','Running Refund','Discover a fleeing mimic and its bonus coins.'],['REACTION','Questionable Chemistry','Trigger an elemental reaction.'],['RESCUE','Helping Hand','Rescue a downed party member.'],['PING','Over There','Send a contextual exploration ping.'],['BANANA','Slippery Business','Slip an enemy with Banana Business.'],['TERRACE','Taking the High Road','Explore a raised biome route.']].map(([key,name,description])=>({id:'WF_'+key.toLowerCase(),name,description,key:'event_'+key,target:1,scope:'total',hidden:false}));
// Template cards used to be named after their stat ("Power", "Health"), so up to
// twelve identical names appeared in the pool. Each card is now named after its own
// template (the id stem: "detonator", "red-mist") plus a noun for its stat, with an
// alternate noun or numeral if that still collides. Ids and effects are unchanged.
const STAT_NOUNS={damage:['Edge','Fury'],rate:['Rush','Tempo'],speed:['Stride','Sprint'],maxHp:['Heart','Bulk'],pickup:['Pull','Lure'],
 size:['Swell','Girth'],range:['Sight','Scope'],projectileSpeed:['Zip','Velocity'],armor:['Plating','Hide'],dodge:['Slip','Feint'],
 lifesteal:['Thirst','Leech'],regen:['Mend','Renewal'],crit:['Eye','Focus'],critPower:['Strike','Smash'],pierce:['Lance','Spike'],
 splash:['Blast','Burst'],chain:['Arc','Spark'],burn:['Ember','Flame'],poison:['Fang','Bite'],slow:['Chill','Drag'],knockback:['Shove','Ram'],
 execute:['Mercy','Reaper'],thorns:['Barbs','Thorns'],explosion:['Bang','Boom'],xpGain:['Lesson','Wisdom'],luck:['Charm','Fortune'],
 chestBonus:['Find','Trove'],dashCooldown:['Step','Hop'],dashBlast:['Kick','Pop'],turretDamage:['Rig','Crew'],turretRate:['Gears','Motor'],
 turretRange:['Antenna','Lookout'],repair:['Patch','Fix'],auraDamage:['Halo','Aura'],stun:['Daze','Jolt'],salvage:['Scraps','Salvage'],
 revive:['Lifeline','Second Wind'],bossDamage:['Bane','Slayer'],ghost:['Phase','Shade'],burrow:['Tunnel','Dig'],blind:['Shroud','Murk'],
 freeze:['Frost','Rime'],shield:['Ward','Bubble'],berserk:['Rage','Frenzy'],ricochet:['Rebound','Carom'],storm:['Storm','Thunder'],
 nova:['Nova','Flare'],pools:['Puddle','Mire'],boomerang:['Return','Loop'],multishot:['Spread','Volley'],goldGain:['Greed','Coin'],
 discount:['Bargain','Haggle'],keyPower:['Key','Pick']};
const templateCards=new Set([...ITEMS,...PERKS].filter(t=>!t.turret).flatMap(t=>t.effects.map((e,index)=>t.id+'-'+index)));
const titleCase=text=>text.split(/[-\s]+/).filter(Boolean).map(w=>w[0].toUpperCase()+w.slice(1)).join(' ');
function nameUpgrades(cards){
 const taken=new Set(cards.filter(card=>!templateCards.has(card.id)).map(card=>card.name));
 for(const card of cards){
  if(!templateCards.has(card.id)) continue;
  const stem=titleCase(card.id.replace(/-\d+$/,'').replace(/-perk$/,''));
  const key=card.effects[0].key;const nouns=STAT_NOUNS[key]||[labels[key]||'Boon','Charm'];
  // Skip a noun the template name already uses ("Storm Storm", "Phase Cloak Phase").
  const root=word=>word.toLowerCase().replace(/s$/,'');
  const words=new Set(stem.split(' ').map(root));
  const fresh=nouns.filter(noun=>!noun.split(' ').some(word=>words.has(root(word))));
  const usable=fresh.length?fresh:nouns;
  let name=usable.map(noun=>stem+' '+noun).find(candidate=>!taken.has(candidate))||stem+' '+usable[0];
  for(let n=2;taken.has(name);n++) name=stem+' '+usable[0]+' '+['','','II','III','IV','V'][n];
  taken.add(name);card.name=name;card.title=name;
 }
 // Explicitly named item/skill pairs ("Jump Boots" twice): the skill version is a
 // trained technique, "Mastery" for weapon-power cards and "Drill" otherwise.
 const trained=name=>name.endsWith(' Power')?name.slice(0,-' Power'.length)+' Mastery':name+' Drill';
 const seen=new Map();
 for(const card of cards){
  if(!seen.has(card.name)){seen.set(card.name,card);continue;}
  const skill=card.kind==='skill'?card:seen.get(card.name);
  if(skill!==card) seen.set(card.name,card);
  skill.name=trained(skill.name);skill.title=skill.name;
 }
 const counts={};for(const card of cards) counts[card.name]=(counts[card.name]||0)+1;
 const repeated=Object.entries(counts).filter(([,n])=>n>1);
 if(repeated.length) throw new Error('Duplicate upgrade names: '+repeated.map(([name,n])=>name+'×'+n).join(', '));
}
const bonusBases=new Map();
for(const item of loot){const effect=item.effects[0];if(!bonusBases.has(effect.key))bonusBases.set(effect.key,{...effect});item.effects=[{...bonusBases.get(effect.key)}];}
const augments=expandContent(loot,weapons,stats,labels);
nameUpgrades(loot);
await mkdir(new URL('../native/data/',import.meta.url),{recursive:true});

await writeFile(new URL('../native/data/catalog.json',import.meta.url),JSON.stringify({version:8,heroes,weapons,weaponCap:WEAPON_CAP,loot,stats,labels,families,augments,chestPrices:CHEST_PRICES,achievements:[...ACHIEVEMENTS,...discoveries]},null,2));

console.log(`Native content: ${loot.length} loot templates, ${weapons.length} weapons, ${ACHIEVEMENTS.length+discoveries.length} achievement IDs`);

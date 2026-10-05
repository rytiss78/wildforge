// 360 distinct condition/bonus combinations plus 40 behavioral weapon variants.
// One positive effect per card. IDs and artwork recipes are stable across exports.
export const CONDITIONS=[
 ['air','Skybound','while airborne','Mobility'],['ground','Trail','while grounded','Mobility'],
 ['moving','Runner','while moving','Mobility'],['still','Patient','while stationary','Precision'],
 ['low','Last Stand','below 40% health','Defense'],['healthy','Pristine','above 80% health','Recovery'],
 ['shield','Bubbleguard','while your shield holds','Defense'],['bare','Unarmoured','without shield health','Defense'],
 ['dash','Afterimage','for 3 seconds after dashing','Mobility'],['slam','Quake','for 4 seconds after a slam','Explosives'],
 ['kill','Victory','for 3 seconds after a kill','Assassin'],['hurt','Defiant','for 4 seconds after taking damage','Defense'],
 ['boss','Giantkiller','within 25 metres of a boss','Precision'],['alone','Scout','with no enemy within 8 metres','Scavenging'],
 ['crowd','Crowd','with 4 enemies within 12 metres','Chaos'],['flower','Petal','within 8 metres of a flower','Garden'],
 ['turret','Workshop','within 8 metres of your turret','Engineering'],['rich','Treasury','while carrying at least 50 coins','Economy']
];
export const BONUSES=[
 ['damage','Gauntlet',.25,'multiply','weapon damage'],['rate','Metronome',.22,'multiply','attack speed'],
 ['speed','Boots',.18,'multiply','movement speed'],['regen','Teacup',1.2,'add','health per second'],
 ['armor','Shield',2,'add','armour'],['dodge','Cloak',.06,'add','dodge chance'],
 ['crit','Lens',.08,'add','critical chance'],['critPower','Crown',.25,'multiply','critical damage'],
 ['range','Compass',.2,'multiply','weapon reach'],['projectileSpeed','Arrow',.25,'multiply','projectile speed'],
 ['size','Balloon',.25,'multiply','projectile size'],['knockback','Hammer',.8,'add','knockback metres'],
 ['lifesteal','Fang',.04,'add','lifesteal'],['bossDamage','Spear',.3,'multiply','damage to bosses'],
 ['xpGain','Book',.2,'multiply','XP gain'],['goldGain','Purse',.2,'multiply','coin gain'],
 ['pickup','Magnet',1.2,'add','XP pickup metres'],['turretDamage','Anvil',.3,'multiply','turret damage'],
 ['turretRate','Gears',.25,'multiply','turret attack speed'],['turretRange','Telescope',.25,'multiply','turret reach']
];
const pairs=[
 ['gun','Popcorn Repeater',{extraShots:2,spread:.2},'Needle Driver',{extraPierce:4}],
 ['shotgun','Confetti Cannon',{extraShots:3,spread:.24},'Pebble Blunderbuss',{shotScale:2.2,spread:.06}],
 ['flame','Venom Candle',{payload:'poison'},'Steam Iron',{payload:'bubble'}],
 ['poison','Chilli Sprayer',{payload:'fire'},'Wasp Injector',{extraPierce:3}],
 ['ice','Snow Globe',{payload:'bubble'},'Hail Hose',{extraShots:3,spread:.18}],
 ['rail','Ricochet Ruler',{extraBounce:3},'Knitting Needles',{extraShots:1,spread:.04}],
 ['lightning','Fork Lightning',{extraPierce:4},'Tesla Yo-yo',{returning:true}],
 ['saw','Pizza Wheel',{sweepDot:.1},'Frost Cleaver',{payload:'ice',sweepDot:.35}],
 ['rocket','Bottle Rockets',{extraShots:1,spread:.18},'Cork Launcher',{extraBounce:2}],
 ['ghost','Ember Lantern',{payload:'fire'},'Winter Lantern',{payload:'ice'}],
 ['boomerang','Horseshoe Hook',{extraPierce:4},'Pretzel Twister',{extraBounce:3}],
 ['disc','Vinyl Spinner',{returning:true},'Button Barrage',{extraShots:2,spread:.14}],
 ['harpoon','Venom Anchor',{payload:'poison'},'Trident',{extraShots:2,spread:.11}],
 ['gravity','Teacup Singularity',{areaScale:1.8},'Pocket Black Hole',{durationScale:2}],
 ['horn','Kazoo Chorus',{coneDot:.1},'Sleepy Tuba',{stunBonus:1.1}],
 ['bubble','Slime Soap',{payload:'poison'},'Foam Party',{extraShots:2,spread:.2}],
 ['meteor','Comet Cracker',{areaScale:1.7},'Marble Rain',{extraMeteors:3}],
 ['bomb','Pumpkin Fuse',{fuse:1.8,areaScale:1.6},'Marble Mine',{fuse:.35}],
 ['turret','Staple Sentry',{extraShots:2,spread:.12},'Toaster Sentry',{payload:'fire'}],
 ['fire-turret','Pepper Sentry',{payload:'poison'},'Steam Sentry',{payload:'ice'}]
];
export function expandContent(loot,weapons,stats,labels){
 const augments={};
 for(let c=0;c<CONDITIONS.length;c++)for(let b=0;b<BONUSES.length;b++){
  const [condition,adjective,when,family]=CONDITIONS[c];const [stat,object,amount,mode,label]=BONUSES[b];
  const id=`augment-${condition}-${stat}`;const name=`${adjective} ${object}`;
  augments[id]={condition,stat,mode,when,label};stats[id]=0;labels[id]=name;
  loot.push({id,name,title:name,family,kind:(c+b)%2?'skill':'item',icon:id,art:{shape:b,condition:c},effects:[{key:id,amount,mode:'add'}]});
 }
 for(let a=0;a<pairs.length;a++)for(let v=0;v<2;v++){
  const [base,n0,m0,n1,m1]=pairs[a];const name=v?n1:n0;const modifiers=v?m1:m0;
  const source=weapons.find(w=>w.id===base);const id=name.toLowerCase().replaceAll(/[^a-z0-9]+/g,'-');
  weapons.push({...source,id,name,archetype:base,icon:id,art:{shape:a,condition:18+v},modifiers,
   damage:source.damage*(v?1.12:.9),rate:source.rate*(v?.88:1.1),description:variantDescription(base,modifiers)});
 }
 return augments;
}
function variantDescription(base,m){
 const lines=[];
 if(m.extraShots)lines.push(`Fires ${m.extraShots} extra projectiles per attack`);
 if(m.extraPierce)lines.push(`Pierces ${m.extraPierce} extra targets`);
 if(m.extraBounce)lines.push(`Bounces to ${m.extraBounce} extra targets`);
 if(m.payload)lines.push(`Adds ${m.payload==='bubble'?'a slowing bubble':m.payload==='ice'?'a brief freeze':m.payload==='fire'?'burning damage':'poison damage'} on hit`);
 if(m.returning)lines.push('Projectiles return for another pass');
 if(m.shotScale)lines.push(`Projectiles are ${m.shotScale}× larger`);
 if(m.sweepDot!==undefined)lines.push('Sweeps a wider melee arc');
 if(m.areaScale)lines.push(`Area radius is ${m.areaScale}× larger`);
 if(m.durationScale)lines.push(`Gravity well lasts ${m.durationScale}× longer`);
 if(m.coneDot!==undefined)lines.push('Blasts a much wider sound cone');
 if(m.stunBonus)lines.push(`Sound stuns for ${m.stunBonus} extra seconds`);
 if(m.extraMeteors)lines.push(`Drops ${m.extraMeteors} extra meteors`);
 if(m.fuse)lines.push(`Bomb fuse: ${m.fuse} seconds`);
 return lines.join('. ')+'.';
}

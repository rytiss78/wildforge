import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync,existsSync} from 'node:fs';
const root=new URL('../',import.meta.url);
const catalog=JSON.parse(readFileSync(new URL('native/data/catalog.json',root),'utf8'));
test('every native loot card has one beneficial bonus with a shared rarity baseline',()=>{
 const baselines=new Map();
 assert.ok(catalog.loot.length>=250);
 for(const item of catalog.loot){
  assert.equal(item.effects.length,1,item.id);
  const e=item.effects[0];
  assert.ok(Number.isFinite(e.amount)&&e.amount!==0,item.id);
  assert.ok(e.key==='dashCooldown'?e.amount<0:e.amount>0,item.id);
  const signature=JSON.stringify(e);
  if(baselines.has(e.key))assert.equal(signature,baselines.get(e.key),e.key);
  else baselines.set(e.key,signature);
 }
 for(const key of ['jumpHeight','airJumps','fallGuard','slamPower','slamRadius','bounceJump'])assert.ok(baselines.has(key),key);
});
test('all stable local achievements have paired valid illustrated 256px icons',()=>{
 const steam=JSON.parse(readFileSync(new URL('community/achievements.json',root),'utf8'));
 assert.equal(steam.achievements.length,catalog.achievements.length);
 assert.deepEqual(steam.achievements.map(a=>a.apiName),catalog.achievements.map(a=>a.id));
 const hashes=new Set();
 for(const a of steam.achievements){
  for(const field of ['iconUnlocked','iconLocked']){
   const path=new URL('community/'+a[field],root);assert.ok(existsSync(path));
   const png=readFileSync(path);assert.equal(png.readUInt32BE(16),256);assert.equal(png.readUInt32BE(20),256);
   if(field==='iconUnlocked')hashes.add(png.toString('base64'));
  }
 }
 assert.equal(hashes.size,steam.achievements.length);
});
test('all six first-discovery announcements have original text and rendered audio',()=>{
 const provenance=JSON.parse(readFileSync(new URL('native/assets/voices/voice-provenance.json',root),'utf8'));
 for(let i=0;i<6;i++){
  const line=provenance.lines.find(line=>line.id==='biome_'+i);
  assert.ok(line&&line.duration>1&&line.sha256.length===64);
  assert.ok(existsSync(new URL('native/assets/voices/biome_'+i+'.wav',root)));
 }
});
test('complete 3D roster has articulated heroes, enemy health cores, and baked scenery',()=>{
 const glb=(name)=>{const b=readFileSync(new URL(`native/assets/style3d/${name}.glb`,root));assert.equal(b.toString('ascii',0,4),'glTF');return JSON.parse(b.toString('utf8',20,20+b.readUInt32LE(12)));};
 assert.equal(catalog.heroes.length,25);
 for(const hero of catalog.heroes){
  const doc=glb(hero.model==='rubber_duck_toy'?'count_duck':'hero_'+hero.model);
  assert.ok(doc.nodes.some(n=>n.name?.startsWith('GlassCore')),hero.id+' core');
  assert.ok(doc.nodes.some(n=>n.name?.startsWith('HandSocket')),hero.id+' socket');
  assert.ok(catalog.weapons.some(w=>w.id===hero.weapon));
 }
 for(let b=0;b<6;b++)for(let i=0;i<6;i++){
  assert.ok(glb(`creature_${b}_${i}`).nodes.some(n=>n.name?.startsWith('GlassCore')));
  glb(`prop_${b}_${i}`);
  for(const name of [`creature_${b}_${i}`,`creature_${b}_${i}-core`,`prop_${b}_${i}`])assert.ok(existsSync(new URL(`native/assets/style3d/baked/${name}.res`,root)),name);
 }
 for(let b=0;b<6;b++)glb('harvest_'+b);
 for(const w of catalog.weapons)assert.ok(existsSync(new URL(`native/assets/illustrated/weapon-icons/${w.id}.png`,root)),w.id);
 for(const a of catalog.achievements)assert.ok(existsSync(new URL(`native/assets/illustrated/achievements/${a.id}.svg`,root)),a.id);
});

// The expansion increases the roster to 25 and adds one uncanny creature per biome.
test('new classes have physical profiles and dedicated modeled weapons',()=>{
 for(const id of ['ninja','smoker','alcoholic','white-supra']){
  const h=catalog.heroes.find(h=>h.id===id);assert.ok(h,id);
  const w=catalog.weapons.find(w=>w.id===h.weapon);assert.ok(w?.archetype,id);
  assert.ok(existsSync(new URL(`native/assets/style3d/weapon_${w.id}.glb`,root)));
 }
 assert.ok(new Set(catalog.heroes.map(h=>h.height)).size>=8);
 for(const h of catalog.heroes){assert.ok(h.height>h.radius);assert.ok(h.effects.some(e=>e.key==='jumpHeight'));assert.ok(h.effects.some(e=>e.key==='speed'));}
 for(let b=0;b<6;b++)assert.ok(existsSync(new URL(`native/assets/style3d/creature_${b}_6.glb`,root)));
});

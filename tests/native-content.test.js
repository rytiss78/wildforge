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
test('expanded hero and exotic creature rosters resolve to distinct compact painted assets',()=>{
 assert.equal(catalog.heroes.length,21);
 const art=new Set();
 for(const h of catalog.heroes){
  const png=readFileSync(new URL('native/assets/illustrated/heroes/'+h.model+'.png',root));
  assert.equal(png.readUInt32BE(16),256);assert.equal(png.readUInt32BE(20),256);art.add(png.toString('base64'));
  assert.ok(catalog.weapons.some(w=>w.id===h.weapon));
 }
 assert.equal(art.size,21);
 const creatures=new Set();
 for(let b=0;b<6;b++)for(let s=0;s<6;s++){
  const png=readFileSync(new URL(`native/assets/illustrated/creatures/creature_${b}_${s}.png`,root));
  assert.equal(png.readUInt32BE(16),256);assert.equal(png.readUInt32BE(20),256);creatures.add(png.toString('base64'));
 }
 assert.equal(creatures.size,36);
 for(let b=0;b<6;b++){
  assert.ok(existsSync(new URL(`native/assets/illustrated/terrain-${b}.png`,root)));
  for(let p=0;p<4;p++)assert.ok(existsSync(new URL(`native/assets/illustrated/scenery/prop_${b}_${p}.png`,root)));
 }
});

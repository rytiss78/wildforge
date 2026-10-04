import {test} from 'node:test';
import assert from 'node:assert/strict';
import {CHEST_PRICES,chestPrice,freeChestChance,nextLevelXp,canEquipWeapon,realmGate} from '../scripts/data/run-rules.js';
test('paid chest prices follow MegaBonk while beneficial discounts and keys never increase cost',()=>{assert.equal(CHEST_PRICES.length,80);assert.deepEqual(CHEST_PRICES.slice(0,5),[30,72,115,159,206]);assert.equal(chestPrice(0,.2),24);assert.equal(chestPrice(1),72);assert.equal(freeChestChance(.3),.3/1.3);assert.ok(CHEST_PRICES.every((n,i)=>i===0||n>CHEST_PRICES[i-1]));});
test('turrets and guns share a strict three-weapon cap, while duplicate weapons upgrade',()=>{const weapons=[{id:'gun'},{id:'turret'},{id:'flame'}];assert.equal(canEquipWeapon(weapons,'turret'),true);assert.equal(canEquipWeapon(weapons,'ice'),false);assert.equal(canEquipWeapon(weapons.slice(0,2),'ice'),true);});
test('level growth is slower and gates require defeating both realm bosses',()=>{assert.ok(nextLevelXp(1)>40);assert.ok(nextLevelXp(5)>nextLevelXp(4));assert.equal(realmGate(1,0),'locked');assert.equal(realmGate(2,0),'next');assert.equal(realmGate(2,2),'finish');});

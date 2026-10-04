// Published MegaBonk chest table; free chests do not increment this index.
export const CHEST_PRICES=Object.freeze([30,72,115,159,206,256,309,366,427,495,569,952,1346,1753,2175,2617,3083,3577,4105,4677,5301,6538,7853,9262,10786,12451,14288,16334,18636,21249,24243,28900,34123,40037,46793,54577,63615,74182,86615,101324,118811,166087,193496,225949,264554,310667,365937,432380,512453,609156,726148,962390,1138829,1352108,1610332,1923388,2303340,2764905,3326037,4008642,4839443,5851044,7083220,8584498,10414081,12644194,15362957,18677872,22720088,27649620,33661668,40994392,49938340,60847976,74155752,90389272,110192192,134349776,163820048,199771808]);
export const WEAPON_CAP=3;
export function chestPrice(paidCount,discount=0){if(!Number.isInteger(paidCount)||paidCount<0)throw new Error('Invalid paid chest count');if(paidCount>=CHEST_PRICES.length)throw new Error('Chest price table exhausted');return Math.max(1,Math.ceil(CHEST_PRICES[paidCount]*(1-Math.min(.6,Math.max(0,discount)))));}
export function freeChestChance(keyPower){return Math.max(0,keyPower)/(1+Math.max(0,keyPower));}
export function nextLevelXp(level){return Math.round(24+level*14+level*level*3);}
export function canEquipWeapon(weapons,id){return weapons.some(w=>w.id===id)||weapons.length<WEAPON_CAP;}
export function realmGate(bossesDefeated,realm){return bossesDefeated>=2&&(realm<2?'next':'finish')||'locked';}

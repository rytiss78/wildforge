import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mergeFeedback} from '../scripts/collect-feedback.mjs';
import {ACHIEVEMENTS} from '../scripts/data/achievements.js';
import {readFileSync} from 'node:fs';

test('edited player feedback reopens review without losing its prior text or duplicating ideas',()=>{
  const a={id:'review:1',text:'More flowers',url:'https://example.com/feedback/1'};
  const first=mergeFeedback([],[a,a]);
  first[0].status='Testing';
  const next=mergeFeedback(first,[{...a,text:'Flowers should heal'}]);
  assert.equal(next.length,1);assert.equal(next[0].status,'Needs re-review');
  assert.equal(next[0].revisions[0].text,a.text);
  assert.equal(mergeFeedback(next,[{...a,text:'Flowers should heal'}])[0].status,'Needs re-review');
  assert.throws(()=>mergeFeedback([],[{...a,url:'javascript:alert(1)'}]));
});
test('native achievements have no generic kill-count goals and every build has content',()=>{
  const catalog=JSON.parse(readFileSync('native/data/catalog.json','utf8'));
  assert.equal(ACHIEVEMENTS.length,100);
  assert.ok(ACHIEVEMENTS.every(a=>!a.key.toLowerCase().includes('kill')));
  for(const a of ACHIEVEMENTS.filter(a=>a.key.startsWith('family_'))){
    assert.ok(catalog.loot.some(item=>item.family===a.key.slice(7)),a.id);
  }
  for(const hero of catalog.heroes)assert.ok(catalog.weapons.some(w=>w.id===hero.weapon));
  assert.equal(catalog.weapons.find(w=>w.id==='flowers').turret,false);
});

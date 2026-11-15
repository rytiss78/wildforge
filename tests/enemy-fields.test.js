import test from 'node:test';
import assert from 'node:assert/strict';
import {readdirSync, readFileSync} from 'node:fs';
import {join, dirname} from 'node:path';
import {fileURLToPath} from 'node:url';

// Enemies are plain dictionaries, so a misspelt field (`enemy.frezee`) is not an
// error in Godot: a read gives nothing, a write quietly makes a new field. This
// test is the missing spell-check. Every field the scripts touch through a
// variable called `enemy` must be listed in enemy-fields.json, and every listed
// field must still be in use. Adding a field on purpose means adding it there.
const root=join(dirname(fileURLToPath(import.meta.url)),'..');
const scripts=join(root,'native','scripts');
const listed=JSON.parse(readFileSync(join(root,'tests','enemy-fields.json'),'utf8'));

export function enemyFields(source) {
  const found=new Set();
  for (const m of source.matchAll(/\benemy\.(\w+)\b(?!\()/g)) found.add(m[1]);
  for (const m of source.matchAll(/\benemy\.(?:get|has|erase)\("(\w+)"/g)) found.add(m[1]);
  for (const m of source.matchAll(/\benemy\["(\w+)"\]/g)) found.add(m[1]);
  return found;
}

test('the spell-check sees dotted, get/has/erase and bracket access, not method calls', () => {
  assert.deepEqual([...enemyFields('enemy.hp-=1;enemy.get("slow",0);enemy.erase("pull");enemy["fire"]=2;enemy.duplicate();other.zzz=1')].sort(),['fire','hp','pull','slow']);
});

test('every enemy field used in the game scripts is a known field', () => {
  const known=new Set(listed);const used=new Map();
  for (const file of readdirSync(scripts).filter(f=>f.endsWith('.gd')))
    for (const name of enemyFields(readFileSync(join(scripts,file),'utf8'))) if(!used.has(name)) used.set(name,file);
  const unknown=[...used].filter(([name])=>!known.has(name)).map(([name,file])=>`${name} (${file})`);
  assert.deepEqual(unknown,[],'Enemy fields not in tests/enemy-fields.json. A typo, or a new field to add there: '+unknown.join(', '));
  const unused=listed.filter(name=>!used.has(name));
  assert.deepEqual(unused,[],'Fields listed in tests/enemy-fields.json that no script uses any more: '+unused.join(', '));
  assert.deepEqual(listed,[...listed].sort(),'tests/enemy-fields.json is kept in alphabetical order');
});

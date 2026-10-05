import { readFileSync, mkdirSync, writeFileSync, copyFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const root = new URL('../../../', import.meta.url);
const output = new URL('../artifacts/content/', import.meta.url);
const catalog = JSON.parse(readFileSync(new URL('native/data/catalog.json', root), 'utf8'));
const select = (list, id) => {
  const entry = list.find(entry => entry.id === id);
  if (!entry) throw new Error(`Missing source content: ${id}`);
  return entry;
};
const assets = [
  'native/assets/style3d/count_duck.glb',
  'native/assets/illustrated/heroes/rubber_duck_toy.png',
  'native/assets/voices/quip_duck_weapon.wav',
  'native/assets/voices/quip_duck_boss.wav',
  'native/assets/voices/hurt_duck_0.wav',
];
// Validate before staging anything. Original content remains untouched.
for (const path of assets) if (!existsSync(new URL(path, root))) throw new Error(`Missing asset: ${path}`);
const content = {
  schemaVersion: 1,
  status: 'source-reference-only; runtime plugin imports original GLB and registers adapted gameplay separately',
  sourceCatalogVersion: catalog.version,
  heroes: [select(catalog.heroes, 'duck')],
  weapons: [select(catalog.weapons, 'gun')],
  items: ['fang-0', 'clover-0', 'boots-0'].map(id => select(catalog.loot, id)),
  assets: assets.map(path => ({
    source: path,
    file: path.split('/').at(-1),
    sha256: createHash('sha256').update(readFileSync(new URL(path, root))).digest('hex'),
  })),
};
mkdirSync(output, { recursive: true });
for (const asset of content.assets) copyFileSync(new URL(asset.source, root), new URL(asset.file, output));
writeFileSync(new URL('wildforge-source.json', output), JSON.stringify(content, null, 2) + '\n');
console.log(`Staged Count Duck, one weapon, three item references and ${assets.length} assets at ${fileURLToPath(output)}`);

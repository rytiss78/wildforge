import { existsSync, readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const game = process.env.MEGABONK_DIR || 'G:\\SteamLibrary\\steamapps\\common\\Megabonk';
const has = relative => existsSync(join(game, relative));
let sdk = spawnSync('dotnet', ['--list-sdks'], { encoding: 'utf8', windowsHide: true });
if (sdk.status !== 0) sdk = spawnSync(fileURLToPath(new URL('../../../tools/megabonk-mod/dotnet/dotnet.exe', import.meta.url)), ['--list-sdks'], { encoding: 'utf8', windowsHide: true });
const managers = join(game, 'Megabonk_Data/globalgamemanagers');
const unity = existsSync(managers) ? readFileSync(managers).subarray(0, 256).toString('latin1').match(/20\d{2}\.\d+\.\d+[abfp]\d+/)?.[0] ?? null : null;
const assembly = join(game, 'GameAssembly.dll');
const report = {
  gameDirectory: game,
  unityVersion: unity,
  gameAssemblySha256: existsSync(assembly) ? createHash('sha256').update(readFileSync(assembly)).digest('hex') : null,
  checks: {
    executable: has('Megabonk.exe'),
    il2cppMetadata: has('Megabonk_Data/il2cpp_data/Metadata/global-metadata.dat'),
    loaderCore: has('BepInEx/core/BepInEx.Core.dll'),
    loaderIl2cpp: has('BepInEx/core/BepInEx.Unity.IL2CPP.dll'),
    gameInterop: has('BepInEx/interop/Assembly-CSharp.dll'),
    dotnetSdk: sdk.status === 0 && Boolean(sdk.stdout?.trim()),
    unityEditor: existsSync(`C:/Program Files/Unity/Hub/Editor/${unity}/Editor/Unity.exe`),
  },
  sdkVersions: sdk.status === 0 ? sdk.stdout.trim().split(/\r?\n/).filter(Boolean) : [],
  note: 'Unity editor is optional: the plugin imports its original GLB at runtime. Readiness does not prove gameplay compatibility.',
};
report.readyForBootstrapBuild = report.checks.executable && report.checks.loaderCore && report.checks.loaderIl2cpp && report.checks.gameInterop && report.checks.dotnetSdk;
const output = new URL('../artifacts/', import.meta.url);
mkdirSync(output, { recursive: true });
writeFileSync(new URL('preflight.json', output), JSON.stringify(report, null, 2) + '\n');
console.log(JSON.stringify(report, null, 2));
process.exitCode = report.readyForBootstrapBuild ? 0 : 2;

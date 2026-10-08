import {spawn, spawnSync} from 'node:child_process';
import {createWriteStream, existsSync, mkdirSync, readFileSync, statSync, writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const godot = join(root, 'tools/godot/Godot_v4.7.2-stable_win64_console.exe');
const stage = join(root, '.build-staging/agent-workflow');
const fatal = /SCRIPT ERROR:|Parse Error:|Compile Error:/;

// Keep full evidence on disk and only a bounded tail in memory/chat.
export async function runStep(exe, args, {cwd, env, timeoutMs, logPath}) {
  mkdirSync(resolve(logPath, '..'), {recursive: true});
  const log = createWriteStream(logPath);
  const started = Date.now();
  let output = '', timedOut = false, launchError = null;
  const child = spawn(exe, args, {cwd, env, shell: false, windowsHide: true, stdio: ['ignore', 'pipe', 'pipe']});
  const append = chunk => { log.write(chunk); output = (output + chunk.toString()).slice(-262144); };
  child.stdout.on('data', append);
  child.stderr.on('data', append);
  const timer = setTimeout(() => {
    timedOut = true;
    // Only the process tree created by this invocation is eligible for termination.
    if (child.pid && process.platform === 'win32') {
      spawnSync(join(process.env.SystemRoot || 'C:/Windows', 'System32/taskkill.exe'), ['/PID', String(child.pid), '/T', '/F'], {windowsHide: true, timeout: 10000});
    } else child.kill('SIGKILL');
  }, timeoutMs);
  const code = await new Promise(resolveExit => {
    child.on('error', error => { launchError = error.message; });
    child.on('close', value => resolveExit(value));
  });
  clearTimeout(timer);
  await new Promise(done => log.end(done));
  return {command: [exe, ...args], cwd, exitCode: timedOut ? 124 : code ?? 1,
    timedOut, launchError, seconds: (Date.now() - started) / 1000, logPath, output};
}

export function assessSmoke(output) {
  const line = output.split(/\r?\n/).findLast(x => x.startsWith('NATIVE_SMOKE '));
  if (!line) throw new Error('Missing NATIVE_SMOKE result; an exit code alone is not a pass.');
  const fields = JSON.parse(line.slice('NATIVE_SMOKE '.length));
  const checks = Object.entries(fields).filter(([, value]) => typeof value === 'boolean');
  const failed = checks.filter(([, value]) => !value).map(([key]) => key);
  if (!checks.length || failed.length) throw new Error(`Smoke failed: ${failed.join(', ') || 'no boolean checks'}`);
  return {checksPassed: checks.length, metadataFields: Object.keys(fields).length - checks.length};
}

export function assessPng(path, started, minimum=320) {
  const info = statSync(path);
  if (info.mtimeMs < started - 1000) throw new Error('Capture is stale.');
  const data = readFileSync(path);
  if (!data.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]))) throw new Error('Capture is not a PNG.');
  const width = data.readUInt32BE(16), height = data.readUInt32BE(20);
  if (width < minimum || height < Math.min(minimum,180)) throw new Error('Capture is unexpectedly small.');
  return {path, width, height, bytes: info.size, sha256: createHash('sha256').update(data).digest('hex'), visualReview: 'required'};
}

async function main(action) {
  if (!['progression-review', 'field-review', 'crowd-review', 'check', 'smoke', 'capture', 'capture-ui', 'combat-review', 'pace-review', 'soak', 'scenery-review', 'hunt-review', 'coop', 'journey-review', 'integration', 'build', 'weapon-icons', 'test-build', 'status'].includes(action)) {
    console.error('Usage: node scripts/agent-workflow.mjs check|smoke|capture|capture-ui|combat-review|pace-review|soak|integration|build|status'); return 2;
  }
  const git = (...args) => spawnSync('git', ['-C', root, ...args], {encoding:'utf8', windowsHide:true}).stdout?.trim() ?? '';
  if (action === 'status') { console.log(JSON.stringify({root, node:process.execPath, godot, godotPresent:existsSync(godot), head:git('rev-parse','HEAD'), changes:git('status','--short')}, null, 2)); return 0; }
  const runDir = join(stage, new Date().toISOString().replace(/[:.]/g, '-') + '-' + action);
  mkdirSync(runDir, {recursive:true});
  const started = Date.now();
  const env = {...process.env, APPDATA:join(runDir,'profile/Roaming'), LOCALAPPDATA:join(runDir,'profile/Local'), TEMP:join(runDir,'temp'), TMP:join(runDir,'temp')};
  for (const dir of [env.APPDATA, env.LOCALAPPDATA, env.TEMP]) mkdirSync(dir,{recursive:true});
  const report = {action, started:new Date(started).toISOString(), head:git('rev-parse','HEAD'),
    diffSha256:createHash('sha256').update(git('diff','--binary','HEAD')).digest('hex'), isolatedProfile:env.APPDATA, steps:[], success:false};
  async function step(name, exe, args, timeoutMs) {
    const result = await runStep(exe,args,{cwd:root,env,timeoutMs,logPath:join(runDir,name+'.log')});
    const {output,...record}=result; report.steps.push(record);
    if (result.exitCode !== 0 || fatal.test(output)) throw new Error(`${name} failed (exit ${result.exitCode}). ${output.slice(-2400)}`);
    return output;
  }
  try {
    if (action === 'check') await step('javascript-tests',process.execPath,['--test'],120000);
    if (action === 'check' || action === 'build' || !existsSync(join(root,'native/.godot/global_script_class_cache.cfg'))) {
      await step('godot-import',godot,['--headless','--path',join(root,'native'),'--editor','--import'],180000);
      await step('gdscript-parse',godot,['--headless','--path',join(root,'native'),'--check-only','--script','res://scripts/game.gd'],45000);
    }
    if (action === 'test-build') {
      const previous=JSON.parse(readFileSync(join(stage,'latest-build.json'),'utf8'));
      if(!previous.success || !existsSync(previous.build)) throw new Error('No successful current build to test.');
      const output=await step('exported-combat',previous.build,['--resolution','1440x810','--','--combat-review'],120000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('COMBAT_REVIEW '));
      if(!line) throw new Error('Missing exported combat result.');
      report.combat=JSON.parse(line.slice('COMBAT_REVIEW '.length));report.build=previous.build;
      report.capture=assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge/combat-review.png'),started);
    }
    if (action === 'weapon-icons') {
      const output=await step('weapon-icons',godot,['--path',join(root,'native'),'--script','res://scripts/render_weapon_icons.gd'],180000);
      const weapons=JSON.parse(readFileSync(join(root,'native/data/catalog.json'),'utf8')).weapons;
      if(!output.includes('WEAPON_ICONS_COMPLETE '+weapons.length)) throw new Error('Missing weapon render completion.');
      report.icons=weapons.map(w=>assessPng(join(root,'native/assets/illustrated/weapon-icons',w.id+'.png'),started,128));
    }
    if (action === 'smoke') report.smoke=assessSmoke(await step('native-smoke',godot,['--headless','--path',join(root,'native'),'--','--smoke'],90000));
    if (action === 'integration') {
      const output=await step('integration',godot,['--headless','--path',join(root,'native'),'--','--big-update-check'],180000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('BIG_UPDATE_CHECK '));
      if (!line) throw new Error('Missing integration result.');
      const result=JSON.parse(line.slice('BIG_UPDATE_CHECK '.length));
      const checks=Object.entries(result.checks).filter(([,v])=>typeof v==='boolean');
      if (!result.passed || !checks.length || checks.some(([,v])=>!v)) throw new Error('Integration assertions failed: '+line);
      report.integration={checksPassed:checks.length,routeMaxSlope:result.route_max_slope};
    }
    if (action === 'capture') {
      const output=await step('golden-capture',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--golden-scene'],90000);
      if (!output.includes('GOLDEN_SCENE_SAVED: OK')) throw new Error('Missing successful capture marker.');
      report.capture=assessPng(join(root,'native/docs/golden-scene.png'),started);
    }
    if (action === 'build') {
      const exe=join(runDir,'Wildforge.exe');
      await step('export',godot,['--headless','--path',join(root,'native'),'--export-release','Windows Native',exe],240000);
      for (const artifact of [exe,join(runDir,'Wildforge.pck')]) if (!existsSync(artifact) || statSync(artifact).size < 1024) throw new Error('Missing or empty build artifact: '+artifact);
      report.exportedSmoke=assessSmoke(await step('exported-smoke',exe,['--headless','--','--smoke'],90000));
      report.build=exe;
    }
    if (action === 'capture-ui') {
      const output=await step('ui-capture',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--ui-review'],90000);
      if (!output.includes('UI_REVIEW_SAVED: OK')) throw new Error('UI capture failed.');
      report.capture=['menu','coop','hero','ice-match','hud','potions','potion-icons','chest-opening','chest-reels','offers','focus','weapons'].map(name=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge','ui-'+name+'.png'),started));
    }
    if (action === 'coop') {
      const results=await Promise.allSettled(['host','client'].map(role=>step('coop-'+role,godot,['--headless','--path',join(root,'native'),'--','--coop-'+role+'-test'],90000)));
      const failed=results.filter(r=>r.status==='rejected');
      if(failed.length) throw new Error(failed.map(r=>r.reason.message).join('\n'));
      report.coop=results.map(r=>JSON.parse(r.value.split(/\r?\n/).findLast(x=>x.startsWith('COOP_TEST ')).slice(10)));
    }
    if (action === 'hunt-review') {
      const output=await step('hunt-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--hunt-review'],120000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('HUNT_REVIEW '));
      if (!line) throw new Error('Missing hunt result.');
      report.hunt=JSON.parse(line.slice('HUNT_REVIEW '.length));
      if(Object.values(report.hunt).some(v=>v===false)) throw new Error('Hunt assertions failed.');
      report.capture=['active','complete'].map(i=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge','hunt-'+i+'.png'),started));
    }
    if (action === 'scenery-review') {
      const output=await step('scenery-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--scenery-review'],120000);
      if (!output.includes('"captures_saved":true')) throw new Error('Scenery capture failed.');
      report.capture=[0,2].map(i=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge','scenery-'+i+'.png'),started));
    }
    if (action === 'journey-review') {
      const output=await step('journey-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--journey-review'],120000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('JOURNEY_REVIEW '));
      if (!line) throw new Error('Missing journey checks.');
      report.journey=JSON.parse(line.slice('JOURNEY_REVIEW '.length));
      if(Object.values(report.journey).some(v=>v===false)) throw new Error('Journey checks failed');
      report.capture=['portal','boss','coast'].map(name=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge','journey-'+name+'.png'),started));
    }
    if (action === 'soak') {
      const output=await step('soak',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--soak'],120000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('NATIVE_SOAK '));
      if (!line) throw new Error('Missing soak measurements.');
      report.soak=JSON.parse(line.slice('NATIVE_SOAK '.length));
      report.capture=Array.from({length:6},(_,i)=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge','biome-'+i+'.png'),started));
    }
    if (action === 'pace-review') {
      const output=await step('pace-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--pace-review'],120000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('PACE_REVIEW '));
      if (!line) throw new Error('Missing pace measurements.');
      report.pace=JSON.parse(line.slice('PACE_REVIEW '.length));
      report.capture=assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge/pace-review.png'),started);
    }
    if (action === 'progression-review') {
      const output=await step('progression-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--progression-review'],120000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('PROGRESSION_REVIEW '));
      if(!line) throw new Error('Missing progression result.');
      report.progression=JSON.parse(line.slice(19));
      if(Object.values(report.progression.checks).some(v=>v===false)) throw new Error('Progression assertions failed.');
      report.capture=['stats','cards','recap'].map(name=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge/progression-'+name+'.png'),started));
    }
    if (action === 'field-review') {
      const output=await step('field-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--field-review'],90000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('FIELD_REVIEW '));
      if(!line) throw new Error('Missing field result.');
      report.fields=JSON.parse(line.slice(13));
      if(Object.values(report.fields).some(v=>v===false)) throw new Error('Field checks failed.');
      report.capture=assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge/field-review.png'),started);
    }
    if (action === 'crowd-review') {
      const output=await step('crowd-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--crowd-review'],90000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('CROWD_REVIEW '));
      if(!line) throw new Error('Missing crowd measurements.');
      report.crowd=JSON.parse(line.slice(13));
      report.capture=assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge/crowd-review.png'),started);
    }
    if (action === 'combat-review') {
      const output=await step('combat-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--combat-review'],90000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('COMBAT_REVIEW '));
      if (!line) throw new Error('Missing combat measurements.');
      report.combat=JSON.parse(line.slice('COMBAT_REVIEW '.length));
      report.capture=assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge/combat-review.png'),started);
    }
    report.success=true;
  } catch (error) { report.error=error.message; }
  const reportPath=join(runDir,'result.json'); writeFileSync(reportPath,JSON.stringify(report,null,2));
  writeFileSync(join(stage,'latest-'+action+'.json'),JSON.stringify(report,null,2));
  console.log(JSON.stringify({action,success:report.success,smoke:report.smoke,capture:report.capture,build:report.build,error:report.error,reportPath},null,2));
  return report.success ? 0 : 1;
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) process.exitCode=await main(process.argv[2]);

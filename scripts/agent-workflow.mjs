import {copyFileSync,cpSync} from 'node:fs';
import {spawn, spawnSync} from 'node:child_process';
import {createWriteStream, existsSync, mkdirSync, readFileSync, statSync, writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const root = fileURLToPath(new URL('../', import.meta.url));
const godot = join(root, 'tools/godot/Godot_v4.7.2-stable_win64_console.exe');
const stage = join(root, '.build-staging/agent-workflow');
const fatal = /SCRIPT ERROR:|Parse Error:|Compile Error:/;

// A staged executable can make a binary diff exceed spawnSync's capture limit.
// Hash every byte as it streams; never certify a truncated prefix as source evidence.
export async function diffFingerprint(cwd) {
  const hash=createHash('sha256');
  const child=spawn('git',['-C',cwd,'diff','--binary','HEAD'],{windowsHide:true,stdio:['ignore','pipe','ignore']});
  child.stdout.on('data',chunk=>hash.update(chunk));
  const code=await new Promise((resolve,reject)=>{child.on('error',reject);child.on('close',resolve);});
  if(code!==0) throw new Error('Could not fingerprint Git diff: exit '+code);
  return hash.digest('hex');
}

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
  if (!['playfeel-review', 'red-moon-review', 'fresh-import', 'biome-review', 'release-review', 'roster-review', 'bake-roster', 'style-review', 'boss-review', 'forge-weapon-icon', 'forge-review', 'bake-forge', 'coop-feedback', 'eclipse-review', 'feedback-review', 'controls-review', 'crowd-surface', 'surface-review', 'crowd-eclipse', 'progression-review', 'field-review', 'crowd-review', 'check', 'smoke', 'capture', 'capture-ui', 'combat-review', 'pace-review', 'soak', 'scenery-review', 'hunt-review', 'coop', 'journey-review', 'integration', 'build', 'weapon-icons', 'test-build', 'status'].includes(action)) {
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
    diffSha256:await diffFingerprint(root),
    untrackedFiles:git('ls-files','--others','--exclude-standard','-z').split('\0').filter(Boolean).map(path=>({path,sha256:createHash('sha256').update(readFileSync(join(root,path))).digest('hex')})),
    isolatedProfile:env.APPDATA, steps:[], success:false};
  async function step(name, exe, args, timeoutMs) {
    const result = await runStep(exe,args,{cwd:root,env,timeoutMs,logPath:join(runDir,name+'.log')});
    const {output,...record}=result; report.steps.push(record);
    if (result.exitCode !== 0 || fatal.test(output)) throw new Error(`${name} failed (exit ${result.exitCode}). ${output.slice(-2400)}`);
    return output;
  }
  try {
    if(action==='fresh-import'){
      const clean=join(runDir,'native');
      cpSync(join(root,'native'),clean,{recursive:true,filter:p=>!/(^|[\\/])(\.godot|docs)([\\/]|$)/.test(p)});
      await step('fresh-import',godot,['--headless','--path',clean,'--editor','--import'],240000);
      report.smoke=assessSmoke(await step('fresh-smoke',godot,['--headless','--path',clean,'--','--smoke'],90000));
    }
    if (action === 'check') await step('javascript-tests',process.execPath,['--test'],120000);
    if (action === 'check' || action === 'build' || action === 'bake-forge' || !existsSync(join(root,'native/.godot/global_script_class_cache.cfg'))) {
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
      for (const [flag,prefix,key] of [['--coop-feedback','COOP_FEEDBACK ','coopFeedback'],['--eclipse-review','ECLIPSE_REVIEW ','eclipse'],['--feedback-review','FEEDBACK_REVIEW ','feedback'],['--controls-review','CONTROLS_REVIEW ','controls'],['--surface-review','SURFACE_REVIEW ','surface'],['--progression-review','PROGRESSION_REVIEW ','progression'],['--journey-review','JOURNEY_REVIEW ','journey']]) {
        const details=await step('exported-'+key,previous.build,['--resolution','1440x810','--',flag],120000);
        const resultLine=details.split(/\r?\n/).findLast(x=>x.startsWith(prefix));
        if(!resultLine) throw new Error('Missing exported '+key+' result');
        report[key]=JSON.parse(resultLine.slice(prefix.length));
        if(Object.values(report[key].checks ?? report[key]).some(v=>v===false)) throw new Error('Exported '+key+' checks failed');
      }
      report.featureCaptures=['coop-feedback','feedback-cards','feedback-hud-ping','feedback-report','controls-custom','surface-wall','surface-ceiling','surface-ledge','progression-stats','progression-cards','progression-recap','progression-mobility','journey-corruption-after'].map(name=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge',name+'.png'),started));
    }
    if (action === 'playfeel-review') {
      const output=await step('playfeel-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--playfeel-review'],180000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('PLAYFEEL_REVIEW '));
      if(!line)throw new Error('Missing playfeel review');report.playfeel=JSON.parse(line.slice(15));
      if(Object.values(report.playfeel.checks).includes(false))throw new Error('Playfeel assertions failed');
      report.capture=['slam','turrets','damage',...Array.from({length:6},(_,i)=>'building-'+i)].map(n=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge','playfeel-'+n+'.png'),started));
    }
    if (action === 'red-moon-review') {
      const output=await step('red-moon-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--red-moon-review'],180000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('RED_MOON_REVIEW '));
      if(!line)throw new Error('Missing Red Moon review');report.redMoon=JSON.parse(line.slice(16));
      if(Object.values(report.redMoon.checks).includes(false))throw new Error('Red Moon assertions failed');
      report.capture=['ninja','smoker','alcoholic','white-supra','field','arena','silhouette','attack-0','attack-1','attack-2','attack-3','lance-impact','eclipse'].map(n=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge','red-moon-'+n+'.png'),started));
    }
    if (action === 'weapon-icons') {
      const output=await step('weapon-icons',godot,['--path',join(root,'native'),'--script','res://scripts/render_weapon_icons.gd'],180000);
      const weapons=JSON.parse(readFileSync(join(root,'native/data/catalog.json'),'utf8')).weapons;
      if(!output.includes('WEAPON_ICONS_COMPLETE '+weapons.length)) throw new Error('Missing weapon render completion.');
      report.icons=weapons.map(w=>assessPng(join(root,'native/assets/illustrated/weapon-icons',w.id+'.png'),started,128));
    }
    if (action === 'bake-roster') await step('bake-roster',godot,['--headless','--path',join(root,'native'),'--script','res://scripts/bake_models.gd'],180000);
    if (action === 'bake-forge') await step('bake-forge',godot,['--headless','--path',join(root,'native'),'--script','res://scripts/bake_models.gd','--','--forge-slice'],180000);
    if (action === 'forge-weapon-icon') {
      const output=await step('forge-weapon-icon',godot,['--path',join(root,'native'),'--script','res://scripts/render_weapon_icons.gd','--','--forge-slice'],120000);
      if(!output.includes('WEAPON_ICONS_COMPLETE 1')) throw new Error('Missing weapon render');
      report.capture=assessPng(join(root,'native/assets/illustrated/weapon-icons/gun.png'),started,128);
    }
    if (action === 'roster-review') {
      const output=await step('roster-review',godot,['--path',join(root,'native'),'--script','res://scripts/roster_review.gd'],180000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('ROSTER_REVIEW '));
      if(!line)throw new Error('Missing roster review');report.roster=JSON.parse(line.slice(14));
      if(Object.values(report.roster.checks).includes(false))throw new Error('Roster checks failed');
      report.capture=report.roster.captures.map(p=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge',p.replace('user://','')),started));
    }
    if (action === 'biome-review') {
      const output=await step('biome-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--biome-review'],180000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('BIOME_REVIEW '));
      if(!line)throw new Error('Missing biome result');report.biomes=JSON.parse(line.slice(13));
      if(Object.values(report.biomes.checks).includes(false))throw new Error('Biome review failed');
      report.captures=Array.from({length:6},(_,i)=>['biome-'+i,'biome-fx-'+i]).flat().map(n=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge',n+'.png'),started));
    }
    if (action === 'release-review') {
      const previous=JSON.parse(readFileSync(join(stage,'latest-build.json'),'utf8'));
      if(!previous.success || !existsSync(previous.build))throw new Error('No verified build');report.build=previous.build;
      for(const resolution of ['1280x720','1920x1080']){
        const out=await step('ui-'+resolution,previous.build,['--resolution',resolution,'--','--ui-review'],120000);
        if(!out.includes('UI_REVIEW_SAVED: OK'))throw new Error('Missing UI result');
        const captureDir=join(env.APPDATA,'Godot/app_userdata/Wildforge');
        for(const name of ['ui-menu','ui-about','ui-hero','ui-coop','ui-hud','ui-offers','ui-pause','ui-build']){
          const source=join(captureDir,name+'.png');assessPng(source,started);
          copyFileSync(source,join(runDir,name+'-'+resolution+'.png'));
        }
      }
      for(const [name,prefix] of [['forge','FORGE_REVIEW '],['style','STYLE_REVIEW '],['boss','BOSS_REVIEW '],['biome','BIOME_REVIEW ']]){
        const output=await step('exported-'+name,previous.build,['--resolution','1440x810','--','--'+name+'-review'],180000);
        const line=output.split(/\r?\n/).findLast(x=>x.startsWith(prefix));
        if(!line)throw new Error('Missing exported '+name+' result');
        const result=JSON.parse(line.slice(prefix.length));report[name]=result;
        if(Object.values(result.checks).includes(false))throw new Error('Exported '+name+' assertions failed');
      }
    }
    if (action === 'style-review') {
      const output=await step('style-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--style-review'],120000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('STYLE_REVIEW '));
      if(!line) throw new Error('Missing style review');report.style=JSON.parse(line.slice(13));
      if(Object.values(report.style.checks).some(v=>v===false)) throw new Error('Style review assertions failed');
      report.capture=['idle','warning','impact','expansion','recovery','electric','gravity','poison'].map(n=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge','style-'+n+'.png'),started));
    }
    if (action === 'boss-review') {
      const output=await step('boss-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--boss-review'],180000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('BOSS_REVIEW '));
      if(!line) throw new Error('Missing boss review');report.bosses=JSON.parse(line.slice(12));
      if(Object.values(report.bosses.checks).some(v=>v===false)) throw new Error('Boss review assertions failed');
      report.capture=Array.from({length:8},(_,i)=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge','boss-'+i+'.png'),started));
    }
    if (action === 'forge-review') {
      const output=await step('forge-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--forge-review'],120000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('FORGE_REVIEW '));
      if(!line) throw new Error('Missing forge review');report.forge=JSON.parse(line.slice(13));
      if(Object.values(report.forge.checks).some(v=>v===false)) throw new Error('Forge review assertions failed');
      report.capture=['scene','half','low','empty','remote-half','damage','reward'].map(n=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge','forge-'+n+'.png'),started));
    }
    if (action === 'smoke') report.smoke=assessSmoke(await step('native-smoke',godot,['--headless','--path',join(root,'native'),'--','--smoke'],90000));
    if (action === 'integration') {
      const output=await step('integration',godot,['--verbose','--headless','--path',join(root,'native'),'--','--big-update-check'],180000);
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
        // SAFEGUARD: refuse to build from dirty working tree.
        // A build must always reproduce a committed state; never ship uncommitted code.
        const gitStatus=git('status','--porcelain');
        const lines=gitStatus.split(/\r?\n/).filter(l=>l.trim().length>0);
        const codeFiles=lines.filter(l=>{
          // Track only game source files. Ignore docs, build cache, tool configs, and documentation.
          const path=l.trim().split(/\s+/).slice(1).join(' ');
          // Excluded directories/files
          const excluded=[
            'native/docs/', 'native/.godot/', 'native/data/',   // non-source
            'scripts/', 'tests/', 'tools/', '.build-staging/',   // tooling
            'native/project.godot', 'native/export_presets.cfg',  // build config
            'package.json',                                        // npm config
          ];
          if (excluded.some(e=>path===e||path.startsWith(e))) return false;
          // Excluded file extensions
          const skipExt=['.json','.txt','.cfg','.md','.html','.css','.svg','.png','.jpg','.wav','.ico','.xml'];
          if (skipExt.some(ext=>path.toLowerCase().endsWith(ext))) return false;
          // Track everything else (game scripts, shaders, etc.)
          return true;
        });
        if (codeFiles.length > 0) {
          throw new Error(
            'Build rejected: uncommitted code changes exist. Commit all code changes before building.\n'+
            'Uncommitted files: '+codeFiles.join(', ')
          );
        }
        const exe=join(runDir,'Wildforge.exe');
        await step('export',godot,['--headless','--path',join(root,'native'),'--export-release','Windows Native',exe],240000);
      for (const artifact of [exe,join(runDir,'Wildforge.pck')]) if (!existsSync(artifact) || statSync(artifact).size < 1024) throw new Error('Missing or empty build artifact: '+artifact);
      report.exportedSmoke=assessSmoke(await step('exported-smoke',exe,['--headless','--','--smoke'],90000));
      report.build=exe;
    }
    if (action === 'coop-feedback') {
      const output=await step('coop-feedback',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--coop-feedback'],180000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('COOP_FEEDBACK '));
      if(!line) throw new Error('Missing co-op feedback checks');
      report.coopFeedback=JSON.parse(line.slice('COOP_FEEDBACK '.length));
      if(Object.values(report.coopFeedback).some(v=>v===false)) throw new Error('Co-op feedback checks failed');
      report.capture=assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge/coop-feedback.png'),started);
    }
    if (action === 'eclipse-review') {
      const output=await step('eclipse-review',godot,['--verbose','--headless','--path',join(root,'native'),'--','--eclipse-review'],180000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('ECLIPSE_REVIEW '));
      if(!line) throw new Error('Missing Eclipse checks');
      report.eclipse=JSON.parse(line.slice('ECLIPSE_REVIEW '.length));
      if(Object.values(report.eclipse).some(v=>v===false)) throw new Error('Eclipse checks failed');
    }
    if (action === 'feedback-review') {
      const output=await step('feedback-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--feedback-review'],180000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('FEEDBACK_REVIEW '));
      if(!line) throw new Error('Missing feedback checks');
      report.feedback=JSON.parse(line.slice('FEEDBACK_REVIEW '.length));
      if(Object.values(report.feedback).some(v=>v===false)) throw new Error('Feedback checks failed');
      report.capture=['pickups-before','pickups-after','hud-ping','simple','report','cards'].map(name=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge','feedback-'+name+'.png'),started));
    }
    if (action === 'controls-review') {
      const output=await step('controls-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--controls-review'],180000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('CONTROLS_REVIEW '));
      if(!line) throw new Error('Missing controls checks');
      report.controls=JSON.parse(line.slice('CONTROLS_REVIEW '.length));
      if(Object.values(report.controls).some(v=>v===false)) throw new Error('Controls checks failed');
      report.capture=['before','custom'].map(name=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge','controls-'+name+'.png'),started));
    }
    if (action === 'surface-review') {
      const output=await step('surface-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--surface-review'],180000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('SURFACE_REVIEW '));
      if(!line) throw new Error('Missing surface checks');
      report.surface=JSON.parse(line.slice('SURFACE_REVIEW '.length));
      if(Object.values(report.surface).some(v=>v===false)) throw new Error('Surface checks failed');
      report.capture=['before','wall','ceiling','ledge','slope'].map(name=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge','surface-'+name+'.png'),started));
    }
    if (action === 'capture-ui') {
      const output=await step('ui-capture',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--ui-review'],90000);
      if (!output.includes('UI_REVIEW_SAVED: OK')) throw new Error('UI capture failed.');
      report.capture=['menu','coop','hero','ice-match','hud','build','potions','buff-compatibility','potion-icons','chest-opening','chest-reels','offers','focus','weapons','pause','ended','compatibility','harvest-0','harvest-1','harvest-2','harvest-3','harvest-4','harvest-5','harvest-buffs','damage-text','achievement-icon','achievement'].map(name=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge','ui-'+name+'.png'),started));
    }
    if (action === 'coop') {
      const results=await Promise.allSettled(['host','client'].map(role=>step('coop-'+role,godot,['--headless','--path',join(root,'native'),'--','--coop-'+role+'-test'],420000)));
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
      report.capture=['portal','boss','coast','corruption-before','corruption-after'].map(name=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge','journey-'+name+'.png'),started));
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
      report.capture=['stats','cards','recap','mobility'].map(name=>assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge/progression-'+name+'.png'),started));
    }
    if (action === 'field-review') {
      const output=await step('field-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--field-review'],90000);
      const line=output.split(/\r?\n/).findLast(x=>x.startsWith('FIELD_REVIEW '));
      if(!line) throw new Error('Missing field result.');
      report.fields=JSON.parse(line.slice(13));
      if(Object.values(report.fields).some(v=>v===false)) throw new Error('Field checks failed.');
      report.capture=assessPng(join(env.APPDATA,'Godot/app_userdata/Wildforge/field-review.png'),started);
    }
    if (action === 'crowd-review' || action === 'crowd-eclipse' || action === 'crowd-surface') {
      const output=await step('crowd-review',godot,['--path',join(root,'native'),'--resolution','1440x810','--','--crowd-review',...(action==='crowd-eclipse'?['--eclipse-crowd']:action==='crowd-surface'?['--surface-crowd']:[])],90000);
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

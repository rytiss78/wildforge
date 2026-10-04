import {spawn,spawnSync} from 'node:child_process';
import {existsSync} from 'node:fs';
import {fileURLToPath} from 'node:url';
const root=fileURLToPath(new URL('../',import.meta.url));
const exe=fileURLToPath(new URL('../tools/godot/Godot_v4.7.2-stable_win64_console.exe',import.meta.url));
if(!existsSync(fileURLToPath(new URL('../native/.godot/global_script_class_cache.cfg',import.meta.url)))){
  const imported=spawnSync(exe,['--headless','--path','native','--editor','--import'],{cwd:root,encoding:'utf8'});
  process.stdout.write(imported.stdout||'');
  process.stderr.write(imported.stderr||'');
  // Godot may request an editor restart after first-time GDExtension registration.
  const registered=existsSync(fileURLToPath(new URL('../native/.godot/global_script_class_cache.cfg',import.meta.url)));
  const diagnostic=(imported.stdout||'')+(imported.stderr||'');
  if(imported.status!==0 && !(imported.status===1 && registered && !/\b(?:SCRIPT )?ERROR:/.test(diagnostic)))process.exit(imported.status??1);
}
const test=process.argv.includes('--test');
const child=spawn(exe,[...(test?['--headless']:[]),'--path','native',...(test?['--','--smoke']:[])],{cwd:root,stdio:'inherit'});
child.on('error',error=>{console.error(error.message);process.exitCode=1;});
child.on('exit',code=>{process.exitCode=code??1;});

import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync, writeFileSync, readFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {runStep, assessSmoke, assessPng, diffFingerprint} from '../scripts/agent-workflow.mjs';
import {spawnSync} from 'node:child_process';
import {createHash, randomBytes} from 'node:crypto';

test('wrapper preserves a failing process exit and handles spaces plus paths', async () => {
  const dir=mkdtempSync(join(tmpdir(),'workflow + '));
  const script=join(dir,'fixture + fail.mjs');
  writeFileSync(script,'console.log("evidence"); process.exitCode=7;');
  const result=await runStep(process.execPath,[script],{cwd:dir,env:process.env,timeoutMs:10000,logPath:join(dir,'result.log')});
  assert.equal(result.exitCode,7); assert.match(readFileSync(result.logPath,'utf8'),/evidence/);
});
test('wrapper terminates its own hung process and reports timeout', async () => {
  const dir=mkdtempSync(join(tmpdir(),'workflow-timeout-'));
  const script=join(dir,'hang.mjs'); writeFileSync(script,'setInterval(()=>{},1000);');
  const result=await runStep(process.execPath,[script],{cwd:dir,env:process.env,timeoutMs:500,logPath:join(dir,'timeout.log')});
  assert.equal(result.exitCode,124); assert.equal(result.timedOut,true);
});
test('smoke evidence excludes numeric metadata and rejects missing/false checks', () => {
  assert.deepEqual(assessSmoke('NATIVE_SMOKE {"ok":true,"count":108}'),{checksPassed:1,metadataFields:1});
  assert.throws(()=>assessSmoke('NATIVE_SMOKE {"ok":false,"count":108}'));
  assert.throws(()=>assessSmoke('exit 0'));
});
test('capture evidence rejects stale or invalid image files', () => {
  const dir=mkdtempSync(join(tmpdir(),'workflow-png-')); const path=join(dir,'old.png');
  writeFileSync(path,'not a png'); assert.throws(()=>assessPng(path,0),/not a PNG/);
  assert.throws(()=>assessPng(path,Date.now()+10000),/stale/);
});

test('source fingerprint includes a binary diff beyond the default capture limit', async () => {
  const dir=mkdtempSync(join(tmpdir(),'workflow-large-diff-'));
  const git=(...args)=>{
    const result=spawnSync('git',['-C',dir,...args],{windowsHide:true,maxBuffer:16*1024*1024});
    assert.equal(result.status,0);return result.stdout;
  };
  git('init');writeFileSync(join(dir,'seed.txt'),'baseline');git('add','seed.txt');
  git('-c','user.name=Workflow fixture','-c','user.email=fixture@example.invalid','commit','-m','Fixture');
  writeFileSync(join(dir,'large.bin'),randomBytes(2*1024*1024));git('add','large.bin');
  const complete=git('diff','--binary','HEAD');assert.ok(complete.length>1024*1024);
  assert.equal(await diffFingerprint(dir),createHash('sha256').update(complete).digest('hex'));
});

test('build guard rejects staged, unstaged, untracked and renamed build inputs but permits docs', async () => {
  const {assertCommittedBuild}=await import('../scripts/agent-workflow.mjs');
  const dir=mkdtempSync(join(tmpdir(),'workflow-guard-'));
  const git=(...args)=>{const r=spawnSync('git',['-C',dir,...args],{windowsHide:true});assert.equal(r.status,0);};
  git('init');writeFileSync(join(dir,'package.json'),'{}');git('add','.');
  git('-c','user.name=Workflow fixture','-c','user.email=fixture@example.invalid','commit','-m','Fixture');
  assert.doesNotThrow(()=>assertCommittedBuild(dir));
  writeFileSync(join(dir,'PLAN.md'),'Evidence');assert.doesNotThrow(()=>assertCommittedBuild(dir));
  writeFileSync(join(dir,'package.json'),'{"version":"2"}');assert.throws(()=>assertCommittedBuild(dir),/package.json/);
  git('add','package.json');assert.throws(()=>assertCommittedBuild(dir),/package.json/);
  git('-c','user.name=Workflow fixture','-c','user.email=fixture@example.invalid','commit','-m','Metadata');
  git('mv','package.json','README.md');assert.throws(()=>assertCommittedBuild(dir),/package.json/);
  writeFileSync(join(dir,'new art.svg'),'<svg/>');assert.throws(()=>assertCommittedBuild(dir),/new art.svg/);
});

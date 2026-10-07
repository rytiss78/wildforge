import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtempSync, writeFileSync, readFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {runStep, assessSmoke, assessPng} from '../scripts/agent-workflow.mjs';

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

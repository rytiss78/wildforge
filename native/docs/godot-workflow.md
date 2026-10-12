# Godot workflow for Wildforge

Run these commands in PowerShell from the repository root (`G:\game` on the current machine). Project rules are in [AGENTS.md](../../AGENTS.md). The engine is bundled locally; no editor GUI operation is required to validate scripts or export Windows builds.

## Project map

| Location | Purpose |
| --- | --- |
| `native/project.godot`, `native/main.tscn` | Godot project and main scene |
| `native/scripts/game.gd` | Run lifecycle, combat and several diagnostic entry points |
| `native/scripts/hud.gd` | Menus, HUD, reward cards and notifications |
| `native/scripts/coop.gd` | Host/client transport, snapshots and lobby state |
| `native/scripts/world.gd`, `enemy_surface.gd` | Terrain and enemy traversal |
| `native/scripts/rules.gd`, `native/data/catalog.json` | Rules and runtime content data |
| `native/scripts/upgrade_fit.gd`, `harvest_book.gd` | Current-loadout compatibility and biome harvestables/effects |
| `native/scripts/gameplay_repair_checks.gd`, `hill_checks.gd` | XP/harvest/compatibility regressions (smoke) and small-hill fixtures (surface review) |
| `native/scripts/repair_checks.gd`, `*_checks.gd`, `*_review.gd` | Runtime regression tests and captures |
| `scripts/agent-workflow.mjs` | Preferred validation/export runner |
| `tests/` | Node.js tests; these do not replace Godot runtime tests |
| `native/export_presets.cfg` | Windows export options and executable version |
| `.build-staging/agent-workflow/` | Dated logs, isolated saves, screenshots and builds |

## Start and diagnose

```powershell
node scripts/agent-workflow.mjs status
node scripts/agent-workflow.mjs check
```

`status` reports the executable path and working-tree state. `check` runs Node tests, Godot import, and the main script parse check. The expected engine is `tools/godot/Godot_v4.7.2-stable_win64_console.exe`; the export template is `tools/godot/templates/windows_release_x86_64.exe`.

When `game.gd` says it cannot resolve/preload another script, check the named script directly to reveal its first error:

```powershell
& .\tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path native --check-only --script res://scripts/hud.gd
```

Direct parse checks are a diagnostic shortcut. Re-run the wrapper after fixing the error. Do not treat editor import exit code 0 as proof of success; search the output for `SCRIPT ERROR`, `Parse Error`, and `Compile Error`.

To play manually from source:

```powershell
node scripts/native.mjs
```

This normal launcher uses the player's regular save profile. Automated tests should use the wrapper instead.

## Choose the relevant checks

Prefix every action below with `node scripts/agent-workflow.mjs`.

| Action | Use for | Notes |
| --- | --- | --- |
| `check` | Syntax, import and Node tests | Run first after code edits |
| `smoke` | Startup, menus, basic runtime and repair regressions | Headless; inspects boolean checks, not just process exit |
| `integration` | Gameplay, rewards, content and traversal | Headless; detailed assertions in its log |
| `capture-ui` | Menu, co-op selection, HUD, cards and pause screens | Rendered; inspect the PNGs |
| `controls-review` | Keyboard/controller bindings and settings | Rendered; includes saved-setting checks |
| `combat-review` | Combat, damage numbers and frame measurements | Rendered; metrics alone do not prove improvement |
| `surface-review` | Wall, ceiling, ledge and slope traversal | Rendered; captures several positions |
| `feedback-review`, `progression-review` | Feedback, reports and progression UI | Rendered; inspect feature captures |
| `pace-review` | XP/level pacing | Review measurements against the intended design |
| `eclipse-review` | Eclipse handling and music state | Known acceptance mismatch; see audit |
| `coop-feedback` | Focused multiplayer feedback behavior | Not a substitute for the two-process network test |
| `coop` | Real host/client networking | Approximately six minutes; known wraparound/teardown failures |
| `build` | New Windows executable and pack | Imports/parses, exports and smoke-tests that executable |
| `test-build` | Broader rendered checks of the last exported build | Does not rebuild; currently reaches known Eclipse failures |

Run networking checks sequentially. `capture-ui` also hosts a party; running it during `coop` causes an ENet port error. Ports are UDP 29736 (game) and 29737 (discovery). Do not terminate an unrelated player's game to free them.

The [repair audit](repair-audit-2026-10-12.md) records the October 12 baseline: Eclipse `quick_control`/`brakes` expectations conflict with slower planned drift, and the long co-op test has realm wraparound/teardown failures. Recheck these when working in those areas. Known failures must remain visible in the report, not silently excluded.

## Read evidence and screenshots

Each run prints a `reportPath`. Prefer that exact dated report, especially if more than one action has run. `latest-<action>.json` is only a convenience pointer; overlapping invocations can finish out of order.

```powershell
$godotReport = Get-Content .build-staging/agent-workflow/latest-check.json -Raw | ConvertFrom-Json
$godotReport.success
$godotReport.error
$godotReport.steps | Select-Object exitCode, timedOut, logPath
foreach ($godotStep in $godotReport.steps) {
    Select-String -LiteralPath $godotStep.logPath -Pattern 'SCRIPT ERROR|Parse Error|Compile Error|ERROR:|WARNING:'
}
```

Inspect all diagnostics. The wrapper rejects script errors, but it does not automatically reject every general `ERROR:` or warning. Explain any remaining diagnostic rather than calling the log clean. A failed test is a failure even when screenshots were produced.

```powershell
$uiReport = Get-Content .build-staging/agent-workflow/latest-capture-ui.json -Raw | ConvertFrom-Json
$uiReport.capture | Select-Object path, width, height, visualReview
```

Open those image files in the available image viewer. Check text, clipping, overlays, contrast, icons, focus and selected states. Validate at 1280×720, 1440×810 and 1920×1080 when changing scaling. The logical UI canvas is 1920×1080 with `canvas_items` stretch: use the viewport's logical bounds when checking Control rectangles.

## Export and test the actual executable

After the relevant source checks pass:

```powershell
node scripts/agent-workflow.mjs build
$buildReport = Get-Content .build-staging/agent-workflow/latest-build.json -Raw | ConvertFrom-Json
if (-not $buildReport.success) { throw $buildReport.error }
$buildReport.build
$buildReport.exportedSmoke
```

`build` creates a new dated folder. Keep `Wildforge.exe`, `Wildforge.pck`, and any companion runtime files together. An older executable in `build/` is not automatically replaced. If providing a convenient copy, use a new directory and verify hashes; preserve older builds.

For a focused rendered check of the exported game, use the wrapper's `runStep` helper with an isolated profile. This example tests the actual exported co-op menu and hero-selection buttons; run it only after other party-hosting checks finish:

```powershell
@'
import {mkdirSync, readFileSync, writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {runStep} from './scripts/agent-workflow.mjs';
const build = JSON.parse(readFileSync('.build-staging/agent-workflow/latest-build.json', 'utf8'));
if (!build.success) throw new Error('No successful build.');
const dir = resolve('.build-staging', 'exported-ui-' + Date.now());
const env = {...process.env, APPDATA:dir+'/Roaming', LOCALAPPDATA:dir+'/Local', TEMP:dir+'/temp', TMP:dir+'/temp'};
for (const path of [env.APPDATA, env.LOCALAPPDATA, env.TEMP]) mkdirSync(path, {recursive:true});
const result = await runStep(build.build, ['--resolution','1920x1080','--','--ui-review'], {
  cwd:process.cwd(), env, timeoutMs:90000, logPath:dir+'/ui.log'
});
const success = result.exitCode === 0 && result.output.includes('UI_REVIEW_SAVED: OK')
  && !/SCRIPT ERROR:|Parse Error:|Compile Error:/.test(result.output);
writeFileSync(dir+'/result.json', JSON.stringify({success, build:build.build, ...result}, null, 2));
console.log(result.output);
console.log('Evidence: ' + dir);
process.exitCode = success ? 0 : 1;
'@ | node --input-type=module
```

Screenshots are under that run's `Roaming/Godot/app_userdata/Wildforge/`. `--` separates Godot engine arguments from this game's diagnostic arguments. Inspect the log and images as well as the success flag.

Avoid `npm run package` as a shortcut for a small code repair: its packaging script also regenerates content/art and writes the main `build/` directory. Prefer the staging wrapper unless regeneration is intentional.

## Common failures and their causes

| Symptom | Check / repair |
| --- | --- |
| Cannot preload `hud.gd`; game does not launch | Parse `hud.gd` directly. Look for duplicate declarations, undefined names or a dependency parse failure. |
| Invalid assignment of property/key at runtime | Check the property belongs to that exact Godot class. Parse success cannot validate every dynamically typed assignment. |
| Co-op portrait disappears or crashes after selection | Each rebuilt menu needs a fresh portrait node. A class variable does not keep a node alive when its parent is queued for deletion. |
| “Already has a parent” | Add a node once. Reparent deliberately when reuse is intended; do not attach a child that is about to be deleted. |
| Blank icon despite existing texture | Verify the Control is actually parented, visible and has nonzero size. Then check the art lookup precedence and resource path. |
| UI covers health/coins or appears in a corner | Inspect container ownership, sibling draw order, positions, viewport scaling and generic visibility loops. A background panel added last can cover text. |
| Particles invisible | `ParticleProcessMaterial` handles motion; `GPUParticles3D` owns `amount`, `lifetime`, `emitting`, `preprocess`, and `draw_pass_1`. Supply a draw mesh and exercise the effect. |
| Damage totals contain timestamps or IDs | Keep damage accounting separate from visual-number pooling/deduplication. Test totals after repeated hits. |
| Temporary upgrade lasts forever or multiplies damage wildly | Verify stat units, modifier composition, expiry, refresh, pause and realm/reset behavior. A label saying “20s” does not implement a timer. |
| Enemy sticks to a wall or stops before its top | Test acquisition, continued attachment, ledge transition and detach separately; do not skip attached movement just because target elevation becomes small. |
| Camera starts underground | Check pitch sign and orbit origin. Use a consistent player-body anchor for both the orbit and look-at target. |
| WAV loop has a long gap | `loop_end` is a sample-frame index, not bytes. Verify against stream length and mix rate. |
| ENet host cannot start | Check for another game/test using the shared ports. Run party-hosting tests sequentially. |
| Wrapper times out | Inspect its dated log first: a script error can leave Godot open without reaching the test's quit call. Fix the error before raising timeouts. |

For node/dictionary changes, inspect every constructor and consumer. For example, every record in an effects array must provide the fields the update loop reads. Check cleanup, new-run reset, realm transitions and both host/client paths.

## Completion note template

```text
Changed: <user-visible behavior and root cause>
Verified: <commands, exact dated reports, screenshots inspected>
Build: <actual exported executable path; or no build needed for docs-only work>
Remaining: <known failures/unfinished requirements; do not omit them>
Plan: <item status and evidence link updated>
```

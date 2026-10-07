# Wildforge current handoff
Updated 2026-10-07. User wants substantial standalone quality overhaul: ugly, boring, slow. Ignore mods/megabonk-wildforge. One agent. No new publication performed.

## Completed local checkpoints
- Batch 1 f161c1e: five readable illustrated reward cards, selected comparison, HP/shield HUD, controller focus. UI capture verified.
- Batch 2: higher gameplay camera, normalized smaller ordinary enemies, player locator, calmer terrain, shorter scenery/shadows, staggered enemy simulation. Committed as 9616aeb.

## Fresh batch 2 evidence
- `node scripts/agent-workflow.mjs check`: 13 JS tests + Godot import/parse passed.
- `node scripts/agent-workflow.mjs integration`: 55 boolean checks passed, report 2026-10-07T15-31-31-139Z-integration.
- `node scripts/agent-workflow.mjs build`: export + 67 exported smoke booleans passed; EXE G:/game/.build-staging/agent-workflow/2026-10-07T15-31-47-693Z-build/Wildforge.exe.
- `node scripts/agent-workflow.mjs combat-review`: actual-camera PNG inspected. Stress p95 18.872→13.814ms, draw calls 1497→1084. p50 4.792→5.216ms. One bounded scenario, not global performance certification.
- Before/after evidence under .build-staging/agent-workflow/2026-10-07T15-18-52-715Z-combat-review and 2026-10-07T15-29-45-543Z-combat-review.
- Failed intermediate parse/float precision/stale UI hierarchy checks and fixes recorded in PROGRESS.md.

## Latest completed work and next task
Batch3 committed037b67f: first XP threshold14, first woods chest38–45m; normal-stat fixed scenario first choice13.77s/level4 32.38s. Integration55/check13JS+parse/build67smoke passed.
Batch4 menu: dusk forest backdrop, larger animated hero, retained controller focus. Capture-ui six PNGs (2026-10-07T15-39-51-899Z) inspected menu+hero. Build `G:/game/.build-staging/agent-workflow/2026-10-07T15-40-04-289Z-build/Wildforge.exe` passed67exported smoke checks. Commit next.
Six-biome100-enemy soak (2026-10-07T15-40-38-124Z) traversed all6; PNGs inspected. Hero locatable; some large foreground props. Ground delta>-0.002m. p50 13.695ms/p95 23.519ms NOT60fps pass. Diagnostic O(n²) spacing loop executes repeatedly for100ms everysecond, contaminating measured frames. Next correct sampler to once/second and exclude its following frame from timing; rerun, then profile gameplay if still slow. New wrapper soak action encodes native command and validates6PNGs.
Still open: later-run/other-hero balance, icon semantic audit, remaining roadmap polish. No new release/publication.

## Working state and commands
Preserve preexisting modified AGENTS.md, untracked native/docs/golden-scene.png and nul. Do not stage them. Read git status/diff. No saves deleted; diagnostics isolate APPDATA.
Use node scripts/agent-workflow.mjs check|smoke|integration|capture-ui|combat-review|build. Build development artifacts are not release distributions. Full logs and result JSON under .build-staging/agent-workflow. vision_analyze unavailable; use view_image for actual PNG inspection.

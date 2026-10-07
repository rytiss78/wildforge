# Wildforge current handoff
Updated 2026-10-07. User wants substantial standalone quality overhaul: ugly, boring, slow. Ignore mods/megabonk-wildforge. One agent. No new publication performed.

## Completed local checkpoints
- Batch 1 f161c1e: five readable illustrated reward cards, selected comparison, HP/shield HUD, controller focus. UI capture verified.
- Batch 2: higher gameplay camera, normalized smaller ordinary enemies, player locator, calmer terrain, shorter scenery/shadows, staggered enemy simulation. Pending local commit immediately after this update.

## Fresh batch 2 evidence
- `node scripts/agent-workflow.mjs check`: 13 JS tests + Godot import/parse passed.
- `node scripts/agent-workflow.mjs integration`: 55 boolean checks passed, report 2026-10-07T15-31-31-139Z-integration.
- `node scripts/agent-workflow.mjs build`: export + 67 exported smoke booleans passed; EXE G:/game/.build-staging/agent-workflow/2026-10-07T15-31-47-693Z-build/Wildforge.exe.
- `node scripts/agent-workflow.mjs combat-review`: actual-camera PNG inspected. Stress p95 18.872→13.814ms, draw calls 1497→1084. p50 4.792→5.216ms. One bounded scenario, not global performance certification.
- Before/after evidence under .build-staging/agent-workflow/2026-10-07T15-18-52-715Z-combat-review and 2026-10-07T15-29-45-543Z-combat-review.
- Failed intermediate parse/float precision/stale UI hierarchy checks and fixes recorded in PROGRESS.md.

## Next deliverable
Measure first-minute normal-stat reward/encounter pace, then improve it. Current first-level target41 XP, first chest30 gold at75–95m; base ordinary spawn two per1.9s. Start nine enemies11–16m. Current combat-review is a stress scene (damage4/three weapons/invulnerability), not pacing evidence. Add independent pace-review wrapper, measure before/after. Then menu presentation, all-biome visual review and later-run balance.

## Working state and commands
Preserve preexisting modified AGENTS.md, untracked native/docs/golden-scene.png and nul. Do not stage them. Read git status/diff. No saves deleted; diagnostics isolate APPDATA.
Use node scripts/agent-workflow.mjs check|smoke|integration|capture-ui|combat-review|build. Build development artifacts are not release distributions. Full logs and result JSON under .build-staging/agent-workflow. vision_analyze unavailable; use view_image for actual PNG inspection.

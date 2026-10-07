# Wildforge current handoff

Updated 2026-10-07. User requests a substantial standalone quality overhaul: ugly, boring and slow. Ignore frozen mods/megabonk-wildforge. Use one agent. No new publication requested.

## Current milestone
Batch 1 reward-card/health HUD pass complete. Five horizontal rarity cards, selected comparison, keyboard/controller focus, HP/shield readout, receding control hints. PLAN Phase 1.2 layout complete; semantic icon audit and remaining Phase 1 work open.

## Fresh evidence
- `node scripts/agent-workflow.mjs check`: passed JS suite and Godot import/parse.
- `node scripts/agent-workflow.mjs smoke`: 67 boolean checks passed, 9 metadata fields.
- `node scripts/agent-workflow.mjs capture-ui`: five PNGs + navigation/layout assertions passed. Last screenshots in `.build-staging/agent-workflow/2026-10-07T15-15-10-692Z-capture-ui/profile/Roaming/Godot/app_userdata/Wildforge/`.
- Actual before/after reward, HUD and weapon screenshots inspected via view_image; vision_analyze unavailable. Weapon footer clipping was found and fixed.
- Build: `G:\game\.build-staging\agent-workflow\2026-10-07T15-15-32-813Z-build\Wildforge.exe`; exported smoke passed 67 boolean checks. Full logs under its staging folder.
- Initial three stale smoke assertions replaced with real on-screen/non-overlap and selected-preview checks. See PROGRESS for failures and exact paths.

## Next concrete deliverable
Capture a fixed-seed actual gameplay camera, measure frame times, improve enemy/hero scale readability and noisy terrain. Then encounter/reward pace. Do not confuse the isolated golden diorama with gameplay-camera quality.

## Working state
Read git status/diff. Preexisting AGENTS.md edit, native/docs/golden-scene.png and untracked nul must be preserved. Existing theme, wrapper and game diagnostic changes were carried into the batch 1 checkpoint. No saves deleted.

## Commands
Use node scripts/agent-workflow.mjs check|smoke|capture|capture-ui|build. Node is on PATH. Wrappers use isolated APPDATA, bounded children and staged builds. New capture-ui uses --ui-review selected before career initialization. Build assets are development artifacts, not release distributions.

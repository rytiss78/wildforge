# Wildforge current handoff
Updated2026-10-07. User wants a substantial standalone quality overhaul: ugly, boring, slow; broad freedom. Ignore mods/megabonk-wildforge. One agent. No new release published. Preserve saves and preexisting files.

## Completed local checkpoints
- f161c1e: five readable illustrated reward cards, selected comparison, HP/shield HUD, focus/keyboard/controller checks.
- 9616aeb: higher gameplay camera, normalized smaller ordinary enemies, player locator, calmer terrain, shorter scenery/shadows, staggered enemy30Hz simulation.
- 037b67f: opening XP threshold14 (8+4L+2L²); first woods chest38–45m,24chests/four per biome preserved.
- 2607106: dusk forest menu, larger animated hero portrait, retained hero-selection controller focus, six-image UI diagnostics.
- Latest diagnostic-only correction: soak spacing sampling once/second and exclusion of following diagnostic-contaminated frame. Commit immediately after this update.

## Fresh evidence (full reports in .build-staging/agent-workflow)
- Latest playable EXE: G:/game/.build-staging/agent-workflow/2026-10-07T15-44-29-883Z-build/Wildforge.exe. Keep PCK alongside it. Import/parse/export and67exported smoke boolean checks passed;9metadata fields.
- Latest JS suite13passed: batch4check2026-10-07T15-39-14-615Z. Integration55passed: batch3run2026-10-07T15-36-12-519Z. Menu and diagnostic edits since, not combat/rules edits.
- capture-ui2026-10-07T15-39-51-899Z: sixPNGs, focus/layout assertions. Main menu and TankPotato inspected. Batch1 card/HUD before/after inspected.
- Actual-camera fixed combat stress: p95 18.872→13.814ms, drawcalls1497→1084 (74actors,RX9060XT). Reports2026-10-07T15-18-52-715Z and15-29-45-543Z; bothPNG inspected.
- Normal-stat pace-review2026-10-07T15-35-09-167Z: firstchoice13.77s,level3 16.60s,level4 32.38s;60s survived,66kills,117gold. Baseline died20.88s before anychoice; initial delayed capture failed honestly. Automatic firstchoice/bot movement is not proof of balance/fun.
- Six-biome100+enemy soak2026-10-07T15-40-38-124Z: allsixPNG inspected; player locatable, some large foregroundprops. Original tail timing contaminated by diagnostic spacing loops.
- Corrected soak2026-10-07T15-43-12-117Z:2140samples,p50 11.965ms/p95 16.702ms,106enemies,grounddelta -0.000764m,6regions. No universal60fpsclaim. Minimum pairspacing0.245 unresolved: may be vertical/flying or actualoverlap.

## Next concrete task
Investigate low spacing metric with actual collision-volume vertical overlap; preserve collision/melee/freeze tests. Then extend normal-stat pace tests to other heroes and later bosses. Semantic icon audit, foreground scenery occlusion, movement polish, later-run balance and release acceptance remain open. Current build is a quality-overhaul preview, not all PLAN phases complete.

## Working state/commands
Preexisting modified AGENTS.md, untracked native/docs/golden-scene.png and nul remain untouched/uncommitted. Read git status/diff before edits. No saves deleted, no mod edits.
Use node scripts/agent-workflow.mjs check|smoke|integration|capture-ui|combat-review|pace-review|soak|build. Wrappers isolate APPDATA and preserve full logs/results. Give check/smoke/capture >=180s outer timeout, build>=600s. Build output is a development artifact, not release distribution. vision_analyze unavailable; inspect actualPNG via view_image.

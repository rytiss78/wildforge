# Wildforge current handoff — 2026-10-08

## Objective
User said "do the rest" after lobby release. Continued crowd performance, black-hole/poison visuals and weapon sound requests. Single development agent; standalone game only. Broader PLAN is not all complete.

## Latest implementation
- Large crowds (>80): distant ordinary enemies20Hz, contact-range/bosses30Hz. Same elapsed-time damage/motion. Original collision/steering retained after failed experiments.
- Co-op clients no longer fall through into local enemy movement; elite pulse no longer creates new material per frame.
- AreaVisual: black-hole animated orange accretion/black core; poison and ignited wispy clouds. Local/remote gravity constructor shared; gameplay radii/lifetimes unchanged.
- 21original weapon attacks+3loops, preloaded WAVs, modest pitch variation. Generator scripts/create-weapon-audio.py and native/assets/audio/weapons/provenance.json.
- Existing co-op hero selection/Ready/host Start and bounded48damage labels retained.

## Fresh evidence (all reports .build-staging/agent-workflow/2026-10-08T...)
- crowd-review15-15-11 baseline125enemies p50=115.815,p95=148.533ms. Run failed only erroneous150minimum acceptance; actual game cap125, corrected to120. Capture inspected.
- Capsule/obstacle-probe experiments failed wall_pursuit in integration15-17-04,15-18-16,15-18-58. Both experiments reverted. Integration15-20-09 then passed55.
- final crowd15-21-59:p50=29.501,p95=45.409ms; repeat15-27-31:p50=19.119,p95=33.186ms,combatp95=11.788ms.125enemies, fixed seed81173. Final screenshot inspected. Improvement, not60fps certification.
- coop15-23-15:realhost/client gameplay and lobby checks passed.
- integration15-23-46:55passed after final crowd/VFX changes.
- check15-26-22:13JS+parse/import passed after audio integration.
- field-review15-27-17:4booleans passed; before15-21-04 and after15-23-37 images inspected. Clears kill flash in after diagnostic.
- Audio generator24unique samples, peak0.87, nonzero RMS; in-engine sample and loop playback routing checked. Subjective listening remains open.

## Next concrete work
Finish current export/package/publication and record exact results below. Then loot probability audit (inverse-family weighting is suspicious) and broader max-crowd/biome profiling; broader PLAN features remain open.
Commands: node scripts/agent-workflow.mjs check|integration|coop|crowd-review|field-review|build|test-build. Diagnostic profiles isolated. Do not improvise Godot arguments.

## Preserve
Preexisting AGENTS.md changes and deleted mods/megabonk-wildforge files belong to another process; do not stage them. Untracked native/docs/golden-scene.png, scenery-review-0.png, scenery-review-2.png and nul remain. Preserve saves/logs/captures/history. Older-build deletion twice blocked by automatic review; no deletion performed.
Previous public release test-2026-10-08-lobby at3e4a9e3. User authorized test-build publication and source push.

Final build15-28-11 and exported rendered test-build15-30-04 passed; EXE .build-staging/agent-workflow/2026-10-08T15-28-11-141Z-build/Wildforge.exe. Final EXE combat screenshot inspected;4damage-feedback booleans pass.

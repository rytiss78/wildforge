# Wildforge handoff — 2026-10-08
## Objective
Continue remaining PLAN, single agent. User wants fewer builds/uploads: group multiple tested source milestones. Full roadmap is not complete.
## Latest delivery
Source78e968b pushed. Public https://github.com/rytiss78/wildforge/releases/tag/test-2026-10-08-progression
Local G:/game/build/Wildforge.exe +Wildforge.pck match tested export. ZIP dist/Wildforge-test-2026-10-08-progression-Windows.zip, checksum SHA256SUMS-progression.txt. Both remote assets verified.
Seven older standalone GitHub releases removed. User subsequently requested mod removal: both mod releases and their2tags removed; only progression test release remains. Commit history preserved. Local cleanup completed on renewed user authorization:19obsolete files removed (1,171,961,301bytes); latest stable/staged binaries, latest ZIP/checksums and diagnostic logs preserved.
## Implemented this continuation
- Mechanic-balanced loot and rare ExtraHop scaling.696loot,65weapons.
- Attraction/Repulsion passive skills with distinct SVG art; host-authoritative co-op pulses, boss resistance.
- Detailed pause stats with base/hero/gear-run/buff/augment contributions and equipment. Persistent damage-by-weapon/effect and enemy-type run recap, time/gold/local rank. DOT grouped by effect; overkill excluded.
- Eclipse corruption: stage/tier-scaled dark tint, mild stretch/lean and cached thorn mesh. Existing/new enemies, client snapshot state, collision dimensions unchanged.
-12semantic mobility SVG icons; larger centered card art. Broader icon/model art still open.
## Fresh evidence
Reports under .build-staging/agent-workflow/2026-10-08T...:
check15-55-31:13JS+parse/import. integration15-55-58:55checks. coop15-58-45:realhost/client passed.
progression15-55-47:16booleans,138ExtraHop/12000rolls. Rendered stats/cards/mobility reviewed.
journey15-53-25:21booleans, includes corruption replication and final victory. Before/after inspected.
capture-ui15-59-38:15PNGs/focus/layout, pause/ended/cards inspected unclipped.
crowd-eclipse15-58-24:125enemies,p50=20.898,p95=49.328ms. Ordinary15-59-08:p50=31.837,p95=52.434ms. Not60fps certification.
build16-01-28:72exported smoke booleans+9metadata. test-build16-02-34:4combat+16progression+21journey booleans. Exported combat/cards/corruption captures inspected.
Publication/package/cleanup proof JSON in .build-staging/agent-workflow/.
## Latest source checkpoint (not yet exported)
EnemySurface climbing for ordinary grounded enemies pursuing elevated targets. Walls/ceilings/convex ledges/slopes, freeze/detach, rotated targeting and roof-safe contact. Co-op up/forward snapshots; protocol direct-5 (same-build required). Flyers/bosses unchanged. No extra actor bodies.
Fresh check16-34-46:13JS+parse; surface16-33-54:15booleans/5inspected PNGs; coop16-35-37 bothroles; integration16-36-46:55pass. First surface test failed due old avoidance, fixed. Crowd-surface16-37-40:125attached,max125,framep95=14.122ms,physics43.503ms. Specialized scene, not ground-performance certification.
## Next concrete task
Saved configurable keyboard/controller action bindings with reset/cancel/conflict handling and persistence tests. Continue another source milestone before combined export; current public EXE still progression release, not climbing source.
Use node scripts/agent-workflow.mjs check|surface-review|integration|coop|crowd-surface|build|test-build. Preserve existing meaningful assertions. Broader art/balance/accessibility/performance remain open.
## Preserve
Preserve preexisting AGENTS.md changes. The41previously deleted mod files are now intentionally committed for removal under the user’s explicit instruction. Untracked native/docs/golden-scene.png, scenery-review-0.png, scenery-review-2.png and nul remain. Preserve saves/logs/history. No simultaneous agents.

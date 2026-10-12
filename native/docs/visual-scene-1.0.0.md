# 1.0.0 representative scene development checkpoint

Version remains 0.8.10. This is a validated sub-batch, not the completed 1.0.0 overhaul.

Rebuilt Count Duck, the pistol, six Clover Woods enemies and six prop meshes with new angular silhouettes, gilt details, split cloak, weapon sockets and exposed health vessels. Added a painted basalt/moss ground texture, carved pillars with collision, broken lintels, emerald lights and sparse sparks. The six harvestable effects are unchanged; Cloverheart now has blade leaves and a gilt vessel. The original camera/terrain heights and achievement sound remain unchanged.

Removed the stray boss mesh health bar and changed the boss HUD to a circular HP vessel. Network snapshots previously removed all stats, leaving clients unable to update remote HP and defense orbs. They now send three compact vitals fields; avatar creation and ticking share the visual update. Full stats remain omitted.

## Evidence

All dated evidence roots below are under `.build-staging/agent-workflow/`.

| Check | Result / evidence |
| --- | --- |
| check | Passed; `2026-10-12T18-32-27-666Z-check` |
| smoke | 118 passed; `2026-10-12T18-29-13-123Z-smoke` |
| integration | 57 passed; `2026-10-12T18-29-28-432Z-integration`; existing shutdown leak: 18 objects / 5 resources |
| surface-review | 17 passed; `2026-10-12T18-23-36-684Z-surface-review`; slope screenshot inspected |
| controls-review | Passed; `2026-10-12T18-29-44-819Z-controls-review`; rendered binding/focus screenshot inspected |
| coop-feedback | Passed; `2026-10-12T18-27-57-805Z-coop-feedback`; screenshot inspected |
| forge-review | Passed; `2026-10-12T18-32-01-155Z-forge-review`; real start button, unchanged camera, pillar collision, actor/boss orb states, serialized snapshot remote HP/shields, real critical hit and reward/controller focus |
| combat-review | Passed; `2026-10-12T18-29-58-145Z-combat-review`; screenshot inspected |
| build | `2026-10-12T18-30-36-579Z-build`; exported smoke passed |

Export: G:/game/.build-staging/agent-workflow/2026-10-12T18-30-36-579Z-build/Wildforge.exe. Executable SHA-256: 7f60faa389694e833e5f50267bd2e2c844a570761589b6091b880bc4ead3de71. Exported scene tests passed at 1280x720, 1440x810 and 1920x1080; logs/results/captures in `.build-staging/visual-overhaul-1.0.0/scene-{resolution}/`. Those builds include the snapshot repair; the later source-only test refinement adds a pillar ray assertion and faces the remote test actor toward the camera. Half/low/full/empty HP, remote shield and reward views were inspected. No relevant parse/runtime diagnostics in final scene/control/combat/export logs. The integration shutdown leak remains open.

The original focused co-op fixture crashed by indexing a missing ordinary-hit label: `2026-10-12T18-23-59-834Z-coop-feedback`. It now explicitly checks ordinary-hit suppression and critical confirmation, plus logical viewport bottom-band bounds. This aligns with the existing independently checked critical-only policy; no gameplay assertion was relaxed. Remote vitals failed half/low/empty/shield assertions before the fix: `2026-10-12T18-28-06-275Z-forge-review`.

Combat sample at 1440x810, RX 9060 XT: p50 17.042ms, p95 35.107ms, 684 frames, 5,067 nodes, 1,447 draw calls, 133,975,871 static memory bytes, 66 enemies / 8 kills. Baseline: p50 17.461ms, p95 35.024ms, 4,694 nodes, 1,309 draw calls. Memory was not sampled at baseline. These stochastic samples do not establish a speedup; added geometry/lights increased nodes/draws.

[Scene](visual-overhaul/scene-clover.png) · [Half HP](visual-overhaul/scene-half-hp.png) · [Remote half HP + shield](visual-overhaul/scene-remote-half.png)

## Texture provenance

`native/assets/illustrated/forge-basalt-moss.png` is an original built-in ImageGen output, copied into the project from `C:/Users/rytis/.codex/generated_images/01a13145-e576-7881-93b0-763fe3920669/exec-34bb1a53-8c9a-4530-af07-0a6c8739801d.png`. Prompt brief: seamless square overhead albedo for an original dark mythic action game; strongly inked hand-painted fractured charcoal basalt partly covered in emerald moss; sparse bronze seams, 8-12 main slabs, flat diffuse lighting, no props/text/border, palette #172823/#384941/#205438/#8e784a. The user's reference screenshots are not shipped. Mipmaps are enabled. New model source is `scripts/build-forge-slice.py`; baking is limited by `bake-forge`; pistol art is rendered with `forge-weapon-icon`.

## Remaining

This is still a visual direction checkpoint. The oversized current boss uses the rebuilt Pine Spider; the eight original boss designs/rotation are pending. The minimap, distant biome scenery, most catalog icons/portraits, other heroes/weapons, effects and menus need further work. The ground's detail density and enemy crowd silhouettes need continued review as the rest of the scene evolves. No obsolete files have yet been deleted. Long network wraparound/teardown and Eclipse acceptance failures remain open. Do not mark phases 1-7 complete from this checkpoint.

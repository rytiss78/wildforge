# Build 17 work and evidence

Not built or published yet. Build 16 remains the release.

## Contact attack repair

Enemies previously set an unused `attack_windup` metadata value and damaged immediately. Contact now commits to a target, displays a growing coral ring for 0.45 seconds, then checks range again. Moving away or freezing/blinding the attacker prevents the hit. Host snapshots carry the warning to clients; clients do not resolve damage.

- Reproduced: `.build-staging/agent-workflow/2026-10-15T11-12-16-927Z-integration/result.json` (warning, dodge and freeze regressions fail).
- Passing: `2026-10-15T11-13-48-351Z-integration/result.json`; parse/import/JS `2026-10-15T11-13-24-363Z-check/result.json`.
- Rendered: `2026-10-15T11-15-41-990Z-combat-review/`, including inspected `contact-warning.png` under its isolated profile. Initial capture needed two rendered frames after creating the fixture; retained original.
- Export and real two-process warning validation still pending.

## Performance baseline

Before further crowd optimizations, seed 81173, 125 corrupted enemies, 1440x810: `2026-10-15T11-14-59-697Z-crowd-eclipse/result.json`: frame median 66.70 ms, p95 150.85 ms; combat p95 18.40 ms, physics p95 76.19 ms. This short wall-time benchmark is noisy and does not include global Eclipse weather; use repeated comparable measurements before claiming an improvement.

Crowd movement now uses the existing spatial separation for enemy neighbours while retaining physical terrain/hero collisions. Step-up clearance sweeps run only after a blocked slide and reuse collision objects. Staggered simulation velocity is converted back before feeding animation, avoiding exaggerated walk animation at lower AI frequencies. Diagnostic timing now separates steering, movement and visuals.

Repeated collision A/B: baseline median 66.70 / 67.77 ms; neighbour-collision removal 31.25 / 31.67 ms. With conditional step-up: median 19.93 ms, p95 128.81 ms (`2026-10-15T11-22-19-765Z-crowd-eclipse`). The median improves, but severe p95 hitches remain; this is not a stable-60-FPS claim. Full global Eclipse weather and longer runs still need measurement.

Validation: `2026-10-15T11-20-04-515Z-check`, `2026-10-15T11-20-27-697Z-integration`, `2026-10-15T11-20-55-110Z-surface-review` (wall/ceiling/ledge/slope and small-step fixtures). Crowd and ledge captures inspected. No general warnings or script errors in these logs.

## Baron fallback

Separate authored GLB, heavy suspended robe, bald face, 42 m reference height, very slow movement and four steam vents (64 particles total). Original Observatory asset retained. [Source/provenance and unresolved photorealism](baron-model.md).

Passing source checks: `2026-10-15T11-26-26-512Z-check`, `2026-10-15T11-27-07-564Z-red-moon-review` (portal, immense silhouette, four deadly patterns, real damage/dodge, weapon targeting, local network reconstruction, steam budget and permanent Eclipse). Silhouette and attack capture inspected; no script errors or warnings. Exported appearance and two-process review remain pending.

## Ground and biome pass

Woods now blend smaller slate detail with irregular moss patches aligned with grass islands. Wet biomes use broad low fronds; moon/ember/space use opaque mineral fragments with wind disabled. All remain chunk-instanced, shadow-free and non-colliding. Marsh/cloud alone get two distant low-mist pockets, 24 particles total; immediate player space stays clear, and Eclipse disables them.

Validation: `2026-10-15T11-30-26-270Z-biome-review` renders six normal and six effect views plus marsh/cloud mist-off comparisons. The six-biome contact sheet `.build-staging/build17-biomes.png` was inspected. Terrain, foliage and warning colours remain distinct; subjective Hades-style acceptance is not inferred from a passing check. Check/import/JS `2026-10-15T11-33-27-022Z-check`, gameplay `2026-10-15T11-34-13-410Z-integration` pass. Exported 720p/1080p and final performance measurements remain pending.

## Two-process warning and boss coverage

`2026-10-15T11-31-43-542Z-shared-review` passes real host/client contact-warning replication and final-realm Baron/steam reconstruction, alongside shared XP/chests and guard checks. This narrow test does **not** reproduce or resolve the newly reported early-game co-op desync. That investigation is explicitly scheduled last in PLAN.md.

## Final checkpoint corrections

The enemy-neighbour collision removal was rejected after the soak recorded overlapping enemies (minimum spacing 0.0197). Physical crowd blocking is restored. Conditional step-up, reused collision objects and corrected animation velocity remain. Experimental physics-backend/capsule changes and longer avoidance caching are not shipped. Earlier mask-3 timings do not describe the shipped configuration; performance work remains open.

Minimap rotation used the wrong 2D sign for Godot's 3D camera convention. A regression based independently on 3D forward/right vectors failed before the repair: `2026-10-15T11-47-56-977Z-integration`. Terrain and landmarks now rotate together in the correct direction. HUD reads actual camera orientation so orbit smoothing does not misalign the map. Rendered combat review checks four camera headings, including a deliberately different target yaw. The old regression expectation was incorrect and has been replaced with camera-basis checks at five angles and a translated hero position.

## October 16 source revalidation

- `2026-10-16T16-53-11-738Z-check`: JavaScript tests, Godot import and game-script parse pass. The Windows timeout test had stalled because `taskkill` could not terminate its child in this session. `scripts/agent-workflow.mjs` now falls back to killing the direct child handle when process-tree termination fails; the targeted timeout test and complete `check` both pass.
- `2026-10-16T17-00-43-714Z-smoke`: 118 startup assertions pass. `2026-10-16T17-00-57-822Z-integration`: 71 gameplay assertions pass.
- `2026-10-16T16-53-28-692Z-red-moon-review`: all Baron, attack, warning, damage/dodge, targeting, steam-budget and Eclipse assertions pass. Inspected the 1440×810 silhouette, attack and impact captures. This remains source evidence: exported appearance and the required two-process exported review are not verified. The initial same-day attempt (`2026-10-16T16-45-00-049Z-red-moon-review`) emitted only the startup banner; its cause was not established, and the later full review completed successfully.
- `2026-10-16T16-54-10-283Z-biome-review`: all biome, streaming, scattering and mist assertions pass; inspected woods, marsh and cloudwilds with effects. The open areas still look dark and sparse, so this does not close the user's ground-art/color acceptance request.
- `2026-10-16T17-02-01-075Z-combat-review`: contact warning and minimap camera alignment pass; inspected four camera headings and the warning capture. Render benchmark: 11.55 ms p50, 16.52 ms p95 at 1440×810 with 71 enemies on an AMD Radeon RX 9060 XT; this fixture is not a late-Eclipse performance claim.
- `2026-10-16T17-02-42-511Z-balance-review`: 15 controlled DPS estimates pass. The 24-offensive-card solo projections range from 4.7 minutes for weapons to 20.2 minutes for slam-only; stationary-target uptime assumptions exclude dodging, movement, deaths and realistic upgrade availability. Full-fight balance remains open.
- Repeated seed 81173, 125-enemy Eclipse captures: `2026-10-16T17-03-25-900Z-crowd-eclipse` and `2026-10-16T17-03-59-022Z-crowd-eclipse`. Frame p50/p95 were 15.33/49.50 ms and 14.90/49.59 ms; physics p95 was 117.44/118.95 ms. Frame timing repeated closely, while physics still has large tail stalls. This does not close performance work.
- No script errors, parse errors, compile errors or general warnings appeared in the review logs. No new executable has been exported yet; the clean committed build is the next step.

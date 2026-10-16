# Build 17 work and evidence

Build 17 is a local checkpoint; publication is on hold until the active plan is complete. The latest successful local export is from `23c5c95bb94518f67da19792efd9a3104398b405`; it predates the follow-up art edits recorded below. Build 16 remains the public download.

## Contact attack repair

Enemies previously set an unused `attack_windup` metadata value and damaged immediately. Contact now commits to a target, displays a growing coral ring for 0.45 seconds, then checks range again. Moving away or freezing/blinding the attacker prevents the hit. Host snapshots carry the warning to clients; clients do not resolve damage.

- Reproduced: `.build-staging/agent-workflow/2026-10-15T11-12-16-927Z-integration/result.json` (warning, dodge and freeze regressions fail).
- Passing: `2026-10-15T11-13-48-351Z-integration/result.json`; parse/import/JS `2026-10-15T11-13-24-363Z-check/result.json`.
- Rendered: `2026-10-15T11-15-41-990Z-combat-review/`, including inspected `contact-warning.png` under its isolated profile. Initial capture needed two rendered frames after creating the fixture; retained original.
- Export and real two-process warning validation are recorded below.

## Performance baseline

Before further crowd optimizations, seed 81173, 125 corrupted enemies, 1440x810: `2026-10-15T11-14-59-697Z-crowd-eclipse/result.json`: frame median 66.70 ms, p95 150.85 ms; combat p95 18.40 ms, physics p95 76.19 ms. This short wall-time benchmark is noisy and does not include global Eclipse weather; use repeated comparable measurements before claiming an improvement.

Crowd movement now uses the existing spatial separation for enemy neighbours while retaining physical terrain/hero collisions. Step-up clearance sweeps run only after a blocked slide and reuse collision objects. Staggered simulation velocity is converted back before feeding animation, avoiding exaggerated walk animation at lower AI frequencies. Diagnostic timing now separates steering, movement and visuals.

Repeated collision A/B: baseline median 66.70 / 67.77 ms; neighbour-collision removal 31.25 / 31.67 ms. With conditional step-up: median 19.93 ms, p95 128.81 ms (`2026-10-15T11-22-19-765Z-crowd-eclipse`). The median improves, but severe p95 hitches remain; this is not a stable-60-FPS claim. Full global Eclipse weather and longer runs still need measurement.

Validation: `2026-10-15T11-20-04-515Z-check`, `2026-10-15T11-20-27-697Z-integration`, `2026-10-15T11-20-55-110Z-surface-review` (wall/ceiling/ledge/slope and small-step fixtures). Crowd and ledge captures inspected. No general warnings or script errors in these logs.

## Baron fallback

Separate authored GLB, heavy suspended robe, bald face, 42 m reference height, very slow movement and four steam vents (64 particles total). Original Observatory asset retained. [Source/provenance and unresolved photorealism](baron-model.md).

Passing source checks: `2026-10-15T11-26-26-512Z-check`, `2026-10-15T11-27-07-564Z-red-moon-review` (portal, immense silhouette, four deadly patterns, real damage/dodge, weapon targeting, local network reconstruction, steam budget and permanent Eclipse). Silhouette and attack capture inspected; no script errors or warnings. Exported appearance was reviewed below.

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
- `2026-10-16T16-53-28-692Z-red-moon-review`: all Baron, attack, warning, damage/dodge, targeting, steam-budget and Eclipse assertions pass. Inspected the 1440×810 silhouette, attack and impact captures. The initial same-day attempt (`2026-10-16T16-45-00-049Z-red-moon-review`) emitted only the startup banner; its cause was not established, and the later full review completed successfully.
- `2026-10-16T16-54-10-283Z-biome-review`: all biome, streaming, scattering and mist assertions pass; inspected woods, marsh and cloudwilds with effects. The open areas still look dark and sparse, so this does not close the user's ground-art/color acceptance request.
- `2026-10-16T17-02-01-075Z-combat-review`: contact warning and minimap camera alignment pass; inspected four camera headings and the warning capture. Render benchmark: 11.55 ms p50, 16.52 ms p95 at 1440×810 with 71 enemies on an AMD Radeon RX 9060 XT; this fixture is not a late-Eclipse performance claim.
- `2026-10-16T17-02-42-511Z-balance-review`: 15 controlled DPS estimates pass. The 24-offensive-card solo projections range from 4.7 minutes for weapons to 20.2 minutes for slam-only; stationary-target uptime assumptions exclude dodging, movement, deaths and realistic upgrade availability. Full-fight balance remains open.
- Repeated seed 81173, 125-enemy Eclipse captures: `2026-10-16T17-03-25-900Z-crowd-eclipse` and `2026-10-16T17-03-59-022Z-crowd-eclipse`. Frame p50/p95 were 15.33/49.50 ms and 14.90/49.59 ms; physics p95 was 117.44/118.95 ms. Frame timing repeated closely, while physics still has large tail stalls. This does not close performance work.
- `2026-10-16T17-06-29-142Z-build`: clean committed Build 17 export from `ef416c16e8f0173327cf2708d66f6d4ac08a8fcc`; exported startup smoke passes 118 checks. Executable, pack and build manifest hashes are in that report.
- `2026-10-16T17-07-06-311Z-release-review`: exported UI at 1280×720 and 1920×1080, forge/style checks, all eight bosses and six biomes pass. Inspected menu, HUD, reward cards and Baron capture; no clipping observed in those views.
- `2026-10-16T17-09-22-042Z-hermes-review`: exported Baron/attack, hunt and Eclipse feature assertions pass; this single-process review does not substitute for shared-session co-op.
- `2026-10-16T17-22-37-198Z-shared-review`: fail-fast source host/client review passes all 42 shared progression, chest, magnet, guard, contact-warning and Baron checks when run outside the sandbox. Earlier sandbox-only attempts blocked loopback UDP; their member/chest index errors were secondary setup failures.
- `2026-10-16T17-23-19-316Z-shared-review`: packaged `Wildforge.console.exe` host/client review passes all 39 checks, including Build 17 contact-warning replication and Baron reconstruction. Console executable is required for headless packaged tests.
- These focused shared checks do not reproduce or resolve the early-game desynchronization. That investigation remains last in PLAN.md.
- Human gamepad/audio checks, art acceptance, full-fight balance and late-Eclipse performance remain open.

## October 16 continuation

- `2026-10-16T17-27-50-320Z-check` and `2026-10-16T17-32-43-957Z-check`: JS tests plus Godot import/parse pass after terrain, HUD-copy and review-harness edits.
- `2026-10-16T17-28-06-501Z-biome-review`: all six biomes, stream/scattering and mist checks pass. Inspected all six 1440×810 captures. Midtones are brighter and more distinct; Woods still reads as bare slate in open areas, Cloudwilds is crowded by large trunks, and Candy Hell still needs stronger ground detail. Art acceptance remains open.
- Eclipse crowd at seed 81173, 125 enemies, 1440×810: baseline `2026-10-16T17-27-08-100Z-crowd-eclipse` was 14.21 ms p50 / 50.81 ms p95 frame and 117.15 ms physics p95. With the terrain shader edit, `2026-10-16T17-28-49-366Z-crowd-eclipse` was 14.27 / 51.02 ms and 118.99 ms physics p95. The comparable results are effectively unchanged; late-Eclipse performance remains open.
- `2026-10-16T17-30-02-035Z-balance-review`: all 15 controlled damage fixtures pass. At 24 offensive cards, ideal solo projections are 4.7 minutes weapons, 3.4 minutes turrets, 16.1 minutes status, 20.2 minutes slam and 7.3 minutes flowers; stationary, invulnerable uptime is not real-fight balance or win-rate evidence.
- `2026-10-16T17-41-02-559Z-progression-review` and `2026-10-16T17-41-15-807Z-feedback-review`: all stat-total, damage attribution, persistence, death-count, last-run trimming, card reachability, mobility-icon and recap checks pass. Reviewed the rendered captures. The run screens now label enemy totals clearly and show an empty state when there were no kills.
- The boss review now explicitly covers the final Baron, because the previous eight-boss loop skipped him. `2026-10-16T17-40-06-651Z-boss-review` passes 42 m height, 9 m radius, cylinder collision, four emitting vents, network reconstruction and matching remote collision. Inspected `boss-baron.png` in that run: the whole stylized silhouette fits at 69 m using the normal 12 m third-person camera tilted slightly upward. Steam still does not read clearly in the capture, so visible-steam/art acceptance and exported-game review remain open. Photoreal/licensed asset research is still unresolved.
- Early co-op desync remains deliberately untouched until it is the sole active plan item. Nothing from these shared-review tests proves it fixed.

## Local Build 17 export from this continuation

- Source commit: `d64857f05f925503064c3d8b9cb1749aeef0c896`; clean tree at export.
- Export: `.build-staging/agent-workflow/2026-10-16T17-46-02-132Z-build/Wildforge.exe` with companion `Wildforge.console.exe` and `Wildforge.pck`. The manifest records executable SHA-256 `ac8086889c3f385fc8152cf543b84eb1e931ab6b8096379a155a133c3503436f` and pack SHA-256 `e763873885cdfe6ac2ac8757a118bf876f1b3022a08f1c509e37676e3661247e`.
- Exported startup: 118 smoke checks pass. `2026-10-16T17-46-58-554Z-release-review` passes exported UI at 1280×720 and 1920×1080, plus forge, style, eight-roster-boss and six-biome checks. Inspected exported menu, HUD, and offer captures at both resolutions; no clipping in those views.
- Packaged host/client: `2026-10-16T17-48-38-211Z-shared-review` passes all 42 checks against this exact export. This remains focused shared-feature coverage, not the deferred early-game desync reproduction.
- Exported smoke, boss, biome, host and client logs contain no `ERROR`, `WARNING` or script-error entries. This is a local development build only; no release or upload was created.

## Follow-up before the next local export

- Baron vent locations were moved from behind the robe to its front. `2026-10-16T17-51-22-336Z-boss-review` passes the source checks and the inspected `boss-baron.png` now shows four visible puffs; retain the 64-particle budget. The committed local export above predates this placement correction; rerun its exported review after committing.
- Ground cover increased from 900 to 1100 candidates per chunk, relaxed the patch rejection threshold and slightly increased tuft size. `2026-10-16T17-52-23-166Z-biome-review` passes; Woods and marsh show fuller clumps, but open lanes remain bare, Cloudwilds still crowds the view, and Candy Hell has sparse ground detail.
- After the foliage change, repeated seed 81173 / 125-enemy Eclipse runs `2026-10-16T17-52-58-660Z-crowd-eclipse` and `2026-10-16T17-53-29-794Z-crowd-eclipse` measured frame p50/p95 14.90/48.40 ms and 14.88/54.58 ms; physics p95 122.58/135.67 ms. No reliable improvement is established; performance stays open.
- Follow-up source commit: `23c5c95bb94518f67da19792efd9a3104398b405`. Clean local export: `.build-staging/agent-workflow/2026-10-16T17-57-26-034Z-build/Wildforge.exe`; pack SHA-256 `32d7e80237d61b6caee8098beaf18b99a3c364c37bcbe97759d15c11f30035c1`, executable SHA-256 `ac8086889c3f385fc8152cf543b84eb1e931ab6b8096379a155a133c3503436f`.
- Exported startup passes 118 checks. `2026-10-16T17-57-55-126Z-release-review` passes 720p/1080p UI and exported forge/style/boss/biome reviews; inspected its exported six-biome captures and Baron view. The new front-facing steam puffs are visible, but the art remains stylized and its final acceptance remains open.
- `2026-10-16T17-59-37-155Z-shared-review` passes all 42 packaged host/client checks against this exact export. It does not test the deferred early-game desync.
- This is still a local development build. Build 16 remains the latest public download; no release or upload was created.
- `2026-10-16T18-00-47-494Z-hermes-review` passes on the packaged console executable, covering magnet, hunt and Eclipse. `2026-10-16T18-01-07-253Z-roster-review` passes hero/enemy orb, harvestable and icon assertions; it does not establish distinct encounter behavior or visual acceptance.
- `2026-10-16T18-01-36-537Z-playfeel-review` passes the automated slam/recovery, turret, damage, music-state, drop-rate, grove openness and no-collision checks. `2026-10-16T18-02-26-262Z-controls-review` passes remapping/control-screen assertions. These automated reviews do not replace physical controller feel or auditioning music/Lithuanian speech during a full battle; those remain open.

## October 16 continued review

- Repeated `balance-review`: `2026-10-16T18-11-19-414Z-balance-review` passes all 15 idealized DPS fixtures. The 24-card solo projections are 4.7 minutes for weapons, 3.4 minutes for turrets, 16.1 minutes for status, 20.2 minutes for slam and 7.3 minutes for flowers. Strong 36-card projections range from 29.8 seconds (turrets) to 6.6 minutes (status). These assume a stationary invulnerable boss and full uptime; they are not actual win-rate or survival evidence. Real-fight balance stays open.
- Repeated seed 81173 / 125-enemy Eclipse run `2026-10-16T18-12-02-927Z-crowd-eclipse`: frame p50/p95 14.90/47.67 ms; physics p95 118.66 ms; steering p95 3.12 ms and movement p95 9.69 ms. This is consistent with earlier runs but does not resolve the high physics tail or establish a stable improvement. The stress capture was inspected; the packed crowd keeps attacks readable, while its low-angle camera and deliberately dense setup are not representative visual acceptance.
- Woods ground shading was adjusted to expose more continuous green between the instanced grass clumps. `2026-10-16T18-13-14-448Z-check` and `2026-10-16T18-13-29-091Z-biome-review` pass. Inspected all six 1440x810 gameplay views: Woods has more green ground, while the lunar and Candy Hell open ground remains sparse; Cloudwilds still crowds the view with trunks. This remains an iteration, not final visual approval. Matched 720p/1080p review and Eclipse measurements after this shader change are still needed.
- Asset research did not find a verified licensed, textured/rigged, game-ready photoreal Baron. The current source search is documented in `baron-model.md`; a new web search found a board-game bust and unverified Sketchfab candidates but no verified game-ready reusable asset. Keep the authored model labelled stylized and leave the photoreal replacement request open.
- The physical gamepad feel and full-battle music/Lithuanian voice audition have not been performed. Early-game co-op desync investigation remains deliberately last and untouched until the other active plan items are resolved.
- Follow-up art pass: `terrain.gdshader` gives Woods a wider, brighter moss pattern; `ground_cover.gd` increases lunar/space mineral fragments and spreads Candy Hell shards more broadly while retaining lava/path clearance. Cloudwild large props are less common and smaller; its close landmark grove uses mid/low growths beside one reduced tall feature. `2026-10-16T18-17-34-714Z-biome-review` and later `2026-10-16T18-21-47-377Z-biome-review` pass all six biome/streaming/mist checks. The refreshed captures show more green Woods and denser Candy Hell fragments. The Cloudwilds capture still has a broad foreground canopy, so the result is not accepted as finished art.
- Revalidated current source with `2026-10-16T18-21-33-655Z-check`, `2026-10-16T18-22-30-662Z-smoke` (118 assertions), and `2026-10-16T18-22-39-575Z-integration` (71 assertions). No code export was made from these uncommitted source changes.
- Comparable seed 81173 / 125-enemy Eclipse samples after the art pass: `2026-10-16T18-23-54-764Z-crowd-eclipse` measured frame p50/p95 15.85/55.56 ms and physics p95 134.75 ms; `2026-10-16T18-24-14-055Z-crowd-eclipse` measured 18.28/122.40 ms and 60.72 ms. Both have movement p95 around 10–11 ms and steering p95 around 3.3–3.5 ms. These high tails vary widely between runs; performance remains open and no improvement is claimed.
- The current source edits pass checks but have not been committed or exported. Build 16 remains public; do not publish Build 17 until the remaining plan items have evidence and acceptance.

## October 16 matched-resolution and human acceptance

- The previous local Build 17 executable from source commit `23c5c95bb94518f67da19792efd9a3104398b405` was captured with `--biome-review` at 1280×720 and 1920×1080 in `.build-staging/build17-before-biome-1792175772370/`. Both runs passed all biome, camera, mist, landmark, scattering and streaming assertions. Their six gameplay captures at each resolution are paired with the refreshed current-source screenshots in `.build-staging/source-biome-final-1792175558121/`.
- The refreshed 720p and 1080p sets were visually inspected. The user accepted the refreshed views (“its fine”). The subsequent pass adds woods moss, lunar/space mineral fragments and Candy Hell shards, and reduces Cloudwilds tree size/density around the tested landmark. Open travel/hazard lanes remain clear in the reviewed captures. The earlier captures and logs are retained for comparison.
- User also accepted the physical gamepad dash/deploy/menu feel and full-battle music/Lithuanian speech check (“its fine”). This is user-reported acceptance; no new automated review is represented as a physical-device or listening test.
- `check` (`2026-10-16T18-31-04-473Z-check`), `smoke` (118 checks, `2026-10-16T18-32-00-490Z-smoke`), `integration` (71 checks, `2026-10-16T18-32-09-649Z-integration`) and current-source six-biome reviews at 1280×720, 1440×810 and 1920×1080 pass. Repeated seed 81173 / 125-enemy Eclipse runs (`18-33-47-334Z` and `18-34-07-594Z`) show variable frame/physics p95 tails; performance remains open.
- The acceptance updates close the ground visuals/mist implementation and human feel/audio plan checks. Full-fight balance, enemy/art polish, performance, Baron asset/acceptance and the final early-game co-op desync investigation remain open. No export or publication has been made from the current uncommitted art changes.

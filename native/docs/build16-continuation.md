# Build 16 continuation — October 15, 2026

## Changes

Last run is now saved independently of the top-100 score table and can be reopened from the hero menu. Current reports show live death counts; recording a run also saves career death totals and best statistics immediately. Old profiles migrate without losing scores or settings.

Natural-obstacle avoidance reuses its collision query and caches unchanged steering for 0.1 seconds. A changed direction forces a fresh probe. Collision-based walking remains authoritative. Integration still exercises getting around a thick trunk while keeping ordinary terrain climbing.

The old forge/building reviews now exercise solid natural trunks and walkable grove clearings. This follows the explicit replacement of buildings; it does not remove collision or walkthrough checks. The pickup review now checks value conservation, actual reduction in object count, and the existing XP-value cap independently. Its obsolete four-object ceiling conflicted with that XP cap.

## Boss damage measurements

`balance-review` applies real catalogue effects and runs combat against the stationary final-boss body for 30 simulated seconds. Three budgets use 12/24/36 common offensive cards and weapon ranks 1/3/6. These exclude defensive choices, so they are defined offensive budgets, not proof of a typical level/build. Slam uses the landing damage path with cooldown plus half a second of airtime. Flowers use six established blooms without planting downtime. Party figures scale the measured DPS and existing boss HP; they are estimates, not network playtests.

Initial measurements (`2026-10-15T10-32-00-766Z-balance-review`):

| Archetype | 12 cards DPS | 24 cards DPS | 36 cards DPS | 24-card ideal solo duration |
| --- | ---: | ---: | ---: | ---: |
| Gun / shotgun / rail | 257 | 1,278 | 5,953 | 4.7 min |
| Three turrets | 257 | 1,771 | 12,084 | 3.4 min |
| Flame / poison / lightning | 153 | 373 | 912 | 16.1 min |
| Slam alone | 50 | 297 | 1,536 | 20.2 min |
| Established flower garden | 144 | 821 | 6,214 | 7.3 min |

This exposes large differences. Slam has three free weapon slots and status damage continues while dodging, whereas turret damage depends on deployment and range. Do not flatten these into equal numbers from this diagnostic. Five-minute survival fights, realistic upgrade availability and party outcomes remain open. The initial diagnostic reported headless audio playback references still alive at shutdown. The verbose log identified WAV/playback objects. The diagnostic now stops its audio players before exiting; `2026-10-15T10-53-21-918Z-balance-review` passes without those warnings. Original failure logs are retained.

## Performance evidence

Same machine, seed 81173, 1440×810, 125 corrupted enemies, 12-second scene with four-second warmup:

| Run | Frame median / p95 | Combat p95 | Physics p95 |
| --- | --- | --- | --- |
| Before cache, 10:23:03 | 55.91 / 155.20 ms | 19.08 ms | 24.59 ms |
| After cache, 10:27:09 | 17.82 / 74.38 ms | 16.32 ms | 25.96 ms |

The second run is smoother but still has serious tail stalls; physics did not improve. These single runs can include shader/cache and scheduling effects, so do not advertise the whole frame-time difference as caused by steering or claim the performance task is finished.

## Verification so far

All paths below are under `.build-staging/agent-workflow/`:

- `2026-10-15T10-37-07-021Z-check`: JS tests, import/parse passed.
- `2026-10-15T10-39-37-553Z-integration`: gameplay regressions, including natural obstacles, passed.
- `2026-10-15T10-26-38-925Z-feedback-review`: last run survives high-score trimming and disk reload, deaths persist, actual Last run / Back buttons reopen successfully. Report screenshots inspected; text and navigation are legible.
- `2026-10-15T10-40-48-789Z-playfeel-review`: six grove walkthrough/collision checks plus slam progression, turret controls, damage feedback, drop and music-state checks passed.

## Open art requests

The user's newer feedback supersedes visual acceptance of the prior colour pass: ground cover/low mist and a convincing Hades-inspired palette remain open. See ground-art-research.md. The requested photorealistic Baron Harkonnen replacement with steam is also open; no matching model has been imported. Initial searches surfaced printable sculpts rather than a verified textured/rigged game asset, including [this free printing model](https://cults3d.com/en/3d-model/art/baron-harkonnen-free-model). Availability for printing is not verification of game redistribution terms.

Physical gamepad feel and subjective full-battle audio audition still require human feedback. NodeTunnel remains deferred.

## Ground-cover first pass

Replaced 80 tiny dark blades per 64-metre terrain section with patchy, short curved-blade clumps, biome colours and occasional pink tips. Paths, portal approach, lava and steep slopes are excluded; ground cover has no collisions, no shadows and a 65-metre visibility limit. Corrected instance colours to linear colour space after the first preview looked washed out. The larger clumps use 900 candidate placements rather than 2,200, reducing terrain-sampling work at similar blade count.

Six-biome captures: `2026-10-15T10-50-04-834Z-biome-review` (first colour-corrected layout). Woods, marsh and the combined six-biome sheet inspected. This is progress, not full Hades-style visual acceptance. Low mist and further ground texture/composition work remain open.

Crowd measurements with the first cover layout: `2026-10-15T10-51-18-074Z-crowd-eclipse`, frame median/p95 32.37/104.11 ms. Larger clumps: `2026-10-15T10-52-35-369Z-crowd-eclipse`, 29.90/134.51 ms, combat p95 17.20 ms. Tail latency is still poor; these measurements do not establish a performance improvement. Keep the performance task open.

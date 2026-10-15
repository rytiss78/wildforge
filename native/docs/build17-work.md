# Build 17 work in progress

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

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

# Gameplay repair — local version 0.8.10

Run [Wildforge.exe](../../build/gameplay-0.8.10/Wildforge.exe) from the `build/gameplay-0.8.10` folder. Keep its `.pck` and companion executable together. Previous builds and player saves are preserved. This is a local build; the published release is unchanged.

## The six repairs

1. **Small hills:** the reproduced enemy stopped before a 0.35 m step and a 22° ramp. Ground movement now uses a collision-tested up/forward/down step, zeroes grounded vertical velocity and allows more slide iterations. Slope attachment probes nearby terrain without requiring the player to be three metres higher. Whole-body clearance checks avoid stepping through ceilings or walls. Existing wall/ceiling/ledge traversal remains covered.
2. **Bursty leveling:** enemy XP previously scaled directly with enemy HP, while merged orbs and immediate post-choice level-ups amplified bursts. Enemy rewards now use sublinear strength scaling and caps (normal 1.5–5, elite 6–12, boss 24–45 before XP bonuses). The shared/native threshold is `18 + 8*level + level²`: 27 XP at level 1 and 146 at level 8. Orbs stop merging above 40% of the next threshold, with a 12-XP minimum bound. Earned choices are separated by eight seconds of active gameplay; pause/reward time does not count and excess XP is retained. The HUD explains queued levels and saved XP.
3. **Card/buff compatibility:** cards name the equipped weapons they affect, show missing weapon requirements, explain conditional augments and flag capped effects. Hero/economy benefits work with any loadout. Potion icons show **Active** or **No benefit** and have detailed compatibility tooltips. Checks cover guns, saws, turrets, Flowers, hero perks and airborne turret conditions. Flowers correctly shows no benefit from Fast Hands or Lucky Shot; Big Bite still helps its bloom damage.
4. **Co-op specialties:** choosing a hero updates specialty name, description, numeric starting perks and starting-weapon explanation. The rendered review activates the actual Tank Potato button, checks its portrait survives menu reconstruction and verifies readiness resets.
5. **Damage readability:** 34-point normal and 42-point critical/slam text, bold font, dark outline/shadow and projection near the damaged actor. Crits stay gold with `!`; healing is green with `+`. Projectiles/melee retain their critical flag through `hit_enemy`, verified against an actual damage event. The existing policy remains: ordinary `hit` numbers are hidden; critical, melee, DOT, area and healing feedback remain enabled. This supersedes the old plan's inconsistent flashing/crit-only claims.
6. **Harvestables:** six distinct multi-part models, correct biome spawning, readable names/descriptions/effect values, reserved clear terrain and temporary-buff HUD timers. Duplicate pickups cannot apply twice. Timed effects refresh rather than stack, pause correctly, expire without mutating permanent stats and reset on a new run. Herb healing uses normal healing accounting. Each harvest yields coins affected by the existing pot-economy upgrade.

| Biome | Harvestable | Effect |
| --- | --- | --- |
| Clover Woods | Cloverheart | Restore 12 HP |
| Puffcap Marsh | Marsh Puffcap | +2 HP/second for 20 seconds |
| Moon Craters | Moon Quartz | +2 shield capacity for the run; restore 2 shield |
| Cloud City | Cloud Blossom | +1 air jump for 20 seconds |
| Candy Hell | Ember Pepper | +15% weapon damage for 20 seconds |
| Starfall Space | Starfall Pearl | +25% enemy gold for 20 seconds |

Eight harvestables per biome are generated in the tested seeds. Temporary bonuses persist across realm travel but reset on a new run. Harvest state remains local to each player's run, as before.

## Pacing measurement

The controlled seed-407 sample used Tank Potato, normal starting damage, invulnerability and automated pickup pursuit for 120 simulated seconds at 3× speed. It reached levels 2–6 at 36.40, 46.70, 54.72, 62.73 and 92.80 seconds, with 132 kills. The shortest interval was 8.02 seconds. This confirms queued choices do not chain immediately; it is not a full survival/difficulty balance certification for every hero or realm.

The original unmodified pacing bot died at 12.38 seconds, before leveling. That run cannot support a comparable before/after rate claim. Regression checks separately verify XP conservation, bounded merging and the choice delay.

## Verification

All commands use [the Godot workflow](godot-workflow.md), the bundled engine and isolated profiles. Dated reports are under `.build-staging/agent-workflow/`:

| Check | Result | Evidence directory |
| --- | --- | --- |
| Reproduction: step + gentle hill | Both failed before movement repair | `2026-10-12T17-32-37-342Z-surface-review` |
| Surface review | All 17 checks passed; slope/ledge screenshots inspected | `2026-10-12T17-33-49-161Z-surface-review` |
| JS tests, Godot import and parse | Passed | `2026-10-12T17-50-14-140Z-check` |
| Source smoke | 118 checks passed | `2026-10-12T17-50-34-551Z-smoke` |
| Gameplay integration | 57 checks passed | `2026-10-12T17-50-53-982Z-integration` |
| Controlled pacing | Completed 120 seconds; minimum level gap 8.02 seconds | `2026-10-12T17-45-24-365Z-pace-review` |
| Source rendered UI, 1440×810 | Passed; cards, buffs, co-op, all six harvestables and damage captures inspected | `2026-10-12T17-51-04-147Z-capture-ui` |
| Rendered combat | Passed; capture inspected | `2026-10-12T17-51-25-758Z-combat-review` |
| Windows export + exported smoke | Passed; 118 checks | `2026-10-12T17-51-57-542Z-build` |

The first new critical-feedback assertion failed in `2026-10-12T17-49-43-046Z-smoke`; the missing critical-cause forwarding was then corrected and the assertion passed. Its failing evidence is preserved.

The build in `build/gameplay-0.8.10` is a SHA-256-verified copy of the dated export. Exported UI reviews passed at 1280×720 and 1920×1080, including actual co-op hero selection, compatibility assertions, all harvest descriptions and the achievement audio check. Final cards, buffs, co-op, harvest and damage screenshots were visually inspected. Both rendered logs contain no errors or warnings. Evidence: `.build-staging/gameplay-0.8.10-exported-1280x720/` and `.build-staging/gameplay-0.8.10-exported-1920x1080/` (`result.json`, `ui.log`, and screenshots in `Roaming/Godot/app_userdata/Wildforge/`).

SHA-256:

- `Wildforge.exe`: `7f60faa389694e833e5f50267bd2e2c844a570761589b6091b880bc4ead3de71`
- `Wildforge.pck`: `a3004382ece402639f065960581580f72a78ce8469b56978215201a953b548ed`

## Remaining limitations

The integration process still reports 18 ObjectDB instances and 5 resources in use at shutdown; its gameplay assertions pass and there are no script errors. Source smoke, UI, combat and export logs contain no such diagnostics in the final runs. This cleanup warning is not silently treated as a clean log.

The earlier co-op realm-wraparound/teardown test failures and Eclipse handling expectation mismatch remain open; this batch does not claim the long network soak or Eclipse review passes. See the [original audit](repair-audit-2026-10-12.md) for pause history, enemy health-bar, difficulty-scaling, icon and performance limitations. The existing 728 staged changes were preserved; no mixed-index commit or publication was performed.

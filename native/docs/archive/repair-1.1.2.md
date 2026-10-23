# Build 16 — Hermes audit and repairs

Current status: this historical checkpoint is included in [Build 16](release-build16.md). The unreleased/hold statements below describe the earlier audit, not the current delivery.
October 15, 2026 · Wildforge 1.1.2 / Build 16 — unreleased development.

## Was the supplied executable old?

The user ran `.build-staging/agent-workflow/2026-10-15T08-25-32-473Z-build/Wildforge.exe`. Its report records `797f45afde11234e3c69e23009397e41e470d01a`, after feature commit `79d9642`. Inspecting its companion pack finds the new magnet methods. Hermes did write code. However, neither that fact nor the 118 smoke checks proves the eleven features worked.

The packaged project still identifies itself as **1.1.1 / Build 13**, while GitHub called it Build 15. Its report also has a nonempty working-diff fingerprint. The old launcher referenced a nonexistent folder. The plan described several nonexistent functions and marked unexercised behavior complete.

The exact release executable's UI run exited successfully, while the same source UI path in the bundled editor reported invalid `Node3D.cast_shadow` assignments during sentry creation. The release log did not expose those errors. This explains why a successful export/smoke message was insufficient; Build 16 adds explicit feature assertions in the actual executable.

Baseline evidence: `.build-staging/hermes-audit/baseline-1792055890337/`, `.build-staging/hermes-audit/pack-inspection.log`, and `.build-staging/agent-workflow/2026-10-15T09-21-58-256Z-capture-ui/`. Original logs are retained.

## What changed

| Area | Finding and repair |
| --- | --- |
| Shared XP | Each peer spawned XP for the same kill; deduplicating client message IDs did not deduplicate the underlying reward. XP drops now exist once on the host, attract toward living party members and replicate visually. Collector XP bonuses apply once. Clients mirror level/XP and cannot award arbitrary credit. Gold stays personal. |
| Shared chests | Client-supplied reward pools and separate hide messages could race. Clients now request a real nearby chest; the host checks realm, state and funds, charges the opener once and distributes one pool. Repeated requests cannot charge twice. Reward menus retain their source and accept real card buttons. |
| Magnet | Invalid properties, a boolean timer, nonexistent damage calls, unreachable targeting, missing network state and an unconditional null-node access. Replaced these with three normal combat records and dedicated sentry rigs, health orbs and telegraphed attacks. Host owns damage/activation; magnet collection uses the ordinary pickup accounting. Realm cleanup and final arena are exercised. |
| HUD | Removed the remaining separate level box; level/XP labels sit above a full-width bottom-edge bar. Shield/armor values remain visible. Removed the map's square backdrop and empty rectangular margins. Shortened interaction prompts. |
| Weather | Removed the Eclipse early return that skipped sky/fog/boundary updates and prevented weather resuming in the same biome. Blood rain and thin ordinary rain are rendered and captured. |
| Boss music/voice | Ordinary bass/bell/air layers stop during boss music; boss motif is 3 dB louder. Eclipse takes precedence. Lithuanian voice uses four-second minimum spacing, 0.75 pitch and the louder -5 dB mix while retaining all ten recordings. |
| Boss health | Ordinary bosses retain the requested fourfold multiplier; the final arena override now also applies it: 360,000 solo HP, scaled for parties. The boss remains 42 m tall, very slow and uses four deadly attack patterns. |
| Hunt | The previous code still used 30–45 m plus a local spawn radius. Actual spawns are now checked at 80–120 m, protected from distance recycling, and indicated by violet screen arrows and map markers. |
| Buildings | Kept the requested removal of broken large halls. Smaller landmarks/scenery remain. Archived obsolete `native/scripts.zip`; it is excluded from export. |
| Co-op damage | Preserve confirmed critical/area/melee damage types across the network. Carrying a poison/fire weapon no longer adds that weapon's status to an unrelated gun hit. |
| Build integrity | Version/build metadata updated together. Dirty-source rejection covers data, art, configuration and tools as well as scripts, including staged/untracked/renamed files. Export verifies runtime version and HEAD stability; `build-info.json` records SHA-256 hashes. Packaging verifies that manifest instead of relabelling arbitrary binaries. |

## Validation

[Source evidence](evidence-build16.json) records exact runs and diagnostics. The repair-checkpoint source checks passed: JS/import/parse, 118 smoke checks, gameplay integration, new rendered feature review, real two-process shared-progression review, menu/button navigation and Red Moon combat review. Source screenshots were visually inspected for map/HUD layout, magnet silhouette, hunt arrows, blood rain and version label.

The six-minute co-op route completed **0 → 1 → 2 → 3 → 0** on both peers, including down/rescue, health, flowers, damage numbers, merchant, supply, hunt, guardian, final boss and permanent Eclipse. Later critical-hit and unrelated-poison fixes are covered by the focused two-process review. The first focused-test teardown leaked audio resources; explicit shutdown/drain repaired the harness, and its final logs are clean. Integration initially exposed a test fixture selecting new world sentries as its two reaction targets; isolated fixtures now retain the original wet-chain assertion.

The eleven-point rendered review exercises actual interaction, projectile hits, area damage, defense locking, attraction and realm reset. The shared review exercises duplicate chest requests, one payment, matching XP/pools, real reward-card buttons, remote sentry damage and activation. The final executable must repeat these reviews plus 720p/1080p menus before publication; exported evidence is retained under `.build-staging/agent-workflow/` and attached to the release.

Publication is on hold at the user’s request. A local candidate at `.build-staging/agent-workflow/2026-10-15T09-51-35-157Z-build/Wildforge.exe` was exported from clean commit `ddee6e7` and passed exported smoke. It has not received the final exported feature/UI reviews and does not include later development. No Build 16 release or delivery folder exists yet. The public download remains Build 15.

## Folder cleanup

The earlier cleanup preserved 5,189,399,996 bytes under `C:\Users\rytis\Wildforge-Archive\before-build13`. This pass moved and hash-verified another 2,956,839,696 bytes of older test/build history under `C:\Users\rytis\Wildforge-Archive\before-build16\agent-workflow`, plus the obsolete source ZIP. Manifests are in `.build-staging/hermes-audit/history-relocation.json`, `remaining-relocation.json` and `archive.json`. A directory move encountered hidden/read-only test-Git files; the remaining files were then moved individually with hash verification. Empty historical directories are retained. Current builds, audit failures, saves, art and tools remain available.

## Limits still open

The requested fourfold final-boss HP means five minutes requires approximately 1,200 applied solo DPS; no representative-build balance claim is made. Broad art/biome polish, Internet latency and dense-scene performance need further work. Controller feel and full-combat audio audition remain human checks. Eclipse music is still a PARANOIA-derived arrangement; this release does not claim it is original. These remain explicit in [PLAN.md](../../../PLAN.md).

## Further development before publication

The user requested more work before Build 16, then replaced the earlier building direction with colourful glowing nature and reported enemies getting stuck climbing props. This continuation changes the source beyond the local candidate listed above. Its evidence is recorded separately in [the natural-world continuation](natural-world-build16.md).

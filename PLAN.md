# Wildforge — Active plan

Updated October 13, 2026. Source integration status: **Batches 1–3 merged as source candidates; Build 13 remains untested and unpublished.** **These changes have not passed the required Godot validation or a new Windows export.** Published: **1.1.0 · Build 12** ([download](https://github.com/rytiss78/wildforge/releases/tag/build-12)). Local development: **1.1.1 · Build 13** (not yet published).

Work directly, one agent. Do easy, useful fixes first; group validation and exports. Preserve incoming edits, saves, artwork, logs and old builds. Follow [AGENTS.md](AGENTS.md) and the [Godot workflow](native/docs/godot-workflow.md).

## In progress

1. **Final boss and build balance.** Fixed body-edge hits for slam, horn, flowers and aura; real attack regressions pass. Continue checking damage against the 42 m boss before tuning health. Verify close-range, area, status and turret builds, then measure weak/typical/strong late-game loadouts and solo/party duration. Aim for roughly five minutes for a typical build; strong builds should earn faster kills. The current 90,000 HP / 300 DPS calculation is only a reference. Keep slow movement, deadly readable attacks and permanent Eclipse after death.
2. **Enemy encounter variety.** Six new original creepy species and size/HP/speed variation are implemented. Finish creepypasta reference research, distinct biome behavior and encounter spacing; check that fast/slow enemies create different threats instead of one clump.
3. **Progression and rewards.** Validate long-run hero/weapon/item combinations, including slam chains, against actual combat. Initial tuning and drop fixes are in [balance notes](native/docs/balance-1.1.0.md); equal win rates are not established.
4. **shared exp and level in co-op** — DONE (Oct 13). Single host-authoritative system: host applies XP to shared pool and triggers `level_up()`; member sends credit with unique `pickup_id="xp_"+seq` (deduped via `credit_ids` set), never advances own level. Gold is per-player (local only, no broadcast). Chest open shared via `open_shared_offer()` on host; hide broadcast removes chest from all maps. Level/XP/xp_target mirrored on member via pose key list + `apply_world` mirror. `credit_ids` cleared on leave() and run_started() to prevent cross-run collision. Check/smoke: 118 checks pass.

## Source changes merged — validation still required

These items have candidate implementations in merged Batches 1–2, but are **not yet complete**. Verify the real entry points, co-op behavior, rendered UI, Godot errors, and executable before marking them done. The merge also includes candidate single-player XP and co-op reward/progression repairs; the previously recorded 118 smoke checks predate this integration.

- **specific to hero walking sounds** Supra Should have car sound.
- **boss indicator ons screen**
- **exp bar at the botom of the screen** Minimal hades style EXP bar at th botom off the screem, touching bottom edge, across all screen lenth.
- **damege numbers dont work in coop** for all players damage numbers in coop stops working, displays drong data.
- **blood rain in eclipse** Stil does not work, at eclipse.
- **fallen playeres heroes corpse should fall** now is enemie dies in the sky it will be stuck.
- **hero revice in coop progres indicator**
- **beem to dead players corpse in coop** its hard to find a body now.
- **minimap rework** bigger, no borders, Hades art style. player at the center, minimap spins.

## Batch 3 source candidates — unverified

- **Boss music:** Original synthesized minor-key motif layered with the existing drums; assess audio quality, mix, loops and Eclipse muting.
- **Portal redesign:** Larger arch, trim, decorative nodes, vortex and beacon; review at multiple resolutions.
- **Co-op lag:** Snapshot and pose cadence reduced from approximately 13.3 Hz to 10 Hz; measure lag and monitor realm-transition stalls.
- **Lava rivers:** Three glowing Candy Hell channels with periodic grounded damage; check geometry, collision, co-op authority and frame time.
- **Biome weather:** More visible and varied rain, motes and sparks; stylistic review remains.
- **Tank builds:** Shield-based overheal and a one-hit protection guard; balance and network testing outstanding.
- **Menus:** Removed a repeated hero-selection footer; broader cleanup not done.

**Validation:** The patch applied cleanly to the merged script baseline; no Godot runtime, multiplayer simulation or Windows export was available. These source changes are not evidence that the features work in game.

## Still open

1. Complete the Hades-inspired visual style conversion of older assets.
2. Finish wider menu/UI copy cleanup.
3. Benchmark and resolve remaining co-op lag, including realm-transition stalls.
4. Finish enemy encounter variety and real build/final-boss balancing.
5. Validate all Batches 1–3 in Godot with the project workflow and export a tested Windows build.

## Follow-up checks

- **Music:** audition ordinary phonk and the quieter Eclipse arrangement in combat, including loop transitions. Playback/peak checks pass. Keep Eclipse provenance accurate: it adapts the existing PARANOIA-derived arrangement, not an original composition.
- **Controller feel:** physical gamepad checks for directional dash, turret switching/deployment and menu navigation. Automated input-action checks already pass.
- **Intermittent 720p review:** retain the unexplained failure at `.build-staging/agent-workflow/2026-10-13T08-01-54-716Z-release-review`. Per-assertion reporting is added and current exported 720p/1080p checks pass; fix the cause if it reproduces, without weakening assertions.
- **Performance:** compare the same scene/build conditions for dense scenery, huge buildings and late Eclipse crowds before claiming improvements.
- **Older audit leftovers:** reconcile pause-menu history/death statistics, realm damage scaling and number-display policy with current behavior. Recheck semantic icon readability rather than treating unique hashes as proof. See the [repair audit](native/docs/repair-audit-2026-10-12.md) and [later gameplay repairs](native/docs/gameplay-repair-0.8.10.md).

## Deferred

**NodeTunnel online co-op:** keep LAN/direct-IP working. Later evaluate a bundled Host Online / Join Room Code flow, engine compatibility, free-service terms and real European latency/jitter/loss. No tunnel installation or hosting purchase now. The October 13 TCP probe timed out and yielded no latency measurement; it does not establish a service outage. [Candidate](https://nodetunnel.io/).

## Completed checkpoints

- [Build 12: Red Moon](native/docs/release-1.1.0.md): giant final boss/arena; Ninja, Smoker, Alcoholic and White Supra; class weapons and physical profiles; directional dash; progression-gated slam; stronger ranged enemies; compact HUD and version/build label; turret and damage feedback; dense scenery, six large buildings, celestial sky, effects and audio.
- [1.0.0 visual overhaul](native/docs/release-1.0.0.md): angular artwork, saturated effects, quiet ground, engraved UI and eight rotating bosses.
- [0.8.10 repairs](native/docs/gameplay-repair-0.8.10.md): enemy traversal, XP pace, card compatibility, co-op selection, damage accounting and harvestables.
- [Archived plan](native/docs/plan-history-through-build12.md): removed duplicate/completed entries and original historical claims. Release reports supersede stale completion marks.

## Completion rule

A task is done only when its real entry point works, required checks pass, visual changes are inspected and evidence is recorded. Run `check`, relevant runtime/feature checks, then `build` after a meaningful group of changes. Inspect result JSON and logs. Run party-hosting checks sequentially. Record exact executable/evidence paths and remaining limits; keep published release and local development status distinct.
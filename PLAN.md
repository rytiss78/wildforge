# Wildforge — active plan

October 16, 2026 · **1.1.3 / Build 17 development checkpoint** · main branch.

Use [AGENTS.md](AGENTS.md) and the [Godot workflow](native/docs/godot-workflow.md). Work directly, one agent. A checked item requires exercised behavior and evidence; historical completion marks are not verification.

Build 17 is a local development checkpoint, not a public release. Keep Build 16 as the public download until every active plan item is verified. [Current changes and evidence](native/docs/build17-work.md), [draft release notes](native/docs/release-build17.md). Real-fight balance and the final early co-op desync investigation remain open. Comparable performance measurements are complete but show a high physics tail; see the work log. The accepted Baron is a stylized fallback, not photorealistic.

## Hermes audit and eleven requested improvements

Source validation is recorded in [the repair report](native/docs/repair-1.1.2.md). Build 16 packages the repaired co-op, natural scenery and current continuation. [Release details](native/docs/release-build16.md). The older `09-51-35` candidate is superseded; it lacks these changes. **This checkpoint does not finish the remaining plan or the new art requests.**

- [x] Shared co-op XP/levels: one host-owned set of drops, collectible near any living player; mirrored progress, independent choices, duplicate client credits ignored.
- [x] Shared chests: host validates the request, charges the opener once, distributes choices and hides the chest for everyone. Both real processes resume after choosing.
- [x] 1. Remove square minimap border/background; preserve the centered, rotating map and markers.
- [x] 2. Show shield and armor values below HP, including zero values.
- [x] 3. Eclipse blood rain replaces ordinary weather; sky/fog still update, weather resumes afterward.
- [x] 4. Thin ordinary rain streaks.
- [x] 5. Boss motif and boss drums replace ordinary music layers; louder motif, Eclipse priority retained.
- [x] 6. Full-width bottom-edge XP meter with level and XP values; remove the separate level panel.
- [x] 7. Fourfold boss health, including the final boss override (360,000 solo HP). This is the requested multiplier, not proof of five-minute balance.
- [x] 8. Lithuanian boss speech: four-second minimum spacing, slower pitch and louder mix; retain all ten recordings.
- [x] 9. Retire broken large decorative halls; keep smaller scenery and landmarks.
- [x] 10. Hunt targets actually spawn 80–120 m away, survive distance cleanup and have screen arrows/minimap marks.
- [x] 11. Magnet with three combat-targetable sentries, health orbs, readable ranged attacks, host-approved activation and 120 m loot attraction. Clears between realms; absent safely in final arena.
- [x] Correct co-op critical damage types and prevent unrelated equipped weapons adding poison/fire to a gun hit.
- [x] Consistent version/build labels, launcher path and committed-build integrity checks; remove obsolete source ZIP from the export.

## Current continuation — natural scenery and encounters

The latest direction replaces the older request for massive buildings: **no decorative houses, castles, door/window facades or boxy platforms**. Use living, colourful nature with strong silhouettes and isolated glow; keep the ground subdued.

- [x] Validated six natural biome sets: emerald fairy trees and pink flowers, luminous mushrooms, pointed moon crystals, flowering willows, ember roots and astral coral. Tall, medium and low growths replace old scattered architectural meshes; large groves replace building landmarks.
- [x] Enemies go around natural props while retaining terrain climbing; real collision movement and wall/ceiling/ledge/slope reviews pass.
- [x] Verified distinct ranged firing distances, retreat and committed charges that can be dodged.
- [x] Inspected the single boss marker and updated colour pass in rendered gameplay.
- [x] Clean-source Build 16 candidate exported and checked at 720p/1080p, with exported two-process co-op tests. Delivery: `build/repair-1.1.2-build16/Wildforge.exe`; release manifest identifies the final source commit.

Evidence and limits: [natural-world continuation](native/docs/natural-world-build16.md). Now included in the Build 16 checkpoint.

## Remaining work — do not mark complete from this checkpoint

[Latest continuation evidence](native/docs/build16-continuation.md): last-run history fixed, crowd steering optimized, and controlled DPS measurements added. Full-fight balance and visual acceptance remain open.

1. **Real build balance:** measure weak/typical/strong weapon, turret, status, slam and flower builds against the final boss in solo and parties. The latest HP increase changes the DPS required for a five-minute fight. Automated contact/attack checks do not establish enjoyable duration or equal win rates.
2. [x] **Enemy and art polish:** reviewed original horror references, distinct silhouettes, legacy-asset replacement and all six biome encounter patterns. Added per-biome movement/telegraph regressions. Full-run pacing remains part of the open real-fight balance item. Evidence: [enemy and encounter review](native/docs/enemy-encounter-review.md).
3. [x] **Performance measurement:** comparable normal and late-Eclipse 125-enemy runs at the same seed/camera are recorded below. Frame and physics p95 tails remain high; this closes the measurement request, not a performance improvement claim. LAN correctness and a lower snapshot rate do not prove lower Internet latency or faster frame times.
4. [x] **Human feel/audio checks:** user accepted physical gamepad dash/deploy/menu feel and music/Lithuanian speech during a full battle on October 16. See [Build 17 work log](native/docs/build17-work.md). Preserve the accurate PARANOIA-derived Eclipse provenance.
- [x] **Broader UI/stat history:** cleaned up enemy-kill summary copy and empty state; reran persisted last-run/death, trimming, damage-source and stat-total checks. Reviewed the 1440×810 last-run, stat, recap and mobility-icon captures. Evidence: `2026-10-16T17-41-02-559Z-progression-review` and `2026-10-16T17-41-15-807Z-feedback-review` in [the work log](native/docs/build17-work.md).

## New request — Baron final boss

- [x] Replace the final boss with the bare stylized Baron fallback accepted by the user October 16. Asset searches and licensing limits are in [the asset report](native/docs/baron-model.md). No free photoreal Baron asset with verified reuse terms was found; do not label the accepted model photorealistic.
- [x] Make him immense: the ordinary camera looks upward to see his full silhouette. Retain very slow movement and deadly, clearly telegraphed ranged attacks. Source and exported Red Moon reviews pass.
- [x] Add visible steam venting from his body, with four emitting vents / 64 GPU particles total and readable attack warnings.
- [x] Verify silhouette, targeting, collision, co-op reconstruction and steam budget in the clean-commit staging export: `2026-10-16T18-56-41-946Z-build` and `2026-10-16T18-57-16-264Z-release-review`. User accepted the exported bare model on October 16.

## New request — finished ground and stronger colour

- [x] Ground-cover/art acceptance: clustered short grass, moss, biome-coloured low growth, wind where appropriate and mineral/ember fragments; no collisions; paths, lava, portal approaches and steep slopes excluded. User accepted the matched 720p/1080p six-biome pass. See [ground-art research](native/docs/ground-art-research.md).
- [x] Trial sparse low mist in marsh/cloud pockets only; compare against grass-only. Do not wash out saturated foliage, hide feet/loot or cover hazard circles. Use ember flecks and mineral/crystal fragments where grass would not fit.
- [x] Use chunked instancing and simple wind animation, distance limits and no foliage collision. Measure the same camera/seed before and after in normal combat and late Eclipse; the noisy p95/physics tails remain tracked under Performance and no improvement is claimed.
- [x] Review every biome from the gameplay camera at 720p/1080p: rich coloured midtones, separated shadows, hot highlights and vivid attacks. Record before/after frames. User accepted the refreshed views on October 16; see [matched-resolution evidence](native/docs/ground-art-research.md#october-16-matched-resolution-review).

Research and implementation choices: [ground-art research](native/docs/ground-art-research.md).

## Final task — early-game co-op desync (do last)

**User priority, October 15: tackle this only when it is the sole remaining active plan item.** Record it now; finish the other active work before starting this investigation. The separately deferred NodeTunnel work is not a prerequisite.

- [x] Reproduced a pause-state input defect on two source host/client processes. When the host paused, the client's authoritative pause flag became true while its local mode remained `playing`; dash and chest-interaction input still executed even though physics was frozen. The failing pre-fix run is `2026-10-18T10-08-53-417Z-shared-review`.
- [x] Added a client gameplay-input gate for the remotely paused state. Three repeated pause/resume cycles pass without dash or chest requests during the pause. Normal host/client review: `2026-10-18T10-10-55-862Z-shared-review`.
- [x] Repeated the same scenarios with a 20 Hz client and 150 ms simulated one-way packet delay. Shared XP/level, offers, chest payment/hiding, pause/resume, enemy warnings and Baron reconstruction all pass: `2026-10-18T10-15-03-377Z-shared-review-stress`.
- [ ] Verify sustained early-game play in two actual exported processes and inspect rendered behavior. The exact original major-desync symptom is not described in the retained evidence, and these source-process regressions do not establish that every reported desync is fixed. Keep this investigation open until exported validation and a symptom-matched reproduction are recorded.

## Deferred

**NodeTunnel online co-op:** no tunnel installation or service purchase now. Keep direct-IP/LAN working. Later assess bundled room codes, free-service terms and measured European latency/jitter/loss. The October 13 timeout did not establish a service outage.

## History

- [Build 16 audit and validation](native/docs/repair-1.1.2.md)
- [Historical plan through Build 15](native/docs/plan-history-through-build15.md) — includes superseded claims, not current acceptance evidence.
- [Build 12 / Red Moon](native/docs/release-1.1.0.md)
- [Build 1.0 visual rollout](native/docs/visual-rollout-1.0.0.md)
- [Older repair audit](native/docs/repair-audit-2026-10-12.md)

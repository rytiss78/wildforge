# Wildforge — active plan

October 15, 2026 · **1.1.2 / Build 16 checkpoint** · main branch.

Use [AGENTS.md](AGENTS.md) and the [Godot workflow](native/docs/godot-workflow.md). Work directly, one agent. A checked item requires exercised behavior and evidence; historical completion marks are not verification.

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
2. **Enemy and art polish:** finish distinct biome encounter behavior/spacing, original creepypasta-inspired references and remaining older visual assets. Preserve readable silhouettes, quiet ground and vivid attacks.
3. **Performance:** measure dense scenery and late Eclipse crowds under comparable conditions. LAN correctness and a lower snapshot rate do not prove lower Internet latency or faster frame times.
4. **Human feel/audio checks:** physical gamepad dash/deploy/menu feel; audition music transitions and Lithuanian speech during a full battle. Preserve the accurate PARANOIA-derived Eclipse provenance.
5. **Broader UI/stat history:** finish copy cleanup and reconcile last-run/death statistics. Keep semantic skill icons under visual review; different hashes are not proof of useful artwork.

## New request — Baron final boss

- [ ] Replace the final boss with Baron Vladimir Harkonnen from the Dune films (the enormous bald floating character). Seek a photorealistic model if a suitable, licensed game-ready asset is available; record its source and reuse terms. Do not label a stylized fallback photorealistic.
- [ ] Make him immense: the ordinary camera must require looking upward to see his whole silhouette. Retain very slow movement and deadly, clearly telegraphed ranged attacks.
- [ ] Add visible steam venting from his body, with bounded particle cost and readable attack warnings.
- [ ] Verify silhouette, targeting, collision, co-op appearance and steam performance in the exported game before marking complete.

## New request — finished ground and stronger colour

- [ ] Ground still looks unfinished and the current colour pass does not meet the user's Hades reference. Reopen visual acceptance: screenshots passing technical checks are not art approval.
- [x] First ground-cover implementation: clustered short grass with biome colours, wind and occasional pink tips; no collisions; paths, lava, portal approaches and steep slopes excluded. Further ferns/moss, composition and colour acceptance remain open. See continuation evidence.
- [ ] Trial sparse low mist in marsh/cloud pockets only; compare against grass-only. Do not wash out saturated foliage, hide feet/loot or cover hazard circles. Use ember flecks and mineral/crystal fragments where grass would not fit.
- [ ] Use chunked instancing and simple wind animation, distance limits and no foliage collision. Measure the same camera/seed before and after in normal combat and late Eclipse.
- [ ] Review every biome from the gameplay camera at 720p/1080p: rich coloured midtones, separated shadows, hot highlights and vivid attacks. Record before/after frames; leave open if it still looks dull.

Research and implementation choices: [ground-art research](native/docs/ground-art-research.md).

## Deferred

**NodeTunnel online co-op:** no tunnel installation or service purchase now. Keep direct-IP/LAN working. Later assess bundled room codes, free-service terms and measured European latency/jitter/loss. The October 13 timeout did not establish a service outage.

## History

- [Build 16 audit and validation](native/docs/repair-1.1.2.md)
- [Historical plan through Build 15](native/docs/plan-history-through-build15.md) — includes superseded claims, not current acceptance evidence.
- [Build 12 / Red Moon](native/docs/release-1.1.0.md)
- [Build 1.0 visual rollout](native/docs/visual-rollout-1.0.0.md)
- [Older repair audit](native/docs/repair-audit-2026-10-12.md)

# Wildforge 0.8.0 — local update

Built on 2026-10-05. Play `G:\game\build\Wildforge.exe`; the portable archive is `G:\game\dist\Wildforge-0.8.0-Windows.zip`. No push, upload or release was performed. Existing career saves and user feedback were preserved. Diagnostics used separate APPDATA directories.

## Changes

- Replaced the accumulated enemy steering probes with pursuit, capped local separation, collision sliding and a short consistent wall-follow direction. Distant irrelevant enemies sleep or despawn; bosses and active objectives stay protected.
- Ordinary spawning runs at half its previous cadence. Deliberate waves retain their own cues and budgets. Ordinary ranged enemies have 42% of their previous species health and an eight-second attack cooldown. Playable heroes and bosses retain separate values.
- Reachable bosses take targeting priority. Range, scenery visibility and melee contact still matter. Bosses alternate pursuit/repositioning with recovery windows.
- Grounded XP and gold merge separately in spatial buckets, preserving exact value and original coin-healing units. Different elevations and blocked scenery do not merge.
- The map uses shared 750 m half-extents: a 1,500 × 1,500 m working target. Streamed terraces, ramps and sparse 24 m biome crossing corridors add routes. Chunk coverage includes separated party members. The minimap rotates terrain, boxes, pings and party markers with the camera.
- Added a wandering merchant, per-realm banish charge, occasional useful offer bias, explicit before/after card values and family tags. Three weapon slots and single positive bonus cards remain.
- Fire/poison, frost/slam and lightning/bubble reactions have bounded effects and damage without recursive triggering.
- Direct co-op adds host-authoritative downing, held rescue and contextual pings. Optional supply beacons provide a defended reward choice once per living participant.
- Added panicking mimics with a bonus coin trail, banana slips, headbanging strong Florist blooms, moon cheese rocks, potion burps and charging mushroom eyebrows.
- Illustrated surfaces, biome palettes, landmark geometry, vegetation motion, pooled impacts/blasts, contact shadows, hero motion, health/armour orb materials and compact opaque UI received a pass. Weapons gain visible parts at ranks 3, 6 and 9, including turrets.
- Added 63 original synthesized context quips across the existing 21 hero voices, with global/context cooldowns and hero-local sound. Sources and voice credits remain editable under `native/assets/voices` and `scripts/generate-hero-voices.py`.
- Run recaps distinguish credited local and party damage, XP, coins, weapons, exploration and interactions. Eight stable discovery/interaction achievement IDs increase the catalog to 108, preserving previous IDs/progress.
- Removed Community Lab menus, routing and packaged community data. Historical feedback/provenance remain in source.

## Validation

The final packaged integration pass passed all 41 checks: boss/melee reach, wall pursuit and contact, freeze/pause, currency conservation, elevation separation, full weapon slots, merchant claims, banish/exhausted pools, reactions, optional-event success/failure, ping throttling, minimap rotation, save round trip, recap, achievements, controller focus/bindings, all six biome captures and split-party chunk coverage. Sampled base-route slope was 1.1205, below the 52° movement limit (1.2799).

The packaged local host/rendered guest pass confirmed movement, snapshots, remote hits, downing, three-second rescue, pings, one-time merchant purchases, supply rewards, party pause, realm travel and guest disconnect. The final runs reported no script/runtime errors or ObjectDB leaks. Existing baked GLB bark-texture UID warnings still resolve through their valid text paths; these also occurred in the previous build.

Evidence is in `validation-0.8.0/`: integration and co-op JSON, six scene captures, card capture, and isolated old/new crowded benchmark results. Controller validation uses bindings and focus simulation, not a physical Xbox controller. Route samples and a short crowded benchmark do not establish full-career balance or four-player hardware performance. See the balance review for concrete changes and remaining pacing risks.

Both crowded samples ran alone for 36 seconds across six regions on the same Ryzen 7 5800X/Radeon RX 9060 XT. The diagnostic deliberately starts crowds near 100 enemies, so it does not measure natural first-minute spawn pacing. Results are a single sample per version; scene seeds and spawn randomness can affect timings.

| Metric | Previous 0.7.9 | Current 0.8.0 |
| --- | ---: | ---: |
| Median frame time | 3.920 ms | 3.380 ms |
| 95th percentile frame time | 30.629 ms | 22.836 ms |
| Maximum scene nodes | 7,112 | 7,047 |
| Last-frame draw calls | 1,416 | 1,457 |
| Minimum sampled enemy separation / combined radii | 0.344 | 0.845 |
| Active chunks at end | 30 | 28 |
| Regions completed | 6 | 6 |

Median frame time fell about 14% and the 95th percentile about 25%. Draw calls rose about 3% with the visual additions. Crowd separation improved substantially; the minimum still captures some transient overlap and should not be interpreted as perfect collision spacing. Ground height stayed within 0.001 m of the surface in the new sample.

## Scope/provenance

Implemented the selected plan's V1,V3,V4,V5,V6,V8,V9,V11,V13,V16,V17,V18; G2,G4,G5,G6,G7,G8,G10,G11,G14,G15,G17,G19,G20; F3,F4,F8,F11,F12,F18; I3,I13 and its movement/spawn/map/loot instructions. Visual work extends the existing illustrated assets and authors procedural 3D geometry and shaders; no new bitmap generation or external art download was used. Audio extends the existing original Kokoro synthesis pipeline. Included model/voice/engine licenses remain in the build.

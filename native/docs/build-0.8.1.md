# Wildforge 0.8.1 — smaller map, more treasure and content

Local build dated 2026-10-05. Play `G:\game\build\Wildforge.exe`, or unpack `G:\game\dist\Wildforge-0.8.1-Windows.zip`. Nothing was pushed, uploaded or published. Real career saves, prior achievement IDs and historical feedback remain preserved; validation used isolated APPDATA.

## Requested changes

| Request | Implemented |
| --- | --- |
| Map was too big | 800 × 800 m, as selected by the user; half-extents 400 m, spawn bound 370 m and danger edge 375 m. Minimap, containment and co-op use shared bounds. |
| More chests spread across the map | 24 paid chests per realm, four in each biome, distributed across four radial bands with deterministic jitter. No clustering at the start. Existing price progression remains. Boss reward chests remain separate. |
| About 400 more items/skills/weapons | Exactly 400 additions: 180 items, 180 skills and 40 behavioral weapon variants. The complete catalog now has 694 item/skill entries and 65 weapons, totaling 759. |
| Different, distinct icons and textures | 759 individual editable SVG card/weapon icons, rendered as Godot textures, plus 65 patterned weapon textures. Each new conditional bonus combines an object silhouette with an activation glyph. Weapon badges add visible payload/trajectory/area symbols. New held weapons have textured attachments that preserve the base weapon silhouette and sockets. |
| Five card selections | Every level, chest and supply reward offer has five choices. Keyboard 1–5, mouse and controller focus work with the larger opaque panel. Pick one reward. Three weapon slots remain; selecting a new weapon while full opens an explicit replacement screen. Full-slot offers include an owned upgrade option. |

## Content design

The 360 new single-positive-bonus cards combine 18 activation conditions with 20 bonuses. Conditions include airborne/grounded, moving/stationary, low/full health, shield/no shield, short windows after dash/slam/kill/health damage, boss proximity, empty/crowded space, flower/turret proximity and carrying 50 coins. Bonuses affect weapon damage/rate/reach, movement, regeneration, armour, dodge, criticals, projectile properties, knockback, lifesteal, boss damage, XP/coins, pickup and turret damage/rate/reach. Owning the card is permanent for the run; its benefit turns on only while the displayed condition holds. Dodge, critical and lifesteal ceilings remain bounded.

The 40 new weapons extend 20 existing attack archetypes with actual firing differences: extra projectiles/piercing/bounces, returning shots, fire/poison/ice/bubble payloads, wider melee/cone attacks, larger or longer gravity wells, stronger stun, additional meteors and different bomb fuses/areas. Examples include Venom Candle, Frost Cleaver, Marble Rain, Needle Driver and Toaster Sentry. They are behavioral variants, rather than 40 entirely new attack engines. Mechanics are described before selection.

See [the 400-entry content list](content-expansion-0.8.1.csv) and [artwork manifest](../assets/illustrated/content/manifest.json). Art is original code-authored vector geometry with stable recipes, not downloaded art or AI-generated raster images. The editable art exporter is `scripts/create-content-art.mjs`; catalog recipes are `scripts/data/expansion.js`. The native packaging script regenerates both.

## Balance implications

The world has about 28% of 0.8.0's area while paid chest count quadruples. Exploration and treasure discovery should be much faster. Coin income and the existing chest price progression were not increased: more chests mean more opportunities, not automatic affordability. Five offers increase build control. Conditional bonuses trade constant uptime for larger situational benefits without negative effects, and rarity scales their positive amount. Extra shot variants share the existing projectile limits. Three weapon slots, boss timing and fragile ordinary ranged enemies remain.

Long career runs are still needed to tune merchant/chest affordability, conditional stacking and late-realm clearing speed. No claim is made that adding 400 entries establishes full-run balance.

## Validation

The final packaged pass passed all 50 cases. New coverage checks catalog totals, all 759 rendered icons for distinct pixel data, five choices across offer types, 24-chest spacing/four-per-biome distribution, conditional health/economy/expiry behavior, and all 40 variant firing branches with their actual held models. Existing coverage checks movement/contact, freeze/pause, targeting, loot conservation, merchant/banish/full slots, reactions, events, pings, saves, recap, achievements, all six biome captures and separated-party chunks. Route samples stayed within the base movement slope limit.

The final packaged host/rendered guest test passed rescue/downing, contextual pings, merchant/supply rewards, party pause, realm travel, movement and remote hits. The guest equipped Venom Candle and a conditional healthy-damage card. Only a local host/guest pair and simulated controller focus/bindings were checked, not physical Xbox hardware or a four-machine party. No script/runtime errors or object leaks appeared in the final packaged logs. Existing bark texture UID warnings still use their valid text-path fallback.

Evidence and rendered artwork/card/biome captures are retained in `validation-0.8.1/`. Older local archives and temporary diagnostic saves are removed after verifying the current build. Previous 0.8.0 notes describe historical settings; this document is the current build's reference.

One isolated 36-second crowded sample completed all six biomes on Ryzen 7 5800X/Radeon RX 9060 XT: median frame time 4.021 ms, 95th percentile 25.394 ms, maximum 7,242 nodes, final 1,350 draw calls and minimum sampled crowd spacing 0.776× combined radii. Ground error remained below 0.001 m. The earlier 0.8.0 sample was 3.380/22.836 ms, and 0.7.9 was 3.920/30.629 ms. Current timings are slower than the 0.8.0 sample with more treasure/visuals, while the 95th percentile remains below 0.7.9. Different scene/spawn randomness and single samples limit the comparison; these are not repeatable FPS guarantees.

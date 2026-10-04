# Wildforge 0.7 — illustrated 3D, blood cores and hidden horizons

Status: implemented in the main run for build 0.7.0, 4 October 2026. The approved prototype now supplies the modeled hero, creature, weapon and scenery system. See [build-0.7.md](build-0.7.md) for shipped behavior, validation and remaining release checks. This plan supersedes the older next-build plan where they disagree, especially starting double jump and painted cutout characters. Stable Steam release remains dependent on extended playtesting and real Steamworks configuration.

## Agreed direction

Keep native Godot, bright illustrated icon art, funny heroes, compact opaque PC UI, three shared weapon slots, positive single-benefit loot, paid three-choice chests, timed bosses and co-op. Replace active close-up painted cutouts with deliberately modeled, textured and animated 3D assets. Preserve existing careers and all achievement IDs.

User decisions: prototype a NEW creature designed around a glass blood core; show damage through draining blood plus cracks/glow changes; flying enemies remain reachable by suitable ranged weapons. Hero blood cores depend on whether the enemy prototype works in actual gameplay.

## 1. Prove the new art and health system first

Build one small playable test scene before converting the roster. Include a new enemy, Count Duck, a held gun matching its icon, a tree, a textured ground patch, bullets and an explosion. Show them at the normal gameplay camera and from multiple sides, with movement and damage.

Proposed creature: **Bottlebite**, a ridiculous four-legged creature with a hollow curved shell, oversized snapping mouth and a round glass core framed in its body. Its geometry should expose the core from several angles without making the whole monster transparent. Its expression and painted markings keep it funny. Create normal, large armored and flying interpretations to check the same visual language across roles.

- Author real silhouettes, meshes, UV layouts and appropriate skeletons. Existing PNGs become concept references and reusable painted texture details; they cannot supply unseen sides, depth, joints or topology automatically. Prepare missing side/back views and repaint seams rather than stretching a front illustration around a generic blob.
- Use restrained lighting, painted color/shadow, warm outlines and small shared texture atlases. Avoid glossy clay surfaces. Start with 256–512px materials and increase only where gameplay views justify it. Create simple distant meshes as part of the asset, not after performance fails.
- Core fill equals current HP divided by maximum HP. A full enemy has a full blood reservoir; damage drains it; death leaves it empty. Keep the liquid surface level while the creature tilts, with restrained slosh.
- Cracks and weaker glow reinforce missing health. Healing restores the visual state; cracks represent current damage, not permanently accumulated damage. Hit pulses are brief and do not conceal fill level.
- Tank variants use near-black blood with a light rim and distinct reinforced core frame. Darkness identifies toughness; remaining fill still identifies health. Test against dark terrain and for players who cannot distinguish red/green.
- Simplify glass and liquid at distance. Avoid many overlapping transparent surfaces. Compare a cheap illustrated glass shader against transparent glass; choose from measured readability and frame time.
- Keep the hero's existing health readout during this experiment. If enemy cores read well, prototype one hero with a front/side-visible core plus a compact matching HUD orb before converting other heroes. No automatic removal of useful health information.

**Review checkpoint:** capture full, half, critical and empty HP at near/normal/far combat distances, with several enemies and mixed status effects. Show the prototype before mass conversion. If fill is unreadable, revise core size/placement/materials first. A small targeted fallback indicator is a later design decision, not an assumed replacement for the requested system.

## 2. Scale, animation and combat readability

Set a consistent hero reference height, then vary enemy bodies and world structures visibly. Initial tuning bands: ordinary creatures roughly 1.5–2.5m tall, heavy creatures 3–5m, bosses 8–14m, trees 10–25m, major towers 25–60m. Width, wingspan and silhouette matter as much as height; adjust these bands using gameplay screenshots. Ordinary threats must remain visible above grass.

- Smaller creatures generally move faster; heavier ones move slower and telegraph stronger attacks. Species retain distinct behavior. Scale health, contact range, hurt boxes, navigation clearance and attack reach together; never enlarge only the picture.
- Give all 36 species distinct authored forms across six biomes. Prioritize a complete six-species biome after the prototype, then convert the remaining five. Preserve the exotic non-humanoid direction.
- Real flying creatures have visible altitude, banking, wing/body movement, appropriate aerial separation and a readable ground shadow. Auto targeting and projectiles account for height. Suitable ranged weapons can hit them from the ground. Melee/slam builds need viable encounters through mixed spawns and advertised landing/dive phases.
- Bosses become genuinely huge with named, visible attacks: windup, readable danger area, impact, recovery and phase change. Vary attacks by creature rather than recycling a single expanding circle. Keep threats visible through weather and ensure large bodies fit routes and arenas.
- Convert all 21 heroes to distinct 3D designs with matching menu previews. Preserve weapon sockets, comic third-arm growth, recoil and Florist planting. Reuse animation systems where anatomy permits, rather than forcing every hero into one humanoid shape.
- Audit idle, walking, turning, jumping, extra jumps, falling, landing, slam, hit bump, death, squash, weapon use and status effects. Match collisions to models; test crowds beside large structures and airborne enemies.

Completion: silhouettes still resemble approved art from gameplay distance; no invisible tiny enemies; crowds do not overlap or stack; all three equipped weapons are visible; flying attacks and huge boss effects are reachable/readable.

## 3. Hide the horizon through biome structure and distance controls

Keep the existing large map footprint first. Make discovery feel larger through layered routes, tall landmarks, elevation and blocked sightlines instead of increasing empty area.

| Biome | Occluders and explorable structures | Sky and local atmosphere |
| --- | --- | --- |
| Clover Woods | Tall branching trees, root arches, hollow trunks, woodland towers | Bright sky, layered treetops, drifting leaves |
| Puffcap Marsh | Giant mushrooms, reed walls, crooked boardwalk huts, bulbous arches | Heavy clouds, local rain and low mist |
| Moon Craters | Crater rims, rock spires, broken observatories, sheltered tunnels | Huge neighboring world, rings and distant stars |
| Cloud City | Tall towers, stacked bridges, climbable cloud platforms | Layered cloud oceans, light shafts and snow squalls |
| Candy Hell | Volcano ridges, obsidian arches, furnace ruins, cooled lava bridges | Painted fire bands and ember storms overhead |
| Starfall Space | Crystal cliffs, asteroid ruins, orbital fragments, giant arches | Massive planets, nebula layers and slow orbital movement |

- Use several variants per structure family with different height/width. Place meaningful paths, clearings and encounter spaces between them. Cloud platforms have real stable collision and reachable routes; treasure cannot require an unowned extra-jump card without an alternative path.
- Begin tuning full detail around 80–120m, simplified geometry around 140–220m, and distant silhouettes only where they help navigation. These are trial ranges, not fixed promises. Combine chunk streaming, mesh LOD, visibility ranges and static occluders. Tall decoration blocks sight but does not by itself guarantee lower rendering cost.
- Separate sky spectacle from nearby world draw distance. Massive sky planets need cheap distant rendering and must not force the whole ground map to render. Fog masks terrain transitions without hiding immediate threats.
- Use camera collision/repositioning and selective foreground treatment so tall scenery cannot permanently hide the hero. Keep solid opaque UI regardless of world effects.
- Local blizzards reduce distant visibility but preserve nearby enemies, danger telegraphs and routes. Bound weather particle counts. Blend skies/weather across biome boundaries without abrupt cuts or repeated announcer spam.
- Destiny 2 reference direction: dramatic scale contrast, layered skies and strong horizon composition. Translate this into original bright illustrated planets/fire/clouds, retaining our art style.

Completion: no view reveals the entire map; no obvious chunk popping during sprinting/jump chains; structures are navigable; six skies are distinct; benchmark each biome and the busiest boss scene at 1080p. Target stable 60 FPS on a declared target PC and record frame-time percentiles, memory and draw calls rather than claiming success from average FPS alone.

## 4. Replace the distant steam wall

Remove the giant far-visible border planes. Use sparse ground-hugging steam, subtle boiling distortion and small local eruptions near the outer danger band. Fade these by proximity so the border is barely noticeable from far away.

As the player approaches, increase local hiss, bubbling ground and a compact danger warning. Preserve the deadly boundary behavior for heroes, enemies and drops, with no loot generated by border kills. Keep solid containment and safe recovery so falling out of the world remains impossible. Subtle at distance must still mean understandable before entering lethal ground. Test corners, flying enemies, jump chains and co-op peers at different distances.

## 5. Textured projectiles, animated explosions and hurt voices

- Give each projectile family a recognizable painted body/trail: bullet streak, shell slug, rocket, seed, poison glob, ice shard, ghost bolt and electrical arc. Use modeled projectiles where shape matters and animated texture sheets where they suit sparks/smoke. This preserves true 3D objects without modeling every tiny particle.
- Explosions have a timed flash, expanding illustrated blast, shockwave, debris/embers and dissipating smoke. Separate fire, poison, frost and cosmic effects. Synchronize the damage moment, sound and controller vibration; effects never linger as invisible damage sources.
- Pool effects and audio; bound simultaneous flashes, lights and debris. Status effects remain attached to enemies and compatible with the core readout.
- Give each of the 21 heroes its own recognizable short hurt vocal, ideally with 2–3 variants: duck squawk, teapot yelp, pirate octopus cry, startled astronaut, indignant book, and so on. Produce natural expressive recordings with consistent levels and documented rights/provenance. Preserve the enemy-specific impact sound alongside the hero reaction.
- Apply vocal cooldown/priority so repeated damage and four players do not create continuous screaming. Play vocals only for actual damage, not blocked hits.

Completion: weapon effects match their icons/mechanics; explosions show impact timing; hero voices are distinct and expressive; heavy combat remains legible and audio does not clip.

## 6. Luck-gated potions and clearer pickups

Retain the four current timed potions: anti-poison, anti-fire, speed and XP. Add ten distinct timed examples:

| Potion | One temporary benefit |
| --- | --- |
| Stone Skin | Reduced incoming damage |
| Big Bite | Increased attack damage |
| Fast Hands | Increased attack speed |
| Lucky Shot | Increased critical chance |
| Long Reach | Increased attack range |
| Coin Rush | Increased coin value |
| Big Magnet | Increased pickup radius |
| High Jump | Increased jump height |
| Soft Landing | Reduced fall damage |
| Fresh Blood | Increased healing per second |

- Potion drops require at least one acquired item/card whose effect grants luck. Innate hero luck alone does not qualify under the literal requested rule. Check eligibility at elite death for each player's personal loot. Without a luck item, potion drop probability is exactly zero. With one, luck controls a bounded drop chance; tune that curve after playtesting.
- Every ground potion has a simple name tag, distinct bottle silhouette/color and matching icon. Tags fade at distance; prioritize the nearest interactable bottle to prevent label clutter. Show keyboard E or Xbox X near pickup.
- Preserve manual pickup, ground expiry and clear buff timers. Repeated same-type pickup refreshes duration unless its card explicitly says otherwise; timed effects do not mutate permanent stats. Party pause freezes timers.
- Make coins visibly larger than XP orbs. Give XP a controlled glow/halo and small pulse; avoid one dynamic light per orb. Differentiate by shape as well as color.

Completion: all 14 potions have unique documented effects; no potion drops without qualifying loot; eligibility works independently in co-op; name tags remain readable at 1080p; temporary bonuses expire correctly; pickups remain visible in grass, snow and bright terrain.

## 7. Jump rules, expanded guns/cards and full-slot rewards

- Baseline: one ground jump, zero extra air jumps. Only an explicitly described hero perk can grant a starting extra jump.
- Each Extra Hop card adds one air jump: first card gives double jump, second triple jump, then more within a stated tested cap. Show a whole-number gain and total jump count. Reconcile rarity with discrete bonuses; never advertise fractional jumps.
- Preserve jump-height, slam and fall-protection cards as separate single-benefit choices. Test landing once, air-jump reset, bounce/slam combinations and safe cloud-platform routes.
- Add at least eight genuinely different weapon mechanics beyond the existing 17: boomerang blade, bouncing disc, harpoon, gravity launcher, sonic horn, bubble cannon, meteor wand and rolling bomb launcher. Final names stay short. Each needs a matching detailed icon, real held model, upgrade progression, animation, sound and distinct combat behavior.
- Add at least 30 meaningful single-benefit card/item templates, prioritizing missing interactions for new weapons, aerial movement and different build families. More names with the same effect do not count toward this target. Keep explicit values and rarity comparisons, and no negative side effects.
- With fewer than three weapon slots filled, weapon rewards can include new weapons or equipped upgrades. With all slots filled, every weapon reward is an upgrade to an equipped weapon; no new weapon or replacement prompt appears. Ordinary item/perk rewards remain available.
- Apply that inventory filter centrally to chests, level-ups, boss rewards, rerolls and fallback generation. When every equipped weapon is capped, offer another useful eligible item/perk rather than an ineffective upgrade. Do not lower the weapon cap or allow turrets outside it.

Completion: every non-specialist hero starts with one jump; stacked cards produce exact totals; full inventories never offer unequipped weapons; capped builds always receive useful legal choices; new content has one clear benefit per card.

## 8. UI finish, co-op and release checks

- Give opaque HUD panels, weapon slots, potion timers and reward cards thin dark edges, small highlight rims and restrained offset shadows for depth. Preserve compact spacing, strong controller focus and 1080p readability. Keep weapon icons and upgrade numbers visible.
- Replicate actual enemy height/scale, flying state, HP/core fill, boss phases, textured shots and relevant effects. Host remains authoritative for hits/deaths. Personal luck gating and reward filtering use each player's own build.
- Preserve careers, achievement IDs and save defaults. Version network/content schemas when required. Test solo and host/guest paths throughout each milestone, not only after the art is finished.
- Validate mouse/controller coexistence, physical Xbox selection/rumble, movement, collisions, terrain, pots/chests, save reload, reward caps, jump stacks, boundary destruction and long sessions. Test four-player stress and live Steam invitations when a real App ID/accounts are available; local tests cannot prove Steam invitations.
- Keep one active packaged game. Export the replacement only after source checks and rendered/package checks pass. Do not publish to Steam as part of this planning task.

## Delivery order

1. New 3D creature/core + one hero/weapon/environment slice; visual review.
2. One complete biome, distance/scale rules, subtle border and performance baseline.
3. Remaining five biomes, 36 enemies, huge bosses and 21 heroes in the approved 3D style.
4. Projectile/explosion effects, animation audit and unique hero hurt vocals.
5. Fourteen potions, luck gate, pickup clarity, jump rules, new weapons/cards and inventory-aware rewards.
6. Compact UI finish, co-op/save regression, 1080p performance pass and a single replacement build.

No time estimate until the 3D/core slice proves the modeling pipeline, visual quality and rendering cost. The largest work item is genuine asset reconstruction, not changing the existing sprites' material.

## Reference sources

- [Godot visibility ranges](https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html): combine distance-dependent representations with mesh LOD and occlusion culling; avoid assuming transparency transitions are free.
- [Bungie Destiny 2 Artist Spotlight](https://www.bungie.net/7/en/News/article/48811): official original environment/sky art reference gallery.
- [Bungie The Skywriters of Destiny](https://www.bungie.net/7/en/News/Article/12017/7_The-Skywriters-of-Destiny): background on sky art as part of a world's scale and composition.

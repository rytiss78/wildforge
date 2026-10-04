# Next build: illustrated characters, living weapons and biome exploration

Status: implementation plan only. This document does not change the playable build.

## Design commitments

- Keep native Godot, full 3D movement, the approved illustrated icon style, funny heroes, compact opaque desktop UI, three shared weapon slots, timed bosses, paid three-choice chests and positive powers.
- Translate the icons into actual 3D assets: expressive low-poly silhouettes, small painted texture atlases, warm outlines and simple shading. Use generated concept sheets and textures to guide authored meshes; image generation alone does not produce rigged 3D characters.
- Chest items grant exactly ONE benefit. Skills should follow the same single-benefit rule so the two systems remain easy to understand. Weapons retain their distinctive mechanics and separate upgrade ranks.
- Large maps must remain readable and fast. Scale up after chunk streaming, navigation and encounter pacing work; map area alone is not the target.
- Enemies have readable minimum sizes and solid collision footprints. Crowds cannot overlap one another, pile vertically or occupy the hero's body during normal movement. Explicit ghost/burrow abilities may temporarily bypass contact according to their advertised mechanic, then restore a valid collision position.
- Preserve saves and existing achievement IDs. Add progression data with defaults; preserve previously earned positive bonuses when loading old saves.

## Milestone 1 — Clear single-bonus loot

Do this first because movement cards, biome rewards, icons and achievements depend on a stable power schema.

1. Remove the runtime process that adds two unrelated bonuses to every rolled item. Split multi-effect templates into independently named, independently illustrated single-benefit items. Audit the source catalog as well as generated native data.
2. Define metadata for each benefit: base amount, unit, additive/multiplicative behavior, rarity bands, rounding, stacking, cap and icon. Amounts must correspond to the actual effect, including nonlinear chances and cooldown reductions.
3. Show one plain description and one number: `Attack damage +10%`, `Jump height +20%`, `Fall damage −25%`, `Extra air jumps +1`. Reducing incoming damage or a cooldown is a beneficial effect; it is not a drawback.
4. Use non-overlapping rarity bands for the SAME benefit. A proposed damage ladder is Common +10%, Rare +20%, Epic +35%, Legendary +55%; these are examples to balance per benefit, not one multiplier applied blindly to all stats.
5. Display rarity and a common-version comparison in the detail card. Stack counts and the resulting total belong in the build screen. At a cap, reroll an ineffective choice or provide another genuinely useful benefit.
6. Keep procedural selection, varied appearances and amounts so runs remain different. Broaden distinct mechanics before multiplying cosmetic names. Target at least 150 meaningful single-benefit item/skill entries for the completed milestone.
7. Give level-up its own audiovisual event: a distinctive rising sound, animated `LEVEL UP · Level N` title on an opaque compact nameplate, a hero-centered celebratory effect and a short controller vibration. Briefly pause combat safely before opening the choice screen so the milestone is felt and the player can read. Coordinate the sound, voice and transition; do not instantly cover the celebration with cards or obscure nearby threats with excessive effects. Consecutive levels must each award their choice without overlapping audio or trapping the player in transitions.

Completion checks: every new item/skill has one effect; all four rarities show correct units; higher rarity improves the same benefit; discrete perks never advertise fractional jumps or lives; old progress loads safely; chest prices and three-choice behavior remain intact; level-up is audible and visibly important, with safe transitions and exactly one reward per earned level.

## Milestone 2 — Prove the illustrated world style

Build a small playable slice with Count Duck, one enemy, one chest, a tree, a rock and three distinct equipped weapons before remaking the whole cast.

- Establish a shared style sheet from the approved icons: silhouette proportions, contour thickness, palette, painted detail, light/shadow treatment and texture density.
- Replace assembled primitive character shapes with deliberate meshes and a reusable skeleton. The duck keeps its ridiculous serious expression, cape and tiny feet; the new arm system must still read clearly.
- Model weapons from their icon designs, including barrels, grips, tanks, coils and material differences. Keep recognizable silhouettes at normal gameplay camera distance.
- Audit grass, dirt, bark, rocks, ruins, chests, pots, crystals, sky and particles. Replace incompatible materials. Use small repeated textures and atlases, with mipmaps and checks for visible seams; avoid noisy detail that competes with enemies.
- Make one hero preview in the menu use the exact same model, materials and equipment as gameplay.
- Set a minimum enemy body size and silhouette budget using the gameplay camera, rather than judging models in close-up previews. Remake rats as chunky, expressive threats. Keep grass below the readable portion of ordinary enemies and use distinct outlines/material contrast across all biome backgrounds. Reduce or fade foreground foliage when it hides combat. Preserve recognizability at encounter distance and with distant detail levels; do not rely on labels to rescue invisible enemies.

Completion checks: screenshots of the slice visibly belong to the icon art direction; weapons remain distinguishable in motion; no visual assets are temporary primitives; collisions fit the visible objects; rats and other ordinary enemies remain visible through grass and at intended encounter distances; test at 1080p on a declared target PC and record frame time and memory.

## Milestone 3 — Visible equipment, animation and weapon audio

- First equipped weapon is held in one hand; second uses the other hand. Equipping a third grows a comic extra arm from the shoulder/back. Grow, equip, replace and remove the correct arm/prop when the build changes.
- Use a shared rig with three weapon sockets and independent aiming. Add limits so wrists, barrels and the third arm do not twist through the body or obscure the camera.
- Turret weapons use a held folded rig or deployment tool and still consume a weapon slot. Flowers use a seed pouch/planting tool: movement plants the garden; it remains a garden build rather than a gun turret.
- Add weapon-specific motions: pistol recoil, shotgun kick, rail charge, rocket launch, flame spray, poison pump, ice pulse, lightning coil discharge, saw spin, turret deployment and flower planting/blooming. Weapon rank increases visual intensity without making aim unreadable.
- Add distinctive weapon sounds and impacts, including loop start/stop behavior for saws and continuous effects. Use pooled positional audio, controlled overlap, material-sensitive hits and volume limits; avoid allocating a new sound player for every bullet.
- Add hero idle, walk/run, acceleration, turning, dash, attack blending, hit reaction, death and victory. Animate enemy attacks and telegraphs. Animate chest lids, leaves, flowers and selected ambient props where motion improves readability.
- Add enemy-bound damage and status effects. Fire shows animated flames, embers and a burning reaction; poison shows a green material tint plus droplets/bubbles; freeze shows frost and ice with the appropriate movement reaction; lightning shows a brief electrical arc; blind shows a readable head-level cue. Give other damage types fitting impacts and reactions as well. Bind effects to the enemy and actual status duration, distinguish ongoing damage from a one-shot hit and clear them on expiry/death. Combine simultaneous statuses without replacing the enemy with an unreadable mass of particles; use shape/motion as well as color for readability.

Completion checks: all three weapons are visibly equipped and animated; third-arm growth works on replacement; deployed weapons obey the cap; menu previews match equipment; weapon sounds remain distinguishable during a busy fight; burn, poison and other statuses remain readable alone and in combination, and visuals end with the status; repeated equipping and status application do not leak resources.

## Milestone 4 — Air movement, impacts and safe boundaries

Recommended baseline: every hero can jump and double jump. Cards add power beyond that baseline.

- Keep F / Xbox A for jumping; a second airborne press performs the double jump. Propose Ctrl / Xbox B for ground slam during gameplay, while B retains its menu-back behavior.
- Track takeoff, airborne state, jump count, peak height, descending speed and landing once. Add jump anticipation, airborne poses, second-jump kick, fall, soft landing, hard landing and slam animations. Test movement with mouse and controller cameras.
- Add fall damage only above a clearly safe drop threshold; ordinary steps, jumping and routine terrain must not hurt. Derive damage from the actual landing, including raised platforms. Prevent duplicate landing damage and false damage after gates, resets or safety recovery.
- Ground slam commits to a fast descent and damages nearby enemies on landing, with readable shockwave, sound and rumble. Separate its damage rules from an accidental fall.
- Add separate cards: Jump Boots (height), Extra Hop (one more air jump), Feather Soles (less fall damage), Slam Stone (slam damage), Wide Slam (slam radius), Bounce Pad (landing jump boost). Each has one benefit and an explicit amount. No card increases damage received from falling.
- Replace coordinate snapping as the normal map boundary with visible, collidable boundary terrain. Add collision-aware movement, valid landing surfaces and a last-safe-ground recovery below the world. Keep safety recovery outside ordinary fall-damage processing. Do not generate bottomless holes or unreachable chest spawns.
- Add collision against solid world props, enemy-to-enemy spacing and enemy-to-hero collision. Use collision-aware steering plus an efficient nearby-neighbor separation pass, with footprints matched to different enemy sizes. Enemies route around obstructions and each other rather than walking through bodies or climbing into a vertical stack. Reject overlapping spawns and safely resolve overlaps after knockback, streaming, teleports or restored collisions. Keep contact damage separate from physical separation so a packed crowd cannot inflict an unintended burst of simultaneous contact hits.

Completion checks: keyboard/controller jump chains and slam work; landing damage fires once; card numbers match behavior; every reachable edge is safe; a forced out-of-bounds test restores the hero without damage loops or lost progression; dense crowds at props, corners and narrow paths do not overlap, stack, enter the hero or push the hero outside the map; profile separation at the intended maximum active enemy count.

## Milestone 5 — Large maps with six biome types

Keep the three-chapter boss/gate progression. Each enlarged chapter map contains several biome regions from a shared palette, rather than a single uniform forest. Proposed first map target: roughly 1 km across, subject to performance and travel-time checks; expand only when exploration remains worthwhile.

| Biome | Visual identity | Native enemies | Threat |
| --- | --- | --- | --- |
| Clover Woods | Sage canopy, flowers, winding trails | Acorn bandits, angry picnic ants | Starter |
| Puffcap Marsh | Giant pastel mushrooms, shallow pools, reed paths | Grumpy toads, mushroom puffballs | Moderate |
| Honey Dunes | Warm sand, honey stone, cactus gardens | Cactus crabs, beetle knights | Moderate |
| Frost Peaks | Blue ice, snowy shelves, bright alpine sky | Woolly snowballs, penguin bruisers | High |
| Cinder Hills | Coral volcanic rock, warm vents, copper plants | Ember lizards, teapot golems | High |
| Prism Gardens | Lavender terraces, crystals, luminous blossoms | Glass beetles, crystal moths | Very high |

These are original biome proposals; Valheim and modded Minecraft inform variety, landmarks and transitions rather than copied assets.

- Generate connected regions with blended terrain/material edges, traversable elevation, recognizable landmarks and clear routes. Keep the starting region survivable and communicate stronger regions before the player enters deeply.
- Stream terrain, collisions and props by chunk. Apply distance detail levels, batched scenery, active enemy budgets and simulation limits for distant areas. Keep seed reproducibility.
- Author biome-specific enemy silhouettes, attacks, effects and sounds. Scale strength by both biome threat and elapsed run time. Harder biomes offer better treasure opportunities, without bypassing the paid-chest economy.
- Tune chest and landmark spacing, path lengths and movement speed together. Exploration must fit the chapter timer; bosses still arrive at the required time marks and remain reachable.
- Add biome discovery on the map, an opaque compact nameplate and a short natural female announcer recording: for example, “Puffcap Marsh.” Announce a biome once on first discovery per run. Boundary hysteresis avoids repeated triggers; urgent boss/health lines take priority over queued discovery lines. Use the existing offline voice production pipeline and bundled recordings.
- Add clearly marked elite variants with matching biome art and stronger, readable attacks. Elite enemies can drop illustrated, temporary consumables as well as normal rewards. These drops remain on the ground and require deliberate interaction; they are not collected by walking over them or by loot magnets.

### Elite consumables

- Examples: **Anti-Poison** (temporary poison immunity), **Anti-Fire** (temporary burn immunity), **Speed Drink** (temporary move-speed boost), **XP Drink** (temporary experience-gain boost). Each consumable has one benefit, an explicit strength where applicable and a displayed duration.
- Recommended first implementation: press **E / Xbox X** near a drop to pick it up and activate it immediately. Show the drop's name, benefit and duration before interaction. This keeps controls compact without adding an unrequested inventory system.
- Immunity removes the matching ongoing status and blocks new applications for its duration. Anti-Fire does not protect against unrelated physical damage from an enemy that happens to live in a fire biome. XP boosts apply to newly earned XP during the active window.
- Show active consumable icons and remaining-time countdowns in the compact opaque HUD. Use an expiry cue. Buff timers pause with gameplay and carry their remaining time through chapter gates.
- Repeating the same consumable refreshes its duration without lowering a stronger active version or accumulating unlimited duration. Different consumables may coexist. Keep temporary effects separate from permanent stats so expiration restores the correct value even if the hero gains cards during the buff.
- If a chest and drop share interaction range, highlight one target deterministically and show exactly which action E / X will perform. Define bounded drop persistence and safe spawn placement; do not spawn loot inside props or outside the map.

Completion checks: all six types appear across the game; crossings are clear; spawn placement is valid; threat/reward differences are felt; discovery audio does not chatter at borders; no streaming gaps expose voids; exploration and bosses work together; elite consumables require the interaction key, show accurate timers, prevent the matching status where applicable and expire without erasing permanent bonuses; profile a busy fight plus chunk transitions on the target PC.

## Milestone 6 — Complete the cast, achievement art and release checks

- Remake all seven current heroes using the proven rig and illustrated style: Count Duck (tiny cape and formal attitude), Wrench (oversized work gear), Tank Potato (potato knight), Stone Granny (statue granny with theatrical expressions), Tax Rat (nervous accountant), Sir Loaf (bread knight), Florist (Petal Punk with planting accessories).
- Give each character distinct idle/personality motions while sharing locomotion and the three-arm equipment system. Check body sizes, camera visibility and collisions across the whole cast.
- Replace all 100 achievement icons with illustrated compositions representing their actual challenges, including paired locked/unlocked variants for the Steam export. Keep existing achievement IDs and earned unlocks. Avoid generic skull/count artwork; the art should tell the story of the challenge.
- Audit the complete world for missing animation, inconsistent texture scales, mismatched particles, UI contrast and sounds. Verify the asset-generation records and Steam AI disclosure notes include the new art and audio.
- Run catalog/save tests, real rendered native tests, extended survival sessions, keyboard/mouse play, physical Xbox controller/rumble tests and performance checks. Rebuild only the single existing Windows build folder.

Completion checks: seven finished heroes, visible animated equipment, six working biomes, readable non-overlapping enemies, single-bonus numeric cards, important level-up events, visible damage/status effects, elite consumables, all movement features, safe boundaries, 100 matching achievement icons and a clean native export. Treat Steam publishing as a separate release gate after stability and store requirements are satisfied.

## Execution order and review points

1. Single-bonus loot, accurate card numbers and level-up celebration.
2. Illustrated vertical slice, enemy visibility and shared rig proof, including three visible weapons.
3. Weapon animation/audio, complete locomotion and enemy damage/status effects.
4. Air movement, fall/slam cards, object/crowd collision and boundary safety.
5. Streaming map generation, biome content, discovery narration and elite consumables.
6. Full hero/achievement art rollout and integrated validation.

Provide a playable update and screenshots at each milestone. Review the art slice before mass-producing models, and benchmark the large-map slice before filling all regions. The hardest dependencies are a convincing shared character rig, independently aiming three weapons, clean landing state transitions and stutter-free chunk streaming.

## 0.5 implementation

The approved plan has been implemented in the single native Windows development build. See [build-0.5.md](build-0.5.md) for the shipped feature summary, validation and remaining hardware/Steam release qualification. The checklist above remains the design and testing reference for continued polish.

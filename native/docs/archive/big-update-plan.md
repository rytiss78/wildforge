# Wildforge — next big update plan

Status: proposal only. No gameplay implementation, new build, GitHub push or release is authorized by choosing to read this plan. The user has requested bigger maps and less clutter at biome borders; optional ideas below require selection first. Date: 2026-10-05.

## Foundation: bigger, readable maps

Proposed starting size: 1,500 × 1,500 metres, up from the current approximate 1,000 × 1,000. This is 2.25 times the area. Validate travel and encounter pacing before increasing it further.

- Replace scattered hard-coded boundary, chest, terrain, sky and navigation distances with shared world-size settings. Co-op and diagnostics use the same settings.
- Keep chunk streaming and limited draw distance. Larger worlds must not load more distant objects or multiply the active enemy population.
- Make 18–30 metre transition corridors with roughly one-third the ordinary decorative density. Keep traversable gaps and gradual ground/sky changes. Large obstructions stay away from crossings; interiors can remain dense and distinctive.
- Put rewards and destinations along usable routes. Do not multiply box count with map area: retain rare boxes and review time between discoveries.
- Spawn enemies around players, including separated co-op players. Distant stuck crowds must not exhaust local spawn budgets.
- Keep boiling edge danger, physical containment and near-only steam. Update minimap scaling, chest markers and realm destinations for the larger world.
- Keep timed bosses initially. Review whether longer travel makes their timing unfair; changes need an explicit choice.

## Visual proposals — V1–V20

1. V1: Painted texture pass — replace remaining plain-looking surfaces with small illustrated atlases.
2. V2: Stronger silhouettes — distinguish every hero and creature at gameplay distance.
3. V3: Layered terrain — cliffs, terraces, valleys and clear routes instead of rounded hills everywhere.
4. V4: Biome palettes — controlled foreground/background colours with strong enemy contrast.
5. V5: Landmark details — windows, banners, cracks and moving parts on existing landmarks.
6. V6: Hero motion polish — readable run, stop, turn, landing and recoil poses.
7. V7: Weapon contact polish — melee trails and visible contact points matched to each weapon.
8. V8: Impact materials — distinct sparks, sap, dust, candy crumbs and blood by creature.
9. V9: Explosion library — hand-painted expanding blast shapes with readable edges.
10. V10: Boss wind-ups — exaggerated anticipation poses and ground warnings.
11. V11: Orb readability — clearer blood level, cracks and blue armour shell at distance.
12. V12: Pickup contrast — consistent coin/orb silhouettes and glow across all terrains.
13. V13: Living flora — wind motion, bending grass and occasional falling petals.
14. V14: Weather depth — nearby precipitation with distant storm silhouettes, without hiding attacks.
15. V15: Sky motion — slowly moving planets, fiery curtains and layered clouds.
16. V16: Contact shadows — ground characters and loot without muddying colours.
17. V17: Compact UI depth — consistent thin borders, bevels and restrained shadows.
18. V18: Upgrade transformations — weapons gain visible parts at rank milestones.
19. V19: Menu diorama — selected hero in a small animated scene instead of a static display.
20. V20: Effects accessibility — colourblind symbols and independent flash/shake intensity.

## Gameplay proposals — G1–G20

1. G1: Exploration pockets — short encounters guarding rewards off the main routes.
2. G2: Traversal routes — natural ramps, jump paths and safe shortcuts across biomes.
3. G3: Treasure clues — footprints, rattles and local signs instead of extra HUD arrows.
4. G4: Rare wandering merchant — optional weapon-upgrade or potion purchases.
5. G5: Weapon preview — show exactly what an upgrade changes before choosing it.
6. G6: Clear family tags — quick fire/poison/flower hints showing likely synergies.
7. G7: One-choice banish — remove an unwanted bonus from this run's future offers.
8. G8: Small offer bias — one choice sometimes suits your weapons; others stay wild.
9. G9: Behaviour elites — distinctive attacks and guaranteed better rewards, not just more health.
10. G10: Boss movement phases — repositioning opportunities between clearly signalled attacks.
11. G11: Element reactions — simple, visible combinations such as poison clouds ignited by fire.
12. G12: Active consumable pocket — hold one found potion and use it when needed.
13. G13: Potion comparison — show duration and replacement before picking up a potion.
14. G14: Co-op revive — rescue a downed friend during a vulnerable channel.
15. G15: Co-op pings — mark treasure, danger and destinations with controller support.
16. G16: Florist variety — seeds create trails, spreading patches or reactive blooms.
17. G17: Close-range auto aim — prioritise reachable threats so melee avoids distant targets.
18. G18: Returning loot — valuable abandoned drops gather into a local pickup after a fight.
19. G19: Run recap — show strongest combinations, exploration and memorable moments.
20. G20: Discovery achievements — unusual interactions and exploration, without kill-count grinds.

## Funny proposals — F1–F20

Previously suggested jokes remain proposals, apart from the already implemented chest sneeze and third-hand thumbs-up.

1. F1: Party-hat bosses — tiny hats wobble on enormous enemies.
2. F2: Snack hand — the third hand eats a biscuit while idle.
3. F3: Headbanging flowers — Florist blooms move to the music.
4. F4: Panic mimic — a fake chest sees your weapons and runs away with bonus loot.
5. F5: Duck parade — harmless ducks cross an occasional path.
6. F6: Turbo snail race — huge snails compete at absurdly slow speed.
7. F7: Toasted Loaf — fireproof Sir Loaf gets toasted edges.
8. F8: Banana slip — a positive card makes enemies slide and squash.
9. F9: Disco frost — frozen enemies shimmer like disco ornaments.
10. F10: Goblin receipt — an economy item prints a ridiculous chest receipt.
11. F11: Moon cheese — crater rocks have cheese holes and bite marks.
12. F12: Potion burp — drinking produces a short coloured bubble.
13. F13: Laundry ghosts — ghosts wear socks, towels and pillowcases.
14. F14: Bathtub bubbles — Admiral Bubbles leaves harmless dash bubbles.
15. F15: Cactus hug — Prickle Rick remembers his spikes halfway through an idle hug.
16. F16: Chicken helmet — a defensive item adds tiny chicken-shaped armour.
17. F17: Boss luggage — a boss arrives dragging a suitcase far too small for it.
18. F18: Angry mushroom eyebrows — mushroom enemies grow dramatic eyebrows while charging.
19. F19: Weapon disagreement — idle hands briefly argue over who gets the biggest gun.
20. F20: Lost tourist — a harmless alien asks for directions in the wrong biome.

## Ideas adapted from other games — I1–I20

These are proposed Wildforge adaptations, not claims that the reference games implement these exact versions. Use original art, sounds, characters and names. Preserve random single-bonus items rather than turning loot into memorised recipes.

Hades inspiration: varied ability builds, expressive characters and replayability, as described on its [developer-published page](https://store.steampowered.com/app/1145360/Hades/).

1. I1: Run-specific family combinations — earned fire/poison/etc. thresholds trigger one clearly described extra effect.
2. I2: Optional reward previews — an encounter symbol shows its reward family before you commit.
3. I3: Reactive hero quips — rare comments about discoveries, bosses or ridiculous weapons.
4. I4: Boss recognition — bosses remember a previous defeat through a brief visual gag.

Valheim inspiration: distinct world regions and discovery; its [official site](https://www.valheimgame.com/) describes biome exploration and bosses.

5. I5: Biome identity through materials — each region has its own rock, vegetation and architecture rules.
6. I6: Recognisable natural destinations — rare landmarks invite exploration from nearby viewpoints.
7. I7: Physical preparation clues — environmental signs hint at fire, poison or cold threats.
8. I8: Sheltered pockets — short spaces where scenery gives relief from weather and a place to regroup.

Dead Cells inspiration: changing routes and responsive combat from its [developer-published page](https://store.steampowered.com/app/588650/Dead_Cells/) and [official weapon/mutation notes](https://deadcells.com/patchnotes/5).

9. I9: Combat animation timing — anticipation, contact and recovery make each weapon feel different.
10. I10: Branching exploration routes — clear safer and tougher paths, with rewards matching effort.
11. I11: Readable attack tells — exotic creatures communicate attacks through movement and sound.
12. I12: Optional challenge pockets — small skill challenges with positive rewards, never mandatory curses.

Deep Rock Galactic: Survivor inspiration: [supply-pod rewards](https://deeprockgalactic.wiki.gg/wiki/Survivor:Artifacts).

13. I13: Supply beacon — defend a spot briefly to call down a reward.
14. I14: Drop impact — the arriving supply pod visibly squashes nearby enemies.
15. I15: A reward worth travelling for — a discovered beacon gives a clear optional destination.
16. I16: Environmental combat rewards — pulling an enemy into an arriving drop creates a memorable success.

Vampire Survivors inspiration: [official Adventures](https://poncle.games/adventures-faq), which remix characters, environments and weapons into side stories.

17. I17: Short hero adventures — optional bite-sized scenarios with a funny premise.
18. I18: Biome remixes — alternate themed layouts using existing assets and different encounter arrangements.
19. I19: Scenario-specific discoveries — optional story objectives rewarding new cosmetics or content.
20. I20: Remix challenges — temporary run rules focused on a weapon family, separate from normal runs.

## Suggested first selection

Start with map foundation plus V1, V2, V3, V4, V10, V11, V17, V20; G2, G5, G9, G15, G17; F1, F2, F3, F11; I5, I9, I11. Where ideas overlap, implement once. This selection prioritises readability, feel, exploration and affordability of development over adding twenty new systems simultaneously.

## Implementation order and balance reviews

1. Confirm map target and selected IDs. Resolve conflicts and mark overlapping proposals as one feature.
2. Map foundation: shared sizes, streaming bounds, clean transition corridors, rewards, minimap and co-op spawning.
3. Selected visuals: establish a single small biome sample first, then apply approved style consistently.
4. Selected gameplay and borrowed ideas: implement dependency order, retaining single-bonus items and random runs.
5. Selected jokes: keep effects short and subordinate to health, threats and weapon readability.
6. After every feature batch, review its effect on clearing speed, survival, XP, income, chest/reroll affordability, travel, three-slot choices, hero differences and co-op fairness. Record findings; ask before unrelated tuning or new mechanics.
7. Once all selected features are integrated, make one candidate build and do the final consolidated bug pass: full-run pacing, all biomes and boundaries, boss attacks, melee/projectiles, controller/menu focus, loot, saves, sound throttling, pause and co-op. Compare crowd performance and chunk memory with the baseline. Fix discovered problems and repeat only the affected checks.
8. Clean obsolete assets, dead code and temporary outputs after checking references. Retain editable source, provenance and one current playable build. Do not delete user saves.
9. Deliver the local build and balance/validation notes. No GitHub upload, push or release until the user explicitly asks again.

## Decisions

Reply with IDs such as `V1 V4, G5 G15, F1 F3, I5 I11`, or approve the suggested first selection. Confirm or change the proposed 1,500 × 1,500 metre map target. Large systems such as element reactions, consumable pockets and revival will need concrete behaviour choices before implementation, asked only if selected.

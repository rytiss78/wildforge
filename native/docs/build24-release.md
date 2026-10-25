# Wildforge 1.7.0 — Build 24

Build 24 is a Windows alpha. `build-info.json` beside the executable records the exact source commit and artifact hashes. Co-op uses protocol `wildforge-shared-world-16`, so **every player in a party needs Build 24**. Build 23 and Build 24 players cannot join each other's parties, and co-op now also refuses any different download of the game, so two players can never end up in a desynced party. The main menu shows the build ID (bottom right) to compare.

**Install:** extract the whole ZIP into a folder and run `Wildforge.exe`. Keep `godot_wry.dll` beside it; the video panel needs it. Archive `Wildforge-1.7.0-Windows.zip`, SHA-256 `b9ddc2ccdaaab687643d7a661b7ccd95fbb6b89ed7437c02ab430060d054e9a3`.

## New look: everything is a cartoon

Every enemy, boss, hero and weapon has been rebuilt from scratch in a gross-out sci-fi cartoon style: bold ink outlines, goofy mismatched eyes, crooked teeth, drool and tentacles. All designs are original. Everything with health shows it in a glass orb.

- **60 enemies, 10 per biome.** Seven are creatures, from the Gloop Gazer (a lime blob with three eyes on stalks) to Saucer Sam (a tiny flying saucer), Wurmo, Brainy Blorp and Crabzilla Jr. Three per biome are new **humanoid mutants** in body-horror style: Melty Mel (its face has slid onto its chest), Two-Torso Terry, Eyeball Eddie, Leggy Lou (walks on its hands), Tentacle Ted, Mirror Mike and more. Colours are chosen to stand out from each biome's ground.
- **The final boss is new.** The Ashen Colossus is now a purple mountain of flesh with a mouth across its whole belly, seven glowing eyes around its health orb, two huge clawed arms, two tiny ones and a tiny dumb head on top. It turns icy blue and then magma red as its phases change.
- **New realm bosses.** All eight have new bodies: a TV-headed alien, a crying brass bell, a lantern-headed skeleton, a robe with three masks, a giant eyeball wrapped in tentacles, an anglerfish tower, a walking mouth on chicken legs, and a mossy deer-skull giant.
- **New heroes.** All 25 are still who they were (Wrench, Count Duck, Tank Potato, Queen Tea, the White Supra...) but are now goofy cartoon characters.
- **New weapons and icons.** The guns are chunky sci-fi gadgets with glowing cores; turrets stand on tripods and look around with one eye. All 73 weapon icons were redrawn from the new models.
- **Every model is built around a big glass health orb**: the belly, torso, shell or whole body. It drains as health drops and is visible from every side.
- **Same speed.** Each enemy is a single mesh animated on the graphics card. With 125 enemies on screen the frame time is the same as before.

## Gameplay changes

- **Touching a melee enemy hurts at once**, then again every 0.7 s while you stay in contact.
- **Enemies are dangerous, not tanky:** ordinary enemies have 35% less health and hit 50% harder. Bosses are unchanged.
- **Only bosses slow you**, so a slow always has a visible cause.
- **Ranged enemies place one mark per shot** (was up to three), and fire at uneven times instead of all at once.
- **Turrets are stronger:** 60% more damage, 25% faster fire, every turret type gets the turret damage bonus, and a turret left far behind comes back to you.
- **Several level-ups at once** (a magnet full of XP) still give every level and card choice, now 3 seconds apart, and the XP bar shows how many are waiting.

## Interface

- A **dash cooldown** readout beside the slam readout; both turn green when ready.
- **Armor** shows its real value and how much damage it removes.
- **Damage, shield and heal numbers** under your health stay longer and fall more slowly.
- **Chests are bright** orange and gold, with a small light.
- **Ground zones are labelled:** `+ HEAL ZONE` in green; `POISON FOG`, `LAVA` and `GRAVITY RIFT` in red; `ICE` and `WIND` in white.
- **The sky is brighter** than the ground again.
- **The run report** sits inside the game-over window, with NEW RUN first.
- **Mutation cards** explain themselves: a mutation is a free bonus attack that fires by itself.
- **Enemy attacks have their own sounds** (a low growl, a dark crunch, a bite), different from every hero weapon.
- **24 easy achievements were retired**, such as the ones for just picking a hero or opening a menu. 93 remain.

## Known limits

- **Balance is untested by people.** Bosses have 5x health, the final boss hits 2.5x harder and drops health potions, and ordinary enemies now hit harder. Tell us what feels unfair.
- **Spell weapons** (tornado, black hole, thunderstorm, inferno and the like) keep their simple wand models.
- **The new enemy sounds** are generated and have not been listened to by a person.
- **Not yet tested on two machines** over a real internet connection.

## Verified

- The export from source commit `15f0483` passes the startup smoke and every exported review, and reports 1.7.0 / Build 24.
- The packaged ZIP, unpacked into a fresh folder, starts and passes the startup smoke with its own `Wildforge.exe`.
- Rendered reviews of the whole cast: `cartoon-review` (all 60 enemies, the mutants, the 25 heroes, the 8 bosses, real spawns in game), `colossus-review`, `boss-review`, `capture-ui`, `weapon-review`, and `crowd-review` for the frame-time comparison.
- `check`, `integration`, `red-moon-review`, `forge-review`, `hermes-review` and the co-op `shared-review` pass.

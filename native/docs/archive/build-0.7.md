# Wildforge 0.7.0 — illustrated 3D

The approved blood-core prototype now runs throughout the main game. This is the single native development alpha in `build/Wildforge.exe`; the Style Lab is an inspection mode in that same game.

## Included

- 21 modeled heroes with distinct silhouettes, held weapons, recoil, movement reactions and the third weapon arm. Each hero has two original neural hurt reactions.
- 36 exotic creature meshes across six biomes, different physical sizes and speeds, real flight/dive phases, draining glass blood cores, damage cracks/glow and dark blood for tough enemies. Hero cores and a compact HUD orb supplement the retained health readout.
- 36 varied scenery assets: branching trees, giant mushrooms, radar dishes, moon arches, cloud steps/towers, volcanoes, furnaces, alien coral and orbital ruins. Shared painted textures and ink contours match the illustrated direction. Terrain materials blend at biome boundaries.
- Streamed terrain, 180 m camera distance, 160 m detailed prop visibility, baked distance LODs and static occluders. Sky planets, rings, cloud oceans and hellfire render independently of ground distance. Local rain, snow, embers and drifting leaves vary by biome.
- Border steam appears locally near the edge rather than covering the distant skyline. The boiling strip still kills creatures and destroys drops; outer walls prevent leaving the map.
- Eight additional weapons: returning boomerang, bouncing disc, pulling harpoon, gravity well, stun horn, trapping bubble, falling meteor and rolling bomb. New icons render their actual meshes. Textured shots, animated explosions and distinct weapon sounds are active.
- 30 additional single-benefit powers, represented as item and perk templates: 332 templates total. Numerical bonuses retain a shared rarity baseline. Extra Hop is deliberately Common-only: each card grants exactly one additional air jump, up to eight. No free starting double jump.
- 14 named manual-pickup potions, including armor, damage, firing speed, critical chance, reach, coins, magnet, jump, fall protection and regeneration boosts. Elite drops require an acquired permanent luck item; innate hero luck and temporary luck potions alone do not unlock drops. Duration, strength and drop-chance cards improve them.
- Full weapon slots offer only upgrades to the three equipped weapons. Weapon ranks remain uncapped. Existing achievement identifiers and career saves remain compatible; the old replacement achievement now rewards upgrading all three weapons.
- Thin opaque UI borders, blood orb readout, coin/XP size distinction, glowing XP, temporary buff readouts and keyboard/Xbox prompts. Existing paid chests, level-up celebrations, Florist mechanics, music, announcer, scores and Community Lab remain.
- Multiplayer preserves the new creature sizes and blood fill, remote weapon mechanics and shared hazard warnings. Deferred disconnect handling fixes a native ENet crash.

## Validation

Source validation: nine Node rules/content tests, native gameplay/save/input smoke checks, and 21 dedicated 0.7 regression checks. The update checks cover the complete modeled roster, blood fill, jump stacking, 120 full-slot reward rolls, potion eligibility/effects, all eight new weapon paths, huge bosses, draw distance and voice/icon availability. Local host/rendered-client testing covers attacks, world snapshots, kills, movement, shared pause and realm transitions.

Rendered stress testing crosses all six biomes with approximately 100–112 creatures on a Ryzen 7 5800X / Radeon RX 9060 XT at 1080p. The final measured median was 4.83 ms and the 95th percentile was 26.13 ms, with about 149 MiB tracked static memory. Measurements are in `soak-07.log`; this is not a guarantee of stable 60 FPS. Chunk transitions and dense crowds still need extended playtesting and profiling on other hardware. The crowd report's horizontal spacing includes flying/dive phases and is not a capsule penetration measurement.

The exported executable also passes the complete native smoke suite, all 21 update checks and the two-process packaged host/rendered-client test. Imported scene caches were refreshed to remove stale texture UIDs. The fall test explicitly clears temporary potion buffs before verifying an unprotected landing, so randomly picked Feather Juice cannot invalidate its baseline.

## Editing and asset provenance

Original mesh generators: `scripts/build-style-models.py` and `scripts/build-world-models.py`. Mesh pre-baking and LOD generation: `native/scripts/bake_models.gd`, executed automatically by the native packager. Existing illustrated PNGs remain concepts/UI assets and supply shared paper, bark and stone textures; geometry is authored separately rather than pretending a front image contains a complete model.

Hero audio is generated offline with Kokoro, with character-specific casts and original short interjections. It is synthetic neural voice audio, not recordings of human actors. Text, voice settings and hashes are recorded in `native/assets/voices/hero-voice-provenance.json`, copied beside the executable with the model license. Existing announcer provenance is retained.

## Release checks still needed

Physical Xbox navigation/vibration, long multi-hour runs, balance/art review on ordinary gameplay cameras and other GPUs, live Steam friend invitations and achievement sync on two real accounts. Steam requires the real App ID and store/depot credentials before publishing. Community feedback is currently local; automatically collecting public Steam reviews is prepared separately and is not connected to the release.

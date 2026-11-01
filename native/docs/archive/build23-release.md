# Wildforge 1.6.0 — Build 23

Build 23 is a Windows alpha. `build-info.json` beside the executable records the exact source commit and artifact hashes. Co-op uses protocol `wildforge-shared-world-15`, so **every player in a party needs Build 23**. Build 22 players cannot join a Build 23 party, and Build 23 players cannot join a Build 22 party.

**Install:** extract the whole ZIP into a folder and run `Wildforge.exe`. Keep `godot_wry.dll` beside it; the video panel needs it. Archive `Wildforge-1.6.0-Windows.zip`, SHA-256 `c392581e0b8b4370967d1bf563301d8677752b794d44c285790b64ec27ee244a`.

## New

- **A new final boss: the Ashen Colossus.** The Baron is gone. The Red Moon now ends with a 17 m stone golem that fights like a Dark Souls boss.
  - **Every blow is telegraphed.** Red marks show where each attack lands, and the animation hits as they go off. Its attacks are a sweep, a ground slam, a stomp, a charging lunge, a leaping crash, a fire breath and a tail spin. Once it starts a blow, it no longer turns to follow you.
  - **Openings.** After a heavy blow it stays open for a moment and takes 35% more damage. Its health orb flashes while it is open.
  - **Three phases.** Stone at the start; ice below 65% health, with lava vents across the arena; fire below 30%, with meteors and chained double blows.
  - **Health orb, no health bar.** A glass orb on its chest drains as it is hurt and changes colour with the phase: red, then blue, then orange.
  - **Very deadly, with health potions.** Its blows hit hard: most can take most of your health. Every minute it sheds three health potions around itself. Walk into one to drink it; each heals 40% of your maximum health.
  - **It has five times the Baron's health.**
- **Every boss has five times more health.**
- **Much harder islands.** Less XP, faster enemies, and bigger, denser waves.
- **Danger is red.** Enemy attack warnings and harmful zones (lava, spores, rifts) are red. Your own skill areas are gold and amber, so red always means move.
- **Heavier hits.** Your hits knock enemies further back and make them hop. Blasts push from their centre.
- **Enemies stand out** from the ground with a warm rim light.
- **Longer view distance.** Fog, grass, scenery and enemy spawns reach further. The distance shrinks on slower machines to keep the frame rate.
- **Your own numbers.** Damage, shield and healing you take fall from under your health panel: red, blue and green. In co-op each player sees only their own damage numbers, and none while dead.
- **New main music:** an original drift-phonk track.

## Fixes

- **Videos kept playing after the pause ended.** Closing the pause now stops the video outright.
- **Block Drop music** is 30% quieter.

## Known limits

- **The new final boss is not balanced yet.** No person or bot has finished the fight since its health went to 5x and its damage to 2.5x. It may be too hard. Tell us how far you get.
- **Boss health elsewhere** went up 5x and has not been measured; mid-run bosses may now take too long.
- **Not yet tested on two machines:** the Colossus in co-op over a real internet connection.
- **Performance:** three max-rank spells in a 125-enemy crowd still run at about 30 fps.

## Credits

- The Ashen Colossus model and animations: "Fire/Ice/Stone Golem" by **umask007** ([OpenGameArt](https://opengameart.org/content/fireicestone-golem)), licensed [CC-BY 3.0](https://creativecommons.org/licenses/by/3.0/). Textures by **yughues**, CC0. Converted for the game; credits ship in `assets/boss/golem/CREDITS.txt`.

## Verified

- The export from source commit `cc89655` passes the startup smoke and reports 1.6.0 / Build 23.
- The packaged ZIP, unpacked into a fresh folder, starts and passes the startup smoke with its own `Wildforge.exe`.
- `colossus-review` (rendered): the real Red Moon entry, every action with its marks, lunge and leap movement, both phase changes, the open-window bonus, the health orb, 2.5x damage, the three potions and potion healing.
- `check`, `integration`, `boss-review`, `red-moon-review` and the co-op `shared-review` pass.

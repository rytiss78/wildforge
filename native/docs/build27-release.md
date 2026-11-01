# Wildforge 1.10.0 — Build 27

Build 27 is a Windows alpha. `build-info.json` beside the executable records the exact source commit and artifact hashes. **Every player in a party needs Build 27**: co-op refuses any other download (network protocol `wildforge-shared-world-17`). The main menu shows the build ID (bottom right) to compare.

**Install:** extract the whole ZIP into a folder and run `Wildforge.exe`. Keep `Wildforge.pck` and `godot_wry.dll` beside it. Archive `Wildforge-1.10.0-Windows.zip`, SHA-256 `b5feadee1efef812c990473192d3a0c8b0bbf2cf36f9e84caa42fd23b0c7cfdc`.

## The island floats

- **No more deadly sea.** Each island is a floating rock with a rounded rim and a hanging underside of earth, roots and glowing veins.
- **Walk over the edge** and your hero swings under the island and walks upside down beneath it. The camera turns with you, so the ground stays at the bottom of the screen. Walk back out over the edge to climb back on top.
- **Only heroes cross.** Enemies, drops and chests stay on top. While you are underneath, nothing hits you and your weapons rest.

## Pets are wisps

- Pets are small glowing wisps floating over your shoulder: **Glint** fetches coins, **Sting** stings enemies, **Halo** heals you.
- **Pet Treats drop only from the final boss**, and pets keep them between runs. One win grows a pet to stage 2, three wins to stage 3. Stars on the hero screen show each pet's stage.

## Look and sound

- **Glass health orbs**: empty orbs are clear glass. Every creature has painted skin, cel lighting and gloss.
- **Junkyard Planet** now has recognisable junk: tyres, fridges, car wrecks, barrels.
- **Calmer audio**: enemies share a sound budget, fewer voices talk at once, and the intro lost its roar.
- **The game has its own window and taskbar icon.**

## Cleaner screens

- **60 fps cap.**
- **A tidier main menu and settings**: grouped buttons; Sound, Screen, Controls and Look in two columns.
- **Show, don't tell**: most on-screen text (biome names, effect captions, long potion and hero descriptions, co-op clutter) is now a word or a symbol, with details in tooltips.

## Known limits

- Hiding under the island is safe; it may be too safe. Tell us if it feels like a cheat.
- The flip under the island and the wisps have been checked in rendered captures, not yet by people in long play.
- Balance is still measured with bots and damage dummies only.
- Not yet tested on two machines over a real internet connection.

## Verified

- The export from source commit `0ce3a57` reports 1.10.0 / Build 27 and passes `test-build`.
- `check`, `smoke`, `integration`, `capture-ui`, `underside-review` and `boss-review` pass on the source.

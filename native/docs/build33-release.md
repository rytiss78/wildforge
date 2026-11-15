# Wildforge 1.15.1 — Build 33

Build 33 is a Windows alpha and a fix release on top of [Build 32](build32-release.md): the game's content is the same. `build-info.json` beside the executable records the exact source commit and artifact hashes. **Every player in a party needs Build 33**: co-op refuses any other download, Build 32 included (network protocol `wildforge-shared-world-25`). The main menu shows the build ID (bottom right) to compare.

**Install:** extract the whole ZIP into a folder and run `Wildforge.exe`. Keep `Wildforge.pck` and `godot_wry.dll` beside it. Archive `Wildforge-1.15.1-Windows.zip`, SHA-256 `43dd0e3340541b2be7b33f2206efe10adbb379f68f943b721d274aa08b5692bd`, source commit `460f9db`.

## Co-op

- **The start of a run:** the host no longer plays on while a guest is still loading.
- **Warden chests:** a warden's reward chest stands in the same spot for everyone, so a guest can open it and it goes away once opened.
- **Level-ups:** a card is no longer lost when the level-up arrives after news of the next level, and a reward still waiting at a portal is no longer dropped.
- **Harvestables** stand in the same spots on every machine from the second map on.

## Big fights

- Burning, poisoned and frozen effects are drawn on the 24 affected enemies nearest the camera; the rest keep their tint. Ordinary creatures no longer cast a sun shadow (the blob under them stays).

## Sound

- The Grand Noggin's roar is about 12 dB quieter and follows the sound-effects slider.
- The title intro stingers are quieter.

## Small fixes

- The launch-pad carry and the trick shout reset with each run, Digby Mole's dig needs footing, and Tax Day's coins are capped.

## Known limits

- Still nobody has played the Build 32 run structure, maps and weapons; balance is only measured by automated reviews.
- Co-op has only run as two copies on one PC. The co-op fixes pass the automated two-copy tests but are not confirmed by a real party.
- One automated two-copy check (`shared-review`) fails for a reason not yet found; see Verified.
- The quieter roar and stingers were set by measured loudness and have not been heard in game by a person.

## Verified

`check`, `smoke`, `integration` (with the new co-op sync regressions), the one-PC two-copy `coop` test and the exported build's smoke run passed on the release commit. `coop-dropin`, `crowd-review` and `crowd-spells` passed on the same game code on November 11. The `shared-review` two-copy check does not pass: its host stalls before the chest handoff. The cause is not yet known and is tracked in [PLAN.md](../../PLAN.md).

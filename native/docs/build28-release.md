# Wildforge 1.11.0 — Build 28

Build 28 is a Windows alpha. `build-info.json` beside the executable records the exact source commit and artifact hashes. **Every player in a party needs Build 28**: co-op refuses any other download (network protocol `wildforge-shared-world-19`). The main menu shows the build ID (bottom right) to compare.

**Install:** extract the whole ZIP into a folder and run `Wildforge.exe`. Keep `Wildforge.pck` and `godot_wry.dll` beside it. Archive `Wildforge-1.11.0-Windows.zip`, SHA-256 `ARCHIVE_SHA`.

## New hero: Digby Mole

- A velvet miner with a hard hat, a pink star nose and huge digging paws. He starts with the Rolling Bomb, and his dash burrows and bursts out.
- **Dig Through (V):** he tunnels straight through the island to the same spot on the other side, and back. Digging up under the monsters blasts them away. "Dig, dig, dig!"

## Turrets

- **Mender Turret** (green cross): heals you while you stand in its green ring.
- **Thumper Turret** (speaker): pulses and knocks enemies in its blue ring away.
- They replace the Ice and Poison Turrets. Turret cards make them heal or push harder, pulse faster and reach wider.

## Under the island

- Jump, double-jump and ground-slam underneath.
- Place turrets there: they hang from the rock and keep working while you are under.

## The world

- **Junkyard crushers** squash the monsters under them and shove heroes and bosses out. Then the plate becomes a lift: jump on and ride it up, monsters too.
- **Lava** sets heroes on fire for a moment (with real flames), ignites monsters, only singes bosses, and burns up gold and XP that land in it.
- **Monsters and bosses move 10% faster.**

## Heroes and pets

- The hero screen starts on a **random hero** every time, solo and co-op.
- **Pets are picked by look**: the three wisps instead of names, also in the co-op menu.
- **Florist**: one flower every 7 m instead of a carpet; each is bigger, shows its area, and blooms harder. Her V plants a ring of six grown flowers at once.

## Cleaner screen

- Ground warnings, bursts and areas are soft colour fills without edge lines.

## Known limits

- Balance is still measured with bots and damage dummies only; the faster monsters are not yet bot-measured.
- Not yet tested on two machines over a real internet connection.

## Verified

- The export from source commit `SOURCE_SHA` reports 1.11.0 / Build 28 and passes `test-build`.
- `check`, `smoke`, `integration`, `capture-ui`, `underside-review`, `crusher-review`, `weapon-review`, `fx-review` and `combat-review` pass on the source.

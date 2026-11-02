# Wildforge 1.14.0 — Build 31

Build 31 is a Windows alpha. `build-info.json` beside the executable records the exact source commit and artifact hashes. **Every player in a party needs Build 31**: co-op refuses any other download (network protocol `wildforge-shared-world-21`). The main menu shows the build ID (bottom right) to compare.

**Install:** extract the whole ZIP into a folder and run `Wildforge.exe`. Keep `Wildforge.pck` and `godot_wry.dll` beside it.

## The rope (C / L3)

A new everyday action for every hero, just for fun. It deals no damage.

- **Next to a monster** (not a boss): C lassos the nearest one in front of you. It is stunned and dragged behind you. Press C again to toss it where you look; it tumbles through the air and lands in a puff of dust, unhurt. The rope needs 2.5 s after a toss.
- **Next to a living friend:** C ties a rope to them and tugs them along behind you. The rope snaps past 12 m.
- **Next to a downed friend:** C drags their body behind you.
- The bottom panel shows **[C] ROPE**, **TOSS** while you hold a monster, or the seconds left. The key can be changed in Sound / Controls.

## Reviving from under the island

- Under the island, stand below a downed friend's body lying on top and press C: the body is pulled straight down through the rock, with dirt bursting out. Then rescue them the usual way (hold E and enter the code) where nothing can hit you. It works the other way round too.
- A downed friend dragged or pulled under the island is shown upside down, and a downed player watching a friend under the island sees them the right way up.

## Roots under the island

- Every island now has 18 wild glowing roots hanging from its underside, besides the roots under planted flowers.
- Everyone sees them, with a soft green glow. Only Digby Mole eats them to heal.
- An eaten root is gone for good, and in co-op it is gone for every player.

## Co-op fixes

- **A friend's new hero:** after a run, a friend who picked another hero was still shown as the old one. The body is now rebuilt with the new hero.
- **Block Drop and videos stopped working** after a run with Clutch: his first-person HUD hid them for good. Only his own plates are hidden now, and they come back when he is down or the run ends.
- **Spectating as a downed Clutch:** his gun and hands no longer stay in front of the camera, his body shows again, keys 1–3 only play cheers, and the camera returns to the normal third-person angle.

## Also in this build (from Build 30)

- Chest reels are a real slot machine: reels stop left to right with a clunk, epic and legendary reels crawl to a stop with a rising whine, rarer reels light up with rays and a RARE / EPIC! / LEGENDARY!! tag, and a legendary ends on a jackpot. Opening a chest raises a light beam in the best prize's colour.
- Level-up and reroll cards spin and stop the same way; a card can't be picked while it still spins.
- Reroll is green and Banish is red.

## Known limits

- Nobody has played the rope, the pull-through revive, the root sharing or the co-op fixes with two real players yet; the co-op test runs two copies on one PC.
- The slot-machine sounds have not been judged by a person for volume and length.

## Verified

`check`, `integration` (new checks `carry_rescue`, `rope_friend`, `lasso`, `wild_roots`, `coop_hero_change`, `clutch_downed`), `smoke`, the one-PC `coop` test, `underside-review`, and the exported build's smoke run passed. Roots under the island were inspected in renders.

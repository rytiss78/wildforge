# Wildforge 1.15.2 — Build 34

Build 34 is a Windows alpha and a balance release on top of [Build 33](build33-release.md). `build-info.json` beside the executable records the exact source commit and artifact hashes. **Every player in a party needs Build 34**: co-op refuses any other download, Build 33 included (network protocol `wildforge-shared-world-26`). The main menu shows the build ID (bottom right) to compare.

**Install:** extract the whole ZIP into a folder and run `Wildforge.exe`. Keep `Wildforge.pck` and `godot_wry.dll` beside it. Archive `Wildforge-1.15.2-Windows.zip`.

## Less health

- Ordinary creatures have about 31% less health.
- Bosses and wardens have 40% less health.
- The Grand Noggin has 40% less health.

## Fire, poison and slam

- **Fire:** the Flamethrower hits much harder (damage 0.65 → 1.6), and burn now grows with Damage, as poison clouds already did.
- **Slam:** Slam Stone adds +50% slam damage per card instead of multiplying by 1.3 each time, and every slam and head stomp hits harder (Damage × 5.5, was × 2). Slam is no longer weak early and runaway late.
- **Poison** is unchanged; the other two were tuned to it.

Measured damage per second against a standing target at 12 / 24 / 36 cards:

| Build | Build 33 | Build 34 |
|---|---|---|
| Fire | 72 / 189 / 466 | 147 / 449 / 1,197 |
| Poison | 140 / 444 / 1,334 | 140 / 444 / 1,334 |
| Slam | 45 / 297 / 1,536 | 108 / 501 / 1,269 |

## Known limits

- The new numbers come from an automated review against a target that never moves or dies; nobody has played them yet.
- Turrets and flowers still deal far more damage late in a run than fire, poison or slam.
- Co-op has only run as two copies on one PC.

# Wildforge 1.8.0 — Build 25

Build 25 is a Windows alpha. `build-info.json` beside the executable records the exact source commit and artifact hashes. **Every player in a party needs Build 25**: co-op refuses any different download, Build 24 included. The main menu shows the build ID (bottom right) to compare.

**Install:** extract the whole ZIP into a folder and run `Wildforge.exe`. Keep `godot_wry.dll` beside it; the video panel needs it. Archive `Wildforge-1.8.0-Windows.zip`, SHA-256 `b64afbdbfa74917845d62fa76f3de4eb056065380c1ea0567c116b2b43c492bc`.

## The Grand Noggin: a new final boss

- **A giant floating head.** The final boss is now a huge bald head rising out of a glowing portal, with big ears, a bulbous nose and a mouth full of square teeth. Its two giant floating hands do the sweeps and slams; the head itself head-butts, spins, lunges and roars.
- **Its eyes are its health.** Two huge glass eyes drain as you hurt it. They change colour with its phases: I · THE NOGGIN DESCENDS, II · THE NOGGIN BOILS, III · THE LAST TANTRUM.
- **It demands a performance.** About 35 seconds in, and then every minute, it stops attacking and sings while seven waves of marks fall around you. Each wave leaves one **gold square** safe. Dodge every mark and the crowd cheers **BRAVO!**: its eyes crack open and take **double damage for 8 seconds**. Get hit once and it's **BOO!**: the Noggin sulks and heals 4% of its health.

## New

- **Rift Dash** (skill card, 3 ranks): your dash opens a green portal and you pop out 8, 10 or 12 metres ahead, with a blast at both ends. Walls stop you; enemies don't.
- **Creatures talk.** Every one of the 60 species babbles in its own gibberish voice: squeaks, gibbers, burps, growls, honks, hisses, warbles and groans, pitched to its size. They yelp when hurt, cry out when they die and chatter while they hunt you. The Noggin booms: a roar at each new phase, and a song, a cheer or a boo for its performance.
- **Spell weapons are cartoon gadgets** like the rest of the arsenal: a tornado funnel with eyes, a ringed black hole in claws, a grumpy thundercloud and a grinning fireball, each on a wand. Their icons were redrawn.

## Known limits

- **The voices are generated** and have not been listened to by a person yet. Tell us which ones are annoying.
- **The performance's difficulty is untested by people.** Tell us if the marks are too fast or the safe square too hard to find.
- **Balance** is still measured with bots and damage dummies only.
- **Not yet tested on two machines** over a real internet connection.

## Verified

- The export from source commit `d5e8d23` reports 1.8.0 / Build 25 and passes every exported review in `test-build`.
- The packaged ZIP, unpacked into a fresh folder, passes the startup smoke (118 checks) with its own `Wildforge.exe`. Two copies of it pass the co-op `shared-review`.
- `colossus-review` covers the boss's actions, phases, potions, the performance (start, fail heals, success opens the eyes for double damage) and the Noggin's voice lines. Rendered captures were inspected.
- `fx-review` renders the rift portals (`fx-rift.png`) and checks that they fade.
- `check`, `integration` (four clean runs in a row, including `rift_dash`, `creature_voices`, `creature_death_voice`), `smoke` and `shared-review` pass.

# Wildforge 1.15.0 — Build 32

Build 32 is a Windows alpha. `build-info.json` beside the executable records the exact source commit and artifact hashes. **Every player in a party needs Build 32**: co-op refuses any other download (network protocol `wildforge-shared-world-25`). The main menu shows the build ID (bottom right) to compare.

**Install:** extract the whole ZIP into a folder and run `Wildforge.exe`. Keep `Wildforge.pck` and `godot_wry.dll` beside it. Archive `Wildforge-1.15.0-Windows.zip`, SHA-256 `edfb9319e6930f1b1207f6f479cad3bcbeda1f0b12681a47efab112608222c82`, source commit `b9b3b70`.

## A new run structure

- **Loadout:** four weapon slots. Once they are full, no other weapon is offered, only ranks and upgrades for the four you carry.
- **Stat cards:** 24 cards of our own (Might, Haste, Vigor, Stride and more), levelled by level-ups. You hold four; after that only their levels appear.
- **Chest items:** everything else comes from chests, with no limit. Each item has one fixed rarity: plain stats are common, effects rare, strong effects epic, game changers legendary. 15 new items: overcrits, BONK, kill stacks, a reflecting shell, an overheal cushion, wisps, fireworks, slowed time and more.
- **New cards:** Dare (more monsters, more XP and gold), Wild Card (two random stats a level), Long Wick (effects last longer), Bouncy (shots bounce on), Gambler (free chests) and Hoarder (interest on saved gold).
- **Heroes grow:** each hero's perk gets a step stronger every level.
- One mutation per level-up. Cards are drawn as cards and items as objects.

## Seven maps, then the Red Moon

- A run is seven six-minute maps in a row, one biome each: Clover Woods, Puffcap Marsh, Moon Craters, Cloudwilds, Junkyard Planet, Candy Hell, Starfall Space. Then the Red Moon and the Grand Noggin.
- Every map has its own ground, sky and music.
- **Climbing:** ten mesas per map with a chest on top, reached by a ramp, a spiral of stone pillars or a launch pad. 28 more chests lie at random spots; they show on the map once someone in the party has been near.
- **Terraced stages:** Cloudwilds, Moon Craters and Starfall Space are built from big flat plateaus on four floors, with earth cliffs and whole tiles tilted into ramps. Monsters walk straight up the cliffs; heroes take the ramps. Junkyard Planet is a flat corridor maze.
- Digby Mole's dig is now a fall through the burning hollow inside the island.

## Weapons

- **85 weapons, and they attack differently.** The flamethrower sprays a short cone, lightning falls from the sky, flasks shatter into poison clouds, rockets home in, mines drop behind you as you walk, the ghost blinks from enemy to enemy and the sniper hits every enemy in a line.
- **Twelve new ones:** Halo (a damage field around you), Orbit Lids, Fire Trail and Frost Trail (footprints that burn or freeze), Dice (a six explodes), Blood Pump (spends a little health on a big blast), Whip, Snip Knife, Katana, Scythe, Hero Blade and Grudge Blade (stronger with every kill).
- **Every weapon evolves**, the new ones included. Tooltips describe how each one attacks.
- Gun, shotgun and harpoon shots now take every card and item: crits, Berserk, Multishot, Bouncy, boomerang, poison and fire payloads and the gilded look when evolved. Shotgun pellets aim at the target instead of flying over short monsters. Poison clouds hurt more with Damage.
- **Clutch** carries an automatic AK-47: 30-round magazine, a reload with its own sound, no laser tracers, keys 1–4 for the four weapon slots, and a HUD that keeps cards, gold and level.

## Achievements

- A run is now won by felling the Grand Noggin. Before this, no run could count as a win.
- Achievements for walking somewhere or just playing a hero are retired, along with ones that could no longer happen. Weapon goals use four slots. Eleven new ones are tied to the Red Moon.
- The six hardest achievements give big mustaches, worn on the hero screen and seen in co-op.

## Also in this build

- XP orbs tick up like a slot machine paying out.
- A softer gun sound, evasion on the vitals, no name plates, and no corrupted veins.

## Known limits

- Nobody has played the new run structure, the seven maps, the terraced stages or the twelve new weapons yet. Their balance (map length, chest count, item odds, weapon strength) is only measured by automated reviews.
- Co-op with the new maps and weapons has only run as two copies on one PC.

## Verified

`check`, `integration`, `smoke`, `weapon-review` (every weapon grows from rank 1 to rank 5), the new `weapon-combos` (every weapon with seven card builds and two builds of real chest items), the one-PC `coop` test, and the exported build's smoke run passed.

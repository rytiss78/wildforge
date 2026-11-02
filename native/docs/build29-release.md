# Wildforge 1.12.0 — Build 29

Build 29 is a Windows alpha. `build-info.json` beside the executable records the exact source commit and artifact hashes. **Every player in a party needs Build 29**: co-op refuses any other download (network protocol `wildforge-shared-world-20`). The main menu shows the build ID (bottom right) to compare.

**Install:** extract the whole ZIP into a folder and run `Wildforge.exe`. Keep `Wildforge.pck` and `godot_wry.dll` beside it. Archive `Wildforge-1.12.0-Windows.zip`.

## New hero: Clutch

- A first-person shooter hero: no auto-aim. Hold the left mouse button to fire where the crosshair points; 1–3 pick the weapon. Headshots deal double. Turrets still aim themselves.
- Gloved hands hold the weapon in first person, and his own screen shows health, armour, weapon slots and a kill streak.
- **Lock-On (V):** an aimbot for 4 s. It swings the view onto the nearest enemy, fires by itself at five times the damage, even through walls, then takes the next one.
- **Shift sneaks:** a slow walk. Enemies lose sight of him, stop and do not attack, unless another hero is in view.
- No slam. His shots also hurt other heroes.

## Heroes that play differently

- **White Supra** drives at twice the speed, drifts on Space with tyre squeal, crashes like a car when hit. No jump or slam.
- **Honey Hustler** flies and sips XP from flowers. **Smoker** hovers, so lava and ground effects miss her.
- **Admiral Bubbles** has no health, only a big bubble shield, and starts with the Bubble Gun.
- **Turbo Snail** leaves a lasting slime trail that slows enemies.
- **Prickle Rick** is now a big pickle lying on his side: no arms, legs or weapons. Enemies shove him about; anything touching him is poisoned (Toxic Hug). Triple health, and enemies come for him first. Weapon cards never drop for him.
- **Tax Rat** runs on all fours with a long tail; **Captain Eight** has eight tentacles.
- **Ninja** starts with a double jump; **Alcoholic**'s potions last twice as long.
- **Wrench** can tune a placed turret (E): keep entering the arrows right and it works twice as fast.
- Seven heroes retired: Roll Ronin, Tank Potato, Sir Loaf, Queen Tea, Bookworm, Chef Cap and Sir Snooze. 20 heroes in all.

## New things to find

- The shop is now **Dyleris**. Talk to him and three free **dropai** appear under the island, marked on your map. Go under and grab them; each changes the run (no fall damage, +30% XP, lava stops hurting you, a free revive and more).
- **Flower roots** grow under the island. Only Digby Mole sees them glowing, and eats them to heal.
- **Three more pets:** Ward (shield every few seconds), Mote (pulls XP orbs in) and Rime (slows enemies near you).

## Co-op

- **Downed players spectate** a living friend (Space switches, movement keys pan) and have a soundboard: number keys 1–0 play one of ten cheers everyone hears. No Block Drop or videos while downed.

## Clearer screens

- Hero screen: what the V trick does with its cooldown, short facts in numbers, hats picked right there, the pet in its own panel. A random hero every visit.
- Potions and biome pickups show their benefit in numbers.
- Death screen: survival time, level and boss phases; co-op adds rescues. No best-run line and no Quit button.
- The particles slider now scales every particle effect.
- **Bosses keep up**: they run at your speed when far away, so you cannot just walk off.

## Known limits

- Balance is still measured with bots and damage dummies only.
- Clutch, the pickle's pushing and the co-op spectating have not yet been played by people; co-op is not yet tested on two machines over a real internet connection.

## Verified

- The export from the tagged source commit reports 1.12.0 / Build 29 and passes `test-build`.
- `check`, `smoke`, `integration`, `capture-ui` and `underside-review` pass on the source.

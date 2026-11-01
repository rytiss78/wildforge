# Wildforge 1.4.0 — Build 21

Build 21 is a Windows alpha release. `build-info.json` inside the archive records the exact source commit and artifact hashes.

## New

- **Weapon evolutions.** Get a weapon to rank 5 and take its matching card (Gun needs a Critical hit card, Rail needs Piercing, spells need Size, and so on). The next chest then offers a gold **EVOLVE** card.
  - Evolving renames the weapon (Hand Cannon, Star Lance, Event Horizon, Sun Halo…), raises its power and gives it more shots, pierce, bounces or area.
  - Evolved weapons fire gilded shots and wear a gold halo.
  - If you're missing the matching card, chests offer it, marked **EVOLUTION KEY**.
  - All 73 weapons can evolve.
- **Spell synergies.** Spells now trigger your "on hit" mutations. Each spell also has two named synergies that switch on when you carry the matching mutation element:

  | Spell | Synergies |
  |---|---|
  | Inferno Halo | Firestorm, Phoenix Ring |
  | Storm Crown | Supercell, Hailstorm |
  | Void Orb | Collapsar, Plague Well |
  | Twister Totem | Fire Whirl, Toxic Cyclone |

  Cards and the build menu tell you which ones you'd switch on.
- **Biome mechanics in fights.** One per biome, appearing near you 40 seconds into an island, each with a warning first:
  - **Clover Woods:** clover rings heal you and clear burn and poison.
  - **Puffcap Marsh:** spore fog poisons everyone inside.
  - **Moon Craters:** ice floors make you slide.
  - **Cloudwilds:** wind gusts shove everyone.
  - **Candy Hell:** lava vents spread burning pools.
  - **Starfall Space:** gravity rifts pull everything in, then implode on enemies.
- **Enemy deaths.** Enemies dissolve into ink, or shatter when killed by frost, crits, explosions or slams.
- **Spell sounds.** All four spells have their own cast sounds, and twisters and void orbs carry looping sounds.
- **Camera zoom.** The camera eases out in big crowds, during big spells and near bosses.
- **One warning style.** Every enemy attack's ground warning is danger red, lasts at least 0.8 s and flashes white just before it lands. Charging enemies now paint their path on the ground.

## Changed

- **Damage numbers.** Non-gun numbers now start on the XP bar at the bottom of the screen. Gun numbers still rise from their weapon slot.
- **Biome looks.** Each biome has its own light, fog and ink. The ground is darker in five biomes, so heroes, enemies and effects stand out. Candy Hell's lava now outshines its ground, and Moon Craters is dark navy with pale crystals.
- **The Baron has 50% more health.** Evolved builds were killing him in two minutes.
- **Evolution power is tuned down 30%** from the first version.

## Verification

- The export from source commit `3d51f3c` passes the startup smoke and reports 1.4.0 / Build 21.
- These exported reviews pass against the exe with no script errors:
  - two-process co-op, plus the lag and slow-player stress review;
  - joining a running game by invite code;
  - the magnet, hunt and eclipse feature review;
  - the 720p and 1080p release review.
- Source checks, the full co-op route, and the combat, Red Moon, biome, island and effects reviews pass. The effects review includes new sheets for evolutions, synergies, deaths, zoom and warnings.

## Known limits

- **Difficulty:** bots now beat the Baron in about 25% of runs, against a 10% target, so the late game is still easier than intended. Results vary a lot between batches.
- **Untested by people:** internet hosting on a real router, the spell sounds, and the new biome looks.
- **Co-op visuals:** teammates see your evolved weapon's halo, but not your gilded shots or synergy effects.
- **Models:** the hand-made model pilot is not in this build; creature and hero models are unchanged.

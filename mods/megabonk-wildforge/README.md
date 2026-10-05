# Megabonk Wildforge Mod 0.3.0 skills compatibility release

The mod imports 21 heroes and their perks, 694 item/skill cards, 65 weapons, 36 enemy species and 18 biome boss forms, with 875 original icon images. Megabonk's original roster, items and enemies remain available.

Wildforge heroes and enemies display HP as blood fill inside their original model orbs. Native Megabonk actors keep their original HP indicators. Source art is loaded directly from GLB and PNG assets; no Unity editor or external character loader is required.

Skill cards appear alongside native level-up upgrades and work on both rosters; item cards enter native chest/reward pools. Mixed enemy waves include Wildforge creatures, and boss selection can include World Maw, Sun Breaker and Star Eater. With Wildforge content equipped, Left Shift dashes and Left Ctrl starts an airborne slam. The perk/card engine covers native stat bonuses, contextual augments, healing, procs, status effects, turrets, flowers and movement/economy effects.

This is a development alpha. Weapon attacks and enemy AI use native archetype adapters. Some projectile variant details and status/boss behaviors differ from the Godot source and need further adaptation. Full-run balance and visual acceptance are not established by compilation or catalog smoke checks.

All 342 skills pass native acquisition, two-stack effect resolution and removal checks. Conditional activation, additive conditional stacking and a skill on a native Megabonk hero also pass. Build coverage checks all 100 effect keys and 18 conditions for runtime consumers. The full batch builds with zero warnings/errors and passes the catalog, models, enemy spawning, sampled healing and partial orb-fill checks. See [VERIFICATION.md](VERIFICATION.md) for the evidence and its limits.

Compatibility changes include weapon-specific power/bounce/quantity/area effects on matching native archetypes, real timed slowing, coin-only healing and attraction, native regeneration units, dash windows, deliberate slam triggers, Wrench's turret and localized kill pools. Kill explosions stop recursive explosion chains. Modifier updates run when values change, and enemy snapshots are shared within a frame.

[Download mod 0.3.0 and checksums](https://github.com/rytiss78/wildforge/releases/tag/megabonk-wildforge-v0.3.0)

## Install and disable

Requires Windows x64 Megabonk 1.0.69 (Unity 2023.2.22f1) and BepInEx 6 IL2CPP x64, pinned to build 6.0.738. Launch once with BepInEx, close the game, then extract the package into the Megabonk folder, merging `BepInEx/plugins/Wildforge`. Alternatively run `scripts/install.ps1 -GameDir '<your Megabonk folder>'`.

Launch normally and choose a Wildforge hero. The mod uses a separate save profile at `BepInEx/config/WildforgeProfile/Saves`. To disable, close the game and move the entire `BepInEx/plugins/Wildforge` folder outside `plugins`. Keep the separate profile to resume later. Native Megabonk then uses its original saves.

The ZIP includes our plugin, original assets and catalog only. Install the loader separately. No game assemblies or personal saves are distributed.

## Development

Implement full batches, then use `scripts/build.ps1`, `scripts/smoke-test.ps1 -SkipBuild` and `scripts/package.ps1 -SkipBuild`. The smoke driver explicitly initializes the player and checks the merged catalog in one launch; omit `--wildforge-smoke` for normal play. Runtime evidence is in `artifacts/latest-smoke.log`. See `PLAN.md` for scope and remaining acceptance.

## Screenshots and about

![Wildforge hero roster inside Megabonk](https://raw.githubusercontent.com/rytiss78/wildforge/main/mods/megabonk-wildforge/docs/screenshots/hero-roster.png)

This screenshot was captured from Megabonk with the plugin installed. Wildforge is also a standalone survival game; its standalone screenshots are not mod gameplay screenshots.

Created by rytiss78. This is an unofficial fan mod for Megabonk, with original Wildforge content. Megabonk belongs to its respective creators. AI tools assisted development and generated significant portions of the original illustrations; see [content provenance](https://github.com/rytiss78/wildforge/blob/main/community/ai-content-provenance.md).

[GitHub source](https://github.com/rytiss78/wildforge/tree/main/mods/megabonk-wildforge) · [Report bugs](https://github.com/rytiss78/wildforge/issues) · [Standalone Wildforge download](https://github.com/rytiss78/wildforge/releases/tag/v0.8.2)
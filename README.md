# Wildforge

**Grow strange. Fight hard. Start again.**

A vivid 3D survival game where a duck, a loaf of bread and an angry granny are perfectly reasonable hero choices. Explore strange places, grab unpredictable upgrades and become outrageously overpowered before the monsters catch you.

**[Download Build 23 for Windows](https://github.com/rytiss78/wildforge/releases/tag/build-23)** · [Play with friends](native/docs/coop.md) · [Share an idea or report a bug](https://github.com/rytiss78/wildforge/issues)

**Build 23 (1.6.0) is now available as an alpha release.** The Red Moon ends with a new final boss, the Ashen Colossus: a 17 m stone golem with telegraphed blows, openings, three phases and a health orb instead of a bar. Every boss has five times more health, the islands are much harder, and danger always reads red. Everyone in a co-op party needs Build 23. [Build 23 notes and limits](native/docs/build23-release.md).

**Build 21 (1.4.0)** brought weapon evolutions into gilded new forms, named spell-and-mutation synergies, and a fight mechanic for every biome: clover rings, spore fog, ice floors, wind gusts, lava vents and gravity rifts. Enemies dissolve into ink or shatter, every attack warning speaks one danger-red language, and each biome has its own light and ink. [Build 21 notes](native/docs/build21-release.md) · [Build 20 notes](native/docs/build20-release.md).

The third map leads to the Red Moon, where an immense, slow Baron waits with four visible steam vents and deadly, telegraphed attacks. He is a stylized original fallback, not a photorealistic or officially licensed film model. Defeat him to begin an endless Eclipse. **Known limits:** some internet providers put homes behind a shared address (carrier-grade NAT), where no router can open a port; the game says so, and a friend with a public address can host instead. Balance comes from automated playtests rather than people, especially the Baron fight. Co-op fixes have been tested on one machine, not yet over a real internet connection.

## Your hero. Your chaos.

Choose from 25 ridiculous heroes, each with their own trick. Count Duck steals life. Sir Loaf dashes with a bang. Florist turns footsteps into a dangerous blooming garden. Admiral Bubbles brings a bathtub to the battlefield.

Carry three weapons at once. When two hands aren't enough, grow a third arm. Mix guns, blades, flowers and turrets with fire, poison, frost, ghosts, thorns and strange money tricks. Every upgrade helps you grow stronger; the next chest might send your run in a completely different direction.

![Hero selection with the new articulated characters](docs/screenshots/red-moon-1.1.0/red-moon-white-supra.png)

*White Supra brings speed, a wide turning footprint and backfire weapons.*

## Find trouble somewhere new

Roam through Clover Woods, Puffcap Marsh, Moon Craters, Cloudwilds, Candy Hell and Starfall Space. Hunt for treasure, jump over trouble, squash enemies underfoot and face huge bosses as the clock ticks down.

Spend your coins on a chest, choose one of five rewards and keep building your ridiculous little disaster. Chase 117 achievements built around exploration, clever combinations and unusual challenges.

![Detailed skill cards with paid rerolls](docs/screenshots/red-moon-1.1.0/ui-offers.png)

*One choice. More trouble for the monsters.*

## Bring friends

Survive solo or team up with up to three friends. Share XP, levels and chests, get your own cards to choose from, see what everyone picked, and discover what happens when four questionable heroes meet the same boss. Done choosing before your friend? Play Block Drop until they are.

Over the internet, the host shares an invite code (the router opens the port automatically through UPnP; behind carrier-grade NAT this is impossible and the game says so) and friends paste it into Join. On the same Wi-Fi, friends can pick the party from the nearby list. Friends can also join a run already in progress. [Co-op setup](native/docs/coop.md)

## Jump in

Download the Windows ZIP, extract the whole folder and run **Wildforge.exe**. No store account or installation is needed. Keyboard and mouse or Xbox controller both work.

**This is a development alpha.** Expect rough edges and plenty of changes. Your ideas can help shape what comes next: [tell us what you loved, what broke or what would be fun](https://github.com/rytiss78/wildforge/issues).

<details>
<summary><strong>For builders: source, tools and controls</strong></summary>

Agents: start with [AGENTS.md](AGENTS.md). Hermes has a [quick start](HERMES.md); the [Godot workflow and troubleshooting guide](native/docs/godot-workflow.md) covers commands, test evidence, screenshots and safe local exports.

The game uses Godot **4.7.2**. Open `native/project.godot`, allow the initial import and run the main scene. Node.js is used by the content scripts. All runtime game assets are included; local tool installations and generated caches are excluded.

For Windows packaging, place the console editor at `tools/godot/Godot_v4.7.2-stable_win64_console.exe` and the release template at `tools/godot/templates/windows_release_x86_64.exe`. `scripts/fetch-export-template.py` can obtain the templates. Python and voice models are needed only when regenerating assets.

```powershell
node scripts/native.mjs
./scripts/package-native.ps1
./scripts/package-release.ps1 -BuildNumber 22 -BuildDirectory <staged build directory> -SourceCommit HEAD
./scripts/test-coop.ps1 -Packaged -RenderedClient
```

Published downloads use sequential build numbers. This release is `Wildforge 1.6.0 — Build 23`, tag `build-23`, archive `Wildforge-1.6.0-Windows.zip` (with `godot_wry.dll` and its license, needed beside the executable for the video panel). The game remains a development alpha. Packaging includes `build-info.json` and a version-specific SHA-256 checksum. Pass `-BuildDirectory` and its exact `-SourceCommit` when packaging a verified staging directory.

WASD / left stick moves; mouse / right stick looks; Space / A jumps; Shift / RT dashes; Ctrl / B slams; E / X interacts; B / Y opens your build; Escape / Menu pauses. Weapons attack automatically. Florist plants while moving.

Achievements, scores and settings save locally in `%APPDATA%/Godot/app_userdata/Wildforge/career.json`. [Build notes](native/docs/archive/build-0.8.3.md) · [Asset origins](native/assets/README.md)

</details>

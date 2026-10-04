# Wildforge

One standalone native Godot game. Open `build/Wildforge.exe` and keep its PCK beside it. No store account or store DLLs are required. The console launcher runs the same game.

Download the Windows alpha from this repository's Releases page, extract the whole ZIP and run `Wildforge.exe`. The source ZIP does not contain the executable. This is an unfinished development alpha.

Build **0.7.7** removes Steam integration and keeps four-player ENet co-op. Play with friends offers Host Party, nearby-party discovery, Copy Host Address and direct IP/hostname/VPN joining. Join before the host starts. Internet hosting needs a reachable host through UDP 29736 forwarding or a shared VPN; no relay service is included. See [co-op instructions](native/docs/coop.md).

Existing achievements, scores, settings and local suggestions are preserved. The game has 21 original orb-first heroes, 36 exotic creature species, 25 weapons, 332 positive single-bonus item/perk templates, 14 timed potions, six biomes per world, three worlds and 100 illustrated achievements. Three weapons grow a third arm. Blood cores show health and blue glass shows armour/shield.

Stronger enemies give more XP. Touching XP drops merge into larger glowing spheres; coins and XP fall with gravity. Crowds navigate obstacles, and stranded enemies can be recycled to keep nearby spawning active. The HUD labels GOLD, BOX PRICE, LEVEL and XP.

Controls: WASD / left stick move; mouse / right stick look; Space / A jump; Shift / RT dash; Ctrl / B slam; E / X interact; B / Y inspect build; T / LB place turret; G / RB select turret; Escape / Menu pause. Weapons attack automatically; Florist plants while moving. Xbox rumble remains.

## Edit and build

Open `native/project.godot` with Godot in `tools/godot`. Content lives in `scripts/data`. Keep the single build folder updated:

The repository excludes local tool installations and generated caches. For a fresh clone, install Node.js and Godot **4.7.2**, open `native/project.godot`, allow the initial import and run the main scene. To use the Windows packaging script, place the console editor at `tools/godot/Godot_v4.7.2-stable_win64_console.exe` and its Windows x86-64 release template at `tools/godot/templates/windows_release_x86_64.exe`. `scripts/fetch-export-template.py` can obtain the templates. All runtime game assets are included; Python/voice models are needed only when regenerating assets.

```powershell
node scripts/native.mjs
./scripts/package-native.ps1
./scripts/test-coop.ps1 -Packaged -RenderedClient
node scripts/export-achievements.mjs
node scripts/collect-feedback.mjs --comments exported-comments.json
```

Local saves: `%APPDATA%/Godot/app_userdata/Wildforge/career.json`. Diagnostic tests use separate profiles. `community` contains achievement artwork/definitions, asset provenance and game/community text. Suggestions stay local; automatic online sharing is planned.

Offline neural voices, sound effects and arranged metal/cyberpunk music require no voice service during play. Provenance/licenses ship with the build. Meshes and illustrated artwork remain editable in `scripts` and `native/assets`. Current notes: [0.7.7](native/docs/build-0.7.7.md).

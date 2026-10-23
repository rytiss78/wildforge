# Wildforge 0.6 — painted worlds and friends

Native Windows development alpha. One active executable/build folder.

## Changes

- Xbox menus have explicit A activation, D-pad navigation and repeating left-stick navigation. Mouse motion/hover cannot steal a controller reward selection. Clicking or using the keyboard changes prompts back. B/Escape returns from the friends screen. Hero selection scrolls through 21 entries at 1080p.
- 21 distinct funny painted heroes replace the shared rounded body silhouettes. Fourteen newcomers include Queen Tea, Captain Eight, Turbo Snail, Roll Ronin, Admiral Bubbles and Toastmaster. Each has its own illustration, starter weapon and positive specialty.
- Weapons use the actual approved icon artwork as transparent world props. They are attached at hand positions, recoil and flash; the third slot grows an extra arm. The characters/props are camera-facing illustrations inside a 3D terrain and collision world, deliberately using the requested 2D fallback. They are not fully sculpted 3D characters.
- Six exotic non-humanoid species per region: 36 total, with weighted common/unusual/rare/mythic appearances, different health, speed, damage and chase/swoop/armour/spit/skitter/charge behavior. Bosses also use creature art. Minimum collision height remains 1.7m for ordinary enemies.
- Hits kick the hero back, shake the camera, jolt/flash the artwork and play a shell/wing/stone/wet/buzz/roar impact according to the enemy species. Ordinary enemy head stomps kill with a squash, burst, bounce and squish sound. Boss stomps deal heavy damage.
- Clover Woods, Puffcap Marsh, Moon Craters, Cloud City, Candy Hell and Starfall Space each have their own small painted ground texture and four illustrated scenery assets. Decoration density increased from 11 to 28 large objects per terrain chunk. Craters, slopes, ridges and raised ruins use actual collision. Ground queries match the rendered terrain triangles.
- Entering a biome blends the sky/fog and changes wind leaves, rain, snow, embers or cosmic motes. Moon/space show stars; the moon region has a distant moon. Four original announcer recordings were updated to the new names.
- The square outer border is a visible animated boiling steam wall. At 475m from the centre along either axis it kills the hero/enemies and destroys drops, consumables, planted flowers, shots and chests. Border deaths do not create new loot. Solid outer walls/recovery still prevent falling off the map. A warning appears before the dangerous band.
- HUD shows boxes discovered/total, opened and any destroyed at the border. Existing progression, one-benefit positive loot, weapon cap, bosses, consumables and saves are preserved.
- Achievement hero badges now reuse the new painted hero art; all 100 Steam IDs remain stable.

## Co-op

`Play with friends` supports up to four players. Host the lobby, let friends join, then start a run. Steam friends-only lobbies, overlay invitations, Steam join requests and launch-time `+connect_lobby` are connected to the bundled GodotSteam extension. Steam callbacks are pumped each frame.

The same session supports local network parties on UDP port 29736: one player hosts, other players enter that computer's local IP. `127.0.0.1` is for two instances on one computer.

The host owns enemy identities, health, movement, boss deaths and world transitions. Guests send hit/stomp/gate requests; replicated states drive their creature visuals. Remote heroes, held weapons, turret placements, muzzle flashes and shot trails are visible. Each player keeps their own wallet, pickups and chest choices. Any living player's pause or reward choice pauses the party. A defeated host continues simulating the world for surviving friends. Any surviving friend can use an unlocked gate. Host departure ends the session; there is no host migration or mid-run joining in this alpha.

**Live Steam invites are not verified.** `native/data/steam.json` still contains App ID 0. Set Wildforge's real App ID there, or set `WILDFORGE_STEAM_APP_ID` before launching, and test with two authorized Steam accounts. No Steam release/upload happened. The current Steam packet adapter uses GodotSteam's supported legacy P2P methods; a newer transport can replace that adapter without changing the game session.

Research: [MegaBonkTogether's own notes](https://github.com/Fcornaire/megabonk-together/blob/main/README.md) describe synchronization problems around shared wallets and dropped important interactions. Wildforge therefore uses personal economies and reliable critical events. [Valve's lobby documentation](https://partner.steamgames.com/doc/features/multiplayer/matchmaking) separates lobby membership from game networking; Wildforge implements both. No mod code or game assets were copied.

## Validation

- Nine Node content/rules/feedback tests pass.
- Expanded native checks cover Xbox menu/reward activation, mouse focus coexistence, all painted rosters/materials, hit bumps, head stomps, border destruction, plus existing combat/progression/save/UI checks.
- Two real game processes on localhost verify connection, shared creatures, guest attacks reaching the host, replicated deaths, remote avatars, party pause and synchronized next-world travel. A rendered guest also exercises the visual path. These tests use separate test profiles.
- The final packaged executable passes the rendered native regression. Packaged host plus rendered guest also pass: 149 guest snapshots, 9 replicated deaths, 12 guest hit requests accepted by the host, synchronized pause and next-world travel, with clean runtime logs.
- 1080p stress run: six biome crossings, 100–111 enemies, Ryzen 7 5800X / Radeon RX 9060 XT. Latest source run median 4.485ms, p95 26.751ms, approximately 172MiB debug static memory, minimum crowd centre spacing 1.015m. Ground delta stayed at or above zero. This is a development stress measurement, not a guaranteed frame rate.
- Physical Xbox controller/rumble, four computers, Steam relay/friend invites, long sessions and release balancing still need hands-on testing.

Commands: `node --test`, `node scripts/native.mjs --test`, `scripts/test-coop.ps1 -RenderedClient`, and Godot `--soak`. Source art and generation specifications are documented in `native/assets/illustrated/art-0.6-prompts.json`.

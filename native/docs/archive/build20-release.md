# Wildforge 1.3.0 — Build 20

Build 20 is a Windows alpha release. `build-info.json` inside the archive records the exact source commit and artifact hashes.

## New

- **Play with friends over the internet, with no extra apps.**
  - Host Party asks your router to open the game's port and gives you an invite code (`WF-…`), copied to the clipboard. Friends paste it into Join.
  - If your router or internet provider does not allow it, the party panel says why and suggests a friend hosts instead.
  - Friends can join a run that is already in progress.
  - Teammate nameplates show their ping.
  - [Co-op setup](coop.md)
- **Co-op combos:**
  - **Crossfire:** two players hitting the same enemy mark it, and it takes 25% more damage from everyone.
  - **Overload:** lightning on an enemy a teammate set on fire causes a blast.
- **Four screen-filling spells**, each taking a weapon slot and growing with rank:
  - **Twister Totem:** wandering twisters drag enemies in.
  - **Void Orb:** pulls a crowd together, then collapses.
  - **Storm Crown:** sky lightning across nearby enemies.
  - **Inferno Halo:** a fire ring sweeps outward.
- **Elite enemies carry a modifier**, shown with a coloured badge:
  - **Shielded:** a bubble that regrows.
  - **Splitting:** leaves two smaller enemies when it dies.
  - **Blinking:** reappears behind you after a warning puff.
  - **Berserk:** faster and harder-hitting below half health.
- **Islands 2 and 3 look different and tougher.** Each has its own coastline, sky, light, glowing ground cracks and drifting air. Island 2 is the Blighted Highlands and island 3 the Ashen Reach. Landing shows the island's name and how much tougher its enemies are.
- **Hunts feel like hunts:**
  - The shrine is now a horned-skull totem with braziers.
  - The hunt has its own drum music, which speeds up in the last 20 seconds.
  - Starting, winning and failing each get their own card and sound.
- **Boss and hunt rewards:**
  - The chest glows with a gold beam into the sky.
  - It offers rare-or-better cards and always includes a mutation.
- **Travelling between islands** plays a teleport sound with a flash and a beam of light.
- **Effect settings:** Shake, Flashes and Particles sliders in Sound & controls.

## Changed

- **The game is harder, and the difficulty is tuned with automated full-run playtests:**
  - Enemy waves build up more steadily.
  - Elites appear after the opening.
  - Each island is tougher than the last.
  - The Eclipse ramps up across the islands instead of hitting full strength at once.
- **Dashing passes through enemies** (never walls), so a crowd can no longer trap you.
- **Damage numbers:** numbers that are not from your guns now rise across the whole width of the screen, fade out, and critical hits shake.
- **Big crowds run much faster:** with 125 enemies, the slowest frames went from 130 ms to under 20 ms.
- **Banishing an offer** no longer removes the mutation cards from a level-up.
- **The minimap** no longer shows flags at the old ruin sites.
- **Hero stats** show drawbacks correctly, for example Tank Potato's "Move faster −18%".

## Verification

- The export from source commit `1789d63` passes the 118-assertion startup smoke and reports 1.3.0 / Build 20.
- The exported 720p and 1080p rendered release review passes. The menu, HUD and Play With Friends screens were inspected.
- Exported two-process co-op passes the shared review and the stress review with lag and a slow peer. The drop-in review also passes: a second player joins a running game with an invite code.
- The exported magnet, hunt and eclipse feature review passes.
- Source reviews pass:
  - check, smoke and integration;
  - the full two-process co-op route;
  - the hunt, island, UI, combat, journey, Red Moon, boss, play-feel and effects reviews.
- In the last 12-run automated playtest, 58% of runs cleared island 1, 17% reached the Baron and 8% beat him.

## Known limits

- **Internet hosting has not been tried on a real router.** Automated tests never change router settings.
- **Balance is measured with bots and damage dummies.** It has not been playtested by people, especially the Baron fight.
- **Three fully upgraded spells in a very large crowd** drop to about 20 fps.
- **The early co-op desync** reported in older builds has never been reproduced, so it is not claimed fixed.
- **Creature, hero and boss models** are mostly the earlier stylized designs.

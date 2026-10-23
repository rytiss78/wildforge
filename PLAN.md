# Wildforge — plan

October 23, 2026 · main branch · **Build 19 (1.2.1) is the latest public release.** Everything under "Since Build 19" is committed but not yet in a published build.

Rules: [AGENTS.md](AGENTS.md) and the [Godot workflow](native/docs/godot-workflow.md). A checked item means the real entry point was exercised and the evidence is recorded. The full history up to this rewrite, with every evidence path, is in [plan-history-through-build19.md](native/docs/archive/plan-history-through-build19.md).

Evidence folders are under `.build-staging/agent-workflow/`. Run folders older than October 23 were moved to `G:\wildforge-archive\2026-10-23\agent-workflow\`. The latest run of each action and the Build 19 build folder were kept.

## The game today

- **Run:** three islands of six biomes each (island 2 is "Blighted Highlands", island 3 "Ashen Reach"). Each island has a 10-minute clock, two wardens and a portal. Then the Red Moon arena with the Baron, then an endless Eclipse.
- **Content:** 25 heroes, 73 weapons (including four screen-filling spells), 746 upgrade cards, 102 mutations, elite modifiers (shielded, splitting, blinking, berserk), hunts, supply beacons, magnet events, a merchant, rerolls and banishes, and 117 achievements with earned cosmetics.
- **Co-op:** up to four players over LAN, or over the internet with UPnP invite codes. Drop-in join, reconnect, shared XP and chests, and party combos (Crossfire, Overload). Protocol `wildforge-shared-world-12`.
- **Difficulty:** tuned with the playtest bot. The last 12-run batch had 58% clear island 1, 17% reach the Baron and 8% beat him (`2026-10-23T09-40-56-088Z-bot-playtest`). The target was about 70 / 25 / 10, kept deliberately hard.
- **Tooling:** `node scripts/agent-workflow.mjs` covers check, smoke, integration, about 30 rendered and two-process reviews, `bot-playtest` and `build`.

## Since Build 19 (unreleased)

Commits `4cbe4a3` → `d95dd56`. Details and evidence for each are in the plan history.

- [x] Four screen-filling spells: Twister Totem, Void Orb, Storm Crown, Inferno Halo (`4cbe4a3`).
- [x] **Phase A:**
  - crowd performance (125 enemies: p95 frame 130 → 18.5 ms);
  - the banish bug fixed;
  - the flaky combat check fixed;
  - Shake, Flashes and Particles settings (`886ae86`).
- [x] **Phase B:**
  - internet co-op with UPnP invite codes;
  - drop-in join and ping on nameplates;
  - Crossfire and Overload combos (`f591afb`).
- [x] **Phase C:**
  - the playtest bot;
  - dashing passes through enemies;
  - wave pacing and Eclipse ramp;
  - elite modifiers;
  - islands 2 and 3 look distinct and harder (`0eaa43c`).
- [x] **October 23 polish** (`d95dd56`):
  - **Hunt:**
    - a horned-skull totem with braziers and a violet beacon;
    - its own drum loop, which speeds up in the last 20 s;
    - HUNT BEGINS / COMPLETE / FAILED cards with their own sounds.
  - **Boss and hunt chests:** a gold sky beam, rare-or-better cards and a guaranteed mutation.
  - **Island arrival:** a teleport sound, flash, beam and ring.
  - **Damage numbers:** non-gun numbers use the full screen width, fade out, and crits shake.
  - **Minimap:** the leftover landmark flags are removed.
  - **Evidence:** `hunt-review`, `island-review`, `capture-ui` and the full two-process `coop` route (`2026-10-23T10-20-21-186Z-coop`) pass.
- [x] Hero stat drawbacks show their real sign ("Move faster −18.0%", was "+-18.0%") (`1789d63`).
- [x] **Build 20 (1.3.0), local, not published.** The user skipped the planned friend test of internet hosting (October 23).
  - Version bumped in `package.json` (version and buildNumber), `native/project.godot` and `native/export_presets.cfg` (`790fde9`, `5eee44d`).
  - Build `.build-staging/agent-workflow/2026-10-23T11-13-11-943Z-build/Wildforge.exe` from source `1789d63`. The exported smoke passes and reports 1.3.0 / Build 20.
  - Exported reviews against that exe pass with 0 script errors:
    - shared-review `2026-10-23T11-13-32-006Z`;
    - shared-review-stress `11-13-46-887Z`;
    - coop-dropin (invite-code join) `11-14-09-588Z`;
    - hermes-review `11-14-18-464Z`;
    - release-review `11-14-31-069Z`. Its 720p and 1080p menu, HUD and co-op renders were inspected.
  - Packaged as `dist/Wildforge-1.3.0-Windows.zip` (81,875,888 bytes, SHA-256 `01f88715…ff5744566`).
  - Notes: [build20-release.md](native/docs/build20-release.md).
  - A first build attempt (`11-07-40-071Z-build`) was rejected by the build guard because `package.json` buildNumber was still 19. That build is invalid.
- [ ] **Publish Build 20** as GitHub release `build-20` and point the README at it, when the user asks.

## Next: Phase D — run depth

- [ ] **Weapon evolutions.** A max-rank weapon plus a matching card evolves into a stronger form with its own look.
- [ ] **Spell–mutation synergies.** Mutation triggers react to spells (for example, Ember igniting inside Inferno Halo).
- [ ] **Biome mechanics in fights.** One per biome, for example ice floors, spreading lava or toxic fog.

## Then: Phase E — look and feel (Hades direction)

- [ ] **Art bible and per-biome pass:** palette, lighting and ink weight per biome. Start from [art-direction.md](native/docs/art-direction.md) and the [Hades study](native/docs/hades-style-research-1.0.0.md).
- [ ] **Enemy death animations:** ink dissolve or shatter.
- [ ] **Better hero and creature models**, made in-house. Earlier procedural and Blender metaball rebuilds read as blobs and were rejected. Pilot one hero and one creature with a slower, hand-directed Blender pipeline (blocked silhouette, subdivision, painted texture, ink outline). Compare them side by side with the current models before any wider rollout.
- [ ] **Spell sounds:** their own casts and loops for the four spells.
- [ ] **Camera zoom** when spells or crowds fill the screen.
- [ ] **Telegraph consistency:** one warning language (shape, colour, timing) for every enemy attack.

## Open issues and limits

- **Internet co-op on a real router is untested.** Automated tests never touch router port mappings. The user is testing HOST PARTY with a friend.
- **Snapshot size:** at 100 enemies, snapshots exceed the 1,392-byte MTU (about 9 fragments). This has not been measured under real packet loss.
- **Early co-op desync:** the original symptom was never described in detail. The pause-input fix and the passing full `coop` route do not prove it is gone, so the issue stays open until a matching report or reproduction exists.
- **Rejoin:** a chest or level-up reward offered while a player was disconnected is not offered again.
- **Performance:** three rank-9 spells in a 125-enemy crowd run at about 20 fps (median 49.5 ms). The per-step enemy update is the remaining cost.
- **Balance** has been measured with bots and damage dummies only. It still needs a human playtest, especially the Baron fight and spells in moving crowds.
- **Cleanup the user does by hand:**
  - delete `G:\game-fxbase`;
  - optionally delete `G:\wildforge-archive` (old runs, builds 15–18 and old release zips; every release is also on GitHub).

## Deferred

- A hosted relay or matchmaking server. The user chose port opening only (October 22).

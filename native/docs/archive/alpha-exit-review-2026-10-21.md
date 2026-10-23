# Alpha exit review — October 21, 2026

Build 17 (1.1.3) review against four reported problems: co-op desync, inconsistent UI, inconsistent graphics and non-descriptive icons. It also asks the broader question of why the game is not yet fun. Findings below cite code or measurements; nothing here is a verified fix.

## Update — October 21

- **Tooling restored.** Git 2.55.0 and Node 24.20.0 are installed. Baseline `check` passes (`2026-10-21T07-53-14-784Z-check`).
- **Desync reproduced** in `2026-10-21T07-53-34-849Z-shared-review`. 100 host enemies → 82,736-byte snapshot → the client receives 0 snapshots in 2 s and sees 0 of 100 enemies, while still connected. All other shared-review checks pass.
- **User direction supersedes sections 3 and 5 below.** The visual target is a Hades-like style. The upgrade pool should have **more than 100** upgrades, mostly ones that change how a run plays, instead of being cut to about 60.

## Environment blocker (resolved)

`git` and `node` are not on this machine's PATH. `scripts/agent-workflow.mjs` spawns `git` for every action (`spawn git ENOENT`), so no `check`, `smoke`, `shared-review` or `build` can run. Install both before any code change:

```powershell
winget install --id Git.Git -e
winget install --id OpenJS.NodeJS.LTS -e
```

## 1. Co-op desync — probable root cause found

**Measured:** a single enemy record in the host's world snapshot (`coop.gd` `snapshot()`) serializes to **728 bytes** with `var_to_bytes`, because each enemy is a Dictionary with 24 string keys. Full snapshots, actors only:

| Enemies | Snapshot bytes |
| --- | --- |
| 10 | 7,340 |
| 30 | 21,900 |
| 60 | 43,740 |
| 125 (cap) | 91,060 |

Measured with the bundled Godot 4.7.2. Players, XP drops, `journey` and `big_update` state add more.

Three consequences in `coop.gd`:

1. **Silent drop above 60 KB.** `tick()` ignores any packet over 60,000 bytes (`if bytes.size()<=60000`). At roughly 75–80 enemies the client stops applying world state entirely: enemies freeze or vanish, XP/level stops updating and pause state is lost. After 12 s it calls `connection_lost()`.
2. **Every snapshot is reliable.** `send_to()` forces reliable mode for anything over 1,000 bytes. That is every snapshot with two or more enemies. At 10 Hz this means 70–900 KB/s of reliable, fragmented traffic per client. One lost fragment stalls the reliable channel. Hits, kills, chest and reward messages then queue behind stale world state. This produces rubber-banding and late events long before the 60 KB limit.
3. **Local deaths are permanent on the client.** `apply_world()` skips any enemy already marked `dead` (`if found.is_empty() or found.dead: continue`). Client-side paths still kill enemies locally, for example `update_boiling_edge()` on interpolated positions. Once that happens, the host keeps simulating an enemy the client can never see again.

Why previous tests passed: `shared-review` and `coop` scenarios use few enemies on LAN/loopback with no packet loss. Early-game density on a real network is the first point where all three effects appear.

**Fix plan (next step once tooling works):**

- Reproduce first: add a `shared-review` stage that spawns 100 host enemies, then asserts that the client keeps applying snapshots and that `snapshots_received` keeps increasing. Record the failing run.
- Send static enemy data (species, biome, size, max HP, boss/elite flags, title) once. Use a reliable `actor_spawn` message, and add a client `need_actors` request for unknown IDs.
- Encode the per-tick dynamic state compactly (ID, position, HP, surface vectors and status timers) as `PackedFloat32Array`. Target about 64 bytes per enemy, under 10 KB at the cap.
- Always send world snapshots unreliable/sequenced, and add a sequence number. The client should drop stale snapshots rather than queue them.
- Never let the client mark a host-owned enemy dead except on a host `kill` message or absence from a snapshot.
- Repeat the stress review (20 Hz client, 150 ms delay) plus 2% simulated loss at 100 enemies, then in two exported processes.

## 2. Inconsistent UI

Inspected `2026-10-18T12-08-00-279Z-capture-ui` (1440×810):

- **Main menu and in-run screens use two different visual languages.** The menu uses a teal Art-Deco pillar scene with flat buttons. The HUD and modals use dark navy panels with gold corner brackets. Hero-list buttons, main buttons and modal buttons each have a different shape and weight.
- **HUD is fragmented:** five separate floating boxes on the left (timer, HP, gold), a loose `Clover Woods` label, a status chip mid-screen, bottom weapon slots, a slam hint, an XP bar and a pause hint. The panels do not share an alignment grid or margins.
- **Debug-like copy reaches players:** `BARON MARKS UI RUNNER · MOVE` appears in World 1. The level-up screen shows `Current 0.8 → 0.96` for jump height with no units.
- **Reward modal:** cards fill the top 45% and the remaining space is empty. The same item (`Jump Boots`) appears twice in one five-card offer at Common and Legendary.

**Direction:** one theme resource (`theme.gd`) owns all fonts, panel styles, buttons and colours. The menu adopts it too. Merge the HUD into three anchored clusters: top-left vitals, bottom-centre loadout and XP, and top-right map. Remove debug strings. Deduplicate offers by name.

## 3. Inconsistent graphics

From the HUD and menu captures: low-poly toon heroes with emissive accents, dark spiky enemies and painterly ground-cover, against an aurora sky and tiled cobblestone. Each was added in a separate pass (toon_art, painted_batch, combat_ink and style_lab scripts all coexist). There is no shared palette or shading rule.

**Direction:** pick one target style and write a one-page art bible covering palette per biome, outline rule, shading model, silhouette scale and emissive budget. Convert biomes one at a time from the gameplay camera, starting with Clover Woods. The art stays procedural and in-engine; consistency is a rules problem, not an asset-count problem.

## 4. Icons

Reward cards show one large generic silhouette (boot, blob, trapezoid) with the meaningful glyph shrunk into a corner badge. `Afterimage Metronome` and `Skybound Gauntlet` do not read as their effect. The audit already noted that 700+ unique SVG hashes do not mean visually distinct icons. Potion icons are the exception: the bottle colour carries the category and a central glyph carries the effect. That rule works.

**Direction:** apply the potion rule everywhere. The frame and colour show the family (Ballistics, Health, Turret and so on). One large central glyph shows the stat (pierce arrow, heart, crosshair, magnet). Rarity is the border only. That needs about 40 family/stat glyphs, not 738 bespoke icons.

## 5. Why it is not fun yet

- **Loot is 738 single-stat bumps.** Every entry in `catalog.json` `loot` has exactly one effect. There are 94 duplicate names, for example 12 entries named `Power` and 11 named `Health`. Choices are "+x% of something", so builds do not change how a run plays. Fun in this genre comes from a few rules-changing pickups that combine, for example "dash leaves a fire trail" or "every 5th shot splits".
- **Breadth over depth:** 25 heroes, 69 weapons, 117 achievements, 8 bosses, six biomes, mastery, cosmetics, formations and reconnects. Core feel and balance are still unverified: the Baron fight duration and win rate were never measured in play.
- **Recommended direction:** freeze new features. Cut the loot pool to about 60 entries: about 40 stat upgrades with one name and tier each, plus about 20 mechanic-changing upgrades with visible effects. Tune one 15-minute run with 3–4 heroes and about 12 weapons until a playtest is enjoyable, then add content back.

## Proposed order

1. Restore tooling (Git and Node), then run baseline `check`, `smoke` and `integration`.
2. Co-op snapshot rewrite (section 1), reproduced and verified in exported two-process runs.
3. Loot pool consolidation and offer deduplication. This is data-driven and testable in `integration`.
4. Unified theme and HUD regrouping, with rendered captures at 720p, 810p and 1080p.
5. Family/stat icon system.
6. Art bible and per-biome style pass.
7. Real-fight playtest and balance of a single focused run.

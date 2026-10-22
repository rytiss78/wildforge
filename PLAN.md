# Wildforge — active plan

October 22, 2026 · **1.2.1 / Build 19 is the public release** · main branch.

Use [AGENTS.md](AGENTS.md) and the [Godot workflow](native/docs/godot-workflow.md). Work directly, one agent. A checked item requires exercised behavior and evidence; historical completion marks are not verification.

## Next work plan (user selection, October 22)

The user picked these from a list of 30 suggestions, plus internet co-op without external apps. Phases run in order; each item lands as its own verified commit. Numbers refer to the suggestion list.

### Phase A — foundations (first: everything later is measured and tuned on top of these)
- [x] **30 · Housekeeping.** At the user's decision (October 22), the uncommitted `game.gd` lobby change and the `README.txt` deletion were discarded; a patch of them is kept in the session scratchpad. Still open: the user deletes the `G:\game-fxbase` folder by hand.
- [ ] **25 · Flaky combat-review check.** `contact_warning_saved` depends on a random species and the soak's frame count; give the check a fixed melee attacker.
- [ ] **9 · Reroll, banish, merchant: verify and fix.** Checked October 22: reroll (button, R / Y, doubling gold price), 5 banishes per run and the wandering merchant exist. Bugs found: banishing a mutation card does not stop that mutation being offered again, and the replacement offers after a banish drop mutations (reroll keeps them) and ignore the chest luck bonus. Exercise the real buttons with rendered captures.
- [ ] **24 · Frame cost at scale.** Measure rank-9 spells, statuses and shots in 100+ enemy crowds against the current baseline; add automatic effect-detail scaling for big crowds.
- [ ] **21 · Effect intensity settings.** Flashing, screen shake and particle density options, saved with the other settings.

### Phase B — co-op over the internet
- [ ] **Internet co-op without external apps.** Today co-op is ENet on UDP 29736 with LAN discovery; over the internet it needs port forwarding or a VPN app. User decision: invite codes plus automatic router port opening (UPnP), no hosted server. The host's router opens the port and the game shows a code holding the public address; friends paste the code. Players behind strict or carrier NAT cannot host this way; the game must say so clearly and suggest a friend hosts instead.
- [ ] **27 · Drop-in join mid-run** with a ping indicator on teammates' nameplates.
- [ ] **28 · Co-op revive and combo synergies** (for example one player's Void Orb feeding the other's Inferno Halo).

### Phase C — difficulty ("the game must be hard")
- [ ] **11 · Automated full-run playtests.** A bot plays complete runs with several builds and records realm reached, deaths, time-to-kill and the Baron fight. Proposed target for a competent bot: clears the first realm about 70% of the time, reaches the Baron about 25%, wins about 10%. Tune until met.
- [ ] **14 · Wave pacing.** Crowd density that rewards area builds while single-target builds stay viable, judged by the bot runs.
- [ ] **4 · Elite modifiers.** Shielded, splitting, teleporting and berserk elites with a clear badge; co-op synced.

### Phase D — run depth
- [ ] **1 · Weapon evolutions.** A max-rank weapon plus a matching card evolves it into a stronger form with its own look.
- [ ] **3 · Spell–mutation synergies.** Mutation triggers react to spells (for example Ember igniting inside Inferno Halo).
- [ ] **8 · Biome mechanics in fights.** Ice floors, spreading lava, toxic fog and similar, one per biome.

### Phase E — look and feel (Hades direction)
- [ ] **15 · Art bible and per-biome pass:** palette, lighting and ink weight per biome.
- [ ] **16 · Enemy death animations:** ink dissolve or shatter.
- [ ] **17 · Better creature and hero models.** User asked for models made here rather than bought or downloaded. Earlier procedural and Blender rebuilds were rejected as worse. Approach: pilot one hero and one creature with a slower, hand-directed Blender pipeline (blocked silhouette, subdivision, painted texture, ink outline) and compare side by side with the current models before any wider rollout.
- [ ] **18 · Spell sounds:** their own sounds and loops for the four spells.
- [ ] **19 · Camera zoom** when spells or crowds fill the screen.
- [ ] **20 · Telegraph consistency:** one warning language (shape, colour, timing) for every enemy attack.

### Older notes

Build 17 was a local checkpoint; Builds 18 and 19 are published (sections below). Real-fight balance and the early co-op desync investigation were open there; Phase C and the co-op items above carry them forward.

## New request — exit alpha (October 21)

Review and evidence: [alpha exit review](native/docs/alpha-exit-review-2026-10-21.md). Feature work is frozen until these are done.

- [x] Restore tooling: Git 2.55.0 and Node 24.20.0 installed with winget on October 21. The repository is owned by another Windows account SID, so agent commands pass `safe.directory=G:/game` through `GIT_CONFIG_COUNT`/`GIT_CONFIG_KEY_0`/`GIT_CONFIG_VALUE_0`. Global Git configuration is unchanged. Baseline `check` passes: `2026-10-21T07-53-14-784Z-check`.
- [ ] Co-op snapshot rewrite. **Reproduced** in `2026-10-21T07-53-34-849Z-shared-review` using the new crowd stage in `shared_review.gd`. With 100 host enemies, the world snapshot is 82,736 bytes, above the client's 60,000-byte receive limit. The client stays connected but receives 0 snapshots in 2 s and sees 0 of the 100 enemies. Failing checks: `crowd_all_visible`, `crowd_snapshots_flowing` (host) and `crowd_visible` (client); all other shared-review checks pass.
  - **Source fix (protocol `wildforge-shared-world-10`):**
    - Enemies travel as 20 packed floats per update (`ACTOR_STRIDE`).
    - Static identity is sent once, reliably: `need_actors` → `actors_info`, in batches of 40.
    - World snapshots are always unreliable-ordered with a sequence number; older ones are ignored.
    - Oversized messages log a warning instead of disappearing silently.
    - Clients no longer remove host-owned enemies at the boiling edge.
    - Review scripts now use `actor_descriptor()`.
  - **Verified:**
    - `2026-10-21T07-57-45-897Z-shared-review`: 100-enemy snapshot is 11,208 bytes; the client receives 21 snapshots and sees 100/100 enemies; all 92 host/client checks pass.
    - Stress run (`2026-10-21T07-59-32-157Z-shared-review-stress`): 24 snapshots, 100/100 visible.
    - `check` `2026-10-21T07-57-29-031Z-check`, `smoke` `2026-10-21T07-58-26-644Z-smoke` (118 assertions), `integration` `2026-10-21T07-58-36-658Z-integration` (78).
    - `surface-review`, `boss-review` and `red-moon-review` pass (`2026-10-21T08-00-46-578Z`, `08-01-04-341Z`, `08-01-16-702Z`).
  - **Already failing before this fix** (reproduced with the committed `coop.gd` in a temporary swap):
    - Stress `reconnect_state` (`2026-10-21T08-00-03-155Z-shared-review-stress`).
    - `journey-review` `final_victory` (`2026-10-21T08-02-03-084Z-journey-review`).
  - **Still open:**
    - Snapshots above the 1,392-byte MTU fragment (about 9 fragments at 100 enemies); Godot warns this raises loss. Measure under simulated packet loss, and split snapshots if needed.
  - **Committed and exported:**
    - Committed as `c28706b`. The unrelated uncommitted `game.gd` lobby-test hunk and the `README.txt` deletion were left unstaged.
    - Local development build: `.build-staging/agent-workflow/2026-10-21T08-03-45-186Z-build/Wildforge.exe`. `build-info.json` source is `c28706b…`; exported smoke passes 118 assertions. It still reports 1.1.3 / Build 17 metadata; it is not a release.
    - Exported two-process `2026-10-21T08-04-35-939Z-shared-review`: all 92 checks pass, and the crowd stage shows 100/100 enemies and 21 snapshots.
    - Exported stress `2026-10-21T08-04-54-427Z-shared-review-stress`: the crowd stage passes (24 snapshots); only the pre-existing `reconnect_state` fails.
- [ ] **User-reported bugs from earlier builds (October 21):**
  1. [x] In co-op, the other players' reward-choice window covers the local player's choices and stays on screen for the rest of the run.
     - **Reproduced** in rendered `2026-10-21T08-27-00-238Z-capture-ui`. After the real card press, a teammate's pick reopened the team panel over gameplay and the minimap (`ui-coop-after-choice.png`) and over the pause menu (`ui-coop-pause-after-choice.png`). Both new assertions failed.
     - **Cause:** `show_party_panel()` set `party_panel_open` and visibility on every teammate message. Nothing cleared the flag until the next run, and only the reward screen leaves room for the panel.
     - **Fix** in `0d87e44`: teammate messages refresh rows only. The panel shows only while this player's split reward screen is open; `open()`/`close()` clear it.
     - **Verified (source):** `2026-10-21T08-27-55-902Z-capture-ui` passes; after-choice, pause, level and chest captures inspected. Also smoke (118), integration (78) and `shared-review` `2026-10-21T08-28-56-702Z`.
     - **Verified (exported):** build `2026-10-21T08-29-30-082Z-build/Wildforge.exe` (source `0d87e44`, exported smoke 118). Rendered UI review at 1920×1080 in `.build-staging/exported-ui-1792571397536` passes; the same captures were inspected. Exported two-process `2026-10-21T08-30-29-556Z-shared-review` passes.
  2. [x] Reconnecting to a co-op run does not resynchronize the game and breaks UI elements.
     - **Reproduced:** `shared-review` now drops the guest twice: once mid-reward while the host opens a chest, and once while the host changes realm. Each drop holds the guest away for 1.5 s. Pre-fix runs `2026-10-21T08-11-15-836Z-shared-review` and `2026-10-21T08-11-39-931Z-shared-review-stress` show:
       - the reward screen visible but unusable (`offer_kept`);
       - the local nameplate destroyed;
       - the chest opened while away still visible;
       - the client stuck in the old realm with no snapshots;
       - the host frozen while the guest was away mid-reward (`host_runs_while_away`);
       - the original `reconnect_state` assertion failing under stress (as `drop2_state`).
     - **Causes:**
       - The rejoin path called `join_lan()`, whose `leave()` wiped session state.
       - The client ignored the realm in the reconnect welcome.
       - The client forced `playing` mode on rejoin.
       - Poses sent before the welcome reported `paused`.
       - `frozen()` counted disconnected members.
     - **Fix** in `4bad7d3`: transport-only rejoin; welcome carries realm and opened chests; restore the pre-drop mode; poses only after welcome; skip disconnected members in `frozen()`; remap the party reward entry to the new peer id.
     - **Verified (source):** `2026-10-21T08-15-05-170Z-shared-review` and two stress runs (`08-15-18-178Z`, `08-15-41-629Z`), all 104 checks each. Also `coop` full route `2026-10-21T08-16-52-140Z-coop`, smoke (118) and integration (78).
     - **Verified (exported):** build `2026-10-21T08-23-22-216Z-build/Wildforge.exe` (source `4bad7d3`, exported smoke 118). Exported `2026-10-21T08-23-48-034Z-shared-review` and `2026-10-21T08-24-00-670Z-shared-review-stress` pass.
     - **Test timing change:** the post-realm snapshot check now waits up to 5 s for 5 snapshots, because the host is still streaming the new realm. Before the fix it received none.
     - **Limits:**
       - Rejoin UI was checked headlessly: modal visible plus a real card press. No rendered screenshot yet.
       - A chest or level-up reward offered while the player was away is not re-offered.
  3. The final boss does not read as a bare, Baron-like demon. Doom's Baron of Hell is id Software's design, so make an original horned, goat-legged, bare-skinned demon in that spirit rather than a copy.
  3. [x] Final Baron rebuilt in `4234a03` and `d58262b`. The user meant Baron Harkonnen from the *Dune* film; an interim horned demon based on a "Doom" misreading was discarded. He is now a colossal, bald, pale, bare, floating original stylized figure built with the new Blender pipeline (`scripts/blender/`). See [baron-model.md](native/docs/baron-model.md). Verified with `2026-10-21T09-02-07-542Z-red-moon-review` and `2026-10-21T09-02-32-946Z-boss-review`. Not an actor likeness.
- [x] **Mutations** (`ff96ca0`): 102 run-changing upgrades.
  - Six biome strains × nine triggers make 54 core mutations, plus 18 strain rules, 15 hybrids and 15 wild cards. Taking one again levels it.
  - Level-ups offer three mutations; chests sometimes offer one. Offers no longer repeat an effect.
  - Drawn medallion icons: strain colour plus trigger glyph.
  - Verified with 13 integration checks (`2026-10-21T08-44-00-528Z-integration`) and the rendered `ui-mutation-offers.png` / `ui-mutation-hud.png` in `2026-10-21T08-44-27-068Z-capture-ui`.
  - **Not done:** balance and real playtest.
- [x] **Visual direction pass** (`fc6697e`): screen-space ink outlines over every surface, a vignette, a stronger saturated grade, a warm key light and glow. Six biomes inspected in `2026-10-21T08-55-09-325Z-biome-review`.
- [x] **Asset pipeline** (`d58262b`): Blender 5.2 (installed with winget) runs headless with `scripts/blender/forge.py`. Metaballs, voxel remesh, smoothing and decimation replace primitive blobs, with cavity shading baked into vertex colours.
- [x] **Second user bug batch (October 21)**, committed in `1b8ed75`:
  - The magnet now pulls every XP orb on the map once into a heap beside it, where the orbs merge into one giant orb (up to 2.6 m radius) that the player must walk over to collect. It then goes dark as spent. Gold and later drops are not pulled. Revised in `dae3c8e`. Exported build `2026-10-21T09-36-50-540Z-build` passes exported shared-review and hermes-review.
  - Magnet guards are tall cyan pylons labelled MAGNET GUARD.
  - Ordinary gun hits show damage numbers that rise from that weapon's slot icon; other damage keeps the bottom band.
  - Verified with `hermes-review`, `combat-review`, smoke, integration and shared-review. Exported build `2026-10-21T09-30-36-368Z-build` (source `5c53892`) passes exported smoke (118), shared-review and hermes-review.
- [x] Main menu uses the in-game window frame (`b64f598`). The Baron's steam is soft, fading vapour (`569a40a`). The journey-review route test is fixed (`c7f7c38`).
- [ ] **Better art assets.** Procedural attempts have hit their ceiling:
  - The Blender metaball Baron and a generated creature set both read as blobs and were rejected or reverted (`5c53892`). The Python floating Baron is current.
  - Real improvement needs authored art: a licensed or commissioned model (also required for any faithful *Dune*-film Baron likeness), an AI 3D generator account, or CC0 packs (Quaternius, Kenney), which need user approval to download.
- [ ] Local build `2026-10-21T09-03-39-561Z-build/Wildforge.exe` (source `d58262b`, exported smoke 118). Exported `2026-10-21T09-03-57-992Z-shared-review` passes all 104 checks, and exported `2026-10-21T09-04-16-670Z-release-review` passes; the 1080p HUD was inspected. It still reports 1.1.3 / Build 17 metadata and is not published.
- [x] Upgrade overhaul (user direction, October 21): 102 run-changing mutations (`ff96ca0`). Stat-card names cleaned up October 22:
  - 94 duplicate names covering 328 cards (twelve "Power", eleven "Health") came from the exporter naming each card after its stat label.
  - `scripts/export-native-data.mjs` now names each card after its own template plus a stat noun ("Detonator Edge", "Venom Fang", "Red Mist Thirst"). Skill twins of explicitly named cards become "… Drill", or "… Mastery" for weapon-power cards.
  - All 738 names are unique, and the exporter refuses duplicates. Ids, effects, kinds, families and all other catalog sections are unchanged (285 renamed).
  - Tier stays the per-offer rarity roll shown on each card; no fixed per-card tier was added, because that would stack a second rarity system and change balance.
  - Verified: new JS test (17/17 pass), check, smoke, integration and capture-ui; offer and icon-sheet captions inspected.
- [x] Mutation balance pass with measured damage (October 22). The new `mutation-balance` action (`mutation_balance.gd`) runs every mutation through the real game code against stationary dummies for 12 s at fixed trigger rates with a seeded RNG, in a crowd (12 enemies) and a sparse field (3). Results are % of the starting gun (23.8 dps); summarise them with `node scripts/summarise-mutation-balance.mjs`.
  - Harness fixes found while measuring: dummies are moved back home each run (knockback had pushed Comet's targets out of range for good), formation spawns are off, and the RNG is reseeded after setup. The `repeat` row (same kit three times) now matches exactly, 83.8 / 83.8 / 83.8.
  - Before, crowd: trigger averages 34–125%, strain averages 34–123% (Venom 123, Comet looked like 34). Thermal Shock reached 473% and Conductor 190%.
  - After, crowd (`2026-10-22T16-16-05-910Z-mutation-balance`): triggers 43–69%, strains 48–65% (Bloom also heals 0.35–0.95 HP/s). The strongest rule, hybrid and wild cards add 104–134%. Sparse fields favour Storm (55%, it chains to single targets) and penalise Comet (12%, an area strain).
  - Tuning: trigger powers rebalanced (dash/jump down, slam up, kill down); strain factors for Bloom, Venom (smaller radius, weaker cloud), Storm, Ember and Comet; Mastery is now +40% damage / 15% reach; Conductor +2 bolts; Shatter +50%; Wide Arc 25%; Thermal Shock detonation cut to a quarter. Card texts match.
  - Limitations: utility cards (cooldowns, dash, healing only, Last Stand at half health) measure 0 damage by design; this is not a survival or full-run measurement and is not playtested.
  - Verified: check, smoke and integration pass (the Shatter check now expects the +50% spec: 150 damage).
- [x] Unified UI theme for menu, HUD and modals; HUD regrouped into three clusters.
  - The menu gained the in-game window frame (`b64f598`).
  - Vitals top-left: one framed plate with the HP orb, HP, shield and armor, a gold/chest row, then buffs and harvest effects.
  - Map top-right: minimap with the run clock and biome name docked under it; the map stays frameless.
  - Loadout bottom-centre: a framed plate with skills/mutations, weapon slots and slam/turret status; level and XP sit at its ends above the full-width XP bar.
  - Verified: `capture-ui` HUD, potions, harvest, mutation and co-op captures inspected in `2026-10-22T15-14-17-324Z-capture-ui`; smoke, hermes, feedback, playfeel and combat reviews pass.
  - The "BARON MARKS UI RUNNER" text seen in captures is the test fixture's player name, not debug copy.
- [x] Stat icon system (`stat_glyphs.gd`): every one of the 738 upgrades now draws an octagonal medallion. The colour shows what the upgrade affects (offense, fire, poison, frost, storm, shadow, defense, healing, movement, coins, learning, turrets, garden), a large symbol shows the exact stat, and a corner badge shows the condition of conditional upgrades; weapon-specific upgrades show that weapon. Round mutation medallions stay distinct. Offer cards, the skill strip, the build menu and chest reels all use it. Verified: `capture-ui` asserts every upgrade resolves, and the `ui-upgrade-icons.png` contact sheet (one per stat and per condition), offers and chest reels were inspected in `2026-10-22T15-05-37-003Z-capture-ui`; smoke and integration pass.
- [x] Combat visual cues (user request, October 22: "Finish skills, guns, attacks impact animations. Guns bullet animations. Poison fire spread visuals."):
  - Shots (`shot_fx.gd`, `ink_tracer.gdshader`): every weapon archetype has a camera-facing ink tracer in its colour (long cyan rail beam, gold on crits), a muzzle flash, and in-flight puffs: flame embers, poison drips, frost glints, rocket smoke, ghost wisps and a fizzing bomb fuse. Co-op remote shots use the same look.
  - Impacts (`ink_star.gdshader`, `CombatInk.star`): per-weapon hits replace the shared yellow fleck: gun star, rail pierce streak, fire burst, toxic splat with a ground stain, frost ring, lightning forks, ghost ring, bubble pop and slashes, plus a gold star on crits. The hero gets a red hit mark (cyan when a shield absorbs it) facing the attacker. The meteor target is a gold danger ring instead of a flat disc.
  - Statuses (`status_fx.gd`, `status_mote.gdshader`): burning enemies carry inked flame tongues, poisoned ones rising lime bubbles, frozen ones an ice shell with glints (only for freezes over 0.5 s, so stuns stay clean), blinded ones dark motes. A flare marks the moment a status catches, so fire and poison visibly spread through a group hit by an area. Burning or poisoned enemies burst into embers or a toxic spray when they die. Visual only; no gameplay change.
  - Shot puffs and status flares have their own effect budgets, so they never block impact effects.
  - Verified: new `fx-review` contact sheets inspected in `2026-10-22T17-18-59-859Z-fx-review` and `2026-10-22T17-05-50-788Z-fx-review` (skills and hero hits). Check, smoke, integration, style-review and playfeel-review pass with no script or shader errors.
  - Performance (combat-review, 69 enemies, interleaved against a HEAD worktree in the same session): median frame 16.36 → 16.71 ms, p95 31.3 → 31.4 ms; final settings 16.26 / 28.13 ms. Run-to-run spread is ±3 ms at p95.
  - Known flaky check: combat-review `contact_warning_saved` failed 2 of about 10 runs. The test's attacker species depends on how many frames the preceding soak ran (700–848). The new code touches neither that RNG nor contact logic.
- [x] Screen-filling spells (user request, October 22: "skills like in Megabonk that have screen-filling effects"). Four new weapons in `skill_book.gd` take a weapon slot and cast on the weapon clock. Each cast is a large area that grows with rank and Size (1× at rank 1, about 2.3× at rank 9, capped at 4×), and extra shots add twisters or strikes:
  - **Twister Totem**: wandering ink twisters that drag enemies in and shred them.
  - **Void Orb**: a vortex that pulls a crowd together for 2.6 s, then collapses in a purple burst.
  - **Storm Crown**: a volley of sky lightning across nearby enemies.
  - **Inferno Halo**: a fire ring sweeping outward (7 m, about 16 m at rank 9) that burns everything it passes.
  - Each has a held focus model, a rendered icon, card art, a description, and Power/Mastery cards. Upgrade fit counts Size and Multishot as useful for spells; projectile and on-hit cards show "no current benefit". Co-op teammates see a teammate's cast at its size; only the caster deals damage. Spell hits merge into one running number at the weapon slot.
  - Balance (`2026-10-22T19-47-15-561Z-mutation-balance`, % of the gun at the same rank; crowd r1/r5, sparse r1/r5): Twister 132/274, 137/163; Void Orb 239/226, 61/62; Storm 200/352, 102/115; Inferno 323/193, 54/48. Existing references: rocket 202/116, lightning 191/139, gravity 336/168, meteor 368/237. Damage grows with the square root of weapon power, because rank already widens the area.
  - Verified: rendered `fx-spells` sheet (ranks 1 and 9, plus the collapse) inspected in `2026-10-22T19-42-04-345Z-fx-review`; check, smoke, integration and co-op shared-review pass with no errors. The content-count check now expects 746 cards and 73 weapons.
  - Not measured: frame cost of rank-9 spells in a large crowd; not playtested.
- [ ] Art direction (user direction, October 21): **Hades-like look** — painterly hand-drawn textures, heavy ink outlines, strong rim light, saturated accents against dark backgrounds, an isometric-leaning readable camera. Write the art bible, then do a per-biome pass.
- [ ] Real playtest and balance of one focused run.

## Hermes audit and eleven requested improvements

Source validation is recorded in [the repair report](native/docs/repair-1.1.2.md). Build 16 packages the repaired co-op, natural scenery and current continuation. [Release details](native/docs/release-build16.md). The older `09-51-35` candidate is superseded; it lacks these changes. **This checkpoint does not finish the remaining plan or the new art requests.**

- [x] Shared co-op XP/levels: one host-owned set of drops, collectible near any living player; mirrored progress, independent choices, duplicate client credits ignored.
- [x] Shared chests: host validates the request, charges the opener once, distributes choices and hides the chest for everyone. Both real processes resume after choosing.
- [x] 1. Remove square minimap border/background; preserve the centered, rotating map and markers.
- [x] 2. Show shield and armor values below HP, including zero values.
- [x] 3. Eclipse blood rain replaces ordinary weather; sky/fog still update, weather resumes afterward.
- [x] 4. Thin ordinary rain streaks.
- [x] 5. Boss motif and boss drums replace ordinary music layers; louder motif, Eclipse priority retained.
- [x] 6. Full-width bottom-edge XP meter with level and XP values; remove the separate level panel.
- [x] 7. Fourfold boss health, including the final boss override (360,000 solo HP). This is the requested multiplier, not proof of five-minute balance.
- [x] 8. Lithuanian boss speech: four-second minimum spacing, slower pitch and louder mix; retain all ten recordings.
- [x] 9. Retire broken large decorative halls; keep smaller scenery and landmarks.
- [x] 10. Hunt targets actually spawn 80–120 m away, survive distance cleanup and have screen arrows/minimap marks.
- [x] 11. Magnet with three combat-targetable sentries, health orbs, readable ranged attacks, host-approved activation and 120 m loot attraction. Clears between realms; absent safely in final arena.
- [x] Correct co-op critical damage types and prevent unrelated equipped weapons adding poison/fire to a gun hit.
- [x] Consistent version/build labels, launcher path and committed-build integrity checks; remove obsolete source ZIP from the export.

## Current continuation — natural scenery and encounters

The latest direction replaces the older request for massive buildings: **no decorative houses, castles, door/window facades or boxy platforms**. Use living, colourful nature with strong silhouettes and isolated glow; keep the ground subdued.

- [x] Validated six natural biome sets: emerald fairy trees and pink flowers, luminous mushrooms, pointed moon crystals, flowering willows, ember roots and astral coral. Tall, medium and low growths replace old scattered architectural meshes; large groves replace building landmarks.
- [x] Enemies go around natural props while retaining terrain climbing; real collision movement and wall/ceiling/ledge/slope reviews pass.
- [x] Verified distinct ranged firing distances, retreat and committed charges that can be dodged.
- [x] Inspected the single boss marker and updated colour pass in rendered gameplay.
- [x] Clean-source Build 16 candidate exported and checked at 720p/1080p, with exported two-process co-op tests. Delivery: `build/repair-1.1.2-build16/Wildforge.exe`; release manifest identifies the final source commit.

Evidence and limits: [natural-world continuation](native/docs/natural-world-build16.md). Now included in the Build 16 checkpoint.

## Remaining work — do not mark complete from this checkpoint

[Latest continuation evidence](native/docs/build16-continuation.md): last-run history fixed, crowd steering optimized, and controlled DPS measurements added. Full-fight balance and visual acceptance remain open.

1. **Real build balance:** measure weak/typical/strong weapon, turret, status, slam and flower builds against the final boss in solo and parties. The latest HP increase changes the DPS required for a five-minute fight. Automated contact/attack checks do not establish enjoyable duration or equal win rates.
2. [x] **Enemy and art polish:** reviewed original horror references, distinct silhouettes, legacy-asset replacement and all six biome encounter patterns. Added per-biome movement/telegraph regressions. Full-run pacing remains part of the open real-fight balance item. Evidence: [enemy and encounter review](native/docs/enemy-encounter-review.md).
3. [x] **Performance measurement:** comparable normal and late-Eclipse 125-enemy runs at the same seed/camera are recorded below. Frame and physics p95 tails remain high; this closes the measurement request, not a performance improvement claim. LAN correctness and a lower snapshot rate do not prove lower Internet latency or faster frame times.
4. [x] **Human feel/audio checks:** user accepted physical gamepad dash/deploy/menu feel and music/Lithuanian speech during a full battle on October 16. See [Build 17 work log](native/docs/build17-work.md). Preserve the accurate PARANOIA-derived Eclipse provenance.
- [x] **Broader UI/stat history:** cleaned up enemy-kill summary copy and empty state; reran persisted last-run/death, trimming, damage-source and stat-total checks. Reviewed the 1440×810 last-run, stat, recap and mobility-icon captures. Evidence: `2026-10-16T17-41-02-559Z-progression-review` and `2026-10-16T17-41-15-807Z-feedback-review` in [the work log](native/docs/build17-work.md).

## New request — Baron final boss

- [x] Replace the final boss with the bare stylized Baron fallback accepted by the user October 16. Asset searches and licensing limits are in [the asset report](native/docs/baron-model.md). No free photoreal Baron asset with verified reuse terms was found; do not label the accepted model photorealistic.
- [x] Make him immense: the ordinary camera looks upward to see his full silhouette. Retain very slow movement and deadly, clearly telegraphed ranged attacks. Source and exported Red Moon reviews pass.
- [x] Add visible steam venting from his body, with four emitting vents / 64 GPU particles total and readable attack warnings.
- [x] Verify silhouette, targeting, collision, co-op reconstruction and steam budget in the clean-commit staging export: `2026-10-16T18-56-41-946Z-build` and `2026-10-16T18-57-16-264Z-release-review`. User accepted the exported bare model on October 16.

## New request — finished ground and stronger colour

- [x] Ground-cover/art acceptance: clustered short grass, moss, biome-coloured low growth, wind where appropriate and mineral/ember fragments; no collisions; paths, lava, portal approaches and steep slopes excluded. User accepted the matched 720p/1080p six-biome pass. See [ground-art research](native/docs/ground-art-research.md).
- [x] Trial sparse low mist in marsh/cloud pockets only; compare against grass-only. Do not wash out saturated foliage, hide feet/loot or cover hazard circles. Use ember flecks and mineral/crystal fragments where grass would not fit.
- [x] Use chunked instancing and simple wind animation, distance limits and no foliage collision. Measure the same camera/seed before and after in normal combat and late Eclipse; the noisy p95/physics tails remain tracked under Performance and no improvement is claimed.
- [x] Review every biome from the gameplay camera at 720p/1080p: rich coloured midtones, separated shadows, hot highlights and vivid attacks. Record before/after frames. User accepted the refreshed views on October 16; see [matched-resolution evidence](native/docs/ground-art-research.md#october-16-matched-resolution-review).

Research and implementation choices: [ground-art research](native/docs/ground-art-research.md).

- [x] **Co-op reward choices:** show every player's complete level-up/chest option list in a compact companion window beside the normal chooser; highlight each selected reward, including “Kept weapons.” Verified with the two-process option/selection assertions in `2026-10-18T10-27-48-110Z-shared-review` and rendered level/chest/skip captures in `2026-10-18T10-28-37-245Z-capture-ui`.
- [x] **Co-op XP boosts and player names:** replicate each collector's evaluated `xpGain` (including skill and XP Juice modifiers) to the host so shared XP is credited once and level thresholds/leftover XP stay synchronized. Add a saved custom name in Play With Friends, show it in the lobby roster and above co-op heroes, and keep nameplates out of solo runs. Verified by `2026-10-18T10-36-13-263Z-shared-review` (two processes, Learn + XP Juice at 1.8×, shared level-up, no duplicate XP, custom names) and `2026-10-18T10-37-07-218Z-integration`; inspected `ui-coop.png` and `ui-coop-nameplate.png` in `2026-10-18T10-37-45-233Z-capture-ui`.

## New request — Baron arena, event, and phase voices

- [x] **Arena entrance:** darken the Red Moon, reveal 32 glowing ground fractures, and animate the Baron rising into the arena. Entrance, midpoint rise and fracture captures inspected in `2026-10-18T11-04-34-708Z-red-moon-review`.
- [x] **Arena hazards:** add ten clearly telegraphed, terrain-following ground eruptions, 2.6 seconds to dodge and 48 damage, repeating through the Baron encounter. Captured the marks and warning in `2026-10-18T11-04-34-708Z-red-moon-review`; attack and eruption assertions pass.
- [x] **Co-op warnings:** identify the Baron’s chosen player in one orange overhead `Name · TARGET` line and a HUD alert. Two-process host/client assertions pass in `2026-10-18T11-06-40-104Z-shared-review`; inspected `ui-coop-boss-target.png` from `2026-10-18T11-01-02-179Z-capture-ui`.
- [x] **Defeat event:** show the Baron fall, arena shockwave and gold fractures for 3.5 seconds, then begin Endless Eclipse. The rendered transition and assertions pass in `2026-10-18T11-04-34-708Z-red-moon-review`.
- [x] **Lithuanian phase speech:** generated eight new original `lt-LT-LeonasNeural` TTS curse clips for arrival and seven health thresholds. Keep the original ten random hit barks intact. The provenance file preserves their text and hashes; red-moon review streams all eight and crosses all seven phases, while the two-process review confirms the arrival and next phase lines reach the guest after the realm transition.

Validation: final `check` `2026-10-18T11-06-21-475Z-check`, `smoke` `2026-10-18T11-07-08-409Z-smoke` (118 assertions), `integration` `2026-10-18T11-07-23-558Z-integration`, and rendered `red-moon-review` `2026-10-18T11-04-34-708Z-red-moon-review` pass. Two-process co-op checks pass in `2026-10-18T11-06-40-104Z-shared-review`; `capture-ui` `2026-10-18T11-01-02-179Z-capture-ui` passes and its target cue was inspected. No build or upload: existing unrelated plan items remain open.

## New request — mastery, formations, co-op quality, and achievement cosmetics

The October 18 request selected weapon mastery, enemy formations, six-biome collection goals, co-op pings, ready checks, reconnects, teammate build inspection, expanded run recaps, and cosmetics earned through achievements. Each feature must increment a stable local achievement counter, and cosmetic rewards must be unlocked by those achievements rather than purchased.

- [x] **Weapon mastery:** persist each weapon's highest rank across runs; award mastery progress at rank 3 and unlock an earned nameplate style. Review rank-up and save/reload behavior.
- [x] **Enemy formations:** spawn readable wedge, line, and ring groups, preserve spacing/attacks, and count actual formation members defeated toward the formation achievement.
- [x] **Biome collection:** retain unique biome discoveries across runs and unlock the six-biome achievement only after all six.
- [x] **Co-op pings and ready checks:** keep contextual pings, require the host and all connected party members to be ready before start, and award progression only for co-op actions.
- [x] **Active-run reconnect:** preserve a dropped member for 40 seconds, authenticate a returning copy of the same saved profile, restore their host-side state, and end the client run only after the reconnect window fails.
- [x] **Shared build view:** show every party member's live weapon ranks and skills from network snapshots; award the achievement only after a complete teammate view.
- [x] **Run recap:** count completed reports opened; retain the existing damage, kills, and score breakdown.
- [x] **Achievement cosmetics:** grant eight co-op nameplate styles from their parent achievements, persist the unlocked collection, and let players choose among earned styles.
- [x] **Evidence:** focused progression, formation, UI, reconnect, and two-process assertions pass; inspected rendered party-build, cosmetic selection, co-op style, and run-report captures. Evidence: `2026-10-18T12-06-15-318Z-integration` (75 checks), `2026-10-18T12-06-50-518Z-progression-review`, `2026-10-18T12-07-27-730Z-shared-review`, and `2026-10-18T12-08-00-279Z-capture-ui`. Final source check `2026-10-18T12-07-43-711Z-check` and smoke `2026-10-18T12-02-07-341Z-smoke` (118 assertions) pass.

Achievement IDs added: `WF_WEAPON_MASTERY`, `WF_FORMATION_BREAKER`, `WF_BIOME_COLLECTOR`, `WF_PARTY_PINGS`, `WF_READY_PARTY`, `WF_WELCOME_BACK`, `WF_BUILD_SCOUT`, `WF_AFTER_ACTION`, and `WF_STYLE_COLLECTION`. Catalog and both native/community icon sets are generated from these definitions.

## Final task — early-game co-op desync (do last)

**User priority, October 15: tackle this only when it is the sole remaining active plan item.** Record it now; finish the other active work before starting this investigation. The separately deferred NodeTunnel work is not a prerequisite.

- [x] Reproduced a pause-state input defect on two source host/client processes. When the host paused, the client's authoritative pause flag became true while its local mode remained `playing`; dash and chest-interaction input still executed even though physics was frozen. The failing pre-fix run is `2026-10-18T10-08-53-417Z-shared-review`.
- [x] Added a client gameplay-input gate for the remotely paused state. Three repeated pause/resume cycles pass without dash or chest requests during the pause. Normal host/client review: `2026-10-18T10-10-55-862Z-shared-review`.
- [x] Repeated the same scenarios with a 20 Hz client and 150 ms simulated one-way packet delay. Shared XP/level, offers, chest payment/hiding, pause/resume, enemy warnings and Baron reconstruction all pass: `2026-10-18T10-15-03-377Z-shared-review-stress`.
- [ ] Verify sustained early-game play in two actual exported processes and inspect rendered behavior. The exact original major-desync symptom is not described in the retained evidence, and these source-process regressions do not establish that every reported desync is fixed. Keep this investigation open until exported validation and a symptom-matched reproduction are recorded.

## Deferred

**NodeTunnel online co-op:** no tunnel installation or service purchase now. Keep direct-IP/LAN working. Later assess bundled room codes, free-service terms and measured European latency/jitter/loss. The October 13 timeout did not establish a service outage.

## History

- [Build 16 audit and validation](native/docs/repair-1.1.2.md)
- [Historical plan through Build 15](native/docs/plan-history-through-build15.md) — includes superseded claims, not current acceptance evidence.
- [Build 12 / Red Moon](native/docs/release-1.1.0.md)
- [Build 1.0 visual rollout](native/docs/visual-rollout-1.0.0.md)
- [Older repair audit](native/docs/repair-audit-2026-10-12.md)

## Build 19 public release — October 22, 2026

- [x] Published GitHub Release [`build-19`](https://github.com/rytiss78/wildforge/releases/tag/build-19) at user request: "Wildforge 1.2.1 — Build 19". The annotated tag resolves to source commit `9dbee5df4c501cfca476f42053cd905dce40a4fe`.
  - Assets: `Wildforge-1.2.1-Windows.zip` (81,669,713 bytes) and `SHA256SUMS-1.2.1.txt`. The re-downloaded ZIP matches SHA-256 `7d22b8b3…6bbb22`, and its `build-info.json` reports 1.2.1 / Build 19 from `9dbee5d`.
  - The exported exe passed shared-review (104 checks), shared-review-stress and hermes-review (33 features): `2026-10-22T17-29-35-710Z-shared-review`, `2026-10-22T17-29-49-143Z-shared-review-stress` and `2026-10-22T17-30-11-973Z-hermes-review`, all run against it via `WILDFORGE_TEST_EXE`.
- Notes: [build19-release.md](native/docs/build19-release.md). README now points at Build 19.


- [x] Build `2026-10-22T17-26-45-819Z-build/Wildforge.exe`, version 1.2.1 / Build 19, source commit `9dbee5df4c501cfca476f42053cd905dce40a4fe`. It contains the mutation balance pass (`91bfa5e`) and the combat visual cues (`e66af4c`). Built from the committed `game.gd`; the uncommitted `lobby_synced` change in the working tree is not part of it.
  - Exported smoke passes 118 checks with no script errors. Exported `2026-10-22T17-27-25-702Z-release-review` passes; the exported combat capture shows the new gun tracer and muzzle flash.
  - Published as `build-19` (above).

## Build 18 public release — October 22, 2026

- [x] Published GitHub Release [`build-18`](https://github.com/rytiss78/wildforge/releases/tag/build-18) at user request: "Wildforge 1.2.0 — Build 18", source commit `1347ca08045ac6092960f274f851898b2b07ce58` (the tag resolves to it).
  - Assets: `Wildforge-1.2.0-Windows.zip` (81,626,463 bytes) and `SHA256SUMS-1.2.0.txt`. The re-downloaded ZIP matches SHA-256 `ada0ae3d…8b77b01`.
  - Built in `2026-10-21T09-38-57-882Z-build`; exported smoke passes 118 checks.
  - Exported shared-review, shared-review-stress, hermes-review and release-review pass.
- Notes: [build18-release.md](native/docs/build18-release.md). Known limits: mutation balance has not been playtested (a measured damage pass followed on October 22, after this release), and real-fight Baron balance is unverified.

## Build 17 public release — October 18, 2026

- [x] User approved publication with remaining limits documented.
- [x] Build 17 (1.1.3), source commit `2ccdb333d689d5e00f58bf49c38fe00c242e8b54`, exported and smoke-tested: 118 assertions passed. Build manifest and artifact SHA-256 values are retained in `.build-staging/agent-workflow/2026-10-18T12-20-25-412Z-build/`.
- [x] Uploaded the Windows ZIP and SHA-256 sums to GitHub Release `build-17`; README links the release and lists known limits.
- [ ] Real-fight Baron balance remains unverified. Full-fight duration/survival/win rates have not been established by stationary DPS estimates.
- [ ] The exported two-process full realm route completed. Host assertions passed; the client failed `lobby_hero_ready_synced`. The original reported early-game desync symptom remains unspecified, so the source pause fix is not claimed as a complete resolution.
- Rendered exported Play With Friends and gameplay/nameplate captures inspected at 1440×810. Two-process logs and capture evidence are in `.build-staging/agent-workflow/2026-10-18T12-20-25-412Z-build/`.
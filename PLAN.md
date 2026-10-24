# Wildforge — plan

October 23, 2026 · main branch · **Build 21 (1.4.0) is the latest public release** ([build-21](https://github.com/rytiss78/wildforge/releases/tag/build-21), source `3d51f3c`, zip SHA-256 `8605ba40…58cfafd`). It contains everything under "Since Build 19" and the Phase D and E items checked below (the model pilot is not in it).

Rules: [AGENTS.md](AGENTS.md) and the [Godot workflow](native/docs/godot-workflow.md). A checked item means the real entry point was exercised and the evidence is recorded. The full history up to this rewrite, with every evidence path, is in [plan-history-through-build19.md](native/docs/archive/plan-history-through-build19.md).

Evidence folders are under `.build-staging/agent-workflow/`. Run folders older than October 23 were moved to `G:\wildforge-archive\2026-10-23\agent-workflow\`. The latest run of each action and the Build 19 build folder were kept.

## The game today

- **Run:** three islands of six biomes each (island 2 is "Blighted Highlands", island 3 "Ashen Reach"). Each island has a 10-minute clock, two wardens and a portal. Then the Red Moon arena with the Baron, then an endless Eclipse.
- **Content:** 25 heroes, 73 weapons (including four screen-filling spells), 746 upgrade cards, 102 mutations, elite modifiers (shielded, splitting, blinking, berserk), hunts, supply beacons, magnet events, a merchant, rerolls and banishes, and 117 achievements with earned cosmetics.
- **Co-op:** up to four players over LAN, or over the internet with UPnP invite codes. Drop-in join, reconnect, shared XP and chests, and party combos (Crossfire, Overload). Protocol `wildforge-shared-world-12`.
- **Difficulty:** tuned with the playtest bot. The last 12-run batch had 58% clear island 1, 17% reach the Baron and 8% beat him (`2026-10-23T09-40-56-088Z-bot-playtest`). The target was about 70 / 25 / 10, kept deliberately hard.
- **Tooling:** `node scripts/agent-workflow.mjs` covers check, smoke, integration, about 30 rendered and two-process reviews, `bot-playtest` and `build`.

## Since Build 19 (released as Build 20)

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
- [x] **Build 20 (1.3.0).** Built locally after the user skipped the planned friend test of internet hosting (October 23).
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
- [x] **Published** GitHub release [`build-20`](https://github.com/rytiss78/wildforge/releases/tag/build-20) at the user's request: "Wildforge 1.3.0 — Build 20", marked Latest.
  - The annotated tag resolves to source commit `1789d63d38c972fc81aeb943ea1906ddb24a7f20`.
  - Assets: `Wildforge-1.3.0-Windows.zip` (81,875,888 bytes) and `SHA256SUMS-1.3.0.txt`.
  - The re-downloaded ZIP matches SHA-256 `01f88715…ff5744566`, and its `build-info.json` reports 1.3.0 / Build 20 from `1789d63`.
  - README, README.txt and HERMES.md now point at Build 20.

## Next: Phase D — run depth

- [x] **Weapon evolutions** (`weapon_evolution.gd`, October 23).
  - **Rule:** a weapon at rank 5 that has its catalyst card can evolve once. For example, Gun needs a Critical hit card and Rail needs Piercing.
  - **Offers:** the next chest, or weapon level-up, offers a gold "WEAPON EVOLUTION" card. Choosing it renames the weapon and multiplies its power (×1.4–2.0; spells ×2.25, which is 1.5× damage). It also adds the form's own modifiers: more shots, pierce, bounces, area or stun.
  - **Coverage:** every one of the 73 weapons has a form. The 25 base kinds have their own names (Hand Cannon, Star Lance, Event Horizon, Sun Halo…). Themed variants keep their name with the form's adjective, for example "Gilded Popcorn Repeater".
  - **Evolution key:** a full-rank weapon still missing its catalyst gets that card offered in chests and skill level-ups, marked "EVOLUTION KEY". Without this, an 8-run bot batch had 0 evolutions; with it, 4 evolutions in the 3 strongest runs, at minutes 15–26.
  - **Look:**
    - shots get a wider, gold-tinted trail, gold glints and a gold ring on impact;
    - melee, horn, wells, meteors and spells get a gold flare where they land;
    - the held weapon (and turret) wears a turning gold halo;
    - the HUD slot gets a gold frame with "EVOLVED", or a thinner one with "EVOLVE READY";
    - the build menu and slot tooltip show the recipe;
    - evolving plays a new sound with a WEAPON EVOLVED card, a sky beam, a ring and a star burst.
  - **Co-op:** each player gets only their own evolution and key cards from a shared chest pool. The evolved flag travels in the pose, so teammates see the halo.
  - **Verified:**
    - 23 integration checks (`2026-10-23T11-44-39-573Z-integration`). They cover the real chest purchase and reveal, a press of the EVOLVE card button, the catalyst and key-card path, banish refusal, one evolution per weapon, the evolved shots' pierce and trail, variant names, modifier merging and the co-op pool filter.
    - Disabling the offer injection makes 10 of them fail.
    - Rendered `capture-ui` (`2026-10-23T11-55-16-999Z`): `ui-evolution-key`, `ui-evolution-offer` and `ui-evolution-hud` inspected. The `fx-evolved` sheet (`2026-10-23T11-32-31-274Z-fx-review`) shows plain and evolved shots side by side for gun, rail, flame and rocket, plus the halo close-up.
    - Bot batch: `2026-10-23T11-45-15-376Z-bot-playtest`.
    - Also passing with 0 errors: check, smoke, shared-review, coop-dropin, combat, hunt, journey and playfeel reviews, and the full `coop` route (`2026-10-23T11-57-50-797Z`).
  - **Limits:**
    - Remote co-op shot visuals are not gilded; teammates see the halo only.
    - The evolved damage was not measured separately with the damage-dummy harness; the bot batch is too small to say whether it changes win rates (3 of 8 reached the Baron, against 1 of 8 before, on the same seeds).
    - Not playtested by a person.
- [x] **Spell–mutation synergies** (`spell_synergy.gd`, October 23).
  - **Found first:** spell damage never fired "on hit" mutations. Spells call `hurt_enemy` directly, so Ember Edge did nothing inside Inferno Halo.
  - **Spell hits as triggers:** spell hits now count as weapon hits for "on hit" mutations, at most once per spell damage tick (4 per second, like a fast gun). Unthrottled, a spell hitting a crowd pinned those mutations at their cooldown.
  - **Eight named synergies,** two per spell. Each is active while the hero carries the matching strain (any mutation of it):
    - **Firestorm** (Inferno Halo + Ember): burns twice as hot and ends in a ring of Ember eruptions.
    - **Phoenix Ring** (Inferno Halo + Bloom): 0.3 healing per enemy burned, up to 3 per cast.
    - **Supercell** (Storm Crown + Storm): strikes fork Storm lightning.
    - **Hailstorm** (Storm Crown + Frost): strikes freeze enemies for 0.8 s.
    - **Collapsar** (Void Orb + Comet): 50% wider collapse that hurls the crowd.
    - **Plague Well** (Void Orb + Venom): a poison cloud where it collapses.
    - **Fire Whirl** (Twister Totem + Ember): twisters set held enemies on fire.
    - **Toxic Cyclone** (Twister Totem + Venom): poison clouds along the path.
  - Synergy damage scales like the strain's own effects.
  - **Where players see them:**
    - the first activation each run shows a "SPELL SYNERGY · NAME" card;
    - mutation cards name the synergy they would switch on with the equipped spells, and spell cards name the ones they would switch on with the carried strains;
    - the build menu has a SPELL SYNERGIES section;
    - the spell's slot tooltip lists its active synergies.
  - **Measured** (`2026-10-23T12-23-51-055Z-mutation-balance`, 12-dummy crowd, spells at rank 5). Damage each synergy adds beyond the spell and the strain measured separately:
    - Firestorm +65% of the spell;
    - Collapsar +54%;
    - Plague Well +54%;
    - Fire Whirl +43%;
    - Toxic Cyclone +42%;
    - Supercell +24%;
    - Hailstorm adds control, not damage;
    - Phoenix Ring heals 2.5 HP/s.
  - **Tuning the measurement caught:**
    - Firestorm first compounded the burn on each recast (+14,000 dps). It now sets a fixed burn.
    - Plague Well's cloud was 11 times Venom's own cloud (+218%).
    - Phoenix Ring healed 6 HP/s.
    - Unthrottled spell hits let one Ember Edge nearly double Void Orb's damage.
  - **Verified:**
    - 13 integration checks with real casts against controls without the strain (`2026-10-23T12-25-06-160Z-integration`). The halo alone already ignites, so Firestorm is checked by burn strength. Disabling the synergies and the spell-hit trigger makes 10 of them fail.
    - The `fx-synergies` sheet (`2026-10-23T12-26-01-124Z-fx-review`) shows one cell per synergy with its card, all inspected.
    - Check, smoke, capture-ui, shared-review, coop-dropin, combat and playfeel reviews pass with 0 errors.
    - `crowd-spells` (no mutations) runs at median 34 ms / p95 51 ms, no slower than Phase A.
  - **Limits:**
    - Teammates see a teammate's spell but not its synergy effects. Damage stays on the caster, as before.
    - Supercell's forks and Phoenix Ring's healing are subtle on screen.
    - Frame cost with a full mutation kit in a 125-enemy crowd was not measured.
    - Not playtested by a person.
- [x] **Biome mechanics in fights** (`biome_mechanics.gd`, October 23). One per biome. Each appears near the hero after an island's first 40 s, is telegraphed, and affects enemies too:
  - **Clover Woods · clover rings:** stand inside to heal and shed burn and poison.
  - **Puffcap Marsh · spore fog:** a drifting cloud that poisons heroes and enemies inside.
  - **Moon Craters · ice floors:** heroes slide (momentum kept, slow grip); enemies are slowed and slip.
  - **Cloudwilds · wind gusts:** a streak-telegraphed gust shoves heroes and enemies.
  - **Candy Hell · lava vents:** erupt into a pool that spreads from 1 m to 4.5 m and burns everyone. The pool is a bright yellow with a dark crust, apart from the orange rivers.
  - **Starfall Space · gravity rifts:** pull everything in, then implode on enemies; the centre hurts the hero.
  - **Presentation:** each zone has a bright edge ring. The first event of each kind in a run explains itself.
  - **Co-op:** the host rolls events near every member and broadcasts them (`biome_event`). Each player applies the effect to their own hero; only the host moves, statuses and damages enemies.
  - **Bot:** the playtest bot walks out of spore fog and lava pools.
  - **Not on the Red Moon.**
  - **Verified:**
    - 10 integration checks (`2026-10-23T15-25-44-236Z-integration`): each mechanic through the real tick and the hero's real movement step against a control outside the zone, plus scheduling, other-realm events, clearing and Red Moon exclusion. Switching off the tick and movement hook fails 7 of them.
    - The rendered `biome-review` (`2026-10-23T13-56-24-726Z`) adds one `biome-mechanic-N` capture per biome. All six were inspected. The first version's clover ring, gust streaks and lava pool did not read, and were made bolder. The lava pool was also sinking into slopes because it was scaled; it is now rebuilt as it spreads.
    - Also passing with 0 errors: check, smoke, capture-ui, the Red Moon, feature, journey and island reviews, shared-review, coop-dropin, crowd-review and the full `coop` route (`2026-10-23T15-28-03-562Z`).
- [x] **Phase D difficulty retune** (12-bot batches on the Phase C seeds 801–812):
  - **With evolutions, synergies and biome mechanics** (`2026-10-23T13-57-53-807Z`): 67% clear island 1, 42% reach the Baron, 25% beat him. The Phase C baseline was 58 / 17 / 8.
  - **Biome mechanics off** (`14-13-05-735Z`): 83 / 33 / 25. The mechanics make island 1 harder; the easier late game comes from evolutions.
  - **Changes:**
    - Evolution power bonuses are cut by 30% (Gun +50% → +35%, spells ×2.25 → ×1.96).
    - The Baron's health multiplier goes from 4 to 6 (360,000 → 540,000 solo). Evolved builds had killed him in 2–12 minutes, against 17 before.
    - A tougher island step (+0.36) was tried and reverted: 75 / 8 / 0 (`14-33-38-680Z`).
  - **Final** (`2026-10-23T15-03-41-146Z`): 75 / 42 / 25, with Baron fights of 6–8 minutes.
  - **Open:**
    - The late game is still easier than the target (about 70 / 25 / 10).
    - Batch-to-batch noise is large: reaching the Baron moved 42 → 8 → 33 → 42% across similar settings.
    - The next retune should use larger batches (24+ runs) before changing numbers again.
  - The reviews that hard-coded 360,000 now use the arena's formula.

## Then: Phase E — look and feel (Hades direction)

- [x] **Art bible and per-biome pass** (October 23).
  - **Art bible:** [art-direction.md](native/docs/art-direction.md) is rewritten as version 1.0. It covers the pillars, a value hierarchy, a per-biome table (ground, key, fill, fog, ink, accents), the colour language, ink rules, model rules, the readability checks and how to verify a look change. The old 0.1 storybook baseline predated the Hades direction.
  - **Per-biome pass:** the new `biome_look.gd` gives each biome its own key light (colour, strength, angle), ambient fill, fog reach and ink colour, thickness, strength and vignette. Values ease across borders, islands 2 and 3 blend 60% of their grade on top, and the Red Moon keeps its original lighting.
  - **Ground and horizons:** ground bases and horizons for Puffcap Marsh, Moon Craters, Cloudwilds, Candy Hell and Starfall Space are darker, so the ground stays the quietest layer.
  - **Results:**
    - Candy Hell's lava now outshines its ground.
    - Moon Craters went from washed-out blue-grey to dark navy with pale crystals and long shadows. A first try with a blue key light turned the whole biome saturated blue, so the key is now near-neutral.
    - Cloudwilds' ground moved from pale cream (about 165) to a mid grey-green (about 125).
  - **Verified:**
    - before/after sheet `.build-staging/agent-workflow/biome-pass-before-after.png` (before `16-13-27-590Z`, after `16-31-19-144Z-biome-review`);
    - island sheet `16-31-38-940Z-island-review`;
    - check, smoke, integration, the Red Moon and style reviews pass with 0 errors.
  - **Not yet accepted by the user.** The October 16 refreshed views had been accepted, so this pass needs their look.
- [x] **Enemy death animations** (`death_fx.gd`, October 23). The killing blow picks the style:
  - **Ink dissolve** (most kills): the painted enemy shader has a new `dissolve` uniform. The body erodes top-down with a dark ink edge and sinks into a soft round ink blot while wisps rise. The outline pass is dropped so no ghost remains. Bosses take 1.4 s.
  - **Shatter** (frost, crits, explosions, slams, meteors, or a frozen enemy): the body bursts into tumbling shards in its own colour; frost shards are pale ice.
  - Visual only, shard count capped, and it follows the Particles setting. Co-op clients use the same path.
  - **Verified:**
    - the `fx-deaths` sheet (`2026-10-23T15-57-06-714Z-fx-review`) shows hit, poison, frost and crit kills, early and late, cropped on the victim;
    - review checks confirm each style, the shader dissolve and full clean-up;
    - `crowd-review` median 11.7 / p95 15.9 ms (Phase A: 14.0 / 18.5).
  - **The review needed fixes before it showed anything:**
    - the victims were still burning from the synergy section;
    - the crop used viewport units on a smaller image;
    - the first blot was a hard square;
    - the first frost shards rendered brown.
- [x] **Damage numbers at the XP bar** (user report, October 23: "dmage numer still dont rise from the exp bar"). Non-gun numbers started 210 px above the bottom; they now start on the XP bar at the bottom edge and rise 260 px, across the full width. Gun numbers still rise from their weapon's slot. The combat-review contract changed with it (start within the bottom 60 px; the spec change is noted in the test). Verified in `2026-10-23T16-01-21-533Z-capture-ui` (`ui-damage-text`) and `16-01-36-427Z-combat-review`.
- [x] **Biome events stay out of reviews:** automated reviews switch ambient spawns off with a huge spawn clock, and biome events now follow it. A clover ring had appeared in an effects capture.
- [x] **Model pilot (dropped for now)** (`scripts/blender/pilot.py`, not used by the game). It rebuilds Count Duck and the Briar Beetle with the same node names, pivots, hand sockets and GlassCore health orb as the shipped models. The GLBs are generated outside the game's assets until the pilot wins a side-by-side.
  - **Version 1** (subdivision cages): rounder but weaker than the faceted originals. A bandit-like mask, loaf arms and an egg torso hid the orb; the beetle shells read as bullets.
  - **Version 2** (planes and points, subdivision only on corners): a better beetle (wing plates over a dark body, thorns, berries) but messy legs. The duck gained a vampire collar, scowl mask, visible orb and scalloped cape, but its bill reads as a thin line from the front.
  - **In-game comparison** (October 23): the new `model-review` action builds the pilot in Blender into its run folder and renders it beside the shipped models through `StyleModel`. `StyleModel.setup_scene` adopts any glTF scene with the shipped node names. The sheet shows the gameplay camera (duck from behind, beetle trio ahead) and close-ups.
  - **Pipeline fixes the comparison found:**
    - the pilot orb's node sat at the body origin, so the orb shader drew it empty;
    - parts with special surface names (`metal`, `boot`, `rim`…) rendered white because Blender exports vertex-painted base colour as white.
  - **Version 3:** thick ridged bill, fanned beetle legs, a cape with a shoulder V notch, scalloped hem and gold chain (`2026-10-23T16-52-12-518Z-model-review`).
  - **Verdict (assistant):**
    - The beetle pilot is a plausible improvement: wing plates over a dark body, thorns, berries, legs that read as six.
    - The duck pilot does not beat the shipped Count Duck. From behind (the view players see all game) its cape is still rectangular next to the current flared, pointed one, and the current head and gold arms read stronger.
  - **Decision (user, October 23): keep the current models; the pilot is dropped for now.** `pilot.py` and `model-review` stay in the repository for a later attempt; nothing from the pilot is in the game.
- [ ] **Better hero and creature models**, made in-house. Earlier procedural and Blender metaball rebuilds read as blobs and were rejected. Pilot one hero and one creature with a slower, hand-directed Blender pipeline (blocked silhouette, subdivision, painted texture, ink outline). Compare them side by side with the current models before any wider rollout.
- [x] **Spell sounds** (`spell_audio.gd`, October 23). Synthesized, no samples. Each spell has its own cast:
  - Twister Totem: a rising whoosh.
  - Void Orb: descending suction, plus a boom on collapse.
  - Storm Crown: a thunder crack and rolling rumble, plus a crack per strike.
  - Inferno Halo: a fire whoomp with roar and crackle.
  - Twisters and orbs carry seamless 3D loops (wind; a deep hum) that fade with the spell.
  - Before this, the spells borrowed the dash, gravity, lightning and nova sounds.
  - **Verified:** integration checks confirm each spell uses its own sound, every sound peaks between 0.15 and 0.96 (audible, unclipped) and both loops loop (`2026-10-23T16-02-24-064Z-integration`); fx-review casts all spells with 0 errors. Not yet heard by a person.
- [x] **Camera zoom** (October 23). A `fight_zoom` factor on top of the player's own camera distance eases out by up to 35%:
  - for a crowd within 16 m (more than 10 enemies, full effect at 50);
  - for active screen-filling spells;
  - for a nearby boss (not in the Red Moon arena, which has its own camera).
  - It eases in again more slowly, counts four times a second, and resets with each run and island. The player's distance setting and the reviews' camera checks are untouched.
  - **Verified:** an integration check (40-enemy crowd zooms out past 1.15, back below 1.03 once they are gone; `2026-10-23T16-10-57-897Z-integration`) and the `fx-zoom` before/after sheet (`16-09-35-247Z-fx-review`).
- [x] **Telegraph consistency** (October 23). One warning language:
  - **Colour:** every enemy attack's ground mark now has a danger-red ink (`DangerMark.DANGER`), with the attack's own colour kept only as the inner fill. The hero's own strikes stay gold; harmless hazards (ice floors, wind gusts) are pale blue.
  - **Timing:** every ground warning lasts at least 0.8 s, and the sweep closes in. The last 0.25 s flashes white ("impact now"), for marks, the melee bite ring (now the same red) and the new charge lanes.
  - **Charge lanes:** charges used to show only angry eyebrows during their 0.8 s windup. They now paint their lane on the ground in danger red. The review found lanes left behind when a freeze or blind interrupted the windup, or the charger died; lanes now clear on every path.
  - **Verified:** the `fx-telegraphs` sheet (`2026-10-23T16-09-35-247Z-fx-review`) shows four styles in red with their own fills, the final flash, a charge lane and a bite ring, all inspected. Review checks cover the red ink, flash timing, lane creation and lane clean-up.
  - **Regression runs:** check, smoke, integration, the boss, Red Moon, style, combat, playfeel and biome reviews, and coop-dropin pass with 0 errors.
  - **Known flaky:** `shared-review` failed once (`16-12-59-888Z`). After the island-change reconnect the guest got 4 of the required 5 snapshots within 5 s; three re-runs passed with 5. This is timing under load and has not been changed by this work. Left open, not loosened.

## Co-op big-fight desync (user report, October 23, Build 21)

- **Report:** in big fights over the internet the guest took damage but saw no enemies, the host saw the guest frozen in a crowd, they sometimes recovered, the guest sometimes had to be revived, and once a revive produced a second copy of the guest.
- **Measured** (`net_size_checks.gd`; 125 enemies, 300 XP orbs, a full build):
  - The world snapshot was **48,916 bytes**, near the 60,000-byte drop limit and about 35 network fragments, so over a lossy link most snapshots were lost. XP orbs, sent as dictionaries, took 36,008 of those bytes.
  - The guest's pose was **3,596 bytes** (stats took 2,948). That is over the 1,000-byte unreliable limit, so it went out reliably ten times a second and stalled behind resends.
- **Fixes** (protocol `wildforge-shared-world-13`):
  - XP orbs travel packed (six floats each), at most the 200 nearest any hero. The client matches them through an index instead of a search per orb.
  - Stats travel apart from the pose, as reliable changed values only, at most every 0.5 s, and in full after a welcome.
  - Poses, like world snapshots, stay unreliable at any size.
  - **Duplicate copies of a player:**
    - A returning player is matched by profile token even while the host still believes the old connection is alive; the stale connection and its avatar are dropped.
    - Late poses from a dropped connection no longer rebuild its avatar. Under lag, such poses left ghost avatars; the stress run found two.
  - **Engine errors after a dead link:** the client's link checks and ping read the actual connection state, which removes the errors after a silent drop.
- **Results:** snapshot **17,716 bytes**, pose **632 bytes**.
- **Verified:**
  - integration (`net_world_size`, `net_pose_unreliable`);
  - shared-review with a new silent-drop rejoin (the guest's link dies without notice) and `reconnect_no_duplicate`;
  - shared-review-stress, coop-dropin and the full `coop` route (`2026-10-23T20-37-43-363Z`), all with 0 errors.
- **Not verified:** a real internet session with packet loss; the tests run on one machine. Snapshots were later split into independent packets (see Open issues: split world snapshots).

## Weapon damage review (user report, October 24)

- **Report:** a friend saw one weapon always show "1" damage, even after ranking it up. The user also asked that hero-specific weapons can drop for other heroes.
- **New review:** `weapon-review` (`weapon_review.gd`) runs every weapon through the real combat path at ranks 1 and 5 and reads the number shown at its slot.
- **Hero weapons:** all already sit in the shared drop pool. The review checks that each hero's starting weapon is offered in 4,000 weapon rolls.
- **Fixes:**
  - Gravity wells (Gravity Jar, Pocket Black Hole, Teacup Singularity) dealt damage every frame. Each slice was a fraction of a point, shown as "1", and on a co-op guest each slice was one hit message per enemy. Wells now tick four times a second with the same total.
  - Gravity and meteor damage was not on the list of causes that show a number; neither was flower blooms. All three now show.
  - Flowers bloomed at the power they had when planted, for their full 22 s life, so a rank-up only showed once the old trail withered. Blooms now use the weapon's current rank.
  - The burn or poison of a fire or poison weapon, and flower pollen, were flat (10 / 9 / 4). They now grow with the square root of the weapon's power, like spells.
  - Hybrid mutation infusions hit for a flat 1. They now scale like their strain.
  - Rolling bombs (Bomb, Marble Mine, Bottle Barrage, Pumpkin Fuse) aimed their hit test at an enemy's middle while rolling on the ground, so they passed under tall enemies and went off only at the end of the fuse. They now test at bomb height.
  - The host's co-op cause list keeps a guest's gravity and bloom damage as such, instead of plain hits.
  - **Volley variants** (`scripts/data/expansion.js volleyShare`): the variants that fire extra projectiles or meteors kept the damage per shot of their base weapon, so a volley dealt 2–7x the base weapon (Marble Rain 6.7x Meteor, Hail Hose 4x Ice Gun, Confetti Cannon 4x Shotgun). Damage per shot is now split so a full volley is about 1.5x a base volley (Shotgun counts its own three pellets). Measured afterwards: 1.4–1.7x, Marble Rain 2.3x (its meteors also spread over more ground). Affected: Popcorn Repeater, Confetti Cannon, Hail Hose, Knitting Needles, Bottle Rockets, Button Barrage, Trident, Foam Party, Marble Rain, Staple Sentry. Bounce and pierce variants are unchanged: the dummy ring favours them, which says little about real crowds.
- **Verified:** `weapon-review` passed on two runs (`2026-10-24T13-37-46-311Z`); every weapon grows from rank 1 to rank 5. check, integration, smoke, shared-review and coop-dropin passed with no script errors.
- **Limits:** the review uses pinned dummies, not moving crowds. Spells grow about 1.5x by rank 5 by design (square root of power). The friend's weapon was not named, so the fix covers every cause found, not a confirmed single weapon.

## Reward offers (user reports, October 24)

- **"Level-up sometimes offers just one item":** in co-op, shared offers hid every weapon a full loadout (3 weapons) could not hold. A weapon level (level 2, then every third level) then showed only the rank-up of a held weapon. All cards now stay, and a new weapon opens the swap menu, as in solo. A swap is now reported to the party panel too.
- **"Every player gets the same drop" in co-op:** the host rolled one set of cards for everyone. Level-ups and chests are still shared events, but each guest now rolls its own cards from its own loadout and luck. Event chests keep their minimum rarity, because the chest message now says it is an event chest.
- **"All runs end up with the same weapons":** the first weapon offer was already varied (72 of 73 weapons over 80 runs, the commonest 12 times in 400 cards), so the sameness came from the shared co-op cards and from habit. The profile now keeps the last runs' weapons (`recentWeapons`, up to 8, not the hero's own weapon). Those sit out the weapon offers at levels 2, 3 and 6, including rerolls.
- **Verified:**
  - weapon-review checks `early_diverse`, `recent_sit_out` (0 of 200 cards) and `full_loadout_cards` (5).
  - shared-review checks `own_pool` and `own_chest_pool`. These replace `same_pool` and `shared_chest_pool`, which required the host's cards; the spec changed on request.
  - check, integration, smoke, coop-dropin and shared-review-stress passed with no script errors.
- **Limits:** the full-loadout case is checked by calling the offer directly, not by pressing through a co-op swap. The swap menu itself is the solo path.

## Block Drop minigame (user request, October 24)

- A small falling-blocks game for waiting (`block_drop.gd`). It is not named after the trademarked original. Controls: arrows or WASD, Space hard drop, Z rotate back. On a controller: D-pad, A rotate, Y or D-pad up hard drop.
- **Where it appears:**
  - the pause menu's **BLOCK DROP** button;
  - automatically, under the "party paused" banner, while a co-op friend chooses a reward and this player is done.
- **Saving:** one board for the session. It is saved to the profile (`blockDrop`) whenever it leaves the screen, and continues at the next pause, after a restart too.
- **Audio:** game music pauses while it is open. It has its own chiptune arrangement of "Korobeiniki" (public-domain folk song, 1861) and seven effects, all generated by `scripts/make-block-drop-audio.py`.
- **Verified:**
  - `block-drop-review`: 20 checks through the real Esc, button and key path; captures inspected.
  - capture-ui pause menu inspected.
  - check, smoke, integration, shared-review and coop-dropin passed, with no leaks at exit.
- **Party choices beside the board:** in co-op, the team options panel (each player's cards, ✓ on a pick) shows while Block Drop is open, both in the menu and the waiting overlay. The board moves left to make room.
- **Space no longer picks reward cards** (friends spamming Space as hard drop picked a random card). For 0.8 s after an offer opens, Enter and controller A are ignored too. Number keys and the mouse pick at once. block-drop-review checks `space_guard`, `space_never_picks` and `number_picks`. The smoke test's controller-accept check now presses after that moment.
- **Short videos beside the board** (`shorts_panel.gd`, `assets/shorts/`): **TikTok by default**, with a button to switch to YouTube Shorts and back, plus a VIDEOS: ON/OFF button.
  - **Plugin:** godot_wry v1.0.2 (MIT; the user approved the download). Only its Windows DLL and the license are installed, in `addons/godot_wry`. It is a native Edge WebView2 window laid over the game, so it follows the panel's on-screen rectangle (including the 1920x1080 stretch) and hides when the panel leaves the screen.
  - **Short and fast:** each video plays at most 15 s, videos over 60 s are skipped, looping is off, and the next starts at once. The volume is 35% of the music volume.
  - **TikTok:** the panel reads the video links on a TikTok hashtag page while hidden, from the user's tag list (#phonk, #gymtok, #meme, #gravel, #remco, #techhouse, #nature, #run, #rally, #parrot, #core, #cuterat, #punk, #puppy, #mindset, #uptempo, #rats), so the page's cookie banner is never shown or answered. It plays them in TikTok's official embed player (`tiktok.html`), which shows no banner.
  - **YouTube:** shorts come from the public feeds of The Dodo, The Pet Collective, Good News Network and Animal Planet. Nat Geo Wild and BBC Earth are left out (predators hunting). They play through YouTube's IFrame API on youtube-nocookie.com (`player.html`, loaded from res:// so the embed gets the referrer it requires; error 153 otherwise). youtube.com pages themselves open on a consent wall in the EU.
  - **Limits:** hashtags are chosen by uploaders, so TikTok content is steered toward upbeat, not vetted. TikTok and YouTube may change their pages or embed rules.
  - **Bigger:** the Block Drop screen now fills nearly the whole screen (the left 65% in co-op, beside the party panel). The board and video zoom to fit (about 1.45x at 1080p), and the co-op overlay grows to the free space (about 1.3x).
  - **Verified:**
    - shorts-review, 21 checks: TikTok default, auto-scroll within 15 s, the switch button to YouTube and back, the end of a video loading the next, low volume, loop off, BACK hides.
    - Desktop captures of both sources and of the co-op overlay inspected.
    - block-drop-review, smoke, integration, shared-review and coop-dropin passed.
- **Not verified:** the exported build with the plugin.
- **Not verified:** how the music and effects sound (generated, not listened to), and the overlay in a real two-machine session.

## Difficulty retune (October 24, bot-playtest)

- **Target:** about 70% clear island 1, 25% reach the Baron, 10% beat him.
- **Results** (24 runs each, 12 heroes and styles, 55 simulated minutes):

| Setting | Clear island 1 | Reach the Baron | Beat the Baron | Evidence |
|---|---|---|---|---|
| Island step 0.3 (before) | 67% | 50% | 33% | batches `2026-10-23T21-18-09-505Z`, `2026-10-24T13-09-47-181Z` |
| Island step 0.38 | 79% | 46% | 25% | `2026-10-24T13-41-23-297Z`, `14-01-46-922Z` |
| Island step 0.45, Baron health x7.5, volley-damage fix | 71% | 42% | 25% | `2026-10-24T14-16-36-566Z`, `14-36-09-552Z` |

- **Now in the game:** island step 0.45 and Baron health x7.5 (both runs at 0.38 and later also had the weapon-damage fixes).
- **Effect so far:** island 1 is on target. Baron fights won by bots now last 9–16 minutes instead of 5–10.
- **Still open:** islands 2–3 and the Baron remain too easy. 6 of the 10 bots that reached him won.
- **Main killers:** enemy meteor hazards account for 6 of 13 deaths on islands 1–2. They are telegraphed, so they are left as they are.
- **Step 0.55 tried and dropped:** over 48 runs it gave 81% / 40% / 27%, against 71% / 42% / 25% at 0.45. That is no measurable difference, so the game stays at 0.45.
  - **Evidence:** `2026-10-24T15-02-19-270Z`, `15-18-44-994Z`, and the paired reruns `15-33-28-564Z`, `15-42-11-694Z`.
  - **Bot runs do not repeat from their seed:** the same hero and seed went from beating the Baron to dying in the first minute, and island 1 outcomes changed in 13 of 24 runs at an unchanged island 1. Paired seeds therefore cannot reduce the noise, and 24-run batches swing by about 20 points.
  - **Next:** a step change is not a lever this noise can measure. The Baron's own damage and patterns, judged by human playtest or batches of 48+ runs, is the next thing to try.

## Open issues and limits

- **Internet port opening failed on the user's router** (October 23): the "router did not allow automatic port opening" message appeared. UPnP was on in the modem, but no mapping was created. That message covered both "no router answered" and "router refused".
  - **Reworked** (`coop.gd upnp_work`):
    - three search styles with longer waits;
    - every gateway found is tried, not only the first;
    - a permanent mapping first, then a timed one;
    - alternate outside ports 29746 and 29756 on a mapping conflict, with the invite code carrying the port that worked.
  - **Diagnostics:** the panel now names the failing step and the router's own answer, and every attempt is logged to `coop-upnp.log`. The no-router message points at Windows Firewall, which drops the router's answer when Wildforge is not allowed. `coop.md` explains the firewall, the log and manual forwarding.
  - **Verified:** integration `upnp_outcomes` and `upnp_result_names`.
  - **Root cause found on the user's network** (October 24; read-only probes, no mapping changed):
    - The firewall allows the downloaded Build 21 on the Private network.
    - The modem is a Huawei EchoLife at 192.168.101.1. It answers UPnP, and its WAN service reports **Connected**, but with outside address **10.254.50.76**: a private address, meaning the provider's carrier-grade NAT. The engine labels such a gateway status 5 ("disconnected") and refuses to use it.
    - No port mapping on this connection can be reached from the internet. Fix: a friend with a public address hosts, or the user asks the provider for a public IP.
  - **Game fix:** a modem answering with status 5 is now reported as carrier-grade NAT, with that advice, instead of "router did not allow". Verified against the real modem: the game's `upnp_work` returns `carrier` on it. Integration check `upnp_provider_nat`.
- **Split world snapshots** (fixed October 24, protocol `wildforge-shared-world-14`): the world now travels as about 20 packets, all under the 1,392-byte MTU (the largest is 1,200 bytes at 125 enemies and 300 orbs). It used to be one 17.7 KB message in about 13 fragments, where any lost fragment lost the whole update.
  - **Packets:** a core packet (time, progression, events, player ids), the live enemy and orb id lists (removals come only from these), enemies 13 per packet, orbs 45 per packet, and one packet per player.
  - **Late packets:** each enemy, orb and player keeps the newest seq it has seen, so a late packet never rolls it back. A lost packet costs only its own enemies for one tick.
  - **Verified:** integration `net_packets_fit_mtu`; shared-review (100-enemy crowd all visible), shared-review-stress and coop-dropin. Not yet measured over a real lossy internet link.
- **Early co-op desync:** the original symptom was never described in detail. The pause-input fix and the passing full `coop` route do not prove it is gone, so the issue stays open until a matching report or reproduction exists.
- **Rejoin rewards** (fixed October 24): level-ups and chests the host shared while a player was away were lost, and a second shared reward arriving while one was still open replaced it. The host now keeps its last 24 shared rewards and replays those from shortly before the player's last packet when they rejoin. The guest queues a reward that arrives while another is open and never opens the same reward twice. Verified by shared-review `drop1.away_offer` and `away_offer_once`; with the replay switched off, the check fails. Replayed rewards are marked as replays, so they count even after the host has moved to another island (shared-review `drop2.earlier_island_chest`).
- **Performance** (profiled October 24, crowd-spells): three rank-9 spells in a 125-enemy crowd run at about 30 fps (frame median 33 ms).
  - **Where the time goes:** physics step 19 ms and process 12 ms, render about 2 ms. In the physics step, enemy collision slides take 5.8 ms (about 0.1 ms per `move_and_slide`, about 60 a frame), skills 2.6, steering 2.1 and rig posing 1.1. In process, the game's own work is about 2.3 ms (HUD 1.2, camera and effects 0.9); the other roughly 9.5 ms is engine-side, most likely transform sync for the many posed rig parts.
  - **Tried, no worthwhile gain, reverted:** Jolt physics (slides 5.4 ms), staggering far enemies to every 4th tick (worse, 36–43 ms), skipping slides for walkers beyond 14 m (the test crowd stays close), capsule colliders instead of cylinders (frame 32 ms, about 1 ms; changes ledge behaviour).
  - **Real fix:** a script-side crowd mover (ground following plus scenery avoidance without a physics slide for ordinary walkers) and fewer posed parts per rig. This is a larger piece of work.
  - Profiling-only timers (`slide`, `surface`, `p_*` sections) stay for the next attempt.
- **Balance** has been measured with bots and damage dummies only. It still needs a human playtest, especially the Baron fight and spells in moving crowds.
- **Cleanup the user does by hand:**
  - delete `G:\game-fxbase`;
  - optionally delete `G:\wildforge-archive` (old runs, builds 15–18 and old release zips; every release is also on GitHub).

## Deferred

- A hosted relay or matchmaking server. The user chose port opening only (October 22). On October 24 a relay plan was offered: (A) an own relay on a small rented server, (B) A plus direct connection first, (C) Epic Online Services, (D) Steam, (E) NodeTunnel. The user declined it for now: they test over the MoleTun tunnel, where friends join by the host's tunnel address.

# Wildforge — Development Plan

> **Active release: 1.1.0 — Build 12.** The October 13 Red Moon checkpoint adds the final arena, four heroes, combat/build progression, environment and UI changes. See [release evidence and remaining work](native/docs/release-1.1.0.md) and [balance notes](native/docs/balance-1.1.0.md). The older [1.0.0 overhaul](native/docs/release-1.0.0.md) remains historical evidence.

> **October 12 audit:** historical `[x done]` marks below overstate completion. The [original audit](native/docs/repair-audit-2026-10-12.md) records the baseline; the [0.8.10 gameplay repair](native/docs/gameplay-repair-0.8.10.md) supersedes its hill traversal, XP, compatibility, co-op specialty, damage readability and harvestable findings. Pause history, HP-bar removal, difficulty scaling, icon distinctness and performance claims remain partial or unverified.

**One developer. Streamlined process.** No multi-agent orchestration, no heavy rules. Direct edits, commit after each meaningful step, group exports after several milestones (Rytis prefers less-frequent uploads).

**Version:** 1.1.0 / Build 12. Previous published version was v0.8.10-alpha (Build 11), not Build 4; older release statements are historical and were stale. **Build:** Oct 13 2026. **Wrapper:** `node scripts/agent-workflow.mjs <action>`.

**Working rule:** every change committed + validated with the wrapper (see bottom), make exe build. Update README + release current.

---

## How this file works

- Items are `[ ] open`, `[~ in progress]`, or `[x done]`.
- We review the list one by one. Each item can be **done**, **edited**, or **left** 
- This file is rewritten to drop completed work; only the active list remains.

---

## Bugs to fix (new from 2026-10-11)

### October 13 follow-up — next gameplay and visual pass

Implementation and evidence are recorded in [the 1.1.0 checkpoint](native/docs/release-1.1.0.md). Completed implementation does not imply finished long-run balancing or a measured performance improvement.

1. **Boss indicators and health orbs — `[x done]`:** Remove boss HP indicators and nameplates from the screen. Enemy/boss health orbs are sufficient; restyle the orbs to match the new visual design while preserving readable health states and co-op synchronization.
2. **Denser environments and lighting — `[x done]`:** Populate maps with more biome-appropriate objects, localized glow and cast shadows, using Hades as the reference. Keep the ground restrained and preserve clear movement and combat visibility.
3. **Directional dash — `[x done]`:** Give players usable control over dash direction so ranged attacks can be deliberately dodged. Verify keyboard/mouse and controller behavior, including movement independent of camera facing.
4. **Dangerous enemy ranged attacks — `[x done]`:** Make ranged enemy attacks substantially more threatening; a poorly prepared hero build can be killed. Preserve readable warnings and opportunities to dodge, and balance solo/co-op damage.
5. **Final zone after the third map — `[~ in progress]`:** The third map's exit portal leads to a small mini-Mars arena with a huge, slow boss using several different ranged attacks. Tune its health for approximately five-minute battles with representative builds and party sizes. After its death, trigger Eclipse permanently until all heroes are dead. Verify portal progression, final boss death, co-op authority and the endless Eclipse phase. “Ellipse” is interpreted as the existing Eclipse event.
6. **Practical minimal UI — `[x done]`:** Rework the interface further toward a minimal, practical Hades-inspired style. Prioritize clear hierarchy, compact information and useful controls; verify actual navigation and 720p/1080p layouts.
7. **Biome-specific creepy enemies — `[~ in progress]`:** Research internet creepypasta references and create more original, distinctly different enemy designs for each biome. Vary movement speeds and behaviors so enemies do not all arrive in one clump; verify combat readability and encounter pacing.
8. **Visible celestial sky — `[x done]`:** Create a clearly visible Destiny 2-inspired sky with bright celestial objects, adapted to the Hades-inspired palette and lighting. Compose the sky for the existing camera and each biome, retaining contrast between the sky, terrain and combat effects.
9. **New heroes, class weapons and physical variety — `[x done]`:** Add Ninja, Smoker, Alcoholic and a white Supra-inspired meme car, each with a distinct starting weapon. Review the whole roster for meaningful differences in size, speed and jump height, with matching collision and readable health orbs.
10. **Deferred online co-op option: NodeTunnel — `[ ] later`:** The user selected NodeTunnel as the preferred option to evaluate. Bundle its Godot plugin with Wildforge and provide Host Online / Join Room Code without separate player software or router configuration. Retain LAN/direct-IP. Check compatibility with the bundled engine and test actual two-network host/client gameplay before adopting it. Measure host-client round-trip latency, jitter and loss, including ranged attacks and directional dodges. The [currently listed free relay](https://nodetunnel.io/) is US East; European routing may add substantial delay. The [plugin listing](https://store.godotengine.org/asset/androodev/nodetunnel/) labels it beta/unstable and supports self-hosting; consider an EU relay if measured latency is unsuitable. This pins the candidate, not a completed integration or a hosting purchase. October 13 connectivity probe: five TCP connection attempts from this PC to `us-east.nodetunnel.io:8080` timed out (2-second socket timeout); no latency sample was obtained. This does not establish a service outage or actual in-game latency.

October 13: items 1–9 implemented; item 5 remains open for representative five-minute solo/party balance, and item 7 for further reference research/encounter pacing. The final boss was revised to 42 m, 0.22 m/s, angular skull/spires/skeletal legs and four 95–120 damage attack patterns after user feedback. NodeTunnel/tunneling remains deferred. Input actions are verified automatically; physical gamepad feel still needs player feedback.

### October 13 additional requests — easiest first

- `[x done]` Progression toward jump–slam chains: baseline 4.5s recovery shared with head stomps; no ordinary-enemy instant kill. Rebound Gear improves recharge, alongside extra jumps, bounce, slam radius/power and elemental upgrades. A visible readiness indicator uses the current binding. Verify real inputs, recovery, upgraded chains and co-op authority.

- `[x done]` Turret selection: visibly mark the selected turret and show current deploy/switch bindings, including custom controls and controller input.
- `[x done]` Clearer hero damage: stronger readable hit feedback; lower Eclipse music volume.
- `[~ in progress]` Quick balance pass: all heroes (including older class identities), weapons, skills, items, enemy roles and drop rates. Add useful new items. Record calculations and any playtest limitations.
- `[x done]` Enemy physiques: vary sizes with speed and health, including modest species variation and matching co-op collision/visuals.
- `[~ in progress]` Eclipse arrangement: adapt the existing local arrangement for gameplay while preserving its recognizable character; keep the original file. Review clipping, loudness and loop continuity.
- `[~ in progress]` Other music: original, simpler phonk arrangements, with Eclipse remaining the aggressive contrast.
- `[x done]` Finish the bright Hades-inspired effect pass, especially slam and remaining legacy effects; add/remake matching sound effects.
- `[x done]` Massive biome buildings: substantial architectural spaces beyond scattered trees and towers; preserve navigation, sightlines and performance.

- `[x done]` Main-menu and About version/build labels use project metadata: v1.1.0 / Build 12, checked at 720p and 1080p.

Balance calculations and drop fixes are implemented; long-run balance remains open. Eclipse is 5 dB quieter with a softened mix of the existing arrangement, and original simpler phonk stems are implemented. Playback/loops/peaks pass; subjective music listening remains open.

**Validation follow-up — `[~ in progress]`:** Diagnose the intermittent aggregate failure in the exported 720p UI review (`2026-10-13T08-01-54-716Z-release-review`). Per-assertion reporting is now added; current source/exported 720p/1080p navigation passes, but the historical failure has not been reproduced or explained. Keep the failed evidence alongside successful runs; do not weaken assertions.

### October 12 follow-up — six gameplay repairs — `[x done]`

- Enemies: reproduced failure at a 0.35 m step and a 22° hill. Collision-tested stepping, floor movement and local slope acquisition now pass both plus existing wall/ceiling/ledge checks.
- XP: threshold `18 + 8*level + level²`, bounded enemy rewards and merged orbs, with at least eight seconds of active play between earned level choices. Extra XP stays banked. Controlled 120-second pacing sample reached level 6; see the report for limitations.
- Cards and potion buffs: current-loadout compatibility, actual weapon names, missing requirements and augment conditions. Capped cards explain that there is no additional benefit.
- Co-op selection: specialty name, description, numeric perks and starting weapon explanation, updated through the actual hero button.
- Damage numbers: bold 34/42-point text with outline/shadow, world-position projection, stable gold crits and green healing; repaired missing critical-shot marker. Existing ordinary-hit suppression remains.
- Harvestables: six distinct models in their correct biomes, readable descriptions/effects, flat clear placement, timed bonuses with refresh/expiry, active HUD timers, healing accounting and harvest coins for pot-economy upgrades.

[Build, exact verification evidence and remaining limitations](native/docs/gameplay-repair-0.8.10.md). The historical entries below describe earlier implementations and are not the current specification for these six areas. Existing staged work is preserved, so no mixed-index commit or remote publication is made.

|||### 0. hud.gd line 573 — portrait out of scope in coop_menu — `[x done]`
|||Portrait was declared as a local variable inside start_menu() but referenced from coop_menu(). Promoted to class-level variable `var portrait: HeroPortrait` (line 42) so both menus share the same instance.

||||### 1. Status effect indicators on enemies — `[x done]`
||||GPUParticles3D indicators created above enemy heads in `create_status_indicator()`. Colors: orange=#ff6633 fire, green=#44cc66 poison, blue=#66bbdd freeze, dark purple=#554477 blind. Indicators scale based on remaining duration, emission energy pulses. Fixed `hurt_enemy()` to set `enemy.status_time=4` when initially applying fire/poison/ice effects (was only set by caller `hit_enemy()`).

||||### 2. Damage number clarity — `[x done]`
||||Crits: red base color, HUD alternates red↔gold during flash, larger size (20pt). Melee: warm white `f0e0d0`. Slam: larger white numbers (20pt, fly speed 1.1×). Heal: green `00ff00`, HUD alternates bright↔dark green during flash, triggered on actual healing from `func heal()`. `size_boost` initialized before if/elif chain to prevent undefined behavior. Flash timer (1.2s) applied to crit and heal in `_process`, decremented each frame.

||||### 3. Death counter + last run stats in pause menu — `[x done]`
||||Added `death_count` tracking in `game.gd`, `career.bump("deaths", death_count)` and `career.bump("kills", kills)` for cumulative stats. HUD pause menu shows "Died X times", run report includes death count. `career.bump()` used for cumulative stats (kills, deaths), `career.best()` for peak metrics (best time, max level).

||||### 4. Remove enemy nameplates, update hero HP UI (shield + armor) — `[x done]`
||||Removed all Label3D nameplates from enemy heads (Elite/Mythic titles, Boss names, HP%). Added shield bar (blue, 8px) below HP bar in health panel and armor stat line ("ARMOR X"). Health panel height increased to 96px. No floating HP bars over enemies — their body color/animation conveys health.

||||### 5. Remove pots, replace with biome-specific harvestables — `[x done]`
||||Replaced `make_pots()` with `make_harvestables()` — 5 biome types (Herb heal 8HP, Ice shard +10% damage, Void fungi +1 shield, Sulfur crystal +15% fire, Ember core +1 air jump). ~8 per biome. Pickup plays sound + particle burst. Active effects shown in HUD. `nearest_harvestable()` and `pick_harvestable()` handle interaction. Status indicators use `GPUParticles3D` with dynamic scale and emission energy based on duration. All harvestables tracked in `harvestables` array, cleaned in `clear_entities()`.


|### 2. Hero gets way too much XP — `[x done]`
|Changed XP curve from `2 + level*2 + level²` to `8 + level*6 + level²*2`. Level 1 now costs ~16 XP vs 5; level 8 costs ~184 vs 82.

|### 3. Enemies stuck on flat ground — `[x done]`
|Added early return in `EnemySurface.tick()`: regular enemies only use surface climbing when player is >3 units higher. On flat ground, enemies walk via standard CharacterBody3D `move_and_slide()`.

|### 4. Mouse up/down zooms instead of looks up/down — `[x done]`
|Scroll wheel zoom kept. Vertical mouse movement now tilts camera look angle (pitch ×2 sensitivity, range -.8/.6). Camera position height no longer affected by pitch — only look direction.

||### 5.  cards show weapon applicability — `[x done]`
|Augment cards (e.g. "augment-gun-damage") now show "Boosts: [weapon name]" when player owns that weapon, or "Won't help — requires [weapon]" when they don't. Generic boosts (damage, rate, etc.) still show normal text.

### 6. Chest card icons — `[x done]`
All 10 chest card icons replaced with detailed 2D SVG artwork. Economy cards (cheap-chest, free-key, gold-glove, gold-heart, piggy-bank, coin-magnet, gold-boots, pot-finder) now feature unique illustrated assets: treasure chest with coins, ornate golden key, golden gauntlet, heart-shaped gold, piggy bank, horseshoe magnet attracting coins, golden boots with buckles, pot of gold with rainbow. Arcane chest-heal-item and chest-heal-skill now show detailed treasure chests with purple bands and healing cross (item) / magical glow with rising particles (skill). All labels corrected from truncated text (e.g. "SA") to full text ("SALE").

||### 7. Hit indicator makes screen to busy — `[x done]`
Damage numbers now only appear on critical hits (`cause=="crit"`). Regular hits no longer spawn floating damage numbers, eliminating screen clutter.

### 8. Modern Series X-style achievement notifications and original chime — `[x done]`
User revision for 0.8.9: flat green rounded banner, original white trophy/laurel artwork, icon-first expansion and text reveal. Replaces the 360 medallion and recording. The new 1.85-second synthesized chime uses an air sweep, soft impact and bright resolving tones; no Xbox audio is loaded or exported. Queuing, menu deferral and SFX controls remain. Verified by 93 smoke checks and source/exported UI reviews at 720p, 810p and 1080p; [build, previews and evidence](native/docs/achievement-ui-0.8.9.md), [sound design](native/assets/audio/achievement-sound.md).

||### 9. Portal maps scale difficulty — `[x done]`
|Added `realm_difficulty` variable (1.0 + realm*0.25, capping at 1.75 for realm 2) applied to: enemy HP, enemy attack damage, hazard telegraph/guardian damage, and Eclipse time-scaling damage. Initial spawn count increased from 9 to 9+realm enemies per realm.

||### 10. Eclipse lag investigation — `[x done]`
||Projectile-enemy collision used expensive `Geometry3D.get_closest_point_to_segment` (called every frame per projectile×enemy). Replaced with fast sphere-swept distance check: computes squared distance to line segment using dot product projection. Reduces per-frame CPU cost by ~10-50x. With 140 projectiles × 125 enemies, this eliminates the most expensive physics operation in the combat loop.

||### 11. Eclipse new music — `[x done]`
||Replaced MIDI-synthesized eclipse music with PARANOIA.mp3 converted to WAV (44100Hz, 2ch, 16-bit). Full track loops automatically via `stream.loop=true` and `stream.loop_end=stream.data.size()` in sound.gd. 116s duration, seamless looping.

||### 20. Maps too hilly — enemies get stuck — `[x done]`
|Flattened terrain generation: reduced Moon Craters (biome 2) amplitude from -28 to -6, lowered all other biome amplitudes (9→6, 5→4, 11→6, 19→6, 16→6), reduced mountain contribution (25→12) and base noise (9→6). Terrace stepping at 5-unit intervals creates naturally flat zones. Net height range reduced from ~±55 to ~±15.

||### 21. CPU spike — check GPU offload — `[x done]`
||Investigation complete. Rendering, particles, shaders, MultiMesh already GPU. CPU-bound: physics (trimesh collision, CharacterBody3D, ray queries), game logic, audio. Fixed the main game loop bottleneck: replaced `Geometry3D.get_closest_point_to_segment` (called every frame per projectile×enemy) with fast sphere-swept distance check using dot product projection. Reduces per-frame CPU cost by ~10-50x. Remaining CPU items: terrain trimesh collision, per-enemy ray queries in EnemySurface.tick, projectile-enemy aura checks.

||### 22. Run report damage numbers are nonsense — `[x done]`
|Damage report showed identical/similar values with cryptic labels like "4349/poison Time". Root cause: `damage_sources` dictionary was shared between damage crediting and floating damage number dedup tracking. Dedup keys like "enemyID/cause" mixed with real damage entries. Fixed by prefixing dedup keys with "dedup_" in `record_damage_number()`.

||### 12. Eclipse hero drift — `[x done]`
||Hero turn response reduced from 22/14 to 6/4 lerp rate during Eclipse on ground. Movement is noticeably slipperier — momentum lingers, directional changes feel sluggish.

||### 13. Eclipse blood rain — `[x done]`
||Added `GPUParticles3D` blood rain system in `_ready()`. Emits 200 red droplets from a 120×60 box above player (y=55), gravity -8, initial velocity 80–120 downward. Visibility toggled on Eclipse enter/exit. Positioned to follow camera horizontally.

|||### 14. Remake non-weapon card/skill/boost icons — `[x done]`
||Replaced `skill-gen.py` with detailed version using SHA1-seeded motif selection (gear/shield/heart/crosshair/bolt/flame/snow/etc.), family-specific background patterns, card styling with drop shadows. 344 skills all unique, 352 items all unique — zero duplicates. Output: `native/assets/illustrated/content/*.svg`.

||### 15. HUD pushed into corner — `[x done]`
||Health panel widened to 310px. Gold text increased to 18pt with gold-themed panel. Elements more spread out with better visual hierarchy.

||### 16. Camera: third-person shooter perspective — `[x done]`
Camera switched to TPS-style orbit around player using spherical coords: `player + (sin(yaw)*cos(pitch)*dist, sin(pitch)*dist, cos(yaw)*cos(pitch)*dist)`. Mouse X = yaw (orbit), Mouse Y = pitch (height). Initial pitch -0.3 (slightly downward). Zoom range tightened to 4–8. Camera always looks at player body anchor. Raycast occlusion kept.

||### 17. Damage aura visual indicator — `[x done]`
Golden pulsing ring appears around player when `auraDamage > 0`. Ring scales with sinusoidal pulse (15% oscillation, 5 Hz). Emission glow oscillates 2.0–2.8×. Cleans up when no enemies nearby.

||### 18. Lightning effect looks like lightning — `[x done]`
Replaced simple blue beam with `lightning_bolt()`: 6-segment jagged zigzag using perpendicular offsets, electric glow (`#d0e8ff`, emission 3×), 0.22s lifetime. Each chain segment is a separate bolt segment with decreasing width toward the target.

|||### 19. Enemy speed too fast — set to `2.9 + realm*0.35` — `[x done]`
|Changed enemy base speed from `8.0+realm*.35+randf()*1.5` to `2.9+realm*.0.35+randf()*0.6`. Enemies are now ~64% slower at base, with proportionally reduced random variation.

||### 20. make camera 3rd person fps style. with big zoomout compability — `[x done]`
|Camera base distance increased from 8.0 to 12.0, zoom range expanded from 4–8 to 4–16. Provides much wider zoom-out capability while maintaining close-range FPS-style play.

## Done (retained, removed from active list)

- Organic island + minimap, painted ground materials, compact HUD + treasure-reel chests.
- Hunter's Oath encounter, semantic potion/weapon/mobility icons, hero materials.
- Co-op lobby (hero select/Ready), shared flowers, owned damage numbers, bottom-edge damage labels, remote stomp ownership.
- Surface climbing (walls/ceilings/ledges/slopes), configurable controls, group XP/coin merge, Attraction/Repulsion pulses, detailed pause stats, run recap, Eclipse corruption visuals, PARANOIA Eclipse music.
- Bugfixes 0.8.2: dictionary corruption crash, 45° slope gate, corruption stage storage.

---

## Validation (how to prove each change)

Read [AGENTS.md](AGENTS.md) and the [Godot workflow guide](native/docs/godot-workflow.md) for exact commands, diagnostics, visual checks and known baseline failures. Hermes can start from [HERMES.md](HERMES.md).

- After edits: `node scripts/agent-workflow.mjs check` (JS + Godot import/parse) then `integration`.
- Feature-specific: `pace-review` (XP/level pace), `capture-ui` / `controls-review` (menus, camera, HUD), `coop` / `coop-feedback` (co-op), `combat-review` (combat).
- Build after several milestones: `node scripts/agent-workflow.mjs build` → `.build-staging/.../Wildforge.exe`, then package with `scripts/package-release.ps1 -BuildNumber N -BuildDirectory <dir> -SourceCommit <sha>`.
- Test new builds in solo and in coop. Make and inspect new screenshots for UI bugs!
- Preserve history, saves, logs; delete old builds only with explicit authorization.
- Update plan.md: version, newest build, done tasks moved to do "## Done".

Visual overhaul scene checkpoint: [models, orb replication, evidence and remaining work](native/docs/visual-scene-1.0.0.md). Version remains 0.8.10; full 1.0.0 roadmap stays open.

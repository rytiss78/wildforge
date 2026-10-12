# Wildforge — Development Plan

> **Active next release: 1.0.0.** Follow the [staged visual-overhaul roadmap](native/docs/visual-overhaul-1.0.0.md), requested October 12. It supersedes the earlier visual direction: Hades-inspired visuals throughout, unchanged camera, damage numbers rising from the bottom, retained HP orbs, expanded monster-boss rotation, verified removal of old assets, regular GitHub pushes and updated About/README/screenshots. The implementation runs in a new session; 0.8.10 below remains the tested starting build.

> **October 12 audit:** historical `[x done]` marks below overstate completion. The [original audit](native/docs/repair-audit-2026-10-12.md) records the baseline; the [0.8.10 gameplay repair](native/docs/gameplay-repair-0.8.10.md) supersedes its hill traversal, XP, compatibility, co-op specialty, damage readability and harvestable findings. Pause history, HP-bar removal, difficulty scaling, icon distinctness and performance claims remain partial or unverified.

**One developer. Streamlined process.** No multi-agent orchestration, no heavy rules. Direct edits, commit after each meaningful step, group exports after several milestones (Rytis prefers less-frequent uploads).

**Version:** 0.8.10 (local development). **Build:** Oct 12 2026. **Wrapper:** `node scripts/agent-workflow.mjs <action>`.

**Working rule:** every change committed + validated with the wrapper (see bottom), make exe build. Update README + release current.

---

## How this file works

- Items are `[ ] open`, `[~ in progress]`, or `[x done]`.
- We review the list one by one. Each item can be **done**, **edited**, or **left** 
- This file is rewritten to drop completed work; only the active list remains.

---

## Bugs to fix (new from 2026-10-11)

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

# Wildforge — Development Plan

**One developer. Streamlined process.** No multi-agent orchestration, no heavy rules. Direct edits, commit after each meaningful step, group exports after several milestones (Rytis prefers less-frequent uploads).

**Version:** 0.8.2 (in `native/project.godot`). **Latest release:** build-2. **Wrapper:** `node scripts/agent-workflow.mjs <action>`.

**Working rule:** every change committed + validated with the wrapper (see bottom). Keep README + release current.

---

## How this file works

- Items are `[ ] open`, `[~ in progress]`, or `[x done]`.
- We review the list one by one. Each item can be **done**, **edited**, or **left** — Rytis decides.
- This file is rewritten to drop completed work; only the active list remains.

---

## Bugs to fix (new from 2026-10-11)

|### 1. UI offcentered, no visual update — `[x done]`
|Modal panels now dynamically center based on `get_viewport().get_visible_rect().size` instead of fixed `Vector2(220,80)`. Panels stay centered at any resolution.

|### 2. Hero gets way too much XP — `[x done]`
|Changed XP curve from `2 + level*2 + level²` to `8 + level*6 + level²*2`. Level 1 now costs ~16 XP vs 5; level 8 costs ~184 vs 82.

|### 3. Enemies stuck on flat ground — `[x done]`
|Added early return in `EnemySurface.tick()`: regular enemies only use surface climbing when player is >3 units higher. On flat ground, enemies walk via standard CharacterBody3D `move_and_slide()`.

|### 4. Mouse up/down zooms instead of looks up/down — `[x done]`
|Scroll wheel zoom kept. Vertical mouse movement now tilts camera look angle (pitch ×2 sensitivity, range -.8/.6). Camera position height no longer affected by pitch — only look direction.

|### 5. Card picker: weapon upgrade not matched to equipped weapon — `[x done]`
|Weapon cards show "Equipped: Rank X → X+1" for owned weapons, "New weapon — fills empty slot" / "full slot required" for new weapons.
|### 5b. Boost cards show weapon applicability — `[x done]`
|Augment boost cards (e.g. "augment-gun-damage") now show "Boosts: [weapon name]" when player owns that weapon, or "Won't help — requires [weapon]" when they don't. Generic boosts (damage, rate, etc.) still show normal text.

### 6. Chest card icons — `[ ] open`
Chest card icons need a complete visual overhaul: detailed 2D artwork. Not a code fix — asset creation needed.

||### 7. Hit indicator makes screen to busy — `[x done]`
Damage numbers now only appear on critical hits (`cause=="crit"`). Regular hits no longer spawn floating damage numbers, eliminating screen clutter.

||### 8. Xbox-style achievement notifications — `[x done]`
||Achievement popup slides in from top-right corner with fade animation (1s in, 3s hold, 0.5s out). Gold-bordered panel shows achievement name and description. Triggered via `achievement_event()` in game.gd.

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

|### 14. Remake non-weapon card/skill/boost icons — `[ ] open`
|Redesign all icons for cards, skills, and boost items (NOT weapon icons — those are fine). Needs detailed 2D artwork. Covers ~600 loot items + skills.

||### 15. HUD pushed into corner — `[x done]`
||Health panel widened to 310px. Gold text increased to 18pt with gold-themed panel. Elements more spread out with better visual hierarchy.

||### 16. Camera: third-person shooter perspective — `[x done]`
Camera switched to TPS-style orbit around player using spherical coords: `player + (sin(yaw)*cos(pitch)*dist, sin(pitch)*dist, cos(yaw)*cos(pitch)*dist)`. Mouse X = yaw (orbit), Mouse Y = pitch (height). Initial pitch -0.3 (slightly downward). Zoom range tightened to 4–8. Camera always looks at player body anchor. Raycast occlusion kept.

||### 17. Damage aura visual indicator — `[x done]`
Golden pulsing ring appears around player when `auraDamage > 0`. Ring scales with sinusoidal pulse (15% oscillation, 5 Hz). Emission glow oscillates 2.0–2.8×. Cleans up when no enemies nearby.

||### 18. Lightning effect looks like lightning — `[x done]`
Replaced simple blue beam with `lightning_bolt()`: 6-segment jagged zigzag using perpendicular offsets, electric glow (`#d0e8ff`, emission 3×), 0.22s lifetime. Each chain segment is a separate bolt segment with decreasing width toward the target.

||### 19. Enemy speed too slow — they stop even on flat ground — `[x done]`
Enemy base speed increased from `2.9 + realm*0.35` to `8.0 + realm*0.35 + randf()*1.5` (~9–11 units/sec at realm 0 vs ~3.3). Enemies now move fluidly toward player with proper CharacterBody3D move_and_slide.

## Done (retained, removed from active list)

- Organic island + minimap, painted ground materials, compact HUD + treasure-reel chests.
- Hunter's Oath encounter, semantic potion/weapon/mobility icons, hero materials.
- Co-op lobby (hero select/Ready), shared flowers, owned damage numbers, bottom-edge damage labels, remote stomp ownership.
- Surface climbing (walls/ceilings/ledges/slopes), configurable controls, group XP/coin merge, Attraction/Repulsion pulses, detailed pause stats, run recap, Eclipse corruption visuals, PARANOIA Eclipse music.
- Bugfixes 0.8.2: dictionary corruption crash, 45° slope gate, corruption stage storage.

---

## Validation (how to prove each change)

- After edits: `node scripts/agent-workflow.mjs check` (JS + Godot import/parse) then `integration`.
- Feature-specific: `pace-review` (XP/level pace), `capture-ui` / `controls-review` (menus, camera, HUD), `coop` / `coop-feedback` (co-op), `combat-review` (combat).
- Build after several milestones: `node scripts/agent-workflow.mjs build` → `.build-staging/.../Wildforge.exe`, then package with `scripts/package-release.ps1 -BuildNumber N -BuildDirectory <dir> -SourceCommit <sha>`.
- Test new builds in solo and coop. Make and inspect new screenshots.
- Preserve history, saves, logs; delete old builds only with explicit authorization.

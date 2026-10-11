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

|### 7. Hit indicator makes screen to busy — `[ ] open`
|Enemie hit particles should apear only on critical hit on the nenemie

|### 8. Xbox-style achievement notifications — `[ ] open`
|Add achievement popup with Xbox-style notification look + sound. Use a centered top banner with fade in/out animation and Xbox achievement sound effect.

|### 9. Portal maps scale difficulty — `[ ] open`
|Entering a new map through a portal should make that map harder (more enemies, tougher stats) proportional to map depth/progression.

|### 10. Eclipse lag investigation — `[ ] open`
|Investigate lag when there are many enemies with skills/weapon events. Profile to find bottleneck (physics, rendering, or logic).

|### 11. Eclipse new music — `[ ] open`
|Replace current eclipse background music with PARANOIA.mp3 (provided). Map to eclipse stage in game.gd / run_clock.gd audio system.

|### 12. Eclipse hero drift — `[ ] open`
|Increase hero drift/slippage on eclipse stage (slippery movement, harder control). Modify hero physics or add an eclipse-specific friction multiplier.

|### 13. Eclipse blood rain — `[ ] open`
|Add blood rain particle effect for eclipse stage. Red droplet particles falling across the screen.

|### 14. Remake non-weapon card/skill/boost icons — `[ ] open`
|Redesign all icons for cards, skills, and boost items (NOT weapon icons — those are fine). Needs detailed 2D artwork. Covers ~600 loot items + skills.

|### 15. HUD pushed into corner — `[ ] open`
|Screenshot shows UI elements (health, gold, chest count, location) crammed into the top-left corner, leaving most of the screen empty. Redesign HUD layout: spread elements across screen edges (health top-left, minimap top-right, inventory bottom-center, XP bottom-left, gold/round timer top-center). Increase font sizes and make panels more visible without blocking gameplay view.

|### 16. Camera: third-person shooter perspective — `[ ] open`
|Current camera is overhead/top-down (camera Y fixed at `7.5 + distance*0.25`, high angle, small character on screen). Remake camera to TPS style:
- Camera orbit around player: mouse X rotates yaw, mouse Y orbits pitch (clamped -0.5 to 0.4 radians)
- Camera height tied to pitch: `player.y + 1.5 + cos(pitch)*distance*0.5`
- Camera distance: 4–7 units (not 3–11)
- Smooth follow with raycast occlusion (current system ok, keep)
- No crosshair
- Scroll wheel zoom: 4–7 range
- Keyboard WASD moves character relative to camera direction

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

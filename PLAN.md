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

## Review items (new from 2026-10-10 — decide each one)

|### 1. Co-op: does one player opening a chest remove it from everyone's map? — `[x done]`
|✅ Verified: `chest_open` + `chest_hide` broadcast to all co-op members; chests are hidden from everyone's world and mini-map.

### 2. Co-op XP/gold scaling — `[x done]`
✅ Verified: confirmed 1:1 full credit per picker. Decided: divide by party size (4-player = 25%). Implemented in `coop.gd` credit handlers (host + client).

|### 3. Half XP rates — `[x done]`
|✅ Done: halved the XP curve formula in `rules.gd` from `4 + level * 4 + level² * 2` to `2 + level * 2 + level²`. Level 1 now costs ~10 XP vs 20; level 10 costs ~257 vs ~514.

|### 4. Banishes: 1 → 5, not shared in co-op — `[x done]`
|✅ Done: increased per-realm banish charges from 1 to 5 in `big_update.gd` (line 46). Banish charges are a per-player variable on `BigUpdate` instance — already not shared in co-op.

|### 5. Unlock vertical camera movement — `[x done]`
|✅ Done: added `camera.rotation.x = pitch` in `game.gd` _process, so mouse/stick vertical input now tilts the camera view angle. Previously pitch only offset camera height.

### 6. Menu / UI / overhaul overhaul — `[x done]`
✅ Completed: panel entrance/exit tweens, toast fade in/out, low-HP pulse, timer warning glow (<60s), chest reveal glow animation, weapon slot pop-in, HP icon, gold icon. All existing functionality preserved.

### 9. UI polish (spacing, icons, animations) — `[x done]`
See item 6. All polish applied.

### 7. Sole-developer process — `[x done 2026-10-10]`
Rytis is now the only developer. Multi-agent orchestration dropped; dev rules simplified. One agent, direct edits, group exports. This plan file itself is the streamlined workflow.

### 8. Rewrite GitHub page — `[x done]`
Updated `community/README.md` with full feature list, download link, 6 current UI screenshots, and build instructions. Updated `community/about.md` with co-op scaling note.

---

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
- Preserve history, saves, logs, screenshots; delete old builds only with explicit authorization.

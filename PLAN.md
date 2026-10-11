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

### 1. Co-op: does one player opening a chest remove it from everyone's map? — `[ ] verify`
Behavior to check in `coop.gd`/`game.gd`: when player A opens a chest, is the chest removed from the world for players B/C/D too, or does each player keep their own copy? Also: level-up rewards and banish selection scope (see item 4). If it currently only affects the opener, that's a co-op consistency fix.

### 2. Co-op XP/gold scaling — `[ ] verify + decide`
Question: does shared XP/gold scale *down* per player so more players don't make the game much easier? Current design credits each picker locally (see old PLAN URGENT #1). Decide: keep 1:1 credits, or apply a per-player divisor so a 4-player run doesn't 4x the pace. Balance impact is high — confirm target before coding.

### 3. Half XP rates — `[ ] edit`
Level-ups feel too frequent. Plan: cut base XP roughly in half (tune the XP curve / `xp_target` in `game.gd`) and re-run `pace-review` to confirm opening pace still feels good. Small data change; no logic change.

### 4. Banishes: 1 → 5, not shared in co-op — `[ ] edit`
Reward screen has a "Banish" option but only one use per chest. Increase to 5 banishes. Banishes and banish-selection choices are **not** shared between co-op players (each player spends from their own pool, sees their own options) — unlike shared chest opening. Confirm current banish logic before changing counts.

### 5. Unlock vertical camera movement — `[ ] implement`
Currently the camera likely locks to a horizontal plane. Unlock up/down look so players can tilt the camera vertically. Scope: camera controller in `game.gd`. Verify no collision/aim regression.

### 6. Menu / UI / overhaul overhaul — `[ ] big — scope first`
Menus, HUD, and overlays have been patched many times; some logic is tangled and the look is plain. Plan: redesign menus, UI, and overlays — keep existing functionality, add more only after asking what Rytis wants (per instruction). Do **not** gut working logic. This is the largest item; we should lock a visual direction + concrete "add" list before coding.

### 7. Sole-developer process — `[x done 2026-10-10]`
Rytis is now the only developer. Multi-agent orchestration dropped; dev rules simplified. One agent, direct edits, group exports. This plan file itself is the streamlined workflow.

### 8. Rewrite GitHub page — `[ ] implement` (draft below, needs current screenshots)
community/README.md (repo page) + community/about.md (About tab) currently show an old build and outdated description. Plan: refresh download link to latest release, replace screenshots with current-build captures, update text. Needs a fresh build export with current screenshots (see item 6 overlap — coordinate).

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

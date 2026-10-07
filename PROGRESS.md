# Wildforge development progress log

Working rules: AGENTS.md. Roadmap: PLAN.md. Megabonk mod is frozen (mods/megabonk-wildforge — never touch).
Keep this file current after every batch: exact validation commands, results, decisions, next task.

## Batch — 2026-10-06 (this session): resolved the achievement-icon uniqueness test failure

### Problem (carried from handoff)
`tests/native-content.test.js` failed: 100 distinct unlocked achievement icons vs 108 achievements.
The prior session's test edit compared against the live catalog count (was hardcoded 100),
which exposed a real uniqueness mismatch. Handoff instruction: fix the mismatch, do NOT weaken the check, preserve IDs/saves.

### Root cause (found this batch)
- `scripts/create-achievement-icons.py` predates the 8 first-discovery achievements added in 0.8.2
  (`WF_beacon, WF_merchant, WF_mimic, WF_reaction, WF_rescue, WF_ping, WF_banana, WF_terrace` — lowercase IDs, catalog indices 100–107).
- Those 8 icons were created by a **byte-copy hack** in `scripts/export-achievements.mjs`
  (`discoveryBadges` map → `copyFile` of 8 existing badges' bytes).
- Result: only 100 distinct unlocked icons → uniqueness assertion failed.
- Note for the record: the 8-bit per-ID stitch pattern is NOT unique across 108 IDs on its own (20+ collision pairs); distinct source tiles are what mostly separate badges.

### Fix (implemented + verified)
1. New `scripts/create-discovery-badges.py`: renders the 8 first-discovery badges from the same
   approved atlas (`native/assets/illustrated/icons.png`) + paper texture, each with a **distinct source
   tile** matched to its discovery (beacon→turret, merchant→coins, mimic→boots, reaction→fire charm,
   rescue→heart, ping→lightning, banana→poison sprayer, terrace→key), explore-style flag-on-trail motif,
   plus the per-ID stitched stitches for stable identity. Asserts the 8 tiles are mutually distinct.
2. `scripts/export-achievements.mjs`: **removed the copyFile hack**; replaced with a gate that errors on
   any missing icon PNG and on any two API IDs sharing an unlocked-icon hash — a future export can never
   silently re-introduce the duplicate.

### Validation (this batch, freshly run)
- Distinctness probe, all 108 IDs, both states → `unlocked distinct: 108, dup groups: 0`; `locked distinct: 108, dup groups: 0`.
- `node scripts/export-achievements.mjs` → "Exported 108 standalone achievement definitions."; achievements.json/csv byte-identical to pre-fix (diff clean).
- `node --test` (full JS suite) → `tests 9, pass 9, fail 0`.

### Files changed
- `tests/native-content.test.js` (prior session's count fix — kept as-is)
- `scripts/export-achievements.mjs` (copy hack → distinctness gate)
- `scripts/create-discovery-badges.py` (new)
- `community/achievement-icons/wf_{beacon,merchant,mimic,reaction,rescue,ping,banana,terrace}-{unlocked,locked}.png` (16 files)
- `native/assets/illustrated/achievement-art.json` (regenerated manifest)
- `AGENTS.md`, `PROGRESS.md` (docs)

### Decisions / notes
- In-game HUD already intentionally falls back to `IllustratedIcons` for achievement index ≥100 (native/scripts/hud.gd:739). The 8 new badges therefore do NOT need to fit the 10x10 native atlases; the 256px distinct PNGs are the community/Steam export surface the test enforces. hud.gd left untouched.
- Achievement IDs and save format preserved; no IDs renamed.

## Batch — 2026-10-07: wrote `native/docs/art-direction.md` (Phase 0, item 1 done)
- New `native/docs/art-direction.md` (145 lines): style statement (warm whimsical storybook diorama), 5 core palette hexes verified from code (ink `#17293D`, paper `#FFF8DE`, warm light `#FFF2DE`, star gold `#FFF1C8`, terracotta `#B67552`) plus verified biome accents 0–4, typography (marked proposed — HUD fonts not yet audited), rounded-shape rules, warm single-sun lighting, restrained particle budget, and 7 measurable readability criteria (contrast ≥4.5:1, silhouette flat-render test, color distinctness, distance, screen share, frame check via golden scene, motion).
- Honest status: typography, Prism biome palette, card radii and new hero models are marked **proposed/unverified** in §3/§8 pending a rendered check. No game code touched; no assets modified.
- Committed as local docs checkpoint (this commit).
- Next task unchanged: build the golden scene (see below).

## Unresolved / next concrete task
1. ~~Phase 0 item 1: art-direction.md~~ — **done 2026-10-07** (see batch above).
2. Build the golden scene (hero + 2 enemies + 1 chest + ground + sky), screenshot to `native/docs/golden-scene.png`, verify visually against art-direction.md §7. Capture pattern to reuse: `game.gd` smoke path uses `await RenderingServer.frame_post_draw` + `get_viewport().get_texture().get_image().save_png("user://...")` (e.g. line 1849); models via `world.model(name, height)` (`world.gd:120`); heroes via `select_hero(...)` (`game.gd:264`).
3. First focused UI/theme batch: `native/scripts/theme.gd` + card/HUD pass against the art direction.
4. At milestone end: run the Godot integrated checks (`node scripts/native.mjs --test`) and a short playable run; record results.
   (The 55 integrated Godot checks were NOT rerun in this batch — historical only until re-run.)

## Environment notes (for future sessions)
- Node: use `C:\Users\rytis\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe` (npm was unavailable in the handoff shell; `node --test` works from G:\game).
- Python with PIL: `C:/Users/rytis/AppData/Local/hermes/installs/9f9fc6403a6bec78/environments/f2292ca6a116451e86fb5ed0c1cbc8a8/venv/Scripts/python.exe` (system python has no PIL).
- Historical (handoff, not re-verified): compression config updated (no-thinking summaries, 45K trigger, 300s cap); test log at Hermes logs/wildforge-compression-test.json.

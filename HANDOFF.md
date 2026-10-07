# Wildforge current handoff
Updated2026-10-07. Standalone Wildforge overhaul; ignore mods/megabonk-wildforge. One development agent. Follow AGENTS.md. User wants sustained quality development, not a claim that the game is finished.

## Current objective and user priorities
Latest: improve enemies/heroes/items/guns/buildings/trees; use assets where needed. Icons must depict their item. Longer/procedural music. Compact HUD. Larger boxes with visible opening/audio and slot-machine choice feel. Explain chest vs level progression. Earlier: impactful bosses, meaningful timer expiry, organic island/coherent minimap, visible portal summoning final guardian; then broader mechanics/events/endgame/art/music.
Answered chest distinction: chests give items via exploration/gold, boss chests free/minimumRare; levels give skills, weapons atlevel2/everythird, plus15%heal/shield refill. Both5choices/onepick. Effect pools overlap; deeper reward identity remains open.

## Completed local checkpoints
- f161c1e: five readable illustrated reward cards, selected comparison, HP/shield HUD, controller/focus checks.
- 9616aeb: camera/ordinary enemy scale/player locator/calmer terrain/staggered30Hz enemy updates. Fixed crowded scenario p9518.872→13.814ms; not universal60fps.
- 037b67f: opening XP threshold14, first woods chest38–45m;24chests/four per biome retained.
- 2607106: dusk forest menu/animated hero portrait/controller focus.
- 1602b90: corrected diagnostic-only soak sampling.
- 69568de: named boss arrivals/banner/healthbar;600sEclipse with30s escalation; portal vortex/beacon/direction; portal summons guardian whose defeat permits travel/final victory. Co-op wired but fresh network roundtrip remains untested.
- 3df475b: organic coastline shared by terrain/water/death/map; north-up single-frame minimap; inland chests.
- 54cc3d2: generated moss/stone ground textures. Built-in imagegen; full prompts/provenance native/docs/generated-art.md. Ground improved, foreground props remain oversized in places.
- 6270c96: compact clock/status, one-line controls hint, larger hinged chests, opening before modal, five actual-icon reels with synchronized latch/tick/lock cues. Bindings preserved in settings.
- cdc30f8: three original53.333s realm themes plus quiet/heavy backing section variation; theme does not restart each phrase. scripts/create-realm-music.py reproducible asset source.

## Latest fresh evidence
Full reports: .build-staging/agent-workflow/<timestamp>-ACTION/result.json.
- Latest playable EXE G:/game/.build-staging/agent-workflow/2026-10-07T16-20-25-309Z-build/Wildforge.exe. Keep PCK beside EXE. Import/parse/export and71exported smoke boolean checks+9metadata passed. Four new music checks cover long clips, continuity, pause and realm/boss transitions.
- check2026-10-07T16-19-49-513Z:13JS+Godot parse/import passed. Final smoke additions compiled in final build above.
- capture-ui16-13-16:8PNGs/focus/layout passed; HUD, opening and reels inspected. Final sound-only changes followed this render.
- integration55passed16-02-51; journey-review13booleans16-02-37 (coast, guardian, timer, progression) and screenshots inspected.
- Six-biome soak16-07-10: p5014.015ms,p9523.519ms,minimumspacing0.937; forest/moon/space PNGs inspected. Random scenario not comparable to fixed combat benchmark; no universal60fpsclaim.
- New music generator checked durations, zero clipping, faded endpoints. No subjective listening review yet.

## Next concrete batch
Review actual hero/enemy/material and foreground prop art before/after. Prioritize readable consistent art over content counts. Semantic icon audit still open; do not claim all694icons match. Then optional encounters/endgame expansion and music listening/mix review. All wider PLAN phase acceptance criteria remain unfinished.

## Working state and commands
Preserve preexisting modified AGENTS.md, untracked native/docs/golden-scene.png and nul. Never stage/delete those. No user saves deleted; no mod changes; no new publication.
Use node scripts/agent-workflow.mjs check|smoke|integration|capture-ui|combat-review|pace-review|soak|journey-review|build. Wrapper isolates APPDATA and preserves logs. No improvised engine arguments. Build is development artifact, not distributable release with all notices. vision_analyze unavailable: use view_image and inspect actual PNG.
Python: C:/Users/rytis/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe. Current source music assets require import (wrapper does this in check/build). No active tool sessions.

Batch11 checkpoint: opt-in scenery sightline cutaway, smaller decorative props, independent outline materials; new scenery-review wrapper. Before16-26-40/after16-28-14 PNGs inspected (hero visible behind tree/moon prop). Integration55passed16-27-51; latest build G:/game/.build-staging/agent-workflow/2026-10-07T16-28-25-113Z-build/Wildforge.exe passed71smoke+9metadata. Next hero costume/material presentation.

Batch12 complete: hero_surfaces.gd and hero_surface shader categorize garment/leather/metal/ceramic surfaces. Subtle polish, not new skins/models. Check13+parse16-30-22; before/after8UI captures16-29-50/16-30-38, duck/potato inspected. Latest build16-31-00 passed71smoke. Next timed optional hunt event; no event edits yet.

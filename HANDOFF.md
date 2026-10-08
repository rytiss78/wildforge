# Wildforge handoff — 2026-10-08

## Current objective
User urgently requested fixing Hermes build, producing test EXE and removing old builds. Standalone Wildforge only; one agent. Build repair is complete. Cleanup is blocked. Broader roadmap remains unfinished.

## Tested deliverable
- G:/game/build/Wildforge.exe; keep Wildforge.pck alongside.
- G:/game/dist/Wildforge-test-2026-10-08-Windows.zip (8 entries, executable/package plus existing notices).
- Exact tested source export: .build-staging/agent-workflow/2026-10-08T13-33-24-114Z-build/.
- Promoted EXE/PCK SHA256 matches staging; proof promoted-test-build.json. ZIP SHA256 in dist/SHA256SUMS.txt.

## Changes
Removed 27 accidental leading pipes from rules.gd. Preserved Hermes inverse-family loot weighting and HUD/card/damage overlay edits in this tested checkpoint. Added agent-workflow test-build to run exported EXE with isolated profile and rendered combat capture.
Previous all-65 weapon icon/model matching complete (fdc19fe), documented native/docs/weapon-identity.md. Broader art and semantic card audit remains open.

## Fresh validation
All reports under .build-staging/agent-workflow/:
- check 2026-10-08T13-32-46-694Z: 13 JS tests + Godot import/parse passed.
- build 2026-10-08T13-33-24-114Z: export + 72 exported smoke booleans passed; 9 metadata fields.
- capture-ui 2026-10-08T13-33-34-261Z: 11 PNGs and focus/layout assertions passed; offers image inspected.
- test-build 2026-10-08T13-34-25-338Z: actual exported EXE rendered combat and exited; PNG inspected. Hero/weapons/enemies/HUD visible. Not performance certification.
Commands: node scripts/agent-workflow.mjs check|build|capture-ui|test-build. Other established actions retained. Isolated APPDATA avoids saves.

## Blocker and next tasks
Old local build deletion command was rejected by automatic approval review: "blocked by policy", no detailed reason. No files were deleted. Do not work around this rejection using another tool. Old GitHub releases also still present; earlier user authorized local and old GitHub release removal and git push. Keep latest standalone published release and ignore mod releases.
Next development batch: black-hole/poison field visuals and punchier gun audio (user requested, not yet implemented). Then audit inverse-family weighting (not proven to improve rare drops), damage-number aggregation and stale labels when array empties. Broader PLAN covers remaining gameplay/art.

## Preserve unrelated changes
AGENTS.md modified before this batch. Entire mods/megabonk-wildforge tracked tree deleted by another process/Hermes; not staged here. Untracked native/docs/golden-scene.png, scenery-review-0.png, scenery-review-2.png and nul retained. Never delete saves, logs, captures or history. See PROGRESS.md for prior milestones and exact fresh results.

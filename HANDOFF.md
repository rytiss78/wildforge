# Wildforge handoff — 2026-10-08
## Current objective
User's latest correction: damage labels must rise from bottom edge. Implemented and verified in current local export. Continue five requests in PLAN section Co-op reliability and rejected presentation: flowers, owned damage, complete icon remake, stationary enemies, intelligible hero/boss voices. One agent only; group builds/uploads.
## Current delivery
Latest public download: https://github.com/rytiss78/wildforge/releases/tag/v0.8.2-test.1 (1a96f9b). Source pushed; ZIP/checksum published on explicit user request. Remote asset sizes/digests verified. ZIP dist/Wildforge-0.8.2-test.1-Windows.zip matches tested17-35-38 export. Stable build folder unchanged. Prior progression release retained. Preserve history/saves/logs.
Latest playable local: G:/game/.build-staging/agent-workflow/2026-10-08T17-35-38-980Z-build/Wildforge.exe with adjacent Wildforge.pck. Development staging, not fully packaged public release.
## Latest source batch
Remote flowers: compact per-peer state, growth/bloom/removal/realm cleanup, visual-only replicas (no duplicate healing/damage). Protocol direct-6 requires matching builds.
Damage: host-confirmed owner-only ordinary hits and fire/poison DOT; no client predicted duplicates. Per-status ownership. Bottom-edge labels begin just inside screen and rise35%screen height, fade unchanged. World position metadata retained but labels aren't target-anchored.
New coop_feedback_review.gd diagnostic and wrapper coop-feedback; exported test-build includes it. Real co-op scenario verifies remote flowers/own numbers on both roles.
## Fresh validation
Commands: node scripts/agent-workflow.mjs ACTION. Logs/results .build-staging/agent-workflow/2026-10-08T... and latest-ACTION.json.
check17-35-23:13JS+Godot import/parse. Earlier17-26-51 class_name placement failure fixed;17-27-52 also passed.
coop-feedback17-31-14:13booleans including PNG, bottom start/upward animation. Source PNG visually inspected. Earlier17-29-47 target-label layout superseded.
coop17-29-58:both real roles pass including remote_flowers and own_damage_numbers.
build17-35-38:72exported smoke booleans+9metadata.
test-build17-36-01:combat4,coopFeedback13,eclipse13,feedback13,controls12,surface15,progression16,journey21; zero false. Exported coop-feedback PNG inspected: lower rising label visible. No claim of multiplayer ownership coverage for every special mechanic yet.
## Next concrete work
Audit remote stomp shortcut in coop.gd301: currently kill_enemy directly / boss hurt without hit_owner; not covered by ownership tests. Keep damage PLAN checkbox open until audit.
Stationary enemies: confirmed explicit game.gd1503 distance>55 ordinary-enemy continue; enemy steering875 and EnemySurface acquire only elevated targets>=1.5. Reproduce far60m and same-height/downhill mountain scenarios, implement/test before broadening. Existing surface-review15 must remain meaningful.
Voices: lt-LT-LeonasNeural generation succeeded through edge_tts in tools/music-env; preview .build-staging/boss-neural-preview.mp3. Not listened/shipped. Current boss assets still eSpeak with runtime pitch.88, hero mixed Kokoro/Pocket. Need natural-pitch clearer replacements and accurate provenance. Official Azure language support lists Lithuanian neural voices.
Icons: user explicitly rejected344procedural3D thumbnails. Complete detailed2D remake still open. Read imagegen skill already (C:/Users/rytis/.codex/skills/.system/imagegen/SKILL.md); tool not yet invoked. Announce skill before use, inspect actual result, avoid declaring templates/distinct hashes proof of quality.
## Prior implemented systems retained
800m organic island/deadly sea24chests,5choices,65weapons/696loot. Attraction/repulsion, progression/ExtraHop balancing. Surface wall/ceiling/ledge/slope climbing toward elevated players, co-op orientation.19saved bindings.6mXP/coin merge; poison hit SFX removed. Simplified stats/report icons/bottom skill strip/ping sound+offscreen direction. Boss curses7sbudget.
Eclipse PARANOIA approximate3-track MIDI+116.4sPCM, slight grounded drift14/s and braking22/s. Original M:/Music/Phonk/PARANOIA.mp3 unchanged; no listening/likeness claim. Scripts transcribe-eclipse-music.py/render-eclipse-midi.py use tools/music-env. Earlier Ogg encode crash fixed using stdlibPCM. Broader art/voices/performance/fun remain open.
## Preserve / tools
Preexisting modified AGENTS.md; untracked native/docs/golden-scene.png, scenery-review-0.png, scenery-review-2.png and nul. Do not stage these. Current intended batch includes PLAN/PROGRESS/HANDOFF, native/docs/coop.md, big_update.gd/coop.gd/game.gd/hud.gd/coop_feedback_review.gd, scripts/agent-workflow.mjs.
Use wrapper actions check/smoke/capture/build; no improvised engine flags. node on PATH works; fallback C:/Users/rytis/AppData/Local/hermes/tools/node-26.7.0-win32-x64/node.exe. Bundled Python for PIL, tools/music-env Python for music/edge_tts. No simultaneous agents. Fresh build diagnostics isolate APPDATA.

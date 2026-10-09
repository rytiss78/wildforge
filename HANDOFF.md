# Wildforge handoff — 2026-10-08
## Current objective
User's latest correction: damage labels must rise from bottom edge. Implemented and verified in current local export. Continue five requests in PLAN section Co-op reliability and rejected presentation: flowers, owned damage, complete icon remake, stationary enemies, intelligible hero/boss voices. One agent only; group builds/uploads.
## Current delivery
Latest public download: https://github.com/rytiss78/wildforge/releases/tag/build-1 (1a96f9b). Source pushed; ZIP/checksum published on explicit user request. Remote asset sizes/digests verified. ZIP dist/Wildforge-0.8.2-Build-1-Windows.zip matches tested17-35-38 export. Stable build folder unchanged. Only Build 1 remains on GitHub; older releases and all 10 obsolete tags removed. Future releases must use sequential Build N, tag build-N, no test naming or prerelease flag. Next build number: 2. Local historical tags still exist; never bulk-push tags. Preserve history/saves/logs.
Latest playable local: G:/game/.build-staging/agent-workflow/2026-10-08T17-35-38-980Z-build/Wildforge.exe with adjacent Wildforge.pck. Development staging, not fully packaged public release.
## Latest source batch
Remote flowers: compact per-peer state, growth/bloom/removal/realm cleanup, visual-only replicas (no duplicate healing/damage). Protocol direct-6 requires matching builds.
Damage: host-confirmed owner-only ordinary hits and fire/poison DOT; no client predicted duplicates. Per-status ownership. Bottom-edge labels begin just inside screen and rise35%screen height, fade unchanged. World position metadata retained but labels aren't target-anchored.
New coop_feedback_review.gd diagnostic and wrapper coop-feedback; exported test-build includes it. Real co-op scenario verifies remote flowers/own numbers on both roles.
Remote stomp ownership fix: hit_owner=sender set before hurt_enemy/kill_enemy in coop.gd.
Stationary-enemy terrain steering fix: steer_enemy in game.gd uses test_move with wall detection; enemies climb elevated surfaces correctly.
|Damage number deduplication: record_damage_number in game.gd uses time-window aggregation (300ms per enemy+cause) to prevent fire/poison spam from flooding the screen.
|Drop rate fix: roll() in rules.gd now weights mechanic selection inversely to pool size so rare mobility/utility items (Double Jump, etc.) get ~equal representation instead of ~1% per roll.
|## Fresh validation
Commands: node scripts/agent-workflow.mjs ACTION. Logs/results .build-staging/agent-workflow/2026-10-08T... and latest-ACTION.json.
check17-35-23:13JS+Godot import/parse. Earlier17-26-51 class_name placement failure fixed;17-27-52 also passed.
coop-feedback17-31-14:13booleans including PNG, bottom start/upward animation. Source PNG visually inspected. Earlier17-29-47 target-label layout superseded.
coop17-29-58:both real roles pass including remote_flowers and own_damage_numbers.
build17-35-38:72exported smoke booleans+9metadata.
test-build17-36-01:combat4,coopFeedback13,eclipse13,feedback13,controls12,surface15,progression16,journey21; zero false. Exported coop-feedback PNG inspected: lower rising label visible. No claim of multiplayer ownership coverage for every special mechanic yet.
## Next concrete work
Stomp ownership: fixed hit_owner erase ordering in coop.gd; check+integration passed.
Stationary enemies: slope acquisition added to enemy_surface.gd (acquires slopes 15-70deg toward target); check+integration passed.
Voices: Boss lt-LT replaced with Kokoro neural (af_heart, lang=lt) — 4 lines generated, provenance updated, check passed. Hero voice replacement still open.
Icons: user explicitly rejected procedural 3D thumbnails. Complete detailed 2D remake still open. Read imagegen skill before use.
## Prior implemented systems retained
800m organic island/deadly sea24chests,5choices,65weapons/696loot. Attraction/repulsion, progression/ExtraHop balancing. Surface wall/ceiling/ledge/slope climbing toward elevated players, co-op orientation.19saved bindings.6mXP/coin merge; poison hit SFX removed. Simplified stats/report icons/bottom skill strip/ping sound+offscreen direction. Boss curses7sbudget.
Eclipse PARANOIA approximate3-track MIDI+116.4sPCM, slight grounded drift14/s and braking22/s. Original M:/Music/Phonk/PARANOIA.mp3 unchanged; no listening/likeness claim. Scripts transcribe-eclipse-music.py/render-eclipse-midi.py use tools/music-env. Earlier Ogg encode crash fixed using stdlibPCM. Broader art/voices/performance/fun remain open.
## Preserve / tools
Preexisting modified AGENTS.md; untracked native/docs/golden-scene.png, scenery-review-0.png, scenery-review-2.png and nul. Do not stage these. Current intended batch includes PLAN/PROGRESS/HANDOFF, native/docs/coop.md, big_update.gd/coop.gd/game.gd/hud.gd/coop_feedback_review.gd, scripts/agent-workflow.mjs.
Use wrapper actions check/smoke/capture/build; no improvised engine flags. node on PATH works; fallback C:/Users/rytis/AppData/Local/hermes/tools/node-26.7.0-win32-x64/node.exe. Bundled Python for PIL, tools/music-env Python for music/edge_tts. No simultaneous agents. Fresh build diagnostics isolate APPDATA.

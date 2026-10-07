# Wildforge current handoff
Updated2026-10-07. Standalone quality overhaul; ignore mods/megabonk-wildforge. One agent. Read AGENTS.md and relevant PLAN/PROGRESS; do not claim the full game is finished.

## Objective / priorities
User says continue developing. Earlier requests: better movement/combat/readability, organic800m island/dead sea/24chests,5choices, semantic icons, improved characters/items/guns/buildings/trees, longer music, compactHUD, animated/audio slot-machine chests, impactful bosses, meaningfultimerend, visibleportal summoning finalguardian, moreevents/endgame.
Chest vs level explained: chestitems/exploration/gold, bossfreeRareminimum; levelskills/weaponat2andmultiples3 +15%heal/shield. Both5choose1. Effect pools still overlap; deeper rewardidentity open.

## Local completed checkpoints
f161c1e cards/focus/HPHUD;9616aeb camera/enemy scale/player locator/staggered30Hz updates;037b67f openingXP14/firstchest38–45m;2607106 menu/hero preview;1602b90 diagnostic sampler.
69568de portal guardian/Eclipse/boss arrivals;3df475b organic coast/single-frame north-upmap;54cc3d2 generated moss/stone materials (fullprompts native/docs/generated-art.md);6270c96 compactHUD/largerhingedchests/fivereels/audio;cdc30f8 three original53s realmthemes/evolvingbacking.
4e3b2e6 scenery camera-to-hero stippled cutaway (paint+outline), smallerdecorativeprops. Actor/projectile materials optout; outlinesindependent. Fixed obstructingtree/moonprop before/after inspected.
44a6039 hero cloth/leather/metal/ceramic material categories. Subtle polish; no new character models or selectable skins.
8901d4c Hunter's Oath: shrine60,-35m, available60s; optional3marked tougher ordinary foes/45s; freeRare+chest per player on success; no-cost timeout; oneattempt/realm. Shrine/targetminimapmarks, compactprogress. Host-authoritative activation; replicated state drives each player's reward exactly once.
71a07a4:14semantic potion SVG icons now match world bottle palettes and effects, replacing unrelated skill art. Generator scripts/create-potion-icons.py.

## Latest fresh validation / playable build
EXE G:/game/.build-staging/agent-workflow/2026-10-07T16-51-20-084Z-build/Wildforge.exe. Keep Wildforge.pck alongside. Final import/parse/export and72exported smoke booleans+9metadata passed. Development artifact, not release distribution.
check16-40-40:13JS+parse/import passed. Final UI diagnostic compiled in build above.
capture-ui16-41-13:10PNGs/focus/layout assertions. All14potion icons contact sheet and four-buff gameplayHUD inspected; before16-39-43 inspected. Earliermaterial before16-29-50/after16-30-38 duck/potato inspected.
hunt-review16-36-27:11booleans including gated/proximityactivation,nocharge,3marks,duplicateblock,timeout,reset,singlereward,5Rare+offers,captures. Active/completePNG inspected.
coop16-35-44: realhost/client passed role-specific checks; client233snapshots/9kills,host15remotehits. Clientinitiatedhunt,bothrewardchests,guardian defeat replication,rescue/merchant/supply/realm/pause verified. Host party_pause/realm_received false are role-specific metadata, not failedassertions.
integration55passed16-36-54 before clearance-only final line. Finalcheck16-37-25 failed indentation in newclearanceline; corrected,16-37-57 passed. Subsequentbuilds clean.
Baseline soak16-25-14 produced6biomePNG; moonforegroundobstruction inspected. Performance not freshlybenchmarked after newchanges. Previousrandomsoak p9523.519ms; no universal60fps claim.
Music numerically checked duration/no clipping/fadedendpoints; subjective listening review still open.

## Next concrete work
Stronger scenery/weapon art and general item/skill/weapon semantic icon audit. Existing694icon count does not establish semantics/quality. Character material pass is not model replacement. Normal-play hunt balance (including otherheroes), additionalendgame and musicmixreview remain open. Continue bounded implement/run/inspect/commit batches; no routinepermission needed.

## Commands / preserved state
node scripts/agent-workflow.mjs check|smoke|integration|capture-ui|combat-review|pace-review|soak|journey-review|scenery-review|hunt-review|coop|build. Wrapper isolates APPDATA, bounds runtime, saves full logs/results. No improvisedengineargs. view_image used because vision_analyze unavailable.
Python C:/Users/rytis/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe.
Preserve preexisting modified AGENTS.md, untracked native/docs/golden-scene.png and nul; never stage/delete them. No savesdeleted,modedits,publishing. No active tool sessions.

Latest batch15: user requested allguns match icons. Fixed elemental model identities and rendered all65icons from WeaponModel (sameheld/previewconstructor); prioritylookup bypasses legacycontentart. All65distinct; fullcontactsheet/QueenTeaIceGun UI inspected. Finalcheck13JS+parse16-49-19;capture-ui16-49-58 now11PNGs. Firstexport16-50-10 failed stale128/768iconresolutionassertion; acceptednew256afterpublicrenderverification. Finalexport16-51-20 passed72smoke+9metadata. native/docs/weapon-identity.md documents regeneration; new wrapper weapon-icons. Specific gun/icon mismatch request complete. Broader nonweaponsemantic/modelquality roadmap remains open.

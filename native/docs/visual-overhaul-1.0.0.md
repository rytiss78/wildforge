# Wildforge 1.0.0 — complete visual overhaul

Requested October 12, 2026. This is the active roadmap for a new implementation session. Target release: **1.0.0**. The verified local starting build is **0.8.10**; this document does not declare 1.0.0 implemented.

## User requirements and fixed constraints

- Redesign everything visual with the supplied Hades screenshots as the art-direction reference: HUD, menus, cards, buffs, guns, achievements, portraits/busts, icons, textures, terrain/map, models, buildings, props, lighting and effects.
- **Keep the current camera placement and controls.** Do not switch to Hades' isometric camera. Save baseline camera parameters and test orbit, zoom, controller and mouse behavior against them.
- **Damage numbers rise from the bottom of the screen.** Replace the 0.8.10 actor-projected placement with a lower-screen emission band above occupied HUD space. Retain readable bold numbers, outlines, critical/healing distinctions, pooling and damage accounting. They must visibly travel upward and fade, without covering the lower HUD or modal choices.
- **Heroes and enemies retain orb-based HP indication.** Restyle the orbs so they belong to the new art direction while preserving their health/shield readability, including remote co-op actors and bosses. Do not replace this system with the health bars in the reference screenshots. Audit existing stray actor health bars.
- Add more rotating bosses inspired by Trevor Henderson's towering, uncanny monsters, including the broad Siren Head direction. Design original silhouettes and names that fit Wildforge, with distinct attacks and readable telegraphs. Starting scope: eight bosses; rotation must actually change encounters.
- Remove superseded assets from the local project and GitHub's current source tree after replacements pass validation. Use explicit reviewed deletion manifests and normal deletion commits. Do not rewrite Git history or delete saves, logs, reference images, or historical executables under the label of asset cleanup.
- Update About, README, release notes and screenshots for the actual final 1.0.0 build.
- Work in steps in a **new session**. Commit and push tested milestones regularly, not just at the end. The user explicitly authorizes these GitHub pushes and removal of replaced assets.

## Art direction

Use original game assets informed by the supplied images: strongly inked silhouettes, angular sculpted shapes, painted surfaces, deep charcoal shadows, emerald spectral light, crimson/lava accents, aged gold, bone and restrained ivory lettering. Rich architectural detail and controlled bright effects should frame the action without hiding enemies or terrain. Ornate dark panels, sharp borders, distinct illustrated symbols and coherent material treatment replace the current cream cards and soft pastel primitive appearance.

The references guide visual treatment, not camera, health mechanics or a wholesale change to the game's rules. Preserve each hero's identity and each weapon's readable silhouette. Interpret the six existing biomes through this new language, with their own palettes and landmarks. Materials alone are insufficient: character silhouettes, terrain dressing, architecture, UI compositions and icon artwork all need a coherent redesign.

Reference files are copied locally to `.build-staging/visual-overhaul-1.0.0/references/hades-01.png` through `hades-05.png`. These are the user's supplied screenshots, for reference only; do not ship them as game assets or use them as new README gameplay screenshots. Original attachment names are listed in `references/manifest.json`.

## Milestones

Mark a milestone complete only after its listed behavior and visual checks pass. Add commit, push, evidence and build information to the ledger below. Continue autonomously through the milestones; a checkpoint is not an automatic permission stop.

### 0 — Audited baseline and asset inventory `[ ]`

- Read `AGENTS.md`, `HERMES.md`, the Godot workflow and repair reports. Inspect both staged and unstaged content. The incoming index contains 728 changed files plus previous repair work; preserve it and classify changes before making commits. Never sweep everything into a visual-overhaul commit without reviewing it.
- Establish branch `codex/1.0.0-visual-overhaul` from the actual current working state, including the 0.8.10 repair files. Do not start from a clean remote branch that silently loses the local repairs. Record pre-overhaul source/index state recoverably.
- Reconcile the local repair baseline into an explicitly described checkpoint, separately from new visual work. Review files for secrets and generated/import/cache content; never print credential-bearing remote URLs. Push the baseline/roadmap checkpoint once coherent. Preserve unrelated file contents and report anything that cannot safely be included.
- Inventory every runtime asset family, generator, import and fallback path. Record replacement owner, references, replacement status and eventual deletion status in an asset manifest. Include embedded meshes, shader materials, baked resources and UI-drawn icons, not just PNGs.
- Record baseline screenshots, camera parameters, orb states, frame/node/memory measurements and known failing checks. Run the relevant wrapper checks against the current state.

### 1 — Shared visual foundations and first playable scene `[ ]`

- Introduce reusable palette/material, lighting, outline, typography and panel/icon rules. Use actual modeled silhouettes and painted detail; avoid applying a dark tint to unchanged pastel assets and calling the overhaul complete.
- Build one finished representative scene: one biome area with terrain, architecture and props, one hero, common enemies, one weapon, one harvestable and an early boss design, together with the HUD and one reward screen.
- Preserve the existing camera. Verify orbs and attack telegraphs remain readable in bright and dark areas. Exercise the new bottom-rising damage-number behavior in real combat.
- Capture source and exported gameplay at the unchanged camera, 720p/810p/1080p UI layouts, and compare representative frame measurements. Resolve readability/performance problems before multiplying assets across the game.
- Commit and push this working scene, including real screenshots and review notes.

### 2 — Complete UI, illustrated icons and portraits `[ ]`

- Apply the visual system to main menu, solo/co-op hero selection, specialty previews, pause, settings, controls, run report, About, chest reveal, reward selection, build/inventory, minimap and map overlays, party indicators, tooltips, prompts and achievement banners.
- Redesign all card, skill, item, buff/potion, gun/weapon, achievement and hero portrait/bust art. Use semantically distinct designs and full-catalog contact sheets to find duplicates or meaningless variations. Preserve rarity, selected/focus/disabled states, conditions and current-loadout compatibility.
- Keep the original synthesized achievement sound from 0.8.9; the user requested a visual overhaul, not a replacement sound recording.
- Exercise actual mouse/controller and co-op hero selection paths, long descriptions, full inventories and stacked buffs. Screens must remain readable at 720p and unclipped at 1080p.
- Commit and push coherent batches rather than one enormous undifferentiated asset commit.

### 3 — Heroes, enemies, weapons and combat visuals `[ ]`

- Redesign all 21 heroes and the common/elite enemy roster, preserving recognizable identities, animation attachments, melee contacts and weapon sockets. Replace visibly primitive placeholder geometry with intentional forms and surface detail.
- Restyle all handheld/deployed weapons, turrets, flowers, projectiles, pickups, shields, status effects, explosions, hit effects and orb HP visuals. Preserve useful color distinctions and accessibility at gameplay distance.
- Verify orb response across full/half/low HP, healing, shield/armor states, death, bosses and network snapshots. Cover both local and remote characters.
- Recheck collision bounds, small hills, walls, ceilings, hit locations, co-op visuals, damage-source accounting and render cost. Push each validated roster family.

### 4 — All biomes, map, architecture and harvestables `[ ]`

- Finish Clover Woods, Puffcap Marsh, Moon Craters, Cloud City, Candy Hell and Starfall Space as six distinct environments within the shared art direction.
- Replace terrain materials/textures, sky/atmosphere, foliage, rocks, roads/ruins, buildings, landmark structures, portal/hunt/shop architecture, environmental effects and minimap styling. Preserve movement geometry and camera behavior unless a specific collision repair is necessary.
- Bring all six harvestables into the new visual language while retaining names, biome matching, descriptions and the verified timed effects. Keep their placement clear of scenery.
- Validate every biome in normal play, across realms and with dark/bright effects active. Check streamed chunks and local/network consistency, traversal, performance and visual cohesion. Push each finished biome group.

### 5 — Expanded monster boss rotation `[ ]`

- Create eight original bosses with unmistakable silhouettes, purposeful animation, distinct telegraphs and encounter roles. Concept directions may include a signal-tower giant, bell-crowned walker, lantern-ribbed sentinel, hollow procession, many-jointed watcher, drowned spire, hanging maw and antlered monument; names/designs may evolve for quality.
- At least one towering signal/siren-inspired creature should express the user's monster reference. Avoid eight recolors of one skeleton. Keep boss HP expressed through the orb system and make the orb readable at the existing camera distance.
- Implement deterministic host-authoritative selection from the larger roster with no immediate repeats, appropriate biome/realm weights, collision sizes and correct rewards. Do not add bosses that exist only in preview scenes.
- Exercise every boss and multiple seeded rotations; verify host/client agreement, attack fairness, orb feedback, death, drops and guardian/portal progression. Push boss batches and rotation logic after targeted checks.

### 6 — Replacement audit and obsolete-asset removal `[ ]`

- Complete the replacement manifest and remove old runtime fallbacks and outdated generators that could restore obsolete visuals.
- Search references, preload/load paths, `.tscn`/`.tres`/`.res`, JSON catalogs, shaders, import sidecars and scripts. Delete only verified superseded project assets and their unused metadata. Resolve each absolute deletion target inside the intended project asset directories before deleting; never use a broad root cleanup.
- Remove tracked assets with normal Git deletion commits so the local project and GitHub branch both lose the old current files. Existing Git history remains recoverable; no force-push/history purge is authorized by this plan.
- Test a fresh import and export without relying on stale `.godot` cache. Check the exported pack for missing resources and obsolete assets. Commit and push the cleanup manifest and deletions.

### 7 — 1.0.0 release validation and documentation `[ ]`

- Run `check`, `smoke`, `integration`, relevant rendered feature reviews, all-boss/biome coverage and exported executable checks. Run the two-process co-op test sequentially with other port-using checks. Fix relevant regressions; investigate/document the existing realm-wraparound/teardown and Eclipse expectation failures instead of weakening assertions.
- Confirm camera invariants, bottom-rising damage, orb HP, weapon compatibility, leveling and harvest effects. Compare render measurements against the baseline; do not claim optimization without comparable evidence.
- Update all version metadata together to **1.0.0**, plus in-game About/credits, README, changelog and release/build instructions. Replace old README screenshots with actual final gameplay/menu/co-op/boss images from the new executable; verify all image links.
- Export a clearly named local 1.0.0 build, verify hashes and rendered behavior, and prepare accurate GitHub release notes/build artifacts. Regular source pushes are authorized. Record the publication status explicitly; never label an untested milestone as the finished 1.0.0 release.

## Checkpoint policy

- Commit and push after each tested milestone or substantial validated sub-batch. Keep baseline, UI, character art, environments, bosses, cleanup and release-documentation changes reviewable.
- Run commands from the repository root through `node scripts/agent-workflow.mjs`; follow [the workflow](godot-workflow.md). Inspect logs as well as exit codes and visually inspect screenshots. Do not run party-hosting tests together.
- Keep a short ledger row containing scope, acceptance result, evidence path, commit, remote push result and next work. If push fails, preserve the local commit, report the actual error without secrets, and continue independent work.
- User approval is not required at every step: this request authorizes the overhaul and regular pushes. Ask only when an unresolved choice materially changes scope or requires a destructive operation beyond replacing obsolete assets.

## Progress ledger

| Step | Status | Evidence / commit / push |
| --- | --- | --- |
| Roadmap and reference handoff | Prepared in the original repair session | This document and local reference manifest; implementation starts in the new session |
| 0 — audited source baseline | Source checkpoint pushed; orb coverage pending | `4ffec33`; [audit/inventory](visual-baseline-1.0.0.md); original mixed index preserved |
| 1a — UI foundation + bottom damage | Validated development sub-batch | [Evidence/build/screenshots](visual-foundation-1.0.0.md); commit/push recorded below |
| 1b–7 | Open | Representative scene, complete catalogs/rosters/biomes/bosses, cleanup and release remain |

Baseline context: [0.8.10 repair](gameplay-repair-0.8.10.md), [earlier audit](repair-audit-2026-10-12.md), [project rules](../../AGENTS.md).

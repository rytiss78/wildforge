# Wildforge Development Plan
**Goal:** Transform from alpha prototype to a polished, good-looking, fun-to-play endless survivor game.
**Current:** standalone overhaul in progress (2026-10-07). Reward cards and health HUD improved; combat camera/scale and measured frame spikes improved; opening pace and menu presentation are next. Published v0.8.2 is historical, not this development build.
**Target:** Consistent whimsical-surreal art direction, readable UI, juicy combat feel, responsive controls, 60fps on target PC.

**Working principle:** Every increment is git-committed, screenshot-verified, and test-passing. Plans live on disk (this file + milestone docs) so long-horizon work survives context resets. Each phase has a "definition of done" with concrete checks.

---

## Phase 0 — Style Lock & Foundation (Week 1)
**Goal:** Establish the visual language so everything after it is consistent.

### 0.1 Art direction document
- Write `native/docs/art-direction.md`: palette (5 core colors + biome accents), typography (display font for titles, body font for UI), shape language (rounded vs angular), lighting mood, particle style
- Define the "one sentence" style: *warm, whimsical, slightly surreal — like a storybook came to life and got a bit dangerous*
- Reference: the existing illustrated icon style (painted, warm outlines) is the north star

### 0.2 Golden scene
- Build one small scene: hero + 2 enemies + 1 chest + ground + sky
- Apply the full art direction: proper lighting, contact shadows, particle ambience
- Screenshot and save as `native/docs/golden-scene.png`
- This is the quality bar for everything else

### 0.3 Verification pipeline
- Ensure `node scripts/native.mjs --test` (55 checks) is the gate
- Add screenshot capture at each milestone (non-headless) for visual regression
- Git: commit at every meaningful step

**Done when:** `art-direction.md` exists, golden scene looks intentional, tests pass.

---

## Phase 1 — UI & Menu Overhaul (Week 1-2)
**Goal:** Kill the "flat beige rectangle" look. This is the most visible ugliness.

### 1.1 Theme system
- Create `native/scripts/theme.gd`: centralized color palette, font assignments, spacing tokens
- All UI scripts reference theme.gd instead of hard-coded colors
- Fonts: use a display font (rounded, characterful) for titles; clean sans for body
- Colors: warm parchment → deeper tones; rarity colors (Common=gray, Rare=blue, Epic=purple, Legendary=gold)

### 1.2 Card redesign
- Card layout: icon top-left, name top-right, rarity bar (colored strip), description bottom
- Rarity glow: subtle colored border + inner shadow matching rarity
- Icon legibility: audit all 694 icons; flag ones that don't convey their effect (boxing glove → "Aura" is wrong)
- Hover state: slight scale up + tooltip with base comparison
- Selection state: clear highlight, not just focus border

### 1.3 Menu screens
- Main menu: hero display with slow idle rotation, thematic background (not flat parchment)
- Hero selection: larger portraits, name + tagline, smooth transition on select
- Pause menu: compact, doesn't obscure the world too much
- Level-up: dramatic moment — screen dim, cards slide in, "LEVEL UP" text with glow

### 1.4 HUD
- Health orb: cleaner, readable at distance
- Weapon bar: compact, shows rank with visual weight
- Minimap: themed border, clear icons
- Buff timers: icon + countdown, consistent size

**Done when:** Screenshots of menu, cards, HUD look intentional and cohesive. No flat beige rectangles. Rarity is instantly readable. Tests pass.

---

## Phase 2 — Character & World Quality (Week 2-4)
**Goal:** Make the world feel alive and characters feel present.

### 2.1 Character presentation
- Improve hero models: better proportions, more expressive idle poses
- Enemy readability: silhouettes distinguishable at gameplay camera distance
- Contact shadows under all characters
- Hit reactions: brief squash/stretch, white flash on damage
- Death: particles + shrink/fade, not just disappear

### 2.2 World props & terrain
- Terrain: painted textures (already exists) — verify tiling, contrast, no visible seams
- Props (trees, rocks, chests): consistent style, proper scale, contact shadows
- Biome transitions: smooth material blends, clear visual boundaries
- Scenery density: enough to feel alive, not so much it hides enemies

### 2.3 Lighting & atmosphere
- Directional light per biome (warm woods, cool frost, etc.)
- Ambient occlusion (if performance allows)
- Fog: subtle distance fog for depth
- Sky: per-biome gradient (already has biome_sky.gdshader — verify quality)

### 2.4 Particle effects
- Ambient: floating dust/spores/petals per biome
- Combat: hit sparks, blood/sap splatter per creature type
- Status: fire (embers), poison (green bubbles), ice (crystal shards)
- Level-up: burst of light + rising particles
- Chest open: sparkle burst + light

**Done when:** Golden scene matches Phase 0 quality bar in all 6 biomes. Characters and enemies are readable at gameplay distance. Tests pass.

---

## Phase 3 — Gameplay Feel & Audio (Week 3-5)
**Goal:** Make combat feel good. Juice.

### 3.1 Combat juice
- Screen shake: small on hits, medium on criticals, large on explosions
- Hit flash: enemies flash white 50ms on damage
- Damage numbers: floating, colored by type (physical=white, fire=orange, poison=green)
- Kill feedback: squash + particles + sound, slight camera pulse on multi-kills
- Weapon recoil: each weapon type has distinct visual kick

### 3.2 Audio
- Weapon sounds: distinct per type (pistol crack, shotgun boom, rail zap)
- Hit sounds: material-sensitive (metal clang, flesh thud, plant squish)
- Status: fire crackle, poison bubble, ice crack
- UI: card select (satisfying click), level up (rising chime), chest open (sparkle)
- Music: per-biome ambient, boss theme, level-up sting
- Audio pooling: no new AudioStreamPlayer per bullet (performance)

### 3.3 Control feel
- Movement: acceleration/deceleration (not instant), slight camera lead
- Dash: brief invulnerability frames + trail effect
- Jump: anticipation (crouch) → launch → land (dust puff)
- Camera: smooth follow with slight lag, zoom out on dash, zoom in on boss

### 3.4 Enemy readability
- Attack telegraphs: wind-up animation before attack
- Elite markers: glowing outline + name tag
- Boss: health bar top of screen, phase transitions with dramatic moment

**Done when:** Playing 5 minutes feels satisfying. Combat is readable. Audio is present and non-annoying. Tests pass.

---

## Phase 4 — Content & Balance (Week 4-6)
**Goal:** Expand variety and tune the loop.

### 4.1 New content
- 5+ new weapons with distinct mechanics
- 5+ new enemy types (1-2 per biome)
- 10+ new card entries (single-benefit, matching Phase 1 card design)
- 2-3 new hero abilities (if existing 21 feel repetitive)

### 4.2 Balance pass
- Run 10+ full sessions, record: time to clear, death points, power curve
- Adjust XP curve, enemy HP/damage scaling, chest prices
- Ensure all 65 weapons feel distinct (no "best weapon" that dominates)
- Rarity balance: Common is usable, Legendary is exciting but not broken

### 4.3 Progression
- Career progression: visible milestones, unlockable heroes
- Achievements: verify all 108 work, add 10-15 more for new content
- Score system: kill streaks, exploration bonuses, style points

**Done when:** 10 full runs feel varied. No single dominant build. All new content tested. Tests pass.

---

## Phase 5 — Polish & Release (Week 6-8)
**Goal:** Ship a build people want to play.

### 5.1 Performance
- Target: 60fps at 1080p on mid-range GPU
- Profile: GPU, CPU, memory, draw calls
- Optimization: LOD on props, cull distant enemies, batch particles
- Load time: <5s to playable

### 5.2 Bug pass
- Full run: all 6 biomes, all bosses, all 21 heroes
- Co-op: 4-player, all interactions
- Save/load: career, mid-run, achievements
- Edge cases: rapid pause/resume, window resize, controller disconnect

### 5.3 Accessibility
- Colorblind mode: shape + color for rarity
- UI scale: adjustable text size
- Audio: independent music/SFX volume
- Controls: full remapping, controller-first

### 5.4 Release
- Windows build (existing pipeline)
- README update with new features
- Screenshots for store page
- Version bump to 1.0 (or 0.9.0 if still alpha)

**Done when:** Build is stable, performant, fun, and looks good. Release is packaged.

---

## Workstream Division (for parallel agents)
| Workstream | Phase | Independent? |
|---|---|---|
| UI theme + cards | P1 | Yes (hud.gd, theme.gd, card rendering) |
| Character/world models | P2 | Yes (GLB assets, world.gd, actor_rig.gd) |
| Lighting/atmosphere | P2 | Partial (shaders, environment) |
| Combat juice | P3 | Yes (game.gd combat, particles) |
| Audio | P3 | Yes (sound.gd, assets/music, SFX) |
| New content (weapons/enemies) | P4 | Yes (catalog.json, rules.gd, content scripts) |
| Balance | P4 | No (needs content done first) |
| Performance | P5 | No (needs all content done) |

**Dependencies:** P0 → P1 → P2/P3 (parallel) → P4 → P5
**Parallelizable:** P2 and P3 can run concurrently. Content (P4) can start after P2 models are done.

## Verification Gates
- After every commit: `node scripts/native.mjs --test` passes
- After every phase: screenshot review against art-direction.md
- After P2/P3: 5-minute playtest, record feel notes
- After P4: 10 full runs, balance review
- After P5: full bug pass, performance profile

## File Map (where things live)
- **UI:** `native/scripts/hud.gd`, `native/scripts/theme.gd` (new)
- **Game logic:** `native/scripts/game.gd` (main loop), `native/scripts/rules.gd` (data/rules)
- **World:** `native/scripts/world.gd`, `native/scripts/biome_landmarks.gd`
- **Characters:** `native/scripts/actor_rig.gd`, `native/assets/style3d/*.glb`
- **Content data:** `native/data/catalog.json` (heroes, weapons, loot, achievements)
- **Icons:** `native/assets/illustrated/` (painted PNGs)
- **Shaders:** `native/shaders/*.gdshader`
- **Audio:** `native/assets/music/`, `native/scripts/sound.gd`
- **Tests:** `node scripts/native.mjs --test` (55 Godot checks), `npm test` (JS tests)
- **Build:** `build/Wildforge.exe`, `dist/Wildforge-0.8.2-Windows.zip`
- **Mod (frozen):** `mods/megabonk-wildforge/` — do not touch

## Current execution checkpoints — 2026-10-07

- Phase 1.2 card layout/focus: implemented and screenshot-reviewed. Five horizontal rarity cards, full selected comparison, keyboard/controller selection retained. Comprehensive 694-icon semantic audit remains open.
- Phase 1.4 HUD: HP/shield readout and bar added; controls recede after the opening. Further minimap/menu consolidation remains open.
- Next bounded deliverable: readable, responsive combat view. Capture an actual fixed-seed gameplay camera baseline; reduce terrain noise and oversized foreground enemies, then measure frame times before/after.
- Follow with encounter pacing and early reward cadence, then remaining menus/content quality. Do not add catalog volume before these foundations work.

### 2026-10-07 combat checkpoint
Phase 2 partial: gameplay camera, ordinary enemy scale, player locator and calmer terrain verified in actual crowded combat. Phase 3 performance partial: alternating enemy simulation reduced measured p95 from 18.872 to 13.814ms in a fixed stress scenario. Full biome review and later-run performance remain open. Next: measured opening reward pace.

### 2026-10-07 opening progression checkpoint
Opening XP curve and one closer chest delivered. Fixed normal-stat scenario reaches first choice13.77s and level4 at32.38s; previously died20.88s before any choice. 24chests/four per biome preserved. Later-run and other-hero balance still open. Next Phase1.3 menu presentation.

### 2026-10-07 menu checkpoint
Phase1.3 main menu/hero selection delivered and captured with two heroes/controller focus. Six-biome traversal inspected; player locatable but foreground props still large. Heavy soak p95 23.519ms needs clean diagnostic sampling before attributing all cost to gameplay. Next: correct sampler and verify heavy-crowd performance.

### 2026-10-07 verified playable preview
Final current-source Windows export: `.build-staging/agent-workflow/2026-10-07T15-44-29-883Z-build/Wildforge.exe`, exported67-check smoke passed. Cleaned diagnostic heavy-crowd soak p50 11.965ms/p95 16.702ms across6biomes. Measurement correction only. Next investigate low spacing metric, then other-hero/later-boss pacing. This is a tested preview; remaining phase acceptance criteria are still open.

## Priority update — 2026-10-07, user-directed continuation
1. Impactful boss arrivals, meaningful timer expiry, portal-summoned final guardian — implemented first checkpoint; tests and captures in PROGRESS.
2. Organic coastline + one coherent minimap — next.
3. Continue beyond these fixes: improved textures/skins, encounter mechanics/events, endgame and music. Do not stop at the first five requests or represent the whole game as finished.

Progression decision: two wardens awaken the portal early; at10minutes the Eclipse also awakens it, changes sky/music and escalates enemies every30s. Portal activation summons one final guardian, whose defeat permits travel; third-island guardian leads to victory. Existing three-world progression and builds preserved.

### Batch7 organic island complete
Seeded lobed coastline shared by terrain, dead-sea damage/water/sand shader and minimap. North-up single-frame map with distinct portal ring. Chests repositioned inland,24/four-per-biome preserved. Next art and gameplay/audio continuation.

### Additional user priorities (2026-10-07)
- Upgrade enemies, heroes, items, guns, buildings and trees visually; use suitable assets where engine-made art is inadequate.
- Icons must depict the represented item/effect, not merely be distinct.
- Longer or procedurally arranged music.
- Rethink gameplay overlay: movement instruction strip occupies too much space.
- Slightly larger boxes, visible opening animation/audio, retain slot-machine reward identity.
- Clarify and improve chest versus level reward progression: currently chest items/gold/exploration, level skills+periodic weapons/XP; effect pools overlap.
Next batch after ground materials: compact HUD and chest presentation. Then encounters, music and hero skins; all visual categories remain part of continuing development.

### Batch9 compact HUD and chest presentation complete
Larger hinged boxes, opening visible before modal, five actual reward-icon reels with sequential sound locks; full movement bindings remain in controls menu. Compact clock/status and one-line controls hint free gameplay space. Next longer evolving soundtrack, then encounters/character and prop art.

### Batch10 longer music complete (listening review open)
Three original53-second realm melodies sustain across backing phrases, with procedural quiet/heavy sections and boss response. Runtime continuity/pause/realm transition tested in exported build. Remaining: subjective mix/listening review. Next bounded batch: character/material and scenery art with before/after rendered acceptance, followed by semantic icon audit and encounter expansion.

### Batch11 scenery visibility complete
Smaller decorative scenery and camera-to-hero cutaway, matching outline behavior; fixed before/after tree and moon obstruction inspected. Traversal/collision integration and exported smoke pass. Next hero costume/material presentation, then semantic icons and gameplay encounters.

### Batch12 hero material pass
Cloth/leather/metal/ceramic differentiation implemented; original character silhouettes retained. New models/selectable skins remain open. Next optional timed hunt combat objective between bosses.

### Batch13 optional hunt delivered
Hunter's Oath shrine,3marked foes/45seconds, freeRare+chest on success, no-cost timeout. Solo state/reward tests and real two-process co-op (including portal guardian replication) passed. Next semantic potion icons; full694-icon audit and new character/weapon/prop assets remain open.

### Batch14 potion semantics complete
All14temporary-drink HUD icons now depict matching bottles/effect symbols; full-set and in-game renders inspected. General item/skill/weapon semantic audit remains open. Next stronger scenery/weapon assets, broader semantic audit and normal-play hunt balance before further endgame expansion.

### Batch15 all weapon model/icon identities fixed
User-provided IceGun mismatch traced to generic elemental GLBs plus independently illustrated card art. Added elemental model hardware/colors and regenerated all65weapon icons from the exact WeaponModel constructor used in hands/hero previews, including variants and sentries. Weapon image lookup takes precedence over legacy content art. All65PNG hashes distinct; full contact sheets and corrected QueenTea/IceGun preview inspected. See native/docs/weapon-identity.md for regeneration contract. Broader non-weapon item/skill semantics remain open.

# Wildforge Art Direction

Version: 0.1 (Phase 0 baseline) — describes the style as shipped in the current
native build, so new assets and UI work can be checked against it. Verified
values are cited from code; proposed values are marked **proposed** and need
a render check before being treated as canonical.

## 1. Overall style

Warm, whimsical storybook diorama: a small rounded world on a sheet of paper.

- Low-poly toon primitives (spheres, cylinders, boxes, prisms) with flat
  cel-style colors, no per-pixel shading noise. Built in `toon_art.gd`.
- Everything sits on illustrated paper: terrain is tiled from `terrain-0..5.png`
  (256×256 paper tiles, one per biome), and the world edges fade into fog and a
  "deadly sea" paper border rather than a horizon line.
- Ink is the organizing principle: dark indigo ink reads as the outline,
  pupil, and text color across models, portraits, and UI.
- Props may be either hand-illustrated paper sprites (`assets/illustrated/`,
  billboarded with alpha cutout) or baked GLB props (`assets/style3d/`, 11
  props: wooden sign, stone shrine, wooden gate, stone gate, lantern,
  stone lantern, stone pillar, wooden bench, stone well, wooden crate,
  stone crate) — both families share the same paper palette.
- Silhouette first: every actor and enemy must be identifiable by outline
  alone, at game distance, before color or detail is considered.

## 2. Core palette

Five core hex values used everywhere (verified in code):

| Role            | Hex       | Source / use |
|-----------------|-----------|--------------|
| Ink             | `#17293D` | outline/eye ink in `toon_art.gd`; use for UI text and icon strokes |
| Paper cream     | `#FFF8DE` | warm off-white for highlights, faces, HUD paper |
| Warm light      | `#FFF2DE` | cloud color, key-light tint; the "afternoon sun" note |
| Star gold       | `#FFF1C8` | accent gold for stars, pickups, reward glints |
| Earth terracotta| `#B67552` | trunks, crates, warm mid-tones in most biomes |

Supporting tones (verified): sky ambient `#E6EFFF` (cool, used only in
environment so the world stays warm), sun light `#FFF8EF` at 0.85 energy,
stone cool grays `#847D70` / `#849EB1` / `#9BB4B9`, parchment steam
`rgba(232,226,212,0.12)`.

Biome accents (verified from `world.gd` scenery):

| Biome | Accents |
|-------|---------|
| 0 Verdant | leaf `#9FBE8C`, pine `#51B899`, island orange `#ECAB8A` |
| 1 Rose dunes | petal `#BB8CA7`, blossom `#F5E9C9`, sand trunk `#E6D7BA` |
| 2 Meadow | sage `#9CAF76`, fruit `#E5AC95` |
| 3 Snow | ice `#8AB5B6`, snow `#E9F0E2`, moon glow `#FFF2DB` |
| 4 Ember dusk | rock `#947F7D`, ember `#E5A578`, bark `#B9886B` |
| 5 Prism (wildcard) | `COLORS[biome]` darkened variants — **proposed**: keep to desaturated jewel tones, no neon |

Rules:

- One warm color may dominate a frame; cool tones (sky, ice, stone) are
  contrast only, never the hero of a shot.
- New asset colors must come from this table (or a darkened/lightened
  variant of one of them). No pure white, no pure black, no saturated neon.
- Global grade: saturation ×1.04, contrast ×1.03 (`world.gd` environment) —
  restrained terrain contrast keeps characters readable.

## 3. Typography

**Proposed** (HUD fonts not yet audited — verify against `hud.gd` before
treating as canonical):

- Rounded humanist sans for all body text; no serifs, no condensed faces.
  **Proposed** fallback stack: "Baloo 2" / "Nunito" / system rounded.
- Body text minimum 16px equivalent at 1080p; numbers (gold, HP) at least
  20px so combat reads at a glance.
- Ink `#17293D` on paper `#FFF8DE` for all primary text; never paper-on-ink
  for long text, only for short labels on dark cards.
- One typeface per screen, max two weights (regular + bold). No italic, no
  all-caps body text. Titles may be bold, not decorated.
- Card and button labels ≤ 2 words where possible; secondary detail on a
  smaller second line.

## 4. Shapes

- Rounded everywhere: box props use small bevels or inset panels, UI cards
  use rounded rectangles (radius ≈ 8–12px at 1080p, **proposed**), no sharp
  corners on player-facing surfaces.
- Actors are built from balls and tubes (see `toon_art.gd`): head bigger
  than body, limbs stubby — the "plush toy" ratio. Keep new models in that
  proportion; a heroic silhouette is allowed to stretch, a toy is not.
- Eyes follow the shared `eyes()` helper: cream sclera, ink iris, white
  glint. Any new creature without eyes must still read friendly via shape.
- Paper edges (fog, sea, borders) are soft and matte; hard edges are reserved
  for ink outlines and UI strokes.

## 5. Lighting

- Single warm sun: `#FFF8EF`, 0.85 energy, fixed angle (−42°, −35°),
  shadows capped at 38m — one shadow direction per frame, never moving.
- Cool ambient `#E6EFFF` at 0.36 energy lifts shadows without killing the
  warm key.
- Fog: depth fog `#E6EFFF`-tinted, begins 35m, ends 155m; the world recedes
  into paper, not darkness. New biomes keep the same fog distances.
- Emissive accents are rare and gold-tinted (`#FFF1C8`): stars, moon glow,
  lanterns. Max one glow source per screen area of gameplay.

## 6. Particles and weather

Restrained by design:

- Weather: one 180-particle system per world (currently light rain), low
  alpha, no wind gusts.
- Border steam: 32 particles per side, only near the world edges.
- Combat feedback: short-lived (≤ 0.6s), small count (≤ 20 per event),
  from the core palette (ink, paper, gold, terracotta). **Proposed** rule:
  never more than 3 simultaneous particle emitters in the camera frustum.
- No particle trails on projectiles; use color flash + scale pop instead.

## 7. Readability criteria (measurable)

A new model, enemy, or UI change is acceptable only if it passes all:

1. **Contrast**: primary UI text ink `#17293D` on paper `#FFF8DE` measures
   ≥ 4.5:1 (actual ≈ 13:1); HP bars use ink fill on paper track, not
   red/green pairs alone (colorblind-safe: also differ in shape/position).
2. **Silhouette**: enemy identifiable by outline alone in a 50% gray flat
   render at 4m screen distance (test: render the model with a single
   unlit color and check the PNG).
3. **Color distinctness**: any two enemies that can share a screen differ
   by at least 2 palette roles (e.g. different base + different accent).
4. **Distance**: player and enemies stay fully visible within 35m (fog
   start); no required gameplay element depends on anything beyond 60m.
5. **Screen share**: a single enemy never exceeds 25% of viewport height
   at combat range; the hero never drops below 10% at standstill.
6. **Frame**: with camera at the standard combat position (hero + 3 enemies
   + 1 chest), every actionable element has ≥ 2 palette roles of contrast
   against everything behind it (checked in the golden-scene screenshot).
7. **Motion**: combat feedback readable at 1× speed on a 60Hz display;
   nothing important lasts < 100ms or is conveyed by flicker alone.

## 8. Asset status

- Verified in repo: `assets/illustrated/` paper textures, hero/creature
  PNGs, `assets/style3d/` 11 GLB props (see `style-lab.md`), terrain tiles,
  `paper.png`.
- **Proposed / unverified**: UI font choice, exact card corner radii, the
  Prism biome palette, and any new hero models — each needs a rendered
  check against §7 before it becomes canonical.

## Gameplay-camera checkpoint (2026-10-07)

The actual combat camera now starts 8m behind and 9.5m above its target. Ordinary creature base heights are 1.2–2.5m; bosses retain their large scale. Baked meshes are normalized by their actual height. A small gold player marker remains readable through crowded fights. Terrain uses 19% painted detail over muted biome colors, with scenery visible to 105m. This is a gameplay readability pass; the older golden-scene image is not the acceptance capture. See PROGRESS.md for actual combat captures and measured frame times.

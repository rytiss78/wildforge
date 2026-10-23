# Wildforge art bible

Version 1.0 · October 23, 2026. This replaces the 0.1 "storybook diorama" baseline, which predates the Hades direction (see [the Hades study](hades-style-research-1.0.0.md); the old text is in git history). Values marked *(code)* are the shipped values and live in the named file; change them there and here together.

## 1. Pillars

1. **Dark, quiet ground; loud action.** The floor and scenery sit in low values and moderate saturation. Heroes, enemies, loot and effects carry the brightest values and the strongest colour.
2. **Ink holds the world together.** Screen-space ink outlines (`ink_overlay.gdshader`) and painted textures give every surface a drawn edge. Each biome has its own ink colour and weight.
3. **One meaning per colour.** Gameplay colours never change meaning between biomes (section 4).
4. **Readable first, pretty second.** Any change must keep the hero, threats and loot readable at the normal camera in a 40-enemy fight (section 7).

## 2. Value hierarchy

From darkest to brightest in a normal frame:

| Layer | Target | How it is kept there |
|---|---|---|
| Ground | darkest large area | terrain base colours *(code: `terrain.gdshader` `biome_paint`)* stay below about 0.17 linear |
| Scenery | dark-to-mid, biome hue | scenery tint per island *(code: `world.gd` `GRADE.scenery`)* |
| Enemies | mid, warm or cool against the ground | painted batch shader, ink outline |
| Hero | brightest character; red cape and gold marker | never tinted by biome grade |
| Loot, telegraphs, effects | brightest values, emissive | glow above HDR 1.05 *(code: `world.gd` environment)* |

The global grade is saturation ×1.22 and contrast ×1.1 *(code: `world.gd make_environment`)*. That boost amplifies any coloured key light, so key lights stay close to neutral. A blue moon key turned Moon Craters entirely blue during the October 23 pass.

## 3. Biomes

*(code: `biome_look.gd` `LOOK`, `world.gd` `SKY_HORIZON`, `terrain.gdshader`)*

| Biome | Mood | Ground base (linear) | Key light | Fill | Fog (m) | Ink colour · thickness · strength | Accents |
|---|---|---|---|---|---|---|---|
| Clover Woods | warm late afternoon; the reference | slate and moss, painted | `#ffe0ad` 1.2 at −42° | `#a4b8ed` .28 | 45–165 | near-black blue · 1.25 · .9 | emerald canopy, pink flowers, cyan sap |
| Puffcap Marsh | damp, close | `(.07,.14,.10)` | `#e8f0c4` 1.05 at −40° | `#a8d8c4` .30 | 35–140 | green-black · 1.35 · .95 | pink and violet caps, yellow gill glow |
| Moon Craters | cold, still, long shadows | `(.06,.075,.11)` | `#eef1f7` 1.3 at −26° | `#8e98b0` .20 | 60–190 | navy · 1.55 · 1.0 | pale crystals, cyan veins |
| Cloudwilds | high bright daylight | `(.15,.20,.21)` | `#fff0d8` 1.2 at −48° | `#d8e6ef` .26 | 40–150 | slate · 1.3 · .95 | teal parasol trees, lilac blossoms |
| Candy Hell | heat; the lava owns the light | `(.13,.05,.04)` | `#ff9466` 1.15 at −34° | `#f0a48a` .22 | 45–160 | maroon-black · 1.45 · 1.0 | molten rivers, ember fruit |
| Starfall Space | cool starlight | `(.075,.045,.13)` | `#d8c4ff` 1.15 at −38° | `#b9a8f0` .24 | 50–175 | violet-black · 1.45 · 1.0 | pink crystal coral |

- **Islands 2 and 3** (Blighted Highlands, Ashen Reach) blend their own grade 60% over the biome look: sun, fill and sun angle *(code: `GRADE`)*. Ground corruption and veins mark them as harder.
- **The Red Moon** keeps its own fixed lighting *(code: `BiomeLook.RED_MOON`)*.
- Crossing a biome border eases every value over about two seconds.

## 4. Colour language

These meanings hold in every biome:

| Colour | Meaning | Where |
|---|---|---|
| Danger red `#ff4a2e` | an enemy attack will land here | every enemy ground mark's ink, bite rings, charge lanes *(code: `DangerMark.DANGER`)* |
| White flash | impact now | the last 0.25 s of every warning |
| Gold `#ffd35a` / `#ffd36b` | yours, or valuable | the hero's own strikes, chests, event beams, evolved weapons |
| Pale caution blue `#bfe6ff` | a harmless hazard: watch your footing | ice floors, wind gusts |
| Fire orange, toxic lime, frost cyan, storm blue, ghost violet | status and element | shot trails, status flames and bubbles, strain colours *(code: `shot_fx.gd`, `MutationBook.STRAINS`)* |
| Ink `#16121f` | death | the dissolve and ink blots *(code: `death_fx.gd`)* |

- An attack's own colour may appear only as the inner fill of its warning, never as its rim.
- Biome zone edges use the zone's colour lightened, or a dark crust for lava.

## 5. Ink

- Silhouettes come from depth steps and creases from normal bends. Ink fades out between 22 and 70 m.
- Ink thickness ranges from 1.25 (Clover Woods) to 1.55 (Moon Craters). Use heavier ink where scenery is pale or crystalline, so shapes stay separate.
- Ink colour is a very dark version of the biome's shadow hue, never pure black.
- Vignette strength is .42–.52, darker in the harsher biomes.

## 6. Characters, creatures and models

- **Proportions:** plush-toy proportions. The head is large and the limbs short, and the silhouette must be readable by outline alone. Bosses may break scale (the Baron stands 42 m tall); ordinary enemies stay 1.2–2.5 m.
- **Materials:** painted vertex colour with a paper, bark or stone grain *(code: `painted_batch.gd`)*. Deaths use the same shader's `dissolve`.
- **New models:** made in-house, never bought or downloaded. They must beat the current model side by side at the gameplay camera before replacing it (see the model pilot in [PLAN.md](../../PLAN.md)).

## 7. Readability checks

Kept from 0.1, still binding:

1. **Contrast:** HUD text against its plate is at least 4.5:1.
2. **Silhouette:** an enemy is identifiable from a flat single-colour render at 4 m.
3. **Distinctness:** two enemies that share a screen differ in at least two of shape, base colour and accent.
4. **Distance:** everything actionable is visible within 35 m; nothing required lies beyond 60 m.
5. **Screen share:** an ordinary enemy stays under 25% of viewport height at combat range, and the hero stays above 10% at rest. The fight zoom may pull back up to 35%, so the hero must still read at that zoom.
6. **Motion:** feedback reads at 1× speed. Nothing important lasts under 100 ms or relies on flicker alone; the white warning flash is backed by the closing sweep.

## 8. How to check

| What | Workflow action | Look at |
|---|---|---|
| Biomes and mechanics | `biome-review` | `biome-N.png`, `biome-mechanic-N.png` |
| Islands | `island-review` | `island-sheet.png` |
| Weapons, statuses, spells, synergies, deaths, zoom, telegraphs | `fx-review` | `fx-*.png` |
| HUD and menus | `capture-ui` | `ui-*.png`, at 1280×720 and 1920×1080 through `release-review` |

Compare against the previous run's images before accepting a look change.

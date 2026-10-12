# Hades reference study and corrected Wildforge direction

Research date: October 12, 2026. Focus: the original Hades. The user rejected the bright ground in checkpoint `37e9df1`: the desired saturation and brightness belong chiefly to skills, explosions and focused lighting. Passing runtime checks does not constitute acceptance of that art direction.

## What the creators document

- Jen Zee describes a deliberate change from painterly art to pen and ink, with Mike Mignola, Fred Taylor and ancient Greek art among the influences. She also describes developing a color script for the game's different regions. An early Tartarus concept was darker and more muted than the shipped version: the goal is not to make everything black. [Jen Zee interview, MCV/DEVELOP](https://mcvuk.com/business-news/behind-the-art-of-hades-we-value-artistic-integrity-and-excellence-in-artistic-craft-at-supergiant-however-were-first-and-foremost-a-game-design-lead-team/).
- VFX/UI artist Josh Barnett describes pursuing immediate, forceful, visceral effects, and overcoming an overreliance on tools and tiny details. This supports an emphasis on clear impact and expressive shapes; it does not specify a bloom threshold or lighting recipe. [Barnett's own development reflection](https://kirbyufo.com/2020/09/19/hades-1-0-thoughts-on-art-personal-growth/).
- Supergiant explains that the original game's animated 3D characters were rendered into many 2D frames; most environments and portraits are hand-painted 2D. Its appearance therefore cannot be reproduced by simply applying a cel shader to generic 3D models. [Supergiant developer explanation](https://steamcommunity.com/app/1145360/discussions/0/1738883810796606862/).
- Environment artist Joanne Tran describes creating painted environment assets and building 2D maps from them. Her portfolio provides additional original environment reference. [Production description](https://joannetranart.weebly.com/about.html), [Tartarus](https://joannetran.artstation.com/projects/lV6YgJ), [Asphodel](https://joannetran.artstation.com/projects/v2401Y), [Elysium](https://joannetran.artstation.com/projects/Ga6gXd).

Supergiant also published an [official elemental VFX breakdown](https://twitter.com/SupergiantGames/status/1313526043446132736). The direct social video was inaccessible during this research; do not claim its frames were inspected or infer exact shader implementations from it. No Hades II rendering claim is being applied to the original game.

## Visual analysis of the user's five screenshots

These observations are our reading of the supplied images, not quoted engine specifications. Reference copies and hashes are retained locally under `.build-staging/visual-overhaul-1.0.0/references/`; none are shipped in the game.

1. **Value hierarchy.** In the Tartarus combat image, the slash and impact reach near-white. The playable floor occupies a quieter middle range, and the architecture contains substantial dark masses. Saturated green pools mark individual light sources. The floor has readable cracks and seams without every slab demanding attention.
2. **Saturation has an area budget.** The Asphodel image contains a very saturated red-orange lava field, but the walkable rock stays comparatively subdued. The explosion has pale yellow/white centers, yellow bodies and orange fringes. It still stands apart from the lava. A colored region can be vivid without making its floor uniformly bright.
3. **Lighting is spatially composed.** Torchlight, doorways, ghostly figures and impacts create local pools of color. Large intervening shadow areas make those pools meaningful. Blue-violet shadows and warm highlights coexist; broad green ambient fill would muddy this separation. The throne-hall and overlook images are particularly clear examples.
4. **Ink describes masses, not just outer contours.** Columns, statues and borders contain broad black shapes, angular shaded planes, broken fine lines and selective edge highlights. A uniform outline around smooth primitive geometry captures only a small part of the style.
5. **Effects have authored silhouettes.** The sword attack is a tapered brush-like crescent; the explosion is a cluster of shaped lobes, pointed streaks and hot centers. These shapes remain identifiable before considering glow. Soft luminous spheres and equally weighted particles will not produce the same result.
6. **Elysium is a useful counterexample to 'make the whole game dark'.** It has brighter cyan-green environments, but quiet blue-green ground, darker foreground framing and very bright attack accents still establish a hierarchy. Each region needs its own palette and distribution of light.

The stills establish shape/color relationships, not exact timing. For Wildforge, use a short concentrated impact peak followed by colored expansion and a quick fade; tune this in motion rather than claiming specific Hades frame counts.

## Diagnosis of checkpoint 37e9df1

The ground covers most of the image with bright turquoise, frequent bright green seams and gold chips. Strong general lighting and terrain emission keep that entire area active. The pillars, floor and sky sit too close together in value, while the existing small effects have too little room to stand out. The first muddy texture and its desaturation were also wrong; reverting to that image is not the solution.

The models and architecture still need more intentional shape/detail work. A more accurate palette cannot by itself make the full scene equivalent to the reference.

## Implementation direction

| Layer | Required treatment |
| --- | --- |
| Ground | Dark-to-middle slate with restrained teal undertones. Remove pervasive neon moss/gold sparkle; reduce contrast between adjacent slabs. Keep travel surfaces readable and non-emissive except for actual magic. |
| Architecture | Broad ink shadows, designed carved forms and selective warm/cool lit edges. Avoid uniformly bright pillar faces and repeated unmotivated decorative strips. |
| Characters | Separate from the floor through silhouette, controlled highlights and local color. Preserve dark shape structure, crimson cloth and readable HP vessels. |
| Permanent lighting | Local emerald braziers, warm gold focal lights and cooler shadow fill. Light should fall off into quieter space. Do not use a global saturation/exposure increase as the primary treatment. |
| Skills/explosions | Sharp near-white cores inside saturated effect colors, purposeful arcs/streaks/lobes, a brief impact peak and darker/transparent recovery. Short-lived local illumination should react to the burst. Preserve elemental identities. |
| Hostile warnings | Clear borders and timing cues, with restrained translucent interiors. They must remain identifiable beneath friendly effects. |
| UI | Quiet dark backing, high-contrast text and selective accent colors; do not compete with live combat. |

Preserve the existing camera, controls, collision geometry and game rules. Adapt the illustration principles to the existing 3D camera rather than replacing it with Hades' fixed presentation.

Before approving another scene checkpoint, render the same real combat path in idle, warning, impact and recovery states. Inspect the colored captures and grayscale value structure. Compare ground, character, warning and effect regions separately; do not optimize a global image brightness statistic. Review at 720p and 1080p, in motion and under overlapping effects, and keep performance measurements comparable. Runtime checks remain mandatory but are independent of visual approval.

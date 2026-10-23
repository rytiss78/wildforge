# Enemy and encounter review — October 16, 2026

## Reference research

The earlier direction asks for original creepy enemies, not reproductions. Public internet-horror references include the shifting online folklore around Slender Man ([USC Digital Folklore Archives](https://folklore.usc.edu/the-slender-man/)), the Rake story and its later image associations ([Creepypasta.com](https://www.creepypasta.com/the-rake/)), and towering uncanny creatures in [Trevor Henderson's bestiary](https://trevorhenderson.format.com/beastiary). These references informed broad design grammar only: uncertain sightlines, unnatural posture, scale, and sound/shape motifs. No named character, recognizable silhouette, image, or story was copied into Wildforge.

The project already replaces the primitive roster and legacy fallbacks under the audited visual overhaul. The [overhaul report](visual-overhaul-1.0.0.md) records the actor redesign and the [asset cleanup manifest](visual-cleanup-1.0.0.json) preserves the retired source list and hashes. Wildforge keeps its own names, low-poly forms, red health orbs, biome palettes and attacks.

## Current behavior and spacing

Six biome-specific ranged enemy sets now use different preferred firing rings and sidestep amounts. Their attacks use one, two or three marks with matching biome hazard styles. At the ring they strafe; they retreat when crowded and move in when outside their effective firing range. Charge enemies commit to a warned direction so a sideways dodge can evade them. Shared physical movement remains enabled after an experiment without enemy-body collision was rejected for overlap.

The October 16 integration adds four focused checks to the actual tactics helpers: approach, retreat, distinct firing rings and distinct telegraphs for all six biomes. `2026-10-16T19-06-30-906Z-integration` passes all 75 gameplay assertions, including the existing live firing-ring, retreat, charge-windup, charge-commit, wall traversal and enemy-contact checks. The initial fixture exposed threshold-equality assumptions in its test inputs; the test now samples beyond the inclusive ring boundary. No gameplay behavior was loosened to satisfy it.

`2026-10-16T19-01-41-282Z-roster-review` passes all assertions and renders 42 enemies, 25 heroes, 36 biome props and 807 icons. The three enemy sheets and biome captures were inspected. The central health-orb language repeats by design; body outlines and appendages remain readable across the sampled species. Six-biome gameplay art at 720p and 1080p has separate user acceptance recorded in [ground-art research](ground-art-research.md).

## Limits

This closes the reference survey, original roster review, biome-specific ranged behaviors and existing asset replacement review. It does not establish full-run encounter pacing or build win rates; those remain in the real-fight balance item in [PLAN.md](../../../PLAN.md). The crowded performance captures are stress scenes and are not used as visual acceptance.

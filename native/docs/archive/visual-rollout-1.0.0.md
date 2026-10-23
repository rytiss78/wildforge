# Full visual rollout — 1.0.0

October 13, 2026. This completes the remaining catalogue/roster implementation after the Clover Woods and eight-boss checkpoints. Final build and release evidence is recorded in [release-1.0.0.md](release-1.0.0.md).

- Twenty remaining heroes retain articulated hands, distinct headgear/costumes and unobstructed glass health cores. Thirty remaining common enemies use carved silhouettes; all 36 retain their orbs.
- Twenty-four base weapons and all 65 rendered thumbnails use the new materials/inlays. The 40 weapon variants retain their behavioral differences and model attachments.
- All 696 reward SVGs, 108 achievement seals, 14 potion icons and compact effect glyphs share dark engraved frames. Equal effects intentionally share symbols. The 360 stat/condition combinations remain distinct; no file-hash trick is presented as artistic uniqueness.
- Five remaining scenery families add 30 models alongside the six Clover Woods models; six offering-bowl harvestables retain gameplay effects. All six terrain/sky palettes, map, landmark stonework and treasure chests use the new palette. Darker terrain leaves room for bright attacks.
- HUD health is a blood orb with a separate shield arc. The new About screen is reachable and can be reopened from the menu. Existing synthesized achievement audio remains.
- Old actor, weapon, scenery and icon sprite fallbacks are removed. The [explicit deletion manifest](visual-cleanup-1.0.0.json) records archived copies and SHA-256 hashes. Shared terrain textures, audio, community publication images, saved games and old builds are retained. Legacy mesh recipes remain importable helpers; their old standalone entry points refuse to overwrite new art.

## Acceptance changes and repairs

The old icon test required 761 unique image hashes even for cards granting the same effect. The new test loads every asset and requires 360 distinct rendered stat/condition combinations. Contact sheets were inspected independently; repeated equivalent bonuses are intentional. The map test samples six remote sectors for opaque, distinguishable biome colors instead of requiring an obsolete exact swatch.

Eclipse handling remains deliberately slippery (turn response 4/s; braking 6/s). Its old 0.32-second / 0.2-second settlement windows contradicted that behavior. The revised test retains the 2% threshold and initial drift check, with settlement windows 1.2 seconds / 0.75 seconds; it also compares 30 Hz against 144 Hz. No gameplay response rate was changed.

Verbose integration identified the exit leak as nine audio playback/stream pairs. Explicitly stop and release channels, then allow 150 ms for the mixer before test exit. The final integration log is free of the earlier ObjectDB/resource diagnostics. The Eclipse review also disables automatic game updates while it drives explicit music transitions, allows mixer frames between transitions, and stops/releases audio before exit. Verbose logs identified the old exit-only diagnostics as music playback/WAV resources; the refreshed review is clean.

A concurrent local edit used a nonexistent BLEND_MODE_ALPHA constant. Its intended alpha blending is preserved using [Godot's BLEND_MODE_MIX](https://docs.godotengine.org/en/stable/classes/class_basematerial3d.html#enum-basematerial3d-blendmode). That local edit, the map marker edit, the armour shader edit and explore_dredge.glb are outside this commit and preserved.

## Source evidence

Under `.build-staging/agent-workflow/`:

- `2026-10-13T07-38-39-600Z-check`: JavaScript and Godot import/parse passed.
- `2026-10-13T07-38-58-658Z-integration`: catalogue, weapon branches, map, traversal and gameplay checks passed; clean audio shutdown.
- `2026-10-13T07-39-13-384Z-eclipse-review`: handling/audio checks passed.
- `2026-10-13T07-36-44-304Z-roster-review`: all roster/orb/asset-load checks passed; front/back/contact sheets reviewed. Outline-only icon contrast was subsequently improved.
- `2026-10-13T07-36-50-244Z-biome-review`: streamed all six biomes with normal and combat captures. Terrain was subsequently darkened following visual review.
- `2026-10-13T07-39-16-905Z-style-review`: final quiet ground and high-contrast lightning/explosion captures inspected; camera and damage/lifetime checks pass.

Performance numbers remain hardware/workload dependent. No optimization claim is made from asset hashes or isolated frame measurements.

# Baron boss art — Build 17 work

The final boss now uses a separately authored stylized bald, heavy, suspended figure in a dark robe. The previous `boss_8.glb` is preserved; `scripts/build-baron.py` generates only `boss_8_baron.glb`. Runtime identity stays `boss_8`, preserving attacks, portal routing and network identity. Sixty-four GPU particles vent from four upper-body sites, above floor-level warnings.

This is **not a photorealistic model**. The authored fallback uses no downloaded model, film still or texture. The Dune character remains a third-party character; original geometry is not a claim of ownership of that character or an official licensed likeness.

## Asset search

- [Free Baron OBJ listing](https://cults3d.com/en/3d-model/art/baron-harkonnen-free-model): a printing-model listing; no verified reusable, textured/rigged game asset downloaded.
- [Andrea Di Natale's Sketchfab model](https://sketchfab.com/3d-models/baron-harkonnen-42db2a7f33e24e34af34767308e54db8): reference candidate; downloadable files and suitable reuse terms were not verified.

Photorealism and visual acceptance remain open. Do not describe this fallback as satisfying those parts of the request.

## Validation

Initial rendered review `2026-10-15T11-24-54-623Z-red-moon-review` passed combat, size, portal and local network-reconstruction checks but failed steam count because duplicate node names were rewritten by Godot. Each vent now has a unique name. The original failure log is retained. Facial outlines were removed after inspecting the silhouette image. Final review evidence follows in the Build 17 work log.

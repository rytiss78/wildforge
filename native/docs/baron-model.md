# Baron boss art — Build 17 work

The final boss now uses a separately authored stylized bald, heavy, suspended bare figure, following the user's October 16 direction to look for a realistic model and otherwise make the current model naked. The previous `boss_8.glb` is preserved; `scripts/build-baron.py` generates only `boss_8_baron.glb`. Runtime identity stays `boss_8`, preserving attacks, portal routing and network identity. The replacement has a continuous torso, exposed arms and legs, and a neutral non-explicit treatment. Sixty-four GPU particles vent from four upper-body sites, above floor-level warnings.

This is **not a photorealistic model**. The authored fallback uses no downloaded model, film still or texture. The Dune character remains a third-party character; original geometry is not a claim of ownership of that character or an official licensed likeness.

## Asset search — October 16, 2026

- [Free Baron OBJ listing](https://cults3d.com/en/3d-model/art/baron-harkonnen-free-model): a printing-model listing; no verified reusable, textured/rigged game asset downloaded.
- [Andrea Di Natale's Sketchfab model](https://sketchfab.com/3d-models/baron-harkonnen-42db2a7f33e24e34af34767308e54db8): a 456.8k-triangle fan-art model; the listing did not provide verified game reuse terms or confirm a rigged game asset.
- [Bald Man - Rigged on OpenGameArt](https://opengameart.org/content/bald-man-rigged): CC0, 8.8k polygons, FBX and 2K color/specular/normal textures. Its author says it is a practice model and reports issues with the ears; it is not a photoreal heavy Baron.
- [Ravi on itch.io](https://oudarya.itch.io/ravi): tagged photorealistic and CC0, but costs at least USD 5 to download, is fully clothed and does not match this character. No purchase was made.
- [Realistic Chubby Balding Male on Fab](https://www.fab.com/listings/00062ece-c8d6-4fd4-99a3-67ea43dc5997): the listing describes a realistic, heavy, balding, fully rigged male with PBR materials in FBX/Blender. It requires selecting and purchasing a license; price and fit for Godot were not verified. [Fab's Standard License summary](https://www.fab.com/eula?lang=en) allows adaptation and commercial distribution inside a project, but this listing is a generic civilian, not Baron art. No purchase was authorized or made.

No verified free, photoreal Baron asset met the request. A paid generic Fab character is a possible separate route if the user wants to fund and approve that purchase; the work here follows the requested authored fallback. The result remains stylized and must not be described as photorealistic. User acceptance of the newly rendered bare model and its visibility in the exported game are still pending.

## Bare model implementation and checks

`scripts/build-baron.py` now generates a continuous bare torso and exposed limbs instead of the robe. It writes a 20,960-triangle, 46-mesh-node asset. `native/scripts/baron_steam.gd` keeps four emitting vents / 64 GPU particles total and places them on the chest and abdomen.

- The first bare-body review exposed torso seams and oversized steam particles. That capture is retained in `2026-10-16T18-50-33-104Z-boss-review`.
- Final source boss review `2026-10-16T18-51-56-820Z-boss-review` passes model, scale, collider, co-op reconstruction, vent count and warning checks. Its `boss-baron.png` was inspected.
- Final source Red Moon review `2026-10-16T18-54-21-506Z-red-moon-review` passes silhouette, huge-body targeting, weapon hit, slow movement, four attack patterns, warning marks and the bare-model regression.
- `2026-10-16T18-52-32-758Z-check`, `2026-10-16T18-52-54-693Z-smoke` (118 checks) and `2026-10-16T18-53-11-418Z-integration` (71 checks) pass. A failed source review caused by an outdated test expecting the removed robe is preserved at `2026-10-16T18-53-48-029Z-red-moon-review`; the assertion was corrected to check `BareTorso` and the robe's absence.
- This is source-render evidence only. No export was made from this revision; the project still requires the final exported-game view and user acceptance before the Baron item can close.

## Validation

Initial rendered review `2026-10-15T11-24-54-623Z-red-moon-review` passed combat, size, portal and local network-reconstruction checks but failed steam count because duplicate node names were rewritten by Godot. Each vent now has a unique name. The original failure log is retained. Facial outlines were removed after inspecting the silhouette image. Later robe-model reviews are superseded by the October 16 bare-model review above.

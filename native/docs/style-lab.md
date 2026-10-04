# Wildforge 0.6.1 — first 3D review slice

This is the first visual checkpoint of the 0.7 plan, not the completed major update. Open **3D Style Lab** from the main menu in the same Wildforge executable. It is a solo art/combat sandbox and does not change career progress. Leave a co-op party before entering.

## Implemented

- Bottlebite: an original non-humanoid four-legged creature with actual hollow ring geometry, a glass-like blood reservoir, eyestalks, cork horns, shell rivets, a snapping jaw and articulated legs.
- Core liquid drains to current HP, animates to the new level, remains upright as the body tilts, cracks at low HP and heals back. Full, half, critical and black-blood tank examples stand side by side. The live target can also be emptied.
- Real Count Duck mesh, modeled from the approved illustration: shaped bill/head, suspicious brows, hair/crown, high vampire collar, cape with lining, coat buttons, lace/cravat, articulated legs/arms and weapon socket.
- Mint-and-brass pistol modeled from its approved icon: wooden grip, receiver, hollow barrel, cuffs, guard and rivets. Held in the right hand, aims/recoils and fires a modeled textured brass slug with sound and hit burst.
- Small textured 3D arena with six authored trees, collision ground/trunks, a collidable moving target, jumping and bright lighting. This is a style sample, not a rebuilt forest biome.
- Compact opaque bordered UI with original art references. **View models** switches to a close-up orbit view; click again to return to the arena. Characters are true meshes viewed from any side, not camera-facing sprites.

## Controls

- WASD / Xbox left stick: move.
- F / A: ground jump.
- Space / right trigger: shoot; hold for repeated shots.
- E / X: heal the live core by 25 percentage points.
- R / Y: refill the live core.
- Hold right mouse button / right stick: orbit camera.
- Mouse wheel / D-pad up/down: zoom.
- Tab / **View models**: switch inspection/arena views.
- Escape / B / **Main menu**: return to the game menu.

## Asset pipeline and limitations

`scripts/build-style-models.py` is the editable source for the five GLB models. It authors vertex positions, normals, UVs, silhouettes, extrusions, hollow rings and articulated pivots. It reuses approved paper/bark/stone PNGs; it does not create or edit raster images. Palette conversion follows glTF linear color factors. Rebuild models with Python, then run Godot editor import. These meshes can also be opened and refined in a normal 3D editor.

`style_model.gd` applies textured toon materials/contours and animates rigid part pivots. These are articulated prototype meshes, not production skinned skeletons. They still need visual approval, costume/texture refinement, lower-cost crowd versions and production animation work before all 21 heroes/36 enemies are converted. Model source totals approximately 1.75 MiB; texture sources are reused. Separate mesh parts must be merged/batched by compatible material and animation group for production crowds.

The core uses an opaque illustrated glass approximation with reflection strokes, rim color and an internal fill boundary. It avoids stacking transparent refraction passes. It is not physically simulated glass/liquid. Review visibility at real camera distance before choosing the final material.

The rest of 0.7 remains on the plan: hidden horizons/tall biome structures, complete scale/flying/boss work, subtle border steam, full hero/enemy conversion, expanded effects/voices, luck-gated 14-potion system, new jump baseline, new guns/cards and full-slot reward filtering. Hero HP has not been converted to cores.

## Verification

Run Godot with `--headless --path native res://style_lab.tscn -- --style-check` or the packaged console launcher with `-- --style-check`. Results use a separate `style-check-results.json` diagnostic file, not the career save. Rendered captures use `--style-inspect` and write arena/character PNGs. Package checks also cover the normal game regression; physical Xbox hardware remains a hands-on check.

Final 0.6.1 verification: nine Node tests pass; all 15 prototype checks pass in headless source and the rendered packaged game; the packaged normal-game regression passes; rendered Xbox-style menu activation into the lab and return to the normal menu pass without duplicated input bindings. Final checked runs have clean runtime logs. Xbox actions were injected for these tests; a physical controller/rumble still needs user testing.

Review images: `screenshots/style-review.png` (normal combat distance) and `screenshots/style-character-review.png` (front view). The review checkpoint is pending before mass conversion. No Steam upload occurred.

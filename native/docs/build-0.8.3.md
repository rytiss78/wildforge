# Wildforge 0.8.3

Final Windows build for the requested update, dated 2026-10-10.

- Bugfix release. `journey_review.gd` no longer crashes on late-game corruption checks — Dictionary corruption keys are read with `.get("corruption",0)` instead of dot syntax, so the `Invalid access to property or key 'corruption'` crash is gone.
- `eclipse_corruption.gd` now stores the applied corruption stage back on each enemy dict, so corruption-level replication and checks observe the current stage instead of always reading 0.
- `enemy_surface.gd` steep-surface reattach gates use `normal.y < 0.71` (≈45°) instead of `0.5` (≈60°), so enemies correctly cling to 45° slopes while still falling off flat ground.
- `game.gd` records cumulative damage on a hit-number before rounding, so overlapping hits within the dedup window accumulate correctly.
- `sound.gd` guards the eclipse music stream and fixes boss voice volume (now -10 dB relative to the voice setting instead of -80 dB).
- `coop.gd` lerps client realm time toward the host to prevent visible time jumps during co-op sync.
- `world.gd` frame-budgets realm chunk building across frames to avoid a one-frame stall on realm transitions.

## Validation

Six diagnostics pass fresh this batch: `check` (13 JS + Godot import/parse), `combat-review`, `coop-feedback`, `journey-review`, `surface-review`, `controls-review`. The exported build passes 72 smoke checks plus 9 metadata fields.

Real career saves were not used for validation. Tests use isolated APPDATA. Local two-player tests and simulated controller input do not establish physical controller or multi-machine compatibility. This release does not establish long-run balance across every combination.

## Artwork provenance

Provenance is recorded in `../assets/illustrated/content/art-provenance.json`. Scenery review screenshots: `scenery-review-0.png`, `scenery-review-2.png`.

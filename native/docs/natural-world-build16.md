# Natural-world continuation — Build 16 remains unreleased

October 15, 2026. Supersedes the older request for massive decorative buildings.

## Changes

All scattered decorative building meshes are replaced by 18 cached organic meshes, batched per chunk. Six landmark groves replace windows, doors, castles, platforms and banners. Existing interactive chests, portals, sentries and other gameplay objects remain functional. Source art and old building generators are preserved but are no longer called by normal scenery generation.

Emerald/teal foliage, pink/gold blossoms, colourful mushrooms, tapered crystals, willow strands, ember roots and astral coral add colour above the subdued ground. Tree tapers join continuously. Natural sap/glowing organs share the existing emissive shader; sparse warm/biome lights cast shadows with distance fading. Scenery meshes retain camera proximity fading. Tall, medium and low growths break up repeated silhouettes. Cloud City is now Cloudwilds in the biome HUD.

Natural obstacle colliders are excluded from enemy climbing probes. Body sweeps choose a passing side around trunks, while ordinary terrain retains its climbing code. Ranged enemies maintain biome-specific firing distances and require a clear line of sight; charging enemies warn for 0.8 seconds, commit to their initial direction and cancel on freeze/blind. A duplicate boss locator was removed, keeping the camera-projected marker and health orbs.

## Validation

- Source check: `.build-staging/agent-workflow/2026-10-15T10-11-02-285Z-check/result.json`.
- Gameplay integration: `.build-staging/agent-workflow/2026-10-15T10-11-38-220Z-integration/result.json`, including real firing distance, retreat, charge/dodge, freeze cancellation and traversal around a thick tree.
- First fixture failed because earlier integration stats killed its enemy; the fixture now starts a fresh isolated run. A second assertion sampled the transition frame before charge movement. Diagnostics confirmed the locked direction; the check now observes the rush itself, with the same movement assertion. Failed logs remain in the dated staging folders.
- Surface traversal: `.build-staging/agent-workflow/2026-10-15T10-12-15-540Z-surface-review/result.json`; wall, ceiling, ledge and slope captures inspected.
- Six-biome rendered review: `.build-staging/agent-workflow/2026-10-15T10-13-13-792Z-biome-review/result.json`; all six normal-camera captures and the forest explosion capture inspected. Natural landmarks and scattering checks pass. No decorative architecture remains in the inspected routes. Close foliage can still fill the frame; the hero-area fade remains active.
- Red Moon: `.build-staging/agent-workflow/2026-10-15T10-14-02-922Z-red-moon-review/result.json`; silhouette, impact and Eclipse captures inspected. One boss location marker, with the health orb retained.
- Startup smoke: `.build-staging/agent-workflow/2026-10-15T10-14-44-847Z-smoke/result.json`, 118 checks passed.
- Integration has 67 passing checks. The final logs from all six actions above contain no script/runtime errors or warnings. No extra export was made.

## Delivery and limits

No new export or publication: the user explicitly requested more work before Build 16. The local `09-51-35-157Z-build` candidate predates these changes. `Play-Wildforge.cmd` falls back to the existing Build 15 folder until the future Build 16 delivery folder exists, and prints the folder it opens. For current source use `node scripts/native.mjs`.

No new final-boss duration claim, crowd-performance claim or Internet-latency claim is made. Five-minute final-boss balance remains open. Local steering is not a full navigation mesh; dense mixed crowds still need a playtest. The earlier six-minute co-op evidence covers the repair checkpoint, not a new full soak of these scenery changes. Legacy forge/playfeel building screenshots refer to the retired architecture and need refreshing before those reviews are used again.

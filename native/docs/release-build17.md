# Wildforge 1.1.3 — Build 17 checkpoint

October 16, 2026. [Windows download](https://github.com/rytiss78/wildforge/releases/tag/build-17).

Unzip `Wildforge-1.1.3-Windows.zip` and keep the executable, pack and build manifest together. Run `Wildforge.exe`. All players in a co-op party must use Build 17. The manifest records the exact source commit and executable/pack SHA-256 hashes; the release includes the ZIP checksum.

## Included

- Camera-relative minimap rotation, including camera smoothing.
- Dodgeable, telegraphed enemy contact attacks, with host-owned co-op damage and replicated warnings.
- The immense, slow Baron fallback, four bounded steam vents, deadly readable patterns and an endless Eclipse after defeat. The model is stylized; no photorealistic, licensed game-ready film asset was verified.
- Chunked, non-colliding ground cover and biome-specific foliage, moss and minerals, plus sparse marsh/cloud mist.
- Reduced repeated step-up collision work while retaining physical enemy blocking.

## Verification

- JavaScript tests, Godot import and GDScript parse: `.build-staging/agent-workflow/2026-10-16T16-53-11-738Z-check`.
- Source startup smoke (118 checks): `.build-staging/agent-workflow/2026-10-16T17-00-43-714Z-smoke`; gameplay integration (71 checks): `.build-staging/agent-workflow/2026-10-16T17-00-57-822Z-integration`.
- Rendered Baron size, movement, targeting, damage/dodge, four patterns, steam budget and Eclipse: `.build-staging/agent-workflow/2026-10-16T16-53-28-692Z-red-moon-review`; inspected silhouette and attack captures.
- Six-biome scenery and mist review: `.build-staging/agent-workflow/2026-10-16T16-54-10-283Z-biome-review`; inspected woods, marsh and cloudwilds.
- Contact warning and camera-relative minimap: `.build-staging/agent-workflow/2026-10-16T17-02-01-075Z-combat-review`; inspected four camera headings and the warning capture.
- Controlled balance estimates: `.build-staging/agent-workflow/2026-10-16T17-02-42-511Z-balance-review`. These use stationary targets and perfect attack uptime; real fight duration remains open.
- Repeated late-Eclipse measurement (seed 81173, 125 enemies): `.build-staging/agent-workflow/2026-10-16T17-03-25-900Z-crowd-eclipse` and `.build-staging/agent-workflow/2026-10-16T17-03-59-022Z-crowd-eclipse`. Frame p50/p95 repeated at 15.33/49.50 and 14.90/49.59 ms; physics p95 stayed high at 117.44/118.95 ms.
- The clean exported build's smoke and rendered release review accompany the downloadable archive and its `build-info.json` manifest. The packaged shared-session co-op review timed out, and the source shared review failed on empty host-member/chest fixture arrays; these checks remain open in [Build 17 work and evidence](build17-work.md). This is not a reproduction or resolution of the early-game desynchronization.

## Still open in PLAN.md

This is an alpha checkpoint, not completion of the active plan. Full-fight build balance and survival rates, ground/color acceptance, late-Eclipse performance, semantic UI art review, and human gamepad/audio checks remain open. The required early-game co-op desynchronization investigation stays last. NodeTunnel remains deferred.

See [the active plan](../../PLAN.md), [Build 17 work and evidence](build17-work.md), and [Baron model provenance](baron-model.md).

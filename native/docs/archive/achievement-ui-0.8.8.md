# Achievement notifications — local build 0.8.8

Historical build: superseded by 0.8.9, which uses a modern Series X-inspired banner and original synthesized audio. Current code no longer loads or exports the old Xbox recording.

The achievement popup now resembles an Xbox 360 notification: a dark rounded capsule, green trophy medallion, white title, description and animated entrance/exit. It appears above the weapon slots for five seconds. Unlocks queue instead of replacing one another and wait while menus are open.

Each banner plays its chime on a dedicated audio channel. Menu clicks cannot interrupt it; SFX volume and mute apply. The old generic ping and spoken achievement announcement were removed from this callback. This local build includes the original Xbox 360 recording as an optional personal-use asset; clean checkouts use an original synthesized fallback. See [sound provenance and export restrictions](../../assets/audio/achievement-sound.md).

## Build

[Run Wildforge 0.8.8](../../build/achievement-0.8.8/Wildforge.exe). Keep its `.pck` and companion executable together. All three files were SHA-256 compared with the validated staging export. Previous builds remain available. This has not been published.

## Verification

- [Check report](../../.build-staging/agent-workflow/2026-10-12T17-11-43-895Z-check/result.json): 13 Node tests pass; Godot import/parse passes.
- [Smoke report](../../.build-staging/agent-workflow/2026-10-12T17-10-58-875Z-smoke/result.json): 92 checks pass, including queue ordering, expiry, menu deferral, dedicated sound playback, SFX volume/mute and fallback generation.
- [Rendered source review](../../.build-staging/agent-workflow/2026-10-12T17-11-11-514Z-capture-ui/result.json): UI review passes at 1440×810; achievement screenshot visually inspected.
- [Build report](../../.build-staging/agent-workflow/2026-10-12T17-12-09-417Z-build/result.json): Windows export and all 92 exported smoke checks pass.
- Actual exported executable: rendered UI review passes at [1920×1080](../../.build-staging/achievement-exported-1920x1080-1791825161921/result.json) and [1280×720](../../.build-staging/achievement-exported-1280x720-1791825176418/result.json). Both achievement screenshots were visually inspected; no banner clipping or persistent empty panel. Both logs confirm the packaged MP3 loads, length 0.366 seconds. These automated captures mute the master audio bus, so they verify playback/resource behavior rather than an audible listening review.

![Achievement banner in the exported game](../../.build-staging/achievement-exported-1920x1080-1791825161921/Roaming/Godot/app_userdata/Wildforge/ui-achievement.png)

## Remaining diagnostics

The exported headless smoke test still reports shutdown cleanup diagnostics after passing its assertions: 20 ObjectDB instances leaked and five resources still in use. The previous 0.8.7 build also reported this class of diagnostic (18 instances, five resources). Neither rendered exported review reports these diagnostics or script errors. The cleanup issue remains open; the smoke log is not claimed to be clean.

Other incomplete plan items and the known long co-op/Eclipse checks remain as recorded in the [repair audit](../repair-audit-2026-10-12.md). This achievement change does not certify those features. Existing staged work was preserved; these changes were not committed into the mixed index.

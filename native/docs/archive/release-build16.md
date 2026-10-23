# Wildforge 1.1.2 — Build 16 checkpoint

October 15, 2026. [Windows download](https://github.com/rytiss78/wildforge/releases/tag/build-16).

Local delivery: `G:\game\build\repair-1.1.2-build16\Wildforge.exe`. Keep the executable, pack and build-info.json together. `Play-Wildforge.cmd` selects this folder. The manifest records the exact source commit and both artifact hashes; the release includes a ZIP checksum.

## Included

- Host-owned shared XP drops/levels and shared chest opportunities, with independent choices and duplicate-credit protection.
- Combat-targetable magnet guards, host-validated activation, distant hunt targets and arrows.
- Bottom XP bar, shield/armor numbers, Eclipse rain/weather recovery, separate boss music and spaced Lithuanian boss speech.
- Slow 42-metre final boss with 360,000 solo HP, deadly ranged patterns and permanent Eclipse after defeat.
- Six natural biome sets replacing buildings; enemies route around natural props instead of climbing them. Different ranged distances and committed, dodgeable charges.
- First short grass/ground-cover pass with biome colours and clear paths. No ground-cover collision.
- Last run stored separately from high scores, a Last run menu, live death counts and immediate career-stat persistence.
- Controlled final-boss damage measurements and reduced repeated obstacle probes.

## Verification

All reports are under `.build-staging/agent-workflow/`.

- Source JS/import/parse: `2026-10-15T10-54-15-393Z-check`.
- Gameplay/obstacle regressions: `2026-10-15T10-39-37-553Z-integration`.
- History, persistence and actual menu buttons: `2026-10-15T10-52-02-725Z-feedback-review`.
- Natural-grove walkthroughs, slam, turrets, drops and audio state: `2026-10-15T10-40-48-789Z-playfeel-review`.
- Binding/settings behavior: `2026-10-15T10-45-04-889Z-controls-review`.
- Fifteen controlled boss-DPS samples: `2026-10-15T10-53-21-918Z-balance-review`, clean log after stopping diagnostic audio before shutdown.
- Candidate export from committed gameplay source `633c42c`: `2026-10-15T10-55-39-835Z-build`, 118 exported smoke checks.
- Exported 720p/1080p menus and forge/style/eight-boss/six-biome checks: `2026-10-15T10-56-21-949Z-release-review`.
- Two actual exported processes sharing XP, levels, chest choices, critical hits and magnet state: `2026-10-15T10-57-57-113Z-shared-review`.
- Exported magnet, hunts, weather/HUD/audio state: `2026-10-15T10-58-11-732Z-hermes-review`.

Release documentation is committed after the candidate checks, then the unchanged gameplay code is exported again. The delivered build-info.json and latest-build.json identify that final export; the candidate above is retained as evidence, not used as a mislabeled release.

## Unfinished

This is an alpha checkpoint, not completion of PLAN.md. The photorealistic Baron Harkonnen boss with steam is a new open task; no suitable game-ready model has been imported. The ground cover is a first pass, and the user's requested Hades-like colour/composition, low-mist trial and further enemy/art polish remain open.

Boss timings are ideal sustained-DPS estimates, not proof of enjoyable five-minute survival fights. Status, weapon, turret, slam and garden builds differ substantially. Dense Eclipse crowds still show frame-time stalls; do not read the new probe cache as a completed performance fix. Physical gamepad feel and full-battle audio audition still need human feedback. NodeTunnel remains deferred.

See [continuation measurements](build16-continuation.md), [ground-art research](ground-art-research.md), and [the active plan](../../../PLAN.md).

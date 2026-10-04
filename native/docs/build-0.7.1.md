# Wildforge 0.7.1 — exploration, controls and generated voices

- Minimap grows from 145 to 230 logical pixels (about 307 pixels at 1080p), marking all unopened boxes with outlined chest icons. Opened or destroyed boxes leave the map. The counter now reads `BOXES 6 left`.
- Opening a box plays its lid animation and then hides the world object. Metadata remains for prices, career counters and safe repeat-interaction handling.
- Scenery candidates fall from 28 to 12 per chunk. Major buildings fall from three to one, with their scale reduced from 2.6–4.4 to 1.3–2.0. Smaller scenery also shrinks, retaining tall landmarks with more open routes.
- Four original slot-machine sounds match the rarity reveal durations: slowing reel ticks, sequential reel stops and brighter payout chimes for rarer treasure.
- Space jumps; Shift dashes. Xbox A/RT remain unchanged. HUD and pause instructions match.
- Weapon reward screens offer `SKIP · KEEP MY WEAPONS`. Skipping consumes that reward and resumes play without replacing, upgrading or adding a weapon. Pending earned levels are handled normally.
- All active voices are newly generated with Kyutai Pocket TTS stock profiles, replacing the previous Kokoro cast. No human recordings ship. Original short tactical calls replace long narration. Each biome announcement contains only its name.
- Female announcements come from 32 metres overhead with a dedicated spacious reverb bus, keeping the dry speech clear. Hero hurt reactions follow the hero, remain dry, cannot interrupt an active reaction and have a minimum three-second interval. Short original character interjections retain each hero's personality.

Pocket TTS code/model license: MIT. Alba preset: CC BY 4.0, Alba MacKenna / Kyutai. Selected VCTK presets: CC BY 4.0, CSTR / University of Edinburgh. Marius/Javert volunteer profiles: CC0. Exact voice casts, source links and generated-file hashes are in the shipped provenance JSON; credits and license accompany the build. Generator: `scripts/update-presentation-audio.py`; only rendered WAVs ship, not Python, model weights or a live TTS service.

Validation: built once, then ran one packaged rendered `--presentation-check`. All 12 checks passed, covering the changed UI, box lifecycle, keyboard binds, skip behavior, reel assets, hero spatial playback/cooldown and overhead announcement routing. No full stress-test or repeated multiplayer suite was run for this presentation patch. The log is `presentation-0.7.1.log`; screenshot: `screenshots/build-0.7.1-gameplay.png`. Voice quality remains an artistic judgement; the engine change does not imply indistinguishability from human actors.

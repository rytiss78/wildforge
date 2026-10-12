# Original modern achievement chime

As of 0.8.9, `RunSound.make_achievement_chime()` generates the achievement audio directly. No Xbox recording is loaded, sampled, pitch-shifted, or used as a fallback.

The 1.85-second cue has a short filtered air sweep, a soft low impact, and staggered glassy tones at 587.33, 880 and 1318.51 Hz. Gentle attacks, decaying harmonics and a final fade keep it clear without harsh clicks. This is original synthesis inspired by modern console feedback, not a transcription of the Xbox melody. It is generated once during sound setup and played on its own channel when each queued banner appears. SFX volume and mute apply; menu sounds cannot cut it off.

The rendered UI review writes the exact runtime stream to `user://achievement-modern.wav` for listening. Smoke checks validate audible sample amplitude, no clipping, quiet endpoints, playback independence and volume/mute behavior.

The old `assets/audio/local/xbox360-achievement.mp3` may remain on this machine as a historical asset for 0.8.8, but current code never loads it. The Windows export preset explicitly excludes `assets/audio/local/*`; the exported UI check verifies that the old recording is unavailable. Old 0.8.8 builds remain unchanged.

The banner uses original trophy/laurel vector art and the modern icon-first, color-filled presentation. Visual reference: [Xbox's achievement refresh](https://news.xbox.com/en-us/2026/04/08/xbox-insiders-may-2026-console-features/).

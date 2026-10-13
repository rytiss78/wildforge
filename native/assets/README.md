# Active native art and audio

The current game uses original procedural cartoon meshes, dark outlines, generated illustrated textures, an icon atlas, dark engraved UI and a celestial procedural sky. Runtime art scripts are in `native/scripts`; mesh generators are in the root `scripts` folder. See `illustrated/README.md` for generation prompts.

The new phonk stems and effect synthesis are original (`scripts/create-game-feel-audio.py`; hashes and levels in `music/phonk-game-mix.json`). Eclipse is different: `eclipse_paranoia.wav` is the existing synthesized MIDI arrangement derived from the user-supplied PARANOIA track, described in `music/eclipse_paranoia.json`. `eclipse_game_mix.wav` applies EQ to that arrangement, with playback reduced by 5 dB. It retains the existing notes/timing and must not be described as an original composition. The source arrangement is preserved. Current announcer and hero lines are original text generated offline with Kyutai Pocket TTS stock synthetic profiles. The bundled WAV files require no Python, model, account or online service during play. There are no cloned personal voices.

See `voices/voice-provenance.json`, `voices/hero-voice-provenance.json` and `voices/Pocket-TTS-voice-credits.txt` for sources, generated dialogue hashes and attribution. Voice models and rendering environments are excluded from the repository and playable build.

# AI content provenance — release preparation

This records asset origins for standalone distribution.

- The 24 original item/weapon illustrations and four painted material textures were generated from original prompts. Those prompts are recorded in `native/assets/illustrated/README.md`.
- Achievement artwork composes those illustrations with authored badge motifs; hero badges use renders of the actual procedural game models. `achievement-art.json` maps the 100 stable IDs to their compositions.
- Hero, weapon and environment meshes, rig animation, scenery batching, sounds and music arrangements use AI-assisted authored code. The game runs these locally; there is no live image or language-model service in gameplay.
- Current announcer and hero lines were generated offline with Kyutai Pocket TTS stock synthetic profiles. Exact text, hashes, sources, attribution and licenses are supplied with the build. No personal voice is cloned.
- The planned community feature uses AI assistance to review feedback and develop selected changes. Suggestions stay on the player's PC and developers can manually import exported comments. A connected automated development service is not shipped in this alpha.

There is no live AI generation service or store integration in gameplay. Achievements and scores save locally.

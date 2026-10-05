# Standalone Wildforge community files

All 108 achievements unlock locally and retain stable IDs, illustrated locked/unlocked icons and existing player progress. Regenerate their definitions with `node scripts/export-achievements.mjs`.

Community Lab was removed in 0.8.0; existing local feedback files are retained as historical records. Import exported feedback with `node scripts/collect-feedback.mjs --comments exported-comments.json`. Each entry needs `id`, `text` and HTTPS `url`. This tool performs no store API calls. No automatic sharing or comment-driven development is promised.

`about.md` describes the game; `ai-content-provenance.md` records asset origins. Steam publication was cancelled by the owner on 5 October 2026. This agent performed no game upload or fee payment.

# Wildforge development working rules

These rules support the user's ongoing standalone Wildforge development request. Follow later user instructions when they change scope. Use the existing PLAN.md as the roadmap; keep the Megabonk mod out of this work.

## Persistent progress

- Keep PLAN.md and PROGRESS.md current after each completed batch. Record completed changes, decisions, exact validation commands and results, unresolved problems, and the next concrete task.
- Before context compression or handing work to another session, save enough state for a fresh session to resume from those files and the repository. Do not rely on chat summaries alone.
- On resuming, read these rules, PLAN.md, PROGRESS.md if present, and the relevant git status/diff. Preserve changes made by the user or another process.

## Execution

- Continue through authorized milestones without waiting for routine confirmation. Finish a concrete implementation and relevant verification before moving to the next batch.
- Use one development agent at a time with the current local model. Separate workstreams in the plan, but avoid simultaneous model requests that compete for its inference slot.
- Keep file reads focused. Inspect only the code needed for the current task and reuse facts already recorded rather than repeating broad repository surveys.
- After two failures with the same tool or approach, record the blocker and try a materially different approach or continue independent work. Avoid indefinite retry loops.
- Keep image-analysis questions narrow and short enough for the configured response limit. Ask for specific visual defects or comparisons rather than exhaustive descriptions.

## Quality and checkpoints

- Prioritize movement, camera, combat feedback, enemy readability, UI clarity, and consistent existing art before adding more heroes, weapons, biomes, or systems.
- Work in small, reviewable increments: implement, run relevant checks, inspect the actual result, update progress, then commit working checkpoints within the user's authorized scope.
- Distinguish newly executed validation from historical test results. Record failures honestly; content counts and passing logic checks do not establish visual quality or fun.
- For visual changes, capture and inspect rendered before/after screenshots. Preserve keyboard/controller behavior, saves, and existing gameplay rules unless the user authorized a change.
- Finish each milestone with a tested playable local build and a concise record of what improved and what remains unresolved. Treat calendar estimates as provisional.
- Keep local changes and checkpoints separate from publication. Do not push, publish, release, delete saves, or make destructive cleanup changes without applicable user authorization.

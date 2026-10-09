# Wildforge development working rules

These rules support the user's ongoing standalone Wildforge development request. Follow later user instructions when they change scope. Use the existing PLAN.md as the roadmap; keep the Megabonk mod out of this work.

## Persistent progress

- Keep PLAN.md and PROGRESS.md current after each completed batch. Record completed changes, decisions, exact validation commands and results, unresolved problems, and the next concrete task.
- Before context compression or handing work to another session, save enough state for a fresh session to resume from those files and the repository. Do not rely on chat summaries alone.
- On resuming, read these rules and HANDOFF.md first, then the relevant PLAN.md section, latest PROGRESS.md entry, and git status/diff. Avoid rereading the full historical log. Preserve changes made by the user or another process.

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

## Evidence-based implementation checkpoints

- For each batch, name one deliverable and its acceptance check. Once its cause and edit location are established, complete an edit/run/inspect cycle before broadening the investigation. Read tool arguments must select the intended lines; use explicit offset/limit and verify the returned range.
- Trace public behavior before repairing a test. Weapon variants may inherit mechanics through an archetype; validate that contract instead of adding unsupported descriptions to satisfy a raw dictionary lookup. Preserve meaningful assertions and distinguish implementation defects from stale expectations.
- Keep capture and smoke entry points independent. Select a diagnostic profile before loading career data, control camera/gameplay updates explicitly, preserve rendering, check the PNG write, and exit the diagnostic process. Verify the requested image exists and inspect it visually; headless passes establish logic only.
- Record actual fresh validation counts and failures in PROGRESS.md. Separate boolean checks from output metadata and prior passes from results after the latest edit. Correct obsolete success claims, and stage only intended files after reviewing git status/diff.

## Verified agent commands and bounded batches

Use the Hermes-managed Node runtime if node is not on PATH:
`"C:/Users/rytis/AppData/Local/hermes/tools/node-26.7.0-win32-x64/node.exe" "G:/game/scripts/agent-workflow.mjs" ACTION`

Actions: `status`, `check` (JavaScript tests + Godot import/parse), `smoke` (headless behavior), `capture` (rendered golden scene), `build` (current-source Windows export into a new staging folder). Native engine arguments are already encoded; do not improvise them or pipe these commands to tail. Give the outer terminal at least 180 seconds for check/smoke/capture and 600 for build. Full logs and exact results are under `.build-staging/agent-workflow/`; console output names the result JSON. Tests/capture use an isolated APPDATA profile. Build exports current assets; run the existing export generators only if a source-data change requires regeneration. Staged builds are development artifacts, not distributable releases with all notices.

- One batch has one deliverable and explicit acceptance evidence. Implement and test before moving to the next. After two unchanged reads or repeated errors, use the missing fact/error itself to choose a different action.
- Keep HANDOFF.md under roughly 100 lines: current objective, known facts, dirty files, exact fresh results, remaining blocker, next concrete action. Update it at each milestone and before an expected session handoff. PROGRESS.md retains history; HANDOFF.md is the concise current state.
- A fresh capture validates generation only. Inspect the image with vision_analyze for the narrow acceptance question; do not infer visual quality from file existence or exit 0. Count boolean checks separately from numeric metadata.
- After a completed tested milestone, prefer a fresh chat loaded from HANDOFF.md when the current conversation is long or repetitive. Preserve user changes, checks and logs; never clear/delete old sessions or reset the working tree. If session controls are unavailable, keep the handoff current and continue the next bounded batch.
- Use file/search/patch, terminal/process, vision, docs and todo tools for coding. Use skills only when relevant; don't create or reorganize skills while a game deliverable is unfinished. Request unavailable capabilities only when the current task actually needs them.

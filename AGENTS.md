# Wildforge project rules

These instructions apply to this repository. Start here when working as Hermes or another coding agent.

## Read first

1. Read the user's current request, then [PLAN.md](PLAN.md).
2. Read [the Godot workflow](native/docs/godot-workflow.md) before running, testing or exporting the game.
3. Consult [the repair audit](native/docs/repair-audit-2026-10-12.md) for known unfinished work. A historical `[x done]` in the plan is not proof that a feature works.
4. Inspect `git status --short`, `git diff`, and `git diff --cached` before editing. Preserve existing work, including staged changes.

## Working rules

- Work directly in small, reviewable steps. Do not start multiple agents unless the user asks for them.
- Reproduce the reported failure before fixing it where practical. Keep the original error and the passing verification log.
- Fix the first relevant parse/runtime error before chasing errors caused by it. Do not remove types, features or checks just to hide a failure.
- Use the bundled Godot console executable and `scripts/agent-workflow.mjs`. Run commands from the repository root. Do not substitute an arbitrary Godot installation.
- Prefer an existing helper and a small targeted edit over rewriting a large script. Read callers, data shapes and lifecycle/cleanup paths before replacing code.
- Do not invent Godot properties. Verify the owning class and API against the bundled engine or official documentation; then exercise the changed path at runtime.
- Preserve saves, artwork, old builds and logs. Use isolated profiles for automated gameplay. The workflow wrapper creates these automatically.
- Never kill every Godot/Node process. Stop only a process started by the current task, using its recorded process/session identity.
- Do not reset, discard, stage or commit someone else's work. When committing a completed step, include only the intended changes; inspect the staged diff first. If the index already mixes unrelated changes, leave it intact and report the state.
- Keep local export and publishing separate. Make local builds when needed; publish only within the user's requested scope.

## Validation required for code changes

1. Run `node scripts/agent-workflow.mjs check` after edits to verify JS tests plus Godot import/parse.
2. Run `smoke` for startup/runtime changes, and `integration` for gameplay/data changes.
3. Run the relevant feature review from the workflow guide. UI changes require fresh rendered screenshots and visual inspection; headless checks cannot validate layout.
4. For menu bugs, exercise the actual button/navigation path, including reopening the menu and changing selection. Calling an internal selection function alone does not prove the menu works.
5. Run `build` after a meaningful group of validated changes. It exports into a new staging folder and smoke-tests that executable. Verify rendered behavior on the exported game when UI/rendering changed.
6. Inspect `result.json` and the step logs. Godot can return exit code 0 while reporting script errors. A screenshot file or a completion message alone is insufficient.
7. Run `capture-ui`, `coop` and other party-hosting checks sequentially: they share UDP ports. Avoid simultaneous imports/exports or duplicate runs of the same action.

Documentation-only edits need link/command checks, not a fresh game build. Run meaningful regression tests for behavior fixes; do not add tests that merely restate the implementation.

## Before marking a plan item done

- The requested behavior exists and its real entry point was exercised.
- Relevant checks pass; screenshots were inspected for visual changes.
- No relevant script/runtime errors remain unexplained.
- The plan records the evidence path, build path if applicable, and any limitation.
- Remaining failures stay open. Never loosen an assertion merely to turn a test green. If the spec changed, document the changed expectation and verify it independently before updating the test.
- Performance claims require comparable measurements. Different image hashes do not prove visibly distinct artwork.
- Update version metadata together when bumping a version: `package.json`, `native/project.godot`, `native/export_presets.cfg`, and applicable docs. Distinguish local development builds from the published release.

Report the result as: what changed, what was tested, where the executable/evidence is, and what remains unfinished.

## Build integrity rules — NEVER skip

1. **Code → commit → build.** Every code change must be committed to the repository before building. The `build` action automatically rejects dirty working trees containing uncommitted source files. Only docs, plan, and readme updates may be staged separately.
2. **One logical commit per feature set.** All changes for a single task or feature group go into one commit. This makes the commit history a reliable map of what each build contains.
3. **Verify the commit matches the build.** Before pushing or publishing, confirm the HEAD commit hash matches what the build ran against. If you built from a dirty tree, the build is invalid and must be rebuilt after committing.
4. **Never publish a build from uncommitted code.** An executable built from a dirty working tree is a lie — it cannot be reproduced, debugged, or trusted. If the agent-workflow build guard rejects you, commit the changes and rebuild.

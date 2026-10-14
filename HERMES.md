# Hermes: start here

Read [AGENTS.md](AGENTS.md) for the project rules and [the Godot workflow](native/docs/godot-workflow.md) for commands, logs, screenshots and exports.

From the repository root:

```powershell
node scripts/agent-workflow.mjs status
node scripts/agent-workflow.mjs check
node scripts/agent-workflow.mjs smoke
```

Run each command to completion and inspect its result before proceeding. Then choose the feature-specific check from the workflow guide. Do not run the full suite blindly for every edit.

Current priorities and known gaps are in [PLAN.md](PLAN.md) and the [October 12 repair audit](native/docs/repair-audit-2026-10-12.md). Read the audit before trusting old completion marks.

The current playable release is `build/red-moon-1.1.0-build12/Wildforge.exe`; local development builds and priorities are listed in [PLAN.md](PLAN.md). Use `Play-Wildforge.cmd` for the latest verified local build. Archived old executables can be restored using [workspace cleanup notes](native/docs/workspace-cleanup-2026-10-13.md). Read [the gameplay repair report](native/docs/gameplay-repair-0.8.10.md) for the current XP design, weapon-compatibility rules, harvestable effects and exact passing/failing evidence. Preserve these regressions when continuing the plan: `gameplay_repair_checks.gd` runs with `smoke`; small-step/gentle-hill checks run with `surface-review`; `capture-ui` exercises co-op hero buttons and records all six harvestables. `pace-review` is an invulnerable, accelerated 120-second cadence measurement, not a survival-balance test.

If your agent does not automatically load repository instructions, explicitly read `AGENTS.md` at the beginning of the session. This file is a navigation aid; the shared rules live in `AGENTS.md`.

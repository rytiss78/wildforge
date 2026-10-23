# Hermes: start here

Read [AGENTS.md](AGENTS.md) for the project rules and [the Godot workflow](native/docs/godot-workflow.md) for commands, logs, screenshots and exports.

From the repository root:

```powershell
node scripts/agent-workflow.mjs status
node scripts/agent-workflow.mjs check
node scripts/agent-workflow.mjs smoke
```

Run each command to completion and inspect its `result.json` and logs before proceeding. Then choose the feature-specific review from the workflow guide; do not run the full suite blindly for every edit.

Current state, priorities and known gaps are in [PLAN.md](PLAN.md). The latest published release is Build 21 ([notes](native/docs/build21-release.md)). `Play-Wildforge.cmd` opens the most recent local build made by the workflow. Historical plans, build notes and review reports are in [native/docs/archive](native/docs/archive/).

If your agent does not automatically load repository instructions, explicitly read `AGENTS.md` at the beginning of the session. This file is a navigation aid; the shared rules live in `AGENTS.md`.

# Visual overhaul baseline — October 12, 2026

Branch: `codex/1.0.0-visual-overhaul`. Source version remains 0.8.10 until release validation.

## Preservation and scope

Before editing, saved 5,564 tracked/untracked working files with SHA-256 hashes, the original binary index, `status.z`, and separate binary staged/unstaged/HEAD patches under `.build-staging/visual-overhaul-1.0.0/baseline/`. Original HEAD and branch are in `snapshot.json`. The initial in-memory patch capture exceeded its buffer; all three final patches were subsequently streamed directly to disk successfully.

Incoming index: 728 paths, including 696 content illustrations, one orphan import sidecar, source changes, marketing material and root executables. The baseline checkpoint explicitly selects source/repair files and their dependencies. Root executables (including a temporary pack), community documents, old marketing screenshots and `icon-template.svg.import` remain staged and untouched; they are not certified release assets. The source checkpoint includes prior 0.8.7–0.8.10 repairs and the 1.0.0 roadmap, not new overhaul artwork. Selected text files were scanned for credential-bearing URLs, common GitHub tokens and private keys; no candidates were found. Git remote URLs must never be printed.

The [machine-readable inventory](visual-asset-manifest.json) lists each asset's hash, runtime owner/generator, replacement and deletion state. `node scripts/visual-asset-inventory.mjs` regenerates the baseline inventory; do not regenerate over curated replacement/deletion decisions. Dynamic roots remain live until their call sites are replaced and exports are tested. Embedded geometry/shader/drawing references are included. No old asset has yet been approved for deletion.

## Camera invariants

- Runtime camera FOV: 70 degrees; default distance 12; wheel range 4–16 in 0.5 steps.
- Realm entry pitch 0.3; look clamp −0.4 to 1.1; sensitivity and invert settings preserved.
- Anchor: player position + (0, 1.2, 0); spherical orbit; lerp rate `1-exp(-delta*9)`.
- Existing occlusion ray and 0.4 m clearance, controller bindings and mouse scaling remain unchanged.
- Diagnostic captures that deliberately override the camera are not evidence of unchanged gameplay placement.

## Reproduced baseline

All evidence roots below are `.build-staging/agent-workflow/`.

| Check | Evidence | Result |
| --- | --- | --- |
| JS/import/parse | `2026-10-12T18-01-15-640Z-check` | Passed; diagnostics clean |
| Smoke | `2026-10-12T18-01-56-145Z-smoke` | 118 passed; diagnostics clean |
| Integration | `2026-10-12T18-02-16-792Z-integration` | 57 passed; 18 ObjectDB instances / 5 resources at shutdown remain |
| Combat | `2026-10-12T18-02-42-290Z-combat-review` | Passed; screenshot inspected; diagnostics clean |

Combat at 1440×810 on AMD Radeon RX 9060 XT: p50 17.461 ms, p95 35.024 ms, 657 measured frames, peak 4,694 nodes, final 1,309 draw calls, 66 enemies / 8 kills. This is one stochastic combat sample, not a precise benchmark or optimization claim. Memory was not recorded by this baseline review. HP orbs are visible on the enemies; dedicated full/half/low/shield/remote orb coverage remains open.

Verified pre-overhaul executable: `build/gameplay-0.8.10/Wildforge.exe`; hashes and exported UI evidence are in [the repair report](gameplay-repair-0.8.10.md). The source baseline reproduces its check results. Known co-op wraparound/teardown and Eclipse handling acceptance failures remain open; see [the audit](repair-audit-2026-10-12.md).

## Next

Implement the shared dark UI and bottom-emitting damage feedback first, then a rendered Clover Woods representative scene with original modeled forms, before expanding the roster. Stage 0 remains partial until additional orb/memory coverage is recorded; stage 1 is not complete merely because its palette exists.

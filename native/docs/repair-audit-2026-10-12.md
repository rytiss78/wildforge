# October 12 repair and PLAN.md audit

Follow-up: achievement visuals/audio were subsequently replaced in [local build 0.8.9](achievement-ui-0.8.9.md), using modern Series X-inspired visuals and original synthesized audio. The audit below preserves the earlier 0.8.7 repair evidence.

The [0.8.10 gameplay repair](gameplay-repair-0.8.10.md) subsequently addresses small hills, inconsistent XP, current-loadout compatibility, co-op specialties, damage readability and harvestables. Its report supersedes those baseline findings below; unrelated open issues remain open.

The incoming working tree did not launch. The completion marks in PLAN.md were not reliable. This audit covers the active list, including its duplicate item numbers; the older unnumbered history is not a new feature certification.

## Reproduced failures and repairs

- **Launch/export:** `hud.gd` declared `num_color` twice; `game.gd` assigned an undeclared `flash_timer`. Both scripts now parse. Rain/status particles also used nonexistent Godot properties and had no draw meshes. Corrected the properties and supplied meshes.
- **Co-op hero selection:** moving `portrait` into a class variable did not fix its lifetime. Opening a modal queues the previous portrait's parent for deletion. The co-op menu now creates its own portrait every time. The UI test presses a hero button and verifies the replacement survives subsequent frames.
- **Overlapping HUD:** an empty gold panel covered health/coins. Coins now belong to that panel, which sits below health. Armor has readable text. The generic visibility loop no longer exposes inactive achievement panels.
- **Resolution/layout:** replaced the invalid `keep_aspect_covered` stretch mode with `canvas_items`; scaled the menu backdrop to its actual size. The smoke test now checks settings against the actual viewport instead of a hard-coded 810-pixel height.
- **Blank reward cards:** `PowerIcon` nodes were allocated but never parented. They now belong to the card. SVG card art takes precedence over older skill PNGs. Conditional augment cards describe their activation condition instead of treating `air`, `dash`, etc. as nonexistent weapon IDs.
- **Damage report:** the `dedup_` prefix did not prevent timestamps and array indices from appearing as damage totals. Aggregation now searches the small live damage-number pool, keeping `damage_sources` exclusively for credited damage.
- **Accounting:** removed the second addition of all run kills (kills were already counted on each death); reset `death_count` when a new run starts.
- **Effects:** status indicators now synchronize with active effects and expire correctly; aura visuals require an aura upgrade, follow the player, and clean up. Boss telegraph records now include the velocity required by the effects update loop.
- **Camera:** a negative initial orbital pitch put the camera below the ground. Initial pitch is positive and orbit position uses the same body anchor as look-at.
- **Enemy pursuit:** the early return for ground-level players prevented enemies crossing walls and interrupted attached traversal. Wall acquisition now works independently of the elevated-target slope gate; edge transitions work again.
- **Achievements/music:** notifications now come from the actual unlock callback, with UI audio and slide/fade behavior. Fixed duplicate parenting of the popup contents. WAV loop end now uses sample frames, not byte count.

## Item-by-item result

“Present” means the implementation exists; it does not imply every visual/balance claim has been independently proved.

| PLAN item | Result after repair | Evidence / remaining work |
| --- | --- | --- |
| 0 — co-op portrait | Fixed | New portrait per menu; actual hero button exercised in `ui_review.gd`. |
| 1 — status indicators | Fixed | Incoming activation checks never fired for already-active statuses; invalid particle properties corrected. Regression checks cover creation and expiry. |
| 2 — damage clarity | Present, partially unverified | Colors/flash/size exist and parse. `fly_speed` is stored but not used by HUD positioning, so the claimed faster slam animation is not implemented. |
| 3 — death counter / last-run pause stats | Partial | Reset/double-kill accounting fixed. Pause extras still require a saved record for the current run, so a live pause does not show the promised last-run statistics. |
| 4 — enemy labels / shield / armor | Partial | Labels removed and hero shield/armor UI exists. Boss mesh health bars remain despite the explicit “no floating HP bars” claim; host/client update paths differ. |
| 5 — harvestables | **Incomplete** | Fixed invalid TorusMesh property that interrupted generation. All six types still spawn randomly rather than in their matching biomes. Temporary bonuses directly modify stats without expiration; `damage += 10` is not +10%, sulfur adds flat burn, and the gold-labelled pearl adds luck. No active-buff HUD or pickup burst is implemented. Herbs bypass `heal()` accounting. Pot-related upgrades/achievements need reconciliation. |
| 2 — XP pace | Present | `8 + 6*level + 2*level²`; level 1 = 16, level 8 = 184. Gameplay pacing not newly benchmarked. |
| 3 — enemies stuck on ground | Fixed regression | Ground walking retained, wall/ceiling/ledge/slope tests pass after repairing acquisition and transition logic. |
| 4 — mouse vertical look | Superseded | Later TPS orbit task changes the meaning of vertical input. Mouse changes orbital pitch; wheel changes distance. |
| 5 — weapon applicability | Incoming implementation wrong; fixed | Catalog augments are conditions, not weapon IDs. Cards now use the catalog's `when` description; weapon rank/slot notes remain. |
| 6 — chest icons | Present | Ten SVG assets exist; repaired card parenting and art selection make them reachable. |
| 7 — only critical numbers | **Contradicted** | Regular `hit` numbers are hidden, but poison, fire, ice, slam, melee, explosions, aura, healing, etc. remain enabled. This also conflicts with the damage-clarity item. Policy needs reconciliation. |
| 8 — achievement popup / audio | Fixed | Actual unlock callback now drives popup and audio. Hidden/visible/expiry regression checks pass. |
| 9 — realm difficulty | Partial | HP and telegraphs scale. `attack` is a cooldown, not damage; ordinary contact damage does not receive `realm_difficulty`. Realms 0/1/2 yield 1.0/1.25/1.5, not the claimed 1.75. |
| 10 — Eclipse collision optimization | Present; speedup unproved | Squared-distance segment check exists. No evidence supports the specific 10–50× CPU improvement claim. Still loops over projectiles × enemies. |
| 11 — PARANOIA music | Fixed loop bound | Track loads and playback checks pass. Loop end corrected from bytes to sample frames. “Seamless” musical looping has not been auditioned. |
| 20 — flatter terrain | Present | Reduced amplitudes/terraces exist; integration route slope check passes. Exact ±15 height range is not proved. |
| 21 — CPU/GPU investigation | Partial evidence | Optimization exists; no new GPU offload or before/after benchmark verifies the claimed speedup. |
| 22 — damage report | Fixed | Prefix-only solution still polluted totals. Live-number aggregation now uses separate storage; regression verifies report contents. |
| 12 — Eclipse drift | Present; validation conflict | Response rates are 6/4 as planned. Existing `eclipse-review` still demands 98% turning within ~0.32 s and braking within 0.2 s; those two checks fail with the deliberately slower drift. Requires an agreed handling target and updated acceptance criteria. |
| 13 — blood rain | Repaired implementation | Invalid properties removed; draw mesh supplied. Construction is smoke-tested. Final visual density/placement during Eclipse needs review. |
| 14 — distinct non-weapon icons | Partial | 344 skill and 352 item SVGs have unique SHA-256 hashes. Rendered offers still repeat near-identical leaf motifs. Unique file contents do not establish visually distinct or semantically useful icons. |
| 15 — HUD placement | Fixed | Health, armor, coins and biome labels no longer cover each other in inspected 1440×810 captures with 1920×1080 logical layout. |
| 16 — TPS camera | Fixed initial position | Positive starting pitch and shared anchor avoid ground-clipped startup camera. Combat capture inspected. |
| 17 — aura indicator | Fixed | Previously unconditional and left at spawn position. Now gated, follows the player, pulses and cleans up; regression checks pass. |
| 18 — lightning | Present | Jagged multi-segment bolt exists. Some reaction paths still use the older beam visual. |
| 19 — enemy speed | Present | Base `2.9 + realm*.35 + random*.6`; species modifiers still apply. Bosses retain their separate base speed. |
| 20 — expanded zoom | Present | Default distance 12, wheel clamp 4–16. |

## Validation and local build

Development version is now consistently **0.8.7** in the project, package and Windows export metadata. This is a local repair build, not a newly published release.

- JavaScript tests and Godot import/parse: passed (`check`).
- Source smoke: **85 checks passed**, including the new repair regressions.
- Integration: **57 checks passed**, including a final run after the repairs. The obsolete one-banish expectation was corrected to five charges, decrementing by one.
- Surface review: **passed**, including wall, ceiling, ledge, slope, freeze, detach and network orientation.
- Combat review: **passed**. The bounded-label fixture now fills the pool with visible critical hits and separately checks ordinary hits remain hidden.
- UI: **passed** against source at 1440×810 and the final packaged executable at 1920×1080. Menu, co-op hero selection, HUD and reward screenshots inspected. Reward icons are checked for actual scene attachment and visibility.
- Packaged controls: **12 checks passed** at 1280×720; settings layout inspected.
- Six-minute source co-op run: **failed overall**, despite successful discovery, lobby/hero readiness, remote combat, revives, pause, merchant/supply/hunt rewards and guardian combat. The test forces realms 1 → 2 → 0, but `enter_realm()` only broadcasts when `index>0`; host finishes in realm 0 while client remains in realm 2. Its final assertion also incorrectly expects realm 1, and the host disconnects before the client records its final connection state. This artificial wraparound/test teardown remains unresolved; ordinary game progression ends after realm 2. Do not present the full network soak as passing.
- Eclipse review: **11 passed, 2 failed** (`quick_control`, `brakes`), as explained above. These failures are not hidden or relabelled as passes.
- Windows export: **passed**, including **85 smoke checks against the exported executable**.

Ready-to-run build: `build/repair-0.8.7/Wildforge.exe` (keep its neighboring `.pck` and runtime files). This is a byte-verified copy of `.build-staging/agent-workflow/2026-10-12T16-58-04-946Z-build/Wildforge.exe`; the previous `build/Wildforge.exe` is preserved.

Executable SHA-256: `15412ddeeb0cba269bf2849a8a11c7076c8736ee96fb0ec6c4270482619b6461`. Pack SHA-256: `1b16a26d172159d10107a5bd53a804a1ef9121c084a32ed91084d99725ff6433`.

Evidence is in dated directories under `.build-staging/agent-workflow/`. Relevant initial/final reports: `2026-10-12T16-44-58-181Z-check`, `2026-10-12T16-50-54-582Z-integration`, `2026-10-12T16-52-02-478Z-surface-review`, `2026-10-12T16-53-09-305Z-smoke`, `2026-10-12T16-53-55-874Z-combat-review`, and `2026-10-12T16-53-55-874Z-build`.

Final reports: `2026-10-12T16-57-40-694Z-integration`, `2026-10-12T16-58-04-946Z-build`, `2026-10-12T16-58-22-070Z-capture-ui`, and `2026-10-12T16-52-02-478Z-coop`. Packaged captures/logs are under `.build-staging/repair-packaged-ui/` and `.build-staging/repair-packaged-controls/`.

All automated runs use isolated profiles. Existing saves, staged changes, artwork, old builds and logs were preserved. The incoming index already contained 728 changed files; this repair does not commit that unrelated staged work or publish a release.

## Reproducible Godot workflow

From the repository root, run these sequentially:

```powershell
node scripts/agent-workflow.mjs check
node scripts/agent-workflow.mjs integration
node scripts/agent-workflow.mjs capture-ui
node scripts/agent-workflow.mjs coop
node scripts/agent-workflow.mjs build
```

`capture-ui` and `coop` must run sequentially: both host on UDP 29736. Inspect the screenshots; a successful capture marker alone does not prove the layout is correct. The wrapper checks script diagnostics because Godot's editor import can return exit code 0 even when scripts do not compile. Build in staging to preserve older exports.

# Combat and feedback 0.4.0 verification

Verified on 2026-10-05 with the pinned local Megabonk 1.0.69 installation.

- Release build: zero warnings and zero errors.
- Build audit: all 100 resolved effect keys and 18 conditions have runtime consumers, excluding smoke code. Machine-readable references are in `artifacts/skill-coverage.json`; this is coverage evidence, not proof of combat semantics.
- Every one of the 694 cards passes acquisition, stacking, effect resolution and removal in the live player inventory. Conditional activation and source-style additive conditional stacking pass.
- A Wildforge attack-speed skill applies on a native Bandit inventory.
- Runtime registration: 21 heroes and named perks, 694 cards, 65 weapons, 54 enemy forms and 875 icon files.
- All 21 hero starting-weapon inventories construct successfully.
- All 57 distinct original actor GLBs load and contain HP orb meshes.
- Live Forest run: Count Duck and starting gun initialize; sampled cards stack. Two Clover stacks add 0.28 luck and two Boots stacks add 0.2544 native speed multiplier.
- All 54 enemy forms spawn and attach their original models.
- After native spawn protection expires, actual HP damage and the shared healing observer pass.
- Hero and enemy orbs both show partial HP fill.
- All 65 weapon models construct with renderable meshes.
- Three power cards increase actual equipped damage from 15 to 19.97; three speed cards reduce firing cooldown from 0.606 to 0.455 seconds. Removing the cards restores damage.
- Normal native gun attacks hit enemies while preserving custom weapon identity and returning attacks to compatible pools.
- Dash activation, cooldown rejection and sustained horizontal velocity pass. R-deployed turret, visible models, generated audio and effect cues initialize.
- Final batch reports `SMOKE PASS` in `artifacts/latest-smoke.log`.

The smoke uses explicit player initialization and an observer fallback for interop calls. All skill inventory/effect-resolution checks pass; this does not verify every combat proc, normal menu interaction, visual acceptance, exact source combat behavior or complete-run balance. Native attack/AI adapters have the limitations described in README.md. Native actor indicators remain on their original code path; normal-play acceptance of both indicator styles remains pending.

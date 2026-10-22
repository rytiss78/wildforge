# Wildforge 1.2.1 — Build 19

Build 19 is a Windows alpha release. `build-info.json` inside the archive records the exact source commit and artifact hashes.

## New

- **Every shot is visible:** each weapon type fires a glowing ink trail in its colour, with a muzzle flash.
  - Flame shots shed embers, poison drips, ice frost glints and rockets smoke.
  - Ghost shots trail wisps, and rolling bombs fizz.
  - The Rail Gun leaves a long cyan beam. Critical hits are gold.
- **Every hit has its own impact:**
  - Gun shots burst into a star, Rail Gun shots pierce through with a streak, and Fire Gun shots flare.
  - Poison splats and stains the ground, ice rings with frost, lightning forks, ghost shots ring and bubbles pop.
  - Critical hits add a gold star.
  - When you are hit, a red mark shows the side the blow came from, or a cyan one when your shield takes it.
- **Fire and poison you can read:**
  - Burning enemies are wrapped in flames and poisoned ones bubble.
  - Frozen enemies sit in an ice shell; short stuns stay clean. Blinded ones are circled by dark motes.
  - A flare pops on each enemy as it catches fire or poison, so you can watch it spread through a group.
  - Burning or poisoned enemies burst into embers or a toxic spray when they die.
- **Meteor Gun:** the target is a gold warning ring instead of a flat disc.

## Changed

- **Mutation balance from measured damage.** Every mutation was measured through the real game code and tuned toward an even spread:
  - In a crowd, strains now deal 48–65% of the starting gun's damage each, where they ranged from 34% to 123% before.
  - Strongest changes: Venom is weaker, Comet and Bloom stronger, and dash and jump triggers weaker. Slam triggers are stronger.
  - Mastery is now +40% damage and 15% reach. Conductor jumps to 2 more enemies, Shatter is +50%, Wide Arc reaches 25% farther, and Thermal Shock's explosion is much smaller.
  - Card texts match the new numbers.

## Verification

- The export from source commit `9dbee5d` passes the 118-assertion startup smoke.
- The exported 720p and 1080p rendered release review passes, and the exported combat capture shows the new shot trail.
- Exported two-process co-op passes all 104 checks, also with lag and a slow peer.
- The exported magnet, hunt and eclipse feature review passes.
- Source reviews pass: integration, smoke, style, playfeel, combat, co-op shared review and the new weapon-effects review.
- In a 69-enemy fight the new effects cost about 0.35 ms per frame (2%), measured against Build 18 code in the same session.

## Known limits

- Mutation balance is measured against stationary targets, not playtested.
- Real-fight Baron balance remains unverified.
- Creature, hero and boss models are mostly the earlier stylized designs.

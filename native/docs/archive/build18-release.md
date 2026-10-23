# Wildforge 1.2.0 — Build 18

Build 18 is a Windows alpha release. `build-info.json` inside the archive records the exact source commit and artifact hashes.

## New

- **102 mutations.** Runs now change shape instead of stacking percentages:
  - Six biome strains (Bloom, Venom, Frost, Storm, Ember, Comet) release their element when you hit, crit, kill, dash, jump, slam, get hurt, collect coins, or on a timer.
  - Strain rules (for example Shatter and Wildfire), two-strain hybrids and wild cards bend them further.
  - Taking a mutation again levels it up.
  - Level-ups offer three mutations, and chests sometimes one. Each mutation card has a medallion icon: its colour shows the strain, its symbol shows the trigger.
- **New look:** a shared ink outline over the whole world, a richer colour grade, glow on hot accents, and a main menu that matches the in-game windows.
- **Redesigned final Baron:** a colossal, bald, floating figure who hovers above the Red Moon with steam rising off him. He is an original stylized model, not a film likeness.
- **Giant-orb magnet:** activating the E.X.P. magnet pulls every XP orb on the map, once, into one ever-growing orb beside it. Walk over to collect it. Magnet guards are now tall cyan pylons.
- **Damage numbers on every hit:** your gun's numbers rise from its weapon slot; other damage rises from the band above the HUD.

## Fixed

- **Co-op desync with crowds:** world updates were too large past about 80 enemies, and clients silently stopped receiving them. 100-enemy updates went from 82,736 to 11,208 bytes.
- **Co-op reconnect:** rejoining now resyncs the realm and opened chests, keeps an open reward screen usable, restores the nameplate, and no longer freezes the host.
- **Co-op reward panel:** the teammates' reward panel no longer stays on screen or covers the pause menu.
- **Upgrade offers:** offers no longer show two cards with the same effect.

## Verification

- The export from the release commit passes the 118-assertion startup smoke.
- Exported two-process co-op passes, including a 100-enemy crowd stage and drops mid-reward and across a realm change.
- The exported magnet, HUD, weather and audio review passes.
- The exported 720p and 1080p rendered release review passes.
- Source reviews pass: integration (91 checks, including 13 mutation checks), the full co-op route, combat, boss, Red Moon, biome, UI and journey reviews.

## Known limits

- Mutation balance has not been playtested; numbers are first-pass.
- Real-fight Baron balance remains unverified.
- Creature, hero and boss models are mostly the earlier stylized designs. Procedural rebuilds were tried and rejected as worse.

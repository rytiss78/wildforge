# Wildforge 0.8.2

Final Windows build for the requested update, dated 2026-10-05.

- 800 × 800 m world, 24 paid chests per realm distributed four per biome, and five reward choices.
- Exactly 400 added entries: 180 items, 180 skills and 40 weapon variants. The complete catalog contains 694 item/skill entries and 65 weapons. Conditional cards combine 18 activation conditions with 20 bonuses; weapon variants modify existing attack archetypes.
- Rich painted collectible icons replace the basic vector presentation. All 759 runtime icons have distinct pixel compositions, with condition seals and identity engraving. Forty new weapons each have individual painted object art. Existing 65 patterned weapon textures remain.
- Jump Boots multiply jump height: common +20%, higher rarity increases the bonus. Extra Hop grants an additional air jump. Both have item and skill cards, with winged boots and feather art.
- The island slopes to a sandy beach and ends in a visible animated deadly sea. Crossing 375 m on either axis kills players and removes enemies; the warning appears before the shoreline. Scenery stops before the coastal strip.
- The minimap reveals the whole island immediately, without exploration fog. It rotates with the camera and shows unopened chests, merchant, active supply signal, landmarks, breakable pots, dropped potions, gate, party members and pings. Used/removed interactables disappear.
- Co-op merchant purchases send the latest position/funds before the transaction and explicitly reject invalid requests, preventing a pending menu from freezing the party. The minimap follows the merchant’s current wandering position.
- Earlier selected update work includes merchants, banish, reactions, rescue and pings, supply defence, creature movement/collision improvements, merged currency, 108 achievements and 63 hero quips. Ordinary ranged enemies have reduced HP and an eight-second attack cooldown; heroes and bosses retain their own rules.

## Validation

55 integrated source-build checks passed, covering distinct rendered icon pixels, content totals, all 40 weapon firing branches, jump multiplier/air-jump cards, sea geometry/shore heights, minimap terrain/markers, card selections, chest distribution, collision, reactions, interactions, saves and realm traversal. The final packaged build also passed all 55 checks. Local host/guest checks cover downing/rescue, pings, merchant purchases, supply rewards, party pause, realm travel and remote hits. The release script now requires all interaction results to pass. Evidence is retained in `validation-0.8.2/`.

A 36-second crowded stability run visited all six biomes without runtime errors, with 6,541 maximum nodes and ground error below 0.001 m. It ran concurrently with other validation processes, so its timings are recorded as evidence rather than compared with previous isolated benchmarks.

Real career saves were not used for validation. Previous achievement IDs and existing save data remain preserved. Tests use isolated APPDATA. Local two-player tests and simulated controller input do not establish physical controller or four-machine compatibility. This final update build does not establish long-run balance across every combination.

Artwork provenance is recorded in `../assets/illustrated/content/art-provenance.json`; the reproducible icon bake uses the stored atlas and code-authored seals. Historical 0.8.0/0.8.1 notes remain evidence for those builds, not the current settings.

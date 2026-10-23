# Wildforge 0.7.5 — orb-first heroes

All 21 hero GLBs are replaced with fresh articulated 3D geometry authored around a central glass orb. `scripts/build-orb-heroes.py` builds the orb first, then the character-specific chassis, head, limbs, hands and details. It does not convert sprites, reuse the previous hero meshes, or cut a hole into a completed character. World-model regeneration also routes hero generation through the new builder.

The silhouettes include a gear-bodied wrench, a vampire duck with a split cape, a potato rind exoskeleton, a rocking-chair granny, a ledger rat, a croissant knight, a petal-bodied Florist, a glass teapot, an eight-limbed pirate, an astronaut gimbal suit, a spiked cactus ring, an open spellbook, a snail shell with eye stalks, a honey bee, a rice-and-seaweed roll, a hollow mushroom stem, an alarm clock, a waffle bowl, an open miniature bath, a peacock fan and an open toaster. Existing named perks and held-weapon/third-hand support remain. Original illustrated paper and material swatches supply the established visual style; these are directly authored 3D models.

Blood cores and impact splatters always use red blood. The black tank-blood branch is removed. Transparent blue armour/shield glass is retained. The Style Lab no longer describes black blood.

Flying-spawn probability is exactly one tenth of its previous absolute weight in each biome: forest 3.8%, swamp 2.4%, moon 4.8%, clouds 8.2%, hell 1.4%, space 5.2%. Within flying and grounded groups, original relative species weights remain. This changes the spawn mix rather than grounding flying creatures or reducing the total enemy count.

Glowing XP drops use the same gravity, soft bounce, terrain landing and attraction path as coins, with a smaller ground clearance. They no longer hover at the height of a defeated flying creature. Reward values and XP glow remain.

The ambiguous old `coin number / box number` becomes `GOLD <owned>  BOX PRICE <next paid box>`. The bottom panel labels `LEVEL <hero level>` and `XP <current points> / <points needed> to next level`, with the XP progress bar. Boxes left and weapon upgrade levels keep their labels. There are still no HUD health/armour gauges.

Compilation and packaging passed. The focused packaged rendered check passed 18 checks, including all hero bonuses/orbs, protection and health state, critical/extra-shot perks, red blood, labelled HUD, XP gravity and landing, glow preservation, and 36,000 sampled biome spawn choices. Roster front/back, hero selection and gameplay HUD captures were inspected. The same check was rerun after correcting its hero-selection setup to capture the selected hero. No broad multiplayer or stress suite was repeated. Log: `hero-0.7.5.log`; captures: `user://heroes-front-0.7.5.png`, `user://heroes-back-0.7.5.png`, `user://hero-hud-0.7.5.png`, `user://hero-menu-0.7.5.png`.

The existing `build/Wildforge.exe` and pack were replaced. Co-op protocol is `wildforge-0.7.5-1`.

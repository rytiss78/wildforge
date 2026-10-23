# Wildforge 0.7.9 — colour, choices and character

Stronger world colours, clearer nearby scenery, six distinct biome landmarks, detailed skill illustrations, animated card reveals and original power-family selection sounds.

Paid rerolls use R, Xbox Y or the on-screen button. The first costs max(10, level × 4) coins and doubles within the current reward. Full weapon slots still offer only upgrades to owned weapons. Boxes sneeze four collectible coins; upgrading the third weapon earns a brief third-hand thumbs-up.

Combat corrections cover range-dependent projectile flight, fast-shot collision, size-dependent hit radius, thorns, frozen/blinded attack initiation and muted weapon loops. Selection focus survives switching between mouse and controller. Card generation and previews reuse indexed pools and cached assets; landmark geometry is batched.

## Packaged validation

- Twenty focused checks passed, covering animation, sounds, device switching, reroll charging, unaffordable rerolls, full slots, range, fast projectiles, thorns, landmarks and both jokes.
- Rendered 1920×1080 captures inspected for all six landmarks and the selection screen.
- A 36-second crowded run visited all six biomes without falling through the terrain or script errors. Median frame time was 4.143 ms and the 95th percentile was 29.32 ms on Ryzen 7 5800X / Radeon RX 9060 XT. Co-op diagnostics overlapped part of this run, so this is a smoke performance sample rather than an isolated benchmark. Occasional hitches remain.
- Packaged co-op host/client passed discovery, connection, replicated enemies, remote damage, movement, kills, realm transition and party pause checks.

See [balance review](balance-review-0.7.9.md) for findings and unapproved tuning recommendations, and [twenty funny proposals](funny-ideas.md) for ideas awaiting selection.

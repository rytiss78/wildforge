# Wildforge 0.7.3 — grounded coins

Coins scatter 0.8–1.15 m horizontally from their original drop position so they no longer spawn directly inside the paired XP orb. A small outward toss and gravity bring them down to the terrain, including after flying-enemy kills. Coins bounce once, then remain on the ground without the old idle hovering. Ground height follows the same terrain triangles used for collision. Attraction pulls coins toward the hero and completes collection without resetting them to their original airborne height.

XP retains its glow and idle movement. Reward values, pickup limits, merge behavior and magnet bonuses are preserved. The existing single Windows build was replaced; no additional playable version was created.

Packaging and script preflight passed. One focused packaged check passed all nine checks: separated spawns, aerial fall, landing, no idle floating, XP presentation, reward value preservation, coin magnet collection, XP collection and hill landing. See `pickup-0.7.3.log`. No broad gameplay or multiplayer suite was rerun.

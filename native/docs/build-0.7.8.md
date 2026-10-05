# Wildforge 0.7.8 — gameplay performance and enemy attacks

Enemy obstacle probes now ignore player colliders and distinguish walkable slopes from walls. Enemies follow wall tangents, choosing compatible routes with nearby enemies instead of switching directions and bunching up. Physical movement still collides with heroes and scenery. Contact attacks use the position after movement, and frozen enemies cannot deal contact damage.

Obstacle probes run about eight times per second instead of every enemy update. Crowd buckets rebuild only when enemies update. Terrain heights reuse grid vertices until the realm or seed changes. XP checks for touching drops run ten times per second; drop movement, gravity, attraction and collection remain at the physics rate. Settled XP reuses its landing height. Projectile, chain and crowd comparisons use entity IDs rather than comparing whole dictionaries.

## Validation

- Windows native export and script preflight passed.
- Packaged `--combat-check`: all six ground behaviours and a flying enemy dealt damage; movement collision masks stayed intact; frozen contact damage was blocked; merged XP landed and collected without losing value.
- Packaged `--crowd-xp-check`: all 12 enemies passed a solid wall in the crowd simulation; spawn recycling, boss protection, XP rewards, drop merging and collection passed.
- Packaged `--soak`: crowded gameplay through six biomes with roughly 100–110 enemies. On a Ryzen 7 5800X and Radeon RX 9060 XT, median frame time fell from 129.45 ms to 3.80 ms and the 95th percentile from 144.07 ms to 28.59 ms. The soak harness also stopped comparing whole enemy dictionaries when recording spacing. These randomized runs are indicative, not identical workloads or a minimum FPS guarantee; occasional hitches remain.

The existing music, voices, illustrated assets, co-op wire format and saved careers are preserved.

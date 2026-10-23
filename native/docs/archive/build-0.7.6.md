# Wildforge 0.7.6

Enemy XP is proportional to spawn-time health and attack strength, including species, biome, difficulty and elite scaling. Co-op kill messages carry the same base reward; each player's XP bonuses still apply individually.

Touching XP spheres coalesce in 3D, preserving their combined reward. Smaller drops flow into the larger sphere with a short shrink/growth pulse. Combined drops grow, glow and settle on the terrain with their new radius. Coins remain separate.

Ground creatures steer around solid obstacles. Crowd separation slides along scenery rather than reverting valid movement, and exact overlaps receive opposite pushes. At the enemy cap, non-boss enemies beyond 55 metres from every living party member can be despawned to allow fresh nearby enemies. Recycling grants no kill rewards and preserves bosses.

Steam publisher registration has been opened for the owner. SteamPipe configuration tooling is prepared; assigned Steam IDs and completed onboarding are still needed before upload and Valve review.

Validation uses one focused packaged-game scenario covering reward scaling, touching versus vertically separated orbs, XP conservation through collection, gravity, glow, cap recovery and boss protection. Twelve real creature capsules are simulated around a solid wall. The initial collection assertion was corrected to count an additional nearby drop collected at the same time; production collection correctly awarded its XP.

Final packaged result: all 14 assertions passed; 12/12 creatures passed to the far side of the wall. Log: `crowd-xp-0.7.6.log`. Existing mint-pistol resource UID warnings fall back to the correct texture path; no gameplay script errors were reported.

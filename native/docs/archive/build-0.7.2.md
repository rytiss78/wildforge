# Wildforge 0.7.2 — reaching melee

The Saw now starts with 8 metres of actual reach, increased by range bonuses. Targeting measures distance to the enemy's body surface, including large creatures, rather than requiring the hero to touch it or reach its centre.

The held Saw stays attached to its hand. A funny stretching arm winds up, sweeps toward the target, and retracts. The blade spins; damage lands halfway through the swing in a forward arc. A cream slash ribbon, swish, impact sound and controller pulse mark the strike. The weapon card explains the mechanic and starting reach.

Direct weapon hits create illustrated blood droplets and a short-lived ground splatter. Tank creatures retain dark blood. Poison/fire ticks do not repeatedly spray blood, and direct-hit splatter has a per-enemy cooldown and shares the existing effect budget. No persistent blood accumulation.

Co-op shot messages carry swing duration so remote held weapons use the same animation and delayed slash. Remote cosmetic swings do not apply additional local damage. Protocol changed to `wildforge-0.7.2-1`; party members must use the same build. Full multiplayer end-to-end testing was not repeated for this update.

The single Windows build was replaced in `build/Wildforge.exe`. Compilation and packaging succeeded. One focused rendered packaged regression found incorrect scaling in the stretching arm; the geometry was corrected and that same regression rerun. All 13 checks passed: starting reach, windup delay, timed damage, separated contact, forward arc, hand reach, slash, blood, no DOT splatter spam, hand return, remote visual damage isolation, pause, and cleanup. Log: `melee-0.7.2.log`. Rendered capture: `user://melee-0.7.2.png`.

# Wildforge — plan

November 1, 2026 · main branch · **Build 27 (1.10.0) is the latest public release** ([build-27](https://github.com/rytiss78/wildforge/releases/tag/build-27), notes [build27-release.md](native/docs/build27-release.md), source `0ce3a57`).

Rules: [AGENTS.md](AGENTS.md) and the [Godot workflow](native/docs/godot-workflow.md). A checked item means the real entry point was exercised and the evidence is recorded. Everything done up to Build 27, with evidence paths, is in git history (the last full plan is `PLAN.md` at commit `0ce3a57`); release notes are on the [GitHub releases page](https://github.com/rytiss78/wildforge/releases).

## The game today

- **Run:** three floating islands of seven biomes each (Junkyard Planet is the seventh). Each island has a 10-minute clock, two wardens and a portal; then the Red Moon arena with the final boss, **The Grand Noggin** (a giant floating head; its glass eyes are its health), then an endless Eclipse.
- **Islands float:** no sea. Walking over the rim flips the hero to walk upside down under the island, out of the fight; enemies, drops and chests stay on top. The Red Moon arena keeps its deadly void.
- **Content:** 26 heroes, each with a unique trick (V / left trigger); 73 weapons including four spells; weapon evolutions and spell–mutation synergies; a fight mechanic per biome; 60 original cartoon creatures built around glass health orbs; elites, hunts, beacons, exploding barrels, a merchant; 93 achievements with hats and cosmetics.
- **Pets:** wisps over the shoulder, chosen with the hero: Glint (fetches), Sting (bites), Halo (heals). Treats drop only from the final boss and are kept between runs (stage 2 after one win, stage 3 after three).
- **Co-op:** up to four players over LAN or the internet (UPnP invite codes, or a tunnel). Drop-in, reconnect with replayed rewards, rescue codes, party combos. Exact build match required; protocol `wildforge-shared-world-18`.
- **Presentation:** 60 fps cap, show-don't-tell HUD (symbols, details in tooltips), own title intro instead of the engine splash, calmer audio with an enemy sound budget, own window and exe icon.
- **Waiting:** Block Drop in the pause menu and co-op waiting overlay, with TikTok or YouTube Shorts beside it.
- **Tooling:** `node scripts/agent-workflow.mjs` (check, smoke, integration, about 50 rendered and two-process reviews, `bot-playtest`, `build`, `test-build`); `scripts/package-release.ps1` packs a release.

## Since Build 27

- [x] **Digby Mole, the 26th hero** (user request, November 1). A velvet-grey miner (hard hat with a lamp, pink star nose, round glasses, buck teeth, big pink paws, orb belly) with the Rolling Bomb and the Tunnel Vision perk (dashing burrows, bursting out for 30). His trick **Dig Through** (V, 9 s) tunnels straight through the island in 0.9 s to the same spot on the other side: the camera rolls over about its view line so forward stays forward; popping out on top blasts and knocks back the enemies there. On the Red Moon (no underside) it is a burrow-and-burst in place. `Underside.dig`/`can_dig`/`finish_dig`; co-op protocol 18. Checks: smoke `mole_dig_down`, `mole_dig_up`, `mole_hero`, `hero_roster` (26); integration `hero_tricks`; `underside-review` captures `mole`, `mole-dig`, `mole-under`, `mole-up`; `cartoon-review` hero sheet now six cells. **Voice** (`scripts/generate-hero-voices.py`, Kokoro am_santa): hurt "Oof!" / "Mind the paws!", his own quips ("Ooh. Something shiny down here.", "Big fella. I will dig round him.", "More paws. Faster digging.") and a trick shout "Dig, dig, dig!" (`HeroTricks.shout`, at most every 15 s; any hero with a `quip_<id>_trick.wav` gets one). Integration `mole_voice`. Not yet heard by a person; a live feel test of the roll.

- [x] **Pets chosen by look, also in co-op** (user, November 1). The hero screen and the co-op menu show the three wisps as drawn icons (`PetIcon`, `hud.pet_picker`): Glint's eye, Sting's flame wings, Halo's ring, orbiting motes for its stage, a gold ring on the chosen one; names and jobs only in the tooltip. capture-ui asserts both pickers (no text) and that picking saves.

- [x] **Junkyard crushers squash and lift** (user, November 1). When the plate lands, ordinary monsters under it are squashed outright; the hero and bosses take damage and are shoved out past its edge (no clipping into or onto it). Then the plate is a solid lift (`AnimatableBody3D` on collision layer 8, which heroes and monsters now collide with): it rests 2 s as a step, rises 5.5 m over 2.4 s carrying whoever stands on it, holds 1.6 s and lets go below fall-damage height. The playtest bot no longer avoids a plate that has already struck. Rendered `crusher-review` (new action) checks squash, push-out, riding hero and monster, the safe landing; captures `crusher-rest/ride/top`.

- [x] **Monsters 10% faster** (user, November 1): `ENEMY_SPEED_SCALE` 1.1 → 1.21 for every monster (elites, flyers, chargers and Eclipse ramps scale from it) and `BOSS_SPEED_SCALE` 1.1 for the realm bosses and the Noggin, whose speed came straight from BossBook. Hero speed unchanged. Not bot-measured.

- [x] **Under the island: jump, slam, turrets** (user, November 1). Underneath, jump (and air jumps) lift the hero away from the belly and fall back onto it (`Underside.hop`); a ground slam lands with the usual blast and a shower of dirt. Turrets can be placed there, hanging upside down from the rock, and keep working while the hero is under (hand weapons still rest). Smoke `under_jump`, `under_slam`, `under_turret`; `underside-review` capture `under-turret`.
- [x] **Two turrets that pulse instead of shooting** (user, November 1: "too many similar turrets"). The Ice and Poison Turrets are replaced by the **Mender Turret** (`heal-turret`, green cross; heals the hero standing in its green ring) and the **Thumper Turret** (`pulse-turret`, speaker cone; knocks enemies in its blue ring away and hurts them). Both draw their ring on the ground (`GroundRing`). Turret cards work on them: Stronger turret heals more / pushes and hurts harder, Faster turret pulses more often, Turret reach widens the ring; weapon ranks add power (`TurretPulse`). New models and icons; co-op protocol 19. Integration `mender_heals`, `thumper_pushes`; weapon-review measures the Mender's healing growing with rank (15 → 24 HP in 6 s).
- [x] **Florist: fewer flowers, bigger area** (user, November 1). One flower every 7 m instead of 2.3 m (seed cards add up to two more beside it), at most 14 instead of 48. Each flower is 1.6× bigger and stands in a ring showing its 5 m reach (was 3 m); a bloom blasts the whole ring for twice the damage and heals twice as much, with an ink wave. Integration `flowers_wide`; weapon-review flowers 2,013 → 4,327 damage from rank 1 to 5.
- `playfeel-review` fails `grove_walk_0` and `turret_selected` on main before these changes too (checked on a stash); not yet investigated.

## Next

- [ ] **Human playtest of Build 27:** the flip under the island (feel, camera, flipped controls), the wisps in motion, the calmer audio. Decide whether hiding underneath is too safe (simple fix: a slow health drain while under).
- [ ] **Balance with people.** Bots last measured 75% clear island 1 / 25% reach the final boss / 0% beat it (12 runs, before the October 25 "dangerous, not tanky" change, which is not bot-measured). Target about 70 / 25 / 10. Use 48+ run batches; 24-run batches swing about 20 points.
- [ ] **Creatures still too basic?** If so: thicker limbs and bigger heads on the stick-figure humanoid mutants (`CartoonBook` designs).
- [ ] **Two-machine co-op over the internet** with packet loss; all co-op tests so far run on one PC.

## Open issues and limits

- **Internet hosting on the user's connection:** the provider uses carrier-grade NAT (outside address 10.254.50.76), so no port mapping can work. A friend with a public address hosts, the user asks the provider for a public IP, or the party uses the tunnel. The game reports this case as carrier-grade NAT.
- **Early co-op desync:** never described in detail; open until a matching report or reproduction.
- **Performance:** three rank-9 spells in a 125-enemy crowd run at about 30 fps (physics step about 19 ms). The real fix is a script-side crowd mover and fewer posed rig parts; the profiling timers stay in the code.
- **Not heard by a person:** generated creature voices, enemy attack sounds, spell sounds, the phonk music and the intro stingers.
- **Known flaky checks** (not loosened): `shared-review` rejoin snapshot count under load, integration `biome_gust` and `spell_hits_trigger_mutations` (once, November 1), smoke `head_stomp`.
- **Remote co-op visuals:** teammates see an evolved weapon's halo but not gilded shots or spell synergy effects.

## Deferred

- **Better hero and creature models** from a hand-directed Blender pipeline. The October 23 pilot (`scripts/blender/pilot.py`, `model-review`) lost to the shipped models; the user chose to keep them.
- **A hosted relay or matchmaking server.** The user chose port opening and tunnels for now (October 22 and 24).

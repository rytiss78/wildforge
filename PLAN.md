# Wildforge — plan

November 1, 2026 · main branch · **Build 27 (1.10.0) is the latest public release** ([build-27](https://github.com/rytiss78/wildforge/releases/tag/build-27), notes [build27-release.md](native/docs/build27-release.md), source `0ce3a57`).

Rules: [AGENTS.md](AGENTS.md) and the [Godot workflow](native/docs/godot-workflow.md). A checked item means the real entry point was exercised and the evidence is recorded. Everything done up to Build 27, with evidence paths, is in git history (the last full plan is `PLAN.md` at commit `0ce3a57`); release notes are on the [GitHub releases page](https://github.com/rytiss78/wildforge/releases).

## The game today

- **Run:** three floating islands of seven biomes each (Junkyard Planet is the seventh). Each island has a 10-minute clock, two wardens and a portal; then the Red Moon arena with the final boss, **The Grand Noggin** (a giant floating head; its glass eyes are its health), then an endless Eclipse.
- **Islands float:** no sea. Walking over the rim flips the hero to walk upside down under the island, out of the fight; enemies, drops and chests stay on top. The Red Moon arena keeps its deadly void.
- **Content:** 25 heroes, each with a unique trick (V / left trigger); 73 weapons including four spells; weapon evolutions and spell–mutation synergies; a fight mechanic per biome; 60 original cartoon creatures built around glass health orbs; elites, hunts, beacons, exploding barrels, a merchant; 93 achievements with hats and cosmetics.
- **Pets:** wisps over the shoulder, chosen with the hero: Glint (fetches), Sting (bites), Halo (heals). Treats drop only from the final boss and are kept between runs (stage 2 after one win, stage 3 after three).
- **Co-op:** up to four players over LAN or the internet (UPnP invite codes, or a tunnel). Drop-in, reconnect with replayed rewards, rescue codes, party combos. Exact build match required; protocol `wildforge-shared-world-17`.
- **Presentation:** 60 fps cap, show-don't-tell HUD (symbols, details in tooltips), own title intro instead of the engine splash, calmer audio with an enemy sound budget, own window and exe icon.
- **Waiting:** Block Drop in the pause menu and co-op waiting overlay, with TikTok or YouTube Shorts beside it.
- **Tooling:** `node scripts/agent-workflow.mjs` (check, smoke, integration, about 50 rendered and two-process reviews, `bot-playtest`, `build`, `test-build`); `scripts/package-release.ps1` packs a release.

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
- **Known flaky checks** (not loosened): `shared-review` rejoin snapshot count under load, integration `biome_gust`, smoke `head_stomp`.
- **Remote co-op visuals:** teammates see an evolved weapon's halo but not gilded shots or spell synergy effects.

## Deferred

- **Better hero and creature models** from a hand-directed Blender pipeline. The October 23 pilot (`scripts/blender/pilot.py`, `model-review`) lost to the shipped models; the user chose to keep them.
- **A hosted relay or matchmaking server.** The user chose port opening and tunnels for now (October 22 and 24).

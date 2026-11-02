# Wildforge — plan

November 1, 2026 · main branch · **Build 28 (1.11.0) is the latest public release** ([build-28](https://github.com/rytiss78/wildforge/releases/tag/build-28), notes [build28-release.md](native/docs/build28-release.md)).

Rules: [AGENTS.md](AGENTS.md) and the [Godot workflow](native/docs/godot-workflow.md). A checked item means the real entry point was exercised and the evidence is recorded. Everything done up to Build 27, with evidence paths, is in git history (the last full plan is `PLAN.md` at commit `0ce3a57`); release notes are on the [GitHub releases page](https://github.com/rytiss78/wildforge/releases).

## The game today

- **Run:** three floating islands of seven biomes each (Junkyard Planet is the seventh). Each island has a 10-minute clock, two wardens and a portal; then the Red Moon arena with the final boss, **The Grand Noggin** (a giant floating head; its glass eyes are its health), then an endless Eclipse.
- **Islands float:** no sea. Walking over the rim flips the hero to walk upside down under the island, out of the fight; enemies, drops and chests stay on top. The Red Moon arena keeps its deadly void.
- **Content:** 26 heroes, each with a unique trick (V / left trigger); 73 weapons including four spells; weapon evolutions and spell–mutation synergies; a fight mechanic per biome; 60 original cartoon creatures built around glass health orbs; elites, hunts, beacons, exploding barrels, a merchant; 93 achievements with hats and cosmetics.
- **Pets:** wisps over the shoulder, chosen with the hero: Glint (fetches), Sting (bites), Halo (heals). Treats drop only from the final boss and are kept between runs (stage 2 after one win, stage 3 after three).
- **Co-op:** up to four players over LAN or the internet (UPnP invite codes, or a tunnel). Drop-in, reconnect with replayed rewards, rescue codes, party combos. Exact build match required; protocol `wildforge-shared-world-20`.
- **Presentation:** 60 fps cap, show-don't-tell HUD (symbols, details in tooltips), own title intro instead of the engine splash, calmer audio with an enemy sound budget, own window and exe icon.
- **Waiting:** Block Drop in the pause menu and co-op waiting overlay, with TikTok or YouTube Shorts beside it.
- **Tooling:** `node scripts/agent-workflow.mjs` (check, smoke, integration, about 50 rendered and two-process reviews, `bot-playtest`, `build`, `test-build`); `scripts/package-release.ps1` packs a release.

## In Build 28

- [x] **Digby Mole, the 26th hero** (user request, November 1). A velvet-grey miner (hard hat with a lamp, pink star nose, round glasses, buck teeth, big pink paws, orb belly) with the Rolling Bomb and the Tunnel Vision perk (dashing burrows, bursting out for 30). His trick **Dig Through** (V, 9 s) tunnels straight through the island in 0.9 s to the same spot on the other side: the camera rolls over about its view line so forward stays forward; popping out on top blasts and knocks back the enemies there. On the Red Moon (no underside) it is a burrow-and-burst in place. `Underside.dig`/`can_dig`/`finish_dig`; co-op protocol 18. Checks: smoke `mole_dig_down`, `mole_dig_up`, `mole_hero`, `hero_roster` (26); integration `hero_tricks`; `underside-review` captures `mole`, `mole-dig`, `mole-under`, `mole-up`; `cartoon-review` hero sheet now six cells. **Voice** (`scripts/generate-hero-voices.py`, Kokoro am_santa): hurt "Oof!" / "Mind the paws!", his own quips ("Ooh. Something shiny down here.", "Big fella. I will dig round him.", "More paws. Faster digging.") and a trick shout "Dig, dig, dig!" (`HeroTricks.shout`, at most every 15 s; any hero with a `quip_<id>_trick.wav` gets one). Integration `mole_voice`. Not yet heard by a person; a live feel test of the roll.

- [x] **Pets chosen by look, also in co-op** (user, November 1). The hero screen and the co-op menu show the three wisps as drawn icons (`PetIcon`, `hud.pet_picker`): Glint's eye, Sting's flame wings, Halo's ring, orbiting motes for its stage, a gold ring on the chosen one; names and jobs only in the tooltip. capture-ui asserts both pickers (no text) and that picking saves.

- [x] **Junkyard crushers squash and lift** (user, November 1). When the plate lands, ordinary monsters under it are squashed outright; the hero and bosses take damage and are shoved out past its edge (no clipping into or onto it). Then the plate is a solid lift (`AnimatableBody3D` on collision layer 8, which heroes and monsters now collide with): it rests 2 s as a step, rises 5.5 m over 2.4 s carrying whoever stands on it, holds 1.6 s and lets go below fall-damage height. The playtest bot no longer avoids a plate that has already struck. Rendered `crusher-review` (new action) checks squash, push-out, riding hero and monster, the safe landing; captures `crusher-rest/ride/top`.

- [x] **Monsters 10% faster** (user, November 1): `ENEMY_SPEED_SCALE` 1.1 → 1.21 for every monster (elites, flyers, chargers and Eclipse ramps scale from it) and `BOSS_SPEED_SCALE` 1.1 for the realm bosses and the Noggin, whose speed came straight from BossBook. Hero speed unchanged. Not bot-measured.

- [x] **Under the island: jump, slam, turrets** (user, November 1). Underneath, jump (and air jumps) lift the hero away from the belly and fall back onto it (`Underside.hop`); a ground slam lands with the usual blast and a shower of dirt. Turrets can be placed there, hanging upside down from the rock, and keep working while the hero is under (hand weapons still rest). Smoke `under_jump`, `under_slam`, `under_turret`; `underside-review` capture `under-turret`.
- [x] **Two turrets that pulse instead of shooting** (user, November 1: "too many similar turrets"). The Ice and Poison Turrets are replaced by the **Mender Turret** (`heal-turret`, green cross; heals the hero standing in its green ring) and the **Thumper Turret** (`pulse-turret`, speaker cone; knocks enemies in its blue ring away and hurts them). Both draw their ring on the ground (`GroundRing`). Turret cards work on them: Stronger turret heals more / pushes and hurts harder, Faster turret pulses more often, Turret reach widens the ring; weapon ranks add power (`TurretPulse`). New models and icons; co-op protocol 19. Integration `mender_heals`, `thumper_pushes`; weapon-review measures the Mender's healing growing with rank (15 → 24 HP in 6 s).
- [x] **Florist: fewer flowers, bigger area** (user, November 1). One flower every 7 m instead of 2.3 m (seed cards add up to two more beside it), at most 14 instead of 48. Each flower is 1.6× bigger and stands in a ring showing its 5 m reach (was 3 m); a bloom blasts the whole ring for twice the damage and heals twice as much, with an ink wave. Integration `flowers_wide`; weapon-review flowers 2,013 → 4,327 damage from rank 1 to 5.

- [x] **A random hero on each visit to the hero screen** (user, November 1), solo and co-op: `game.roll_menu_hero` rolls once per visit (kept while browsing menus or after a manual pick), and again after a run. Automated reviews keep their fixed hero. Integration `random_menu_hero`.
- [x] **Florist's V plants a ring of flowers** (`HeroTricks` kind `garden`): six fully grown flowers in a 6.5 m circle round her, 14 s cooldown (heals instead if she no longer carries Flowers). Integration `hero_tricks`; `underside-review` capture `florist`.
- [x] **Lava burns** (`Lava`, user November 1): Candy Hell lava rivers and lava-vent pools set the hero on fire for 2.5 s with visible flames (particles and a warm light on the hero, any fire source); monsters catch fire, bosses only smoulder (2 + island burn); gold and XP orbs that land or lie in lava burn up (XP only on the host). Integration `lava_hero_fire`, `lava_boss_smoulders`, `lava_burns_drops`; capture `underside-fire`.
- [x] **Ground indicators without edge lines** (user November 1): danger marks are a soft fill that deepens from the middle as the warning runs (white flash at the end); bursts (explosions, slams, heals, pulses) are a spreading, fading colour disc; turret and flower rings and biome zones have no rim. `fx-telegraphs` inspected.

- [x] **Playfeel review green again** (November 2): a stray scatter tree stood in the first grove's walk lane, so scatter trees now keep 24 m clear of the landmark groves; the turret check follows the new readout.
- [x] **Turret readout shows pictures** (November 2): the selected turret's icon with a recharge shade that drains, its deploy key, then the switch key and the next turret's small icon; no turret names and no "SELECTED" label.
- [x] **Script-side crowd mover** (`CrowdMover`, November 2): ordinary monsters with nothing solid within a couple of metres (checked about five times a second, terrain ignored) move along `World.height_at` without `move_and_slide`, and stop at heroes' edges; near trees, walls, lifts, on steep ground, in the air, at the rim, climbing, in the Red Moon arena and for bosses they use physics as before. Integration `crowd_glides`; crowd reviews report `glide_share`.

## Big update (user list, November 2)

Done in this order: quick screen and data fixes first, then hero rework, then new systems. "Witch" = Smoker (purple robe and pointed chimney hat), "Rat" = Tax Rat. Trademarked names stay out of the game: the requested "CS2" hero ships as **Clutch** with its own tactical HUD and sounds.

**A. Screens and text (fast)**
- [x] 1, 6 · Death screen: no best-run line, no QUIT button.
- [x] 2, 5 · Death screen recap: drop "regions / landmarks" (landmark groves give nothing now); revives and rescues become "♥ got back up ×N" and "✚ friends saved ×N", shown only in co-op.
- [x] 3 · Biome pickups: the benefit in plain numbers ("+12 ♥", "+15% damage 20 s") pops over the hero on pickup, shows on the HUD with its icon and time, and floats over the pickup when near.
- [x] 4 · Potions: the same: "+40% speed 25 s" on drinking, short benefit under each buff icon, on approach.
- [x] 7 · Pet picker: stage pips (1–3) under each wisp, and the benefit in numbers ("fetches coins in 8 m", "bites 6 dmg/s", "heals 1 ♥/s") under the row.
- [x] 8 · Hats: picked on the hero screen (◀ hat ▶, worn by the preview), not hidden in Settings; locked hats show how to earn them in the tooltip.
- [x] 15, 24 · Hero screen: drop the filler title line; show the V trick (key glyph, name, one-line effect, cooldown) and three short facts per hero (health, speed, what the perk does in numbers).
- [x] 27 · Particles slider: verify; also scale GPU particle systems (spells, flames, trails), not only shards and puffs.

**B. Roster and numbers (fast)**
- [x] 19 · Remove Roll Ronin, Tank Potato, Sir Loaf, Queen Tea, Bookworm, Chef Cap, Sir Snooze (saved choices fall back; their achievements and hat sources go).
- [x] 22 · Ninja starts with a double jump.
- [x] 23 · Alcoholic: potions last twice as long; kills drop potions a bit more often.
- [x] 26 · Bosses keep up: they run at hero speed (faster when far away) so you cannot outrun and forget them.

**C. Heroes that play differently**
- [x] 11 · White Supra: no jump/slam (and no jump/slam cards), twice normal speed, Space = handbrake drift with tyre squeal, a car-crash sound when hit.
- [x] 12 · Smoker (witch): hovers all the time, which keeps her out of lava and ground effects.
- [x] 18 · Honey Hustler: flies (no jump/slam or their cards); gains XP from map flowers and a little from hero flowers.
- [x] 21 · Admiral Bubbles: starts with the Bubble Gun; no health and no health orb, only a big bubble shield; no health drops for him.
- [x] 20 · Turbo Snail: leaves a lasting slime trail that slows enemies crossing it.
- [x] 17 · Prickle Rick: no arms, legs or weapon; lies there and gets shoved around; thorns build (much more health; tank, poison, thorns and aggro cards). He lies on his side and rolls with momentum when shoved (`HeroPlay.roll`). Marked as a party hero.
- [x] 13 · Tax Rat: runs on all fours with a long tail (no hitbox), jumps like a four-legged animal.
- [x] 16 · Captain Eight: eight tentacles instead of human arms and legs.

**D. New systems**
- [x] 9, 10 · Flowers grow roots under the island; only Digby Mole sees them (green glow) and eats them to heal.
- [x] 25 · Three more pets (Ward +shield, Mote pulls XP, Rime slows nearby enemies); the pet picker gets its own panel on the hero screen and no longer rebuilds with every hero.
- [x] 14 · Wrench: E at a placed turret starts an arrow-key sequence; while he keeps hitting the right arrows, that turret works twice as fast.
- [ ] 29 · Co-op: a downed player spectates the living (free camera) and has a soundboard of about 10 cheers; no Block Drop or shorts while downed.
- [ ] 30 · The shop becomes **Dyleris**: talking to him marks where three items lie under the island; they are free but you must fetch them. Item ideas (three rolled per island): Gravity Anchor (no fall damage, slam from any height), Sun Lantern (night monsters weaker), Root Map (minimap shows chests), Golden Pickaxe (all pots drop coins ×2), Moon Compass (boss revealed on the map), Hourglass (+30 s before each boss), Rain Cloud (lava cools to rock), Echo Bell (every 10th shot repeats), Second Heart (one free revive), Merchant's Ledger (shop prices −30%).

**E. Biggest**
- [ ] 28 · **Clutch**, a first-person tactical shooter hero: no auto-aim (turrets still aim), number keys pick the active weapon, own HUD (health, armour, slots, kill combo), V = short aim lock with 5× damage and a headshot chime, Shift = slow walk that makes enemies lose him for a moment, no slam. Friendly fire on other heroes.

## Next

- [ ] **Human playtest of Build 27:** the flip under the island (feel, camera, flipped controls), the wisps in motion, the calmer audio. Decide whether hiding underneath is too safe (simple fix: a slow health drain while under).
- [ ] **Balance with people.** Bots last measured 75% clear island 1 / 25% reach the final boss / 0% beat it (12 runs, before the October 25 "dangerous, not tanky" change, which is not bot-measured). Target about 70 / 25 / 10. Use 48+ run batches; 24-run batches swing about 20 points.
- [ ] **Creatures still too basic?** If so: thicker limbs and bigger heads on the stick-figure humanoid mutants (`CartoonBook` designs).
- [ ] **Two-machine co-op over the internet** with packet loss; all co-op tests so far run on one PC.

## Open issues and limits

- **Internet hosting on the user's connection:** the provider uses carrier-grade NAT (outside address 10.254.50.76), so no port mapping can work. A friend with a public address hosts, the user asks the provider for a public IP, or the party uses the tunnel. The game reports this case as carrier-grade NAT.
- **Early co-op desync:** never described in detail; open until a matching report or reproduction.
- **Performance:** three rank-9 spells in a 125-enemy crowd now run at about 38 fps (frame p50 about 26 ms, was 60–70 ms) since monsters on open ground glide along the terrain in script (`CrowdMover`, 98% of monster steps) instead of a physics sweep. What is left is spread over the spells, the HUD and engine work; switching to Jolt physics measured a further gain in the plain crowd (physics p95 38 → 15 ms) but needs a full physics review first.
- **Not heard by a person:** generated creature voices, enemy attack sounds, spell sounds, the phonk music and the intro stingers.
- **Known flaky checks** (not loosened): `shared-review` rejoin snapshot count under load, integration `biome_gust` and `spell_hits_trigger_mutations` (once, November 1), smoke `head_stomp`.
- **Remote co-op visuals:** teammates see an evolved weapon's halo but not gilded shots or spell synergy effects.

## Deferred

- **Better hero and creature models** from a hand-directed Blender pipeline. The October 23 pilot (`scripts/blender/pilot.py`, `model-review`) lost to the shipped models; the user chose to keep them.
- **A hosted relay or matchmaking server.** The user chose port opening and tunnels for now (October 22 and 24).

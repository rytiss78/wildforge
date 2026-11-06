# Wildforge — plan

November 2, 2026 · main branch · **Build 31 (1.14.0) is the latest public release** ([build-31](https://github.com/rytiss78/wildforge/releases/tag/build-31), notes [build31-release.md](native/docs/build31-release.md)).

Rules: [AGENTS.md](AGENTS.md) and the [Godot workflow](native/docs/godot-workflow.md). A checked item means the real entry point was exercised and the evidence is recorded. Everything done up to Build 28, with evidence paths, is in git history (the Build 28 plan is `PLAN.md` at tag `build-28`); release notes are on the [GitHub releases page](https://github.com/rytiss78/wildforge/releases).

## The game today

- **Run:** three floating islands of seven biomes each (Junkyard Planet is the seventh). Each island has a 10-minute clock, two wardens and a portal; then the Red Moon arena with the final boss, **The Grand Noggin** (a giant floating head; its glass eyes are its health), then an endless Eclipse.
- **Islands float:** no sea. Walking over the rim flips the hero to walk upside down under the island, out of the fight; enemies, drops and chests stay on top. The Red Moon arena keeps its deadly void.
- **Content:** 20 heroes (seven retired in Build 29, Clutch added), each with a unique trick (V / left trigger); 85 weapons including four spells; weapon evolutions and spell–mutation synergies; a fight mechanic per biome; Dyleris and the dropai under the island; 60 original cartoon creatures built around glass health orbs; elites, hunts, beacons, exploding barrels, a merchant; 93 achievements with hats and cosmetics.
- **Pets:** wisps over the shoulder, chosen with the hero: Glint (fetches), Sting (bites), Halo (heals), Ward (shields), Mote (pulls XP), Rime (slows). Treats drop only from the final boss and are kept between runs (stage 2 after one win, stage 3 after three).
- **Co-op:** up to four players over LAN or the internet (UPnP invite codes, or a tunnel). Drop-in, reconnect with replayed rewards, rescue codes, party combos. Exact build match required; protocol `wildforge-shared-world-20`.
- **Presentation:** 60 fps cap, show-don't-tell HUD (symbols, details in tooltips), own title intro instead of the engine splash, calmer audio with an enemy sound budget, own window and exe icon.
- **Waiting:** Block Drop in the pause menu and co-op waiting overlay, with TikTok or YouTube Shorts beside it.
- **Tooling:** `node scripts/agent-workflow.mjs` (check, smoke, integration, about 50 rendered and two-process reviews, `bot-playtest`, `build`, `test-build`); `scripts/package-release.ps1` packs a release.

## In Build 29: the big update (user list, November 2)

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
- [x] 17 · Prickle Rick: no arms, legs or weapon; lies there and gets shoved around; thorns build (much more health; tank, poison, thorns and aggro cards). Now a curved pickle lying on his side: pushes slide him lengthways and turn him, he only rocks (`HeroPlay.shoved`); Toxic Hug poisons enemies touching him; no weapon cards (`HeroRules.weapon_key`), no weapon HUD.
- [x] 13 · Tax Rat: runs on all fours with a long tail (no hitbox), jumps like a four-legged animal.
- [x] 16 · Captain Eight: eight tentacles instead of human arms and legs.

**D. New systems**
- [x] 9, 10 · Flowers grow roots under the island; only Digby Mole sees them (green glow) and eats them to heal.
- [x] 25 · Three more pets (Ward +shield, Mote pulls XP, Rime slows nearby enemies); the pet picker gets its own panel on the hero screen and no longer rebuilds with every hero.
- [x] 14 · Wrench: E at a placed turret starts an arrow-key sequence; while he keeps hitting the right arrows, that turret works twice as fast.
- [x] 29 · Co-op: a downed player spectates the living (free camera) and has a soundboard of about 10 cheers; no Block Drop or shorts while downed.
- [x] 30 · The shop becomes **Dyleris**: talking to him marks where three items lie under the island; they are free but you must fetch them. Ten dropai (`Dropai.ITEMS`, three rolled per island, never twice a run): Gravity Anchor (no fall damage, slams +50%), Sun Lantern (+8 armour), Golden Pickaxe (double pot coins), Moon Compass (+30% XP), Hourglass (potions +50%), Rain Cloud (lava no longer hurts you), Echo Bell (+15% fire rate), Second Heart (a free revive), Merchant's Ledger (boxes and Dyleris −25%), World Seed (+20% damage, +20 health). Local to each player.

**E. Biggest**
- [x] 28 · **Clutch**, a first-person tactical shooter hero: no auto-aim (turrets still aim), number keys pick the active weapon, own HUD (health, armour, slots, kill combo), V = short aim lock with 5× damage and a headshot chime, Shift = slow walk that makes enemies lose him for a moment, no slam. Friendly fire on other heroes.

## Big update MB (user, November 2)

Megabonk-style structure with this game's own content: Megabonk's own items, books, weapons and heroes are not copied, only the kind of structure (slot limits, stat cards, chest items, climbing maps).

- [x] 1 · **Loadout:** 4 weapon slots (no other weapon appears once full, only ranks and upgrades for those), 4 card slots (24 stat cards of our own, e.g. Might, Haste, Vigor, Stride, levelled by level-ups; once 4 are held only their levels appear), items with no limit from chests. All 747 old cards are kept and sorted (`Loadout.slot_of`): core stats → card levels, single-weapon upgrades → weapon upgrades offered while carrying that weapon, everything conditional / on-hit / on-kill / hero-mechanic / economy → chest items. One mutation per level-up. Minimal HUD: card and weapon tiles centred at the bottom (gun damage numbers rise from the weapon tiles), no dark plates behind vitals, loadout or timer.
- [x] 2 · **One biome per map:** seven six-minute maps in a row (Clover Woods, Puffcap Marsh, Moon Craters, Cloudwilds, Junkyard Planet, Candy Hell, Starfall Space; that biome's ground, plants and creatures only), then the Red Moon. Difficulty climbs over the seven (`RealmWorld.tier`). Each map has its own sky after Destiny 2's worlds (`SkyLook`: a pale pearl, a banded giant, the blue home world, aurora, a black sun, a ringed giant); the corrupted veins are gone.
- [x] 3 · **Climbing maps:** ten mesas per map (`ClimbMap`) reached by a ramp, a spiral of stone pillars or a launch pad, a chest on top of each; 28 more chests at random spots each run, shown on the map only once someone in the party has been near (`chest_seen`). The underside stays; Digby's dig now flies over hell (`HellFlight`, wailing souls and fire).
- [x] 4 · **More content of our own:** Dare (more monsters, more XP and gold) and Wild Card (two random stats a level) cards; chest items have one fixed rarity (plain stats common, effects rare, strong effects epic, game changers legendary, no weak copies of the best), plus 15 new items where Megabonk had ideas we lacked (`Relics`: overcrits, BONK, kill stacks, reflect shell, overheal cushion, wisps, fireworks, slow time...).
- [x] 5 · **Heroes:** each hero's perk grows a step every level (`HeroGrowth`), the body tuning stays.
- [ ] 6 · **Playtest MB:** pacing of six-minute maps and 38 chests, mesa heights, item rarity odds, Dare and the relics' strength; co-op with the new maps (protocol 22).
- **Vitals:** health on top, one even row of shield, armor and evasion chips below.
- **Labyrinths:** Cloudwilds, Moon Craters and Starfall Space are Megabonk-style terraced stages (`Terraces`): 32 m flat plateau tiles on four floors 8 m apart over the whole island, straight earth cliffs with a grass lip between floors, and whole tiles tilted into ramps (a spanning-tree height walk biased to a high ring, as in Megabonk's generator). Junkyard Planet keeps our own flat corridor maze (`Labyrinth`). Monsters walk straight up cliffs and walls, as in Megabonk; heroes take the ramps (or jump/rope).
- **Look and sound (November 3):** cards are drawn as cards and items as objects (`ItemArt`); no map name plates (the narrator names the biome); own music per map (`make-map-music.py`, a little quieter); softer gun; Clutch holds a detailed AK-47 (`AkModel`); Digby's dig is a fall through the burning hollow inside the island.
- **Clutch (November 3):** fully automatic AK-47 (10 rounds/s, 30-round magazine, 2.4 s reload with its own sound; same damage over a full cycle as before), no tracer beams, look speed 0.6, keys 1–4 for the four weapon slots, plate-free HUD that keeps cards, gold, buffs and level visible, gun damage numbers from his weapon list.
- **Weapons (November 5–6):** twelve new attack patterns (halo, pot lids, fire and frost trails, dice, blood pump, whip, snip knife, katana, scythe, hero blade, grudge blade) and distinct ones for the old kinds (flamethrower cone, sky bolts, flasks, homing rockets, mines dropped while walking, a blinking ghost, an instant sniper line) in `WeaponActs`. Every weapon evolves (twelve new forms) and has a tooltip. Gun, shotgun and harpoon shots follow the usual shot rules again (crit, berserk, Multishot, Bouncy, boomerang, payloads, evolved gilding and trails; themed variants keep their extra shots and sizes); shotgun pellets aim at the target instead of sailing over short monsters; a poison weapon's cloud poisons in step with Damage. `weapon-combos` runs every weapon with seven card builds and two builds of real chest items.
- **Achievements (November 3):** a run is now won by felling the Grand Noggin (before, no run could ever count as a win, so every "win" achievement was out of reach). Retired: wins for removed heroes, raised-ruin chests, ruins and edge walks, map tiles, the Florist's automatic flower effects, "no gun". Weapon goals use four slots; the supply beacon and merchant stand on playable ground. Eleven new ones around the Red Moon; the six hardest gift big mustaches (`MustacheBook`, replacing the unfinished hats; hero screen and Settings, seen in co-op).

## Next

- [ ] **Human playtest of Build 29:** Clutch (aim, aimbot, sneak, hands), the pickle being shoved, co-op spectating and cheers, Dyleris and the dropai, the flip under the island. Decide whether hiding underneath is too safe (simple fix: a slow health drain while under).
- [ ] **Balance with people.** Bots last measured 75% clear island 1 / 25% reach the final boss / 0% beat it (12 runs, before the October 25 "dangerous, not tanky" change, which is not bot-measured). Target about 70 / 25 / 10. Use 48+ run batches; 24-run batches swing about 20 points.
- [ ] **Creatures still too basic?** If so: thicker limbs and bigger heads on the stick-figure humanoid mutants (`CartoonBook` designs).
- [ ] **Two-machine co-op over the internet** with packet loss; all co-op tests so far run on one PC.
- [ ] **Co-op playtest of Build 31:** the C rope (pull a downed friend's body down through the island from underneath and rescue them there with the usual code; drag living friends or toss monsters, harmless), wild roots under every island (glowing for everyone, eaten for good by Digby, shared in co-op), a friend's new hero showing in the second run, Block Drop and videos after a Clutch run, spectating as a downed Clutch.

## Open issues and limits

- **Internet hosting on the user's connection:** the provider uses carrier-grade NAT (outside address 10.254.50.76), so no port mapping can work. A friend with a public address hosts, the user asks the provider for a public IP, or the party uses the tunnel. The game reports this case as carrier-grade NAT.
- **Early co-op desync:** never described in detail; open until a matching report or reproduction.
- **Performance:** three rank-9 spells in a 125-enemy crowd now run at about 38 fps (frame p50 about 26 ms, was 60–70 ms) since monsters on open ground glide along the terrain in script (`CrowdMover`, 98% of monster steps) instead of a physics sweep. What is left is spread over the spells, the HUD and engine work; switching to Jolt physics measured a further gain in the plain crowd (physics p95 38 → 15 ms) but needs a full physics review first.
- **Not heard by a person:** generated creature voices, enemy attack sounds, spell sounds, the phonk music and the intro stingers.
- **Known flaky checks** (not loosened): `shared-review` rejoin snapshot count under load, integration `biome_gust` and `spell_hits_trigger_mutations` (once, November 1), `biome_lava` and `mb_labyrinth_seams` (once each, November 6; the seams check uses unseeded `randf`).
- **New weapons not played by a person:** the twelve November 5 patterns and their evolutions are only measured by `weapon-review`/`weapon-combos`; feel, reach and balance are unchecked.
- **Remote co-op visuals:** teammates see an evolved weapon's halo but not gilded shots or spell synergy effects.

## Deferred

- **Better hero and creature models** from a hand-directed Blender pipeline. The October 23 pilot (`scripts/blender/pilot.py`, `model-review`) lost to the shipped models; the user chose to keep them.
- **A hosted relay or matchmaking server.** The user chose port opening and tunnels for now (October 22 and 24).

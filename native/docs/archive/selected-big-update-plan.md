# Wildforge — selected big update implementation plan

Date: 2026-10-05. Status: authorized for implementation in a new chat. Work locally in G:\game. No GitHub push, upload or release. Preserve user saves, source assets and one current playable build.

## Scope and decisions

Approved IDs: V1,V3,V4,V5,V6,V8,V9,V11,V13,V16,V17,V18; G2,G4,G5,G6,G8,G7,G10,G11,G14,G15,G17,G19,G20; F3,F4,F8,F11,F12,F18; I3,I13.

Use big-update-plan.md for the original meanings. This document turns those selections into deliverables and overrides its proposal-only status for these features. Do not implement unselected proposals.

Additional instructions: rebuild enemy movement from scratch with a simple approach; remove Community Lab; prioritize bosses when targeting; rotate the minimap; lower normal enemy spawning while retaining deliberate waves; make ranged non-boss units fragile with long attack cooldowns (wording needs clarification below); merge grounded XP and money drops to reduce clutter and work.

Preserve native Godot, illustrated 3D art, compact opaque PC UI, Xbox controls, positive single-bonus items, three weapon slots, rare paid boxes and timed bosses. Steam remains abandoned. Removing Community Lab does not require Steam and does not affect direct LAN/VPN co-op.

Clarify early in the new chat: the user wrote “Range heroes are very low hp. And have big attack cooldown. Bosses do not follow this rule.” Ask whether this means ranged ordinary enemies or playable heroes. The boss exception suggests enemies, but do not change playable hero HP or attack speed on that assumption. Continue independent work while awaiting the answer.

Carry forward bigger maps and cleaner biome crossings from the prior request. Start with the proposed 1,500 × 1,500 metre target unless the user changes it; mark this as a working assumption, not a previously confirmed dimension.

## Phase 1 — simple movement, spawning and loot foundation

### Fresh enemy movement

Replace the current accumulating steering workarounds. Preserve enemy species, attacks, damage and status systems separately from movement.

- One desired direction toward the selected living player; normal size-based movement speed, gravity and ground collision.
- Use Godot body collision and sliding against scenery; avoid manually moving enemy bodies through each other or the hero.
- One local separation calculation from nearby spatial-grid neighbours, with capped influence so enemies can still reach attack distance.
- If genuinely blocked, choose a consistent short wall-follow direction, reassess periodically and return to pursuit when clear. No stack of ray probes, oscillating side choices or per-enemy full-map path rebuilds.
- Flying units steer in 3D within their intended attack heights; keep ordinary ranged weapons able to reach them.
- Pause freezes movement and cooldowns. Freeze stops movement; blindness and attack cooldowns remain explicit, separate rules.
- Distant irrelevant crowds sleep/despawn safely instead of monopolizing spawn capacity. Avoid disappearing enemies close to players, bosses or active objectives.

Acceptance: enemies approach, slide around representative scenery and attack; no dense persistent stuck gangs, hero penetration or vertical piling during normal movement. Test both solo and separated co-op players. If this simple approach cannot navigate complex geometry, simplify the collision layout first; introduce navigation only with evidence it is necessary.

### Spawn and targeting changes

- Separate ordinary spawn pacing from wave events and bosses. Begin normal spawning at roughly half the current rate, then review first-minute pressure rather than promising an arbitrary final number.
- Waves have explicit start/end, their own budget and a readable cue. Preserve timed boss scheduling.
- Shared target selection prioritizes a living boss only when reachable by that weapon; otherwise choose a reachable ordinary threat. Apply consistently to auto-fire, melee and turrets. Do not target a distant boss through range limits or make melee chase an unreachable flying boss.
- Once clarified, give ordinary ranged enemies lower health and longer telegraphed attack intervals than comparable melee enemies. Bosses use their own values. Maintain visible minimum creature size.

### Grounded loot merging

- XP merges with XP; money merges with money. Preserve the exact sum, identity, achievements and player ownership in co-op. Do not convert one currency into the other.
- Merge only grounded, nearby compatible drops. Keep gravity and avoid pulling drops up cliffs, through scenery or across separate elevations.
- Use spatial buckets and a modest merge cadence rather than all-pairs scans every frame. Bound survivor scale so large piles remain readable and easy to collect.
- Keep the XP glow and gold coin identity. Fewer rendered objects and attraction/physics updates are the intended outcome.

## Phase 2 — map layout and removal of Community Lab

- Centralize world dimensions and edge distances. Update terrain, containment, steam, chests, sky, spawn bounds, landmarks, minimap and co-op data consistently.
- Keep streamed chunks, existing draw-distance limits and bounded nearby simulation. Larger maps must not multiply active enemy counts or instantiate all scenery at once.
- Biome borders: approximately 18–30 metre transition corridors, fewer decorative props, readable crossings and gradual ground colour transitions. Interior landmarks and tall scenery remain.
- V3/G2: terraces, cliffs, valleys, ramps, jumping routes and shortcuts. Guarantee routes that do not require unearned extra jumps; optional upper routes may reward jump builds.
- Minimap rotates with the camera yaw, with the player facing consistently upward. Rotate boxes, party markers and terrain together; retain readable screen-space icons and labels. Preserve box discovery/opened removal and counter rules.
- Remove Community Lab from main/pause menus, runtime routing, feedback/roadmap screens, packaged data and dependent checks. Update public-facing local documentation to remove promises of automatic comment-driven development. Keep historical provenance and user-created feedback files unless explicitly asked to delete them.

## Phase 3 — selected visual overhaul

- V1/V4: small illustrated texture atlases and coherent biome palettes; detailed colourful foregrounds, legible enemies and restrained distant fog. Use the approved icon style, not photorealism.
- V5: add doors, windows, banners, cracks and selective moving details to landmarks without increasing building clutter.
- V6: hero run/turn/stop/jump/land/recoil polish, preserving health-orb visibility and held weapon alignment.
- V8/V9: creature-specific impact particles and illustrated animated explosions. Reuse pooled effects and keep threats visible.
- V11: improve red blood level, damage cracks and transparent blue armour. No black blood and no return of redundant health/armour HUD counters.
- V13: animated vegetation in visible nearby areas, with cheap shader motion rather than per-plant scripts.
- V16: contact shadows that ground actors and pickups without making colours muddy; choose an affordable implementation for the renderer.
- V17: consistent narrow borders, bevels and shadows on compact opaque 1080p UI; verify controller focus and scaling.
- V18: rank milestones change visible weapon parts and textures while preserving weapon identity, socket positions and performance.

First review one representative scene and combat encounter before spreading changes through all biomes. Generate artwork where useful, author actual 3D geometry where required, and record provenance. Do not describe generated images as rigged models.

## Phase 4 — cards, combat and economy

- G5/G6: show upgrade mechanics and before/after values clearly, with simple family tags. Keep each item one positive bonus.
- G7: offer an explicit optional banish action for a selected unwanted bonus for the remainder of the run. Default to one banish charge per realm; label the affected bonus and charge. Banish the bonus key rather than one of many differently named templates. Do not banish already owned power or break full-slot weapon upgrades. Handle exhausted pools safely.
- G8: mildly favour a useful owned-weapon bonus in one offer slot sometimes, retaining random choices in the others and respecting caps, banishes and rerolls. No fixed recipe builds.
- G4: rare wandering merchant, simple coin prices and up to three clearly described positive purchases. Weapon purchases upgrade owned weapons when slots are full. Pause interactions consistently in solo/co-op and keep inventory/charging authoritative.
- G17: melee only selects reachable targets, with visible hand extension and contact. Boss priority still respects melee reach.
- G10: bosses have readable movement phases, fair warnings and recovery windows; tune separately from fragile ranged enemies.
- G11: begin with a small explicit reaction table: fire + poison makes a brief ignited cloud; frost + a slam creates a shatter burst; lightning hitting wet/bubbled enemies chains once. These are proposed implementation defaults within the approved reaction feature. Prevent recursive reaction loops, duplicate network damage and excessive particles. Explain interactions through icons and short text.

## Phase 5 — co-op and optional world events

- G14: downed state and revive interaction; start with a three-second held rescue, interrupted by damage or leaving range. A downed player cannot attack. Solo retains its existing death/revive rules. Replicate state on the host, prevent duplicate revives and handle disconnects and realm transitions.
- G15: one contextual ping action usable on keyboard/controller. Ping treasure, threat or destination, with cooldown and short lifetime. Keep it distinct from camera, jump and modal controls; show the chosen bindings in proper glyphs.
- I13: rare supply beacon discovered through exploration. Activate intentionally; a short defend-the-area event temporarily uses wave spawning, then delivers a choice of positive rewards. Reward once, preserve paid chest economics, and support co-op participants without multiplying claims. Clearly show progress and success/failure. Losing an optional attempt must not subtract already earned items.

## Phase 6 — approved funny elements and reactions

- F3: powerful Florist blooms headbang to musical beats without changing combat timing.
- F4: recognizable mimic reveals itself, panics and flees with a small bonus loot trail. Give clear interaction/payment behaviour; do not consume a paid chest reward without compensation.
- F8: banana-themed single-bonus card briefly slips eligible enemies. Use diminishing/restricted control on bosses; preserve collision and avoid permanent loops.
- F11: illustrated cheese craters and bitten moon rocks, placed as light environmental jokes.
- F12: short coloured potion-burp bubble; throttle it and preserve effect visibility.
- F18: mushroom eyebrows exaggerate the wind-up before charging and help attack readability.
- I3: short, infrequent context-specific hero quips about discoveries, weapons and bosses. Use the existing original synthesized voice pipeline where suitable, with hero-local spatial sound and global/per-hero cooldowns. Do not reintroduce robotic placeholder speech or spam. Announcer remains sky-spatial and biome announcements stay name-only.

## Phase 7 — recap, achievements and balance

- G19: concise run recap for damage, useful powers, exploration, coins/XP and memorable interactions; separate local-player and party totals accurately.
- G20: new discovery/interaction achievements, using illustrated icons and stable save IDs. No repetitive kill-count milestones. Update achievement counts honestly if adding achievements beyond the existing 100.
- After each integrated batch, record implications for survival, first-minute pressure, clearing speed, ranged/melee parity, status control, bosses, XP levels, chest/reroll/merchant income, travel and co-op scaling.
- Record concrete before/after values and unresolved risks. Avoid unrelated nerfs or changing the requested chest formula silently. Preserve the “become OP or die” intent.

## Final build, bug pass and cleanup

Do source-level checks as changes require, not repeated full builds after every edit. Make one final candidate package once all phases are integrated, then perform consolidated checks. Rebuild only if final review finds a change necessary.

Cover keyboard/Xbox focus and bindings, 1080p UI, boss-first targeting, simple pursuit and contact attacks, crowd spacing, all biomes and routes, map containment, rotating minimap/box markers, merge-value conservation, merchant/banish/rerolls, element reactions, supply wave, co-op rescue/pings/disconnects, save migration, recap/achievements, audio throttling and pause. Run one crowded performance sample against the previous baseline, with other diagnostic clients excluded from the timing sample.

Clean unused assets and dead code after checking references, remove temporary outputs, retain editable source/provenance and one current playable build, and keep user saves untouched. Deliver local executable plus change/balance/validation notes. Never push, upload or publish this update unless the user explicitly asks again.

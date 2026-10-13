# Balance and progression — 1.1.0

Quick tuning pass, October 13, 2026. These are starting profiles and controlled checks, not a claim of equal win rates.

## Slam progression

Ground slam and damaging head stomps share recovery. A normal jump stays available. Early head stomps no longer instantly kill ordinary enemies regardless of HP. Both solo and host handling use damage × 2 × slam power. The host separately gates repeated remote stomp packets.

| Rebound recharge bonus | Recovery |
| --- | --- |
| None | 4.50 s |
| +30% (one common Rebound Gear) | 3.46 s |
| +105% (one epic roll) | 2.20 s |
| +350% | 1.00 s |
| +500% cap | 0.75 s |

Formula: `4.5 / (1 + slamRecovery)`. Combine Rebound Gear with Extra Hop, Bounce Pad, Slam Stone, Wide Slam, Slam Heal and elemental slam upgrades. Rarity changes upgrade strength; acquiring recharge requires run progression. The HUD uses the configured slam binding and displays readiness.

## Starting heroes

| Hero | HP | Armour | Height / radius (m) | Speed (m/s) | Jump-height multiplier | Identity |
| --- | ---: | ---: | --- | ---: | ---: | --- |
| Wrench | 100 | 0 | 1.70 / 0.43 | 7.68 | 0.95 | Fix It |
| Count Duck | 100 | 0 | 1.50 / 0.38 | 8.16 | 1.10 | Blood Bank |
| Tank Potato | 140 | 6 | 2.05 / 0.57 | 6.56 | 0.80 | Iron Potato |
| Stone Granny | 100 | 0 | 1.85 / 0.48 | 6.88 | 0.85 | Granny Splash |
| Tax Rat | 100 | 0 | 1.20 / 0.31 | 9.36 | 1.25 | Tax Refund |
| Sir Loaf | 100 | 0 | 1.50 / 0.46 | 8.40 | 1.05 | Bread Rush |
| Florist | 100 | 0 | 1.70 / 0.40 | 8.00 | 1.05 | Flower Power |
| Queen Tea | 100 | 0 | 1.65 / 0.49 | 7.36 | 0.90 | Tea Break |
| Captain Eight | 100 | 0 | 1.85 / 0.53 | 7.52 | 1.15 | Eight Shot |
| Space Cadet | 100 | 0 | 1.80 / 0.42 | 7.68 | 1.35 | Moon Boots |
| Prickle Rick | 100 | 0 | 1.95 / 0.48 | 7.20 | 0.90 | Bad Hug |
| Bookworm | 100 | 0 | 1.35 / 0.36 | 8.56 | 1.20 | Chain Letter |
| Turbo Snail | 100 | 3 | 1.25 / 0.47 | 6.80 | 0.70 | Slime Trail |
| Honey Hustler | 100 | 0 | 1.20 / 0.30 | 9.60 | 1.35 | Honey Money |
| Roll Ronin | 100 | 0 | 1.40 / 0.38 | 8.96 | 1.15 | Sharp Slice |
| Chef Cap | 100 | 0 | 1.60 / 0.47 | 7.84 | 1.10 | Hot Seasoning |
| Sir Snooze | 100 | 0 | 1.75 / 0.44 | 7.60 | 1.00 | Slow Time |
| Disco Scoop | 100 | 0 | 1.90 / 0.39 | 8.24 | 1.20 | Brain Freeze |
| Admiral Bubbles | 100 | 0 | 1.35 / 0.58 | 6.72 | 0.70 | Bubble Bath |
| Fancy Pants | 100 | 0 | 2.00 / 0.48 | 8.64 | 1.15 | Show Off |
| Toastmaster | 100 | 0 | 1.35 / 0.45 | 7.68 | 0.90 | Pop Goes Toast |
| Ninja | 85 | 0 | 1.40 / 0.32 | 9.92 | 1.45 | Afterimage |
| Smoker | 100 | 0 | 2.10 / 0.43 | 7.36 | 0.90 | Secondhand Hex |
| Alcoholic | 130 | 0 | 1.75 / 0.53 | 7.04 | 0.80 | Last Orders |
| White Supra | 100 | 0 | 1.05 / 0.70 | 11.36 | 0.55 | Turbocharged |

Tank Potato trades speed/height clearance for health and armour. Ninja trades health for mobility and dodge. Turbo Snail gains 3 armour to support its slow, poison-focused identity. White Supra has the widest collision footprint and low jumps to offset its speed. Hero effects, selection descriptions, local collisions and remote avatar profiles share the same data.

## Weapons, enemies and rewards

- New class weapon direct damage × rate × added-shot-count multipliers are 1.14 (Ninja), 1.026 (Smoker), 1.05 (Alcoholic) and 1.092 (Supra). This removes accidental double/triple starting projectile damage. These are tuning proxies; piercing, area damage, status and hit coverage still differ. All 44 behavior branches pass integration checks.
- Enemies vary 0.90–1.12× within their species. HP scales with size^1.5 and speed with size^-0.6. Elites are 1.25× larger and move at 90% of their species speed. Distinct biome species retain their own baseline health, size, speed and behavior.
- Ranged enemies use locked ground warnings (at least 1.05 seconds), 24 base damage plus 7 per realm, then enemy/difficulty multipliers. Their health modifier rises from 0.42 to 0.60.
- Loot chooses a mechanic uniformly before choosing its card, preventing large themed card families from drowning out basic upgrades. Added 20 Eclipse and 20 guardian-condition cards plus item/skill Rebound Gear. Total: 738 upgrades and 69 weapons.
- Legendary chance: 1.3% baseline, 5.8% at the capped luck contribution, down from 14.8% at that contribution. A seeded 30,000-roll check measured 1.243% and 6.03%; both are within the stated statistical bounds.
- Potion rolls no longer require owning a Luck item: innate hero luck and Potion Luck work. Bosses guarantee a drop. Elites roll 22% before bonuses; ordinary enemies have a 3% opportunity to make that roll (0.66% baseline overall). Potion-roll chance caps at 75%.

The Red Observatory is 42 m tall and moves at 0.22 m/s. Its four patterns deal 95–120 base damage, with at least 1.6 seconds of ground warning. Shots select range from the giant body surface so short-range weapons remain usable. Its broad silhouette has six skeletal legs, a faceted skull, broken cathedral spires and blade claws.

## Remaining playtest work

The final boss starts at 90,000 HP solo and gains 65% per additional party member. At 300 applied DPS this is five minutes; the actual duration across weak/strong late-game builds still needs player testing. No forced five-minute invulnerability is used. Music taste, encounter pressure and long-run build diversity remain playtest judgments.

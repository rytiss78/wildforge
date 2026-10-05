# Gameplay and code review — 0.7.9

Wildforge should reward becoming absurdly powerful. This review fixes broken bonuses and presentation; it does not introduce a general damage nerf or change the requested chest price table.

## What is already working

- The 21 heroes have distinct perk effect sets. Their perks include thorns, walking income, fire, poison, chain hits, healing, extra shots, armour and airborne damage.
- There are 25 weapons and 332 item/skill templates, covering 99 different bonus keys. Each card grants one bonus. Rarity multiplies its common value by 1, 2, 3.5 or 5.5; integer bonuses and capped stats are adjusted to their actual gain.
- Three weapon slots force a choice. With full slots, weapon offers upgrade owned weapons. The new paid reroll preserves this rule and rerolls upgrade quality.
- Ordinary enemies, elites and bosses grant XP according to their spawn-time health and damage. XP requirements grow from 41 at level 1 to 464 at level 10 and 1,504 at level 20.
- Two timed bosses gate each realm, so exploration and survival have a concrete destination.

## Bugs corrected in this update

- **Range:** targeting used the boosted range, but projectile lifetime and horn reach used the base range. They now agree.
- **Thorns:** contact damage incorrectly multiplied the perk by a single enemy step. It now deals the stated damage at half-second intervals, including for local co-op guests.
- **Large and fast shots:** larger visuals now have a corresponding hit radius; collision follows the travelled segment so a fast shot can hit between frames.
- **Freeze and blind:** frozen or blinded ranged enemies cannot start new spit attacks or charges. Frozen bosses cannot start a new telegraph. Existing attacks retain their visible warning and resolution.
- **Muted weapon loops:** creating a loop after SFX was muted could access a sound that had not been generated. Muted loops now stop or remain absent safely.
- **Input switching:** changing from mouse to Xbox prompts no longer destroys and recreates the selection cards, which could reset focus.
- **Ineffective bonuses:** size, knockback and slowing limits now match their existing combat limits, so cards do not promise gains combat discards.
- **False reward tracking:** a chest no longer records five rewards when it only offers three choices.

## Optimizations

Loot pools are indexed once by kind, family and ID. Rolling cards and showing their common baseline no longer repeatedly filter the full catalog. Icon textures reuse cached atlas regions. Preview panels rebuild only when their selected card changes. New landmark render geometry is batched, while its physical collision shapes remain in the world.

## Recommendations awaiting a separate choice

| Issue | What to consider next |
| --- | --- |
| Late chests can outpace income | The first paid chest costs 30; the 18th costs 3,577. Ordinary forest kills start at 2 coins and reach 6 in realm 3 before item multipliers. Consider realm-scaled income or bonus treasure events while keeping the copied price table. |
| Some bonuses need a particular weapon | Show a short “best with” hint, or weight part of an offer toward owned weapons without eliminating wild combinations. |
| Some starting heroes scale faster | Extra shots and chain hits improve immediate clearing; income and airborne heroes depend more on player behaviour. Compare first-three-minute survival and power growth before changing numbers. |
| Area damage has no simple DPS comparison | A basic gun starts around 24.75 direct DPS; saw around 39.6, shotgun around 28.96 if all pellets connect, and rail around 29.7 before piercing. Poison, fire, bloom and area damage can hit many enemies, so these figures are not rankings. |
| Luck descriptions could be clearer | Treasure rarity uses luck up to +75%; additional luck can still affect potion drops. Make the distinction visible and avoid offering luck after both benefits are saturated. |
| Weapon upgrades hide their practical gain | Add a before/after damage or mechanic preview next to the existing upgrade level. |
| Late builds can permanently control bosses | Preserve the OP fantasy, but consider boss phases that ask the player to move rather than simply increasing health. |
| Rerolls compete with saving for boxes | The first reroll costs max(10, level × 4), doubling within that selection. Track use before adjusting the fee. It resets for the next reward. |

These are source-based findings, not a completed player study. Long runs across all heroes, real co-op latency and player feedback are still needed to establish the best balance.

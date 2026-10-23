# Wildforge 0.7.4 — hero perks and body health

All 21 heroes have distinct primary bonuses, a named perk and a description generated alongside the actual native effects. The selection menu now shows both the mechanic and numeric bonuses. The original roster had overlapping bundles, new heroes had no visible perk explanation, and Florist had an empty effect list. The native roster now uses explicit, positive starting bonuses:

| Hero | Perk | Starting bonus |
| --- | --- | --- |
| Wrench | Fix It | +35% turret damage; heal 2/s near turret |
| Count Duck | Blood Bank | 8% lifesteal |
| Tank Potato | Iron Potato | 6 armour; +40% health |
| Stone Granny | Granny Splash | 45% splash; +25% boss damage |
| Tax Rat | Tax Refund | 20% chest discount; 1% interest per minute |
| Sir Loaf | Bread Rush | Dash blast deals 30 damage |
| Florist | Flower Power | One extra seed; +25% bloom power; +2 bloom healing |
| Queen Tea | Tea Break | Heal 2/s |
| Captain Eight | Eight Shot | One extra shot |
| Space Cadet | Moon Boots | One extra air jump; +25% airborne damage |
| Prickle Rick | Bad Hug | 12 contact thorn damage twice per second |
| Bookworm | Chain Letter | Two extra lightning chain targets |
| Turbo Snail | Slime Trail | +8 poison damage/s on weapon hits |
| Honey Hustler | Honey Money | 0.25 coins/metre; heal 0.5 per coin pickup |
| Roll Ronin | Sharp Slice | +20% critical chance |
| Chef Cap | Hot Seasoning | +8 fire damage/s on weapon hits |
| Sir Snooze | Slow Time | +30% slow on weapon hits |
| Disco Scoop | Brain Freeze | +20% freeze chance |
| Admiral Bubbles | Bubble Bath | 25 rechargeable shield |
| Fancy Pants | Show Off | +25% luck; heal 12 on chest opening |
| Toastmaster | Pop Goes Toast | Defeated enemies explode for 12 damage |

Combat fixes make critical hits and on-hit cards work with the Saw, and extra projectiles work with the shotgun. Starting shield is now filled at run start, so Admiral Bubbles immediately has its perk. Existing weapon-specific effects still combine with these bonuses.

The editable mesh generator cuts a genuine opening through each hero's body, interpolating UVs and normals at the cut. A single large blood orb sits in that opening and remains visible from front and rear. Character faces, silhouettes, joints, clothing and held-weapon sockets are retained. These are original 3D models, using the established illustrated textures.

The red liquid drains and refills with health. A separate transparent blue glass shell leaves the liquid visible: armour contributes a permanent blue tint based on damage reduction; rechargeable shield adds a blue layer that drains vertically as shield is spent and returns when it recharges. It disappears when neither protection exists. Selection previews show starting protection. Co-op poses carry shield state for remote coatings; protocol is `wildforge-0.7.4-1`.

The HUD no longer contains health numbers, the small blood gauge, the health bar or shield bar. It retains hero name, level and XP in a compact panel.

Script compilation and packaging succeeded. A focused packaged rendered check passed all 12 checks: starting shield, 21 valid bonuses, distinct primary perks, 21 large orbs, health fill, shield fill, no unprotected coating, armour coating, removed HUD gauges, melee critical hits, on-hit effects and shotgun extra shot. Front/rear roster renders and the selection menu were visually inspected. Only that focused check was rerun after the shotgun fix; no full multiplayer or stress suite was repeated. Log: `hero-0.7.4.log`. Captures: `user://heroes-front-0.7.4.png`, `user://heroes-back-0.7.4.png`, `user://hero-menu-0.7.4.png`.

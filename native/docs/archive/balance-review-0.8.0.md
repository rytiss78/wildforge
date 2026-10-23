# Balance review — 0.8.0

The intent remains “become OP or die.” These are implementation values and short diagnostic observations, not a claim of full-run balance tuning.

| System | Change | Implication |
| --- | --- | --- |
| Ordinary pressure | Spawn cadence halved; initial nine-enemy ring retained | More travel space and fewer incidental kills; XP/coin income may fall between waves. |
| Ordinary ranged enemies | HP ×0.42; attack cooldown 4.5 → 8 s | Fragile targets with wider attack gaps. This does not nerf playable ranged heroes or bosses. |
| Deliberate encounters | Timed bosses retained; wave/beacon budget 180 + realm ×60 | Pressure stays deliberate rather than compensating with ambient crowds. Review late-realm budgets in longer runs. |
| Boss movement | Eight-second pursuit/reposition cycle; 1.3 s post-telegraph recovery | Adds punish windows. Target priority requires range and visibility; melee cannot select unreachable flyers. |
| Map | Approximately 1,000 → 1,500 m per side; shared spawn bound 720 m, danger edge 725 m | Area grows 2.25× while chunk/nearby simulation remains bounded. Timed bosses and scarce boxes can make long travel costly. |
| Crossings | 24 m corridor, roughly one-third decoration; terrain ramps | Traversal remains possible without extra jumps. Upper routes can still reward mobility. |
| Paid boxes | Existing count/price formula and three-slot rules retained | Boxes are not multiplied by map area. Longer time between discoveries needs career play feedback. |
| Merchant | Three offers once per player/realm; prices 35/45/55 + realm ×15 | Adds a coin sink. Full-slot weapons upgrade an owned weapon; each bonus purchase remains one positive effect. |
| Banish/offer bias | One banish charge per realm, key excluded for rest of run; 30% chance of useful candidate in one slot | Improves agency without fixed recipes. Caps, bans, rerolls and exhausted pools are respected. |
| Loot merge | 0.25 s cadence, 2 m buckets, 1.5 m merge radius, ≤0.25 m height difference, scenery check | Exact XP/gold and original coin-healing counts survive; lower clutter does not reduce rewards. |
| Ignited cloud | Fire + poison: 1.5 s, 8 DPS, 2 m radius | Small area bonus; reaction damage cannot trigger another reaction. |
| Shatter | Frozen target + slam: 40% hit damage within 3 m | Adds melee payoff for freeze. |
| Wet chain | Lightning + bubbled target: one 50% hit within 8 m | Adds controlled lightning synergy. Reactions share a three-second per-target cooldown. |
| Banana | 0.8 s ordinary slip; 0.2 s boss slip; two-second rearm | Boss control is brief and cannot lock permanently. |
| Supply beacon | Defend 25 s within 14 m; fail after 6 s absent; one choice per living participant | Optional exploration reward without taking paid-box rewards or removing earned items on failure. |
| Co-op rescue | Hold 3 s within 3 m; damage/range interruption; revive 40% HP and 3 s protection | Vulnerable rescue without simultaneous-helper acceleration or duplicate revival. Downed players cannot attack, collect loot or open level offers. |
| Pings/voices | Ping 2 s cooldown/8 s life; quip 45 s global/90 s context cooldown | Coordinates co-op and adds personality without constant sound or markers. |

The first-minute ring and half-rate ambient cadence were retained after the integrated encounter checks. No compensating changes were made to XP requirements, chest prices, hero health, basic attack damage or timed boss scheduling. The short checks cover mechanics; sustained solo/co-op runs remain necessary to judge level rate, merchant affordability, late-realm control chains and long-map discovery pacing.

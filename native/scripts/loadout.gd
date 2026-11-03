extends RefCounted
class_name Loadout

# Big update MB, part 1 (user, November 2): what a hero carries.
#
#   Weapons  4 slots. The starter takes one; level-ups offer new weapons only
#            while a slot is free. Once full, no other weapon appears: level-ups
#            rank up the four you have, plus upgrades for those weapons.
#   Cards    4 slots of stat cards. A card is one core stat that grows a level
#            at a time. Level-ups offer new cards while a slot is free, then
#            only levels of the four you hold.
#   Items    everything else, found in chests (and from Dyleris, the merchant
#            and supply beacons), with no limit.
#
# Which boost is a card and which an item (the user asked to think this
# through): a card is a stat that is always useful, grows evenly with every
# level and defines what kind of hero this run makes, so choosing four of them
# is a real decision. An item is a boost that is conditional (while airborne,
# after a dash, at low health), an effect on hit or on kill (fire, poison,
# chain, explosions), a hero-specific mechanic (slam, jump, flowers, potions),
# economy, or a one-off (an extra life): fun to stumble on in a chest, and too
# narrow to spend one of only four slots on. Upgrades that only touch one
# weapon (boomerang power, turret range, extra meteors) belong to that weapon
# and come with level-ups only while you carry it. Every old card is kept:
# its effect is now a card level, a weapon upgrade or an item.

const WEAPON_SLOTS=4
const CARD_SLOTS=4

# Card per level at common rarity; rarer offers give bigger levels
# (RunRules.roll strength). Names are this game's own.
const CARDS={
	"damage":{"name":"Might","amount":.1,"mode":"multiply","family":"Precision"},
	"rate":{"name":"Haste","amount":.1,"mode":"multiply","family":"Ballistics"},
	"crit":{"name":"Keen Eye","amount":.08,"mode":"add","family":"Precision"},
	"critPower":{"name":"Heavy Hand","amount":.25,"mode":"add","family":"Precision"},
	"size":{"name":"Bulk","amount":.1,"mode":"multiply","family":"Arcane"},
	"range":{"name":"Long Reach","amount":.12,"mode":"multiply","family":"Ballistics"},
	"projectileSpeed":{"name":"Swift Shot","amount":.12,"mode":"multiply","family":"Ballistics"},
	"multishot":{"name":"Echo","amount":1,"mode":"add","family":"Ballistics"},
	"knockback":{"name":"Shove","amount":.6,"mode":"add","family":"Defense"},
	"maxHp":{"name":"Vigor","amount":.1,"mode":"multiply","family":"Defense"},
	"armor":{"name":"Plating","amount":2,"mode":"add","family":"Defense"},
	"dodge":{"name":"Slippery","amount":.05,"mode":"add","family":"Mobility"},
	"regen":{"name":"Mending","amount":.7,"mode":"add","family":"Recovery"},
	"shield":{"name":"Bubble Guard","amount":25,"mode":"add","family":"Defense"},
	"lifesteal":{"name":"Leech","amount":.025,"mode":"add","family":"Vampiric"},
	"thorns":{"name":"Bramble","amount":7,"mode":"add","family":"Nature"},
	"speed":{"name":"Stride","amount":.12,"mode":"multiply","family":"Mobility"},
	"jumpHeight":{"name":"Spring","amount":.2,"mode":"multiply","family":"Mobility"},
	"dashCooldown":{"name":"Quick Step","amount":-.12,"mode":"multiply","family":"Mobility"},
	"pickup":{"name":"Magnet","amount":.12,"mode":"multiply","family":"Scavenging"},
	"xpGain":{"name":"Scholar","amount":.2,"mode":"multiply","family":"Arcane"},
	"luck":{"name":"Clover","amount":.14,"mode":"add","family":"Fortune"},
	"goldGain":{"name":"Coin Sense","amount":.3,"mode":"multiply","family":"Economy"},
	"turretDamage":{"name":"Workshop","amount":.2,"mode":"multiply","family":"Engineering"},
}

# Where an old loot entry goes now: "card", "weapon_up" or "item".
static func slot_of(item: Dictionary,augments: Dictionary) -> String:
	var key=str(item.effects[0].key)
	if augments.has(key) or key.begins_with("mut:"): return "item"
	if CARDS.has(key): return "card"
	if weapon_specific(key): return "weapon_up"
	return "item"

static func weapon_specific(key: String) -> bool:
	if key in UpgradeFit.SHOTS or key in UpgradeFit.ON_HIT or key in ["damage","rate","range","airDamage"]: return false
	return UpgradeFit.weapon_key(key)

static func card_offer(stat: String,tier: int,level: int) -> Dictionary:
	var card=CARDS[stat];var strength=[1.0,2.0,3.5,5.5][tier]
	var amount=float(card.amount)*strength
	if stat=="multishot": amount=1.0 if tier<3 else 2.0
	return {"id":"card-"+stat,"kind":"card","stat":stat,"name":card.name,"title":card.name,"family":card.family,
		"tier":tier,"strength":strength,"level":level+1,"effects":[{"key":stat,"amount":amount,"mode":card.mode}]}

# Hand weapons and turrets share the four weapon slots.
static func weapons_full(equipped: Array) -> bool: return equipped.size()>=WEAPON_SLOTS
static func cards_full(cards: Dictionary) -> bool: return cards.size()>=CARD_SLOTS

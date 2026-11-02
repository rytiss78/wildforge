extends RefCounted
class_name HeroRules

# Heroes that break the usual rules (user list, November 2). Gameplay, the hero
# screen and the card pool all ask here instead of checking hero ids inline.
#   White Supra  drives: no jump or slam; Space is a handbrake drift
#   Honey Hustler flies: no jump or slam; hovers over the ground
#   Prickle Rick  lies there: no jump, slam or weapon; enemies shove him around
#   Smoker        the witch: hovers all the time (lava and ground effects miss her)
#   Admiral Bubbles has no health, only a bubble shield
const NO_JUMP=["white-supra","bee","cactus"]
const FLYERS=["bee"]
const HOVERERS=["smoker","bee"]
const SHIELD_ONLY=["bathtub"]
const NO_WEAPON=["cactus"]
# Cards that would do nothing for a hero.
const JUMP_KEYS=["jumpHeight","airJumps","fallGuard","slamPower","slamRadius","bounceJump"]

static func hero_id(item) -> String:
	return str(item.get("id","")) if item is Dictionary else str(item)

static func can_jump(item) -> bool: return not NO_JUMP.has(hero_id(item))
static func can_slam(item) -> bool: return not NO_JUMP.has(hero_id(item))
static func flies(item) -> bool: return FLYERS.has(hero_id(item))
static func hovers(item) -> bool: return HOVERERS.has(hero_id(item))
static func no_health(item) -> bool: return SHIELD_ONLY.has(hero_id(item))
static func armed(item) -> bool: return not NO_WEAPON.has(hero_id(item))

# How a hero that cannot jump gets about (hero screen).
static func mover(item) -> String:
	match hero_id(item):
		"white-supra": return "drifts on Space"
		"bee": return "flies"
		"cactus": return "gets shoved about"
	return ""

# A card the hero can use at all.
static func card_fits(item,card: Dictionary) -> bool:
	if card.get("effects",[]).is_empty(): return true
	var key=str(card.effects[0].get("key",""))
	if not can_jump(item) and JUMP_KEYS.has(key): return false
	if no_health(item) and key in ["maxHp","regen","lifesteal"]: return false
	return true

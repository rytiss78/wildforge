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
const NO_SLAM=["clutch"]  # Clutch jumps but never slams
const SLAM_KEYS=["slamPower","slamRadius"]
# Cards that would do nothing for a hero.
const JUMP_KEYS=["jumpHeight","airJumps","fallGuard","slamPower","slamRadius","bounceJump"]

# Card keys that only matter with a weapon or turret in hand.
const WEAPON_STATS=["rate","multishot","pierce","projectileSpeed","ricochet","boomerang","boomerangPierce","discBounces","range","size","bombSize","gravitySize","harpoonPull","hornStun","meteorCount","bubbleTime","splash","chain","crit","critPower","execute","knockback","turretDamage","turretRange","turretRate","burn","freeze","slow","explosion","stun","blind"]
const NOT_WEAPON_POWER=["slamPower","keyPower","potionPower","flowerPower"]

# Is this card key (augments included: "augment-<when>-<stat>") weapon-only?
static func weapon_key(key: String) -> bool:
	if key.begins_with("augment-"):
		var parts=key.split("-")
		if parts.size()>=3 and parts[1] in ["turret","flower"]: return true
		key=parts[parts.size()-1]
	if key.ends_with("Power") and not NOT_WEAPON_POWER.has(key): return true
	return WEAPON_STATS.has(key)

static func hero_id(item) -> String:
	return str(item.get("id","")) if item is Dictionary else str(item)

static func can_jump(item) -> bool: return not NO_JUMP.has(hero_id(item))
static func can_slam(item) -> bool: return not NO_JUMP.has(hero_id(item)) and not NO_SLAM.has(hero_id(item))
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
	if not can_slam(item) and SLAM_KEYS.has(key): return false
	if no_health(item) and key in ["maxHp","regen","lifesteal"]: return false
	if not armed(item) and weapon_key(key): return false
	return true

# Prickle Rick lies on his side wherever his model is shown (run, hero screen,
# friends' screens): the standing pickle is turned onto its side, curve up.
const LYING=["cactus"]
static func lies(item) -> bool: return LYING.has(hero_id(item))
static func lie(rig: Node,item):
	if not is_instance_valid(rig): return
	var model=rig.find_child("CartoonModel",true,false)
	if model==null: return
	if lies(item): model.rotation=Vector3(0,0,PI*.5);model.position=Vector3(.8,.2,0)
	else: model.rotation=Vector3.ZERO;model.position=Vector3.ZERO

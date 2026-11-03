extends RefCounted
class_name HeroGrowth

# Big update MB, part 5 (user, November 2: "review Megabonk heroes and their
# specials"). There every hero's passive gets stronger as the hero levels up,
# so a hero's identity grows through the run instead of being a fixed bonus.
# Here a hero's own perk (the positive effects in its catalog entry, not the
# body's move and jump tuning) grows a step every level:
#   amounts      +6% of the starting amount per level
#   percentages  (multiply perks) the same, but at most +3% a level
#   whole things (an extra shot, air jump, flower seed) +1 every few levels
# It is level-driven, so co-op members (who mirror the host's level) grow too.

const STEP=.06
const STEP_CAP=.03
const WHOLE={"multishot":10,"airJumps":10,"flowerSeeds":8}
const BODY=["speed","jumpHeight"]

static func perk(hero: Dictionary) -> Array:
	return hero.get("effects",[]).filter(func(e):return float(e.amount)>0 and not BODY.has(str(e.key)))

# What reaching this level adds.
static func step(hero: Dictionary,level: int) -> Array:
	var result=[]
	for effect in perk(hero):
		var key=str(effect.key)
		if WHOLE.has(key):
			if level%int(WHOLE[key])==0: result.append({"key":key,"amount":1,"mode":"add"})
		elif effect.get("mode","add")=="multiply": result.append({"key":key,"amount":minf(float(effect.amount)*STEP,STEP_CAP),"mode":"multiply"})
		else: result.append({"key":key,"amount":float(effect.amount)*STEP,"mode":"add"})
	return result

# Called every frame: apply every level gained since the last call.
static func sync(g):
	while int(g.hero_growth)<int(g.level):
		g.hero_growth=int(g.hero_growth)+1
		var max_hp=float(g.stats.maxHp)
		g.rules.apply_effects(g.stats,step(g.hero,int(g.hero_growth)))
		if g.stats.maxHp>max_hp: g.hp=minf(g.stats.maxHp,g.hp+g.stats.maxHp-max_hp)

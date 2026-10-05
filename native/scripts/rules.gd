extends RefCounted
class_name RunRules

const WEAPON_CAP = 3
const RARITIES = ["Common", "Rare", "Epic", "Legendary"]
const COLORS = [Color("93b6a1"), Color("54b7ef"), Color("b17bea"), Color("ffd36b")]
var data: Dictionary
var rng = RandomNumberGenerator.new()
var loot_pools={}
var loot_by_id={}

func _init():
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	for item in data.loot:
		loot_by_id[item.id]=item
		if not loot_pools.has(item.kind): loot_pools[item.kind]={}
		if not loot_pools[item.kind].has(item.family): loot_pools[item.kind][item.family]=[]
		loot_pools[item.kind][item.family].append(item)
	rng.randomize()

func chest_price(paid: int, discount: float = 0.0) -> int:
	return maxi(1, int(ceil(data.chestPrices[mini(paid, 79)] * (1.0 - clampf(discount, 0.0, 0.6)))))

func free_chance(power: float) -> float:
	return clampf(power,0,.75)

func next_xp(level: int) -> int:
	return 24 + level * 14 + level * level * 3

func can_weapon(equipped: Array, id: String) -> bool:
	return equipped.any(func(w): return w.id == id) or equipped.size() < WEAPON_CAP

func rarity(luck: float) -> int:
	var chance = rng.randf() + minf(luck, 0.75) * 0.18
	return 3 if chance > 0.987 else 2 if chance > 0.91 else 1 if chance > 0.66 else 0

func roll(kind: String, luck: float = 0.0, minimum: int = 0) -> Dictionary:
	var tier = maxi(minimum, rarity(luck))
	var strength = [1.0, 2.0, 3.5, 5.5][tier]
	if kind == "weapon":
		var result: Dictionary = data.weapons[rng.randi_range(0, data.weapons.size() - 1)].duplicate(true)
		result.kind = "weapon"
		result.tier = tier
		result.strength = strength
		return result
	var families = loot_pools[kind].keys()
	var family = families[rng.randi_range(0, families.size() - 1)]
	var pool: Array = loot_pools[kind][family]
	var result: Dictionary = pool[rng.randi_range(0, pool.size() - 1)].duplicate(true)
	result.effects=[result.effects[0].duplicate()]
	for effect in result.effects:
		effect.amount *= strength
		if effect.key=="airJumps": effect.amount=1
		elif effect.key in ["flowerSeeds","revive","multishot","pierce","chain","ricochet","discBounces","boomerangPierce","meteorCount"]: effect.amount=maxi(1,roundi(effect.amount))
	if result.effects[0].key=="airJumps":
		if minimum>0: return roll(kind,luck,minimum)
		tier=0;strength=1.0
	result.tier = tier
	result.strength = strength
	result.name = data.labels.get(result.effects[0].key, result.name)
	if result.family in ["Economy","Mobility"]: result.name = result.title
	return result

func offers(kind: String, luck: float, elite: bool = false, current_stats: Dictionary = {}, equipped: Array = [],excluded_ids: Array=[]) -> Array:
	var result = []
	if kind=="weapon" and equipped.size()>=WEAPON_CAP:
		var eligible=data.weapons.filter(func(w): return equipped.any(func(owned): return owned.id==w.id))
		eligible.shuffle()
		for weapon in eligible:
			var item=weapon.duplicate(true);item.kind="weapon";item.tier=maxi(1 if elite else 0,rarity(luck));item.strength=[1.0,2.0,3.5,5.5][item.tier]
			result.append(item)
		return result
	var attempts = 0
	while result.size() < 3:
		var item = roll(kind, luck, 1 if elite else 0)
		attempts += 1
		if attempts<80 and excluded_ids.has(item.id): continue
		if item.kind!="weapon" and not current_stats.is_empty():
			var candidate=current_stats.duplicate(true)
			apply_effects(candidate,item.effects)
			var effect=item.effects[0];var key=effect.key
			if is_equal_approx(candidate[key],current_stats[key]):
				if attempts<800: continue
				item=roll("weapon",luck,1 if elite else 0)
				if equipped.size()>=WEAPON_CAP:
					item=offers("weapon",luck,elite,{},equipped)[result.size()%equipped.size()]
			else:
				effect.amount=(candidate[key]/current_stats[key]-1) if effect.get("mode","add")=="multiply" and current_stats[key]!=0 else candidate[key]-current_stats[key]
		if attempts < 80 and result.any(func(a): return a.id == item.id or a.name == item.name): continue
		result.append(item)
	return result

func apply_effects(stats: Dictionary, effects: Array):
	for effect in effects:
		var key: String = effect.key
		if not stats.has(key): continue
		if effect.get("mode", "add") == "multiply": stats[key] *= 1.0 + effect.amount
		else: stats[key] += effect.amount
	var caps = {"airJumps":8,"keyPower":.75,"fallGuard":.95,"jumpHeight":5,"slamRadius":4,"bounceJump":2,"flowerSeeds":2,"flowerRoots":0.7,"rate":18,"speed":18,"maxHp":5000,"damage":3000,"dodge":0.65,"lifesteal":0.4,"crit":0.85,"freeze":0.65,"blind":0.65,"discount":0.6,"multishot":7,"chain":8,"pierce":12,"turretCount":1,"drones":3,"interest":0.08,"ghost":2.0,"pickup":20,"coinRadius":22,"regen":40,"revive":4}
	caps.merge({"discBounces":8,"boomerangPierce":12,"harpoonPull":3,"gravitySize":4,"hornStun":3,"bubbleTime":4,"meteorCount":5,"bombSize":4,"airDamage":3,"landingHeal":50,"slamHeal":50,"airControl":.5,"fallThreshold":20,"potionDuration":4,"potionPower":3,"potionChance":.6,"jumpShield":100,"jumpBlast":200,"slamFire":100,"slamPoison":100,"coinHeal":20,"chestHeal":200})
	# Match the limits already used by combat instead of offering ineffective cards.
	caps.merge({"size":2.5,"knockback":3,"slow":.7})
	for id in ["boomerang","disc","harpoon","gravity","horn","bubble","meteor","bomb"]: caps[id+"Power"]=20
	for key in caps:
		if stats.has(key): stats[key] = minf(stats[key], caps[key])
	stats.dashCooldown = maxf(0.6, stats.dashCooldown)
	stats.chestBonus = minf(stats.chestBonus, 0.75)

func describe(effect: Dictionary) -> String:
	var phrases = {"flowerPower":"Bigger flower blooms", "flowerRoots":"Roots slow enemies", "flowerPollen":"Poison pollen", "flowerHeal":"Blooms heal you", "flowerSeeds":"Plant extra flowers","damage":"Hit harder", "rate":"Attack faster", "speed":"Move faster", "maxHp":"More health", "armor":"Take less damage", "regen":"Health grows back", "lifesteal":"Hits heal you", "poison":"Poison on hit", "burn":"Fire on hit", "thorns":"Hurt enemies that touch you", "freeze":"Freeze enemies", "blind":"Blind enemies", "ghost":"Dash through danger", "burrow":"Dash underground, then explode", "shield":"A shield that grows back", "goldGain":"More coins from enemies", "discount":"Cheaper chests", "keyPower":"Chance to open chests free", "walkGold":"Walking makes coins", "hurtGold":"Being hit gives coins", "interest":"Saved coins grow each minute", "coinRadius":"Pull coins from farther away", "potGold":"More coins from pots", "drones":"Flying helpers attack", "orbitDamage":"Orbiting blades", "auraDamage":"Hurt nearby enemies", "storm":"Call lightning", "nova":"Send out a blast", "pools":"Leave poison pools", "boomerang":"Shots come back", "ricochet":"Shots bounce", "multishot":"More shots", "crit":"More critical hits", "critPower":"Bigger critical hits", "pierce":"Shots go through enemies", "chain":"Lightning jumps", "splash":"Hits explode", "explosion":"Kills explode", "dashBlast":"Dash makes a blast", "dashCooldown":"Dash more often", "revive":"Another life", "luck":"Better treasure", "chestBonus":"Better treasure", "salvage":"Kills heal you", "turretCount":"Stronger turret", "turretDamage":"Stronger turret", "turretRate":"Faster turret", "turretRange":"Turret reaches farther", "turretLife":"Turret stays longer", "repair":"Heal near your turret", "berserk":"Hit harder at low health", "xpGain":"Learn faster", "pickup":"Pull XP closer", "range":"Reach farther", "projectileSpeed":"Faster shots", "size":"Bigger shots", "knockback":"Push enemies back", "slow":"Slow enemies", "execute":"Finish weak enemies", "bossDamage":"Hurt bosses more", "stun":"Stun enemies", "magnetPulse":"Pull in XP"}
	var name=phrases.get(effect.key, data.labels.get(effect.key,"More power"))
	var extra={"discBounces":"Disc bounces","boomerangPierce":"Blade piercing","harpoonPull":"Hook pull","gravitySize":"Gravity radius","hornStun":"Horn stun","bubbleTime":"Bubble time","meteorCount":"Extra meteors","bombSize":"Bomb radius","airDamage":"Damage while airborne","landingHeal":"Heal on landing","slamHeal":"Heal on slam","airControl":"Air movement","fallThreshold":"Safe fall height","potionDuration":"Potion time","potionPower":"Potion strength","potionChance":"Potion drop chance","jumpShield":"Shield on jump","jumpBlast":"Jump blast damage","slamFire":"Fire on slam","slamPoison":"Poison on slam","coinHeal":"Heal per coin pickup","chestHeal":"Heal on opening a chest"}
	if extra.has(effect.key): name=extra[effect.key]
	var amount=float(effect.amount)
	if effect.key in ["harpoonPull","fallThreshold"]: return name+" +%s m" % snappedf(amount,.01)
	if effect.key=="hornStun": return name+" +%s s" % snappedf(amount,.01)
	if effect.key in ["airDamage","airControl","potionChance"]: return name+" +%s%%" % snappedf(amount*100,.01)
	if effect.key=="dashCooldown": return "Dash cooldown −%s s" % snappedf(absf(amount),.01)
	if effect.key in ["jumpHeight","airJumps","fallGuard","slamPower","slamRadius","bounceJump"]:
		name={"jumpHeight":"Jump height","airJumps":"Extra air jumps","fallGuard":"Fall damage reduction","slamPower":"Slam damage","slamRadius":"Slam radius","bounceJump":"Landing jump boost"}[effect.key]
	var percent=effect.get("mode","add")=="multiply" or effect.key in ["crit","dodge","lifesteal","discount","freeze","blind","slow","stun","execute","salvage","fallGuard","bounceJump","interest","chestBonus"]
	if effect.key=="keyPower": return "Free chest chance +%s%%" % snappedf(amount*100,.01)
	if effect.key=="ghost": return "Ghost dash +%s s" % snappedf(amount,.01)
	return name+" +"+str(snappedf(amount*100 if percent else amount,.01))+("%" if percent else "")

extends RefCounted
class_name RunRules

const WEAPON_CAP = Loadout.WEAPON_SLOTS
const OFFER_COUNT = 5
const RARITIES = ["Common", "Rare", "Epic", "Legendary"]
const COLORS = [Color("93b6a1"), Color("54b7ef"), Color("b17bea"), Color("ffd36b")]
var data: Dictionary
var rng = RandomNumberGenerator.new()
var loot_pools={}
var loot_by_id={}
var mechanic_pools={}
var banished=[]
# Chest items by their fixed rarity (big update MB, user November 3): like
# Megabonk, an item has ONE rarity. Plain stat boosts are common, effects are
# rare, strong effects epic, game changers legendary; a chest rolls the
# rarity first and then an item of exactly that rarity, so the best items
# never show up as weak common copies. tier -> mechanic -> items.
var item_tiers={0:{},1:{},2:{},3:{}}
const ITEM_RARE=["poison","burn","freeze","stun","chain","splash","pierce","ricochet","bossDamage","walkGold","hurtGold","chestBonus","jumpShield",
	"dashBlast","jumpBlast","slamFire","slamPoison","slamHeal","slamPower","potionChance","potionPower","flowerPower","flowerRoots","auraDamage",
	"burrow","pools","enemyPull","enemyPush","coinHeal","chestHeal","salvage","interest","discount","airDamage","blind","slow"]
const ITEM_EPIC=["explosion","berserk","ghost","nova","storm","execute","airJumps","flowerSeeds","riftDash","magnetPulse","drones"]
const ITEM_LEGENDARY=["revive"]
# How much stronger than its catalog amount an item of each rarity is.
const ITEM_STRENGTH=[1.5,2.0,2.5,3.0]
const WHOLE_KEYS=["airJumps","flowerSeeds","revive","multishot","pierce","chain","ricochet","discBounces","boomerangPierce","meteorCount"]

static func item_tier(item: Dictionary,augments: Dictionary) -> int:
	if item.has("rarity"): return int(item.rarity)
	var key=str(item.effects[0].key)
	if augments.has(key): return 0
	if key in ITEM_LEGENDARY: return 3
	if key in ITEM_EPIC: return 2
	if key in ITEM_RARE: return 1
	return 0
# Prickle Rick carries no weapon: weapon cards leave his pool (HeroPlay.start).
var no_weapons=false

func _init():
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
	# Stats only cards and chest items of the big update MB use.
	data.stats.merge({"curse":0.0,"chaos":0.0,"duration":1.0});data.stats.merge(Relics.defaults())
	# Big update MB: every loot entry is now a card level, a weapon upgrade or a
	# chest item (Loadout.slot_of). Cards are rolled from Loadout.CARDS, so the
	# pools hold items ("item") and weapon upgrades ("weapon_up").
	for item in data.loot:
		loot_by_id[item.id]=item
		item.slot=Loadout.slot_of(item,data.augments)
		if not loot_pools.has(item.kind): loot_pools[item.kind]={}
		if not loot_pools[item.kind].has(item.family): loot_pools[item.kind][item.family]=[]
		loot_pools[item.kind][item.family].append(item)
		if item.slot=="card": continue
		var key=str(item.effects[0].key)
		var mechanic=str(data.augments[key].stat) if data.augments.has(key) else key
		if not mechanic_pools.has(item.slot): mechanic_pools[item.slot]={}
		if not mechanic_pools[item.slot].has(mechanic): mechanic_pools[item.slot][mechanic]=[]
		mechanic_pools[item.slot][mechanic].append(item)
		if item.slot=="item": add_item_tier(item,mechanic)
	# Items with no counterpart before (Relics): each in one rarity only.
	for relic in Relics.entries():
		loot_by_id[relic.id]=relic;add_item_tier(relic,str(relic.effects[0].key))
	rng.randomize()

func add_item_tier(item: Dictionary,mechanic: String):
	item.rarity=item_tier(item,data.augments)
	var pool: Dictionary=item_tiers[int(item.rarity)]
	if not pool.has(mechanic): pool[mechanic]=[]
	pool[mechanic].append(item)

func chest_price(paid: int, discount: float = 0.0) -> int:
	return maxi(1, int(ceil(data.chestPrices[mini(paid, 79)] * (1.0 - clampf(discount, 0.0, 0.6)))))

func free_chance(power: float) -> float:
	return clampf(power,0,.75)

func next_xp(level: int) -> int:
	return 18 + level * 8 + level * level

func can_weapon(equipped: Array, id: String) -> bool:
	return equipped.any(func(w): return w.id == id) or equipped.size() < WEAPON_CAP

func card_targets_weapon(item: Dictionary, weapon_id: String) -> bool:
	if item.kind=="weapon": return item.id==weapon_id
	for effect in item.effects:
		var key=str(effect.key)
		if data.augments.has(key): key=data.augments[key].stat
		if not UpgradeFit.weapon_key(key) or UpgradeFit.affects(key,ContentExpansion.weapon(weapon_id)): return true
	return false

func rarity(luck: float) -> int:
	var chance = rng.randf() + clampf(luck,0,0.75) * 0.06
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
	# Pick a gameplay mechanic first, then a card. Large families cannot suppress unique powers.
	# Equal mechanic odds keep adding themed cards from diluting basic upgrades.
	if kind=="skill": kind="item"
	if kind=="item":
		# Fixed rarity: roll the rarity, then an item that only exists in it.
		while tier>0 and item_tiers[tier].is_empty(): tier-=1
		var kinds=item_tiers[tier].keys();var group: Array=item_tiers[tier][kinds[rng.randi_range(0,kinds.size()-1)]]
		var item: Dictionary=group[rng.randi_range(0,group.size()-1)].duplicate(true)
		if not item.get("relic",false):
			item.effects=[item.effects[0].duplicate()]
			var effect=item.effects[0]
			if effect.key in WHOLE_KEYS: effect.amount=maxi(1,roundi(effect.amount))
			else: effect.amount*=ITEM_STRENGTH[tier]
		item.tier=tier;item.strength=ITEM_STRENGTH[tier];item.name=item.title
		return item
	var mechanics=mechanic_pools[kind].keys()
	var mechanic=mechanics[rng.randi_range(0,mechanics.size()-1)]
	var pool: Array=mechanic_pools[kind][mechanic]
	var result: Dictionary = pool[rng.randi_range(0, pool.size() - 1)].duplicate(true)
	result.effects=[result.effects[0].duplicate()]
	for effect in result.effects:
		effect.amount *= strength
		if effect.key in ["airJumps","flowerSeeds","revive","multishot","pierce","chain","ricochet","discBounces","boomerangPierce","meteorCount"]: effect.amount=maxi(1,roundi(effect.amount))
	result.tier = tier
	result.strength = strength
	result.name = result.title
	if result.family in ["Economy","Mobility"]: result.name = result.title
	return result

# minimum: lowest rarity tier to roll (-1: uncommon for elite chests, else common).
func offers(kind: String, luck: float, elite: bool = false, current_stats: Dictionary = {}, equipped: Array = [],excluded_ids: Array=[],filtered_weapon: String="",minimum: int=-1) -> Array:
	var floor_tier=minimum if minimum>=0 else (1 if elite else 0)
	var result = []
	var attempts = 0
	if no_weapons and kind=="weapon": kind="skill"
	if kind=="weapon" and equipped.size()>=WEAPON_CAP:
		# Full weapon slots: no other weapon appears, only ranks for these.
		var mine=equipped.duplicate();mine.shuffle()
		for weapon in mine:
			var item=weapon.duplicate(true)
			item.tier=maxi(floor_tier,rarity(luck));item.strength=[1.0,2.0,3.5,5.5][item.tier];item.kind="weapon"
			item.erase("node")
			result.append(item)
		return result
	while result.size() < OFFER_COUNT and attempts<1000:
		var item = roll(kind, luck, floor_tier)
		attempts += 1
		# Item 5: when a specific equipped weapon is given, keep only cards that
		# apply to that weapon (weapon upgrades and +Power boosts), plus the weapon
		# itself when it matches. This keeps a shared party pool relevant to each
		# player's own loadout instead of offering unrelated power cards.
		if filtered_weapon != "":
			if not card_targets_weapon(item, filtered_weapon): continue
		if item.kind!="weapon" and banished.has(item.effects[0].key): continue
		if no_weapons and item.kind in ["weapon","evolution"]: continue
		if attempts<80 and excluded_ids.has(item.id): continue
		if item.kind!="weapon" and not current_stats.is_empty():
			var candidate=current_stats.duplicate(true)
			apply_effects(candidate,item.effects)
			var effect=item.effects[0];var key=effect.key
			if not current_stats.has(key): pass
			elif is_equal_approx(candidate[key],current_stats[key]):
				if attempts<800: continue
				item=roll("weapon",luck,1 if elite else 0)

			else:
				effect.amount=(candidate[key]/current_stats[key]-1) if effect.get("mode","add")=="multiply" and current_stats[key]!=0 else candidate[key]-current_stats[key]
		if attempts < 80 and result.any(func(a): return a.id == item.id or a.name == item.name or a.kind!="weapon" and item.kind!="weapon" and a.effects[0].key==item.effects[0].key): continue
		result.append(item)
	if result.size()<OFFER_COUNT:
		var fallback=offers("weapon",luck,elite,{},equipped) if kind!="weapon" and not no_weapons else []
		while result.size()<OFFER_COUNT and not fallback.is_empty(): result.append(fallback.pop_front())
	# A mild single-slot preference, never a fixed recipe or a banned/capped bonus.
	if kind!="weapon" and rng.randf()<.3 and not equipped.is_empty():
		var keys=["damage","rate","range"]
		for w in equipped:
			if w.id=="flowers": keys.append_array(["flowerPower","flowerRoots","flowerPollen"])
			if w.turret: keys.append_array(["turretDamage","turretRate","turretRange"])
			if w.id in ["boomerang","disc","harpoon","gravity","horn","bubble","meteor","bomb"]: keys.append(w.id+"Power")
		for attempt in range(40):
			var item=roll(kind,luck,1 if elite else 0)
			var key=item.effects[0].key
			if not keys.has(key) or banished.has(key) or excluded_ids.has(item.id) or result.any(func(i):return i.kind!="weapon" and i.effects[0].key==key): continue
			if not current_stats.is_empty():
				var candidate=current_stats.duplicate(true);apply_effects(candidate,item.effects)
				if is_equal_approx(candidate.get(key,0),current_stats.get(key,0)): continue
				item.effects[0].amount=candidate[key]/current_stats[key]-1 if item.effects[0].get("mode","add")=="multiply" and current_stats[key]!=0 else candidate[key]-current_stats[key]
			if not result.is_empty(): result[0]=item
			break
	return result

# Level-up offers (big update MB): new weapons while a weapon slot is free,
# ranks for the weapons you carry, new cards while a card slot is free, levels
# for the cards you hold, and upgrades for your own weapons. weapon_focus (level
# 2 and every third level) makes at least two of the five weapons.
func level_offers(luck: float,current_stats: Dictionary,equipped: Array,cards: Dictionary,excluded_ids: Array=[],weapon_focus: bool=false) -> Array:
	var pools={"weapon":[],"card":[],"weapon_up":[]}
	if not no_weapons:
		if equipped.size()<WEAPON_CAP:
			var fresh={}
			for attempt in range(60):
				if fresh.size()>=3: break
				var weapon=roll("weapon",luck)
				if equipped.any(func(w):return w.id==weapon.id) or (attempt<40 and excluded_ids.has(weapon.id)): continue
				fresh[weapon.id]=weapon
			pools.weapon.append_array(fresh.values())
		for weapon in equipped:
			var rank_up=weapon.duplicate(true);rank_up.erase("node")
			rank_up.tier=rarity(luck);rank_up.strength=[1.0,2.0,3.5,5.5][rank_up.tier];rank_up.kind="weapon"
			pools.weapon.append(rank_up)
	var stats_known=not current_stats.is_empty()
	for stat in Loadout.CARDS:
		var held=cards.has(stat)
		if banished.has(stat) or (not held and cards.size()>=Loadout.CARD_SLOTS): continue
		var card=Loadout.card_offer(stat,rarity(luck),int(cards.get(stat,0)))
		if stats_known and current_stats.has(stat):
			var candidate=current_stats.duplicate(true);apply_effects(candidate,card.effects)
			if is_equal_approx(float(candidate[stat]),float(current_stats[stat])): continue
		pools.card.append(card)
	if not equipped.is_empty() and mechanic_pools.has("weapon_up"):
		for attempt in range(40):
			if pools.weapon_up.size()>=3: break
			var up=roll("weapon_up",luck)
			var key=str(up.effects[0].key)
			if banished.has(key) or pools.weapon_up.any(func(u):return u.effects[0].key==key): continue
			if not equipped.any(func(w):return card_targets_weapon(up,str(w.id))): continue
			pools.weapon_up.append(up)
	for key in pools: pools[key].shuffle()
	var result=[]
	if weapon_focus:
		while result.size()<2 and not pools.weapon.is_empty(): result.append(pools.weapon.pop_front())
	var weights={"card":.45,"weapon":.35,"weapon_up":.2}
	var guard=0
	while result.size()<OFFER_COUNT and guard<50:
		guard+=1
		var open=weights.keys().filter(func(k):return not pools[k].is_empty())
		if open.is_empty(): break
		var total=0.0
		for k in open: total+=weights[k]
		var pick=rng.randf()*total;var chosen=open[0]
		for k in open:
			pick-=weights[k]
			if pick<=0: chosen=k;break
		var item=pools[chosen].pop_front()
		if result.any(func(r):return r.id==item.id): continue
		result.append(item)
	# A full loadout with nothing left to grow still gets a choice: chest items.
	if result.size()<OFFER_COUNT:
		for item in offers("item",luck,false,current_stats,equipped,excluded_ids):
			if result.size()>=OFFER_COUNT: break
			if not result.any(func(r):return r.id==item.id): result.append(item)
	return result

func apply_effects(stats: Dictionary, effects: Array):
	for effect in effects:
		var key: String = effect.key
		if not stats.has(key): continue
		if effect.get("mode", "add") == "multiply": stats[key] *= 1.0 + effect.amount
		else: stats[key] += effect.amount
	var caps = {"slamRecovery":5,"airJumps":8,"keyPower":.75,"fallGuard":.95,"jumpHeight":5,"slamRadius":4,"bounceJump":2,"flowerSeeds":2,"flowerRoots":0.7,"rate":18,"speed":18,"maxHp":5000,"damage":3000,"dodge":0.65,"lifesteal":0.4,"crit":0.85,"freeze":0.65,"blind":0.65,"discount":0.6,"multishot":7,"chain":8,"pierce":12,"turretCount":1,"drones":3,"interest":0.08,"ghost":2.0,"pickup":20,"coinRadius":22,"regen":40,"revive":4}
	caps.merge({"discBounces":8,"boomerangPierce":12,"harpoonPull":3,"gravitySize":4,"hornStun":3,"bubbleTime":4,"meteorCount":5,"bombSize":4,"airDamage":3,"landingHeal":50,"slamHeal":50,"airControl":.5,"fallThreshold":20,"potionDuration":4,"potionPower":3,"potionChance":.6,"jumpShield":100,"jumpBlast":200,"slamFire":100,"slamPoison":100,"coinHeal":20,"chestHeal":200})
	# Match the limits already used by combat instead of offering ineffective cards.
	caps.merge({"enemyPull":8,"enemyPush":8,"size":2.5,"knockback":3,"slow":.7,"banana":.6,"riftDash":3})
	for id in ["boomerang","disc","harpoon","gravity","horn","bubble","meteor","bomb"]: caps[id+"Power"]=20
	for key in caps:
		if stats.has(key): stats[key] = minf(stats[key], caps[key])
	stats.dashCooldown = maxf(0.6, stats.dashCooldown)
	stats.chestBonus = minf(stats.chestBonus, 0.75)

func describe(effect: Dictionary) -> String:
	if str(effect.key).begins_with("mut:"): return MutationBook.describe(str(effect.key),int(effect.amount))
	if data.augments.has(effect.key):
		var bonus=data.augments[effect.key];var amount=float(effect.amount)
		var percent=bonus.mode=="multiply" or bonus.stat in ["crit","dodge","lifesteal"]
		return "+%s%s %s %s" % [snappedf(amount*100 if percent else amount,.01),"%" if percent else "",bonus.label,bonus.when]
	if effect.key=="curse": return "More monsters +%d%%" % roundi(float(effect.amount)*100)
	if str(effect.key).begins_with("relic"): return Relics.describe(str(effect.key),float(effect.amount))
	var phrases = {"duration":"Effects and traps last longer","ricochet":"Shots bounce to another enemy","enemyPull":"Attraction pulse strength (8 m, every 3.5 s)","riftDash":"Dash through a portal: pop out further ahead with a blast at both ends","enemyPush":"Repulsion pulse strength (8 m, every 4.5 s)","banana":"Chance to slip enemies","flowerPower":"Bigger flower blooms", "flowerRoots":"Roots slow enemies", "flowerPollen":"Poison pollen", "flowerHeal":"Blooms heal you", "flowerSeeds":"Plant extra flowers","damage":"Hit harder", "rate":"Attack faster", "speed":"Move faster", "maxHp":"More health", "armor":"Take less damage", "regen":"Health grows back", "lifesteal":"Hits heal you", "poison":"Poison on hit", "burn":"Fire on hit", "thorns":"Hurt enemies that touch you", "freeze":"Freeze enemies", "blind":"Blind enemies", "ghost":"Dash through danger", "burrow":"Dash underground, then explode", "shield":"A shield that grows back", "goldGain":"More coins from enemies", "discount":"Cheaper chests", "keyPower":"Chance to open chests free", "walkGold":"Walking makes coins", "hurtGold":"Being hit gives coins", "interest":"Saved coins grow each minute", "coinRadius":"Pull coins from farther away", "potGold":"More coins from harvestables", "drones":"Flying helpers attack", "orbitDamage":"Orbiting blades", "auraDamage":"Hurt nearby enemies", "storm":"Call lightning", "nova":"Send out a blast", "pools":"Leave poison pools", "boomerang":"Shots come back", "multishot":"More shots", "crit":"More critical hits", "critPower":"Bigger critical hits", "pierce":"Shots go through enemies", "chain":"Lightning jumps", "splash":"Hits explode", "explosion":"Kills explode", "dashBlast":"Dash makes a blast", "dashCooldown":"Dash more often", "revive":"Another life", "luck":"Better treasure", "chestBonus":"Better treasure", "salvage":"Kills heal you", "turretCount":"Stronger turret", "turretDamage":"Stronger turret", "turretRate":"Faster turret", "turretRange":"Turret reaches farther", "turretLife":"Turret stays longer", "repair":"Heal near your turret", "berserk":"Hit harder at low health", "xpGain":"Learn faster", "pickup":"Pull XP closer", "range":"Reach farther", "projectileSpeed":"Faster shots", "size":"Bigger shots", "knockback":"Push enemies back", "slow":"Slow enemies", "execute":"Finish weak enemies", "bossDamage":"Hurt bosses more", "stun":"Stun enemies", "magnetPulse":"Pull in XP"}
	var name=phrases.get(effect.key, data.labels.get(effect.key,"More power"))
	var extra={"discBounces":"Disc bounces","boomerangPierce":"Blade piercing","harpoonPull":"Hook pull","gravitySize":"Gravity radius","hornStun":"Horn stun","bubbleTime":"Bubble time","meteorCount":"Extra meteors","bombSize":"Bomb radius","airDamage":"Damage while airborne","landingHeal":"Heal on landing","slamHeal":"Heal on slam","airControl":"Air movement","fallThreshold":"Safe fall height","potionDuration":"Potion time","potionPower":"Potion strength","potionChance":"Potion drop chance","jumpShield":"Shield on jump","jumpBlast":"Jump blast damage","slamFire":"Fire on slam","slamPoison":"Poison on slam","coinHeal":"Heal per coin pickup","chestHeal":"Heal on opening a chest"}
	if extra.has(effect.key): name=extra[effect.key]
	var amount=float(effect.amount)
	if effect.key in ["harpoonPull","fallThreshold"]: return name+" +%s m" % snappedf(amount,.01)
	if effect.key=="hornStun": return name+" +%s s" % snappedf(amount,.01)
	if effect.key in ["airDamage","airControl","potionChance"]: return name+" +%s%%" % snappedf(amount*100,.01)
	if effect.key=="slamRecovery": return "Slam recharge +%s%% (4.5s base; 0.75s minimum)" % snappedf(amount*100,.01)
	if effect.key=="dashCooldown": return "Dash cooldown −%s s" % snappedf(absf(amount),.01)
	if effect.key in ["jumpHeight","airJumps","fallGuard","slamPower","slamRadius","bounceJump"]:
		name={"jumpHeight":"Jump height","airJumps":"Extra air jumps","fallGuard":"Fall damage reduction","slamPower":"Slam damage","slamRadius":"Slam radius","bounceJump":"Landing jump boost"}[effect.key]
	var percent=effect.get("mode","add")=="multiply" or effect.key in ["crit","dodge","lifesteal","discount","freeze","blind","slow","stun","execute","salvage","fallGuard","bounceJump","interest","chestBonus","banana","berserk"]
	if effect.key=="keyPower": return "Free chest chance +%s%%" % snappedf(amount*100,.01)
	if effect.key=="ghost": return "Ghost dash +%s s" % snappedf(amount,.01)
	# Hero drawbacks are negative (Tank Potato moves 18% slower): show the real sign.
	return name+(" +" if amount>=0 else " −")+str(snappedf(absf(amount)*100 if percent else absf(amount),.01))+("%" if percent else "")

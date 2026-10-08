extends RefCounted
class_name RunReport

static func stat_rows(game) -> Array:
	var base=game.rules.data.stats
	var hero=base.duplicate(true);game.rules.apply_effects(hero,game.hero.effects)
	var rows=[]
	for key in base:
		if str(key).begins_with("augment-"): continue
		var permanent=float(game.stats.get(key,base[key]))
		var potion=PotionBook.value(key,permanent,game.buffs,float(game.stats.get("potionPower",1)))
		var total=game.stat(key)
		if total==0 and float(base[key])==0 and key not in ["shield","armor","crit","dodge","regen","airJumps","enemyPull","enemyPush"]: continue
		rows.append({"key":key,"name":game.rules.data.labels.get(key,str(key).capitalize()),"base":float(base[key]),"hero":float(hero[key])-float(base[key]),"gear":permanent-float(hero[key]),"buff":potion-permanent,"augment":total-potion,"total":total})
	return rows

static func source_name(game,key: String) -> String:
	for weapon in game.rules.data.weapons:
		if weapon.id==key: return weapon.name
	return key.trim_prefix("effect:").replace("_"," ").capitalize()

static func ranked_damage(game) -> Array:
	var result=[]
	for key in game.damage_sources: result.append({"source":key,"name":source_name(game,key),"amount":game.damage_sources[key]})
	result.sort_custom(func(a,b):return a.amount>b.amount)
	return result

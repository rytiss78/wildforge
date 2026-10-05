extends RefCounted
class_name ContentExpansion

static var weapons={}

static func weapon(id: String) -> Dictionary:
	if weapons.is_empty():
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/catalog.json"))
		for entry in data.weapons: weapons[entry.id]=entry
	return weapons.get(id,{})

static func kind(id: String) -> String:
	return str(weapon(id).get("archetype",id))

static func refresh(game):
	game.conditional_bonuses.clear()
	var active={};var needed={}
	for id in game.rules.data.augments:
		if float(game.stats.get(id,0))>0: needed[game.rules.data.augments[id].condition]=true
	for condition in needed: active[condition]=condition_met(game,condition)
	for id in game.rules.data.augments:
		var amount=float(game.stats.get(id,0))
		var definition=game.rules.data.augments[id]
		if amount>0 and active.get(definition.condition,false):
			game.conditional_bonuses[definition.stat]=float(game.conditional_bonuses.get(definition.stat,0))+amount

static func condition_met(game,condition: String) -> bool:
	match condition:
		"air": return not game.player.is_on_floor()
		"ground": return game.player.is_on_floor()
		"moving": return Vector2(game.player.velocity.x,game.player.velocity.z).length()>1
		"still": return Vector2(game.player.velocity.x,game.player.velocity.z).length()<.5
		"low": return game.hp<game.stats.maxHp*.4
		"healthy": return game.hp>game.stats.maxHp*.8
		"shield": return game.shield_hp>0
		"bare": return game.shield_hp<=0
		"dash","slam","kill","hurt": return game.elapsed-float(game.condition_times.get(condition,-100))<(4 if condition in ["slam","hurt"] else 3)
		"rich": return game.gold>=50
		"boss": return game.enemies.any(func(e):return not e.dead and e.boss and e.node.position.distance_squared_to(game.player.position)<625)
		"alone": return not game.enemies.any(func(e):return not e.dead and e.node.position.distance_squared_to(game.player.position)<64)
		"crowd":
			var count=0
			for enemy in game.enemies:
				if not enemy.dead and enemy.node.position.distance_squared_to(game.player.position)<144: count+=1
			return count>=4
		"flower": return game.flowers.any(func(f):return is_instance_valid(f.node) and f.node.position.distance_squared_to(game.player.position)<64)
		"turret": return game.equipped.any(func(w):return w.turret and is_instance_valid(w.node) and w.node.position.distance_squared_to(game.player.position)<64)
	return false

static func value(game,key: String,base: float) -> float:
	var amount=float(game.conditional_bonuses.get(key,0))
	var result=base+amount if key in ["regen","armor","dodge","crit","knockback","lifesteal","pickup"] else base*(1+amount)
	if key in ["crit","dodge","lifesteal"]: result=minf(result,.85 if key=="dodge" else .6 if key=="lifesteal" else 1)
	return result

static func payload(enemy: Dictionary,type: String):
	if enemy.dead: return
	match type:
		"fire": enemy.fire=maxf(enemy.fire,8);enemy.status_time=4
		"poison": enemy.poison=maxf(enemy.poison,8);enemy.status_time=4
		"ice": enemy.freeze=maxf(enemy.freeze,.2 if enemy.boss else .8);enemy.slow=maxf(enemy.slow,.35);enemy.status_time=4
		"bubble": enemy.bubble=maxf(enemy.get("bubble",0),1.5);enemy.slow=maxf(enemy.slow,.6);enemy.status_time=4

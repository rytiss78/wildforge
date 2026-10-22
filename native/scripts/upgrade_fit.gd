extends RefCounted
class_name UpgradeFit

const SHOTS=["multishot","pierce","ricochet","boomerang","projectileSpeed","size","berserk"]
const ON_HIT=["burn","poison","slow","freeze","blind","stun","execute","lifesteal","knockback","splash","chain","bossDamage","banana","crit","critPower"]
const SPECIAL={"discBounces":"disc","boomerangPierce":"boomerang","harpoonPull":"harpoon","gravitySize":"gravity","hornStun":"horn","bubbleTime":"bubble","meteorCount":"meteor","bombSize":"bomb"}

static func weapon_key(key: String) -> bool:
	return key in SHOTS or key in ON_HIT or key in ["damage","rate","range","airDamage","repair"] or key.begins_with("turret") or key.begins_with("flower") or SPECIAL.has(key) or key.ends_with("Power") and key.trim_suffix("Power") in ["boomerang","disc","harpoon","gravity","horn","bubble","meteor","bomb"]+SkillBook.KINDS

static func affects(key: String, weapon: Dictionary) -> bool:
	var kind=ContentExpansion.kind(weapon.id)
	if key.begins_with("turret") or key=="repair": return weapon.get("turret",false)
	if key.begins_with("flower"): return kind=="flowers"
	if SPECIAL.has(key): return kind==SPECIAL[key]
	if key.ends_with("Power") and key!="critPower": return kind==key.trim_suffix("Power")
	if key=="damage": return true
	if key=="rate": return kind!="flowers" and not weapon.get("turret",false)
	if key in ["range","airDamage"]: return kind!="flowers"
	# Spells grow with Size and multiply with extra shots; they have no projectile or on-hit.
	if kind in SkillBook.KINDS and (key in SHOTS or key in ON_HIT): return key in ["size","multishot"]
	if key in SHOTS: return kind not in ["flowers","saw","horn","gravity","meteor"]
	if key in ON_HIT: return kind not in ["flowers","horn","gravity","meteor"]
	return false

static func for_key(game,key: String) -> Dictionary:
	if not weapon_key(key): return {"useful":true,"text":"HERO BENEFIT · any loadout"}
	var names=[]
	for weapon in game.equipped:
		if affects(key,weapon): names.append(str(weapon.name))
	if not names.is_empty(): return {"useful":true,"text":"WORKS WITH · "+", ".join(names)}
	var requires="a projectile weapon"
	if key.begins_with("turret") or key=="repair": requires="an equipped turret"
	elif key.begins_with("flower"): requires="Flowers"
	elif SPECIAL.has(key): requires=str(ContentExpansion.weapon(SPECIAL[key]).get("name",SPECIAL[key]))
	elif key.ends_with("Power") and key!="critPower": requires=str(ContentExpansion.weapon(key.trim_suffix("Power")).get("name",key.trim_suffix("Power")))
	elif key=="rate": requires="a handheld weapon"
	elif key in ON_HIT: requires="a projectile weapon or saw"
	return {"useful":false,"text":"NO CURRENT BENEFIT · needs "+requires}

static func describe(game,item: Dictionary) -> Dictionary:
	if item.get("kind","")=="mutation":
		var definition=MutationBook.entry(str(item.id).trim_prefix("mut:"))
		var level=int(game.mutations.get(definition.get("id",""),0))
		var group=str(definition.get("group",""))
		var text={"core":"MUTATION · ","rule":"STRAIN RULE · ","hybrid":"HYBRID · "}.get(group,"WILD CARD · changes every mutation")+("" if group=="wild" else MutationBook.family(definition))
		return {"useful":true,"text":text+(" · owned Lv %d" % level if level>0 else "")}
	var notes=[];var useful=false
	var candidate=game.stats.duplicate(true);game.rules.apply_effects(candidate,item.effects)
	for effect in item.effects:
		var key=str(effect.key);var condition=""
		if is_equal_approx(float(candidate.get(key,0)),float(game.stats.get(key,0))):
			notes.append("AT LIMIT · no additional benefit");continue
		if game.rules.data.augments.has(key):
			var augment=game.rules.data.augments[key];key=augment.stat;condition=" · "+str(augment.when)
			var required="flowers" if augment.condition=="flower" else "turret" if augment.condition=="turret" else ""
			if not required.is_empty() and not game.equipped.any(func(w):return ContentExpansion.kind(w.id)=="flowers" if required=="flowers" else w.get("turret",false)):
				notes.append("NO CURRENT BENEFIT · needs "+required+condition);continue
		var fit=for_key(game,key)
		if key=="critPower" and game.stat("crit")<=0:
			fit={"useful":false,"text":"NO CURRENT BENEFIT · needs critical-hit chance"}
		useful=useful or fit.useful;notes.append(fit.text+condition)
	return {"useful":useful,"text":"\n".join(notes)}

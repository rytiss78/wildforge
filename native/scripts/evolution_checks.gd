extends RefCounted

# Weapon evolution through the real paths: a real chest purchase and reveal,
# a press of the EVOLVE card's own button, the evolved weapon's shots, the HUD
# slot, banish, and the co-op shared-pool filter.
static func run(game: Node3D) -> Dictionary:
	var checks={}
	game.clear_entities();game.hud.close();game.mode="playing";game.owned.clear();game.equipped.clear();game.offers.clear()
	var gun=game.rules.data.weapons.filter(func(w):return w.id=="gun")[0].duplicate(true);gun.kind="weapon";gun.strength=1.0
	game.equip_weapon(gun)
	var weapon=game.equipped[0];weapon.rank=WeaponEvolution.RANK-1
	var crit_card=game.rules.data.loot.filter(func(i):return i.kind=="item" and i.effects[0].key=="crit")
	if crit_card.is_empty(): crit_card=game.rules.data.loot.filter(func(i):return game.rules.data.augments.has(i.effects[0].key) and game.rules.data.augments[i.effects[0].key].stat=="crit")
	checks.evolution_needs_rank=not WeaponEvolution.ready(game,weapon)
	weapon.rank=WeaponEvolution.RANK
	checks.evolution_needs_catalyst=not WeaponEvolution.ready(game,weapon)
	# At full rank without its catalyst, chests and skill level-ups offer the catalyst.
	var with_key=WeaponEvolution.inject(game,game.rules.offers("item",0,false,game.stats,game.equipped),"chest")
	var key_cards=with_key.filter(func(i):return i.get("catalyst_for","")=="gun")
	checks.evolution_catalyst_offered=key_cards.size()==1 and (key_cards[0].effects[0].key=="crit" or game.rules.data.augments.get(key_cards[0].effects[0].key,{}).get("stat","")=="crit")
	var skill_key=WeaponEvolution.inject(game,game.rules.offers("skill",0,false,game.stats,game.equipped),"level")
	checks.evolution_catalyst_level=skill_key.any(func(i):return i.get("catalyst_for","")=="gun")
	# Taking it through the real offer button completes the recipe.
	game.offers=with_key;game.mode="offer";game.offer_kind="item";game.offer_source="chest";game.hud.show_offers(with_key,"chest",false)
	game.hud.cards[with_key.find(key_cards[0]) if not key_cards.is_empty() else 0].pressed.emit()
	checks.evolution_catalyst_taken=WeaponEvolution.ready(game,weapon)
	game.hud.close();game.mode="playing";game.owned.clear()
	game.owned.append(crit_card[0].duplicate(true))
	checks.evolution_ready=WeaponEvolution.ready(game,weapon)
	# Every weapon in the catalog has an evolved form.
	checks.evolution_every_weapon=game.rules.data.weapons.all(func(w):return not WeaponEvolution.form(w.id).is_empty())
	game.hud.weapons.refresh()
	var ready_tag=game.hud.weapons.find_children("EvolveTag","Label",true,false)
	checks.evolution_ready_hint=not ready_tag.is_empty() and ready_tag[0].text=="EVOLVE READY"
	# A real chest purchase: the reveal leads to an offer whose first card evolves the gun.
	game.make_chest(game.player.position+Vector3(2,0,0),false);var chest=game.chests[-1];chest.mimic=false;chest.free=true
	game.buy_chest(chest)
	for i in range(400):
		if game.mode!="reveal": break
		game._process(.05)
	checks.evolution_chest_offer=game.mode=="offer" and not game.offers.is_empty() and game.offers[0].kind=="evolution" and game.offers[0].weapon_id=="gun"
	checks.evolution_one_card=game.offers.filter(func(i):return i.kind=="evolution").size()==1
	# Banish cannot remove it.
	var charges=game.update.banish_charges;game.update.banish(0)
	checks.evolution_not_banished=game.update.banish_charges==charges and game.offers[0].kind=="evolution"
	var power=float(weapon.power)
	if checks.evolution_chest_offer:
		var card_button=game.hud.cards[0]
		checks.evolution_card_text=card_button.tooltip_text.contains("Hand Cannon")
		card_button.pressed.emit()
	checks.evolution_applied=weapon.get("evolved",false) and weapon.name=="Hand Cannon" and is_equal_approx(float(weapon.power),power*float(WeaponEvolution.form("gun").power))
	checks.evolution_modifiers=int(weapon.get("modifiers",{}).get("extraPierce",0))==2 and is_equal_approx(float(weapon.get("modifiers",{}).get("shotScale",1)),1.5)
	checks.evolution_announced=str(game.events.get("announcement",""))=="WEAPON EVOLVED"
	checks.evolution_held_halo=not game.avatar.held.is_empty() and game.avatar.held[0].evolved
	game.hud.weapons.refresh()
	var evolved_tag=game.hud.weapons.find_children("EvolveTag","Label",true,false)
	checks.evolution_hud_slot=not evolved_tag.is_empty() and evolved_tag[0].text=="EVOLVED"
	checks.evolution_once=WeaponEvolution.inject(game,game.rules.offers("item",0,false,game.stats,game.equipped),"chest").all(func(i):return i.kind!="evolution")
	# Its shots: gilded and piercing two more enemies than the plain gun's.
	game.hud.close();game.mode="playing"
	game.spawn_enemy(8);var target=game.enemies[-1];target.node.position=game.player.position+Vector3(0,0,-6)
	var before=game.projectiles.size()
	game.fire(weapon,game.player.position+Vector3.UP)
	var shots=game.projectiles.slice(before)
	checks.evolution_shots=not shots.is_empty() and shots.all(func(s):return s.get("evolved",false) and int(s.pierce)>=int(game.stats.pierce)+2)
	checks.evolution_shot_trail=not shots.is_empty() and is_instance_valid(shots[0].get("trail")) and shots[0].trail_width>ShotFx.style("gun").width*1.5
	# Themed variants keep their own name with the form's adjective; modifiers merge.
	checks.evolution_variant_name=WeaponEvolution.evolved_name({"id":"popcorn-repeater","name":"Popcorn Repeater"})=="Gilded Popcorn Repeater"
	var merged=WeaponEvolution.merge({"extraShots":2,"coneDot":.4,"payload":"poison","shotScale":2.0},{"extraShots":1,"coneDot":.2,"payload":"fire","shotScale":1.5})
	checks.evolution_merge=is_equal_approx(merged.extraShots,3) and is_equal_approx(merged.coneDot,.2) and merged.payload=="poison" and is_equal_approx(merged.shotScale,3.0)
	# Co-op: a shared chest pool carries the opener's evolution card; each player
	# drops it and gets their own instead (none here: the gun already evolved).
	var pool=game.rules.offers("item",0,false,game.stats,game.equipped)
	pool[0]={"id":"evolve:rail","kind":"evolution","weapon_id":"rail","name":"EVOLVE · Star Lance","tier":3,"effects":[]}
	pool[1]=pool[1].duplicate(true);pool[1].catalyst_for="rail"
	game.open_shared_offer(pool,"item",false,"chest","evolution-check")
	checks.evolution_shared_pool=not game.offers.any(func(i):return i.kind=="evolution" or i.has("catalyst_for")) and game.offers.size()==pool.size()-1
	game.hud.close();game.mode="playing";game.clear_entities();game.owned.clear()
	return checks

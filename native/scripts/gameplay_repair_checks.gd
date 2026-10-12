extends RefCounted

static func run(game) -> Dictionary:
	game.start_run(611);game.set_physics_process(false);game.spawn_clock=99999
	var checks={}
	checks.harvest_biome=game.harvestables.size()==48 and game.harvestables.all(func(h):return game.world.biome_at(h.node.position)==h.biome)
	checks.harvest_descriptions=HarvestBook.TYPES.all(func(t):return not t.description.is_empty() and not t.effect.is_empty())
	var damage=game.stat("damage");var permanent=game.stats.damage
	var pepper=game.harvestables.filter(func(h):return h.biome==4)[0]
	game.pick_harvestable(pepper)
	checks.harvest_percent=is_equal_approx(game.stat("damage"),damage*1.15) and game.stats.damage==permanent
	game.harvest_buffs[4]=2
	var second=game.harvestables.filter(func(h):return h.biome==4)[0];game.pick_harvestable(second)
	checks.harvest_refresh=game.harvest_buffs[4]==20 and is_equal_approx(game.stat("damage"),damage*1.15)
	var coins=game.pickups.size();game.pick_harvestable(second)
	checks.harvest_pick_once=game.pickups.size()==coins
	game.mode="paused";game._physics_process(2)
	checks.harvest_pause=game.harvest_buffs[4]==20
	game.mode="playing";HarvestBook.tick(game,21)
	checks.harvest_expiry=not game.harvest_buffs.has(4) and is_equal_approx(game.stat("damage"),damage)
	var herb=game.harvestables.filter(func(h):return h.biome==0)[0];game.hp=game.stats.maxHp-20;game.pick_harvestable(herb)
	checks.harvest_heal=game.hp==game.stats.maxHp-8 and game.damage_numbers.any(func(d):return d.cause=="heal")
	var crystal=game.harvestables.filter(func(h):return h.biome==2)[0];var shield=game.stats.shield;game.pick_harvestable(crystal)
	checks.harvest_shield=game.stats.shield==shield+2 and game.shield_hp>=2
	game.harvest_buffs[3]=20;game.harvest_buffs[5]=20
	checks.harvest_jump=game.stat("airJumps")==game.stats.airJumps+1
	checks.harvest_gold=is_equal_approx(game.stat("goldGain"),game.stats.goldGain*1.25)
	var equipped=game.equipped
	game.equipped=[ContentExpansion.weapon("gun")]
	checks.gun_fit=UpgradeFit.for_key(game,"pierce").useful and not UpgradeFit.for_key(game,"turretDamage").useful and not UpgradeFit.for_key(game,"flowerHeal").useful
	checks.hero_fit=UpgradeFit.for_key(game,"armor").useful
	checks.conditional_fit=not UpgradeFit.describe(game,{"effects":[{"key":"augment-air-turretDamage","amount":.2}]}).useful
	game.equipped=[ContentExpansion.weapon("saw")]
	checks.saw_fit=not UpgradeFit.for_key(game,"multishot").useful and UpgradeFit.for_key(game,"chain").useful
	game.equipped=[ContentExpansion.weapon("turret")]
	checks.turret_fit=UpgradeFit.for_key(game,"turretDamage").useful and not UpgradeFit.for_key(game,"rate").useful
	game.equipped=[ContentExpansion.weapon("flowers")]
	checks.flowers_fit=UpgradeFit.for_key(game,"flowerHeal").useful and not UpgradeFit.for_key(game,"pierce").useful
	game.equipped=equipped
	game.xp=500;game.level_choice_cooldown=0;var target=game.xp_target;game.level_up()
	var level=game.level;game.mode="offer";game.choose_offer(0)
	checks.level_no_chain=game.mode=="playing" and game.level==level and game.xp==500-target
	game.level_up();checks.level_gap=game.level==level
	game.level_choice_cooldown=0;game.level_up()
	checks.level_banked=game.level==level+1 and game.xp==500-target-game.rules.next_xp(level)
	checks.xp_bounded=game.enemy_xp_reward({"maxHp":50000,"damage":4})<=5 and game.enemy_xp_reward({"maxHp":50000,"damage":4,"boss":true})<=45
	game.mode="playing";game.xp=0;game.level_choice_cooldown=0
	for pickup in game.pickups: pickup.node.queue_free()
	game.pickups.clear();var point=game.player.position+Vector3(10,1,0)
	for i in range(20):
		game.spawn_pickup(point+Vector3(i*.02,0,0),"xp",2)
		game.pickups[-1].settled=true;game.pickups[-1].base_y=point.y-1
	game.merge_xp_orbs()
	checks.xp_merge_bounded=game.pickups.size()>1 and game.pickups.all(func(p):return p.value<=maxf(12,game.xp_target*.4))
	checks.xp_merge_conserved=is_equal_approx(game.pickups.reduce(func(total,p):return total+p.value,0.0),40)
	game.damage_numbers.clear();var victim=game.enemies[0];victim.hp=10000;victim.maxHp=10000
	game.hit_enemy(victim,{"kind":"gun","damage":10.0,"critical":true})
	checks.critical_feedback=game.damage_numbers.any(func(d):return d.cause=="crit")
	game.start_run(612);game.set_physics_process(false)
	checks.new_run_resets=game.harvest_buffs.is_empty() and game.level_choice_cooldown==0
	game.clear_entities()
	return checks

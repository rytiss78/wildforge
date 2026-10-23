extends RefCounted

# Ideal sustained damage, not a survival or five-minute playtest.
# Each tier spends 12/24/36 common offensive cards, plus weapon ranks 1/3/6.
static func run(g):
	AudioServer.set_bus_volume_db(0,-80)
	g.start_run(1616);g.enter_realm(3);g.set_process(false);g.set_physics_process(false)
	g.invulnerable=100000;g.spawn_clock=100000;g.xp_target=100000
	var boss=g.enemies[0];var rows=[];var checks={}
	for build in ["weapons","turrets","status","slam","flowers"]:
		for tier in range(3):
			for list in [g.projectiles,g.effects,g.flowers,g.pools,g.hazards]:
				for item in list:
					if is_instance_valid(item.node): item.node.queue_free()
				list.clear()
			for weapon in g.equipped:
				if is_instance_valid(weapon.get("node")): weapon.node.queue_free()
			g.equipped.clear();g.stats=g.rules.data.stats.duplicate(true);g.buffs.clear();g.owned.clear()
			g.damage_sources.clear();g.condition_times.clear()
			var keys=["damage","rate"]
			var weapons=["gun","shotgun","rail"]
			match build:
				"turrets": keys=["damage","turretDamage","turretRate"];weapons=["turret","fire-turret","rocket-turret"]
				"status": keys=["damage","rate","burn","poison"];weapons=["flame","poison","lightning"]
				"slam": keys=["damage","slamPower","slamRecovery"];weapons=[]
				"flowers": keys=["damage","flowerPower","flowerSeeds"];weapons=["flowers"]
			for i in range(12*(tier+1)):
				var key=keys[i%keys.size()]
				var card=g.rules.data.loot.filter(func(c):return c.get("effects",[]).size()>0 and c.effects[0].key==key)[0]
				g.rules.apply_effects(g.stats,card.effects)
			boss.hp=1000000000;boss.maxHp=boss.hp;boss.freeze=100000;boss.contact=100000;boss.attack=100000
			boss.fire=0;boss.poison=0;boss.status_time=0
			g.player.position=boss.node.position+Vector3(0,0,boss.radius+1.5)
			g.player.position.y=g.world.height_at(g.player.position.x,g.player.position.z)+.1
			g.player.velocity=Vector3.DOWN;g.player.move_and_slide();g.avatar.position=g.player.position
			for id in weapons:
				var weapon=g.rules.data.weapons.filter(func(w):return w.id==id)[0].duplicate(true)
				weapon.strength=1.0
				for rank in range([1,3,6][tier]): g.equip_weapon(weapon)
			var initial=boss.hp;var slam_clock=0.0
			# Established garden: six mature flowers touching the boss; no planting downtime.
			if build=="flowers":
				for i in range(6):
					g.plant_flower(g.player.position+Vector3.RIGHT*(i-2.5)*.5,g.equipped[0]);g.flowers[-1].age=2;g.flowers[-1].life=100
			for tick in range(1800):
				var delta=1.0/60
				g.elapsed+=delta;g.realm_time+=delta;g.mode="playing"
				if build=="slam":
					slam_clock-=delta
					if slam_clock<=0:
						# Landing entry point with full cooldown and .5 seconds of airtime.
						g.player.velocity=Vector3.DOWN;g.player.move_and_slide()
						g.slamming=true;g.landing_ready=true;g.peak_height=g.player.position.y+2;g.check_landing(false)
						slam_clock=g.slam_recovery()+.5
				g.update_combat(delta)
				if tick%6==0: g._process(.1)
				if tick%60==0: await g.get_tree().process_frame
			var damage=initial-boss.hp;var dps=damage/30
			checks[build+str(tier)]=dps>0
			rows.append({"build":build,"offensive_cards":12*(tier+1),"weapon_rank":[1,3,6][tier],"damage_30s":damage,"dps":dps,"ideal_solo_seconds":(preload("res://scripts/final_arena.gd").TARGET_SECONDS*preload("res://scripts/final_arena.gd").REFERENCE_DPS*preload("res://scripts/final_arena.gd").HEALTH_MULTIPLIER)/maxf(.001,dps),"ideal_two_equal_players_seconds":(preload("res://scripts/final_arena.gd").TARGET_SECONDS*preload("res://scripts/final_arena.gd").REFERENCE_DPS*preload("res://scripts/final_arena.gd").HEALTH_MULTIPLIER)*1.65/maxf(.001,dps*2),"ideal_four_equal_players_seconds":(preload("res://scripts/final_arena.gd").TARGET_SECONDS*preload("res://scripts/final_arena.gd").REFERENCE_DPS*preload("res://scripts/final_arena.gd").HEALTH_MULTIPLIER)*2.95/maxf(.001,dps*4)})
			print("BALANCE_SAMPLE "+JSON.stringify(rows[-1]))
	print("BALANCE_REVIEW "+JSON.stringify({"checks":checks,"samples":rows,"note":"Stationary invulnerable target and perfect attack uptime; estimates exclude dodging, travel, planting and deaths. Offensive cards only; not a claim about typical level or win rates."}))
	g.clear_entities()
	g.equipped.clear();g.avatar.sync_equipment([])
	for node in g.find_children("*","AudioStreamPlayer",true,false): node.stop()
	for node in g.find_children("*","AudioStreamPlayer3D",true,false): node.stop()
	await g.get_tree().create_timer(.2).timeout
	for i in range(3): await g.get_tree().process_frame
	g.get_tree().quit(1 if checks.values().has(false) else 0)

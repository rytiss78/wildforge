extends RefCounted

# Regressions for the November 2026 bug sweep of game.gd.
static func run(game: Node3D) -> Dictionary:
	var checks={}
	game.select_hero(game.rules.data.heroes[1])
	game.start_run(733);game.set_physics_process(false);game.spawn_clock=99999;game.clear_entities();game.mode="playing"
	var coop: CoopSession=game.coop
	var here: Vector3=game.player.position

	# The host under the island with no friend in reach: pickups keep working.
	coop.active=true;coop.hosting=true;coop.members.clear()
	game.underside.state="under"
	game.spawn_pickup(here+Vector3(2,.4,0),"xp",3.0);game.spawn_pickup(here+Vector3(12,.4,0),"gold",5.0)
	checks.sweep_no_collector_setup=coop.target(here).id==-1 and game.pickups.size()==2
	game.update_pickups(.1)
	checks.sweep_pickups_run_without_collector=game.pickups.size()==2 and game.pickups.all(func(p):return p.age>0.05)
	game.underside.state="top"

	# A friend's chest: the achievements go to the friend, judged by their gold.
	var price=game.rules.chest_price(0,0.0)
	coop.members[2]={"hp":100.0,"gold":price+50,"paid_chests":0,"stats":{"discount":0.0,"keyPower":0.0,"luck":0.0,"chestBonus":0.0},"position":CoopSession.array(here)}
	for id in ["LAST_COIN","SALE","FREE_KEY","BOSS_GIFT","HIGH_CHEST"]: game.career.data.total.erase("event_"+id)
	game.gold=price;game.stats.discount=.2
	game.make_chest(here+Vector3(1.5,0,0),false);var chest=game.chests[-1];chest.rolled_free=true;chest.free=false
	game.buy_chest(chest,2)
	checks.sweep_friend_chest_paid_by_friend=chest.opened and game.gold==price and int(coop.members[2].gold)==50
	checks.sweep_friend_chest_no_host_achievements=not game.career.data.total.has("event_LAST_COIN") and not game.career.data.total.has("event_SALE")
	# The friend's own game is told what it needs to award them.
	game.chest_achievements(price,price,false,false,true)
	checks.sweep_chest_achievements_for_opener=game.career.data.total.has("event_LAST_COIN") and game.career.data.total.has("event_SALE") and game.career.data.total.has("event_HIGH_CHEST") and not game.career.data.total.has("event_FREE_KEY")
	game.offers.clear();game.hud.close();game.mode="playing";game.stats.discount=0.0
	coop.members.clear();coop.active=false;coop.hosting=false
	game.clear_entities()

	# A dash does not cut short protection that is already running.
	game.invulnerable=3.0;game.dash_cooldown=0.0;game.dash()
	checks.sweep_dash_keeps_longer_protection=game.invulnerable>=2.9
	game.invulnerable=0.0;game.dash_cooldown=0.0;game.dash()
	checks.sweep_dash_still_protects=game.invulnerable>=.29
	game.dash_time=0.0

	# Storm bolts fall on the four nearest enemies, not the oldest ones far away.
	for i in range(7): game.spawn_enemy(12.0)
	var far=game.enemies[0];var near=game.enemies.slice(1)
	for enemy in game.enemies: enemy.maxHp=5000.0;enemy.hp=5000.0;enemy.speed=0.0;enemy.erase("modifier")
	far.node.position=here+Vector3(70,0,0)
	for i in range(near.size()): near[i].node.position=here+Vector3(4.0+i*3.0,0,0)
	game.stats.storm=10.0;game.storm_strike()
	var struck=near.filter(func(e):return e.hp<5000.0)
	checks.sweep_storm_hits_nearest_four=far.hp==5000.0 and struck.size()==4 and near.slice(0,4).all(func(e):return e.hp<5000.0)
	game.stats.storm=0.0;game.clear_entities()

	# The host drags enemies into a friend's black hole (shown here as a visual
	# only), and a hit on someone who has left the party is ignored.
	coop.active=true;coop.hosting=true
	game.spawn_enemy(12.0);var dragged=game.enemies[-1];dragged.erase("modifier");dragged.speed=0.0;dragged.node.position=here+Vector3(3,0,0);dragged.erase("pull")
	var hp_before=float(dragged.hp)
	SkillBook.cast_visual(game,"blackhole",here,here+Vector3(3,0,2),.1);SkillBook.tick(game,.016)
	var drag: Vector3=dragged.get("pull",Vector3.ZERO)
	checks.sweep_host_pulls_for_friend_spell=drag.length()>1.0 and drag.z>0 and float(dragged.hp)==hp_before
	coop.damage_player(77,10.0,here,"hit")
	checks.sweep_hit_on_departed_player_ignored=not coop.members.has(77)
	coop.active=false;coop.hosting=false;game.clear_entities()

	# A new run starts without the last run's timers and pushes.
	game.shield_delay=4.0;game.ghost_time=2.0;game.burrow_time=.4;game.knock_velocity=Vector3(11,0,0);game.walking_gold=.9
	game.start_run(734);game.set_physics_process(false);game.spawn_clock=99999
	checks.sweep_new_run_clears_timers=game.shield_delay==0.0 and game.ghost_time==0.0 and game.burrow_time==0.0 and game.knock_velocity==Vector3.ZERO and game.walking_gold==0.0
	game.clear_entities()
	return checks

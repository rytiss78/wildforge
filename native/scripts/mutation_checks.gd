extends RefCounted

# Mutations through their real entry points: offer mixing, choose_offer(),
# dash/kill/pulse triggers and damage modifiers against spawned enemies.
static func target(g,offset: Vector3) -> Dictionary:
	g.spawn_enemy(6);var enemy=g.enemies[-1]
	enemy.node.position=g.player.position+offset;enemy.maxHp=5000.0;enemy.hp=5000.0
	enemy.freeze=0.0;enemy.fire=0.0;enemy.poison=0.0;enemy.speed=0.0
	return enemy

static func choose(g,id: String):
	g.offers=[MutationBook.card(id,int(g.mutations.get(id,0))+1)];g.mode="offer";g.offer_source="level"
	g.choose_offer(0)

static func run(g) -> Dictionary:
	# Runs after encounter_checks inside its active run; restarting would restart music just before quit.
	g.set_process(false);g.set_physics_process(false)
	g.stats=g.rules.data.stats.duplicate(true);g.owned.clear();g.rules.banished.clear();MutationBook.reset(g)
	g.hp=g.stats.maxHp;g.mode="playing"
	g.clear_entities();g.equipped.clear();g.spawn_clock=99999;g.invulnerable=10000
	# Silent: one-shot effect players started just before quit would outlive the test.
	var sfx=g.sound.settings.sfx;g.sound.settings.sfx=0
	var checks={}
	var catalog=MutationBook.all()
	var names={}
	for id in catalog: names[catalog[id].name]=true
	checks.mutation_count=catalog.size()>=100 and names.size()==catalog.size()
	var duplicate_keys=false
	for i in range(200):
		var keys=g.rules.offers("skill",0,false,g.stats,g.equipped).filter(func(item):return item.kind!="weapon").map(func(item):return item.effects[0].key)
		var seen={}
		for key in keys:
			if seen.has(key): duplicate_keys=true
			seen[key]=true
	checks.offers_no_duplicate_effects=not duplicate_keys
	var level_offer=MutationBook.mix(g,g.rules.offers("skill",0,false,g.stats,g.equipped),"level")
	var ids=level_offer.map(func(item):return item.id)
	checks.level_offer_has_mutations=level_offer.size()==5 and level_offer.filter(func(item):return item.kind=="mutation").size()==3 and ids.size()==ids.filter(func(id):return ids.count(id)==1).size()
	checks.mutation_card_describes=g.rules.describe(level_offer[0].effects[0]).length()>20
	# A dash with Cinder Step erupts in flame around the hero.
	choose(g,"ember_dash")
	checks.choose_takes_mutation=g.mutations.get("ember_dash",0)==1 and g.owned.any(func(item):return item.id=="mut:ember_dash") and g.mode=="playing"
	var near=target(g,Vector3(1.5,0,0))
	g.dash_cooldown=0;g.dash()
	checks.dash_mutation_damages=near.hp<5000 and near.fire>0
	choose(g,"ember_dash")
	checks.mutation_levels_up=g.mutations.ember_dash==2 and g.rules.describe({"key":"mut:ember_dash","amount":2}).contains("Level 2")
	# Echo repeats the eruption later through the tick.
	choose(g,"ember_echo");near.hp=5000.0
	g.dash_cooldown=0;g.dash();var after_dash=near.hp
	g.elapsed+=.5;MutationBook.tick(g,.01)
	checks.echo_repeats=after_dash<5000 and near.hp<after_dash
	# Frost pulse fires on its timer without input.
	choose(g,"frost_pulse");near.hp=5000.0;near.freeze=0.0
	for i in range(42): MutationBook.tick(g,.1)
	checks.pulse_fires_on_timer=near.hp<5000 and near.freeze>0
	# Hybrids need both strains; Shatter multiplies personal damage to frozen enemies.
	checks.hybrid_requires_pair=MutationBook.eligible(g,MutationBook.entry("hy_thermal")) and not MutationBook.eligible(g,MutationBook.entry("hy_neuro"))
	choose(g,"frost_shatter")
	near.freeze=2.0;near.hp=5000.0;g.hurt_enemy(near,100,"hit")
	checks.shatter_amplifies=is_equal_approx(5000.0-near.hp,150.0)
	# Kill mutations need this hero's recent hit; a teammate's kill does not trigger them.
	choose(g,"bloom_kill")
	g.hp=g.stats.maxHp-40;var hp_before=g.hp
	var remote=target(g,Vector3(0,0,6));remote.hit_owner=99;remote.last_local_hit=-99.0;g.kill_enemy(remote,"hit")
	var remote_heal=g.hp-hp_before
	var victim=target(g,Vector3(0,0,-6));victim.hp=10.0;g.hurt_enemy(victim,50,"hit")
	checks.kill_trigger_local_only=is_equal_approx(remote_heal,0.0) and victim.dead and g.hp>hp_before
	var max_before=g.stats.maxHp;choose(g,"wild_glass")
	checks.glass_heart_costs_health=is_equal_approx(g.stats.maxHp,max_before*.75)
	g.clear_entities();MutationBook.reset(g);g.mode="playing";g.sound.settings.sfx=sfx
	return checks

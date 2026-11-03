extends RefCounted
class_name Relics

# Chest items this game was missing (user, November 3: "check Megabonk's items
# and use them as inspiration where we have nothing similar"). Each idea below
# was missing here; the names, numbers and looks are this game's own. Like
# Megabonk's best items they come in ONE rarity only: no common copy of a
# legendary exists (RunRules rolls the rarity first, then an item of it).
#
#   Rare       Knuckle Rings  +25% damage to monsters within 6 m
#              Hot Pickle     +20% damage, -5% max health
#              Hearty Stew    +0.5 max health per kill (up to +100)
#              Twin Shards    12% chance a kill drops a second XP orb
#              Lucky Receipt  +2.5% damage for every chest opened this run
#   Epic       Trophy Jar     +0.1% damage per kill (up to +100%)
#              Muscle Belt    +0.2% damage per max health above 100
#              Shine Shell    a hit bounces back at monsters around you, with
#                             a moment of safety (8 s cooldown)
#              Roller Heels   attack speed grows with move speed (up to +40%)
#              Firework Pouch 20% chance a kill launches 3 fireworks
#   Legendary  Overcrit Prism 15% of crits become overcrits (x4)
#              Giant Mallet   2% of hits BONK for x20
#              Plump Pillow   healing past full becomes a cushion (up to 75%
#                             of max health) and +15% lifesteal
#              Wisp Lantern   every kill frees 2 wisps that seek monsters
#              Slow Hourglass hurt below half health: monsters crawl and you
#                             hit twice as hard for 4 s (15 s cooldown)

const ITEMS=[
	{"id":"relicClose","title":"Knuckle Rings","rarity":1,"family":"Precision","effects":[{"key":"relicClose","amount":.25,"mode":"add"}]},
	{"id":"relicPickle","title":"Hot Pickle","rarity":1,"family":"Precision","effects":[{"key":"relicPickle","amount":1,"mode":"add"},{"key":"damage","amount":.2,"mode":"multiply"},{"key":"maxHp","amount":-.05,"mode":"multiply"}]},
	{"id":"relicStew","title":"Hearty Stew","rarity":1,"family":"Defense","effects":[{"key":"relicStew","amount":1,"mode":"add"}]},
	{"id":"relicTwin","title":"Twin Shards","rarity":1,"family":"Arcane","effects":[{"key":"relicTwin","amount":.12,"mode":"add"}]},
	{"id":"relicReceipt","title":"Lucky Receipt","rarity":1,"family":"Economy","effects":[{"key":"relicReceipt","amount":.025,"mode":"add"}]},
	{"id":"relicTrophy","title":"Trophy Jar","rarity":2,"family":"Precision","effects":[{"key":"relicTrophy","amount":1,"mode":"add"}]},
	{"id":"relicBelt","title":"Muscle Belt","rarity":2,"family":"Defense","effects":[{"key":"relicBelt","amount":.002,"mode":"add"}]},
	{"id":"relicShell","title":"Shine Shell","rarity":2,"family":"Defense","effects":[{"key":"relicShell","amount":1,"mode":"add"}]},
	{"id":"relicHeels","title":"Roller Heels","rarity":2,"family":"Mobility","effects":[{"key":"relicHeels","amount":.4,"mode":"add"}]},
	{"id":"relicRockets","title":"Firework Pouch","rarity":2,"family":"Ballistics","effects":[{"key":"relicRockets","amount":.2,"mode":"add"}]},
	{"id":"relicOvercrit","title":"Overcrit Prism","rarity":3,"family":"Precision","effects":[{"key":"relicOvercrit","amount":.15,"mode":"add"}]},
	{"id":"relicBonk","title":"Giant Mallet","rarity":3,"family":"Precision","effects":[{"key":"relicBonk","amount":.02,"mode":"add"}]},
	{"id":"relicPillow","title":"Plump Pillow","rarity":3,"family":"Vampiric","effects":[{"key":"relicPillow","amount":.75,"mode":"add"},{"key":"lifesteal","amount":.15,"mode":"add"}]},
	{"id":"relicWisps","title":"Wisp Lantern","rarity":3,"family":"Arcane","effects":[{"key":"relicWisps","amount":2,"mode":"add"}]},
	{"id":"relicHourglass","title":"Slow Hourglass","rarity":3,"family":"Arcane","effects":[{"key":"relicHourglass","amount":1,"mode":"add"}]},
]
const TEXT={
	"relicClose":"+%d%% damage within 6 m","relicPickle":"+20%% damage · -5%% max health","relicStew":"+0.5 max health per kill (up to +%d)",
	"relicTwin":"%d%% chance of a second XP orb","relicReceipt":"+%.1f%% damage per chest opened","relicTrophy":"+0.1%% damage per kill (up to +%d%%)",
	"relicBelt":"+%.1f%% damage per max health over 100","relicShell":"Hits bounce back at monsters (x%d)","relicHeels":"Attack speed from speed (up to +%d%%)",
	"relicRockets":"%d%% chance a kill launches fireworks","relicOvercrit":"%d%% of crits become overcrits (x4)","relicBonk":"%d%% of hits BONK (x20)",
	"relicPillow":"Overheal up to %d%% as a cushion","relicWisps":"Kills free %d seeking wisps","relicHourglass":"Below half health: slow time, x2 damage (x%d)"}
# stat -> [StatGlyphs category, glyph]
const GLYPHS={"relicClose":["offense","fist"],"relicPickle":["offense","drop"],"relicStew":["recovery","heart"],"relicTwin":["arcane","xp"],
	"relicReceipt":["fortune","tag"],"relicTrophy":["offense","crown"],"relicBelt":["defense","ring"],"relicShell":["defense","shield"],
	"relicHeels":["mobility","dash"],"relicRockets":["fire","burst"],"relicOvercrit":["offense","star"],"relicBonk":["offense","slam"],
	"relicPillow":["recovery","bubble"],"relicWisps":["arcane","ghost"],"relicHourglass":["arcane","clock"]}

static func defaults() -> Dictionary:
	var result={}
	for item in ITEMS: result[item.effects[0].key]=0.0
	return result

static func entries() -> Array:
	var result=[]
	for item in ITEMS:
		var entry=item.duplicate(true);entry.name=entry.title;entry.kind="item";entry.relic=true;entry.slot="item"
		result.append(entry)
	return result

static func describe(key: String,amount: float) -> String:
	var text=str(TEXT.get(key,"%s"))
	match key:
		"relicPickle": return text
		"relicStew": return text % roundi(100*amount)
		"relicTrophy": return text % roundi(100*amount)
		"relicReceipt","relicBelt": return text % (amount*100)
		"relicShell","relicHourglass","relicWisps": return text % roundi(amount)
	return text % roundi(amount*100)

static func s(g,key: String) -> float: return float(g.stats.get(key,0.0))

# --- hooks (game.gd) ------------------------------------------------------

# Extra damage on a hit. Returns [damage, cause] (cause can turn into "crit").
static func hit(g,enemy: Dictionary,damage: float,critical: bool) -> float:
	var bonus=1.0
	if s(g,"relicClose")>0 and enemy.node.position.distance_to(g.player.position)<6.0: bonus+=s(g,"relicClose")
	bonus+=s(g,"relicReceipt")*float(g.run_chests)
	bonus+=minf(s(g,"relicTrophy"),float(g.relic.get("trophy",0))*.001)
	bonus+=s(g,"relicBelt")*maxf(0.0,float(g.stats.maxHp)-100.0)
	if g.elapsed<float(g.relic.get("hourglass_until",-1.0)): bonus*=2.0
	damage*=bonus
	if critical and g.rules.rng.randf()<s(g,"relicOvercrit"):
		damage*=4.0;HeroTricks.word(g,"OVERCRIT!",Color("ffe36b"))
	if s(g,"relicBonk")>0 and g.rules.rng.randf()<s(g,"relicBonk"):
		damage*=20.0;HeroTricks.word(g,"BONK!",Color("ff8a3d"))
		g.burst(enemy.node.position+Vector3.UP*.8,Color("ffd36b"),18);g.hit_shake=maxf(g.hit_shake,.3)
	return damage

static func attack_speed(g) -> float:
	if s(g,"relicHeels")<=0: return 1.0
	var pace=Vector2(g.player.velocity.x,g.player.velocity.z).length()/maxf(1.0,7.0*float(g.stats.speed))
	return 1.0+s(g,"relicHeels")*clampf(pace,0,1)

static func killed(g,enemy: Dictionary):
	if float(enemy.get("last_local_hit",-99.0))<g.elapsed-1.5: return
	g.relic.kills=int(g.relic.get("kills",0))+1
	if s(g,"relicTrophy")>0: g.relic.trophy=int(g.relic.get("trophy",0))+1
	if s(g,"relicStew")>0 and float(g.relic.get("stew",0.0))<100.0*s(g,"relicStew"):
		g.relic.stew=float(g.relic.get("stew",0.0))+.5;g.stats.maxHp+=.5;g.hp+=.5
	var p: Vector3=enemy.node.position
	if g.rules.rng.randf()<s(g,"relicTwin"): g.spawn_pickup(p+Vector3(.6,.4,0),"xp",float(enemy.get("xp_reward",3.0)))
	if g.rules.rng.randf()<s(g,"relicRockets"): seek(g,p,3,g.stats.damage*6.0,"explosion",Color("ff9a4a"))
	if s(g,"relicWisps")>0: seek(g,p,int(s(g,"relicWisps")),g.stats.damage*3.0,"lightning",Color("9ff7ff"))

# Fireworks and wisps: streak from where the monster fell to the nearest others.
static func seek(g,from: Vector3,count: int,damage: float,cause: String,color: Color):
	var targets=g.enemies.filter(func(e):return not e.dead and e.node.position.distance_to(from)<14.0)
	targets.sort_custom(func(a,b):return a.node.position.distance_to(from)<b.node.position.distance_to(from))
	for target in targets.slice(0,count):
		var to: Vector3=target.node.position+Vector3.UP*.8
		for k in range(4): g.burst(from.lerp(to,(k+1)/4.0)+Vector3.UP*(.8+sin((k+1)/4.0*PI)*1.2),color,2)
		if cause=="explosion": g.damage_area(target.node.position,2.5,damage,"explosion")
		else: g.hurt_enemy(target,damage,cause)

# Called when hurt, before the damage lands. Returns the damage still taken.
static func hurt(g,amount: float,source: Vector3) -> float:
	if s(g,"relicShell")>0 and g.elapsed>=float(g.relic.get("shell_ready",0.0)):
		g.relic.shell_ready=g.elapsed+8.0
		g.damage_area(g.player.position,6.0,amount*2.0*s(g,"relicShell"),"explosion")
		g.burst(g.player.position+Vector3.UP,Color("fff4b0"),16);HeroTricks.word(g,"SHINE!",Color("fff4b0"))
		g.invulnerable=maxf(g.invulnerable,.5)
		return 0.0
	if s(g,"relicHourglass")>0 and g.hp-amount<g.stats.maxHp*.5 and g.elapsed>=float(g.relic.get("hourglass_ready",0.0)):
		g.relic.hourglass_ready=g.elapsed+15.0;g.relic.hourglass_until=g.elapsed+4.0*s(g,"relicHourglass")
		for enemy in g.enemies:
			if not enemy.dead: enemy.slow=maxf(float(enemy.slow),.7);enemy.status_time=maxf(float(enemy.status_time),4.0)
		HeroTricks.word(g,"SLOW TIME",Color("c6a8ff"))
	return amount

# Healing past full health: the Plump Pillow keeps it as a cushion (shield).
static func overheal(g,overflow: float):
	if s(g,"relicPillow")<=0 or overflow<=0: return
	var cap=float(g.stats.maxHp)*s(g,"relicPillow")
	g.relic.cushion=minf(cap,float(g.relic.get("cushion",0.0))+overflow)
	g.shield_hp=maxf(g.shield_hp,minf(cap,g.shield_hp+overflow))

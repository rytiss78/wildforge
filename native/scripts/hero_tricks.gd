extends RefCounted
class_name HeroTricks

# Hero tricks (user request, October 29): every hero has one unique trick on its
# own button (V / left trigger), with a cooldown. They are built from a few kinds,
# each tuned and named for its hero:
#   shout   a cry that stuns enemies around you          (Count Duck's QUACK!)
#   roll    you roll forward through enemies, hurting them (Turbo Snail)
#   quake   a big ground smash that hurts and knocks back
#   nova    a ring of fire, ice, poison or lightning
#   heal    heal and soothe, rooting or freezing enemies near you
#   cloud   a cloud that blinds and slows enemies
#   frenzy  a few seconds of faster shooting and/or running
#   leap    a huge jump that smashes down where you land
#   coins   tax the enemies around you: damage, and they drop coins
#   bubble  refill your shield and trap nearby enemies in bubbles
#   blink   vanish in smoke and reappear ahead
#   dig     dig straight through the island to its other side, and back (Mole)
#   garden  plant a ring of fully grown flowers round you at once (Florist)
# Damage goes through damage_area/hurt_enemy, so co-op guests' tricks reach the
# host like any hit; stuns and blinds travel as the "stun"/"blind" causes.

const TRICKS={
	"wrench":{"name":"Overclock","kind":"frenzy","cooldown":18.0,"rate":2.0,"speed":1.0,"time":6.0,"word":"OVERCLOCK!"},
	"duck":{"name":"QUACK!","kind":"shout","cooldown":12.0,"radius":7.0,"stun":1.6,"word":"QUACK!"},
	"grandma":{"name":"Handbag Quake","kind":"quake","cooldown":12.0,"radius":7.0,"damage":60.0,"word":"WHACK!"},
	"goblin":{"name":"Tax Day","kind":"coins","cooldown":16.0,"radius":8.0,"damage":25.0,"coins":3,"word":"TAXED!"},
	"florist":{"name":"Bouquet","kind":"garden","cooldown":14.0,"count":6,"radius":6.5,"heal":.3,"cause":"stun","word":"BLOOM!"},
	"octopus":{"name":"Ink Cloud","kind":"cloud","cooldown":14.0,"radius":8.0,"word":"SPLOOSH!"},
	"astronaut":{"name":"Moon Jump","kind":"leap","cooldown":11.0,"radius":7.0,"damage":50.0,"word":"BOING!"},
	"cactus":{"name":"Needle Burst","kind":"nova","cooldown":9.0,"radius":6.0,"damage":45.0,"cause":"hit","color":"9be05a","word":"PRICKLES!"},
	"snail":{"name":"Shell Spin","kind":"roll","cooldown":9.0,"distance":9.0,"damage":40.0,"word":"WHEEE!"},
	"bee":{"name":"Sugar Rush","kind":"frenzy","cooldown":18.0,"rate":1.6,"speed":1.4,"time":5.0,"word":"BUZZZ!"},
	"icecream":{"name":"Brain Freeze","kind":"nova","cooldown":13.0,"radius":7.0,"damage":20.0,"cause":"ice","color":"bfeaff","word":"BRAIN FREEZE!"},
	"bathtub":{"name":"Bubble Bath","kind":"bubble","cooldown":18.0,"radius":7.0,"word":"SPLISH!"},
	"peacock":{"name":"Fabulous!","kind":"cloud","cooldown":14.0,"radius":8.0,"heal":10.0,"word":"FABULOUS!"},
	"toaster":{"name":"Pop-Up","kind":"nova","cooldown":11.0,"radius":6.5,"damage":40.0,"cause":"fire","color":"ffb03a","word":"POP!"},
	"ninja":{"name":"Smoke Step","kind":"blink","cooldown":8.0,"distance":9.0,"word":"POOF!"},
	"smoker":{"name":"Smog Bomb","kind":"nova","cooldown":12.0,"radius":8.0,"damage":20.0,"cause":"poison","color":"8fd65a","word":"COUGH!"},
	"alcoholic":{"name":"Hiccup Blast","kind":"quake","cooldown":10.0,"radius":6.0,"damage":45.0,"word":"HIC!"},
	"white-supra":{"name":"Nitro","kind":"frenzy","cooldown":16.0,"rate":1.0,"speed":1.8,"time":4.0,"word":"NITRO!"},
	"mole":{"name":"Dig Through","kind":"dig","cooldown":9.0,"radius":6.0,"damage":50.0,"word":"DIG!"},
	"clutch":{"name":"Lock-On","kind":"aimlock","cooldown":20.0,"time":4.0,"word":"LOCKED!"},
}

# Tax Day drops at most this many coins, each worth more in a big crowd.
const COIN_CAP=30

static func trick(g) -> Dictionary: return TRICKS.get(str(g.hero.id),{})

# One line for the hero screen: what the trick does, in numbers, and its cooldown.
static func describe(t: Dictionary) -> String:
	var text=""
	var r=float(t.get("radius",0));var dmg=roundi(float(t.get("damage",0)))
	match str(t.kind):
		"shout": text="Stuns enemies within %d m for %.1f s" % [r,float(t.stun)]
		"roll": text="Roll %d m through enemies for %d damage" % [roundi(float(t.distance)),dmg]
		"quake": text="Smash the ground: %d damage within %d m" % [dmg,r]
		"nova": text="A ring of %s: %d damage within %d m" % [{"fire":"fire","ice":"ice","poison":"poison","lightning":"lightning"}.get(str(t.get("cause","")),"spikes"),dmg,r]
		"heal": text="Heal %d%% ♥ and calm enemies within %d m" % [roundi(float(t.heal)*100),r]
		"cloud": text="A cloud that blinds and slows enemies within %d m" % r
		"frenzy":
			var parts=[]
			if float(t.get("rate",1))>1: parts.append("%.1f× fire rate" % float(t.rate))
			if float(t.get("speed",1))>1: parts.append("%.1f× speed" % float(t.speed))
			text="%d s of %s" % [roundi(float(t.time))," and ".join(parts)]
		"leap": text="Leap high and smash down: %d damage within %d m" % [dmg,r]
		"coins": text="%d damage within %d m; each enemy hit drops %d coins" % [dmg,r,int(t.coins)]
		"bubble": text="Refill your shield and trap enemies within %d m in bubbles" % r
		"blink": text="Vanish and reappear %d m ahead" % roundi(float(t.distance))
		"dig": text="Dig through the island to its other side; burst out for %d damage" % dmg
		"garden": text="Plant %d grown flowers in a ring round you" % int(t.count)
		"aimlock": text="%.0f s aimbot: locks on the nearest enemy's head and fires by itself, %d× damage" % [float(t.time),roundi(ClutchPlay.LOCK_DAMAGE)]
		_: text=str(t.get("name",""))
	return text+" · %d s" % roundi(float(t.cooldown))

# Damage scales with the island like the enemies' health does.
static func power(g) -> float: return float(g.realm_difficulty)*maxf(1.0,float(g.stats.get("damage",1.0))/10.0)

static func use(g) -> bool:
	var t=trick(g)
	if t.is_empty() or g.trick_cooldown>0 or g.mode!="playing" or g.hp<=0 or g.update.downed: return false
	var p: Vector3=g.player.position
	# Digging through the island (Mole): only from solid footing on top or underneath.
	if str(t.kind)=="dig":
		if g.underside.state in ["down","up","dig_down","dig_up"]: return false
		if g.underside.can_dig(g):
			g.trick_cooldown=float(t.cooldown);word(g,str(t.word))
			g.underside.dig(g,t.damage*power(g),float(t.radius));shout(g)
			return true
		# Not on solid footing (mid-jump): nothing happens and no cooldown is spent.
		if g.world.realm!=RealmWorld.ARENA: return false
		# The Red Moon has no underside: burrow down and burst up where you stand.
		g.trick_cooldown=float(t.cooldown);word(g,str(t.word))
		g.damage_area(p,t.radius,t.damage*power(g),"burrow");g.burst(p+Vector3.UP*.4,Color("7a5a3a"),18)
		CombatInk.wave(g,p,t.radius,Color("c79a5a"));g.hit_shake=maxf(g.hit_shake,.4);g.sound.effect("slam",p);shout(g)
		return true
	g.trick_cooldown=float(t.cooldown)
	word(g,str(t.word))
	match str(t.kind):
		"shout":
			g.damage_area(p,t.radius,1.0,"stun")
			CombatInk.wave(g,p,t.radius,Color("ffe14d"));g.sound.effect("horn",p)
		"quake":
			g.damage_area(p,t.radius,t.damage*power(g),"slam")
			for enemy in g.enemies:
				if not enemy.dead and not enemy.boss and enemy.node.position.distance_to(p)<t.radius: enemy.node.move_and_collide(((enemy.node.position-p)*Vector3(1,0,1)).normalized()*2.5)
			g.slam_wave();g.hit_shake=maxf(g.hit_shake,.5)
		"nova":
			g.damage_area(p,t.radius,t.damage*power(g),str(t.cause))
			CombatInk.wave(g,p,t.radius,Color(str(t.color)));g.burst(p+Vector3.UP,Color(str(t.color)),16);g.sound.effect("nova",p)
		"garden":
			# A ring of flowers, grown at once, round the Florist (user, November 1:
			# "the Florist's V should plant flowers in a circle instantly").
			var bed=g.equipped.filter(func(w):return w.id=="flowers")
			if bed.is_empty():
				g.heal(g.stats.maxHp*float(t.heal))
			else:
				var count=int(t.count);var turn=randf()*TAU
				for i in range(count):
					var at=p+Vector3.RIGHT.rotated(Vector3.UP,turn+i*TAU/count)*float(t.radius)
					g.plant_flower(at,bed[0]);g.flowers[-1].age=1.5;g.flowers[-1].node.scale=Vector3.ONE
					g.burst(Vector3(at.x,g.world.height_at(at.x,at.z)+1.0,at.z),Color("f5a8c4"),6)
				g.last_plant=p
			g.sound.effect("heal",p)
		"aimlock":
			# Clutch: an aimbot for a few seconds (aims, fires, next target), 5x damage.
			ClutchPlay.lock_until=g.elapsed+float(t.time);ClutchPlay.lock_target={}
		"heal":
			g.heal(g.stats.maxHp*float(t.heal));g.player_poison=0;g.player_fire=0
			g.damage_area(p,t.radius,1.0,str(t.cause))
			CombatInk.wave(g,p,t.radius,Color("9bffb0"));g.burst(p+Vector3.UP,Color("9bffb0"),14);g.sound.effect("heal",p)
		"cloud":
			g.damage_area(p,t.radius,1.0,"blind")
			if t.has("heal"): g.heal(float(t.heal))
			for i in range(10): g.burst(p+Vector3(randf_range(-1,1),randf_range(.3,1.6),randf_range(-1,1))*t.radius*.5,Color("2a1f3a") if g.hero.id=="octopus" else Color("ff8ac6"),3)
			g.sound.effect("steam",p)
		"frenzy":
			g.trick_boosts.rate=[float(t.rate),g.elapsed+float(t.time)];g.trick_boosts.speed=[float(t.speed),g.elapsed+float(t.time)]
			g.burst(p+Vector3.UP,Color("ffe14d"),12);g.sound.effect("level",p)
		"roll":
			g.trick_roll={"left":float(t.distance),"damage":t.damage*power(g),"hit":{},"dir":forward(g)}
			g.sound.effect("dash",p)
		"leap":
			g.player.velocity.y=19.0;g.trick_leap={"radius":t.radius,"damage":t.damage*power(g),"armed":.25}
			g.sound.effect("jump",p)
		"coins":
			# The same gold in at most COIN_CAP coins: a big crowd used to drop
			# hundreds of pickups in one frame.
			var taxed=g.enemies.filter(func(e):return not e.dead and e.node.position.distance_to(p)<=t.radius)
			var owed=taxed.size()*int(t.coins);var dropped=mini(owed,COIN_CAP)
			for i in range(dropped): g.spawn_pickup(taxed[i%taxed.size()].node.position+Vector3.UP*.8,"gold",maxf(1.0,2.0+g.realm)*owed/dropped)
			g.damage_area(p,t.radius,t.damage*power(g),"hit")
			g.sound.effect("coin",p);CombatInk.wave(g,p,t.radius,Color("edc361"))
		"bubble":
			g.shield_hp=maxf(g.shield_hp,float(g.stats.get("shield",0))+25.0);g.shield_delay=0
			for enemy in g.enemies:
				if not enemy.dead and not enemy.boss and enemy.node.position.distance_to(p)<t.radius: enemy.bubble=2.5;enemy.slow=maxf(enemy.slow,.7);enemy.status_time=2.5
			g.damage_area(p,t.radius,1.0,"stun")
			g.burst(p+Vector3.UP,Color("c6e4ed"),18);g.sound.effect("bubble",p)
		"blink":
			g.damage_area(p,4.0,1.0,"blind");g.burst(p+Vector3.UP,Color("3a3a46"),16)
			g.rift_dash_move(forward(g)*float(t.distance))
			g.burst(g.player.position+Vector3.UP,Color("3a3a46"),10);g.sound.effect("dash",g.player.position)
	return true

static func forward(g) -> Vector3:
	var stick=Input.get_vector("move_left","move_right","move_forward","move_back",.18)
	return preload("res://scripts/combat_tactics.gd").dash_vector(stick,g.yaw,g.direction)

# The hero's own trick shout (quip_<id>_trick.wav; Digby Mole's "Dig, dig, dig!"),
# at most every 15 s so it does not get old.
static var last_shout=-100.0
# A new run restarts g.elapsed: forget the last run's shout time.
static func reset():
	last_shout=-100.0
static func shout(g) -> bool:
	if g.elapsed-last_shout<15.0: return false
	if not ResourceLoader.exists("res://assets/voices/quip_%s_trick.wav" % str(g.hero.id)): return false
	last_shout=g.elapsed;g.sound.hero_quip(str(g.hero.id),"trick",g.player)
	return true

# A big comic word over the hero's head.
static func word(g,text: String,color: Color=Color("ffe14d")):
	var label=Label3D.new();label.text=text;label.font_size=72;label.pixel_size=.012;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate=color;label.outline_modulate=Color("1b1a24");label.outline_size=14;label.no_depth_test=true
	g.add_child(label);label.position=g.player.position+Vector3.UP*2.6
	g.effects.append({"node":label,"life":.9,"velocity":Vector3.UP*1.4})

# Rolls and leaps run over several frames.
static func tick(g,delta: float):
	g.trick_cooldown=maxf(0.0,g.trick_cooldown-delta)
	if not g.trick_roll.is_empty():
		var roll=g.trick_roll;var step=minf(roll.left,18.0*delta);roll.left-=step
		g.player.move_and_collide(roll.dir*step)
		for enemy in g.enemies.duplicate():
			if enemy.dead or roll.hit.has(enemy.net_id) or enemy.node.position.distance_to(g.player.position)>1.8: continue
			roll.hit[enemy.net_id]=true;g.hurt_enemy(enemy,roll.damage,"hit");g.burst(enemy.node.position+Vector3.UP,Color("ffd23f"),5)
		g.invulnerable=maxf(g.invulnerable,.1)
		var spin=g.avatar.get("body") if is_instance_valid(g.avatar) else null
		if spin is Node3D: spin.rotation.x-=delta*22.0
		if roll.left<=0:
			g.trick_roll={}
			if spin is Node3D: spin.rotation.x=0.0
	if not g.trick_leap.is_empty():
		g.trick_leap.armed-=delta
		if g.trick_leap.armed<=0 and g.player.is_on_floor():
			var at=g.player.position;g.damage_area(at,g.trick_leap.radius,g.trick_leap.damage,"slam")
			g.slam_wave();g.hit_shake=maxf(g.hit_shake,.6);g.trick_leap={}

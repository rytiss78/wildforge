extends RefCounted
class_name HeroTricks

# Hero tricks (user request, October 29): every hero has one unique trick on its
# own button (V / left trigger), with a cooldown. They are built from a few kinds,
# each tuned and named for its hero:
#   shout   a cry that stuns enemies around you          (Count Duck's QUACK!)
#   roll    you roll forward through enemies, hurting them (Tank Potato)
#   quake   a big ground smash that hurts and knocks back
#   nova    a ring of fire, ice, poison or lightning
#   heal    heal and soothe, rooting or freezing enemies near you
#   cloud   a cloud that blinds and slows enemies
#   frenzy  a few seconds of faster shooting and/or running
#   leap    a huge jump that smashes down where you land
#   coins   tax the enemies around you: damage, and they drop coins
#   bubble  refill your shield and trap nearby enemies in bubbles
#   blink   vanish in smoke and reappear ahead
# Damage goes through damage_area/hurt_enemy, so co-op guests' tricks reach the
# host like any hit; stuns and blinds travel as the "stun"/"blind" causes.

const TRICKS={
	"wrench":{"name":"Overclock","kind":"frenzy","cooldown":18.0,"rate":2.0,"speed":1.0,"time":6.0,"word":"OVERCLOCK!"},
	"duck":{"name":"QUACK!","kind":"shout","cooldown":12.0,"radius":7.0,"stun":1.6,"word":"QUACK!"},
	"broccoli":{"name":"Spud Roll","kind":"roll","cooldown":10.0,"distance":11.0,"damage":45.0,"word":"ROLL!"},
	"grandma":{"name":"Handbag Quake","kind":"quake","cooldown":12.0,"radius":7.0,"damage":60.0,"word":"WHACK!"},
	"goblin":{"name":"Tax Day","kind":"coins","cooldown":16.0,"radius":8.0,"damage":25.0,"coins":3,"word":"TAXED!"},
	"loaf":{"name":"Rise & Shine","kind":"leap","cooldown":12.0,"radius":6.0,"damage":55.0,"word":"RISE!"},
	"florist":{"name":"Bouquet","kind":"heal","cooldown":20.0,"heal":.3,"radius":6.0,"cause":"stun","word":"BLOOM!"},
	"teapot":{"name":"Tea Time","kind":"heal","cooldown":20.0,"heal":.2,"radius":6.0,"cause":"ice","word":"TEA TIME!"},
	"octopus":{"name":"Ink Cloud","kind":"cloud","cooldown":14.0,"radius":8.0,"word":"SPLOOSH!"},
	"astronaut":{"name":"Moon Jump","kind":"leap","cooldown":11.0,"radius":7.0,"damage":50.0,"word":"BOING!"},
	"cactus":{"name":"Needle Burst","kind":"nova","cooldown":9.0,"radius":6.0,"damage":45.0,"cause":"hit","color":"9be05a","word":"PRICKLES!"},
	"book":{"name":"Plot Twist","kind":"nova","cooldown":12.0,"radius":10.0,"damage":35.0,"cause":"lightning","color":"8fd6ff","word":"PLOT TWIST!"},
	"snail":{"name":"Shell Spin","kind":"roll","cooldown":9.0,"distance":9.0,"damage":40.0,"word":"WHEEE!"},
	"bee":{"name":"Sugar Rush","kind":"frenzy","cooldown":18.0,"rate":1.6,"speed":1.4,"time":5.0,"word":"BUZZZ!"},
	"sushi":{"name":"Rolling Cut","kind":"roll","cooldown":8.0,"distance":9.0,"damage":55.0,"word":"SLICE!"},
	"mushroom":{"name":"Flambé","kind":"nova","cooldown":11.0,"radius":7.0,"damage":30.0,"cause":"fire","color":"ff7a2a","word":"FLAMBÉ!"},
	"clock":{"name":"Alarm!","kind":"shout","cooldown":13.0,"radius":8.0,"stun":2.0,"word":"BRRRING!"},
	"icecream":{"name":"Brain Freeze","kind":"nova","cooldown":13.0,"radius":7.0,"damage":20.0,"cause":"ice","color":"bfeaff","word":"BRAIN FREEZE!"},
	"bathtub":{"name":"Bubble Bath","kind":"bubble","cooldown":18.0,"radius":7.0,"word":"SPLISH!"},
	"peacock":{"name":"Fabulous!","kind":"cloud","cooldown":14.0,"radius":8.0,"heal":10.0,"word":"FABULOUS!"},
	"toaster":{"name":"Pop-Up","kind":"nova","cooldown":11.0,"radius":6.5,"damage":40.0,"cause":"fire","color":"ffb03a","word":"POP!"},
	"ninja":{"name":"Smoke Step","kind":"blink","cooldown":8.0,"distance":9.0,"word":"POOF!"},
	"smoker":{"name":"Smog Bomb","kind":"nova","cooldown":12.0,"radius":8.0,"damage":20.0,"cause":"poison","color":"8fd65a","word":"COUGH!"},
	"alcoholic":{"name":"Hiccup Blast","kind":"quake","cooldown":10.0,"radius":6.0,"damage":45.0,"word":"HIC!"},
	"white-supra":{"name":"Nitro","kind":"frenzy","cooldown":16.0,"rate":1.0,"speed":1.8,"time":4.0,"word":"NITRO!"},
}

static func trick(g) -> Dictionary: return TRICKS.get(str(g.hero.id),{})

# Damage scales with the island like the enemies' health does.
static func power(g) -> float: return float(g.realm_difficulty)*maxf(1.0,float(g.stats.get("damage",1.0))/10.0)

static func use(g) -> bool:
	var t=trick(g)
	if t.is_empty() or g.trick_cooldown>0 or g.mode!="playing" or g.hp<=0 or g.update.downed: return false
	g.trick_cooldown=float(t.cooldown)
	var p: Vector3=g.player.position
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
			for enemy in g.enemies.duplicate():
				if enemy.dead or enemy.node.position.distance_to(p)>t.radius: continue
				for i in range(int(t.coins)): g.spawn_pickup(enemy.node.position+Vector3.UP*.8,"gold",maxf(1.0,2.0+g.realm))
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

# A big comic word over the hero's head.
static func word(g,text: String):
	var label=Label3D.new();label.text=text;label.font_size=72;label.pixel_size=.012;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate=Color("ffe14d");label.outline_modulate=Color("1b1a24");label.outline_size=14;label.no_depth_test=true
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

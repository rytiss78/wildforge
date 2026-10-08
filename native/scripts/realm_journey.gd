extends RefCounted

static func state(g) -> String:
	if g.events.get("guardian_defeated",false): return "cleared"
	if g.events.get("guardian_summoned",false): return "fighting"
	return "ready" if g.realm_bosses>=2 or g.realm_time>=600 else "sealed"

static func announce(g,title: String,subtitle: String):
	g.events.announcement=title;g.events.announcement_detail=subtitle;g.events.announcement_until=g.elapsed+5
	g.hit_shake=.8;g.vibrate(.5,.8,.35);g.sound.effect("horn",g.player.position)
	if g.coop.active and g.coop.hosting: g.coop.broadcast({"type":"journey_announcement","title":title,"detail":subtitle})

static func boss_arrived(g,enemy):
	enemy.freeze=2.5;enemy.contact=3
	enemy.title=["Briar Colossus","Cinder Sovereign","Astral Devourer"][g.realm] if enemy.get("guardian",false) else ["The Root Warden","The Dusk Warden"][mini(g.realm_bosses,1)]
	g.boss_name=enemy.title;enemy.label.text=enemy.title
	announce(g,enemy.title.to_upper(),"PORTAL GUARDIAN · Defeat it to leave this island" if enemy.get("guardian",false) else "WARDEN AWAKENED · Watch the ground warnings")
	g.explosion_fx(enemy.node.position,8);g.burst(enemy.node.position+Vector3.UP*3,Color("f4cb80"),18)

static func activate(g):
	if state(g)=="sealed": g.achievement_event("LOCKED_GATE");g.hud.tell("Defeat two wardens or survive until the Eclipse.",4);return
	if state(g)=="fighting": g.hud.tell("Defeat the portal guardian before travelling.",4);return
	if state(g)=="cleared":
		if g.realm==2: g.end_run(true)
		else: g.enter_realm(g.realm+1)
		return
	var before=g.enemies.size();g.spawn_enemy(15,true,g.gate_position,true)
	if g.enemies.size()==before: g.hud.tell("The portal is obstructed. Move into open ground and try again.");return
	var enemy=g.enemies[-1];enemy.guardian=true;enemy.maxHp*=1.6;enemy.hp=enemy.maxHp;enemy.damage*=1.2
	g.events.guardian_summoned=true;g.events.guardian_attack=g.realm_time+4
	g.gate.get_meta("marker").text="GUARDIAN AWAKENED"

static func tick(g):
	if g.coop.active and not g.coop.hosting: return
	if g.realm_time>=600 and not g.events.get("eclipse",false):
		g.events.eclipse=true;g.events.eclipse_stage=0
		announce(g,"THE ECLIPSE","The portal awakens. Enemies grow stronger every 30 seconds.")
		g.sound.effect("blast",g.player.position);g.gate.get_meta("marker").text="SUMMON GUARDIAN"
	if g.events.get("eclipse",false):
		var stage=1+int((g.realm_time-600)/30)
		if stage>int(g.events.get("eclipse_stage",0)):
			g.events.eclipse_stage=stage
			for enemy in g.enemies: EclipseCorruption.apply(enemy,stage)
			g.events.swarm_until=g.realm_time+12;g.events.wave_active=true;g.events.wave_budget=30+stage*5
			for i in range(4): g.spawn_enemy(22)
	if state(g)=="fighting" and g.realm_time>=float(g.events.get("guardian_attack",0)):
		g.events.guardian_attack=g.realm_time+8
		for i in range(6):
			var p=g.player.position+Vector3.RIGHT.rotated(Vector3.UP,i*TAU/7+g.realm_time)*6
			g.warn_at(p,2.2,1.8,22+g.realm*8,"void")
			if g.coop.active: g.coop.broadcast({"type":"hazard","realm":g.realm,"position":g.coop.array(p),"radius":2.2,"delay":1.8,"damage":22+g.realm*8,"style":"void"})

static func defeated(g,enemy):
	if enemy.get("guardian",false):
		g.events.guardian_defeated=true;g.gate.get_meta("marker").text="ENTER PORTAL"
		announce(g,"ISLAND LIBERATED","Return to the portal · "+("Final victory awaits" if g.realm==2 else "Your build continues into the next world"))
	elif state(g)=="ready":
		g.gate.get_meta("marker").text="SUMMON GUARDIAN";announce(g,"THE PORTAL AWAKENS","Follow the gold beacon and summon this island's guardian")

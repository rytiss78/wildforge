extends RefCounted

const TARGET_SECONDS=300.0
const REFERENCE_DPS=300.0
const HEALTH_MULTIPLIER=4.0 # Latest requested boss-health increase; duration needs real build playtests.

static func setup(g):
	g.events.final_arena=true;g.events.final_defeated=false
	g.gate.visible=false;g.player.position=Vector3(0,g.world.height_at(0,28)+1,28)
	g.world.ensure_ground(g.player.position);g.spawn_clock=99999
	if g.coop.active and not g.coop.hosting: return
	g.spawn_enemy(1,true,Vector3(0,g.world.height_at(0,-14),-14),true)
	if g.enemies.is_empty(): push_error("Final arena boss could not spawn");return
	var enemy=g.enemies[-1]
	var party_size=maxi(1,g.coop.members.size()+1) if g.coop.active else 1
	enemy.maxHp=TARGET_SECONDS*REFERENCE_DPS*HEALTH_MULTIPLIER*(1+.65*(party_size-1));enemy.hp=enemy.maxHp
	enemy.node.rotation.y=PI
	enemy.guardian=true;enemy.attack=4;enemy.attack_cycle=0;enemy.freeze=3;enemy.contact=3
	g.events.final_boss_hp=enemy.maxHp

static func attack(g,enemy):
	var cycle=int(enemy.get("attack_cycle",0))%4;enemy.attack_cycle=cycle+1
	var origin=enemy.node.position;var target=g.coop.target(origin).position
	var forward=target-origin;forward.y=0;var target_distance=clampf(forward.length(),18,48);forward=forward.normalized()
	var right=forward.cross(Vector3.UP);var marks=[];var damage=105.0;var style="annihilation"
	if cycle==0:
		for row in range(2):
			for i in range(5):marks.append([origin+forward.rotated(Vector3.UP,(i-2)*.18)*(target_distance-4+row*8),3.1,1.8+row*.4])
	elif cycle==1:
		damage=95;style="orbital"
		for ring in range(3):
			for i in range(12):
				if i in [2,3]:continue
				marks.append([origin+Vector3.RIGHT.rotated(Vector3.UP,i*TAU/12+enemy.attack_cycle*.3)*(16+ring*13),3.7,2.2+ring*.5])
	elif cycle==2:
		damage=120
		for i in range(7):marks.append([target+right*(i-3)*5.5+forward*(2 if i%2==0 else -2),3.4,1.6+i*.22])
	else:
		damage=110
		for lane in [-1,0,1]:
			for i in range(5):marks.append([origin+forward*(14+i*10)+right*lane*8,3.0,2.0+i*.18])
	for mark in marks:
		# Keep every impact on playable ground, including when the titan approaches the rim.
		var flat=Vector2(mark[0].x,mark[0].z)
		if flat.length()>64:flat=flat.normalized()*64;mark[0].x=flat.x;mark[0].z=flat.y
		g.warn_at(mark[0],mark[1],mark[2],damage,style)
		if g.coop.active:g.coop.broadcast({"type":"hazard","realm":g.realm,"position":CoopSession.array(mark[0]),"radius":mark[1],"delay":mark[2],"damage":damage,"style":style})
	enemy.node.get_meta("rig").attack=2;enemy.recovery=g.realm_time+2.6;enemy.attack=7.5 if enemy.phase==1 else 6.0

static func defeated(g):
	g.events.final_defeated=true;g.events.eclipse=true;g.events.eclipse_started=g.realm_time;g.events.eclipse_stage=0
	g.spawn_clock=0
	g.Journey.announce(g,"ENDLESS ECLIPSE","The observatory is silent. Survive until the last light falls.")

static func tick(g):
	if g.coop.active and not g.coop.hosting: return
	if not g.events.get("final_defeated",false): return
	g.events.eclipse=true
	var stage=1+int((g.realm_time-float(g.events.get("eclipse_started",g.realm_time)))/30)
	if stage>int(g.events.get("eclipse_stage",0)):
		g.events.eclipse_stage=stage
		for enemy in g.enemies: EclipseCorruption.apply(enemy,stage)
		g.events.swarm_until=g.realm_time+30;g.events.wave_active=true;g.events.wave_budget=60+stage*10

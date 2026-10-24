extends RefCounted

const TARGET_SECONDS=300.0
const REFERENCE_DPS=300.0
# 4.0 was the requested fourfold increase. Evolved builds (Phase D) then killed
# him in 2-12 minutes in bot runs, against 17 before; 6.0 restores a long fight.
# 7.5 (October 24): after the weapon-damage fixes half the bots that reached him
# still won; the target is about 40%.
# 37.5 (October 24, user request): five times the Colossus's health.
const HEALTH_MULTIPLIER=37.5
const INTRO_SECONDS=3.6
# The final boss is the Ashen Colossus (ColossusFight, ColossusRig): three phases.
const PHASE_NAMES=ColossusFight.PHASES

static func setup(g):
	g.events.final_arena=true;g.events.final_defeated=false
	g.gate.visible=false;g.player.position=Vector3(0,g.world.height_at(0,28)+1,28)
	g.world.ensure_ground(g.player.position);g.spawn_clock=99999
	g.events.final_intro_clock=0.0;g.events.final_intro=true;g.events.final_rift_time=14.0;g.events.final_cracks=[]
	g.world.environment.ambient_light_energy=.12
	g.world.environment.adjustment_brightness=.68
	make_cracks(g)
	if g.coop.active and not g.coop.hosting: return
	g.spawn_enemy(1,true,Vector3(0,g.world.height_at(0,-14),-14),true)
	if g.enemies.is_empty(): push_error("Final arena boss could not spawn");return
	var enemy=g.enemies[-1]
	var party_size=maxi(1,g.coop.members.size()+1) if g.coop.active else 1
	enemy.maxHp=TARGET_SECONDS*REFERENCE_DPS*HEALTH_MULTIPLIER*(1+.65*(party_size-1));enemy.hp=enemy.maxHp
	enemy.node.rotation.y=PI
	enemy.final_ground_y=enemy.node.position.y;enemy.node.position.y-=11;enemy.node.scale=Vector3.ONE*.08
	enemy.colossus_phase=0;enemy.guardian=true;enemy.attack=INTRO_SECONDS+1.5;enemy.freeze=INTRO_SECONDS;enemy.contact=INTRO_SECONDS
	g.events.final_boss_hp=enemy.maxHp
	phase_changed(g,enemy,0,false)

static func make_cracks(g):
	var material=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.albedo_color=Color(1.0,.10,.025,.96)
	material.emission_enabled=true;material.emission=Color("ff2817");material.emission_energy_multiplier=4.0
	for i in range(32):
		var angle=TAU*float(i)/32.0+g.rules.rng.randf_range(-.11,.11)
		var radius=g.rules.rng.randf_range(12,52);var length=g.rules.rng.randf_range(3,10)
		var point=Vector3(cos(angle)*radius,0,sin(angle)*radius);point.y=g.world.height_at(point.x,point.z)+.045
		var crack=MeshInstance3D.new();var mesh=BoxMesh.new();mesh.size=Vector3(g.rules.rng.randf_range(.18,.34),.08,length);crack.mesh=mesh
		crack.position=point;crack.rotation.y=angle+g.rules.rng.randf_range(-.7,.7);crack.material_override=material.duplicate();crack.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.world.add_child(crack);g.events.final_cracks.append(crack)

static func phase_changed(g,enemy,phase: int,replicate: bool=true):
	g.boss_phases_reached=maxi(int(g.boss_phases_reached),clampi(phase,0,2)+1)
	var phase_name=PHASE_NAMES[clampi(phase,0,PHASE_NAMES.size()-1)]
	var body=ColossusFight.rig(enemy)
	if body!=null: body.roar()
	if replicate and g.coop.active and g.coop.hosting: broadcast_phase(g,enemy,phase,phase_name,0)
	return phase_name

static func broadcast_phase(g,enemy,phase: int,phase_name: String,index: int):
	if g.coop.active and g.coop.hosting: g.coop.broadcast({"type":"boss_phase","realm":g.realm,"phase":phase,"name":phase_name,"index":index,"position":CoopSession.array(enemy.node.position)})

static func broadcast_intro(g):
	for enemy in g.enemies:
		if enemy.get("boss_id",-1)==8 and not enemy.dead:
			broadcast_phase(g,enemy,0,PHASE_NAMES[0],0);return

# The old Baron's four mark volleys, kept for reference; the Colossus fights
# through ColossusFight.attack.
static func attack(g,enemy):
	var cycle=int(enemy.get("attack_cycle",0))%4;enemy.attack_cycle=cycle+1
	var origin=enemy.node.position;var target_info=g.coop.target(origin);var target=target_info.position
	var target_id=int(target_info.id);var target_name=g.coop.player_name_for(target_id)
	if g.coop.active:
		g.coop.set_boss_focus(target_id,target_name)
		if g.coop.hosting:g.coop.broadcast({"type":"boss_focus","realm":g.realm,"player_id":target_id,"name":target_name})
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
	g.events.final_ceremony=true;g.events.final_ceremony_until=g.realm_time+3.5;g.events.final_ceremony_announced=false
	g.events.eclipse_started=g.events.final_ceremony_until;g.spawn_clock=99999
	g.Journey.announce(g,"THE COLOSSUS FALLS","The Red Moon cracks beneath it.")
	CombatInk.wave(g,Vector3(0,g.world.height_at(0,0)+.2,0),58,Color("ffd16c"))
	for i in range(8):
		var x=cos(i*TAU/8)*16;var z=sin(i*TAU/8)*16
		g.burst(Vector3(x,g.world.height_at(x,z)+1,z),Color("ffca66"),12)
	g.hit_shake=1.0;g.sound.effect("horn",g.player.position)

static func tick(g):
	var replica=g.coop.active and not g.coop.hosting
	var titan={}
	for enemy in g.enemies:
		if enemy.get("boss_id",-1)==8 and not enemy.dead:titan=enemy;break
	if g.events.get("final_intro",false):
		g.events.final_intro_clock+=.016
		var progress=clampf(g.events.final_intro_clock/INTRO_SECONDS,0,1);var eased=progress*progress*(3-2*progress)
		g.world.environment.ambient_light_energy=lerpf(.12,.36,eased)
		g.world.environment.adjustment_brightness=lerpf(.68,1.0,eased)
		if not replica and not titan.is_empty():
			var ground=float(titan.get("final_ground_y",titan.node.position.y+11))
			titan.node.position.y=lerpf(ground-11,ground,eased);titan.node.scale=Vector3.ONE*lerpf(.08,1.0,eased)
		if progress>=1:
			g.events.final_intro=false;g.world.environment.ambient_light_energy=.36;g.world.environment.adjustment_brightness=1.0
			g.hud.tell("THE ASHEN COLOSSUS RISES",3)
			var body=ColossusFight.rig(titan) if not titan.is_empty() else null
			if body!=null: body.play("roar",.9,1.4,.9)
	if replica:return
	if g.events.get("final_defeated",false):
		if g.events.get("final_ceremony",false) and g.realm_time>=float(g.events.final_ceremony_until):
			g.events.final_ceremony=false;g.events.final_ceremony_announced=true;g.spawn_clock=0
			g.Journey.announce(g,"ENDLESS ECLIPSE","The Colossus has fallen. Survive until the last light falls.")
			for crack in g.events.get("final_cracks",[]):
				if is_instance_valid(crack) and crack.material_override is StandardMaterial3D:
					crack.material_override.albedo_color=Color(1,.62,.16,.96);crack.material_override.emission=Color("ffc357");crack.material_override.emission_energy_multiplier=4.0
		g.events.eclipse=true
		if not g.events.get("final_ceremony",false):
			var stage=1+int((g.realm_time-float(g.events.get("eclipse_started",g.realm_time)))/30)
			if stage>int(g.events.get("eclipse_stage",0)):
				g.events.eclipse_stage=stage
				for enemy in g.enemies:EclipseCorruption.apply(enemy,stage)
				g.events.swarm_until=g.realm_time+30;g.events.wave_active=true;g.events.wave_budget=60+stage*10
		return
	if not titan.is_empty() and not g.events.get("final_intro",false): ColossusFight.tick(g,titan)
	if g.events.get("final_intro",false) or not titan.is_empty():return
	if g.realm_time>=float(g.events.get("final_rift_time",14.0)):
		erupt(g)

static func erupt(g):
	g.events.final_rift_time=g.realm_time+19.0
	g.hud.tell("GROUND BREACH · MOVE BETWEEN THE RED MARKS",3)
	for i in range(10):
		var radius=17.0+(i%3)*9.0;var angle=TAU*float(i)/10.0+g.realm_time*.11
		var p=Vector3(cos(angle)*radius,0,sin(angle)*radius);p.y=g.world.height_at(p.x,p.z)
		g.warn_at(p,2.7,2.6,48,"lava")
		if g.coop.active:g.coop.broadcast({"type":"hazard","realm":g.realm,"position":CoopSession.array(p),"radius":2.7,"delay":2.6,"damage":48,"style":"lava"})

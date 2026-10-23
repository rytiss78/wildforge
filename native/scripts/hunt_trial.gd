extends RefCounted

static func shrine(g): return g.get_node_or_null("HuntShrine")
static func state(g) -> String: return str(g.events.get("hunt_state","idle"))

static func setup(g):
	var old=shrine(g)
	if old: g.remove_child(old);old.queue_free()
	var node=Node3D.new();node.name="HuntShrine";g.add_child(node)
	node.position=Vector3(60,g.world.height_at(60,-35),-35)
	build_totem(node)
	var title=Label3D.new();title.name="Title";title.text="HUNTER'S OATH";title.font_size=34;title.pixel_size=.013;title.position.y=5.6;title.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate=Color("f3d9ff");title.outline_modulate=Color("1d0f22");title.outline_size=8;node.add_child(title)
	g.events.hunt_state="idle";g.events.hunt_ids=[];g.events.hunt_kills=[]

# A hunter's totem: a carved pole crowned with a horned beast skull, crossed
# spears, two fire braziers, and a violet beacon that shows while a hunt can
# be started, so the shrine reads as "hunt" from across the island.
static func build_totem(node: Node3D):
	var bone=Color("ead9b8");var wood=Color("5a3a26");var dark=Color("1c1014");var violet=Color("c77dff")
	var base=CylinderMesh.new();base.top_radius=1.5;base.bottom_radius=1.9;base.height=.35
	ToonArt.part(node,base,Color("3a2c33"),Vector3(0,.18,0))
	ToonArt.tube(node,wood,Vector3(0,1.9,0),.28,.36,3.2)
	for y in [1.0,1.9,2.8]: ToonArt.tube(node,Color("3b2418"),Vector3(0,y,0),.4,.4,.12)
	# Beast skull with sockets and two swept horns.
	ToonArt.ball(node,bone,Vector3(0,3.85,.05),Vector3(.62,.52,.7))
	ToonArt.ball(node,bone,Vector3(0,3.62,.42),Vector3(.34,.26,.36))
	for side in [-1,1]:
		ToonArt.ball(node,dark,Vector3(side*.2,3.92,.5),Vector3(.13,.12,.06))
		for i in range(3):
			var horn=CylinderMesh.new();horn.top_radius=.03+.04*(2-i);horn.bottom_radius=.07+.04*(2-i);horn.height=.5;horn.radial_segments=8
			var part=ToonArt.part(node,horn,bone.darkened(.1*i),Vector3(side*(.42+i*.3),4.05+i*.22,-.05+i*.08));part.rotation.z=-side*(.9-i*.35)
	# Crossed spears with red tufts.
	for side in [-1,1]:
		var shaft=ToonArt.tube(node,Color("6b4a30"),Vector3(side*.35,1.6,.55),.035,.035,2.9);shaft.rotation.z=side*.42
		var tip=CylinderMesh.new();tip.top_radius=0;tip.bottom_radius=.08;tip.height=.32;tip.radial_segments=6
		var head=ToonArt.part(node,tip,Color("b9c2c8"),Vector3(side*.95,2.95,.55));head.rotation.z=side*.42
		ToonArt.ball(node,Color("b8332c"),Vector3(side*.86,2.72,.55),Vector3(.12,.16,.12))
	# Two braziers.
	for side in [-1,1]:
		ToonArt.tube(node,Color("2d2328"),Vector3(side*1.35,.55,.2),.32,.22,.7)
		var flame=CylinderMesh.new();flame.top_radius=0;flame.bottom_radius=.26;flame.height=.6;flame.radial_segments=7
		var fire=ToonArt.part(node,flame,Color("ff8a2a"),Vector3(side*1.35,1.15,.2));fire.name="Flame"+("L" if side<0 else "R")
		var light=OmniLight3D.new();light.light_color=Color("ff9a4a");light.light_energy=1.4;light.omni_range=5.0;light.position=Vector3(side*1.35,1.5,.2);node.add_child(light)
	# Beacon: visible while the hunt waits to be started.
	var beam=MeshInstance3D.new();var shaft_mesh=CylinderMesh.new();shaft_mesh.top_radius=.3;shaft_mesh.bottom_radius=.6;shaft_mesh.height=1.0;shaft_mesh.cap_top=false;shaft_mesh.cap_bottom=false
	beam.mesh=shaft_mesh;beam.scale=Vector3(1,50,1);beam.position.y=29;beam.name="Beacon"
	var paint=StandardMaterial3D.new();paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;paint.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.blend_mode=BaseMaterial3D.BLEND_MODE_ADD;paint.cull_mode=BaseMaterial3D.CULL_DISABLED;paint.albedo_color=Color(violet,.3)
	beam.material_override=paint;beam.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;beam.visible=false;node.add_child(beam)

# The big centre-screen card used for hunt outcomes (like island announcements,
# without the horn and shake).
static func announce(g,title: String,detail: String,sound_id: String):
	g.events.announcement=title;g.events.announcement_detail=detail;g.events.announcement_until=g.elapsed+5
	g.sound.effect(sound_id,g.player.position)

static func hint(g) -> String:
	var node=shrine(g)
	if node==null or g.player.position.distance_to(node.position)>4: return ""
	if state(g)=="idle": return "HUNT AWAKENS AT 1:00" if g.realm_time<60 else "E / X · HUNT 3 MARKED FOES IN 45 s · RARE CHEST"
	return "HUNT COMPLETE · FREE REWARD CHEST" if state(g)=="complete" else "HUNT ENDED" if state(g)=="failed" else "HUNT ACTIVE · FOLLOW VIOLET MARKS"

static func interact(g) -> bool:
	if g.update.downed or hint(g).is_empty(): return false
	if g.coop.active and not g.coop.hosting:
		g.coop.send_to(g.coop.owner_id,g.coop.pose())
		g.coop.send_to(g.coop.owner_id,{"type":"hunt_start","realm":g.realm})
	else: activate(g,g.player.position)
	return true

static func activate(g,position: Vector3) -> bool:
	var node=shrine(g)
	if node==null or state(g)!="idle" or g.realm_time<60 or position.distance_to(node.position)>4 or g.mode!="playing": return false
	var ids=[]
	var rng=RandomNumberGenerator.new();rng.seed=g.seed_value+int(g.realm_time)
	for i in range(3):
		for attempt in range(12):
			var angle=TAU*float(i)/3.0+rng.randf_range(-.35,.35)
			var dist=rng.randf_range(85,115)
			var spawn_pos=node.position+Vector3(cos(angle)*dist,0,sin(angle)*dist)
			spawn_pos.y=g.world.height_at(spawn_pos.x,spawn_pos.z)
			var before=g.enemies.size();g.spawn_enemy(0,false,spawn_pos)
			if g.enemies.size()<=before: continue
			var enemy=g.enemies[-1];var actual=Vector2(enemy.node.position.x-node.position.x,enemy.node.position.z-node.position.z).length()
			if actual<80 or actual>120:
				enemy.node.queue_free();g.enemies.erase(enemy);continue
			enemy.maxHp*=2.2;enemy.hp=enemy.maxHp;enemy.damage*=1.2;enemy.contact=2.0;enemy.freeze=1.5;ids.append(enemy.net_id);break
	if ids.size()!=3:
		for enemy in g.enemies:
			if enemy.net_id in ids: enemy.dead=true;enemy.node.queue_free()
		g.hud.tell("Hunt needs open ground. Try again.");return false
	g.events.hunt_ids=ids;g.events.hunt_kills=[];g.events.hunt_deadline=g.realm_time+45;g.events.hunt_state="active"
	g.events.announcement="THE HUNT BEGINS";g.events.announcement_detail="Three marked foes · 45 seconds · follow the violet marks";g.events.announcement_until=g.elapsed+4
	g.sound.effect("horn",position)
	return true

static func defeated(g,enemy):
	if g.coop.active and not g.coop.hosting: return
	if state(g)!="active" or g.realm_time>float(g.events.hunt_deadline): return
	if enemy.net_id not in g.events.hunt_ids or enemy.net_id in g.events.hunt_kills: return
	g.events.hunt_kills.append(enemy.net_id)
	if g.events.hunt_kills.size()==3: g.events.hunt_state="complete"

static func tick(g):
	var node=shrine(g)
	if node==null: return
	if (not g.coop.active or g.coop.hosting) and state(g)=="active" and g.realm_time>float(g.events.hunt_deadline): g.events.hunt_state="failed"
	var current=state(g)
	var ready=current=="idle" and g.realm_time>=60
	node.get_node("Beacon").visible=ready
	for name in ["FlameL","FlameR"]:
		var flame=node.get_node_or_null(name)
		if flame: flame.scale=Vector3.ONE*(1.0+sin(Time.get_ticks_msec()*.012+(0.0 if name=="FlameL" else 2.0))*.15)*(1.4 if current=="active" else 1.0)
	g.sound.hunt_music(float(g.events.get("hunt_deadline",0))-g.realm_time if current=="active" else -1.0)
	node.get_node("Title").text={"idle":"HUNTER'S OATH","active":"HUNT IN PROGRESS","complete":"OATH FULFILLED","failed":"OATH EXPIRED"}[current]
	for enemy in g.enemies:
		if enemy.dead: continue
		var marked=current=="active" and enemy.net_id in g.events.get("hunt_ids",[])
		var marker=enemy.node.get_node_or_null("HuntMark")
		if marked and marker==null:
			marker=Label3D.new();marker.name="HuntMark";marker.text="◆ HUNT ◆";marker.font_size=34;marker.pixel_size=.016;marker.modulate=Color("e6b3ff");marker.billboard=BaseMaterial3D.BILLBOARD_ENABLED;marker.no_depth_test=true;enemy.node.add_child(marker);marker.position.y=enemy.height+.55
		if marker: marker.visible=marked
	if current=="complete" and not node.has_meta("reward_spawned"):
		node.set_meta("reward_spawned",true)
		var p=node.position+Vector3(3,0,0);p.y=g.world.height_at(p.x,p.z)
		g.make_chest(p,true,true)
		announce(g,"HUNT COMPLETE","All three marked foes fell · a rare reward waits at the shrine","hunt_win")
	if current=="failed" and not node.has_meta("failure_shown"):
		node.set_meta("failure_shown",true)
		announce(g,"HUNT FAILED","The marked foes escaped · you keep what you earned","hunt_fail")

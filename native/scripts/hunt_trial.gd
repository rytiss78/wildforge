extends RefCounted

static func shrine(g): return g.get_node_or_null("HuntShrine")
static func state(g) -> String: return str(g.events.get("hunt_state","idle"))

static func setup(g):
	var old=shrine(g)
	if old: g.remove_child(old);old.queue_free()
	var node=Node3D.new();node.name="HuntShrine";g.add_child(node)
	node.position=Vector3(60,g.world.height_at(60,-35),-35)
	var base=CylinderMesh.new();base.top_radius=1.4;base.bottom_radius=1.8;base.height=.35
	ToonArt.part(node,base,Color("544764"),Vector3(0,.18,0))
	for side in [-1,1]:
		ToonArt.part(node,BoxMesh.new(),Color("ad80ca"),Vector3(side*.95,1.3,0),Vector3(.3,2.4,.3))
	var ring=TorusMesh.new();ring.inner_radius=.55;ring.outer_radius=.72
	var halo=ToonArt.part(node,ring,Color("eed185"),Vector3(0,2.1,0));halo.rotation.x=PI/2
	var title=Label3D.new();title.name="Title";title.text="HUNTER'S OATH";title.font_size=30;title.pixel_size=.012;title.position.y=3;title.billboard=BaseMaterial3D.BILLBOARD_ENABLED;node.add_child(title)
	g.events.hunt_state="idle";g.events.hunt_ids=[];g.events.hunt_kills=[]

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
	for i in range(3):
		var before=g.enemies.size();g.spawn_enemy(12+i*3,false,node.position)
		if g.enemies.size()>before:
			var enemy=g.enemies[-1];enemy.maxHp*=2.2;enemy.hp=enemy.maxHp;enemy.damage*=1.2;enemy.contact=2.0;enemy.freeze=1.5;ids.append(enemy.net_id)
	if ids.size()!=3:
		for enemy in g.enemies:
			if enemy.net_id in ids: enemy.dead=true;enemy.node.queue_free()
		g.hud.tell("Hunt needs open ground. Try again.");return false
	g.events.hunt_ids=ids;g.events.hunt_kills=[];g.events.hunt_deadline=g.realm_time+45;g.events.hunt_state="active"
	g.hud.tell("HUNT STARTED · THREE MARKED FOES · 45 SECONDS",4);g.sound.effect("horn",position)
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
		g.make_chest(p,true);g.hud.tell("HUNT WON · FREE RARE+ CHEST AT THE SHRINE",5);g.sound.effect("level",p)
	if current=="failed" and not node.has_meta("failure_shown"):
		node.set_meta("failure_shown",true);g.hud.tell("HUNT EXPIRED · KEEP YOUR EARNED LOOT",4)

extends Node3D
# Local presentation with host-authoritative optional events and rescue channels.
var game
var banish_charges=1
var focused_offer=0
var downed=false
var rescue_hold=false
var rescue_progress={}
var downed_ids={}
var merchant: Node3D
var merchant_position=Vector3.ZERO
var stock=[]
var purchased={}
var pending_purchase=-1
var beacon: Node3D
var beacon_position=Vector3.ZERO
var beacon_state="idle"
var beacon_seconds=0.0
var beacon_budget=180
var beacon_claimed={}
var beacon_absent=0.0
var pings=[]
var ping_clock=0.0
var quip_clock=0.0
var quip_times={}
var run_damage=0.0
var party_damage=0.0
var rescue_interrupt_until=0.0
var run_xp=0.0
var run_coins=0.0
var memories={}
var mimic={}
var mimic_clock=0.0

func setup(owner_game): game=owner_game

func new_run():
	game.rules.banished.clear();downed=false;downed_ids.clear();rescue_progress.clear()
	run_damage=0;party_damage=0;run_xp=0;run_coins=0;memories.clear();quip_times.clear();quip_clock=0

func realm_started():
	if downed: game.hp=game.stats.maxHp*.4;game.invulnerable=3
	for node in [merchant,beacon]:
		if is_instance_valid(node): node.queue_free()
	merchant=null;beacon=null;stock.clear();purchased.clear();beacon_claimed.clear()
	banish_charges=1;pending_purchase=-1;downed=false;downed_ids.clear();rescue_progress.clear()
	beacon_state="idle";beacon_seconds=0;beacon_absent=0;mimic.clear();pings.clear()
	var rng=RandomNumberGenerator.new();rng.seed=game.seed_value+game.realm*839
	var angle=rng.randf()*TAU
	merchant_position=Vector3(cos(angle)*230,0,sin(angle)*230)
	merchant_position.y=game.world.height_at(merchant_position.x,merchant_position.z)
	merchant=Node3D.new();merchant.position=merchant_position;add_child(merchant)
	ToonArt.tube(merchant,Color("bd8269"),Vector3(0,.7,0),.55,.7,1.4)
	ToonArt.ball(merchant,Color("efd4a1"),Vector3(0,1.8,0),Vector3(.9,.8,.8))
	ToonArt.tube(merchant,Color("a378c8"),Vector3(0,2.3,0),.1,.75,.65)
	for x in [-.65,.65]: ToonArt.ball(merchant,Color("edbf56"),Vector3(x,1.2,0),Vector3(.5,.3,.5))
	caption(merchant,"WANDERING MERCHANT",2.9)
	# Catalog-only stock; each purchase has one positive bonus. Different realms visit once.
	var pools=game.rules.data.loot.filter(func(i):return i.kind=="item")
	for i in range(3):
		var item=pools[rng.randi_range(0,pools.size()-1)].duplicate(true)
		item.effects=[item.effects[0]];item.tier=1;item.strength=2.0;item.effects[0].amount*=2
		item.name=item.title
		stock.append(item)
	var weapon=game.rules.data.weapons[rng.randi_range(0,game.rules.data.weapons.size()-1)].duplicate(true)
	weapon.kind="weapon";weapon.tier=1;weapon.strength=2.0;stock[0]=weapon
	angle+=1.9;beacon_position=Vector3(cos(angle)*310,0,sin(angle)*310)
	beacon_position.y=game.world.height_at(beacon_position.x,beacon_position.z)
	beacon=Node3D.new();beacon.position=beacon_position;add_child(beacon)
	ToonArt.tube(beacon,Color("617886"),Vector3(0,1.2,0),.2,.5,2.4)
	ToonArt.ball(beacon,Color("8be7ef"),Vector3(0,2.6,0),Vector3(.8,.8,.8))
	caption(beacon,"SUPPLY SIGNAL",3.5)
	if game.chests.size()>2:
		var chest=game.chests[2];chest.mimic=true

func caption(node: Node3D,text: String,height: float):
	var label=Label3D.new();label.text=text;label.font_size=24;label.position.y=height
	label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.no_depth_test=false;node.add_child(label)

func note(key: String):
	memories[key]=int(memories.get(key,0))+1;game.achievement_event(key)

func recap() -> String:
	var powers=[]
	for weapon in game.equipped: powers.append("%s %d" % [weapon.name,weapon.rank])
	return "YOUR RUN · %d damage · %d XP · %d coins found\nPARTY DAMAGE · %d\n%d regions · %d landmarks · %s\n%s" % [run_damage,run_xp,run_coins,party_damage,game.biome_seen.size(),game.visited_ruins.size(),", ".join(powers)," · ".join(memories.keys())]

func banish(index: int):
	if game.mode!="offer" or banish_charges<=0 or index<0 or index>=game.offers.size(): return
	var item=game.offers[index]
	if item.kind=="weapon": game.hud.tell("Choose a bonus card to banish");return
	var key=item.effects[0].key;game.rules.banished.append(key);banish_charges-=1
	game.offers=game.rules.offers(game.offer_kind,game.stats.luck,game.offer_elite,game.stats,game.equipped)
	game.hud.show_offers(game.offers,game.offer_source,false);game.hud.tell("Banished "+game.rules.data.labels.get(key,key)+" for this run")

func hint() -> String:
	if downed:
		var seconds=float(rescue_progress.get(game.coop.local_id,rescue_progress.get(str(game.coop.local_id),0)))
		return "DOWNED · RESCUE %.1f / 3 s · FRIEND HOLDS E / X" % seconds
	if rescue_target(game.player.position,game.coop.local_id)>0: return "HOLD E / X · RESCUE FRIEND · 3 s"
	if is_instance_valid(merchant) and game.player.position.distance_to(merchant.position)<3.5: return "E / X · WANDERING MERCHANT"
	if is_instance_valid(beacon) and game.player.position.distance_to(beacon_position)<4 and beacon_state=="idle": return "E / X · ACTIVATE SUPPLY · DEFEND 25 s"
	if beacon_state=="defending": return "SUPPLY · %d s · STAY WITHIN 14 m" % ceili(25-beacon_seconds)
	return ""

func interact() -> bool:
	if downed or rescue_target(game.player.position,game.coop.local_id)>0: return true
	if is_instance_valid(merchant) and game.player.position.distance_to(merchant.position)<3.5: merchant_menu();return true
	if is_instance_valid(beacon) and game.player.position.distance_to(beacon_position)<4 and beacon_state=="idle":
		if game.coop.active and not game.coop.hosting: game.coop.send_to(game.coop.owner_id,{"type":"big_action","action":"beacon","realm":game.realm})
		else: activate_beacon()
		return true
	return false

func merchant_menu():
	quip("discovery")
	game.mode="merchant"
	var box=game.hud.open("WANDERING MERCHANT","One positive purchase per offer · coins stay yours")
	for i in range(stock.size()):
		var item=merchant_item(i,game.equipped)
		var text=item.name+" · "+(WeaponDetails.describe(item.id) if item.kind=="weapon" else game.rules.describe(item.effects[0]))
		var price=merchant_price(i)
		var button=game.hud.button(text+" · %d COINS" % price,func():purchase(i))
		button.disabled=game.gold<price or purchased.has(str(game.coop.local_id)+":"+str(i)) or pending_purchase>=0
		box.add_child(button)
	box.add_child(game.hud.button("LEAVE",game.hud.close))
	for control in box.get_children():
		if control is Button and not control.disabled: control.grab_focus();break

func merchant_price(i: int) -> int: return 35+game.realm*15+i*10

func merchant_item(i: int,weapons: Array) -> Dictionary:
	var item=stock[i].duplicate(true)
	if item.kind!="weapon" and game.rules.banished.has(item.effects[0].key):
		item=game.rules.data.weapons.filter(func(w):return w.id==game.hero.weapon)[0].duplicate(true);item.kind="weapon";item.tier=1;item.strength=2.0
	if item.kind=="weapon" and weapons.size()>=3 and not weapons.any(func(w):return w.id==item.id):
		item=game.rules.data.weapons.filter(func(w):return w.id==weapons[0].id)[0].duplicate(true)
		item.kind="weapon";item.tier=1;item.strength=2.0
	return item

func purchase(i: int):
	if game.mode!="merchant" or pending_purchase>=0 or i<0 or i>=stock.size() or game.gold<merchant_price(i): return
	if game.coop.active and not game.coop.hosting:
		pending_purchase=i
		# Position and funds must arrive before the transaction on the reliable channel.
		game.coop.send_to(game.coop.owner_id,game.coop.pose())
		game.coop.send_to(game.coop.owner_id,{"type":"big_action","action":"purchase","index":i,"realm":game.realm});merchant_menu();return
	grant_purchase(i)

func grant_purchase(i: int):
	if i<0 or i>=stock.size(): return
	var key=str(game.coop.local_id)+":"+str(i)
	pending_purchase=-1
	if purchased.has(key) or game.gold<merchant_price(i): return
	purchased[key]=true;game.gold-=merchant_price(i)
	grant(merchant_item(i,game.equipped));note("MERCHANT");merchant_menu()

func grant(item: Dictionary):
	if item.kind=="weapon": game.equip_weapon(item)
	else:
		var hp=game.stats.maxHp;game.rules.apply_effects(game.stats,item.effects)
		game.hp+=maxf(0,game.stats.maxHp-hp);game.owned.append(item)
		game.families[item.family]=int(game.families.get(item.family,0))+1
	game.hud.tell("+ "+item.name)

func activate_beacon():
	if beacon_state!="idle": return
	beacon_state="defending";beacon_seconds=0;beacon_absent=0;beacon_budget=180+game.realm*60
	game.hud.tell("SUPPLY WAVE · DEFEND THE SIGNAL",4);quip("discovery")

func award_beacon():
	var id=str(game.coop.local_id)
	if beacon_claimed.has(id): return
	beacon_claimed[id]=true;note("BEACON")
	game.hud.tell("SUPPLY SECURED · CHOOSE YOUR REWARD",3)
	game.offer_kind="item";game.offer_elite=true;game.offer_rerolls=0;game.offer_source="beacon"
	game.offers=game.rules.offers("item",game.stats.luck,true,game.stats,game.equipped)
	game.mode="offer";game.hud.show_offers(game.offers,"beacon")

func start_mimic(chest: Dictionary) -> bool:
	if not chest.get("mimic",false) or chest.get("mimic_revealed",false): return false
	# Reveal before payment; the real paid reward remains at the original position.
	chest.mimic_revealed=true;note("MIMIC");quip("discovery")
	var node=Node3D.new();node.position=chest.node.position;add_child(node)
	ToonArt.ball(node,Color("d8ad5f"),Vector3(0,.6,0),Vector3(1.3,.9,1))
	for x in [-.3,.3]:
		ToonArt.ball(node,Color("fff8da"),Vector3(x,.8,-.48),Vector3(.3,.35,.2))
		ToonArt.ball(node,Color("574536"),Vector3(x,.8,-.59),Vector3(.13,.18,.06))
	caption(node,"NOPE!",1.5);mimic={"node":node,"life":5.0,"drop":0.0}
	game.hud.tell("MIMIC! · NO CHARGE · THE REAL BOX STAYS HERE",4)
	return true

func send_ping():
	if game.mode!="playing" or ping_clock>0: return
	ping_clock=2;note("PING")
	var p=game.player.position+Vector3.FORWARD.rotated(Vector3.UP,game.yaw)*12
	var label="DESTINATION"
	var chest=game.chests.filter(func(c):return not c.opened and c.node.position.distance_to(p)<12)
	var enemy=game.nearest_enemy(p,8)
	if not chest.is_empty(): p=chest[0].node.position;label="TREASURE"
	elif not enemy.is_empty(): p=enemy.node.position;label="THREAT"
	p.y=game.world.height_at(p.x,p.z)
	var message={"type":"big_ping","position":CoopSession.array(p),"label":label,"actor":game.coop.local_id,"realm":game.realm}
	if game.coop.active and not game.coop.hosting: game.coop.send_to(game.coop.owner_id,message)
	else: show_ping(message);game.coop.broadcast(message)

func show_ping(message: Dictionary):
	if int(message.get("realm",-1))!=game.realm: return
	var p=CoopSession.vector(message.get("position",[]))
	if not p.is_finite(): return
	var marker=Node3D.new();marker.position=p;add_child(marker)
	caption(marker,str(message.get("label","DESTINATION")),3)
	var ring=TorusMesh.new();ring.inner_radius=.7;ring.outer_radius=1.0
	game.shape(ring,Color("edbf56"),marker,Vector3(0,.15,0),.3)
	pings.append({"position":p,"node":marker,"life":8.0})
	if pings.size()>8: pings[0].node.queue_free();pings.pop_front()

func rescue_target(p: Vector3,helper: int) -> int:
	for id in downed_ids:
		if int(id)==helper: continue
		var position=game.player.position if int(id)==game.coop.local_id else CoopSession.vector(game.coop.members.get(int(id),{}).get("position",[]))
		if p.distance_to(position)<3: return int(id)
	return 0

func knocked_down():
	if downed: return
	downed=true;game.hp=0;game.player.velocity=Vector3.ZERO
	game.melee_attacks.clear();game.avatar.finish_melee();game.avatar.body.rotation.z=.9
	game.hud.tell("DOWNED · FRIENDS CAN HOLD E / X TO RESCUE",6)
	if game.coop.hosting: downed_ids[game.coop.local_id]=true
	else: game.coop.send_to(game.coop.owner_id,{"type":"big_action","action":"down","realm":game.realm})

func revive(id: int):
	if not downed_ids.has(id): return
	downed_ids.erase(id);rescue_progress.erase(id)
	if id==game.coop.local_id: revived()
	else: game.coop.send_to(id,{"type":"big_revive","realm":game.realm})
	if game.coop.members.has(id): game.coop.members[id].hp=maxf(1,float(game.coop.members[id].get("stats",{}).get("maxHp",100))*.4)
	game.coop.broadcast({"type":"big_rescued","id":id,"realm":game.realm})

func revived():
	if not downed: return
	downed=false;game.hp=game.stats.maxHp*.4;game.invulnerable=3;game.avatar.body.rotation.z=0
	game.hud.tell("BACK ON YOUR FEET",4)

func host_tick(delta: float):
	for id in downed_ids.keys():
		if int(id)!=game.coop.local_id and not game.coop.members.has(int(id)): downed_ids.erase(id);rescue_progress.erase(id)
	var helpers=game.coop.members.duplicate(true);helpers[game.coop.local_id]={"position":CoopSession.array(game.player.position),"hp":game.hp,"rescue_hold":rescue_hold}
	var working={}
	for helper in helpers:
		var member=helpers[helper]
		if float(member.get("hp",0))<=0 or not member.get("rescue_hold",false) or game.elapsed<float(member.get("rescue_interrupt_until",0)): continue
		var target=rescue_target(CoopSession.vector(member.get("position",[])),int(helper))
		if target<=0: continue
		if working.has(target): continue
		working[target]=true
		rescue_progress[target]=float(rescue_progress.get(target,0))+delta
		if rescue_progress[target]>=3:
			revive(target)
			if int(helper)==game.coop.local_id: note("RESCUE")
			else: game.coop.send_to(int(helper),{"type":"big_memory","key":"RESCUE"})
	for id in rescue_progress.keys():
		if not working.has(id): rescue_progress.erase(id)
	if not downed_ids.is_empty() and helpers.values().all(func(m):return float(m.get("hp",0))<=0):
		game.coop.broadcast({"type":"finish","win":false});game.end_run(false)
	if beacon_state=="defending":
		var present=helpers.values().any(func(m):return float(m.get("hp",0))>0 and CoopSession.vector(m.get("position",[])).distance_to(beacon_position)<14)
		beacon_absent=0 if present else beacon_absent+delta
		beacon_seconds+=delta if present else 0
		if beacon_absent>6: beacon_state="failed";game.hud.tell("SUPPLY LOST · KEEP YOUR EARNED POWERS",4)
		elif beacon_seconds>=25:
			beacon_state="complete"
			for id in helpers:
				if float(helpers[id].get("hp",0))<=0: continue
				if int(id)==game.coop.local_id: award_beacon()
				else: game.coop.send_to(int(id),{"type":"big_beacon_reward","realm":game.realm})

func world_state() -> Dictionary:
	return {"downed":downed_ids.keys(),"rescue":rescue_progress,"beacon":beacon_state,"seconds":beacon_seconds,"party_damage":party_damage}

func apply_state(state: Dictionary):
	party_damage=float(state.get("party_damage",0))
	downed_ids.clear()
	for id in state.get("downed",[]): downed_ids[int(id)]=true
	rescue_progress=state.get("rescue",{});beacon_state=state.get("beacon","idle");beacon_seconds=float(state.get("seconds",0))

func receive(sender: int,message: Dictionary) -> bool:
	var type=str(message.get("type",""))
	if not type.begins_with("big_"): return false
	if game.coop.hosting:
		if not game.coop.members.has(sender) or int(message.get("realm",-1))!=game.realm: return true
		var member=game.coop.members[sender];var p=CoopSession.vector(member.get("position",[]))
		if type=="big_ping" and float(member.get("ping_time",-3))+2<=game.elapsed:
			var marker=CoopSession.vector(message.get("position",[]))
			if marker.is_finite() and marker.distance_to(p)<30:
				member.ping_time=game.elapsed;message.actor=sender;show_ping(message);game.coop.broadcast(message)
		elif type=="big_action":
			var action=message.get("action","")
			if action=="down": downed_ids[sender]=true;member.hp=0
			elif action=="beacon" and p.distance_to(beacon_position)<4 and float(member.get("hp",0))>0: activate_beacon()
			elif action=="purchase":
				var i=int(message.get("index",-1));var key=str(sender)+":"+str(i)
				if is_instance_valid(merchant) and p.distance_to(merchant.position)<4 and i>=0 and i<stock.size() and not purchased.has(key) and int(member.get("gold",0))>=merchant_price(i):
					purchased[key]=true;member.gold-=merchant_price(i);game.coop.send_to(sender,{"type":"big_purchase","index":i,"realm":game.realm})
				else: game.coop.send_to(sender,{"type":"big_purchase_rejected","realm":game.realm})
	else:
		if sender!=game.coop.owner_id: return true
		if type=="big_memory": note(str(message.key));return true
		if int(message.get("realm",-1))!=game.realm: return true
		if type=="big_damage": run_damage+=float(message.get("amount",0))
		elif type=="big_ping": show_ping(message)
		elif type=="big_revive": revived()
		elif type=="big_rescued": downed_ids.erase(int(message.id))
		elif type=="big_beacon_reward": award_beacon()
		elif type=="big_purchase": grant_purchase(int(message.index))
		elif type=="big_purchase_rejected": pending_purchase=-1;game.hud.tell("Purchase unavailable");merchant_menu()
	return true

func tick(delta: float):
	ping_clock=maxf(0,ping_clock-delta);quip_clock=maxf(0,quip_clock-delta)
	rescue_hold=Input.is_action_pressed("interact") and not downed and game.elapsed>=rescue_interrupt_until
	if not game.coop.active or game.coop.hosting: host_tick(delta)
	for ping in pings:
		ping.life-=delta
		if ping.life<=0: ping.node.queue_free()
	pings=pings.filter(func(p):return p.life>0)
	if is_instance_valid(merchant):
		# A small wandering orbit; host and clients use the same realm clock.
		merchant.position=merchant_position+Vector3(sin(game.realm_time*.06)*5,0,cos(game.realm_time*.06)*5)
		merchant.position.y=game.world.height_at(merchant.position.x,merchant.position.z)
	if not mimic.is_empty():
		mimic.life-=delta;mimic.drop-=delta
		var away=(mimic.node.position-game.player.position).normalized();away.y=0
		mimic.node.position+=away*delta*7;mimic.node.position.y=game.world.height_at(mimic.node.position.x,mimic.node.position.z)
		mimic.node.rotation.z=sin(game.elapsed*18)*.15
		if mimic.drop<=0: game.spawn_pickup(mimic.node.position+Vector3.UP,"gold",2);mimic.drop=.6
		if mimic.life<=0: mimic.node.queue_free();mimic.clear()

func quip(context: String):
	if quip_clock>0 or float(quip_times.get(context,-100))+90>game.elapsed: return
	quip_clock=45;quip_times[context]=game.elapsed
	var text={"discovery":"Well, that looks suspicious.","boss":"That one skipped leg day.","weapon":"Three hands. Still no pockets."}.get(context,"")
	game.hud.tell(game.hero.name+": "+text,3)
	game.sound.hero_quip(game.hero.id,context,game.player)

var effect_pool=[]
var shadow_mesh: PlaneMesh
var shadow_material: ShaderMaterial
var shadows=[]

func effect_node(mesh: Mesh,paint: Material,p: Vector3) -> MeshInstance3D:
	var node=effect_pool.pop_back() if not effect_pool.is_empty() else MeshInstance3D.new()
	if node.get_parent()==null: game.add_child(node)
	node.mesh=mesh;node.material_override=paint;node.position=p;node.scale=Vector3.ONE;node.rotation=Vector3.ZERO;node.visible=true
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;node.set_meta("pooled_effect",true)
	return node

func release_effect(node: Node3D):
	if node.get_meta("pooled_effect",false) and effect_pool.size()<160:
		node.visible=false;effect_pool.append(node)
	else: node.queue_free()

var shadow_batch: MultiMeshInstance3D
var shadow_clock=0.0
func contact_shadows():
	shadow_clock-=game.get_physics_process_delta_time()
	if shadow_clock>0: return
	shadow_clock=.1
	if shadow_batch==null:
		shadow_mesh=PlaneMesh.new();shadow_mesh.size=Vector2(1,1)
		shadow_material=ShaderMaterial.new();shadow_material.shader=preload("res://shaders/contact_shadow.gdshader")
		shadow_batch=MultiMeshInstance3D.new();var instances=MultiMesh.new();instances.transform_format=MultiMesh.TRANSFORM_3D
		instances.use_colors=true;instances.mesh=shadow_mesh;instances.instance_count=128;shadow_batch.multimesh=instances
		shadow_batch.material_override=shadow_material;shadow_batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(shadow_batch)
	var actors=[{"node":game.player,"radius":.7}]
	for enemy in game.enemies:
		if not enemy.dead and enemy.node.position.distance_to(game.player.position)<35: actors.append(enemy)
	for pickup in game.pickups:
		if pickup.settled and pickup.node.position.distance_to(game.player.position)<25: actors.append({"node":pickup.node,"radius":.25})
	if actors.size()>128: actors.resize(128)
	shadow_batch.multimesh.visible_instance_count=actors.size()
	for i in range(actors.size()):
		var actor=actors[i];var p: Vector3=actor.node.position;var ground=game.world.height_at(p.x,p.z)
		var radius=float(actor.get("radius",.6))*2.2
		shadow_batch.multimesh.set_instance_transform(i,Transform3D(Basis.from_scale(Vector3(radius,1,radius)),Vector3(p.x,ground+.04,p.z)))
		shadow_batch.multimesh.set_instance_color(i,Color(1,1,1,clampf(1-(p.y-ground)/5,0,1)))

func eyebrows(enemy: Dictionary):
	if enemy.biome!=1 or enemy.species!=1: return
	if not enemy.has("brows"):
		var brows=Node3D.new();enemy.node.add_child(brows);brows.position=Vector3(0,enemy.height*.8,-enemy.radius)
		for side in [-1,1]:
			var mesh=BoxMesh.new();mesh.size=Vector3(.45,.12,.12)
			var brow=game.shape(mesh,Color("574536"),brows,Vector3(side*.24,0,0));brow.rotation.z=side*.4
		enemy.brows=brows
	enemy.brows.scale=Vector3.ONE*(1+sin(enemy.windup*4)*.35)

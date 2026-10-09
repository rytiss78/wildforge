extends Node

class_name CoopSession

var flower_visuals={}

# Transport-independent authoritative world. Important events are reliable;
# poses/snapshots use unreliable ordered delivery. Never deserialize objects.
const PROTOCOL="wildforge-0.8.2-direct-6"
const PORT=29736
const DISCOVERY_PORT=29737
var discovery: PacketPeerUDP
var search: PacketPeerUDP
var discovered={}
var discovery_clock=0.0
var connection_clock=0.0
var local_ready=false
var lobby_roster=[]
var welcomed=false
var game
var peer: ENetMultiplayerPeer
var transport=""
var active=false
var hosting=false
var local_id=1
var owner_id=1
var members={}
var avatars={}
var accumulator=0.0
var next_entity=1
var paused=false
var status="Solo"
var kills_received=0
var snapshots_received=0
var remote_hits=0
var force_requests_received=0
var saw_force_pulse=false
var last_snapshot=0.0
var test_mode=false
var joined=false
var saw_pause=false
var saw_realm=false
var turret_models={}

func setup(owner_game):
	game=owner_game

func local_addresses() -> Array:
	var addresses=[]
	for address in IP.get_local_addresses():
		if address.contains(":") or address.begins_with("127.") or address.begins_with("169.254.") or address=="0.0.0.0": continue
		addresses.append(address)
	return addresses

func begin_discovery():
	if search!=null: return
	discovered.clear();search=PacketPeerUDP.new()
	if search.bind(0,"0.0.0.0")!=OK: search=null;return
	search.set_broadcast_enabled(true);discovery_clock=0

func stop_discovery():
	if search!=null: search.close();search=null

func discover_tick(delta: float):
	if discovery!=null:
		for i in range(mini(32,discovery.get_available_packet_count())):
			var bytes=discovery.get_packet();var address=discovery.get_packet_ip();var port=discovery.get_packet_port()
			if bytes.size()>512: continue
			var message=JSON.parse_string(bytes.get_string_from_utf8())
			if message is Dictionary and message.get("query","")==PROTOCOL:
				discovery.set_dest_address(address,port)
				discovery.put_packet(JSON.stringify({"protocol":PROTOCOL,"name":str(game.career.data.settings.name).left(24),"players":members.size()+1,"playing":game.run_active}).to_utf8_buffer())
	if game.mode!="coop": stop_discovery()
	if search==null: return
	discovery_clock-=delta
	if discovery_clock<=0:
		discovery_clock=1.5
		for address in ["255.255.255.255","127.0.0.1"]:
			search.set_dest_address(address,DISCOVERY_PORT);search.put_packet(JSON.stringify({"query":PROTOCOL}).to_utf8_buffer())
	for i in range(mini(32,search.get_available_packet_count())):
		var bytes=search.get_packet();var address=search.get_packet_ip()
		if bytes.size()>512: continue
		var message=JSON.parse_string(bytes.get_string_from_utf8())
		if not message is Dictionary or message.get("protocol","")!=PROTOCOL: continue
		if hosting and (local_addresses().has(address) or address=="127.0.0.1"): continue
		discovered[address]={"address":address,"name":str(message.get("name","Friend")).left(24),"players":clampi(int(message.get("players",1)),1,4),"playing":bool(message.get("playing",false)),"seen":Time.get_ticks_msec()}
	for address in discovered.keys():
		if Time.get_ticks_msec()-discovered[address].seen>5000: discovered.erase(address)

func host_lan():
	leave();peer=ENetMultiplayerPeer.new()
	var error=peer.create_server(PORT,3)
	if error!=OK: status="Could not open local party port "+str(PORT);peer=null;return
	transport="lan";active=true;hosting=true;local_id=1;owner_id=1
	discovery=PacketPeerUDP.new()
	if discovery.bind(DISCOVERY_PORT,"0.0.0.0")!=OK: discovery=null
	peer.peer_connected.connect(func(id):
		if game.run_active: peer.disconnect_peer(id)
	)
	publish_lobby()
	peer.peer_disconnected.connect(remove_member);status="Party ready · %s · UDP %d. Friends join before you start." % [", ".join(local_addresses()),PORT]

func join_lan(address: String):
	address=address.strip_edges()
	if address.is_empty() or address.length()>253 or address.contains(" ") or address.contains("/"):
		status="Enter the host's IP address or hostname.";return
	leave();peer=ENetMultiplayerPeer.new()
	if peer.create_client(address,PORT)!=OK: status="Could not connect to that address.";peer=null;return
	transport="lan";hosting=false;active=true;owner_id=1;status="Connecting…"
	connection_clock=0;welcomed=false;game.career.data.settings.coopAddress=address;game.career.dirty=true
	peer.peer_disconnected.connect(func(id):
		if id==1: connection_lost.call_deferred()
	)

func leave():
	clear_flower_visuals()
	local_ready=false;lobby_roster.clear()
	if peer!=null: peer.close();peer=null
	if discovery!=null: discovery.close();discovery=null
	for actor in avatars.values(): actor.queue_free()
	for turret in turret_models.values(): turret.queue_free()
	turret_models.clear()
	avatars.clear();members.clear();active=false;hosting=false;paused=false;transport="";joined=false;welcomed=false;connection_clock=0;last_snapshot=0

func connection_lost():
	leave();status="Host disconnected. Return to solo or host a new party."
	if game.run_active: game.end_run(false)
	game.hud.tell(status,8)

func remove_member(id: int):
	sync_flowers(id,{"flower_realm":game.realm})
	members.erase(id)
	if avatars.has(id): avatars[id].queue_free();avatars.erase(id)
	for key in turret_models.keys():
		if key.begins_with(str(id)+":"): turret_models[key].queue_free();turret_models.erase(key)
	if not hosting and id==owner_id: connection_lost()
	elif hosting: publish_lobby()

func send_to(id: int,message: Dictionary,reliable: bool=true):
	var bytes=var_to_bytes(message)
	if bytes.size()>60000: return
	if transport=="lan" and peer!=null and peer.get_connection_status()==MultiplayerPeer.CONNECTION_CONNECTED:
		peer.set_target_peer(id);peer.transfer_mode=MultiplayerPeer.TRANSFER_MODE_RELIABLE if reliable or bytes.size()>1000 else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED;peer.put_packet(bytes)

func broadcast(message: Dictionary,reliable: bool=true):
	for id in members: send_to(id,message,reliable)

func hero_changed():
	local_ready=false
	publish_lobby_choice()

func set_ready(value: bool):
	if not active or game.run_active or (not hosting and not welcomed): return
	local_ready=value
	publish_lobby_choice()

func publish_lobby_choice():
	if not active or game.run_active: return
	if hosting: publish_lobby()
	elif welcomed: send_to(owner_id,{"type":"lobby_choice","hero":game.hero.id,"ready":local_ready})

func publish_lobby():
	if not hosting or game.run_active: return
	lobby_roster=[{"id":local_id,"hero":game.hero.id,"name":game.hero.name,"ready":local_ready,"host":true}]
	for id in members:
		var member=members[id]
		lobby_roster.append({"id":id,"hero":member.get("hero",""),"name":member.get("hero_name","Choosing hero…"),"ready":member.get("ready",false),"host":false})
	broadcast({"type":"lobby_state","players":lobby_roster})

func can_start() -> bool:
	if not active or not hosting or game.run_active or not local_ready: return false
	for member in members.values():
		if not member.get("ready",false) or str(member.get("hero","")).is_empty(): return false
	return true

func start_party(shared_seed: int=-1) -> bool:
	if not can_start(): return false
	game.start_run(shared_seed)
	if shared_seed>=0: run_started()
	return game.run_active

func run_started():
	if not active or not hosting: return
	for member in members.values(): member.mode="loading";member.last_seen=Time.get_ticks_msec()/1000.0
	broadcast({"type":"start","seed":game.seed_value,"realm":0})

func realm_changed():
	if active and hosting: broadcast({"type":"realm","realm":game.realm})

func frozen() -> bool:
	if not active or not game.run_active: return false
	if not hosting: return paused
	for member in members.values():
		if member.get("mode","loading") not in ["playing","ended"]: return true
	return false

func tick(delta: float):
	discover_tick(delta)
	if not active: return
	if transport=="lan" and peer!=null:
		peer.poll()
		if peer==null or not active: return
		if not hosting and not welcomed:
			connection_clock+=delta
			if connection_clock>12:
				leave();status="Connection timed out. Check the address and allow UDP 29736 through the host's firewall/router.";return
		if not hosting and peer.get_connection_status()==MultiplayerPeer.CONNECTION_CONNECTED and not joined:
			local_id=peer.get_unique_id();send_to(owner_id,{"type":"hello","protocol":PROTOCOL});joined=true
		for i in range(mini(128,peer.get_available_packet_count())):
			var sender=peer.get_packet_peer();var bytes=peer.get_packet()
			if bytes.size()<=60000: receive(sender,bytes_to_var(bytes))
			if peer==null or not active: return
	accumulator+=delta
	if accumulator>=.075:
		accumulator=0
		if hosting:
			if game.run_active: broadcast(snapshot(),false)
		else:
			send_to(owner_id,pose(),false)
			if game.run_active and last_snapshot>0 and Time.get_ticks_msec()/1000.0-last_snapshot>12: connection_lost()
	if hosting:
		var now=Time.get_ticks_msec()/1000.0
		for id in members.keys():
			if now-members[id].get("last_seen",now)>20: remove_member(id)
	for id in avatars:
		var state=members.get(id,{})
		if state.has("position"):
			var node=avatars[id];var target=vector(state.position);var movement=(target-node.position)*8
			node.position=node.position.lerp(target,1-exp(-delta*12));node.rotation.y=float(state.get("yaw",0));node.get_meta("rig").animate(delta,movement,true)
			if state.has("weapons"): node.get_meta("rig").sync_equipment(state.weapons)
			if node.has_meta("nameplate"): node.get_meta("nameplate").text=str(state.get("name","Friend"))+("\nDOWNED · HOLD E / X" if game.update.downed_ids.has(id) else "")
			if state.has("hp") and state.has("stats"): node.get_meta("rig").set_health(float(state.hp)/maxf(1,float(state.stats.get("maxHp",100))))
			if state.has("stats"): node.get_meta("rig").set_defense(float(state.stats.get("armor",0)),float(state.get("shield_hp",0)),float(state.stats.get("shield",0))+float(state.stats.get("jumpShield",0)))

func pose() -> Dictionary:
	var weapons=[]
	for weapon in game.equipped:
		var state={"id":weapon.id,"rank":weapon.rank}
		if weapon.turret and is_instance_valid(weapon.get("node")): state.placement=array(weapon.node.position)
		weapons.append(state)
	var effective=game.stats.duplicate()
	for key in effective.keys():
		if str(key).begins_with("augment-"): effective.erase(key)
	for key in game.conditional_bonuses: effective[key]=game.stat(key)
	return {"type":"pose","flower_realm":game.realm,"flowers":flower_state(),"position":array(game.player.position),"yaw":game.avatar.rotation.y,"model":game.hero.model,"name":game.hero.name,"mode":"ended" if game.run_recorded else game.mode,"weapons":weapons,"hp":game.hp,"shield_hp":game.shield_hp,"stats":effective,"gold":game.gold,"rescue_hold":game.update.rescue_hold}

func snapshot() -> Dictionary:
	var actors=[]
	for enemy in game.enemies:
		if not enemy.dead: actors.append({"id":enemy.net_id,"position":array(enemy.node.position),"biome":enemy.biome,"species":enemy.species,"height":enemy.height,"radius":enemy.radius,"hp":enemy.hp,"maxHp":enemy.maxHp,"xp_reward":enemy.xp_reward,"boss":enemy.boss,"guardian":enemy.get("guardian",false),"title":enemy.get("title",""),"elite":enemy.elite,"corruption":enemy.get("corruption",0),"surface_up":array(enemy.node.basis.y),"surface_forward":array(-enemy.node.basis.z),"fire":enemy.fire,"poison":enemy.poison,"freeze":enemy.freeze,"blind":enemy.blind,"slip_until":enemy.get("slip_until",0),"windup":enemy.get("windup",0)})
	var poses=members.duplicate(true);poses[local_id]=pose()
	for member in poses.values(): member.erase("stats");member.erase("last_seen")
	return {"type":"world","actors":actors,"players":poses,"seconds":game.realm_time,"elapsed":game.elapsed,"realm":game.realm,"journey":game.events,"wardens":game.realm_bosses,"pause":frozen() or game.mode not in ["playing","ended"],"big_update":game.update.world_state()}

static func array(v: Vector3) -> Array: return [v.x,v.y,v.z]
static func vector(v) -> Vector3:
	if not v is Array or v.size()!=3: return Vector3.ZERO
	return Vector3(float(v[0]),float(v[1]),float(v[2]))

func receive(sender: int,message):
	if not message is Dictionary or not message.get("type","") is String: return
	if game.update.receive(sender,message): return
	var kind=message.type
	if hosting:
		if kind=="hello":
			if game.run_active or message.get("protocol","")!=PROTOCOL or members.size()>=3: send_to(sender,{"type":"reject","reason":"Party is full, already playing, or on a different version."});return
			members[sender]={"mode":"loading","last_seen":Time.get_ticks_msec()/1000.0};status="%d / 4 players. Ready to start." % (members.size()+1)
			send_to(sender,{"type":"welcome"});publish_lobby();return
		if not members.has(sender): return
		members[sender].last_seen=Time.get_ticks_msec()/1000.0
		if kind=="lobby_choice" and not game.run_active:
			var choices=game.rules.data.heroes.filter(func(h):return h.id==str(message.get("hero","")))
			if choices.is_empty(): return
			members[sender].hero=choices[0].id;members[sender].hero_name=choices[0].name
			members[sender].ready=message.get("ready",false)==true
			publish_lobby()
		elif kind=="pose":
			var p=vector(message.get("position",[]))
			if not p.is_finite() or maxf(absf(p.x),absf(p.z))>RealmWorld.EXTENT+10: return
			for key in ["position","yaw","model","name","mode","weapons","hp","shield_hp","stats","gold","rescue_hold","flower_realm","flowers"]:
				if message.has(key): members[sender][key]=message[key]
			if game.run_active: ensure_avatar(sender,members[sender])
			if game.update.downed_ids.has(sender): members[sender].hp=0
		elif kind=="force_pulse" and int(message.get("realm",-1))==game.realm and game.run_active and not frozen():
			var key=str(message.get("key",""));var member=members[sender]
			if not ForcePulse.PERIODS.has(key) or float(member.get("hp",0))<=0: return
			if game.elapsed-float(member.get("last_"+key,-100))<ForcePulse.PERIODS[key]-.1: return
			var power=clampf(float(member.get("stats",{}).get(key,0)),0,8)
			if power<=0: return
			member["last_"+key]=game.elapsed;force_requests_received+=1
			ForcePulse.apply(game,vector(member.get("position",[])),key,power)
		elif kind=="shot":
			var weapon=str(message.get("weapon",""))
			if members[sender].get("weapons",[]).any(func(w):return w.get("id","")==weapon):
				message.actor=sender;show_shot(message);broadcast(message,false)
		elif kind=="hunt_start" and int(message.get("realm",-1))==game.realm and not frozen() and float(members[sender].get("hp",0))>0:
			game.Hunt.activate(game,vector(members[sender].get("position",[])))
		elif kind=="travel" and game.mode=="playing" and not frozen():
			if vector(members[sender].get("position",[])).distance_to(game.gate_position)<5:
				game.Journey.activate(game)
		elif kind=="stomp" and game.mode=="playing" and not frozen():
			for enemy in game.enemies:
				if enemy.dead or enemy.net_id!=int(message.get("id",-1)): continue
				var p=vector(members[sender].get("position",[]));var top=enemy.node.position.y+enemy.height
				if Vector2(p.x-enemy.node.position.x,p.z-enemy.node.position.z).length()<enemy.radius+.5 and absf(p.y-top)<1.5:
					enemy.hit_owner=sender
					if enemy.boss:
						game.hurt_enemy(enemy,float(members[sender].get("stats",{}).get("damage",15))*4,"stomp")
						enemy.erase("hit_owner")
					else:
						game.kill_enemy(enemy,"stomp")
						enemy.erase("hit_owner")
				return
		elif kind=="hit" and game.mode=="playing" and not frozen():
			for enemy in game.enemies:
				if enemy.dead or enemy.net_id!=int(message.get("id",-1)): continue
				var state=members[sender];var p=vector(state.get("position",[]))
				if p.distance_to(enemy.node.position)>65: return
				var stats=state.get("stats",{})
				var limit=maxf(1,float(stats.get("damage",15)))*maxf(4,float(stats.get("critPower",1)))*10
				var damage=clampf(float(message.get("damage",0)),0,limit)
				if not is_finite(damage): return
				enemy.hit_owner=sender
				game.hurt_enemy(enemy,damage,"coop",str(message.get("mechanic","")));remote_hits+=1
				enemy.erase("hit_owner");enemy.status_owner=sender
				if not enemy.dead:
					var owned_ids=state.get("weapons",[]).map(func(w):return str(w.id))
					var ids=owned_ids.map(func(id):return ContentExpansion.kind(id))
					var mechanic=str(message.get("mechanic",""))
					if owned_ids.has(mechanic):
						ContentExpansion.payload(enemy,str(ContentExpansion.weapon(mechanic).get("modifiers",{}).get("payload","")))
						mechanic=ContentExpansion.kind(mechanic)
						if mechanic=="bubble": enemy.bubble=1.5*float(stats.get("bubbleTime",1));enemy.slow=maxf(enemy.slow,.7)
						if mechanic=="horn": enemy.freeze=maxf(enemy.freeze,.35+float(stats.get("hornStun",0)))
						if mechanic in ["harpoon","gravity"] and not enemy.boss:
							var pull=p if mechanic=="harpoon" else vector(message.get("origin",[]))
							if pull.is_finite() and pull.distance_to(p)<65:
								enemy.node.move_and_collide((pull-enemy.node.position).normalized()*minf(3,.05 if mechanic=="gravity" else .15+float(stats.get("harpoonPull",0))))
					enemy.status_time=4;game.set_damage_status(enemy,"fire",float(stats.get("burn",0))+(10 if ids.any(func(id):return id.contains("flame") or id.contains("fire")) else 0),sender);game.set_damage_status(enemy,"poison",float(stats.get("poison",0))+(9 if ids.any(func(id):return id.contains("poison")) else 0),sender);enemy.slow=maxf(enemy.slow,float(stats.get("slow",0)) + (.35 if ids.any(func(id):return id.contains("ice")) else 0))
					if game.rules.rng.randf()<float(stats.get("freeze",0)): enemy.freeze=1.6
					if game.rules.rng.randf()<float(stats.get("blind",0)): enemy.blind=3
					game.update_reaction(enemy,mechanic,damage)
					if game.rules.rng.randf()<float(stats.get("banana",0)) and game.realm_time>enemy.get("slip_until",-3)+2:
						enemy.slip_until=game.realm_time+(.2 if enemy.boss else .8);enemy.freeze=maxf(enemy.freeze,.2 if enemy.boss else .8)
						send_to(sender,{"type":"big_memory","key":"BANANA"})
				return
	else:
		if sender!=owner_id: return
		last_snapshot=Time.get_ticks_msec()/1000.0
		if kind=="reject": leave();status=str(message.reason);game.hud.tell(status,8)
		elif kind=="welcome": welcomed=true;status="Joined. Choose your hero and mark Ready.";publish_lobby_choice()
		elif kind=="lobby_state" and not game.run_active: lobby_roster=message.get("players",[])
		elif kind=="start": game.start_run(int(message.seed));game.hud.close()
		elif kind=="realm": game.enter_realm(int(message.realm));saw_realm=true
		elif kind=="force_pulse_fx" and int(message.get("realm",-1))==game.realm: ForcePulse.visual(game,vector(message.position),str(message.key));saw_force_pulse=true
		elif kind=="world": apply_world(message)
		elif kind=="journey_announcement": game.Journey.announce(game,str(message.title),str(message.detail))
		elif kind=="shot": show_shot(message)
		elif kind=="hazard" and int(message.get("realm",-1))==game.realm:
			game.warn_at(vector(message.position),float(message.radius),float(message.delay),float(message.damage),str(message.style))
		elif kind=="kill":
			kills_received+=1
			for enemy in game.enemies:
				if enemy.net_id==int(message.id) and not enemy.dead: game.kill_enemy(enemy,str(message.cause));return
			if message.has("actor"): game.kill_enemy(game.spawn_network_enemy(message.actor),str(message.cause))
		elif kind=="damage":
			game.take_damage(float(message.amount),vector(message.position),str(message.sound))
		elif kind=="finish": game.end_run(bool(message.win))

func ensure_avatar(id: int,state: Dictionary):
	sync_flowers(id,state)
	if id==local_id or not state.has("model"): return
	if not avatars.has(id):
		var model=str(state.model)
		if not game.rules.data.heroes.any(func(h):return h.model==model): return
		var node=CharacterBody3D.new();node.collision_layer=2;node.collision_mask=1
		var collider=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.42;capsule.height=1.6;collider.shape=capsule;collider.position.y=.8;node.add_child(collider)
		var rig=game.world.model(model,1.65);node.add_child(rig);node.set_meta("rig",rig);game.add_child(node);avatars[id]=node
		var nameplate=Label3D.new();nameplate.text=str(state.get("name","Friend")).left(24);nameplate.position.y=2.1;nameplate.font_size=26;nameplate.billboard=BaseMaterial3D.BILLBOARD_ENABLED;node.add_child(nameplate);node.set_meta("nameplate",nameplate)
		if state.has("position"): node.position=vector(state.position)
	var wanted={}
	for weapon in state.get("weapons",[]):
		if not weapon is Dictionary or not weapon.has("placement") or not game.rules.data.weapons.any(func(w):return w.id==weapon.get("id","") and w.turret): continue
		var key=str(id)+":"+str(weapon.id);wanted[key]=true
		if not turret_models.has(key):
			var turret=WeaponModel.new();turret.setup(weapon.id);turret.rank=int(weapon.rank);turret.scale=Vector3.ONE*1.7;game.add_child(turret);turret_models[key]=turret
		turret_models[key].position=vector(weapon.placement)+Vector3.UP*.75;turret_models[key].rank=int(weapon.rank);turret_models[key].transform_rank()
	for key in turret_models.keys():
		if key.begins_with(str(id)+":") and not wanted.has(key): turret_models[key].queue_free();turret_models.erase(key)

func apply_world(message: Dictionary):
	if not game.run_active or int(message.realm)!=game.realm: return
	game.update.apply_state(message.get("big_update",{}))
	game.events=message.get("journey",game.events).duplicate(true);game.realm_bosses=int(message.get("wardens",game.realm_bosses))
	snapshots_received+=1;paused=bool(message.pause);saw_pause=saw_pause or paused;game.realm_time=float(message.seconds);game.elapsed=float(message.elapsed)
	for id in message.players:
		var number=int(id)
		if number==local_id: continue
		members[number]=message.players[id];ensure_avatar(number,members[number])
	for id in avatars.keys():
		if not message.players.has(str(id)) and not message.players.has(id): avatars[id].queue_free();avatars.erase(id);members.erase(id)
	var ids={}
	for actor in message.actors:
		var id=int(actor.id);ids[id]=true
		var found={}
		for enemy in game.enemies:
			if enemy.net_id==id: found=enemy;break
		if found.is_empty(): found=game.spawn_network_enemy(actor)
		if found.is_empty() or found.dead: continue
		EnemySurface.replicate(found,vector(actor.get("surface_up",[0,1,0])),vector(actor.get("surface_forward",[0,0,-1])))
		EclipseCorruption.apply(found,int(actor.get("corruption",0)))
		found.hp=float(actor.hp);found.target_position=vector(actor.position)
		for key in ["fire","poison","freeze","blind","slip_until","windup"]: found[key]=float(actor.get(key,0))
	for enemy in game.enemies:
		if not ids.has(enemy.net_id) and not enemy.dead: enemy.dead=true;enemy.node.queue_free()

func hit(enemy: Dictionary,damage: float,mechanic: String="",origin: Vector3=Vector3.ZERO):
	if active and not hosting: send_to(owner_id,{"type":"hit","id":enemy.net_id,"damage":damage,"mechanic":mechanic,"origin":array(origin)})

func stomp(enemy: Dictionary):
	if active and not hosting: send_to(owner_id,{"type":"stomp","id":enemy.net_id})

func died(enemy: Dictionary,cause: String):
	if active and hosting: broadcast({"type":"kill","id":enemy.net_id,"position":array(enemy.node.position),"cause":cause,"actor":{"id":enemy.net_id,"position":array(enemy.node.position),"biome":enemy.biome,"species":enemy.species,"height":enemy.height,"radius":enemy.radius,"hp":enemy.hp,"maxHp":enemy.maxHp,"xp_reward":enemy.xp_reward,"boss":enemy.boss,"guardian":enemy.get("guardian",false),"title":enemy.get("title",""),"elite":enemy.elite}})

func target(origin: Vector3) -> Dictionary:
	var result={"id":local_id,"position":game.player.position};var distance=origin.distance_squared_to(game.player.position) if game.hp>0 else INF
	if active and hosting:
		for id in members:
			var member=members[id]
			if not member.has("position") or member.get("hp",0)<=0: continue
			var p=vector(member.position);var d=origin.distance_squared_to(p)
			if d<distance: distance=d;result={"id":id,"position":p}
	return result

func damage_player(id: int,amount: float,origin: Vector3,sound: String):
	if id==local_id: game.take_damage(amount,origin,sound)
	elif hosting:
		if game.update.downed_ids.has(id): return
		members[id].rescue_hold=false
		members[id].rescue_interrupt_until=game.elapsed+.4
		game.update.rescue_progress.clear()
		send_to(id,{"type":"damage","amount":amount,"position":array(origin),"sound":sound})

func shot(weapon: String,origin: Vector3,target_position: Vector3,duration: float=.44):
	if not active: return
	var message={"type":"shot","weapon":weapon,"origin":array(origin),"target":array(target_position),"actor":local_id,"duration":duration}
	if hosting: broadcast(message,false)
	else: send_to(owner_id,message,false)

func show_shot(message: Dictionary):
	var actor=int(message.get("actor",0));var weapon=str(message.get("weapon",""))
	if actor==local_id or not avatars.has(actor) or not game.rules.data.weapons.any(func(w):return w.id==weapon): return
	var origin=vector(message.get("origin",[]));var target_position=vector(message.get("target",[]))
	if not origin.is_finite() or not target_position.is_finite() or origin.distance_to(target_position)>80: return
	var duration=clampf(float(message.get("duration",.44)),.07,.44)
	if ContentExpansion.kind(weapon)=="saw": avatars[actor].get_meta("rig").begin_melee(weapon,target_position,duration)
	else: avatars[actor].get_meta("rig").shot(weapon)
	if weapon.contains("turret") and turret_models.has(str(actor)+":"+weapon): turret_models[str(actor)+":"+weapon].shoot()
	game.remote_weapon_effect(weapon,origin,target_position,duration);game.sound.effect("slash" if weapon=="saw" else weapon,origin)

func flower_state() -> PackedFloat32Array:
	var result=PackedFloat32Array()
	for flower in game.flowers:
		var p: Vector3=flower.node.position
		result.append_array(PackedFloat32Array([flower.id,p.x,p.y,p.z,flower.age,flower.bloom,flower.power]))
	return result

func clear_flower_visuals():
	for flower in flower_visuals.values():
		if is_instance_valid(flower): flower.queue_free()
	flower_visuals.clear()

func sync_flowers(actor: int,state: Dictionary):
	if actor==local_id: return
	var wanted={};var entries=state.get("flowers",PackedFloat32Array())
	if not entries is PackedFloat32Array or entries.size()>48*7 or entries.size()%7!=0: return
	if int(state.get("flower_realm",-1))==game.realm:
		for i in range(0,entries.size(),7):
			var p=Vector3(entries[i+1],entries[i+2],entries[i+3])
			if not p.is_finite() or absf(p.x)>RealmWorld.EXTENT+10 or absf(p.z)>RealmWorld.EXTENT+10: continue
			var key=str(actor)+":"+str(int(entries[i]));wanted[key]=true
			if not flower_visuals.has(key): flower_visuals[key]=game.make_flower_visual(p,int(entries[i]))
			var node=flower_visuals[key];node.position=p
			node.scale=Vector3.ONE*clampf(entries[i+4]/1.5,0,1)*(1.12 if entries[i+5]>0 else 1.)
			node.rotation.z=sin(game.elapsed*TAU*144/60)*(.22 if entries[i+6]>=1.5 else .045)
	for key in flower_visuals.keys():
		if key.begins_with(str(actor)+":") and not wanted.has(key): flower_visuals[key].queue_free();flower_visuals.erase(key)

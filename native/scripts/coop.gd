extends Node

class_name CoopSession

var flower_visuals={}
var party_seen={}

# Transport-independent authoritative world. Important events are reliable;
# poses/snapshots use unreliable ordered delivery. Never deserialize objects.
const PROTOCOL="wildforge-shared-world-10"
# World snapshots carry each enemy as ACTOR_STRIDE floats: id, position(3), hp,
# maxHp, surface up(3), surface forward(3), ACTOR_STATUS(7), corruption. Static
# identity (species, size, boss/elite flags) is sent once via actors_info.
const ACTOR_STRIDE=20
const ACTOR_STATUS=["fire","poison","freeze","blind","slip_until","windup","contact_windup"]
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
var local_nameplate: Label3D
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
var test_messages={}
var test_finished_peers={}
var joined=false
var saw_pause=false
var saw_realm=false
var turret_models={}
var last_remote_reward_level=1
var review_lag_ms=0
var review_packet_queue=[]
var reconnecting=false
var reconnect_attempting=false
var disconnect_started=0.0
var snapshot_seq=0
var last_snapshot_seq=-1
var actor_info={}
var actor_requested={}
var test_reconnect_hold=0.0
var mode_before_drop="playing"

func setup(owner_game):
	game=owner_game
	if OS.get_cmdline_user_args().has("--shared-review-lag"): review_lag_ms=150

func clean_player_name(value, fallback: String="Player") -> String:
	var cleaned=str(value).replace("\r"," ").replace("\n"," ").strip_edges().left(24)
	return cleaned if not cleaned.is_empty() else fallback

func player_name() -> String:
	return clean_player_name(game.career.data.settings.get("name","Player"))

func player_name_for(id: int) -> String:
	if id==local_id:return player_name()
	return clean_player_name(members.get(id,{}).get("name",members.get(id,{}).get("player_name","Player")))

func cosmetic_style(id: String) -> Dictionary:
	var styles={"mastery_crown":{"mark":"♛ ","color":Color("f6d67c")},"formation_gold":{"mark":"✦ ","color":Color("ffba72")},"biome_prism":{"mark":"❖ ","color":Color("9ff0d2")},"ping_star":{"mark":"✧ ","color":Color("ffe98f")},"party_banner":{"mark":"⚑ ","color":Color("b6d6ff")},"comeback_flame":{"mark":"🔥 ","color":Color("ff927a")},"scout_visor":{"mark":"◈ ","color":Color("b7ebff")},"recap_medal":{"mark":"★ ","color":Color("e8d0a5")}}
	return styles.get(id,{"mark":"","color":Color("fff1d1")})

func set_boss_focus(id: int,name: String):
	game.events.boss_focus_id=id;game.events.boss_focus_until=game.elapsed+4.0
	game.hud.tell("BARON MARKS "+clean_player_name(name)+" · MOVE",3.0)
	sync_local_nameplate()

func name_changed():
	if not active: return
	if game.run_active:
		sync_local_nameplate()
	elif hosting:
		publish_lobby()
	elif welcomed:
		publish_lobby_choice()

func sync_local_nameplate():
	if not active or not game.run_active:
		if is_instance_valid(local_nameplate): local_nameplate.queue_free()
		local_nameplate=null
		return
	if not is_instance_valid(local_nameplate):
		local_nameplate=Label3D.new()
		local_nameplate.name="CoopPlayerNameplate"
		local_nameplate.font_size=26;local_nameplate.pixel_size=.01
		local_nameplate.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		local_nameplate.modulate=Color("fff1d1");local_nameplate.outline_modulate=Color("263138");local_nameplate.outline_size=6
		game.player.add_child(local_nameplate)
	local_nameplate.position=Vector3(0,float(game.hero.get("height",1.65))+.55,0)
	var targeted=int(game.events.get("boss_focus_id",0))==local_id and float(game.events.get("boss_focus_until",0))>game.elapsed
	var style=cosmetic_style(str(game.career.data.settings.get("cosmetic","")))
	local_nameplate.text=("⚠ "+player_name()+" · TARGET" if targeted else str(style.mark)+player_name())
	local_nameplate.font_size=36 if targeted else 26;local_nameplate.pixel_size=.012 if targeted else .01
	local_nameplate.modulate=Color("ff9675") if targeted else style.color

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
	publish_lobby()
	peer.peer_disconnected.connect(remove_member);status="Party ready · %s · UDP %d. Friends join before you start." % [", ".join(local_addresses()),PORT]

func join_lan(address: String):
	address=address.strip_edges()
	if address.is_empty() or address.length()>253 or address.contains(" ") or address.contains("/"):
		status="Enter the host's IP address or hostname.";return
	leave();open_client(address)

# Opens only the client transport. A run rejoin keeps avatars, nameplates and
# reward progress; leave() is reserved for actually quitting the party.
func open_client(address: String):
	peer=ENetMultiplayerPeer.new()
	var err=peer.create_client(address,PORT)
	if err!=OK: status="Could not connect to that address.";peer=null;return
	transport="lan";hosting=false;active=true;owner_id=1;status="Connecting…"
	connection_clock=0;welcomed=false;joined=false;game.career.data.settings.coopAddress=address;game.career.dirty=true
	peer.peer_disconnected.connect(func(id):
		if id==1: connection_lost.call_deferred()
	)

func leave():
	clear_flower_visuals()
	if is_instance_valid(local_nameplate): local_nameplate.queue_free()
	local_nameplate=null
	review_packet_queue.clear()
	local_ready=false;lobby_roster.clear()
	if peer!=null: peer.close();peer=null
	if discovery!=null: discovery.close();discovery=null
	for actor in avatars.values(): actor.queue_free()
	for turret in turret_models.values(): turret.queue_free()
	turret_models.clear()
	avatars.clear();members.clear();active=false;hosting=false;paused=false;transport="";joined=false;welcomed=false;connection_clock=0;last_snapshot=0;last_remote_reward_level=1
	reset_actor_sync()

func close_transport():
	if peer!=null: peer.close();peer=null
	active=false;welcomed=false;joined=false

func reset_actor_sync():
	last_snapshot_seq=-1;actor_info.clear();actor_requested.clear()

func connection_lost():
	if game.run_active and not hosting and not reconnecting:
		# Remember an open reward/pause screen so the rejoin returns to it.
		mode_before_drop=game.mode if game.mode!="paused" or game.hud.modal.visible else "playing"
		reconnecting=true;disconnect_started=Time.get_ticks_msec()/1000.0;status="Connection lost · trying to rejoin for 40 seconds…";game.mode="paused";game.hud.tell(status,8)
		close_transport()
		attempt_reconnect.call_deferred()
		return
	if reconnecting: return
	leave();status="Host disconnected. Return to solo or host a new party."
	if game.run_active: game.end_run(false)
	game.hud.tell(status,8)

func attempt_reconnect():
	if reconnect_attempting: return
	reconnect_attempting=true
	if test_reconnect_hold>0:
		await get_tree().create_timer(test_reconnect_hold).timeout;test_reconnect_hold=0.0
	var address=str(game.career.data.settings.get("coopAddress",""))
	for attempt in range(8):
		if not reconnecting: break
		if Time.get_ticks_msec()/1000.0-disconnect_started>=40: break
		if not active and not address.is_empty(): open_client(address)
		var deadline=Time.get_ticks_msec()+3200
		while reconnecting and active and not welcomed and Time.get_ticks_msec()<deadline:
			await get_tree().create_timer(.1).timeout
		if welcomed and active: reconnect_attempting=false;return
		if active: close_transport()
		await get_tree().create_timer(.8).timeout
	reconnecting=false;reconnect_attempting=false
	leave();status="Could not rejoin the active party. This run has ended."
	if game.run_active: game.end_run(false)
	game.hud.tell(status,8)

func remove_member(id: int):
	sync_flowers(id,{"flower_realm":game.realm})
	if hosting and game.run_active and members.has(id):
		members[id].disconnected=true;members[id].disconnect_until=Time.get_ticks_msec()/1000.0+40.0;members[id].last_seen=Time.get_ticks_msec()/1000.0
		if avatars.has(id): avatars[id].queue_free();avatars.erase(id)
		for key in turret_models.keys():
			if key.begins_with(str(id)+":"): turret_models[key].queue_free();turret_models.erase(key)
		status="Player disconnected · waiting 40 seconds for a reconnect."
		return
	members.erase(id)
	if avatars.has(id): avatars[id].queue_free();avatars.erase(id)
	for key in turret_models.keys():
		if key.begins_with(str(id)+":"): turret_models[key].queue_free();turret_models.erase(key)
	if not hosting and id==owner_id: connection_lost()
	elif hosting: publish_lobby()

func send_to(id: int,message: Dictionary,reliable: bool=true):
	var bytes=var_to_bytes(message)
	if bytes.size()>60000: push_warning("Co-op %s message dropped: %d bytes" % [str(message.get("type","")),bytes.size()]);return
	if hosting and members.has(id) and members[id].get("disconnected",false): return
	if transport=="lan" and transport_peer_connected(id):
		# World snapshots stay unreliable at any size: a newer one supersedes a
		# lost one, and reliable delivery would stall events behind stale state.
		var unreliable=not reliable and (bytes.size()<=1000 or message.get("type","")=="world")
		peer.set_target_peer(id);peer.transfer_mode=MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED if unreliable else MultiplayerPeer.TRANSFER_MODE_RELIABLE;peer.put_packet(bytes)

func broadcast(message: Dictionary,reliable: bool=true):
	for id in members:
		if not members[id].get("disconnected",false) and transport_peer_connected(int(id)): send_to(id,message,reliable)

func transport_peer_connected(id: int) -> bool:
	if peer==null or peer.get_connection_status()!=MultiplayerPeer.CONNECTION_CONNECTED: return false
	if not hosting: return true
	var remote=peer.get_peer(id)
	return remote!=null and remote.get_state()==ENetPacketPeer.STATE_CONNECTED

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
	elif welcomed: send_to(owner_id,{"type":"lobby_choice","hero":game.hero.id,"player_name":player_name(),"ready":local_ready})

func publish_lobby():
	if not hosting or game.run_active: return
	lobby_roster=[{"id":local_id,"hero":game.hero.name,"name":player_name(),"ready":local_ready,"host":true}]
	for id in members:
		var member=members[id]
		lobby_roster.append({"id":id,"hero":member.get("hero_name","Choosing hero…"),"name":clean_player_name(member.get("player_name","Player")),"ready":member.get("ready",false),"host":false})
	broadcast({"type":"lobby_state","players":lobby_roster})

func can_start() -> bool:
	if not active or not hosting or game.run_active or not local_ready: return false
	for member in members.values():
		if not member.get("ready",false) or str(member.get("hero","")).is_empty(): return false
	return true

func start_party(shared_seed: int=-1) -> bool:
	if not can_start(): 
		return false
	if not members.is_empty(): game.career.bump("ready_runs")
	game.start_run(shared_seed)
	if shared_seed>=0:
		run_started()
	return game.run_active

func party_builds() -> Array:
	var result=[{"id":local_id,"name":player_name(),"build":pose().get("build",{})}]
	for id in members:
		var state=members[id]
		result.append({"id":int(id),"name":clean_player_name(state.get("name",state.get("player_name","Player"))),"build":state.get("build",{})})
	return result

func run_started():
	if not active or not hosting: return
	for member in members.values(): member.mode="loading";member.paid_chests=0;member.last_seen=Time.get_ticks_msec()/1000.0
	broadcast({"type":"start","seed":game.seed_value,"realm":0})

func realm_changed():
	if active and hosting: broadcast({"type":"realm","realm":game.realm})

func frozen() -> bool:
	if not active or not game.run_active: return false
	if not hosting: return paused
	for member in members.values():
		if member.get("disconnected",false): continue
		if member.get("mode","loading") not in ["playing","ended"]: return true
	return false

func tick(delta: float):
	discover_tick(delta)
	if not active: return
	if transport=="lan" and peer!=null:
		peer.poll()
		if peer==null or not active: return
		if not review_packet_queue.is_empty():
			var now=Time.get_ticks_msec();var waiting=[]
			for item in review_packet_queue:
				if item.due<=now: receive(item.sender,item.message)
				else: waiting.append(item)
			review_packet_queue=waiting
		if not hosting and not welcomed:
			connection_clock+=delta
			if connection_clock>12:
				leave();status="Connection timed out. Check the address and allow UDP 29736 through the host's firewall/router.";return
		if not hosting and peer.get_connection_status()==MultiplayerPeer.CONNECTION_CONNECTED and not joined:
			local_id=peer.get_unique_id();send_to(owner_id,{"type":"hello","protocol":PROTOCOL,"token":str(game.career.data.settings.get("coopToken",""))});joined=true
		for i in range(mini(128,peer.get_available_packet_count())):
			var sender=peer.get_packet_peer();var bytes=peer.get_packet()
			if bytes.size()>60000: push_warning("Co-op packet ignored: %d bytes" % bytes.size())
			else:
				var message=bytes_to_var(bytes)
				if review_lag_ms>0: review_packet_queue.append({"sender":sender,"message":message,"due":Time.get_ticks_msec()+review_lag_ms})
				else: receive(sender,message)
			if peer==null or not active: return
	# Full world packets include every enemy, player and event. Ten updates per
	# second saves bandwidth and serialization work without dropping reliable hits.
	accumulator+=delta
	if accumulator>=.10:
		accumulator=fmod(accumulator,.10)
		if hosting:
			if game.run_active and not members.is_empty(): broadcast(snapshot(),false)
		else:
			# Before the host's welcome a rejoining client still reports its
			# disconnected "paused" mode, which would freeze the host's run.
			if welcomed: send_to(owner_id,pose(),false)
			if game.run_active and last_snapshot>0 and Time.get_ticks_msec()/1000.0-last_snapshot>12: connection_lost()
	if hosting:
		var now=Time.get_ticks_msec()/1000.0
		for id in members.keys():
			if members[id].get("disconnected",false):
				if now>float(members[id].get("disconnect_until",0)):
					members.erase(id);game.update.remap_peer_id(int(id),0);publish_lobby()
			elif now-members[id].get("last_seen",now)>20: remove_member(id)
	for id in avatars:
		var state=members.get(id,{})
		if state.has("position"):
			var node=avatars[id];var target=vector(state.position);var movement=(target-node.position)*8
			node.position=node.position.lerp(target,1-exp(-delta*12));node.rotation.y=float(state.get("yaw",0));node.get_meta("rig").animate(delta,movement,true)
			if state.has("weapons"): node.get_meta("rig").sync_equipment(state.weapons)
			var is_downed=game.update.downed_ids.has(int(id))
			if node.has_meta("nameplate"):
				var player_text=clean_player_name(state.get("name","Player"))
				var targeted=int(game.events.get("boss_focus_id",0))==int(id) and float(game.events.get("boss_focus_until",0))>game.elapsed
				var label: Label3D=node.get_meta("nameplate")
				var style=cosmetic_style(str(state.get("cosmetic","")))
				label.text=("⚠ "+player_text+" · TARGET" if targeted else str(style.mark)+player_text+("\nDOWNED · HOLD E / X" if is_downed else ""))
				label.font_size=36 if targeted else 26;label.pixel_size=.012 if targeted else .01;label.modulate=Color("ff9675") if targeted else style.color
			if node.has_meta("down_beacon"): node.get_meta("down_beacon").visible=is_downed
			update_avatar_vitals(node.get_meta("rig"),state)
	if is_instance_valid(local_nameplate): sync_local_nameplate()

func update_avatar_vitals(rig,state: Dictionary):
	var stats=state.get("stats",{})
	var vitals=state.get("vitals",{"max_hp":stats.get("maxHp",100),"armor":stats.get("armor",0),"shield_capacity":float(stats.get("shield",0))+float(stats.get("jumpShield",0))})
	if state.has("hp"): rig.set_health(float(state.hp)/maxf(1,float(vitals.get("max_hp",100))))
	rig.set_defense(float(vitals.get("armor",0)),float(state.get("shield_hp",0)),float(vitals.get("shield_capacity",0)))

func pose() -> Dictionary:
	var weapons=[]
	for weapon in game.equipped:
		var state={"id":weapon.id,"rank":weapon.rank}
		if weapon.turret and is_instance_valid(weapon.get("node")): state.placement=array(weapon.node.position)
		weapons.append(state)
	var effective=game.stats.duplicate()
	# Consumable and conditional XP modifiers are computed by stat(), outside the
	# permanent stats dictionary. The host needs the collector's live value.
	effective.xpGain=game.stat("xpGain")
	for key in effective.keys():
		if str(key).begins_with("augment-"): effective.erase(key)
	for key in game.conditional_bonuses: effective[key]=game.stat(key)
	var build={"weapons":weapons,"skills":game.owned.filter(func(item):return item.kind in ["skill","mutation"]).map(func(item):return str(item.name).left(48))}
	return {"type":"pose","flower_realm":game.realm,"flowers":flower_state(),"position":array(game.player.position),"yaw":game.avatar.rotation.y,"model":game.hero.model,"name":player_name(),"cosmetic":str(game.career.data.settings.get("cosmetic","")),"mode":"ended" if game.run_recorded else game.mode,"weapons":weapons,"build":build,"hp":game.hp,"shield_hp":game.shield_hp,"stats":effective,"gold":game.gold,"rescue_hold":game.update.rescue_hold}

# Everything a client needs to construct a replica of a host enemy.
func actor_descriptor(enemy: Dictionary) -> Dictionary:
	return {"id":enemy.net_id,"position":array(enemy.node.position),"biome":enemy.biome,"species":enemy.species,"height":enemy.height,"radius":enemy.radius,"hp":enemy.hp,"maxHp":enemy.maxHp,"xp_reward":enemy.xp_reward,"boss":enemy.boss,"boss_id":enemy.get("boss_id",-1),"guardian":enemy.get("guardian",false),"magnet_guard":enemy.get("magnet_guard",false),"title":enemy.get("title",""),"elite":enemy.elite,"corruption":enemy.get("corruption",0),"surface_up":array(enemy.node.basis.y),"surface_forward":array(-enemy.node.basis.z),"fire":enemy.fire,"poison":enemy.poison,"freeze":enemy.freeze,"blind":enemy.blind,"slip_until":enemy.get("slip_until",0),"windup":enemy.get("windup",0),"contact_windup":enemy.get("contact_windup",0)}

func request_actors(ids: Array):
	var now=Time.get_ticks_msec()
	if actor_requested.size()>1024: actor_requested.clear()
	var wanted=ids.filter(func(id):return now-int(actor_requested.get(id,-100000))>1000).slice(0,160)
	if wanted.is_empty(): return
	for id in wanted: actor_requested[id]=now
	send_to(owner_id,{"type":"need_actors","realm":game.realm,"ids":wanted})

func send_actor_descriptors(id: int,requested):
	if not requested is Array: return
	var wanted={}
	for value in requested.slice(0,160): wanted[int(value)]=true
	var batch=[]
	for enemy in game.enemies:
		if enemy.dead or not wanted.has(int(enemy.net_id)): continue
		batch.append(actor_descriptor(enemy))
		if batch.size()==40: send_to(id,{"type":"actors_info","realm":game.realm,"actors":batch});batch=[]
	if not batch.is_empty(): send_to(id,{"type":"actors_info","realm":game.realm,"actors":batch})

func snapshot() -> Dictionary:
	var actors=PackedFloat32Array()
	for enemy in game.enemies:
		if enemy.dead: continue
		var p=enemy.node.position;var up=enemy.node.basis.y;var forward=-enemy.node.basis.z
		actors.append_array(PackedFloat32Array([enemy.net_id,p.x,p.y,p.z,enemy.hp,enemy.maxHp,up.x,up.y,up.z,forward.x,forward.y,forward.z,enemy.fire,enemy.poison,enemy.freeze,enemy.blind,enemy.get("slip_until",0),enemy.get("windup",0),enemy.get("contact_windup",0),enemy.get("corruption",0)]))
	snapshot_seq+=1
	var poses={}
	for id in members:
		if not members[id].get("disconnected",false): poses[id]=members[id].duplicate(true)
	poses[local_id]=pose()
	for member in poses.values():
		var stats=member.get("stats",{})
		member.vitals={"max_hp":stats.get("maxHp",100),"armor":stats.get("armor",0),"shield_capacity":float(stats.get("shield",0))+float(stats.get("jumpShield",0))}
		member.erase("stats");member.erase("last_seen")
	return {"type":"world","seq":snapshot_seq,"actors":actors,"players":poses,"seconds":game.realm_time,"elapsed":game.elapsed,"realm":game.realm,"journey":game.events,"wardens":game.realm_bosses,"level":game.level,"xp":game.xp,"xp_target":game.xp_target,"run_xp":game.update.run_xp,"pause":frozen() or game.mode not in ["playing","ended"],"big_update":game.update.world_state(),"xp_drops":game.pickups.filter(func(p):return p.kind=="xp" and p.age>=0).map(func(p):return {"id":p.net_id,"position":array(p.node.position),"value":p.value,"heap":p.get("magnet_heap",false)})}

static func array(v: Vector3) -> Array: return [v.x,v.y,v.z]
static func vector(v) -> Vector3:
	if not v is Array or v.size()!=3: return Vector3.ZERO
	return Vector3(float(v[0]),float(v[1]),float(v[2]))

func publish_reward_options(items: Array,source: String,kind: String,elite: bool):
	if not active or not game.run_active or game.party_reward_id.is_empty(): return
	var options=[]
	for item in items.slice(0,5):
		if item is Dictionary: options.append({"id":str(item.get("id","")),"name":str(item.get("name",item.get("title",""))).left(64)})
	var state={"player_id":local_id,"name":game.hero.name,"reward_id":game.party_reward_id,"source":source,"kind":kind,"elite":elite,"options":options,"selected_id":""}
	game.party_seen[str(local_id)]=state
	if hosting: broadcast({"type":"reward_options","state":state})
	else: send_to(owner_id,{"type":"reward_options","state":state})
	game.hud.show_party_panel(game.party_seen)

func publish_reward_choice(item: Dictionary,source: String):
	if not active or game.party_reward_id.is_empty(): return
	var key=str(local_id);var state=game.party_seen.get(key,{"player_id":local_id,"name":game.hero.name,"reward_id":game.party_reward_id,"source":source,"options":[]})
	state.selected_id=str(item.get("id",""));state.selected_name=str(item.get("name","Selected reward")).left(64)
	game.party_seen[key]=state
	var message={"type":"reward_chosen","player_id":local_id,"name":game.hero.name,"reward_id":game.party_reward_id,"source":source,"selected_id":state.selected_id,"selected_name":state.selected_name}
	if hosting: broadcast(message)
	else: send_to(owner_id,message)
	game.hud.show_party_panel(game.party_seen)

func publish_reward_skip(source: String):
	if not active or game.party_reward_id.is_empty(): return
	var key=str(local_id);var state=game.party_seen.get(key,{"player_id":local_id,"name":game.hero.name,"reward_id":game.party_reward_id,"source":source,"options":[]})
	state.selected_id="__skip__";state.selected_name="Kept weapons"
	game.party_seen[key]=state
	var message={"type":"reward_chosen","player_id":local_id,"name":game.hero.name,"reward_id":game.party_reward_id,"source":source,"selected_id":"__skip__","selected_name":"Kept weapons"}
	if hosting: broadcast(message)
	else: send_to(owner_id,message)
	game.hud.show_party_panel(game.party_seen)

func apply_reward_state(state: Dictionary):
	var player_id=int(state.get("player_id",0))
	if player_id<=0: return
	var options=[]
	var raw_options=state.get("options",[])
	if raw_options is Array:
		for item in raw_options.slice(0,5):
			if item is Dictionary: options.append({"id":str(item.get("id","" )).left(100),"name":str(item.get("name","Reward")).left(64)})
	game.party_seen[str(player_id)]={"player_id":player_id,"name":str(state.get("name","Player")).left(32),"reward_id":str(state.get("reward_id","")),"source":str(state.get("source","")),"kind":str(state.get("kind","")),"elite":bool(state.get("elite",false)),"options":options,"selected_id":str(state.get("selected_id","")),"selected_name":str(state.get("selected_name",""))}
	game.hud.show_party_panel(game.party_seen)

func apply_reward_choice(player_id: int,reward_id: String,selected_id: String,selected_name: String,source: String,name: String):
	if player_id<=0 or reward_id!=game.party_reward_id: return
	var key=str(player_id);var state=game.party_seen.get(key,{"player_id":player_id,"name":name,"reward_id":reward_id,"source":source,"options":[]})
	state.selected_id=selected_id.left(100);state.selected_name=selected_name.left(64)
	if str(state.get("name","")).is_empty(): state.name=name.left(32)
	game.party_seen[key]=state
	game.hud.show_party_panel(game.party_seen)

func receive(sender: int,message):
	if not message is Dictionary or not message.get("type","") is String: return
	if game.update.receive(sender,message): return
	var kind=message.type
	if kind=="test_shared":
		if test_mode and (members.has(sender) if hosting else sender==owner_id):
			var phase=str(message.get("phase",""));test_messages[phase]=message.get("data",{})
			if not hosting and phase=="reconnect_force":
				# A test drop may stay away briefly so the host observes the absence.
				test_reconnect_hold=clampf(float(message.get("data",{}).get("hold",0)),0,5)
				connection_lost.call_deferred()
		return
	if kind=="test_done":
		if test_mode and (members.has(sender) if hosting else sender==owner_id): test_finished_peers[sender]=int(message.get("realm",-1))
		return
	if hosting:
		if kind=="hello":
			if message.get("protocol","")!=PROTOCOL: send_to(sender,{"type":"reject","reason":"Different game version."});return
			var token=str(message.get("token","")).left(64);var resume_id=0
			if game.run_active:
				for old_id in members:
					if members[old_id].get("disconnected",false) and str(members[old_id].get("token",""))==token and Time.get_ticks_msec()/1000.0<=float(members[old_id].get("disconnect_until",0)):
						resume_id=int(old_id);break
				if resume_id==0: send_to(sender,{"type":"reject","reason":"This party is already playing. Rejoin with the same player profile within 40 seconds."});return
			else:
				if members.size()>=3: send_to(sender,{"type":"reject","reason":"Party is full."});return
			if resume_id>0:
				var restored=members[resume_id];members.erase(resume_id);restored.erase("disconnected");restored.erase("disconnect_until");restored.last_seen=Time.get_ticks_msec()/1000.0;restored.mode="playing";members[sender]=restored
				game.update.remap_peer_id(resume_id,sender)
				if game.party_seen.has(str(resume_id)):
					game.party_seen[str(sender)]=game.party_seen[str(resume_id)];game.party_seen[str(sender)].player_id=sender;game.party_seen.erase(str(resume_id))
				status="A player reconnected · %d / 4." % (members.size()+1)
				# Everything one-off broadcasts changed while the member was away.
				var opened=game.chests.filter(func(c):return c is Dictionary and c.get("opened",false) and is_instance_valid(c.get("node"))).map(func(c):return [int(c.node.position.x),int(c.node.position.y),int(c.node.position.z)])
				send_to(sender,{"type":"welcome","reconnected":true,"realm":game.realm,"opened_chests":opened})
			else:
				members[sender]={"mode":"loading","player_name":"Player","token":token,"last_seen":Time.get_ticks_msec()/1000.0};status="%d / 4 players. Ready to start." % (members.size()+1)
				send_to(sender,{"type":"welcome","reconnected":false});publish_lobby()
			return
		if not members.has(sender): return
		members[sender].last_seen=Time.get_ticks_msec()/1000.0
		if kind=="lobby_choice" and not game.run_active:
			var choices=game.rules.data.heroes.filter(func(h):return h.id==str(message.get("hero","")))
			if choices.is_empty(): return
			members[sender].hero=choices[0].id;members[sender].hero_name=choices[0].name
			members[sender].player_name=clean_player_name(message.get("player_name",members[sender].get("player_name","Player")))
			members[sender].ready=message.get("ready",false)==true
			publish_lobby()
		elif kind=="need_actors" and game.run_active and int(message.get("realm",-1))==game.realm:
			send_actor_descriptors(sender,message.get("ids",[]))
		elif kind=="pose":
			var p=vector(message.get("position",[]))
			if not p.is_finite() or maxf(absf(p.x),absf(p.z))>RealmWorld.EXTENT+10: return
			for key in ["position","yaw","model","name","cosmetic","mode","weapons","build","hp","shield_hp","stats","gold","rescue_hold","flower_realm","flowers"]:
				if message.has(key): members[sender][key]=message[key]
			if message.has("name"): members[sender].name=clean_player_name(message.name)
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
		elif kind=="reward_options" and game.run_active:
			var incoming=message.get("state",{})
			if not incoming is Dictionary or str(incoming.get("reward_id",""))!=game.party_reward_id: return
			var state=incoming.duplicate(true);state.player_id=sender;state.name=str(members[sender].get("name",incoming.get("name","Player"))).left(32)
			state.source=str(state.get("source","" )).left(24);state.kind=str(state.get("kind","")).left(24)
			var options=[]
			if state.get("options",[]) is Array:
				for item in state.options.slice(0,5):
					if item is Dictionary: options.append({"id":str(item.get("id","")).left(100),"name":str(item.get("name","Reward")).left(64)})
			state.options=options;game.party_seen[str(sender)]=state
			game.hud.show_party_panel(game.party_seen)
			broadcast({"type":"reward_options","state":state})
		elif kind=="reward_chosen" and game.run_active:
			var who=str(members[sender].get("name",message.get("name","Player"))).left(32)
			var reward_id=str(message.get("reward_id",""));var selected_id=str(message.get("selected_id",""))
			if reward_id!=game.party_reward_id: return
			var selected_name="Kept weapons" if selected_id=="__skip__" else ""
			if selected_id!="__skip__":
				var offered=game.party_seen.get(str(sender),{}).get("options",[])
				if not offered.any(func(item):return str(item.get("id",""))==selected_id): return
				selected_name=str(offered.filter(func(item):return str(item.get("id",""))==selected_id)[0].get("name",message.get("selected_name","Reward")))
			apply_reward_choice(sender,reward_id,selected_id,selected_name,str(message.get("source","")),who)
			# The host relays the accepted highlight to every peer.
			broadcast({"type":"reward_chosen","player_id":sender,"name":who,"reward_id":reward_id,"source":str(message.get("source","")),"selected_id":selected_id,"selected_name":selected_name})
		elif kind=="chest_request" and game.run_active:
			var accepted=false
			if int(message.get("realm",-1))==game.realm and game.mode=="playing" and not frozen() and float(members[sender].get("hp",0))>0:
				var requested=vector(message.get("position",[]));var p=vector(members[sender].get("position",[]))
				for chest in game.chests:
					if not chest.opened and chest.node.position.distance_to(requested)<.1 and p.distance_to(chest.node.position)<4:
						game.buy_chest(chest,sender);accepted=chest.opened;break
			if not accepted: send_to(sender,{"type":"chest_rejected","realm":game.realm})

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
					var now=Time.get_ticks_msec()/1000.0
					if now<float(members[sender].get("stomp_ready",0)): return
					var stats=members[sender].get("stats",{})
					members[sender].stomp_ready=now+4.5/(1+clampf(float(stats.get("slamRecovery",0)),0,5))
					enemy.hit_owner=sender
					game.hurt_enemy(enemy,float(stats.get("damage",15))*2*float(stats.get("slamPower",1)),"stomp")
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
				var cause=str(message.get("cause","hit"))
				if cause not in ["hit","crit","melee","slam","explosion","fire","poison","ice","sonic","thorn","aura","lightning","meteor","burrow","stomp","burn"]: cause="hit"
				game.hurt_enemy(enemy,damage,cause,str(message.get("mechanic","")));remote_hits+=1
				enemy.erase("hit_owner");enemy.status_owner=sender
				if not enemy.dead:
					var owned_ids=state.get("weapons",[]).map(func(w):return str(w.id))
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
					enemy.status_time=4;game.set_damage_status(enemy,"fire",float(stats.get("burn",0))+(10 if (mechanic=="flame" or mechanic.contains("fire")) else 0),sender);game.set_damage_status(enemy,"poison",float(stats.get("poison",0))+(9 if mechanic.contains("poison") else 0),sender);enemy.slow=maxf(enemy.slow,float(stats.get("slow",0)) + (.35 if mechanic.contains("ice") else 0))
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
		elif kind=="welcome":
			welcomed=true;reset_actor_sync()
			if bool(message.get("reconnected",false)):
				var host_realm=int(message.get("realm",game.realm))
				if host_realm!=game.realm: game.enter_realm(host_realm)
				for position in message.get("opened_chests",[]): apply_chest_hide(position)
				reconnecting=false;paused=false;game.mode=mode_before_drop;game.career.bump("coop_reconnects");status="Rejoined the active run.";game.hud.tell(status,5)
				sync_local_nameplate()
				if test_mode:
					test_messages["reconnected"]={"mode":game.mode};send_to(owner_id,{"type":"test_shared","phase":"reconnected","data":{"mode":game.mode}})
			else:
				status="Joined. Choose your hero and mark Ready.";publish_lobby_choice()
		elif kind=="lobby_state" and not game.run_active: lobby_roster=message.get("players",[])
		elif kind=="start":
			reset_actor_sync()
			game.start_run(int(message.seed))
			game.hud.close()
		elif kind=="realm": actor_info.clear();actor_requested.clear();game.enter_realm(int(message.realm));saw_realm=true
		elif kind=="actors_info" and int(message.get("realm",-1))==game.realm and message.get("actors",[]) is Array:
			for actor in message.actors:
				if actor is Dictionary and actor.has("id"): actor_info[int(actor.id)]=actor
		elif kind=="force_pulse_fx" and int(message.get("realm",-1))==game.realm: ForcePulse.visual(game,vector(message.position),str(message.key));saw_force_pulse=true
		elif kind=="world": apply_world(message)
		elif kind=="journey_announcement": game.Journey.announce(game,str(message.title),str(message.detail))
		elif kind=="shot": show_shot(message)
		elif kind=="hazard" and int(message.get("realm",-1))==game.realm:
			game.warn_at(vector(message.position),float(message.radius),float(message.delay),float(message.damage),str(message.style),true)
		elif kind=="boss_focus" and int(message.get("realm",-1))==game.realm:
			set_boss_focus(int(message.get("player_id",0)),str(message.get("name","Player")))
		elif kind=="boss_phase" and int(message.get("realm",-1))==game.realm:
			game.boss_phases_reached=maxi(int(game.boss_phases_reached),clampi(int(message.get("phase",0)),0,7)+1)
			game.hud.tell("BARON · "+str(message.get("name","THE WRATH")),4)
			game.sound.boss_curse(vector(message.get("position",[])),int(message.get("index",10)),true)
			if test_mode:test_messages["boss_phase_"+str(int(message.get("phase",-1))) ]={"name":str(message.get("name","")),"index":int(message.get("index",-1))}
		elif kind=="boss_voice" and int(message.get("realm",-1))==game.realm:
			game.sound.boss_curse(vector(message.get("position",[])),int(message.get("index",10)),true)
		elif kind=="damage":
			game.take_damage(float(message.amount),vector(message.position),str(message.sound))
			if message.get("status","")=="poison" and not game.buffs.has("poison"): game.player_poison=3
		elif kind=="kill":
			kills_received+=1
			for enemy in game.enemies:
				if enemy.net_id==int(message.id) and not enemy.dead: game.kill_enemy(enemy,str(message.cause));return
			if message.has("actor"): game.kill_enemy(game.spawn_network_enemy(message.actor),str(message.cause))
		elif kind=="reward_options":
			var state=message.get("state",{})
			if state is Dictionary and str(state.get("reward_id",""))==game.party_reward_id: apply_reward_state(state)
		elif kind=="reward_chosen":
			apply_reward_choice(int(message.get("player_id",0)),str(message.get("reward_id","")),str(message.get("selected_id","")),str(message.get("selected_name","")),str(message.get("source","")),str(message.get("name","Player")))
		elif kind=="level_up" and int(message.get("realm",-1))==game.realm:
			var shared_level=int(message.get("level",game.level))
			if shared_level<game.level or shared_level<=last_remote_reward_level: return
			if shared_level>last_remote_reward_level:
				last_remote_reward_level=shared_level
				game.heal(game.stats.maxHp*.15)
				game.shield_hp=game.stats.shield
			game.level=shared_level
			game.xp=int(message.get("xp",game.xp))
			game.xp_target=int(message.get("xp_target",game.xp_target))
			game.open_shared_offer(message.get("offers",[]),str(message.get("kind","skill")),bool(message.get("elite",false)),"level",str(message.get("reward_id","")))
		elif kind=="chest_paid" and int(message.get("realm",-1))==game.realm:
			game.pending_chest=false;var price=int(message.get("price",0));game.gold=maxi(0,game.gold-price)
			if price>0: game.paid_chests+=1
			game.run_chests+=1;game.career.bump("chests");game.heal(game.stats.chestHeal)
		elif kind=="chest_rejected": game.pending_chest=false;game.hud.tell("Chest unavailable or not enough coins")
		elif kind=="chest_open" and int(message.get("realm",-1))==game.realm:
			game.open_shared_offer(message.get("offers",[]),str(message.get("kind","item")),bool(message.get("elite",false)),"chest",str(message.get("reward_id","")))
		elif kind=="chest_hide" and int(message.get("realm",-1))==game.realm:
			apply_chest_hide(message.get("pos",[]))

		elif kind=="finish": game.end_run(bool(message.win))

func ensure_avatar(id: int,state: Dictionary):
	sync_flowers(id,state)
	if id==local_id or not state.has("model"): return
	if not avatars.has(id):
		var model=str(state.model)
		if not game.rules.data.heroes.any(func(h):return h.model==model): return
		var node=CharacterBody3D.new();node.collision_layer=2;node.collision_mask=1
		var collider=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=.42;capsule.height=1.6;collider.shape=capsule;collider.position.y=.8;node.add_child(collider)
		var definition=game.rules.data.heroes.filter(func(h):return h.model==model)[0]
		capsule.radius=float(definition.get("radius",.42));capsule.height=maxf(float(definition.get("height",1.65)),capsule.radius*2);collider.position.y=capsule.height*.5
		if definition.id=="white-supra":
			var box=BoxShape3D.new();box.size=Vector3(capsule.radius*2,definition.height,2.3);collider.shape=box;collider.position.y=definition.height*.5
		var rig=game.world.model(model,float(definition.get("height",1.65)));node.add_child(rig);node.set_meta("rig",rig);game.add_child(node);avatars[id]=node
		var nameplate=Label3D.new();nameplate.text=clean_player_name(state.get("name","Player"));nameplate.position.y=float(definition.get("height",1.65))+.55;nameplate.font_size=26;nameplate.pixel_size=.01;nameplate.billboard=BaseMaterial3D.BILLBOARD_ENABLED;nameplate.modulate=Color("fff1d1");nameplate.outline_modulate=Color("263138");nameplate.outline_size=6;node.add_child(nameplate);node.set_meta("nameplate",nameplate)
		# A long, translucent cyan column makes a fallen teammate findable
		# over terrain, while the screen-edge marker works out of view.
		var beacon=MeshInstance3D.new()
		var beam_mesh=CylinderMesh.new();beam_mesh.top_radius=.09;beam_mesh.bottom_radius=.28;beam_mesh.height=26;beam_mesh.radial_segments=10
		beacon.mesh=beam_mesh;beacon.position=Vector3(0,13,0)
		var beacon_material=StandardMaterial3D.new()
		beacon_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		beacon_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		beacon_material.albedo_color=Color(0.18,0.82,1.0,0.32)
		beacon_material.emission_enabled=true;beacon_material.emission=Color("45c5ef")
		beacon.material_override=beacon_material
		beacon.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beacon.visible=false;node.add_child(beacon);node.set_meta("down_beacon",beacon)
		if state.has("position"): node.position=vector(state.position)
	update_avatar_vitals(avatars[id].get_meta("rig"),state)
	var wanted={}
	for weapon in state.get("weapons",[]):
		if not weapon is Dictionary or not weapon.has("placement") or not game.rules.data.weapons.any(func(w):return w.id==weapon.get("id","") and w.turret): continue
		var key=str(id)+":"+str(weapon.id);wanted[key]=true
		if not turret_models.has(key):
			var turret=WeaponModel.new();turret.setup(weapon.id);turret.rank=int(weapon.rank);turret.scale=Vector3.ONE*1.7;game.add_child(turret);turret_models[key]=turret
		turret_models[key].position=vector(weapon.placement)+Vector3.UP*.75;turret_models[key].rank=int(weapon.rank);turret_models[key].transform_rank()
	for key in turret_models.keys():
		if key.begins_with(str(id)+":") and not wanted.has(key): turret_models[key].queue_free();turret_models.erase(key)

func apply_chest_hide(position):
	if not position is Array or position.size()!=3: return
	for chest in game.chests:
		if not chest is Dictionary or not is_instance_valid(chest.get("node")): continue
		var p=chest.node.position
		if int(p.x)==int(position[0]) and int(p.y)==int(position[1]) and int(p.z)==int(position[2]):
			chest.opened=true
			chest.node.visible=false
			break

func apply_world(message: Dictionary):
	if not game.run_active or int(message.realm)!=game.realm: return
	# Unreliable snapshots can arrive late; never roll state back to an older one.
	var seq=int(message.get("seq",0))
	if seq>0:
		if seq<last_snapshot_seq: return
		last_snapshot_seq=seq
	# Refresh shared progression even when no level-up message is in flight.
	game.level=int(message.get("level",game.level))
	game.xp=int(message.get("xp",game.xp))
	game.xp_target=int(message.get("xp_target",game.xp_target))
	game.update.run_xp=int(message.get("run_xp",game.update.run_xp))
	var drop_ids={}
	for drop in message.get("xp_drops",[]):
		var drop_id=int(drop.id);drop_ids[drop_id]=true
		var matches=game.pickups.filter(func(p):return p.kind=="xp" and p.net_id==drop_id)
		var pickup={}
		if matches.is_empty():
			game.spawn_pickup(vector(drop.position),"xp",float(drop.value),true)
			pickup=game.pickups[-1];pickup.net_id=drop_id
		else: pickup=matches[0]
		pickup.value=float(drop.value);pickup.target_position=vector(drop.position);pickup.magnet_heap=bool(drop.get("heap",false));game.resize_xp(pickup,true)
	for pickup in game.pickups:
		if pickup.kind=="xp" and not drop_ids.has(pickup.net_id): pickup.age=-1;pickup.node.queue_free()
	game.pickups=game.pickups.filter(func(p):return p.age>=0)
	game.update.apply_state(message.get("big_update",{}))
	game.events=message.get("journey",game.events).duplicate(true);game.realm_bosses=int(message.get("wardens",game.realm_bosses))
	snapshots_received+=1;paused=bool(message.pause);saw_pause=saw_pause or paused
	# Smooth time sync: lerp client time toward host to prevent jumps
	var target_time=float(message.seconds)
	if game.realm_time>0:
		game.realm_time=lerp(game.realm_time,target_time,0.18)
	else:
		game.realm_time=target_time
	game.elapsed=float(message.elapsed)
	for id in message.players:
		var number=int(id)
		if number==local_id: continue
		members[number]=message.players[id];ensure_avatar(number,members[number])
	for id in avatars.keys():
		if not message.players.has(str(id)) and not message.players.has(id): avatars[id].queue_free();avatars.erase(id);members.erase(id)
	var packed=message.get("actors",PackedFloat32Array())
	if not packed is PackedFloat32Array: packed=PackedFloat32Array()
	var known={}
	for enemy in game.enemies: known[int(enemy.net_id)]=enemy
	var ids={};var missing=[]
	for base in range(0,packed.size()-ACTOR_STRIDE+1,ACTOR_STRIDE):
		var id=int(packed[base]);ids[id]=true
		var found=known.get(id,{})
		if found.is_empty():
			if not actor_info.has(id): missing.append(id);continue
			found=game.spawn_network_enemy(actor_info[id]);actor_info.erase(id);known[id]=found
		if found.is_empty() or found.dead: continue
		EnemySurface.replicate(found,Vector3(packed[base+6],packed[base+7],packed[base+8]),Vector3(packed[base+9],packed[base+10],packed[base+11]))
		EclipseCorruption.apply(found,int(packed[base+19]))
		found.hp=packed[base+4];found.maxHp=packed[base+5];found.target_position=Vector3(packed[base+1],packed[base+2],packed[base+3])
		for i in range(ACTOR_STATUS.size()): found[ACTOR_STATUS[i]]=packed[base+12+i]
	request_actors(missing)
	for enemy in game.enemies:
		if not ids.has(enemy.net_id) and not enemy.dead: enemy.dead=true;enemy.node.queue_free()

func hit(enemy: Dictionary,damage: float,mechanic: String="",origin: Vector3=Vector3.ZERO,cause: String="hit"):
	if active and not hosting: send_to(owner_id,{"type":"hit","id":enemy.net_id,"damage":damage,"mechanic":mechanic,"origin":array(origin),"cause":cause})

func stomp(enemy: Dictionary):
	if active and not hosting: send_to(owner_id,{"type":"stomp","id":enemy.net_id})

func died(enemy: Dictionary,cause: String):
	if active and hosting: broadcast({"type":"kill","id":enemy.net_id,"position":array(enemy.node.position),"cause":cause,"actor":actor_descriptor(enemy)})

func target(origin: Vector3) -> Dictionary:
	var result={"id":local_id,"position":game.player.position};var distance=origin.distance_squared_to(game.player.position) if game.hp>0 else INF
	if active and hosting:
		for id in members:
			var member=members[id]
			if member.get("disconnected",false): continue
			if not member.has("position") or member.get("hp",0)<=0: continue
			var p=vector(member.position);var d=origin.distance_squared_to(p)
			if d<distance: distance=d;result={"id":id,"position":p}
	return result

func damage_player(id: int,amount: float,origin: Vector3,sound: String,status: String=""):
	if id==local_id: game.take_damage(amount,origin,sound)
	elif hosting:
		if game.update.downed_ids.has(id): return
		members[id].rescue_hold=false
		members[id].rescue_interrupt_until=game.elapsed+.4
		game.update.rescue_progress.clear()
		send_to(id,{"type":"damage","amount":amount,"position":array(origin),"sound":sound,"status":status})

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

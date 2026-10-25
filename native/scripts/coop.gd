extends Node

class_name CoopSession

var flower_visuals={}
var party_seen={}

# Transport-independent authoritative world. Important events are reliable;
# poses/snapshots use unreliable ordered delivery. Never deserialize objects.
const PROTOCOL="wildforge-shared-world-16"
# Big fights: only this many XP orbs (nearest any hero) travel in a world packet.
const XP_SYNC_LIMIT=200
# World snapshots carry each enemy as ACTOR_STRIDE floats: id, position(3), hp,
# maxHp, surface up(3), surface forward(3), ACTOR_STATUS(8), corruption. Static
# identity (species, size, boss/elite flags) is sent once via actors_info.
const ACTOR_STRIDE=21
# Split world packets stay under the 1,392-byte ENet MTU (about 1,180 and 1,120 bytes).
const ACTORS_PER_PACKET=13
const ORBS_PER_PACKET=45
const ACTOR_STATUS=["fire","poison","freeze","blind","slip_until","windup","contact_windup","elite_shield"]
const PORT=29736
const DISCOVERY_PORT=29737
# Automated tests run on ports of their own (WILDFORGE_COOP_PORT, set by the agent
# workflow), so a test party never meets a real game hosting on this PC (user
# report, October 24: a test guest joined the user's party).
var party_port=env_port()
var discovery_port=party_port+1
static func env_port() -> int:
	var value=OS.get_environment("WILDFORGE_COOP_PORT")
	return int(value) if value.is_valid_int() and int(value)>1024 and int(value)<65000 else PORT
# Internet hosting: the router opens PORT through UPnP on a worker thread and
# reports the public address, which becomes the party's invite code.
# The gateway device that holds our mapping, and the outside port it opened.
var upnp: UPNPDevice
var upnp_port=party_port
var upnp_thread: Thread
var invite=""
# Peer ids the host transport currently has, from its connect/disconnect
# signals: asking ENet for an unknown id logs an engine error.
var linked={}
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
var party_combos_seen=0
var test_finished_peers={}
var joined=false
var saw_pause=false
var saw_realm=false
var turret_models={}
var last_remote_reward_level=1
# Shared rewards (level-ups, chests) the host broadcast recently: a player who
# rejoins is sent the ones broadcast while they were away.
var reward_log=[]
# A guest's shared rewards that arrived while another was still open, and the
# rewards already opened (a replay after a rejoin must not open one twice).
var queued_offers=[]
var rewards_seen={}
var review_lag_ms=0
var review_packet_queue=[]
var reconnecting=false
var stats_sent={}
var stats_clock=0.0
var reconnect_attempting=false
var disconnect_started=0.0
var snapshot_seq=0
var last_snapshot_seq=-1
# Last snapshot seq applied per enemy, orb and player (split packets).
var actor_seq={}
var orb_seq={}
var player_seq={}
var ids_seq={}
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
	game.hud.tell("THE COLOSSUS MARKS "+clean_player_name(name)+" · MOVE",3.0)
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
			search.set_dest_address(address,discovery_port);search.put_packet(JSON.stringify({"query":PROTOCOL}).to_utf8_buffer())
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
	var error=peer.create_server(party_port,3)
	if error!=OK: status="Could not open party port "+str(party_port)+". Another copy of the game may be hosting.";peer=null;return
	transport="lan";active=true;hosting=true;local_id=1;owner_id=1
	discovery=PacketPeerUDP.new()
	if discovery.bind(discovery_port,"0.0.0.0")!=OK: discovery=null
	publish_lobby()
	peer.peer_connected.connect(func(id):linked[id]=true)
	peer.peer_disconnected.connect(func(id):linked.erase(id))
	peer.peer_disconnected.connect(remove_member);status="Party ready on your network · %s · UDP %d. Friends can also join after the run starts." % [", ".join(local_addresses()),party_port]

# Opens the party to the internet. Only the HOST PARTY button calls this:
# automated tests never change a router's port mappings.
func open_internet():
	if not hosting or upnp_thread!=null or not invite.is_empty(): return
	upnp_thread=Thread.new();upnp_thread.start(upnp_work)
	status="Party ready on your network · opening internet access…"

# Router result names (UPNP.UPNP_RESULT_*), for messages players can report back.
const UPNP_RESULTS=["success","not authorized","mapping not found","inconsistent parameters","no such entry","action failed","source IP wildcard not permitted","external port wildcard not permitted","internal port wildcard not permitted","remote host must be wildcard","external port must be wildcard","no port maps available","conflict with another mechanism","conflict with another mapping","same port values required","only permanent leases supported","invalid gateway","invalid port","invalid protocol","invalid duration","invalid arguments","invalid response","invalid parameter","HTTP error","socket error","out of memory","no gateway","no devices","unknown error"]

static func upnp_result(code: int) -> String:
	return UPNP_RESULTS[code] if code>=0 and code<UPNP_RESULTS.size() else "error %d" % code

# A modem that answers but whose own outside address is private (status 5,
# "disconnected" in the engine's naming) sits behind the provider's shared
# network: no mapping on it can be reached from the internet. Seen on a Huawei
# EchoLife reporting "Connected" with outside address 10.254.50.76.
static func provider_nat(statuses: Array) -> bool:
	return statuses.has(UPNPDevice.IGD_STATUS_DISCONNECTED)

static func gateways(router: UPNP) -> Array:
	var found=[]
	for i in range(router.get_device_count()):
		var device=router.get_device(i)
		if device!=null and device.is_valid_gateway(): found.append(device)
	return found

# Runs on a worker thread. Some routers only answer one style of search, some
# refuse permanent (or only accept permanent) mappings, and another device may
# already hold the port, so each is tried in turn. Every step is logged so a
# failure can say exactly what the router answered.
func upnp_work() -> Dictionary:
	var log=[];var router=UPNP.new();var devices=[]
	for search in [[2500,2,"InternetGatewayDevice"],[3500,4,"WANIPConnection"],[3500,4,""]]:
		var code=router.discover(search[0],search[1],search[2])
		devices=gateways(router)
		log.append("search '%s': %s, %d devices, %d gateways" % [search[2] if search[2]!="" else "all",upnp_result(code),router.get_device_count(),devices.size()])
		if not devices.is_empty() or router.get_device_count()>0: break
	if devices.is_empty():
		var statuses=[]
		for i in range(router.get_device_count()):
			var device=router.get_device(i);statuses.append(device.igd_status)
			log.append("device %s: status %d" % [device.description_url,device.igd_status])
		if provider_nat(statuses): return {"error":"carrier","address":"","log":log}
		return {"error":"no_router","log":log}
	var last=""
	for device in devices:
		log.append("gateway %s via %s" % [device.description_url,device.igd_our_addr])
		for external_port in [party_port,party_port+10,party_port+20]:
			var conflict=false
			for lease in [0,7200]:
				var code=device.add_port_mapping(external_port,party_port,"Wildforge co-op","UDP",lease)
				last=upnp_result(code)
				log.append("  map UDP %d -> %d lease %d: %s" % [external_port,party_port,lease,last])
				if code==UPNP.UPNP_RESULT_SUCCESS:
					var external=device.query_external_address()
					log.append("  public address: %s" % (external if external!="" else "none"))
					if external.is_empty() or InviteCode.unreachable(external):
						device.delete_port_mapping(external_port,"UDP");return {"error":"carrier","address":external,"log":log}
					return {"router":device,"port":external_port,"address":external,"log":log}
				if code==UPNP.UPNP_RESULT_CONFLICT_WITH_OTHER_MAPPING: conflict=true;break
			if not conflict: break
	return {"error":"refused","reason":last,"log":log}

func upnp_finished(result: Dictionary):
	var lan="Friends on your network: "+", ".join(local_addresses())
	# The full attempt log, for reporting what the router answered.
	var file=FileAccess.open("user://coop-upnp.log",FileAccess.WRITE)
	if file!=null: file.store_string("\n".join(result.get("log",[])));file.close()
	if not hosting:
		if result.has("router"): result.router.delete_port_mapping(int(result.port),"UDP")
		return
	match str(result.get("error","")):
		"no_router":
			status="Internet hosting unavailable: no router answered the automatic port-opening request (UPnP). Check that UPnP is on in the router and that Windows Firewall allows Wildforge (Windows Security · Firewall · Allow an app). Or forward UDP %d to this PC by hand and give friends your public IP. %s" % [party_port,lan]
		"refused":
			status="Internet hosting unavailable: the router answered but refused to open UDP %d (router said: %s). Forward UDP %d to this PC by hand and give friends your public IP, or let a friend host. %s" % [party_port,str(result.get("reason","")),party_port,lan]
		"carrier":
			status="Internet hosting unavailable: your modem answered, but its own outside address is private. Your internet provider shares one public address between customers (carrier-grade NAT), so friends cannot reach this PC, whatever the router settings. Let a friend host, or ask your provider for a public IP address. %s" % lan
		_:
			upnp=result.router;upnp_port=int(result.port);invite=InviteCode.encode(str(result.address),upnp_port)
			DisplayServer.clipboard_set(invite)
			status="Party open to the internet · invite code %s (copied). Friends paste it into Join. %s" % [invite,lan]
	game.hud.tell("Invite code copied: "+invite if not invite.is_empty() else "Internet hosting unavailable · see the party panel",5)

func close_internet():
	if upnp_thread!=null:
		var result=upnp_thread.wait_to_finish();upnp_thread=null
		if result is Dictionary and result.has("router"): result.router.delete_port_mapping(int(result.port),"UDP")
	if upnp!=null: upnp.delete_port_mapping(upnp_port,"UDP");upnp=null
	invite=""

func _exit_tree():
	close_internet()

func join_lan(address: String):
	address=address.strip_edges()
	var code=InviteCode.decode(address)
	if not code.is_empty(): leave();open_client(code.address,code.port);return
	if address.is_empty() or address.length()>253 or address.contains(" ") or address.contains("/"):
		status="Enter an invite code (WF-…) or the host's IP address.";return
	leave();open_client(address)

# Opens only the client transport. A run rejoin keeps avatars, nameplates and
# reward progress; leave() is reserved for actually quitting the party.
func open_client(address: String,port: int=-1):
	if port<0: port=party_port
	peer=ENetMultiplayerPeer.new()
	var err=peer.create_client(address,port)
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
	linked.clear()
	close_internet()
	if discovery!=null: discovery.close();discovery=null
	for actor in avatars.values(): actor.queue_free()
	for turret in turret_models.values(): turret.queue_free()
	turret_models.clear()
	avatars.clear();members.clear();active=false;hosting=false;paused=false;transport="";joined=false;welcomed=false;connection_clock=0;last_snapshot=0;last_remote_reward_level=1;reward_log.clear();queued_offers.clear();rewards_seen.clear()
	reset_actor_sync()

func close_transport():
	if peer!=null: peer.close();peer=null
	active=false;welcomed=false;joined=false

func reset_actor_sync():
	last_snapshot_seq=-1;actor_info.clear();actor_requested.clear();actor_seq.clear();orb_seq.clear();player_seq.clear();ids_seq.clear()

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
		members[id].away_since=float(members[id].get("last_seen",Time.get_ticks_msec()/1000.0))
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
		# World snapshots and poses stay unreliable at any size: a newer one supersedes
		# a lost one, and reliable delivery would stall events behind stale state.
		var unreliable=not reliable and (bytes.size()<=1000 or message.get("type","") in ["world","world_actors","world_orbs","world_players","world_ids","pose"])
		peer.set_target_peer(id);peer.transfer_mode=MultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED if unreliable else MultiplayerPeer.TRANSFER_MODE_RELIABLE;peer.put_packet(bytes)

func broadcast(message: Dictionary,reliable: bool=true):
	if hosting and message.get("type","") in ["level_up","chest_open"]:
		reward_log.append({"time":Time.get_ticks_msec()/1000.0,"message":message})
		if reward_log.size()>24: reward_log.pop_front()
	for id in members:
		if not members[id].get("disconnected",false) and transport_peer_connected(int(id)): send_to(id,message,reliable)

func transport_peer_connected(id: int) -> bool:
	if peer==null or peer.get_connection_status()!=MultiplayerPeer.CONNECTION_CONNECTED: return false
	# A client checks its actual link to the host: after a connection dies without
	# notice the transport still reports connected for a moment.
	if not hosting:
		var host=peer.get_peer(1)
		return host!=null and host.get_state()==ENetPacketPeer.STATE_CONNECTED
	if not linked.has(id): return false
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
	if upnp_thread!=null and not upnp_thread.is_alive():
		var result=upnp_thread.wait_to_finish();upnp_thread=null;upnp_finished(result)
	discover_tick(delta)
	if not active: return
	if not queued_offers.is_empty() and game.mode=="playing" and game.run_active:
		var next=queued_offers.pop_front()
		if int(next[5])==game.realm: game.open_shared_offer(next[0],next[1],next[2],next[3],next[4],next[6])
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
				leave();status="Could not reach the party. Check the invite code or address. Over the internet, the host needs the invite code shown when hosting; if their game said internet hosting is unavailable, one of you behind a different connection should host.";return
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
			if game.run_active and not members.is_empty():
				for packet in snapshot_packets(): broadcast(packet,false)
		else:
			# Before the host's welcome a rejoining client still reports its
			# disconnected "paused" mode, which would freeze the host's run.
			if welcomed:
				send_to(owner_id,pose(),false)
				stats_clock-=.10
				if stats_clock<=0: stats_clock=.5;send_stats()
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
				var ms=ping_for(int(id),state)
				var ping_text=(" · %d ms" % ms) if ms>0 else ""
				label.text=("⚠ "+player_text+" · TARGET" if targeted else str(style.mark)+player_text+ping_text+("\nDOWNED · HOLD E / X" if is_downed else ""))
				label.font_size=36 if targeted else 26;label.pixel_size=.012 if targeted else .01;label.modulate=Color("ff9675") if targeted else style.color
			if node.has_meta("down_beacon"): node.get_meta("down_beacon").visible=is_downed
			update_avatar_vitals(node.get_meta("rig"),state)
	if is_instance_valid(local_nameplate): sync_local_nameplate()

# Round trip in milliseconds to a peer this machine talks to directly (the host
# to each player, a player to the host); 0 when unknown.
func ping_to(id: int) -> int:
	if transport!="lan" or not transport_peer_connected(id): return 0
	var link=peer.get_peer(id)
	# A connection that died without notice still has a peer object but no link.
	return int(link.get_statistic(ENetPacketPeer.PEER_ROUND_TRIP_TIME)) if link!=null and link.get_state()==ENetPacketPeer.STATE_CONNECTED else 0

# Shown on nameplates. Players hear about each other through the host, so a
# player's ping to another player is shown as that player's ping to the host.
func ping_for(id: int,state: Dictionary) -> int:
	if hosting or id==owner_id: return ping_to(id)
	return int(state.get("ping",0))

func update_avatar_vitals(rig,state: Dictionary):
	var stats=state.get("stats",{})
	var vitals=state.get("vitals",{"max_hp":stats.get("maxHp",100),"armor":stats.get("armor",0),"shield_capacity":float(stats.get("shield",0))+float(stats.get("jumpShield",0))})
	if state.has("hp"): rig.set_health(float(state.hp)/maxf(1,float(vitals.get("max_hp",100))))
	rig.set_defense(float(vitals.get("armor",0)),float(state.get("shield_hp",0)),float(vitals.get("shield_capacity",0)))

# The stats the host needs from this player (chest luck, XP gain, damage caps).
# Consumable and conditional XP modifiers are computed by stat(), outside the
# permanent stats dictionary, so the host gets the live values.
func effective_stats() -> Dictionary:
	var effective=game.stats.duplicate()
	effective.xpGain=game.stat("xpGain")
	for key in effective.keys():
		if str(key).begins_with("augment-"): effective.erase(key)
	for key in game.conditional_bonuses: effective[key]=game.stat(key)
	return effective

# Stats travel apart from the 10-per-second pose, reliably and only as changed
# values: with them the pose was 3.6 KB, over the unreliable limit, and a
# reliable pose stalls behind resends over the internet (a frozen teammate).
func send_stats(force: bool=false):
	var current=effective_stats();var changes={}
	for key in current:
		if force or not stats_sent.has(key) or stats_sent[key]!=current[key]: changes[key]=current[key]
	if changes.is_empty(): return
	stats_sent.merge(changes,true)
	send_to(owner_id,{"type":"stats","changes":changes})

func pose() -> Dictionary:
	var weapons=[]
	for weapon in game.equipped:
		var state={"id":weapon.id,"rank":weapon.rank,"evolved":weapon.get("evolved",false)}
		if weapon.turret and is_instance_valid(weapon.get("node")): state.placement=array(weapon.node.position)
		weapons.append(state)
	var build={"weapons":weapons,"skills":game.owned.filter(func(item):return item.kind in ["skill","mutation"]).map(func(item):return str(item.name).left(48))}
	return {"type":"pose","flower_realm":game.realm,"flowers":flower_state(),"position":array(game.player.position),"yaw":game.avatar.rotation.y,"model":game.hero.model,"name":player_name(),"cosmetic":str(game.career.data.settings.get("cosmetic","")),"mode":"ended" if game.run_recorded else game.mode,"weapons":weapons,"build":build,"hp":game.hp,"shield_hp":game.shield_hp,"gold":game.gold,"rescue_hold":game.update.rescue_hold}

# Everything a client needs to construct a replica of a host enemy.
func actor_descriptor(enemy: Dictionary) -> Dictionary:
	return {"id":enemy.net_id,"position":array(enemy.node.position),"biome":enemy.biome,"species":enemy.species,"height":enemy.height,"radius":enemy.radius,"hp":enemy.hp,"maxHp":enemy.maxHp,"xp_reward":enemy.xp_reward,"boss":enemy.boss,"boss_id":enemy.get("boss_id",-1),"guardian":enemy.get("guardian",false),"magnet_guard":enemy.get("magnet_guard",false),"title":enemy.get("title",""),"modifier":enemy.get("modifier",""),"elite":enemy.elite,"corruption":enemy.get("corruption",0),"surface_up":array(enemy.node.basis.y),"surface_forward":array(-enemy.node.basis.z),"fire":enemy.fire,"poison":enemy.poison,"freeze":enemy.freeze,"blind":enemy.blind,"slip_until":enemy.get("slip_until",0),"windup":enemy.get("windup",0),"contact_windup":enemy.get("contact_windup",0)}

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
		actors.append_array(PackedFloat32Array([enemy.net_id,p.x,p.y,p.z,enemy.hp,enemy.maxHp,up.x,up.y,up.z,forward.x,forward.y,forward.z,enemy.fire,enemy.poison,enemy.freeze,enemy.blind,enemy.get("slip_until",0),enemy.get("windup",0),enemy.get("contact_windup",0),enemy.get("elite_shield",0),enemy.get("corruption",0)]))
	snapshot_seq+=1
	var poses={}
	for id in members:
		if not members[id].get("disconnected",false): poses[id]=members[id].duplicate(true)
	poses[local_id]=pose();poses[local_id].stats=game.stats
	for id in poses: poses[id].ping=ping_to(int(id)) if int(id)!=local_id else 0
	for member in poses.values():
		var stats=member.get("stats",{})
		member.vitals={"max_hp":stats.get("maxHp",100),"armor":stats.get("armor",0),"shield_capacity":float(stats.get("shield",0))+float(stats.get("jumpShield",0))}
		member.erase("stats");member.erase("last_seen")
	return {"type":"world","seq":snapshot_seq,"actors":actors,"players":poses,"seconds":game.realm_time,"elapsed":game.elapsed,"realm":game.realm,"journey":game.events,"wardens":game.realm_bosses,"level":game.level,"xp":game.xp,"xp_target":game.xp_target,"run_xp":game.update.run_xp,"pause":frozen() or game.mode not in ["playing","ended"],"big_update":game.update.world_state(),"xp_orbs":xp_state()}

# XP orbs as packed numbers (id, position, value, heap flag), nearest to any hero
# first. As dictionaries 300 orbs took 36 KB and pushed the world packet toward
# the 60 KB drop limit in big fights.
func xp_state() -> PackedFloat32Array:
	var heroes=[game.player.position]
	for id in members:
		if not members[id].get("disconnected",false): heroes.append(vector(members[id].get("position",[])))
	var orbs=game.pickups.filter(func(p):return p.kind=="xp" and p.age>=0)
	if orbs.size()>XP_SYNC_LIMIT:
		var keyed=orbs.map(func(p):return [heroes.map(func(h):return p.node.position.distance_squared_to(h)).min(),p])
		keyed.sort_custom(func(a,b):return a[0]<b[0]);orbs=keyed.slice(0,XP_SYNC_LIMIT).map(func(item):return item[1])
	var packed=PackedFloat32Array()
	for p in orbs:
		var at: Vector3=p.node.position
		packed.append_array(PackedFloat32Array([p.net_id,at.x,at.y,at.z,p.value,1.0 if p.get("magnet_heap",false) else 0.0]))
	return packed

static func array(v: Vector3) -> Array: return [v.x,v.y,v.z]
static func vector(v) -> Vector3:
	if not v is Array or v.size()!=3: return Vector3.ZERO
	return Vector3(float(v[0]),float(v[1]),float(v[2]))

# Opens a shared reward, or queues it while another is still open: a second
# reward used to replace the first, which was lost.
func shared_offer(pool,kind: String,elite: bool,source: String,reward_id: String,event: bool=false):
	if not reward_id.is_empty():
		if rewards_seen.has(reward_id): return
		rewards_seen[reward_id]=true
	if game.mode in ["offer","replace","reveal","level_reveal"] and game.party_reward_id!=reward_id:
		queued_offers.append([pool,kind,elite,source,reward_id,game.realm,event]);return
	game.open_shared_offer(pool,kind,elite,source,reward_id,event)

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
				# "silent": the connection dies without telling the host, as over the
				# internet, so the host still believes the old connection is alive.
				if bool(message.get("data",{}).get("silent",false)) and peer!=null and peer.get_peer(1)!=null: peer.get_peer(1).reset()
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
					if token.is_empty() or str(members[old_id].get("token",""))!=token: continue
					if members[old_id].get("disconnected",false) and Time.get_ticks_msec()/1000.0>float(members[old_id].get("disconnect_until",0)): continue
					# The player's game gave up first (12 s without world packets) while this
					# side still thinks the old connection is alive: the same profile is
					# returning, not a new player. Drop the stale connection and its avatar,
					# or the party ends up with two of them.
					# The old id's avatar and turrets always go, whichever way it dropped.
					if avatars.has(old_id): avatars[old_id].queue_free();avatars.erase(old_id)
					for key in turret_models.keys():
						if key.begins_with(str(old_id)+":"): turret_models[key].queue_free();turret_models.erase(key)
					if not members[old_id].get("disconnected",false):
						linked.erase(old_id)
						if peer!=null and peer.get_peer(old_id)!=null: peer.disconnect_peer(old_id,true)
					resume_id=int(old_id);break
			# Up to four players; a new player may drop into a run in progress.
			if resume_id==0 and members.values().filter(func(m):return not m.get("disconnected",false)).size()>=3: send_to(sender,{"type":"reject","reason":"Party is full."});return
			if resume_id>0:
				# Rewards are replayed from shortly before the last packet heard: after a
				# silent drop the host kept sending to a connection that was already dead.
				var away_since=float(members[resume_id].get("away_since",members[resume_id].get("last_seen",0.0)))-2.0
				var restored=members[resume_id];members.erase(resume_id);restored.erase("away_since");restored.erase("disconnected");restored.erase("disconnect_until");restored.last_seen=Time.get_ticks_msec()/1000.0;restored.mode="playing";members[sender]=restored
				game.update.remap_peer_id(resume_id,sender)
				if game.party_seen.has(str(resume_id)):
					game.party_seen[str(sender)]=game.party_seen[str(resume_id)];game.party_seen[str(sender)].player_id=sender;game.party_seen.erase(str(resume_id))
				status="A player reconnected · %d / 4." % (members.size()+1)
				# Everything one-off broadcasts changed while the member was away.
				var opened=game.chests.filter(func(c):return c is Dictionary and c.get("opened",false) and is_instance_valid(c.get("node"))).map(func(c):return [int(c.node.position.x),int(c.node.position.y),int(c.node.position.z)])
				send_to(sender,{"type":"welcome","reconnected":true,"realm":game.realm,"opened_chests":opened})
				# Level-ups and chests shared while the player was away; their game
				# skips any it already opened.
				for entry in reward_log:
					if float(entry.time)>=away_since:
						var replay=entry.message.duplicate();replay.replay=true;send_to(sender,replay)
			elif game.run_active:
				# Drop-in: the joiner starts the same run and enters the host's realm;
				# the world pauses ("loading") until they are in.
				members[sender]={"mode":"loading","player_name":"Player","token":token,"last_seen":Time.get_ticks_msec()/1000.0,"drop_in":true}
				var opened=game.chests.filter(func(c):return c is Dictionary and c.get("opened",false) and is_instance_valid(c.get("node"))).map(func(c):return [int(c.node.position.x),int(c.node.position.y),int(c.node.position.z)])
				send_to(sender,{"type":"welcome","reconnected":false,"drop_in":true,"seed":game.seed_value,"realm":game.realm,"opened_chests":opened})
				status="A player is joining the run · %d / 4." % (members.size()+1);game.hud.tell("A friend is joining…",3)
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
		elif kind=="stats":
			var known: Dictionary=members[sender].get("stats",{})
			known.merge(message.get("changes",{}),true);members[sender].stats=known
		elif kind=="pose":
			# A late pose from a connection that already dropped would rebuild that
			# player's avatar; after they rejoin under a new id it stays as a ghost copy.
			if members[sender].get("disconnected",false): return
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
				if cause not in ["hit","crit","melee","slam","explosion","fire","poison","ice","sonic","thorn","aura","lightning","meteor","burrow","stomp","burn","gravity","bloom"]: cause="hit"
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
			welcomed=true;reset_actor_sync();stats_sent.clear();stats_clock=0.0
			if bool(message.get("reconnected",false)):
				var host_realm=int(message.get("realm",game.realm))
				if host_realm!=game.realm: game.enter_realm(host_realm)
				for position in message.get("opened_chests",[]): apply_chest_hide(position)
				reconnecting=false;paused=false;game.mode=mode_before_drop;game.career.bump("coop_reconnects");status="Rejoined the active run.";game.hud.tell(status,5)
				sync_local_nameplate()
				if test_mode:
					test_messages["reconnected"]={"mode":game.mode};send_to(owner_id,{"type":"test_shared","phase":"reconnected","data":{"mode":game.mode}})
			elif bool(message.get("drop_in",false)):
				reset_actor_sync();game.start_run(int(message.seed))
				var host_realm=int(message.get("realm",0))
				if host_realm!=game.realm: game.enter_realm(host_realm)
				for position in message.get("opened_chests",[]): apply_chest_hide(position)
				game.hud.close();sync_local_nameplate()
				status="Joined the run in progress.";game.hud.tell(status,5)
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
		elif kind=="party_combo" and int(message.get("realm",-1))==game.realm and str(message.get("kind","")) in ["crossfire","overload"]:
			PartyCombo.visual(game,str(message.kind),vector(message.get("position",[])));party_combos_seen+=1
		elif kind=="world": apply_world(message)
		elif kind in ["world_actors","world_orbs","world_players","world_ids"] and game.run_active and int(message.get("realm",-1))==game.realm:
			var seq=int(message.get("seq",0))
			if kind=="world_ids":
				var list=str(message.get("kind",""))
				if list in ["actors","orbs"] and fresh_item(ids_seq,list.hash(),seq):
					if list=="actors": remove_missing_actors(message.get("ids",PackedInt32Array()))
					else: remove_missing_orbs(message.get("ids",PackedInt32Array()))
			elif kind=="world_actors": apply_actors(message.get("actors"),seq)
			elif kind=="world_orbs": apply_orbs(message.get("xp_orbs"),seq)
			else: apply_players(message.get("players"),seq)
		elif kind=="journey_announcement": game.Journey.announce(game,str(message.title),str(message.detail))
		elif kind=="shot": show_shot(message)
		elif kind=="hazard" and int(message.get("realm",-1))==game.realm:
			game.warn_at(vector(message.position),float(message.radius),float(message.delay),float(message.damage),str(message.style),true)
		elif kind=="boss_focus" and int(message.get("realm",-1))==game.realm:
			set_boss_focus(int(message.get("player_id",0)),str(message.get("name","Player")))
		elif kind=="boss_phase" and int(message.get("realm",-1))==game.realm:
			game.boss_phases_reached=maxi(int(game.boss_phases_reached),clampi(int(message.get("phase",0)),0,7)+1)
			ColossusFight.show_phase(game,clampi(int(message.get("phase",0)),0,2))
			if test_mode:test_messages["boss_phase_"+str(int(message.get("phase",-1))) ]={"name":str(message.get("name","")),"index":int(message.get("index",-1))}
		elif kind=="colossus_action" and int(message.get("realm",-1))==game.realm: ColossusFight.replay(game,message)
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
		# A replayed reward (missed while away) counts even if the host has since
		# moved to another island.
		elif kind=="level_up" and (int(message.get("realm",-1))==game.realm or message.get("replay",false)):
			var shared_level=int(message.get("level",game.level))
			if shared_level<game.level or shared_level<=last_remote_reward_level: return
			if shared_level>last_remote_reward_level:
				last_remote_reward_level=shared_level
				game.heal(game.stats.maxHp*.15)
				game.shield_hp=game.stats.shield
			game.level=shared_level
			game.xp=int(message.get("xp",game.xp))
			game.xp_target=int(message.get("xp_target",game.xp_target))
			shared_offer(message.get("offers",[]),str(message.get("kind","skill")),bool(message.get("elite",false)),"level",str(message.get("reward_id","")))
		elif kind=="chest_paid" and int(message.get("realm",-1))==game.realm:
			game.pending_chest=false;var price=int(message.get("price",0));game.gold=maxi(0,game.gold-price)
			if price>0: game.paid_chests+=1
			game.run_chests+=1;game.career.bump("chests");game.heal(game.stats.chestHeal)
		elif kind=="chest_rejected": game.pending_chest=false;game.hud.tell("Chest unavailable or not enough coins")
		elif kind=="chest_open" and (int(message.get("realm",-1))==game.realm or message.get("replay",false)):
			shared_offer(message.get("offers",[]),str(message.get("kind","item")),bool(message.get("elite",false)),"chest",str(message.get("reward_id","")),bool(message.get("event",false)))
		elif kind=="biome_event": BiomeMechanics.spawn(game,message)
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
	# A full snapshot carries everything; a split one (snapshot_packets) carries
	# only the live ids here, with the orbs, players and enemies in their own packets.
	if message.has("xp_orbs"): apply_orbs(message.xp_orbs,seq);remove_missing_orbs(ids_in(message.xp_orbs,6))
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
	if message.has("players"): apply_players(message.players,seq)
	var player_ids=message.get("player_ids",message.get("players",{}).keys()).map(func(id):return int(id))
	for id in avatars.keys():
		if not player_ids.has(int(id)): avatars[id].queue_free();avatars.erase(id);members.erase(id)
	if message.has("actors"): apply_actors(message.actors,seq);remove_missing_actors(ids_in(message.actors,ACTOR_STRIDE))

# The host's world in packets under the network MTU: one core packet (time,
# progression, events, player ids), the ids of every live enemy and orb, and the
# enemies, XP orbs and players in packets of their own. A lost packet now costs only its own
# enemies for one tick; as one 13-fragment message, any lost fragment lost all of it.
func snapshot_packets() -> Array:
	var full=snapshot();var seq=full.seq;var realm=full.realm
	var core=full.duplicate();core.erase("actors");core.erase("xp_orbs");core.erase("players")
	core.player_ids=full.players.keys()
	var packets=[core]
	# Removals come from these lists: an enemy missing from a lost actor packet stays.
	packets.append({"type":"world_ids","seq":seq,"realm":realm,"kind":"actors","ids":ids_in(full.actors,ACTOR_STRIDE)})
	packets.append({"type":"world_ids","seq":seq,"realm":realm,"kind":"orbs","ids":ids_in(full.xp_orbs,6)})
	var actors: PackedFloat32Array=full.actors
	for begin in range(0,actors.size(),ACTOR_STRIDE*ACTORS_PER_PACKET): packets.append({"type":"world_actors","seq":seq,"realm":realm,"actors":actors.slice(begin,begin+ACTOR_STRIDE*ACTORS_PER_PACKET)})
	var orbs: PackedFloat32Array=full.xp_orbs
	for begin in range(0,orbs.size(),6*ORBS_PER_PACKET): packets.append({"type":"world_orbs","seq":seq,"realm":realm,"xp_orbs":orbs.slice(begin,begin+6*ORBS_PER_PACKET)})
	for id in full.players: packets.append({"type":"world_players","seq":seq,"realm":realm,"players":{id:full.players[id]}})
	return packets

static func ids_in(packed,stride: int) -> PackedInt32Array:
	var ids=PackedInt32Array()
	if packed is PackedFloat32Array:
		for base in range(0,packed.size()-stride+1,stride): ids.append(int(packed[base]))
	return ids

# A split packet: newer data for each item only (an item's last seq is kept).
func fresh_item(table: Dictionary,id: int,seq: int) -> bool:
	if seq>0 and seq<int(table.get(id,-1)): return false
	table[id]=seq;return true

func apply_orbs(orbs,seq: int):
	if not orbs is PackedFloat32Array: return
	# Index the client's orbs once: a search per orb cost 90,000 comparisons a
	# packet in a 300-orb fight.
	var by_id={}
	for pickup in game.pickups:
		if pickup.kind=="xp": by_id[int(pickup.net_id)]=pickup
	for i in range(0,orbs.size()-5,6):
		var drop_id=int(orbs[i]);var at=Vector3(orbs[i+1],orbs[i+2],orbs[i+3])
		if not fresh_item(orb_seq,drop_id,seq): continue
		var pickup=by_id.get(drop_id,{})
		if pickup.is_empty():
			game.spawn_pickup(at,"xp",orbs[i+4],true)
			pickup=game.pickups[-1];pickup.net_id=drop_id
		pickup.value=orbs[i+4];pickup.target_position=at;pickup.magnet_heap=orbs[i+5]>.5;game.resize_xp(pickup,true)

func remove_missing_orbs(ids):
	var alive={}
	for id in ids: alive[int(id)]=true
	for pickup in game.pickups:
		if pickup.kind=="xp" and not alive.has(int(pickup.net_id)): pickup.age=-1;pickup.node.queue_free();orb_seq.erase(int(pickup.net_id))
	game.pickups=game.pickups.filter(func(p):return p.age>=0)

func apply_players(players,seq: int):
	if not players is Dictionary: return
	for id in players:
		var number=int(id)
		if number==local_id or not fresh_item(player_seq,number,seq): continue
		members[number]=players[id];ensure_avatar(number,members[number])

func apply_actors(packed,seq: int):
	if not packed is PackedFloat32Array: return
	var known={}
	for enemy in game.enemies: known[int(enemy.net_id)]=enemy
	var missing=[]
	for base in range(0,packed.size()-ACTOR_STRIDE+1,ACTOR_STRIDE):
		var id=int(packed[base])
		if not fresh_item(actor_seq,id,seq): continue
		var found=known.get(id,{})
		if found.is_empty():
			if not actor_info.has(id): missing.append(id);continue
			found=game.spawn_network_enemy(actor_info[id]);actor_info.erase(id);known[id]=found
		if found.is_empty() or found.dead: continue
		EnemySurface.replicate(found,Vector3(packed[base+6],packed[base+7],packed[base+8]),Vector3(packed[base+9],packed[base+10],packed[base+11]))
		EclipseCorruption.apply(found,int(packed[base+12+ACTOR_STATUS.size()]))
		found.hp=packed[base+4];found.maxHp=packed[base+5];found.target_position=Vector3(packed[base+1],packed[base+2],packed[base+3])
		for i in range(ACTOR_STATUS.size()): found[ACTOR_STATUS[i]]=packed[base+12+i]
		EliteMods.replicate(found)
	request_actors(missing)

func remove_missing_actors(ids):
	var alive={}
	for id in ids: alive[int(id)]=true
	for enemy in game.enemies:
		if not alive.has(int(enemy.net_id)) and not enemy.dead: enemy.dead=true;enemy.node.queue_free();actor_seq.erase(int(enemy.net_id))

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
	game.remote_weapon_effect(weapon,origin,target_position,duration);game.sound.effect("slash" if weapon=="saw" else SkillBook.sound(weapon),origin)

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

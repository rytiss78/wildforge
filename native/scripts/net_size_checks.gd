extends RefCounted

# Co-op message sizes in a big late-game fight: 200 enemies, 300 XP orbs on the
# ground, a full build of cards and mutations. The world snapshot must stay far
# below the 60,000-byte receive limit (above it a message is dropped), and the
# client's pose small enough to stay on the unreliable channel (1,000 bytes);
# a reliable pose waits for resends over the internet and freezes the player.
static func run(game: Node3D) -> Dictionary:
	var checks={}
	game.clear_entities();game.spawn_clock=1e9;game.mode="playing"
	for i in range(200):
		game.spawn_enemy(10.0+float(i%40));var enemy=game.enemies[-1];enemy.speed=0.0;enemy.fire=3.0;enemy.poison=2.0
	for i in range(300): game.spawn_pickup(game.player.position+Vector3(float(i%20)-10.0,.4,float(i/20)-7.0),"xp",3.0)
	var owned=game.owned.duplicate()
	for card in game.rules.data.loot.slice(0,40): game.owned.append(card.duplicate(true))
	for id in ["ember_hit","storm_crit","frost_kill","venom_dash","bloom_jump","comet_slam","wild_echo","ember_mastery"]: MutationBook.take(game,MutationBook.card(id,1));game.owned.append(MutationBook.card(id,1))
	game.coop.members[2]=game.coop.pose().merged({"hp":100.0},true)
	var world=var_to_bytes(game.coop.snapshot()).size();var pose=var_to_bytes(game.coop.pose()).size()
	# Split for sending: every packet fits the 1,392-byte ENet MTU (no fragments).
	var packets=game.coop.snapshot_packets();var largest=0
	var sizes={}
	for packet in packets:
		var bytes=var_to_bytes(packet).size();largest=maxi(largest,bytes)
		sizes[str(packet.type)]=maxi(int(sizes.get(str(packet.type),0)),bytes)
	var core=packets[0];var parts={}
	for key in core: parts[key]=var_to_bytes(core[key]).size()
	game.coop.members.erase(2)
	print("NET_SIZES "+JSON.stringify({"world":world,"pose":pose,"enemies":game.enemies.size(),"xp":game.pickups.size(),"packets":packets.size(),"largest_packet":largest,"largest_by_type":sizes,"core_parts":parts}))
	checks.net_packets_fit_mtu=largest<=1392
	checks.net_world_size=world<20000
	checks.net_pose_unreliable=pose<=1000
	# A message over the 60,000-byte limit travels in pieces and arrives whole
	# (it used to be dropped without a word, and the games drifted apart).
	var blob=PackedByteArray();blob.resize(150000)
	for i in range(blob.size()): blob[i]=(i*31+7)%251
	var big={"type":"test_big","blob":blob,"note":"whole"}
	var pieces=CoopSession.split_message(var_to_bytes(big),7);var rebuilt=null;var early=false;var part_max=0
	for part in pieces:
		part_max=maxi(part_max,var_to_bytes(part).size())
		if rebuilt!=null: early=true
		rebuilt=game.coop.take_part(99,part)
	checks.net_big_message_parts_fit=pieces.size()>=5 and part_max<=CoopSession.MESSAGE_LIMIT
	checks.net_big_message_whole=not early and rebuilt is Dictionary and rebuilt.get("note","")=="whole" and rebuilt.get("blob")==blob
	# A piece out of order, or a missing one, gives nothing rather than a broken message.
	var skipped=null
	for i in [0,2,3,4,5]:
		if i<pieces.size(): skipped=game.coop.take_part(99,pieces[i])
	checks.net_big_message_gap_refused=skipped==null
	checks.net_big_message_bad_piece_refused=game.coop.take_part(99,{"type":"part","serial":8,"index":0,"count":9999,"bytes":PackedByteArray([1])})==null and game.coop.take_part(99,{"type":"part","serial":"x","index":0,"count":2,"bytes":PackedByteArray([1])})==null
	game.coop.parts_in.erase(99)
	# Replica motion: an enemy walking at 4 m/s, reported ten times a second and
	# 50 ms late, drawn at 30 Hz. Chasing only the last report trails by over half
	# a metre; carrying the reported speed stays within 30 cm, does not run on past
	# a stop, and takes no speed from a teleport.
	var replica={};var chased=Vector3.ZERO;var drawn=Vector3.ZERO;var old_error=0.0;var new_error=0.0;var samples=0;var overshoot=0.0
	for tick in range(150):
		var now=tick/30.0
		var truth=func(t: float) -> Vector3: return Vector3(4.0*minf(maxf(t,0.0),3.0),0,0)
		if tick%3==0:
			var seen: Vector3=truth.call(now-.05)
			CoopSession.replica_snapshot(replica,seen);replica.plain=seen
		chased=chased.lerp(replica.plain,1-exp(-16.0/30.0))
		drawn=CoopSession.replica_step(replica,drawn,1.0/30.0,16)
		if now>.5 and now<3.0: old_error+=chased.distance_to(truth.call(now));new_error+=drawn.distance_to(truth.call(now));samples+=1
		overshoot=maxf(overshoot,drawn.x-12.0)
	checks.net_replica_keeps_up=new_error/samples<.3 and old_error/samples>.5
	checks.net_replica_stops=overshoot<.6 and drawn.distance_to(Vector3(12,0,0))<.05
	CoopSession.replica_snapshot(replica,Vector3(60,0,0))
	checks.net_replica_no_speed_from_teleport=replica.net_velocity==Vector3.ZERO and replica.target_position==Vector3(60,0,0)
	game.owned=owned;MutationBook.reset(game);game.clear_entities()
	return checks

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
	game.owned=owned;MutationBook.reset(game);game.clear_entities()
	return checks

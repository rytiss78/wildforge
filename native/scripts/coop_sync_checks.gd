extends RefCounted

# Co-op state-sync regressions (November 10, the "early co-op desync" review), run
# inside the integration checks in one process: the session is put in the host's
# or a guest's state and handed the messages the other machine would send. With no
# transport open nothing leaves this process.
#  - the host waits for a loading guest through poses left over from the lobby;
#  - a warden's reward chest stands on the guest where the host has it, and chests
#    are matched by distance;
#  - a level-up that arrives after a snapshot of the next level still gives its card;
#  - a reward queued behind another survives a map change;
#  - harvestables are placed from the run's seed, not the shared random stream.
static func run(game: Node3D) -> Dictionary:
	var checks={};var coop=game.coop
	var was={"active":coop.active,"hosting":coop.hosting,"owner":coop.owner_id,"local":coop.local_id}
	game.start_run(407);game.set_physics_process(false);game.spawn_clock=99999;game.mode="playing"

	# Harvestables: the same spots again after the shared stream has been drawn
	# from, as it has been on each machine by the time a later map starts.
	var first=game.harvestables.map(func(h):return h.node.position)
	for i in range(57): game.rules.rng.randf()
	for harvest in game.harvestables: harvest.node.queue_free()
	game.harvestables.clear();game.world.harvest_sites.clear();HarvestBook.spawn(game)
	var same=not first.is_empty() and game.harvestables.size()==first.size()
	if same:
		for i in range(first.size()): same=same and game.harvestables[i].node.position.distance_to(first[i])<.001
	checks.coop_harvest_same_for_party=same

	# Host: the run has started and the guest is loading. A pose the guest sent
	# from the lobby ("ended", no run) must not end the wait; its first pose from
	# this run does.
	coop.active=true;coop.hosting=true;coop.local_id=1;coop.owner_id=1
	coop.members[77]={"mode":"ended","player_name":"Guest","last_seen":Time.get_ticks_msec()/1000.0}
	coop.run_started()
	var stale=coop.pose();stale.run=-1;stale.mode="ended"
	coop.receive(77,stale)
	checks.coop_start_waits_for_loading=coop.frozen() and str(coop.members[77].get("mode",""))=="loading"
	var live=coop.pose();live.mode="playing"
	coop.receive(77,live)
	checks.coop_start_resumes_when_loaded=int(live.run)==game.seed_value and not coop.frozen() and str(coop.members[77].get("mode",""))=="playing"
	if coop.avatars.has(77): coop.avatars[77].queue_free();coop.avatars.erase(77)
	for turret in coop.turret_models.values(): turret.queue_free()
	coop.turret_models.clear()
	coop.members.clear();coop.clear_flower_visuals()

	# Guest: a warden's replica trails the host's by a snapshot. It dies where the
	# host saw it, so its reward chest stands where the host's does.
	coop.hosting=false;coop.owner_id=1;coop.local_id=2
	# A spot with no other chest near it.
	var fell=Vector3(20,0,0)
	for turn in range(12):
		var spot=Vector3(20,0,0).rotated(Vector3.UP,turn*TAU/12)
		if game.chests.all(func(c):return Vector2(c.node.position.x-spot.x,c.node.position.z-spot.z).length()>12):
			fell=spot;break
	fell.y=game.world.height_at(fell.x,fell.z)
	var warden=game.spawn_network_enemy({"id":9001,"position":CoopSession.array(fell+Vector3(.8,0,.6)),"biome":0,"species":0,"hp":50.0,"maxHp":50.0,"xp_reward":5.0,"boss":true,"boss_id":0,"guardian":false,"magnet_guard":false,"title":"Warden","modifier":"","elite":false,"corruption":0})
	var chests_before=game.chests.size()
	coop.receive(1,{"type":"kill","id":9001,"position":CoopSession.array(fell),"cause":"hit"})
	var reward={}
	if game.chests.size()==chests_before+1: reward=game.chests[-1]
	checks.coop_warden_chest_where_host_has_it=bool(warden.dead) and not reward.is_empty() and reward.node.position.distance_to(fell)<.01
	# Chests are matched by distance: a spot a little off still means this chest,
	# a spot metres away means none.
	checks.coop_chest_matched_by_distance=not reward.is_empty() and is_same(coop.chest_near(fell+Vector3(.4,0,.3),true),reward) and coop.chest_near(fell+Vector3(4,0,0),true).is_empty()
	coop.receive(1,{"type":"chest_hide","realm":game.realm,"pos":CoopSession.array(fell+Vector3(.4,0,.3))})
	checks.coop_chest_hidden_when_opened_elsewhere=not reward.is_empty() and bool(reward.opened) and not reward.node.visible and coop.chest_near(fell,true).is_empty()

	# Guest: a snapshot of level 3 arrived before the (resent) level-up to 2. The
	# card for level 2 is still offered, once, and the newer level stays.
	var pool=game.rules.data.loot.slice(0,3).map(func(card):return card.duplicate(true))
	var level_two={"type":"level_up","offers":pool,"kind":"level","level":2,"xp":0,"xp_target":50,"realm":game.realm,"reward_id":"sync-check:level:2"}
	game.mode="playing";game.level=3;coop.last_remote_reward_level=1;coop.rewards_seen.clear();coop.queued_offers.clear()
	coop.receive(1,level_two)
	checks.coop_late_level_up_kept=game.mode=="offer" and game.party_reward_id=="sync-check:level:2" and coop.last_remote_reward_level==2 and game.level==3
	game.hud.close()
	coop.receive(1,level_two)
	checks.coop_level_up_once=game.mode=="playing" and coop.queued_offers.is_empty()

	# Guest: a reward still queued when the party took the portal opens on the next map.
	coop.queued_offers.append([pool,"level",false,"level","sync-check:level:9",game.realm+1,false])
	coop.tick(0.0)
	checks.coop_queued_reward_survives_portal=game.mode=="offer" and game.party_reward_id=="sync-check:level:9" and coop.queued_offers.is_empty()
	game.hud.close()

	coop.active=was.active;coop.hosting=was.hosting;coop.owner_id=was.owner;coop.local_id=was.local
	coop.last_snapshot=0;coop.last_remote_reward_level=1;coop.rewards_seen.clear();coop.queued_offers.clear()
	game.party_seen.clear();game.party_reward_id="";game.level=1
	game.clear_entities();game.mode="playing"
	return checks

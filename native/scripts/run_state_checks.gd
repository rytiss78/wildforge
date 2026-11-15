extends RefCounted

# Run state kept in static variables: every script that has any is classified in
# RunState, and one call clears what a run leaves behind.
static func run(game: Node3D) -> Dictionary:
	var checks={}
	var unknown=[];var stale=[]
	var declares=RegEx.new();declares.compile("(?m)^static var ")
	var with_static={}
	for file in DirAccess.get_files_at("res://scripts"):
		if not file.ends_with(".gd") or file.ends_with("_review.gd") or file.ends_with("_checks.gd"): continue
		var id=file.trim_suffix(".gd")
		if declares.search(FileAccess.get_file_as_string("res://scripts/"+file))==null: continue
		with_static[id]=true
		if not RunState.RESET.has(id) and not RunState.SHARED.has(id): unknown.append(id)
	for id in RunState.RESET.keys()+RunState.SHARED:
		if not with_static.has(id): stale.append(id)
	if not unknown.is_empty() or not stale.is_empty(): print("RUN_STATE "+JSON.stringify({"unclassified":unknown,"no_longer_static":stale}))
	checks.run_state_every_static_classified=unknown.is_empty() and with_static.size()>20
	checks.run_state_tables_current=stale.is_empty() and RunState.RESET.keys().all(func(id):return not RunState.SHARED.has(id))
	# What a finished run leaves behind is gone after one call.
	ClimbMap.carry=Vector3(9,0,0);ClimbMap.carry_until=900.0
	HeroTricks.last_shout=900.0
	Spectate.last_cheer=900.0;Spectate.target_id=7;Spectate.pan=Vector3.ONE;Spectate.last_heard={"from":7,"index":0,"time":900.0}
	Lasso.mine=5;Lasso.cooldown=3.0;Lasso.throws=4
	WrenchTune.streak=3;WrenchTune.boost_until=900.0
	ClutchPlay.lock_until=900.0;ClutchPlay.headshot_kills=5
	HeroPlay.roll=Vector3(4,0,0);HeroPlay.drifting=true
	RunState.reset_all(game)
	checks.run_state_reset_clears=ClimbMap.carry==Vector3.ZERO and ClimbMap.carry_until<0 and HeroTricks.last_shout<0 and Spectate.last_cheer<0 and Spectate.target_id==-1 and Spectate.pan==Vector3.ZERO and Spectate.last_heard.is_empty() and Lasso.mine==-1 and Lasso.cooldown==0.0 and Lasso.throws==0 and WrenchTune.streak==0 and WrenchTune.boost_until<0 and ClutchPlay.lock_until<0 and ClutchPlay.headshot_kills==0 and HeroPlay.roll==Vector3.ZERO and not HeroPlay.drifting
	return checks

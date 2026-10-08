extends RefCounted
static func capture(game,name):
	game.hud.update(0)
	for i in range(5): await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return game.get_viewport().get_texture().get_image().save_png("user://journey-"+name+".png")==OK
static func run(game):
	AudioServer.set_bus_volume_db(0,-80);seed(407);game.start_run(407);game.set_physics_process(false);game.camera_locked=true
	game.player.position=game.gate_position+Vector3(0,0,14);game.camera.position=game.gate_position+Vector3(12,11,24);game.camera.look_at(game.gate_position+Vector3.UP*4)
	var checks={}
	checks.captures=await capture(game,"portal")
	checks.sealed=game.Journey.state(game)=="sealed"
	var coast=game.world.shore_radius(Vector3.RIGHT)
	checks.irregular_coast=absf(coast-game.world.shore_radius(Vector3.FORWARD))>5
	checks.chests_inland=game.chests.all(func(c):return not game.world.dangerous(c.node.position))
	game.player.position=Vector3(coast-12,game.world.height_at(coast-12,0),0)
	game.camera.position=game.player.position+Vector3(-12,10,14);game.camera.look_at(Vector3(coast+14,0,0))
	checks.captures=await capture(game,"coast") and checks.captures
	game.player.position=game.gate_position+Vector3(0,0,14)
	game.Journey.activate(game);checks.seal_blocks=not game.events.get("guardian_summoned",false)
	game.spawn_enemy(12)
	var specimen=game.enemies[-1];var rig=specimen.node.get_meta("rig");var base_scale=rig.scale
	game.camera.position=specimen.node.position+Vector3(4,3,7);game.camera.look_at(specimen.node.position+Vector3.UP*specimen.height*.55)
	checks.corruption_before=await capture(game,"corruption-before")
	var collider=specimen.node.get_child(0).shape;var original_height=collider.height
	game.realm_time=600;game.update_events()
	checks.corruption_existing=specimen.get("corruption",0)==1 and rig.scale.y>base_scale.y
	checks.corruption_new=game.enemies[-1].get("corruption",0)==1
	game.realm_time=750;game.Journey.tick(game)
	checks.corruption_scales=specimen.corruption==6 and rig.scale.y>base_scale.y*1.1 and collider.height==original_height
	var size=rig.scale;var children=rig.get_child_count();EclipseCorruption.apply(specimen,6)
	checks.corruption_idempotent=rig.scale==size and rig.get_child_count()==children
	rig.statuses(false,true,false,false)
	checks.corruption_status=rig.batched.get_shader_parameter("corruption")>0 and rig.batched.get_shader_parameter("tint").y==1
	checks.corruption_after=await capture(game,"corruption-after")
	var actor=game.coop.snapshot().actors.filter(func(a):return a.id==specimen.net_id)[0]
	var remote=game.spawn_network_enemy(actor);EclipseCorruption.apply(remote,int(actor.corruption))
	checks.corruption_replication=remote.corruption==specimen.corruption and remote.node.get_meta("rig").scale.is_equal_approx(rig.scale)
	remote.node.queue_free();game.enemies.erase(remote)
	game.realm_time=600;game.events.eclipse_stage=0;game.Journey.tick(game)
	checks.eclipse=game.events.get("eclipse",false) and game.Journey.state(game)=="ready" and game.events.eclipse_stage==1
	game.realm_time=630;game.Journey.tick(game);checks.escalation=game.events.eclipse_stage==2
	game.Journey.activate(game)
	var guardians=game.enemies.filter(func(e):return e.get("guardian",false) and not e.dead)
	checks.guardian=guardians.size()==1 and game.Journey.state(game)=="fighting"
	var count=game.enemies.size();game.Journey.activate(game);checks.no_duplicate=game.enemies.size()==count
	var guardian=guardians[0]
	checks.near_portal=guardian.node.position.distance_to(game.gate_position)<38
	game.world.eclipse=true;game.world.weather_tick(8,game.player.position)
	game.camera.position=guardian.node.position+Vector3(14,13,25);game.camera.look_at(guardian.node.position+Vector3.UP*4)
	checks.captures=await capture(game,"boss") and checks.captures
	game.kill_enemy(guardian,"diagnostic");checks.guardian_unlocks=game.Journey.state(game)=="cleared"
	game.Journey.activate(game);checks.travel=game.realm==1 and game.Journey.state(game)=="sealed"
	game.enter_realm(2);game.events.guardian_defeated=true;game.Journey.activate(game);checks.final_victory=game.mode=="ended"
	print("JOURNEY_REVIEW "+JSON.stringify(checks));game.get_tree().quit(0 if checks.values().all(func(v):return v) else 1)

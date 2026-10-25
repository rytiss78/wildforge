extends RefCounted

static func capture(g,name: String) -> bool:
	for i in range(5): await g.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return g.get_viewport().get_texture().get_image().save_png("user://boss-"+name+".png")==OK

static func clear_list(list: Array):
	for item in list:
		if is_instance_valid(item.node): item.node.queue_free()
	list.clear()

static func marks_follow_terrain(g) -> bool:
	for hazard in g.hazards:
		for vertex in hazard.node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			var p=hazard.node.to_global(vertex)
			var clearance=p.y-g.world.height_at(p.x,p.z)
			if clearance<.085 or clearance>.095: return false
	return not g.hazards.is_empty()

static func run(g):
	AudioServer.set_bus_volume_db(0,-80)
	g.hud.menu_start.pressed.emit();g.start_run(809);g.invulnerable=1000;g.spawn_clock=99999;g.xp_target=100000
	for i in range(180): await g.get_tree().process_frame
	g.set_physics_process(false);g.equipped.clear();clear_list(g.enemies)
	var checks={"camera":g.camera.fov==70 and g.camera_distance==12 and is_equal_approx(g.pitch,.3)}
	var seen=[];var signatures=[];var ids=[]
	for seed_value in [1,7,809,1423]:
		var history=[]
		for i in range(24):
			var id=BossBook.choose(seed_value,i/8,i%6,history)
			checks["determinism_"+str(seed_value)+"_"+str(i)]=id==BossBook.choose(seed_value,i/8,i%6,history) and (history.is_empty() or id!=history[-1])
			history.append(id)
			if i%8==7:
				var bag={}
				for value in history.slice(i-7,i+1): bag[value]=true
				checks["bag_"+str(seed_value)+"_"+str(i)]=bag.size()==8
	for i in range(8):
		g.spawn_enemy(24,true)
		if g.enemies.is_empty(): checks["spawn_"+str(i)]=false;break
		var enemy=g.enemies[-1];var id=int(enemy.boss_id);seen.append(id);ids.append(enemy.net_id)
		enemy.node.position=Vector3(0,g.world.height_at(0,-29),-29);enemy.node.rotation.y=PI
		enemy.freeze=0;enemy.contact=999;enemy.attack=999
		var rig=enemy.node.get_meta("rig")
		checks["model_"+str(id)]=rig.identity=="boss_"+str(id) and rig.solid.core_material!=null
		checks["orb_"+str(id)]=true
		for fraction in [1.0,.5,.12,0.0,1.0]:
			rig.set_health(fraction);rig.solid.animate(1)
			checks["orb_"+str(id)]=checks["orb_"+str(id)] and is_equal_approx(float(rig.solid.core_material.get_shader_parameter("fill")),fraction)
		var before=rig.legs[0].rotation.x if not rig.legs.is_empty() else 0.0
		rig.animate(.25,Vector3(0,0,2),true)
		checks["animated_"+str(id)]=not rig.legs.is_empty() and not is_equal_approx(before,rig.legs[0].rotation.x)
		clear_list(g.effects);g.hud.update(0)
		checks["capture_"+str(id)]=await capture(g,str(id))
		var actor=bytes_to_var(var_to_bytes(g.coop.actor_descriptor(enemy)))
		var remote=g.spawn_network_enemy(actor)
		var local_shape=enemy.node.get_child(0).shape;var remote_shape=remote.node.get_child(0).shape
		checks["network_"+str(id)]=remote.boss_id==id and remote.model==enemy.model and remote.node.get_meta("rig").identity==rig.identity and is_equal_approx(remote.radius,enemy.radius) and remote.height==enemy.height
		checks["network_collider_"+str(id)]=local_shape.get_class()==remote_shape.get_class() and local_shape.radius==remote_shape.radius and local_shape.height==remote_shape.height
		remote.node.queue_free();g.enemies.erase(remote)
		var marks=BossBook.pattern(id,enemy.node.position,g.player.position,1)
		var signature=[]
		for mark in marks: signature.append([mark.position,mark.radius,mark.delay])
		signatures.append(JSON.stringify(signature))
		checks["reaction_"+str(id)]=marks.all(func(m):return m.delay>=1.4 and m.radius<=2.0)
		enemy.attack=0;g.update_combat(.05)
		checks["attack_"+str(id)]=g.hazards.size()==marks.size() and marks_follow_terrain(g)
		checks["warning_capture_"+str(id)]=await capture(g,str(id)+"-warning")
		clear_list(g.hazards)
		var old_chests=g.chests.size();var old_wardens=g.realm_bosses
		g.kill_enemy(enemy,"crit")
		checks["reward_"+str(id)]=enemy.dead and g.chests.size()==old_chests+1 and g.chests[-1].free and g.realm_bosses==old_wardens+1
		g.enemies.erase(enemy)
		for frame in range(24): await g.get_tree().process_frame
	var unique={};var patterns={}
	for id in seen: unique[id]=true
	for signature in signatures: patterns[signature]=true
	checks.eight_runtime_bosses=unique.size()==8;checks.eight_patterns=patterns.size()==8
	# A client renders received hazard marks; only the authoritative damage packet hurts it.
	clear_list(g.hazards);g.invulnerable=0;g.hp=g.stats.maxHp;g.shield_hp=0
	g.coop.hosting=false;g.coop.active=true;g.coop.owner_id=1
	g.coop.receive(1,{"type":"hazard","realm":g.realm,"position":CoopSession.array(g.player.position),"radius":2.0,"delay":.05,"damage":10,"style":"roots"})
	checks.remote_warning=g.hazards.size()==1 and g.hazards[0].visual_only
	var hp_before=g.hp;g.coop.active=false;g.update_combat(.1)
	checks.no_duplicate_hazard_damage=is_equal_approx(g.hp,hp_before)
	g.coop.active=true;g.coop.receive(1,{"type":"damage","amount":10,"position":CoopSession.array(g.player.position),"sound":"blast","status":"poison"});g.coop.active=false
	checks.authoritative_hazard_damage=g.hp<hp_before
	checks.authoritative_poison=g.player_poison==3
	g.invulnerable=1000
	# Exercise the game's interaction entry point at the real portal.
	clear_list(g.chests);clear_list(g.harvestables);clear_list(g.consumables)
	g.player.position=g.gate_position;g.mode="playing";g.hud.close();g.interact()
	var guardians=g.enemies.filter(func(e):return e.boss and e.guardian)
	checks.portal_summon=guardians.size()==1 and g.events.get("guardian_summoned",false)
	if not guardians.is_empty():
		var warden_count=g.realm_bosses;g.kill_enemy(guardians[0],"crit")
		checks.portal_defeat=g.Journey.state(g)=="cleared" and g.realm_bosses==warden_count
	# The final Baron is outside the eight-boss shuffle roster; exercise him explicitly.
	g.coop.active=false
	g.enter_realm(3)
	var barons=g.enemies.filter(func(e):return e.get("boss_id",-1)==8)
	checks.baron_spawn=barons.size()==1
	if not barons.is_empty():
		var baron=barons[0];var rig=baron.node.get_meta("rig")
		# The Ashen Colossus (cartoon giant since October 25): 17 m, with its health orb.
		checks.baron_scale=baron.height==17.0 and is_equal_approx(baron.radius,4.2) and rig is ColossusRig and rig.identity=="boss_8" and rig.model!=null
		checks.baron_orb=rig.find_child("GlassCore",true,false)!=null and rig.skins.size()==3
		var local_shape=baron.node.get_child(0).shape
		checks.baron_collider=local_shape is CylinderShape3D and is_equal_approx(local_shape.height,17.0) and is_equal_approx(local_shape.radius,4.2)
		# Keep the normal 12 m third-person camera; frame the full silhouette at arena distance.
		g.player.position=Vector3(0,g.world.height_at(0,55)+1.0,55)
		g.pitch=-.05;g.yaw=0;g.camera_distance=12.0
		var camera_anchor=g.player.position+Vector3.UP*1.2
		g.camera.position=camera_anchor+Vector3(0,sin(g.pitch)*g.camera_distance,cos(g.pitch)*g.camera_distance)
		g.camera.look_at(camera_anchor)
		for frame in range(60): await g.get_tree().process_frame
		clear_list(g.effects);g.hud.update(0);checks.baron_capture=await capture(g,"baron")
		var actor=bytes_to_var(var_to_bytes(g.coop.actor_descriptor(baron)))
		var remote=g.spawn_network_enemy(actor);var remote_rig=remote.node.get_meta("rig")
		checks.baron_network=remote.boss_id==8 and remote.model=="boss_8" and remote_rig is ColossusRig and remote_rig.identity=="boss_8"
		checks.baron_network_collider=remote.node.get_child(0).shape.height==local_shape.height and remote.node.get_child(0).shape.radius==local_shape.radius
		remote.node.queue_free();g.enemies.erase(remote)
	print("BOSS_REVIEW "+JSON.stringify({"checks":checks,"rotation":seen,"patterns":patterns.size(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}))
	g.get_tree().quit(0 if not checks.values().has(false) else 1)

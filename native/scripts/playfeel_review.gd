extends RefCounted

static func capture(g,name: String) -> bool:
	for i in range(5): await g.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return g.get_viewport().get_texture().get_image().save_png("user://playfeel-"+name+".png")==OK

static func press(g,action: String):
	var event=ControlBindings.event_for(ControlBindings.spec(g.career.data.settings,action,"keyboard"))
	event.pressed=true;g._input(event)

static func clear(list):
	for item in list:
		if is_instance_valid(item.node): item.node.queue_free()
	list.clear()

static func run(g):
	AudioServer.set_bus_volume_db(0,-80)
	g.select_hero(g.rules.data.heroes[0]);g.start_run(407)
	g.set_physics_process(false);g.set_process(false);g.spawn_clock=99999;g.xp_target=100000;g.invulnerable=1000
	g.storm_clock=99999;g.nova_clock=99999;g.equipped.clear();clear(g.enemies)
	for i in range(140): g._process(.016);await g.get_tree().process_frame
	var checks={};var metrics={}
	g.player.position=Vector3(0,g.world.height_at(0,0)+5,0);g.player.velocity=Vector3.ZERO
	await g.get_tree().physics_frame
	g.player.move_and_slide()
	press(g,"slam");checks.base_slam=g.slamming and is_equal_approx(g.slam_cooldown,4.5)
	g.slamming=false;g.player.velocity.y=3
	for i in range(20): press(g,"slam")
	checks.spam_blocked=not g.slamming and g.player.velocity.y==3
	g._physics_process(.25);checks.recovery_ticks=g.slam_cooldown>4.2 and g.slam_cooldown<4.3
	g.hud.update(0);checks.recovery_hud=g.hud.slam_status.text.contains("4.3s") or g.hud.slam_status.text.contains("4.2s")
	g.mode="paused";var recovery=g.slam_cooldown;g._physics_process(.5);checks.pause_preserves_recovery=g.slam_cooldown==recovery;g.mode="playing"
	# A normal jump is independent of slam recovery. Settle through real physics first.
	g.player.position=Vector3(0,g.world.height_at(0,0)+.15,0);g.player.velocity=Vector3(0,-2,0)
	for i in range(30):
		await g.get_tree().physics_frame;g.player.velocity.y=-2;g.player.move_and_slide()
	press(g,"jump");checks.jump_stays_responsive=g.player.velocity.y>0 and g.slam_cooldown>0
	g.rules.apply_effects(g.stats,g.rules.loot_by_id["rebound-gear-item"].effects)
	metrics.one_rebound_seconds=g.slam_recovery();checks.rebound_from_loot=g.slam_recovery()<3.47 and g.slam_recovery()>3.45
	for i in range(30):g.rules.apply_effects(g.stats,g.rules.loot_by_id["rebound-gear-skill"].effects)
	checks.recharge_cap=is_equal_approx(g.slam_recovery(),.75) and g.stats.slamRecovery==5
	g.slam_cooldown=0;g.player.position.y+=3;await g.get_tree().physics_frame;g.player.move_and_slide();press(g,"slam")
	checks.upgraded_slam=g.slamming and is_equal_approx(g.slam_cooldown,.75)
	g.stats.bounceJump=.25;g.landing_ready=true;g.peak_height=g.player.position.y
	g.player.position.y=g.world.height_at(g.player.position.x,g.player.position.z)+.1
	for i in range(10):
		await g.get_tree().physics_frame;g.player.velocity.y=-24;g.player.move_and_slide()
	g.check_landing(false);checks.bounce_build=g.player.velocity.y>8.5 and not g.slamming
	g.player.position=Vector3(0,g.world.height_at(0,0),0);g.player.velocity=Vector3.ZERO
	g._process(.016);clear(g.effects);g.slam_wave();g._process(.1);g.hud.update(0)
	checks.slam_capture=await capture(g,"slam");checks.slam_ink=g.effects.any(func(e):return e.get("ink_fx",false))
	g._process(1);checks.effects_expire=not g.effects.any(func(e):return e.get("ink_fx",false))
	# Head hopping cannot bypass recovery or erase a high-health enemy.
	g.spawn_enemy(8);var enemy=g.enemies[-1];enemy.hp=10000;enemy.maxHp=10000;enemy.node.position=Vector3.ZERO
	g.slam_cooldown=0;g.slamming=false;g.player.position=Vector3(0,enemy.height-.05,0)
	g.check_stomp(Vector3(0,enemy.height+.7,0),-8)
	checks.stomp_bounded=enemy.hp<10000 and enemy.hp>9900 and not enemy.dead
	var after=enemy.hp;g.player.position.y=enemy.height-.05;g.check_stomp(Vector3(0,enemy.height+.7,0),-8)
	checks.stomp_shared_recovery=enemy.hp==after
	# Exercise the host packet handler, including its recovery gate and build stat.
	g.coop.active=true;g.coop.hosting=true
	g.coop.members[77]={"position":CoopSession.array(enemy.node.position+Vector3.UP*enemy.height),"stats":{"damage":15,"slamPower":2,"slamRecovery":3.5},"mode":"playing","hp":100}
	g.coop.receive(77,{"type":"stomp","id":enemy.net_id});checks.remote_stomp_damage=is_equal_approx(after-enemy.hp,60)
	after=enemy.hp;g.coop.receive(77,{"type":"stomp","id":enemy.net_id});checks.remote_stomp_gate=enemy.hp==after
	checks.remote_recovery_build=absf(g.coop.members[77].stomp_ready-Time.get_ticks_msec()/1000.0-1)<.1
	g.coop.active=false;g.coop.hosting=false;g.coop.members.clear();clear(g.enemies);clear(g.effects)
	g.player.position=Vector3(0,g.world.height_at(0,0),0);g._process(.016)
	# The actual mapped switch/deploy path, with the currently selected card highlighted.
	for id in ["turret","ice-turret"]:
		var weapon=g.rules.data.weapons.filter(func(w):return w.id==id)[0].duplicate(true);weapon.kind="weapon";weapon.strength=1;weapon.tier=0;g.equip_weapon(weapon)
	g.selected_turret=0;g.hud.update(0);press(g,"next_turret");g.hud.update(0)
	checks.turret_selected=g.selected_turret==1 and g.hud.turret_status.text.contains(g.equipped[1].name)
	ControlBindings.bind(g.career.data.settings,"deploy","keyboard",{"type":"key","code":KEY_H});g.hud.update(0)
	var old=g.equipped[1].node;g.equipped[1].deploy_clock=0;press(g,"deploy")
	checks.remapped_deploy=g.equipped[1].node!=old and g.hud.turret_status.text.contains("H")
	g.hud.update(0);checks.turret_capture=await capture(g,"turrets")
	checks.selected_border=g.hud.weapons.get_children().filter(func(c):return c.get_meta("selected_turret",false)).size()==1
	g.invulnerable=0;g.stats.dodge=0;g.stats.armor=0;g.shield_hp=0;g.hp=g.stats.maxHp
	g.take_damage(30,g.player.position+Vector3.RIGHT*5);g.hud.update(0)
	checks.hero_hit=g.damage_feedback_time>0 and g.last_damage_taken==30 and g.hit_shake>.2
	checks.damage_capture=await capture(g,"damage")
	g.invulnerable=0;g.shield_hp=50;g.take_damage(10);checks.shield_sound=g.sound.cache.has("effect_shield-hit")
	g.hp=g.stats.maxHp;g.damage_feedback_time=0;g.invulnerable=1000
	g.sound.start(407);g.sound.tick(.01,true,false)
	checks.phonk_playing=g.sound.drums.playing and g.sound.drums.stream.resource_path.ends_with(g.sound.MUSIC+"drums.wav")
	g.sound.tick(.1,false,false);checks.music_paused=g.sound.drums.stream_paused
	g.events.eclipse=true;g.sound.tick(.1,true,false)
	checks.eclipse_mix=g.sound.eclipse_music.playing and g.sound.eclipse_music.stream.resource_path.ends_with("eclipse_game_mix.wav")
	checks.eclipse_ducked=g.sound.drums.volume_db==-80 and is_equal_approx(g.sound.eclipse_music.volume_db,linear_to_db(maxf(.0001,float(g.career.data.settings.music)))-8)
	var song=g.sound.eclipse_music.stream;checks.eclipse_loop=absf(float(song.loop_end)/song.mix_rate-song.get_length())<.001
	g.events.eclipse=false;g.sound.tick(.1,true,false)
	checks.music_resumes=not g.sound.eclipse_music.playing and g.sound.drums.playing
	g.rules.rng.seed=9301;var ordinary=0;var lucky=0
	for i in range(30000):
		if g.rules.rarity(0)==3:ordinary+=1
		if g.rules.rarity(.75)==3:lucky+=1
	metrics.legendary_base=float(ordinary)/30000;metrics.legendary_max_luck=float(lucky)/30000
	checks.drop_rates=metrics.legendary_base>.009 and metrics.legendary_base<.017 and metrics.legendary_max_luck>.05 and metrics.legendary_max_luck<.065
	checks.natural_landmark_count=g.world.landmarks.size()==RealmWorld.BIOME_COUNT and g.world.building_sites.is_empty()
	g.equipped.clear()
	for biome in range(6):
		var root=g.world.get_node("Landmark_"+str(biome))
		checks["grove_biome_"+str(biome)]=g.world.biome_at(root.position)==biome
		g.player.position=root.to_global(Vector3(0,0,-62));g.player.position.y=g.world.height_at(g.player.position.x,g.player.position.z)
		g.yaw=root.rotation.y+PI;g.pitch=.15;g.player.velocity=Vector3.ZERO;g.player.reset_physics_interpolation()
		for i in range(100):g._process(.016);await g.get_tree().process_frame
		await g.get_tree().physics_frame
		var space=g.get_world_3d().direct_space_state
		var through=PhysicsRayQueryParameters3D.create(root.to_global(Vector3(5,10,12)),root.to_global(Vector3(5,10,-12)),1,[g.player.get_rid()])
		var trunk=root.get_child(1).global_position+Vector3.UP*2
		var wall=PhysicsRayQueryParameters3D.create(trunk+Vector3.LEFT*4,trunk+Vector3.RIGHT*4,1,[g.player.get_rid()])
		checks["grove_open_"+str(biome)]=space.intersect_ray(through).is_empty()
		checks["grove_solid_"+str(biome)]=not space.intersect_ray(wall).is_empty()
		g.current_biome=biome;g.hud.update(0);checks["grove_capture_"+str(biome)]=await capture(g,"grove-"+str(biome))
		g.player.position=root.to_global(Vector3(5,0,12));g.player.position.y=g.world.height_at(g.player.position.x,g.player.position.z)+.1;g.yaw=root.rotation.y
		Input.action_press("move_forward")
		for frame in range(240):
			await g.get_tree().physics_frame;g._physics_process(1.0/60);g._process(1.0/60)
		Input.action_release("move_forward")
		checks["grove_walk_"+str(biome)]=root.to_local(g.player.position).z< -8
	print("PLAYFEEL_REVIEW "+JSON.stringify({"checks":checks,"metrics":metrics}))
	g.get_tree().quit(1 if checks.values().has(false) else 0)

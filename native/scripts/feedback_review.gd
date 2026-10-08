extends RefCounted
static func capture(game,name: String) -> bool:
	game.hud.update(0)
	for i in range(5): await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return game.get_viewport().get_texture().get_image().save_png("user://feedback-"+name+".png")==OK
static func run(game):
	seed(151);AudioServer.set_bus_volume_db(0,-80);game.start_run(151);game.set_physics_process(false);game.camera_locked=true;game.clear_entities()
	var checks={};var origin=game.player.position
	game.camera.position=origin+Vector3(12,15,18);game.camera.look_at(origin)
	game.hud.close()
	for i in range(80):
		var p=origin+Vector3((i%10)*.65-3,.3,(i/10)*.65-2)
		game.spawn_pickup(p,"gold" if i%2==0 else "xp",1)
		var pickup=game.pickups[-1];pickup.node.position=p;pickup.base_y=origin.y;pickup.settled=true
	checks.pickups_before=await capture(game,"pickups-before")
	game.merge_xp_orbs()
	checks.merge_far=game.pickups.size()<=4 and game.pickups.reduce(func(v,p):return v+p.value,0)==80
	checks.pickups_after=await capture(game,"pickups-after")
	for id in ["extra-hop-skill","jump-boots-skill","feather-soles-skill","slam-stone-skill","wide-slam-skill","bounce-pad-skill","attraction-pulse-skill","repulsion-pulse-skill"]:
		var item=game.rules.loot_by_id[id].duplicate(true);item.name=item.title;item.tier=1;game.owned.append(item)
	game.hud.update_skill_strip();checks.skill_strip=game.hud.skill_strip.get_child_count()==8
	game.update.show_ping({"realm":game.realm,"position":CoopSession.array(origin+Vector3(40,0,40)),"label":"TREASURE"})
	checks.ping=game.update.pings.size()==1 and game.sound.ui_voice.playing
	checks.hud=await capture(game,"hud-ping")
	game.hud.build_menu();checks.simple=await capture(game,"simple")
	game.damage_sources={"gun":120,"effect:poison":35};game.hud.run_report_menu();checks.report=await capture(game,"report")
	game.hud.show_offers(game.owned.slice(0,5),"level");checks.cards=await capture(game,"cards")
	checks.all_skill_art=game.rules.data.loot.filter(func(i):return i.kind=="skill").all(func(i):return ResourceLoader.exists("res://assets/illustrated/skill-icons/"+i.id+".png"))
	game.sound.boss_voice_last=-100;var before=game.sound.boss_voice_count
	game.spawn_enemy(8,true);var boss=game.enemies[-1];boss.hp=10000
	for i in range(50): game.hurt_enemy(boss,1,"hit","gun")
	checks.boss_voice_budget=game.sound.boss_voice_count==before+1
	var status_before=game.sound.sfx_index
	for i in range(100):
		boss.poison=0;game.hurt_enemy(boss,.01,"poison")
	checks.poison_hit_audio_budget=game.sound.sfx_index==status_before and game.sound.boss_voice_count==before+1
	checks.boss_voice_assets=true
	for i in range(4): checks.boss_voice_assets=checks.boss_voice_assets and load("res://assets/voices/boss_lt_%d.wav" % i).get_length()>.5
	print("FEEDBACK_REVIEW "+JSON.stringify(checks));game.get_tree().quit(0 if not checks.values().has(false) else 1)

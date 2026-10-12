extends RefCounted

# Regression coverage for the broken October 12 development build.
static func run(game) -> Dictionary:
	var checks={}
	game.start_run(407);game.set_physics_process(false);game.spawn_clock=99999
	game.damage_sources.clear();game.damage_numbers.clear()
	game.credit_damage("gun",25)
	game.record_damage_number(7,10,"crit")
	game.record_damage_number(7,15,"crit")
	game.record_damage_number(7,3,"heal")
	checks.clean_damage_report=game.damage_sources=={"gun":25.0} and RunReport.ranked_damage(game).size()==1
	checks.damage_number_merge=game.damage_numbers.size()==2 and game.damage_numbers[0].value==25 and game.damage_numbers[1].cause=="heal"
	var enemy=game.enemies[0]
	enemy.fire=3;enemy.status_time=4;enemy.freeze=2;enemy.blind=1
	game.update_status_indicators(enemy)
	checks.status_particles=is_instance_valid(enemy.indicator_fire) and enemy.indicator_fire.draw_pass_1!=null and is_instance_valid(enemy.indicator_ice) and is_instance_valid(enemy.indicator_blind)
	enemy.fire=0;enemy.freeze=0;enemy.blind=0;enemy.status_time=0
	game.update_status_indicators(enemy)
	checks.status_expiry=enemy.indicator_fire==null and enemy.indicator_ice==null and enemy.indicator_blind==null
	checks.rain_mesh=game.blood_rain.draw_pass_1!=null
	game.stats.auraDamage=0;game.update_aura_visual()
	checks.aura_requires_upgrade=not game.has_meta("aura_node")
	enemy.node.position=game.player.position+Vector3.RIGHT
	game.stats.auraDamage=2;game.update_aura_visual()
	var ring=game.get_meta("aura_node")
	game.player.position+=Vector3.RIGHT;game.update_aura_visual()
	checks.aura_follows=ring.position.is_equal_approx(game.player.position+Vector3.UP*.12)
	game.stats.auraDamage=0;game.update_aura_visual()
	checks.aura_cleanup=not game.has_meta("aura_node")
	var kills_before=float(game.career.data.total.get("kills",0))
	game.kills=4;game.death_count=2;game.elapsed=10;game.record_run(false)
	checks.kills_not_counted_twice=game.career.data.total.get("kills",0)==kills_before
	game.start_run(408)
	checks.deaths_reset=game.death_count==0
	game.hud._ach_note_queue.clear();game.hud._ach_note_active=false;game.hud.update(0)
	checks.notification_hidden=not game.hud._ach_note_panel.visible
	game.career.on_unlock.call(game.career.achievements[0]);game.hud.update(1.1)
	checks.notification_visible=game.hud._ach_note_panel.visible and game.hud._ach_note_alpha==1
	var first_name=game.hud._ach_note_name.text
	game.hud.show_achievement_notification("Second unlock","Queued, never lost")
	game.hud.update(.1)
	checks.notification_queue=game.hud._ach_note_name.text==first_name and game.hud._ach_note_queue.size()==1
	var remaining=game.hud._ach_note_timer
	game.hud.modal.visible=true;game.hud.update(7)
	checks.notification_waits_for_menu=not game.hud._ach_note_panel.visible and game.hud._ach_note_timer==remaining and game.hud._ach_note_queue.size()==1
	game.hud.modal.visible=false
	game.hud.update(5)
	checks.notification_expires=not game.hud._ach_note_panel.visible
	game.hud.update(.5)
	checks.notification_next=game.hud._ach_note_name.text=="Second unlock" and game.hud._ach_note_panel.visible and game.hud._ach_note_queue.is_empty()
	var sfx=game.sound.settings.sfx
	game.sound.settings.sfx=.5;game.sound.achievement_unlocked()
	var clip=game.sound.achievement_voice.stream
	game.sound.ui_effect("card")
	checks.notification_sound_channel=game.sound.achievement_voice.playing and game.sound.achievement_voice.stream==clip and clip.get_length()>.3
	checks.notification_sound_volume=is_equal_approx(game.sound.achievement_voice.volume_db,linear_to_db(.5)-3)
	game.sound.settings.sfx=0;game.sound.tick(0,false,false);game.sound.achievement_unlocked()
	checks.notification_sound_mute=not game.sound.achievement_voice.playing
	game.sound.settings.sfx=sfx
	checks.notification_original_sound=clip is AudioStreamWAV and clip.resource_path.is_empty() and clip.get_length()>1.8 and clip.loop_mode==AudioStreamWAV.LOOP_DISABLED
	var peak=0
	for offset in range(0,clip.data.size(),2): peak=maxi(peak,absi(clip.data.decode_s16(offset)))
	checks.notification_audio_clean=peak>2000 and peak<30000 and clip.data.decode_s16(0)==0 and absi(clip.data.decode_s16(clip.data.size()-2))<3
	game.hud.update(5)
	game.clear_entities()
	checks.merge(preload("res://scripts/gameplay_repair_checks.gd").run(game))
	return checks

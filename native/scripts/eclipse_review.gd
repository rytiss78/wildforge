extends RefCounted
static func run(game):
	AudioServer.set_bus_volume_db(0,-80);game.start_run(614);game.set_physics_process(false);game.clear_entities()
	var checks={};var speed=game.stat("speed")
	game.events.eclipse=false
	var normal=game.eclipse_running(Vector3.RIGHT,1./60,true)
	checks.normal_immediate=normal.is_equal_approx(Vector3.RIGHT*speed)
	game.events.eclipse=true
	var turn=game.eclipse_running(Vector3.FORWARD,1./60,true)
	checks.turn_drift=turn.x>0 and turn.z<0 and turn.length()<=speed+.01
	for i in range(18): turn=game.eclipse_running(Vector3.FORWARD,1./60,true)
	checks.quick_control=turn.distance_to(Vector3.FORWARD*speed)<speed*.02
	for i in range(12): turn=game.eclipse_running(Vector3.ZERO,1./60,true)
	checks.brakes=turn.length()<speed*.02
	game.eclipse_run_velocity=Vector3.RIGHT*speed
	for i in range(30): turn=game.eclipse_running(Vector3.FORWARD,1./30,true)
	var thirty=turn
	game.eclipse_run_velocity=Vector3.RIGHT*speed
	for i in range(144): turn=game.eclipse_running(Vector3.FORWARD,1./144,true)
	checks.frame_independent=turn.distance_to(thirty)<.001
	checks.air_unchanged=game.eclipse_running(Vector3.LEFT,1./60,false).is_equal_approx(Vector3.LEFT*speed)
	game.events.eclipse=false;checks.exit_immediate=game.eclipse_running(Vector3.RIGHT,1./60,true).is_equal_approx(Vector3.RIGHT*speed)
	game.sound.tick(.016,true,false);checks.normal_music=not game.sound.eclipse_active
	game.events.eclipse=true;game.sound.tick(.016,true,true)
	checks.eclipse_music=game.sound.eclipse_active and game.sound.eclipse_music.playing and game.sound.eclipse_music.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and game.sound.eclipse_music.stream.get_length()>110
	checks.no_overlap=game.sound.drums.volume_db< -70 and game.sound.atmosphere.volume_db< -70
	game.sound.tick(.016,false,true);checks.paused=game.sound.eclipse_music.stream_paused
	game.career.data.settings.music=0;game.sound.tick(.016,true,true);checks.volume=game.sound.eclipse_music.volume_db< -70 and not game.sound.eclipse_music.stream_paused
	game.career.data.settings.music=.45;game.events.eclipse=false;game.sound.tick(.016,true,false)
	checks.music_restored=not game.sound.eclipse_music.playing and game.sound.drums.volume_db> -70
	print("ECLIPSE_REVIEW "+JSON.stringify(checks));game.get_tree().quit(0 if not checks.values().has(false) else 1)

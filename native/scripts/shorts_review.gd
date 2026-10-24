extends RefCounted

# The short-video panel through the real pause path (Esc, BLOCK DROP): TikTok
# plays by default and scrolls on by itself within MAX_PLAY seconds; the switch
# button moves to YouTube Shorts, which plays too; the end of a video loads the
# next; nothing loops; BACK hides the browser. Needs the internet. The browser
# is a native window over the game, so captures come from the desktop
# (shorts-tiktok.png, shorts-youtube.png), not from the game's own viewport.

static func key(g,code: Key):
	for pressed in [true,false]:
		var event=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=pressed
		Input.parse_input_event(event)
	await g.get_tree().process_frame;await g.get_tree().process_frame

static func press(g,text: String) -> bool:
	for node in g.hud.modal.find_children("*","Button",true,false):
		if node.text==text and node.is_visible_in_tree(): node.pressed.emit();await g.get_tree().process_frame;return true
	return false

static func wait(g,condition: Callable,seconds: float) -> bool:
	var end=Time.get_ticks_msec()+seconds*1000
	while Time.get_ticks_msec()<end:
		if condition.call(): return true
		await g.get_tree().create_timer(.1).timeout
	return condition.call()

static func desktop(g,file: String) -> bool:
	await g.get_tree().create_timer(1.5).timeout
	var screen=DisplayServer.window_get_current_screen()
	var image=DisplayServer.screen_get_image(screen)
	return image!=null and image.get_region(Rect2i(DisplayServer.window_get_position()-DisplayServer.screen_get_position(screen),DisplayServer.window_get_size())).save_png("user://"+file)==OK

static func run(g):
	AudioServer.set_bus_volume_db(0,-80)
	var checks={}
	# Quiet: the panel plays at 35% of the music volume.
	g.career.data.settings.music=.05;g.career.data.settings.shortsPanel=true;g.career.data.settings.erase("shortsSource")
	g.start_run(407);g.invulnerable=1e9;g.spawn_clock=1e9
	await wait(g,func():return g.mode=="playing" and not g.hud.modal.visible,3)
	var shorts=g.hud.shorts
	checks.extension=ClassDB.class_exists("WebView")
	await key(g,KEY_ESCAPE)
	checks.menu_button=await press(g,"▦  BLOCK DROP")
	checks.bigger=g.hud.block_drop.zoom>1.2 and shorts.size.y>shorts.BASE.y*1.2
	checks.browser=await wait(g,func():return shorts.view!=null and shorts.shown,5)
	# TikTok by default.
	checks.tiktok_default=await wait(g,func():return shorts.source=="tiktok",3)
	checks.tiktok_reads_tag=await wait(g,func():return shorts.stage=="short" and shorts.current!="",40)
	checks.tiktok_plays=await wait(g,func():return shorts.playing,30)
	checks.low_volume=float(shorts.last_state.get("volume",1))<=.05
	checks.capture_tiktok=await desktop(g,"shorts-tiktok.png")
	# Fast scrolling: the next video comes by itself within MAX_PLAY seconds.
	var first=shorts.current;var played=shorts.shorts_played
	checks.auto_scroll=await wait(g,func():return shorts.shorts_played>played and shorts.current!=first,shorts.MAX_PLAY+10)
	# The switch button moves to YouTube Shorts.
	checks.switch_button=await press(g,"⇄  SWITCH TO YOUTUBE SHORTS")
	checks.youtube_source=await wait(g,func():return shorts.source=="youtube",5)
	checks.youtube_reads_feeds=await wait(g,func():return shorts.source=="youtube" and shorts.stage=="short" and shorts.current!="",30)
	checks.youtube_plays=await wait(g,func():return shorts.playing,30)
	checks.no_loop=await wait(g,func():return shorts.last_state.get("loop",true)==false,3)
	checks.capture_youtube=await desktop(g,"shorts-youtube.png")
	# The end of a video loads the next one.
	var youtube_first=shorts.current
	shorts.run("window.wfSeekEnd&&wfSeekEnd()")
	checks.next_after_end=await wait(g,func():return shorts.current!=youtube_first and shorts.current!="",20)
	checks.switch_back=await press(g,"⇄  SWITCH TO TIKTOK")
	checks.tiktok_again=await wait(g,func():return shorts.source=="tiktok",5)
	checks.back=await press(g,"←  BACK")
	await g.get_tree().create_timer(.3).timeout
	checks.hidden_on_back=not shorts.shown
	# Reopening starts a fresh video (the hidden one was stopped, not paused).
	await g.get_tree().create_timer(1.0).timeout
	var stopped_at=shorts.shorts_played
	checks.reopen=await press(g,"▦  BLOCK DROP")
	checks.plays_after_reopen=await wait(g,func():return shorts.shorts_played>stopped_at and shorts.playing,30)
	print("SHORTS_REVIEW "+JSON.stringify({"checks":checks,"played":shorts.shorts_played,"current":shorts.current,"state":shorts.last_state,"queue":shorts.queue.size(),"zoom":g.hud.block_drop.zoom}))
	g.get_tree().quit(0 if not checks.values().has(false) else 1)

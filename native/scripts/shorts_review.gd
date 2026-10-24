extends RefCounted

# The YouTube Shorts panel through the real pause path (Esc, BLOCK DROP): a short
# from an upbeat channel feed plays at low volume with its loop off, the next one
# loads when it ends, and BACK hides the browser. Needs the internet. The
# browser is a native window over the game, so the capture is taken from the
# desktop (shorts-panel.png), not from the game's own viewport.

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

static func run(g):
	AudioServer.set_bus_volume_db(0,-80)
	var checks={}
	# Quiet: the panel plays at 35% of the music volume.
	g.career.data.settings.music=.05;g.career.data.settings.shortsPanel=true
	g.start_run(407);g.invulnerable=1e9;g.spawn_clock=1e9
	await wait(g,func():return g.mode=="playing" and not g.hud.modal.visible,3)
	var shorts=g.hud.shorts
	checks.extension=ClassDB.class_exists("WebView")
	await key(g,KEY_ESCAPE)
	checks.menu_button=await press(g,"▦  BLOCK DROP")
	checks.browser=await wait(g,func():return shorts.view!=null and shorts.shown,5)
	checks.reads_feeds=await wait(g,func():return shorts.stage=="short" and shorts.current!="",30)
	checks.plays=await wait(g,func():return shorts.playing,30)
	checks.low_volume=float(shorts.last_state.get("volume",1))<=.05
	checks.no_loop=await wait(g,func():return shorts.last_state.get("loop",true)==false,3)
	var rect=Rect2i(DisplayServer.window_get_position(),DisplayServer.window_get_size())
	await g.get_tree().create_timer(1.5).timeout
	var image=DisplayServer.screen_get_image(DisplayServer.window_get_current_screen())
	checks.capture=image!=null and image.get_region(Rect2i(rect.position-DisplayServer.screen_get_position(DisplayServer.window_get_current_screen()),rect.size)).save_png("user://shorts-panel.png")==OK
	# The end of a short loads the next one; nothing loops.
	var first=shorts.current
	shorts.run("window.wfSeekEnd&&wfSeekEnd()")
	checks.next_short=await wait(g,func():return shorts.current!=first and shorts.current!="",20)
	checks.next_plays=await wait(g,func():return shorts.playing,30)
	checks.back=await press(g,"←  BACK")
	await g.get_tree().create_timer(.3).timeout
	checks.hidden_on_back=not shorts.shown
	print("SHORTS_REVIEW "+JSON.stringify({"checks":checks,"played":shorts.shorts_played,"current":shorts.current,"state":shorts.last_state,"queue":shorts.queue.size()}))
	g.get_tree().quit(0 if not checks.values().has(false) else 1)

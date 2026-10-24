extends Control
class_name ShortsPanel

# Real YouTube Shorts beside Block Drop (user request, October 24), through the
# godot_wry WebView (addons/godot_wry: a native Edge WebView2 window laid over
# the game window). Upbeat only: the shorts come from the public feeds of animal
# and good-news channels, play one after another, each once (looping is off and
# the next short loads when one ends). Playback goes through a local player page
# (assets/shorts/player.html) running YouTube's IFrame API on the privacy-enhanced
# youtube-nocookie.com host, which needs no cookie banner; the youtube.com pages
# themselves open on a consent wall in the EU.

const FEEDS=["TheDodoSite","ThePetCollective","GoodNewsNetwork","AnimalPlanetTV"]
const STALL_SECONDS=12.0
const REFRESH_SECONDS=1800.0
const PLAYER="res://assets/shorts/player.html"

var game
# Where the WebView and feed requests live (the HUD CanvasLayer): a native window
# cannot move in and out of the tree with the wait room, so it stays put and
# follows this slot.
var host: Node
var view: Control
var shown=false
var queue=[]
var seen={}
var fetching=0
var fetched_at=-1e9
var stage="idle"
var stage_clock=0.0
var poll=0.0
var current=""
var playing=false
var last_state={}
var shorts_played=0
var last_rect=Rect2()

func _init():
	custom_minimum_size=Vector2(306,544);mouse_filter=Control.MOUSE_FILTER_IGNORE

func available() -> bool:
	return ClassDB.class_exists("WebView") and DisplayServer.get_name()!="headless" and game!=null and bool(game.career.data.settings.get("shortsPanel",true))

func _draw():
	draw_rect(Rect2(Vector2.ZERO,size),Color(.05,.06,.09,.94))
	var text="Shorts are off" if not available() else "No connection" if stage=="offline" else "Loading YouTube Shorts…"
	draw_string(get_theme_default_font(),Vector2(0,size.y*.5),text,HORIZONTAL_ALIGNMENT_CENTER,size.x,16,Color("a8b3c2"))

# Leaving the tree stops _process, and the native window would stay on screen.
func _notification(what: int):
	if what==NOTIFICATION_EXIT_TREE and shown and view!=null: hide_view()

func _process(delta: float):
	var wanted=is_visible_in_tree() and available()
	if wanted and view==null: create()
	if view==null: return
	if wanted:
		follow()
		if not shown: shown=true;view.call("set_visible",stage=="short");run("window.wfResume&&wfResume()")
		tick(delta)
	elif shown: hide_view()
	queue_redraw()

func hide_view():
	shown=false;run("window.wfPause&&wfPause()");view.call("set_visible",false)

func create():
	view=ClassDB.instantiate("WebView")
	view.call("set_data_directory",ProjectSettings.globalize_path("user://webview"))
	view.call("set_full_window_size",false)
	view.call("set_autoplay",true)
	view.call("set_focused_when_created",false)
	view.call("set_background_color",Color(.05,.06,.09))
	view.call("set_url",PLAYER)
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	view.connect("ipc_message",message)
	follow()
	host.add_child(view)
	view.call("set_visible",false)

# The slot's on-screen rectangle, wherever the wait room sits and however it is
# scaled. The browser is placed in window pixels: the game draws at 1920x1080
# and is stretched to the window, so apply the viewport's stretch too.
func follow():
	var xf=get_viewport().get_final_transform()*get_global_transform()
	var rect=Rect2(xf.origin,size*xf.get_scale())
	if rect==last_rect: return
	last_rect=rect;view.position=rect.position;view.size=rect.size
	if view.is_inside_tree(): view.call("resize")

func run(script: String):
	if view!=null and view.is_inside_tree(): view.call("eval",script)

func volume() -> float:
	return clampf(float(game.career.data.settings.get("music",.45))*.35,0,1)

func tick(delta: float):
	stage_clock+=delta;poll-=delta
	if fetching==0 and (queue.is_empty() and stage!="short" or Time.get_ticks_msec()/1000.0-fetched_at>REFRESH_SECONDS): fetch()
	if stage in ["idle","offline"]:
		if not queue.is_empty(): next_short()
		return
	if poll>0: return
	poll=.5
	run("window.wfState&&wfState(%d)" % roundi(volume()*100))
	if stage_clock>STALL_SECONDS and not playing: next_short()

# The channels' public feeds: the latest uploads, shorts marked by their /shorts/ link.
func fetch():
	fetched_at=Time.get_ticks_msec()/1000.0
	for feed in FEEDS:
		var request=HTTPRequest.new();request.timeout=10;host.add_child(request);fetching+=1
		request.request_completed.connect(func(result,code,_headers,body):
			fetching-=1;request.queue_free()
			if result==HTTPRequest.RESULT_SUCCESS and code==200: add_ids(body.get_string_from_utf8())
			if fetching==0 and queue.is_empty() and stage!="short": stage="offline")
		if request.request("https://www.youtube.com/feeds/videos.xml?user="+feed)!=OK: fetching-=1;request.queue_free()

func add_ids(xml: String):
	var fresh=[]
	for found in RegEx.create_from_string("/shorts/([A-Za-z0-9_-]{11})").search_all(xml):
		var id=found.get_string(1)
		if not seen.has(id) and not queue.has(id) and not fresh.has(id): fresh.append(id)
	fresh.shuffle();queue.append_array(fresh)

func message(text: String):
	var data=JSON.parse_string(text)
	if not data is Dictionary: return
	match str(data.get("type","")):
		"state":
			last_state=data
			if float(data.get("t",0))>.3: playing=true
		"ended","error":
			# Ended, or the uploader blocks embedding: on to the next one.
			if stage=="short" and stage_clock>1.5 or str(data.type)=="error": next_short()

func next_short():
	if queue.is_empty():
		# Everything played: start the round again, newest feeds first.
		for id in seen: queue.append(id)
		seen.clear();queue.shuffle()
		if queue.is_empty(): stage="idle";return
	current=queue.pop_front();seen[current]=true;shorts_played+=1
	stage="short";stage_clock=0.0;playing=false;poll=1.0
	run("window.wfPlay&&wfPlay('%s',%d)" % [current,roundi(volume()*100)])
	if shown: view.call("set_visible",true)

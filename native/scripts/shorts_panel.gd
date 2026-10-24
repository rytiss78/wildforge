extends Control
class_name ShortsPanel

# Real short videos beside Block Drop (user requests, October 24): TikTok by
# default, YouTube Shorts on a switch. Through the godot_wry WebView
# (addons/godot_wry: a native Edge WebView2 window laid over the game window).
# Short and fast: each video plays at most MAX_PLAY seconds (anything over
# MAX_DURATION is skipped), never loops, and the next starts at once.
# - TikTok: the panel reads the video links on a hashtag page from the user's
#   tag list (TAGS) while it is
#   hidden (the page's cookie banner is never shown or answered), then plays
#   them in TikTok's official embed player (assets/shorts/tiktok.html).
# - YouTube: shorts from the public feeds of animal and good-news channels,
#   played through YouTube's IFrame API on the privacy-enhanced
#   youtube-nocookie.com host (assets/shorts/player.html). youtube.com pages open
#   on a consent wall in the EU; the res:// page gives the embed its referrer.

const BASE=Vector2(306,544)
const FEEDS=["TheDodoSite","ThePetCollective","GoodNewsNetwork","AnimalPlanetTV"]
# Chosen by the user (October 24).
const TAGS=["phonk","gymtok","meme","gravel","remco","techhouse","nature","run","rally","parrot","core","cuterat","punk","puppy"]
const PAGES={"youtube":"res://assets/shorts/player.html","tiktok":"res://assets/shorts/tiktok.html"}
const MAX_PLAY=15.0
const MAX_DURATION=60.0
const STALL_SECONDS=12.0
const REFRESH_SECONDS=1800.0
const COLLECT_TIKTOK="""(()=>{try{
	const ids=[...new Set([...document.querySelectorAll('a[href*="/video/"]')].map(a=>(a.getAttribute('href')||'').split('/video/')[1]).filter(Boolean).map(s=>s.split(/[?&#/]/)[0]))];
	if(ids.length) window.ipc.postMessage(JSON.stringify({type:'ids',ids:ids.slice(0,40)}));
	window.scrollBy(0,1500);
}catch(e){}})()"""

var game
# Where the WebView and feed requests live (the HUD CanvasLayer): a native window
# cannot move in and out of the tree with the wait room, so it stays put and
# follows this slot.
var host: Node
var view: Control
var shown=false
var source=""
var page=""
var page_ready=false
var pending_play=false
var queue=[]
var seen={}
var fetching=0
var fetched_at=-1e9
var tag_index=0
var stage="idle"
var stage_clock=0.0
var poll=0.0
var current=""
var playing=false
var last_state={}
var shorts_played=0
var last_rect=Rect2()

func _init():
	custom_minimum_size=BASE;mouse_filter=Control.MOUSE_FILTER_IGNORE
	tag_index=randi()%TAGS.size()

func set_zoom(zoom: float):
	custom_minimum_size=BASE*zoom

func available() -> bool:
	return ClassDB.class_exists("WebView") and DisplayServer.get_name()!="headless" and game!=null and bool(game.career.data.settings.get("shortsPanel",true))

func wanted_source() -> String:
	return "youtube" if str(game.career.data.settings.get("shortsSource","tiktok"))=="youtube" else "tiktok"

func _draw():
	draw_rect(Rect2(Vector2.ZERO,size),Color(.05,.06,.09,.94))
	var name="YouTube Shorts" if wanted_source()=="youtube" else "TikTok"
	var text="Videos are off" if not available() else "No connection" if stage=="offline" else "Loading "+name+"…"
	draw_string(get_theme_default_font(),Vector2(0,size.y*.5),text,HORIZONTAL_ALIGNMENT_CENTER,size.x,16,Color("a8b3c2"))

# Leaving the tree stops _process, and the native window would stay on screen.
func _notification(what: int):
	if what==NOTIFICATION_EXIT_TREE and shown and view!=null: hide_view()

func _process(delta: float):
	var wanted=is_visible_in_tree() and available()
	if wanted and view==null: create()
	if view==null: return
	if wanted:
		if source!=wanted_source(): switch_source()
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
	view.call("set_url","about:blank")
	view.mouse_filter=Control.MOUSE_FILTER_IGNORE
	view.connect("ipc_message",message)
	follow()
	host.add_child(view)
	view.call("set_visible",false)

# A new source starts a fresh queue from its own feeds.
func switch_source():
	if page!="": run("window.wfPause&&wfPause()")
	source=wanted_source();queue.clear();seen.clear();current="";playing=false;pending_play=false
	stage="idle";stage_clock=0.0;fetched_at=-1e9;page=""
	if view!=null: view.call("set_visible",false)

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
	if source=="youtube" and fetching==0 and (queue.is_empty() and stage!="short" or Time.get_ticks_msec()/1000.0-fetched_at>REFRESH_SECONDS): fetch()
	if source=="tiktok" and queue.is_empty() and stage in ["idle","offline"]: read_tag()
	if stage in ["idle","offline"]:
		if not queue.is_empty(): next_short()
		return
	if poll>0: return
	poll=.5
	if stage=="loading" and stage_clock>STALL_SECONDS: page="";next_short()
	if stage=="tags":
		run(COLLECT_TIKTOK)
		if stage_clock>STALL_SECONDS: read_tag()
	elif stage=="short":
		run("window.wfState&&wfState(%d)" % roundi(volume()*100))
		if stage_clock>STALL_SECONDS and not playing: next_short()

# YouTube: the channels' public feeds; shorts are marked by their /shorts/ link.
func fetch():
	fetched_at=Time.get_ticks_msec()/1000.0
	for feed in FEEDS:
		var request=HTTPRequest.new();request.timeout=10;host.add_child(request);fetching+=1
		request.request_completed.connect(func(result,code,_headers,body):
			fetching-=1;request.queue_free()
			if result==HTTPRequest.RESULT_SUCCESS and code==200: add_ids(body.get_string_from_utf8(),"/shorts/([A-Za-z0-9_-]{11})")
			if fetching==0 and queue.is_empty() and stage!="short": stage="offline")
		if request.request("https://www.youtube.com/feeds/videos.xml?user="+feed)!=OK: fetching-=1;request.queue_free()

# TikTok: a hashtag page, read while the browser is hidden.
func read_tag():
	stage="tags";stage_clock=0.0;poll=4.0;page="tag";page_ready=false
	view.call("set_visible",false)
	view.call("load_url","https://www.tiktok.com/tag/"+TAGS[tag_index%TAGS.size()]);tag_index+=1

func add_ids(text: String,pattern: String):
	var fresh=[]
	for found in RegEx.create_from_string(pattern).search_all(text):
		var id=found.get_string(1)
		if not seen.has(id) and not queue.has(id) and not fresh.has(id): fresh.append(id)
	fresh.shuffle();queue.append_array(fresh)

func message(text: String):
	var data=JSON.parse_string(text)
	if not data is Dictionary: return
	match str(data.get("type","")):
		"ready":
			page_ready=true
			if pending_play: pending_play=false;next_short()
		"ids":
			if stage!="tags": return
			var found=[]
			for id in data.get("ids",[]):
				if id is String: found.append("/"+id+"/")
			add_ids("".join(found),"/([0-9]{15,21})/")
			# Gather a moment (the page loads more as it scrolls), then start.
			if queue.size()>=6 and stage_clock>3.0: stage="idle";next_short()
		"state":
			last_state=data
			var t=float(data.get("t",0));var d=float(data.get("d",0))
			if t>.3: playing=true
			# Short and fast: long videos are skipped, the rest cut at MAX_PLAY.
			if stage=="short" and stage_clock>1.0 and (d>MAX_DURATION or t>=MAX_PLAY): next_short()
		"ended","error":
			# Ended, or the uploader blocks embedding: on to the next one.
			if stage=="short" and (stage_clock>1.5 or str(data.type)=="error"): next_short()

func next_short():
	if queue.is_empty():
		if source=="tiktok": read_tag();return
		# Everything played: start the round again in a new order.
		for id in seen: queue.append(id)
		seen.clear();queue.shuffle()
		if queue.is_empty(): stage="idle";return
	# The player page for this source must be loaded first.
	if page!=source or not page_ready:
		if page!=source: page=source;page_ready=false;view.call("load_url",PAGES[source])
		pending_play=true;stage="loading";stage_clock=0.0;return
	current=queue.pop_front();seen[current]=true;shorts_played+=1
	stage="short";stage_clock=0.0;playing=false;poll=1.0
	run("window.wfPlay&&wfPlay('%s',%d)" % [current,roundi(volume()*100)])
	if shown: view.call("set_visible",true)

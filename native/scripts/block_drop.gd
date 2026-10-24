extends Control
class_name BlockDrop

# Block Drop: a small falling-blocks game for waiting, in the pause menu or while
# a co-op friend chooses a reward (user request, October 24). The board carries
# on between pauses and is kept in the profile. The music and effects are made by
# scripts/make-block-drop-audio.py; the tune is "Korobeiniki", a public-domain
# folk song (1861).

const COLUMNS=10
const ROWS=20
const CELL=26.0
const PANEL=170.0
const COLORS=[Color("000000"),Color("4fd1e8"),Color("f2d14b"),Color("b878e8"),Color("6fd36a"),Color("ec6060"),Color("5b86e8"),Color("f29a45")]
# I O T S Z J L at rotation 0, as cells of a 4x4 (I) or 3x3 box.
const SHAPES=[[],
	[Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(3,1)],
	[Vector2i(1,0),Vector2i(2,0),Vector2i(1,1),Vector2i(2,1)],
	[Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)],
	[Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1)],
	[Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(2,1)],
	[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)],
	[Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)]]
const LINE_SCORES=[0,100,300,500,800]
const KICKS=[0,-1,1,-2,2]
const REPEATS=["left","right","down"]

var game
var state={}
var fall=0.0
var landed=false
var held=""
var held_device=-1
var held_clock=0.0
var was_active=false
var music_position=0.0
var music=AudioStreamPlayer.new()
var voice=AudioStreamPlayer.new()
var sounds={}
var rng=RandomNumberGenerator.new()

func _init():
	custom_minimum_size=Vector2(COLUMNS*CELL+PANEL+24,ROWS*CELL+24)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	rng.randomize()
	add_child(music);add_child(voice);voice.max_polyphony=3
	for id in ["move","rotate","lock","line","four","level","over"]: sounds[id]=load("res://assets/audio/block_drop/"+id+".wav")
	var theme=load("res://assets/audio/block_drop/music.wav") as AudioStreamWAV
	if theme!=null:
		theme=theme.duplicate();theme.loop_mode=AudioStreamWAV.LOOP_FORWARD;theme.loop_begin=0;theme.loop_end=roundi(theme.get_length()*theme.mix_rate)
		music.stream=theme

func active() -> bool:
	return game!=null and is_visible_in_tree()

func settings() -> Dictionary:
	return game.career.data.settings if game!=null else {}

func _process(delta: float):
	var now=active()
	if now!=was_active:
		was_active=now
		if now: resume()
		else: suspend()
	if not now: return
	music.volume_db=linear_to_db(maxf(.0001,float(settings().get("music",.45))))-4
	if state.over: queue_redraw();return
	# Held d-pad directions repeat; held keys repeat through key echo.
	if held!="" and held_device>=0:
		var button={"left":JOY_BUTTON_DPAD_LEFT,"right":JOY_BUTTON_DPAD_RIGHT,"down":JOY_BUTTON_DPAD_DOWN}[held]
		if not Input.is_joy_button_pressed(held_device,button): held=""
		else:
			held_clock-=delta
			if held_clock<=0: held_clock=.06;act(held)
	fall+=delta
	if fall>=gravity():
		fall=0.0
		if fits(state.piece,state.rot,state.x,state.y+1): state.y+=1;landed=false
		elif landed: lock_piece()
		else: landed=true
	queue_redraw()

# Moved out of the menu or overlay: _process stops with it, so save here.
func _notification(what: int):
	if what==NOTIFICATION_EXIT_TREE and was_active: was_active=false;suspend()

func gravity() -> float:
	return maxf(.07,.8-(int(state.level)-1)*.07)

# Shown again: the saved board comes back where it was left.
func resume():
	if state.is_empty():
		var saved=game.career.data.get("blockDrop",{})
		state=normalize(saved) if valid(saved) else {}
	if state.is_empty(): restart()
	if music.stream!=null and float(settings().get("music",.45))>0: music.play(music_position)

func suspend():
	if music.playing: music_position=music.get_playback_position()
	music.stop();held=""
	if game!=null and not state.is_empty():
		game.career.data.blockDrop=state.duplicate(true);game.career.save()

func valid(saved) -> bool:
	if not saved is Dictionary: return false
	for key in ["board","piece","rot","x","y","next","bag","score","lines","level","over"]:
		if not saved.has(key): return false
	return saved.board is Array and saved.board.size()==COLUMNS*ROWS and int(saved.piece) in range(1,8) and int(saved.next) in range(1,8)

# The profile is JSON: numbers come back as floats.
func normalize(saved: Dictionary) -> Dictionary:
	var result=saved.duplicate(true)
	for key in ["piece","rot","x","y","next","score","lines","level","best"]: result[key]=int(result.get(key,0))
	result.board=result.board.map(func(v):return int(v));result.bag=result.bag.map(func(v):return int(v));result.over=bool(result.over)
	return result

func restart():
	var best=int(state.get("best",0))
	var board=[];board.resize(COLUMNS*ROWS);board.fill(0)
	state={"board":board,"piece":0,"rot":0,"x":3,"y":0,"next":0,"bag":[],"score":0,"lines":0,"level":1,"over":false,"best":best}
	state.next=take();spawn();fall=0.0;landed=false

func take() -> int:
	if state.bag.is_empty():
		var bag=[1,2,3,4,5,6,7]
		for i in range(bag.size()-1,0,-1):
			var j=rng.randi_range(0,i);var swap=bag[i];bag[i]=bag[j];bag[j]=swap
		state.bag=bag
	return int(state.bag.pop_back())

func spawn():
	state.piece=state.next;state.next=take();state.rot=0;state.x=3;state.y=0;landed=false
	if not fits(state.piece,0,3,0):
		state.over=true;state.best=maxi(int(state.best),int(state.score));play("over")

func cells(kind: int,rot: int) -> Array:
	var size=4 if kind==1 else 3
	var result=[]
	for cell in SHAPES[kind]:
		var p: Vector2i=cell
		if kind!=2:
			for i in range(posmod(rot,4)): p=Vector2i(size-1-p.y,p.x)
		result.append(p)
	return result

func fits(kind: int,rot: int,x: int,y: int) -> bool:
	for cell in cells(kind,rot):
		var cx=x+cell.x;var cy=y+cell.y
		if cx<0 or cx>=COLUMNS or cy>=ROWS: return false
		if cy>=0 and int(state.board[cy*COLUMNS+cx])!=0: return false
	return true

func drop_row() -> int:
	var y=int(state.y)
	while fits(state.piece,state.rot,state.x,y+1): y+=1
	return y

func lock_piece():
	for cell in cells(state.piece,state.rot):
		var cy=int(state.y)+cell.y
		if cy<0: state.over=true;state.best=maxi(int(state.best),int(state.score));play("over");return
		state.board[cy*COLUMNS+int(state.x)+cell.x]=int(state.piece)
	var cleared=0
	var y=ROWS-1
	while y>=0:
		var full=true
		for x in range(COLUMNS):
			if int(state.board[y*COLUMNS+x])==0: full=false;break
		if full:
			cleared+=1
			for row in range(y,0,-1):
				for x in range(COLUMNS): state.board[row*COLUMNS+x]=state.board[(row-1)*COLUMNS+x]
			for x in range(COLUMNS): state.board[x]=0
		else: y-=1
	var level_before=int(state.level)
	state.score=int(state.score)+LINE_SCORES[cleared]*level_before
	state.lines=int(state.lines)+cleared
	state.level=1+int(state.lines)/10
	state.best=maxi(int(state.best),int(state.score))
	play("level" if int(state.level)>level_before else "four" if cleared==4 else "line" if cleared>0 else "lock")
	spawn()

func act(action: String):
	if state.over:
		if action in ["rotate","drop","restart"]: restart()
		return
	match action:
		"left","right":
			var dx=-1 if action=="left" else 1
			if fits(state.piece,state.rot,state.x+dx,state.y): state.x+=dx;landed=false;play("move")
		"down":
			if fits(state.piece,state.rot,state.x,state.y+1): state.y+=1;state.score=int(state.score)+1;fall=0.0
			else: lock_piece()
		"rotate","rotate_back":
			var rot=int(state.rot)+(1 if action=="rotate" else -1)
			for kick in KICKS:
				if fits(state.piece,rot,state.x+kick,state.y): state.rot=posmod(rot,4);state.x+=kick;landed=false;play("rotate");break
		"drop":
			var y=drop_row();state.score=int(state.score)+2*(y-int(state.y));state.y=y;lock_piece()
	queue_redraw()

func _input(event):
	if not active(): return
	var action=""
	if event is InputEventKey and event.pressed:
		match event.physical_keycode:
			KEY_LEFT,KEY_A: action="left"
			KEY_RIGHT,KEY_D: action="right"
			KEY_DOWN,KEY_S: action="down"
			KEY_UP,KEY_W,KEY_X: action="rotate"
			KEY_Z,KEY_Q: action="rotate_back"
			KEY_SPACE: action="drop"
			KEY_ENTER,KEY_KP_ENTER: action="restart" if state.get("over",false) else ""
		if event.echo and not REPEATS.has(action): action=""
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT: action="left"
			JOY_BUTTON_DPAD_RIGHT: action="right"
			JOY_BUTTON_DPAD_DOWN: action="down"
			JOY_BUTTON_A: action="rotate"
			JOY_BUTTON_X: action="rotate_back"
			JOY_BUTTON_DPAD_UP,JOY_BUTTON_Y: action="drop"
		if REPEATS.has(action): held=action;held_device=event.device;held_clock=.17
	if action=="": return
	get_viewport().set_input_as_handled()
	act(action)

func play(id: String):
	var volume=float(settings().get("sfx",.65))
	if volume<=0 or not sounds.has(id) or sounds[id]==null: return
	voice.stream=sounds[id];voice.volume_db=linear_to_db(volume)-6;voice.play()

func block(origin: Vector2,color: Color,ghost: bool=false):
	var r=Rect2(origin+Vector2(1,1),Vector2(CELL-2,CELL-2))
	if ghost: draw_rect(r,Color(color,.55),false,2.0);return
	draw_rect(r,color.darkened(.25))
	draw_rect(Rect2(r.position+Vector2(2,2),r.size-Vector2(4,4)),color)
	draw_rect(Rect2(r.position+Vector2(3,3),Vector2(r.size.x-6,4)),color.lightened(.35))

func _draw():
	if state.is_empty(): return
	var font=get_theme_default_font()
	var board_size=Vector2(COLUMNS,ROWS)*CELL
	var origin=Vector2(12,12)
	draw_rect(Rect2(Vector2.ZERO,size),Color(.05,.06,.09,.94))
	draw_rect(Rect2(origin,board_size),Color(.1,.12,.17))
	for x in range(1,COLUMNS): draw_line(origin+Vector2(x*CELL,0),origin+Vector2(x*CELL,board_size.y),Color(1,1,1,.04))
	for y in range(1,ROWS): draw_line(origin+Vector2(0,y*CELL),origin+Vector2(board_size.x,y*CELL),Color(1,1,1,.04))
	for y in range(ROWS):
		for x in range(COLUMNS):
			var kind=int(state.board[y*COLUMNS+x])
			if kind>0: block(origin+Vector2(x,y)*CELL,COLORS[kind])
	if not state.over:
		var ghost=drop_row()
		for cell in cells(state.piece,state.rot):
			if ghost+cell.y>=0: block(origin+Vector2(int(state.x)+cell.x,ghost+cell.y)*CELL,COLORS[state.piece],true)
		for cell in cells(state.piece,state.rot):
			if int(state.y)+cell.y>=0: block(origin+Vector2(int(state.x)+cell.x,int(state.y)+cell.y)*CELL,COLORS[state.piece])
	draw_rect(Rect2(origin,board_size),Color("a99070"),false,2.0)
	var side=origin+Vector2(board_size.x+18,0)
	var ink=Color("f4ead2");var dim=Color("a8b3c2")
	draw_string(font,side+Vector2(0,22),"BLOCK DROP",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("f2d14b"))
	draw_string(font,side+Vector2(0,58),"NEXT",HORIZONTAL_ALIGNMENT_LEFT,-1,15,dim)
	for cell in cells(state.next,0): block(side+Vector2(8,68)+Vector2(cell)*CELL*.8,COLORS[state.next])
	var rows=[["SCORE",state.score],["LINES",state.lines],["LEVEL",state.level],["BEST",state.best]]
	for i in range(rows.size()):
		draw_string(font,side+Vector2(0,170+i*58),rows[i][0],HORIZONTAL_ALIGNMENT_LEFT,-1,15,dim)
		draw_string(font,side+Vector2(0,194+i*58),str(int(rows[i][1])),HORIZONTAL_ALIGNMENT_LEFT,-1,22,ink)
	var hints=["← →  move","↑  rotate","↓  faster","Space  drop"] if game==null or game.input_kind!="xbox" else ["D-pad  move","A  rotate","↓  faster","Y / ↑  drop"]
	for i in range(hints.size()): draw_string(font,side+Vector2(0,420+i*22),hints[i],HORIZONTAL_ALIGNMENT_LEFT,-1,14,dim)
	if state.over:
		draw_rect(Rect2(origin+Vector2(0,board_size.y*.38),Vector2(board_size.x,100)),Color(0,0,0,.78))
		draw_string(font,origin+Vector2(0,board_size.y*.38+42),"GAME OVER",HORIZONTAL_ALIGNMENT_CENTER,board_size.x,26,Color("ec6060"))
		draw_string(font,origin+Vector2(0,board_size.y*.38+76),"Space / A to play again",HORIZONTAL_ALIGNMENT_CENTER,board_size.x,15,ink)

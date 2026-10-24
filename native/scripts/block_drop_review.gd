extends RefCounted

# Block Drop through the real pause-menu path: Esc, the BLOCK DROP button, key
# presses, BACK, then a second pause that must continue the same board. Also the
# co-op waiting overlay, a line clear, and the music hand-over. Writes two
# rendered captures: block-drop-menu.png and block-drop-wait.png.

static func key(g,code: Key):
	for pressed in [true,false]:
		var event=InputEventKey.new();event.physical_keycode=code;event.keycode=code;event.pressed=pressed
		Input.parse_input_event(event)
	await g.get_tree().process_frame;await g.get_tree().process_frame

static func press(g,text: String) -> bool:
	for node in g.hud.modal.find_children("*","Button",true,false):
		if node.text==text and node.is_visible_in_tree(): node.pressed.emit();await g.get_tree().process_frame;return true
	return false

static func shot(g,file: String) -> bool:
	await RenderingServer.frame_post_draw
	return g.get_viewport().get_texture().get_image().save_png("user://"+file)==OK

static func run(g):
	AudioServer.set_bus_volume_db(0,-80)
	var checks={}
	g.career.data.blockDrop={}
	g.start_run(407);g.invulnerable=1e9;g.spawn_clock=1e9
	for i in range(20): await g.get_tree().process_frame
	var drop=g.hud.block_drop
	await key(g,KEY_ESCAPE)
	checks.paused=g.mode=="paused"
	checks.menu_button=await press(g,"▦  BLOCK DROP")
	checks.open=g.hud.block_drop_active() and drop.music.playing
	checks.game_music_paused=g.sound.drums.stream_paused
	var start_piece=drop.state.piece
	# Play a few pieces with the real keys.
	for piece in range(6):
		for k in [KEY_LEFT,KEY_UP,KEY_RIGHT,KEY_RIGHT,KEY_DOWN] if piece%2 else [KEY_LEFT,KEY_LEFT,KEY_UP,KEY_UP]: await key(g,k)
		await key(g,KEY_SPACE)
	var filled=drop.state.board.filter(func(v):return int(v)!=0).size()
	checks.pieces_land=filled==24 or filled>0 and drop.state.lines>0
	checks.scored=int(drop.state.score)>0
	checks.capture_menu=await shot(g,"block-drop-menu.png")
	var board=drop.state.board.duplicate();var score=int(drop.state.score);var piece=int(drop.state.piece)
	checks.back=await press(g,"←  BACK")
	checks.back_to_pause=g.mode=="paused" and not g.hud.block_drop_active() and not drop.music.playing
	checks.saved=g.career.data.get("blockDrop",{}).get("board",[])==board
	checks.continue_button=await press(g,"▶  CONTINUE")
	await key(g,KEY_ESCAPE)
	await press(g,"▦  BLOCK DROP")
	for i in range(3): await g.get_tree().process_frame
	checks.continues=g.hud.block_drop_active() and drop.state.board==board and int(drop.state.score)==score and int(drop.state.piece)==piece
	# A saved board survives a reload of the profile (numbers come back as floats).
	var reloaded=JSON.parse_string(JSON.stringify(g.career.data.blockDrop))
	checks.reload=drop.valid(reloaded) and drop.normalize(reloaded).board==board
	# A line clear: bottom row full except the first four cells, then an I piece.
	for x in range(4,10): drop.state.board[19*10+x]=3
	drop.state.piece=1;drop.state.rot=0;drop.state.x=0;drop.state.y=0
	for x in range(0,4):
		for y in range(0,20): drop.state.board[y*10+x]=0
	var lines=int(drop.state.lines)
	drop.act("drop")
	checks.line_clear=int(drop.state.lines)==lines+1
	await key(g,KEY_ESCAPE)
	checks.esc_closes=g.mode=="playing" and not g.hud.block_drop_active()
	# Co-op waiting: a frozen party in "playing" shows the board over the game.
	g.coop.active=true;g.coop.hosting=false;g.coop.paused=true
	for i in range(6): await g.get_tree().process_frame
	checks.wait_overlay=g.hud.block_drop_active() and drop.get_parent()==g.hud.root and drop.state.board.size()==200
	await key(g,KEY_LEFT)
	checks.wait_keys=g.mode=="playing"
	checks.capture_wait=await shot(g,"block-drop-wait.png")
	g.coop.paused=false;g.coop.active=false
	for i in range(4): await g.get_tree().process_frame
	checks.wait_ends=not g.hud.block_drop_active() and not drop.music.playing
	checks.start_piece=start_piece in range(1,8)
	print("BLOCK_DROP_REVIEW "+JSON.stringify({"checks":checks,"score":drop.state.score,"lines":drop.state.lines}))
	g.get_tree().quit(0 if not checks.values().has(false) else 1)

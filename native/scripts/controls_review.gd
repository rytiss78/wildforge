extends RefCounted

static func capture(game,name: String) -> bool:
	for i in range(5): await game.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return game.get_viewport().get_texture().get_image().save_png("user://controls-"+name+".png")==OK

static func run(game):
	game.set_physics_process(false)
	var settings=game.career.data.settings;settings.bindings={};ControlBindings.apply(settings)
	var checks={}
	checks.defaults=InputMap.action_get_events("jump").size()==2 and ControlBindings.spec(settings,"dash","controller").code==JOY_AXIS_TRIGGER_RIGHT
	game.hud.settings_menu();checks.before=await capture(game,"before")
	game.hud.bindings_menu();game.hud.begin_binding("jump","keyboard")
	var key=InputEventKey.new();key.physical_keycode=KEY_J;key.pressed=true;game._input(key)
	checks.capture=game.hud.binding_action=="" and InputMap.event_is_action(key,"jump") and game.mode=="bindings"
	checks.controller_preserved=ControlBindings.spec(settings,"jump","controller").code==JOY_BUTTON_A
	ControlBindings.bind(settings,"jump","keyboard",{"type":"key","code":KEY_E})
	checks.swap=ControlBindings.spec(settings,"interact","keyboard").code==KEY_J
	ControlBindings.bind(settings,"jump","controller",{"type":"button","code":JOY_BUTTON_Y})
	checks.pad_swap=ControlBindings.spec(settings,"build","controller").code==JOY_BUTTON_A
	ControlBindings.bind(settings,"dash","controller",{"type":"axis","code":JOY_AXIS_TRIGGER_LEFT,"sign":1})
	var axis=InputEventJoypadMotion.new();axis.axis=JOY_AXIS_TRIGGER_LEFT;axis.axis_value=1
	checks.axis=InputMap.event_is_action(axis,"dash")
	game.hud.bindings_menu();game.hud.begin_binding("jump","keyboard");key.physical_keycode=KEY_ESCAPE;game._input(key)
	checks.cancel=ControlBindings.spec(settings,"jump","keyboard").code==KEY_E and game.hud.binding_action==""
	game.career.dirty=true;game.career.save()
	var saved=JSON.parse_string(FileAccess.get_file_as_string(game.career.file))
	checks.persistence=saved.settings.bindings["jump:keyboard"].code==KEY_E
	checks.custom=await capture(game,"custom")
	settings.bindings={"jump:keyboard":{"type":"key","code":-1}};ControlBindings.apply(settings)
	checks.invalid_fallback=ControlBindings.spec(settings,"jump","keyboard").code==KEY_SPACE
	settings.bindings={};ControlBindings.apply(settings)
	checks.reset=InputMap.action_get_events("jump").size()==2 and ControlBindings.spec(settings,"interact","keyboard").code==KEY_E
	print("CONTROLS_REVIEW "+JSON.stringify(checks));game.get_tree().quit(0 if not checks.values().has(false) else 1)


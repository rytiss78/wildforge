extends RefCounted
class_name ControlBindings

const KEYS={"move_left":KEY_A,"move_right":KEY_D,"move_forward":KEY_W,"move_back":KEY_S,"dash":KEY_SHIFT,"jump":KEY_SPACE,"slam":KEY_CTRL,"interact":KEY_E,"build":KEY_B,"pause_game":KEY_ESCAPE,"deploy":KEY_T,"next_turret":KEY_G,"camera_left":KEY_Q,"camera_right":KEY_R,"ping":KEY_F,"look_left":0,"look_right":0,"look_up":0,"look_down":0}
const BUTTONS={"jump":JOY_BUTTON_A,"slam":JOY_BUTTON_B,"interact":JOY_BUTTON_X,"build":JOY_BUTTON_Y,"pause_game":JOY_BUTTON_START,"deploy":JOY_BUTTON_LEFT_SHOULDER,"ping":JOY_BUTTON_RIGHT_STICK,"next_turret":JOY_BUTTON_RIGHT_SHOULDER}
const AXES={"move_left":[JOY_AXIS_LEFT_X,-1],"move_right":[JOY_AXIS_LEFT_X,1],"move_forward":[JOY_AXIS_LEFT_Y,-1],"move_back":[JOY_AXIS_LEFT_Y,1],"look_left":[JOY_AXIS_RIGHT_X,-1],"look_right":[JOY_AXIS_RIGHT_X,1],"look_up":[JOY_AXIS_RIGHT_Y,-1],"look_down":[JOY_AXIS_RIGHT_Y,1],"dash":[JOY_AXIS_TRIGGER_RIGHT,1]}
const LABELS={"move_left":"Move left","move_right":"Move right","move_forward":"Move forward","move_back":"Move back","dash":"Dash","jump":"Jump","slam":"Ground slam","interact":"Interact","build":"Hero stats / equipment","pause_game":"Pause","deploy":"Place turret","next_turret":"Next turret","camera_left":"Rotate camera left","camera_right":"Rotate camera right","ping":"Party ping","look_left":"Look left","look_right":"Look right","look_up":"Look up","look_down":"Look down"}

static func default_spec(action: String,device: String) -> Dictionary:
	if device=="keyboard": return {"type":"key","code":KEYS[action]} if KEYS[action]!=0 else {"type":"none"}
	if BUTTONS.has(action): return {"type":"button","code":BUTTONS[action]}
	if AXES.has(action): return {"type":"axis","code":AXES[action][0],"sign":AXES[action][1]}
	return {"type":"none"}

static func valid(value,device: String) -> bool:
	if not value is Dictionary: return false
	var kind=str(value.get("type",""));var code=int(value.get("code",-1))
	if kind=="none": return true
	if device=="keyboard": return kind=="key" and code>0 and code<0x2000000 or kind=="mouse" and code in [1,2,3,8,9]
	return kind=="button" and code>=0 and code<21 or kind=="axis" and code>=0 and code<6 and int(value.get("sign",0)) in [-1,1]

static func spec(settings: Dictionary,action: String,device: String) -> Dictionary:
	var saved=settings.get("bindings",{})
	if saved is Dictionary:
		var value=saved.get(action+":"+device)
		if valid(value,device): return value
	return default_spec(action,device)

static func event_for(value: Dictionary) -> InputEvent:
	var event: InputEvent
	match value.type:
		"key": event=InputEventKey.new();event.physical_keycode=int(value.code)
		"mouse": event=InputEventMouseButton.new();event.button_index=int(value.code)
		"button": event=InputEventJoypadButton.new();event.button_index=int(value.code)
		"axis": event=InputEventJoypadMotion.new();event.axis=int(value.code);event.axis_value=float(value.sign)
	return event

static func apply(settings: Dictionary):
	for action in KEYS:
		if not InputMap.has_action(action): InputMap.add_action(action,.18)
		InputMap.action_set_deadzone(action,.18);InputMap.action_erase_events(action)
		for device in ["keyboard","controller"]:
			var event=event_for(spec(settings,action,device))
			if event!=null: InputMap.action_add_event(action,event)

static func bind(settings: Dictionary,action: String,device: String,value: Dictionary) -> String:
	if not KEYS.has(action) or not valid(value,device): return "Invalid binding"
	if value.type=="key" and int(value.code)==KEY_ESCAPE or value.type=="button" and int(value.code) in [JOY_BUTTON_START,JOY_BUTTON_BACK]: return "Escape, Menu and Back are reserved menu controls. Choose another input."
	var old=spec(settings,action,device).duplicate(true);var swapped=""
	if not settings.get("bindings",{}) is Dictionary: settings.bindings={}
	if not settings.has("bindings"): settings.bindings={}
	for other in KEYS:
		if other!=action and value.type!="none" and spec(settings,other,device)==value:
			settings.bindings[other+":"+device]=old;swapped=LABELS[other];break
	settings.bindings[action+":"+device]=value.duplicate(true);apply(settings)
	return "Saved" if swapped=="" else "Swapped with "+swapped

static func display(settings: Dictionary,action: String,device: String) -> String:
	var value=spec(settings,action,device)
	match value.type:
		"key": return OS.get_keycode_string(int(value.code))
		"mouse": return {1:"Mouse left",2:"Mouse right",3:"Mouse middle",8:"Mouse side 1",9:"Mouse side 2"}.get(int(value.code),"Mouse")
		"button": return {0:"A",1:"B",2:"X",3:"Y",4:"Back",5:"Guide",6:"Menu",7:"L3",8:"R3",9:"LB",10:"RB",11:"D-pad up",12:"D-pad down",13:"D-pad left",14:"D-pad right"}.get(int(value.code),"Button "+str(value.code))
		"axis":
			var axis=int(value.code);var positive=int(value.sign)>0
			if axis>=4: return "LT" if axis==4 else "RT"
			var direction=("right" if positive else "left") if axis%2==0 else ("down" if positive else "up")
			return ("LS " if axis<2 else "RS ")+direction
	return "Unbound"

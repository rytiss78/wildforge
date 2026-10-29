extends Control
class_name RescueCode

# The co-op rescue code (user request, October 29, after the arrow codes of a
# certain democracy shooter). Next to a downed friend, hold E / X and tap the
# movement keys to enter the six arrows shown; a wrong arrow starts the code
# over, and so does getting hit. The last arrow revives the friend.
# BigUpdate drives it; this control keeps the code and draws it.

const LENGTH=6
const DIRS=["up","down","left","right"]
const ACTIONS={"up":"move_forward","down":"move_back","left":"move_left","right":"move_right"}
const BOX=46.0
const GAP=10.0

var code=[]
var step=0
var target=0
var error=0.0
var punch=0.0

func _init():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	custom_minimum_size=Vector2(LENGTH*(BOX+GAP)-GAP,BOX)
	size=custom_minimum_size

# A new code for this friend: no arrow three times in a row.
func begin(target_id: int,rng: RandomNumberGenerator=null):
	var random=rng if rng!=null else RandomNumberGenerator.new()
	if rng==null: random.randomize()
	code.clear();step=0;target=target_id;error=0.0
	while code.size()<LENGTH:
		var dir=DIRS[random.randi_range(0,3)]
		if code.size()>=2 and code[-1]==dir and code[-2]==dir: continue
		code.append(dir)
	queue_redraw()

func clear_code():
	code.clear();step=0;target=0;queue_redraw()

func complete() -> bool: return not code.is_empty() and step>=code.size()

# One arrow entered: "ok", "wrong" (the code starts over) or "done".
func press(dir: String) -> String:
	if code.is_empty() or complete(): return ""
	if code[step]==dir:
		step+=1;punch=1.0;queue_redraw()
		return "done" if complete() else "ok"
	step=0;error=.45;queue_redraw()
	return "wrong"

# A hit knocks the helper out of the code.
func interrupt():
	if step>0: step=0;error=.45;queue_redraw()

# The arrows tapped this frame (movement actions, so WASD and the stick both work).
func read_input() -> String:
	for dir in DIRS:
		if Input.is_action_just_pressed(ACTIONS[dir]): return press(dir)
	return ""

func tick(delta: float):
	if error>0 or punch>0:
		error=maxf(0.0,error-delta);punch=maxf(0.0,punch-delta*6.0);queue_redraw()

func _draw():
	if code.is_empty(): return
	var shake=Vector2(sin(error*80.0)*6.0*clampf(error/.45,0,1),0)
	for i in range(code.size()):
		var box=Rect2(Vector2(i*(BOX+GAP),0)+shake,Vector2(BOX,BOX))
		var done=i<step;var next=i==step
		var fill=Color("ff4a4a",.85) if error>0 else Color("3be37a",.9) if done else Color("f7f2e3",.95) if next else Color("1b1a24",.75)
		var ink=Color("1b1a24") if done or next or error>0 else Color("8a8799")
		if next and punch<=0: box=box.grow(3.0)
		draw_rect(box,fill,true)
		draw_rect(box,Color("f7d36b") if next else Color(0,0,0,.6),false,3.0)
		arrow(box.get_center(),code[i],ink)

func arrow(center: Vector2,dir: String,color: Color):
	var turn={"up":0.0,"right":PI*.5,"down":PI,"left":-PI*.5}[dir]
	var points=PackedVector2Array([Vector2(0,-15),Vector2(13,2),Vector2(5,2),Vector2(5,14),Vector2(-5,14),Vector2(-5,2),Vector2(-13,2)])
	for i in range(points.size()): points[i]=center+points[i].rotated(turn)
	draw_colored_polygon(points,color)

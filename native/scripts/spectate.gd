extends RefCounted
class_name Spectate

# Downed in co-op (user, November 2): no Block Drop or video wall. The camera
# follows a living friend instead; the mouse or stick turns it, the movement keys
# pan it freely around them, Space switches to the next friend. Number keys 1-0
# play a cheer from the soundboard that every player hears, with a note popping
# over the downed hero.

const CHEERS=["go","got_this","behind","nice","dont_give_up","help","lets_go","watch_out","legend","horn"]
const PAN_SPEED=14.0
const PAN_MAX=30.0
const CHEER_GAP=1.2

static var target_id=-1
static var pan=Vector3.ZERO
static var last_cheer=-99.0
static var keys_down=[]
static var cache={}

static func active(g) -> bool: return g.coop.active and g.update.downed

static func living(g) -> Array:
	var ids=[]
	for id in g.coop.avatars:
		if is_instance_valid(g.coop.avatars[id]) and float(g.coop.members.get(id,{}).get("hp",0))>0 and not g.update.downed_ids.has(id): ids.append(id)
	ids.sort()
	return ids

# Where the camera looks: the watched friend (plus the free pan), or the hero.
static func anchor(g,fallback: Vector3) -> Vector3:
	if not active(g) or not g.coop.avatars.has(target_id) or not is_instance_valid(g.coop.avatars[target_id]): return fallback
	return g.coop.avatars[target_id].position+up(g,Vector3.UP)*1.2+pan

# Which way is up for the camera: a friend under the island is watched upside
# down, like they see themselves.
static func up(g,fallback: Vector3) -> Vector3:
	if not active(g) or not g.coop.avatars.has(target_id) or not is_instance_valid(g.coop.avatars[target_id]): return fallback
	return Vector3.DOWN if bool(g.coop.members.get(target_id,{}).get("under",false)) else Vector3.UP

static func tick(g,delta: float):
	if not active(g):
		target_id=-1;pan=Vector3.ZERO;return
	var ids=living(g)
	if ids.is_empty(): target_id=-1;return
	if not ids.has(target_id): target_id=ids[0];pan=Vector3.ZERO
	if Input.is_action_just_pressed("jump"): target_id=ids[(ids.find(target_id)+1)%ids.size()];pan=Vector3.ZERO
	var move=Input.get_vector("move_left","move_right","move_forward","move_back",.18)
	if move.length()>0: pan+=Vector3(move.x,0,move.y).rotated(Vector3.UP,g.yaw)*PAN_SPEED*delta
	pan=pan.limit_length(PAN_MAX)
	var look=Input.get_vector("look_left","look_right","look_up","look_down",.18)
	if look.length()>.01: g.camera_look(look*Vector2(2,.65)*delta)
	# The soundboard: number keys 1-9 and 0.
	if keys_down.size()!=CHEERS.size(): keys_down.resize(CHEERS.size());keys_down.fill(false)
	for i in range(CHEERS.size()):
		var down=Input.is_physical_key_pressed(KEY_1+i if i<9 else KEY_0)
		if down and not keys_down[i]: cheer(g,i)
		keys_down[i]=down

static func cheer(g,index: int) -> bool:
	if index<0 or index>=CHEERS.size() or g.elapsed-last_cheer<CHEER_GAP: return false
	last_cheer=g.elapsed
	hear(g,g.coop.local_id,index)
	g.coop.broadcast({"type":"cheer","index":index,"from":g.coop.local_id})
	return true

# A cheer arrived: play it and mark who sent it. The host passes it on.
static func receive(g,sender: int,message) -> bool:
	if not message is Dictionary or message.get("type","")!="cheer": return false
	var index=int(message.get("index",-1));var from=int(message.get("from",sender))
	if index<0 or index>=CHEERS.size(): return true
	hear(g,from,index)
	if g.coop.hosting:
		for id in g.coop.members:
			if int(id)!=sender and g.coop.transport_peer_connected(int(id)): g.coop.send_to(int(id),message)
	return true

static var last_heard={}
static func hear(g,from: int,index: int):
	last_heard={"from":from,"index":index,"time":g.elapsed}
	var path="res://assets/voices/cheers/cheer_%s.wav" % CHEERS[index]
	if not ResourceLoader.exists(path): return
	if not cache.has(path): cache[path]=load(path)
	var voice=AudioStreamPlayer.new();voice.stream=cache[path];voice.bus="Master"
	voice.volume_db=linear_to_db(maxf(.0001,float(g.sound.settings.get("voice",.8))))
	g.add_child(voice);voice.play();voice.finished.connect(voice.queue_free)
	var body: Node3D=g.player if from==g.coop.local_id else g.coop.avatars.get(from,null)
	if is_instance_valid(body):
		var note=Label3D.new();note.text="📣";note.font_size=96;note.pixel_size=.012;note.billboard=BaseMaterial3D.BILLBOARD_ENABLED;note.no_depth_test=true
		g.add_child(note);note.position=body.position+Vector3.UP*2.4
		g.effects.append({"node":note,"life":1.2,"velocity":Vector3.UP*1.2})

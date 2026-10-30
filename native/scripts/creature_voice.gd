extends RefCounted
class_name CreatureVoice

# Gibberish creature voices (user request, October 26): each CartoonBook species
# grunts, squeaks or burps in one of eight voices, pitched to its body, when it is
# hurt (sometimes), when it dies, and now and then while it hunts you. The Grand
# Noggin has a booming voice of its own. Sounds come from
# scripts/make-creature-voices.py; nothing here is speech.

const PATH="res://assets/audio/creatures/"
# [voice, pitch] per species, CartoonBook order (biome*10+slot).
const VOICES=[
	["gibber",1.0],["squeak",1.0],["growl",1.0],["burp",1.15],["squeak",1.25],["growl",.85],["groan",1.1],["groan",.95],["gibber",.8],["burp",.85],
	["burp",1.0],["burp",1.2],["warble",.85],["honk",1.1],["squeak",1.35],["honk",.8],["gibber",.9],["groan",1.0],["burp",.9],["hiss",1.0],
	["growl",.9],["warble",1.1],["growl",.75],["warble",1.25],["squeak",1.15],["honk",.85],["gibber",.85],["gibber",1.15],["groan",.9],["squeak",.9],
	["warble",1.2],["honk",1.15],["burp",.9],["warble",1.0],["squeak",1.1],["growl",1.0],["hiss",1.1],["gibber",1.2],["honk",1.0],["honk",1.25],
	["gibber",1.1],["hiss",.9],["growl",.85],["squeak",1.05],["squeak",1.3],["burp",.8],["hiss",.85],["warble",.9],["groan",.8],["gibber",1.0],
	["gibber",.95],["warble",.85],["honk",1.3],["hiss",1.2],["squeak",1.4],["growl",.8],["warble",1.3],["burp",1.05],["groan",.85],["gibber",1.25],
	["burp",1.1],["honk",1.4],["growl",.7],["hiss",.8],["squeak",1.5],["growl",.7],["warble",.75],["groan",1.05],["gibber",.75],["hiss",1.3]]
const HURT_CHANCE=.35
const HURT_EVERY=1.5  # one enemy's hurt yelps, at most
const GAP=.12  # between any two creature voices
const CHAT_EVERY=Vector2(2.5,5.0)
const CHAT_RANGE=18.0

static var last_voice=-100.0
static var next_chat=0.0

# The [voice, pitch] of an enemy, or [] for bosses, sentries and anything else
# that is not a CartoonBook creature.
static func voice_of(enemy: Dictionary) -> Array:
	if enemy.get("boss",false) or enemy.get("behavior","")=="turret": return []
	var model=str(enemy.get("model",""))
	if not model.begins_with("creature_"): return []
	var parts=model.trim_prefix("creature_").split("_")
	if parts.size()<2: return []
	var index=int(parts[0])*10+int(parts[1])
	if index<0 or index>=VOICES.size(): return []
	var entry=VOICES[index]
	# Elites are bigger, so deeper.
	return [entry[0],float(entry[1])*(.86 if enemy.get("elite",false) else 1.0)]

static func speak(game: Node3D,enemy: Dictionary,cue: String) -> bool:
	var voice=voice_of(enemy)
	if voice.is_empty() or not is_instance_valid(enemy.get("node")): return false
	var now=Time.get_ticks_msec()/1000.0
	# A death always gets through the global gap; hurt and chatter wait their turn.
	if cue!="die" and now-last_voice<GAP: return false
	last_voice=now
	var file=PATH+"%s-%s-%d.wav" % [voice[0],cue,randi()%2]
	return game.sound.creature(file,enemy.node.position+Vector3.UP*float(enemy.get("height",1.0))*.7,float(voice[1])*randf_range(.94,1.06),cue=="die")

static func hurt(game: Node3D,enemy: Dictionary):
	var now=Time.get_ticks_msec()/1000.0
	if now-float(enemy.get("voice_hurt",-100.0))<HURT_EVERY or randf()>HURT_CHANCE: return
	if speak(game,enemy,"hurt"): enemy.voice_hurt=now

static func died(game: Node3D,enemy: Dictionary):
	speak(game,enemy,"die")

# Now and then a living creature near the hero babbles.
static func tick(game: Node3D):
	var now=Time.get_ticks_msec()/1000.0
	if now<next_chat or game.mode!="playing": return
	next_chat=now+randf_range(CHAT_EVERY.x,CHAT_EVERY.y)
	var near=game.enemies.filter(func(e):return not e.dead and is_instance_valid(e.node) and e.node.position.distance_to(game.player.position)<CHAT_RANGE and not voice_of(e).is_empty())
	if not near.is_empty(): speak(game,near[randi()%near.size()],"chat")

# The Grand Noggin's booming lines: roar, sing, bravo, boo.
# boost_db: the intro plays them quieter (user report, October 29: deafening).
static func noggin(game: Node3D,cue: String,position: Vector3,boost_db: float=0.0):
	game.sound.creature(PATH+"noggin-"+cue+".wav",position,1.0,true,boost_db)

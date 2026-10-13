extends Node
class_name RunSound

const BAR_LOOP = 16.0 * 60.0 / 144.0
var settings: Dictionary
var voice = AudioStreamPlayer3D.new()
var drums = AudioStreamPlayer.new()
var rhythm = AudioStreamPlayer.new()
var lead = AudioStreamPlayer.new()
var synth = AudioStreamPlayer.new()
var boss_melody = AudioStreamPlayer.new()
var atmosphere = AudioStreamPlayer.new()
var eclipse_music=AudioStreamPlayer.new()
var eclipse_active=false
# Procedural hero movement cues; no external sounds or licensing required.
var step_player=AudioStreamPlayer3D.new()
var engine_player=AudioStreamPlayer3D.new()
var step_clock=0.0
var step_samples={}
var theme_realm=-1
var rng = RandomNumberGenerator.new()
var phrase = 0
var clock = 0.0
var arrangement = []
var active = false
var boss = false
var voice_times = {}
var genre = "metal"
var cache = {}
var sfx_pool=[]
var sfx_index=0
var pending_biome=""
var weapon_loops={}
var boss_voice=AudioStreamPlayer3D.new()
var boss_voice_last=-100.0
var boss_voice_count=0
var hurt_voice=AudioStreamPlayer3D.new()
var hurt_source: Node3D
var last_hurt=-100.0
var chest_voice=AudioStreamPlayer.new()
var ui_voice=AudioStreamPlayer.new()
var achievement_voice=AudioStreamPlayer.new()
var weapon_samples={}
var effect_samples={}
const WEAPON_SFX=["gun","shotgun","turret","rocket","rocket-turret","bomb","meteor","rail","lightning","lightning-turret","ice","poison","gravity","harpoon","boomerang","disc","horn","bubble","saw","flame","fire-turret"]

func setup(options: Dictionary):
	settings = options
	for id in ["slam","dash","hit","shield-hit","deploy","switch","jump","land","freeze","heal","blast","nova"]:
		effect_samples[id]=load("res://assets/audio/effects/"+id+".wav")
	for id in WEAPON_SFX:
		weapon_samples[id]=load("res://assets/audio/weapons/"+id+".wav")
	for id in ["saw","flame","fire-turret"]:
		weapon_samples[id+"-loop"]=load("res://assets/audio/weapons/"+id+"-loop.wav")
	add_child(boss_voice);boss_voice.unit_size=12;boss_voice.max_distance=65;boss_voice.max_db=0
	add_child(hurt_voice)
	hurt_voice.unit_size=8;hurt_voice.max_distance=45;hurt_voice.max_db=0
	add_child(chest_voice)
	ui_voice.max_polyphony=4;add_child(ui_voice)
	add_child(achievement_voice)
	achievement_voice.stream=make_achievement_chime()
	if AudioServer.get_bus_index("SkyVoice")<0:
		AudioServer.add_bus();var sky_bus=AudioServer.bus_count-1;AudioServer.set_bus_name(sky_bus,"SkyVoice")
		var reverb=AudioEffectReverb.new();reverb.room_size=.82;reverb.damping=.65;reverb.wet=.24;reverb.dry=.90;reverb.spread=.85;reverb.predelay_msec=65
		AudioServer.add_bus_effect(sky_bus,reverb)
	voice.bus="SkyVoice";voice.attenuation_model=AudioStreamPlayer3D.ATTENUATION_DISABLED;voice.max_distance=120;voice.panning_strength=.65
	for player in [voice,drums,rhythm,lead,synth,boss_melody,atmosphere,eclipse_music]: add_child(player)
	boss_melody.stream=make_boss_motif()
	for channel in [step_player,engine_player]:
		channel.unit_size=5;channel.max_distance=32;add_child(channel)
	engine_player.stream=make_supra_engine()
	voice.pitch_scale = 1.0
	for i in range(12):
		var channel=AudioStreamPlayer3D.new();channel.unit_size=7;channel.max_distance=75;channel.max_db=0;add_child(channel);sfx_pool.append(channel)

func stream(name: String) -> AudioStream:
	if not cache.has(name): cache[name] = load("res://assets/music/" + name + ".wav")
	return cache[name]

func hero_hurt(id: String,source: Node3D):
	var now=Time.get_ticks_msec()/1000.0
	if float(settings.voice)<=0 or hurt_voice.playing or now-last_hurt<3.0: return
	var path="res://assets/voices/hurt_%s_%d.wav" % [id,rng.randi_range(0,1)]
	if not ResourceLoader.exists(path): return
	if not cache.has(path): cache[path]=load(path)
	last_hurt=now;hurt_source=source;hurt_voice.global_position=source.global_position+Vector3.UP
	hurt_voice.pitch_scale={"duck":1.06,"broccoli":.94,"goblin":1.08,"loaf":.96,"teapot":1.04,"octopus":.93,"astronaut":.98,"cactus":.97,"snail":.92,"bee":1.06,"sushi":1.04,"clock":.97,"bathtub":.94,"toaster":1.03}.get(id,1.0)
	hurt_voice.stream=cache[path];hurt_voice.volume_db=linear_to_db(maxf(.0001,float(settings.voice)));hurt_voice.play()

func chest_open(tier: int,_duration: float):
	if float(settings.sfx)<=0: return
	chest_voice.stream=load("res://assets/music/chest_reels_%d.wav" % tier)
	chest_voice.volume_db=linear_to_db(maxf(.0001,float(settings.sfx)))-3;chest_voice.play()

func start(seed_value: int):
	rng.seed = seed_value
	genre = settings.get("genre", "metal")
	# Verse, chorus, verse, chorus, breakdown, final chorus; riffs vary within sections.
	var verse = rng.randi_range(0,1)
	var chorus = rng.randi_range(2,4)
	arrangement = []
	for section in range(8):
		verse=rng.randi_range(0,1);chorus=rng.randi_range(2,4)
		arrangement.append_array([verse,verse,chorus,chorus,1-verse,verse,chorus,chorus,5,rng.randi_range(0,1),4,chorus])
	phrase = 0
	clock = 0
	active = true
	boss_voice_last=-100;boss_voice.stop();last_hurt=-100;hurt_voice.stop();hurt_source=null;pending_biome=""
	theme_realm=-1;atmosphere.stop();eclipse_music.stop();eclipse_active=false;boss=false;boss_melody.stop()
	step_clock=0;step_player.stop();engine_player.stop()
	play_phrase()

func play_phrase():
	var riff = arrangement[phrase % arrangement.size()]
	var volume = 0.0 if eclipse_active else float(settings.music)
	for player in [drums,rhythm,lead,synth]: player.volume_db = linear_to_db(maxf(.0001, volume))
	drums.stream = stream("phonk_boss_drums" if boss else "phonk_drums")
	rhythm.stream = stream("phonk_bass_"+str(riff))
	lead.stream = stream("phonk_bell_"+str(riff))
	synth.stream = stream("phonk_air_0")
	drums.volume_db-=7 if genre=="cyber" else 3
	rhythm.volume_db-=5
	lead.volume_db-=12 if genre=="cyber" else 7
	synth.volume_db-=24
	var section=(phrase/4)%8
	if not boss and section in [0,4]: drums.volume_db-=4;lead.volume_db-=4
	for player in [drums,rhythm,lead,synth]: player.play()
	# Distinct, original minor-key boss motif layered over the existing drums.
	# Reset on phrase boundaries to avoid drift, and silence it during Eclipse.
	boss_melody.volume_db=linear_to_db(maxf(.0001,volume))-17
	if boss and not eclipse_active: boss_melody.play()
	else: boss_melody.stop()

static func make_boss_motif() -> AudioStreamWAV:
	var audio=AudioStreamWAV.new();audio.mix_rate=22050;audio.format=AudioStreamWAV.FORMAT_16_BITS
	var duration=BAR_LOOP;var samples=int(duration*audio.mix_rate)
	var bytes=PackedByteArray();bytes.resize(samples*2)
	# D minor motif, 16 notes across one phrase. Each note fades before the next.
	var notes=[293.66,349.23,440.0,293.66,261.63,220.0,261.63,174.61,293.66,349.23,440.0,523.25,466.16,349.23,293.66,220.0]
	var beat=duration/16.0
	for i in range(samples):
		var t=float(i)/audio.mix_rate
		var index=mini(notes.size()-1,int(t/beat))
		var phase=fposmod(t,beat);var envelope=minf(1,phase*85.0)*pow(maxf(0,1-phase/beat),1.9)
		var frequency=notes[index]
		var sample=(sin(TAU*frequency*t)+.24*sin(TAU*frequency*2*t)+.08*sin(TAU*frequency*3*t))*.19*envelope
		bytes.encode_s16(i*2,int(clampf(sample,-.9,.9)*32767))
	audio.data=bytes
	return audio

func tick(delta: float, playing: bool, has_boss: bool):
	achievement_voice.volume_db=linear_to_db(maxf(.0001,float(settings.sfx)))-3
	if float(settings.sfx)<=0: achievement_voice.stop()
	var eclipse_wanted=active and get_parent().events.get("eclipse",false)
	if eclipse_wanted!=eclipse_active:
		eclipse_active=eclipse_wanted
		if eclipse_active:
			if not is_instance_valid(eclipse_music.stream): eclipse_music.stream=load("res://assets/music/eclipse_game_mix.wav") as AudioStreamWAV
			if is_instance_valid(eclipse_music.stream):
				eclipse_music.stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;eclipse_music.stream.loop_begin=0;eclipse_music.stream.loop_end=roundi(eclipse_music.stream.get_length()*eclipse_music.stream.mix_rate)
				eclipse_music.play()
		else:
			eclipse_music.stop();clock=0
			if active: play_phrase()
	eclipse_music.stream_paused=not playing
	eclipse_music.volume_db=linear_to_db(maxf(.0001,float(settings.music)))-8
	for channel in [drums,rhythm,lead,synth,boss_melody]:
		if eclipse_active: channel.volume_db=-80
	if boss!=has_boss and active:
		boss=has_boss;clock=0;play_phrase()
	boss = has_boss
	voice.global_position=get_parent().player.global_position+Vector3.UP*32
	if hurt_voice.playing and is_instance_valid(hurt_source): hurt_voice.global_position=hurt_source.global_position+Vector3.UP
	hurt_voice.stream_paused=not playing
	boss_voice.stream_paused=not playing
	for channel in weapon_loops.values(): channel.stream_paused=not playing
	update_motion_audio(delta,playing)
	if playing and not voice.playing and not pending_biome.is_empty():
		var id=pending_biome;pending_biome="";say(id,0)
	for player in [drums,rhythm,lead,synth,boss_melody,atmosphere]: player.stream_paused = not playing
	var realm_index=clampi(get_parent().realm,0,2)
	if active and theme_realm!=realm_index:
		theme_realm=realm_index
		var theme=stream("phonk_air_"+str(realm_index)).duplicate() as AudioStreamWAV
		theme.loop_mode=AudioStreamWAV.LOOP_FORWARD;theme.loop_begin=0;theme.loop_end=roundi(theme.get_length()*theme.mix_rate)
		atmosphere.stream=theme;atmosphere.play();atmosphere.stream_paused=not playing
	atmosphere.volume_db=-80 if eclipse_active else linear_to_db(maxf(.0001,float(settings.music)))-(24 if boss else 18)
	voice.volume_db = linear_to_db(maxf(.0001, float(settings.voice)))
	if not playing or not active: return
	if genre != settings.get("genre", "metal"):
		genre = settings.get("genre", "metal")
		clock = BAR_LOOP
	clock += delta
	if clock >= BAR_LOOP:
		clock -= BAR_LOOP
		phrase += 1
		play_phrase()

func update_motion_audio(delta: float,playing: bool):
	var game=get_parent()
	var live=playing and active and game.mode=="playing" and game.run_active and not game.update.downed and game.hp>0 and not game.coop.frozen() and not game.hud.modal.visible and float(settings.sfx)>0
	if not live:
		step_clock=0
		engine_player.stop()
		return
	var speed=Vector2(game.player.velocity.x,game.player.velocity.z).length()
	var grounded=game.player.is_on_floor()
	var hero_id=str(game.hero.get("id",""))
	var at=game.player.global_position+Vector3.UP*.2
	if hero_id=="white-supra":
		# The car has its own continuous engine, revving with actual movement.
		step_player.stop();step_clock=0
		engine_player.global_position=at
		engine_player.pitch_scale=clampf(.80+speed*.055,.80,2.1)
		engine_player.volume_db=linear_to_db(maxf(.0001,float(settings.sfx)))-(22 if speed<.7 else 13)
		if not engine_player.playing: engine_player.play()
		return
	engine_player.stop()
	if not grounded or speed<.7:
		step_clock=0
		return
	step_clock-=delta
	if step_clock>0: return
	if not step_samples.has(hero_id): step_samples[hero_id]=make_footstep(hero_id)
	step_player.stream=step_samples[hero_id]
	step_player.global_position=at
	step_player.pitch_scale=randf_range(.91,1.09)
	step_player.volume_db=linear_to_db(maxf(.0001,float(settings.sfx)))-13
	step_player.play()
	step_clock=.44/clampf(speed/5.0,.8,1.75)

static func make_supra_engine() -> AudioStreamWAV:
	# One-second seamless, layered engine hum (integer-cycle harmonics).
	var audio=AudioStreamWAV.new();audio.mix_rate=22050;audio.format=AudioStreamWAV.FORMAT_16_BITS
	var bytes=PackedByteArray();bytes.resize(audio.mix_rate*2)
	for i in range(audio.mix_rate):
		var t=float(i)/audio.mix_rate
		var pulse=1+.13*sin(TAU*7*t)
		var sample=(sin(TAU*58*t)*.32+sin(TAU*116*t)*.20+sin(TAU*174*t)*.12+sin(TAU*29*t)*.12)*pulse
		bytes.encode_s16(i*2,int(clampf(sample,-.9,.9)*32767))
	audio.data=bytes;audio.loop_mode=AudioStreamWAV.LOOP_FORWARD
	audio.loop_begin=0;audio.loop_end=audio.mix_rate
	return audio

static func make_footstep(hero_id: String) -> AudioStreamWAV:
	# Distinct weight/timbre per hero, without dependency on new asset files.
	var audio=AudioStreamWAV.new();audio.mix_rate=22050;audio.format=AudioStreamWAV.FORMAT_16_BITS
	var length=.115
	var bytes=PackedByteArray();bytes.resize(roundi(length*audio.mix_rate)*2)
	var random=RandomNumberGenerator.new();random.seed=hero_id.hash()
	var weight=float(posmod(hero_id.hash(),8))/7.0
	var freq=75+weight*125
	for i in range(bytes.size()/2):
		var t=float(i)/audio.mix_rate
		var envelope=exp(-t*(24+weight*16))*minf(1,t*200)
		var sample=(sin(TAU*freq*t)*(.35-weight*.15)+random.randf_range(-.26,.26))*envelope
		bytes.encode_s16(i*2,int(clampf(sample,-.9,.9)*32767))
	audio.data=bytes
	return audio

func say(id: String, cooldown: float = 12.0):
	if float(settings.voice) <= 0: return
	if id.begins_with("biome_") and voice.playing: pending_biome=id;return
	if not ResourceLoader.exists("res://assets/voices/"+id+".wav"): return
	var now = Time.get_ticks_msec() / 1000.0
	if now - float(voice_times.get(id, -100.0)) < cooldown: return
	voice_times[id] = now
	voice.stream = load("res://assets/voices/" + id + ".wav")
	voice.play()

func effect(id: String,position: Vector3=Vector3.ZERO):
	if float(settings.sfx)<=0 or sfx_pool.is_empty(): return
	var key="effect_"+id
	if effect_samples.has(id): cache[key]=effect_samples[id]
	elif weapon_samples.has(id): cache[key]=weapon_samples[id]
	if not cache.has(key):
		var audio=AudioStreamWAV.new();audio.mix_rate=22050;audio.format=AudioStreamWAV.FORMAT_16_BITS
		var bass=id in ["shotgun","rocket","turret-rocket","land","blast","saw","meteor","bomb","horn"]
		var duration=1.2 if id=="steam" else .6 if id=="level" else .32 if id=="sneeze" else .3 if id.ends_with("bump") or id=="squish" else .26 if bass else .14
		var frequencies={"gun":170.0,"shotgun":70.0,"rail":1250.0,"rocket":85.0,"flame":230.0,"fire":230.0,"poison":320.0,"ice":1600.0,"saw":100.0,"turret":430.0,"fire-turret":210.0,"turret-flame":210.0,"lightning":980.0,"lightning-turret":980.0,"turret-tesla":980.0,"rocket-turret":80.0,"turret-rocket":80.0,"coin":1100.0,"dash":370.0,"hit":90.0,"jump":650.0,"land":80.0,"drink":900.0,"level":523.25}
		var frequency=float(frequencies.get(id,520.0))
		if id in ["boomerang","disc","harpoon","gravity","horn","bubble","meteor","bomb","steam"]:
			frequency={"boomerang":780.0,"disc":1100.0,"harpoon":240.0,"gravity":145.0,"horn":196.0,"bubble":880.0,"meteor":53.0,"bomb":71.0,"steam":53.0}[id]
		if id.ends_with("bump") or id=="squish": frequency={"shell_bump":190.0,"wing_bump":730.0,"stone_bump":58.0,"wet_bump":125.0,"buzz_bump":360.0,"roar_bump":42.0,"squish":220.0}.get(id,90.0)
		var bytes=PackedByteArray();bytes.resize(int(duration*22050)*2)
		var local_rng=RandomNumberGenerator.new();local_rng.seed=id.hash()
		for i in range(bytes.size()/2):
			var t=float(i)/22050
			var envelope=exp(-t*(12 if bass else 22))
			var sample=sin(TAU*frequency*t*(1-t*.6))*.18*envelope
			if id in ["gun","shotgun","rocket","turret","turret-rocket","fire","flame","fire-turret","rocket-turret","turret-flame","hit","saw","land","blast"]: sample+=local_rng.randf_range(-.24,.24)*envelope
			if id in ["rail","ice","turret-tesla"]: sample+=sin(TAU*frequency*2.07*t)*.10*envelope
			if id in ["wet_bump","squish"]: sample=sin(TAU*frequency*t*(1+sin(t*48)*.3))*.3*envelope+local_rng.randf_range(-.15,.15)*envelope
			if id in ["shell_bump","stone_bump","roar_bump"]: sample+=local_rng.randf_range(-.24,.24)*envelope
			if id=="wing_bump": sample+=sin(TAU*frequency*t*(1+t*3))*.18*envelope
			if id=="buzz_bump": sample+=signf(sin(TAU*frequency*t))*.1*envelope
			if id in ["boomerang","disc","harpoon"]: sample+=local_rng.randf_range(-.12,.12)*envelope
			if id in ["meteor","bomb"]: sample+=local_rng.randf_range(-.25,.25)*envelope+sin(TAU*frequency*.5*t)*.12*envelope
			if id=="horn": sample=(sin(TAU*frequency*t)*.16+sin(TAU*frequency*2*t)*.08+sin(TAU*frequency*3*t)*.04)*minf(1,t*60)*exp(-t*9)
			if id=="bubble": sample=sin(TAU*frequency*t*(1+sin(t*57)*.5))*.2*envelope
			if id=="gravity": sample+=sin(TAU*frequency*1.03*t)*.15*envelope
			if id=="slash": sample=(local_rng.randf_range(-.24,.24)+sin(TAU*(900-600*t/duration)*t)*.06)*sin(PI*t/duration)
			if id=="melee_hit": sample=(sin(TAU*75*t*(1-t*2))*.34+local_rng.randf_range(-.23,.23))*exp(-t*26)
			if id=="steam": sample=(local_rng.randf_range(-.06,.06)+sin(TAU*frequency*t)*.025)*(.7+.3*sin(t*50))
			if id=="sneeze": sample=local_rng.randf_range(-.32,.32)*pow(sin(PI*t/duration),3)+sin(TAU*110*t*(1+t))*.12*envelope
			if id=="level":
				var note=[523.25,659.25,783.99,1046.50][mini(3,int(t/.15))]
				sample=(sin(TAU*note*t)*.12+sin(TAU*note*2*t)*.035)*minf(1,t*80)*minf(1,(duration-t)*30)
			bytes.encode_s16(i*2,int(clampf(sample,-.9,.9)*32767))
		audio.data=bytes
		cache[key]=audio
	var channel=sfx_pool[sfx_index%sfx_pool.size()];sfx_index+=1
	channel.global_position=get_parent().player.position if position==Vector3.ZERO else position
	channel.stream=cache[key];channel.pitch_scale=rng.randf_range(.95,1.04) if weapon_samples.has(id) else 1.0;channel.volume_db=linear_to_db(float(settings.sfx));channel.play()

func weapon_loop(id: String,enabled: bool,position: Vector3):
	if float(settings.sfx)<=0:
		if weapon_loops.has(id): weapon_loops[id].stop()
		return
	if not weapon_loops.has(id):
		if not enabled: return
		effect(id,position)
		var channel=AudioStreamPlayer3D.new();channel.unit_size=6;channel.max_distance=50;channel.max_db=-6;add_child(channel)
		var audio=weapon_samples.get(id+"-loop",cache["effect_"+id]).duplicate();audio.loop_mode=AudioStreamWAV.LOOP_FORWARD;audio.loop_begin=0;audio.loop_end=audio.data.size()/2
		channel.stream=audio;weapon_loops[id]=channel
	var channel=weapon_loops[id];channel.global_position=position
	channel.volume_db=linear_to_db(maxf(.0001,float(settings.sfx)))-8
	if enabled and not channel.playing: channel.play()
	if not enabled and channel.playing: channel.stop()

func achievement_unlocked():
	if float(settings.sfx)<=0: return
	achievement_voice.volume_db=linear_to_db(float(settings.sfx))-3
	achievement_voice.play()

static func make_achievement_chime() -> AudioStreamWAV:
	# Original modern console-inspired cue: air sweep, warm impact, glassy resolve.
	# No Xbox sample, melody transcription, or external audio dependency.
	var audio=AudioStreamWAV.new();audio.mix_rate=44100;audio.format=AudioStreamWAV.FORMAT_16_BITS
	var duration=1.85
	var bytes=PackedByteArray();bytes.resize(int(duration*audio.mix_rate)*2)
	var notes=[587.33,880.0,1318.51]
	var starts=[.04,.17,.29]
	var noise=RandomNumberGenerator.new();noise.seed=8809
	var air=0.0
	for i in range(bytes.size()/2):
		var time=float(i)/audio.mix_rate
		air=lerpf(air,noise.randf_range(-1,1),.1)
		var sweep=sin(PI*clampf(time/.32,0,1))
		var sample=air*.10*sweep+sin(TAU*(180*time+260*time*time))*.06*sweep
		var impact=maxf(0,time-.17)
		if time>.17: sample+=sin(TAU*146.83*impact)*.15*minf(impact/.012,1)*exp(-impact*9)
		for note in range(notes.size()):
			var t=time-starts[note]
			if t<0: continue
			var envelope=(1-exp(-t*90))*exp(-t*4.2)
			var tone=sin(TAU*notes[note]*t+.3*sin(TAU*notes[note]*2*t)*exp(-t*12))
			tone+=.20*sin(TAU*notes[note]*2.003*t)+.07*sin(TAU*notes[note]*3*t)
			sample+=tone*.19*envelope
		sample*=clampf((duration-time)/.25,0,1)
		bytes.encode_s16(i*2,int(clampf(sample,-.9,.9)*32767))
	audio.data=bytes
	return audio

func ui_effect(id: String):
	if float(settings.sfx)<=0: return
	var key="ui_"+id
	if not cache.has(key):
		var frequencies={"fire":220.0,"poison":196.0,"ice":880.0,"engineering":330.0,"armour":440.0,"coins":1046.5,"garden":587.3,"healing":659.3,"lightning":784.0,"magic":622.3,"movement":740.0,"damage":293.7,"reroll":392.0,"card":523.3,"party_ping":1174.66,"reel_tick":1350.0,"reel_lock":783.99,"chest_latch":135.0,"sneeze":90.0}
		var frequency=float(frequencies.get(id,523.3));var duration=.055 if id=="reel_tick" else .12 if id=="card" else .32
		var audio=AudioStreamWAV.new();audio.mix_rate=22050;audio.format=AudioStreamWAV.FORMAT_16_BITS
		var bytes=PackedByteArray();bytes.resize(int(duration*22050)*2)
		var noise_rng=RandomNumberGenerator.new();noise_rng.seed=id.hash()
		for i in range(bytes.size()/2):
			var t=float(i)/22050;var envelope=sin(PI*t/duration)*exp(-t*7)
			var sample=(sin(TAU*frequency*t)+sin(TAU*frequency*1.5*t)*.35)*.17*envelope
			if id=="chest_latch": sample=(noise_rng.randf_range(-.18,.18)+sin(TAU*frequency*t)*.35)*exp(-t*24)
			if id=="reel_tick": sample=sin(TAU*frequency*t)*.12*exp(-t*65)
			if id=="card": sample=noise_rng.randf_range(-.22,.22)*exp(-t*35)+sin(TAU*(frequency+t*1600)*t)*.1*envelope
			if id=="fire": sample+=noise_rng.randf_range(-.12,.12)*envelope
			if id=="poison": sample=sin(TAU*frequency*t*(1+sin(t*58)*.18))*.22*envelope
			if id=="ice": sample+=sin(TAU*frequency*2.4*t)*.10*envelope
			if id=="lightning": sample+=noise_rng.randf_range(-.08,.08)*envelope*sin(t*180)
			if id=="sneeze": sample=noise_rng.randf_range(-.35,.35)*pow(sin(PI*t/duration),3)+sin(TAU*frequency*t)*.09*envelope
			bytes.encode_s16(i*2,int(clampf(sample,-.9,.9)*32767))
		audio.data=bytes;cache[key]=audio
	ui_voice.stream=cache[key];ui_voice.volume_db=linear_to_db(float(settings.sfx))-3;ui_voice.play()

func choose_power(key: String):
	var tile=int(IllustratedIcons.SKILLS.get(key,0 if key.ends_with("Power") else 7))
	var families=["damage","engineering","engineering","damage","magic","lightning","engineering","magic","garden","healing","armour","coins","poison","fire","ice","movement"]
	ui_effect(families[tile])

func hero_quip(id: String,context: String,source: Node3D):
	if float(settings.voice)<=0 or hurt_voice.playing: return
	var path="res://assets/voices/quip_%s_%s.wav" % [id,context]
	if not ResourceLoader.exists(path): return
	if not cache.has(path): cache[path]=load(path)
	hurt_source=source;hurt_voice.global_position=source.global_position+Vector3.UP
	hurt_voice.stream=cache[path];hurt_voice.pitch_scale=1.0
	hurt_voice.volume_db=linear_to_db(maxf(.0001,float(settings.voice)));hurt_voice.play()

func boss_curse(position: Vector3,index: int=-1) -> int:
	var now=Time.get_ticks_msec()/1000.0
	if now-boss_voice_last<7.0: return -1
	boss_voice_last=now;boss_voice_count+=1
	var selected=rng.randi_range(0,9) if index<0 else clampi(index,0,9)
	if float(settings.voice)>0:
		boss_voice.global_position=position;boss_voice.stream=load("res://assets/voices/boss_lt_%d.wav" % selected)
		# Fixed: boss voice at -10dB relative to voice setting (was -80dB)
		boss_voice.volume_db=linear_to_db(maxf(.0001,float(settings.voice)))-10
		boss_voice.pitch_scale=.88;boss_voice.play()
	return selected

func shutdown():
	# Release playback before the tree exits so the audio mixer can drain voices.
	for player in get_children():
		if player is AudioStreamPlayer or player is AudioStreamPlayer3D:
			player.stop();player.stream=null
	cache.clear()

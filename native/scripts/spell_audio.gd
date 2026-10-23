extends RefCounted
class_name SpellAudio

# Synthesized sounds for the four screen-filling spells: a cast sound each, a
# collapse boom and a per-strike crack, and two loops that play while a twister
# or a void orb is alive. Original procedural audio, no samples.
const RATE=22050
static var loops={}

static func pcm(samples: PackedFloat32Array,looped: bool=false) -> AudioStreamWAV:
	var bytes=PackedByteArray();bytes.resize(samples.size()*2)
	for i in range(samples.size()): bytes.encode_s16(i*2,int(clampf(samples[i],-.95,.95)*32767))
	var audio=AudioStreamWAV.new();audio.mix_rate=RATE;audio.format=AudioStreamWAV.FORMAT_16_BITS;audio.data=bytes
	if looped: audio.loop_mode=AudioStreamWAV.LOOP_FORWARD;audio.loop_begin=0;audio.loop_end=samples.size()
	return audio

static func lowpass_gain(cutoff: float) -> float:
	return 1.0-exp(-TAU*cutoff/RATE)

# id is the effect id Sound.effect() was asked for ("spell_tornado"...).
static func cast(id: String) -> AudioStreamWAV:
	var rng=RandomNumberGenerator.new();rng.seed=id.hash()
	var length={"spell_tornado":1.1,"spell_blackhole":1.0,"spell_collapse":.9,"spell_thunderstorm":1.4,"spell_strike":.35,"spell_inferno":1.0}.get(id,.5)
	var count=int(length*RATE);var out=PackedFloat32Array();out.resize(count)
	var low=0.0;var low2=0.0;var phase=0.0;var rumble=0.0
	for i in range(count):
		var t=float(i)/RATE;var u=t/length;var noise=rng.randf_range(-1,1);var s=0.0
		match id:
			"spell_tornado":
				# A rising whoosh: noise through a sweeping low-pass, swirling.
				low+=lowpass_gain(250.0+2200.0*sin(PI*u))*(noise-low)
				s=low*.9*sin(PI*u)*(1.0+.35*sin(t*TAU*7.0))
			"spell_blackhole":
				# Suction: a falling sub drone under a swelling hiss.
				phase+=TAU*lerpf(140.0,45.0,u)/RATE
				low+=lowpass_gain(900.0*(1.0-u)+120.0)*(noise-low)
				s=sin(phase)*.35*minf(1,t*8.0)*(1.0-u*.3)+low*.4*u
			"spell_collapse":
				# The orb's collapse: a dropping boom with a crack on top.
				phase+=TAU*lerpf(90.0,32.0,minf(1,u*1.5))/RATE
				low+=lowpass_gain(500.0)*(noise-low)
				s=sin(phase)*.6*exp(-t*3.5)+low*.7*exp(-t*6.0)+noise*.25*exp(-t*40.0)
			"spell_thunderstorm":
				# Thunder: a sharp crack, then a long rolling rumble.
				low+=lowpass_gain(160.0)*(noise-low)
				if i%1800==0: rumble=rng.randf_range(.5,1.0)
				s=noise*.5*exp(-t*28.0)+low*2.2*rumble*exp(-t*1.8)*minf(1,t*30.0)
			"spell_strike":
				low+=lowpass_gain(3000.0)*(noise-low)
				s=(noise*.4+low*.4)*exp(-t*22.0)+sin(TAU*70.0*t)*.25*exp(-t*12.0)
			"spell_inferno":
				# A fire whoomp, a roar, and crackles.
				phase+=TAU*lerpf(95.0,40.0,u)/RATE
				low+=lowpass_gain(700.0)*(noise-low)
				var crackle=noise*.5 if rng.randf()<.004 else 0.0
				s=sin(phase)*.45*exp(-t*4.0)+low*.9*sin(PI*u)+crackle
		out[i]=s
	return pcm(out)

# Seamless loops: drones use whole cycles of the loop length, and the noise bed
# is cross-faded from its own tail into its head.
static func loop(kind: String) -> AudioStreamWAV:
	if loops.has(kind): return loops[kind]
	var rng=RandomNumberGenerator.new();rng.seed=kind.hash()
	var length=1.6;var count=int(length*RATE);var fade=int(.2*RATE)
	var bed=PackedFloat32Array();bed.resize(count+fade);var low=0.0
	for i in range(count+fade):
		low+=lowpass_gain(600.0 if kind=="tornado" else 220.0)*(rng.randf_range(-1,1)-low);bed[i]=low
	var out=PackedFloat32Array();out.resize(count)
	for i in range(count):
		var t=float(i)/RATE;var noise=bed[i]
		if i<fade: noise=lerpf(bed[count+i],bed[i],float(i)/fade)
		if kind=="tornado": out[i]=noise*1.1*(1.0+.4*sin(TAU*t*5.0/length))
		else: out[i]=sin(TAU*55.0*t)*.22+sin(TAU*82.5*t)*.12+noise*.5*(1.0+.3*sin(TAU*t*3.0/length))
	loops[kind]=pcm(out,true)
	return loops[kind]

# A looping 3D voice that follows a spell node; SkillBook fades it with the spell.
static func attach_loop(g,node: Node3D,kind: String) -> AudioStreamPlayer3D:
	if float(g.sound.settings.sfx)<=0: return null
	var voice=AudioStreamPlayer3D.new();voice.stream=loop(kind);voice.unit_size=8.0;voice.max_distance=60.0
	voice.volume_db=linear_to_db(maxf(.0001,float(g.sound.settings.sfx)))-6.0
	node.add_child(voice);voice.play()
	return voice

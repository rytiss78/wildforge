"""Original restrained phonk stems and combat sounds; remaster the supplied local Eclipse arrangement."""
from pathlib import Path
import numpy as np
from scipy.signal import butter,sosfilt
import wave,json,hashlib
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'native/assets/music';SR=44100;B=60/144;N=round(16*B*SR)
report={}
def save(path,x):
 x=np.asarray(x);x-=x.mean();fade=min(round(SR*.012),len(x)//2)
 x[:fade]*=np.linspace(0,1,fade);x[-fade:]*=np.linspace(1,0,fade)
 peak=np.max(np.abs(x));x*=min(1,.88/max(.001,peak))
 path.parent.mkdir(parents=True,exist_ok=True)
 with wave.open(str(path),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(SR);f.writeframes(np.round(x*32767).astype('<i2').tobytes())
 report[path.name]={'seconds':len(x)/SR,'peak':float(np.max(np.abs(x))),'rms':float(np.sqrt(np.mean(x*x))),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
def mix(dst,x,beat):
 start=round(beat*B*SR);count=min(len(x),len(dst)-start)
 if count>0:dst[start:start+count]+=x[:count]
def drum(kind,rng):
 t=np.arange(round(SR*.35))/SR;noise=rng.standard_normal(len(t))
 if kind=='kick':return np.sin(2*np.pi*(48*t+54*.022*(1-np.exp(-t/.022))))*np.exp(-t*17)*.52
 if kind=='snare':return (noise*.13+np.sin(2*np.pi*185*t)*.1)*np.exp(-t*25)
 return (noise-np.roll(noise,1))*.027*np.exp(-t*95)
rng=np.random.default_rng(110021)
for busy in [False,True]:
 x=np.zeros(N)
 for beat in range(16):
  if beat%4 in [0,3] or busy and beat%4==2:mix(x,drum('kick',rng),beat)
  if beat%4==2:mix(x,drum('snare',rng),beat)
  for half in range(2):mix(x,drum('hat',rng),beat+half*.5+(0.035 if half else 0))
 save(OUT/('phonk_boss_drums.wav' if busy else 'phonk_drums.wav'),x)
# Sparse original motifs; no transcribed Eclipse notes or outside samples.
phrases=[[0,7,3,10],[0,3,7,5],[0,10,7,3],[0,5,3,7],[0,7,10,12],[0,3,0,7]]
for index,phrase in enumerate(phrases):
 bass=np.zeros(N);bell=np.zeros(N)
 for bar,note in enumerate(phrase):
  f=41.2034*2**(note/12);t=np.arange(round(SR*B*3.1))/SR
  env=np.minimum(1,t/.015)*np.minimum(1,(len(t)/SR-t)/.14)*np.exp(-t*.5)
  mix(bass,np.tanh(np.sin(2*np.pi*f*t)*1.8)*env*.15,bar*4)
  for beat,pitch in [(0,note+24),(1.75,note+31)]:
   t=np.arange(round(SR*.31))/SR;f=164.8138*2**(pitch/12)
   tone=(np.sin(2*np.pi*f*t+1.9*np.sin(2*np.pi*f*1.48*t)*np.exp(-t*18))+.22*np.sin(2*np.pi*f*.51*t))*np.exp(-t*13)*.095
   mix(bell,tone,bar*4+beat)
 save(OUT/f'phonk_bass_{index}.wav',bass);save(OUT/f'phonk_bell_{index}.wav',bell)
for realm in range(3):
 t=np.arange(N)/SR;root=82.4069*2**([0,3,7][realm]/12)
 pad=(np.sin(2*np.pi*root*t)+.4*np.sin(2*np.pi*root*1.5*t))*.027*(.75+.25*np.sin(2*np.pi*t/(N/SR)))
 save(OUT/f'phonk_air_{realm}.wav',pad)
# The existing approximate MIDI arrangement came from a user-supplied recording.
# Preserve it byte-for-byte; create a separate restrained game mix with identical notes/timing.
source=OUT/'eclipse_paranoia.wav'
with wave.open(str(source),'rb') as f:
 rate=f.getframerate();channels=f.getnchannels();x=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').astype(float)/32768
x=x.reshape(-1,channels).mean(axis=1)
assert rate==SR,(rate,SR)
x=sosfilt(butter(2,30,fs=SR,btype='highpass',output='sos'),x)
high=sosfilt(butter(2,2600,fs=SR,btype='highpass',output='sos'),x)
x=x-high*.20
save(OUT/'eclipse_game_mix.wav',x)
for index,kind in enumerate(['slam','dash','hit','shield-hit','deploy','switch','jump','land','freeze','heal','blast','nova']):
 duration=.65 if kind in ['slam','blast','nova'] else .22 if kind in ['switch','jump','deploy'] else .35
 t=np.arange(round(SR*duration))/SR;rng=np.random.default_rng(1190+index);noise=rng.standard_normal(len(t));low=np.convolve(noise,np.ones(32)/32,mode='same')
 if kind in ['slam','blast','land']:
  x=np.sin(2*np.pi*(48*t+75*.035*(1-np.exp(-t/.035))))*np.exp(-t*12)*.5+low*np.exp(-t*16)*.5+noise*np.exp(-t*120)*.12
 elif kind in ['dash','jump']:
  x=(noise-np.roll(noise,1))*.04*np.sin(np.pi*t/duration)**2+np.sin(2*np.pi*(240*t+800*t*t))*.12*np.sin(np.pi*t/duration)**2
 elif kind in ['hit','shield-hit']:
  f=115 if kind=='hit' else 920;x=noise*np.exp(-t*70)*.20+np.sin(2*np.pi*f*t)*np.exp(-t*23)*.25
 else:
  f=330+index*65;x=(np.sin(2*np.pi*f*t)+.35*np.sin(2*np.pi*f*1.51*t))*np.exp(-t*18)*.23+noise*np.exp(-t*100)*.05
 save(ROOT/f'native/assets/audio/effects/{kind}.wav',x)
report['provenance']={'phonk':'Original deterministic composition and synthesis; no external samples or Eclipse melody.','eclipse':'EQ remaster of the existing user-supplied-source MIDI arrangement, not a new original composition. Original WAV retained.','eclipse_source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'runtime_eclipse_gain_db':-8}
(OUT/'phonk-game-mix.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8');print('Created',len(report)-1,'audio files; originals retained')

"""Per-map music (user, November 3: "different music for different maps, not
very loud"). Each of the seven biome maps gets its own key, lead instrument,
bass sound and pad, over the shared phonk drums (sound.gd plays them in the
same 4-bar, 144 BPM loops as the main set, so riffs line up).

Usage: py -3.12 scripts/make-map-music.py   (numpy)
Writes native/assets/music/map<M>_bass_0..5, map<M>_lead_0..5, map<M>_air
(mono, 16-bit, 22050 Hz).

  0 Clover Woods     G minor   wooden marimba, round 808
  1 Puffcap Marsh    E minor   kalimba, wobbling filtered saw bass
  2 Moon Craters     D minor   glass bells, deep sub, sparse
  3 Cloudwilds       A minor   breathy flute, soft sub
  4 Junkyard Planet  C minor   chiptune square lead, buzzing square bass
  5 Candy Hell       F minor   phonk cowbell, distorted 808
  6 Starfall Space   B-flat minor  shimmering detuned pluck, sub
"""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'tools/voice/python-libs'))
import numpy as np
import soundfile as sf

RATE=22050
BPM=144.0;BEAT=60.0/BPM;BEATS=16
LENGTH=int(BEATS*BEAT*RATE)
STEP=BEAT/4.0
OUT=root/'native/assets/music'
rng=np.random.default_rng(20261103)

# The riffs of the main set (G minor), transposed per map.
BASS=[
    [(0,3,31),(3,1,34),(4,3,31),(7,1,29),(8,3,27),(11,1,29),(12,4,31)],
    [(0,2,31),(2,2,38),(4,3,34),(7,1,36),(8,4,27),(12,2,29),(14,2,31)],
    [(0,2,31),(2,1,31),(3,1,34),(4,2,39),(6,2,38),(8,2,36),(10,2,34),(12,3,31),(15,1,29)],
    [(0,3,27),(3,1,29),(4,3,31),(7,1,34),(8,3,36),(11,1,34),(12,4,31)],
    [(0,1,31),(1,1,31),(2,2,34),(4,1,36),(5,1,36),(6,2,38),(8,2,39),(10,2,38),(12,2,34),(14,2,31)],
    [(0,8,31),(8,8,27)],
]
A=[(0,79),(3,79),(6,82),(8,79),(10,77),(12,79),(14,74)];A2=[(0,79),(3,82),(6,84),(8,82),(10,79),(12,77),(14,74)]
LEADS=[
    [A,A,A,A2],
    [[(0,86),(3,84),(6,82),(8,79),(11,82),(14,79)]]*3+[[(0,86),(3,87),(6,86),(8,84),(11,82),(14,77)]],
    [[(0,91),(2,89),(3,87),(5,86),(6,84),(8,86),(10,82),(11,84),(13,79),(14,82)]]*4,
    [[(0,87),(2,86),(4,84),(6,82),(8,84),(10,86),(12,87),(14,89)]]*3+[[(0,91),(2,89),(4,87),(6,86),(8,84),(10,82),(12,79),(14,77)]],
    [[(0,79),(1,79),(3,82),(4,79),(6,86),(8,79),(9,79),(11,84),(12,82),(14,77)]]*4,
    [[(0,79),(8,74)]]*4,
]
# Per map: key shift from G minor, lead, bass, lead octave shift, pad chord, sparse.
MAPS=[
    dict(shift=0,lead='marimba',bass='round',octave=-12,chord=[55,58,62]),
    dict(shift=-3,lead='kalimba',bass='wobble',octave=-12,chord=[52,55,59,62]),
    dict(shift=-5,lead='glass',bass='sub',octave=0,chord=[50,53,57,60],sparse=True),
    dict(shift=2,lead='flute',bass='sub',octave=-12,chord=[57,60,64]),
    dict(shift=-7,lead='chip',bass='square',octave=-12,chord=[48,51,55,58]),
    dict(shift=-2,lead='cowbell',bass='dist',octave=0,chord=[53,56,60]),
    dict(shift=3,lead='shimmer',bass='sub',octave=-12,chord=[58,61,65,68]),
]

def freq(n): return 440.0*2**((np.asarray(n)-69)/12.0)

def lowpass(x,cut):
    # cut may be a number or an array (a moving filter).
    a=np.broadcast_to(np.exp(-2*np.pi*np.asarray(cut,dtype=float)/RATE),x.shape);y=np.empty_like(x);acc=0.0
    for i in range(x.size): acc=(1-a[i])*x[i]+a[i]*acc;y[i]=acc
    return y

def write(name,x,peak=.8):
    m=np.max(np.abs(x));x=x/m*peak if m>0 else x
    sf.write(OUT/(name+'.wav'),x.astype(np.float32),RATE,subtype='PCM_16')

def add(out,start,s):
    idx=(start+np.arange(s.size))%LENGTH
    np.add.at(out,idx,s)

def note_voice(kind,f,seconds):
    t=np.arange(int(seconds*RATE))/RATE
    ph=2*np.pi*f*t
    if kind=='marimba': return (np.sin(ph)+.3*np.sin(ph*4)*np.exp(-t*30))*np.exp(-t*9)
    if kind=='kalimba': return (np.sin(ph)+.25*np.sin(ph*5.4)*np.exp(-t*25))*np.exp(-t*6)
    if kind=='glass': return (np.sin(ph+1.8*np.sin(ph*3.5)*np.exp(-t*3)))*np.exp(-t*2.5)*.8
    if kind=='flute':
        breath=rng.normal(0,1,t.size)*.08
        vib=np.sin(2*np.pi*5*t)*.004
        return (np.sin(2*np.pi*f*np.cumsum(1+vib)/RATE)+.15*np.sin(ph*2)+breath)*np.minimum(1,t/.05)*np.exp(-t*3)
    if kind=='chip': return np.sign(np.sin(ph))*.5*np.exp(-t*7)*np.minimum(1,t/.003)
    if kind=='cowbell':
        raw=np.sign(np.sin(ph))+np.sign(np.sin(ph*1.48))
        return np.tanh((raw-lowpass(raw,f*.5))*1.2)*(np.exp(-t*16)*.7+np.exp(-t*4)*.3)*.6
    if kind=='shimmer':
        saw=sum(((f*(1+d)*t)%1.0)*2-1 for d in (-.006,0,.007))/3
        return lowpass(saw,2800)*np.exp(-t*5)
    return np.sin(ph)*np.exp(-t*6)

def lead(m,riff):
    out=np.zeros(LENGTH);cfg=MAPS[m]
    for bar,pattern in enumerate(LEADS[riff]):
        for i,(step,note) in enumerate(pattern):
            if cfg.get('sparse') and i%2==1: continue
            length=.6 if riff==5 or cfg['lead'] in ('glass','flute') else .3
            add(out,int((bar*16+step)*STEP*RATE),note_voice(cfg['lead'],freq(note+cfg['shift']+cfg['octave']),length))
    return out

def bass(m,riff):
    out=np.zeros(LENGTH);cfg=MAPS[m];notes=BASS[riff];previous=notes[-1][2]
    for start,beats,note in notes:
        begin=int(start*BEAT*RATE);count=int(beats*BEAT*RATE);t=np.arange(count)/RATE
        glide=np.minimum(1,t/.07);f=freq(previous+cfg['shift'])+(freq(note+cfg['shift'])-freq(previous+cfg['shift']))*(1-(1-glide)**2)
        ph=2*np.pi*np.cumsum(f)/RATE
        env=np.minimum(1,t/.004)*(.55+.45*np.exp(-t*2.2))*np.minimum(1,(count-np.arange(count))/(.02*RATE))
        kind=cfg['bass']
        if kind=='sub': tone=np.sin(ph)
        elif kind=='round': tone=np.tanh((np.sin(ph)+.25*np.sin(ph*2))*1.8)
        elif kind=='wobble': saw=(ph/(2*np.pi))%1.0*2-1;tone=lowpass(saw,300+250*(1+np.sin(2*np.pi*t*BPM/60*2)))*2.5
        elif kind=='square': tone=np.sign(np.sin(ph))*.6
        else: tone=np.tanh((np.sin(ph)+.25*np.sin(ph*2))*2.6)
        add(out,begin,tone*env*.8);previous=note
    return out

def air(m):
    t=np.arange(LENGTH)/RATE;value=np.zeros(LENGTH)
    for n in MAPS[m]['chord']:
        for d in (-.12,.12): value+=((freq(n+0)*2**(d/12)*t)%1.0)*2-1
    value/=2*len(MAPS[m]['chord'])
    low=lowpass(value,180)
    swell=.65+.35*np.sin(2*np.pi*t/(BEATS*BEAT)*2)
    fade=np.minimum(1,np.minimum(np.arange(LENGTH)/(.05*RATE),(LENGTH-np.arange(LENGTH))/(.05*RATE)))
    return low*1.6*swell*fade

if __name__=='__main__':
    for m in range(len(MAPS)):
        for r in range(6):
            write('map%d_bass_%d'%(m,r),bass(m,r))
            write('map%d_lead_%d'%(m,r),lead(m,r))
        write('map%d_air'%m,air(m),.7)
        print('map',m,'done')

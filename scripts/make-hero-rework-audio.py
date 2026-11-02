"""Original synthesized sounds for the November 2 hero rework (no samples):
drift-loop (tyre squeal, loops), car-crash (Supra hit), slime (snail trail),
headshot (Clutch's chime) and pop (bubble). Run with py -3.12."""
import sys,wave,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/voice/python-libs'))
import numpy as np
SR=44100;OUT=ROOT/'native/assets/audio/effects'
rng=np.random.default_rng(20261102)
report={}

def lowpass(x,cut):
    a=np.exp(-2*np.pi*cut/SR);y=np.zeros_like(x);acc=0.0
    for i,v in enumerate(x): acc=a*acc+(1-a)*v;y[i]=acc
    return y

def save(name,x,loop=False):
    x=np.asarray(x,dtype=float);x-=x.mean()
    if not loop:
        fade=min(round(SR*.01),len(x)//2);x[:fade]*=np.linspace(0,1,fade);x[-fade:]*=np.linspace(1,0,fade)
    peak=np.max(np.abs(x));x*=min(1,.85/max(.001,peak))
    path=OUT/(name+'.wav')
    with wave.open(str(path),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(SR);f.writeframes(np.round(x*32767).astype('<i2').tobytes())
    report[name]={'seconds':round(len(x)/SR,3),'peak':round(float(np.max(np.abs(x))),3),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}

# Tyre squeal: a wobbling pitched screech over rough noise; whole cycles so it loops.
t=np.arange(round(SR*1.2))/SR
wob=2100+180*np.sin(2*np.pi*5*t)+90*np.sin(2*np.pi*13*t)
phase=2*np.pi*np.cumsum(wob)/SR
squeal=np.sin(phase)*.5+np.sin(phase*2.01)*.18+np.sign(np.sin(phase))*.06
noise=rng.standard_normal(len(t));rough=noise-lowpass(noise,900)
x=squeal*(.8+.2*np.sin(2*np.pi*2.5*t))+rough*.25
fade=round(SR*.05);x[-fade:]=x[-fade:]*np.linspace(1,0,fade)+x[:fade]*np.linspace(0,1,fade);x=x[fade:]
save('drift-loop',x,loop=True)

# Car crash: a thump, crunching metal noise and a couple of clanging partials.
t=np.arange(round(SR*1.1))/SR
thump=np.sin(2*np.pi*(55*t+40*.03*(1-np.exp(-t/.03))))*np.exp(-t*9)
crunch=lowpass(rng.standard_normal(len(t)),3500)*np.exp(-t*5)*(1+.6*(rng.random(len(t))<.002).cumsum()%2)
clang=sum(np.sin(2*np.pi*f*t)*np.exp(-t*d)*a for f,d,a in [(612,6,.3),(1377,9,.22),(2410,12,.15)])
glass=np.where(t>.12,lowpass(rng.standard_normal(len(t)),9000)*np.exp(-(t-.12)*14)*.5,0)
save('car-crash',thump*.9+crunch*.6+clang+glass)

# Slime: a short wet blip for the snail trail slowing an enemy.
t=np.arange(round(SR*.22))/SR
save('slime',np.sin(2*np.pi*(320*t-500*t*t))*np.exp(-t*18)+lowpass(rng.standard_normal(len(t)),1200)*np.exp(-t*30)*.4)

# Headshot chime: a bright two-tone ping with a short click.
t=np.arange(round(SR*.45))/SR
click=lowpass(rng.standard_normal(len(t)),6000)*np.exp(-t*400)*.6
ping=np.sin(2*np.pi*1760*t)*np.exp(-t*7)*.5+np.sin(2*np.pi*2637*t)*np.exp(-t*9)*.35+np.sin(2*np.pi*3520*t)*np.exp(-t*14)*.15
save('headshot',click+ping)

# Bubble pop.
t=np.arange(round(SR*.18))/SR
save('pop',np.sin(2*np.pi*(900*t+2600*t*t))*np.exp(-t*28)+lowpass(rng.standard_normal(len(t)),4000)*np.exp(-t*80)*.3)

print(json.dumps(report,indent=1))

"""Sounds for the flight through hell when Digby Mole tunnels through the island
(user, November 3: "an intro/outro with a view of flying over hell, with souls
screaming and fire sounds"). Synthesized with numpy only. Run with py -3.12
from the repo root.

  hell-flight.wav  1.8 s: a deep furnace roar, crackling fire and a rushing
                   wind that swells and passes
  soul-wail-0..2   ghostly wails: a breathy voice-like tone that slides up,
                   wavers and dies away, each a different pitch and shape
"""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'tools/voice/python-libs'))
import numpy as np
import soundfile as sf

SR=44100
out=root/'native/assets/audio/effects'
rng=np.random.default_rng(1031)

def t_of(seconds): return np.arange(int(SR*seconds))/SR

def lowpass(x,cut):
    a=np.exp(-2*np.pi*cut/SR);y=np.zeros_like(x);acc=0.0
    for i in range(x.size): acc=(1-a)*x[i]+a*acc;y[i]=acc
    return y

def write(name,signal,level=.7):
    peak=np.max(np.abs(signal))
    signal=signal/peak*level if peak>0 else signal
    n=signal.size;fade=np.minimum(1,np.minimum(np.arange(n)/(SR*.02),(n-np.arange(n))/(SR*.08)))
    sf.write(out/name,(signal*fade).astype(np.float32),SR,subtype='PCM_16')
    print(name,round(n/SR,3),'s')

# Furnace roar: brown noise, slowly breathing; fire: sparse crackle pops;
# wind: band of noise swelling as the flight passes.
d=1.8;t=t_of(d)
brown=np.cumsum(rng.normal(0,1,t.size));brown-=lowpass(brown,3);brown/=np.max(np.abs(brown))
roar=lowpass(brown,140)*(0.7+.3*np.sin(2*np.pi*1.3*t))
crackle=np.zeros_like(t)
for k in range(150):
    at=rng.integers(0,t.size-800);length=rng.integers(60,500)
    pop=rng.uniform(-1,1,length)*np.exp(-np.arange(length)/(length*.25))*rng.uniform(.2,1.0)
    crackle[at:at+length]+=pop
crackle=crackle-lowpass(crackle,900)
wind=rng.normal(0,1,t.size);wind=lowpass(wind,1600)-lowpass(wind,300)
swell=np.sin(np.pi*np.clip(t/d,0,1))**1.5
flight=roar*1.0+crackle*.45+wind*swell*1.4
write('hell-flight.wav',flight,.75)

# Wails: a sawtooth-ish voice through two moving formants, sliding pitch,
# vibrato and breath noise.
def wail(f0,f1,seconds,formants,seed):
    r=np.random.default_rng(seed);t=t_of(seconds)
    slide=f0+(f1-f0)*np.sin(np.pi*np.clip(t/seconds,0,1)*.6)
    vib=1+.035*np.sin(2*np.pi*(5.5+r.uniform(-1,1))*t)
    phase=2*np.pi*np.cumsum(slide*vib)/SR
    voice=sum(np.sin(phase*h)/h for h in range(1,9))
    shaped=np.zeros_like(t)
    for fc,bw in formants:
        band=lowpass(voice,fc+bw)-lowpass(voice,max(40,fc-bw))
        shaped+=band
    breath=r.normal(0,1,t.size);breath=lowpass(breath,3000)-lowpass(breath,700)
    env=np.minimum(1,t/.12)*np.exp(-np.clip(t-seconds*.55,0,None)*5)
    return (shaped+breath*.35)*env

write('soul-wail-0.wav',wail(420,780,1.2,[(700,250),(1200,300)],1),.6)
write('soul-wail-1.wav',wail(560,330,1.1,[(500,200),(1500,350)],2),.6)
write('soul-wail-2.wav',wail(300,620,1.3,[(800,260),(2400,400)],3),.6)

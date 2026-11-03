"""Clutch's AK-47 reload (user, November 3: "add reload after 30 shots with a
classic CS AK reload sound"). Our own synthesized take on the familiar rhythm of
a rifle reload, not a copy of any game's recording. numpy only; run with
py -3.12 from the repo root.

  ak-reload.wav  2.4 s: magazine catch click, magazine slides out, new magazine
                 scrapes in and seats with a hard clack, bolt pulled back and
                 slammed forward
"""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'tools/voice/python-libs'))
import numpy as np
import soundfile as sf

SR=44100
D=2.4
out=root/'native/assets/audio/effects'
rng=np.random.default_rng(3047)
mix=np.zeros(int(SR*D))

def lowpass(x,cut):
    a=np.exp(-2*np.pi*cut/SR);y=np.zeros_like(x);acc=0.0
    for i in range(x.size): acc=(1-a)*x[i]+a*acc;y[i]=acc
    return y

def band(x,lo,hi): return lowpass(x,hi)-lowpass(x,lo)

def add(at,signal,gain=1.0):
    i=int(at*SR);n=min(signal.size,mix.size-i);mix[i:i+n]+=signal[:n]*gain

def ring(freq,length,decay,partials=(1.0,2.76,5.40,8.93),weights=(1,.6,.35,.2)):
    t=np.arange(int(SR*length))/SR;s=np.zeros_like(t)
    for p,w in zip(partials,weights): s+=w*np.sin(2*np.pi*freq*p*t+rng.uniform(0,6.28))*np.exp(-t/(decay/p**.4))
    return s

def tick(length=.004):
    n=int(SR*length);return rng.normal(0,1,n)*np.exp(-np.arange(n)/(SR*length/4))

def clack(freq,body,decay=.07):
    # A hard metal-on-metal hit: a sharp transient, a low body thump and a ring.
    n=int(SR*.25);t=np.arange(n)/SR
    s=np.zeros(n);tr=tick(.006);s[:tr.size]+=tr*1.4
    s+=np.sin(2*np.pi*body*t)*np.exp(-t/.025)*.9
    s+=ring(freq,.25,decay)*.55
    return s

def scrape(length,lo,hi,rise=True):
    n=int(SR*length);t=np.arange(n)/n
    noise=band(rng.normal(0,1,n),lo,hi)
    grit=(rng.random(n)<.004)*rng.normal(0,3,n)
    env=np.sin(np.pi*t)**.7*(.6+.4*(t if rise else 1-t))
    return (noise/np.max(np.abs(noise))+band(grit,lo,hi*1.5))*env

# Magazine catch, magazine out.
add(.12,tick(),.56)
add(.12,ring(3400,.06,.012),.35)
add(.20,scrape(.16,700,4200,rise=False),.45)
add(.36,clack(1500,140,.04),.35)
# New magazine: scrape in, then seats hard.
add(1.00,scrape(.12,900,5000),.5)
add(1.13,clack(1850,170,.08),1.0)
add(1.16,tick(.003),.4)
# Bolt: pulled back with a rasp and a click, released forward with a slam.
add(1.66,scrape(.10,1200,6000),.55)
add(1.75,clack(2600,220,.035),.55)
add(1.93,clack(2200,190,.09),1.05)
add(1.95,ring(5200,.1,.02),.25)

peak=np.max(np.abs(mix));mix=mix/peak*.75
n=mix.size;fade=np.minimum(1,(n-np.arange(n))/(SR*.05))
sf.write(out/'ak-reload.wav',(mix*fade).astype(np.float32),SR,subtype='PCM_16')
print('ak-reload.wav',round(n/SR,3),'s')

"""XP orb pickup sounds (user, November 2: "a small sound for picking up an
exp orb, to make the game more like a slot machine"). Synthesized with numpy
only. Run with py -3.12 from the repo root.

  xp-tick.wav    a tiny bright credit blip; the game raises its pitch up a
                 scale while pickups keep coming, like credits counting up
  xp-chime.wav   a short two-note sparkle every tenth pickup of a streak
"""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'tools/voice/python-libs'))
import numpy as np
import soundfile as sf

SR=44100
out=root/'native/assets/audio/effects'

def t_of(seconds): return np.arange(int(SR*seconds))/SR

def blip(freq,seconds,decay,gain):
    t=t_of(seconds)
    tone=np.sin(2*np.pi*freq*t)+.35*np.sin(2*np.pi*freq*2*t)+.12*np.sin(2*np.pi*freq*3.01*t)
    return tone*np.minimum(1,t/.0015)*np.exp(-t*decay)*gain

def pad(a,length):
    return np.pad(a,(0,max(0,length-a.size)))[:length]

def write(name,signal):
    peak=np.max(np.abs(signal))
    signal=signal/peak*.7 if peak>0 else signal
    fade=np.minimum(1,(signal.size-np.arange(signal.size))/(SR*.01))
    sf.write(out/name,(signal*fade).astype(np.float32),SR,subtype='PCM_16')
    print(name,round(signal.size/SR,3),'s')

# The tick: a glassy blip with a tiny metallic click on top.
tick=blip(1568,.09,48,1.0)
click=np.random.default_rng(7).uniform(-1,1,int(SR*.006))*np.exp(-np.arange(int(SR*.006))/SR*900)*.25
tick[:click.size]+=click
write('xp-tick.wav',tick)

# The chime: two quick rising notes with a soft shimmer tail.
n=int(SR*.32)
chime=pad(blip(1760,.32,14,.8),n)
second=blip(2637,.26,16,.7)
start=int(SR*.06);chime[start:start+second.size]+=second[:n-start]
shimmer=sum(np.sin(2*np.pi*f*t_of(.32))*np.exp(-t_of(.32)*9)*.08 for f in (5274,6272,7040))
chime+=pad(shimmer,n)
write('xp-chime.wav',chime)

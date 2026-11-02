"""Slot-machine sounds for the chest reels and card rolls (user, November 2:
"rolls need a stronger slot machine feel; rarer items should feel special").
Synthesized with numpy only. Run with py -3.12 from the repo root.

  slot-spin.wav       a seamless loop: reel whirr with a ratchet click
  slot-stop-0.wav     common: a solid mechanical clunk
  slot-stop-1.wav     rare: clunk + a clear bell ding
  slot-stop-2.wav     epic: clunk + a bright rising arpeggio with shimmer
  slot-stop-3.wav     legendary: clunk + a big major-chord swell, cymbal, sparkle
  slot-tension.wav    a rising whine for the slow last reel before an epic+
  slot-jackpot.wav    legendary payoff: bells and a coin shower
"""
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'tools/voice/python-libs'))
import numpy as np
import soundfile as sf

SR=44100
out=root/'native/assets/audio/effects'
rng=np.random.default_rng(29)

def t_of(seconds): return np.arange(int(SR*seconds))/SR

def env(t,attack=.004,decay=6.0):
    return np.minimum(1,t/attack)*np.exp(-t*decay)

def bell(freq,seconds,decay=3.0,gain=.5):
    t=t_of(seconds)
    partials=[(1,1),(2.76,.45),(5.4,.25),(8.93,.12)]
    s=sum(a*np.sin(2*np.pi*freq*m*t)*np.exp(-t*decay*(1+m*.35)) for m,a in partials)
    return s*np.minimum(1,t/.002)*gain

def clunk(seconds=.28,gain=.9):
    t=t_of(seconds)
    thump=np.sin(2*np.pi*(95-40*t)*t)*np.exp(-t*22)
    click=rng.uniform(-1,1,t.size)*np.exp(-t*90)
    rattle=rng.uniform(-1,1,t.size)*np.exp(-t*30)*.25*(np.sin(2*np.pi*31*t)>0)
    return (thump*.9+click*.5+rattle)*gain

def noise_hiss(seconds,decay=4.0,gain=.3,bright=True):
    t=t_of(seconds);n=rng.uniform(-1,1,t.size)
    if bright: n=np.diff(np.concatenate([[0],n]))  # tilt toward highs
    return n*np.exp(-t*decay)*np.minimum(1,t/.01)*gain

def mix(*parts):
    n=max(p.size for p in parts);o=np.zeros(n)
    for p in parts: o[:p.size]+=p
    return o

def place(base,part,at):
    i=int(at*SR);n=min(part.size,base.size-i)
    if n>0: base[i:i+n]+=part[:n]
    return base

def save(name,audio,peak=.85):
    audio=audio/max(1e-6,np.max(np.abs(audio)))*peak
    fade=min(400,audio.size//4);audio[-fade:]*=np.linspace(1,0,fade)
    sf.write(out/name,audio.astype(np.float32),SR,subtype='PCM_16');print(name,round(audio.size/SR,2))

# Spin loop: exactly 0.48 s so it loops seamlessly (whole cycles of each part).
loop_s=.48;t=t_of(loop_s)
whirr=np.sin(2*np.pi*125*t)*.18+np.sin(2*np.pi*250*t)*.08
whirr*=1+.25*np.sin(2*np.pi*(1/loop_s)*4*t)
spin=whirr+rng.uniform(-1,1,t.size)*.04
for k in range(12):  # ratchet clicks, 25 per second
    at=k*loop_s/12;click=rng.uniform(-1,1,int(SR*.012))*np.exp(-np.arange(int(SR*.012))/SR*400)*.55
    place(spin,click,at)
save('slot-spin.wav',spin,.6)

save('slot-stop-0.wav',clunk(),.8)
save('slot-stop-1.wav',mix(clunk(.3,.7),np.concatenate([np.zeros(int(SR*.03)),bell(1318.5,.9,3.2,.6)])),.85)

arp=np.zeros(int(SR*1.2))
for i,f in enumerate([1046.5,1318.5,1568.0,2093.0]): place(arp,bell(f,.8,4.0,.45),.03+i*.075)
shimmer=noise_hiss(1.1,3.0,.18)*(.6+.4*np.sin(2*np.pi*14*t_of(1.1)))
save('slot-stop-2.wav',mix(clunk(.3,.7),arp,shimmer),.88)

dur=2.2;t=t_of(dur)
chord=np.zeros(t.size)
for f in [261.63,329.63,392.0,523.25,659.25]:
    for d in (-.6,0,.6):
        ph=2*np.pi*(f+d)*t;chord+=(2*(ph/(2*np.pi)%1)-1)*.05+np.sin(ph)*.06
chord*=np.minimum(1,t/.35)*np.exp(-np.maximum(0,t-.9)*2.2)
cym=noise_hiss(2.0,1.6,.35)
spark=np.zeros(t.size)
for i in range(14): place(spark,bell(rng.uniform(2000,4200),.4,7,.18),.15+i*.09)
save('slot-stop-3.wav',mix(clunk(.35,.9),chord,cym,spark),.9)

t=t_of(1.1);f=300+900*(t/t[-1])**2
whine=np.sin(2*np.pi*np.cumsum(f)/SR)*.4*np.minimum(1,t/.05)
ticks=np.zeros(t.size)
k=0.0
while k<1.05:
    place(ticks,clunk(.05,.35),k);k+=max(.035,.16*(1-k))
save('slot-tension.wav',mix(whine,ticks),.6)

jack=np.zeros(int(SR*2.4))
melody=[523.25,659.25,783.99,1046.5,783.99,1046.5,1318.5]
for i,f in enumerate(melody): place(jack,mix(bell(f,.9,2.6,.5),bell(f*2,.6,4,.2)),i*.11)
for i in range(40): place(jack,bell(rng.uniform(2500,5200),.25,12,.12),.25+i*.045)  # coins
save('slot-jackpot.wav',jack,.85)

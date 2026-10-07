"""Original 128-beat realm themes; deterministic offline synthesis, no samples."""
from pathlib import Path
import json, wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]/"native/assets/music"
SR=22050
BEAT=60/144
N=round(128*BEAT*SR)
report=[]
for realm in range(3):
    out=np.zeros(N)
    rng=np.random.default_rng(812+realm)
    scale=[0,2,3,5,7,10,12]
    # Eight distinct four-bar sentences: sparse discovery, answer, ascent, resolution.
    motifs=[[0,2,4,3],[2,1,0,4],[0,3,5,4],[4,3,2,0],[2,4,6,5],[5,4,2,3],[4,2,1,2],[3,2,1,0]]
    for section,motif in enumerate(motifs):
        for k in range(8):
            degree=motif[k%4]
            midi=64+scale[degree]+(12 if realm==2 and k%3==0 else 0)
            f=440*2**((midi-69)/12)
            duration=(1.5 if realm==1 else 2.8)*BEAT
            t=np.arange(round(duration*SR))/SR
            env=np.minimum(1,t/.025)*np.exp(-t*(2.3 if realm==1 else 1.5))*np.minimum(1,(duration-t)/.14)
            tone=(np.sin(2*np.pi*f*t)+.22*np.sin(2*np.pi*f*2*t)+.09*np.sin(2*np.pi*f*3*t))*env*.105
            start=round((section*16+k*2+(0.5 if realm==1 and k%2 else 0))*BEAT*SR)
            out[start:start+min(len(tone),N-start)]+=tone[:N-start]
    # Quiet E/B drone breathes over eight bars, stays compatible with existing E-minor riffs.
    t=np.arange(N)/SR
    out+=(np.sin(2*np.pi*82.4069*t)+.4*np.sin(2*np.pi*123.4708*t))*.025*(.65+.35*np.sin(2*np.pi*t/(32*BEAT)))
    out*=np.minimum(1,t/.3)*np.minimum(1,(N/SR-t)/.35)
    pcm=(np.clip(out,-.85,.85)*32767).astype('<i2')
    path=ROOT/f"realm_theme_{realm}.wav"
    with wave.open(str(path),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(SR);w.writeframes(pcm.tobytes())
    assert len(pcm)/SR>53 and np.max(np.abs(out))<.85 and abs(int(pcm[0]))<10 and abs(int(pcm[-1]))<10
    report.append(dict(file=path.name,seconds=len(pcm)/SR,peak=float(np.max(np.abs(out))),clipped=int(np.count_nonzero(np.abs(out)>=1))))
print(json.dumps(report,indent=2))

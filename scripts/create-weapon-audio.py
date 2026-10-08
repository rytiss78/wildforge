"""Original layered weapon transients; deterministic synthesis, no external samples."""
from pathlib import Path
import numpy as np
import wave, json, hashlib
root=Path(__file__).resolve().parents[1]/"native/assets/audio/weapons"
root.mkdir(parents=True,exist_ok=True)
sr=44100
profiles={
 "gun":(95,.38,.9),"shotgun":(58,.65,1.4),"turret":(125,.3,.85),
 "rocket":(48,.85,1.1),"rocket-turret":(55,.72,1.1),"bomb":(43,.8,1.5),"meteor":(35,1.0,1.6),
 "rail":(110,.6,.85),"lightning":(130,.5,1.0),"lightning-turret":(145,.45,.9),
 "ice":(100,.6,.7),"poison":(75,.55,.8),"gravity":(38,1.1,.7),
 "harpoon":(85,.45,.9),"boomerang":(130,.38,.45),"disc":(160,.4,.5),
 "horn":(65,.6,.6),"bubble":(90,.4,.6),"saw":(78,.4,1.0),"flame":(62,.55,1.1),"fire-turret":(68,.5,1.0)
}
report={}
def save(name,x):
 x=x-np.mean(x);x=np.tanh(x*1.5)
 if not name.endswith("-loop"):
  x*=np.minimum(1,np.arange(len(x))/max(1,int(sr*.001)))
  x*=np.minimum(1,np.arange(len(x))[::-1]/max(1,int(sr*.03)))
 x*=.87/max(.001,np.max(np.abs(x)))
 pcm=np.round(x*32767).astype('<i2')
 path=root/(name+'.wav')
 with wave.open(str(path),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(sr);f.writeframes(pcm.tobytes())
 report[name]={"seconds":len(x)/sr,"peak":float(np.max(np.abs(x))),"rms":float(np.sqrt(np.mean(x*x))),"sha256":hashlib.sha256(path.read_bytes()).hexdigest()}
for index,(name,(bass,duration,impact)) in enumerate(profiles.items()):
 rng=np.random.default_rng(731+index);t=np.arange(int(sr*duration))/sr
 noise=rng.standard_normal(len(t));low=np.convolve(noise,np.ones(45)/45,mode='same')
 body=np.sin(2*np.pi*(bass*t+38*.025*(1-np.exp(-t/.025))))*np.exp(-t/ (.19 if bass<60 else .075))*.8
 crack=noise*np.exp(-t/.011)*.36*impact
 thump=low*np.exp(-t/.16)*2.3*impact
 tail=(noise-np.roll(noise,1))*.025*np.exp(-t/.15)
 x=body+crack+thump+tail
 if name in ['ice','rail','lightning','lightning-turret']:
  for frequency in [1760,2837,4213]:x+=np.sin(2*np.pi*frequency*t)*np.exp(-t/.105)*.075
 if name in ['poison','bubble']:
  x+=np.sin(2*np.pi*(240*t+60*t*t))*np.exp(-t/.14)*.25
 if name=='gravity':x+=np.sin(2*np.pi*(46*t-12*t*t))*np.exp(-t/.4)*.45
 if name=='horn':x+=sum(np.sin(2*np.pi*98*k*t)/k for k in [1,2,3,4])*np.exp(-t/.13)*.23
 if name in ['saw','flame','fire-turret']:x+=low*np.exp(-t/.2)*2
 if name in ['boomerang','disc']:x+=noise*np.sin(np.pi*np.minimum(1,t/.25))**2*np.exp(-t/.13)*.2
 save(name,x)
for index,name in enumerate(['saw','flame','fire-turret']):
 rng=np.random.default_rng(921+index);n=sr*2;t=np.arange(n)/sr
 noise=rng.standard_normal(n);low=np.fft.irfft(np.fft.rfft(noise)*np.exp(-(np.fft.rfftfreq(n,1/sr)/900)**4),n)
 if name=='saw':x=(np.sin(2*np.pi*85*t)+.3*np.sin(2*np.pi*170*t)+.14*np.sin(2*np.pi*340*t))*.16+low*.6
 else:x=low*1.6+np.sin(2*np.pi*55*t)*.15
 save(name+'-loop',x)
(root/'provenance.json').write_text(json.dumps({"author":"Wildforge procedural synthesis","generator":"scripts/create-weapon-audio.py","external_samples":False,"samples":report},indent=2))
assert all(v['peak']<.9 and v['rms']>.015 for v in report.values())
print(json.dumps({"samples":len(report),"unique":len({v['sha256'] for v in report.values()}),"clipped":False}))

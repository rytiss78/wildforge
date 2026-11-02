"""Co-op soundboard cheers for downed players (user, November 2): ten short,
original encouraging lines rendered offline with Kokoro, plus a synthesized
air horn. Run with py -3.12."""
from pathlib import Path
import sys,json,hashlib
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'tools/voice/python-libs'))
import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro
engine=Kokoro(str(root/'tools/voice/kokoro-v1.0.onnx'),str(root/'tools/voice/voices-v1.0.bin'))
out=root/'native/assets/voices/cheers';out.mkdir(parents=True,exist_ok=True)
lines=[('go','am_puck','Go, go, go!'),('got_this','af_heart','You got this!'),('behind','am_adam','Behind you!'),
 ('nice','bf_emma','Nice one!'),('dont_give_up','am_michael',"Don't give up!"),('help','af_bella','Help me up!'),
 ('wow','am_fenrir','Wooow!'),('lets_go','bm_george',"Let's go!"),('watch_out','af_nicole','Watch out!'),('legend','am_echo','Absolute legend!')]
records=[]
for key,voice,text in lines:
    p=out/f'cheer_{key}.wav'
    if p.exists(): audio,sr=sf.read(p)
    else:
        audio,sr=engine.create(text,voice=voice,speed=1.12,lang='en-gb' if voice.startswith('b') else 'en-us')
        audio=np.asarray(audio,dtype=np.float32);audio*=.85/max(.85,float(np.max(np.abs(audio))))
        sf.write(p,audio,sr,subtype='PCM_16')
    records.append({'id':p.stem,'voice':voice,'text':text,'duration':round(len(audio)/sr,3),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
# Air horn: three stacked detuned saw tones, synthesized.
sr=44100;t=np.arange(int(sr*.9))/sr
horn=sum(np.sign(np.sin(2*np.pi*f*t))*.25+np.sin(2*np.pi*f*t)*.2 for f in [415,523,622])
env=np.minimum(1,t/.02)*np.minimum(1,(t[-1]-t)/.08)*(1+.15*np.sin(2*np.pi*6*t))
horn=horn*env;horn*=.8/np.max(np.abs(horn))
p=out/'cheer_horn.wav';sf.write(p,horn.astype(np.float32),sr,subtype='PCM_16')
records.append({'id':p.stem,'voice':'synth','text':'(air horn)','duration':.9,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(out/'cheers-provenance.json').write_text(json.dumps({'engine':'Kokoro-82M v1.0, offline; air horn synthesized','type':'Original lines with synthetic neural voices; no recordings or cloning','lines':records},indent=1))
print(json.dumps(records,indent=1))

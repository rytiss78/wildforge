"""Render original tactical lines with a natural female neural voice, offline."""
from pathlib import Path
import sys,json,hashlib
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools/voice/python-libs'))
import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro
engine=Kokoro(str(ROOT/'tools/voice/kokoro-v1.0.onnx'),str(ROOT/'tools/voice/voices-v1.0.bin'))
lines={'boss':'Heads up. A boss is on the way.','swarm':'Here they come. Keep moving.','low_health':'Easy now. You need to heal.','shield_down':'Your shield is down. Stay sharp.','affordable':'Got enough gold? That chest is yours.','legendary':'Oh, that is legendary. Have some fun.','level':'You earned this. Pick your next power.','portal':'The gate is open. Ready for the next world?','weapon_full':'All three slots are full. Which weapon goes?','victory':'Three worlds. All yours. Beautifully done.','defeat':'Take a breath. Next time, they are yours.','realm':'New world. Let us make a little trouble.','achievement':'Nicely done. Another achievement is yours.','treasure':'Three choices. Make it a good one.'}
lines.update({f'biome_{i}':text for i,text in enumerate(['Clover Woods. A little green, a little trouble.','Puffcap Marsh. Watch those mushrooms.','Moon Craters. One small hop. One giant squish.','Cloud City. Looking heavenly, hot stuff.','Candy Hell. Sweet name. Hot welcome.','Starfall Space. Let us make the stars jealous.'])})
out=ROOT/'native/assets/voices';out.mkdir(exist_ok=True)
previous={line['id']:line['text'] for line in json.loads((out/'voice-provenance.json').read_text(encoding='utf8')).get('lines',[])} if (out/'voice-provenance.json').exists() else {}
record=[];preview=[]
for name,text in lines.items():
 p=out/(name+'.wav')
 if p.exists() and previous.get(name)==text:
  audio,sr=sf.read(p);record.append({'id':name,'text':text,'duration':round(len(audio)/sr,3),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()});continue
 audio,sr=engine.create(text,voice='af_heart',speed=1.0,lang='en-us')
 audio=np.asarray(audio,dtype=np.float32)
 audio*=.82/max(.82,float(np.max(np.abs(audio))))
 fade=min(240,len(audio)//10)
 audio[:fade]*=np.linspace(0,1,fade);audio[-fade:]*=np.linspace(1,0,fade)
 p=out/(name+'.wav');sf.write(p,audio,sr,subtype='PCM_16')
 record.append({'id':name,'text':text,'duration':round(len(audio)/sr,3),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
 print(name,round(len(audio)/sr,2),flush=True)
 if name in ['swarm','low_health','legendary']:preview.extend([audio,np.zeros(int(sr*.55))])
(out/'voice-provenance.json').write_text(json.dumps({'engine':'Kokoro-82M v1.0','voice':'af_heart','type':'Original text rendered with a synthetic neural voice; not a human recording or voice clone','modelLicense':'Apache-2.0','source':'https://huggingface.co/hexgrad/Kokoro-82M','runtime':'kokoro-onnx 0.6.1 (MIT), offline rendering only','lines':record},indent=2),encoding='utf8')

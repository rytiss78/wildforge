"""Original character hurt interjections, using the project's offline neural model."""
from pathlib import Path
import sys,json,hashlib
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'tools/voice/python-libs'))
import numpy as np
import soundfile as sf
from kokoro_onnx import Kokoro
engine=Kokoro(str(root/'tools/voice/kokoro-v1.0.onnx'),str(root/'tools/voice/voices-v1.0.bin'))
cast={
 'duck':('am_puck',['Ow!','Hey, watch the feathers!']),
 'wrench':('am_adam',['Ouch!','That stings!']),
 'broccoli':('bm_george',['Ugh!','My roots!']),
 'grandma':('bf_emma',['Oh!','You little rascal!']),
 'goblin':('am_fenrir',['Ack!','My wallet!']),
 'loaf':('bm_lewis',['Ow!','My crust!']),
 'florist':('af_heart',['Ah!','Watch the flowers!']),
 'teapot':('bf_isabella',['Ooh!','My porcelain!']),
 'octopus':('bm_daniel',['Argh!','My tentacles!']),
 'astronaut':('am_michael',['Whoa!','Suit breach!']),
 'cactus':('am_echo',['Ow!','That was sharp!']),
 'book':('bf_lily',['Ah!','My pages!']),
 'snail':('bm_fable',['Oof!','My shell!']),
 'bee':('af_bella',['Eek!','Not the wings!']),
 'sushi':('am_liam',['Hah!','Too close!']),
 'mushroom':('am_onyx',['Ouch!','Hot pan!']),
 'clock':('bm_lewis',['Agh!','Bad timing!']),
 'icecream':('af_nicole',['Oh!','Brain freeze!']),
 'bathtub':('bm_george',['Argh!','Man overboard!']),
 'peacock':('af_sarah',['Ah!','My beautiful tail!']),
 'toaster':('am_eric',['Ow!','Burnt toast!'])}
out=root/'native/assets/voices';records=[]
for hero,(voice,lines) in cast.items():
 for context,line in [(str(i),line) for i,line in enumerate(lines)]+[("discovery","Well, that looks suspicious."),("boss","That one skipped leg day."),("weapon","Three hands. Still no pockets.")]:
  p=out/(f'hurt_{hero}_{context}.wav' if context.isdigit() else f'quip_{hero}_{context}.wav')
  if p.exists(): audio,sr=sf.read(p)
  else:
   audio,sr=engine.create(line,voice=voice,speed=1.08,lang='en-gb' if voice.startswith('b') else 'en-us')
   audio=np.asarray(audio,dtype=np.float32);audio*=.8/max(.8,float(np.max(np.abs(audio))))
   sf.write(p,audio,sr,subtype='PCM_16')
  records.append({'id':p.stem,'hero':hero,'voice':voice,'text':line,'duration':round(len(audio)/sr,3),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
 print(hero,flush=True)
(out/'hero-voice-provenance.json').write_text(json.dumps({'engine':'Kokoro-82M v1.0, offline','type':'Original interjections rendered with synthetic neural voices; no human recording or cloning','modelLicense':'Apache-2.0','lines':records},indent=2))

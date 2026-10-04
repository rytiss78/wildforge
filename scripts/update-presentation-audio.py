"""Offline synthetic voice cast and original mechanical chest reel audio."""
from pathlib import Path
import os,json,hashlib
root=Path(__file__).resolve().parents[1]
os.environ.setdefault('HF_HOME',str(root/'tools/voice/pocket-models'))
os.environ.setdefault('HF_HUB_DISABLE_XET','1')
import numpy as np
import soundfile as sf
import torch
from pocket_tts import TTSModel
torch.set_num_threads(4)
torch.manual_seed(4071)
out=root/'native/assets/voices'
model=TTSModel.load_model()
voices={name:model.get_state_for_audio_prompt(name) for name in ['alba','marius','javert','charles','fantine','anna','eponine','azelma']}
voices['jean']=voices['charles'];voices['cosette']=voices['anna']
events={'boss':'A boss approaches.','swarm':'Here they come.','low_health':'You need to heal.','shield_down':'Shield broken.',
 'affordable':'You can open a chest.','legendary':'Legendary treasure!','level':'Level up!','portal':'The gate is open.',
 'weapon_full':'Upgrade your weapons.','victory':'Three worlds conquered!','defeat':'Try again, hero.','realm':'A new world awaits.',
 'achievement':'Achievement unlocked.','treasure':'Choose your treasure.'}
events.update({f'biome_{i}':text+'.' for i,text in enumerate(['Clover Woods','Puffcap Marsh','Moon Craters','Cloud City','Candy Hell','Starfall Space'])})
records=[];hero_records=[]
def render(name,text,voice):
 audio=model.generate_audio(voices[voice],text).detach().cpu().numpy().astype(np.float32)
 active=np.flatnonzero(np.abs(audio)>.007)
 if len(active): audio=audio[max(0,active[0]-int(model.sample_rate*.04)):min(len(audio),active[-1]+int(model.sample_rate*.14))]
 peak=max(.01,float(np.max(np.abs(audio))));audio*=min(1.7,.8/peak)
 p=out/(name+'.wav');sf.write(p,audio,model.sample_rate,subtype='PCM_16')
 print(name,round(len(audio)/model.sample_rate,2),flush=True)
 return {'id':name,'text':text,'voice':{'jean':'charles','cosette':'anna'}.get(voice,voice),'duration':round(len(audio)/model.sample_rate,3),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
for name,text in events.items(): records.append(render(name,text,'alba'))
cast={
 'duck':('marius',['Ow!','Watch the feathers!']),'wrench':('jean',['Ouch!','That stings!']),
 'broccoli':('javert',['Ugh!','My roots!']),'grandma':('fantine',['Oh!','You little rascal!']),
 'goblin':('marius',['Ack!','My wallet!']),'loaf':('jean',['Ow!','My crust!']),
 'florist':('cosette',['Ah!','Watch the flowers!']),'teapot':('alba',['Ooh!','My porcelain!']),
 'octopus':('javert',['Argh!','My tentacles!']),'astronaut':('jean',['Whoa!','Suit breach!']),
 'cactus':('marius',['Ow!','That was sharp!']),'book':('fantine',['Ah!','My pages!']),
 'snail':('javert',['Oof!','My shell!']),'bee':('eponine',['Eek!','Not the wings!']),
 'sushi':('marius',['Hah!','Too close!']),'mushroom':('jean',['Ouch!','Hot pan!']),
 'clock':('javert',['Agh!','Bad timing!']),'icecream':('azelma',['Oh!','Brain freeze!']),
 'bathtub':('javert',['Argh!','Man overboard!']),'peacock':('eponine',['Ah!','My beautiful tail!']),
 'toaster':('marius',['Ow!','Burnt toast!'])}
for hero,(voice,lines) in cast.items():
 for i,text in enumerate(lines): hero_records.append({'hero':hero,**render(f'hurt_{hero}_{i}',text,voice)})
common={'engine':'Kyutai Pocket TTS 3.3.0, CPU offline rendering','type':'Original lines generated with stock synthetic voice profiles. No human recordings are shipped.',
 'source':'https://github.com/kyutai-labs/pocket-tts','modelLicense':'MIT',
 'voiceLicenses':{'alba':'CC BY 4.0, Alba MacKenna / Kyutai stock profile','marius, javert':'CC0, Kyutai volunteer stock profiles','charles, fantine, anna, eponine, azelma':'CC BY 4.0, CSTR VCTK / University of Edinburgh stock profiles'},
 'voiceLicenseSource':'https://huggingface.co/kyutai/tts-voices/blob/main/README.md'}
(out/'voice-provenance.json').write_text(json.dumps({**common,'lines':records},indent=2),encoding='utf8')
(out/'hero-voice-provenance.json').write_text(json.dumps({**common,'lines':hero_records},indent=2),encoding='utf8')
(out/'Pocket-TTS-voice-credits.txt').write_text('Wildforge generated voice audio\nKyutai Pocket TTS, MIT: https://github.com/kyutai-labs/pocket-tts\nAlba stock synthetic profile: Alba MacKenna / Kyutai, CC BY 4.0\nVCTK profiles: CSTR / University of Edinburgh, CC BY 4.0\nhttps://datashare.ed.ac.uk/handle/10283/3443\nhttps://creativecommons.org/licenses/by/4.0/\nhttps://huggingface.co/kyutai/tts-voices\nMarius and Javert profiles: Kyutai volunteer donations, CC0.\nOriginal generated dialogue; PCM conversion, silence trimming and volume normalization.\nNo downloaded human voice recordings are included in the game.\n',encoding='utf8')
music=root/'native/assets/music';sr=22050
for tier,duration in enumerate([.75,1.25,2.1,3.1]):
 t=np.arange(int((duration+.38)*sr))/sr;audio=np.zeros(len(t));rng=np.random.default_rng(800+tier);start=.015
 while start<duration-.12:
  local=t-start;active=(local>=0)&(local<.035)
  audio[active]+=(rng.uniform(-.16,.16,active.sum())+np.sin(local[active]*2*np.pi*210)*.09)*np.exp(-local[active]*120)
  start+=.034+.14*(start/duration)**2
 for k,note in enumerate([659.25,830.61,987.77] if tier<3 else [783.99,987.77,1174.66,1567.98]):
  local=t-(duration-.22+k*.095);active=local>=0
  audio[active]+=(np.sin(2*np.pi*note*local[active])*.14+np.sin(2*np.pi*note*2*local[active])*.035)*np.exp(-local[active]*11)
 audio*=np.minimum(1,np.maximum(0,(t[-1]-t)*50));sf.write(music/f'chest_reels_{tier}.wav',np.clip(audio,-.8,.8),sr,subtype='PCM_16')
print('Synthetic cast and four chest reel sounds prepared.',flush=True)

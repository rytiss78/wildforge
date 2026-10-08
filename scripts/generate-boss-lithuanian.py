"""Original Lithuanian boss curses using local eSpeak NG Lithuanian synthesis."""
from pathlib import Path
import ctypes as C,json,wave,hashlib,sys
root=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(root/'tools/voice/python-libs'))
import espeakng_loader
lib=C.CDLL(espeakng_loader.get_library_path())
lib.espeak_Initialize.argtypes=[C.c_int,C.c_int,C.c_char_p,C.c_int]
sr=lib.espeak_Initialize(2,0,espeakng_loader.get_data_path().encode(),0)
assert sr>0
lib.espeak_SetVoiceByName.argtypes=[C.c_char_p]
assert lib.espeak_SetVoiceByName(b'lt')==0
lib.espeak_SetParameter(1,145,0)
lib.espeak_SetParameter(3,24,0)
chunks=[]
@C.CFUNCTYPE(C.c_int,C.POINTER(C.c_short),C.c_int,C.c_void_p)
def callback(data,n,events):
 if data and n: chunks.append(C.string_at(data,n*2))
 return 0
lib.espeak_SetSynthCallback(callback)
lib.espeak_Synth.argtypes=[C.c_void_p,C.c_size_t,C.c_uint,C.c_int,C.c_uint,C.c_uint,C.c_void_p,C.c_void_p]
lines=['Po velnių!','Kad tave perkūnas!','Šūdas! Dar atsiimsi!','Eik tu velniop!']
out=root/'native/assets/voices';records=[]
for i,text in enumerate(lines):
 chunks.clear();data=C.create_string_buffer(text.encode('utf-8'))
 assert lib.espeak_Synth(data,len(data),0,1,0,1,None,None)==0
 lib.espeak_Synchronize()
 raw=b''.join(chunks);assert len(raw)>1000
 path=out/f'boss_lt_{i}.wav'
 with wave.open(str(path),'wb') as f: f.setnchannels(1);f.setsampwidth(2);f.setframerate(sr);f.writeframes(raw)
 records.append({'id':path.stem,'text':text,'language':'lt','duration':len(raw)/2/sr,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
 print(text,len(raw)/2/sr)
(out/'boss-lithuanian-provenance.json').write_text(json.dumps({'engine':'eSpeak NG Lithuanian, local synthetic monster voice; no voice cloning','lines':records},ensure_ascii=False,indent=2),encoding='utf-8')

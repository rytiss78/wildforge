"""Build a three-track MIDI from the local transcription and synthesize that MIDI.
No source-audio samples are included in the rendered arrangement.
"""
from pathlib import Path
import json,hashlib
import wave as wave_io
import numpy as np
import soundfile as sf
import pretty_midi
from scipy.signal import butter,sosfilt,find_peaks
root=Path(__file__).resolve().parents[1];work=root/'.build-staging/music-transcription'
info=json.loads((work/'notes.json').read_text());duration=info['duration'];tempo=info['tempo']
midi=pretty_midi.PrettyMIDI(initial_tempo=tempo)
bass=pretty_midi.Instrument(38,name='Transcribed sub bass');lead=pretty_midi.Instrument(10,name='Transcribed bell melody');drums=pretty_midi.Instrument(0,is_drum=True,name='Detected percussion')
for start,end,pitch,amplitude,*_ in sorted(info['notes']):
 if end-start<.07 or amplitude<.2: continue
 velocity=int(np.clip(amplitude*125,30,110))
 target=bass if pitch<50 else lead
 target.notes.append(pretty_midi.Note(velocity,int(pitch),max(0,start),min(duration,end)))
percussive,sr=sf.read(work/'percussive.wav')
for lo,hi,pitch,gap,threshold in [(35,135,36,.23,.7),(180,2200,38,.23,1.15),(4500,10000,42,.095,.6)]:
 filtered=sosfilt(butter(3,[lo,hi],btype='bandpass',fs=sr,output='sos'),percussive)
 hop=220;frames=len(filtered)//hop;energy=np.sqrt(np.mean(filtered[:frames*hop].reshape(frames,hop)**2,axis=1))
 peaks,props=find_peaks(energy,distance=int(gap*sr/hop),height=np.median(energy)+threshold*np.std(energy),prominence=np.std(energy)*.3)
 for frame,value in zip(peaks,props['peak_heights']):
  start=float(frame*hop/sr);velocity=int(np.clip(45+45*value/max(.001,np.percentile(energy,98)),40,115))
  drums.notes.append(pretty_midi.Note(velocity,pitch,start,min(duration,start+.09)))
midi.instruments=[bass,lead,drums]
out=root/'native/assets/music';out.mkdir(exist_ok=True)
midipath=out/'eclipse_paranoia.mid';midi.write(str(midipath))
# Read the saved MIDI back: the runtime audio is a render of the delivered notes.
midi=pretty_midi.PrettyMIDI(str(midipath));rate=32000;mix=np.zeros((int(duration*rate),2),dtype=np.float64);rng=np.random.default_rng(441)
for instrument in midi.instruments:
 for note in instrument.notes:
  length=min(1.8,max(.1,note.end-note.start)+.18);n=int(length*rate);t=np.arange(n)/rate;f=pretty_midi.note_number_to_hz(note.pitch);amp=note.velocity/127
  if instrument.is_drum:
   if note.pitch==36:
    phase=2*np.pi*(46*t+55*.018*(1-np.exp(-t/.018)));wave=np.sin(phase)*np.exp(-t*13)*.85
   elif note.pitch==38:
    noise=rng.uniform(-1,1,n);wave=(noise*.7+np.sin(2*np.pi*185*t)*.25)*np.exp(-t*22)*.36
   else:
    noise=rng.uniform(-1,1,n);noise=np.r_[0,np.diff(noise)];wave=noise*np.exp(-t*65)*.09
   pan=0
  elif instrument.program==38:
   wave=np.tanh((np.sin(2*np.pi*f*t)+.25*np.sin(4*np.pi*f*t))*1.5)*.3
   wave*=np.minimum(1,t/.008)*np.minimum(1,np.maximum(0,length-t)/.15);pan=0
  else:
   wave=(np.sin(2*np.pi*f*t+1.6*np.sin(2*np.pi*f*1.48*t)*np.exp(-t*14))+.3*np.sin(2*np.pi*f*2.02*t))*np.exp(-t*7)*.23
   wave*=np.minimum(1,t/.003);pan=.14 if note.pitch%2 else -.14
  wave*=amp;start=int(note.start*rate);count=min(n,len(mix)-start)
  if count<=0: continue
  mix[start:start+count,0]+=wave[:count]*(1-pan);mix[start:start+count,1]+=wave[:count]*(1+pan)
# Short stereo delay supports bell sustain without adding notes or source samples.
delay=int(rate*60/tempo*.75);mix[delay:]+=mix[:-delay,::-1]*.14
mix=np.tanh(mix*1.2);mix*=.88/max(.01,float(np.max(np.abs(mix))))
fade=int(rate*.025);mix[:fade]*=np.linspace(0,1,fade)[:,None];mix[-fade:]*=np.linspace(1,0,fade)[:,None]
def write_pcm(path,audio):
 with wave_io.open(str(path),'wb') as f:
  f.setnchannels(2);f.setsampwidth(2);f.setframerate(rate);f.writeframes((audio*32767).astype('<i2').tobytes())
write_pcm(out/'eclipse_paranoia.wav',mix)
write_pcm(work/'eclipse-preview.wav',mix[int(30*rate):int(50*rate)])
record={'source':'User-supplied PARANOIA.mp3','source_sha256':info['source_sha256'],'method':'Basic Pitch0.4 ONNX dual-pass note transcription; detected percussion; MIDI synthesized with original FM bell/sub/drum voices','scope':'Approximate MIDI arrangement, not the original recording; no source audio samples','duration':duration,'tempo_estimate':tempo,'tracks':{i.name:len(i.notes) for i in midi.instruments},'peak':float(np.max(np.abs(mix))),'midi_sha256':hashlib.sha256(midipath.read_bytes()).hexdigest(),'rms':float(np.sqrt(np.mean(mix*mix)))}
(out/'eclipse_paranoia.json').write_text(json.dumps(record,indent=2));print(json.dumps(record,indent=2))

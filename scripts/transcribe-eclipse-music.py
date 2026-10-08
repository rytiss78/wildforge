"""Local audio-to-MIDI transcription and MIDI-driven Eclipse arrangement.
Run with tools/music-env/Scripts/python.exe; source audio never leaves this PC.
"""
from pathlib import Path
import sys,json,hashlib
import numpy as np
import soundfile as sf
import librosa
from basic_pitch.inference import predict
from scipy.signal import butter,sosfilt
root=Path(__file__).resolve().parents[1]
source=Path(sys.argv[1] if len(sys.argv)>1 else 'M:/Music/Phonk/PARANOIA.mp3')
work=root/'.build-staging/music-transcription';work.mkdir(parents=True,exist_ok=True)
y,sr=sf.read(source,dtype='float32',always_2d=True);mono=y.mean(axis=1);duration=len(mono)/sr
analysis=librosa.resample(mono,orig_sr=sr,target_sr=22050)
print('Source seconds',duration,flush=True)
harmonic,percussive=librosa.effects.hpss(analysis)
sf.write(work/'harmonic.wav',harmonic,22050)
beat_tempo,beat_frames=librosa.beat.beat_track(y=percussive,sr=22050)
tempo=float(np.asarray(beat_tempo).reshape(-1)[0]);print('Detected tempo',tempo,flush=True)
model,midi,notes=predict(work/'harmonic.wav',onset_threshold=.45,frame_threshold=.3,minimum_note_length=90,minimum_frequency=40,maximum_frequency=2100,midi_tempo=tempo)
midi.write(str(work/'raw-transcription.mid'))
# Transient cowbell notes are removed by harmonic separation: transcribe a second,
# high-passed full-mix pass and retain the harmonic pass for the sub bass.
lead_audio=sosfilt(butter(4,180,fs=22050,btype='highpass',output='sos'),analysis)
lead_audio=lead_audio/max(.01,np.max(np.abs(lead_audio)))*.85
sf.write(work/'lead-input.wav',lead_audio,22050)
_,lead_midi,lead_notes=predict(work/'lead-input.wav',onset_threshold=.28,frame_threshold=.18,minimum_note_length=70,minimum_frequency=180,maximum_frequency=2300,midi_tempo=tempo)
notes=[n for n in notes if n[2]<50]+[n for n in lead_notes if n[2]>=50]
lead_midi.write(str(work/'lead-transcription.mid'))
np.savez_compressed(work/'model-output.npz',**model)
(work/'notes.json').write_text(json.dumps({'tempo':tempo,'duration':duration,'notes':notes,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest()},default=lambda v:v.tolist() if hasattr(v,'tolist') else float(v)))
sf.write(work/'percussive.wav',percussive,22050)
print('Transcribed notes',len(notes),'saved',work,flush=True)

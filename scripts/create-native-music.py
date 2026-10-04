"""Original, authored E-minor metal and cyberpunk stems; arranged per run in Godot."""
from pathlib import Path
import math, wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1] / 'native/assets/music'
ROOT.mkdir(parents=True, exist_ok=True)
SR = 22050
BPM = 144
BEAT = 60 / BPM
LENGTH = BEAT * 16
SIZE = int(round(LENGTH * SR))
RNG = np.random.default_rng(407)

def save(name, audio):
    # Headroom leaves room for all three simultaneously playing stems.
    audio = np.tanh(audio * 0.8)
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as handle:
        handle.setnchannels(1); handle.setsampwidth(2); handle.setframerate(SR)
        handle.writeframes((np.clip(audio, -1, 1) * 27000).astype('<i2').tobytes())

def put(output, sound, beat):
    start = int(beat * BEAT * SR)
    if start < 0 or start >= SIZE: return
    output[start:start + min(len(sound), SIZE - start)] += sound[:SIZE - start]

def guitar(midi, duration, mute=False):
    t = np.arange(int(duration * SR)) / SR
    frequency = 440 * 2 ** ((midi - 69) / 12)
    # Detuned power chord, multiple harmonics, hard clipping and a palm-mute envelope.
    signal = np.zeros_like(t)
    for offset, weight in [(0, 1), (7, .7), (12, .4)]:
        f = frequency * 2 ** (offset / 12)
        for detune in [.997, 1.003]:
            for harmonic in [1, 2, 3, 4, 5]:
                signal += np.sin(2 * np.pi * f * detune * harmonic * t) * weight / harmonic
    signal = np.tanh(signal * 2.1)
    # One-pole style smoothing of the distortion takes the harsh top end off.
    signal = np.convolve(signal, np.ones(4) / 4, mode='same')
    envelope = np.minimum(1, t / .004) * np.exp(-t * (24 if mute else 3.7))
    envelope *= np.minimum(1, (duration - t) / .018)
    return signal * envelope * .23

# Authored four-bar phrases: rhythmic chugs, syncopated accents and chord changes.
RIFFS = [
    [0,0,0,None,0,0,3,0, 0,0,5,0,0,None,7,5, 0,0,0,None,0,0,3,0, 7,None,5,None,3,0,0,None],
    [0,0,None,0,7,None,5,3, 0,0,None,0,5,None,3,0, 0,0,None,0,10,None,7,5, 3,None,5,None,7,0,0,None],
    [0,None,None,0,3,None,None,3, 5,None,None,5,7,None,5,None, 0,None,None,0,3,None,None,3, 10,None,7,None,5,None,3,None],
    [0,0,0,0,0,0,3,5, 7,7,7,7,5,5,3,0, 0,0,0,0,3,3,5,5, 7,None,10,None,7,None,5,None],
    [0,None,0,0,0,None,0,0, 3,None,3,3,5,None,5,5, 7,None,7,7,5,None,5,5, 3,None,3,3,0,None,0,0],
    [0,None,None,None,3,None,None,None, 5,None,None,None,7,None,None,None, 0,None,None,None,10,None,None,None, 7,None,None,None,5,None,3,None],
]
for index, phrase in enumerate(RIFFS):
    out = np.zeros(SIZE)
    for step, note in enumerate(phrase):
        if note is None: continue
        mute = index != 5 and (note == 0 or step % 2 == 1)
        put(out, guitar(40 + note, BEAT * (.48 if mute else 1.7), mute), step * .5)
    save('metal_' + str(index), out)

def drum(kind):
    duration = {'kick':.22, 'snare':.20, 'hat':.055, 'crash':.75}[kind]
    t = np.arange(int(duration * SR)) / SR
    noise = RNG.uniform(-1, 1, len(t))
    if kind == 'kick':
        frequency = 45 + 100 * np.exp(-t * 45)
        phase = np.cumsum(frequency) * 2 * np.pi / SR
        return (np.sin(phase) * np.exp(-t * 22) + noise * np.exp(-t * 150) * .18) * .5
    if kind == 'snare': return (noise * .32 + np.sin(2 * np.pi * 185 * t) * .18) * np.exp(-t * 22)
    if kind == 'hat': return (noise - np.roll(noise, 1)) * np.exp(-t * 95) * .11
    return noise * np.exp(-t * 8) * .13

for genre in ['metal','cyber']:
    for intense in [False, True]:
        out = np.zeros(SIZE)
        for step in range(32):
            beat = step * .5
            put(out, drum('hat'), beat)
            if step % 8 in ([0,3,4,6] if genre == 'metal' else [0,2,4,6]): put(out, drum('kick'), beat)
            if step % 8 in [2,6]: put(out, drum('snare'), beat)
            if intense and step % 8 in [0,1,4,5]: put(out, drum('kick'), beat+.25)
        put(out, drum('crash'), 0)
        if intense:
            for step in range(4): put(out, drum('snare'), 15 + step * .25)
        save(genre + ('_boss_drums' if intense else '_drums'), out)

for index, progression in enumerate([[0,3,5,7],[0,0,10,7],[0,5,3,7],[0,7,5,3]]):
    bass = np.zeros(SIZE); lead = np.zeros(SIZE)
    scale = [0,3,7,10,12,10,7,3]
    for step in range(64):
        chord = progression[step//16]
        duration = BEAT*.21
        t = np.arange(int(duration*SR))/SR
        f = 440*2**((28+chord-69)/12)
        saw = 2*((t*f)%1)-1
        sound = np.tanh((saw + np.sin(2*np.pi*f*t)) * 1.8) * np.exp(-t*19) * .16
        put(bass,sound,step*.25)
        tones = [0,4,7,11,12,11,7,4] if chord in [3,10] else [0,3,7,10,12,10,7,3]
        f = 440*2**((64+chord+tones[step%8]-69)/12)
        signal = (np.sin(2*np.pi*f*t)+.35*np.sin(2*np.pi*f*2*t)) * np.minimum(1,t/.007) * np.exp(-t*15) * .06
        put(lead,signal,step*.25)
        put(lead,signal*.3,step*.25+.75)
    save('cyber_'+str(index),bass);save('lead_'+str(index),lead)

pad = np.zeros(SIZE)
for bar, semitone in enumerate([0,3,5,7]):
    duration=BEAT*4;t=np.arange(int(duration*SR))/SR
    chord=np.zeros(len(t))
    for note in [40,52,59]:
        f=440*2**((note-69)/12);chord += np.sin(2*np.pi*f*t) * .025
    put(pad,chord*np.minimum(1,t/.12)*np.minimum(1,(duration-t)/.15),bar*4)
save('pad',pad)
print('Rendered 19 original guitar, drum, bass, arpeggio and pad stems at 144 BPM')

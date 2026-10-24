"""Generates the Block Drop minigame audio: a chiptune arrangement of the folk
song "Korobeiniki" (public domain, 1861) and short blip effects.

Usage: python scripts/make-block-drop-audio.py
Writes native/assets/audio/block_drop/*.wav (mono, 16-bit, 22050 Hz).
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'native', 'assets', 'audio', 'block_drop')
BEAT = 60.0 / 144.0

# (MIDI note or None for rest, beats)
A_SECTION = [
    (76, 1), (71, .5), (72, .5), (74, 1), (72, .5), (71, .5),
    (69, 1), (69, .5), (72, .5), (76, 1), (74, .5), (72, .5),
    (71, 1.5), (72, .5), (74, 1), (76, 1),
    (72, 1), (69, 1), (69, 1), (None, 1),
    (None, .5), (74, 1), (77, .5), (81, 1), (79, .5), (77, .5),
    (76, 1.5), (72, .5), (76, 1), (74, .5), (72, .5),
    (71, 1), (71, .5), (72, .5), (74, 1), (76, 1),
    (72, 1), (69, 1), (69, 1), (None, 1),
]
B_SECTION = [
    (76, 2), (72, 2), (74, 2), (71, 2), (72, 2), (69, 2), (68, 2), (71, 1), (None, 1),
    (76, 2), (72, 2), (74, 2), (71, 2), (72, 1), (76, 1), (81, 2), (80, 4),
]
# One bass root per bar (four beats).
A_BASS = [40, 45, 44, 45, 38, 36, 40, 45]
B_BASS = [45, 40, 45, 40, 45, 40, 45, 40]


def freq(note):
    return 440.0 * 2 ** ((note - 69) / 12)


def write(name, samples):
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = min(1.0, .85 / peak)
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s * scale)) * 32767)) for s in samples))


def pulse(phase, duty=.25):
    return 1.0 if phase % 1.0 < duty else -1.0


def triangle(phase):
    p = phase % 1.0
    return 4 * p - 1 if p < .5 else 3 - 4 * p


def music():
    melody = A_SECTION + A_SECTION + B_SECTION
    bass = A_BASS + A_BASS + B_BASS
    beats = sum(b for _, b in melody)
    total = int(beats * BEAT * RATE)
    out = [0.0] * total
    noise = random.Random(1861)
    # Lead: 25% pulse, slightly detached notes.
    t0 = 0.0
    for note, length in melody:
        start = int(t0 * BEAT * RATE)
        count = int(length * BEAT * RATE)
        if note is not None:
            f = freq(note)
            held = int(count * .88)
            for i in range(held):
                env = min(1.0, i / 90) * (1.0 if i < held - 300 else max(0.0, (held - i) / 300))
                out[start + i] += pulse(f * i / RATE) * .16 * env
        t0 += length
    # Bass: triangle, root and octave on eighth notes.
    eighth = int(BEAT * RATE / 2)
    for bar, root in enumerate(bass):
        for k in range(8):
            note = root + (12 if k % 2 else 0)
            f = freq(note)
            start = (bar * 8 + k) * eighth
            for i in range(int(eighth * .9)):
                if start + i >= total:
                    break
                env = min(1.0, i / 60) * max(0.0, 1 - i / (eighth * .9))
                out[start + i] += triangle(f * i / RATE) * .26 * (.35 + .65 * env)
    # Drums: kick on 1 and 3, snare on 2 and 4, hats on the off-beats.
    beat_len = int(BEAT * RATE)
    for b in range(int(beats)):
        start = b * beat_len
        if b % 2 == 0:
            phase = 0.0
            for i in range(int(.12 * RATE)):
                t = i / RATE
                phase += (50 + 90 * math.exp(-t * 30)) / RATE
                out[start + i] += math.sin(math.tau * phase) * .32 * math.exp(-t * 22)
        else:
            for i in range(int(.10 * RATE)):
                out[start + i] += noise.uniform(-1, 1) * .12 * math.exp(-i / RATE * 35)
        hat = start + beat_len // 2
        for i in range(int(.03 * RATE)):
            if hat + i < total:
                out[hat + i] += noise.uniform(-1, 1) * .05 * math.exp(-i / RATE * 120)
    write('music', out)


def tones(parts, wave_fn=pulse, amp=.3):
    out = []
    for f, seconds in parts:
        n = int(seconds * RATE)
        for i in range(n):
            env = min(1.0, i / 40) * max(0.0, 1 - i / n) ** .6
            out.append(wave_fn(f * i / RATE) * amp * env if f else 0.0)
    return out


def effects():
    noise = random.Random(7)
    write('move', tones([(freq(69), .035)], amp=.18))
    write('rotate', tones([(freq(76), .03), (freq(81), .03)], amp=.18))
    lock = []
    for i in range(int(.09 * RATE)):
        t = i / RATE
        lock.append((noise.uniform(-1, 1) * .25 + math.sin(math.tau * 90 * t) * .4) * math.exp(-t * 40))
    write('lock', lock)
    write('line', tones([(freq(72), .06), (freq(76), .06), (freq(79), .09)]))
    write('four', tones([(freq(72), .06), (freq(76), .06), (freq(79), .06), (freq(84), .06), (freq(88), .25)]))
    write('level', tones([(freq(79), .07), (freq(83), .07), (freq(86), .12)], triangle, .4))
    write('over', tones([(freq(67), .16), (freq(65), .16), (freq(63), .16), (freq(60), .4)], triangle, .4))


if __name__ == '__main__':
    music()
    effects()
    print('wrote', os.path.abspath(OUT))

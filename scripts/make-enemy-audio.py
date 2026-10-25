"""Generates the enemies' own attack sounds, kept apart from every hero sound so a
player can tell by ear who is attacking (user request, October 25). Hero weapons
are bright and clicky; enemy attacks are low, growling and organic.

  enemy-shot.wav    an enemy fires a ground mark: a wet, low "thoomp" with a hiss
  enemy-impact.wav  an enemy mark goes off: a dark crunch that drops in pitch
  enemy-bite.wav    a melee enemy hits you: a short snarl and snap

Usage: python scripts/make-enemy-audio.py
Writes native/assets/audio/effects/enemy-*.wav (mono, 16-bit, 22050 Hz).
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'native', 'assets', 'audio', 'effects')


def shot(seconds=.42):
    rng = random.Random(4101)
    n = int(seconds * RATE)
    phase = 0.0
    hiss = 0.0
    out = []
    for i in range(n):
        t = i / RATE
        # A low throat pulse falling from 150 Hz to 70 Hz, with a breathy hiss on top.
        freq = 150 - 80 * min(1.0, t / seconds)
        phase = (phase + freq / RATE) % 1.0
        body = math.sin(math.tau * phase) + .45 * math.sin(math.tau * phase * 2 + .6)
        hiss += (rng.uniform(-1, 1) - hiss) * .35
        env = min(1.0, t / .012) * math.exp(-t * 9)
        out.append(math.tanh((body * .9 + hiss * .35 * math.exp(-t * 14)) * 1.8) * env)
    return out


def impact(seconds=.7):
    rng = random.Random(4102)
    n = int(seconds * RATE)
    phase = 0.0
    rumble = 0.0
    crunch = 0.0
    out = []
    for i in range(n):
        t = i / RATE
        # A sub thud sliding from 90 Hz to 38 Hz under gritty, low-passed crunch.
        freq = 90 * math.exp(-t * 2.2) + 38
        phase = (phase + freq / RATE) % 1.0
        noise = rng.uniform(-1, 1)
        crunch += (noise - crunch) * .22
        rumble += (math.sin(math.tau * phase) - rumble) * .5
        grit = crunch * (1 if rng.random() < .55 else -.4)
        env = min(1.0, t / .006) * math.exp(-t * 5.5)
        out.append(math.tanh((rumble * 1.4 + grit * .8 * math.exp(-t * 9)) * 2.2) * env)
    return out


def bite(seconds=.3):
    rng = random.Random(4103)
    n = int(seconds * RATE)
    phases = [0.0, 0.0]
    out = []
    for i in range(n):
        t = i / RATE
        # A growl (two detuned saws at ~110 Hz, roughly amplitude-modulated) ending in a snap.
        growl = 0.0
        for k, ratio in enumerate([1.0, 1.06]):
            phases[k] = (phases[k] + 110 * ratio / RATE) % 1.0
            growl += phases[k] * 2 - 1
        growl *= .6 + .4 * math.sin(math.tau * 31 * t)
        snap = rng.uniform(-1, 1) * math.exp(-max(0.0, t - .18) * 60) if t > .18 else 0.0
        env = min(1.0, t / .01) * (1 - t / seconds)
        out.append(math.tanh((growl * .7 + snap * .9) * 2.0) * env)
    return out


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b''.join(struct.pack('<h', int(s / peak * .85 * 32767)) for s in samples))


if __name__ == '__main__':
    write('enemy-shot', shot())
    write('enemy-impact', impact())
    write('enemy-bite', bite())
    print('wrote', os.path.abspath(OUT))

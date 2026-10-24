"""Generates the Ashen Colossus roar (the final boss's phase changes and intro).

Usage: python scripts/make-colossus-audio.py
Writes native/assets/audio/colossus/roar.wav (mono, 16-bit, 22050 Hz).
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'native', 'assets', 'audio', 'colossus')


def roar(seconds=2.6):
    rng = random.Random(1717)
    n = int(seconds * RATE)
    phases = [0.0] * 4
    ratios = [1.0, 1.51, 2.02, 2.97]
    low = 0.0
    breath = 0.0
    out = []
    for i in range(n):
        t = i / RATE
        # Rises into the bellow, then sags as the breath runs out.
        base = 48 + 34 * math.sin(math.pi * min(1.0, t / (seconds * .8))) - 10 * max(0.0, t - seconds * .7)
        growl = 1.0 + .35 * math.sin(math.tau * 17 * t + math.sin(math.tau * 3 * t) * 2)
        value = 0.0
        for k, ratio in enumerate(ratios):
            phases[k] = (phases[k] + base * ratio * (1 + .004 * k) / RATE) % 1.0
            value += (phases[k] * 2 - 1) / (k + 1)
        noise = rng.uniform(-1, 1)
        breath += (noise - breath) * .18
        low += (value * growl - low) * .12
        env = min(1.0, t / .25) * max(0.0, 1 - max(0.0, t - seconds * .65) / (seconds * .35))
        out.append(math.tanh((low * 1.6 + breath * .5) * 2.4) * env)
    return out


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b''.join(struct.pack('<h', int(s / peak * .9 * 32767)) for s in samples))


if __name__ == '__main__':
    write('roar', roar())
    print('wrote', os.path.abspath(OUT))

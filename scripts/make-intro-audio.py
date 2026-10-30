"""Generates the title intro's sounds (user request, October 30: no monster
scream in the intro). Three original stingers, synthesised here:

  rise.wav   a shimmering portal whoosh while the Noggin rises (2.4 s)
  sting.wav  a comic-dramatic timpani "dun, dun, DUNN" when it looms (2.2 s)
  title.wav  a cymbal crash under a bright major-chord fanfare for the title (2.6 s)

Usage: python scripts/make-intro-audio.py
Writes native/assets/audio/intro/*.wav (mono, 16-bit, 22050 Hz).
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'native', 'assets', 'audio', 'intro')


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    gain = .85 / peak
    fade = int(.01 * RATE)
    with wave.open(os.path.join(OUT, name), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        frames = bytearray()
        for i, s in enumerate(samples):
            if i < fade:
                s *= i / fade
            if i > len(samples) - fade:
                s *= (len(samples) - i) / fade
            frames += struct.pack('<h', int(max(-1, min(1, s * gain)) * 32767))
        w.writeframes(bytes(frames))


def rise(seconds=2.4):
    rng = random.Random(29)
    n = int(seconds * RATE)
    out = []
    low = 0.0
    phases = [0.0, 0.0, 0.0]
    for i in range(n):
        t = i / RATE
        p = t / seconds
        # Filtered noise sweeping up, plus three detuned rising tones.
        cutoff = .02 + .25 * p * p
        low += cutoff * (rng.uniform(-1, 1) - low)
        env = math.sin(math.pi * min(1.0, p * 1.15)) ** 1.5
        value = low * 1.6
        for k, ratio in enumerate((1.0, 1.5, 2.01)):
            freq = (110 + 440 * p * p) * ratio
            phases[k] += math.tau * freq / RATE
            value += math.sin(phases[k] + .4 * math.sin(math.tau * 6 * t)) * .22 / (k + 1)
        out.append(value * env)
    return out


def drum(t, freq, decay):
    # A timpani-ish hit: a pitch-dropping sine with a short noisy attack.
    bend = freq * (1 + .35 * math.exp(-t * 30))
    return math.sin(math.tau * bend * t) * math.exp(-t * decay)


def sting(seconds=2.2):
    rng = random.Random(41)
    n = int(seconds * RATE)
    hits = [(0.0, 98.0, 7.0, .7), (.32, 98.0, 7.0, .7), (.72, 73.4, 2.4, 1.0)]
    out = []
    for i in range(n):
        t = i / RATE
        value = 0.0
        for start, freq, decay, amp in hits:
            if t >= start:
                d = t - start
                value += amp * (drum(d, freq, decay) + .45 * drum(d, freq * 1.5, decay * 1.4))
                value += amp * rng.uniform(-1, 1) * .25 * math.exp(-d * 60)
        # A low brass swell under the last hit.
        if t > .72:
            d = t - .72
            env = min(1.0, d / .15) * math.exp(-d * 1.3)
            value += .25 * env * sum(math.sin(math.tau * f * d) / (k + 1) for k, f in enumerate((73.4, 146.8, 220.2, 293.6)))
        out.append(value)
    return out


def title(seconds=2.6):
    rng = random.Random(7)
    n = int(seconds * RATE)
    out = []
    hiss = 0.0
    # C major arpeggio landing on a held chord, bright square-ish tones.
    notes = [(0.0, 523.25), (.09, 659.25), (.18, 783.99), (.30, 1046.5)]
    for i in range(n):
        t = i / RATE
        noise = rng.uniform(-1, 1)
        hiss += .55 * (noise - hiss)
        crash = (noise - hiss) * .55 * math.exp(-t * 1.8)
        value = crash
        for start, freq in notes:
            if t >= start:
                d = t - start
                env = min(1.0, d / .02) * math.exp(-d * 1.1)
                tone = math.sin(math.tau * freq * d)
                tone += .3 * math.sin(math.tau * freq * 2 * d) + .15 * math.sin(math.tau * freq * 3 * d)
                value += .22 * env * tone
        # A punchy kick at the slam.
        value += .9 * math.sin(math.tau * (60 + 90 * math.exp(-t * 25)) * t) * math.exp(-t * 9)
        out.append(value)
    return out


if __name__ == '__main__':
    write('rise.wav', rise())
    write('sting.wav', sting())
    write('title.wav', title())
    print('intro audio written to', os.path.normpath(OUT))

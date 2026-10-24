"""Generates Wildforge's main in-run music: an original drift-phonk stem set in G
minor at 144 BPM, matching the arrangement in sound.gd (4-bar loops, 6.667 s).

Usage: python scripts/make-phonk-music.py
Writes native/assets/music/phonk2_*.wav (mono, 16-bit, 44100 Hz):
  phonk2_drums, phonk2_boss_drums   half-time drums / double-time boss drums
  phonk2_bass_0..5                  distorted 808 with slides (verse 0-1, chorus 2-4, breakdown 5)
  phonk2_bell_0..5                  808-style cowbell melodies for the same riffs
  phonk2_air_0..2                   dark pads, one chord per island
"""
import math
import os
import random
import struct
import wave

RATE = 44100
BPM = 144.0
BEAT = 60.0 / BPM
BEATS = 16
LENGTH = int(BEATS * BEAT * RATE)
STEP = BEAT / 4.0  # sixteenth note
OUT = os.path.join(os.path.dirname(__file__), '..', 'native', 'assets', 'music')


def freq(note):
    return 440.0 * 2 ** ((note - 69) / 12.0)


def write(name, samples, peak_target=.85):
    peak = max(1e-6, max(abs(s) for s in samples))
    scale = peak_target / peak
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b''.join(struct.pack('<h', int(max(-1.0, min(1.0, s * scale)) * 32767)) for s in samples))
    print('wrote', name)


def add(out, start, samples):
    for i, value in enumerate(samples):
        j = (start + i) % LENGTH  # wrap tails so the loop is seamless
        out[j] += value


# ---------------------------------------------------------------- drums
noise = random.Random(808)


def kick(punch=1.0):
    out = []
    phase = 0.0
    for i in range(int(.42 * RATE)):
        t = i / RATE
        f = 45 + 125 * math.exp(-t * 28)
        phase += f / RATE
        body = math.sin(math.tau * phase) * math.exp(-t * 6.5)
        click = noise.uniform(-1, 1) * math.exp(-t * 300) * .35
        out.append(math.tanh((body + click) * 2.2 * punch) * .9)
    return out


def clap():
    out = []
    low = 0.0
    for i in range(int(.32 * RATE)):
        t = i / RATE
        env = sum(math.exp(-max(0.0, t - d) * 60) * (t >= d) for d in (0, .011, .022)) * .5 + math.exp(-t * 14) * .6
        n = noise.uniform(-1, 1)
        low += (n - low) * .25
        out.append((n - low) * env * .8)
    return out


def hat(length=.045, level=.35):
    out = []
    low = 0.0
    for i in range(int(length * RATE)):
        t = i / RATE
        n = noise.uniform(-1, 1)
        low += (n - low) * .55
        out.append((n - low) * math.exp(-t / length * 5) * level)
    return out


def crash():
    out = []
    low = 0.0
    for i in range(int(1.6 * RATE)):
        t = i / RATE
        n = noise.uniform(-1, 1)
        low += (n - low) * .4
        out.append((n - low) * math.exp(-t * 2.4) * .35)
    return out


def drums(boss=False):
    out = [0.0] * LENGTH
    k, c, h, ho = kick(1.25 if boss else 1.0), clap(), hat(), hat(.22, .28)
    for bar in range(4):
        base = bar * 16
        kicks = [0, 3, 6, 10, 12] if boss else [0, 7, 10]
        claps = [4, 12] if boss else [8]
        for s in kicks:
            add(out, int((base + s) * STEP * RATE), k)
        for s in claps:
            add(out, int((base + s) * STEP * RATE), c)
        for s in range(0, 16, 1 if boss else 2):
            accent = 1.0 if s % 4 == 0 else .6
            add(out, int((base + s) * STEP * RATE), [v * accent for v in h])
        add(out, int((base + 14) * STEP * RATE), ho)
        # Triplet hat roll into bars 2 and 4.
        if bar % 2 == 1:
            for r in range(6):
                add(out, int(((base + 12) * STEP + r * STEP * 2 / 3) * RATE), [v * (.5 + r * .1) for v in h])
        if boss and bar == 0:
            add(out, 0, crash())
    return [math.tanh(v * 1.4) for v in out]


# ---------------------------------------------------------------- 808 bass
BASS = [
    [(0, 3, 31), (3, 1, 34), (4, 3, 31), (7, 1, 29), (8, 3, 27), (11, 1, 29), (12, 4, 31)],
    [(0, 2, 31), (2, 2, 38), (4, 3, 34), (7, 1, 36), (8, 4, 27), (12, 2, 29), (14, 2, 31)],
    [(0, 2, 31), (2, 1, 31), (3, 1, 34), (4, 2, 39), (6, 2, 38), (8, 2, 36), (10, 2, 34), (12, 3, 31), (15, 1, 29)],
    [(0, 3, 27), (3, 1, 29), (4, 3, 31), (7, 1, 34), (8, 3, 36), (11, 1, 34), (12, 4, 31)],
    [(0, 1, 31), (1, 1, 31), (2, 2, 34), (4, 1, 36), (5, 1, 36), (6, 2, 38), (8, 2, 39), (10, 2, 38), (12, 2, 34), (14, 2, 31)],
    [(0, 8, 31), (8, 8, 27)],
]


def bass(riff):
    out = [0.0] * LENGTH
    notes = BASS[riff]
    previous = notes[-1][2]
    for start, beats, note in notes:
        begin = int(start * BEAT * RATE)
        count = int(beats * BEAT * RATE)
        target = freq(note)
        source = freq(previous)
        phase = 0.0
        for i in range(count):
            t = i / RATE
            glide = min(1.0, t / .07)  # the 808 slide from the last note
            f = source + (target - source) * (1 - (1 - glide) ** 2)
            phase += f / RATE
            env = min(1.0, t / .004) * (0.55 + 0.45 * math.exp(-t * 2.2)) * min(1.0, (count - i) / (.02 * RATE))
            tone = math.sin(math.tau * phase) + .25 * math.sin(math.tau * phase * 2)
            out[(begin + i) % LENGTH] += math.tanh(tone * 2.6) * env * .8
        previous = note
    return out


# ---------------------------------------------------------------- cowbell
BAR_A = [(0, 79), (3, 79), (6, 82), (8, 79), (10, 77), (12, 79), (14, 74)]
BAR_A2 = [(0, 79), (3, 82), (6, 84), (8, 82), (10, 79), (12, 77), (14, 74)]
BELLS = [
    [BAR_A, BAR_A, BAR_A, BAR_A2],
    [[(0, 86), (3, 84), (6, 82), (8, 79), (11, 82), (14, 79)]] * 3 + [[(0, 86), (3, 87), (6, 86), (8, 84), (11, 82), (14, 77)]],
    [[(0, 91), (2, 89), (3, 87), (5, 86), (6, 84), (8, 86), (10, 82), (11, 84), (13, 79), (14, 82)]] * 4,
    [[(0, 87), (2, 86), (4, 84), (6, 82), (8, 84), (10, 86), (12, 87), (14, 89)]] * 3 + [[(0, 91), (2, 89), (4, 87), (6, 86), (8, 84), (10, 82), (12, 79), (14, 77)]],
    [[(0, 79), (1, 79), (3, 82), (4, 79), (6, 86), (8, 79), (9, 79), (11, 84), (12, 82), (14, 77)]] * 4,
    [[(0, 79), (8, 74)]] * 4,
]


def cowbell(note, length=.2):
    f = freq(note)
    out = []
    low1 = low2 = 0.0
    p1 = p2 = 0.0
    for i in range(int(length * RATE)):
        t = i / RATE
        p1 = (p1 + f / RATE) % 1.0
        p2 = (p2 + f * 1.48 / RATE) % 1.0
        raw = (1.0 if p1 < .5 else -1.0) + (1.0 if p2 < .5 else -1.0)
        low1 += (raw - low1) * .35
        low2 += (low1 - low2) * .08
        band = low1 - low2  # crude band-pass, like the 808 cowbell
        env = math.exp(-t * 16) * .7 + math.exp(-t * 4) * .3
        out.append(math.tanh(band * 1.8) * env * .6)
    return out


def bells(riff):
    out = [0.0] * LENGTH
    for bar, pattern in enumerate(BELLS[riff]):
        for step, note in pattern:
            add(out, int((bar * 16 + step) * STEP * RATE), cowbell(note, .5 if riff == 5 else .2))
    return out


# ---------------------------------------------------------------- pads
CHORDS = [[55, 58, 62], [51, 55, 58, 62], [48, 51, 55]]  # Gm, Ebmaj7, Cm


def air(index):
    out = [0.0] * LENGTH
    low = 0.0
    hiss = 0.0
    phases = []
    for note in CHORDS[index]:
        for detune in (-.12, .12):
            phases.append([0.0, freq(note) * 2 ** (detune / 12)])
    for i in range(LENGTH):
        t = i / RATE
        value = 0.0
        for p in phases:
            p[0] = (p[0] + p[1] / RATE) % 1.0
            value += p[0] * 2 - 1  # saw
        value /= len(phases)
        low += (value - low) * .02  # dark low-pass
        n = noise.uniform(-1, 1)
        hiss += (n - hiss) * .08
        swell = .65 + .35 * math.sin(math.tau * t / (BEATS * BEAT) * 2)
        fade = min(1.0, i / (.05 * RATE), (LENGTH - i) / (.05 * RATE))
        out[i] = (low * 1.6 * swell + hiss * .05) * fade
    return out


if __name__ == '__main__':
    write('phonk2_drums', drums())
    write('phonk2_boss_drums', drums(boss=True))
    for r in range(6):
        write('phonk2_bass_%d' % r, bass(r))
        write('phonk2_bell_%d' % r, bells(r))
    for a in range(3):
        write('phonk2_air_%d' % a, air(a), .7)

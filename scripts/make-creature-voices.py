"""Generates the creatures' gibberish voices (user request, October 26): short
grunts, squeaks and burps per creature type, and a booming voice for The Grand
Noggin. Nothing here is speech; each sound is nonsense syllables from a small
formant synthesizer (a buzzing throat through two or three vowel resonances).

  creatures/<voice>-<cue>-<n>.wav   voice: squeak gibber burp growl honk hiss warble groan
                                    cue: chat (idle chatter), hurt, die; n: 0 or 1
  creatures/noggin-<cue>.wav        roar (new phase), sing (performance), bravo, boo

The game picks a voice per species (creature_voice.gd) and shifts its pitch by
body size, so ten species sharing a voice still sound different.

Usage: python scripts/make-creature-voices.py
Writes native/assets/audio/creatures/*.wav (mono, 16-bit, 22050 Hz).
"""
import math
import os
import random
import struct
import wave
import zlib

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'native', 'assets', 'audio', 'creatures')

# First three formants (Hz) of the vowels the creatures babble in.
VOWELS = {
    'a': (800, 1200, 2500), 'e': (450, 1900, 2600), 'i': (300, 2300, 3000),
    'o': (500, 900, 2400), 'u': (330, 800, 2300), 'y': (380, 1600, 2200),
}

# Per voice: throat pitch, how much it glides, syllable length, vowels, buzz
# (0 smooth .. 1 raspy), breath noise, vibrato and formant scale (small mouths
# are higher). Lengths are per syllable; a cue strings several together.
VOICES = {
    'squeak': dict(f0=760, glide=.35, syl=.07, vowels='iey', rasp=.05, breath=.05, vib=(14, .04), scale=1.45),
    'gibber': dict(f0=230, glide=.45, syl=.085, vowels='aeiouy', rasp=.25, breath=.08, vib=(7, .05), scale=1.1),
    'burp': dict(f0=88, glide=.2, syl=.32, vowels='ou', rasp=.85, breath=.12, vib=(0, 0), scale=.8),
    'growl': dict(f0=78, glide=.15, syl=.22, vowels='ao', rasp=.75, breath=.3, vib=(0, 0), scale=.75),
    'honk': dict(f0=320, glide=.25, syl=.15, vowels='ae', rasp=.35, breath=.04, vib=(0, 0), scale=1.25, nasal=True),
    'hiss': dict(f0=420, glide=.1, syl=.2, vowels='iy', rasp=.1, breath=.9, vib=(0, 0), scale=1.3),
    'warble': dict(f0=290, glide=.3, syl=.18, vowels='uoy', rasp=.08, breath=.05, vib=(9, .16), scale=1.0),
    'groan': dict(f0=112, glide=.3, syl=.3, vowels='oau', rasp=.45, breath=.15, vib=(5, .03), scale=.9),
}

# How many syllables, the pitch arc across them (start, end as multiples of f0)
# and loudness of each cue.
CUES = {
    'chat': dict(count=(2, 4), arc=(1.0, 1.08), stretch=1.0),
    'hurt': dict(count=(1, 1), arc=(1.5, 1.1), stretch=.8),
    'die': dict(count=(2, 2), arc=(1.25, .55), stretch=1.7),
}


class Resonator:
    """Two-pole band-pass at one formant."""

    def __init__(self, freq, width):
        r = math.exp(-math.pi * width / RATE)
        self.a1 = 2 * r * math.cos(math.tau * min(freq, RATE * .45) / RATE)
        self.a2 = -r * r
        self.gain = 1 - r
        self.y1 = self.y2 = 0.0

    def set(self, freq, width):
        r = math.exp(-math.pi * width / RATE)
        self.a1 = 2 * r * math.cos(math.tau * min(freq, RATE * .45) / RATE)
        self.a2 = -r * r
        self.gain = 1 - r

    def run(self, x):
        y = self.gain * x + self.a1 * self.y1 + self.a2 * self.y2
        self.y2, self.y1 = self.y1, y
        return y


def babble(voice, syllables, rng, echo=0.0):
    """syllables: list of (seconds, start_f0, end_f0, vowel_a, vowel_b, loud)."""
    v = VOICES[voice] if isinstance(voice, str) else voice
    out = []
    phase = 0.0
    breath = 0.0
    filters = [Resonator(500, 80), Resonator(1500, 120), Resonator(2500, 200)]
    widths = (90, 130, 220) if not v.get('nasal') else (55, 70, 150)
    for seconds, f_start, f_end, va, vb, loud in syllables:
        n = int(seconds * RATE)
        # A short consonant gap and a click of breath start each syllable.
        gap = int(rng.uniform(.008, .025) * RATE)
        out.extend([0.0] * gap)
        for i in range(n):
            u = i / max(1, n - 1)
            f0 = f_start + (f_end - f_start) * u
            if v['vib'][0]:
                f0 *= 1 + v['vib'][1] * math.sin(math.tau * v['vib'][0] * i / RATE)
            f0 *= 1 + rng.uniform(-.01, .01)
            phase = (phase + f0 / RATE) % 1.0
            # A buzzing throat: a pulse rich in harmonics, roughened by the rasp.
            pulse = (1 - 2 * phase) * (1 - v['rasp']) + (1.0 if phase < .18 else -.22) * v['rasp']
            if v['rasp'] > .5:
                pulse *= .55 + .45 * math.sin(math.tau * 27 * i / RATE + rng.uniform(0, .4))
            breath += (rng.uniform(-1, 1) - breath) * .6
            source = pulse + breath * v['breath'] * 1.6
            fa, fb = VOWELS[va], VOWELS[vb]
            mix = u * u * (3 - 2 * u)
            sample = 0.0
            for k, f in enumerate(filters):
                formant = (fa[k] + (fb[k] - fa[k]) * mix) * v['scale']
                if i % 32 == 0:
                    f.set(formant, widths[k] * v['scale'])
                sample += f.run(source) * (1.0, .7, .35)[k]
            env = min(1.0, i / (.012 * RATE)) * min(1.0, (n - i) / (.03 * RATE))
            out.append(sample * env * loud)
    out.extend([0.0] * int(.05 * RATE))
    if echo > 0:
        # A cavernous slap-back for the giant head: three fading taps.
        taps = ((int(.11 * RATE), echo), (int(.23 * RATE), echo * .55), (int(.37 * RATE), echo * .3))
        dry = out + [0.0] * taps[-1][0]
        out = list(dry)
        for delay, gain in taps:
            for i in range(delay, len(out)):
                out[i] += dry[i - delay] * gain
    return out


def seed(*parts):
    return zlib.crc32('/'.join(str(p) for p in parts).encode())


def cue(voice, name, variant):
    rng = random.Random(seed(voice, name, variant))
    v = VOICES[voice]
    c = CUES[name]
    count = rng.randint(*c['count'])
    if v['syl'] >= .2:
        count = min(count, 2)  # slow throats keep chatter under a second
    syllables = []
    for s in range(count):
        u = s / max(1, count - 1) if count > 1 else 0.0
        arc = c['arc'][0] + (c['arc'][1] - c['arc'][0]) * u
        base = v['f0'] * arc * rng.uniform(.9, 1.12)
        glide = v['glide'] * rng.uniform(-.6, 1.0)
        seconds = v['syl'] * c['stretch'] * rng.uniform(.75, 1.3)
        if name == 'die' and s == count - 1:
            seconds *= 1.6
            glide = -abs(v['glide']) - .25
        syllables.append((seconds, base, base * (1 + glide), rng.choice(v['vowels']), rng.choice(v['vowels']), 1.0 if s == 0 else .8))
    return babble(voice, syllables, rng)


# The Noggin: a huge, slow throat with an octave below and a big echo.
NOGGIN = dict(f0=62, glide=.2, syl=.3, vowels='ao', rasp=.4, breath=.12, vib=(4, .03), scale=.62)


def noggin(name):
    rng = random.Random(seed('noggin', name))
    f = NOGGIN['f0']
    plans = {
        # HRRRAAA-OH: a rising bellow that tips over.
        'roar': [(.75, f * 1.0, f * 1.7, 'o', 'a', 1.0), (.5, f * 1.6, f * .9, 'a', 'o', .9)],
        # La, la, laaa: three notes up a major triad, the last one held and wobbling.
        'sing': [(.28, f * 2, f * 2, 'a', 'a', .9), (.28, f * 2.52, f * 2.52, 'e', 'a', .9), (.85, f * 3, f * 3.05, 'a', 'o', 1.0)],
        # BRAH-VOH: two big pleased syllables, the second higher.
        'bravo': [(.32, f * 1.8, f * 2.1, 'a', 'a', 1.0), (.6, f * 2.4, f * 2.0, 'o', 'o', 1.0)],
        # BOOOO: a long sulky slide down.
        'boo': [(1.2, f * 1.9, f * .8, 'u', 'u', 1.0)],
    }
    voice = dict(NOGGIN)
    if name in ('roar', 'boo'):
        voice['rasp'] = .7
    lead = babble(voice, plans[name], rng, echo=.42)
    # An octave-down copy under it makes the head sound enormous.
    deep = dict(voice)
    deep['scale'] = .5
    low = babble(deep, [(s, a * .5, b * .5, va, vb, l) for s, a, b, va, vb, l in plans[name]], random.Random(7), echo=.42)
    return [lead[i] + (low[i] * .6 if i < len(low) else 0.0) for i in range(len(lead))]


def write(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b''.join(struct.pack('<h', int(math.tanh(s / peak * 1.2) / math.tanh(1.2) * .85 * 32767)) for s in samples))


if __name__ == '__main__':
    for voice in VOICES:
        for name in CUES:
            for variant in range(2):
                write('%s-%s-%d' % (voice, name, variant), cue(voice, name, variant))
    for name in ('roar', 'sing', 'bravo', 'boo'):
        write('noggin-' + name, noggin(name))
    print('wrote', os.path.abspath(OUT))

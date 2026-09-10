#!/usr/bin/env python3
"""Original P5 restrained bass phrase. No samples, RNG, or external dependencies."""
import math
from pathlib import Path
import struct
import wave

RATE = 22050
DURATION = 8
# C2/G2/C3: sparse sustained tones, with a soft octave for phone speakers.
NOTES = [(0, 1.7, 65.406), (2, 1.5, 98.0), (4, 2.7, 130.813)]

def generate():
    samples = []
    for i in range(RATE * DURATION):
        time = i / RATE
        value = 0.0
        for start, length, hz in NOTES:
            at = time - start
            if 0 <= at < length:
                envelope = min(1, at / .12) * min(1, (length - at) / .5)
                value += .15 * envelope * (math.sin(math.tau * hz * at) + .25 * math.sin(math.tau * hz * 2 * at))
        assert abs(value) < 1
        samples.append(round(value * 32767))
    output = Path(__file__).resolve().parents[1] / 'assets/audio/radio/wideband.wav'
    with wave.open(str(output), 'wb') as audio:
        audio.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        audio.writeframes(struct.pack('<%dh' % len(samples), *samples))
    print(f'wideband: {DURATION}s, peak {max(abs(s) for s in samples) / 32767:.3f}')

if __name__ == '__main__':
    generate()

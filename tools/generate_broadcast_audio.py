#!/usr/bin/env python3
"""P4 original station stings; stdlib synthesis, no recordings or external samples."""
import math
from pathlib import Path
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
RATE = 22050
# (start seconds, duration seconds, fundamental Hz, gain)
SCORES = {
    'sign_on': [(0, .30, 261.63, .15), (.22, .30, 392, .13), (.44, .52, 523.25, .12)],
    'line_open': [(0, .18, 440, .10), (.25, .18, 440, .10), (.5, .45, 329.63, .12)],
    'ridge_alert': [(0, .40, 196, .13), (.35, .40, 185, .13), (.7, .55, 130.81, .15)],
}

def generate():
    for name, notes in SCORES.items():
        samples = []
        duration = max(start + length for start, length, _, _ in notes) + .10
        for i in range(math.ceil(duration * RATE)):
            t = i / RATE
            value = 0.0
            for start, length, hz, gain in notes:
                at = t - start
                if 0 <= at < length:
                    envelope = min(1, at / .015) * min(1, (length - at) / .10)
                    value += gain * envelope * (math.sin(math.tau * hz * at) + .14 * math.sin(math.tau * hz * 3 * at))
            assert abs(value) < 1
            samples.append(round(value * 32767))
        path = ROOT / 'assets/audio/radio' / (name + '.wav')
        with wave.open(str(path), 'wb') as out:
            out.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
            out.writeframes(struct.pack('<%dh' % len(samples), *samples))
        print(f'{name}: {duration:.2f}s, peak {max(abs(s) for s in samples)/32767:.3f}')

if __name__ == '__main__':
    generate()

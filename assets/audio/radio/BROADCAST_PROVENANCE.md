# P4 original radio stings

Created for Nightshift FM on 2026-09-10 by Codex during the owner's requested P4
implementation. These are original, programmatically authored note sequences and
waveforms, generated with Python's standard library. No recordings, sampled audio,
commercial music, external sound libraries, voice models, or third-party melodies
were used. They introduce captioned messages; there is no spoken voice-over.

Source: `tools/generate_broadcast_audio.py`. Run it from any directory with Python 3.
Output: mono, signed 16-bit PCM WAV at 22,050 Hz, with attack/release envelopes.

| File | Use | Duration | Peak amplitude |
|---|---|---:|---:|
| `sign_on.wav` | Station ident / control-room notices | 1.06 s | 0.192 |
| `line_open.wav` | Strange caller / Caller arrival | 1.05 s | 0.104 |
| `ridge_alert.wav` | Imminent Caller approach | 1.35 s | 0.163 |

The generator asserts that samples do not clip. No additional third-party license
or attribution dependency is introduced. Artifact hashes are recorded in
`docs/evidence/P4-radio/artifact-sha256.txt`. Human listening, tone, and mix approval
remain separate from successful native playback tests. The earlier six radio WAV
files continue to come from `tools/generate_radio_art.py` and are unchanged by P4.

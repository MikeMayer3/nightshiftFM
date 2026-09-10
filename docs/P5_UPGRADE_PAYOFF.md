# P5 — Wideband upgrade payoff

Source delivery update: P5 is included with the P6 consolidated commit and phone
update. See [current handoff](../handoff.md). Verification below records the
original P5 checkpoint; its earlier local/uncommitted notes are historical.


2026-09-10. One existing build: Studio Monitor / Bass crowd damage, taking the
rank-3 **Wideband** branch (`m5.bass_driver.b1`). Source is local, uncommitted and
unpushed. P5 is now installed on the Pixel as 0.10.10/code 22; see delivery evidence below.

## Implemented

Wideband replaces the single-cone Monitor with a wider, twin-cone cabinet and
outward horns. Actual Bass attack cues draw two segmented pressure fronts instead
of the ordinary soft pressure band. Both fronts stay inside the actual attack
radius; they are presentation of the existing attack, not additional hits. The
cabinet and twin-front shape remain visible with sound muted and low effects.
Reduced flash lowers opacity. The existing earned-upgrade highlight draws attention
to the newly fitted cabinet.

A quiet original eight-second bass phrase joins the station music while Wideband
is equipped. One dedicated player bounds it to one voice, independent of attack
frequency and repeated UI refreshes. Broadcast stings duck both music voices.
Pause, draft, Mixer and background freeze playback; music-off stops it immediately;
results, menu teardown and a fresh Restart release it. Sound-effects mute and
music-off remain separate settings. There are no rhythmic input requirements.

`BassPayoff` reads the equipped branch ID. Pending offers never activate it;
accepted choices and Continue derive it immediately. Later ranks retain it;
other Bass branches and newly started rank-1 runs use the original presentation.
Already-emitted pulses remember the branch at emission. No combat content,
damage, range, timing, RNG, progression or save schema was changed. Presentation
phase is not saved: Continue begins the quiet ambient phrase anew, without
replaying an upgrade fanfare.

## Assets and extension pattern

- `assets/art/equipment/bass_wideband.svg`: original hand-authored vector artwork,
  created for this project; no external images, fonts or licensed samples.
- `assets/audio/radio/wideband.wav`: original synthesis from
  `tools/generate_wideband_audio.py`, Python standard library only. Eight seconds,
  mono PCM16, 22,050 Hz, peak amplitude 0.165 before the player's -12 dB gain.
  Sparse C/G/octave tones use soft attack/release envelopes and silent loop ends.
- The runtime has no new external dependency. An ignored, pinned local
  `imageio-ffmpeg==0.6.0` tool converts the native QA recording to MP4; it is not
  game source, game audio, or part of an export.

For another owner-selected build, add one explicit branch predicate and immutable
hardware asset; attach its bounded visual geometry to actual effect events. Derive
current hardware from accepted tracks and snapshot transient effect style at
emission. Extend the single build-music selection policy rather than allocating a
player per support, shot, upgrade or frame. Keep branch-negative, restore, mute,
interruption, deterministic-combat and measured-rendering checks. P5 implements
only Wideband; P6/P7 and other builds remain outside this change.

## Verification

PASS: pinned import; **5,719 regression checks / 0 failures**; **88 native
UI/audio/save checks / 0 failures**; **3 real-gameplay footage checks / 0 failures**;
seven foundation checks; startup smoke; and final diff validation. The only import
warning is the already-ignored nested `builds/p3-qa-src` project. The initial QA
capture fixture needed deep copies of its rolling snapshots; the final pre-choice,
pending-choice and accepted-choice JSON restore tests all pass.

Evidence is under [P5-payoff](evidence/P5-payoff/). The gameplay clip is real
mission-1 combat with automated legal inputs: seed 42, rank-2 Bass, the normal
Wideband card, then twelve seconds of upgraded combat. A rolling capture point
selects the six active seconds before the choice; the choice screen is held for
two seconds. No actors, hits, ranks or outcomes were staged in that clip. The final MP4 is
450×800 at 30 FPS, 20.03 seconds, with original gameplay audio. Full decoding
passed and an extracted frame was visually checked for the complete HUD and
controls. The local writer fixed its canvas to the default window size, so the
capture viewport matches that size; tall-phone coverage is in the native suite.

The native suite uses actual isolated MissionStore saves, Continue, upgrade cards,
Pause/Resume, Mixer and Restart. It checks 360×640, 450×1000 and 1024×768 with
large text, normal/mute/low effects, and audio lifecycle behavior. Captures of
attacks come from actual simulation cues. Unit fixtures separately cover every
Bass branch through rank 8 and compare 1,500 observed/control combat steps.

The performance harness runs unchanged against the prior commit and P5. It
separates a synthetic 150-enemy/400-projectile/12-pulse render fixture from live
simulation/rendering starting at the densest sampled upgraded moment in one
legal mission-12 campaign. Each mode uses 120 warm-up frames and 300 measured
frames. This is Mac desktop evidence, not baseline-phone performance or a P5
thermal soak. See the recorded comparison for measurements and exact scope.

Commands from the checkout, with `GODOT_BIN` set to the pinned Godot 4.7.2:

```sh
python3 tools/generate_wideband_audio.py
sh tools/godot.sh import
sh tools/godot.sh test
python3 tools/check_foundation.py
sh tools/godot.sh smoke
"$GODOT_BIN" --path . --script res://tests/visual_bass_payoff.gd
"$GODOT_BIN" --path . --resolution 450x800 --script res://tests/p5_footage.gd --write-movie builds/p5/wideband.avi --fixed-fps 30
"$GODOT_BIN" --path . --script res://tests/p5_performance.gd
git diff --check
```

Human listening/art approval, unfamiliar-player satisfaction, physical-phone P5
play/performance, release signing and store submission:
**NOT RUN**. Automated checks do not close those acceptance gates.

## Measured result and limits

Final desktop comparison against `3759501`, Apple M2 Pro / macOS:

| Scenario | Mode | Previous p95 | P5 p95 | Previous → P5 draw calls, p95 |
|---|---|---:|---:|---:|
| 150 enemies / 400 projectiles / 12 pulses | Normal | 10.788 ms | 14.119 ms | 260 → 152 |
| Same synthetic stress | Low effects | 13.581 ms | 13.596 ms | 164 → 186 |
| Live sampled mission-12 encounter | Normal | 13.355 ms | 13.356 ms | 159 → 150 |
| Same live encounter | Low effects | 13.389 ms | 13.424 ms | 115 → 115 |

All four checkpoint hashes match the previous build exactly. Live simulation p95
was 0.368 ms normal / 0.401 ms low, compared with 0.382 / 0.428 ms previously.
Comparable warm-up/end static memory growth in P5 stayed under 0.1% over these
short samples; that does not replace a twenty-minute physical-device soak.

The first pressure implementation used excessive separate drawing commands. The
final normal path batches fixed segment geometry with `draw_multiline`; low
uses two simple arcs. The API was checked against the official
[Godot 4.7 CanvasItem documentation](https://docs.godotengine.org/en/4.7/classes/class_canvasitem.html#class-canvasitem-method-draw-multiline).

Normal stress's display-synchronized upper tail increased despite a lower median
(7.842 → 7.606 ms) and fewer draw calls. An additional matched `--disable-vsync`
comparison measured normal stress p95 **10.669 → 10.000 ms** and live normal
**5.321 → 5.457 ms**. That supports display scheduling as a contributor, rather
than increased normal-mode rendering work; it does not prove every device is
unaffected. Low-effects stress retains one additional visible front: draw calls
rise by 22 across twelve simultaneous pulses, with uncapped p95 **8.190 → 8.564 ms**
and a lower median (5.756 → 5.510 ms). The measured cost is bounded and all
synchronized frame p95 samples remain below the provisional 20 ms desktop target.
Physical-phone performance remains open.

Raw samples, the initial unbatched sample, and the final
[comparison](evidence/P5-payoff/performance-comparison.json) preserve these limits.
`process_p95_ms` is Godot's process monitor and is reported separately from the
harness's frame interval and explicitly timed simulation work; it is not a GPU
measurement. Reproduce the baseline by exporting `git archive 3759501` into an
isolated directory, copying the unchanged `tests/p5_performance.gd` harness there,
creating its evidence output directory, importing, and running the same command.
Run each version sequentially, then repeat with `--disable-vsync`.

## P5 physical Pixel delivery (2026-09-10)

PASS: Android debug export **0.10.10 / code 22**, package
`org.nightshiftfm.spike`, installed in place with `adb -s 57261FDCQ00593 install -r`
on the physical Pixel 10 Pro XL. APK inspection confirms the Wideband cabinet,
music and presentation script are packaged. Version, process, resumed activity
and clean runtime log were verified. The phone was unlocked for final verification;
the visible game menu and Continue saved mission button were inspected.

All six existing save/settings JSON and backup files were byte-identical before
installation, after installation and after launch. Private backup contents remain
under ignored `builds/android/`. [Install evidence](evidence/P5-payoff/pixel-install.json)
and [visible menu](evidence/P5-payoff/pixel-menu.png).

APK: `builds/android/nightshift-m10.apk` (historical filename), SHA-256
`1abef1a50b2919fa174c9c2e50d596fe34612b681d46b1b22fe7a92a958090ec`. This identifies this export only.
Known export warnings: ignored nested `builds/p3-qa-src` project and apksigner/JDK
native-access warning. No export or captured runtime errors.

Human gameplay/listening/art approval and a P5 physical performance soak remain
NOT RUN. Source is local, uncommitted and unpushed; P6 has not started.

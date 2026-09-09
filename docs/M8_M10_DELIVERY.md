# M8–M10 continuation — 0.10.4

Owner-authorized continuation, 2026-09-09. This implements M8 and M9 together,
checks the Android emulator, fixes findings and continues into M10. The previous
0.10.3 delivery at `e2f5f2b` is the baseline. The owner subsequently authorized
committing/pushing this delivery and updating the physical Pixel. The Pixel
installation evidence below is part of this source delivery.

## Playable implementation

**M8:** all twelve campaign missions now have ten authored waves, with 90 new
wave resources for missions 4–12. Eight regular enemy roles comprise the three
existing movement families plus armored players, protective sync hubs, muting
headphones, cycling smartwatches and stationary streaming docks. Three regional
bosses are The Playlist, Cloud Speaker (two targetable satellite weak points)
and The Noise Canceller. Special roles arrive before their mission finale.
Hard unlocks after mission 4; Overload after mission 12. Six Contracts unlock
after mission 4. Records, mission medals, device counters and twelve station logs
are accessible from the route. Shared content resources remain immutable.

**M9:** all 48 local achievement conditions are evaluated, with positive and
negative fixtures. Debug/editor runs remain ineligible. Three tracked goals and
cosmetic titles remain available; tracked counts also appear when paused.
Endless unlocks after mission 12. It awards three drafts per cleared wave through
wave 10, one thereafter, with recruitment before waves 2/4/6/8 and additional
windows before 12/16 when needed. Fully equipped runs consume the skipped
recruitment window automatically. Rank remains capped at eight; exhausted pools
offer 12 Health repair or 20 shield refill. Banking and defeat preserve cleared
wave scores; campaign unlocks do not advance from another mode.

Endless remixes a regional boss every fifth wave after ten. Beyond wave ten,
additional enemy HP scales by `1 + .06*(wave-10)` and breach damage by
`1 + .025*(wave-10)`, on top of the existing wave curve and selected difficulty.
The validated checkpoint envelope supports up to 1,000 waves; this is a practical
bounded schedule, not a claim of mathematically unlimited progression.

**M10:** nine original device silhouettes, closed/open guard shapes, channel
arcs, packet-direction chevrons, support-mute marks, satellite rings and boss
health bars. These read actual combat clocks and remain useful with audio off.
Three subtle regional environments and visible rank-3/6/8 hardware additions
preserve the centered tower, clear shield boundary and evenly spaced full deck.
The station now has an original 32-second synthesized instrumental loop and
bounded warning/shield cues. No commercial samples or new dependencies.

The patchboard initially shows ready connections, with descriptions and the full
catalog behind explicit controls. Shorter station copy replaces old prototype
menu text. Records show localized mode names. The compact setup, hunting tuning
needle, rotating knobs, waveform, bottom Station Health, automatic weapons and
immediately available modules from the approved 0.10.3 design remain intact.

## Defects found and fixed

- Contract composition could replace a boss with a regular enemy. Bosses now
  survive every contract remix; tests cover all regional introductions/finales.
- Reconstructed No Repeats pools ignored previous accepted cards. Purchases now
  replay into the accepted history before validating offers and consumables.
- Passive mitigation during a shield activation could credit Hold the Line.
  Credit now requires actual temporary reserve absorption or active reflection.
- Endless banking from the patchboard could leave a wiring flag on results.
  Banking clears the pending decision; banking before any cleared wave is disabled.
- Bare Antenna had a support-dependent UI path; the main/shield-only flow is
  covered by rendered setup, pause and resume tests.
- Enemy role warnings initially advertised packets for non-firing roles. Warning
  windows are now restricted to actual channel/volley behaviors.
- Legacy M2 scenes have no draft; new rank hardware rendering now handles that.
- Mission 11 contained only special enemies. All three tested Standard strategies
  lost in waves 9/10. Its revised groups alternate two simple escorts with a dock
  and an armored/caster/mimic role. All three then completed the mission.

## Save and reward contract

New runs use `m8.broadcast.1`; existing three-field campaign contexts and old
content versions retain their original schedules. Profile schema 5 adds separate
broadcast records; achievement schema 2 adds per-run wave/reflection watermarks.
Native and JSON-round-tripped saves are validated. Active actors include checked
weak-point ownership and boss child counts. Campaign, Contract and Endless rules
remain explicit in the checkpoint. Replaying results/waves cannot duplicate awards.
Normal gameplay still requires no account, network or native achievement service.

## Verification

Evidence is in `docs/evidence/M8-M10/`, except the fresh-copy runner also writes
`docs/evidence/M10/fresh.json` and `fresh-{import,test,smoke}.txt`.

| Check | Result and boundary |
|---|---|
| Fresh-source generators | PASS: zero changed generated files |
| Fresh import / regression / startup | PASS: 5,155 checks; zero failures and no engine/script errors |
| Foundation checks | PASS: 7; generated QA copies excluded from source-reference scans |
| Existing rendered layout suite | PASS: 200 checks, four viewport sizes |
| Expanded rendered suite | PASS: 63 checks; mode selection, restricted loadout, compact patchboard, all role silhouettes, pause and real one-wave Endless banking |
| Simulation matrix | PASS: 48/48 valid finished runs and checkpoint continuations; 46 victories, two legitimate Overload losses |
| Standard campaign simulations | 36/36 victories across AM/Valve Microphone, shortwave/Studio Monitor and FM/Mixing Desk strategies |
| Six Contract simulations | 6/6 victories on mission 1; this does not prove every contract/mission combination is balanced |
| Endless simulation | 60 cleared waves, 85 scheduled choices and 83 decision restores; banked result restores correctly |
| Android native mission | PASS: mission 4, ten waves, 20 actual upgrade taps, 478.2 simulated seconds, 100 Station Health, 147 intercepted packets |
| Android update/recovery | PASS: QA update preserved the save byte-for-byte; results restored. Combat and accepted-choice force-stops preserved run identity and purchases; draft recovery was also inspected |
| Desktop rendering stress | 150 enemies, 400 projectiles and 12 pulses retained; p95 9.959 ms normal / 9.463 ms low effects on Apple M2 Pro, Godot 4.7.2 |
| Android debug export | PASS: `builds/android/nightshift-m10.apk`, 0.10.4/code 16 |

The native mission uses an isolated `org.nightshiftfm.broadcastqa` package with
an explicitly labeled unlocked fixture and 3× simulation. Its purchases use real
Android taps. This is emulator automation, not a human phone playtest. The 60-wave
run and 48-run matrix are separate headless simulations. The staged device-tell
screenshots exercise the production renderer but are not played encounters.

The stress fixture measures rendering, not a real Android encounter or a thermal
soak. Static memory changed by about 7.5 KB over each 300-frame measured window
following 120 warm-up frames. No enemy or damage was silently dropped.

## Reproduce

From the repository root with the pinned Godot 4.7.2 standard build:

```sh
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
python3 tools/check_encounter_fresh.py --milestone M10
python3 tools/check_foundation.py
"$GODOT_BIN" --path . --script res://tests/visual_radio.gd
"$GODOT_BIN" --path . --script res://tests/visual_broadcast.gd
python3 tools/check_broadcast_runs.py
"$GODOT_BIN" --headless --path . --script res://tests/broadcast_playthrough.gd -- endless 1 60 bass_driver
"$GODOT_BIN" --path . --script res://tests/radio_render_stress.gd
sh tools/godot.sh android-debug
python3 tools/build_broadcast_qa.py
```

Native input drivers are `tools/android_broadcast_playtest.py` (start at a draft
with the isolated QA app foreground) and `tools/android_broadcast_recovery.py`
(start at its patchboard). They target only `org.nightshiftfm.broadcastqa` on
`emulator-5554`, Pixel_10_Pro at 1280×2856, with the QA build's 3× clock. Coordinates
are specific to this emulator configuration. Three additional Android Home/return
cycles retained the decision screen; `native-summary.json` reports no runtime
script/fatal errors and unchanged rewarded run IDs after results restoration.
`native-recovery.json`, `native-package.txt` and `qa-update.json` record recovery,
0.10.4/code 16 and byte-identical save preservation. Physical hardware is separate.

`check_broadcast_runs.py` documents the tested build strategies and checks every
actual draft via JSON recovery. Failed simulation results remain in the evidence;
`run-matrix-before-balance.json` records the mission 11 problem before adjustment.

## Physical Pixel delivery — 2026-09-09

PASS: updated the connected Pixel 10 Pro XL from 0.10.3/code 15 to 0.10.4/code 16
using `adb install -r builds/android/nightshift-m10.apk`. Package remains
`org.nightshiftfm.spike`. Launch returned `Status: ok`; the game was foreground
and its menu was inspected. The process log contained no script/fatal errors.
Both `m3_mission.json` and its backup were copied to an ignored local backup
folder and remained byte-identical before installation, after installation and
after launch. See `evidence/M8-M10/pixel-install.json`, `pixel-runtime.txt` and
`pixel-0104-menu.png`. This verifies update/launch/save preservation, not physical
combat, sound quality, haptics or thermal acceptance.

## Open acceptance gates

Physical Pixel gameplay, haptics/audio judgment, baseline-device frame rates,
20-minute thermal/memory soaks, iPhone execution, and human visual/difficulty
approval are **NOT RUN for 0.10.4**. The physical Pixel was connected for the later authorized update; the earlier
playtest used the Android emulator.
Two Overload strategies lost in the matrix; these are recorded balance observations,
not runtime failures or proof of fair difficulty. Human Endless 20/40/60 sessions
and the earlier multi-tester fun gate remain open. M8/M9 playable scope and the
M10 polish pass are implemented; full milestone acceptance is not certified.
M11 native services, signing and store submission remain outside this pass.

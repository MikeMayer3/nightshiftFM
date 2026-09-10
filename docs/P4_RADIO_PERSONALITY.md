# P4 — radio personality and boss anticipation

Git handoff: see [`handoff.md`](../handoff.md) for the consolidated commit scope
and current resume instructions. Earlier local/uncommitted statements below are
historical checkpoints superseded by that handoff.

Implemented 2026-09-10 on `main`, based on `80e514f`, alongside existing local work.
Android debug **0.10.9 / code 21** was installed and launched on the connected
Pixel 10 Pro XL on 2026-09-10, updating P3 in place. All six existing JSON/save
backup files remained byte-identical after installation and launch. Source remains
uncommitted/unpushed.

## Player-facing scope

First-region campaign missions 1–4 now have brief, authored control-room notices,
strange callers, and emergency broadcasts at waves 1, 4, and 7. Twelve regional
lines, two Caller lines, and one quiet station ident are localized in
`assets/ui_strings.csv`. Contracts, Endless, and later regions do not use these
story cues. Existing enemies, wave pacing, damage, upgrades, and RNG are unchanged.

A fixed radio-console slot above the battlefield displays the caption and either
station hardware or the Caller icon. It stays the same height between lines and
when idle. Captions last seven seconds of active simulation time. Ambient messages
have a 24-second minimum gap; if an event comes too soon it is skipped, not queued.
They never open a modal or require acknowledgement.

The existing mission-4 Caller gets an amber interference cue in Incoming Signals
five seconds before its actual authored spawn group. The indicator persists while
the living Caller is still outside the protected combat entry. Its first combat
entry triggers its arrival line. The two boss messages may preempt ambient speech;
there is only one caption and one sting voice, with no backlog. Static brackets,
color, and explicit wording carry the warning; there is no added flash or shake.
The population waveform still reflects living enemy count. Header lettering keeps
its proportions on wide displays instead of stretching with the field.

Three new original synthesized stings accompany captions. The station music ducks
6 dB during a sting. Routine tuning/channel tones cannot clash with a sting;
ordinary attack/hit feedback remains available. Provenance and reproducible scores:
[Broadcast audio provenance](../assets/audio/radio/BROADCAST_PROVENANCE.md).
Captions communicate the entire message even with all audio muted.

## Phone delivery

At the owner's request, installed the exact tested APK (`b31ee2214d7c47895605eafe091637393137129a61289de9547dc663bb4da5b7`)
using `adb -s 57261FDCQ00593 install -r builds/android/nightshift-m10.apk`.
Verified connected model/package, backed up prior app JSON files under the ignored
`builds/android` directory, compared their hashes before/after installation and
after launch, and checked package version 0.10.9/code 21, running PID, foreground
activity, and runtime log. No script, parse, fatal, or error markers were found.
The phone was locked: the running app and resumed activity were verified, but
visible game UI was not. The lock-screen screenshot is kept only with the ignored
local backup. Evidence: `evidence/P4-radio/pixel-install.json` and
`pixel-launch.log`. This is installation/process-launch evidence, not visible UI,
human gameplay or listening approval.

## Pause and save behavior

`RadioBroadcast` observes session elapsed time, wave, authored spawn order, and
living actors. It never changes simulation state or consumes RNG. `BroadcastStrip`
is a presentation-only view; `CombatScreen` owns the controller and feeds its cue
signal to the bounded `RadioAudio` player. `CombatArena` draws the protected header
indicator. No save schema or preference schema changes are required.

Pause, background, upgrade selection, and Mixer freeze caption time and sting
playback. Mute stops the voice immediately; unmute does not replay it. Results
clear the caption/threat indicator and stop playback. Restart resets presentation.

Continue suppresses all dialogue belonging to the restored wave, including lines
that may have played after its saved checkpoint. It still derives the live visual
boss warning and permits later waves' messages. This deliberately favors avoiding
repetition over replaying potentially unheard current-wave flavor text. Ordinary
pause/resume retains the current caption and remaining time without re-emission.

## Verification

Evidence: [P4-radio](evidence/P4-radio/).

| Check | Result |
|---|---|
| Pinned Godot 4.7.2 import | PASS |
| Full regression runner | PASS — 5,687 checks, zero failures |
| Native rendered UI/audio | PASS — 81 checks at 360×640, 450×1000, 1024×768 |
| Real save, Continue, Restart controls | PASS — 5 checks |
| Eight complete seeded campaigns | PASS — 622 checks; five wins, three losses |
| Foundation checks | PASS — 7 checks |
| Startup smoke | PASS |
| Android debug export and manifest | PASS — 0.10.9/code 21 |
| Whitespace/diff checks | PASS |
| P4 physical-phone installation and process launch | PASS — Pixel 10 Pro XL; saves/settings preserved |
| Visible phone UI verification | NOT RUN — phone locked |
| P4 human phone playthrough | NOT RUN |
| Human listening, writing/tone and usability approval | NOT RUN |
| Store signing/submission | NOT RUN |

Native checks cover simultaneous coaching and broadcasts, large text, muted audio,
low effects/reduced flash, stable field geometry, real pause/Mixer controls, OS
pause/resume, sting replacement/ducking/muting, and modal ordering. Screenshots were
visually inspected at the smallest and wide layouts. Full-run evidence uses real
rank-one loadouts and offered upgrades with fixed automated policies, accelerated
without rendering; it is not human balance or duration evidence. Both mission-4
runs reached the Caller and delivered each boss line once. A separate 1,500-step
matched simulation verifies unchanged actors, damage, snapshots and RNG, and checks
actual warning-to-spawn timing within one fixed-step tolerance.

An initial test-only callback captured its owning RefCounted and retained fixture
resources; it is now explicitly disconnected and the final full-run log exits
cleanly. The Continue/Restart driver accounts for the existing one-frame discard
when leaving pause. Neither finding required a gameplay change.

Non-blocking tool warnings: Godot notices an existing ignored nested QA project
under `builds/p3-qa-src`; the JDK reports apksigner's existing native-access warning.
Final logs contain no `ERROR:`, `SCRIPT ERROR:`, or `FAIL:` markers.

Commands (run from the repository with `GODOT_BIN` pointing to the pinned editor):

```sh
python3 tools/generate_broadcast_audio.py
sh tools/godot.sh import
sh tools/godot.sh test
"$GODOT_BIN" --path . --script res://tests/visual_radio_broadcast.gd
"$GODOT_BIN" --path . --script res://tests/p4_resume.gd
"$GODOT_BIN" --headless --path . --script res://tests/p4_broadcast_runs.gd
python3 tools/check_foundation.py
sh tools/godot.sh smoke
sh tools/godot.sh android-debug
git diff --check
```

Next bounded implementation task is **P5**, only when requested. Prior P0 human
playtesting and P1–P3 acceptance boundaries remain in their respective documents.

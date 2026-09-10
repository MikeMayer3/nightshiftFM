# Nightshift FM — next chat handoff

Updated 2026-09-10 for the owner's requested commit/push handoff. Read this first,
then `AGENTS.md` and `docs/NEXT_SESSION.md`. This file accompanies the commit
containing the previously local radio polish and roadmap P0 preparation/P1–P4.
Earlier documents' “uncommitted/unpushed” statements describe their original
checkpoints; this handoff supersedes them for work included in this commit.
Check `git status --short` and `git log -1` for exact current state.

## Repository and delivered build

- Checkout: `/Users/michaelmayer/Projects/Nightshift FM/nightshift_fm_codex_pack`
- Branch: `main`; origin: `https://github.com/MikeMayer3/nightshiftFM.git`.
- Previous pushed baseline: `80e514f` (M10 radio presentation/mixer).
- Godot **4.7.2 standard**, Compatibility renderer. Local editor:
  `/Applications/Godot.app/Contents/MacOS/Godot`.
- Android **0.10.9 / version code 21**, package `org.nightshiftfm.spike`.
- Owner requested installation after P4. Installed in place on Pixel 10 Pro XL,
  serial `57261FDCQ00593`; verified version, process, resumed activity, and clean
  runtime log. All six existing save/settings JSON and backup files were
  byte-identical before install, after install, and after launch.
- The phone was **locked during P4 launch verification**. Visible game UI and
  human P4 gameplay/listening/tone approval remain **NOT RUN**. Do not confuse
  resumed activity/process evidence with a visible screen or human playtest.
- APK is local/ignored: `builds/android/nightshift-m10.apk` (historical filename).
  Installed SHA-256:
  `b31ee2214d7c47895605eafe091637393137129a61289de9547dc663bb4da5b7`.
  Future rebuilds may hash differently; do not claim this hash for a new export.
- Private phone saves and the P4 lock-screen screenshot remain under ignored
  `builds/android/`; they are not repository evidence. No APK, credentials or
  private save contents are part of this source handoff.

## What is implemented

Earlier owner-directed polish removes wave countdowns, moves spawning offscreen,
protects the Incoming Signals entry corridor, shortens weapon reach, and makes
losses possible. Modules have graphical cards. Flat radio-themed splash art,
station scenery, hit effects, Net/Bass effects, enemy-count waveform, taller
health/shield bars with internal text, and a visible temporary shield boost are
in place. Preserve this direction; the owner rejected realistic splash art and
small selector indicators.

Roadmap: `docs/ADDITIONS_ROADMAP.md`.

| Part | Current state / details |
|---|---|
| P0 | Unfamiliar-player kit written in `docs/playtesting/`; human sessions NOT RUN. |
| P1 | Graphical build/connection guidance; see `docs/P1_BUILD_GUIDANCE.md`. |
| P2 | Recorded loss causes, graphical run report, immediate Retry; see `docs/P2_LOSS_FEEDBACK.md`. Owner said it looked good in their testing. |
| P3 | Once-per-install shield/boost/Mixer coaching, Help replay, visible shield handedness; see `docs/P3_ONBOARDING_RELIABILITY.md`. |
| P4 | First-region captioned radio personality, three original stings, timed Caller approach/entry cues; see `docs/P4_RADIO_PERSONALITY.md`. Installed on phone. |
| P5–P7 / G1–G3 | Not started. |

P4 specifics: campaign missions 1–4 only; waves 1/4/7 have station/caller/emergency
lines. Mission 4's existing Caller gets a five-second pre-spawn warning, static
amber interference in Incoming Signals, and a line on actual combat entry.
Captions sit outside the field and do not move it when they change. Ambient lines
have a 24-second minimum gap and seven active seconds of display. Boss lines may
replace ambient messages; one dedicated sting voice ducks music. Muting preserves
caption meaning. Pause, draft, Mixer and background freeze presentation.
Continue suppresses restored-wave dialogue while preserving the live threat
indicator; later waves and a fresh Restart can speak normally. No P4 combat/RNG
or save-schema changes. Audio provenance: `assets/audio/radio/BROADCAST_PROVENANCE.md`.

## Verification and its limits

Latest P4 evidence lives in `docs/evidence/P4-radio/`:

- PASS: **5,687** regression checks; **81** native layout/audio checks at
  360×640, 450×1000, 1024×768; **5** real save/Continue/Restart checks.
- PASS: **8** complete automated campaign runs / **622** checks (5 wins, 3 losses).
  Both Caller runs emitted warning/arrival once. This is a fixed-policy test,
  not a population win rate, human pacing or balance acceptance.
- PASS: pinned import, **7** foundation checks, smoke, Android export, diff check.
- PASS: 1,500 matched combat steps with/without P4 observers preserve snapshots,
  actors, damage and RNG; real warning-to-spawn timing checked.
- Earlier P3: ten emulator interruption/reward/power cases and 20-minute physical
  Pixel soak, 58–61 sampled FPS, no thermal throttling, 4.75% comparable cleanup
  memory growth. USB charging means unplugged battery drain was NOT measured.
  That soak predates P4; do not present it as a P4 soak.
- Human first-session comprehension, listening/art approval, broad balance,
  unavailable physical hardware, release signing and store submission remain open.
- Known non-blocking tool warnings: ignored nested QA checkout under
  `builds/p3-qa-src`; apksigner/JDK native-access warning.

Handoff review restored the existing `tests/visual_broadcast.gd` unchanged from
the prior commit and moved P4's new test to `tests/visual_radio_broadcast.gd`.
Both suites are preserved. This is test organization, not a change to the installed
game. Final handoff checks passed: local import, 5,687 regressions, 81 native P4
checks, seven foundation checks, and smoke. A clean export of only staged files
also passed import and all 5,687 regressions, verifying required files are included.
Handoff verification logs are in `docs/evidence/handoff/`; log trailing whitespace
was normalized for Git without changing reported results.

## Next bounded task

**P5 — major-upgrade visual and musical payoff**, only when the owner requests it.
Choose one existing build; make an important rank/branch transition visibly change
its hardware/attack presentation, with a subtle original musical layer if useful.
Follow the acceptance criteria in the roadmap: real before/after gameplay footage,
correct restored state, normal/mute/low-effects readability, bounded audio and
measured performance. Stop after that one build. Do not automatically implement
P6/P7, monetization, publicity, or a new roster.

Commercial direction discussed: roughly $2 paid once, no advertising or IAP.
This is a plan, not a configured or published Google Play listing.

## Working rules and useful commands

Preserve one main weapon, one shield, at most five supports from six families.
Keep content immutable, fresh missions rank one, presentation independent of RNG,
versioned/validated atomic saves, idempotent rewards, and bounded generated attacks.
P2 adds optional versioned loss history; P3 adds optional coaching history to
presentation preferences. Older saves remain compatible. Use isolated test saves.

```sh
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
sh tools/godot.sh import
sh tools/godot.sh test
python3 tools/check_foundation.py
sh tools/godot.sh smoke
"$GODOT_BIN" --path . --script res://tests/visual_radio_broadcast.gd
"$GODOT_BIN" --path . --script res://tests/p4_resume.gd
"$GODOT_BIN" --headless --path . --script res://tests/p4_broadcast_runs.gd
sh tools/godot.sh android-debug
git diff --check
```

Fail checks on `ERROR:`, `SCRIPT ERROR:` or `FAIL:` even if Godot exits zero.
Godot may need permission to write its user/config directories. Before any future
phone update, verify `adb devices -l`, target the physical device explicitly,
back up/compare existing saves and settings, install with `-r`, then verify version,
process, logs and actual visible UI when unlocked. Never clear player data for QA.
Do not depend on `/private/tmp` helpers surviving into the next session.

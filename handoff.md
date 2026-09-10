# Nightshift FM — next chat handoff

Updated 2026-09-10 after **P6 visible progression goals** and physical Pixel update.
P5 and P6 are included in the consolidated commit accompanying this handoff.
The previous commit was `3759501` (P1–P4). Use `git log -1`, `git status --short`
and `git rev-list --left-right --count HEAD...origin/main` to verify the exact
current commit and synchronization. Earlier local/uncommitted statements in the
historical milestone documents are superseded by this handoff.

## Checkout and delivered build

- Checkout: `/Users/michaelmayer/Projects/Nightshift FM/nightshift_fm_codex_pack`
- Branch: `main`; origin: `https://github.com/MikeMayer3/nightshiftFM.git`.
- Godot **4.7.2 standard**, Compatibility renderer; engine pin in `tools/`.
- Physical Pixel 10 Pro XL (`57261FDCQ00593`): **0.10.11/code 23**, package
  `org.nightshiftfm.spike`, installed in place over P5 0.10.10/code 22.
- PASS: all **six** existing save/settings JSON and backup files remained
  byte-identical before install, after install and after launch. Package/version,
  process, resumed activity and runtime log verified.
- Phone was **locked** during verification. Visible P6 phone UI is NOT VERIFIED;
  desktop screenshots do not establish physical phone usability.
- Local ignored APK: `builds/android/nightshift-m10.apk` (historical filename).
  Delivered SHA-256: `5acb21a1a3b36285fd1e956e20da87891de0de6c7b7abe0de29b67cdd37706d8`.
- Private phone files remain under ignored `builds/android/`; only sanitized
  hashes and delivery status are committed. No APK, signing key or private save
  contents belong in Git.

## Implemented scope

Preserve the owner-directed radio presentation: flat themed hardware and scenery,
offscreen spawning, protected Incoming Signals corridor, shorter weapon reach,
graphical module cards, clear shield/health/boost meters, and compact controls.
Every mission still starts at rank one with no inherited temporary combat power.

| Roadmap part | State / details |
|---|---|
| P0 | Unfamiliar-player kit in `docs/playtesting/`; human sessions NOT RUN. |
| P1 | Graphical build/connection guidance; `docs/P1_BUILD_GUIDANCE.md`. |
| P2 | Recorded loss causes, run report and Retry; `docs/P2_LOSS_FEEDBACK.md`. Owner reported favorable testing. |
| P3 | First-use coaching, Help replay and handedness; `docs/P3_ONBOARDING_RELIABILITY.md`. |
| P4 | Radio captions, original stings and Caller warning; `docs/P4_RADIO_PERSONALITY.md`. |
| P5 | Wideband rank-3 twin cabinet, pressure fronts and one original music layer; `docs/P5_UPGRADE_PAYOFF.md`. |
| P6 | Next-reward cards, real requirements/counts, explicit reward states, tracked titles and color selection; `docs/P6_PROGRESSION_GOALS.md`. |
| P7 / G1–G3 | Optional weekly challenge and store/publicity work not started. |

P6 automatically recommends existing locked hardware, then an unearned color
for available gear. It stops when that catalogue is complete. Existing tracked
title goals remain explicit player choices, with practice/ineligible progress
explained. Results show new rewards only after the checkpoint reward commit;
Continue does not duplicate rewards or repeat new-equipment announcements.
Report/Retry/Back remain accessible while reward details scroll. No new currency,
combat rules, eligibility rules, reward grant path or save schema was introduced.

## Verification and limits

- PASS: **6,084** regressions; **195** P6 native large-text/layout/save/Continue/
  pointer checks at 360×640, 450×1000 and 1024×768.
- PASS: pinned import, **7** foundation checks, desktop smoke, Android export.
- PASS: clean export containing only staged source passed import and all **6,084**
  regressions. Evidence summaries: `docs/evidence/P6-goals/verification.txt`.
- PASS: physical installation/save preservation/process checks described above.
- Earlier P5: 88 native UI/audio checks and 3 real gameplay capture checks;
  performance comparison and limitations are in its document. Do not promote
  the earlier P3 physical soak into a P5/P6 soak.
- NOT RUN: human next-goal comprehension, final P5 listening/art approval,
  unfamiliar-player release acceptance, and a new P6 phone performance soak.
  P6 synthetic result fixtures are not human wins or production achievements.

## Next requested work

P6 is complete within its implementation scope. Do not automatically start P7.
For 1.0, address remaining human playtesting/acceptance, release QA and device
coverage, M11/native achievement decisions, production signing/package identity,
store assets/metadata/privacy declarations, testing-track requirements and store
submission. Current APK uses the development package and is not a store release.
Commercial direction discussed: roughly $2 paid once, no advertising or IAP;
this is a plan, not a published listing. Verify current store requirements when
that work is requested.

## Working rules and commands

Read `AGENTS.md`, `docs/ADDITIONS_ROADMAP.md`, and the relevant milestone document.
Preserve immutable content, six support families/five simultaneous supports,
versioned atomic saves, idempotent reward commits and presentation-independent RNG.
Use isolated test saves. Fail on `ERROR:`, `SCRIPT ERROR:` or `FAIL:` even if the
process exits zero. For phone updates, explicitly target the Pixel rather than
the emulator, back up/compare saves, install with `-r`, and verify launch/version.

```sh
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
sh tools/godot.sh import
sh tools/godot.sh test
python3 tools/check_foundation.py
sh tools/godot.sh smoke
"$GODOT_BIN" --path . --script tests/visual_progression_goals.gd
sh tools/godot.sh android-debug
git diff --check
```

# P6 — Visible next unlock and progression goals

Implemented 2026-09-10. P6 adds presentation and selection of existing rewards;
no new currency, combat modifier, eligibility rule, reward commit, or save schema.

## Player flow

- Route: a hardware illustration, locked state, actual campaign requirement and
  completed-mission count point to the nearest hardware unlock. After all hardware
  is available, guidance moves to an unearned station color for available gear.
  When every hardware/color reward is earned, the route reports completion.
- Hardware & colors: browse the existing main/shield/support rewards and six
  station colors. Locked, earned and equipped labels are explicit. Earned colors
  can be selected with a full-size button; hardware uses the existing loadout UI.
  Loadout cards identify the chosen equipment. The module panel is unchanged.
- Awards: illustrated title rewards reuse the existing requirements, counters,
  tracking limit and title selection. Selected titles appear on the route.
  Tracked goals appear below route equipment selection and in results. Debug and
  other ineligible runs explain that achievement progress is disabled.
- Results: new rewards appear after the existing checkpoint reward commit, followed
  by the next reward and remaining tracked goals. The detail area scrolls while
  Report, Retry and Back remain accessible. Continue preserves earned rewards
  without announcing old equipment as newly earned again. Retry clears the cards.

Hardware thresholds come from `CampaignContent.options`; color availability comes
from `CampaignProfile.cosmetic_available`; titles and counts come from
`AchievementProfile` and `AchievementCatalog`. The automatic suggestion does not
choose blocked title goals. Choosing a title to track remains an explicit player
action; the requirement describes its eligible mode/difficulty and practice runs
are clearly marked. All modules already unlock at mission zero, so P6 does not
repeat the obsolete module-unlock copy from the old unused helper.

## Changed components

`ProgressionGoals` provides read-only reward views; `ProgressionCard` renders the
shared card. `CampaignPanel`, `ArsenalPicker`, `BootScreen` and `CombatScreen`
connect these views to the existing menu, selection and results flows. UI text
uses `assets/ui_strings.csv`. The small title plaque SVG is original project art;
other cards reuse existing licensed project hardware graphics.

## Verification

PASS: **6,084 regression checks**, including the new P6 integration suite.
Checks cover campaign progress 0–12, real unlock thresholds, distinct equipment
states, available color recommendations, all-earned completion, idempotent reward
commits, serialized reward restoration, and actual tracking/color/title buttons
through Boot's atomic save path.

PASS: **195 native UI checks** at 360×640, 450×1000 and 1024×768, with large text.
Rendered cards fit horizontally and text has no hidden lines. A labeled synthetic
victory follows the actual finish/commit/save path with valid checkpoint history.
Repeated results, finished-run Continue, pointer Retry, and route reload preserve
progress and do not duplicate rewards. These fixtures are not human victories or
production achievement evidence. A first fixture omitted required wave history;
it was corrected rather than weakening the save validator. Reload comparisons
normalize JSON numbers because Godot restores integers as floats.

PASS: pinned import, seven foundation checks, desktop startup smoke and Android
export. Full source-only staged verification and physical delivery are recorded
below and in `evidence/P6-goals/verification.txt`.

Commands (run at repository root, Godot 4.7.2 standard):

```sh
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
sh tools/godot.sh import
sh tools/godot.sh test
python3 tools/check_foundation.py
sh tools/godot.sh smoke
"$GODOT_BIN" --path . --script tests/visual_progression_goals.gd
sh tools/godot.sh android-debug
git diff --cached --check
```

Native screenshots and `native.json` are committed in `docs/evidence/P6-goals/`.
Raw logs, APKs and private phone backups remain ignored. Error scans fail on
`ERROR:`, `SCRIPT ERROR:` or `FAIL:` even if a process exits zero. Existing Godot
warnings about ignored nested QA projects and Android signing JDK native access
are not test failures.

## Remaining acceptance

Human ability to identify an appealing next goal remains **NOT RUN**. Ask an
unfamiliar player to identify the pictured reward, its requirement and progress,
then distinguish locked, earned and equipped rewards. Check the transition after
earning one and repeat on their phone with large text. P6 does not establish a
new physical-device performance soak or release/store readiness. P7, M11/native
achievements, release signing, store setup and submission are outside this task.

## Physical Pixel delivery (2026-09-10)

PASS: **0.10.11 / version code 23** installed in place on Pixel 10 Pro XL
(`57261FDCQ00593`), package `org.nightshiftfm.spike`. All **six** prior mission,
probe and presentation JSON/backup files remained byte-identical before install,
after install and after launch. Package/version, successful launch, running process,
resumed activity and clean runtime log were verified. The phone was **locked**,
so visible P6 UI on the phone is **NOT VERIFIED**. Native screenshots are desktop
fixtures, not phone evidence.

APK SHA-256: `5acb21a1a3b36285fd1e956e20da87891de0de6c7b7abe0de29b67cdd37706d8`. APK and private backups remain ignored under
`builds/android/`; the sanitized manifest is `evidence/P6-goals/pixel-install.json`.
The installation used `adb -s 57261FDCQ00593 install -r` and explicit package
launch, with `run-as` file snapshots and SHA-256 comparisons on both sides.

PASS: a clean export of the staged source passed Godot import and all **6,084**
regressions, proving the committed sources include required files. P5 and P6 are
included together in the authorized consolidated commit accompanying the root
handoff. Use `git log -1` and `git status --short` for its exact identity/state.

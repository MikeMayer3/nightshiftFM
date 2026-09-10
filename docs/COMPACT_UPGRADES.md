# Compact Tuned upgrade choices — 0.10.13 / Android code 25

The upgrade picker previously placed an 88-unit info button inside its text
header and squeezed the connection preview beside a large icon. The resulting
cards and separate Help row required unnecessary scrolling.

The info button now sits beside the text with a 72-unit tap target. Equipment
art is 64 units, card padding and gaps are smaller, and the connection preview
uses the card's full width with an inline name and readiness hint. Help shares
one row with Reroll and Banish. Upgrade names, effects, rank changes and connection
readiness remain visible; the information view retains the full descriptions,
diagrams and tradeoffs. Text sizes and the previous scrolling fix are preserved.

Measured card heights in the desktop fixtures are **159–210 units**. Three choices
and the action row fit within the existing sheet without scrolling in all 18
normal/large-text cases, including actual Tuned-bar decisions, branch/new-instrument
choices and a stress fixture using the longest descriptions on the equipped gear.
Long-text fixtures test presentation only and do not claim those three cards form
a naturally generated offer.

## Checks

- PASS: 510 native rendered layout/input assertions at 360×640, 450×1000 and
  1024×768, each with normal and large text. Checks cover complete cards, all label
  lines, no horizontal/vertical overflow, info/Back and selecting the third card.
- PASS: 6,125 regressions, eight foundation checks, import, startup smoke and
  Android debug export; no engine/script errors.
- PASS: 22 Android emulator OS-input checks in normal/large text, including
  actual Tuned threshold, information/Back and accepting the third offered pick.
- PASS: physical Pixel updated in place to **0.10.13/code 25**; all six save/settings
  JSON and backup files byte-identical before/after install and launch. Visible menu
  and clean runtime logs verified. See `evidence/compact-upgrades/pixel-install.json`.
- Source is included in the 0.10.13 delivery commit. GitHub upload verification
  will be recorded in the handoff; no store submission is claimed.

## Reproduce

```sh
# Set GODOT_BIN to the pinned Godot 4.7.2 editor.
sh tools/godot.sh import
"$GODOT_BIN" --path . --script res://tests/visual_compact_upgrades.gd
sh tools/godot.sh test
sh tools/godot.sh smoke
python3 tools/check_foundation.py
python3 tools/build_scroll_qa.py --evidence docs/evidence/compact-upgrades
adb -s DEVICE install -r builds/android/nightshift-scroll-qa.apk
python3 tools/check_android_compact_upgrades.py --adb /path/to/adb --serial DEVICE --output docs/evidence/compact-upgrades/DEVICE_KIND
sh tools/godot.sh android-debug
```

The QA package is separate from the player's game and saves. Its actual Tuned
case advances a fresh campaign session until a real three-choice decision, then
uses OS taps to open details, return and accept the third offered upgrade.
Automated layout/input evidence does not replace human readability or extended
usability acceptance. The ordinary APK excludes the QA scripts and fixtures.

## Packaging correction

Inspection of the first export found pre-existing local backup JSON and imported
screenshots under `builds/` bundled into the APK. Both export presets now exclude
`builds/*` and `dist/*`, and a foundation regression protects all local-work
exclusions. The rebuilt APK was inspected as an archive: no build/test/doc/QA
paths or private screenshot imports remain. No private file contents were copied
into source or the evidence report. Earlier APKs have not been repackaged by this
change and should be replaced with a clean build before further sharing.

Download: ignored `builds/android/nightshift-fm-0.10.13-android-arm64-debug.apk`.
The version, size and SHA-256 are in `evidence/compact-upgrades/package.json`.

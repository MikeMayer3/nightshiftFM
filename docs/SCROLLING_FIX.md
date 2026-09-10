# Scrolling correction — Android 0.10.12 / code 24

The reported defect was that scrolling depended on where the initial press landed,
with text, artwork and empty areas failing to start a drag. The old screens relied
on child GUI events reaching the built-in ScrollContainer drag path. That did not
provide consistent native-touch and desktop mouse dragging across the whole page.

`PageScroll` now observes the actual GUI hit target on each scrolling page and owns
vertical mouse/native-touch gestures after a small movement threshold. It includes
card backgrounds, labels, artwork, progress meters, disabled controls, headers,
footers and outer margins. Centered draft, mixer and result sheets also accept a
swipe in the surrounding app area through an input backdrop behind the sheet.
Hidden sheets remove that backdrop from input routing.

Normal taps still reach native controls. Dragging cancels the pending button action
using Godot's scroll notification, including selector/info buttons. Mixer faders
and scrollbars retain their own drag interaction. One finger owns a page gesture;
emulated mouse motion cannot double the distance. Release supports bounded
momentum; cancellation, hiding, resizing and focus loss clear the gesture.
Pages whose content already fits remain stationary.

## Scope and source

- Shared input behavior: `scripts/ui/page_scroll.gd`.
- Attached to all six scrolling implementations: campaign, equipment, draft,
  patchboard/mixer, settings/help and combat result/pause sheets.
- Existing content/layout, combat rules, progression and save schemas are unchanged.
- Version: 0.10.12 / Android code 24. APK remains a development build.
- Test fixtures and phone automation are excluded from the ordinary APK. The phone
  fixture exports as the separate `org.nightshiftfm.scrollqa` package.

## Verification

| Check | Result |
| --- | --- |
| Pinned Godot import and startup smoke | PASS; no engine/script errors |
| Full regression suite | PASS: 6,125 checks, including 41 scrolling integration checks |
| Native desktop renderer and viewport input | PASS: 826 checks at 360×640 and 450×1000, with large text |
| Old drag path, shared handler removed | Expected FAIL: all 20 route-page drag probes fail; regression detects the missing fix |
| Python foundation checks | PASS: 7 checks |
| Android QA and normal APK exports | PASS; no engine/script errors |
| Physical Pixel OS input | PASS: 66 swipes across 19 screens plus 4 production control checks; zero final failures |
| Owner package update/save preservation | PASS: 0.10.12/code 24 installed and visibly launched; all six JSON/save/settings files byte-identical before install, after install and after launch; clean runtime logs |

The native sweep covers route, hardware, achievements, codex, records, modes,
enemies, logs, equipment/modules, settings/help, choices, choice details, report,
recruitment, recovery, patchboard, mixer faders/connections and results. Tests send
actual viewport input events; setting the initial offset only resets each probe.
The Android driver sends OS touchscreen swipes, reads the resulting scroll offset,
and separately taps production controls. It uses synthetic progress fixtures and
is not a human gameplay or extended usability session.

The initial phone fader assertion used an unpaused fixture, so the production
mixer correctly rejected the adjustment. The fixture was corrected to pause the
session, then all four control checks passed. The 66 already-passing swipe checks
were retained; the production `PageScroll` source was identical between QA builds.
The combined result records that control recheck explicitly.

Commands, from the project directory (`GODOT_BIN` points to Godot 4.7.2):

```sh
sh tools/godot.sh import
sh tools/godot.sh test
sh tools/godot.sh smoke
python3 tools/check_foundation.py
"$GODOT_BIN" --path . --script res://tests/visual_scrolling.gd
# Expected nonzero exit for the deliberately disabled handler:
"$GODOT_BIN" --path . --script res://tests/visual_scrolling.gd -- --scroll-baseline
python3 tools/build_scroll_qa.py
adb -s DEVICE install -r builds/android/nightshift-scroll-qa.apk
python3 tools/check_android_scrolling.py --adb /path/to/adb --serial DEVICE --output docs/evidence/scrolling/pixel
python3 tools/check_android_scrolling.py --adb /path/to/adb --serial DEVICE --output docs/evidence/scrolling/pixel --controls-only
sh tools/godot.sh android-debug
```

Relevant engine contracts: [GUI input propagation and scroll notifications](https://docs.godotengine.org/en/4.7/classes/class_control.html),
[ScrollContainer input and signals](https://docs.godotengine.org/en/4.7/classes/class_scrollcontainer.html).

## Delivery and Git state

The physical Pixel now runs 0.10.12/code 24. The temporary scrolling QA app was
removed after testing. Private backups and the launch screenshot remain under
ignored `builds/android/`. The normal APK is `builds/android/nightshift-m10.apk`;
SHA-256: `9917ed408e09f603f89dfe7faae69c4104054afe5d08d090322a510e90633bd6`.

This correction is local and uncommitted. The existing GitHub v0.10.11 release
has not been replaced by this work. No store submission was performed.

# Release playthrough audit — 2026-09-10

Audited 0.10.13 source at `d9fef05`, then applied the two navigation corrections
below. **This is not a 1.0 release approval.** The fixes and audit files are
included in v0.10.15. The audit evidence itself was collected on 0.10.13.
Physical checks used the separate `org.nightshiftfm.releaseaudit` QA package.

## Findings

| Priority | Finding | Outcome |
|---|---|---|
| P2 | Android Back did nothing in Mixer when opened from Pause. | **FIXED in 0.10.15.** Back now closes Mixer and leaves the run paused. |
| P2 | Android Back did nothing in the finished-run contribution report. | **FIXED in 0.10.15.** Back now returns to results. |
| P2 / release follow-up | Some shield-caption glyphs disappear in rapid Android results transitions. One initial upgrade capture also omitted the disabled Shield Boost control. | **OPEN.** Seen in two complete phone test sequences; slower isolated result reload/report navigation rendered correctly. No speculative renderer change applied. |

The Back bugs were reproduced through the production window Back signal before
editing: 2 failures in 28 navigation checks. After fixing `scripts/ui/boot.gd`, all
28 pass. Five assertions were added to the existing boot integration suite.
Both fixes also passed real Android Back-key tests on the physical Pixel twice.
Settings still returns to Pause, and opening Mixer directly from combat still
returns to combat.

The visual issue is distinct from text overflow: the diagnostic returned the
complete `Shield 48 / 65` string, a 340 × 76 label rectangle and a 147 × 32 minimum.
The desktop renderer shows it correctly. Compare
[affected results](evidence/release-audit/pixel-repeat/results.png) with
[clean slower replay](evidence/release-audit/pixel/result-after-report-repro.png).
The exact cause and duration are **not established**; do not claim this is an
engine defect, a save bug, or merely a screenshot artifact. Before release, record
rapid Continue → report → Back transitions on a release build and resolve or
conclusively exclude the transient missing HUD elements. The repeatable host
sequence is `tools/check_release_android.py`; the checked-in captures preserve the
finding even though state assertions pass.

## Coverage and results

| Check | Result and boundary |
|---|---|
| Rendered playthroughs | **PASS:** two actual ten-wave campaign missions, 130 assertions, 40 earned upgrades and decision restore checks; both victories. Static Net and Bass starts. Production scenes; accelerated simulation and visible-button signals, not physical taps. |
| Simulation matrix | **PASS:** 17 completed runs, 300 JSON checkpoint continuations; 13 victories and 4 defeats. All 12 Standard campaign missions, three Overload final-mission builds, a Contract and 20-wave Endless. No hangs or invalid final checkpoints. Uses completed-profile fixtures to access later content, not a sequential unlock playthrough. |
| Defeats | Standard mission 7 lost at wave 10; three Overload final-mission policies lost at waves 5–6. These are valid outcomes, not regression failures or evidence of an unwinnable mission. Human difficulty acceptance remains open. |
| Layout geometry | **PASS:** 3,916 visible-control checks across 120 captures at 320×568, 360×640, 450×1000 and 1024×768, normal and large text. No label-line clipping or horizontal overflow in this set. Scroll-page captures show their initial viewport, not every scrolled row. |
| Visual review | Reviewed all 120 page captures as contact sheets, plus full-size combat, upgrade, results and physical-device captures. No overlapping controls found in those views; phone HUD anomaly above remains open. Translucent modal sheets intentionally cover the battlefield. |
| Dense battlefield | **PASS:** 36 spacing assertions and six synthetic captures with five support instruments, 35 enemies and normal/reduced effects at three sizes. Tower/support art stays separated. Staged formations do not establish natural encounter density or full combat-effect coverage. |
| Physical Pixel interaction | **PASS:** 13 checks, repeated successfully. Actual menu → route → equipment → combat taps; Pause/Mixer/Settings/Back; earned Tuned choice; info; force-stop/Continue preserves offers; third-card tap; desktop-earned result restores; report/Back; Retry. No runtime errors in the checked final QA process. This is not a whole physical-device campaign playthrough. |
| Short phone timing sample | 554 post-warmup Godot frame-delta samples; median and p95 16.67 ms in the first run. Indicative early-wave telemetry only, not Android frame-deadline measurements, sustained performance, battery or thermal acceptance. |
| Regression / build checks | **PASS:** 6,130 regressions, eight Python foundation checks, import, startup smoke, isolated Android export. |
| APK static inspection | Existing 0.10.13 APK targets API 36, ARM64; only VIBRATE permission. No build/test/doc/QA resource paths. Both native libraries have 16 KB-aligned LOAD segments; `zipalign -c -P 16 -v 4` passes. APK remains debuggable. |
| 16 KB runtime | **NOT RUN:** physical phone uses 4,096-byte pages. Static library/ZIP alignment does not substitute for testing a 16 KB runtime or the final bundle. |
| Emulator | Initial QA-driver attempts were not accepted as game verification: screen-inset and label matching were corrected before the successful physical checks. |
| Human / store acceptance | **NOT RUN:** unfamiliar-player sessions, extended readability/listening/balance review, release-build device matrix, Play pre-launch report and store submission. |

Production saves/settings were not used as test data or modified. The result
checkpoint copied to the QA app was earned by the isolated desktop simulation.
The QA observer adds telemetry and disables audio; it does not accelerate combat,
pick upgrades, change damage, or unlock progress. The temporary QA APK is not a
player release artifact. Temporary QA packages were removed from both devices
after testing.

## Before submitting to Google Play

1. **Close the Android HUD visual finding** and package these Back-navigation fixes
   in the release candidate. Test rapid navigation, small phones, large text,
   background/foreground transitions and a complete mission with five instruments.
2. **Create and validate a production AAB.** Confirm the permanent application ID,
   release/upload signing and Play App Signing; turn off debug/practice behavior.
   The current APK is a development artifact, and debug runs do not establish
   production achievement eligibility. Google requires AABs for new Play apps.
   [Android release preparation](https://developer.android.com/studio/publish/preparing),
   [publishing format](https://developer.android.com/studio/publish/).
3. **Test the final bundle's platform compatibility.** API 36 is already present
   in the inspected APK and matches the requirement effective August 31, 2026;
   verify the actual release manifest. Check bundle alignment and run on a 16 KB
   Android device/emulator, plus an older/lower-end supported phone. Collect Play's
   pre-launch report and a sustained physical gameplay/thermal session.
   [Target API requirements](https://developer.android.com/google/play/requirements/target-sdk),
   [16 KB guidance](https://developer.android.com/guide/practices/page-sizes).
4. **Finish the listing and declarations.** Prepare representative screenshots,
   icon/feature graphic, descriptions, support contact, content rating, audience,
   ads declaration, privacy policy and Data safety answers that match the final
   app and SDKs. No privacy-policy entry is currently present in the settings
   screen. Offline behavior and the lack of INTERNET permission are evidence to
   use, not a substitute for reviewing the final declaration.
   [App review preparation](https://support.google.com/googleplay/android-developer/answer/9859455),
   [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469).
5. **Complete human and account-specific release testing.** Unfamiliar-player
   sessions and balance/readability approval remain open. If this is a personal
   Play developer account created after November 13, 2023, the current requirement
   is at least 12 closed-test participants opted in continuously for 14 days before
   applying for production access. Account eligibility was not inspected.
   [Google's testing requirement](https://support.google.com/googleplay/android-developer/answer/14151465).

These are launch gates, not authorization to publish, create signing identities,
change the player package, or implement optional P7/native online services.

## Reproduce

Set `GODOT_BIN` to the pinned Godot 4.7.2 editor, then run from the repository:

```sh
sh tools/godot.sh import
sh tools/godot.sh test
python3 tools/check_foundation.py
sh tools/godot.sh smoke
"$GODOT_BIN" --path . --script res://tests/release_playthrough.gd
"$GODOT_BIN" --path . --script res://tests/release_layout_audit.gd
"$GODOT_BIN" --path . --script res://tests/release_full_deck.gd
"$GODOT_BIN" --headless --path . --script res://tests/release_navigation_audit.gd
python3 tools/run_release_simulations.py
python3 tools/build_emulator_playtest.py --release-audit --output builds/android/nightshift-release-audit.apk
adb -s DEVICE install --no-incremental -r builds/android/nightshift-release-audit.apk
python3 tools/check_release_android.py --adb /path/to/adb --serial DEVICE --output docs/evidence/release-audit/DEVICE_KIND --result-save /path/to/isolated/release_audit_static_net.json
```

The final argument is the QA result written by `release_playthrough.gd` in Godot's
NightshiftFM user-data directory. Never substitute a player save. Evidence and
screenshots are under `docs/evidence/release-audit/` and remain excluded from APKs.

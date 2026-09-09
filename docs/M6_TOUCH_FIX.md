# M6 Burst touch correction — Android 0.6.1 / code 10

The owner reported that tapping and dragging did nothing, then clarified that the
gesture started on the Burst button. In 0.6.0 the button only fired at the automatic
target on a click; its “Aim and release” label implied an unsupported drag gesture.
Direct battlefield aiming depended entirely on Godot's touch-to-mouse bridge.

The button now supports tap for automatic targeting and drag into the battlefield
for aimed release. Returning off the battlefield cancels. The label is now
“Burst · Tap or drag”, with explicit pause-screen instructions. Native touch and
drag input tracks one finger; another finger or an emulated mouse event cannot
steal its gesture. Canceled touches, pause, and outside releases clear ownership.
Physical mouse and keyboard/button activation remain supported. Gameplay damage,
cooldown, content version `m6.1`, and save schemas are unchanged.

## Verification

All commands ran in `nightshift_fm_codex_pack`, with:

```sh
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
export JAVA_HOME='/Applications/Android Studio.app/Contents/jbr/Contents/Home'
export ANDROID_HOME=/Users/michaelmayer/Library/Android/sdk
sh tools/godot.sh import
sh tools/godot.sh test
python3 tools/check_foundation.py
sh tools/godot.sh smoke
python3 tools/build_emulator_playtest.py --touch --output builds/android/nightshift-touch-after.apk
"$ANDROID_HOME/platform-tools/adb" -s 57261FDCQ00593 install -r builds/android/nightshift-touch-after.apk
"$ANDROID_HOME/platform-tools/adb" -s 57261FDCQ00593 shell am start -n org.nightshiftfm.touchqa/com.godot.game.GodotAppLauncher
python3 tools/check_android_touch.py --adb "$ANDROID_HOME/platform-tools/adb" --serial 57261FDCQ00593 --output docs/evidence/M6-touch/pixel-button-after --from-button
# Restart the QA activity to reset its frozen formation before the next check.
"$ANDROID_HOME/platform-tools/adb" -s 57261FDCQ00593 shell am force-stop org.nightshiftfm.touchqa
"$ANDROID_HOME/platform-tools/adb" -s 57261FDCQ00593 shell am start -n org.nightshiftfm.touchqa/com.godot.game.GodotAppLauncher
python3 tools/check_android_touch.py --adb "$ANDROID_HOME/platform-tools/adb" --serial 57261FDCQ00593 --output docs/evidence/M6-touch/pixel-field-after
sh tools/godot.sh android-debug
"$ANDROID_HOME/build-tools/36.1.0/apksigner" verify builds/android/nightshift-m6.apk
"$ANDROID_HOME/platform-tools/adb" -s 57261FDCQ00593 install -r builds/android/nightshift-m6.apk
"$ANDROID_HOME/platform-tools/adb" -s 57261FDCQ00593 shell am start -n org.nightshiftfm.spike/com.godot.game.GodotAppLauncher
```

| Check | Result |
|---|---|
| Pinned import, full regression, foundation, smoke | PASS — Godot 4.7.2, 1,938 regression checks / 0 failures; seven foundation checks |
| Native regression before correction | Expected FAIL — native touch routing unsupported; 11 assertions failed in the first 1,934-check run |
| Original button drag on physical Pixel | Reproduced — DOWN (400,2200), MOVE/UP (459,670) on original runtime; no aim and zero Bursts; `pixel-button-before/` |
| Corrected button drag on physical Pixel | PASS — aiming ring follows selected formation, release kills all five fixture enemies in exactly one Burst and clears aim; `pixel-button-after/` |
| Corrected direct battlefield drag on Pixel | PASS — same four checks; `pixel-field-after/` |
| Native viewport regression | PASS — nonzero finger index, drag mapping, second finger, emulated mouse, cooldown, Android cancellation, outside release, pause, overlay interception, physical mouse, button-origin drag, return-to-button cancellation, automatic tap |
| Android export and signature | PASS — existing Java restricted-native-access warning only |
| In-place Pixel installation | PASS — `org.nightshiftfm.spike`, 0.6.1 / code 10; menu launched |
| Existing save preservation | PASS — validated primary JSON and backup before installation; both byte hashes identical after install and after menu launch; `pixel-install.json` |
| Human usability / full physical mission / iOS | NOT RUN for this correction |

The QA APK uses a separate package and a frozen combat formation. The observer
launches the wave and advances 2.4 seconds, then stops the screen's simulation
processing so ADB DOWN/MOVE/UP can be measured without racing moving enemies.
The ordinary runtime scripts/scenes/content are copied unchanged; manifests record
their hashes. Both final input scripts match the tested QA build exactly. The
regular APK additionally contains the revised button/help wording; QA screenshots
precede that text-only revision. QA is not a full-mission performance measurement.
The temporary QA package was removed after checking; the regular game remains.

An initial exploratory battlefield check (`pixel-before/`) used surface-relative
coordinates as screen coordinates. It observed mouse emulation working but aimed
161 pixels too high, so its failed drag assertion is **not evidence of the user's
bug**. The final host checker obtains the SurfaceView origin from Android's UI
hierarchy (`[0,161][1080,2287]` on this Pixel) before injecting events. The actual
button-origin reproduction above used verified physical screenshot coordinates.

Save reads used `adb shell run-as ... cat` and JSON validation; no success claim
relies solely on an `exec-out` exit code. A private temporary backup was retained
outside the repository. Only hashes, not the user's save contents, are in evidence.

API references: Godot 4.7 [InputEvent emulation ID](https://docs.godotengine.org/en/4.7/classes/class_inputevent.html#constants)
and [native touch properties](https://docs.godotengine.org/en/4.7/classes/class_inputeventscreentouch.html).

No commit, push, store publication, or later milestone was performed.

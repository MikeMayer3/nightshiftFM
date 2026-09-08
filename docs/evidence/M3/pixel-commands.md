# M3 physical-device interaction record

These commands were executed in this session, using the inspected UI coordinates.
All inputs were synthetic ADB touch on the physical Pixel, not an emulator or a
human playtest. Initial installation required the owner to unlock the phone.
No app-data clear, credential change, or logcat clear was used.

```sh
export ADB_BIN="/Users/michaelmayer/Library/Android/sdk/platform-tools/adb"
export DEVICE_ID="57261FDCQ00593"
"$ADB_BIN" -s "$DEVICE_ID" install -r builds/android/nightshift-m3.apk
"$ADB_BIN" -s "$DEVICE_ID" shell am start -n org.nightshiftfm.spike/com.godot.game.GodotAppLauncher
"$ADB_BIN" -s "$DEVICE_ID" shell input tap 540 1175 # New mission, after launch
"$ADB_BIN" -s "$DEVICE_ID" shell run-as org.nightshiftfm.spike cat files/m3_mission.json
"$ADB_BIN" -s "$DEVICE_ID" shell am force-stop org.nightshiftfm.spike
"$ADB_BIN" -s "$DEVICE_ID" shell am start -n org.nightshiftfm.spike/com.godot.game.GodotAppLauncher
"$ADB_BIN" -s "$DEVICE_ID" shell input tap 540 1325 # Continue after launch
"$ADB_BIN" -s "$DEVICE_ID" shell input tap 280 1010 # First saved card
"$ADB_BIN" -s "$DEVICE_ID" shell input tap 765 1010 # Banish shown common on next screen
"$ADB_BIN" -s "$DEVICE_ID" shell input swipe 500 1710 500 700 700
"$ADB_BIN" -s "$DEVICE_ID" shell input tap 540 1718 # Reroll, after successful scroll
# Repeated force-stop / launch / Continue; checked saved tokens and visible cards.
"$ADB_BIN" -s "$DEVICE_ID" shell input tap 540 1535 # Arc rank-3 branch
"$ADB_BIN" -s "$DEVICE_ID" shell input tap 540 1010 # Third normal selection
"$ADB_BIN" -s "$DEVICE_ID" shell input tap 540 970 # Decline recruitment
"$ADB_BIN" -s "$DEVICE_ID" shell input tap 540 1010 # Support bonus
# Polled the private save until wave=2, phase=COMBAT, then allowed 3 seconds of play.
# Repeated force-stop / launch / Continue and inspected fresh process start telemetry.
"$ADB_BIN" -s "$DEVICE_ID" shell pidof org.nightshiftfm.spike
"$ADB_BIN" -s "$DEVICE_ID" logcat -d --pid=ACTUAL_PID -v brief
"$ADB_BIN" -s "$DEVICE_ID" exec-out screencap -p > screenshot.png
```

Screenshots map a 720×1280 logical canvas to the device at 1.5× with y=264
canvas offset. Coordinates are this run's observations, not universal automation
selectors. See JSON snapshots for exact IDs, counts and RNG values.

An early swipe failed because card panels stopped touch propagation. Set card
panels, action rows and buttons to MOUSE_FILTER_PASS and labels to IGNORE;
re-exported, reinstalled, continued the same save, and verified a real swipe
reached the lower controls. The final screenshot `pixel-scrolled.png` shows the
successful scroll. Desktop wheel input had already worked and did not expose
this phone-specific defect.

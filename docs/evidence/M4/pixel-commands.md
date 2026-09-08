# Physical Pixel M4 commands

Device: Pixel 10 Pro XL, serial `57261FDCQ00593`, Android 16/API 36.
`adb` is `/Users/michaelmayer/Library/Android/sdk/platform-tools/adb`.
Commands below use that absolute binary with `-s 57261FDCQ00593`.

The disposable proof project path is in `proof-project.json`. It was copied
without `.git`, `.godot`, builds or Python caches, imported, and exported with
`sh tools/godot.sh android-debug`. Its only app-level differences are the test
package ID and app title. `proof-source-check.json` compares all final game
scripts, scenes and content against the regular build.

1. `install <proof-project>/builds/android/nightshift-m4.apk`
2. `shell am start -n org.nightshiftfm.m4proof20260908/com.godot.game.GodotAppLauncher`
3. `shell input tap 540 1178`: New mission. Let the actual first wave resolve.
4. `shell input tap 540 1500`: Arc tuning card. Read `files/m3_mission.json`
   through `shell run-as org.nightshiftfm.m4proof20260908 cat`.
5. `shell input tap 945 1405`: Arc rank-3 information button.
6. `shell input tap 540 1365`: Show Shield Tap instead in the original detailed
   candidate. Compare complete RNG and choice/token counts before and after.
7. `shell input tap 540 1500`: choose that Arc card. Then
   `shell input tap 540 700`: choose the third upgrade.
8. `shell input tap 540 626`: recruit Bass from the actual recruitment screen.
   Assert the saved equipment list contains `bass_driver` at rank 1.
9. `shell am force-stop org.nightshiftfm.m4proof20260908`. Pipe the valid
   desktop-generated `pixel-fixture.json` through
   `shell run-as org.nightshiftfm.m4proof20260908 tee files/m3_mission.json`.
   This touches only disposable test data. Launch again and tap Continue at
   `540 1325`. Observe wave 4 with Arc, Bass and Net in real rendering.
10. `shell input tap 940 354`: pause. Read the durable wave-start envelope and
    capture combat/paused screenshots with `exec-out screencap -p`.
11. Re-export/install the final proof candidate after shorter-details copy/UI
    changes. Force-stop/relaunch and Continue. Read Godot logs with
    `logcat -d --pid=<pidof proof-package> -s godot`. Assert the start event has
    wave 4, zero actors and exactly the saved elapsed time; assert the complete
    saved envelope is unchanged (`pixel-recovery-check.json`).
12. Read the regular app's save bytes, `install -r builds/android/nightshift-m4.apk`,
    then read the save again. Assert byte identity (`pixel-preservation-check.json`).
13. `uninstall org.nightshiftfm.m4proof20260908`: remove only the disposable app.
14. `shell am start -n org.nightshiftfm.spike/com.godot.game.GodotAppLauncher`:
    leave the regular M4 build at the menu. Capture `pixel-final-menu.png`.

These are injected device inputs and fixture-assisted recovery, not human
playtest sessions. No player choices, profile IDs or saves were reset.

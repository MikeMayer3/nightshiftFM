> Current playable export: **M4 support turrets, 0.4.3/code 7**, `builds/android/nightshift-m4.apk`.
> See [M4_ACTIVE_COMBAT.md](M4_ACTIVE_COMBAT.md) and [M4_PLAYTEST.md](M4_PLAYTEST.md) and the current
> [implementation status](IMPLEMENTATION_STATUS.md). M1/M2 commands and results
> below are historical platform setup/evidence; iOS remains deferred.

# Mobile export and lifecycle spike

M0 was accepted by the owner before this work. M1 adds only a diagnostic screen,
safe-area layout, a pausable counter, a tiny local checkpoint, mobile export
presets, and feasibility research. M2 subsequently adds the playable combat
prototype; see [M2_COMBAT.md](M2_COMBAT.md). iOS is deferred at owner request.

## Verified machine and device matrix

| Target | Observed configuration | Evidence |
|---|---|---|
| Development Mac | MacBook Pro Mac14,9, Apple M2 Pro, 16 GB; macOS 26.5.2 (25F84) | Local commands, desktop rendering |
| Godot | 4.7.2.stable.official.ed1daf0bf standard, Compatibility | Editor and matching 4.7.2.stable templates installed |
| Android toolchain | Android Studio 2026.1; bundled OpenJDK 25.0.3; SDK platform 36; export used Build Tools 36.0.0; adb 37.0.1 | Successful APK signing/export/install |
| Physical Android | Pixel 10 Pro XL, Android 16/API 36, 1080 × 2404 | Actual device, not emulator; touch, 20 OS cycles, force-stop recovery PASS |
| Apple toolchain | Xcode 26.6 (17F113), iPhoneOS SDK 26.5 | Local version commands; iOS export blocked by missing Team ID |
| Intended physical iPhone | iPhone 16, supplied by owner as available baseline; actual OS unknown | Not connected; install, touch, lifecycle, and human usability NOT RUN |
| Simulator/emulator | None used for M1 evidence | Existing unrelated simulators were left untouched |

The official [Android export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
recommends JDK 17 and permits higher versions. This spike deliberately uses the
already installed JDK 25.0.3 with the standard APK exporter; it builds successfully
but emits a Java native-access warning. Build Tools 35.0.1 were installed to match
the guide; Godot selected installed 36.0.0 for the actual build. The standard
template supplies min SDK 24 and target/compile SDK 36, verified from the APK.
No Gradle/native-source compilation is claimed; installed NDK 28.2.13676358 and
CMake 3.22.1 were not used. Recheck the plugin/Gradle requirements if taking that
path later. Pinning successful tools here is not a store-eligibility claim.

## Setup and Android reproduction

Install the **standard** export templates matching Godot 4.7.2 via its template
manager or the [official archive](https://godotengine.org/download/archive/4.7.2-stable/).
On this Mac they are in:

```text
~/Library/Application Support/Godot/export_templates/4.7.2.stable/
```

In Godot Editor Settings → Export → Android set Java SDK Path and Android SDK
Path to your actual installations. This machine uses the paths below. Turn off
Shutdown ADB on Exit so an exporter does not stop an adb server used by other
projects. These are machine settings, not committed credentials.

```sh
cd "/Users/michaelmayer/Projects/Nightshift FM/nightshift_fm_codex_pack"
export GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ADB_BIN="$ANDROID_HOME/platform-tools/adb"
sh tools/godot.sh import
sh tools/godot.sh test
sh tools/godot.sh android-debug
"$ADB_BIN" devices -l
# Set DEVICE_ID to the selected device from the previous command.
"$ADB_BIN" -s "$DEVICE_ID" install -r builds/android/nightshift-m2.apk
"$ADB_BIN" -s "$DEVICE_ID" shell am start -n org.nightshiftfm.spike/com.godot.game.GodotAppLauncher
```

For updates to this same debug package, use `install -r` to retain the checkpoint.
Do not uninstall/clear data to hide a signing mismatch. The actual exported
launcher is **GodotAppLauncher**; the internal GodotApp activity is not exported.
The private development package ID is `org.nightshiftfm.spike`. It is provisional,
not a registered store identity. The APK is ARM64-only and uses the local Godot
debug keystore. No release key, password, provisioning profile, or account secret
is in the repository. Tests, tools, docs, and prompts are excluded from the APK.
Its manifest requests **no Android permissions**, including no Internet permission.

## Probe and device checks

Open **Mobile checks** from the menu. The green border marks the safe part of the
fixed logical canvas; extra device space stays letterboxed. OS screen pixels are
converted through the actual viewport transform before applying margins. Desktop
and synthetic geometry checks do not certify a phone notch. On the tested Pixel,
the full logical canvas was already inside the safe display area.

`Tap and save` commits one tap; `Save checkpoint` records the current active time;
`Reload checkpoint` restores the last commit. The counter is an actual pausable
Node. The UI remains responsive while manually paused. Focus and background
notifications are tracked separately, duplicate notifications are idempotent,
and both conditions must clear before resuming. Regaining focus does not cancel
manual pause. Menus also suspend the counter. Notifications never instantiate
another probe scene.

The checkpoint is `user://m1_probe.json` (Android: private `files/m1_probe.json`).
Only schema version 1, integer taps, and finite nonnegative active seconds are
accepted. Writes use a flushed temporary file, validated previous-primary backup,
and rename. A damaged primary recovers from the valid backup. This is an M1
diagnostic, not the future mission/profile save system or arbitrary-frame resume.
Application pause saves a checkpoint, but force-stop can only restore the last
already committed state. Pause/resume counts describe the current process and
reset after a new process starts.

Unlock the phone, open the probe, and tap once. For the automated physical check:

```sh
ADB_BIN="$ANDROID_HOME/platform-tools/adb" python3 tools/android_probe_check.py \
  --serial "$DEVICE_ID" --cycles 20 --output builds/android/lifecycle.json
```

This sends the app to Home and back 20 times, compares the frozen counter across
each pair, checks one live probe, then force-stops/relaunches and compares the
saved checkpoint to the new process's ready report. It reads only this app's logs
and private debug checkpoint; it does not clear device logs/data. `status: PASS`
requires completing all cycles and recovery; interrupted reports remain RUNNING.
Log rotation is handled using monotonic app counters rather than log-line counts.
On-screen taps are tested separately; lifecycle automation is not a human
ergonomics assessment.

## iOS reproduction and current blocker

`iOS Xcode` is a project-only preset with a provisional bundle ID, iPhone target,
technical minimum iOS 17, and Game Center disabled. The owner selected iPhone 16
as the intended device baseline; this technical OS floor is not a promise that
older iPhones are supported. Apple signing and the final identity stay under
owner control.

Godot's [iOS export guide](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)
requires a real 10-character Apple Team ID. The
[4.7.2 exporter](https://github.com/godotengine/godot/blob/4.7.2-stable/editor/export/editor_export_platform_apple_embedded.cpp)
checks this even in project-only mode. The first export therefore failed with
`App Store Team ID not specified.` No fake Team ID was used and no Xcode project,
archive, signed IPA, or physical-iPhone launch is claimed.

Once the owner provides the Team ID, enter it in the preset's Application field
(a Team ID is an identifier, not a password), then run:

```sh
sh tools/godot.sh ios-project
```

The intended destination is `builds/ios/NightshiftM1.zip`; extract the exported
project there and open its `.xcodeproj`. Use Xcode's owner-controlled Signing &
Capabilities settings and select the connected iPhone 16. Record its actual OS
version. Repeat the same 20 background/foreground cycles and force-kill recovery,
inspect the safe-area border, and obtain human usability confirmation on the
phone. No signing override, account selection, or store submission is automated.

## Checks and remaining gates

```sh
sh -n tools/godot.sh
python3 tools/check_foundation.py
sh tools/godot.sh test
sh tools/godot.sh test --intentional-failure # Expected exit 1
sh tools/godot.sh smoke
sh tools/godot.sh test --quit-smoke
```

Latest evidence: 133 engine checks; seven Python checks; clean fresh-source
import; physical Pixel's 20 cycles and checkpoint recovery. See
`IMPLEMENTATION_STATUS.md` and `evidence/M1/`. Documentation is excluded from
Godot import with `.gdignore`; diagnostic screenshots are not game assets.

M1 remains open for the real iOS export/device tests, platform sandbox achievement
test prerequisites, and final human phone-usability gate. The candidate versions,
licenses, compatibility limits, and exact sandbox procedure are in
`NATIVE_ACHIEVEMENTS_SPIKE.md`. No native plugin is installed. Do not begin M2
automatically when finishing this spike.

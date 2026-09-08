# Implementation status

Status schema version: **1**  
Evidence revision: **M2.2**  
Date: **2026-09-07** (America/Chicago)  
Requested milestone: **M2 only, followed by authorized GitHub handoff**  
Outcome: **M2 implementation, automated checks, desktop rendering, and physical Pixel checks PASS. Human M2 playtest acceptance remains NOT RUN. iOS remains deferred; M3 has not started.**

M0 was accepted by the owner. M2 was explicitly authorized with “start 2” after
the owner deferred iOS. M2 depends on M0 and can proceed with recorded M1
platform/account gates. Historical M0/M1 evidence below retains its original
results; the current implementation and commands are described here.

## M2.2 — GitHub handoff

The owner explicitly requested Git initialization and upload as `nightshiftFM`.
Created the private repository [MikeMayer3/nightshiftFM](https://github.com/MikeMayer3/nightshiftFM)
and pushed `main` from this project root. `origin` is
`https://github.com/MikeMayer3/nightshiftFM.git`; `main` tracks `origin/main`.
Initial source commit: `712ef97c2e8a8f5e1bca3b6c4242ce0efa458c78`.

**PASS:** local initialization, initial commit, private repository creation,
initial push, and remote commit match. The 180-file initial source snapshot
contains about 2 MB of source/docs/evidence. `.godot/`, `builds/`, credentials,
and local device saves are excluded. Staged-file checks found no excluded-path
violations or private-key/GitHub-token/AWS-key patterns. README and development
instructions now describe cloning the actual repository.

**PASS:** a literal fresh clone from GitHub imported and ran on the pinned
Godot 4.7.2 standard engine: **268 engine checks, 0 failures**, desktop headless
smoke exit 0, and **7 Python checks**. Commands were:

```sh
git clone https://github.com/MikeMayer3/nightshiftFM.git /path/to/nightshiftFM
cd /path/to/nightshiftFM
export GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
sh tools/godot.sh import
sh tools/godot.sh test
sh tools/godot.sh smoke
python3 tools/check_foundation.py
```

The exact temporary clone path, source commit, commands, exit codes and logs are
in `docs/evidence/GITHUB/`. This revision adds handoff documentation and clone
evidence only; gameplay is unchanged from the tested source commit. M2's human
playtest remains **NOT RUN**, iOS remains deferred, and M3 has not started.

## M2.1 — three-wave combat prototype

### Scope and changed files

| Files | Implemented behavior |
|---|---|
| `scripts/combat/combat_session.gd`, `combat_actor.gd` | Renderer-independent fixed-step simulation, copied actor/run state, main pulse targeting, paths, bounded carrier abilities and destructible shots, shield-first damage and overflow, brace/recharge, waves, death/victory, once-only resolution and clean restart |
| `scripts/combat/combat_content.gd`, nine `content/**/*.tres` resources | One fixed main weapon, one shield, three enemy definitions, three authored waves, one test mission; no full catalog |
| `scripts/core/definitions/{weapon,shield,enemy,wave}_definition.gd` | Explicit instant-pulse behavior, shield timings, enemy path/stats/limits, wave interval; validation of implemented numeric and reference fields |
| `scenes/combat/combat.tscn`, `scripts/combat/{combat_arena,combat_screen}.gd` | Portrait safe-area HUD, fixed transmitter/arena, enemy silhouettes and legend, health bars, held/drag focus and release-to-auto, active shield, pause/lifecycle handling, results and menu/restart |
| `scripts/ui/boot.gd`, `assets/ui_strings.csv`, generated translation | Start opens combat; localized gameplay controls, feedback and result causes |
| `scripts/platform/mobile_probe.gd` | Hidden M1 diagnostics disable their clock and no longer own combat pause state; active M1 diagnostics retain their lifecycle handling |
| `project.godot`, `export_presets.cfg`, `assets/art/icon.svg` and import sidecar, `tools/godot.sh` | M2 app version 0.2.0/code 2, original transmitter icon, current Android APK filename; same private debug package and pinned engine |
| `tests/unit/test_combat.gd`, `tests/integration/test_combat_screen.gd`, `test_boot.gd`, `tests/test_runner.gd` | Combat edge cases, ten natural simulated wins, ten UI restart/result runs, death fixture, actual frame pause, twenty synthetic lifecycle cycles, hidden-probe regression; prior suites retained |
| `tests/visual_combat.gd`, `tools/android_combat_check.py`, `tools/check_foundation.py` | Reproducible desktop images, physical-device touch/lifecycle/run driver, bounded-content and wrapper checks |
| Generated `.gd.uid` sidecars, `README.md`, development/mobile guides, `docs/M2_COMBAT.md`, this file and `docs/evidence/M2/` | Current instructions, scope limits and check evidence |

The gun uses an instant pulse every 0.48 seconds for 8 damage. Swarmer, diver,
and carrier paths are distinct; the diver telegraphs before accelerating. The
carrier can emit at most three reinforcements and three shots. Reinforcements
enter through the top band; projectiles originate at the carrier. The ordinary
gun can destroy those projectiles. Damage resolves through shield before hull,
and the active brace reduces incoming damage by 75% for 2.5 seconds with a
12-second cooldown. There are no reflection, secondary-proc, status/DOT, upgrade,
reward, or progression systems in M2.

The 640 × 720 combat rectangle is scaled uniformly within the existing 720 ×
1280 portrait safe-area UI. All enemies breach across its full-width bottom line.
Kill resolution precedes same-step movement/breach; resolved actors cannot apply
another kill/breach. Mission completion clears actors; restart resets timers,
health, shield, ranks, focus, and temporary state without modifying definitions.

### Commands and results

Run from `nightshift_fm_codex_pack/` with
`GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`. Engine remains
**4.7.2.stable.official.ed1daf0bf**, standard, Compatibility; matching templates
remain **4.7.2.stable**. Android uses the previously documented JDK 25.0.3 and
Build Tools 36.0.0. Exact fresh-source command arrays, working directories,
expected/actual exits and results are in `docs/evidence/M2/fresh-checks.json`.

| Check / exact command | Result | Evidence |
|---|---|---|
| `sh tools/godot.sh import` on a fresh source copy without `.godot/` or builds | **PASS** | Exit 0; no script/import errors; `check-00.txt` |
| `sh tools/godot.sh test` | **PASS** | **268 checks, 0 failures**, exit 0; `check-01.txt` |
| `sh tools/godot.sh test --intentional-failure` | **PASS** | 269 checks, exactly 1 deliberate failure, exit 1 as required; `check-02.txt` |
| `sh tools/godot.sh smoke` | **PASS** | Exit 0, no runtime errors; `check-03.txt` |
| `sh tools/godot.sh test --quit-smoke` | **PASS** | Actual menu Quit signal exits 0; `check-04.txt` |
| `sh -n tools/godot.sh` | **PASS** | Exit 0; `check-05.txt` |
| `python3 tools/check_foundation.py` | **PASS** | 7 tests; `check-06.txt` |
| `"$GODOT_BIN" --path . --script res://tests/visual_combat.gd` | **PASS** | macOS OpenGL/Metal Compatibility rendering; combat/pause/results PNGs visually inspected; `desktop-visual.txt` |
| `sh tools/godot.sh android-debug` | **PASS** | Signed ARM64 debug APK, export exit 0; `android-export.txt`; Java warning described below |
| `"$ADB_BIN" -s "$DEVICE_ID" install -r builds/android/nightshift-m2.apk` | **PASS** | Installed updated app on physical Pixel 10 Pro XL, Android 16/API 36 |
| `"$ADB_BIN" -s "$DEVICE_ID" shell am start -n org.nightshiftfm.spike/com.godot.game.GodotAppLauncher` | **PASS** | Real portrait menu/mission launches |
| `python3 tools/android_combat_check.py --adb "$ADB_BIN" --serial "$DEVICE_ID" --canvas-top 264 --canvas-scale 1.5 --output docs/evidence/M2` | **PASS** | 30 physical-device assertions: Start, pause, 20 Home/resume cycles, active OS pause/resume, hold/drag/release, brace, results, restart and second full run; `pixel-combat-check.json`, events JSON, log and PNGs |
| Build Tools 36.0.0 `aapt dump permissions` / `aapt dump badging` on APK | **PASS** | No requested permissions (including Internet); version 0.2.0/code 2, min SDK 24, target SDK 36; evidence text files |
| Human phone playtest and M2 acceptance | **NOT RUN** | Owner must assess responsiveness, readable danger, viable auto-aim and understandable endings |
| Physical iPhone / iOS export rerun | **NOT RUN** | Deferred at owner request; historical M1 missing-Team-ID failure remains below |
| Native achievement sandbox | **NOT RUN** | Existing M1 account/plugin gates remain; no native integration added |

Fresh verification copied source to
`/var/folders/cy/lx2m7tpd07vb9z_vxtj0ckxw0000gn/T/nightshift-m2-fresh-u58oj5ct/project`.
At the time of M2.1 verification, no Git metadata existed; that check was a
fresh-source copy/import. M2.2 above adds actual GitHub and clone evidence.

The ten renderer-independent auto-aim runs and ten scene-driven complete runs
all reached victory without duplicate result subscriptions or stale actors.
The unopposed-enemy fixture reached defeat; its result retained the damage cause.
The two actual Pixel runs both finished three waves in **52.0167 active seconds,
63.6 hull**, with one combat instance and no actors left on results. These phone
inputs were injected through ADB; they are physical-device checks, not human
usability approval. The desktop script also drives state for screenshot capture;
it is not a recorded manual playthrough.

Final APK: `builds/android/nightshift-m2.apk`  
SHA-256: `1725916e702de80203a7779a93c4a7de73c108564aa2952bb65494f1c32a6735`.

### Findings, corrections and limitations

- The first export emitted an error about an unspecified project icon despite
  producing an APK. Added the original vector transmitter icon and repeated the
  export; the final log has no export errors.
- The initial tuning let auto-aim finish untouched. A denser final wave and a
  0.48-second pulse interval produced readable breaches while preserving an
  automated win. This is a fixture tuning observation, not a human fun gate.
- Review found that the hidden M1 probe could advance its clock or write global
  pause state while combat was active. Disabled its hidden clock and restricted
  pause ownership to its enabled page; two new regressions pass. Repeated the
  fresh-source checks and physical suite after that fix.
- Android signing still reports JDK 25 native-access warnings from `apksigner`;
  export/install succeed. ADB's “Activity not started … task … brought to the
  front” warnings during resume are expected foregrounding of the live process.
- Combat has no mission persistence in M2. Backgrounding the living process
  freezes/resumes it; process death returns to the menu and loses that mission.
  The pause UI explains this. Checkpoints and upgrade/reward transactions are M3.
- No claim of final art/audio, difficulty balance, thermal/performance soak,
  store eligibility, release signing, iOS acceptance, or native achievements.

**Stopped at M2.** The next action is the owner's Pixel playtest using
`docs/M2_COMBAT.md`; M3 has not started. The one-main/one-shield and five-supports-
from-six limits remain intact, core play remains offline, and permanent power
progression, backend services, monetization and a full catalog were not added.

## Historical M1.2 — iOS deferral and M2 readiness

The owner requested “skip ios for now” and asked what is needed to move to M2.
iOS export/signing and physical iPhone validation are deferred, not passed. The
previous missing-Team-ID export failure remains recorded below. Native sandbox
achievement checks remain NOT RUN pending configuration and account access.

M2 depends on M0, which is satisfied. `docs/MILESTONES.md` explicitly permits
core work while M1 device/account blockers are recorded, so no additional setup
is required to begin M2 on the current Mac and Pixel. Outstanding M1 platform
and usability gates remain required before claiming full M1/release acceptance.
M2 has not started; this revision changes only this status document. No runtime
checks were rerun for this documentation-only update; the M1.1 evidence is retained.

## Historical M1.1 — mobile spike evidence

The owner explicitly authorized M1 after confirming the M0 portrait preview
looked good. The owner identified a Pixel and an accessible iPhone 16. The
connected Android device reports Pixel 10 Pro XL, Android 16/API 36. No physical
iPhone is connected; its OS is unknown. The named hardware/toolchain matrix and
reproducible setup commands are in `docs/MOBILE_DEVELOPMENT.md`.

### Implemented and changed files

| Files | M1 change |
|---|---|
| `project.godot`, `scenes/boot/boot.tscn`, `scripts/ui/boot.gd` | M1 app version/title, stable diagnostic user-data directory, touch-to-mouse UI activation, mobile texture import, separate Mobile checks navigation; main canvas stays 720 × 1280 with fixed aspect |
| `scenes/ui/mobile_probe.tscn`, `scripts/platform/mobile_probe.gd`, `scripts/platform/probe_clock.gd` | Isolated touch/save/load and pause/resume diagnostics; actual pausable Node; explicit OS focus/background handling; instance/drift telemetry |
| `scripts/platform/probe_store.gd` | Versioned numeric-only diagnostic checkpoint, temporary write/flush, validated backup rotation/recovery, honest errors |
| `scripts/platform/safe_area.gd`, `scripts/ui/safe_margin.gd` | OS safe-area pixels transformed into fixed-canvas coordinates; margins and diagnostic border |
| `assets/ui_strings.csv`, generated translation | Localized M1 labels/instructions |
| `export_presets.cfg`, `tools/godot.sh` | ARM64 Android debug and iOS project-only presets; wrapper export commands; no release credentials |
| `tests/integration/test_mobile_probe.gd`, `tests/test_runner.gd` | 20 synthetic cycles, actual pause processing, duplicate notifications, manual-pause preservation, schema/backup/error cases, state restoration and safe geometry |
| `tools/android_probe_check.py`, `tools/check_foundation.py` | Physical-device cycle/force-stop driver; log-rotation regression; mobile localization/preset checks |
| New `.gd.uid` sidecars | Generated by pinned editor, retained with source |
| `docs/.gdignore`, `docs/evidence/M0.2/desktop-menu.jpg` | Exclude documentation from game import; correct old screenshot extension to its actual JPEG format |
| `README.md`, `docs/DEVELOPMENT.md`, `docs/MOBILE_DEVELOPMENT.md`, `docs/NATIVE_ACHIEVEMENTS_SPIKE.md`, this file, `docs/evidence/M1/` | Current status, toolchain/device matrix, reproduction, compatibility research, evidence |

Installed matching **4.7.2.stable standard export templates** into the normal
Godot user directory. Added Android Build Tools 35.0.1. The actual successful
export selected existing Build Tools 36.0.0 with Android Studio's JDK 25.0.3;
this deliberate choice and warning are documented. Set local editor Java path
and disabled exporter shutdown of adb. No repository credentials were added.

### Commands and results

All Godot wrapper commands use
`GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`.
Android commands use `ADB_BIN=$HOME/Library/Android/sdk/platform-tools/adb`;
`DEVICE_ID` is the selected physical Pixel from `adb devices -l`.

| Check / command | Result | Evidence |
|---|---|---|
| Fresh source copy excluding `.godot/`, `builds/`, `.DS_Store`, `__pycache__`; `sh tools/godot.sh import` | **PASS** | Exit 0, no errors/warnings; `evidence/M1/check-00.txt` |
| `sh tools/godot.sh test` | **PASS** | **133 checks, 0 failures**; includes M0 checks, useful invalid-content errors, and 20 synthetic lifecycle cycles; `check-01.txt` |
| `sh tools/godot.sh test --intentional-failure` | **PASS** | Expected exit **1**, 134 checks and exactly 1 intentional failure; `check-02.txt` |
| `sh tools/godot.sh smoke` | **PASS** | Exit 0; `check-03.txt` |
| `sh tools/godot.sh test --quit-smoke` | **PASS** | Quit exits 0; `check-04.txt` |
| `sh -n tools/godot.sh` | **PASS** | Exit 0; `check-05.txt` |
| `python3 tools/check_foundation.py` | **PASS** | **Seven checks**, exit 0; `check-06.txt` |
| `sh tools/godot.sh android-debug` | **PASS** | Signed APK and verification completed, exit 0; Java native-access warning recorded below |
| `aapt dump badging builds/android/nightshift-m1.apk` and `aapt dump permissions ...` | **PASS** | ARM64; min SDK 24, target/compile SDK 36; no Android permissions requested |
| APK ZIP inventory | **PASS** | No `assets/docs`, `assets/tests`, `assets/tools`, or `assets/prompts` entries |
| `"$ADB_BIN" -s "$DEVICE_ID" install builds/android/nightshift-m1.apk` | **PASS** | Physical device installation reports Success |
| `"$ADB_BIN" -s "$DEVICE_ID" shell am start -n org.nightshiftfm.spike/com.godot.game.GodotAppLauncher` | **PASS** | Actual exported launcher opens the menu; screenshots retained |
| Pixel touch/safe-area check | **PASS** | Device input opened Mobile checks; one tap changed saved counter 9 → 10; controls fit within safe border above system navigation |
| `python3 tools/android_probe_check.py --serial "$DEVICE_ID" --cycles 20 --output docs/evidence/M1/pixel-lifecycle.json` | **PASS** | 20 real Home/foreground cycles; identical active_seconds across every pause/resume, drift=0, instances=1; report status PASS |
| Force-stop/relaunch in that driver | **PASS** | New process restored **10 taps and 126.485294151515 active seconds**, exactly matching the committed checkpoint |
| `sh tools/godot.sh run` and computer-use inspection | **PASS** | Desktop M1 menu and diagnostics rendered; agent opened diagnostics and inspected controls/border |
| `sh tools/godot.sh ios-project` | **FAIL — blocked** | Exporter rejects missing Apple Team ID. No Xcode project or IPA was produced; `ios-export-blocked.txt` |
| Physical iPhone 16 install, safe-area, 20 cycles, force-kill | **NOT RUN** | Phone not connected; OS and signing/provisioning not verified |
| Native sandbox achievement unlock | **NOT RUN** | Game-specific Apple/Play Games configuration, IDs, tester access, and exact plugin compatibility build unavailable; candidate research completed |
| Final human phone-usability acceptance | **NOT RUN** | Agent device interaction is evidence, not owner ergonomics approval; iPhone has not been tested |

Latest fresh copy:
`/var/folders/cy/lx2m7tpd07vb9z_vxtj0ckxw0000gn/T/nightshift-m1-fresh-3sw13qiq/project`.
APK: `builds/android/nightshift-m1.apk` (about 27 MB), SHA-256:
`213c8bd1762458b237ed88923be6a633b5549690c4b0d46236c9c878d10a8147`.
Build outputs are ignored; no Git repository, commit, remote, or push is claimed.

### Failures found, fixes, and warnings

- **Fixed:** the M0 evidence screenshot was actually JPEG bytes named `.png`.
  The first M1 import attempted to import it and reported PNG errors. Renamed
  it correctly and added `docs/.gdignore`. The final fresh import is clean.
- **Fixed:** the first Android export rejected min/target SDK overrides outside
  Gradle and required ETC2/ASTC import. Removed those overrides, enabled mobile
  texture import, and successfully rebuilt using standard-template SDK values.
- **Fixed command:** launching the internal GodotApp activity was denied by
  Android. Resolved the actual exported GodotAppLauncher and used it; no security
  restriction was bypassed.
- **Fixed test-driver bug:** the first physical-cycle run timed out after 17
  completed cycles because log rotation invalidated historical line counts.
  Switched to monotonic app counters, added a regression test, and passed a
  fresh full 20-cycle run plus force-stop recovery.
- Template download was interrupted; HTTP/1.1 resumed the remaining bytes.
  ZIP extraction/CRC checks and the `4.7.2.stable` version file succeeded before
  installation. No partial archive was installed.
- Android SDK CLI printed its deprecation notice; installation succeeded.
  JDK 25's apksigner emitted a native-access warning; signing and APK verification
  succeeded. The initial exporter also stopped adb on exit; the local shutdown
  setting was disabled for subsequent work. These are not device gameplay failures.

### Remaining M1 gates

1. **Deferred at owner request:** owner supplies the real Apple Team ID, connects iPhone 16, and completes
   owner-controlled Xcode signing/provisioning. Export and repeat physical tests.
2. Obtain game-specific sandbox achievement configuration and test-account access;
   compile/test a selected candidate with exact Godot 4.7.2 before claiming native
   compatibility. No native plugin or purchase functionality was installed here.
3. Owner confirms phone text/touch usability on the tested devices.

Core diagnostics run offline, and immutable content/runtime separation and the
one-main/one-shield/five-of-six-support contracts are unchanged. The checkpoint
is only an M1 probe, not mission saving or permanent progression. No combat,
full catalog, backend, monetization, or M2 work was added. **Stopped at M1 with
the above gates open; M1 is not fully accepted.**

## Historical M0.2 — authorized installation and verification

The owner asked to install Godot. Downloaded the standard macOS Universal ZIP
from the official 4.7.2 archive link and installed `/Applications/Godot.app`
without replacing any existing application. Full version:
**4.7.2.stable.official.ed1daf0bf**. `codesign --verify --deep --strict --verbose=2`
passed, and `spctl --assess --type execute --verbose=2` returned `accepted`,
`source=Notarized Developer ID`. No security settings were changed.
Download retained in `~/Downloads/Godot-4.7.2-setup/`.
Export templates remain **NOT RUN / uninstalled**, outside M0.

The first real import exited 0 but printed missing translation errors; that
initial import was **FAIL** for the clean-import criterion. Godot generated
`assets/ui_strings.en.translation`, its CSV `.import` sidecar, and `.gd.uid`
sidecars. These are now part of the source files to retain in a future commit.
The static reference check now requires the generated translation to exist.
No gameplay code change was needed. README and development instructions were
updated to reflect installation and the first-import fix.

All wrapper commands used:

```sh
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
sh tools/godot.sh version
sh tools/godot.sh import
sh tools/godot.sh test
sh tools/godot.sh test --intentional-failure
sh tools/godot.sh smoke
sh tools/godot.sh test --quit-smoke
sh tools/godot.sh run
```

| Latest check | Result | Evidence |
|---|---|---|
| Engine version | **PASS** | Exact pinned standard official build above |
| Fresh-source import | **PASS** | Copied project excluding `.godot/`, `.DS_Store`, and `__pycache__` into a new temp folder; `sh tools/godot.sh import` exited 0 with no errors/warnings |
| Headless tests, original and fresh copy | **PASS** | Both exit 0; **45 checks, 0 failures**, including useful invalid-fixture errors |
| Intentional failure | **PASS** | Exit **1**; 46 checks, 1 intentional failure, expected failure message |
| Headless main-scene smoke | **PASS** | Exit 0, no errors/warnings |
| Isolated Quit signal smoke | **PASS** | Quit signal terminates process with exit 0 |
| Desktop rendering/navigation | **PASS** | Agent inspected screenshots and clicked Start/Back/Settings/toggle; exercised Escape, Tab/Enter, retained setting, wider/taller resizing and letterboxing |
| Desktop Quit/relaunch | **PASS** | Actual Quit click terminated desktop process with exit 0; preview relaunched successfully and left open |
| Shell/Python regressions | **PASS** | `sh -n tools/godot.sh`; `python3 tools/check_foundation.py`: six tests, exit 0 |
| Owner/human approval | **NOT RUN** | Agent interaction does not substitute for the owner's visual acceptance |
| Literal fresh Git clone | **NOT RUN** | Workspace still has no Git repository; clean source-copy import/test was performed |
| Mobile/export/device work | **NOT RUN** | No M1 work performed |

Fresh-copy evidence logs are retained in
`docs/evidence/M0.2/fresh-import.txt` and `fresh-test.txt`.
The temp copy was `/var/folders/cy/lx2m7tpd07vb9z_vxtj0ckxw0000gn/T/nightshift-m0-fresh-j87oteve/project`.
Desktop renderer reported OpenGL 4.1 Metal, Compatibility, Apple M2 Pro.
No engine error or warning appeared in the final test/smoke/desktop runs.
The remaining M0 action is owner inspection of the open preview. M1 remains
unstarted. The sections below describe the original implementation and checks.

## Historical M0.1 evidence

## Inspected baseline and toolchain

Read `AGENTS.md`, all of `docs/GAME_DESIGN.md`, and M0 in `docs/MILESTONES.md`
before writing source. Also inspected README, the start prompt, references, and
the folder inventory. The supplied handoff lives in `nightshift_fm_codex_pack/`,
which is now the project root. Its enclosing plan/ZIP and existing design,
catalog, milestones, references, instructions, and prompts were preserved.

- Host observed: `Darwin 25.5.0 arm64`; Python `3.9.6`.
- `git status --short --branch`: exit 128, no Git repository in the workspace or
  parents. There is no branch, commit, remote, or push result to report.
- `command -v godot` and `command -v godot4`: no executable found.
- Inspected `/Applications`, Downloads, and the Godot application-support path:
  no installed editor found; Godot application-support directory absent.
- `GODOT_BIN` is unset. Actual engine version/build hash and installed export
  template version: **unavailable**.
- Deliberate decision: retain required Godot **4.7.2 stable official standard**
  and matching **4.7.2.stable standard templates**. No fallback, installation,
  engine upgrade, or export setup was performed. Pins are in `tools/`.
- Official archive/API references were checked; see `docs/DEVELOPMENT.md`.

## Implemented M0 scope and changed files

| Files | Scope |
|---|---|
| `project.godot`, `.gitignore` | Standard typed GDScript foundation, Compatibility renderer, 720 × 1280 logical portrait canvas, 450 × 800 desktop window, fixed aspect, named input actions, cache/credential exclusions |
| `scenes/boot/boot.tscn` | Title/menu, honest Start placeholder, Settings, Back, Quit |
| `scripts/ui/boot.gd`, `scripts/ui/transmitter_art.gd`, `assets/ui_strings.csv` | Typed navigation, keyboard Back, session-only decorative signal toggle, original geometric transmitter, localization keys/English text |
| `scripts/core/game_rules.gd` | One main and one shield slot, five-support limit, six family identities, baseline/max rank, content version |
| `scripts/core/definitions/content_definition.gd` | Stable IDs, localization metadata, schema version, basic validation |
| `scripts/core/definitions/{weapon,upgrade,shield,enemy,wave,mission,module,synergy,achievement}_definition.gd` | Nine typed definition skeletons; no full behavior/effect catalog |
| `scripts/core/content_validator.gd` | Useful ID/path/field errors for null definitions, bad identity/metadata, duplicate IDs, basic invalid numeric values, missing references |
| `scripts/core/state/{weapon,shield,run,profile}_state.gd` | Separate runtime data; copied equipment baselines and ID snapshots; per-instance run/profile arrays; permanent options/cosmetics without permanent combat-stat fields |
| `tests/test_runner.gd`, `tests/test_context.gd` | Explicit result counters, suite completion checks, 15-second runtime watchdog, exit codes, intentional failure, isolated Quit smoke mode |
| `tests/unit/test_foundations.gd`, `tests/integration/test_boot.gd` | Definition fixtures, state isolation, constraints, input declarations, translations, page/button-signal navigation, settings and Back checks |
| `tests/fixtures/{valid_weapon,valid_shield,invalid_weapon,missing_reference}.tres` | Four synthetic fixtures only; no playable content |
| `tools/godot.sh`, `tools/engine-version.txt`, `tools/export-template-version.txt` | Portable GODOT_BIN wrapper, strict version-family check, import/test/smoke/run/editor entry points |
| `tools/check_foundation.py` | Engine-independent source/reference/localization and shell-wrapper regression checks using Python standard library |
| `docs/DEVELOPMENT.md`, this file, `README.md` | Exact setup/run/check instructions, limitations, versioned evidence, updated README entry point |
| `.gitkeep` files under scenes, scripts, content, assets | Intended empty folders retained for future milestones |

No production `.tres` content was added under `content/`. No combat, save system,
mission reset orchestration, recruitment, permanent progression system, backend,
monetization, native integration, mobile export, or lifecycle probe is implemented.

## Executed checks and evidence

Commands below were run from the project root. PASS means only the scope described
in that row. NOT RUN means the intended engine check did not execute.

| Check / exact command | Result | Evidence |
|---|---|---|
| `sh -n tools/godot.sh` | **PASS** | Exit 0; POSIX shell syntax check |
| `python3 tools/check_foundation.py` | **PASS** | Exit 0; six tests, `OK`, Python 3.9.6 |
| Source/reference checks within that Python command | **PASS** | Referenced files exist; the only generated translation reference maps to the source CSV; every scene text key has English text; no populated catalog or export preset |
| Wrapper regression checks within that Python command | **PASS** | Fake executable verifies all five forwarding modes from a different CWD, spaces in paths, missing-engine exit 127, mismatch/.NET/RC exit 2, and propagation of exit 9 including test arguments. This is not Godot execution |
| `sh tools/godot.sh version` | **NOT RUN** | Wrapper exit 127: `NOT RUN: set GODOT_BIN to the Godot 4.7.2 standard editor executable.` |
| `sh tools/godot.sh import` | **NOT RUN** | Same exit 127; no GDScript compilation or resource import took place |
| `sh tools/godot.sh test` | **NOT RUN** | Same exit 127; real unit/integration fixtures and positive exit contract unverified |
| `sh tools/godot.sh test --intentional-failure` | **NOT RUN** | Same exit 127; this is not the required intentional test exit 1 |
| `sh tools/godot.sh smoke` | **NOT RUN** | Same exit 127; main-scene headless launch unverified |
| `sh tools/godot.sh test --quit-smoke` | **NOT RUN** | Same exit 127; Quit process termination unverified |
| `sh tools/godot.sh run` | **NOT RUN** | Same exit 127; no portrait window rendered or desktop input exercised |

Source review found no runtime network dependency, credentials, commercial asset,
or plugin. A targeted scan also returned no matches (rg exit 1):

```sh
rg -n 'HTTPRequest|HTTPClient|WebSocket|Multiplayer|OS.execute|BEGIN .*PRIVATE KEY|AKIA[0-9A-Z]{16}' scripts scenes assets tests tools project.godot
```

That scan is supporting source evidence, not a comprehensive secret audit.
No executed check reported FAIL. Engine-dependent outcomes remain unknown.

## Acceptance and limitations

| M0 acceptance condition | Status |
|---|---|
| Fresh clone/import opens with no missing resources | **NOT RUN** — no Git repository or engine; static path check passed but cannot establish import correctness |
| Portrait title, Start/settings/Back flow and Quit work | **NOT RUN** — source and automated tests exist; no rendered or clicked desktop evidence |
| Headless suite exits 0; intentional failure exits nonzero | **NOT RUN** — wrapper behavior passed independently; real runner unavailable |
| Invalid content fixtures produce useful errors | **NOT RUN** — fixtures and assertions implemented, not executed in Godot |
| No credentials, commercial assets, hidden backend dependency | **PASS** — bounded source/dependency review; original geometry and engine UI font only |
| Human desktop portrait inspection | **NOT RUN** — requires the pinned editor and the documented click/resize checklist |
| Device checks | **NOT RUN** — outside M0; no emulator, simulator, or physical-device evidence claimed |

Resources are read-only by ownership convention, not forcibly frozen by Godot.
Runtime code never writes loaded definitions; isolation tests await execution.
The validator covers the M0 schema only. Complete typed effects, compatibility,
branch reachability, unlock cycles, and achievement reference validation belong
with their future systems. Slot limits are declared contracts; no M0 equip API
claims to enforce recruitment. Run/profile data shapes do not claim working saves
or tested mission resets. UI layout, compiler warnings, and engine errors remain
unknown until import and desktop execution. No FPS, mobile safe-area, playtesting,
signing, store, or release acceptance is claimed.

## Remaining M0 acceptance action

Install the pinned standard editor, set `GODOT_BIN`, and follow
`docs/DEVELOPMENT.md`: capture full version output, import fresh source, run the
normal and intentional-failure suites, headless main-scene and Quit checks, then
the desktop navigation/resize/quit checklist. Record exact output, warnings, and
human observations in the next evidence revision. Stop at M0 until this evidence
is recorded; do not begin M1 as part of this change.

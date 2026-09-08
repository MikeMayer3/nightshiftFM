# Development and reproduction

M0 is accepted. These foundation instructions still apply; see
[M4_ACTIVE_COMBAT.md](M4_ACTIVE_COMBAT.md) for the current playable mission and
[MOBILE_DEVELOPMENT.md](MOBILE_DEVELOPMENT.md) for export setup and M1 probes.

The project root is `nightshift_fm_codex_pack/`, beside its existing `AGENTS.md`.
The enclosing folder contained the source plan and ZIP; those are preserved.
No Git metadata existed at initial inspection. The owner subsequently authorized
Git initialization and upload as `MikeMayer3/nightshiftFM`. The repository root
is this project directory, not the enclosing plan/ZIP folder. Keep hidden
`.gitkeep` files. On another computer, clone the repository and use its root
in place of the example Mac path below.

## Toolchain decision

Keep **Godot 4.7.2 stable official, standard/GDScript**, Compatibility renderer.
The official [4.7.2 archive](https://godotengine.org/download/archive/4.7.2-stable/)
was checked during M0. Download the standard editor for your OS; do not use .NET.
After the initial M0 implementation, the owner authorized installation. Godot is
now installed at `/Applications/Godot.app/Contents/MacOS/Godot` and reports
**4.7.2.stable.official.ed1daf0bf**. Its signature passed `codesign --verify` and
macOS accepted it as a notarized Developer ID application. No substitute engine
version was selected. Matching templates were subsequently installed for M1.

`tools/engine-version.txt` pins `4.7.2.stable.official`. The wrapper accepts that
prefix plus the build hash printed by `--version`, rejects .NET/RC/other versions,
and prints the complete installed version with `version`. Record its complete
output in implementation status when the engine becomes available. The matching
standard export-template pin is `4.7.2.stable` in
`tools/export-template-version.txt`; templates are unnecessary for desktop editor
import/run and are now installed for M1. The mobile guide covers exports.

## Import and launch

Run from the project root. A path containing spaces must remain quoted.

```sh
cd "/Users/michaelmayer/Projects/Nightshift FM/nightshift_fm_codex_pack"
# Example only: point this at your actual standard editor executable.
export GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
sh tools/godot.sh version
sh tools/godot.sh import
sh tools/godot.sh test
sh tools/godot.sh smoke
sh tools/godot.sh test --quit-smoke
sh tools/godot.sh run
# Alternatively, open the editor, then F6/F5 as appropriate:
sh tools/godot.sh editor
```

For Linux use the downloaded editor executable as `GODOT_BIN`. The POSIX wrapper
runs in macOS/Linux or Git Bash on Windows. With native PowerShell use:

```powershell
Set-Location 'C:\Projects\Nightshift FM\nightshift_fm_codex_pack'
$env:GODOT_BIN = 'C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe'
& $env:GODOT_BIN --version # Verify 4.7.2.stable.official before proceeding.
& $env:GODOT_BIN --headless --path . --import
& $env:GODOT_BIN --headless --path . --script res://tests/test_runner.gd
& $env:GODOT_BIN --path .
```

Import must precede tests on a fresh checkout: it registers global script classes
and regenerates `assets/ui_strings.en.translation` from the English CSV as needed.
Keep this generated translation in source alongside its CSV and `.import` sidecar:
the first editor initialization reads configured translations before importing
CSV, so omitting it produces missing-resource errors on a fresh import. Keep
editor-generated `.gd.uid` sidecars too; never commit `.godot/` caches.
The main scene uses resource paths and does not depend on preexisting UIDs.

Equivalent engine commands, per the official
[command-line reference](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html):

```sh
"$GODOT_BIN" --headless --path . --import
"$GODOT_BIN" --headless --path . --script res://tests/test_runner.gd
"$GODOT_BIN" --headless --path . --quit-after 10
"$GODOT_BIN" --path .
```

## Verification contract

```sh
sh -n tools/godot.sh
python3 tools/check_foundation.py
sh tools/godot.sh test --intentional-failure
echo "$?" # Must be 1 after the engine actually ran the intentional failure.
```

`check_foundation.py` uses Python 3.9+ standard library only. It checks resource
paths, localization coverage, the bounded 78-resource M2/M3/M4 catalog, and the
wrapper using an explicitly fake executable in a temporary directory. Its PASS
does **not** establish Godot import, GDScript parsing, scene layout, or gameplay.

The real GDScript runner prints per-check PASS/FAIL and `RESULT: … failures`.
Ordinary tests must exit 0 with zero failures. Intentional failure must print its
specific failure and exit 1. Missing engine exits 127; version mismatch exits 2;
neither proves the intentional-failure acceptance criterion. A runtime stall has
a 15-second watchdog. Also inspect logs for script/import errors: a bare process
exit is not enough evidence of a clean Godot import or smoke run.

The invalid `.tres` fixtures are expected to print useful ID/path/field errors;
these are asserted by the suite and are not unexpected engine errors. Definition validation covers M0–M4 fields and exposed effects.
`--quit-smoke` emits the actual Quit button signal and should terminate with 0;
if Quit does nothing it exits 1. This is separate from the main suite because
Quit terminates the test process. Button-signal tests do not certify mouse/touch
hit testing, keyboard focus rendering, or physical-device usability.

For fresh-source verification, copy the project into a new directory excluding
`.godot/`, then repeat import, tests, and launch there. No existing project files
need to be deleted. GitHub handoff and fresh-clone evidence are recorded separately in
`IMPLEMENTATION_STATUS.md`.

## Desktop human check

1. Launch `run`. Inspect the portrait 450 × 800 desktop window (720 × 1280 logical
   canvas). Confirm the title, geometric transmitter, and three menu buttons fit.
2. Click New mission: play a wave and inspect all draft cards, then use Back to menu and Continue.
3. Click Settings: toggle the decorative signal, return, and reopen Settings.
   Confirm the session-only preference remains and the radio cabinet stays visible.
4. Try Escape from both pages, Tab/Shift-Tab and Enter/Space for navigation.
5. Resize to a taller and wider window: the logical rectangle stays fixed and
   extra space is letterboxed. Inspect text, focus, and button boundaries.
6. Click Quit and verify process exit; relaunch and close the window normally.

The portrait settings follow the official
[ProjectSettings API](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html).
The fixed aspect is deliberate; safe-area probes and mobile input/export checks
are M1 work. M0 reserves `pause` (P), `focus_target` (left mouse), `aim_override`
(right mouse), and `shield_ability` (Space); combat uses the pause, focus and shield actions.
`menu_back` uses Escape; Godot's built-in UI actions handle focus and activation.

## Architecture boundary

`CombatSession` is the renderer-independent simulation. A plain session retains
the M2 fixture for regression tests; the boot menu starts M4; existing M3 saves retain their original content.
`DraftState`, `UpgradeTrack` and `RunRandom` own per-run progression state.
`TrackDefinition` and `UpgradeDefinition` resources remain read-only. `MissionStore`
validates and writes the profile/run envelope; `MissionProfile` owns persistent
option IDs and the idempotent completion record. No permanent combat-stat field
is stored in the profile. The earlier M0 `ProfileState` skeleton and M1 diagnostic
store remain isolated from production mission saves.

See [M3_UPGRADES.md](M3_UPGRADES.md) for save schemas, checkpoint replay,
recruitment limits, RNG precision and the exact exposed branch scope. No backend,
account service, native achievements or later-milestone arsenal was added.

## Dependencies and assets

Runtime: Godot 4.7.2 standard ([MIT license](https://godotengine.org/license/));
engine-provided default UI font only. No third-party plugins or asset downloads.
Python is an optional development check tool, not a runtime dependency.
The transmitter consists of original lines, arcs, circles, and a rectangle drawn
by this project. No commercial music, copyrighted asset pack, account, credential,
or Internet connection is required to run the imported foundation. Obtain engine
license notices from the matching official distribution when packaging later.

## M4 playtest slice

Run `"$GODOT_BIN" --path . --script res://tests/visual_m4.gd` for isolated desktop
rendering evidence. Add `-- --interactive` to leave its draft open for clicking.
The expanded suite covers the three-family slice, branch behavior, elite status
resistance, reports, physical-save-compatible checkpoints and two automated builds.
Read [M4_PLAYTEST.md](M4_PLAYTEST.md) for the separate human acceptance gate.

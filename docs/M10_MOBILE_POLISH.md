# M10 — Radio art and accessibility opening increment

Started by owner request on 2026-09-09. This is a playable M10 increment, not full
milestone acceptance. M8 remains partial; M9 still lacks Endless and 23 evaluated
achievement conditions. Starting M10 does not waive those earlier gates.

## Approved battlefield revision — 0.10.3

Implemented the owner's approved `station-tuning-concept-v4.png` layout:
- Station Health replaces Hull in player-facing health/report text.
- A fixed orange 100 FM target and moving pale needle replace progress fill.
  Earned kills narrow an overshooting search; ready upgrades lock the station.
  Old-radio knobs rotate with the needle; pause freezes both. Timing/RNG/saves
  remain owned by the simulation.
- Shorter header, 48-logical-pixel Pause control, and a taller battlefield.
  Incoming waveform overlays its tick marks in a single strip.
- Raised shield boundary clears every instrument and shield arc. Enemy positions
  and touch input map the simulation's existing breach boundary onto that line.
- Main tower stays horizontally centered for every loadout. Support slots remain
  separate; a full five-support deck has even 90-unit center spacing.
- Deferred upgrade-sheet resizing now safely skips panels removed from the tree.

PASS: clean-source generators changed zero files; import, **4,574 regressions**,
startup smoke, **200 rendered viewport/layout checks** at four sizes with large
text, and seven foundation checks. Final regression and visual logs have no engine
or script errors. Android debug export passed: **0.10.3/code 15**.

PASS: Pixel 10 Pro XL updated in place with `adb install -r`, version 0.10.3/code
15 verified, launch succeeded and the process is running. Both existing mission
save files were backed up and byte-identical before installation, after installation,
and after launch. No runtime script/fatal errors were observed. The game was not
foreground at capture time, so visible physical UI/gameplay checks for this build
are NOT RUN; rendered desktop screenshots are separate evidence. See
`evidence/M10/pixel-approved-install.json` and `pixel-approved-runtime.txt`.

Relevant files: `scripts/ui/radio_dial.gd`, `scripts/combat/combat_arena.gd`,
`combat_screen.gd`, `scripts/ui/draft_panel.gd`, localized UI strings and their
generators, presentation/coordinate regression tests, and `tests/visual_radio.gd`.

Commands (Godot 4.7.2 standard):
```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot python3 tools/check_encounter_fresh.py --milestone M10
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/visual_radio.gd
python3 tools/check_foundation.py
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh android-debug
```

Evidence: `approved-fresh.txt`, `fresh.json`, `approved-tests.txt`,
`approved-visual.txt`, `approved-foundation.txt`, `approved-android-export.txt`,
`approved-source-manifest.json`, and current `combat-*`, `five-supports-*`,
`upgrade-sheet-*` screenshots in `docs/evidence/M10/`.

This handoff includes the previous local M9 and M10 increments. Full M10, remaining
encounters/achievements, physical performance, audio/haptics and human acceptance
remain open. The older sections below are delivery history.

**Physical delivery update (2026-09-09):** M10 was installed on the Pixel 10 Pro
XL at the owner's request. Both existing mission save files remained byte-identical
across update and launch; local backups were retained. Android reported launch
success and a running process. The phone remained locked, so visible UI and
physical gameplay checks remain NOT RUN. See
[physical install evidence](evidence/M10/pixel-install.json).

## Radio station revision — 0.10.2

Owner-directed changes:
- Mission tiles now update a plain, wrapping mission-name label. Removed the
  duplicate mission dropdown and the mission briefing section.
- All twelve modules are available on a fresh profile, with existing tradeoffs
  and the two-slot cap. Existing loadout, profile and module IDs are unchanged.
- Removed the manual Burst button and its drag/tap input path. Field touches
  only focus automatic fire; release returns to automatic targeting. The shield
  ability remains. Removed the obsolete Burst handedness setting from the UI.
- Earned kills tune an animated analog radio scale. The incoming-signal strip
  has a moving waveform. Hull/shield stats and bars sit below the battlefield;
  Pause is a smaller square control with its existing touch-sized hit area.
- Upgrade/recruitment panels are centered sheets at at most 68% of screen
  height, capped at 840 logical pixels, leaving the paused field visible. Cards
  size to their content and retain 88-pixel information-button targets.
- Tower and support-instrument centers occupy equally spaced deck slots.
- Original SVGs now depict a lattice transmission tower, valve microphone,
  studio monitor, mixing desk, tape deck, turntable and spring-reverb equipment.
  Opponents are pocket music players, wireless earbuds and smart speakers.
- Nine distinct attack styles use sound-wave crests, twin waveforms, packet
  fronts, oscillating chains, bass fans, interference lattices, tape loops,
  musical notes and reverb spirals. Enemy bolts use digital packet trails.

**Combat rules:** New campaign checkpoints explicitly store
`active.automatic_radio = true`. This disables the old Burst simulation entry
point and uses 70% of the earlier enemy-health scaling, compensating for removing
manual Burst. Earlier three-field active checkpoints remain readable and retain
their stored rules; restarting/starting a new mission uses automatic-radio rules.
The old active combat helper remains for historical-save and legacy test support,
but current gameplay has no Burst input binding. No automatic Burst is substituted.

Validation:
- PASS: fresh import, reproducible generators (zero changed generated files),
  4,564 full regressions and startup smoke. Includes native touch focus/release,
  early module validation, new/legacy JSON checkpoints and equal deck spacing.
- PASS: 176 real viewport-input/layout checks at 360×640, 450×950, 768×1024 and
  1024×768 with larger text, including live-earned compact upgrades, detail
  panels, contained card text, background pause, and card selection.
- PASS: automated no-Burst campaign study, 27 runs with three starting supports
  across three seeds. 25 victories / 2 defeats; each support cleared mission 3
  on at least one seed. Every decision checkpoint was restored. This establishes
  automatic-only viability, not human balance or pacing acceptance.
- PASS: seven foundation checks; Android debug export 0.10.2/code 14.
- PASS: installed on Pixel 10 Pro XL. Both mission save files were backed up and
  byte-identical before installation, after installation and after launch. Native
  menu and combat screenshots inspected. This is visual smoke evidence, not a
  full physical playthrough. See `pixel-station-install.json` and
  `pixel-station-combat.png`.
- Desktop render-only stress: 550 actors retained; p95 13.551 ms normal and
  13.304 ms low effects on Apple M2 Pro. Android thermal/FPS acceptance NOT RUN.
- Evidence: `automatic-playthrough.json`, `attack-gallery.png`,
  `upgrade-sheet-360x640.png`, `station-source-manifest.json`, current `fresh.json`
  and `station-*.txt` in `docs/evidence/M10/`.

This is still M10. New enemy mechanics/bosses and full milestone/human acceptance
remain open. No GitHub push was part of the earlier 0.10.2 delivery.

## Setup polish revision — 0.10.1

The owner found the setup too text-heavy. The revision replaces the default
form with three illustrated equipment cards, a hull/shield/hit stat strip,
collapsed module/stat/preset drawers, and an always-visible Back/Go live footer.
Full stats and every module tradeoff remain available on demand. Empty preset
loads now show feedback. Back preserves the working equipment, fitted modules,
and selected replay mission during navigation.

Campaign selection now shows twelve tappable stations grouped by valve,
transistor, and digital eras, with completed/locked/selected states. Detailed
briefings and unlock explanations are optional; prototype encounters keep a
visible warning. Settings use compact single-row switches. The pause reminder
is shorter; full instructions remain under Settings → Controls & symbols.
Setup, menu, and settings controls share radio-console colors and surfaces.

Validation for this revision:
- PASS: 4,559 full regression checks, including navigation state preservation.
- PASS: 152 actual viewport-input checks at 360×640, 450×950, 768×1024 and
  1024×768, using larger text. Includes completed stations, all modules, two-slot
  limits, expanded stats/presets/controls, and fixed launch-button visibility.
- PASS: seven foundation checks and Android debug export (0.10.1/code 13).
- Screenshots: `evidence/M10/equipment-360x640.png`, `campaign-360x640.png`,
  `settings-360x640.png`, `modules-360x640.png` and the other tested sizes.
- Build/source identity: `evidence/M10/polish-source-manifest.json`.
- PASS: physical Pixel 10 Pro XL update to 0.10.1/code 13 and process launch.
  Both existing mission save files were backed up and verified byte-identical
  before install, after install, and after launch. The game was not foreground;
  physical visible-UI/gameplay checks are NOT RUN. Evidence:
  `evidence/M10/pixel-polish-install.json`.
- PASS: startup smoke and whitespace checks. Changes remain local/uncommitted;
  this delivery did not push to GitHub.

This revision does not complete the outstanding M10 gameplay, final-art,
physical performance or human acceptance gates below.

## Implemented

- Original vector radio hardware for all six support turrets and three main
  transmitters, used in combat; support/draft icons share the same artwork.
- The three implemented enemy movement families now have radio bodies in valve,
  transistor and digital variants. Campaign region selects their era; the later
  regions still contain explicitly labeled prototype encounters. Existing elite,
  dive, firing, focus and status tells remain visible above the artwork.
- A radio-console menu illustration and quieter era-colored arena surfaces.
- Persistent local reduced-flash, low-effects, larger-text (115%), left-side
  Burst, sound, music, optional hit-vibration and menu-decoration settings.
  Settings use their own versioned atomic file and validated backup, independent
  of mission/profile saves. Invalid settings recover a backup or safe defaults.
- Android system Back now navigates within the app: settings returns to menu;
  combat settings returns to pause. The menu still allows an explicit quit.
- Scrollable settings available from the menu and combat pause screen. Leaving
  combat settings returns to pause; only explicit Resume resumes the fight.
- Larger button hit areas; font scaling applies once per control and reverses
  exactly. Safe margins now refresh when base margins change, even at an
  unchanged viewport size. Existing safe-area conversion remains in use.
- Four original synthesized audio files: transmit, hit, tuning cue and a quiet
  ambient station bed. Four effect voices and throttled shot cues bound audio
  overlap. Audio pauses with gameplay and releases on exit. Headless checks use
  no playback voices because they have no display/listener. Hit vibration is
  opt-in and currently hooked up on Android; physical feedback is unverified.

Combat rules, content IDs, collision radii, unlocks, gameplay RNG and checkpoint
formats are unchanged. Low effects reduces decorative fills and ring geometry;
all enemies, projectiles, field boundaries and status cues remain. Screen shake
is always off. No assets introduce new enemy/boss behavior.

## Art and audio provenance

`tools/generate_radio_art.py` is the source for 18 SVG assets in
`assets/art/radio/` and four WAV files in `assets/audio/radio/`. These are original
repo-native vector drawings and mathematical tone synthesis created for this
project. No downloaded artwork, commercial songs, logos, external asset packs,
image-generation API or new dependency is used. Typography remains Godot's
bundled fallback font. Regeneration is deterministic and checked in a clean copy.

Preview: [Radio hardware sheet](evidence/M10/radio-hardware.png),
[five turrets at 360×640](evidence/M10/five-supports-360x640.png),
[large-text settings](evidence/M10/settings-360x640.png).

## Validation and reproduction

Use the pinned Godot 4.7.2 standard build. Commands run from the project root:

```sh
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
python3 tools/generate_radio_art.py
sh tools/godot.sh import
sh tools/godot.sh test
"$GODOT_BIN" --headless --path . --script res://tests/radio_checks.gd
"$GODOT_BIN" --path . --script res://tests/visual_radio.gd
"$GODOT_BIN" --path . --script res://tests/radio_render_stress.gd
python3 tools/check_foundation.py
python3 tools/check_encounter_fresh.py --milestone M10
sh tools/godot.sh smoke
sh tools/godot.sh android-debug
```

Script-driven QA uses `m10_script_preferences.json` and named fixture saves; it
does not read or overwrite the owner's presentation preferences. Five-support
screenshots are explicitly artificial loadouts with saving disconnected, not
evidence of earned unlocks. Test saves require app-data filesystem access.

| Check | Result |
|---|---|
| Before-change baseline | PASS — 4,499 checks, zero failures |
| Updated regression | PASS — 4,540 checks, zero failures |
| Targeted M10 suite | PASS — 39 checks, zero failures |
| Desktop viewport input/layout | PASS — 68 checks; 360×640, 450×950, 768×1024, 1024×768 |
| Foundation/source checks | PASS — seven tests |
| Clean-copy generation/import/test/smoke | PASS — no generated differences; 4,540 checks; no script errors or shutdown warnings |
| Android 0.10.0/code 12 debug export | PASS — `builds/android/nightshift-m10.apk` |
| Native Android emulator checks | PASS — final APK install/launch, settings persistence, Back navigation and opening combat; emulator only |
| Physical Android/iPhone, haptic feel and audio approval | NOT RUN |
| 20-minute physical thermal/memory soak and battery settings | NOT RUN |
| Full-campaign human balance, art approval, store screenshots | NOT RUN |

The render-only fixture uses 150 enemies, 400 enemy projectiles, five turrets and
12 decorative pulses without advancing simulation. On the Apple M2 Pro / macOS
Compatibility renderer, 300 measured frames after 120 warm-up frames gave p95
9.850 ms normal and 9.728 ms low effects. All 550 actors remained present. Static
memory grew about 7.5 KB during each short sample. This is not a sustained memory
soak, an actual authored-fight benchmark, or a mobile performance claim. Detailed
results are in `evidence/M10/render-stress.json`.

The initial sandboxed baseline could not write test saves; rerunning with the
required app-data access passed. An early visual fixture tried to equip locked
families from the opening campaign catalog; the isolated fixture was corrected.
Native Android Back initially exited from Settings; explicit window Back routing
now fixes that behavior and is covered by two additional regression checks.
Headless test teardown exposed retained dummy WAV playback; headless audio now
does not create playback voices. These initial results are not acceptance passes.

API references checked during implementation: Godot's
[handheld vibration API](https://docs.godotengine.org/en/stable/classes/class_input.html#class-input-method-vibrate-handheld)
, [Window Back requests](https://docs.godotengine.org/en/stable/classes/class_window.html#class-window-signal-go-back-requested)
and [AudioStreamPlayer](https://docs.godotengine.org/en/4.5/classes/class_audiostreamplayer.html).
Compilation and execution use the installed pinned 4.7.2 build. The Android
signing tool emits its known Java native-access deprecation warning; APK
signature verification succeeds. Android export
enables the vibration permission; no network permission or native service login
was added.

## Remaining M10 work

The five additional enemy roles, bosses and their final attack animations depend
on remaining M8 content. Their radio forms are specified in
[the art brief](RADIO_ART_DIRECTION.md), but are not newly implemented here.
Branch/rank-specific art evolution, full authored environment art and a finished
soundtrack remain open. Larger text in platform popup menus and all translated
language layouts still need dedicated coverage; current release text is English.

Physical baseline devices must be named and tested for safe areas, readable
touch targets, denied login, interrupted audio, battery restrictions, force-stop
at every required checkpoint phase and 20-minute thermal/memory behavior. Existing
regression save tests do not substitute for those device checks. Human review
must approve the radio silhouettes, sound mix, controls, pacing and difficulty.

M11, release signing, store submission and publishing have not started. Source
changes are local and uncommitted. The Pixel now has M10; its existing mission
save files were preserved. Visible physical gameplay acceptance remains open.

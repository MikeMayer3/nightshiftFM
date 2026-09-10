# Battlefield and feedback polish — 2026-09-10

The owner approved all five recommended improvements following the splash redraw.
This is a presentation-only continuation: combat damage, ranges, enemy paths,
upgrade eligibility and checkpoint schema remain unchanged.

## Implemented

- Original native vector mountains, foothills and edge pines replace the repeated
  architecture/stripe background. Muted navy/teal shapes echo the revised splash
  while keeping the central action corridor legible. Three era sky tints remain.
- A small studio sits beneath the central transmitter. Healthy/damaged/critical
  health lights three/two/one windows; defeat darkens all windows. Hits briefly
  dim lit windows, and a critical studio gains a cracked panel.
- Damage events trigger short sprite-only recoil and small contact strokes. Bass
  recoil is stronger. The actual Static Net slow state draws a moving weave over
  the trapped actor; the decoration ends with the mechanical status.
- Near-breach actors mark their approach points at the defense line. Critical
  health adds a steady readable warning and a warm edge; the gentle animation
  becomes static under reduced-flash settings. Nearby markers merge and cap at 16.
- Each wave shows “ON AIR · WAVE …” for 2.4 seconds in the existing signal strip,
  alongside the existing radio cue. No modal, countdown, wave delay or new tap.
- Successful upgrade/recruitment/branch choices briefly illuminate their actual
  instrument for 1.3 seconds. Rejected choices do not create a celebration.

`RadioScenery` owns original vector shapes; `RadioFeedback` owns transient visual
state. `CombatArena` reads both, and `CombatScreen` connects actual wave and choice
events. Localization adds two short labels. No external artwork or audio was
introduced in this pass.

Feedback clocks freeze during pause, choices and wiring. Recoil is disabled by
low-effects/reduced-flash options; optional stars, trees and upgrade sparks reduce
in low-effects mode. Damage reaction storage caps at 128 actors. Restart clears
all feedback and the earlier kill fragments. Rendering never consumes gameplay RNG.

## Verification

Godot 4.7.2 standard; commands from the project root:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh import
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh test
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh smoke
python3 tools/check_foundation.py
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/visual_battle_polish.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/polish_autoplay.gd -- --battle-polish
```

PASS: **5,555 regression checks, zero failures**; seven foundation checks and
asset/script import and startup smoke. Regression coverage includes sprite-only recoil, checkpoint/RNG
invariance, paused clocks, bounded reaction storage, warning thresholds, real
earned upgrade button wiring, rejected choices, restart cleanup and wave notice
delivery during live combat.

PASS: **15 rendered checks, zero failures**, at 360×640, 450×950 and 1024×768.
Staged dense fights contain 18 actors and all five equipped support slots. Healthy,
critical and reduced-effects screenshots were inspected. These scenes deliberately
stage health, statuses, ranks and actor positions to inspect presentation; they
are not evidence of completing a mission or representative balance.

PASS: **88 complete rendered-playthrough checks, zero failures**. Two accelerated
production-scene mission-1 runs reached wave-10 victory using legal visible draft
button signals. Net: 22 choices, 524.05 game seconds, 100 hull, zero breaches.
Bass: 20 choices, 541.98 seconds, 59.69 hull, 47 breaches. All 42 accepted choices
highlighted the correct instrument. Seeds, metrics and return-to-menu evidence:
`evidence/M10-battle-polish/playthrough.json` and `playthrough.log`. These automated
recruit-first runs are not human win-rate evidence. No player stat bonuses were
injected into these runs; the dense visual fixture above is separate.

No script/runtime errors appeared in the saved execution logs. Import warns about
the existing nested QA project in ignored `builds/`, which Godot skips.

NOT RUN: physical-phone review of these additions, human feel/readability approval,
audio listening approval or distribution. The phone still has the earlier 0.10.6
balance/module build. This work is local, uncommitted and unpushed.

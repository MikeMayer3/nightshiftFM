# Population waveform and in-bar health — 2026-09-10

Owner-requested HUD revision, on top of the local battlefield polish.

The Incoming Signals / ON AIR strip counts living spawned enemies, including those
still approaching from offscreen. Projectiles, resolved actors and zero-health
actors are excluded. An empty field produces a flat signal. Amplitude increases
and wavelength decreases monotonically with population: density = n/(n+12),
amplitude = 2+13*density for nonzero n, wavelength = 160-132*density. The result
stays within the strip even for extreme populations. Sampling remains fixed at
97 points. Existing paused/choice clocks keep the animation frozen when play stops.
Combat, targeting, upgrade timing and gameplay RNG are unchanged.

Health and shield bars are now 60 logical pixels tall, with independent centered
`Health current / maximum` and `Shield current / maximum` labels. Dark amber and
teal fills support readable cream text with a dark outline across both filled and
empty portions. The old shared label above the bars is hidden. Labels use actual
module-adjusted capacity values and the existing large-text setting.

Changed: `RadioFeedback`, `CombatArena`, `CombatScreen`, localization, feedback
unit tests, the module-adjusted HUD integration assertion and `visual_meters.gd`.

PASS: **5,561 regression checks, zero failures**. **63 rendered checks, zero
failures** across 360×640, 450×950 and 1024×768, with large text and staged counts
0/4/24. Inspected full, partial and empty bars. Import, startup smoke and seven
foundation checks passed. No script errors. Render fixtures stage populations and
health for visual inspection; no human/full-mission acceptance is inferred.

Commands from the project root with Godot 4.7.2:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh import
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh test
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh smoke
python3 tools/check_foundation.py
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/visual_meters.gd
```

Evidence: `evidence/M10-meters/`. This pass is local, uncommitted and unpushed.
NOT RUN: phone installation/review of this revision or human readability approval.

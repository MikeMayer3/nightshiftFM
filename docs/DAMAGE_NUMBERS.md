# Hit damage numbers (2026-09-10)

Follow-up: numbers now spawn over the enemy and no longer separate to avoid overlap.
See [NOTE_DRONES.md](NOTE_DRONES.md) for the newer local change.
The description and captures below document the original 0.10.14 delivery.

Implemented on top of the release-audit fixes. Android 0.10.14/code 26 was built
and installed on the physical Pixel at the user's request. Launch passed with no
runtime errors and all six save/settings files byte-identical before/after.
Source remains uncommitted/unpushed; GitHub release remains 0.10.13.

- Enemy hits show floating, dark-outlined cream numbers at the impact location.
- Actual critical rolls produce larger gold numbers with `!`, a stronger initial
  scale pop, and a longer lifetime (1.05 seconds versus 0.85 seconds).
- Values represent effective damage after mitigation and remaining-health limits,
  rounded for display; positive sub-unit hits use one decimal with a 0.1 minimum.
- Hits on the same target within 120 ms combine separately by critical status.
  Presentation is capped at 48 entries; this never drops simulation damage.
- Numbers survive enemy removal, pause during Pause/upgrade choices, and clear on
  restart. Reduced flash/effects disable the scale pop and reduce travel; large
  text increases number size. Labels stay inside the battlefield and make a bounded
  attempt to separate from other numbers; extreme crowd overlap is still possible.
- Damage events now carry the existing critical roll. No additional gameplay RNG
  calls, damage formula changes or checkpoint schema changes were introduced.

## Changed code

`combat_event.gd`, `arsenal_combat.gd`, and `combat_session.gd` carry critical metadata.
`damage_numbers.gd` owns bounded cosmetic state and drawing; `combat_arena.gd` captures
hit locations and draws numbers above effects; `radio_feedback.gd` advances/resets them.
`tests/unit/test_damage_numbers.gd` is registered in `tests/test_runner.gd`.
`tests/visual_damage_numbers.gd` renders synthetic hits through production UI wiring.
Drawing API checked against the [official CanvasItem reference](https://docs.godotengine.org/en/stable/classes/class_canvasitem.html#class-canvasitem-method-draw-string-outline).

## Validation

Commands run from the project root, with `GODOT_BIN` set to the pinned Godot 4.7.2 executable:

```sh
sh tools/godot.sh import
sh tools/godot.sh test
sh tools/godot.sh smoke
"$GODOT_BIN" --path . --script res://tests/visual_damage_numbers.gd
```

PASS: import, 6,146 regression checks, desktop smoke, and 18 rendered checks
across nine screenshots. Logs contain no `ERROR:`, `SCRIPT ERROR:` or `FAIL:`.
Physical-device validation for this feature: **NOT RUN**.

Evidence: [damage-numbers](evidence/damage-numbers/). Native rendered fixtures cover
320×568, 450×1000 and 1024×768, initial pop, floating phase and reduced-effects/large
numbers. These are synthetic desktop renders, not physical phone or human playtests.
The initial visual fixture had four enemies outside valid weapon reach and correctly
produced no popups for them. Moving that fixture into actual range resolved the test;
protected-entry behavior remains covered by a regression.

Prior audit's intermittent Android shield-caption issue and remaining store release
gates remain open; see [RELEASE_PLAYTHROUGH_AUDIT.md](RELEASE_PLAYTHROUGH_AUDIT.md).

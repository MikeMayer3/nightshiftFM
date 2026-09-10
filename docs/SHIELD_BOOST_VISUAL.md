# Visible temporary shield boost — 2026-09-10

Owner requested a clear visual for the shield button's temporary protection.

Implemented a translucent violet dome across the station defense line, a shield
crest and the current bonus reserve above the station. The shield meter adds a
second line, `+20 TEMP SHIELD` at base activation, and a violet duration strip.
Capacitor's button now reads `Shield Boost` when ready and `BOOSTED · 3s` during
the boost, with an active violet treatment. After protection ends it shows cooldown.
Both bottom bars are now 76 logical pixels tall so two lines fit with large text;
their height remains steady when the temporary line appears or disappears.

The dome, reserve text and duration strip read the actual overshield state via
`RadioShieldVisual`. Values round up for display. Damage consumption updates the
display immediately; depletion or timer expiry removes the indicators. Pause
freezes the actual timer. Reduced-flash mode uses a quieter steady fill and
low-effects mode omits decorative marks. No gameplay stats, durations, absorption
rules or serialized formats changed. UI activation uses the existing `use_shield`
handler so the button refreshes immediately after activation.

Changed: `RadioShieldVisual`, `CombatArena`, `CombatScreen`, localization, and
`tests/visual_shield_boost.gd`.

PASS: 5,561 regression checks; 60 rendered shield checks; seven foundation checks;
asset/script import and startup smoke. Zero final failures or script errors.
The rendered fixture uses real button activation, damage absorption, timer expiry,
pause and JSON checkpoint restore, with isolated saves. It covers 360×640,
450×950 and 1024×768 with large text, and normal/reduced-effects previews.
An initial fixture used an invalid test-only damage-source ID; replacing it with
the actual spawned enemy's name key made the restore checks valid and pass.

Commands from the project root, Godot 4.7.2:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh import
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh test
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh smoke
python3 tools/check_foundation.py
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/visual_shield_boost.gd
```

Screenshots/logs: `evidence/M10-shield-boost/`.
NOT RUN: physical-phone/human visual approval. Local only, uncommitted and unpushed.

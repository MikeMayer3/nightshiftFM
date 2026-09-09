# M6 — Patchboard selection foundation

Status: **STARTED / NOT ACCEPTED**. This is the first testable M6 increment,
not the complete milestone and not a playable patchboard release.

## Implemented source

`PatchboardState` owns at most two distinct recipe IDs. It validates an authored
`Array[SynergyDefinition]` once, copies endpoint/localization metadata, and keeps
runtime selection out of shared Resources. Recipe definitions must have two
distinct known endpoints. The six support-family IDs retain the five-equipped
limit. `main` and `shield` are endpoint roles, not extra support slots; a future
combat adapter must resolve the selected chassis to those roles.

Selection changes require an intermission and an externally supplied unlock
state. **A mid-wave Signal upgrade pause is not an intermission.** Empty slots,
shared endpoints and slot ordering are supported. Rejected operations are atomic.
Removing a required equipped endpoint makes `is_active` false immediately.
Preview results include missing endpoint IDs and localization keys, and do not
leak the controller's mutable arrays.

The isolated schema-1 snapshot stores only recipe IDs. Restore rejects unknown,
duplicate, excessive, malformed, locked or unequipped selections and preserves
existing state on failure. It validates against authoritative equipment/unlocks,
not values embedded in the snapshot. JSON numeric versions are supported without
accepting a boolean as version 1. New-mission reset clears active connections.
This snapshot is **not yet integrated into existing run/profile save schemas**.
Call `restore` only from checkpoint recovery, not as a UI rewire operation.

## Tests authored

`tests/unit/test_patchboard.gd` is registered in the existing test runner. It
covers configuration failures/retries; copied-resource isolation; two slots;
shared endpoints; locked/in-combat/invalid rewiring; live equipment checks;
preview isolation; reset; JSON round-trip; malformed saves and atomic recovery.

All eight catalog endpoint pairs appear as **test fixtures only**: Ball
Lightning, Dead Zone, B-Side, Live Wire, Pressure Drop, Double Drop, Needle
Thread and Feedback Loop. These fixtures verify selection contracts, not
recipe damage, status application, balance or discovery.

## Integration work remaining in M6

1. Author the eight immutable gameplay recipe resources, validated coefficients,
   trigger conditions, cooldowns, target/generation caps and localization.
2. Implement combat adapters/payoffs, attribution and connection telemetry. Add
   positive and negative trigger tests, generated-hit exclusions, shield-loop
   prevention, boss-resistance fallbacks and bounded worst-case proc tests.
3. Add the two-slot intermission UI, prerequisite previews and unlock/tutorial
   presentation. Do not create mid-wave rewiring through Signal drafts.
4. Integrate checkpoint/profile state with content versioning and migrations;
   implement discovery on the first successful trigger, not mere selection.
5. Run import, full regression, smoke, stress and phone checks. Human-test three
   combinations. Earlier human acceptance gates remain unverified.

No gameplay scene, existing content resource, M5 coefficient, save format,
export preset, engine pin, native service or release asset was changed here.
No M7/M8 systems are included.

## Reproduction

From the full repository with the existing pinned Godot 4.7.2 standard toolchain:

```sh
export GODOT_BIN="/absolute/path/to/Godot"
sh tools/godot.sh import
sh tools/godot.sh test
python3 tools/check_foundation.py
sh tools/godot.sh smoke
```

This authoring environment had no Godot executable, project checkout, Android
SDK/device or iOS environment. Repository files were inspected through GitHub;
changed source was authored separately. A source-whitespace check was run, but
**GDScript parsing/execution, full regression and gameplay checks are NOT RUN**.
Do not infer a passing compile or gameplay result from these files' existence.

API reference reviewed: Godot official GDScript and Array documentation
(`https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_basics.html`
and `https://docs.godotengine.org/en/stable/classes/class_array.html`). The engine
pin was not changed, and this documentation review is not engine verification.

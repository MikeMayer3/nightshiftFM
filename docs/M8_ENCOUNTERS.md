# M8 opening encounter increment

The owner requested the next milestone be started. M8 follows the implemented
M7 progression shell. This is a complete playable opening increment, **not M8
completion**. Existing local M6/M7 work is retained.

## Playable scope

| Mission | Encounter identity |
|---|---|
| 1 — First Transmission | Tight swarms, then alternating lanes and broad fans; divers enter in wave 3 |
| 2 — Carrier Traffic | Centered carrier escorts; three-member introductory groups expand to five; divers enter in wave 5 |
| 3 — Crossed Wires | Alternating diver pairs and broad mixed carrier formations |

Each mission has ten immutable authored wave Resources, its own tempo and
composition, and a matching selection-screen briefing. Elite swarmer, carrier,
and diver variants retain their familiar movement/counters and visible gold
elite marker. They first appear in wave 6, recur in waves 8–9, and form a spaced
trio in the finale. No new enemy identity appears for the first time in wave 10.
Carriers retain a hard limit of three children and three destructible bolts.
There are still only three base enemy families in these encounters.

Four formation layouts are bounded within the top spawn band. A wave declares
one to five members per group; spawn order and wave RNG remain deterministic.
The UI accurately keeps missions 4–12 labeled as prototype battles. Mission
unlocks, modules, ranks, and reward commits continue through M7 services.

## Save contract

New missions 1–3 use content version `m8.encounters.1`. M7 checkpoints keep
`m7.1`, including the old wave-8 elite schedule. Restoring then advancing a
legacy checkpoint is regression-tested against advancing the original state.
New checkpoints resolve elite definitions, actor state, source attribution,
projectiles, and formation progress. Old content rejects new enemy identities.
Unknown M8 mission/version combinations are rejected rather than silently
substituting a battle. No profile schema or permanent stat multiplier changes.

## Changed components

- `tools/generate_encounter_content.py`, `content/encounters/`, opening mission
  Resources and `EncounterWaves`: deterministic generated encounter data.
- `EncounterContent`, `WaveDefinition`, `CombatSession`: authored lookup,
  formation placement, content reference/budget/introduction validation.
- `SignalSnapshot`: version-aware recovery of new and legacy encounters.
- `CampaignPanel`, localized strings: selected-mission briefing.
- M7 generator: preserves M8-owned authored missions during module regeneration.
- Encounter unit checks, campaign UI coverage, playthrough and visual drivers;
  updated foundation content count. No new dependencies or native APIs.

## Validation

From the project directory, with Godot `4.7.2.stable.official.ed1daf0bf`:

```sh
python3 tools/generate_encounter_content.py
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh import
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh test
python3 tools/check_foundation.py
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh smoke
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/encounter_playthrough.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/visual_encounters.gd
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot python3 tools/check_encounter_fresh.py
```

| Check | Result |
|---|---|
| Import and desktop smoke | PASS |
| Full regression | PASS — 4,326 checks, zero failures |
| Foundation | PASS — seven checks |
| Full mission simulations | PASS — 27 victories: three missions × three starting-support preferences × three seeds |
| Restore-and-continue at earned choices | PASS — 662 real decision checkpoints across those runs |
| Viewport input and layout | PASS — 36 checks at 360×640, 450×800, 450×950; no horizontal overflow |
| Clean-copy generators/import/regression/smoke | PASS — no generated content changes; 4,326 checks, zero failures |
| Human pacing / challenge / variety acceptance | NOT RUN |
| M8 Android/iOS export, emulator and physical-device checks | NOT RUN |

Evidence lives in `docs/evidence/M8/`. The playthrough policies use legal offers,
earned mission unlocks, aimed Burst and shield activation. They favor one
starting family while recruiting available supports; they are **not** proof of
three exclusive, fully differentiated strategic archetypes. Simulated mission
durations span 477.68–574.97 seconds. Twenty-five of 27 runs finished at full hull;
the lowest was 65.08. This is forgiving opening balance, not a certified fun gate.
No failed full-run build was observed in this matrix. An initial unit fixture
incorrectly placed support timers above the save schema's limit; removing that
unnecessary fixture override produced the final passing regression run.

The clean-copy checker omits `.godot`, builds and old evidence files, retains
the evidence output directories required by earlier unit suites, regenerates
both M7 and M8 content and compares hashes before import/test/smoke. The initial
ad hoc copy omitted those output directories and caused two older suites to
fail while writing reports; the reproducible checker preserves their structure.

The regular APK remains M7 and the physical phone has not been changed.
No commit, push or publication was performed.

## Remaining M8 work

Mission 4's Dead Caller boss is the next encounter increment. Then add the
remaining regional encounters, Plated Signals/Choir Casters/Jammers/Mimics/Mortars,
Pirate Station and Silence bosses with ordinary-attack weak-point targeting,
Standard/Hard/Overload rules and unlocks, all six explicit Contracts,
mission-specific medals, enemy/boss codex and twelve mission logs. Complete
cross-catalog reachability validation and campaign-wide archetype/failed-build
evidence. Obtain human campaign pacing/variety feedback; current tests do not
close that gate or the earlier M7 human progression gate. M9 has not started.

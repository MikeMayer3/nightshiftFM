# Mixer reminder, close hit numbers and note drones (2026-09-10)

Delivered to the physical Pixel as **0.10.15 / code 27**. All six save/settings
files remained byte-identical through install and process launch; no runtime errors.
The phone was locked, so visible in-app verification remains NOT RUN. Source is
included in the v0.10.15 publication. Future validated changes should
automatically install when the physical phone is connected, per `AGENTS.md`.

## Player behavior

- The Mixer reminder appears after 12 seconds of active combat or the first upgrade,
  whichever makes it eligible first. It appears once per run, including for players
  who have already seen onboarding. It stays for ten visible seconds and can be
  dismissed. Its text points to the Mixer button and explains that mixing pauses
  combat. Other introductory hints expire after eight visible seconds.
- Damage numbers now start over the enemy's upper body, with less lateral offset
  and shorter upward travel. Collision avoidance that displaced numbers away from
  their target is removed. Critical-hit emphasis and accessibility settings remain.
- Turntable notes fly to an enemy, circle it, fire visibly at it, then disappear
  after three baseline hits. Notes that lose their target seek an eligible nearby
  enemy; they disappear when no target remains. Projectiles and enemies in the
  protected entry corridor are excluded.
- Existing upgrade IDs and saved choices remain: pierce upgrades grant extra shots,
  steering upgrades increase orbit and firing speed, projectiles add note drones,
  and marking upgrades retain actual vulnerability and contribution credit. The
  launch interval, base damage and normal critical roll still use the existing
  stats. Baseline output is intentionally stronger than the previous flying notes.
- Each note has a finite lifetime and shot budget. Flights finish before orbiting
  starts, so fast orbit upgrades cannot prevent slow notes acquiring large enemies.
  Orbit motion follows a moving target. Shot events retain their original root and
  source; notes do not become echo sources.

## Saves and scope

The runtime validator accepts legacy nine-field traveling-note envelopes and the
new thirteen-field drone envelopes. Legacy effects migrate to finite drones on
restore; new saves preserve orbit angle, firing delay, remaining shots and flight
state. An older APK cannot be assumed to load a newer active-drone checkpoint.
No player saves were used or changed for these tests.

Runtime files: `arsenal_combat.gd`, `combat_session.gd`, `combat_arena.gd`,
`combat_screen.gd`, `arsenal_runtime.gd`, `combat_coach.gd`, `damage_numbers.gd`.
Localized descriptions and their content-generator source were updated. Generator
output was checked in an isolated directory; unrelated content was not regenerated.
The existing release-audit Back-navigation fixes remain in the local checkout.

## Verification

PASS: import; 6,159 regression checks; desktop smoke; 15 native rendered/input
checks and six screenshots. The final automated run won ten waves with
17 JSON checkpoint restores (13 containing live drones), 12842 credited Turntable
damage and a peak of 15 pending effects. Logs contain no runtime errors.

Godot 4.7.2, from the project root with `GODOT_BIN` set:

```sh
sh tools/godot.sh import
sh tools/godot.sh test
sh tools/godot.sh smoke
"$GODOT_BIN" --path . --script res://tests/visual_note_drones.gd
"$GODOT_BIN" --headless --path . --script res://tests/note_drone_playthrough.gd
```

The native visual fixture stages an unlocked Turntable in production combat UI and
uses pointer input to open the Mixer at 320×568 (large text), 450×1000 and 1024×768.
It checks that the hint fits and does not cover the arena. Six screenshots show
orbiting notes, firing, close damage numbers and the reminder.
The automated campaign uses an unlocked-profile fixture and legally selected
upgrades, restoring JSON checkpoints at every upgrade choice. It is not a human
playtest or evidence of campaign-wide balance. Physical-device gameplay for this
revision is **NOT RUN**. The previous Android shield-caption issue and store gates
remain open; see [RELEASE_PLAYTHROUGH_AUDIT.md](RELEASE_PLAYTHROUGH_AUDIT.md).

Evidence: [note-drones](evidence/note-drones/).

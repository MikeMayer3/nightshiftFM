# Studio mixer

The primary patchboard is a mixing desk available from the first mission. Open
**Mixer** from the combat footer or pause menu at any point in an unfinished run.
The world freezes while editing. Return restores the prior combat or upgrade
state; an explicit manual pause remains paused.

| Fader | Each point | Applies to |
| --- | --- | --- |
| Direct | +10% damage | Direct weapons: pulse/burst main, Arc Aerial, Needle Swarm |
| AOE | +8% damage; +6% radius or beam width | Sweep main, Static Net, Bass Driver, Reverb Well |
| Control | +12% existing slow/jam strength and push/pull/release force | Weapons that already have those parameters |

Echo Deck copies the recorded shot's mix; it does not multiply it a second time.
Shield and standalone connection-proc damage are not directly boosted by these
faders. Effects calculated from an already mixed weapon retain that input.
Existing slow, jam, force, damage, and radius limits still apply. Bonuses are
multiplicative on derived weapon parameters after rank and module changes.

Each fader allows 0–4 points. Shared budgets follow campaign progress, regardless
of the difficulty selected for this particular run: 3 initially, 5 after clearing
mission 4, 7 after clearing mission 12. Those clears unlock Hard and Overload.
Lowering a fader refunds its points immediately. Dragging beyond the available
budget stops at the affordable value; unavailable plus buttons are disabled.
A new run starts at zero allocations. No points are spent automatically.

The optional **Weapon connections** view retains both connection slots and all
eight recipes, with availability based on owned gear. Expanded runs can rewire
while the mixer is open, preserving cooldowns and resetting partial trigger
progress. There are no forced intermission connection screens in new broadcasts.
Older non-expanded saves keep the historical intermission-only rules.

The patchboard save adds an optional `mixer` object with schema 1 and three
integer levels. Loads validate channel count, integral numeric values, the
per-channel cap, and the progression budget, including after JSON conversion.
Old expanded saves without this object receive neutral faders. Run-local tracks
reference their own mix. Existing fields, projectiles, echoes, timers, health,
shield, and RNG are unchanged when points move. Shared resources are immutable.

## Verification

With `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`:

```sh
sh tools/godot.sh import
sh tools/godot.sh test
sh tools/godot.sh smoke
python3 tools/check_foundation.py
"$GODOT_BIN" --path . --script res://tests/visual_mixer.gd
python3 tools/build_mixer_qa.py
```

Evidence is in `docs/evidence/M10-mixer/`: 5,494 regression checks, 156 rendered
and viewport-input checks, seven foundation checks, clean import/startup smoke.
The render driver covers both phone sizes and budgets, disk persistence,
connections, pause-menu access, backgrounding, and returning to pending drafts.
The isolated QA export uses `org.nightshiftfm.mixerqa` and automatically opens a
first-mission mixer, or continues its own prior checkpoint on relaunch. It never
uses the player package or save. Android emulator native swipes and taps verified
3-point clamping, redistribution from [3,0,0] to [2,1,0], unchanged elapsed time
while mixing, and preservation of [2,1,0] after force-stop/relaunch. Logs contain
no script or crash errors. See `emulator-result.json` and the saved checkpoints.

Physical Pixel delivery subsequently passed: version 0.10.5/code 17 installed
in place and launched successfully; both existing saves remained byte-identical
through install and launch. See `pixel-install.json` and `pixel-0105-menu.png`.
The actual player export used the normal Android Debug preset and the unchanged
`org.nightshiftfm.spike` package. Human balance/usability testing remains NOT RUN.
The 0.10.5 source handoff includes this revision; see `docs/NEXT_SESSION.md`.

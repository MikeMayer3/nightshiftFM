# P1 — build identities and graphical connection guidance

2026-09-10. Implemented the first P1 increment using the existing arsenal and
eight connections. **Local source only; not installed, committed or pushed.**
Human assessment of build identity and overall balance remains NOT RUN.

## What changed

Upgrade cards now include a compact illustrated equipment pair and one relevant
connection hint. The hint projects the actual offered choice: missing gear,
missing Marking Pins, readiness after the pick, readiness now, or connected state.
It explicitly tells players to connect through Mixer; selecting an upgrade does
not silently fill a connection slot. New instruments are evaluated at rank 1.

The information view shows equipment diagrams, names, prerequisite states,
activation conditions and tradeoffs for the related connections. Back and alternate
branch controls remain before the longer details. Mixer → Weapon connections uses
the same diagrams for all eight recipes and keeps its explicit Connect controls.
Existing ready/all filters, two slots, discovery, pause and cooldown rules remain.

Readiness uses `PatchboardState.eligible_tracks`, shared with combat's existing
eligibility path. `BuildGuide` projects copied runtime tracks without changing
choices, RNG, stats, faders, or saves. No serialized field or content ID changed.
The UI reuses the approved original hardware illustrations and localized text.

An additional context warning identifies Dead Zone when the projected Net already
has at least that much jam duration, including the current Control fader. Existing
jam cooldowns make this overlap less useful. The warning is based on derived
parameters rather than a hardcoded branch-name assumption.

## The three build identities

| Identity | Existing build route | Strength | Counter/tradeoff |
|---|---|---|---|
| Bass / crowd damage | Studio Monitor + Spring Reverb → Pressure Drop; Tape Deck can enable Double Drop | Bass bonus grows with the number of enemies inside overlapping fields | Spread-out enemies and early pressure before assembling the combo; Bass has shorter reach |
| Net / control | Mixing Desk + Studio Monitor → Dead Zone; Valve Microphone enables Live Wire | Slow a group, jam with Bass, and prepare Charged targets for Arc | Jam-resistant enemies; field overlap and cooldowns; Dead Air can overlap the connection's jam |
| Precision / marks | Turntable → rank-3 Marking Pins + main → Needle Thread; Tape Deck → B-Side | Aim main shots at marks; direct main behavior benefits according to chassis; replays seek marks | Requires the marking branch and targets in reach; Echo does not inherit Needle Thread's bonus |

These are options to assemble through existing recruitment and branch controls,
not new forced presets. A player pursuing Dead Zone should compare the Net's
Interference/Live Current paths with Dead Air rather than assume every control
bonus stacks. Existing rank-3/6/8 choices still carry their authored tradeoffs.

## Measured behavior

`tests/build_mechanisms.gd` exercises the real combat hooks on explicitly staged
targets. This establishes conditional behavior, not campaign difficulty:

| Controlled situation | Measured result |
|---|---|
| One enemy in a Well/Bass overlap | 0.8 Pressure Drop bonus damage |
| Six enemies in the same overlap | 28.8 total bonus damage, 4.8 per target |
| No overlapping Well | Zero Pressure Drop bonus |
| Six Net-slowed ordinary enemies with jam available | 2.7 aggregate added jam seconds; no connection damage |
| No Net slow, or existing jam cooldown | Zero added jam seconds |
| Pulse shot with / without a marked first target | Two / one aligned targets hit |
| Target still in protected Incoming Signals approach | No damage from the three tested connections |

`tests/build_comparison.gd` completed 48 campaigns: three fixed build policies,
missions 1/4 on Standard, mission 8 on Hard, mission 12 on Overload, two seeds,
and paired connected/unconnected runs. Every run used the same fully unlocked
profile context (`cleared=12`) and no modules. This permits all starting chassis
and seven mixer points; it is **not** a fresh-player campaign sample. Precision
uses four Direct points and leaves the remaining points unused; other policies
spend seven. These are deliberately different build policies, not a controlled
single-variable comparison between archetypes. Within each pair, connection use
is the changed policy; changed combat can subsequently change offered choices.

All upgrades were offered picks or legal alternate-branch swaps. New equipment
used normal recruitment. Connections used the paused Mixer rules. Every decision
was JSON-round-tripped and resumed before accepting its choice: **452 restores**.
Each displayed readiness prediction was compared with the actual accepted build.

| Fixed policy | Wins, connections off | Wins, connections on |
|---|---|---|
| Bass: Wideband / Well / Echo | 2 / 8 | 2 / 8 |
| Control: Dead Air / Aftershock / Arc | 1 / 8 | 1 / 8 |
| Precision: Marking Pins / Penetrator / Echo | 4 / 8 | 4 / 8 |

The control policy exposed the jam-overlap issue now explained by the guide.
Connection triggers and contributions were recorded even when the final win/loss
outcome did not change. Precision performs better in this sample; this does not
prove it is universally dominant or that the other builds are balanced. No claim
of improved win rate is made, and no blanket damage/range/health changes were
justified by this guidance increment. P2 should investigate early pressure and
alternative control choices with broader policies before changing balance.

The player-facing improvement in P1 is making the existing distinct mechanisms
discoverable and showing their real conditions and overlap. Additional combat
tuning and human proof of satisfying identities remain explicit follow-up work.

## Files and verification

- `scripts/patchboard/build_guide.gd`: read-only projection and relevant hint order.
- `scripts/patchboard/patchboard_state.gd`: shared eligibility, unchanged semantics.
- `scripts/ui/connection_diagram.gd`: illustrated compact/full connection views.
- `scripts/ui/draft_panel.gd`, `scripts/ui/patchboard_panel.gd`: point-of-choice
  hints and graphical connection catalogue.
- `assets/ui_strings.csv` and imported English translation: concise copy.
- `tests/unit/test_build_guide.gd`: missing capability, recruitment, support cap,
  state transitions, non-mutating previews and derived jam overlap.
- `tests/build_comparison.gd`, `tests/build_mechanisms.gd`,
  `tests/visual_build_guide.gd`: campaign, controlled-mechanism and UI evidence.

With the pinned Godot 4.7.2 binary assigned to `GODOT_BIN`:

```sh
sh tools/godot.sh import
sh tools/godot.sh test
sh tools/godot.sh smoke
python3 tools/check_foundation.py
"$GODOT_BIN" --headless --path . --script res://tests/build_comparison.gd
"$GODOT_BIN" --headless --path . --script res://tests/build_mechanisms.gd
"$GODOT_BIN" --path . --script res://tests/visual_build_guide.gd
git diff --check
```

Evidence: [P1-builds](evidence/P1-builds/), including `comparison.json`,
`mechanisms.json`, logs and screenshots. The comparison's gameplay eligibility
path is unchanged by the later presentation-only jam warning.

Rendered checks cover 360×640, 450×950 and 1024×768 with large text, actual viewport
pointer events on an upgrade diagram and its info button, Connect button signals,
state-dependent disabled controls and horizontal overflow checks. Screenshot
fixtures are explicitly staged and disconnect checkpoint writing; they are not
durable campaign progress. The separate comparison supplies legal restore proof.
An initial fixture incorrectly attempted to save staged progress and displayed a
recovery overlay; the isolated final captures do not. A staged unit Net also needed
the normal `apply_ranks` mixer binding; that fixture was corrected.

Physical-device input, listening, human comprehension and human build preference:
**NOT RUN**. No phone installation or production release is implied by desktop
rendered checks. See the current implementation-status entry for final totals.

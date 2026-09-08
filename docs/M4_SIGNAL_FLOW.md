# M4 revision — kill-driven upgrades

**Current new-run revision:** [Active combat](M4_ACTIVE_COMBAT.md) adds aimed
bursts and grouped pressure. The rules below are retained for `m4.signal.1` saves.

Owner direction, 2026-09-08: longer levels, a bar that fills from kills and grants
an upgrade or new weapon, fewer passive defensive choices, and a radio-tuner
visual treatment later. This revises M4's core loop; it does not begin M5.

## Playable rules

- Ten longer waves: each previous pattern is repeated, with 2.0-second spawn
  intervals on waves 1–3 and 1.85 seconds on waves 4–10. Waves end when all
  scheduled enemies and their remaining threats are resolved, with a two-second
  transition. There is no artificial wait after clearing a wave.
- Each enemy kill fills the **Signal** bar by one. Carrier reinforcements count;
  intercepted shots and enemies that breach do not. The first choice costs five
  kills, then seven, nine, eleven and thirteen. Later choices remain thirteen.
- A full meter pauses combat at the end of the fixed simulation step. Choose one
  upgrade or one new weapon, then resume the same fight. Overflow carries forward;
  a multi-kill can queue another choice. Final victory takes precedence over a
  full meter. There are no three-choice batches at wave end, recruitment windows,
  or fixed 27-pick quota in new missions.
- Up to three distinct eligible cards are shown. At least one new weapon appears
  while one is available. Bass Driver and Static Net share the earned-choice
  pool with upgrades. Acquiring one starts it at rank 1 and spends one choice.
- The initial Pulse, shield and Arc start at rank 1. Shield and its active ability
  remain available, but shield upgrades are excluded from this flow. Main/Arc,
  Bass and Net retain rank-8 limits. New runs reset all power.
- Rerolls, one tuning banish, optional details, and branch comparison remain.
  If all offensive upgrades are exhausted, Overdrive gives +25% weapon damage
  for 20 simulation seconds; repeated choices refresh duration without stacking.
- The bar is a simple functional placeholder. A radio tuner, richer card art and
  final audiovisual feedback are explicitly deferred.

## Offensive support changes

Arc's **Lightning Spear** replaces Shield Tap for new missions: twice base Arc
damage against one target, ignoring 35 armor. Needle Arc trades 15% damage for
30 more armor penetration; Capacitor Strike adds 70% damage with 50% longer
interval. Thunder Needle can pierce up to three distinct aligned targets.
Storm Network retains its crowd-damage branch.

Static Net now deals 3 damage every 0.75 seconds to at most eight enemies per
field tick. Its tuning choices improve damage, area and deployment rate.
**Live Current** replaces Interference Screen: 50% more field damage, 25% smaller
radius and half slow strength. Rapid Current ticks every 0.5 seconds at 75%
damage; Surge Current doubles tick damage with a 1.25-second interval. Live
Broadcast adds 50% damage and one second of field duration. Dead Air retains
control alongside the new baseline damage. Bass keeps its area/exposure paths.

## Saves and compatibility

New missions use content `m4.signal.1` and run schema 2 within the existing atomic
profile/run envelope. Continue preserves `m3.1` and `m4.1` content and behavior;
existing saves are not silently converted. Start **New mission · Standard** to
play this revision. The app ID and save path remain unchanged.

Checkpoints occur at wave starts, earned choices, rerolls/banishes/branch swaps,
accepted choices, cleared waves and results. New mid-wave checkpoints include
live enemies, projectiles, statuses, Net fields, Bass shocks, timers, contribution,
RNG, accepted choices and meter progress. JSON writes preserve full floating-point
precision. Force-stop replays from the latest checkpoint; it does not resume an
arbitrary unsaved frame. Pausing a live process freezes and resumes in place.
Kills since the checkpoint are discarded together with their signal and actors,
so they cannot be counted twice. Results and rewards retain the atomic commit.

## Balance evidence

`docs/evidence/M4-signal/balance.json` contains 15 automated runs: main, Arc,
Bass, Net and random preference policies, each with seeds 11, 42 and 91. No active
brace or manual aiming was used. All twelve focused-build runs won; one of three
random runs won. Completed runs lasted 504–545 simulation seconds (8.4–9.1
minutes), with 22–25 earned choices. The first choice appeared around 10.6 seconds.
Wave length and choice intervals exclude time spent reading upgrade cards.

Several focused builds finish without damage; the goal here is longer encounters
and useful offensive decisions, not forced damage to justify defensive cards.
These probes reveal pacing and weak builds; they do not certify human difficulty,
fun, or balance across every branch. Prior owner-positive playtesting predates
this revision. The next art pass remains separate.

## Reproduction

Use pinned Godot 4.7.2 standard / Compatibility. Run
`python3 tools/generate_signal_content.py`, import, `sh tools/godot.sh test`, and
`python3 tools/check_foundation.py`. `tests/visual_signal.gd` renders actual
meter/choice/detail scenes, including 360×640, using an isolated save file.
Detailed commands and phone evidence are recorded in `IMPLEMENTATION_STATUS.md`.

# M5 — Six-family arsenal

M5 was explicitly authorized by the owner after the M4.5 handoff. This advances
implementation; it does not certify the outstanding M4 multi-person human gate.
M6 connections and M7 campaign unlocks are not included.

## Playing this build

Choose **New mission**, select a main weapon, shield and starting support, then
**Go live**. All equipment starts at rank 1. These are M5 playtest selections:
all chassis/families are exposed without pretending campaign unlocks exist.

The ten-wave mission, kill-earned Signal meter, drag-to-aim/release Burst, large
battlefield and support cooldown turrets remain. Earned choices can recruit any
unequipped support until five are equipped; main and shield have separate slots.
One optional shield card appears every fourth decision when available. The other
choices emphasize offense. Specializations and their modifiers can be compared
and exchanged through the card's **i** panel without spending a reroll.

The small Shield button activates the chosen chassis: Capacitor grants temporary
overshield, Relay restarts recharge and repairs some shield, and Feedback briefly
reflects incoming enemy projectiles. The Burst button remains the aimed area attack.

## Content and mechanics

`tools/generate_arsenal_content.py` authors 12 immutable tracks and 216 upgrade
resources. Each track has six stack-limited tunings, three rank-3 specializations,
two rank-6 alternatives per specialization, and one rank-8 cap per specialization.
That is **108 support options and 108 main/shield options**. Tunings modify base
coefficients additively; the comparison view displays resulting runtime values.
Saturated tunings are removed from eligibility when they no longer change output.

| Equipment | Runtime role |
|---|---|
| Pulse Spindle | Precision contacts, armor penetration, ricochets or heavy charged shots |
| Sweep Laser | Frequent beam packets with bounded aligned contacts; no unused projectile-count tuning |
| Burst Rack | Shorter-range multi-contact volleys, focused/scattered coverage or timed stagger packets |
| Arc Aerial | Chains, aligned armor-piercing spear, or limited shield restoration/reservoir |
| Bass Driver | Area damage, displacement and armor exposure; wide/heavy/persistent pulse variants |
| Static Net | Slow/jam, projectile interception, or damage-focused Live Current |
| Echo Deck | Replays primary packets; frequent repeats, stored sequences or alternate-target chorus |
| Needle Swarm | Traveling, steerable projectiles; piercing, homing or bounded vulnerability marks |
| Reverb Well | Pull/control zones, terminal implosions or orbit/release impulses |

The owner's offensive preference overrides the catalog's Net healing branch:
**Live Current** remains the third Net path instead of Grounding Grid. Shield Tap
and shield chassis remain optional defensive choices. Placeholder cones/shockwaves
use simple bounded area pulses; their final visual treatment remains art work.

## Attack and save contracts

Primary Pulse, beam and volley attacks have distinct packet kinds. Echo keeps the
originating attack root, uses source `echo_deck`, generation depth 1 and no eligible
recursive triggers. Layered Recording stores up to 12 prior primary packets and
replays a bounded sequence of their original roots. Chorus retargets away from the
original victim when alternatives exist. Manual Burst is excluded from echo
eligibility. Reflection retains the incoming projectile root and cannot reflect
or restore itself. Marks increase allied damage by at most 50%; elite slow remains
capped at 25%, with existing jam/displacement immunity fallbacks.

Needles hit each actor at most once per projectile, expire within their authored
lifetime and leave the arena. Effects have explicit target, pierce, lifetime and
queue bounds. A producer waits for pending capacity rather than discarding a
created damaging attack. Shield charge and reservoirs are capped. No patchboard
synergies or recursive proc system are enabled.

New missions use content version `m5.1`. Existing `m3.1`, `m4.1`, `m4.signal.1`,
`m4.active.1` and `m4.active.2` runs retain their original rules. M5 checkpoints
include loadout, legitimate upgrade history, RNG streams, actors/statuses,
traveling needles, recorded/pending replays, zones, marks and shield state.
Validation rejects unknown effect kinds/parameters, invalid loadouts, duplicate
families, oversized queues and invalid numeric/root/target bounds. Decision saves
retain earned kills and outstanding effects; restart begins a fresh rank-1 run.
JSON roundtrips allow floating-point representation tolerance, not a promise of
cross-device bit-identical replay.

## Verification

From the repository root, with the pinned Godot 4.7.2 standard editor:

```sh
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
sh tools/godot.sh import
sh tools/godot.sh test
python3 tools/check_foundation.py
sh tools/godot.sh smoke
"$GODOT_BIN" --headless --path . --script res://tests/arsenal_effect_matrix.gd
"$GODOT_BIN" --headless --path . --script res://tests/arsenal_balance.gd
"$GODOT_BIN" --headless --path . --script res://tests/arsenal_balance.gd -- --idle
"$GODOT_BIN" --headless --path . --script res://tests/arsenal_stress.gd
"$GODOT_BIN" --path . --script res://tests/visual_arsenal.gd
```

The effect matrix exercises actual damage events, actors/statuses, movement,
projectile interception, shield effects and timed replay results in controlled
layouts. It includes spaced/aligned/armored/elite/projectile formations and a
controlled critical-roll case; it does not just compare upgrade descriptions.
All 216 effect cases passed. All 72 branch/modifier paths are replayed through rank-8 serialized draft saves.
The unit mission repeatedly restores actual mid-wave decision checkpoints.

Final random-policy simulations use seeds 1, 11 and 42 for every main/support
pair (54 runs), a separate upgrade RNG and a half-second input cadence. **49/54
win**: Pulse 15/18, Sweep 18/18, Burst 16/18. An additional 18 idle runs (seed 11,
all main/support combinations) produced **0 wins**. These are policy results, not
human win rates. Sweep remains the strongest sampled chassis; the small sample
is a balance baseline, not proof that all branches are equal.

Initial coefficients won only 13/54: Pulse 1/18, Sweep 10/18, Burst 2/18. Raising
Pulse/Burst baseline output, restoring Bass cadence, strengthening starting Echo
and Needles, and giving Pulse a useful extra-contact tuning improved viability.
The initial and intermediate results are retained in `docs/evidence/M5/`.

The all-weapons stress matrix uses every legal five-of-six combination at rank 8
across all three branches (18 fixtures, 30 simulated seconds each). The latest run
peaked at 18 pending effects. Worst fixture CPU time was about 153 ms for 1,800
fixed steps on this Mac. This isolates simulation cost; it is not Android frame
performance. Exact event counts, timing and contributions are in `stress.json`.

Android testing uses an isolated QA package with source hashes and a read-only
observer. The host sends actual ADB taps at normal game speed, using measured
SurfaceView bounds; every accepted upgrade is audited against its sampled offer.
There are no direct purchase calls, time scaling, checkpoint retries or rerolls
in the full-run policy. QA seed/loadout files do not touch the regular app's saves.

The long-running AVD initially deteriorated from ~16 FPS to 1–2 FPS. Two attempts
were interrupted and retained, not counted as completed balance samples. Lowering
resolution alone did not recover it. A cold boot with `-gpu host` restored roughly
50–60 FPS at a 720×1600 display override. The full run won with 31 audited random choices, 611 kills and 111 bursts in
639.15 simulated seconds (657.23 wall seconds), median 60 FPS. The regular APK
also passed actual equipment selection, Pause/Resume, shield activation and saved
draft recovery after force-stop/in-place installation; Restart retained the chosen
chassis at rank 1. Display overrides were subsequently reset. Details are recorded in `IMPLEMENTATION_STATUS.md` and the evidence directory.

Human focused/control/defensive build acceptance, final art/audio, physical-phone
M5 testing and iOS testing remain **NOT RUN**. This is a playable M5 implementation,
not human acceptance or a store release.

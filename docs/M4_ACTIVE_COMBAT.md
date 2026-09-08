# M4 active combat revision

Current update: [support turrets and random-build balance](M4_SUPPORT_TURRETS.md),
Android 0.4.3/code 7. Earlier M4.4 evidence below is retained as historical.

Owner feedback (2026-09-08): the kill-meter build was passive enough to leave
unattended between upgrades; expand the battlefield and remove its bottom text.
This revision keeps the fixed transmitter and adds a useful aimed attack. It
stays within M4 and preserves the kill-driven upgrade flow.

## Controls and screen

- Automatic weapons continue firing. Press/drag within the battlefield to direct
  them and preview a burst area. Release inside the field to fire **Burst**.
- Burst damages up to eight targets within 110 world units, ignores 55 armor,
  interrupts surviving shooters for up to 0.6 seconds (elite resistance applies),
  and can destroy enemy shots. Damage is `45 + 3.25 × earned choices` in new runs (`3 ×` in legacy active runs), so support
  builds gain the same active-attack scaling as main-gun builds. Cooldown is five
  simulation seconds. Empty-ground and outside-field releases cost nothing.
- The large Burst button fires at the current target for a simpler input option.
  The existing keyboard ability binding does the same. Pause, upgrade choices,
  backgrounding and results block burst input; pause also freezes recharge.
- Remove the persistent legend, equipment explanation and shield tutorial below
  combat. Controls/checkpoint instructions live in Pause. The main action in new
  runs is offensive Burst; the baseline shield remains passive protection.
- The battlefield fills its layout rectangle; tall phones use their available
  height instead of the old portrait letterbox. Enemy silhouettes remain round.
  Pointer coordinates and effects map back to the same 640×720 simulation world,
  so device aspect ratio does not change travel times or attack reach.

## Pressure and pacing

The active encounter schedule groups five threats around a seeded formation
center every six seconds, with additional groups to retain longer waves. Enemy
health is `base × (2.0 + 0.12 × (wave - 1))`. Carrier children remain their normal
reinforcements. The final wave contains four Overseers rather than eight copied
elite encounters. New `m4.active.2` runs introduce two Overseers in wave 8,
replacing two with plated enemies while retaining all 40 enemies and the same
formation timing. Legacy active runs keep four in wave 8. Automatic fire has time to hurt a formation, but idle play
cannot reliably clear the incoming volume before the next threats arrive.

Signal still grows only from enemy kills. This denser flow uses costs of
6/9/12/15/18/21 kills and then stays at 21. Overflow, offensive upgrades, new
weapons, the rank cap and bounded Overdrive fallback remain. A burst finishes all
its hits before an upgrade screen opens. Radio-tuner and richer combat art remain
for the later art pass.

New missions use the active rules. New runs use `m4.active.2`. Existing `m3.1`, `m4.1`, `m4.signal.1` and `m4.active.1` saves
retain their original gameplay when continued. The app ID/save file stay the same.
Active snapshots also preserve Burst cooldown, use count and damage; reconstruction
retains the full actor/effect/meter snapshot and full-precision JSON behavior.
Burst damage is a subset of Pulse damage in the contribution report, not an
additional source to add to the total.

## Verification and balance limits

`tests/active_balance.gd` runs four upgrade preferences (main, Arc, Bass, Net),
three seeds (11, 42, 91), and three combat-input policies: 36 complete simulations.

| Combat input | Wins | Observation |
|---|---:|---|
| Idle; choose upgrades only | 0/12 | Lost on wave 2 or 3 |
| Press Burst on cooldown at the automatic target | 3/12 | Useful but often hits the edge of a formation |
| Aim bursts at clusters and urgent threats | 9/12 | All four build preferences produced wins |

Aimed wins took 624–663 simulation seconds (10.4–11.1 minutes), excluding upgrade
reading. Some wins were close; three aimed builds still lost. The targeting
policy can inspect exact simulation positions, so these results demonstrate
mechanical value, not a measured human win rate or a claim that fun is solved.
Current owner feedback predates this revision; human acceptance is NOT RUN.

The unit/scene suites cover formed spawns, burst damage/caps, enemy interruption,
cooldown, pause, overflow, old-save compatibility, invalid values, active-save
round trips, actual aim/release/outside-release input mapping, the button fallback,
and the expanded text-free battlefield. `tests/visual_active.gd` renders the real
scene at 450×800, 360×640 and 450×950 using an isolated save.

Reproduce with pinned Godot 4.7.2 standard / Compatibility:

```sh
python3 tools/generate_active_content.py
sh tools/godot.sh import
sh tools/godot.sh test
python3 tools/check_foundation.py
"$GODOT_BIN" --headless --path . --script res://tests/active_balance.gd
"$GODOT_BIN" --path . --script res://tests/visual_active.gd
sh tools/godot.sh smoke
sh tools/godot.sh android-debug
```

The original active revision was Android 0.4.2/code 6. Export APKs sequentially: this Godot toolchain shares
temporary export filenames. See `IMPLEMENTATION_STATUS.md` for actual delivery
and physical-device checks. No commit, push or publication is part of this revision.

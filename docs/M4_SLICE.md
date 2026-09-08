# M4 — three-support slice

**Current new-run rules:** [M4 Signal flow](M4_SIGNAL_FLOW.md) supersedes the
progression schedule and defensive branches below. This document records the
original `m4.1` rules, retained for existing saves.

The original M4 missions use the Standard ten-wave slice. The engine remains pinned to
Godot 4.7.2 standard / Compatibility. There is no new dependency or final art.
The M3 content catalog is retained for existing saved runs; M4 uses content
version `m4.1`, with the same versioned atomic profile/run envelope.

## Content and behavior

Three support families each expose three tuning options, two rank-3 branches,
two modifiers per branch at rank 6, and a matching rank-8 capstone: **33 support
options**. Main/shield retain their 12 M3 options. Every card has a real effect.
The third branch and three remaining families remain deferred to M5.

`tools/generate_m4_content.py` reproduces the immutable resources and card text
under `content/m4/`. Baseline statistics and exact effect text live there.
Branch behavior is implemented in `scripts/combat/support_combat.gd`.

| Family | Damage / control branch | Contrasting branch |
|---|---|---|
| Arc | Storm Network: 4 contacts at 80% damage; Long Route adds 120 range and 20% interval, Tight Circuit adds 35% damage and loses 40% range; capstone branches to at most 6 contacts | Shield Tap: 1 contact at 60% damage; direct hits restore 2 shield with 0.8s cooldown. Quick Charge uses 70% interval and 1.5 healing; Reserve Charge stores up to 12 for brace. Full reservoir plus capstone grants 10 overshield for 4s |
| Bass | Wideband: 140% radius and 80% damage. Wide Cone scales width ×1.5 / depth ×0.65; Deep Cone scales width ×0.7 / depth ×1.6. Capstone travels upward at 400 units/s for 234 or 576 units, hitting at most 12 distinct enemies | Compression: 65% radius, 150% damage, +25 exposure. Hard Clip adds 25 exposure and 25% interval; Direct Injection adds 50% elite damage and halves push. Capstone adds 50% damage and 20 exposure; at most 8 targets |
| Net | Dead Air: +15 percentage points slow, 0.35s jam. Blank Channel uses 0.7s jam and 125% interval; Low Hum adds 1.5s field duration and uses 0.15s jam. Capstone adds 1s field and 0.25s jam | Interference Screen: half slow, +3 interception charges. Dense Mesh adds 3 charges and reduces radius 25%; Wide Mesh adds 40% radius and loses 1 charge. Capstone gives a total 12-shot budget and +1s field |

One active Net field replaces the previous field, including its remaining budget.
It never refills or extends itself. Bass shockwaves have finite travel and hit-once
tracking. Chain hit lists are distinct per root attack. No generated hit recursively
fires another support. Shield gains count only effective restoration. Reservoir
accumulation is not reported as healing before it is released.

## Status and elite rules

- Charged: at most 3 stacks, refreshed to 3 seconds; each adds 5% Arc damage.
- Slowed: strongest active effect wins; 60% ordinary cap, 25% elite cap; expires
  0.6s after leaving a Net. Report uses movement-time prevented, not raw uptime.
- Exposed: at most 100 armor reduction for 3 seconds. Effective armor floors at
  zero; damage is multiplied by `100 / (100 + effective armor)`.
- Jammed: at most 1s ordinary / 0.2s elite interruption. Reapplication cooldown
  is 2s ordinary / 4s elite. Immune and cooldown-limited targets retain a 20%
  ability-speed reduction while affected. No permanent stun lock.
- Knockback: elites receive 25% displacement, clamped to the arena spawn edge.
  Displacement-immune fixtures instead receive a 15% slow attributed to Bass.
- A shield break occurs only when positive ordinary shield reaches zero. Extra
  hits against empty shield do not retrigger it. Overshield absorbs first.

Marked and unrelated support/synergy behaviors are outside this slice.
Actors own status state, which is cleared with the wave and never mutates resources.
Pausing freezes status, support timers, field budgets, damage and contribution.

## Mission and reports

Ten ordered patterns teach armored ranged carriers on wave 3 and introduce the
Overseer on wave 8 before its wave-10 elite finale. Existing swarmer/diver/carrier
paths remain readable; enemies have bounded ability/projectile counts. Armor and
health are explicit data; health scales by 8% per wave after the first. Purple
charge dots, blue slow arcs, orange exposure marks, jam crosses, red shot-warning
rings, moving Bass waves and Net grids communicate effects without sound.

Reports record effective enemy damage, movement-time prevented, push distance,
interceptions, healing, exposure assistance, absorbed shield and true breaks.
Exposure assistance is an attribution subset of damage, not additional damage.
Report totals, independent RNG, support cooldowns and Arc reservoir/overshield
are checkpointed. A killed process replays the wave start and discards partial
wave contribution; a live paused process resumes in place.

M3 profile unlocks are extended to the three-family starting pool only when a
new M4 mission begins. Existing M3 saves retain their exact rank definitions,
offers and rules when continued. No permanent combat power is added.

## Current acceptance limit

The automated damage/exposure and control/defense scripts both win the same
Standard patterns and seed with exactly 27 normal choices. Their choices,
boundaries and full contribution are in `docs/evidence/M4/simulated-builds.json`.
They are regression/balance probes, not human wins. The current runs are short
and generous; the intended 8–12 minute pacing and fun are not certified.

The owner has reported positive M4 playtesting and assigned balance to Codex;
remaining concerns are intended for later art work. See `M4_PLAYTEST.md` for that
feedback and the still-unverified three-testers/two-attempts sample. **M5 must
wait for that gameplay gate.** Final art, release signing, iOS and publication
remain outside this implementation.

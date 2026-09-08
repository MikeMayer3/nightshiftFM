# M3 — upgrades and checkpoints

Launch with `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh run`.
Choose **New mission · Ten waves**, or **Continue saved mission** to resume.
The Android build is `builds/android/nightshift-m3.apk` (debug, ARM64).

Each mission starts with rank-1 Pulse Transmitter, Capacitor and Arc Aerial,
two shared rerolls and one banish. Waves 1–9 each grant three sequential normal
selections: exactly 27 before wave 10. Wave 10 goes directly to results.
Before waves 2/4/6/8, a separate arsenal window allows recruitment or a decline
for one existing-support upgrade. Only Arc is implemented in M3, so the playable
window offers decline; extra families exist only in tests. A normal draft cannot
recruit or buy slots. Main and shield remain independent of the five-support cap.

## Cards and combat

Each track has three common tuning options and one implemented branch path:

| Track | Rank 3 | Rank 6 | Rank 8 |
|---|---|---|---|
| Pulse | Ricochet: +1 distinct target, −2 damage per hit | Long rebound: +160 jump range, +0.08 seconds between attacks | Broadcast burst: +2 targets (four maximum) |
| Capacitor | Bastion: +2 seconds brace, +2 seconds cooldown | Live coil: +6 shield/second during brace, −0.5 ordinary recharge/second | Night reserve: +30 capacity, −4 seconds cooldown |
| Arc Aerial | Storm Network: +2 targets, −1 damage per hit | Long Route: +120 jump range, +0.2 seconds between attacks | Broadcast Storm: +2 targets (six maximum), can branch from prior contacts |

Ranks 2/4/5/7 take common tuning. Ranks 3/6/8 include the required branch in the
same paid selection. Cards show an equipment icon, short effect and current/next rank. Tap the card
to select it. The **i** button opens full numerical changes, prerequisites and
the implemented branch path without spending a choice. The headline refers to
the current wave; the mission-wide 1/27 counter is no longer displayed.
Each common has a four-pick cap in this small M3 catalog. These provisional
coefficients are not the complete catalog's final balance or six-card tuning set.
All 18 exposed cards apply effects; M4/M5 will add the remaining authored paths.

Pulse uses cyan rebound lines; Arc uses purple chains. Every attack visits a
bounded set of distinct targets, and each target can take damage once per root.
Live coil heals even during the normal post-hit recharge delay. Added capacity
never grants an instant refill. The HUD reflects current shield capacity and
brace duration/cooldown. These are original geometric placeholders.

Draft allocation reserves main/shield after two missed eligible normal screens,
then serves supports absent for four screens, oldest first. Remaining slots use
the draft RNG. Bonus screens do not advance quota debt. Rerolls retain allocated
tracks and prefer different options; a sole mandatory option can remain.
Banish removes a common option for this mission and redraws offers; mandatory
branches cannot be banished. Tap **Banish**, then an eligible card, or **Cancel**
to return without spending a token. All three cards and both actions fit the
360 × 640 preview; the action explanation is available on demand.
The allocator shows fewer than three cards when necessary. When eligible tracks
are maxed, choices become **up to 10 hull repair** or **up to 15 shield refill**;
they still consume the normal/bonus selection without increasing ranks.

## Recovery contract

`user://m3_mission.json` holds an atomic envelope containing independently
versioned profile and run data. On this Mac, `user://` maps to
`~/Library/Application Support/NightshiftFM/`. Android uses the app-private files
directory. Saves are local, offline, and are not synchronized through GitHub.

Writes validate, flush and verify `.tmp`, rotate only a valid primary to `.bak`,
then rename the temporary file. Load tries primary, recoverable temporary, then
backup. Invalid IDs, impossible rank histories, numeric ranges, future schemas,
and incompatible content/engine versions are rejected. If none is valid, the UI
provides Retry or an explicit fresh-save action. Write failure freezes gameplay
and retries the exact pending checkpoint. There were no pre-M3 mission saves to
migrate; the M1 diagnostic JSON is a separate file and remains untouched. Unknown
schemas are rejected safely; no fabricated legacy migration is claimed.

Checkpoints are written at initial setup, wave start, resolved wave completion,
every accepted card, reroll/banish, recruitment choice, and results. Closing
mid-wave replays that wave from its saved start. Actors and uncommitted partial-
wave counters are discarded; committed health, timers, rank histories, selection
counts, offers and stream states are reconstructed. Returning to the menu also
uses this checkpoint contract. Backgrounding a live process freezes it in place.

Wave, draft, combat-effects and cosmetic RNG streams are separate. Seed/state
values are decimal strings to preserve signed 64-bit precision through JSON.
The current combat fixture has no random procs; that stream is reserved and
persisted. Content version and engine version gate recovery. Replay guarantees
are within the pinned build, not cross-platform physics equivalence.

Victory records one local completion keyed by run ID. Profile and results are
committed together, so repeated results reloads cannot grant it twice. The
profile contains unlocked IDs and completion records, with no permanent combat
bonuses. New missions reset all ranks, stats, temporary modifiers, tokens and
support acquisitions. This completion record is M3's minimal reward transaction,
not the M7 campaign unlock or M9 achievement system.

## Reproduction and human check

```sh
export GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
sh tools/godot.sh import
sh tools/godot.sh test
sh tools/godot.sh smoke
python3 tools/check_foundation.py
"$GODOT_BIN" --path . --script res://tests/visual_m3.gd
# Isolated desktop draft for interaction; does not touch the player's mission:
"$GODOT_BIN" --path . --script res://tests/visual_m3.gd -- --interactive
```

Tests include 10,800 seeded drafts with a production-only and mock six-family
catalog, real disk corruption/recovery, every exposed effect, complete M3 mission
and scene-button recovery. The M2 three-wave mission remains the default for
`CombatSession.new()` and the isolated combat scene; the boot menu enables M3.
This preserves the M2 regression fixtures without exposing two conflicting
mission modes to players.

For human acceptance, read all three cards on the smallest intended phone;
open a card’s details, use reroll and banish, choose a branch, and explain the
tradeoff.
Force-stop during a wave and during a draft, then Continue. Confirm the former
replays the wave and the latter preserves offers. Complete a run and restart;
confirm ranks reset. Automated or ADB input is not human playtest approval.

The ten-wave schedule currently repeats the three M2 patterns with increasing
initial enemy hull. It is a short progression/checkpoint fixture, not the final
8–12-minute authored mission or an M4 fun/balance acceptance claim. M3 does not
add other support families, synergies, campaign unlocks, native achievements,
final art production, or iOS work. Equipment icons are original SVG placeholders.

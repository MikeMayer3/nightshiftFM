# P2 — loss feedback and balance evidence

Owner feedback after this delivery: "it looks good on my testing" (2026-09-10).
This is positive owner testing feedback; unfamiliar-player comprehension remains
a separate gate.

Implemented 2026-09-10 for Android 0.10.7 (versionCode 19). This increment adds
useful defeat feedback and comparisons; it does **not** change combat values.

## Player-facing behavior

The defeat screen leads with the source of most **health lost after shields**:
breaches or projectiles. A tie/mixed history gets a neutral explanation. It gives
a short suggested response and a one-tap Retry broadcast button. The existing
contribution report now shows health-loss bars and illustrated equipment damage
bars. Back to results is also at the top, so returning does not require scrolling.
The result still displays the correct module-adjusted maximum health.

Descriptions reflect recorded effective health damage, not the final attacker,
attempted damage, shield absorption, or overkill. No claim about fast enemies,
missed inputs, or poor build choices is inferred. Equipment damage uses the
existing effective contribution totals; assistance and Burst subtotals are not
added again. Control and shield metrics retain their existing units.

## Persistence

`AchievementRun.broadcast.loss_history` is an optional version-1 extension within
the existing checkpoint history. It stores breach/projectile/other health damage
and a completeness flag. Validation rejects unknown versions, malformed fields,
negative/nonfinite values, and totals exceeding recorded health damage. Numeric
values are normalized on restore. Existing nine-field broadcast histories migrate
with `complete=false`; they never invent earlier damage. Re-saving preserves that
flag. A fresh run resets the history and temporary combat state.

The result uses a neutral fallback if the history is missing, incomplete, empty,
or does not reconcile with total health damage. JSON round trips use approximate
numeric comparison where serialization changes insignificant float digits.

## Matched legal comparisons

`tests/loss_comparison.gd` runs 48 campaigns: missions 1, 6 and 12 on normal and
mission 12 on difficulty 2, seeds 11 and 42. Every run starts at rank one with
Pulse/Capacitor/Needle, no modules, and the same fully unlocked `cleared=12`
context. Decisions use actual offers, legal branch swaps and explicit eligible
connections. There are 630 JSON decision restores plus final-result restores.

| Policy | Wins / 8 | Total breaches across 8 runs |
| --- | ---: | ---: |
| Coherent marking/echo build | 6 | 96 |
| Defensive-first weak-offense policy | 6 | 189 |
| Mixed offered choices | 6 | 101 |
| Coherent, shield button unused | 6 | 96 |
| Coherent, focus unused | 6 | 56 |
| Coherent, mixer unused | 4 | 203 |

Overall: **34 victories / 14 defeats**. All policies lost both difficulty-2 runs.
The seven-point mixer changed outcomes versus its zero-point comparison. The
mark-seeking focus policy changed breaches and was worse than automatic targeting
in these fixtures: blindly chasing marks is not established as a good strategy.
The low-shield activation policy did not change these full-run outcomes or
absorption totals. A separate identical-hit check demonstrates actual shield
utility: a timed Capacitor boost prevents the 9 health damage that the unboosted
station takes, recording 19 effective absorption exactly once.

These are fixed policies with full unlocks, **not fresh-player win-rate estimates**.
The defensive policy is intentionally weak in offensive prioritization, not proven
to be universally bad; its shield investment can compensate on normal. The sample
shows the higher-difficulty boundary needs human evaluation, but does not isolate
a specific numerical defect. No global health/damage increase was applied. Early
fresh-player pacing, optimal strategies, and unfamiliar-player loss comprehension
remain open. Existing off-screen spawning, entry protection, warning cues, weapon
reach and shield/focus counterplay are unchanged.

## Verification

Evidence: [P2-losses](evidence/P2-losses/).

- PASS: pinned Godot 4.7.2 import; 5,644 regression checks / 0 failures.
- PASS: 48 legal comparisons, 2,860 checks / 0 failures, including restored
  victory/defeat explanations and reconciled damage categories.
- PASS: 27 native rendered/input checks with large text at 360×640, 450×950 and
  1024×768. Screenshots inspected for loss/report/equipment layouts. Actual report,
  Back and Retry input paths exercised; no horizontal report overflow.
- PASS: seven foundation checks, startup smoke and Android debug export.
- PASS: actual pre-update phone mission save accepted by `MissionStore.valid`.
- PASS: Pixel 10 Pro XL updated to 0.10.7/code 19 and launched in foreground;
  all six save/settings hashes unchanged after install and launch, no captured
  runtime errors. Evidence: `pixel-install.json` and `pixel-launch.png`.
- NOT RUN: unfamiliar-player loss comprehension, human balance acceptance,
  production signing or store submission.

Commands (from repository root):

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh import
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh test
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh smoke
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/loss_comparison.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/visual_loss_feedback.gd
python3 tools/check_foundation.py
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh android-debug
```

Changed: `AchievementRun`, `PostRunAnalysis`, station-hit bookkeeping,
`CombatScreen`, existing `DraftPanel` report, localized strings, Android version,
regression tests/runner, comparison and visual drivers, and handoff documentation.
Prior local P1, splash, battlefield, meters and shield presentation work is retained
and included in this Android candidate. Source remains local, uncommitted/unpushed.
P3 (first-session teaching and phone reliability) is next; it has not been started.

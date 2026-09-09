# M9 started: local achievements and report history

The owner authorized pushing the current source and starting M9 before M8 is
complete. The pre-M9 work was committed and pushed to private
`MikeMayer3/nightshiftFM`, `main`, at
`668d7e01a29e88d732399417cd0f1a415980d1c4`. Remote `refs/heads/main` and local
HEAD matched. This M9 increment is subsequent local work, not part of that push.
M8's remaining encounters, bosses, difficulties and Contracts are still open.

## Implemented increment

All 48 approved achievement definitions are generated from `CONTENT_CATALOG.md`
into validated immutable Resources. Each declares its stable ID, localization,
category, progress kind, threshold, condition/parameters, intended eligible
modes, minimum difficulty and stable cosmetic reward ID. Native IDs remain empty.

Twenty-five conditions are implemented for completed authored Standard campaign
missions: First Broadcast, all twelve support-capstone achievements, eight build
achievements, No Scratches, Unbroken, Second Wind and Close Call. The remaining
23 entries explain that they are pending. They cannot grant progress or be
tracked, and their positive progress is rejected during profile restoration.
Capstone definitions declare their eventual Campaign/Contract/Endless support;
only Campaign integration is implemented in this increment.

Campaign → Achievements displays descriptions, progress, earned status and
pending explanations. Up to three unfinished available goals can be tracked.
An earned achievement grants a unique cosmetic title; selecting it displays the
title on the campaign screen. Rewards, title selection and goals persist in the
same atomic local profile. No reward changes combat power.

The contribution report now includes cumulative hull damage and maximum
simultaneous supports. Effective damage combines actual weapon and recipe
damage once; Burst subtotals and exposure/connection assistance are not added
again. Existing cause-of-defeat, support, shield and connection reports remain.

## Eligibility and persistence

- Actual victory completion, complete run history and an authored mission are
  required. Prototype missions 4–12 cannot qualify in their current state.
- Editor, debug and `qa` builds do not earn achievements. Resuming a production
  checkpoint in the debug/editor UI disables eligibility for that continuation.
  The existing debug APK is therefore not a production achievement test.
- Run history keeps cumulative **hull** damage separately from shield absorption,
  peak simultaneous supports, a true shield-break flag, recovery to full current
  shield capacity and completion provenance. Healing does not erase damage.
- Campaign checkpoint schema 3 carries that history; schema 2 continues without
  inventing history or rewards. Content version and original encounter rules
  are preserved. New profile schema 4 reads profile schemas 1–3, preserving
  progression and starting achievements empty. Old records cannot prove all
  achievement eligibility conditions, so no retroactive rewards are fabricated.
- Only the existing idempotent mission-victory commit updates achievement
  progress. Snapshot rollback restores run-local history; repeated result commits
  cannot duplicate rewards. Distinct capstones/recipes/support families use sets.
- `AchievementPlatform` is an explicit unavailable/no-op native boundary. Local
  saves and rewards need no account or network. Native synchronization is M11.

## Validation and reproduction

From the project directory, using Godot `4.7.2.stable.official.ed1daf0bf`:

```sh
python3 tools/generate_achievement_content.py
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/achievement_checks.gd
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh test
python3 tools/check_foundation.py
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh smoke
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --script res://tests/achievement_playthrough.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/visual_achievements.gd
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot python3 tools/check_encounter_fresh.py --milestone M9
```

| Check | Result |
|---|---|
| Pinned import and desktop smoke | PASS |
| Targeted achievements | PASS — 173 checks, zero failures |
| Full regression | PASS — 4,499 checks, zero failures |
| Catalog/evaluator coverage | PASS — 48 valid definitions; positive and negative fixtures for each of 25 implemented conditions; disabled/rejected-progress fixtures for 23 pending entries |
| Foundation | PASS — seven checks |
| Three full campaign simulations | PASS — three victories, 74 restored-and-continued decision checkpoints, persisted rewards |
| Viewport interaction/layout | PASS — 36 checks at 360×640, 450×800 and 450×950 |
| Clean-copy generators/import/regression/smoke | PASS — identical generated content; 4,499 checks, zero failures |
| Production exported-build eligibility / native mobile | NOT RUN |
| Human achievement UX, pacing, Endless wave 20/40/60 | NOT RUN |

The full-run driver deliberately injects eligible provenance into an isolated
test session running in the editor executable. This exercises real legal
upgrade choices, combat, checkpoint continuation and reward commits; it is not
evidence of production-build eligibility, earned player achievements or human
playtesting. UI title screenshots use labeled earned-progress fixtures. Tests
use separate `user://m9_*` paths, not the player's mission save.

Evidence is in `docs/evidence/M9/`, including per-run choices/rewards and viewport
screenshots. The initial regression pass exposed a JSON numeric-type mismatch
in a schema membership check; replacing it with numeric/integer validation
restored schema-2 compatibility. Final tests include that round-trip boundary.

## Changed components and remaining M9 scope

Added `scripts/achievements/`, `AchievementPlatform`, 48 achievement Resources,
the catalog generator, focused checks, full-run and visual drivers. Extended
AchievementDefinition, CombatSession, SignalSnapshot, MissionProfile,
CampaignPanel, DraftPanel, localization, the test runner and fresh-copy checker.
Earlier migration fixtures and the foundation resource count were updated.
No new dependency, native API, account service or permanent combat stat was added.

M9 remains **in progress**. Remaining work includes Endless mode and its exact
recruitment/draft/consumable schedule, wave scoring and commit rules; cumulative
defensive-event attribution for Bouncer/Hold the Line; the other 21 pending
content/mode conditions; fuller tracked-goal presentation; and production/mobile
validation. Complete the outstanding M8 content required by those conditions.
Do not describe placeholder campaign progression as full campaign acceptance,
or this catalog as all 48 achievements being implemented. M10 has not started.

No M9 APK was exported or installed, and no M9 source was pushed in this turn.

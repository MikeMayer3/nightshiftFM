# Implementation status

Evidence revision: **M6 — patchboard selection foundation**
Date: **2026-09-08** (America/Chicago)
Request: **Start the next milestone**.
Outcome: **M6 STARTED; source-only first increment. NOT ACCEPTED.**

## Basis and scope

The connected GitHub `main` at `36b47cc8d78af28447e09ef1575cb8fa739aa77c`
records playable M5 and explicitly says M6 has not started. This increment uses
that recorded state; it does not assume any unpushed local M6/M7/M8 work exists.
The owner requested starting the next milestone; previous human gates are not
thereby marked passed. The M5 report is preserved byte-for-byte in
[the M5 implementation-status archive](IMPLEMENTATION_STATUS_M5_36b47cc.md).

See [M6 implementation details and remaining scope](M6_PATCHBOARD.md).

| File | Change |
|---|---|
| `scripts/progression/patchboard_state.gd` | Typed two-slot selection, endpoint validation, copied catalog, intermission/unlock checks, preview, atomic snapshot restore and mission reset |
| `tests/unit/test_patchboard.gd` | Positive/negative selection and save fixtures, including the eight catalog endpoint pairs |
| `tests/test_runner.gd` | Registers the M6 selection suite alongside all previous suites |
| `docs/M6_PATCHBOARD.md` | API boundary, integration checklist and reproduction commands |
| `docs/IMPLEMENTATION_STATUS_M5_36b47cc.md` | Unmodified historical status retained from the base commit |
| `docs/IMPLEMENTATION_STATUS.md` | This current, explicitly partial status |

| Check | Result |
|---|---|
| Changed-source whitespace (`git diff --cached --check`, staged authored files) | PASS; no whitespace errors. Not a syntax or behavior test. |
| Godot availability (`command -v godot`; `command -v godot4`) | Neither executable available; no replacement engine installed |
| Pinned import (`sh tools/godot.sh import`) | NOT RUN — no pinned executable/full checkout in this environment |
| Full regression, including new M6 suite (`sh tools/godot.sh test`) | NOT RUN — tests authored, not executed |
| Existing Python foundation (`python3 tools/check_foundation.py`) | NOT RUN — full repository not materialized |
| Desktop smoke (`sh tools/godot.sh smoke`) | NOT RUN |
| Android/iOS exports, emulator, physical phone and human playtests | NOT RUN; prior iOS deferral retained |

## Remaining M6 acceptance

The patchboard is not exposed in gameplay yet. All eight combat recipe payoffs,
cooldowns/proc bounds, event attribution, tutorial/discovery, intermission UI,
run/profile migration integration, stress evidence and three human-tested
combinations remain unfinished. The state fixture does not prove any recipe
triggers or any recursive combat effect terminates.

Existing M5 gameplay/content/save rules are unchanged. M5/M4 human gates remain
open. Do not merge as a verified playable M6 release. No milestone beyond M6 was
started; no app build or store release was published.

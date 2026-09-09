# Authorized M8–M10 continuation

Owner request 2026-09-09: implement M8 and M9 together, playtest in Android
emulator and fix gaps/errors, then continue into M10 without milestone-by-milestone
confirmation. This overrides the older one-milestone stop instruction for this pass.
Current baseline: main e2f5f2b, 0.10.3/code 15, clean working tree, 4,574 regression
checks and 200 rendered UI checks from the preceding delivery.

Work sequence:
1. Preserve legacy campaign/checkpoint behavior; introduce versioned expanded-run
   rules and generated campaign content for 12 missions, eight roles, three bosses.
2. Add difficulties, six explicit Contracts, mission medals, codex/log rewards.
3. Add Endless schedule and bounded consumables, score/reward commits, and complete
   48 achievement conditions with history and migration coverage.
4. Verify content reachability, mechanics, real full-run decisions and checkpoint
   continuation, positive/negative achievement fixtures, and UI access/layout.
5. Export isolated Android QA app, play through emulator controls, inspect rendered
   battles and runtime errors, force-stop/resume at required phases, fix defects.
6. M10: distinct new role/boss art and tells, rank evolution, environment/audio,
   accessibility and measured performance; rerun relevant checks after fixes.
7. Record exact implemented scope and PASS/FAIL/NOT RUN evidence. Human acceptance,
   physical-device thermal/usability and M11 native services/store release are not
   certified by automated/emulator results. No M11 implementation in this pass.

## Outcome

Implementation sequence completed through the M10 pass. See
[M8–M10 delivery](M8_M10_DELIVERY.md) for changes, exact checks, emulator evidence,
balance findings and open human/physical acceptance gates. The owner subsequently authorized committing/pushing the delivery and updating
the Pixel; physical installation and save-preservation evidence is recorded.

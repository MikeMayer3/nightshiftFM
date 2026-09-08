# M4 support turrets and random-build balance

Owner request: represent secondary weapons as small bottom turrets with cooldown
bars, and playtest random upgrades on the emulator. This remains M4.

## Implemented

- Equipped Arc, Bass and Net have small turrets inside the existing battlefield.
  Their icons and colors match upgrade cards. Recruitment reveals the matching
  turret; unowned weapons do not appear. Main weapon and shield stay separate.
- Each bar reads the weapon's actual simulation timer. Empty means just fired;
  full and a lit muzzle mean ready. A ready support waits for an available target
  and fires automatically. Pause and upgrade decisions freeze its cooldown.
  Branch interval modifiers use the same helper for firing and presentation.
- Arc lightning starts at its mini turret. Bass and Net use matching colored
  launch flashes and effects. Round glyphs and bars stay undistorted on tall
  screens; no extra bottom text or separate toolbar consumes the playfield.
- New missions use `m4.active.2`: Burst damage is `45 + 3.25 × earned choices`,
  previously `45 + 3 × choices`. At 20 choices this is 110 instead of 105.
  Opening damage, radius, five-second cooldown and enemy health are unchanged.
  Wave 8 now introduces two Overseers instead of four, replacing the other two
  with plated enemies. All 40 enemies, five-enemy formations and spawn timing
  remain; wave 10 keeps four Overseers. This avoids introducing the finale
  elite count abruptly in wave 8. The old active wave resource is preserved.
- Existing `m4.active.1` saves keep the old damage formula and four-elite wave 8 after load and re-save.
  M3, original M4 and Signal saves also retain their rules. Saves need no schema
  rewrite. Android is **0.4.3 / code 7**, same regular app ID and save filename.

## Random-build balance evidence

`tests/random_balance.gd` chooses uniformly among displayed offers with a separate
RNG seeded `mission seed + 10000`. There is no family preference, reroll, banish,
branch swap, free recruitment, or recovery. Record every offer and selection.
All policies retain automatic weapon fire. Aimed policies inspect exact actor
positions to choose clusters/urgent threats, so they are not human win rates.

| Input policy | Initial tuning, seeds 1–60 | Final wave-8 tuning, same seeds |
|---|---:|---:|
| Aimed, checked every 0.1 second | 51/60 | **59/60** |
| Aimed, checked every 0.5 second | 46/60 | **57/60** |
| No combat input; upgrades only | 0/60 | **0/60** |

Final suite: **180 completed runs**. Winning runs take approximately 609–658
simulation seconds before card reading (10.1–11 minutes). The final remaining
losses are one aimed defeat on wave 10 and three slower-policy defeats: one on
wave 8, two on wave 10. No-input runs still lose mostly on wave 3.

The first small Burst growth adjustment alone did not improve win counts on
seeds 1–30, although mean damage taken fell. A corrected emulator run then exposed
an abrupt wave-8 elite pileup. That evidence prompted the versioned encounter
change, after which all 60 seeds were rerun. Mean damage taken by the slower
policy fell from 126.0 to 61.7 across those seeds. These are strong targeting
policies, so high completion rates do not imply a 95% human win rate. The opening
and four-elite finale remain demanding when bursts are missed or poorly aimed.

## Android emulator playtests

AVD `Pixel_10_Pro`, Android 17 / API 37 / arm64, 1280×2856, Compatibility renderer.
Software graphics under host memory pressure runs approximately 12–18 FPS;
this is emulator performance, not a physical-phone performance measurement.

The isolated `org.nightshiftfm.turretqa` APK contains the unchanged runtime sources
plus a read-only observer and QA entry scene. Its source-hash manifest is recorded.
The observer only reports state, coordinates and a seeded random offer index.
`tools/emulator_playtest.py` sends actual Android `input tap` events to those
rendered cards and battlefield points. Combat runs at normal speed in the real
CombatScreen, with real checkpoint saves. No direct upgrades, combat advancement,
health changes, time scaling, or checkpoint retries are injected by the driver.

An initial driver attempt lost on wave 5 after 289 simulation seconds. This was
invalid as a clean balance comparison: Godot reports its inset rendering surface
at (0,0), while Android taps use full-display coordinates. The driver omitted the
156-pixel top inset and did not promptly retry missed taps. Preserved its log and
result under `emulator-seed-1`. The corrected driver reads SurfaceView bounds from
Android's UI hierarchy and retries unconsumed taps after one second. An actual
Pause/Resume check froze all three support timers, Burst cooldown, elapsed time,
hull and kills; matching telemetry is recorded in `emulator-pause-check.json`.

The corrected preliminary run lost on wave 8 at 497 simulation seconds, after
entering that wave with full hull. Its later audit found one stale gameplay tap
selected draft 14 before the observer sampled it, so its later build differs
from the final run. It is gameplay evidence of the elite spike, not a clean
paired random-build experiment. Recorded under `emulator-seed-1-corrected`.
The final build uses the same mission seed with uniformly random choices from
the beginning, and every accepted card is checked against its random selection:
**PASS: victory on wave 10, 636.05 simulation seconds / 656.07 wall seconds,
588 kills, 110 bursts, 30 audited random choices, 100 hull remaining.** The
final screenshot shows 22 shield remaining and three breached enemies. All 30
accepted cards match the sampled random choices. Saved under
`emulator-seed-1-final`; no checkpoints were retried. This demonstrates that a
uniformly random upgrade build can win with active aiming. The regular APK was
then installed and launched on the emulator. See `IMPLEMENTATION_STATUS.md`. Physical-phone delivery, human fun approval and final art are
not part of these automated emulator checks. Existing phone apps/saves untouched. The disposable emulator QA package was removed
after its final save, screenshots and telemetry were captured; the regular app remains.

## Reproduce

Use pinned Godot 4.7.2 standard and the local Android SDK/JDK documented in
`MOBILE_DEVELOPMENT.md`. Export APKs sequentially.

```sh
sh tools/godot.sh import
sh tools/godot.sh test
python3 tools/check_foundation.py
sh tools/godot.sh smoke
"$GODOT_BIN" --path . --script res://tests/visual_turrets.gd
"$GODOT_BIN" --headless --path . --script res://tests/random_balance.gd -- prior 1 31 legacy
"$GODOT_BIN" --headless --path . --script res://tests/random_balance.gd -- final 1 61
sh tools/godot.sh android-debug
python3 tools/build_emulator_playtest.py --output builds/android/nightshift-turret-qa-final.apk
"$ANDROID_HOME/emulator/emulator" -avd Pixel_10_Pro -no-snapshot-save -no-audio -no-boot-anim
"$ANDROID_HOME/platform-tools/adb" -s emulator-5554 install -r builds/android/nightshift-turret-qa-final.apk
python3 tools/emulator_playtest.py --adb "$ANDROID_HOME/platform-tools/adb" --serial emulator-5554 --seed 1 --output docs/evidence/M4-turrets/emulator-seed-1-final
```

Evidence lives in `docs/evidence/M4-turrets/`. The QA observer and controller are
excluded from the regular APK. No commit, push, signing-key change or publication.

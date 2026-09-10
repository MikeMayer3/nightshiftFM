# Continuous waves, entry corridor and module cards

Owner-directed local revision after 0.10.5, based on `main` at `80e514f`.
This changes the current automatic radio battles; it does not start a new milestone.

Automatic broadcasts skip the timed intermission, including a countdown loaded
from an older save. Upgrade decisions and explicitly opened mixer/connection
screens still pause time. Wave-start checkpoints and reward boundaries remain.

Enemy centers begin at simulation y = −80, above the visible field. The entire
collision body must pass y = 96 before targeting, damage, chains, fields or
retargeted echoes can affect it. Incoming Signals is painted above attacks and
actors; area effects stop at the protected approach. Enemy ability clocks begin
only after entry. Ranged enemies and bosses descend to y = 300 before holding,
which keeps them reachable by every main chassis even near the side edges.

Station acquisition and damage limits (simulation units):

| Equipment | Base reach |
| --- | ---: |
| AM tower | 540 (was 600) |
| FM tower | 516 (was 600) |
| Shortwave tower | 500 |
| Valve Microphone | 460 |
| Studio Monitor | 420 |
| Mixing Desk | 460 |
| Turntable | 540 |
| Spring Reverb | 440 |
| Tape Deck | 550 |

Support acquisition previously had no station-distance check. Chain distances,
field radii and local retarget distances retain their own upgrade effects. Main
range upgrades and Long Mast still work within a hard 588-unit station cap and
the entry boundary. Focus selects an eligible target for each weapon, so an
out-of-range priority enemy cannot prevent firing at a closer valid target.
Damage from generated connections and shield retaliation obeys the same entry
rule. Traveling notes expire when crossing into the protected strip. Knockback
cannot push enemies back into it.

The old flat 0.70 automatic enemy-health multiplier is replaced by 0.80 on wave
one, increasing by 0.025 per wave to 1.00 on wave nine. This is applied on top of
the existing wave and difficulty health scales. It is fixed encounter tuning;
there is no hidden adjustment based on the player's modules or performance.

All twelve modules have distinct original SVG equipment illustrations generated
by `tools/generate_module_art.py` in `assets/art/modules/`. The two-column cards
use the whole illustrated surface as the selection target, with selected border
and background, short benefit/cost text, and a full-description tooltip. Existing
two-slot limits, presets, module IDs and tradeoffs remain. Long Mast explicitly
says its bonus is capped. The setup details show actual station reach.

## Evidence

`docs/evidence/M10-balance-modules/` contains original and final simulations,
rendered module galleries, actual setup input checks, and entry screenshots.

The comparison uses Standard difficulty, seeds 11/42/91/137/205, missions
1/4/8/12, the default AM/Capacitor/Valve Microphone loadout, no modules and neutral
mixer. All choices come from real offers, with independent decision RNG and no
rerolls. Policies select uniformly, prioritize recruitment then the tower, or
prioritize tower upgrades (the historical harness called the latter “defense,”
although offensive drafts contain no shield upgrades). Shields activate below
30% capacity in every policy. Neither baseline nor final runs inject player
stats, damage or kills.

| Mission | Before wins / 15 | Final wins / 15 |
| --- | ---: | ---: |
| 1 | 15 | 13 |
| 4 | 13 | 10 |
| 8 | 8 | 4 |
| 12 | 12 | 9 |
| Total | 48 / 60 | 36 / 60 |

All 60 final runs reached a real victory or defeat. The first mission retains
an easier introduction; two choice/seed combinations now lose on wave nine.
At mission 8 the uniform policy lost all five runs while recruitment-first and
tower-first each won two. These policies are simple probes, not optimal play or
estimates of a human win rate. Results also show regional difficulty remains
uneven; mission 8 is harder than mission 12 for these probes.

A separate 18-run equipped check uses all three main and shield chassis, three
starting supports, Hot Tubes + Signal Booster, and the earned seven-point mixer
allocation (4 Direct / 3 AOE), with a cleared-12 profile. It won 17/18 and restored
**254** upgrade checkpoints through full-precision JSON. Strong fully equipped
builds remain powerful; this pass does not claim every build has an equal win
rate. `after.json` and `after-ramp.json` are intermediate tuning evidence;
`final.json` and `equipped.json` describe the delivered local rules.

Commands from the project root:

```sh
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
sh tools/godot.sh import
sh tools/godot.sh test
sh tools/godot.sh smoke
python3 tools/check_foundation.py
python3 tools/generate_module_art.py
"$GODOT_BIN" --headless --path . --script res://tests/radio_balance.gd -- final
"$GODOT_BIN" --headless --path . --script res://tests/radio_balance.gd -- equipped
"$GODOT_BIN" --path . --script res://tests/visual_modules.gd
```

- PASS: import, startup smoke, seven foundation checks, 12 distinct valid SVGs
  with byte-identical regeneration, and `git diff --check`.
- PASS: 152 rendered/input checks at 360×640 and 450×950. Actual viewport input
  selects/replaces modules, enforces the two-slot limit and scrolls to the last
  row; width checks cover every card child.
- Regression count is recorded in `IMPLEMENTATION_STATUS.md` and the evidence logs.
- PASS: subsequent authorized Android export and physical Pixel update to
  0.10.6 / code 18. All six JSON files matched after installation; mission and
  presentation files also matched after launch. Installed version/process checked,
  with no runtime script/crash errors. Evidence: `pixel-install.json` and
  `pixel-launch.log`. APK and original saves are under ignored `builds/`.
- NOT RUN: human balance/usability and artwork acceptance. No commit or push.

The final normal-access import emitted only the existing warning about ignored
`builds/broadcast-qa-src/project.godot`. Initial sandboxed save tests could not
write Godot's application-data directory; they were rerun with normal access.
Sandboxed numeric simulation runs also printed OS log/certificate access errors;
their complete results were saved in the project and validated. No script errors
are accepted in the final regression or rendered runs.

## Save behavior

Existing profiles, serialized IDs, progression and mixer allocations remain.
Negative positions are admitted only for actors in automatic broadcasts, within
−80…720; malformed coordinates still fail validation. Legacy nonautomatic saves
retain their original entry/countdown rules. Existing automatic saves adopt the
new range/countdown rules and use the new health tuning for newly spawned waves;
already saved actor health is preserved. Comparisons use the same pinned engine
and full-precision JSON as the production save writer.

# Station splash and combat polish — 2026-09-10

Owner art revision: replaced the realistic splash with a flat illustrated redraw
using the game's module and combat art as style references. Retained the warm
station, rooftop tower, mountain and looming device silhouettes. Active prompt:
`assets/art/splash/REDRAW_PROMPT.md`. Import and startup smoke passed; the existing
rendered fixture passed **105 checks, zero failures** after replacement, including
Continue/large-text layouts at 360×640, 450×950 and 1024×768. Reviewed the phone
renders. This asset-only revision did not rerun the gameplay suite or full runs.
Logs: `evidence/M10-polish/splash-style-*.log`; splash PNG previews now show the redraw.

Owner-requested presentation pass over the local 0.10.6 balance/module revision.
This remains uncommitted and unpushed. The installed Pixel build is still 0.10.6
without this subsequent polish; no new APK was exported or installed in this pass.

## Changes grounded in play and visual review

- Added an illustrated opening title: a warm remote radio station and rooftop
  tower, with a mountain and shadowed music-player, earbud and speaker enemies.
  New/Continue/Settings are immediately available. The composition survives wide
  windows and narrow phones; diagnostics and the old footer leave the title menu.
- Replaced the net's misleading diamond with a circular woven field matching its
  actual radius, subtle anchors and energized strands.
- Replaced stacked bass outlines with expanding upward pressure fronts and soft
  trailing bands; removed duplicate net/reverb deployment geometry.
- Actual arsenal attacks now render AM wave packets, an intertwined FM beam, or
  shortwave volleys. Previously they all used the same generic chain waveform.
- Connected actual arsenal shots to the existing throttled, four-voice audio cue.
  Added short deterministic kill fragments, capped at 32 simultaneous bursts.
- Transient effects now freeze along with combat during upgrade choices, wiring,
  and pause. Low-effects/reduced-flash options remain supported; visuals never
  consume gameplay RNG or change damage, ranges, save formats, or progression.
- Enlarged upgrade illustrations and replaced duplicated recruitment captions
  with “NEW INSTRUMENT”. Styled the report action consistently and removed the
  unavailable Mixer action from results after spotting it in a completed run.

Implementation: `SplashArt`, `RadioEffects`, `CombatArena`, `CombatScreen`,
`RadioAudio`, `BootScreen`, `DraftPanel`, localization and presentation fixtures.
Art origin and full generation prompt: `assets/art/splash/PROVENANCE.md`.

## Validation

Using Godot 4.7.2 standard, from the project root:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh import
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh test
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh smoke
python3 tools/check_foundation.py
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/visual_polish.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/polish_autoplay.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/polish_playtest.gd
```

PASS: import, startup smoke, seven foundation checks, **5,537 regression checks**,
**104 rendered layout checks**, and **47 rendered playthrough checks**; zero
failures or script/runtime errors in the saved logs. Import reports an existing
nested QA project under ignored `builds/`, which Godot skips.

Layout coverage: 360×640, 450×950 and 1024×768; title with Continue and large text,
settings transition, results actions, six attack presentations, reduced effects.
The gallery uses staged actors and results-layout screenshots stage a result
solely for layout inspection; neither is claimed as a completed game.

Two complete accelerated mission-1 runs used real production scenes, simulation,
legal draft-button signals, isolated saves and normal result handling. Net:
22 choices, 10 waves, 529.85 game seconds, victory, 100 hull, zero breaches. Bass:
21 choices, 10 waves, 538.07 seconds, victory, 63.3 hull, 28 breaches. Seeds and
metrics are recorded in `evidence/M10-polish/playthrough.json`. This deliberately
recruits available instruments; it is not a representative player win-rate sample.
The later results-button cleanup was then checked by the final layout and full
regression suites; full-run result images preserve the earlier observed layout.

Direct desktop UI inspection used the separate `polish_interactive.json` save:
New broadcast, equipment selection, net start, earned bass recruitment, restart
into Continue, further bass/net upgrades, pause, and return to the splash. This
was real-time interaction; the two entire missions above were automated. Owner
mission saves were not used by the playthrough fixtures.

NOT RUN: physical-phone testing of this new polish, human playtest/asset approval,
auditory listening approval, release signing or distribution. The earlier Pixel
install/save-preservation evidence applies only to the balance/module build.

Screenshots and execution logs: `evidence/M10-polish/`.

# P3 — first-session guidance and phone reliability

Implemented 2026-09-10. Player candidate: **0.10.8 / Android code 20**.
The owner reported that P2 looked good in their testing and requested P3. That is
owner feedback on the prior build, not unfamiliar-player onboarding acceptance.

## Changes

A compact illustrated hint sits outside the battlefield, immediately above the
action buttons. It never pauses play or introduces a countdown. Each hint appears
once per installation and can be dismissed with its × button:

- Shield: an entered enemy has approached the station and the ability is ready.
  Wording matches Capacitor, Relay, or Feedback rather than implying every shield
  has the same active ability.
- Temporary boost: appears only after actual activation while a temporary reserve
  exists. Its description points to the existing violet shield, BOOSTED text,
  extra absorption number and thin duration bar. It disappears on expiry/depletion.
- Mixer: introduced after the first accepted gear choice, when the player has a
  changed build and can allocate existing power or investigate connections.

Settings → **Help & controls → Replay combat hints** resets only coaching history.
The hints return when their real context is relevant. No combat, RNG, campaign,
reward, or checkpoint state is stored in coaching. There is no required reading,
first-run overlay, repeat-every-mission tutorial, or permanent stat bonus.

The previously hidden handedness setting is now exposed as **Action button on the
left**. On current automatic broadcasts it moves the visible shield control to
the selected side; legacy Burst layouts retain their original behavior. The old
implementation moved a hidden Burst button, so it had no useful effect in current
broadcasts.

## Saved state

The existing version-1 presentation envelope accepts an optional `coaching` array
of the three known IDs. Two-field pre-P3 files remain valid, preserving every
existing option. Entries are unique strings; unknown IDs, duplicates, incorrect
types and malformed envelopes are rejected. Existing atomic temporary-write and
validated-backup behavior is reused. Showing a hint records it immediately, so
restarts and interruptions do not repeat coaching; Help explicitly replays it.
A failed preference write can leave the hint eligible after a later cold start,
and existing settings error feedback remains available. Mission saving is separate.

## Verification and evidence boundaries

Evidence files are in [evidence/P3-onboarding](evidence/P3-onboarding/).

| Target | Scope | Result |
| --- | --- | --- |
| Godot 4.7.2 headless | Full regression suite, including old preference migration and coaching persistence | PASS — 5,659 checks / 0 failures |
| Native macOS window, 360×640 / 450×1000 / 1024×768 | Large text, muted sound/music, low effects/reduced flash, real hint/Help/Mixer/shield input, both handedness positions, no battlefield overlap, background/resume delta | PASS — 54 checks / 0 failures |
| Native fresh-start flow, 360×640 | Real menu → station → loadout → combat; actual legal choices and approaching enemies trigger all three hints; cold scene Continue and preference reload | PASS — 10 checks / 0 failures |
| Native macOS audio playback | Actual music/effect voice start, background pause, foreground resume and mute | PASS — six playback-state checks; hearing quality is not inferred |
| Existing safe-area regression fixtures | Scaled/offset notch mapping, bounds clamping and unavailable-inset fallback | PASS in regression suite; synthetic safe-area evidence |
| Android emulator, isolated `org.nightshiftfm.p3recovery` | Force-stop during combat, draft, after accepted choice, results, repeated results and Home/foreground | PASS — six cases; initial result was a defeat |
| Android emulator, earned victory | Coherent legal winning run, two force-stops on its result | PASS — one earned reward remains exactly once |
| Android emulator, lifecycle/power | Active Home/foreground freezes elapsed time; simulated unplugged battery saver still permits combat | PASS — power settings restored; not a battery-drain measurement |
| Pixel 10 Pro XL, isolated `org.nightshiftfm.p3qa` | Physical 150-enemy/400-projectile rendering load, late authored mission loops, twenty-minute thermal/memory soak | PASS — full soak completed; see measured results below |
| Physical small/notched Android models other than Pixel, physical tablet, iOS | Hardware layout/performance | NOT RUN — hardware not available |
| Unfamiliar-player first-session comprehension | Human usability | NOT RUN |

The fresh-flow and emulator drivers accelerate simulation to reach decisions;
they are not measurements of player pacing or physical performance. Force-stop
checks compare the resumed state to the durable checkpoint, including accepted
choices, run ID, hint history, and reward records. They do not promise restoration
of unsaved partial-wave time.

The physical QA snapshot uses the same runtime scripts as the player candidate
except the small Mixer hint icon: the final candidate uses the existing fader
illustration instead of a Net icon. The final icon/input layout was rechecked in
the 54-check native pass. Package names and test entry points also differ.

The QA packages are separate from `org.nightshiftfm.spike` and use synthetic test
profiles only. The performance package unlocks the campaign in its own profile,
then plays mission 12 at normal simulation speed with legal offered choices and
actual mixer/shield actions. It does not establish worst-case performance across
every authored encounter or human strategy. The static rendering fixture holds
150 swarmers and 400 projectile actors; it is a rendering ceiling test, separate
from the live mission's simulation cost.

The Pixel remained USB-powered. Battery temperature and Android thermal status
are measured; unplugged energy consumption and battery drain are **NOT RUN**.
Frame-delta p95 during authored play is an engine timing measure, not a separate
input-latency or display-photon measurement. Rendering-stress samples use wall time
between rendered frames (120 warm-up frames, 300 measured frames per mode).

## Reproduction

Run from the repository root with the pinned standard Godot 4.7.2 executable:

```sh
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh import
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh test
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh smoke
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/visual_coaching.gd
/Applications/Godot.app/Contents/MacOS/Godot --path . --script res://tests/p3_first_run.gd
python3 tools/check_foundation.py
GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot sh tools/godot.sh android-debug
```

Device-only test entry points are `tests/p3_phone_probe.gd` and
`tests/p3_recovery_probe.gd`. Export them only from an isolated copied checkout
with their own main scenes and package IDs; the normal player export excludes
`tests/*` and `tools/*`. `tools/p3_phone_soak.py` samples the connected Pixel;
`tools/p3_recovery_check.py` drives the emulator (default checkpoint cases,
`--mode victory` for an earned reward, `--mode lifecycle` for Home/battery saver). APK hashes and package IDs are
recorded with device evidence. The regular player build must retain its original
package identity to preserve owner saves.

Source changes remain local, uncommitted/unpushed. P4 is the next roadmap task;
P3 does not implement P4 radio personality/boss anticipation or store services.

## Final physical results and delivery

Physical Pixel 10 Pro XL, Android 17, USB powered:

- PASS: 150 enemies / 400 projectiles, 300 measured rendering frames after 120
  warm-up frames: p95 **19.078 ms normal**, **19.179 ms low effects**. Both meet
  their respective 20 ms / 36 ms provisional thresholds.
- PASS: thirty-second warm-up plus twenty-minute authored-combat soak at normal
  simulation speed. Two full mission-12 victories occurred during the soak.
  Sampled FPS **58–61**; maximum cumulative engine-delta p95 **16.667 ms**.
- PASS: comparable fresh-run cleanup static memory **73,660,640 → 77,159,706 bytes**,
  **+4.75%**, below the 10% investigation threshold. This includes QA sample buffers.
- PASS: measured battery temperature **30.0–32.2°C**, maximum Android thermal status
  **0**. No sampled save errors or captured script/parse/fatal runtime errors.
- NOT RUN: unplugged battery drain, human audio/haptic quality, unfamiliar-player
  first-session comprehension, and other physical device classes.

Full measurements: [pixel-soak-summary.json](evidence/P3-onboarding/pixel-soak-summary.json),
plus raw host/runtime samples and the QA package hash. Initial locked-phone samples
are retained as unavailable measurements and excluded from live temperature/FPS
summary calculations. The user unlocked the phone before measured gameplay began.

The player package was updated in place from **0.10.7/code 19 to 0.10.8/code 20**.
Its actual pre-update mission save passed validation. All six existing save/settings
files matched their pre-install SHA-256 hashes immediately after installation and
after launch. Foreground activity, process and launch logs were verified.
[pixel-install.json](evidence/P3-onboarding/pixel-install.json) records the local
backup location, APK hash and preservation checks. The temporary physical QA app
was removed after evidence collection; its data was separate from the player game.

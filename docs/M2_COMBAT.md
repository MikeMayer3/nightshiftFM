# M2 combat prototype

M2 implements one offline three-wave mission. Select **Start · Three waves**.
The fixed bottom transmitter carries one rank-1 Pulse gun and one rank-1
Capacitor shield. There are no supports, drafts, unlocks, rewards, or permanent
stat increases in this milestone. Nightshift FM remains a provisional skin.

## Play

- The gun fires automatically at the threat nearest the full-width breach line.
  Its instant pulse can destroy enemy shots as well as enemies.
- Hold over a threat to focus it. Drag to change focus. Release anywhere to
  return to auto-aim. The ring identifies the current target.
- **Brace shield** reduces incoming damage by 75% for 2.5 seconds, with a
  12-second cooldown. It does not reflect or generate attacks.
- Shield absorbs damage first; overflow reaches hull. Shield recharges at
  3 points/second after 5 seconds without damage.
- Round swarmers descend straight. Triangular divers weave slowly for two
  seconds, then accelerate. Square carriers descend slowly and send at most
  three swarmers and three destructible shots. Reinforcements enter at the top.
- **Pause** (desktop P/Escape) freezes combat. **Resume**, **Restart mission**,
  and **Back to menu** remain available. Space activates the shield on desktop.
- Victory follows three cleared waves, including outstanding shots. Zero hull
  ends the mission immediately. Results show kills, interceptions, breaches,
  remaining hull, and the last hit source and damage route.

This is a short combat test, not the eventual ten-wave mission. The current
untouched auto-aim fixture wins in 52.02 simulated seconds with 63.6 hull.
That establishes viability for this fixed fixture, not human balance approval.

Backgrounding a living process freezes combat, including cooldowns and enemy
abilities. Returning preserves manual pause and clears any held targeting input.
**Closing or force-stopping the app ends the prototype mission.** Wave-checkpoint
saving, upgrade drafts, RNG persistence, and rewards are M3 work. M1's separate
Mobile checks save probe remains available and is not used as a mission save.

## Run and verify

From the project root:

```sh
export GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
sh tools/godot.sh import
sh tools/godot.sh test
python3 tools/check_foundation.py
sh tools/godot.sh smoke
sh tools/godot.sh test --quit-smoke
sh tools/godot.sh run
```

See [DEVELOPMENT.md](DEVELOPMENT.md) for other operating systems and fresh-source
imports. Rendered screenshot evidence can be reproduced with a graphical desktop:

```sh
"$GODOT_BIN" --path . --script res://tests/visual_combat.gd
```

For Android, keep the existing SDK/template setup in
[MOBILE_DEVELOPMENT.md](MOBILE_DEVELOPMENT.md):

```sh
sh tools/godot.sh android-debug
export ADB_BIN="$HOME/Library/Android/sdk/platform-tools/adb"
"$ADB_BIN" devices -l
# Set DEVICE_ID from the device listing.
"$ADB_BIN" -s "$DEVICE_ID" install -r builds/android/nightshift-m2.apk
"$ADB_BIN" -s "$DEVICE_ID" shell am force-stop org.nightshiftfm.spike
"$ADB_BIN" -s "$DEVICE_ID" shell am start -n org.nightshiftfm.spike/com.godot.game.GodotAppLauncher
```

For the tested Pixel 10 Pro XL at 1080 × 2404, the logical canvas starts at
physical y=264 and has scale 1.5. These are measured coordinates, not assumptions
for another phone or display configuration. Leave the phone unlocked on the menu:

```sh
python3 tools/android_combat_check.py --adb "$ADB_BIN" --serial "$DEVICE_ID" \
  --canvas-top 264 --canvas-scale 1.5 --output builds/android/m2-check
```

The driver performs synthetic ADB touch on a physical device: Start, manual
pause, 20 Home/resume cycles, Resume, active background/resume, hold/drag/release,
shield activation, results, restart, and a second full auto-aim run. It records
PASS/FAIL JSON and screenshots; it does not clear app data or phone logs.
It cannot certify how controls feel in a person's hand. iOS remains deferred at
owner request.

## Implementation boundary

`CombatSession` owns fixed-step runtime simulation and explicit shot/hit/wave/
finished signals. `CombatActor` owns copied per-enemy values and movement.
`CombatArena` only draws and maps pointer coordinates. `CombatScreen` handles
HUD, lifecycle, and navigation. Nine immutable-by-ownership `.tres` definitions
provide one gun, one shield, three enemies, three waves, and one test mission.
No runtime values are written into these resources.

Combat uses a fixed 640 × 720 rectangle within the portrait safe-area layout;
extra space does not change spawn positions, speeds, or breach geometry. Spawn
positions are authored deterministic arithmetic, with no random stream or save
claim. Kills resolve before same-step breaches, each actor resolves once, and
ending a mission clears its actors. Restart replaces run state and clears every
combat timer. The active shield has no secondary attack, so no proc generation
system is needed in M2. No damage-over-time/status system is introduced here.

The UI uses Godot's documented [Control input handling](https://docs.godotengine.org/en/stable/classes/class_control.html)
and [custom 2D drawing](https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html),
verified with the pinned 4.7.2 engine. Original vector geometry and the transmitter
icon require no external art license or runtime dependency.

The remaining M2 human gate is a Pixel playtest: confirm gun responsiveness,
readable danger, useful auto-aim/focus, and an understandable ending. Record any
adjustments before proceeding to M3. Automated tests do not approve this gate.

# Implementation status

Evidence revision: **M5 — six-family arsenal**
Date: **2026-09-08** (America/Chicago)
Requested milestone: **M5 only**, explicitly authorized by the owner.
Outcome: **Playable M5 implemented. Human acceptance remains NOT RUN.**

See [M5 arsenal](M5_ARSENAL.md) for controls, coefficients, attack/save contracts,
reproduction commands and evidence limits. M6 has not started.

| Scope | Implementation |
|---|---|
| Equipment selection | New mission → main/shield/starting support → Go live; fresh rank 1; all M5 playtest options exposed |
| Complete catalog | 12 immutable tracks, 216 options: 108 support + 108 chassis; six tunings, three branches, two modifiers per branch and a cap per branch |
| New families | Echo Deck with stored/repeated/alternate-target packets; traveling Needle Swarm with pierce/homing/marks; Reverb Well with pull/orbit/release fields |
| Existing families | Complete Arc/Bass/Net branches; offensive Live Current retained in place of the original Net healing design |
| Main/shield behavior | Precision/beam/volley contracts; Capacitor/Relay/Feedback active and passive effects; separate compact shield button |
| UI | Up to five equipped support turrets and cooldown bars; new placeholder icons; rank/branch comparisons; short player-facing captions |
| Saves | New m5.1 content version; strict actor/effect/loadout validation; legacy behavior retained; Continue/Restart retains equipment and exposes correct controls |

Primary files: `tools/generate_arsenal_content.py`, `content/arsenal/`,
`scripts/progression/arsenal_{content,draft,stats}.gd`,
`scripts/combat/arsenal_combat.gd`, `scripts/save/arsenal_runtime.gd`,
`scripts/ui/arsenal_picker.gd`, and integrations in CombatSession, SignalSnapshot,
CombatScreen, CombatArena, DraftPanel and BootScreen. Tests and reproducible
emulator tools are in `tests/arsenal_*`, `tests/unit/test_arsenal.gd`,
`tests/integration/test_arsenal_screen.gd` and `tools/emulator_playtest.py`.

| Check | Result |
|---|---|
| Pinned Godot import | PASS — Godot 4.7.2 standard; clean temporary QA-source import also passed |
| Regression | PASS — 1,731 checks, 0 failures; includes 72 serialized rank-8 branch/modifier paths, legacy controls, restart selection and actual mid-wave recovery |
| Effect matrix | PASS — all 216 options cause observed gameplay changes in controlled fixtures; no leaked fixture listeners |
| Python foundation | PASS — 7 checks; 363 total immutable resources |
| Desktop smoke | PASS |
| Desktop UI | PASS — equipment selection, five turrets, draft/comparison, 450×800, 360×640 and 450×950 |
| Final random policy | PASS — 54 completed runs, 49 victories; Pulse 15/18, Sweep 18/18, Burst 16/18 |
| Idle policy | PASS — 18 completed runs, zero victories |
| Stress | PASS — 18 legal five-of-six rank-8 combinations, 30 simulated seconds each; peak 18 pending effects, worst CPU ~153 ms per 1,800 steps |
| Android exports | PASS — separate QA and regular debug APKs; regular Android 0.5.0/code 8; APK signature verifies (existing Java native-access warning only) |
| Actual emulator full mission | PASS — wave-10 victory; 611 kills, 111 bursts, 31/31 random choices audited; 639.15 simulated / 657.23 wall seconds; median 60 FPS |
| Regular APK selector/pause/recovery | PASS — Sweep/Relay/Reverb selection, enlarged dropdown targets, shield button, Pause/Resume, identical saved draft after force-stop and in-place update, single accepted choice and fresh-rank Restart |
| Human acceptance / final art | NOT RUN |
| Physical phone / iOS M5 | NOT RUN |
| M5 source handoff | Owner authorized commit and push; source and verification evidence included in this handoff |

Evidence: `docs/evidence/M5/`. The full-run QA export differs only in its entry
scene, read-only observer and isolated Android package. `qa-source-manifest.json`
and `apk-parity.json` document source hashes and subsequent display/resume UI
changes. A final exposure-assistance attribution fix records whether Bass or Reverb supplied the debuff; its exact metadata-only patch is retained. Damage, targeting, wave coefficients and upgrade selection rules are unchanged from the completed full-run QA test.

Two early emulator attempts were explicitly interrupted because the long-lived
AVD degraded to 1–2 FPS; they are not completed balance samples. Reducing render
resolution alone did not fix it. A cold boot with `-gpu host` restored ~50–60 FPS
at 720×1600. The display size/density overrides were reset to the original 1280×2856/480 after testing. The regular 0.5.0 APK is installed and left at the menu. This is emulator evidence, not physical Pixel or human usability
acceptance. The initial 13/54-win balance batch and intermediate 47/54 batch are
retained alongside final results.

---

# Historical M4.5 implementation report

Status schema version: **1**
Evidence revision: **M4.5 — support turrets and random-build balance**
Date: **2026-09-08** (America/Chicago)
Requested milestone: **M4 only**, following owner authorization to move to the next milestone.
Outcome: **Support turrets and cooldown bars implemented; versioned Burst growth
and wave-8 elite tuning. 726 Godot checks PASS, 180 current-balance random-build
simulations completed. A final emulator run cleared all 10 waves with 30 audited
random upgrade choices.
M5 has not started.**

## M4.5 — support turrets and random-build balance

Requested small bottom turrets for secondary weapons, actual cooldown bars, and
emulator playtests with random upgrades. See `M4_SUPPORT_TURRETS.md` for behavior,
seed policies, reproduction commands and evidence limits.

| Files | Change |
|---|---|
| `scripts/combat/combat_arena.gd` | Equipped-only Arc/Bass/Net mini turrets, matching icons/colors, aim direction, firing flash/origin, full-ready cooldown bars; existing playfield size retained |
| `scripts/combat/support_combat.gd` | One shared effective firing-interval helper, including branch modifiers, used by simulation and recharge display |
| `scripts/combat/{active_combat,combat_session}.gd`, `scripts/save/signal_snapshot.gd` | New `m4.active.2` Burst growth: 3.25 damage per earned choice; two Overseers in wave 8, four in finale; previous active saves retain 3.0 and the original wave schedule |
| `content/active/waves/wave_8_turrets.tres`, `scripts/progression/active_content.gd`, `tools/generate_active_content.py` | Separate immutable first-elite encounter, same formation count/timing; old wave remains for legacy saves |
| `tests/{unit/test_active,integration/test_active_screen,visual_turrets,random_balance,emulator_playtest}.gd` | Cooldown firing/recharge/pause/recovery, ownership, legacy beam origin/balance, three viewport sizes, uniform random offers, read-only Android observer |
| `tools/{build_emulator_playtest,emulator_playtest}.py` | Isolated QA export with source hashes; actual ADB taps at normal speed, measured Android surface inset, saved telemetry/screens/results |
| `project.godot`, `export_presets.cfg`, current docs | Android 0.4.3/code 7; current mechanics and acceptance records |

All commands below run from this checkout using
`GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`,
`JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home`, and
`ANDROID_HOME=/Users/michaelmayer/Library/Android/sdk` where applicable.

| Check | Exact command / evidence | Result |
|---|---|---|
| Import | `sh tools/godot.sh import` | PASS; also clean source-copy import for QA export |
| Regression | `sh tools/godot.sh test` | PASS — 726 checks, 0 failures |
| Foundation | `python3 tools/check_foundation.py` | PASS — 7 checks; 135 immutable resources |
| Smoke | `sh tools/godot.sh smoke` | PASS |
| Desktop UI | `$GODOT_BIN --path . --script res://tests/visual_turrets.gd` | PASS — 450×800, 360×640, 450×950, three turrets and aim/release |
| Random builds | `$GODOT_BIN --headless --path . --script res://tests/random_balance.gd -- final 1 61` | PASS — 180 completed runs: 59/60 aimed wins, 57/60 half-second reaction wins, 0/60 idle wins |
| Android export | `sh tools/godot.sh android-debug` | PASS — regular APK 0.4.3/code 7 |
| Isolated QA export | `python3 tools/build_emulator_playtest.py --output builds/android/nightshift-turret-qa-final.apk` | PASS — 273 runtime files hash-match current source; observer/entry scene and package label are QA-only |
| APK signatures | `$ANDROID_HOME/build-tools/36.1.0/apksigner verify builds/android/nightshift-m4.apk`; repeat for `nightshift-turret-qa-final.apk` | PASS; existing Java native-access warning only |
| Emulator Pause/Resume | Actual Android taps; `emulator-pause-check.json` | PASS — all three support timers and Burst/combat state freeze together |
| Emulator | `python3 tools/emulator_playtest.py --adb "$ANDROID_HOME/platform-tools/adb" --serial emulator-5554 --seed 1 --output docs/evidence/M4-turrets/emulator-seed-1-final` | PASS — wave-10 victory, 636.05 simulation seconds, 30/30 random picks verified, 588 kills, 100 hull |

Evidence: `docs/evidence/M4-turrets/`. The first visual fixture directly equipped
unearned supports and correctly failed save validation; it now explicitly
isolates that artificial presentation fixture from the save store. The final
visual run passes. An initial emulator driver omitted Android's 156-pixel surface
inset and delayed missed-tap retries; its wave-5 defeat remains recorded as a
driver failure, not a clean balance sample. Corrected taps use measured
SurfaceView bounds. The game itself did not require an input mapping change.

The small Burst adjustment alone left original-seed win counts unchanged. An
emulator attempt then lost on wave 8 at 497 seconds, despite entering at full hull.
A later audit found one stale tap selected an unsampled card in that preliminary
run; it is gameplay evidence, not a clean paired random-build sample. The final
run audits every accepted card against the observed random selection.
It exposed the abrupt four-elite introduction. Replacing two with plated enemies
preserves formation size/timing and the four-elite finale. Final 60-seed retesting
improves aimed wins from 51 to 59 and slower-policy wins from 46 to 57, with zero
idle wins. Winning simulations take about 10.1–11 minutes excluding draft reading.
These are automated policy results, not measured human win rates.
Final emulator result: wave 10 cleared at 636.05 simulation seconds (656.07 wall
seconds), with 588 kills, 110 bursts, 30 audited random picks, 100 hull and 22
shield remaining. Three enemies breached; the run was not damage-free. Median
emulator rendering was 16 FPS on software graphics. Every accepted card matched
the observer's random offer selection. No checkpoint retries, rerolls or time
scaling were used. Victory screenshot and telemetry are recorded. Regular APK
0.4.3/code 7 installed and launched on the same emulator after the QA run.
APK SHA-256: `65e61e2665b7c1cef40d3209ca0c3a0cf808a8577b5683f916f49da4e6269ef9`.

Physical phone delivery, human acceptance and final art: NOT RUN for this revision.
Existing phone apps and saves were not touched. The disposable emulator QA package was removed
after its final save, screenshots and telemetry were captured; the regular app remains. No commit, push or publication.

### GitHub handoff — owner authorized

The owner requested committing and pushing the latest build after the completed
M4.5 checks. This handoff includes the previously uncommitted M3/M4 implementation,
content, documentation and evidence required to reproduce Android 0.4.3/code 7.
The installable ARM64 debug APK is attached to the `v0.4.3` GitHub prerelease;
build outputs and credentials remain outside Git source. No M5 work is included.
A clean archive of the staged source passed pinned-engine import, all 726 Godot
checks, all 7 foundation checks and startup smoke before this commit. Logs are
`docs/evidence/M4-turrets/github-fresh-*.log`.
The next roadmap milestone is M5 (complete six-family arsenal, main guns and
shields), following the M4 human gameplay gate. Automated victory is not human
acceptance.

## M4.4 — active combat and expanded battlefield

The owner found the previous kill-meter build passive and requested a larger
field without the bottom explanations. Kept the existing fixed transmitter and
implemented aimed offensive Burst against formations. See `M4_ACTIVE_COMBAT.md`
for exact mechanics, controls, versioning and balance limits. This remains M4.
The earlier single-enemy spawn cadence let automatic fire eliminate enemies
near the spawn line, leaving targeting and brace with little practical value.

### Scope and files

| Files | Change |
|---|---|
| `scripts/combat/active_combat.gd`, `scripts/progression/active_content.gd`, `content/active/waves`, `tools/generate_active_content.py` | Five-enemy formations, survivable automatic-fire pressure, aimed damage/armor penetration/interrupt/shot-clear burst, bounded cooldown/targets; finale reduced from eight copied elites to four |
| `scripts/combat/{combat_session,combat_arena,combat_screen}.gd` | Versioned active-run start, grouped spawns, aim/drag/release and button input, visible aim radius/cooldown, enlarged field with round enemy silhouettes, removed bottom legend/rank/tutorial labels |
| `scripts/progression/signal_progress.gd`, `scripts/save/signal_snapshot.gd` | Denser flow's kill thresholds 6/9/12/15/18/21; active cooldown/count/damage snapshots; old Signal cost curve and old content versions preserved |
| `scripts/ui/{boot,draft_panel}.gd`, localization, `project.godot`, `export_presets.cfg` | New-run routing, burst report subset, controls in Pause, tall-display expansion, Android 0.4.2/code 6 |
| `tests/{unit/test_active,integration/test_active_screen,active_balance,visual_active}.gd`, runner/boot tests, foundation resource count | Burst effects/caps, freeze/recovery, old-version safety, actual input mapping, text removal/field area and 36 comparative simulations |
| Current design, milestone, README, mobile, playtest and active-combat docs | Owner-directed M4 revision and exact acceptance/evidence boundaries |

### Commands and evidence

All commands use pinned Godot **4.7.2.stable.official.ed1daf0bf**, standard /
Compatibility. Run from the project root with
`GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`. Android export retains
`JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home` and
`ANDROID_HOME=/Users/michaelmayer/Library/Android/sdk`.

| Check | Command | Result |
|---|---|---|
| Import | `sh tools/godot.sh import`; fresh source-copy import before proof export | PASS |
| Full regression + active behavior | `sh tools/godot.sh test` | PASS — 708 checks, 0 failures |
| Foundation/content/localization/wrapper | `python3 tools/check_foundation.py` | PASS — 7 checks; 134 resources |
| Boot smoke | `sh tools/godot.sh smoke` | PASS |
| Real desktop UI | `$GODOT_BIN --path . --script res://tests/visual_active.gd` | PASS — field/aim/release burst; 450×800, 360×640, 450×950 |
| Comparative balance | `$GODOT_BIN --headless --path . --script res://tests/active_balance.gd` | PASS — 36 complete simulations |
| Debug export and signatures | `sh tools/godot.sh android-debug`; SDK `apksigner verify` | PASS — regular/proof APKs, built sequentially |

Logs, screenshots, source equivalence, balance details and delivery metadata are
under `docs/evidence/M4-active/`. Java's existing native-access signing warning
remains; exports/signature checks passed. The prototype's first active health/
damage combination was too harsh (all active probes lost); final balance reduced
late health scaling, gave support builds equal burst scaling, and reduced the
elite count. A test fixture initially advanced before the next formation existed;
its timing was corrected, then the full suite passed.

Four upgrade preferences × three seeds × three input policies produce **0/12 idle
wins, 3/12 automatic-target button wins, and 9/12 aimed-burst wins**. Every build
preference has an aimed win. Aimed wins last 624–663 seconds excluding decisions.
These tests use exact simulation positions; they show that aiming/timing matters,
not human skill, accessibility acceptance or guaranteed fun. New-flow human
playtesting, final art, iOS and release publication are NOT RUN. No commit or push.

### Physical Pixel and delivery

On the Pixel 10 Pro XL (Android 16/API 36, 1080×2404):

- **PASS:** Android 0.4.2/code 6 installed in place with `adb install -r`.
  The regular `org.nightshiftfm.spike` save (`m4.signal.1`) matched its pre-install
  bytes. APK SHA-256:
  `4a9d611a30b84abb91b5b256051f48a4708737fbb190424d29d84f0e00a954f3`.
- **PASS:** isolated `org.nightshiftfm.activeproof20260908` booted; a real touch
  opened a new mission. Observed the enlarged battlefield, five-enemy formation,
  removed bottom explanations, Burst control and kill-earned choice on screen.
- **OBSERVED:** while the owner tried the test app, its checkpoint reached wave 2,
  60 kills and five choices with one Burst use / 68 effective enemy damage saved.
  The app was not unattended at this point. This demonstrates live device Burst
  use/persistence, but is not a controlled aiming-versus-button experiment.
- **NOT RUN:** controlled physical aim/drag/release and force-stop recovery
  sequence. The owner was interacting during the attempted scripted sequence;
  state guards stopped the script before it injected a stale action. Those paths
  pass desktop input/save tests. No complete new-build human win is claimed.

Runtime sources match between the regular build and separate proof copy; only
Android package ID/app label differ. The test app and its run were deliberately
left intact because the owner was trying it. The regular app is also updated;
start New mission there for active combat, or Continue the existing Signal run.
Exact delivery hashes and observed checkpoint are in `docs/evidence/M4-active/`.

## M4.3 — longer waves and kill-driven offensive choices

The owner requested longer levels, upgrades/new weapons earned by filling a kill
bar, offensive choice focus, and radio-tuner art later. Implemented that revision
within M4 and documented its precedence over the original end-wave/27-pick design.
See `M4_SIGNAL_FLOW.md` for exact rules and save behavior. Old `m3.1` and `m4.1`
runs continue unchanged; new missions use `m4.signal.1` / run schema 2.

### Scope and changed files

- `content/signal/{tracks,upgrades,waves}`, `tools/generate_signal_content.py`,
  `scripts/progression/{signal_content,signal_progress,signal_draft}.gd`: longer
  encounters, kill thresholds 5/7/9/11/13, retained overflow, offensive eligibility,
  acquisitions in the same pool, fresh rerolls and bounded Overdrive fallback.
- `scripts/combat/{combat_session,signal_support_combat,support_combat}.gd`:
  end-of-step choice pausing and same-wave resumption, armor-piercing Arc path,
  damaging Net and Live Current variants; old support behavior retained.
- `scripts/save/{signal_snapshot,mission_store}.gd`: validated actor/status/field/
  shock snapshots, meter and choice consistency, full-precision JSON, unchanged
  atomic envelope and reward commits. Fixed integer normalization on JSON reload.
- `scripts/combat/combat_screen.gd`, `scripts/ui/{boot,draft_panel}.gd`, localization:
  simple live meter, compact new-weapon cards/details, updated pause explanation,
  new-run routing. Final tuner art remains deferred.
- `tests/unit/test_signal.gd`, `tests/integration/test_signal_screen.gd`, boot/runner,
  `tests/visual_signal.gd`, resource-count check: new flow, pause, overflow, final-kill
  race, branches, target caps, fallback, invalid saves and actual disk/UI checks.
- App/export version 0.4.1/code 5; current-flow docs, design/roadmap override and
  AGENTS checkpoint contract updated. All prior uncommitted M3/M4 work preserved.

### Commands and results

From the project root, with `GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`:

| Check | Command/evidence | Result |
|---|---|---|
| Import | `sh tools/godot.sh import`; also fresh disposable source copy with no `.godot` cache | PASS |
| Regression + new behavior | `sh tools/godot.sh test`; `docs/evidence/M4-signal/tests.log` | PASS — 665 checks, 0 failures |
| Content/wrapper/localization | `python3 tools/check_foundation.py` | PASS — 7 checks, 124 resources |
| Boot smoke | `sh tools/godot.sh smoke` | PASS |
| Desktop actual scene | `$GODOT_BIN --path . --script res://tests/visual_signal.gd` | PASS — meter/choice/details, 450×800 and 360×640 |
| Balance | Five preference policies × seeds 11/42/91 in unit suite; `balance.json` | PASS — 15 completed runs; 13 wins and 2 losses |
| Debug Android exports | `sh tools/godot.sh android-debug`, regular and separate proof package | PASS — 0.4.1/code 5 |
| Whitespace | `git diff --check` | PASS |

Android export uses the existing `JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home`
and `ANDROID_HOME=/Users/michaelmayer/Library/Android/sdk`. The existing apksigner
Java native-access warning remains; both exports completed successfully.

Winning automated runs take 504–545 simulation seconds (8.4–9.1 minutes) and
22–25 choices, excluding decision reading. No scripted brace or aiming. All twelve
focused policies win; one of three random builds wins. Some focused builds still
finish cleanly, while two low-output random builds die. This measures pacing and
build viability, not human fun or exhaustive branch balance. Exact choices and
contributions are retained in `balance.json`. Prior owner-positive playtesting
predates this revision. Final art, iOS, store signing and publication are NOT RUN.

### Physical Pixel and delivery

Pixel 10 Pro XL, Android 16/API 36, serial `57261FDCQ00593`, 1080×2404.
The separate package `org.nightshiftfm.signalproof20260908` was built from a
fresh source copy; runtime files match the delivered source. Only Android ID and
app label differ. The player's regular save was never used for test play.

- **PASS:** real touch starts a new mission; Signal visibly grows to 2/5, then
  opens a three-card choice at five kills during wave 1, with Bass acquisition
  and offensive upgrades. Screenshots and the actual decision save are retained.
- **PASS:** force-stop retains the exact pending-choice save bytes.
- **INCOMPLETE:** physical Continue/accepted-choice recovery interaction. Phone
  use interrupted the check. No successful physical recovery UI is claimed.
  Equivalent real-scene/disk tests and active-effect JSON reconstruction pass
  on desktop. No full new-flow human playtest is claimed.
- **PASS:** final APK exported, `apksigner verify` passed, and
  `adb install -r builds/android/nightshift-m4.apk` installed 0.4.1/code 5 to
  `org.nightshiftfm.spike`. The existing `m4.1` save matched its pre-install
  SHA-256 byte for byte. Regular app reached its menu. Choose New mission for
  the new flow; Continue keeps the old rules. See `delivery.json`.

APK SHA-256: `426d096d68bbd18445cac64706980b8c333624e819488dcfbb075dedebfbf393`.

One concurrent export attempt failed because Godot's exporters collided on a
shared temporary APK; that invalid APK was rejected by Android. Both final exports
were rerun **sequentially**, verified, and installed successfully. Exporting two
Godot APKs simultaneously is unsafe with this toolchain. No game crash was found;
Android emitted surface-disconnection messages when the proof app was backgrounded.
No commit or push was performed.

## M4.2 — owner playtest feedback and balance ownership

The owner reports that M4 playtesting was fine, expects remaining concerns to be
resolved through more art, and states that balance is Codex's responsibility.
Recorded that positive human feedback in `M4_PLAYTEST.md`. Attempt counts,
loadouts and results were not specified. The broader formal sample is unverified,
not being claimed complete or treated as a reason to ask the owner to do numerical
balance work. Codex owns the next balance investigation and resulting tuning;
no completed balance pass is claimed by this documentation update.

This revision changes feedback/status documentation only. `git diff --check`
is the relevant verification; engine checks and the installed APK below remain
the M4.1 evidence. No gameplay values, builds, installs, commits or pushes changed.

## M4.1 — three-support vertical slice

The owner authorized the next milestone after the M3 upgrade-screen revision.
Inspected the actual dirty `main` checkout, AGENTS.md, M4 criteria, design/status
rules, and catalog. Preserved all uncommitted M3 work and existing M3 save support.
Pinned Godot remains **4.7.2.stable.official.ed1daf0bf**, standard / Compatibility.
The owner proceeding is not being counted as the mandatory six M4 human sessions.

### Scope and changed files

| Files | Implemented behavior |
|---|---|
| `content/m4/{tracks,upgrades,enemies,waves}/*.tres`, `tools/generate_m4_content.py`, `scripts/progression/m4_content.gd` | Three support tracks, 33 real upgrade options, two branches and two modifiers per branch, ten authored Standard wave patterns, plated ranged carrier and elite Overseer |
| `scripts/combat/{support_combat,status_state,contribution_report}.gd` | Arc damage/shield paths, Bass area/exposure paths, Net disruption/interception paths; capped statuses, elite resistance/fallbacks, finite wave/field budgets, effective contribution attribution |
| `scripts/combat/{combat_session,combat_actor,combat_event,combat_arena,combat_screen}.gd`, `scripts/core/definitions/enemy_definition.gd` | Armor pipeline, shield breaks, all support runtime timers, readable tells, arena clipping, M4 checkpoint extension, recruitment, compact details/branch comparison and results report |
| `scripts/ui/{draft_panel,boot}.gd`, `scripts/save/mission_profile.gd`, `assets/ui_strings.csv` and generated translation, `assets/art/equipment/{bass,net}.svg` and sidecars | New missions use M4; old M3 runs retain original definitions. New M4 profiles gain starting-pool option IDs without permanent power. Original SVG placeholders and concise primary cards retained |
| `tests/unit/test_m4.gd`, `tests/integration/test_m4_screen.gd`, `tests/visual_m4.gd`, `tests/test_runner.gd`, `tools/check_foundation.py` | Complete branch reachability/reconstruction, effect/control/budget/rollback tests, real scene recruitment/comparison/report tests, two full automated builds; previous suites retained |
| `project.godot`, `export_presets.cfg`, `tools/godot.sh`, README and current development/mobile docs | Android 0.4.0/code 4, `nightshift-m4.apk`, same regular app identity and save location |
| `docs/{M4_SLICE,M4_PLAYTEST,IMPLEMENTATION_STATUS}.md`, `docs/evidence/M4/` | Exact scope/rules, six-session human record, development failures and final evidence |

The full roster remains three supports: Arc Aerial, Bass Driver and Static Net.
Main and shield are independent of support slots. Recruitment can be declined
for a focused build. Only implemented branches are exposed. At rank 3/6, a player
can compare an eligible alternative in Details without spending an upgrade or
reroll; the swapped offer is saved. Capstones need no lucky rare offer.

### Commands and results

Commands run from the project root unless noted. Set
`GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`. Android export uses
`JAVA_HOME=/Applications/Android Studio.app/Contents/jbr/Contents/Home` and
`ANDROID_HOME=/Users/michaelmayer/Library/Android/sdk`.

| Check / exact command | Result | Evidence under `docs/evidence/M4/` |
|---|---|---|
| `python3 tools/generate_m4_content.py` | **PASS** | 48 M4 resources generated; full catalog totals 78 resources |
| `sh tools/godot.sh import` | **PASS** | `import-final.txt`, no parse/import errors |
| `sh tools/godot.sh test` | **PASS: 519 checks, 0 failures** | `tests.txt`, no script errors; includes original 10,800 M3 draft fixtures |
| `sh tools/godot.sh smoke` | **PASS** | `smoke.txt` |
| `python3 tools/check_foundation.py` | **PASS: seven checks** | `python.txt` |
| `"$GODOT_BIN" --path . --script res://tests/visual_m4.gd` | **PASS** | `desktop-visual.txt`; draft/details/recruitment/three-support combat/elite finale/results/report at 360×640 |
| Fresh source copy import and Android export | **PASS** | `proof-project.json`, `proof-import.txt`, `proof-export.txt`; separate application ID for isolated physical testing |
| `sh tools/godot.sh android-debug` | **PASS** | `android-export.txt`; existing JDK native-access warning only |
| Physical Pixel first wave, card choice, branch comparison and Bass recruitment | **PASS** | `pixel-branch-check.json`, `pixel-proof-recruited.json` and screenshots; isolated app data |
| Physical force-stop/relaunch/Continue with three-support wave-4 fixture | **PASS** | `pixel-recovery-check.json`, `pixel-proof-recovery-log.txt`; zero actors and original checkpoint elapsed/contribution restored |
| `adb -s 57261FDCQ00593 install -r builds/android/nightshift-m4.apk` | **PASS** | `android-install.txt`; `pixel-preservation-check.json` confirms existing player save bytes unchanged |
| `adb -s 57261FDCQ00593 uninstall org.nightshiftfm.m4proof20260908` | **PASS** | Disposable test app removed after verification; regular game retained |
| `git diff --check` | **PASS** | No whitespace errors |
| Three human testers × two attempts; two human winning builds | **NOT VERIFIED** | Positive owner playtesting now reported; full sample and winning routes unspecified |
| Full ten-wave physical-phone human playthrough, thermal soak, final art approval | **NOT RUN** | Simulation and injected touch do not certify these gates |
| iOS, native achievements, release signing and publication | **NOT RUN** | Existing deferral retained; outside this slice |

Physical verification used Pixel 10 Pro XL, Android 16/API 36, serial
`57261FDCQ00593`. A fresh source copy used package
`org.nightshiftfm.m4proof20260908` to isolate all test choices and injected fixture
data. The final candidate differed from the regular build only in application
identity/title; it was re-exported after the final details-page changes. A real
first-wave playthrough and touch inputs verified selection/branch comparison and
Bass recruitment. For the three-support check, `pixel-fixture.json` is a valid
checkpoint generated through actual desktop session decisions; it was written
only into the disposable app's private files. It is fixture-assisted physical
recovery evidence, not a human four-wave playthrough. The regular app retained
package `org.nightshiftfm.spike` and its existing save byte-for-byte.

Final debug APK: `builds/android/nightshift-m4.apk`, version **0.4.0 / code 4**.
SHA-256: `c8bade39e10f9e2d7c0d8dee276e007ece1af0f2b1c5edff0eebadbd3aaea878`.

The damage/exposure build and control/defense build each complete identical
Standard patterns with seed 420, 27 normal choices, one recruited support and
three decline bonuses. `simulated-builds.json` records each actual choice,
boundary, result and contribution total. These are **automated victories only**.
Current runs finish at full hull and take approximately 3.8 and 5.2 active minutes;
this is a generous starting point for human feedback, not final 8–12-minute pacing.

### Corrections and remaining acceptance

- Initial mission pressure overwhelmed both automated builds. Reduced repeated
  armored groups and wave health scaling, retained the same mission and roster,
  and leveled the main gun in each test strategy. Initial failure logs are retained.
- Typed conditional arrays caused runtime errors; replaced them with explicitly
  typed assignments. Final tests and rendered runs contain no script errors.
- Branch comparison now safely rejects options from unequipped families.
- Phone inspection showed repeated long branch text in the first detail-page
  draft. Removed duplicate descriptions, moved Back near the top, and limited
  the future preview to concise relevant path steps. Compact primary cards remain.
- Net fields initially drew above the arena; arena clipping keeps effects out of
  the HUD. Wide/Deep Bass modifiers also affect capstone travel distance.
- Support reports separate effective damage from armor assistance and exclude
  overhealing. Wave-start recovery discards uncommitted partial-wave output.
- Positive owner playtesting is recorded in M4.2. The broader human sample and
  two human winning builds remain unverified. Codex owns balance investigation
  and tuning; art concerns remain on the later asset backlog.
  **Do not start M5 before the M4 gameplay gate is accepted.**

No commit, push or publication was requested or performed. M3 and M4 changes
remain in the working tree on `main`, based on `10e5771f067bddc13bf85fdb0cc23259be8dcba7`.

## Historical M3 evidence

The following M3 sections describe their original verification; their statements
that M4 had not started are historical.

The owner requested “ok lets get started on M3”. Inspected the clean `main`
checkout, AGENTS.md, milestone acceptance, design/catalog rules and M2 evidence
before implementation. Kept the pinned **Godot 4.7.2.stable.official.ed1daf0bf**
standard engine, Compatibility renderer, and **4.7.2.stable** export templates.
No dependencies, plugins, services or external assets were added.

## M3.2 — simpler upgrade selection

The owner found the original upgrade screen confusing, awkward and too wordy,
and requested more visual emphasis. “Upgrade 1/27” counted normal selections
across the whole mission (three after each of waves 1–9), which distracted from
choosing the current card. The headline is now **Choose an upgrade**, with only
the completed wave and a tap instruction underneath. The mission rules are unchanged.

Three whole-card touch targets show a colored equipment icon, short equipment
name, current/next rank, upgrade name and concise effect. All three cards and
the reroll/banish toolbar fit a 360 × 640 desktop viewport. Numerical details,
prerequisites and the branch path are available through each card's **i** button.
Banish has a separate mode with Cancel and disables mandatory branch choices.
The support-bonus page is shorter and includes an Arc icon. Original SVG icons
are placeholders for future art; final illustration approval is not claimed.

Changed files: `scripts/ui/draft_panel.gd`, `scripts/combat/combat_screen.gd`,
`assets/art/equipment/*.svg` and import sidecars, `assets/ui_strings.csv` and
translation, `tools/generate_m3_content.py`, `tests/integration/test_m3_screen.gd`,
`tests/visual_m3.gd`, `tools/check_foundation.py`, this status and `M3_UPGRADES.md`.
The Python resource-path check now recognizes explicit directory references.

### Revision checks

Commands run from the project root with
`GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`.
Evidence is under `docs/evidence/M3.2/`; earlier M3.1 evidence below is historical.

| Check / exact command | Result | Evidence |
|---|---|---|
| `sh tools/godot.sh import` | **PASS** | `import.txt` |
| `sh tools/godot.sh test` | **PASS: 400 checks, 0 failures** | `tests.txt`; includes card bounds, details and banish cancellation regressions |
| `sh tools/godot.sh smoke` | **PASS** | `smoke.txt` |
| `python3 tools/check_foundation.py` | **PASS: seven checks** | `python.txt` |
| `"$GODOT_BIN" --path . --script res://tests/visual_m3.gd -- --revision-m3-2` | **PASS** | `desktop-visual.txt`, draft/details/360×640/support screenshots |
| Same rendered fixture with `--interactive`, computer-use click at window x104/y124 | **PASS** | `desktop-card-check.json`, `desktop-card-click.png`; isolated save's normal selection count increased exactly 0→1 |
| `sh tools/godot.sh android-debug` with existing Android Studio JDK and SDK | **PASS** | `android-export.txt`; existing apksigner native-access warning retained |
| `adb -s 57261FDCQ00593 install -r builds/android/nightshift-m3.apk` | **PASS** | `android-install.txt`; in-place update |
| Physical Pixel info, Back, Banish and Cancel touch inputs | **PASS** | `pixel-navigation-check.json` contains exact coordinates; complete saved envelope unchanged after each action, four normal choices retained |
| `git diff --check` | **PASS** | No whitespace errors |
| Owner acceptance of revised screen / final art | **NOT RUN** | Revised screen left open on Pixel for review |

The initial layout exposed vertically wrapped rank labels; ranks now explicitly
disable wrapping, with a card-content-height regression check. An initial Python
check treated the screenshot output directory as a file; the final check validates
explicit directories separately. A stale early phone snapshot predating a card
choice was unsuitable for navigation comparison; the final physical check took
a fresh baseline and compared the entire envelope after each of four inputs.
No player save was reset or rolled back.

Current APK SHA-256:
`19a4416da73b7417b508c0160f8274d9ad851b5223e6215f1af0bcc2ed6eaf7c`.
All M3 work remains uncommitted and unpushed. No M4 work was added.

## M3.1 — upgrade drafts and checkpoint saves

### Scope and changed files

| Files | Implemented behavior |
|---|---|
| `scripts/progression/{track_definition,upgrade_track,draft_state,m3_content,run_random}.gd` | Immutable track resources, reconstructed rank state, compatibility/prerequisites/exclusions/caps, eligible-track allocation, main/shield quotas, most-overdue-first support queue, separate bonus drafts, rerolls/banishes, bounded fallback consumables and independent RNG streams |
| `content/tracks/*.tres`, `content/upgrades/*.tres`, `tools/generate_m3_content.py`, `scripts/core/definitions/upgrade_definition.gd` | Three starting tracks and 18 working upgrade options: three common cards plus one rank-3/6/8 route per track; reproducible resources/localized card text; no later families exposed |
| `scripts/combat/{combat_session,combat_actor,combat_event,combat_arena}.gd` | Ten-wave progression mode, Arc chains and bounded branching capstone, Pulse rebounds, live shield stats/brace recharge, distinct-target hit limits, explicit root/source/depth/trigger metadata, wave checkpoint capture/reconstruction, original chain visuals; retained M2 regression fixture |
| `scripts/save/{save_checks,mission_profile,mission_store}.gd` | Versioned validated profile/run envelope, temporary write/flush/verify, recoverable temporary and backup, safe rejection/recovery, idempotent local completion reward; no permanent combat growth |
| `scripts/ui/{boot,draft_panel}.gd`, `scripts/combat/combat_screen.gd`, `assets/ui_strings.csv` and generated translation | New/Continue flow, current/next ranks and prerequisites, branch previews, scrollable card choices, token explanations, recruitment decline, save-error freeze/retry, corruption recovery, updated health/ability/results UI |
| `tests/unit/test_m3.gd`, `tests/integration/test_m3_screen.gd`, `test_boot.gd`, `tests/test_runner.gd`, `tests/visual_m3.gd`, `tools/check_foundation.py` | 10,800 draft stress fixtures, all 18 effect checks, generic mock recruitment, corruption/version/precision/rollback/reward tests, full ten-wave simulation, real scene/button recovery, screenshots, earlier suites retained |
| `project.godot`, `export_presets.cfg`, `tools/godot.sh` | Version 0.3.0/code 3 and `nightshift-m3.apk`; same offline debug Android identity and pinned toolchain |
| `README.md`, `docs/{DEVELOPMENT,MOBILE_DEVELOPMENT,M3_UPGRADES,IMPLEMENTATION_STATUS}.md`, `docs/evidence/M3/`, generated UID sidecars | Current instructions, bounds, commands, evidence and remaining human acceptance |

M3's playable roster is Pulse, Capacitor and Arc Aerial. Each starts at rank 1;
new missions reset ranks, derived stats, temporary modifiers, support acquisitions,
rerolls and banishes while preserving profile option IDs and completion records.
The three M2 wave patterns form a short ten-wave progression fixture with scaled
initial enemy hull. Waves 1–9 grant exactly three normal selections each; wave
10 ends directly at results. Before waves 2/4/6/8, declining recruitment grants
one support-only bonus. Other families appear only in test fixtures, which verify
five-support enforcement and unlocked recruitment without consuming main/shield.

At rank 8, or when no valid options remain, small repair/refill choices keep the
27-selection structure moving. No normal option purchases a support slot.
Each exposed effect is active in combat. See `M3_UPGRADES.md` for exact routes,
coefficients, slot rules, card behavior and the wave-checkpoint contract.

### Commands and results

Run from the repository root with
`GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`.
A fresh source copy excluded `.git`, `.godot`, builds and caches; it was created
at `/var/folders/cy/lx2m7tpd07vb9z_vxtj0ckxw0000gn/T/nightshift-m3-fresh-9ak91f7p/project`.
This is a fresh-source import, not a new GitHub clone of unpushed M3 changes.
Exact command arrays, working directory and exits are in `fresh-checks.json`.

| Check / exact command | Result | Evidence under `docs/evidence/M3/` |
|---|---|---|
| `sh tools/godot.sh import` on fresh source | **PASS** | `check-00.txt`, exit 0, no script/import errors |
| `sh tools/godot.sh test` | **PASS** | **393 checks, 0 failures**; `check-01.txt` |
| `sh tools/godot.sh test --intentional-failure` | **PASS** | 394 checks, exactly one intentional failure, exit 1; `check-02.txt` |
| `sh tools/godot.sh smoke` | **PASS** | Main scene starts/exits cleanly, `check-03.txt` |
| `sh tools/godot.sh test --quit-smoke` | **PASS** | Actual Quit signal exits 0, `check-04.txt` |
| `python3 tools/check_foundation.py` | **PASS** | Seven Python checks, `check-05.txt` |
| `sh -n tools/godot.sh` | **PASS** | `check-06.txt` |
| `"$GODOT_BIN" --path . --script res://tests/visual_m3.gd` | **PASS** | Compatibility rendering, draft/scroll/360×640/recruitment/combat images, `desktop-visual.txt`; final log has no errors |
| `"$GODOT_BIN" --path . --script res://tests/visual_m3.gd -- --interactive` plus computer-use input | **PASS** | Clicked branch preview, scrolled, rerolled (2→1), chose a card; `desktop-interaction.png`; isolated visual save |
| `sh tools/godot.sh android-debug` with existing JDK/SDK environment | **PASS** | ARM64 debug export, `android-export.txt` |
| `adb -s 57261FDCQ00593 install -r builds/android/nightshift-m3.apk` | **PASS** | Updated physical Pixel 10 Pro XL, `android-install.txt` |
| Physical ADB touch, force-stop, launch and Continue | **PASS** | Ten checks in `pixel-check.json`; exact inputs in `pixel-commands.md`, snapshots and screenshots |
| Build Tools 36.0.0 `aapt dump badging` / `aapt dump permissions` | **PASS** | Version 0.3.0/code 3, min SDK 24, target SDK 36, no requested permissions including Internet |
| `git diff --check` | **PASS** | CSV normalized to LF; no trailing-whitespace errors |
| Human M2/M3 phone playtest / card readability approval | **NOT RUN** | Agent screenshots and synthetic touch do not certify human usability or fun |
| Full ten-wave human/physical-phone balance playthrough | **NOT RUN** | Complete mission proof is deterministic simulation; physical checks covered first-wave drafts, recruitment and second-wave recovery |
| iOS / native achievement sandbox | **NOT RUN** | Existing owner deferral and M1 account/platform gates retained |

The 10,800 seeded normal drafts span 400 production/mock-roster fixtures, plus
rerolls and banishes. Checks reject duplicates, incompatible/prerequisite-blocked,
maxed and banished options; verify hard quotas/overdue queue; and exercise fewer-
than-three and zero-option cases. Cosmetic RNG interleaving leaves drafts intact.
Full-width signed 64-bit RNG states round-trip through JSON decimal strings.
Every exposed option applies both its authored effects; focused combat tests
exercise Arc contact range/branching, per-root target limits, projectile metadata
and shield recovery during the hit delay.

The final seeded auto-aim M3 mission won in **135.75 active seconds**, with
**100 hull**, exactly **27 normal selections**, **four bonus selections**, and
arsenal windows **[2, 4, 6, 8]**. Every boundary/decision/result checkpoint in that
mission was serialized and reconstructed. This short, easy fixture is evidence
of the progression/save loop, not an 8–12-minute balance or fun acceptance.

On the physical Pixel, the app restored the same draft after force-stop; a real
injected touch accepted the saved card exactly once. Banish and reroll persisted
their counters and current offers. After selecting Arc's rank-3 branch, taking
three normal cards and declining recruitment for a support bonus, force-stopping
an active wave 2 and using Continue restored its **wave-start elapsed time,
health and zero actors**, retaining three normal choices and one bonus. No app
data or M1 probe was cleared. The owner unlocked the phone for these checks.

Final APK: `builds/android/nightshift-m3.apk`
SHA-256: `4ead19d6acc6d5c93e3a92a59a7b8470890b02a29e99e52b0329e8f1ff896f30`.

### Findings, corrections and limitations

- M2 fast-forward regression caught an accumulator reset at wave start; removed
  it while preserving decision-screen freeze. Earlier suites pass again.
- Save tests caught strict integer/float and String/StringName comparisons after
  JSON parsing. Added explicit validation/conversion and exact RNG string storage.
  The mock roster initially shared external child Resources after duplication;
  fixtures now explicitly copy each option, preserving production definitions.
- Desktop rendering caught an untyped ternary array in chain traversal; changed
  it to an explicitly typed array. The final rendered log is clean.
- Physical touch found that card panels stopped swipe propagation even though
  desktop wheel scrolling worked. Cards/actions now pass touch events to the
  ScrollContainer; the reinstalled build passes the actual swipe/reroll check.
  New screens reset scroll position, and keyboard focus can reveal lower controls.
- Early failing logs are retained as development evidence; `check-*.txt`,
  `fresh-checks.json`, final `desktop-visual.txt` and `pixel-check.json` are the
  current outcomes. No failure is being counted as a pass.
- Android signing repeats the existing JDK 25 restricted-native-access warning
  from `apksigner`; export, installation and execution succeed. No engine/runtime
  error appeared in the final checks.
- M3 starts the mission-save schema at version 1. There is no older production
  mission save to migrate; unknown future/content/engine versions reject safely.
  The M1 diagnostic file is independent. Actual legacy migration is not claimed.
- Only one branch per track and three tuning cards per track are implemented.
  The remaining arsenal, meaningful contrasting builds, full authored finales,
  campaign, achievements, balance and art/audio production remain later scope.
- No performance/thermal soak, final asset approval, smallest-physical-phone
  usability, iOS acceptance, native integration, release signing or publication
  is claimed. Human M2/M3 gates remain open. **Stopped at M3.**

API behavior was checked against official Godot documentation for
[RandomNumberGenerator](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html),
[FileAccess](https://docs.godotengine.org/en/stable/classes/class_fileaccess.html),
[JSON](https://docs.godotengine.org/en/stable/classes/class_json.html) and
[ScrollContainer](https://docs.godotengine.org/en/stable/classes/class_scrollcontainer.html),
then verified on the installed pinned engine.

Git at completion: `main`, base commit `10e5771f067bddc13bf85fdb0cc23259be8dcba7`,
tracking `origin/main` at `https://github.com/MikeMayer3/nightshiftFM.git`.
M3 changes remain uncommitted in the working tree. No commit or push was requested
or performed; no remote ahead/behind refresh was needed for this local milestone.

## Historical M2 evidence

The following sections retain the M2 and earlier milestone outcomes at the time
of their original verification. Their “M3 not started” statements are historical.

## M2.2 — GitHub handoff

The owner explicitly requested Git initialization and upload as `nightshiftFM`.
Created the private repository [MikeMayer3/nightshiftFM](https://github.com/MikeMayer3/nightshiftFM)
and pushed `main` from this project root. `origin` is
`https://github.com/MikeMayer3/nightshiftFM.git`; `main` tracks `origin/main`.
Initial source commit: `712ef97c2e8a8f5e1bca3b6c4242ce0efa458c78`.

**PASS:** local initialization, initial commit, private repository creation,
initial push, and remote commit match. The 180-file initial source snapshot
contains about 2 MB of source/docs/evidence. `.godot/`, `builds/`, credentials,
and local device saves are excluded. Staged-file checks found no excluded-path
violations or private-key/GitHub-token/AWS-key patterns. README and development
instructions now describe cloning the actual repository.

**PASS:** a literal fresh clone from GitHub imported and ran on the pinned
Godot 4.7.2 standard engine: **268 engine checks, 0 failures**, desktop headless
smoke exit 0, and **7 Python checks**. Commands were:

```sh
git clone https://github.com/MikeMayer3/nightshiftFM.git /path/to/nightshiftFM
cd /path/to/nightshiftFM
export GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
sh tools/godot.sh import
sh tools/godot.sh test
sh tools/godot.sh smoke
python3 tools/check_foundation.py
```

The exact temporary clone path, source commit, commands, exit codes and logs are
in `docs/evidence/GITHUB/`. This revision adds handoff documentation and clone
evidence only; gameplay is unchanged from the tested source commit. M2's human
playtest remains **NOT RUN**, iOS remains deferred, and M3 has not started.

## M2.1 — three-wave combat prototype

### Scope and changed files

| Files | Implemented behavior |
|---|---|
| `scripts/combat/combat_session.gd`, `combat_actor.gd` | Renderer-independent fixed-step simulation, copied actor/run state, main pulse targeting, paths, bounded carrier abilities and destructible shots, shield-first damage and overflow, brace/recharge, waves, death/victory, once-only resolution and clean restart |
| `scripts/combat/combat_content.gd`, nine `content/**/*.tres` resources | One fixed main weapon, one shield, three enemy definitions, three authored waves, one test mission; no full catalog |
| `scripts/core/definitions/{weapon,shield,enemy,wave}_definition.gd` | Explicit instant-pulse behavior, shield timings, enemy path/stats/limits, wave interval; validation of implemented numeric and reference fields |
| `scenes/combat/combat.tscn`, `scripts/combat/{combat_arena,combat_screen}.gd` | Portrait safe-area HUD, fixed transmitter/arena, enemy silhouettes and legend, health bars, held/drag focus and release-to-auto, active shield, pause/lifecycle handling, results and menu/restart |
| `scripts/ui/boot.gd`, `assets/ui_strings.csv`, generated translation | Start opens combat; localized gameplay controls, feedback and result causes |
| `scripts/platform/mobile_probe.gd` | Hidden M1 diagnostics disable their clock and no longer own combat pause state; active M1 diagnostics retain their lifecycle handling |
| `project.godot`, `export_presets.cfg`, `assets/art/icon.svg` and import sidecar, `tools/godot.sh` | M2 app version 0.2.0/code 2, original transmitter icon, current Android APK filename; same private debug package and pinned engine |
| `tests/unit/test_combat.gd`, `tests/integration/test_combat_screen.gd`, `test_boot.gd`, `tests/test_runner.gd` | Combat edge cases, ten natural simulated wins, ten UI restart/result runs, death fixture, actual frame pause, twenty synthetic lifecycle cycles, hidden-probe regression; prior suites retained |
| `tests/visual_combat.gd`, `tools/android_combat_check.py`, `tools/check_foundation.py` | Reproducible desktop images, physical-device touch/lifecycle/run driver, bounded-content and wrapper checks |
| Generated `.gd.uid` sidecars, `README.md`, development/mobile guides, `docs/M2_COMBAT.md`, this file and `docs/evidence/M2/` | Current instructions, scope limits and check evidence |

The gun uses an instant pulse every 0.48 seconds for 8 damage. Swarmer, diver,
and carrier paths are distinct; the diver telegraphs before accelerating. The
carrier can emit at most three reinforcements and three shots. Reinforcements
enter through the top band; projectiles originate at the carrier. The ordinary
gun can destroy those projectiles. Damage resolves through shield before hull,
and the active brace reduces incoming damage by 75% for 2.5 seconds with a
12-second cooldown. There are no reflection, secondary-proc, status/DOT, upgrade,
reward, or progression systems in M2.

The 640 × 720 combat rectangle is scaled uniformly within the existing 720 ×
1280 portrait safe-area UI. All enemies breach across its full-width bottom line.
Kill resolution precedes same-step movement/breach; resolved actors cannot apply
another kill/breach. Mission completion clears actors; restart resets timers,
health, shield, ranks, focus, and temporary state without modifying definitions.

### Commands and results

Run from `nightshift_fm_codex_pack/` with
`GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`. Engine remains
**4.7.2.stable.official.ed1daf0bf**, standard, Compatibility; matching templates
remain **4.7.2.stable**. Android uses the previously documented JDK 25.0.3 and
Build Tools 36.0.0. Exact fresh-source command arrays, working directories,
expected/actual exits and results are in `docs/evidence/M2/fresh-checks.json`.

| Check / exact command | Result | Evidence |
|---|---|---|
| `sh tools/godot.sh import` on a fresh source copy without `.godot/` or builds | **PASS** | Exit 0; no script/import errors; `check-00.txt` |
| `sh tools/godot.sh test` | **PASS** | **268 checks, 0 failures**, exit 0; `check-01.txt` |
| `sh tools/godot.sh test --intentional-failure` | **PASS** | 269 checks, exactly 1 deliberate failure, exit 1 as required; `check-02.txt` |
| `sh tools/godot.sh smoke` | **PASS** | Exit 0, no runtime errors; `check-03.txt` |
| `sh tools/godot.sh test --quit-smoke` | **PASS** | Actual menu Quit signal exits 0; `check-04.txt` |
| `sh -n tools/godot.sh` | **PASS** | Exit 0; `check-05.txt` |
| `python3 tools/check_foundation.py` | **PASS** | 7 tests; `check-06.txt` |
| `"$GODOT_BIN" --path . --script res://tests/visual_combat.gd` | **PASS** | macOS OpenGL/Metal Compatibility rendering; combat/pause/results PNGs visually inspected; `desktop-visual.txt` |
| `sh tools/godot.sh android-debug` | **PASS** | Signed ARM64 debug APK, export exit 0; `android-export.txt`; Java warning described below |
| `"$ADB_BIN" -s "$DEVICE_ID" install -r builds/android/nightshift-m2.apk` | **PASS** | Installed updated app on physical Pixel 10 Pro XL, Android 16/API 36 |
| `"$ADB_BIN" -s "$DEVICE_ID" shell am start -n org.nightshiftfm.spike/com.godot.game.GodotAppLauncher` | **PASS** | Real portrait menu/mission launches |
| `python3 tools/android_combat_check.py --adb "$ADB_BIN" --serial "$DEVICE_ID" --canvas-top 264 --canvas-scale 1.5 --output docs/evidence/M2` | **PASS** | 30 physical-device assertions: Start, pause, 20 Home/resume cycles, active OS pause/resume, hold/drag/release, brace, results, restart and second full run; `pixel-combat-check.json`, events JSON, log and PNGs |
| Build Tools 36.0.0 `aapt dump permissions` / `aapt dump badging` on APK | **PASS** | No requested permissions (including Internet); version 0.2.0/code 2, min SDK 24, target SDK 36; evidence text files |
| Human phone playtest and M2 acceptance | **NOT RUN** | Owner must assess responsiveness, readable danger, viable auto-aim and understandable endings |
| Physical iPhone / iOS export rerun | **NOT RUN** | Deferred at owner request; historical M1 missing-Team-ID failure remains below |
| Native achievement sandbox | **NOT RUN** | Existing M1 account/plugin gates remain; no native integration added |

Fresh verification copied source to
`/var/folders/cy/lx2m7tpd07vb9z_vxtj0ckxw0000gn/T/nightshift-m2-fresh-u58oj5ct/project`.
At the time of M2.1 verification, no Git metadata existed; that check was a
fresh-source copy/import. M2.2 above adds actual GitHub and clone evidence.

The ten renderer-independent auto-aim runs and ten scene-driven complete runs
all reached victory without duplicate result subscriptions or stale actors.
The unopposed-enemy fixture reached defeat; its result retained the damage cause.
The two actual Pixel runs both finished three waves in **52.0167 active seconds,
63.6 hull**, with one combat instance and no actors left on results. These phone
inputs were injected through ADB; they are physical-device checks, not human
usability approval. The desktop script also drives state for screenshot capture;
it is not a recorded manual playthrough.

Final APK: `builds/android/nightshift-m2.apk`
SHA-256: `1725916e702de80203a7779a93c4a7de73c108564aa2952bb65494f1c32a6735`.

### Findings, corrections and limitations

- The first export emitted an error about an unspecified project icon despite
  producing an APK. Added the original vector transmitter icon and repeated the
  export; the final log has no export errors.
- The initial tuning let auto-aim finish untouched. A denser final wave and a
  0.48-second pulse interval produced readable breaches while preserving an
  automated win. This is a fixture tuning observation, not a human fun gate.
- Review found that the hidden M1 probe could advance its clock or write global
  pause state while combat was active. Disabled its hidden clock and restricted
  pause ownership to its enabled page; two new regressions pass. Repeated the
  fresh-source checks and physical suite after that fix.
- Android signing still reports JDK 25 native-access warnings from `apksigner`;
  export/install succeed. ADB's “Activity not started … task … brought to the
  front” warnings during resume are expected foregrounding of the live process.
- Combat has no mission persistence in M2. Backgrounding the living process
  freezes/resumes it; process death returns to the menu and loses that mission.
  The pause UI explains this. Checkpoints and upgrade/reward transactions are M3.
- No claim of final art/audio, difficulty balance, thermal/performance soak,
  store eligibility, release signing, iOS acceptance, or native achievements.

**Stopped at M2.** The next action is the owner's Pixel playtest using
`docs/M2_COMBAT.md`; M3 has not started. The one-main/one-shield and five-supports-
from-six limits remain intact, core play remains offline, and permanent power
progression, backend services, monetization and a full catalog were not added.

## Historical M1.2 — iOS deferral and M2 readiness

The owner requested “skip ios for now” and asked what is needed to move to M2.
iOS export/signing and physical iPhone validation are deferred, not passed. The
previous missing-Team-ID export failure remains recorded below. Native sandbox
achievement checks remain NOT RUN pending configuration and account access.

M2 depends on M0, which is satisfied. `docs/MILESTONES.md` explicitly permits
core work while M1 device/account blockers are recorded, so no additional setup
is required to begin M2 on the current Mac and Pixel. Outstanding M1 platform
and usability gates remain required before claiming full M1/release acceptance.
M2 has not started; this revision changes only this status document. No runtime
checks were rerun for this documentation-only update; the M1.1 evidence is retained.

## Historical M1.1 — mobile spike evidence

The owner explicitly authorized M1 after confirming the M0 portrait preview
looked good. The owner identified a Pixel and an accessible iPhone 16. The
connected Android device reports Pixel 10 Pro XL, Android 16/API 36. No physical
iPhone is connected; its OS is unknown. The named hardware/toolchain matrix and
reproducible setup commands are in `docs/MOBILE_DEVELOPMENT.md`.

### Implemented and changed files

| Files | M1 change |
|---|---|
| `project.godot`, `scenes/boot/boot.tscn`, `scripts/ui/boot.gd` | M1 app version/title, stable diagnostic user-data directory, touch-to-mouse UI activation, mobile texture import, separate Mobile checks navigation; main canvas stays 720 × 1280 with fixed aspect |
| `scenes/ui/mobile_probe.tscn`, `scripts/platform/mobile_probe.gd`, `scripts/platform/probe_clock.gd` | Isolated touch/save/load and pause/resume diagnostics; actual pausable Node; explicit OS focus/background handling; instance/drift telemetry |
| `scripts/platform/probe_store.gd` | Versioned numeric-only diagnostic checkpoint, temporary write/flush, validated backup rotation/recovery, honest errors |
| `scripts/platform/safe_area.gd`, `scripts/ui/safe_margin.gd` | OS safe-area pixels transformed into fixed-canvas coordinates; margins and diagnostic border |
| `assets/ui_strings.csv`, generated translation | Localized M1 labels/instructions |
| `export_presets.cfg`, `tools/godot.sh` | ARM64 Android debug and iOS project-only presets; wrapper export commands; no release credentials |
| `tests/integration/test_mobile_probe.gd`, `tests/test_runner.gd` | 20 synthetic cycles, actual pause processing, duplicate notifications, manual-pause preservation, schema/backup/error cases, state restoration and safe geometry |
| `tools/android_probe_check.py`, `tools/check_foundation.py` | Physical-device cycle/force-stop driver; log-rotation regression; mobile localization/preset checks |
| New `.gd.uid` sidecars | Generated by pinned editor, retained with source |
| `docs/.gdignore`, `docs/evidence/M0.2/desktop-menu.jpg` | Exclude documentation from game import; correct old screenshot extension to its actual JPEG format |
| `README.md`, `docs/DEVELOPMENT.md`, `docs/MOBILE_DEVELOPMENT.md`, `docs/NATIVE_ACHIEVEMENTS_SPIKE.md`, this file, `docs/evidence/M1/` | Current status, toolchain/device matrix, reproduction, compatibility research, evidence |

Installed matching **4.7.2.stable standard export templates** into the normal
Godot user directory. Added Android Build Tools 35.0.1. The actual successful
export selected existing Build Tools 36.0.0 with Android Studio's JDK 25.0.3;
this deliberate choice and warning are documented. Set local editor Java path
and disabled exporter shutdown of adb. No repository credentials were added.

### Commands and results

All Godot wrapper commands use
`GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot`.
Android commands use `ADB_BIN=$HOME/Library/Android/sdk/platform-tools/adb`;
`DEVICE_ID` is the selected physical Pixel from `adb devices -l`.

| Check / command | Result | Evidence |
|---|---|---|
| Fresh source copy excluding `.godot/`, `builds/`, `.DS_Store`, `__pycache__`; `sh tools/godot.sh import` | **PASS** | Exit 0, no errors/warnings; `evidence/M1/check-00.txt` |
| `sh tools/godot.sh test` | **PASS** | **133 checks, 0 failures**; includes M0 checks, useful invalid-content errors, and 20 synthetic lifecycle cycles; `check-01.txt` |
| `sh tools/godot.sh test --intentional-failure` | **PASS** | Expected exit **1**, 134 checks and exactly 1 intentional failure; `check-02.txt` |
| `sh tools/godot.sh smoke` | **PASS** | Exit 0; `check-03.txt` |
| `sh tools/godot.sh test --quit-smoke` | **PASS** | Quit exits 0; `check-04.txt` |
| `sh -n tools/godot.sh` | **PASS** | Exit 0; `check-05.txt` |
| `python3 tools/check_foundation.py` | **PASS** | **Seven checks**, exit 0; `check-06.txt` |
| `sh tools/godot.sh android-debug` | **PASS** | Signed APK and verification completed, exit 0; Java native-access warning recorded below |
| `aapt dump badging builds/android/nightshift-m1.apk` and `aapt dump permissions ...` | **PASS** | ARM64; min SDK 24, target/compile SDK 36; no Android permissions requested |
| APK ZIP inventory | **PASS** | No `assets/docs`, `assets/tests`, `assets/tools`, or `assets/prompts` entries |
| `"$ADB_BIN" -s "$DEVICE_ID" install builds/android/nightshift-m1.apk` | **PASS** | Physical device installation reports Success |
| `"$ADB_BIN" -s "$DEVICE_ID" shell am start -n org.nightshiftfm.spike/com.godot.game.GodotAppLauncher` | **PASS** | Actual exported launcher opens the menu; screenshots retained |
| Pixel touch/safe-area check | **PASS** | Device input opened Mobile checks; one tap changed saved counter 9 → 10; controls fit within safe border above system navigation |
| `python3 tools/android_probe_check.py --serial "$DEVICE_ID" --cycles 20 --output docs/evidence/M1/pixel-lifecycle.json` | **PASS** | 20 real Home/foreground cycles; identical active_seconds across every pause/resume, drift=0, instances=1; report status PASS |
| Force-stop/relaunch in that driver | **PASS** | New process restored **10 taps and 126.485294151515 active seconds**, exactly matching the committed checkpoint |
| `sh tools/godot.sh run` and computer-use inspection | **PASS** | Desktop M1 menu and diagnostics rendered; agent opened diagnostics and inspected controls/border |
| `sh tools/godot.sh ios-project` | **FAIL — blocked** | Exporter rejects missing Apple Team ID. No Xcode project or IPA was produced; `ios-export-blocked.txt` |
| Physical iPhone 16 install, safe-area, 20 cycles, force-kill | **NOT RUN** | Phone not connected; OS and signing/provisioning not verified |
| Native sandbox achievement unlock | **NOT RUN** | Game-specific Apple/Play Games configuration, IDs, tester access, and exact plugin compatibility build unavailable; candidate research completed |
| Final human phone-usability acceptance | **NOT RUN** | Agent device interaction is evidence, not owner ergonomics approval; iPhone has not been tested |

Latest fresh copy:
`/var/folders/cy/lx2m7tpd07vb9z_vxtj0ckxw0000gn/T/nightshift-m1-fresh-3sw13qiq/project`.
APK: `builds/android/nightshift-m1.apk` (about 27 MB), SHA-256:
`213c8bd1762458b237ed88923be6a633b5549690c4b0d46236c9c878d10a8147`.
Build outputs are ignored; no Git repository, commit, remote, or push is claimed.

### Failures found, fixes, and warnings

- **Fixed:** the M0 evidence screenshot was actually JPEG bytes named `.png`.
  The first M1 import attempted to import it and reported PNG errors. Renamed
  it correctly and added `docs/.gdignore`. The final fresh import is clean.
- **Fixed:** the first Android export rejected min/target SDK overrides outside
  Gradle and required ETC2/ASTC import. Removed those overrides, enabled mobile
  texture import, and successfully rebuilt using standard-template SDK values.
- **Fixed command:** launching the internal GodotApp activity was denied by
  Android. Resolved the actual exported GodotAppLauncher and used it; no security
  restriction was bypassed.
- **Fixed test-driver bug:** the first physical-cycle run timed out after 17
  completed cycles because log rotation invalidated historical line counts.
  Switched to monotonic app counters, added a regression test, and passed a
  fresh full 20-cycle run plus force-stop recovery.
- Template download was interrupted; HTTP/1.1 resumed the remaining bytes.
  ZIP extraction/CRC checks and the `4.7.2.stable` version file succeeded before
  installation. No partial archive was installed.
- Android SDK CLI printed its deprecation notice; installation succeeded.
  JDK 25's apksigner emitted a native-access warning; signing and APK verification
  succeeded. The initial exporter also stopped adb on exit; the local shutdown
  setting was disabled for subsequent work. These are not device gameplay failures.

### Remaining M1 gates

1. **Deferred at owner request:** owner supplies the real Apple Team ID, connects iPhone 16, and completes
   owner-controlled Xcode signing/provisioning. Export and repeat physical tests.
2. Obtain game-specific sandbox achievement configuration and test-account access;
   compile/test a selected candidate with exact Godot 4.7.2 before claiming native
   compatibility. No native plugin or purchase functionality was installed here.
3. Owner confirms phone text/touch usability on the tested devices.

Core diagnostics run offline, and immutable content/runtime separation and the
one-main/one-shield/five-of-six-support contracts are unchanged. The checkpoint
is only an M1 probe, not mission saving or permanent progression. No combat,
full catalog, backend, monetization, or M2 work was added. **Stopped at M1 with
the above gates open; M1 is not fully accepted.**

## Historical M0.2 — authorized installation and verification

The owner asked to install Godot. Downloaded the standard macOS Universal ZIP
from the official 4.7.2 archive link and installed `/Applications/Godot.app`
without replacing any existing application. Full version:
**4.7.2.stable.official.ed1daf0bf**. `codesign --verify --deep --strict --verbose=2`
passed, and `spctl --assess --type execute --verbose=2` returned `accepted`,
`source=Notarized Developer ID`. No security settings were changed.
Download retained in `~/Downloads/Godot-4.7.2-setup/`.
Export templates remain **NOT RUN / uninstalled**, outside M0.

The first real import exited 0 but printed missing translation errors; that
initial import was **FAIL** for the clean-import criterion. Godot generated
`assets/ui_strings.en.translation`, its CSV `.import` sidecar, and `.gd.uid`
sidecars. These are now part of the source files to retain in a future commit.
The static reference check now requires the generated translation to exist.
No gameplay code change was needed. README and development instructions were
updated to reflect installation and the first-import fix.

All wrapper commands used:

```sh
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
sh tools/godot.sh version
sh tools/godot.sh import
sh tools/godot.sh test
sh tools/godot.sh test --intentional-failure
sh tools/godot.sh smoke
sh tools/godot.sh test --quit-smoke
sh tools/godot.sh run
```

| Latest check | Result | Evidence |
|---|---|---|
| Engine version | **PASS** | Exact pinned standard official build above |
| Fresh-source import | **PASS** | Copied project excluding `.godot/`, `.DS_Store`, and `__pycache__` into a new temp folder; `sh tools/godot.sh import` exited 0 with no errors/warnings |
| Headless tests, original and fresh copy | **PASS** | Both exit 0; **45 checks, 0 failures**, including useful invalid-fixture errors |
| Intentional failure | **PASS** | Exit **1**; 46 checks, 1 intentional failure, expected failure message |
| Headless main-scene smoke | **PASS** | Exit 0, no errors/warnings |
| Isolated Quit signal smoke | **PASS** | Quit signal terminates process with exit 0 |
| Desktop rendering/navigation | **PASS** | Agent inspected screenshots and clicked Start/Back/Settings/toggle; exercised Escape, Tab/Enter, retained setting, wider/taller resizing and letterboxing |
| Desktop Quit/relaunch | **PASS** | Actual Quit click terminated desktop process with exit 0; preview relaunched successfully and left open |
| Shell/Python regressions | **PASS** | `sh -n tools/godot.sh`; `python3 tools/check_foundation.py`: six tests, exit 0 |
| Owner/human approval | **NOT RUN** | Agent interaction does not substitute for the owner's visual acceptance |
| Literal fresh Git clone | **NOT RUN** | Workspace still has no Git repository; clean source-copy import/test was performed |
| Mobile/export/device work | **NOT RUN** | No M1 work performed |

Fresh-copy evidence logs are retained in
`docs/evidence/M0.2/fresh-import.txt` and `fresh-test.txt`.
The temp copy was `/var/folders/cy/lx2m7tpd07vb9z_vxtj0ckxw0000gn/T/nightshift-m0-fresh-j87oteve/project`.
Desktop renderer reported OpenGL 4.1 Metal, Compatibility, Apple M2 Pro.
No engine error or warning appeared in the final test/smoke/desktop runs.
The remaining M0 action is owner inspection of the open preview. M1 remains
unstarted. The sections below describe the original implementation and checks.

## Historical M0.1 evidence

## Inspected baseline and toolchain

Read `AGENTS.md`, all of `docs/GAME_DESIGN.md`, and M0 in `docs/MILESTONES.md`
before writing source. Also inspected README, the start prompt, references, and
the folder inventory. The supplied handoff lives in `nightshift_fm_codex_pack/`,
which is now the project root. Its enclosing plan/ZIP and existing design,
catalog, milestones, references, instructions, and prompts were preserved.

- Host observed: `Darwin 25.5.0 arm64`; Python `3.9.6`.
- `git status --short --branch`: exit 128, no Git repository in the workspace or
  parents. There is no branch, commit, remote, or push result to report.
- `command -v godot` and `command -v godot4`: no executable found.
- Inspected `/Applications`, Downloads, and the Godot application-support path:
  no installed editor found; Godot application-support directory absent.
- `GODOT_BIN` is unset. Actual engine version/build hash and installed export
  template version: **unavailable**.
- Deliberate decision: retain required Godot **4.7.2 stable official standard**
  and matching **4.7.2.stable standard templates**. No fallback, installation,
  engine upgrade, or export setup was performed. Pins are in `tools/`.
- Official archive/API references were checked; see `docs/DEVELOPMENT.md`.

## Implemented M0 scope and changed files

| Files | Scope |
|---|---|
| `project.godot`, `.gitignore` | Standard typed GDScript foundation, Compatibility renderer, 720 × 1280 logical portrait canvas, 450 × 800 desktop window, fixed aspect, named input actions, cache/credential exclusions |
| `scenes/boot/boot.tscn` | Title/menu, honest Start placeholder, Settings, Back, Quit |
| `scripts/ui/boot.gd`, `scripts/ui/transmitter_art.gd`, `assets/ui_strings.csv` | Typed navigation, keyboard Back, session-only decorative signal toggle, original geometric transmitter, localization keys/English text |
| `scripts/core/game_rules.gd` | One main and one shield slot, five-support limit, six family identities, baseline/max rank, content version |
| `scripts/core/definitions/content_definition.gd` | Stable IDs, localization metadata, schema version, basic validation |
| `scripts/core/definitions/{weapon,upgrade,shield,enemy,wave,mission,module,synergy,achievement}_definition.gd` | Nine typed definition skeletons; no full behavior/effect catalog |
| `scripts/core/content_validator.gd` | Useful ID/path/field errors for null definitions, bad identity/metadata, duplicate IDs, basic invalid numeric values, missing references |
| `scripts/core/state/{weapon,shield,run,profile}_state.gd` | Separate runtime data; copied equipment baselines and ID snapshots; per-instance run/profile arrays; permanent options/cosmetics without permanent combat-stat fields |
| `tests/test_runner.gd`, `tests/test_context.gd` | Explicit result counters, suite completion checks, 15-second runtime watchdog, exit codes, intentional failure, isolated Quit smoke mode |
| `tests/unit/test_foundations.gd`, `tests/integration/test_boot.gd` | Definition fixtures, state isolation, constraints, input declarations, translations, page/button-signal navigation, settings and Back checks |
| `tests/fixtures/{valid_weapon,valid_shield,invalid_weapon,missing_reference}.tres` | Four synthetic fixtures only; no playable content |
| `tools/godot.sh`, `tools/engine-version.txt`, `tools/export-template-version.txt` | Portable GODOT_BIN wrapper, strict version-family check, import/test/smoke/run/editor entry points |
| `tools/check_foundation.py` | Engine-independent source/reference/localization and shell-wrapper regression checks using Python standard library |
| `docs/DEVELOPMENT.md`, this file, `README.md` | Exact setup/run/check instructions, limitations, versioned evidence, updated README entry point |
| `.gitkeep` files under scenes, scripts, content, assets | Intended empty folders retained for future milestones |

No production `.tres` content was added under `content/`. No combat, save system,
mission reset orchestration, recruitment, permanent progression system, backend,
monetization, native integration, mobile export, or lifecycle probe is implemented.

## Executed checks and evidence

Commands below were run from the project root. PASS means only the scope described
in that row. NOT RUN means the intended engine check did not execute.

| Check / exact command | Result | Evidence |
|---|---|---|
| `sh -n tools/godot.sh` | **PASS** | Exit 0; POSIX shell syntax check |
| `python3 tools/check_foundation.py` | **PASS** | Exit 0; six tests, `OK`, Python 3.9.6 |
| Source/reference checks within that Python command | **PASS** | Referenced files exist; the only generated translation reference maps to the source CSV; every scene text key has English text; no populated catalog or export preset |
| Wrapper regression checks within that Python command | **PASS** | Fake executable verifies all five forwarding modes from a different CWD, spaces in paths, missing-engine exit 127, mismatch/.NET/RC exit 2, and propagation of exit 9 including test arguments. This is not Godot execution |
| `sh tools/godot.sh version` | **NOT RUN** | Wrapper exit 127: `NOT RUN: set GODOT_BIN to the Godot 4.7.2 standard editor executable.` |
| `sh tools/godot.sh import` | **NOT RUN** | Same exit 127; no GDScript compilation or resource import took place |
| `sh tools/godot.sh test` | **NOT RUN** | Same exit 127; real unit/integration fixtures and positive exit contract unverified |
| `sh tools/godot.sh test --intentional-failure` | **NOT RUN** | Same exit 127; this is not the required intentional test exit 1 |
| `sh tools/godot.sh smoke` | **NOT RUN** | Same exit 127; main-scene headless launch unverified |
| `sh tools/godot.sh test --quit-smoke` | **NOT RUN** | Same exit 127; Quit process termination unverified |
| `sh tools/godot.sh run` | **NOT RUN** | Same exit 127; no portrait window rendered or desktop input exercised |

Source review found no runtime network dependency, credentials, commercial asset,
or plugin. A targeted scan also returned no matches (rg exit 1):

```sh
rg -n 'HTTPRequest|HTTPClient|WebSocket|Multiplayer|OS.execute|BEGIN .*PRIVATE KEY|AKIA[0-9A-Z]{16}' scripts scenes assets tests tools project.godot
```

That scan is supporting source evidence, not a comprehensive secret audit.
No executed check reported FAIL. Engine-dependent outcomes remain unknown.

## Acceptance and limitations

| M0 acceptance condition | Status |
|---|---|
| Fresh clone/import opens with no missing resources | **NOT RUN** — no Git repository or engine; static path check passed but cannot establish import correctness |
| Portrait title, Start/settings/Back flow and Quit work | **NOT RUN** — source and automated tests exist; no rendered or clicked desktop evidence |
| Headless suite exits 0; intentional failure exits nonzero | **NOT RUN** — wrapper behavior passed independently; real runner unavailable |
| Invalid content fixtures produce useful errors | **NOT RUN** — fixtures and assertions implemented, not executed in Godot |
| No credentials, commercial assets, hidden backend dependency | **PASS** — bounded source/dependency review; original geometry and engine UI font only |
| Human desktop portrait inspection | **NOT RUN** — requires the pinned editor and the documented click/resize checklist |
| Device checks | **NOT RUN** — outside M0; no emulator, simulator, or physical-device evidence claimed |

Resources are read-only by ownership convention, not forcibly frozen by Godot.
Runtime code never writes loaded definitions; isolation tests await execution.
The validator covers the M0 schema only. Complete typed effects, compatibility,
branch reachability, unlock cycles, and achievement reference validation belong
with their future systems. Slot limits are declared contracts; no M0 equip API
claims to enforce recruitment. Run/profile data shapes do not claim working saves
or tested mission resets. UI layout, compiler warnings, and engine errors remain
unknown until import and desktop execution. No FPS, mobile safe-area, playtesting,
signing, store, or release acceptance is claimed.

## Remaining M0 acceptance action

Install the pinned standard editor, set `GODOT_BIN`, and follow
`docs/DEVELOPMENT.md`: capture full version output, import fresh source, run the
normal and intentional-failure suites, headless main-scene and Quit checks, then
the desktop navigation/resize/quit checklist. Record exact output, warnings, and
human observations in the next evidence revision. Stop at M0 until this evidence
is recorded; do not begin M1 as part of this change.

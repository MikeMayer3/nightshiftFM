# Nightshift FM — resume here

## 0.10.15 GitHub publication (2026-09-11)

Release source includes damage numbers with critical emphasis, close hit placement,
Turntable note drones, a once-per-run Mixer reminder, and Android Back fixes.
The validated phone-delivered APK is published under `v0.10.15` with the
construction summary and SHA256SUMS. See the [release](https://github.com/MikeMayer3/nightshiftFM/releases/tag/v0.10.15).
The repository is now public (verified against GitHub); downloads do not require
repository membership. Private phone backups remain excluded from Git and APKs.
Version 0.10.15/code 27 was installed with all six save/settings files preserved;
the phone was locked, so final visible launch/gameplay checks remain NOT RUN.
Future updates should install automatically when the physical phone is connected.
Prior local-only and old-version entries below describe historical state.

## 0.10.15 phone delivery and standing preference (2026-09-10)

Installed **0.10.15 / code 27** on the connected physical Pixel with the Mixer
reminder, close damage numbers and Turntable note drones. All six existing
save/settings files stayed byte-identical through install and process launch.
Android reported a successful launch and the game process had no runtime errors.
The phone was locked, so visible in-app launch/gameplay verification was NOT RUN.
APK: `builds/android/nightshift-fm-0.10.15-android-arm64-debug.apk`.
SHA-256: `6291dcdffa2e426426c92ed7087cbbf8decc479591e7d844c9da47d0cd326843`.
Export/packaging passed; private backups and tests/docs/tools are excluded.
**Standing owner instruction:** automatically build/install validated game updates
when the physical phone is connected. Recorded in `AGENTS.md` for future sessions.
Source remains uncommitted/unpushed; GitHub release remains 0.10.13.

## Mixer reminder and note drones (2026-09-10)

Added a once-per-run Mixer reminder, moved damage numbers over their target, and
changed Turntable notes to drones that fly in, orbit, fire three baseline shots and
despawn. Upgrades add shots/notes or improve rhythm/marks. Retargeting, protected
entry and legacy note-save migration are covered. See [NOTE_DRONES.md](NOTE_DRONES.md).
PASS: 6,159 regressions, import/smoke, 15 native visual/input checks, six captures,
and a ten-wave automated win with 17 checkpoint restores (13 with live drones).
These new changes are **local, uncommitted, unpushed and not yet packaged/installed**.
The phone remains on 0.10.14; GitHub remains on 0.10.13. Physical gameplay acceptance
for the drone revision and the previous Android shield-caption issue remain open.

## 0.10.14 phone delivery (2026-09-10)

Installed Android **0.10.14 / code 26** on the physical Pixel with damage numbers,
critical-hit emphasis and the local Android Back-navigation fixes. Package version,
foreground launch and visible menu were verified; current-process logs contained
no runtime errors. All six existing save/settings files remained byte-identical
through install and launch. Private backups/screenshots are excluded under `builds/`.
APK: `builds/android/nightshift-fm-0.10.14-android-arm64-debug.apk`.
SHA-256: `44b9957c303e348a34208cb1fb9998d9ff1d86ea44f41330b6dfd5c438148bc8`.
Export passed; APK includes damage-number code and excludes docs/tests/tools/builds.
Source is still **uncommitted/unpushed**; GitHub release remains 0.10.13.
Damage-number gameplay visuals have desktop fixture evidence; physical gameplay
acceptance and the earlier intermittent shield-caption issue remain open.

## Damage numbers (2026-09-10)

Added floating enemy damage numbers with larger gold criticals, a stronger pop,
and longer critical lifetime. Rapid hits combine separately by critical status;
reduced effects and large text are respected. Gameplay damage/RNG are unchanged.
PASS: import, 6,146 regressions, desktop smoke, 18 rendered checks across nine
phone-size/desktop screenshots. Physical-phone feature checks: **NOT RUN**.
Changes remain **local, uncommitted and unpushed** on top of the release-audit fixes;
phone and GitHub APK still contain 0.10.13. Prior Android glyph issue remains open.
See [DAMAGE_NUMBERS.md](DAMAGE_NUMBERS.md) for scope, commands and evidence.

## Release playthrough audit (2026-09-10)

Audited 0.10.13 and fixed two Android Back-navigation bugs locally: Mixer opened
from Pause now closes back to Pause, and contribution reports return to results.
PASS: 6,130 regressions; two rendered ten-wave victories; 17 completed simulation
cases and 300 checkpoint restores; 120 layout captures; 36 maximum-deck checks;
13 physical Pixel OS-input checks repeated twice in an isolated QA app.
**OPEN:** intermittent missing shield-caption glyphs in fast phone result/report
transitions; slower replay renders correctly. Evidence and remaining production
AAB, privacy/listing, 16 KB runtime, device/human and Play testing gates are in
[RELEASE_PLAYTHROUGH_AUDIT.md](RELEASE_PLAYTHROUGH_AUDIT.md).
Source/audit changes are **local, uncommitted and unpushed**. The player's app and
GitHub APK remain 0.10.13. Earlier delivery entries below are historical.

## 0.10.13 delivery (2026-09-10)

The scrolling and compact-upgrade fixes are committed and pushed to `main` at
`172bd9c`; release tag `v0.10.13` points to this source commit.
Physical Pixel **0.10.13/code 25** installed and visibly launched; all six existing
save/settings files remained byte-identical through install and launch, with no
runtime errors. APK SHA-256: `0fff8e6594153b2c0400a3a1a8423067bb2c4efcc3b4943a086f1e214e83f346`.
APK contents were checked to exclude local backups and test/build directories.
Prior native, regression and Android input results remain documented below.
[GitHub 0.10.13 release](https://github.com/MikeMayer3/nightshiftFM/releases/tag/v0.10.13)
contains the clean APK, anonymized construction summary and checksums. A complete
authenticated APK download matches the installed SHA-256. The repository is private;
sign in to GitHub to download. Fresh staged-source import and 6,125 regressions passed.
The older 0.10.11 APK and checksum were removed with explicit approval; their
absence was verified. The source tag and construction summary remain available.
Use 0.10.13 for sharing.
Earlier local-only and disconnected-phone notes below are historical and superseded
by this entry.

## Compact Tuned upgrade cards — 0.10.13 (2026-09-10)

Compacted card padding, art, information-button placement and connection hints;
Help now shares the Reroll/Banish row. All three choices/actions fit without scroll
in the tested normal/large-text layouts. PASS: 510 native layout/input checks,
6,125 regressions, 22 Android emulator checks, eight foundation checks and export.
The APK also excludes local backup/build folders after an export inspection found
they were being bundled. [Details and evidence](COMPACT_UPGRADES.md).
**Local/uncommitted**. APK is 0.10.13/code 25; the disconnected physical Pixel's
last verified build remains 0.10.12/code 24. This update is not installed on it.

## Scrolling correction — 0.10.12 (2026-09-10)

Implemented full-page mouse/native-touch dragging across every scroll screen,
including text, art, cards, margins and the app area outside centered sheets.
Taps, selectors and mixer faders remain usable. PASS: 6,125 regressions, 826
native desktop checks, seven foundation checks, 66 physical Pixel swipes and four
physical control checks. Android **0.10.12/code 24** installed and visibly launched;
all six existing save/settings files remained byte-identical, with clean logs.
[Scope, commands, evidence and test-fixture correction](SCROLLING_FIX.md).
Changes are **local and uncommitted**; the existing GitHub release is unchanged.
Human extended usability testing remains NOT RUN. Earlier entries are historical.

Git handoff: see [`handoff.md`](../handoff.md) for the consolidated commit scope
and current resume instructions. Earlier local/uncommitted statements below are
historical checkpoints superseded by that handoff.

## Latest: P6 progression goals (2026-09-10)

Pixel delivery: **0.10.11/code 23** installed in place; six save/settings files
byte-identical after install and launch. Version/process/resumed activity and
runtime logs passed. Phone locked: visible P6 phone UI NOT VERIFIED.
Clean staged-source import and 6,084 regressions also passed.

P6 is implemented. Read [P6_PROGRESSION_GOALS.md](P6_PROGRESSION_GOALS.md) and the root [handoff.md](../handoff.md) for current source/device state. PASS: 6,084 regressions and 195 native checks. Human next-goal comprehension remains open. P5 and P6 are included in the consolidated source handoff. Do not automatically start P7. The next requested work should address 1.0 readiness and its remaining human/release gates. All P5 and earlier next-task/local-state notes below are historical.

Latest roadmap implementation: **P5 — Wideband upgrade payoff** (2026-09-10).
See [P5_UPGRADE_PAYOFF.md](P5_UPGRADE_PAYOFF.md) for current verification and limits.
One existing build gets a twin-cone cabinet, segmented pressure fronts and one
original music layer at its actual rank-3 Wideband choice. Source is local,
uncommitted and unpushed. Pixel now has P5 0.10.10/code 22; visible menu launch and save preservation passed.
**Next bounded task: P6 — visible next unlock and progression goals**, when requested.

The P4 and older entries below are historical delivery checkpoints.

Latest roadmap implementation: **P4 radio personality and boss anticipation**
(2026-09-10). First-region broadcasts, original stings, and the existing Caller's
five-second approach warning are implemented. See
[P4_RADIO_PERSONALITY.md](P4_RADIO_PERSONALITY.md).

PASS: 5,687 regressions, 86 native UI/audio/save-control checks, eight complete
campaigns / 622 checks, import, seven foundation checks, smoke, and Android export.
**0.10.9/code 21** is installed and launched on the Pixel 10 Pro XL. All six prior
save/settings JSON and backup files remained byte-identical after install and
launch; runtime log is clean. The phone was locked, so visible game UI was not
verified. Human tone/listening and P4 gameplay acceptance
remain NOT RUN. Source is **uncommitted/unpushed**.

**Next bounded task: P5 — one build's major-upgrade payoff**, when requested.

Previous roadmap implementation: **P3 first-session guidance and phone reliability**,
installed on the Pixel 10 Pro XL as **0.10.8/code 20** (2026-09-10). Read
[P3_ONBOARDING_RELIABILITY.md](P3_ONBOARDING_RELIABILITY.md). Hints teach actual
shield/boost/Mixer use, remember their display, and replay through Help. Handedness
now moves the visible shield button. Existing saves/settings were preserved.

PASS: 5,659 regressions, 70 native UI/audio checks, ten emulator interruption/
reward/power cases, and a twenty-minute physical soak. Pixel sampled 58–61 FPS,
no thermal throttling, 4.75% cleanup-memory growth. USB-powered measurements do
not establish battery drain. Human first-session comprehension and unavailable
physical hardware remain open. Owner feedback on P2 was positive.

P4 was subsequently implemented; see the current entry above. All current source
changes remain **uncommitted/unpushed**.

Previous roadmap implementation: **P2 loss feedback**, delivered to the connected
Pixel 10 Pro XL as **0.10.7 / code 19** on 2026-09-10. Read
[P2_LOSS_FEEDBACK.md](P2_LOSS_FEEDBACK.md). Results explain recorded health loss,
reports use graphical bars, old saves remain compatible, and Retry starts fresh.
5,644 regression checks, 48 legal campaign comparisons (34 wins/14 losses), and
27 rendered/input checks passed. Save/settings hashes were unchanged after
install and launch. No combat values changed; human balance/loss comprehension
remain open. Source and prior local work are **uncommitted/unpushed**.

P3 was subsequently implemented; see the current entry above.
Do not assume existing automated checks establish unfamiliar-player usability.

Previous roadmap implementation (2026-09-10): **P1 graphical build guidance**.
Read [P1_BUILD_GUIDANCE.md](P1_BUILD_GUIDANCE.md). Upgrade cards preview real
connections; details and Mixer show illustrated gear pairs, prerequisites,
activation conditions and tradeoffs. A derived warning flags redundant Net/Bass
jam. No combat values or save fields changed. Compared 48 legal campaigns and
452 JSON decision restores; precision leads the fixed policies, with wins/losses
for every archetype. Broader balance and human distinctness remain open.
This P1 work is included in the P2 Android delivery. Source remains uncommitted
and unpushed; see the current P2 entry above for final verification totals.

Roadmap work started (2026-09-10): P0's [unfamiliar-player kit](playtesting/P0_GUIDE.md)
is ready, with a facilitator script, per-participant feedback sheet and blank
observation/findings logs. Human sessions and candidate artifact preflight remain
NOT RUN; no new APK was built/installed. P1 (distinct builds) is the next suggested
implementation task, with P2 also able to use existing owner balance feedback.

Planning addition (2026-09-10): [additions and launch roadmap](ADDITIONS_ROADMAP.md)
records proposed P0–P7 gameplay/playtest tasks and G1–G3 publicity tasks, with a
copyable single-task Codex prompt and acceptance criteria. Documentation only;
select one task explicitly before implementation. Existing delivery notes below
remain authoritative for what has actually shipped.

Latest addition: **visible shield boost**. Violet defense dome, actual reserve
number, temporary-shield meter line and duration strip, and `Shield Boost` /
`BOOSTED` button states. Bars now stay 76 logical pixels tall. See
`docs/SHIELD_BOOST_VISUAL.md`. PASS: 5,561 regression / 60 rendered shield checks,
seven foundation checks, import and smoke. Local only, not installed or pushed.

Latest HUD revision: **living-enemy waveform and taller labeled health/shield bars**.
Read `docs/COMBAT_METERS.md`. More enemies mean higher amplitude and shorter period;
zero enemies flatten the signal. Health/shield text is inside the separate bars.
PASS: 5,561 regression / 63 rendered checks, import, smoke and seven foundation
checks. Evidence: `docs/evidence/M10-meters/`. Local, not installed or pushed.

Latest addition: **all five approved battlefield polish recommendations**, recorded
in `docs/BATTLEFIELD_POLISH.md`. Mountains/pines and a health-reactive studio now
match the splash; hit/net reactions, breach cues, uninterrupted wave notices and
instrument upgrade highlights are implemented. PASS: 5,555 regression checks,
15 dense rendered checks, 88 complete-run checks (two ten-wave runs, 42 legal
upgrades), import, smoke and seven foundation checks. Evidence is under
`docs/evidence/M10-battle-polish/`. Not installed on the phone, committed or pushed.

Latest local work: **station splash and combat presentation polish**.
The owner subsequently requested less realism: the active splash is a flat,
outlined illustration retaining the station/tower/mountain mood. Import, smoke
and 105 rendered checks passed after the replacement; see the recorded prompt
under `assets/art/splash/REDRAW_PROMPT.md`. Still not installed or pushed. Read
`docs/PRESENTATION_POLISH.md`. Added the requested station/tower/mountain/shadow
enemy title artwork; improved net, bass and main-weapon effects; fixed missing
shot cues, effects fading during choices, duplicate card captions and awkward
results buttons. 5,537 regression / 104 layout / 47 rendered playthrough checks
passed; two full legal runs finished, plus direct desktop UI checks. Evidence:
`docs/evidence/M10-polish/`. This polish has NOT been exported or installed on
the phone, committed, or pushed. Human/physical-phone approval is still pending.

Latest delivery: **0.10.6 / Android version code 18**, on `main`.
Latest delivered changes: **continuous waves / combat balance / module art**.
The working tree now contains the owner-requested revision documented in
`docs/RADIO_BALANCE.md`: no timed wave countdown, offscreen enemy entry protected
from all attacks, shorter station reach, stronger late-wave enemies, and twelve
illustrated module cards without toggle switches. See
`docs/evidence/M10-balance-modules/module-gallery.png` for the graphics.

This work was exported and installed in place on the physical Pixel as 0.10.6.
All six JSON files matched after install; mission saves and presentation settings
remained byte-identical after launch. No runtime script/crash errors were found.
Evidence: `docs/evidence/M10-balance-modules/pixel-install.json`.
Source changes remain uncommitted and unpushed.
Same-seed simulations changed from 48/60 to 36/60 victories. Equipped build checks
won 17/18 with 254 successful upgrade-checkpoint restores; strong builds remain
powerful. Rendered/input checks passed at 360×640 and 450×950. Read the current
implementation-status entry for exact validation and acceptance boundaries.
No subsequent milestone was requested.

Repository: `https://github.com/MikeMayer3/nightshiftFM`.
Checkout: `/Users/michaelmayer/Projects/Nightshift FM/nightshift_fm_codex_pack`.
Read `AGENTS.md` and `docs/IMPLEMENTATION_STATUS.md`, then verify Git state before
starting the next user request. No additional milestone was requested at handoff.

The latest source includes:

- Studio mixer replacing the primary patchboard: Direct, AOE, Control faders;
  3 points initially, 5 after mission 4, 7 after mission 12, max 4 per fader.
  Free redistribution during paused combat; optional connection view; no forced
  connection intermissions in new broadcasts. Run-local settings survive Continue.
- Randomized decimal FM targets, deterministic on resume, with independent
  presentation RNG; richer modern-device enemy art and compact status cues
  replacing confusing enclosing circles.
- Prior campaign, difficulty, Contracts, Endless, and achievement implementation
  remains in place. These requests do not establish human acceptance of every
  earlier milestone; use the documented evidence boundaries.

Validation: 5,494 regression checks, 156 rendered/input checks at 360×640 and
450×950, seven foundation checks, import and startup smoke passed. Isolated
Android emulator touch tests passed for slider dragging, budget limits,
redistribution, frozen time and app-restart persistence.

Previous mixer delivery: Pixel 10 Pro XL was updated in place to 0.10.5 and launched successfully.
Both save files remained byte-identical before/after installation and launch;
no script/crash errors were found. Evidence: `docs/evidence/M10-mixer/`, especially
`pixel-install.json`. Player package is `org.nightshiftfm.spike`; the emulator QA
package is `org.nightshiftfm.mixerqa`. Save backups and APKs remain under ignored
`builds/`; do not commit them. Human gameplay/balance/usability acceptance is not
established by these checks.

Mixer rules: `docs/STUDIO_MIXER.md`. Art direction: `docs/RADIO_ART_DIRECTION.md`.
Pinned engine: Godot 4.7.2. Normal commands:

```sh
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
sh tools/godot.sh import
sh tools/godot.sh test
sh tools/godot.sh smoke
```

The user prefers compact graphical UI, vintage radio instruments defending a
station against modern audio devices, and autonomous execution of authorized
work. Preserve existing saves and report actual device, test, and Git outcomes.

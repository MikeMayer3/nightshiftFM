# Milestones and acceptance gates

> **M4 support-turret revision:** Equipped Arc, Bass and Net appear as small
> turrets with live cooldown bars. New runs receive slightly stronger earned
> Burst scaling; old saves retain their rules. See [random-build and emulator
> evidence](M4_SUPPORT_TURRETS.md).

> **M4 active-play revision (2026-09-08):** Following feedback that the kill-meter
> build was too passive, new missions add aimed Burst attacks and grouped enemy
> threats. The battlefield expands into the space formerly used by bottom text.
> See [active combat rules and evidence](M4_ACTIVE_COMBAT.md). Old saves retain
> their original gameplay. This remains M4; later milestones have not started.

> **Owner-directed M4 flow revision (2026-09-08):** New missions now use longer
> waves and a kill-filled Signal meter. Each fill pauses the current fight for
> one offensive upgrade or a new weapon. This supersedes the fixed 27-pick,
> end-wave draft/recruitment schedule and defensive choice quotas for new runs.
> Existing M3/M4 saves retain their original rules. Mid-wave upgrade checkpoints
> preserve actors and effects; the radio-tuner art is deferred. See
> [M4 Signal flow](M4_SIGNAL_FLOW.md) for the implemented rules and balance data.
> Remaining later-milestone material below is a roadmap, not implemented scope.

This roadmap deliberately separates technical proof, gameplay proof, and content production. Work on one requested milestone at a time. A generated scene or successful compilation is not evidence that a milestone's gameplay criteria passed.

Every milestone ends with an updated `docs/IMPLEMENTATION_STATUS.md`: scope implemented, changed files, exact commands, PASS / FAIL / NOT RUN results, manual checks, known defects, and remaining acceptance conditions. Keep automated tests for earlier milestones running. Each milestone's prompt is: **“Implement M[number] only, using AGENTS.md and this milestone's acceptance criteria. Stop and report evidence.”**

## M0 — Project foundation

**Dependencies:** none.

**Build:** initialize a Godot 4.7.2 standard/GDScript project, portrait boot/menu scene, original geometric placeholders, intended folder layout, input-action names, content-definition skeletons, and a minimal typed test runner. Add a `GODOT_BIN` wrapper, `.gitignore`, engine/template version notes, and desktop import/run documentation. Define a versioned implementation-status document. Do not build the complete combat game or populate the catalog.

**Acceptance:** a fresh clone/import opens without missing resources; the main scene displays a title and a working start-placeholder/settings navigation flow; quitting works; a headless test exits zero on success and nonzero on an intentional failure; invalid content fixtures produce useful errors. The project contains no credentials, commercial assets, or hidden backend dependency.

**Human check:** run the desktop build and inspect the portrait window. If the engine is unavailable, these checks remain NOT RUN rather than passed. Document exact setup requirements.

## M1 — Android/iOS export and lifecycle spike

**Dependencies:** M0. This risk-reduction work should happen early. Core work can proceed from M0 while a device/account blocker is recorded, but release cannot pass without the platform evidence.

**Build:** install matching export templates and document Android/iOS export presets without secrets. Make a native Android debug build and an iOS Xcode export of the minimal scene. Add safe-area probes, a touch button, a pause/resume counter, and a small save/load probe. Record the actual development Mac, Android device, intended oldest-supported iPhone, SDK/Xcode versions, and test OS versions; do not invent missing hardware information.

Investigate achievement integration feasibility now: identify compatible maintained native plugins or a minimal native bridge; record source/license/version and run a small sandbox achievement test when accounts/device access allow it. This is a spike, not production integration. A plugin name in a document is not proof it works.

**Acceptance:** install/launch works on a physical Android device and an intended physical iPhone; touch controls respect safe areas; twenty background/foreground cycles do not create duplicate scenes or advance the paused counter; force-kill/relaunch recovers the save probe. Distinguish physical-device results from simulators. Android release-signing and iOS provisioning remain owner-controlled.

**Human gate:** verify readable UI and usable touch controls on actual screens. Log any platform/plugin blocker now, not at the end of development.

## M2 — Gray-box combat loop

**Dependencies:** M0; M1's mobile validation should be performed as hardware becomes available.

**Build:** fixed bottom transmitter, top spawn band, one main gun, one shield, hull/shield UI, auto-targeting, tap/drag focus, active shield button, and three enemies: swarmer, diver, and carrier. Add a three-wave test mission, one ranged-projectile test fixture, pause, victory, death, results, and restart. Keep stats fixed; no full upgrade economy yet.

**Acceptance:** enemies spawn only in the intended band and use their defined paths; a breach anywhere on the bottom line damages the station once; an enemy killed at the boundary cannot also breach; shield absorbs first and excess reaches hull; a carrier cannot spawn endlessly; pause freezes gameplay timers and damage; restarting clears actors and timers. Ten consecutive complete runs do not duplicate signals or leave stale enemies.

**Human gate:** the main gun feels responsive, danger is readable, auto-aim is viable, and it is possible to explain why a run ended. Adjust this before building deep progression.

## M3 — Upgrade drafts, rank state, and checkpoint saves

**Dependencies:** M2.

**Build:** generic upgrade-track state; an initial Arc Aerial support; main/shield upgrades; three-choice draft UI; the ten-wave/27-normal-selection mission structure; recruitment schedule with mocked extra families only in tests; rerolls and banishes; eligibility/bad-luck protection; immutable content/runtime separation; versioned profile and run saves; wave-start recovery and upgrade-screen recovery.

Implement independent RNG streams and persist their states. Add a lightweight combat event model with root/source IDs so later achievements and synergies do not need to infer events from visuals.

**Acceptance:** seeded tests exercise at least 10,000 generated drafts across fixtures; no duplicate, incompatible, maxed, or illegally banished choice is offered; quotas and overdue-track policy pass; fewer-than-three and no-valid-option cases cannot deadlock. Exactly 27 normal choices occur before the tenth-wave finale. Normal upgrades cannot purchase an extra support slot. Main and shield are independent of the five-support cap.

Save/reload preserves current offers, accepted choices, counts, and RNG state. Interleaving cosmetic RNG calls does not alter upgrade choices. Starting a new mission resets ranks and temporary modifiers while preserving unlocked IDs. A second run does not inherit mutated values from the first run's resources. Loading an intentionally truncated save recovers from backup or produces a safe recovery screen. A results reward commits once despite repeated reloads.

**Human check:** read every card on a small screen. Players can understand current rank, next branch, prerequisites, and what reroll/banish will do.

## M4 — Three-support vertical slice and fun gate

**Dependencies:** M3.

**Build:** Arc Aerial, Bass Driver, and Static Net with enough complete rank-1–8 content to demonstrate two contrasting branches per family. Implement the relevant status rules, correct visual tells, a ten-wave mission, an elite finale, and two deliberately different viable builds. Add a simple post-run contribution report. Use placeholders with better feedback, not final art production.

The third branch per family and the remaining support families are deferred to M5. Show only real implemented options in this build. Recruitment declines permit focused builds despite the three-family temporary roster.

**Acceptance:** a focused damage/exposure build and a control/defense build can each complete the same Standard mission in documented human playtests. Rank-3 and rank-6 choices visibly change behavior; rank-8 effects have bounded output. Status caps, immunity/resistance fallbacks, shield breaks, and repeated pause transitions pass regression tests. Support value is reported as control/interception/healing as well as damage.

**Human gate — do not skip:** have at least three testers play two attempts each on phones when available. Record upgrade choices, loss causes, confusing UI, and whether they voluntarily request another attempt. Treat six play sessions as qualitative feedback, not statistically conclusive research. At least two distinct winning builds must be demonstrated. Fix the core loop if testers cannot identify meaningful choices or read the screen. Do not use more missions or weapons as the fix.

## M5 — Complete the six-family arsenal, main guns, and shields

**Dependencies:** accepted M4 gameplay gate.

**Build:** Echo Deck, Needle Swarm, and Reverb Well; complete all six families' three specializations, two modifiers per specialization, and capstones; the 108 support-upgrade definitions; three main chassis and three shield chassis with their complete compatible upgrade tracks. Fill all branch coefficients, durations, caps, and cooldowns into validated data. Do not leave fake descriptive cards that do nothing.

Implement the actual arsenal choices and maximum five supports. Add enemy/pattern fixtures that expose the role of each family. Expand the branch preview and comparative stat UI. Give Echo/beam/volley interactions explicit contracts rather than treating them as the same projectile prefab.

**Acceptance:** every exposed upgrade has an effect test and valid prerequisites; every branch can be reached by legitimate upgrade selections; no run can equip six supports or duplicate a family; main and shield never consume a support slot. Echoes cannot echo echoes. Every rank-8 track reconstructs identically from a save. Beam tuning cards do not modify unused projectile stats.

Run the all-weapons stress fixture and record bottlenecks. Human-test at least one focused, one area-control, and one defensive build. Any family that is always mandatory or always ignored becomes a balance investigation, not a reason to add a seventh weapon.

## M6 — Patchboard synergies and bounded effects

**Dependencies:** M5.

**Build:** two active connection slots; connection discovery/tutorial; eight recipes from the catalog; intermission rewiring; prerequisite previews; shared-endpoint rules; connection-specific telemetry. Add explicit internal cooldowns, generation flags, and event attribution.

**Acceptance:** at most two distinct valid recipes can be active; inactive or unequipped recipes do not trigger; rewiring does not leave event listeners from the removed recipe; each recipe passes trigger and no-trigger tests. Echo/reflection/retaliation combinations terminate. Generated damage cannot restore the originating shield in the prohibited feedback loop. Boss resistance leaves documented control-build value without allowing permanent stun-locks.

A bounded worst-case proc test produces no runaway event count or unbounded entity creation. The game never silently drops damage to pass the test. Human-test at least three combinations with distinct strengths and weaknesses and verify that their UI descriptions match actual behavior.

## M7 — Persistent options and player progression

**Dependencies:** M6.

**Build:** campaign-selection shell, equipment unlock schedule, two module slots, twelve tradeoff modules, loadout presets, mastery cosmetics, recipe codex, and mission-medal records. At this stage existing mission content may use clearly labeled placeholders; new battle content comes in M8. Add migration fixtures and run/profile isolation tests.

**Acceptance:** main combat stats reset to the selected chassis/module baseline each mission; module tradeoffs appear in previews and resulting combat stats; no secret permanent percentage growth occurs. The support unlock schedule grants Echo after mission 2, Reverb after mission 3, and Needles after mission 4 exactly once. Replaying completion does not duplicate unlock rewards. Removed/renamed content IDs migrate safely.

Loadout presets cannot equip locked, duplicate, or excessive modules. Persistent cosmetic/mastery rewards survive reinstall-style save migration fixtures where a save is provided. Do not promise automatic recovery after an actual uninstall without a defined cloud-backup solution.

**Human gate:** the first four missions teach choices progressively rather than exposing every module and connection at once. Players can identify what persists and what resets.

## M8 — Campaign, enemy variety, bosses, and Contracts

**Dependencies:** M7.

**Build:** twelve missions across three regions; eight base enemy families; three bosses; authored elite finales; Standard, Hard, and Overload definitions; mission-specific medals; six Contracts. Create bounded wave templates with readable telegraphs and formation variety. Add enemy/boss codex entries and twelve mission-log rewards.

**Acceptance:** each campaign mission runs from start to results; higher difficulty unlocks and overrides are valid; every boss can be defeated without one required support family. Support casters and jammers have recoverable counterplay. Auto-targeting can select active boss weak points. Contract overrides are explicit, including the main-only contract's no-support rule.

Run a content reachability validator on mission unlocks, chassis, modules, branch paths, and later achievement references. Demonstrate at least three strategic archetypes across the campaign; record failed builds too. No mission introduces an unavoidable, unexplained first-seen mechanic in its final wave.

**Human gate:** confirm campaign pacing and meaningful enemy variety rather than twelve recolored versions of the same wave schedule.

## M9 — Achievements, Endless, and post-run analysis

**Dependencies:** M8; event foundations from M3 onward.

**Build:** all 48 local achievement definitions and progress screens; cosmetic rewards; tracked goals; contribution/defeat reports; Endless mode and local best scores. Native-service synchronization is M11, but use the platform interface/no-op implementation now without making login mandatory.

Endless uses the standard recruitment windows before waves 2/4/6/8. At the end of wave 10, award three drafts and continue. After wave 10, grant one normal draft per completed wave; add recruitment windows before waves 12 and 16 only when below five supports. All equipment still caps at rank 8. After no valid upgrades remain, offer bounded consumable repair/refill choices rather than unlimited permanent-stat ranks. Each fifth later wave has an elite/boss remix and a documented scaling step. Leaving or dying commits the finished-wave score once.

**Acceptance:** each achievement has at least one positive and one negative fixture; max-support history, hull-damage history, distinct-capstone sets, true shield breaks, and difficulty/mode restrictions behave correctly. Repeated events, repeated results screens, and wave-checkpoint rollback cannot duplicate rewards. A progress migration preserves earned achievements. Editor/debug runs never qualify.

Endless wave 20/40/60 triggers are tested using controlled fixtures and separate human playtests; do not claim sixty-wave balance from a fixture. There is no dead draft screen after maxing equipment. Reports correctly attribute echo/reflection damage, effective rather than overhealed shield gain, and control contribution. No report double-counts damage as both original and echoed.

## M10 — Mobile polish, accessibility, and balance verification

**Dependencies:** M9 plus available M1 physical-device exports.

**Build:** approved original art, distinct silhouettes, readable hit feedback, sound/music, optional haptics, reduced-flash/shake options, low-effects mode, left/right-handed controls, scalable UI text, and final safe-area layouts. Profile and optimize measured bottlenecks. Add localization-ready strings even if release is English-only.

**Acceptance:** normal gameplay and upgrade decisions are usable without sound; statuses are not color-only; all interactive elements work on the smallest supported screen and representative tall/notched/tablet layouts. Every frame-critical effect has a low-effects presentation alternative without changing combat rules. Maintain a named device/OS results matrix.

Measure the 150-enemy/400-projectile stress fixture and worst real authored encounter on baseline devices. Provisional goals are 60-fps normal mode with p95 frame time <=20 ms, or 30-fps reduced-effects mode with p95 <=36 ms; report actual results and adjust scope/device support explicitly if necessary. Run 20-minute physical-device thermal/memory soaks. Compare equivalent warm-up/cleanup snapshots; investigate persistent memory growth over 10%.

Force-stop during combat, during a draft, after an accepted choice, and on results. Verify the documented checkpoint behavior and no reward duplication. Test interrupted audio, backgrounding, battery-saving settings, and denied/absent platform login. Record balance observations by mission and chosen build rather than assuming win rate alone proves fairness.

**Human gate:** approve visuals, controls, difficulty progression, and store-facing screenshots before release work is called complete.

## M11 — Native achievements and release candidate

**Dependencies:** M10; resolved M1 native export/plugin feasibility; owner-provided accounts/signing configuration for the affected checks.

**Build:** production Game Center and Google Play Games achievement adapters using verified compatible integrations; authentication status UI; retry-safe synchronization queue; mapping from internal IDs to configured platform IDs. Prepare Android release and iOS archive workflows, app identity, icons, version numbers, license notices, and a release checklist. Core play still works offline without sign-in.

Review current official SDK/target-platform, architecture/native-library, signing, testing, data-disclosure/privacy, age-rating, and store-submission requirements at implementation time. The owner must supply accurate business details and approve legal/store declarations. No fabricated privacy claims or secret credentials in source control.

**Acceptance:** on real devices and appropriate sandbox/internal-testing accounts, native achievements unlock and increment correctly; reconnecting after offline play does not multiply progress; an account change does not overwrite unrelated local data. Unsupported/unavailable services fail gracefully. Signed release builds launch and play, not just debug builds.

Internal beta testers complete the onboarding and at least one region on both platforms. Release packaging contains only intended licensed assets and dependencies. Known blockers and platform-specific issues are documented. Final submission/publishing is a separate owner-authorized action, not automatic milestone behavior.

## Cross-cutting regression checklist

| Area | Must remain true |
|---|---|
| Limits | At most five support families, no duplicates; main and shield are separate |
| Reset | New missions clear run power but retain unlocked options and cosmetics |
| Combat | Kill/breach/death events resolve once; no negative health or invalid intervals |
| Branches | Required choices remain reachable; no impossible or ineffective upgrade card |
| Drafts | Seeded/recoverable choices, quota compliance, no deadlocks, no maxed offers |
| Effects | Bounded echoes/reflections/retaliation; caps and boss fallbacks are tested |
| Save | Versioned, recoverable, migration-tested, and idempotent reward commits |
| Lifecycle | Pause is real; process death follows wave-checkpoint rules |
| Achievements | Correct modes/history, unique rewards, offline support, safe retries |
| Mobile | Safe areas, readable controls, honest physical-device evidence |
| Performance | Measured frame/memory behavior; no silent gameplay degradation |
| Release | No secrets, no unlicensed assets, no unauthorized publication |

## Suggested command contract for the repository

M0 must implement/document the runner before these commands are claimed to work. Commands below are a specification, not a report of executed game tests:

```sh
# Point to the actual Godot 4.7.2 editor binary installed on the developer machine.
# Example macOS path; replace it when the app is installed elsewhere.
export GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
"$GODOT_BIN" --version
"$GODOT_BIN" --headless --path . --import
"$GODOT_BIN" --headless --path . --script res://tests/test_runner.gd
"$GODOT_BIN" --path .
```

CI should run import, schema/content validation, and automated tests using the pinned engine. It must fail on test failures. A headless pass does not validate touch input, graphics, audio, frame rate, physical-device exports, or store eligibility.

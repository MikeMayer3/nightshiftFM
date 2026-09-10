# Nightshift FM — additions and launch roadmap

Recorded 2026-09-10 from the owner's feature and publicity discussion.

**Status: proposed work, not implemented or accepted by this document.** The
owner requested a reusable plan. Select one task below in a future Codex request;
do not implement the entire roadmap automatically.

## Product direction

The hook is **defend a mountain radio station with weaponized sound**. The intended
Google Play offer is approximately $2, with $1.99 discussed as the price: one
purchase, a complete game, no advertising or additional purchases. This is a
product direction, not a published listing or configured price.

Prioritize distinct builds, fair losses, memorable radio atmosphere, and effortless
phone play. These are hypotheses to validate with players, not promises of sales.

### Existing foundation to extend

The current repository documents twelve missions, eight regular enemy roles,
three bosses, Hard/Overload, six Contracts, Endless, medals, logs, local bests,
all 48 local achievement conditions, tracked goals, and post-run analysis.
There are already equipment branches, connections, and the three-fader mixer.
Inspect their actual implementation before proposing replacements.

Recent revisions include continuous waves, protected offscreen entry, shorter
weapon reach, graphical modules, illustrated station scenery/splash, improved
combat effects, an enemy-population waveform, and a visible temporary shield.
Do not rebuild those features as new tasks. Read `NEXT_SESSION.md` for current
delivery state; this document is not a version or test-count authority.

### Lessons from comparable games

| Reference | Relevant strength | Application here |
|---|---|---|
| Brotato: Premium | Multiple weapons and varied builds in compact runs | Equipment choices should produce recognizable strategies. |
| Vampire Survivors | Simple controls, escalating power, unlocks | Deliver satisfying growth and a clear reason for another run. |
| 20 Minutes Till Dawn: Premium | Character/weapon combinations and discoverable synergies | Let players deliberately pursue combinations. |
| The Tower | Strategic depth around a fixed defense position | Extend meaningful decisions without adding purchase-driven grind. |

These are feature comparisons based on current listings, not revenue research or
proof that any one feature caused a competitor's popularity. Sources are below.

## How to give a task to Codex

Copy this prompt and replace the task ID. Each task is a bounded work package
related to M10 polish or M11 release preparation, not a renumbering of M0–M11.

```text
Work on task P1 only from docs/ADDITIONS_ROADMAP.md. Read AGENTS.md,
docs/NEXT_SESSION.md, docs/IMPLEMENTATION_STATUS.md, docs/GAME_DESIGN.md and the
relevant milestone and task criteria. Inspect the current code and preserve
unrelated local work. Treat this selected task as my requested scope; do not
start another task or the rest of its parent milestone.

Implement the smallest complete increment described by this task. Reuse existing
systems and resolve routine implementation details yourself. Preserve the owner
constraints in the roadmap. Run the relevant checks and update implementation
status plus the roadmap execution log. Distinguish automated, rendered,
emulator, physical-device and human evidence. Mark unavailable checks NOT RUN.
Stop after this task with changes, evidence and remaining acceptance conditions.
Do not commit, push, install on my phone, publish, contact anyone or spend money
unless I separately request those actions.
```

For P0 and G1–G3, produce the specified research/planning/assets rather than
unrequested game changes. External actions are separate from preparing their
reviewable materials. If a task requires human observation, prepare the protocol
and complete independent work; do not invent participants or their feedback.

### Constraints for every task

- Keep the approved flat, outlined radio-machine art style and graphical UI.
  Avoid text-heavy module panels and the removed selector indicators.
- Preserve automatic waves with no countdown or forced radio-story intermission.
- No attack, secondary effect or synergy may damage enemies beyond the Incoming
  Signals protection boundary. Enemies must enter before they can be hit.
- Keep the six support families and maximum five simultaneous supports; main
  transmitter and shield remain separate. Use existing families for combinations.
- Unlock options and cosmetics rather than hidden permanent combat advantages.
  New missions begin with the documented fresh run state.
- Preserve deterministic gameplay RNG, bounded generated attacks, checkpoint
  rules, save migrations, and idempotent rewards. Presentation RNG is separate.
- Core play works offline without accounts. No multiplayer, backend, advertising,
  paid power, gacha, energy timers, or extra purchases.
- Essential information remains understandable with sound muted, reduced effects,
  and large text. Use localized strings and licensed/original assets.
- Automated completion or a simulated win rate is not human fun/balance approval.

## Recommended order

Start with P0 to prepare a small unfamiliar-player test. Use observed problems to
choose between P1, P2 and P3. Then tackle P4–P6. Prepare G1 alongside stable visual
work, followed by G2/G3 when release timing is concrete. P7 is a later option.
When feedback is not available, P1/P2 can proceed using documented owner feedback
and measured game behavior; keep the human acceptance gate open.

| ID | Work package | Priority | Dependency |
|---|---|---|---|
| P0 | Unfamiliar-player test package | First | Current playable build |
| P1 | Distinct builds and graphical synergy guidance | High | Existing arsenal/mixer |
| P2 | Fair losses and useful defeat feedback | High | Existing damage/results tracking |
| P3 | First-session teaching and phone reliability | High | Existing settings/checkpoints |
| P4 | Radio personality and boss anticipation | Medium | Current art/audio direction |
| P5 | Major-upgrade visual and musical payoff | Medium | P1 build identities |
| P6 | Visible next unlock and progression goals | Medium | Existing achievements/unlocks |
| P7 | Shared weekly Midnight Broadcast | Later | Contracts; stable balance |
| G1 | Store assets and creator press kit | Before launch | Representative stable gameplay |
| G2 | Organic publicity and launch plan | Before launch | G1; release timing |
| G3 | Store measurement and experiment plan | At/after launch | Listing access and traffic |

## P0 — Unfamiliar-player test package

**Deliver:** a short facilitator script, feedback sheet, device/build fields,
observation log and prioritized findings template for 10–15 unfamiliar players.
Use a few observed sessions first; collect broader feedback after obvious fixes.
Recruitment and distribution are owner actions unless explicitly delegated.

Observe whether players understand the objective, shield and mixer; recognize a
build; explain a loss; resume after interruption; and voluntarily start another
run. Record where they hesitate and whether the facilitator had to explain.
Separate raw observations, player opinions and developer interpretations.

**Acceptance:** the package is usable without verbal instructions from Codex;
contains no fabricated results; identifies the exact tested build; and supports
ranking issues by frequency and severity. Human findings remain NOT RUN until
actual sessions occur. Do not claim a statistically representative retention rate.

## P1 — Distinct builds and graphical synergy guidance

**Goal:** bass, net/control and precision playstyles feel and behave differently.

Audit existing branches and connections first. Strengthen at least three existing
archetypes using their current equipment and rules. Show concise, graphical
combination hints at the point of choice, including prerequisites and tradeoffs.
Document the intended strengths, weaknesses and counters of each build.

A bass pulse propagating through captured enemies was a brainstorming example,
not a committed mechanic. Prefer existing connection behaviors; if adding one
interaction is needed, bound it explicitly and retain damage attribution and the
Incoming Signals restriction. Do not expand the support roster.

**Acceptance:** three legal builds can be assembled through normal choices;
their measured strengths and weaknesses differ across representative encounters;
no new universally dominant choice is demonstrated by the comparison; hints
match actual behavior; and upgrade/resume paths preserve the build correctly.
Report winning and losing cases. Include rendered small-phone evidence and leave
whether the identities feel distinct to people as an explicit human check.

## P2 — Fair losses and useful defeat feedback

**Goal:** players can lose, understand why, and form a plan for the next run.

Extend existing contribution and defeat reports rather than building a second
reporting system. Present one short, evidence-backed primary loss explanation
with graphical supporting information and a fast restart action. Show useful
equipment contributions without counting damage twice or inventing causality.
“Fast enemies caused most breaches” is valid only when recorded events support it.
Use a neutral fallback when there is insufficient evidence.

Compare legal weak, coherent and mixed builds on representative early, middle,
late and higher-difficulty encounters. Fix demonstrated balance defects with
small documented adjustments. Do not target a universal win rate or raise every
enemy stat to force failure. Preserve readable warning and response opportunities.

**Acceptance:** loss explanations agree with recorded events; victory and defeat
reports remain correct after checkpoint replay; restart clears temporary state;
and comparisons include both successful and failed runs. Record whether shield,
focus and mixer decisions matter. Unfamiliar players' ability to explain their
loss is a separate human gate, not inferred from simulations.

## P3 — First-session teaching and phone reliability

**Goal:** teach through brief contextual visuals and survive normal phone use.

Audit the actual first-run flow. Teach shield activation and temporary absorption
with a short visual cue tied to its existing feedback. Introduce the mixer when
it becomes useful. Keep hints dismissible and replayable through help; avoid
long instructions, mandatory countdowns, and coaching that repeats every run.

Verify small/tall/notched/tablet layouts, large text, mute, low effects, handedness
where supported, background/foreground and checkpoint recovery. Use existing
lifecycle and save contracts; do not promise arbitrary-frame restoration.
Measure sustained performance and battery/thermal behavior on available devices.

**Acceptance:** hints correspond to real actions and do not obstruct combat;
their saved state resumes correctly; all essential information works muted;
the documented interruption cases preserve saves and avoid duplicate rewards;
and a named device matrix separates desktop, emulator and physical evidence.
Use M10's performance/soak criteria and report unavailable hardware as NOT RUN.
Human first-session comprehension remains a separate check.

## P4 — Radio personality and boss anticipation

**Goal:** make the station setting memorable without interrupting waves.

Build a small authored set of captioned emergency broadcasts, strange callers
and station stings tied to existing encounter events. Start with one region and
one existing boss. Give that boss an anticipatory mountain silhouette or signal
interference cue consistent with the game's flat art and actual encounter timing.
Do not replace the boss roster or write an entire narrative campaign in this task.

**Acceptance:** cues trigger at the correct events with bounded frequency;
do not cover enemies, controls or upgrade choices; respect pause and audio/
accessibility settings; and do not alter gameplay RNG or create repeated messages
on resume. Original audio has recorded provenance. Captions carry any essential
meaning. Human listening and tone approval are reported separately.

## P5 — Major-upgrade visual and musical payoff

**Goal:** major equipment changes are visibly and audibly rewarding.

Choose one existing build for the first complete increment. Give its important
rank/branch transition a clear hardware/attack change. Explore a subtle original
musical layer linked to that equipped instrument, with limits that prevent a
crowded mix. Use P1's documented identities and existing audio settings.
Do not make a new rhythm-game mechanic or change damage to fit an animation.

**Acceptance:** capture before/after footage from real gameplay; the presentation
matches the actual upgrade and restored state; normal/mute/low-effects modes
remain readable; audio does not stack uncontrollably; and measured combat load
does not regress without explanation. Provide an asset-extension pattern for
other builds, but stop after this selected build. Listening/art approval remains
human evidence.

## P6 — Visible next unlock and progression goals

**Goal:** players know what appealing option they can earn next.

Extend existing tracked goals, achievements and unlock UI. Show a compact hardware
silhouette or reward illustration, a short real requirement, and current progress
at useful menu/results moments. Make locked versus equipped versus earned states
clear without returning to text-heavy modules or tiny selector indicators.
Use existing option/cosmetic rewards; do not add a second progression currency.

**Acceptance:** displayed requirements and counts match authoritative progression;
earned rewards survive reload; repeated results cannot award twice; completed
goals transition sensibly; and no recommendation is permanently unreachable.
Verify large text and small phones. Human ability to identify a next goal is an
explicit check.

## P7 — Shared weekly Midnight Broadcast (optional later)

**Goal:** reuse Contracts for a repeatable challenge players can compare.

Prepare one offline-capable weekly challenge with an explicit seed, fixed loadout,
rules version and local best. Document a common week boundary and a readable
challenge code that identifies compatible builds. Keep the current challenge
fixed for an active run even if the date changes. Treat the local clock and shared
screenshots as informal play, not cheat-resistant competition.

**Acceptance:** matching versions/codes generate the same intended challenge;
checkpoint restore retains its rules; update/week rollover and unavailable content
have defined handling; ordinary progression/rewards do not duplicate; and play
works without a server. No online leaderboard, login, streak penalties or rewards
that require playing during a particular week. Reassess this task after feedback.

## G1 — Store assets and creator press kit

**Deliver:** reviewable local assets and copy for the approximately $2 premium
offer: icon/feature-graphic candidates, phone screenshots, a short real-gameplay
trailer, concise listing text and a simple creator press kit with game summary,
screenshots, trailer link/file, credits and a placeholder for owner contact details.

Suggested trailer sequence: station under pressure, visible shield catching an
attack, then a satisfying build clearing the crowd. Only show interactions that
actually exist. Open with gameplay rather than a long logo/splash sequence.
Keep the visual style consistent with the game. Do not put price/promotion claims
in restricted asset fields; recheck current Google asset rules before exporting.

**Acceptance:** claims match the build; screenshots are legible at store sizes;
assets meet current official dimensions/formats; provenance is recorded; and
unavailable captures are marked as missing rather than substituted with fake
gameplay. Prepare everything locally. Store upload and publication are separate.

## G2 — Organic publicity and launch plan

**Deliver:** a practical, low-budget calendar and copy drafts using G1's assets.
Include short gameplay clips, relevant Android/roguelite/defense communities,
a small researched creator shortlist, outreach drafts and a review-code plan.
Check community promotion rules and current creator relevance before suggesting
specific destinations. Never require a positive review in exchange for a code.

Include a draft Play promotional-content event for a real substantial update or
challenge. Evaluate pre-registration only once release timing is known. Check
current indie-program eligibility if relevant; do not assume US eligibility for
region-specific funding or assume a program's application window is open.

**Acceptance:** deliverables have dates relative to launch, owners, asset needs
and trackable links/campaign labels; factual claims are verified; no unsupported
coverage/sales promises; and paid ads are deferred pending measured economics.
Do not send messages, create codes, post, register, launch campaigns or spend.

## G3 — Store measurement and experiment plan

**Deliver:** a small measurement plan using Play Console's existing reports.
Cover traffic sources, listing response, paid acquisitions, reviews and Android
vitals. Specify one initial icon or screenshot experiment, what it tests and how
to avoid interpreting very small samples as a winner. Explain which metrics the
available reports actually expose rather than inventing analytics fields.

Consider custom listings for strategy-focused versus atmosphere-focused audiences.
Treat featuring and promotional placement as opportunities, not entitlements.
If proposing an in-app review prompt, scope integration separately, use Google's
current guidance, and avoid incentives, repeated nags or screening by sentiment.

**Acceptance:** the owner can use the plan without a new backend or paid analytics
subscription; every proposed metric has a source; acquisition cost is compared
with actual net proceeds rather than sticker price; and unavailable account data
is explicit. Use a read-only audit when account access exists. Configuration,
SDK additions and campaigns require a separately selected implementation task.

## Publicity tools and reference links

Research snapshot: 2026-09-10. Store rules, availability, quotas and programs can
change. Recheck the relevant official source when executing a launch task.

- [Brotato: Premium](https://play.google.com/store/apps/details?id=com.brotato.shooting.survivors.games.paid.android)
- [Vampire Survivors](https://play.google.com/store/apps/details?id=com.poncle.vampiresurvivors)
- [20 Minutes Till Dawn: Premium](https://play.google.com/store/apps/details?id=com.Flanne.MinutesTillDawn.roguelike.shooting.gp)
- [The Tower](https://play.google.com/store/apps/details?id=com.TechTreeGames.TheTower)
- [Preview assets](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en): screenshots, feature graphic, icon and video requirements.
- [Listing experiments](https://support.google.com/googleplay/android-developer/answer/12053285?hl=en): test store graphics/text once traffic supports a useful comparison.
- [Custom listings](https://support.google.com/googleplay/android-developer/answer/9867158?hl=en): tailor the presentation to audiences and campaigns.
- [Promotional content](https://support.google.com/googleplay/android-developer/answer/12929029?hl=en): current guidance makes it available to all games; additional featuring/targeting capabilities have eligibility conditions.
- [Promotional-content capabilities](https://support.google.com/googleplay/android-developer/answer/12932229?hl=en): verify access and actual placement/reporting.
- [Promo codes](https://support.google.com/googleplay/android-developer/answer/6321495?hl=en): research snapshot permits up to 500 non-subscription codes per app per quarter.
- [Acquisition reports](https://support.google.com/googleplay/android-developer/answer/9859173?hl=en): sources and listing performance; use campaign tags for external links.
- [Android vitals](https://developer.android.com/games/optimize/vitals): stability and other quality issues can affect discovery.
- [In-app reviews](https://developer.android.com/guide/playcore/in-app-review): optional native integration, not already certified by local achievements.
- [Featuring guidance](https://play.google.com/console/about/guides/featuring/): quality and assets influence consideration; featuring is not guaranteed.
- [Indie programs](https://play.google.com/console/about/programs/indiegames/): check current regions, deadlines and eligibility.
- [Google Ads App campaigns](https://support.google.com/google-ads/answer/6247380?hl=en-EN): paid exposure across Google properties; defer until acquisition economics justify it.

## Execution log

P0 preparation is **READY; HUMAN EVIDENCE NOT RUN** (2026-09-10). The owner's
request to start this roadmap was scoped to its first package. Delivered the
[facilitator guide](playtesting/P0_GUIDE.md), [session/feedback form](playtesting/SESSION_TEMPLATE.md),
and blank observation/finding CSVs. The guide records build identity requirements,
staged cohorts, neutral prompts, assisted-versus-unprompted behavior, device
checks and evidence-based triage. No participants or test outcomes are invented.
Candidate artifact preparation, distribution and human sessions remain open.

P1 (2026-09-10): **first playable increment IMPLEMENTED; human distinctness and
broader balance acceptance OPEN**. [Build guidance and evidence](P1_BUILD_GUIDANCE.md)
adds graphical upgrade/connection previews, actual prerequisite/ready/connected
states, tradeoffs and a derived jam-overlap warning. Shared runtime eligibility
keeps hints honest. Three existing archetypes were compared across 48 legal runs
with 452 JSON decision restores; controlled fixtures establish distinct conditional
behavior. Combat values were not changed. Precision leads these fixed policies;
do not interpret the sample as proof of balanced archetypes or human win rates.

P2 (2026-09-10): **loss-feedback increment IMPLEMENTED; human balance and loss
comprehension acceptance OPEN**. See [P2_LOSS_FEEDBACK.md](P2_LOSS_FEEDBACK.md).
Effective health-loss attribution survives checkpoints, legacy history uses a
neutral fallback, existing reports show graphical bars, and Retry is immediate.
48 legal matched campaigns produced 34 wins/14 losses; no combat values changed.
Android delivery evidence is recorded with this increment.

P3 (2026-09-10): **IMPLEMENTED and delivered as 0.10.8/code 20**. Contextual
shield/boost/Mixer hints are dismissible, remembered and replayable through Help.
Visible shield handedness is now configurable. [P3 evidence](P3_ONBOARDING_RELIABILITY.md)
includes 5,659 regression checks, 70 native UI/audio checks, ten emulator
interruption/reward/power cases, and a completed twenty-minute Pixel soak.
Owner P2 feedback was positive; unfamiliar-player onboarding comprehension,
unplugged battery drain and unavailable hardware remain separate open checks.

P4 (2026-09-10): **IMPLEMENTED and delivered as 0.10.9/code 21** to the Pixel.
First-region station/caller/emergency captions, three original stings, and the
existing Caller's timed approach/entry cues. [P4 evidence](P4_RADIO_PERSONALITY.md)
records 5,687 regressions, 86 native UI/audio/save checks, eight full campaigns,
and Android export. Physical install/launch preserved all six prior save/settings
JSON and backup files byte-for-byte; runtime log is clean. Phone was locked, so
visible game UI verification remains NOT RUN. Human tone/listening
and gameplay approval remain NOT RUN. Continue suppresses current-wave dialogue
without changing save schemas.

P5–P7 and G1–G3 remain **PROPOSED / NOT STARTED**. Existing milestone
human/device acceptance is not changed by these increments.

When a selected task is performed, append its date, scope, evidence links and
status here, and update `IMPLEMENTATION_STATUS.md`. Separate implementation
completion from human/device/store acceptance. Do not mark a task complete just
because its plan or test protocol exists.

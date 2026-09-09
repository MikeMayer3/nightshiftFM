# Game design and implementation specification

> **Owner radio-station revision (2026-09-09, 0.10.3):** Current campaign runs
> use automatic tower/support attacks without the manual Burst cooldown action.
> Holding a target focuses fire; releasing returns to automatic targeting. Shield
> remains available. All twelve module sidegrades are available from mission 1,
> with at most two fitted. Mission tiles select a plain mission-name label; there
> is no duplicate dropdown or mission briefing. Kills advance an analog radio
> dial with a hunting needle and rotating knobs; incoming signals combine ticks
> and a waveform. Station Health is below the taller field; Pause is compact.
> The tower stays centered and the shield boundary clears all instruments.
> Compact upgrade sheets retain the battlefield behind them. Defenders are
> vintage studio instruments and a radio tower; enemies are modern music players,
> earbuds and smart speakers. This supersedes earlier Burst, module-unlock and
> possessed-radio art instructions below. See [current art direction](RADIO_ART_DIRECTION.md).


> **M9 opening increment:** Local achievement progress, tracked goals, cosmetic
> titles and run history are implemented for 25 conditions; 23 catalog entries
> and Endless remain pending. M8 is still partial. See [M9 contracts](M9_ACHIEVEMENTS.md).

> **Current implementation:** M7 progression is implemented and M8 has started
> with three authored Rooftop Relays missions. See [M8 scope and evidence](M8_ENCOUNTERS.md).
> The older revision notes below are historical; the full M8 catalog remains a roadmap.

> M6 implementation note: the prototype now exposes eight patchboard recipes immediately, with two slots and player-confirmed intermissions. The campaign unlock is deferred to progression. See [M6 contracts](M6_PATCHBOARD.md); human acceptance is still unverified.

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

> **M10 opening increment (2026-09-09):** The current three enemy movement
> families and all six support turrets now use original radio-hardware artwork.
> Saved presentation settings and optional audio are implemented. See
> [M10 scope and remaining acceptance](M10_MOBILE_POLISH.md).

## 1. Design decisions and theme alternatives

The requested game is best scoped as a **fixed-turret roguelite defense shooter**, rather than a path-building tower defense game. There are no mazes, tower placement grids, or moving player avatar. The interesting decisions are targeting, timed defense, equipment selection, and upgrades.

These are proposed creative directions, not claims that nobody has used a similar premise:

| Working theme | Player at bottom | Incoming enemies | Weapon/defense vocabulary | Distinctive interaction |
|---|---|---|---|---|
| **Nightshift FM** | The last haunted radio transmitter | Interference spirits, pirate signals, dead broadcasts | Echo decks, arc aerials, bass drivers, static nets | Connect equipment using a limited patchboard |
| **Dreamstitch** | A sewing-machine fortress repairing sleep | Flying tears in reality, loose nightmares, unraveling masks | Needles, bobbins, scissors, pin cushions, quilt shields | Stitch enemies together; cutting one damages linked targets |
| **Afterlife Lost & Found** | A supernatural baggage-claim desk | Unclaimed memories and possessed luggage | Claim tags, pneumatic tubes, bell bursts, conveyor shields | Tag threats, then redirect or cash in their tags |
| **Forecast: Impossible** | A weather engine holding back an impossible sky | Hail creatures, living lightning, miniature eclipses | Pressure pulses, rain curtains, wind turbines, cloud armor | Change weather states to transform existing weapons |
| **Museum of Unfinished Inventions** | A restoration apparatus under siege | Escaped prototypes, patent sketches, broken automata | Spring guns, magnetic tools, folding machines | Temporarily combine two incomplete inventions into a new effect |
| **Abyssal Relay** | A living signal beacon on the seabed | Drifting abyssal predators and parasitic colonies | Sonar pulses, pressure jets, bioluminescent lures, shell shields | Light attracts enemies into controlled kill zones |

**Owner-selected visual direction (2026-09-09):** use radio hardware for both turrets and enemies, spanning old-school valve sets, transistor/FM and tape-era equipment, and modern digital receivers and broadcast transmitters. Enemies are possessed radio machines; turret shapes and attack mechanisms come from aerials, speakers, reels, tuning hardware and dishes. The alternative themes above remain historical proposals. See [Radio art direction](RADIO_ART_DIRECTION.md) for family designs and the campaign's era progression.

Names are placeholders. Perform storefront and name-clearance checks before committing to public branding.

## 2. Product pillars and non-goals

**Pillars:** short self-contained missions; readable one-hand mobile play; few weapons with genuinely different builds; no permanent statistical grind; strong replayability through visible choices; offline play.

**Non-goals for version 1:** multiplayer, PvP, procedural story generation, full physics destruction, user-generated levels, cloud accounts, ranked global leaderboards, daily login streaks, ads, fitness integration, and an elaborate crafting economy.

The theme is spooky and playful rather than graphic. Critical information must remain readable with the sound muted. Original sound design and an optional layered soundtrack support the radio premise, but rhythm accuracy is not a gameplay requirement.

## 3. Screen, controls, and damage rules

Use portrait orientation and a 720 × 1280 logical design reference. Preserve a consistent combat rectangle across aspect ratios; additional screen space may hold UI or decorative framing, not create an unfairly larger arena. Keep the top spawn band, bottom breach line, and all action buttons outside camera cutouts and system gesture areas.

The transmitter remains fixed near the bottom center. Hostile units enter through a top band, then use straight, diagonal, curved, or acceleration-based paths toward the bottom breach line. These are authored movement behaviors, not tower-defense pathfinding.

The main gun auto-fires. By default it targets the closest threatening enemy; the player can tap a target to focus fire or drag on an unobstructive aiming pad. Releasing the override returns to auto-targeting. Supports fire automatically. A large shield-ability button is the only required active combat button. Provide left/right-handed layouts, a pause button, and targeting presets for nearest-to-breach, lowest health, highest health, and support-caster priority.

All damage to the station resolves through shield first, then hull. Shield overflow damage reaches hull unless a specific phase/negation effect prevents the hit. Every enemy crossing the full-width breach line deals its defined breach damage once and despawns once. It does not need to physically collide with the center turret. Killed enemies cannot also breach. Ranged attackers fire visible, destructible projectiles toward the station. At least one basic, non-specialized counter must exist for every enemy attack.

Pause simulation while upgrade screens are open, on loss of application focus, and during settings menus. No cooldown, wave timer, or damage-over-time timer advances while paused.

## 4. Exact mission structure and upgrade budget

A **mission is a run**. Completing a campaign mission does not carry its weapon ranks into the next mission. Target 8–12 minutes of active combat for a normal mission, plus whatever time the player spends paused making decisions. These are playtest targets, not measured results.

A standard mission has ten waves. Waves 1–9 grant three sequential upgrade drafts after the wave is fully resolved. Each draft offers up to three distinct eligible choices and grants exactly one selection. This produces **27 normal upgrade selections before the final encounter**. Wave 10 ends with a regional boss or an elite finale and goes directly to results; do not offer post-win combat upgrades.

At the beginning of a mission select one rank-1 main chassis, one rank-1 shield chassis, and one rank-1 support family. Start with two shared rerolls and one banish. Before waves 2, 4, 6, and 8, provide a separate arsenal choice: add one unequipped unlocked support at rank 1, or decline recruitment for one bonus upgrade on an existing support. Show the available families rather than hiding a needed option behind another random roll. Declining does not create another recruitment opportunity later.

This establishes a hard cap of **five simultaneous support families, selected from a launch roster of six**. The main gun and shield do not consume support slots. There are no duplicate families and no support replacement after a mission starts. The last recruitment opportunity happens before the final six normal drafts, so the player must consider whether a late weapon has time to mature.

Each weapon track and the main/shield tracks run from rank 1 to rank 8. Acquisition provides rank 1; seven upgrade selections max a track. Two fully developed support weapons therefore cost 14 normal selections. A player still has 13 normal selections for the main gun, shield, and other supports. Maxing all five supports would cost 35 selections before upgrading the main gun or shield: deliberately impossible under the standard budget.

Recruitment declines can increase the 27-selection budget by up to four, but only by sacrificing breadth. Numeric UI labels distinguish wave number from equipment rank and campaign mission number.

### Draft eligibility and bad-luck protection

Upgrade offers include owned supports, main weapon, and shield, never a weapon the player cannot use. A selection increments one equipment track by one rank. If it reaches rank 3, 6, or 8, the corresponding branch decision is part of that same selection, not an extra rank or extra paid choice.

Offer generation first picks eligible tracks, then valid upgrade options. Main and shield each receive an offer at least once in every three normal draft screens while eligible. If a chosen support has been absent for four normal draft screens and remains eligible, guarantee it on the next eligible screen. The allocator must satisfy the main/shield quota and overdue support together before filling remaining positions randomly. Maintain a most-overdue-first queue when several supports qualify. An unavailable/maxed/banished track does not accumulate a debt.

No duplicate card ID appears within a draft. Rerolls change offers, not the mission's enemy schedule. A banish removes a common card option for this run, not an entire weapon track or its required rank-3/rank-6/rank-8 choices. Mandatory branch/capstone options cannot be banished.

If fewer than three valid choices remain, display fewer valid choices. If none remain, offer an explicitly described small hull repair or shield refill rather than deadlocking. Persist the current offer IDs, choice index, reroll counters, banishes, and RNG states so relaunching cannot reroll the current offer.

## 5. Equipment depth

### Support upgrade grammar

Each family has 18 authored upgrade definitions: six repeatable basic tuning options, three mutually exclusive rank-3 specializations, two rank-6 modifiers for each specialization, and one rank-8 capstone for each specialization. That is **108 support-upgrade definitions across the roster**, not 108 upgrades equipped in one mission.

Ranks 2, 4, 5, and 7 choose a valid tuning option. Rank 3 selects one of three specializations. Rank 6 selects one of the two modifiers belonging to that specialization. Rank 8 adds its capstone. Rank-3 and rank-6 selections must change behavior or introduce an explicit tradeoff, not merely rename a percentage bonus.

Do not make capstones depend on a lucky rare drop. Rank and the selected branch are the prerequisites. Show a readable branch preview before the player commits, including incompatible choices, costs, and the final capstone.

The content catalog supplies the initial branch concepts. Implement three support families first, then prove two contrasting builds before finishing the six-family catalog.

### Main weapon

Three unlockable chassis: **Pulse Transmitter** (balanced shots), **Sweep Transmitter** (continuous focused beam), and **Burst Transmitter** (shorter-range volleys). They are alternatives with comparable starting value, not strictly better tiers.

Shared tuning concepts include base damage, fire rate, critical chance, target width, penetration, and effect application. Chassis-specific branch behaviors include ricochet versus focused penetration, sustained beam versus short overload pulses, and broad scatter versus converging volleys. Beam and projectile implementations must share attack/stat interfaces without pretending that their targeting rules are identical.

Main rank-3, rank-6, and rank-8 decisions use the same rank grammar as supports. Do not silently convert beam width into projectile count. The catalog defines the initial main branches.

### Shields

Three alternatives: **Capacitor** (large reserve, slower recovery), **Relay** (smaller reserve, faster recharge), and **Feedback** (moderate reserve, limited retaliation). Each has rank-1 baseline values and an associated active ability; none requires permanent shield-stat grinding.

Use a shared upgrade vocabulary of capacity, recharge speed, recharge delay, ability cooldown, temporary damage reduction, and break recovery, with bounded chassis-specific branch modifiers. Example active abilities: a temporary overshield, immediate restart of recharge, or a short projectile-reflection window. Retaliation and reflection are bounded attacks, not unrestricted feedback loops.

Shield breaks can be an offensive build trigger, but repeated breaks cannot create a self-sustaining infinite healing/damage cycle. Shield capacity cannot be farmed permanently across waves unless an explicitly capped run effect says so.

## 6. Signature mechanic: patchboard connections

The radio-station patchboard has **two active connection slots**. A connection is an authored synergy recipe between two equipped endpoints, which may include the main gun or shield for specific recipes. Connections do not occupy support-weapon slots. Players may rewire at intermissions, not during combat. Sharing an endpoint between the two connections is allowed; selecting the same recipe twice is not.

Unlock the patchboard after the second campaign mission and provide a short interactive tutorial. Before this unlock, the player is not expected to manage it. Reveal the full recipe catalog and its prerequisites when the patchboard unlocks; record a recipe as discovered when it first triggers. Connections are not random drops. Prerequisites must be shown. Generic statuses continue to function independently; a recipe's additional payoff only occurs when that recipe is connected.

Start with two recipes in the prototype expansion; target eight for release. Prefer recipes that complement both ordinary and specialized builds. The catalog defines their conditions and bounded payoffs.

### Five common status effects

**Charged:** bounded stacks used by arc interactions. **Slowed:** movement reduction with an upper cap. **Exposed:** armor reduction, never negative armor unless specifically designed. **Marked:** a visible target flag with a bounded damage-taken modifier. **Jammed:** an interruption/silence window against an enemy ability.

Pull and knockback are movement impulses, not extra damage types. Define boss/elite displacement resistance and interruption cooldowns. Bosses must retain an alternate payoff such as reduced ability speed or additional stagger progress instead of making an entire control build useless.

## 7. Persistent progression and modes

Persist campaign progress, unlocked equipment options, station-module options, cosmetic mastery, discovered recipes, achievements, settings, and best scores. Reset equipped support acquisitions, ranks, temporary modifiers, current health/shield, rerolls, banishes, patch connections, and per-run currency/state when a new mission begins. Persist a run checkpoint only for continuing that same mission.

The opening equipment pool is Pulse, Capacitor, Arc Aerial, Bass Driver, and Static Net. Unlock Echo Deck after mission 2, Reverb Well after mission 3, and Needle Swarm after mission 4. Completing each of these missions once is sufficient; replay grinding is not required. Unlock Relay shield after mission 3, Sweep main weapon after mission 4, Burst main weapon after mission 6, and Feedback shield after mission 8. All ordinary branch choices arrive with their weapon family; do not hide essential capstones behind lengthy mastery grinds.

Allow two pre-mission station modules from a catalog of twelve tradeoff-based modules. Start with none and introduce them after mission 4. Modules are sidegrades: a gain in one area incurs a visible cost elsewhere. Do not add permanent stacking damage research. Equipment mastery awards skins, portraits, and optional titles rather than raw power. Module unlocks are first-clear rewards: mission 4 grants Hot Tubes and Heavy Battery; mission 5 grants Long Mast and Fast Fuse; mission 6 grants Signal Booster and Quiet Room; missions 7–12 grant Wideband Module, Narrowband Module, Counterweight, Thin Wire, Night Ledger, and Glass Tower respectively. This makes all twelve available through the Standard campaign without a separate research currency.

Release modes: **Campaign** with three regions of four missions, **Endless** unlocked after region 1, and **six Contracts** that use authored restrictions or objectives. Every campaign mission still starts from baseline. Endless extends the wave loop with a separate bounded reward policy and enemy-scaling schedule; do not automatically hand out unlimited permanent stat ranks after equipment caps.

Difficulty choices: Standard, Hard, and Overload. Unlock higher difficulties by completing the preceding tier's regional finale. Difficulty adds telegraphed elite combinations, wave patterns, and boss modifiers, with documented numerical scaling rather than numerical inflation alone. Core progression and most achievements remain available on Standard.

An offline daily-seed challenge, cloud saving, and any verified leaderboard are post-release features. A local seed and an editable local save are not an anti-cheat system.

## 8. Content, encounters, and meaningful choice

Target three regions: **Rooftop Relays**, **Flooded Switchyard**, and **The Dead Band**. Each has four missions with authored wave templates and a limited environmental rule, introduced safely before it appears in a difficult encounter. Avoid visual noise that hides enemy tells.

Target eight enemy families and three regional bosses, with reuse through authored formations and clearly signaled elite modifiers. Ordinary mission finales use an elite encounter; regional finales use a major boss. Teach each enemy family alone or in an easy pairing before combining it with several threats.

All enemies enter from the top, including ranged units that temporarily stop in the upper arena. Enemy formation and behavior must make weapon roles matter. Swarms reward area attacks, plated units reward exposure or penetration, carriers reward focus fire, and support casters reward target priority. No mission may require one particular support family to win.

Provide three optional mission medals: completion; finishing with at least 50% hull; and an authored mission-specific objective. Report objectives before launch and persist best medals independently. Replaying a mission does not repay its one-time unlock reward.

## 9. Achievements and feedback

Target 48 local achievements: 8 progression, 12 weapon mastery, 8 build/synergy, 6 defense, 6 contract, 4 discovery, and 4 Endless. The catalog specifies exact conditions. Each has a stable ID, localization keys, category, progress type, threshold, reward, eligibility rules, and optional platform IDs.

Support run-specific flags, cumulative counters, distinct-ID collections, and high-water marks. Evaluate from gameplay events, not displayed text or screen pixels. Persist the maximum support count used, peak shield, hull damage, all selected modules, debug eligibility, and other historical facts needed by run achievements; checking only the final loadout is insufficient.

Commit partial-wave achievement progress only when the wave is committed. Use run/wave commit IDs so retrying a save, replaying a result screen, or recovering from a crash cannot duplicate rewards. Cosmetics are granted once using a stable reward ID. Queue native-service synchronization separately; offline and signed-out players still see local completion immediately.

Avoid endless grind, paid achievements, mandatory login streaks, and achievements that depend on hearing a cue. Show progress, condition descriptions, and optional tracked goals. A post-run report shows damage contribution, useful shield absorption, interrupts, control contribution, selected branches, and defeat cause. Do not equate a low-damage support with an ineffective support.

## 10. Technical architecture

Baseline recommendation: Godot 4.7.2 standard, typed GDScript, native Android/iOS exports, Compatibility renderer for the initial 2D project. Godot's September 7, 2026 download page lists 4.7.2. Its stable mobile export guides describe C# mobile export support as experimental; this is why the baseline uses GDScript. The iOS workflow requires macOS with Xcode. See `REFERENCES.md` and recheck these facts if the project starts later.

Use a small service boundary: `GameFlow`, `RunSession`, `ProfileStore`, `ContentRegistry`, `AudioService`, and `PlatformServices`. Combat actors use explicit components for health, movement, targeting, weapons, and statuses. Do not put every weapon, menu, and save operation in one global manager.

Suggested folders:

```text
project.godot
AGENTS.md
scenes/{boot,menus,combat,ui}/
scripts/{core,combat,equipment,progression,persistence,platform,ui}/
content/{weapons,upgrades,shields,enemies,waves,missions,modules,synergies,achievements}/
assets/{art,audio,fonts}/
tests/{unit,integration,fixtures}/
tools/
docs/
```

Use typed immutable Godot Resources for `WeaponDefinition`, `UpgradeDefinition`, `ShieldDefinition`, `EnemyDefinition`, `WaveDefinition`, `MissionDefinition`, `ModuleDefinition`, `SynergyDefinition`, and `AchievementDefinition`. Store runtime values in separate `WeaponState`, `ShieldState`, `RunState`, and `ProfileState` structures.

A weapon definition needs stable ID, localization keys, behavior enum/component reference, compatible stats, projectile/visual references, tags, upgrade-track references, and targeting capabilities. An upgrade definition needs ID, target compatibility, rank constraints, prerequisites, excluded branches, stack cap, typed effects, and display text. A synergy needs endpoint IDs/tags, eligibility, event condition, internal cooldown, effect, and generation policy.

The content validator must reject duplicate IDs, missing references, impossible prerequisites, invalid stat combinations, empty required branch options, cyclic unlock dependencies, nonpositive attack intervals, and achievement references to unavailable content. Schema validation is not a substitute for combat tests.

### Stats and combat calculation

Keep additive bonuses grouped before multiplication. A starting damage convention is `base_damage * (1 + additive_damage_bonus) * product(explicit_multipliers)`. Fire rate uses `base_interval / (1 + fire_rate_bonus)` with a minimum interval. Critical chance caps at 100%; slow has a declared cap; shields/hull clamp to valid ranges. Do not apply a percentage repeatedly to an already-modified value when reconstructing a save.

Use a documented armor rule such as `damage_after_armor = damage_before_armor * 100 / (100 + effective_armor)` for nonnegative armor. Apply exposure to armor before damage reduction. Decide and test where criticals, marked damage, shield absorption, and retaliation occur in that pipeline.

Attack events distinguish direct, echoed, reflected, and synergy-generated sources. Echoes snapshot the eligible attack's relevant damage/target information when recorded, then use the explicit replay multiplier. Replays do not recursively produce new recordings. Limit secondary generation depth to 1 initially unless a specific tested recipe needs a larger bound.

### Randomness and performance

Use independent RNG streams for wave composition/spawns, draft selection, combat random effects, and presentation. Save RNG states, not just the initial seed. Stable ordering and a pinned content version are required for repeatable tests. Seeded randomness alone is not proof of cross-platform deterministic physics.

Use simple 2D collision/target queries first. Profile before introducing a custom spatial grid or pooling system. Where pooling is justified, reset status, damage attribution, listeners, timers, and visuals on reuse. Decorative particles may be reduced in quality settings, but gameplay projectiles and damage may not disappear to meet a frame target.

Initial stress fixture: 150 simultaneous enemies and 400 player/enemy projectiles, including a busy synergy build. Select named baseline Android and iPhone devices during the export spike. Provisional goals: normal mode targets 60 fps with 95th-percentile frame time at most 20 ms; reduced-effects mode targets 30 fps at most 36 ms. Use a 20-minute physical-device soak and compare memory after equivalent warm-up/cleanup cycles; investigate persistent growth above 10%. These are engineering targets requiring measurement, not promised hardware support.

### Save and resume contract

Maintain versioned profile and run saves with validated IDs, a backup, and a recoverable temporary write. Save after every upgrade choice, immediately before a wave, on committed wave completion, and on run completion. If the process remains alive, backgrounding freezes and then resumes the current simulation. If the OS kills the process, reload the most recent wave-start checkpoint and replay that wave, discarding uncommitted partial-wave counters. The UI must explain this behavior.

Persist upgrade-screen position so recovery does not lose an already accepted choice or grant it twice. Persist run phase and reward commit IDs so a death cannot become a victory and a results screen cannot repay rewards. Migrations must preserve unlocked content and safely handle removed IDs. Checksums detect corruption; they are not security against save editing.

### Platform services

Core play has no network dependency. Define an achievement adapter with available/authenticated status, unlock, monotonic progress submission, and retry handling. Prototype an actual compatible integration before promising native achievements. Plugin selection must verify engine compatibility, license, maintenance status, and device behavior. A no-op adapter is a development fallback, not a completed native integration.

Apple Game Center and Google Play Games Services provide native achievement systems. They do not automatically provide shared Android/iOS profile progress. Avoid repeatedly incrementing platform progress on uncertain retries; use absolute or monotonic progress APIs where supported, with an idempotent local synchronization journal.

## 11. Art, accessibility, release, and scope gates

Use original placeholder art until the gray-box is fun. Final art should make six weapon silhouettes and eight enemy roles immediately distinguishable. Use bounded flashes, optional screen shake and haptics, readable type, icons plus text for statuses, separate music/effects controls, and settings that work with sound off. Do not use commercial radio songs without appropriate rights.

Follow [Radio art direction](RADIO_ART_DIRECTION.md) for enemy, turret and boss assets. Old-to-new radio eras guide materials and silhouettes across the three regions; they do not introduce permanent power tiers or change family identities. M10's opening pass replaces current turret/enemy placeholders; final human art approval and later enemy/boss assets remain open.

Recommended first-release business model: paid full download with no advertising, energy timers, gacha, or paid combat power. This is a scope preference, not a revenue prediction. Do not add purchase SDKs to the prototype.

Before submission, recheck current Android/iOS SDK, target-platform, architecture, signing, native-plugin, privacy/data-disclosure, age-rating, and store-testing requirements against official sources. Build and test real release configurations. Keep accounts, legal attestations, signing, and final publishing under the owner's control.

The critical human gate is after the three-support vertical slice: testers should want another attempt, understand why they lost, recognize different build choices, and read the screen on a phone. If that gate fails, revise pace, controls, enemies, or upgrades before creating the full content catalog. More content does not repair an uninteresting core loop.

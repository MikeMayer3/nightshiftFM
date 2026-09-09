# Content catalog

Current implementation: [0.10.4 delivery](M8_M10_DELIVERY.md). All 48 local
achievement conditions, twelve missions and the expanded enemy roster are now
implemented. The catalog below remains the design reference; runtime coefficients
and generated resources provide the exact tested values.

This is a design catalog for incremental implementation. It is not a claim that these assets or mechanics already exist. Numbers in tuning cards are initial configuration values for testing, not verified balance. Branch coefficients, cooldowns, durations, and target caps must be chosen explicitly in configuration and documented by M5; no upgrade is complete until it has a visible behavior, a valid tradeoff, and automated tests.

## 1. Support weapons and upgrade definitions

Each family has six basic tuning cards plus three specialization definitions, six specialization-specific modifier definitions, and three capstone definitions: 18 per family, 108 across six families. The six basic tuning cards are options for ranks 2, 4, 5, and 7; a player takes only four of those tuning selections in a fully ranked track. Rank 3 chooses the specialization, rank 6 chooses one of its two modifiers, and rank 8 grants its matching capstone. Tuning caps prevent invalid or excessive values.

Use IDs derived from the family and stable card keys; do not derive persisted IDs from the display names. Display all numerical and behavior changes before accepting a choice. A card that modifies an unsupported stat is invalid, not silently ignored.
### Valve Microphone (`arc_aerial`)

Chain damage, charge application, and optional shield support.

**Six tuning cards:** Coil Gain: +15% additive damage per pick, maximum 3 stacks; Fast Oscillator: +10% fire-rate bonus, maximum 3 stacks; Antenna Reach: +20% jump range, maximum 2 stacks; Extra Contact: +1 maximum chain target, maximum 2 stacks; Long Charge: +25% Charged duration, maximum 2 stacks; Boss Grounding: +15% damage against elites/bosses, maximum 2 stacks.

| Rank-3 specialization | Behavior | Rank-6 choice A | Rank-6 choice B | Rank-8 capstone |
|---|---|---|---|---|
| Storm Network | More chain targets but lower damage per target. | Long Route: greater jump distance, reduced fire rate. | Tight Circuit: more damage to tightly grouped targets, shorter jump distance. | Broadcast Storm: bounded branching chains within the attack target cap. |
| Lightning Spear | Trade chain targets for concentrated armor-penetrating strikes. | Needle Arc: more armor penetration, narrower target acquisition cone. | Capacitor Strike: slower attacks with stronger first hits. | Thunder Needle: a heavy piercing strike through a short aligned group. |
| Shield Tap | Trade damage for capped shield restoration on eligible direct hits. | Quick Charge: smaller, more frequent restoration. | Reserve Charge: accumulate a bounded reservoir, release on the next shield ability. | Closed Circuit: a brief overshield from a full reservoir; no self-triggered restoration. |

### Tape Deck (`echo_deck`)

Records eligible main-weapon attacks and replays weaker copies; never records its own echoes.

**Six tuning cards:** Playback Gain: +15% additive replay damage, maximum 3 stacks; Short Tape: reduce required main attacks between recordings by 1, bounded minimum, maximum 2 stacks; Fast Playback: reduce replay delay by 15%, bounded minimum, maximum 2 stacks; Second Track: +1 bounded replay copy, maximum 1 stack; Tracking Head: +20% retargeting search radius, maximum 2 stacks; Clean Recording: +5 percentage points of replay critical chance, maximum 2 stacks.

| Rank-3 specialization | Behavior | Rank-6 choice A | Rank-6 choice B | Rank-8 capstone |
|---|---|---|---|---|
| Rapid Repeat | Frequent, weaker echoes. | Double Tap: two quick copies with a lower coefficient each. | Staccato: tighter timing, reduced retarget range. | Loop Pedal: a fixed-size volley of nonrecursive echoes. |
| Layered Recording | Store a short bounded sequence before replaying it as a burst. | Long Side: more stored attacks, slower release. | Hot Master: fewer stored attacks, more damage. | Master Tape: release the bounded recorded burst toward a priority target. |
| Ghost Chorus | Echoes search for targets other than the original victim. | Wide Chorus: broader search, reduced per-copy damage. | Lead Singer: prefer marked or elite targets, fewer alternate targets. | Phantom Broadcast: a fan of echoes across a capped number of distinct targets. |

### Studio Monitor (`bass_driver`)

Area damage, knockback, and armor exposure.

**Six tuning cards:** Heavy Cone: +15% additive damage, maximum 3 stacks; Big Cabinet: +15% radius, maximum 2 stacks; Quick Beat: +10% fire-rate bonus, maximum 3 stacks; Push Coil: +20% knockback force, maximum 2 stacks; Cracking Tone: +15% Exposed strength, bounded armor floor, maximum 2 stacks; Sustained Note: +25% Exposed duration, maximum 2 stacks.

| Rank-3 specialization | Behavior | Rank-6 choice A | Rank-6 choice B | Rank-8 capstone |
|---|---|---|---|---|
| Wideband | Large-area coverage with lower peak damage. | Wide Cone: greater width, shorter reach. | Deep Cone: longer reach, reduced width. | Wall of Sound: a broad forward shockwave with a finite travel distance. |
| Compression | Narrow heavy pulses with greater exposure and less coverage. | Hard Clip: stronger armor reduction, slower cadence. | Direct Injection: more boss damage, weaker knockback. | Crushing Note: concentrated armor-breaking pulse; no instant boss deletion. |
| Aftershock | Leave a short-lived secondary pulse zone. | Ringing Floor: longer zone duration, weaker ticks. | Double Thump: an earlier second pulse, shorter zone duration. | Seismic Chorus: a capped sequence of aftershocks at the impact area. |

### Turntable (`needle_swarm`)

Stylus projectiles for penetration, pursuit, and marking priority targets.

**Six tuning cards:** Sharp Tip: +15% additive damage, maximum 3 stacks; Fast Platter: +10% fire-rate bonus, maximum 3 stacks; Through Groove: +1 pierce, maximum 2 stacks; Guide Arm: +20% baseline steering rate, maximum 2 stacks; Extra Stylus: +1 projectile per volley, bounded cap, maximum 2 stacks; Lasting Mark: +25% Marked duration, maximum 2 stacks.

| Rank-3 specialization | Behavior | Rank-6 choice A | Rank-6 choice B | Rank-8 capstone |
|---|---|---|---|---|
| Piercing Needles | Straighter projectiles that pass through more enemies. | Long Groove: additional pierce, lower damage after each hit. | Hard Cut: stronger first impact, fewer later hits. | Record Cutter: a finite piercing lane with per-target hit-once tracking. |
| Homing Needles | Sharper pursuit, less penetration. | Wide Seek: larger search radius, slower projectile travel. | Close Pursuit: faster turning near targets, shorter lifetime. | Needle Hurricane: a capped homing volley; no unlimited orbiting projectiles. |
| Marking Needles | Reduced direct damage but stronger support for focused fire. | Spotlight: stronger Marked bonus, fewer marked targets. | Full Set: mark more targets, weaker bonus per target. | Perfect Groove: a bounded vulnerability window on the priority marked target. |

### Spring Reverb (`reverb_well`)

Pulls a bounded group into a zone, with small baseline damage and control value.

**Six tuning cards:** Long Room: +20% duration, maximum 2 stacks; Large Chamber: +15% radius, maximum 2 stacks; Strong Draw: +20% pull force, maximum 2 stacks; Pressure Gain: +15% additive tick damage, maximum 3 stacks; Fast Reset: +10% activation-rate bonus, maximum 3 stacks; Extra Channels: +2 affected-target capacity, bounded cap, maximum 2 stacks.

| Rank-3 specialization | Behavior | Rank-6 choice A | Rank-6 choice B | Rank-8 capstone |
|---|---|---|---|---|
| Trap Room | Larger control area and longer holds, weaker damage. | Long Hall: duration emphasis, reduced pull speed. | Narrow Door: stronger pull, smaller radius. | Dead Room: a large bounded control field with boss-resistance fallback. |
| Pressure Well | Smaller area with stronger damage against grouped enemies. | Hard Walls: more tick damage, shorter duration. | Heavy Air: stronger pull/exposure, lower tick damage. | Implosion: a capped terminal burst based on trapped-target count. |
| Orbit Chamber | Enemies arc around the well before release. | Slow Orbit: greater control, fewer affected enemies. | Fast Orbit: stronger exit displacement, shorter hold. | Slingshot: a bounded release impulse, not physics collision damage between enemies. |

### Mixing Desk (`static_net`)

A slowing field with a small baseline projectile-interception budget.

**Six tuning cards:** Thick Static: +5 percentage points of slow strength, capped, maximum 2 stacks; Long Broadcast: +20% field duration, maximum 2 stacks; Wide Screen: +15% field radius, maximum 2 stacks; Fast Refresh: +10% activation-rate bonus, maximum 3 stacks; Strong Mesh: +1 projectile interception per field, capped, maximum 2 stacks; Lingering Noise: +20% residual slow duration, maximum 2 stacks.

| Rank-3 specialization | Behavior | Rank-6 choice A | Rank-6 choice B | Rank-8 capstone |
|---|---|---|---|---|
| Dead Air | Emphasize slowdown and brief enemy-ability interruption. | Blank Channel: stronger interruption, longer activation interval. | Low Hum: longer slow, weaker interruption. | Dead Zone: bounded ability disruption with boss cooldown/stagger rules. |
| Interference Screen | Emphasize interception, with weaker movement control. | Dense Mesh: more interception charges, smaller field. | Wide Mesh: larger coverage, fewer charges. | Signal Firewall: a temporary barrier with an explicit absorption budget. |
| Grounding Grid | Trade interception capacity for limited shield recovery. | Steady Ground: smaller periodic regeneration contributions. | Emergency Ground: a capped burst only when shield is low. | Safe Frequency: a brief recovery field that cannot be extended by its own effects. |


## 2. Main-weapon and shield branch guidance

For each main chassis, implement six compatible basic tuning options and three mutually exclusive behavioral branches, with two rank-6 variants and one rank-8 capstone per branch. Share implementation where appropriate, but every exposed option must affect the selected chassis. Branch names below define the three paths; the M5 content task must fill their explicit modifiers/caps and test them.

| Main chassis | Three branches | Example capstones |
|---|---|---|
| Pulse Transmitter | Penetrator; Ricochet; Charge Shot | Long piercing shot; bounded multi-bounce burst; slow heavy charged projectile |
| Sweep Transmitter | Focused Beam; Fan Sweep; Pulse Beam | Sustained boss burn; broad controlled sweep; timed high-power pulses |
| Burst Transmitter | Wide Scatter; Converging Volley; Stagger Burst | Wide close-defense volley; concentrated multi-hit burst; crowd-control volley with stagger limits |

Basic main tuning vocabulary: damage, cadence, critical chance, reach, target width/coverage, and chassis-compatible penetration or burst/pulse count. Keep all six useful on the selected chassis. A beam targeting a single point must not receive a fake projectile-count upgrade.

| Shield chassis | Baseline tradeoff | Three branch directions | Active ability |
|---|---|---|---|
| Capacitor | Large reserve, slower recovery | Deep Reserve; Damage Smoothing; Emergency Reserve | Temporary overshield with a fixed expiration |
| Relay | Smaller reserve, faster recharge | Fast Restart; Sustained Recharge; Recovery Pulse | Immediately restart normal recharge; incoming damage can still interrupt it |
| Feedback | Moderate reserve, limited retaliation | Reflection; Break Pulse; Retaliation Charge | Short reflection window for eligible enemy projectiles |

Basic shield tuning vocabulary: capacity, recharge rate, recharge delay, ability cooldown, temporary mitigation strength, and bounded break-recovery strength. Implement three branch-specific rank-3 choices, two rank-6 variants per branch, and one rank-8 capstone per branch for each shield chassis. Persistent chassis unlocks do not change rank-1 base stats.

## 3. Eight patchboard recipes

Two connections can be active. Each recipe needs two equipped endpoints and any listed status capability. All rates, target caps, and cooldowns are configuration values with tests. These are additional connected effects, not passive global rules.

| ID / recipe | Endpoints | Explicit payoff and safety rule |
|---|---|---|
| `ball_lightning` / Ball Lightning | Valve Microphone + Spring Reverb | A threshold of direct arc hits on trapped Charged enemies produces one capped discharge; shared internal cooldown and generated-hit exclusion prevent recursion. |
| `dead_zone` / Dead Zone | Mixing Desk + Studio Monitor | A direct bass hit on an enemy slowed by the connected net adds a brief Jammed effect; boss interruption cooldown still applies. |
| `b_side` / B-Side | Turntable + Tape Deck | Echoes prioritize marked targets; targeting must adapt correctly to projectile, volley, and beam attacks. |
| `live_wire` / Live Wire | Valve Microphone + Mixing Desk | Connected net ticks apply bounded Charged stacks at a fixed maximum rate; the application itself is not an extra arc attack. |
| `pressure_drop` / Pressure Drop | Studio Monitor + Spring Reverb | Bass attacks hitting the active well gain a capped grouping bonus; count eligible targets once per attack. |
| `double_drop` / Double Drop | Tape Deck + Studio Monitor | Every third eligible direct bass activation produces one weaker repeat; that repeat never advances the trigger counter. |
| `needle_thread` / Needle Thread | Main weapon + Turntable | Main attacks against marked targets receive one compatible penetration benefit; a beam instead uses an explicitly defined small damage benefit. |
| `feedback_loop` / Feedback Loop | Shield + Valve Microphone | A shield break emits one arc retaliation pulse with a long internal cooldown; it cannot restore the same shield or trigger another break pulse. |

## 4. Twelve station modules

Choose at most two distinct modules before a mission. Introduce modules after mission 4. All module gains and costs are visible. Values are provisional; each effect uses the same centralized stat calculation as ordinary upgrades. Modules cannot increase support-slot limits or grant free rank-3 branches.

| ID / module | Benefit | Cost |
|---|---|---|
| `hot_tubes` / Hot Tubes | +15% fire-rate bonus to attacks | −20% shield recharge rate |
| `long_mast` / Long Mast | +20% acquisition range | −10% maximum hull |
| `heavy_battery` / Heavy Battery | +25% shield capacity | −20% recharge rate |
| `fast_fuse` / Fast Fuse | −15% shield-ability cooldown | −15% shield capacity |
| `signal_booster` / Signal Booster | +15% additive attack damage | +1 second recharge delay |
| `quiet_room` / Quiet Room | +25% shield recharge rate | −10% support activation rate |
| `wideband_module` / Wideband Module | +20% area radius | −15% direct single-target attack damage |
| `narrowband_module` / Narrowband Module | +20% direct single-target damage | −15% area radius |
| `counterweight` / Counterweight | +25% displacement force | −10% projectile speed |
| `thin_wire` / Thin Wire | +30% Charged duration | −10% shield capacity |
| `night_ledger` / Night Ledger | One extra run reroll | −10% main-weapon damage |
| `glass_tower` / Glass Tower | +10 percentage points of main critical chance | −15% maximum hull |

Attack tags define area versus direct single-target damage; do not classify a piercing projectile inconsistently on different hits. All penalties participate in previews and save reconstruction.

## 5. Enemies, bosses, and missions

| Enemy family | Behavior | Intended answers |
|---|---|---|
| Swarmers | Low-health groups descend in formations | Area damage, chains, broad volleys |
| Divers | Telegraph, then accelerate toward the breach line | Early focus fire, slowing, timely shield use |
| Carriers | Release a bounded number of small enemies | Kill the carrier early, then area cleanup |
| Plated Signals | Large health pool with visible armor | Exposed, penetration, concentrated damage |
| Choir Casters | Temporarily protect nearby enemies | Prioritize the caster, interrupt, or overwhelm limited protection |
| Jammers | Channel a short disabling attack against one support | Focus fire, interruption, shield planning; never disable every weapon indefinitely |
| Mimics | Cycle through visible defensive states | Change targeting or use mixed damage patterns; no permanent total immunity |
| Mortars | Stop in the upper arena and fire destructible bolts | Kill the source, intercept bolts, or use normal shield capacity |

Boss 1: **The Dead Caller**. Alternates add waves with telegraphed bursts. Teaches target priority and shield timing.

Boss 2: **The Pirate Station**. Two visible aerials support a protected core. Damaging either aerial works with ordinary attacks; destroying both creates a vulnerability window. No particular support family is required.

Boss 3: **The Silence**. Alternates weak-point windows, limited jamming, and telegraphed heavy shots. Control-oriented builds contribute stagger rather than permanently stunning the boss. Auto-targeting must be able to select active weak points.

Mission structure: three regions × four missions. Region 1 introduces basic swarms, divers, carriers, and the first boss. Region 2 introduces protection, armor, and ranged attacks. Region 3 combines jammers, mimics, and earlier roles. Finales of non-boss missions use authored elite combinations. Do not give unseen mechanics to the player only in the hardest final wave.

Six Contracts: **Two-Channel Radio** (at most two supports); **Bare Antenna** (main weapon only, explicitly overrides starter/recruitment support rules); **Fragile Broadcast** (reduced hull, normal shields); **No Repeats** (no repeat tuning-card IDs); **Overcrowded Frequency** (swarm-heavy waves); and **Long Distance Call** (ranged enemy emphasis). Contracts declare overrides before starting and use separate scoring. The main-only contract is not the default campaign rule.

## 6. Forty-eight achievements

Unless specified otherwise, run achievements require completing a non-debug Campaign mission on Standard or higher. Weapon capstone discoveries count in completed Campaign, Contract, or Endless runs when their committed progress satisfies the condition. Cumulative defensive counters use committed eligible waves. Contracts and Endless achievements use their named modes. Tutorial demonstrations, editor/debug runs, and rolled-back partial waves do not count.

All rewards are cosmetics, cosmetic collection progress, or titles; no achievement is required for essential combat power. Give every achievement a stable reward ID and issue it once. A game's internal achievement count need not match any platform points system; configure native metadata separately.

| ID | Category | Name | Exact condition |
|---|---|---|---|
| `first_broadcast` | Progression | First Broadcast | Complete any Campaign mission. |
| `local_legend` | Progression | Local Legend | Complete all four Rooftop Relays missions on Standard or higher. |
| `deep_signal` | Progression | Deep Signal | Complete all four Flooded Switchyard missions on Standard or higher. |
| `still_on_air` | Progression | Still on Air | Complete all four Dead Band missions on Standard or higher. |
| `full_schedule` | Progression | Full Schedule | Complete all twelve Campaign missions on Hard or higher. |
| `overtime` | Progression | Overtime | Complete any regional finale on Overload. |
| `new_dials` | Progression | New Dials | Unlock all three main-weapon chassis. |
| `backup_plans` | Progression | Backup Plans | Unlock all three shield chassis. |
| `arc_aerial_first_capstone` | Weapon mastery | Valve Microphone: Turn It Up | Reach a rank-8 capstone with Valve Microphone in an eligible completed run. |
| `arc_aerial_three_capstones` | Weapon mastery | Valve Microphone: Full Range | Record all three distinct rank-8 specialization capstones for Valve Microphone across eligible completed runs. |
| `echo_deck_first_capstone` | Weapon mastery | Tape Deck: Turn It Up | Reach a rank-8 capstone with Tape Deck in an eligible completed run. |
| `echo_deck_three_capstones` | Weapon mastery | Tape Deck: Full Range | Record all three distinct rank-8 specialization capstones for Tape Deck across eligible completed runs. |
| `bass_driver_first_capstone` | Weapon mastery | Studio Monitor: Turn It Up | Reach a rank-8 capstone with Studio Monitor in an eligible completed run. |
| `bass_driver_three_capstones` | Weapon mastery | Studio Monitor: Full Range | Record all three distinct rank-8 specialization capstones for Studio Monitor across eligible completed runs. |
| `needle_swarm_first_capstone` | Weapon mastery | Turntable: Turn It Up | Reach a rank-8 capstone with Turntable in an eligible completed run. |
| `needle_swarm_three_capstones` | Weapon mastery | Turntable: Full Range | Record all three distinct rank-8 specialization capstones for Turntable across eligible completed runs. |
| `reverb_well_first_capstone` | Weapon mastery | Spring Reverb: Turn It Up | Reach a rank-8 capstone with Spring Reverb in an eligible completed run. |
| `reverb_well_three_capstones` | Weapon mastery | Spring Reverb: Full Range | Record all three distinct rank-8 specialization capstones for Spring Reverb across eligible completed runs. |
| `static_net_first_capstone` | Weapon mastery | Mixing Desk: Turn It Up | Reach a rank-8 capstone with Mixing Desk in an eligible completed run. |
| `static_net_three_capstones` | Weapon mastery | Mixing Desk: Full Range | Record all three distinct rank-8 specialization capstones for Mixing Desk across eligible completed runs. |
| `patch_cable` | Builds | Patch Cable | Trigger at least one connected synergy and win the mission. |
| `sound_engineer` | Builds | Sound Engineer | Trigger each of the eight distinct connection recipes in at least one completed eligible run. |
| `stereo` | Builds | Stereo | Win with both active connections each having triggered at least ten times in that mission. |
| `minimalist` | Builds | Minimalist | Win a Campaign mission with maximum simultaneous support count no greater than two throughout the run. |
| `all_hands` | Builds | All Hands on Deck | Win with five distinct support families, each recording damage, effective shield gain, interception, or nonzero enemy control contribution. |
| `soloist_duet` | Builds | Power Duet | Win with two support weapons at rank 8; do not count the main gun or shield. |
| `variety_show` | Builds | Variety Show | Win at least one Campaign mission with each of the six support families equipped. |
| `deep_focus` | Builds | Deep Focus | Win with both the main weapon and shield at rank 8. |
| `no_scratches` | Defense | No Scratches | Win with cumulative hull damage taken equal to zero; healing never erases damage history. |
| `unbroken` | Defense | Unbroken | Win with zero shield-break events. |
| `bouncer` | Defense | Bouncer | Reflect 100 eligible enemy projectiles across committed waves; count each original projectile once. |
| `second_wind` | Defense | Second Wind | In one mission, recover from a true shield break to full current maximum shield, then win. |
| `close_call` | Defense | Close Call | Win while current hull is greater than zero and no more than 10% of its current maximum. |
| `hold_the_line` | Defense | Hold the Line | Win a mission after a single activation of a shield ability mitigates or reflects at least three distinct incoming attacks. |
| `contract_two_channel` | Contracts | Two-Channel Radio | Complete the Two-Channel Radio Contract under its declared restrictions. |
| `contract_bare_antenna` | Contracts | Bare Antenna | Complete the Bare Antenna Contract under its declared restrictions. |
| `contract_fragile_broadcast` | Contracts | Fragile Broadcast | Complete the Fragile Broadcast Contract under its declared restrictions. |
| `contract_no_repeats` | Contracts | No Repeats | Complete the No Repeats Contract under its declared restrictions. |
| `contract_overcrowded_frequency` | Contracts | Overcrowded Frequency | Complete the Overcrowded Frequency Contract under its declared restrictions. |
| `contract_long_distance` | Contracts | Long Distance Call | Complete the Long Distance Call Contract under its declared restrictions. |
| `know_enemy` | Discovery | Know Your Interference | Encounter all eight base enemy families in committed eligible waves; variants do not create additional families. |
| `boss_notebook` | Discovery | Boss Notebook | Defeat each of the three regional bosses at least once. |
| `blueprint_collector` | Discovery | Blueprint Collector | Unlock all twelve station modules. |
| `signal_archive` | Discovery | Signal Archive | Collect all twelve mission log entries, each awarded on that mission’s first completion. |
| `endless_20` | Endless | Twenty Past Midnight | Complete wave 20 in Endless. |
| `endless_40` | Endless | Late Shift | Complete wave 40 in Endless. |
| `endless_60` | Endless | Never Off Air | Complete wave 60 in Endless. |
| `endless_three` | Endless | Three-Channel Marathon | Complete wave 20 in Endless with no more than three support families used at any time in that run. |


Achievement implementation records should include `id`, `name_key`, `description_key`, `category`, `progress_kind`, `threshold`, `condition_id`, `condition_parameters`, `eligible_modes`, `minimum_difficulty`, `reward_id`, and optional `ios_achievement_id` / `android_achievement_id`. These are schema requirements for Codex to turn into validated content, not names of an existing SDK API.

Progression rewards and achievement unlocks use committed game events. Evaluate equipment history, not only the final inventory. For capstone mastery, store a set of branch IDs, not a counter that can be incremented by repeating the same branch. Native synchronization needs monotonic progress and retry-safe bookkeeping.

# Nightshift FM — Codex development handoff

Current build: **0.10.3 — defend the radio station.** Vintage studio instruments
fight modern audio devices with distinct sound-wave attacks. The main tower stays
centered below the raised shield boundary. A hunting radio needle, rotating knobs,
compact header and bottom Station Health display leave more room for the field.
New runs use automatic weapons, modules are available immediately, and upgrade
sheets keep the paused battlefield visible. Setup uses illustrated equipment cards,
optional details and a graphical twelve-station route.
See [current revision and verification](docs/M10_MOBILE_POLISH.md).

Android debug output: `builds/android/nightshift-m10.apk` (0.10.3/code 15).
M8/M9/M10 remain partial; full human and physical-performance acceptance are open.

**M9 has started with local achievements, tracked goals, cosmetic titles and
report history.** The catalog has 48 entries: 25 evaluated conditions and 23
explicitly pending. Endless is not implemented. M8's first three authored
missions are available; its remaining content and human acceptance stay open.
The title and haunted-radio theme are provisional; iOS remains deferred.

Open `project.godot` with Godot 4.7.2 standard, or follow the
[development instructions](docs/DEVELOPMENT.md). Choose **New mission · Standard**,
select a campaign mission, choose equipment and **Go live**. **Continue saved
mission** restores an existing run. Missions 1–3 use distinct ten-wave encounters;
missions 4–12 still explicitly identify their reused prototype battles.

Read [M9 achievements and remaining scope](docs/M9_ACHIEVEMENTS.md),
[M8 opening encounters and remaining scope](docs/M8_ENCOUNTERS.md),
[M7 progression and verification](docs/M7_PROGRESSION.md),
[M6 patchboard](docs/M6_PATCHBOARD.md), [M5 arsenal](docs/M5_ARSENAL.md),
[implementation status](docs/IMPLEMENTATION_STATUS.md), and
[mobile setup](docs/MOBILE_DEVELOPMENT.md). The previous M7 Android artifact is
`builds/android/nightshift-m7.apk`, version 0.7.0/code 11. The new M10 artifact
includes the current M8/M9 increments and the M10 presentation pass. Existing prototype saves continue with their original
rules; New mission starts the campaign.

This handoff includes the local M9 achievement and M10 presentation increments.
Campaign → **Achievements** opens progress and goals. Editor/debug/prototype runs
do not earn rewards; production native eligibility validation remains pending.
Pixel installation and save-preservation evidence is recorded in the
[current delivery notes](docs/M10_MOBILE_POLISH.md).

## Project in one paragraph

Create an offline-first, portrait Android/iOS fixed-turret roguelite defense game. The player is a haunted radio transmitter at the bottom of the arena; enemies fly in from the top. The player has one main weapon, one shield, and at most five support weapons chosen from six families. Every mission resets combat power. Permanent progress unlocks alternatives, missions, cosmetics, and achievements. Depth comes from branching weapon upgrades, selective specialization, target priorities, enemy composition, and two configurable synergy connections.

## Clone and continue

```sh
git clone https://github.com/MikeMayer3/nightshiftFM.git
cd nightshiftFM
```

The repository root contains `project.godot` and `AGENTS.md`. Follow the
[development instructions](docs/DEVELOPMENT.md), including the Windows PowerShell
commands, to import with Godot 4.7.2 standard before running tests or the game.
Generated `.godot/` caches, APKs/builds, credentials, and local saves are excluded.
GitHub synchronizes source and evidence; it does not synchronize device saves.

Read `docs/IMPLEMENTATION_STATUS.md` before continuing. M10 is the current
owner-requested milestone; stop and report its evidence before starting M11.
`prompts/START_HERE.md` preserves the original M0 prompt as history.

| File | Purpose |
|---|---|
| `AGENTS.md` | Persistent implementation and reporting rules for Codex |
| `docs/GAME_DESIGN.md` | Rules, core loop, progression, technical architecture, and scope |
| `docs/CONTENT_CATALOG.md` | Weapons, branching upgrade ideas, modules, enemies, and 48 achievement definitions |
| `docs/MILESTONES.md` | M0–M11 with dependencies, deliverables, acceptance criteria, and human gates |
| `docs/REFERENCES.md` | Official engine/platform references and facts to recheck |
| `prompts/START_HERE.md` | Initial and continuation prompts |

Start with the narrow prototype. The eventual six-weapon, twelve-mission catalog is a content ceiling for the first complete release, not the first implementation task. Missing SDKs, hardware, signing credentials, or store accounts must be reported as blockers to the affected checks rather than silently treated as passed.

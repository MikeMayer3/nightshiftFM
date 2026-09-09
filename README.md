# Nightshift FM — Codex development handoff

**M8 has started: the first three Rooftop Relays missions now have authored
encounters, formations, briefings and family elites.** M7 progression remains
available. Human progression/pacing acceptance remains open.
The title and haunted-radio theme are provisional; iOS remains deferred.

Open `project.godot` with Godot 4.7.2 standard, or follow the
[development instructions](docs/DEVELOPMENT.md). Choose **New mission · Standard**,
select a campaign mission, choose equipment and **Go live**. **Continue saved
mission** restores an existing run. Missions 1–3 use distinct ten-wave encounters;
missions 4–12 still explicitly identify their reused prototype battles.

Read [M8 opening encounters and remaining scope](docs/M8_ENCOUNTERS.md),
[M7 progression and verification](docs/M7_PROGRESSION.md),
[M6 patchboard](docs/M6_PATCHBOARD.md), [M5 arsenal](docs/M5_ARSENAL.md),
[implementation status](docs/IMPLEMENTATION_STATUS.md), and
[mobile setup](docs/MOBILE_DEVELOPMENT.md). The local Android debug build is
`builds/android/nightshift-m7.apk`, version 0.7.0/code 11; it does not contain this
M8 source increment. Existing prototype saves
Continue with their original rules; New mission starts the campaign. Source and
APKs from this local milestone have not been published. Radio-tuner art comes later.

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

M7 implementation is ready for progression playtesting. Read
`docs/IMPLEMENTATION_STATUS.md` before continuing. Stop at M7; M8 requires another
owner request. `prompts/START_HERE.md` preserves the original M0 prompt as history.

| File | Purpose |
|---|---|
| `AGENTS.md` | Persistent implementation and reporting rules for Codex |
| `docs/GAME_DESIGN.md` | Rules, core loop, progression, technical architecture, and scope |
| `docs/CONTENT_CATALOG.md` | Weapons, branching upgrade ideas, modules, enemies, and 48 achievement definitions |
| `docs/MILESTONES.md` | M0–M11 with dependencies, deliverables, acceptance criteria, and human gates |
| `docs/REFERENCES.md` | Official engine/platform references and facts to recheck |
| `prompts/START_HERE.md` | Initial and continuation prompts |

Start with the narrow prototype. The eventual six-weapon, twelve-mission catalog is a content ceiling for the first complete release, not the first implementation task. Missing SDKs, hardware, signing credentials, or store accounts must be reported as blockers to the affected checks rather than silently treated as passed.

# Nightshift FM — Codex development handoff

Current build: **0.10.4 — twelve stations, Contracts and Endless.** Defend
radio with a centered transmission tower and six vintage instrument families
against modern devices. All twelve ten-wave missions, eight regular enemy roles,
three bosses, Hard/Overload and six Contracts are playable. All 48 local
achievement conditions are evaluated; debug/editor play remains ineligible.

The M10 pass adds distinct device tells, rank hardware, regional scenery, original
music and a compact patchboard. The approved tuning dial, rotating knobs, tall
field and bottom Station Health layout remain intact. Select **New broadcast**,
a mission and optionally **Broadcast modes**, then equipment and **Go live**.
Modules are available immediately. Existing saves retain their original rules.

Android debug artifact: `builds/android/nightshift-m10.apk` (0.10.4/code 16).
Updated on the physical Pixel 10 Pro XL with existing saves preserved. Emulator
playtests and automated checks passed; physical gameplay, iPhone and human
acceptance remain open. No M11 release work.
See [delivery and exact evidence](docs/M8_M10_DELIVERY.md) and
[implementation status](docs/IMPLEMENTATION_STATUS.md).

Open `project.godot` in Godot 4.7.2 standard, or follow
[development instructions](docs/DEVELOPMENT.md) and
[mobile setup](docs/MOBILE_DEVELOPMENT.md).

## Project in one paragraph

Create an offline-first, portrait Android/iOS fixed-turret roguelite defense game. The player protects a radio station using its centered transmission tower and vintage instruments; modern audio devices attack from the top. The player has one main weapon, one shield, and at most five support weapons chosen from six families. Every mission resets combat power. Permanent progress unlocks alternatives, missions, cosmetics, and achievements. Depth comes from branching weapon upgrades, selective specialization, target priorities, enemy composition, and two configurable synergy connections.

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

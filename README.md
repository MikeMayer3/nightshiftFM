# Nightshift FM — Codex development handoff

Current build: **0.10.15 — note drones, damage numbers and Mixer guidance.**
Defend the radio station with a centered transmission tower and six vintage
instrument families across twelve stations, Contracts and Endless.

[Download the Android APK and construction summary](https://github.com/MikeMayer3/nightshiftFM/releases/tag/v0.10.15).
The release includes SHA-256 checksums. The APK is an Android ARM64 debug build
(version code 27), not a Play Store production bundle.

Hits display floating damage numbers with larger gold criticals. Turntable notes
orbit enemies and fire three baseline shots before disappearing. An in-game
reminder points players to the Mixer. Android Back now closes a paused Mixer and
returns from the contribution report to results.

Version 0.10.15 is installed on the physical Pixel with saves/settings preserved;
the phone was locked during the final launch check. Desktop automated and visual
evidence is recorded in [note drones](docs/NOTE_DRONES.md),
[damage numbers](docs/DAMAGE_NUMBERS.md) and the
[release playthrough audit](docs/RELEASE_PLAYTHROUGH_AUDIT.md).
Human gameplay acceptance, the intermittent Android shield-caption issue and
remaining store gates are still open. See [current status](docs/IMPLEMENTATION_STATUS.md).

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

Read `handoff.md` and `docs/IMPLEMENTATION_STATUS.md` before continuing. The current
work is owner-directed combat/UI polish; do not start another milestone automatically.
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

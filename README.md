# Nightshift FM — Codex development handoff

**M2 is implemented: one playable offline three-wave combat prototype.**
M0 is accepted; iOS is deferred at the owner's request. M2 human playtest
acceptance remains open. The title and haunted-radio theme are provisional.

Open `project.godot` in Godot 4.7.2 standard, or follow the
[development instructions](docs/DEVELOPMENT.md). Select **Start · Three waves**.
See [M2 controls and reproduction](docs/M2_COMBAT.md),
[implementation evidence](docs/IMPLEMENTATION_STATUS.md), and
[mobile setup](docs/MOBILE_DEVELOPMENT.md). The current Android export is
`builds/android/nightshift-m2.apk`. No M3 upgrades or mission saves are implemented.

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

M2 is implemented, with its human playtest gate still open. Read
`docs/IMPLEMENTATION_STATUS.md` before continuing and request one milestone at a
time. `prompts/START_HERE.md` preserves the original M0 prompt as history; do not
restart the foundation or begin M3 automatically.

| File | Purpose |
|---|---|
| `AGENTS.md` | Persistent implementation and reporting rules for Codex |
| `docs/GAME_DESIGN.md` | Rules, core loop, progression, technical architecture, and scope |
| `docs/CONTENT_CATALOG.md` | Weapons, branching upgrade ideas, modules, enemies, and 48 achievement definitions |
| `docs/MILESTONES.md` | M0–M11 with dependencies, deliverables, acceptance criteria, and human gates |
| `docs/REFERENCES.md` | Official engine/platform references and facts to recheck |
| `prompts/START_HERE.md` | Initial and continuation prompts |

Start with the narrow prototype. The eventual six-weapon, twelve-mission catalog is a content ceiling for the first complete release, not the first implementation task. Missing SDKs, hardware, signing credentials, or store accounts must be reported as blockers to the affected checks rather than silently treated as passed.

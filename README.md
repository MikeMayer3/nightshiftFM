# Nightshift FM — Codex development handoff

**M4 now includes support turrets with live cooldown bars, aimed bursts, and kill-earned offensive upgrades.**
M0 is accepted; iOS is deferred at the owner's request. The M4 human fun gate remains open: three testers, two phone attempts each. The title and haunted-radio theme are provisional.

Open `project.godot` in Godot 4.7.2 standard, or follow the
[development instructions](docs/DEVELOPMENT.md). Select **New mission · Standard**
or **Continue saved mission**. Read [support turrets and random-build tests](docs/M4_SUPPORT_TURRETS.md), [current controls and balance](docs/M4_ACTIVE_COMBAT.md), [kill-meter flow](docs/M4_SIGNAL_FLOW.md), [M4 mechanics](docs/M4_SLICE.md), [phone playtest](docs/M4_PLAYTEST.md),
[implementation evidence](docs/IMPLEMENTATION_STATUS.md), and
[mobile setup](docs/MOBILE_DEVELOPMENT.md). The Android debug export is
`builds/android/nightshift-m4.apk`; download the installable APK from the
[M4 0.4.3 playtest release](https://github.com/MikeMayer3/nightshiftFM/releases/tag/v0.4.3). Android 0.4.3/code 7. Existing M3/M4/Signal saves Continue with their original rules; choose New mission to play the new flow. Radio-tuner art comes later.

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

M4 technical implementation is ready; human playtesting is still required. Read
`docs/IMPLEMENTATION_STATUS.md` before continuing and request one milestone at a
time. `prompts/START_HERE.md` preserves the original M0 prompt as history; do not
restart the foundation or begin M5 before M4 gameplay acceptance.

| File | Purpose |
|---|---|
| `AGENTS.md` | Persistent implementation and reporting rules for Codex |
| `docs/GAME_DESIGN.md` | Rules, core loop, progression, technical architecture, and scope |
| `docs/CONTENT_CATALOG.md` | Weapons, branching upgrade ideas, modules, enemies, and 48 achievement definitions |
| `docs/MILESTONES.md` | M0–M11 with dependencies, deliverables, acceptance criteria, and human gates |
| `docs/REFERENCES.md` | Official engine/platform references and facts to recheck |
| `prompts/START_HERE.md` | Initial and continuation prompts |

Start with the narrow prototype. The eventual six-weapon, twelve-mission catalog is a content ceiling for the first complete release, not the first implementation task. Missing SDKs, hardware, signing credentials, or store accounts must be reported as blockers to the affected checks rather than silently treated as passed.

# Codex project instructions

## Authority and scope

Implement the game described in `docs/GAME_DESIGN.md`. Work only on the milestone explicitly requested by the user from `docs/MILESTONES.md`. This document describes a new project; inspect the actual repository before modifying anything. Preserve existing user work and do not overwrite conflicting files without explaining the conflict.

Use the haunted-radio theme as a replaceable working skin. Do not expand the support roster beyond six families or the simultaneous support limit beyond five. The main weapon and shield are separate. Do not add multiplayer, an account system, advertising, paid power, gacha, energy timers, a backend, or health/fitness integration.

All missions start at rank 1 for their equipped starting gear and with no inherited temporary combat modifiers. Unlocking an option must not secretly grant permanent damage or shield bonuses. Never mutate shared content resources to hold run state.

## Toolchain

Baseline: Godot 4.7.2 standard build, typed GDScript, 2D, Compatibility renderer. Pin the actual engine and export-template versions. If the installed toolchain differs, report the difference and document a deliberate decision; do not silently upgrade the project. Check official documentation for version-specific APIs. Do not invent engine APIs, plugin classes, build results, or native integrations.

Use local desktop execution and headless tests where available. Use `GODOT_BIN` in scripts rather than a hard-coded installation path. If the engine or an SDK is unavailable, implement only what can be safely inspected and mark execution checks as NOT RUN. Never replace an unrun test with a claimed pass.

## Architecture

Prefer small typed components and a small number of explicit services. Use immutable `.tres` content definitions with stable IDs, and separate serializable runtime state. Keep damage, stats, eligibility, progression, and achievement evaluation testable without rendering. Use signals for explicit domain events; avoid a global event bus that becomes an untyped dumping ground.

Keep art/audio/display names out of combat conditionals. Use localization keys for UI text. Content definitions describe supported behavior; they are not an arbitrary scripting language. Add no general-purpose visual editor or framework before it is required.

Keep gameplay RNG separate from visual/audio RNG. Persist seed, RNG state, content version, and engine version. Seeded draft/wave reproducibility is required within a pinned build; cross-device bit-identical physics replays are not promised.

Generated attacks carry a root attack ID, source ID, generation depth, and eligible trigger flags. Echoes cannot echo themselves. Reflections cannot reflect themselves. Apply internal cooldowns and bounded generation counts to avoid recursive proc storms. Never silently remove gameplay damage to hide a performance problem.

## Saves and platform boundaries

Save only validated IDs, numeric values, and explicit state. Use versioned saves, a temporary write plus recoverable backup, and migration tests. Run and reward commits must be idempotent. The crash-resume contract is wave-checkpoint replay, not exact arbitrary-frame restoration. Uncommitted partial-wave achievement progress must not be counted twice.

Core play, local achievements, and local saves must work offline without authentication. Native achievements belong behind a platform interface with an honest unavailable/no-op implementation. Native service achievements are not cross-platform cloud saving. Do not commit signing keys, provisioning profiles, store credentials, or secrets. Do not publish or purchase anything without an explicit user request.

## Testing and completion

For each requested milestone:
1. Inspect relevant code and report the bounded implementation plan.
2. Implement the smallest complete playable or testable increment.
3. Add regression tests for the new behavior and previously discovered bugs.
4. Run the import check, relevant unit/integration tests, and desktop smoke check when possible.
5. Run device checks only when real hardware and credentials are available; distinguish emulator, simulator, and physical-device evidence.
6. Update `docs/IMPLEMENTATION_STATUS.md`, including implemented scope, changed files, exact commands, results, and remaining blockers.
7. Stop after that milestone; do not start the next one automatically.

A test report must distinguish PASS, FAIL, and NOT RUN. Report warnings and limitations. Human playtesting, asset approval, real-device usability, store signing, and store submission cannot be certified by unit tests.

Never make destructive Git changes, delete unrelated files, or fabricate commits. Keep dependencies minimal, pin approved dependencies, and record their licenses. Original placeholder graphics are acceptable; copyrighted commercial music and unlicensed assets are not.

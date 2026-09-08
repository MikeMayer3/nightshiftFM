# Initial prompt to paste into Codex

Read AGENTS.md, docs/GAME_DESIGN.md, and the M0 section of docs/MILESTONES.md. Inspect the repository before changing files. We are building the Android/iOS portrait fixed-turret roguelite defense game in those documents, using Nightshift FM as a provisional theme.

Implement **M0 only**: the Godot project foundation, desktop boot scene, typed project structure, data-definition foundations, test entry point, toolchain wrapper, and reproducible import/smoke-check instructions. Use the pinned Godot 4.7.2 standard/GDScript baseline unless the actual environment requires a documented decision. Do not create the complete combat game, the content catalog, native service integrations, a backend, or monetization.

First report your bounded plan and any concrete missing tools. Then implement the smallest complete M0 increment. Add tests and documentation rather than claiming checks passed from inspection. Use a GODOT_BIN environment variable for the engine path; do not assume a particular machine installation. When tools are unavailable, mark the affected commands NOT RUN and give exact reproduction steps.

Preserve the design constraints: one main gun and one shield plus no more than five support families from a six-family roster; every mission resets combat power; persistent progression unlocks alternatives and cosmetics. Keep immutable content separate from runtime state. Never commit signing credentials or publish anything.

Finish with changed files, exact commands and results, manual verification steps, known limitations, and the updated docs/IMPLEMENTATION_STATUS.md. Stop at M0 and identify its remaining acceptance checks. Do not begin M1 automatically.

---

# Continuation prompt template

Read AGENTS.md, docs/IMPLEMENTATION_STATUS.md, and milestone M[N] in docs/MILESTONES.md. Inspect the relevant code and the evidence for dependencies. Implement **only M[N]**, preserving previously accepted behavior. Do not assume an earlier milestone passed merely because its files exist.

Before coding, summarize the bounded change. Implement it, add the required regression tests, run the available checks, and update implementation status with PASS / FAIL / NOT RUN evidence. Record any unavailable physical-device, SDK, account, signing, or human-playtest checks as blockers to their associated gate, not as completed work.

Stop after M[N]. Report what changed, how to run it, which criteria passed, which remain open, and the next human acceptance action. Do not expand the roster or introduce unrequested systems.

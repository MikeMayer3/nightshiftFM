# Nightshift FM — resume here

Latest delivery: **0.10.5 / Android version code 17**, on `main`.
Repository: `https://github.com/MikeMayer3/nightshiftFM`.
Checkout: `/Users/michaelmayer/Projects/Nightshift FM/nightshift_fm_codex_pack`.
Read `AGENTS.md` and `docs/IMPLEMENTATION_STATUS.md`, then verify Git state before
starting the next user request. No additional milestone was requested at handoff.

The latest source includes:

- Studio mixer replacing the primary patchboard: Direct, AOE, Control faders;
  3 points initially, 5 after mission 4, 7 after mission 12, max 4 per fader.
  Free redistribution during paused combat; optional connection view; no forced
  connection intermissions in new broadcasts. Run-local settings survive Continue.
- Randomized decimal FM targets, deterministic on resume, with independent
  presentation RNG; richer modern-device enemy art and compact status cues
  replacing confusing enclosing circles.
- Prior campaign, difficulty, Contracts, Endless, and achievement implementation
  remains in place. These requests do not establish human acceptance of every
  earlier milestone; use the documented evidence boundaries.

Validation: 5,494 regression checks, 156 rendered/input checks at 360×640 and
450×950, seven foundation checks, import and startup smoke passed. Isolated
Android emulator touch tests passed for slider dragging, budget limits,
redistribution, frozen time and app-restart persistence.

Physical Pixel 10 Pro XL was updated in place to 0.10.5 and launched successfully.
Both save files remained byte-identical before/after installation and launch;
no script/crash errors were found. Evidence: `docs/evidence/M10-mixer/`, especially
`pixel-install.json`. Player package is `org.nightshiftfm.spike`; the emulator QA
package is `org.nightshiftfm.mixerqa`. Save backups and APKs remain under ignored
`builds/`; do not commit them. Human gameplay/balance/usability acceptance is not
established by these checks.

Mixer rules: `docs/STUDIO_MIXER.md`. Art direction: `docs/RADIO_ART_DIRECTION.md`.
Pinned engine: Godot 4.7.2. Normal commands:

```sh
export GODOT_BIN=/Applications/Godot.app/Contents/MacOS/Godot
sh tools/godot.sh import
sh tools/godot.sh test
sh tools/godot.sh smoke
```

The user prefers compact graphical UI, vintage radio instruments defending a
station against modern audio devices, and autonomous execution of authorized
work. Preserve existing saves and report actual device, test, and Git outcomes.

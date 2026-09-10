# P0 — unfamiliar-player playtest kit

Prepared 2026-09-10. **Kit ready; participant sessions and findings NOT RUN.**
This kit implements the preparation portion of [P0](../ADDITIONS_ROADMAP.md).
It does not certify human acceptance of the game or replace device release checks.

## Start here

1. Choose one candidate build. Complete the build record below before testing.
2. Use a dedicated test device/profile with no valuable player saves. Confirm it
   starts with a fresh campaign through the normal menu. Do not clear the owner's
   installed game data to prepare a session. If isolation is unavailable, record
   the existing progress and classify the session as returning-player testing.
3. Copy [SESSION_TEMPLATE.md](SESSION_TEMPLATE.md) for each participant, using
   anonymous IDs such as P01. It includes the player's feedback sheet.
4. Use [OBSERVATIONS.csv](OBSERVATIONS.csv) for timestamped events and
   [FINDINGS.csv](FINDINGS.csv) to group evidenced issues after sessions.
5. Conduct three observed sessions first. Fix obvious blockers in a separately
   selected roadmap task, then test the revised build with another 7–12 unfamiliar
   players. Keep cohorts/builds separate; don't combine their rates.

Allow about 30–40 minutes per person, including an optional second run and guided
checks. A participant may finish early or decline any step. No participant has
been recruited, contacted or scheduled by preparing this kit.

## Candidate and tested-build identity

The current source is on `main`, based on
`80e514f0821d1a44fb6710d769ae8a0e99c73910`, with uncommitted gameplay/polish changes.
`project.godot` and the Android preset both say `0.10.6`; the Android code is 18.
**Version 0.10.6 and this Git commit alone cannot distinguish the old phone build
from the later local polish.** The handoff describes the phone delivery as
predating the latest scenery, splash and shield revisions; device state was not
rechecked while preparing this kit.

No new APK was exported or installed for P0. Before a participant session, record:

| Required field | Value to fill before testing |
|---|---|
| Candidate ID | A unique label for this exact artifact/source snapshot |
| Build date/time and timezone | |
| Git commit and dirty/clean state | |
| Source snapshot identity | Commit if clean; archived source SHA-256 if dirty |
| APK/file name and SHA-256 | Required for an Android artifact |
| Package, version name, version code | Read from the artifact/device |
| Engine version | Actual version used, not just the repository pin |
| Install verification | Device/package/version checked; whether this was a fresh test install |
| Candidate preflight | Launch, new mission, one upgrade, shield, mixer, Continue |
| Prior technical evidence | Link and build identity; label older-build evidence |
| Latest smoke/device results | PASS / FAIL / NOT RUN plus evidence |

For a prepared Android artifact, `shasum -a 256 /absolute/path/to/candidate.apk`
gives its identity. Hash the artifact actually installed; do not infer its contents
from the name. For desktop sessions, freeze/archive the tested source and hash
that archive before testing, rather than testing a moving working tree.
Preserve the artifact privately so an issue can be reproduced later.

**Preflight:** the facilitator checks the route menu → first Campaign mission →
equipment → combat on a separate test profile, confirms the latest shield has
the violet dome and temporary reserve display, and checks a normal upgrade and
Continue. Record problems before inviting participants. Fresh participants must
not inherit this preflight's unlocks. An unprepared artifact is NOT READY for a
session, even though this kit is ready.

Do not use older M4 playtest instructions: they describe obsolete manual Burst,
recruitment and starting-loadout behavior. The current automatic-attack flow,
hold-to-focus, Shield Boost and Mixer are the relevant controls.

## Facilitator script

Keep the facilitator notes below away from the participant during the first run.
Record elapsed timestamps from handing over the title screen. Screen recording
is optional; ask whether it is okay before recording and avoid collecting names
or personal notifications. Written observations are sufficient.

### A. Introduction — about 2 minutes

Say: “I'd like to see how this game comes across to someone new. We're testing the
game, not you. Please use it as you normally would. You can stop whenever you want.
If something is unclear, that's useful for me to see.”

Record prior familiarity with Nightshift, survival games and defense games. Show
the title/menu without explaining the goal, shield, mixer, builds or controls.
Do not mention the proposed price or pitch why the game should be fun yet.

### B. First run — self-directed

Say: “Please explore and start playing whenever you're ready.”

Observe how they start, choose equipment and upgrades, respond to danger, and use
controls. Capture hesitation as observable behavior: repeated taps, revisiting a
screen, asking what something does, or a timed pause. Do not call quiet thinking
“confusion” without evidence. Note upgrade choices at branch decisions when
visible; don't distract the player by demanding every number.

If asked for help, first say: “What would you try?” If they are stuck, offer the
smallest useful instruction and record its exact wording/time. Don't leave them
frustrated to protect the protocol. All behavior after relevant help is assisted.

Do not force a loss, tell them to choose a weak build, recommend Bass/Net, ask
them to use the shield, or interrupt this run for device checks. If it has not
ended after about 15 minutes, offer to pause and record “unfinished,” not defeat.

### C. Natural stopping point and retry observation

At results or a pause chosen by the player, allow a brief natural pause. Observe
whether they start another run or ask to play again **before any retry prompt**.
Record spontaneous retry as yes/no; use not-observed if time or interruption
removed the opportunity. Accepting an invitation is a prompted retry.

Then ask, without correcting answers:

- “What were you trying to achieve?”
- “What changed when you chose your upgrades?”
- “What do you think led to that result?”
- “What would you try differently?”

Write the player's explanation separately from the game's report. On defeat,
compare their account with visible/reproducible evidence after they answer. If
they won or never lost, mark loss understanding NOT OBSERVED, not PASS.

### D. Optional second run

If they did not already choose to retry, say: “Would you like another attempt, or
would you rather finish?” Record whether the retry was spontaneous or prompted.
Do not pressure them. Let them select the strategy. Explain only controls they
requested help with and retain that intervention in the record.

Record whether they change equipment, branches, targeting or mixer choices for a
reason they can explain. A second run on the same profile is a repeat run, not a
second independent first-time participant.

### E. Guided comprehension and interruption checks — about 5 minutes

Do these after measuring unprompted play. Label all observations GUIDED.

- Ask “What do you think the Shield button does?” before teaching it. Then invite
  them to try it and describe what changes and when it ends. Do not tell them the
  answer in the question. If there is no incoming damage, absorption is NOT
  OBSERVED; activation/expiry alone does not prove they understood absorption.
- Ask them to find a way to adjust the station's mix, then explain one fader's
  expected effect. Record whether they find it unaided or need a hint.
- In a new optional run or existing unfinished run, note mission/wave, equipment,
  and whether an upgrade choice is open. Have them background the app for about
  ten seconds and return. Observe continuity and confusion.
- If they agree, close/reopen the app and use Continue. Record the actual closure
  method: switching apps, swiping from recents and OS force-stop are different.
  Expected behavior is the supported saved checkpoint, not exact elapsed-frame
  recovery. Upgrade decisions should return with their saved cards. A replayed
  partial interval is not automatically a defect; unexpected lost choices,
  repeated rewards or an unreadable recovery flow warrant investigation.
- Briefly observe play with sound muted and, if comfortable, large text/low effects.
  Record the exact settings and restore their preferred settings afterwards.

If time runs out or a check has no opportunity, use NOT OBSERVED/NOT RUN with the
reason. These short checks are not a thermal soak or comprehensive lifecycle QA.

### F. Private feedback — about 3 minutes

Give the participant the feedback section of SESSION_TEMPLATE.md. They can answer
in writing or aloud. Record words faithfully without defending the design. Ask
price/value last so it does not prime first impressions. Thank them regardless
of whether they enjoyed it or wanted another run.

## Record and interpret evidence

`OBSERVATIONS.csv` holds one event per row, never one row per guessed diagnosis.
Use `phase` = unprompted / assisted / guided / feedback, and `kind` = observed /
player_quote / interpretation. Link screenshots or session timestamps when
available. Don't put an interpretation into a quote field.

`FINDINGS.csv` groups events into actionable hypotheses:

- **Severity 3:** crash, data loss, blocked progression, or cannot complete a core
  action. Reproduce promptly; stop sessions on the affected build if necessary.
- **Severity 2:** recurring misunderstanding or control failure changes decisions
  or makes danger/loss hard to understand.
- **Severity 1:** friction or presentation issue that the player works around.
- **Severity 0:** preference or optional enhancement with no observed impediment.

Record frequency as affected eligible participants / eligible participants
observed, alongside build/cohort and evidence IDs. For a shield issue, eligibility
means a chance to use/see that shield behavior. “Not observed” is not “unaffected.”
Do not aggregate ten events from one player as ten affected people.

Triage severity first, then recurrence, strength of evidence and repair effort.
A single save-loss report may outrank a common cosmetic preference. State
confidence as provisional, repeated observation, or technically reproduced.
Include counterexamples and the smallest proposed change; map to P1/P2/P3 etc.
Confirm the hypothesis with a fresh participant after fixing it where possible.

## Cohort report template

Copy this section after actual sessions:

```text
Build/cohort ID:
Sessions attempted/completed; first-time participants:
Devices/settings represented; important gaps:
Unprompted goal understanding: numerator / eligible denominator + evidence
Shield understanding before help: numerator / eligible denominator + evidence
Mixer discovery before help: numerator / eligible denominator + evidence
Recognizable build explanation: numerator / eligible denominator + evidence
Loss explanation: numerator / eligible defeated participants + evidence
Spontaneous retry: numerator / participants with an unprompted opportunity
Prompted retries (reported separately):
Resume checks and actual closure methods:
Top issues: finding IDs, severity, frequency, counterexamples
Proposed next task and smallest change:
Human acceptance: PASS / FAIL / NOT RUN for each tested question; limitations
```

These small convenience samples provide qualitative direction. Do not call retry
observations “retention,” willingness to pay “sales,” or a first-mission victory
“campaign balance.” No quotas require the facilitator to create positive results.

## Kit acceptance and remaining work

- Preparation includes a runnable session procedure, build/device fields,
  feedback sheet, observation log and prioritized findings template.
- Source/UI references were inspected; document structure and links are checked
  separately from game validation in the current implementation-status entry.
- Artifact preparation/preflight: NOT RUN for this kit.
- Recruitment, participant sessions, human findings and gameplay acceptance:
  NOT RUN. Historical owner feedback is not a new unfamiliar-player cohort.
- No game behavior changed, APK installed, invitation sent or result fabricated.

P0's preparation can be used now; its human evidence remains open. The roadmap
permits P1/P2 to use existing owner feedback while sessions are being arranged.

---
description: Resume after an interrupt from specs/plans PROGRESS.md without restarting from zero
---

RESUME after interrupt in the current active agent (`swe`, `swe-build`, or `swe-plan`).

$ARGUMENTS

1. Load `interrupt-handling`.
2. Read `specs/STATUS.md`, `plans/STATUS.md`, and `plans/PROGRESS.md` (or `specs/PROGRESS.md`).
3. Report the resume point without switching agents:
   - If phase is specs/plans with a pending human gate, stay in the current planning context and do not build.
   - If phase is build and artifacts are approved, continue from `next_step` with `build-from-spec` when appropriate for the current agent.
4. Set PROGRESS to `resumed` then `running`. Do not redo completed checklist items without cause. Do not treat interrupt as approval.

---
description: Resume after an interrupt from specs/plans PROGRESS.md without restarting from zero
---

RESUME after interrupt (run in the current active agent: `swe`, `swe-build`, or `swe-plan`).

$ARGUMENTS

1. Load `interrupt-handling`.
2. Read `specs/STATUS.md`, `plans/STATUS.md`, and `plans/PROGRESS.md` (or `specs/PROGRESS.md`).
3. Report the resume point. Do **not** switch to a different primary agent. Continue in the current agent context according to the phase:
   - If phase is specs/plans with pending human gate → stay in plan/spec context and do not build.
   - If phase is build and artifacts are approved → continue from `next_step` with `build-from-spec` if appropriate for this agent, else follow phase guidance without agent switch.
4. Set PROGRESS to `resumed`/`running`. Do not redo completed checklist items without cause. Do not treat interrupt as approval.

---
description: Turn a full developer prompt into specs/ and plans/ with self-review and human approval gates (no application code)
agent: swe-plan
---

Developer prompt (full source for specs and plans):

$ARGUMENTS

Follow the Spec→Plan→Build lifecycle in **plan mode** only:

1. Explore existing repo if present (`@repo-explorer`). Do not edit application source.
2. Treat the full prompt above as the source request; extract requirements, constraints, assumptions, and open questions before drafting.
3. `@spec-writer` + `spec-authoring` → create/update `specs/` at project root.
4. `@spec-plan` validates specs, then self-review → `human-review-gate` → **STOP** for developer (`approve` | `changes:` | `reject:`).
5. Only after specs `approved`: `@plan-writer` + `plan-authoring` → create/update `plans/`.
6. `@spec-plan` validates plans against the approved specs, then self-review → `human-review-gate` → **STOP** again.
7. When plans `approved`, hand off: switch to `swe-build` and `/swe-build`. Do not implement yourself.

Honor `/swe-interrupt` semantics if asked to stop; checkpoint PROGRESS.

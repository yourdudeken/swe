---
name: incident-response
description: Investigate and coordinate production incidents with impact assessment, evidence preservation, mitigation, rollback, timeline, root cause, and follow-up actions.
license: MIT
compatibility: opencode
metadata:
  category: operations
---

# Incident response

## Procedure

1. Establish impact, affected users, start time, symptoms, and current mitigations.
2. Preserve logs, metrics, traces, deploy history, and a timestamped timeline.
3. Recommend the smallest reversible mitigation; obtain approval for production actions.
4. Separate immediate cause, root cause, and contributing factors.
5. Produce prioritized follow-up actions with owners and verification criteria.

## Expected output

Incident status, impact, timeline, evidence, mitigation, root cause, follow-up actions, and residual risk.

## Verification

Verify recovery using user-facing health signals and confirm the original failure no longer reproduces.

## Failure modes

Do not destroy evidence, make unapproved production changes, or confuse mitigation with root cause.

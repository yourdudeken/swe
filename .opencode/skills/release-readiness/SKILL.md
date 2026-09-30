---
name: release-readiness
description: Assess whether a change is ready to release, including versioning, artifacts, migrations, compatibility, rollout, rollback, deployment configuration, and release notes.
license: MIT
compatibility: opencode
metadata:
  category: operations
---

# Release readiness

## Procedure

1. Inspect the real diff, release metadata, artifacts, deployment configuration, and migration order.
2. Confirm tests and verification evidence match the risk tier.
3. Review compatibility, rollout sequencing, rollback or forward-fix, backups, and operational ownership.
4. Draft release notes from the actual change and list blockers explicitly.

## Expected output

Ready/conditional/blocked decision, evidence, blockers, rollout, rollback, release notes, and residual risk.

## Verification

Run the repository's package/build/smoke checks and confirm rollback steps are executable or clearly marked unverified.

## Failure modes

Do not deploy, claim readiness from a green unit suite alone, or hide migration and rollback uncertainty.

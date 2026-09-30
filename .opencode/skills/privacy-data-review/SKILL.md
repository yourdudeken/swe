---
name: privacy-data-review
description: Review PII and persisted-data changes for classification, minimization, access, retention, deletion, masking, export, backup, restore, and migration safety.
license: MIT
compatibility: opencode
metadata:
  category: data
---

# Privacy and data review

## Procedure

1. Classify data and map collection, use, access, retention, deletion, and export paths.
2. Check authorization, masking, encryption, logs, analytics, and data minimization.
3. Review migration ordering, backfills, downtime, backup, restore, rollback, and forward-fix.
4. Turn requirements into tests and operational checks.

## Expected output

Data inventory, privacy findings, migration/recovery plan, required controls, residual risk, and verification.

## Verification

Verify sensitive fields are protected and migration/restore procedures are tested or explicitly marked unverified.

## Failure modes

Do not infer compliance from encryption alone or approve destructive data changes without recovery evidence.

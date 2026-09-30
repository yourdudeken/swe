---
name: documentation-sync
description: Synchronize documentation with behavior changes across APIs, configuration, CLI, migrations, examples, runbooks, changelogs, and removal of stale claims.
license: MIT
compatibility: opencode
metadata:
  category: documentation
---

# Documentation sync

## Procedure

1. Compare the real diff with README, API/config references, examples, runbooks, migration notes, and changelog conventions.
2. Update only documentation required by the changed public behavior.
3. Check examples and commands remain executable or clearly labeled.
4. Remove or correct stale claims; do not document speculative behavior.

## Expected output

Documentation impact map, files updated, unresolved gaps, and verification evidence.

## Verification

Run documentation tests, link checks, example checks, or targeted command validation when available.

## Failure modes

Do not rewrite unrelated prose, duplicate implementation details, or claim documentation is complete without checking the relevant surfaces.

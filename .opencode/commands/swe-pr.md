---
description: Package current work for review, commit, or PR
agent: swe
---

Prepare this work for review/PR.

$ARGUMENTS

Current tree context:
!`git status -sb`
!`git diff --stat`

Load `pr-preparation` and `git-hygiene`. Summary and test plan must match the real diff and checks actually run. Only create commits/PRs if explicitly requested. Never force-push protected branches.
Run `bash scripts/guard-lifecycle.sh diff` and `bash scripts/guard-lifecycle.sh secrets` before reporting the change ready.

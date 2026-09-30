# Release readiness workflow

```text
Stable change set
  → git-hygiene and real diff
  → verification-loop and DoD
  → @release-engineer + release-readiness
  → compatibility, artifact, migration, rollout, rollback review
  → @security-reviewer / @data-reviewer / @observability-engineer as applicable
  → release notes from actual diff
  → human release approval
  → deploy only when explicitly requested
```

## Success criteria

- Required checks ran and evidence is recorded.
- Rollout and rollback or forward-fix are explicit.
- Migration and operational risks have owners.
- No deployment is implied by readiness review.

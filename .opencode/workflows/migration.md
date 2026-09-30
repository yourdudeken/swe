# Data migration workflow

```text
Schema or data change
  → @data-reviewer + privacy-data-review
  → database-change expand/contract design
  → classify data and compatibility window
  → backup and restore or forward-fix plan
  → migration rehearsal and targeted tests
  → deploy expand step
  → backfill with monitoring and pause strategy
  → deploy contract step only after consumers migrate
  → verify and record rollback/forward-fix evidence
```

## Hard rules

- No destructive migration without explicit approval and recoverability evidence.
- Preserve compatibility during rolling deploys.
- Treat backfills as production workloads with limits and observability.

# Incident response workflow

```text
Alert or incident report
  → @incident-responder + incident-response
  → establish impact and preserve evidence
  → timeline and current-state hypothesis
  → approved reversible mitigation or rollback
  → verify recovery through user-facing signals
  → root cause and contributing factors
  → corrective actions, owners, and post-incident review
```

## Hard rules

- Production actions require explicit authorization.
- Preserve evidence and timestamps before cleanup.
- Separate mitigation, root cause, and follow-up work.

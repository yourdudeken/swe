# Observability workflow

```text
Critical path or production behavior change
  → identify SLOs, failure modes, and owners
  → @observability-engineer + observability-review
  → inspect logs, metrics, traces, alerts, dashboards
  → check cardinality, retention, and sensitive telemetry
  → add minimum instrumentation with tests
  → verify success and failure signals
  → release-readiness review
```

## Success criteria

- Operators can identify impact and likely failure location.
- Signals are actionable, bounded, and free of secrets or unnecessary PII.
- Verification covers both success and failure paths.

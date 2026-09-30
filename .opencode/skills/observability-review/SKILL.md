---
name: observability-review
description: Review logs, metrics, traces, alerts, dashboards, SLOs, cardinality, sampling, and telemetry privacy for production-facing changes.
license: MIT
compatibility: opencode
metadata:
  category: operations
---

# Observability review

## Procedure

1. Identify critical paths, failure modes, SLOs, and operational owners.
2. Trace existing logs, metrics, traces, alerts, and correlation identifiers.
3. Check signal quality, cardinality, sampling, retention, and alert actionability.
4. Check secrets and PII cannot enter telemetry.
5. Recommend minimum instrumentation and a verification plan.

## Expected output

Critical paths, current signals, gaps, privacy risks, recommended instrumentation, and verification commands.

## Verification

Run available telemetry tests or smoke checks and verify failure paths emit actionable, non-sensitive signals.

## Failure modes

Do not recommend metrics without owners, treat logging as observability completeness, or expose sensitive payloads.

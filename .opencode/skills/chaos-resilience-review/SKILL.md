---
name: chaos-resilience-review
description: Review resilience under dependency failure, latency, retries, partial outage, restart, capacity pressure, and data recovery scenarios. Use for critical distributed or production paths.
license: MIT
compatibility: opencode
metadata:
  category: reliability
---

# Chaos and resilience review

## Procedure

1. Map dependencies, failure domains, timeouts, retries, queues, and recovery boundaries.
2. Identify likely partial failures and their user-visible invariants.
3. Check idempotency, backpressure, circuit breaking, graceful degradation, and recovery.
4. Propose the smallest safe fault-injection or game-day check.

## Expected output

Dependency map, failure scenarios, resilience gaps, mitigations, recovery objectives, and verification plan.

## Verification

Run safe local fault tests or document why the environment cannot exercise them; never inject faults into production without approval.

## Failure modes

Do not add blind retries, confuse redundancy with recovery, or claim resilience without failure evidence.

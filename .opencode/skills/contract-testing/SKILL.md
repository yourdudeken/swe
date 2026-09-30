---
name: contract-testing
description: Design and verify compatibility tests for HTTP, RPC, GraphQL, events, CLI, library, and schema contracts across producers and consumers.
license: MIT
compatibility: opencode
metadata:
  category: verification
---

# Contract testing

## Procedure

1. Identify producers, consumers, compatibility policy, and versioning rules.
2. Capture request/response, errors, headers, events, schemas, and behavioral invariants.
3. Add focused consumer/provider or golden contract tests using repository conventions.
4. Check additive, breaking, rollout, and rollback behavior.

## Expected output

Contract inventory, compatibility matrix, tests added or recommended, and verification evidence.

## Verification

Run producer and consumer contract suites; report any untested external consumers honestly.

## Failure modes

Do not validate only happy-path payloads or assume internal tests cover external consumers.

# Contract change workflow

```text
Public API, event, CLI, or library contract change
  → api-change and contract-testing
  → identify producers, consumers, and compatibility policy
  → define additive or breaking rollout
  → update contract tests and documentation
  → verify old and new clients where required
  → @code-reviewer
  → release-readiness with rollback or forward-fix
```

## Hard rules

- A small diff can still be T3 when external consumers exist.
- Do not remove fields or change errors without compatibility evidence.
- Report unknown consumers as residual risk.

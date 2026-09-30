# Threat modeling workflow

```text
Request or design
  → assign risk tier
  → map assets, actors, trust boundaries, entry points
  → @threat-modeler + threat-modeling
  → rank abuse cases and mitigations
  → convert high-risk threats into acceptance criteria
  → @architect for boundary tradeoffs when needed
  → human decision for unresolved high-risk threats
  → implementation plan and verification
```

## Hard rules

- Threat modeling precedes implementation for new trust boundaries.
- Separate evidence, assumptions, and residual risk.
- Do not mark high-risk threats accepted without explicit developer approval.

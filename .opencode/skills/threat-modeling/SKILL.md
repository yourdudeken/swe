---
name: threat-modeling
description: Model assets, trust boundaries, abuse cases, and security acceptance criteria before implementation. Use for auth, privileged operations, sensitive data, external input, or new integrations.
license: MIT
compatibility: opencode
metadata:
  category: security
---

# Threat modeling

## Procedure

1. Identify assets, actors, entry points, trust boundaries, and privileged actions.
2. Enumerate realistic abuse cases with STRIDE or an equivalent model.
3. Rank likelihood and impact; record assumptions and evidence separately.
4. Convert material threats into security acceptance criteria, mitigations, and tests.
5. Re-check the design after mitigation; unresolved high-risk threats block approval.

## Expected output

Threat model, prioritized risks, security requirements, mitigations, residual risk, and verification commands.

## Verification

Confirm every trust boundary has an abuse case review and every high-risk threat has a tested mitigation.

## Failure modes

Do not invent infrastructure, claim a threat is mitigated without code evidence, or substitute a post-change review for pre-change analysis.

---
name: accessibility-review
description: Review UI changes for keyboard access, semantics, focus, contrast, forms, screen readers, motion, responsive reflow, and inclusive interaction.
license: MIT
compatibility: opencode
metadata:
  category: quality
---

# Accessibility review

## Procedure

1. Inspect semantic structure, labels, roles, keyboard order, and focus management.
2. Check loading, error, validation, dialog, and dynamic-content announcements.
3. Check contrast, resize/reflow, reduced motion, touch targets, and text scaling.
4. Run available browser or accessibility checks and separate static from runtime evidence.

## Expected output

Ranked findings with affected paths, reproducible checks, recommended fixes, and residual gaps.

## Verification

Run the repository's accessibility/lint/browser checks when available and manually exercise keyboard-only flows.

## Failure modes

Do not claim accessibility from static markup alone or treat color-only and mouse-only interactions as acceptable.

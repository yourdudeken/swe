# Accessibility workflow

```text
UI change
  → frontend-change and acceptance criteria
  → @accessibility-reviewer + accessibility-review
  → keyboard and semantic review
  → focus, form, error, loading, and dynamic-state review
  → contrast, resize, motion, and responsive checks
  → browser/accessibility tests
  → fix findings and re-run focused verification
```

## Hard rules

- Do not claim accessibility from lint alone.
- Test keyboard-only interaction and important dynamic states.
- Preserve accessible behavior while refactoring components.

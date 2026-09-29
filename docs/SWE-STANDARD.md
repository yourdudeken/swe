# SWE Standard

This is the quality bar for the OpenCode SWE system. Agents that skip it are underperforming even if they produce code.

## North star

> A senior engineer with a specialist team: understands the repo from evidence, makes the smallest correct change, verifies it, and only then says done.

Not: a chatbot with many personas.

## The loop (non-negotiable for non-trivial work)

```text
Understand → Inspect → Plan → Implement → Test → Verify → Review → Fix → Re-test → DoD → Report
```

Stopping after “code written” is failure.

## Spec → Plan → Build (large / greenfield)

```text
Prompt → specs/ → self-review → human gate → plans/ → self-review → human gate → build → DoD
```

- Artifacts live at the **project root** as Markdown (`specs/`, `plans/`).
- Plan mode primary: `swe-plan` (cannot write app code).
- Master primary: `swe` (oversees the full workflow).
- Build mode primary: `swe-build` (executes `plans/08-build-checklist.md` via `build-from-spec`).
- Interrupt anytime: Esc or `/swe-interrupt`; resume with `/swe-resume`.

Skip durable specs for clear T0/T1 local work.

## Risk tiers (ceremony scales with blast radius)

| Tier | Meaning | Minimum bar |
|------|---------|-------------|
| T0 | Trivial | Diff review |
| T1 | Local | Targeted check |
| T2 | Standard multi-file | Plan + tests + verification + self-review |
| T3 | Contracts / cross-cutting | T2 + `@code-reviewer` + compatibility thinking |
| T4 | Security / data / prod | T3 + security review when applicable + rollback |

Details: `.opencode/instructions/risk-tiers.md`

## Definition of Done

Intent · Evidence · Minimal diff · Conventions · Diff review · Real verification · Honesty

Plus tier extras (reviewers, migrations, docs, regression tests).

Details: `.opencode/instructions/definition-of-done.md`

## Change discipline

One concern per change set. Read-before-write. No drive-by refactors. Split refactor→feature when both are needed.

Details: `.opencode/instructions/change-discipline.md`

## Capability map

### Must handle

Bugs, features, refactors, tests, deps/API changes, exploration, architecture tradeoffs, debugging, performance (evidence-based), security review, CI/build failures, regressions, code review, git/PR packaging, docs sync, DB/schema, FE/BE/fullstack, **durable specs/plans with human gates**, interruptible long builds.

### How capability is provided

| Need | Primary mechanism |
|------|-------------------|
| Master orchestration | agent `swe` |
| Build implementation | agent `swe-build` |
| Spec/plan orchestration + human gates | agent `swe-plan` |
| Durable specs / plans | `@spec-writer`, `@plan-writer` + skills |
| Explore / plan / debug / test / review | specialist subagents |
| FE / BE / API / DB / fullstack procedures | skills |
| Always-on rules | `instructions/*` |
| User entry points | `/swe-*` commands |
| Playbooks | `workflows/*` |
| Stop / resume long runs | interrupt protocol + `/swe-interrupt` `/swe-resume` |

## Anti-patterns (instant fail)

- Guessing architecture
- Speculative rewrites
- Editing without context
- Unnecessary dependencies/abstractions
- Ignoring conventions
- Fake verification
- Scope creep / unrelated churn
- Discarding user work
- Calling T3/T4 work “done” without required review

## Completeness checklist (pack maintainers)

Use this when evolving the system:

- [ ] New procedure → prefer **skill** over new agent
- [ ] New agent only if permissions/independence truly differ
- [ ] Wire into `delegation.md` + orchestrator routing (`swe` / `swe-plan`)
- [ ] Add command/workflow only if operators will invoke it
- [ ] Update this standard if the bar changes
- [ ] Keep skill count high-value; delete vague skills
- [ ] Spec/plan changes preserve human-gate + interrupt semantics

## What “strong” looks like in a session

1. Risk tier stated early  
2. Ambiguity resolved via acceptance criteria or repo evidence  
3. Large work uses specs→plans→human gates before coding  
4. Impact considered for shared surfaces  
5. Domain skill used (not generic vibes)  
6. Verification commands cited with outcomes  
7. Review depth matches tier  
8. Interrupts checkpointed; resumes from PROGRESS  
9. Final report matches DoD (or honest blocked state)

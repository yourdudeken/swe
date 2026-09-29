# Architecture

## Goal

Maximize real SWE performance: correctness, repository understanding, minimal changes, and verification — using OpenCode’s native **primary agents**, **subagents** (`task` / `@` mention), and **skills** (`skill` tool).

## Hierarchy

```text
        ┌──────────────────────┐     ┌──────────────────────┐
        │  swe-plan (primary)  │     │  swe (primary)       │
        │  specs → plans gates │────▶│  master oversight     │
        └──────────┬───────────┘     └──────────┬───────────┘
                   │                            │
     ┌─────────────┼─────────────┐              │
     ▼             ▼             ▼              ▼
spec-writer   plan-writer   repo-explorer   (full specialist set)
     │             │                            │
     └─────────────┴────────────────────────────┘
                         │ delegates
                         ▼
              ┌──────────────────────────────┐
              │  swe-build (primary)         │
              │  implementation + verification│
              └──────────────┬───────────────┘
                             │
                         Skills (on demand)
```

## Modes

| Mode | Primary | Writes |
|------|---------|--------|
| Plan | `swe-plan` | `specs/**`, `plans/**` only |
| Oversight | `swe` | Coordinates all work and owns final DoD/report |
| Build | `swe-build` | Application source + tests; consumes approved artifacts |

## Why these agents (not dozens)

OpenCode subagents cost context and latency. This pack keeps **strong orchestrators** and **specialists only where expertise or independence matters** (especially review/security, and durable spec/plan authorship with narrow write permissions).

| Agent | Why separate |
|-------|----------------|
| `spec-writer` | Product/requirements craft; write-scoped to `specs/` |
| `plan-writer` | Executable build runbooks; write-scoped to `plans/`; reviewed by `@spec-plan` |
| `spec-plan` | Read-only correctness and traceability validation between specs and plans |

Git, dependency, and documentation remain separate because their failure modes are distinct (data loss, lockfile breakage, doc drift).

## Spec → Plan → Build

Protocol: `.opencode/instructions/spec-plan-build.md`  
Workflow: `.opencode/workflows/spec-plan-build.md`

Human gates are mandatory between phases. Agents never self-approve.

## Interrupt

Protocol: `.opencode/instructions/interrupt.md`  
Skill: `interrupt-handling`  
Commands: `/swe-interrupt`, `/swe-resume`  
TUI: Esc (`session_interrupt`)

## Skills vs agents

| Construct | Role |
|-----------|------|
| **Agent** | Permission boundary + persona + when-to-invoke description for Task/`@` |
| **Skill** | Procedural playbook loaded on demand (composable, shorter, reusable across agents) |

Agents **load skills** instead of duplicating procedures. Example: `debugger` loads `failure-reproduction` → `root-cause-analysis` → `verification-loop`.

## Coordination protocol

Specialists return:

```text
STATUS / FINDINGS / EVIDENCE / RECOMMENDATION / RISKS / FILES / VERIFICATION
```

Orchestrators treat this as **evidence**. Critical claims are re-checked before user-facing success claims.

## Context management

Orchestrators maintain the task-state block defined in `swe-protocol.md`. Rules:

- Track files, hypotheses, failures, verification, specs/plans STATUS
- Avoid re-reading understood files unless editing or contradicted
- Summarize large files; keep only critical excerpts
- Re-read immediately before edit

## Delegation policy (summary)

**Direct:** trivial, local, clear cause.  
**Delegate:** large explore, specs/plans drafting, deep debug, independent review, security/perf/architecture, messy git, dependency migrations.

Full matrix: `.opencode/instructions/delegation.md`.

## Verification policy

Hierarchy: syntax → types → lint → unit → integration → e2e → build → **diff review**.  
Run the relevant slice; report honestly. Details: `.opencode/instructions/verification.md`.

## Quality gates

- **Risk tiers T0–T4** scale planning/review (`risk-tiers.md`).
- **Definition of Done** blocks undeserved success (`definition-of-done.md`).
- **Change discipline** keeps diffs surgical (`change-discipline.md`).
- **Human gates** on durable specs/plans (`spec-plan-build.md`).
- Canonical narrative: `docs/SWE-STANDARD.md`.

## Error recovery

1. Read the exact error  
2. Env vs code classification  
3. One retry max if transient; then change strategy  
4. Loop: diagnose → fix → targeted re-test → broaden  
5. Surface blockers instead of inventing success  
6. On interrupt: checkpoint PROGRESS; resume without restarting from zero  

## Engineering loops

Canonical loop:

```text
Understand → Inspect → Plan → Implement → Test → Verify → Review → Fix → Re-test → Report
```

Project lifecycle loop:

```text
Prompt → Specs → Self-review → Human → Plans → Self-review → Human → Build → Verify → DoD
```

Playbooks: `.opencode/workflows/*.md`.

## Extending

1. **New skill** — `.opencode/skills/<name>/SKILL.md` with required frontmatter; keep procedure operational.  
2. **New specialist** — `.opencode/agents/<name>.md` with `mode: subagent`, tight permissions, skill allowlist.  
3. **Wire into orchestrators** — add a row to delegation instructions and optionally a slash command.  

Prefer improving a skill over adding another agent.

For practical command examples and the project layout, see [Usage](USAGE.md).

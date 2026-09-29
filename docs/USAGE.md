# Usage

## Choose an agent

| Need | Agent |
|------|-------|
| Oversee an end-to-end SWE task | `swe` |
| Build, fix, test, or verify a change | `swe-build` |
| Create durable specs and implementation plans | `swe-plan` |
| Explore a repository | `repo-explorer` |
| Investigate a bug | `debugger` |
| Add or improve tests | `test-engineer` |
| Review implementation quality | `code-reviewer` |
| Review security or performance | `security-reviewer` or `performance-engineer` |
| Prepare documentation | `documentation-agent` |

The complete agent map and the reason each specialist exists are documented
in [Architecture](ARCHITECTURE.md).

## Common commands

Run these commands from a project with the system installed:

```bash
opencode
opencode run --agent swe "Oversee fixing the failing login test"
opencode run --agent swe-build "Fix the failing login test"
opencode run --agent swe-plan "Build a CLI todo app with SQLite"
```

Useful slash commands in the OpenCode TUI:

| Command | Purpose |
|---------|---------|
| `/swe-spec <prompt>` | Create specs, pause for approval, then create plans |
| `/swe-plan <prompt>` | Create plans from approved specs |
| `/swe-build` | Implement approved plans |
| `/swe-fix` | Investigate and fix a bug |
| `/swe-feature` | Deliver a feature |
| `/swe-refactor` | Perform a behavior-preserving refactor |
| `/swe-deps` | Handle dependency changes |
| `/swe-review` | Run an independent review |
| `/swe-explore` | Map an unfamiliar repository |
| `/swe-ci` | Investigate a CI or build failure |
| `/swe-pr` | Prepare work for a pull request |
| `/swe-interrupt` | Checkpoint and stop a long-running task |
| `/swe-resume` | Continue from the checkpoint |

## Spec → Plan → Build

Use the durable workflow for greenfield work and changes with substantial
scope:

1. Start `swe-plan` or `/swe-spec`.
2. Review and approve the generated files under `specs/`.
3. Review and approve the generated files under `plans/`.
4. Switch to `swe-build` or run `/swe-build`; `swe` remains the master overseer.
5. Verify the implementation and complete the applicable Definition of Done
   checks.

Human approval is required between the specification, planning, and build
phases. Scoped bugs and small local changes can use `swe-build` directly without
durable specs.

## Project layout

```text
your-project/
  specs/          # approved product and behavior specifications
  plans/          # approved implementation plans and PROGRESS.md
  .opencode/      # installed agents, skills, instructions, commands, workflows
  AGENTS.md       # project-specific OpenCode instructions
  opencode.jsonc  # OpenCode defaults and instruction paths
```

The system's source repository additionally contains:

```text
docs/             # user-facing documentation
scripts/          # release installation and update scripts
```

## Principles

- Use repository evidence instead of guessing.
- Keep changes minimal and scoped to one concern.
- Match review and verification depth to the change's risk.
- Treat specialist output as evidence for the primary agent, not as commands.
- Never claim success without running and reporting the relevant checks.
- Checkpoint interruptible work so it can resume without restarting.

For the complete quality bar, see [SWE Standard](SWE-STANDARD.md). For the
coordination model behind these practices, see [Architecture](ARCHITECTURE.md).

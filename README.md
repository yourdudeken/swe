# OpenCode SWE Multi-Agent System

A production-oriented agent and skills architecture for
[OpenCode](https://opencode.ai). It provides a senior-engineer-style primary
agent, focused specialists, reusable skills, and verification-oriented
workflows.

## Highlights

- `swe` — default master agent overseeing the full SWE workflow.
- `swe-plan` — spec and plan authoring with human approval gates.
- `swe-build` — implementation, testing, and verification agent.
- Specialist agents for exploration, debugging, testing, architecture, review,
  security, threat modeling, accessibility, data privacy, observability,
  release readiness, incident response, performance, dependencies, Git, and
  documentation.
- Safety controls for destructive commands, lifecycle approvals, secret checks,
  diff checks, and scoped agent permissions.
- Reusable skills, protocols, slash commands, and workflows for consistent
  delivery.

## Requirements

- [OpenCode](https://opencode.ai) 1.0 or newer
- A configured model provider (`opencode providers`)

## Install

Install the latest release into the current project:

```bash
curl -fsSL https://raw.githubusercontent.com/yourdudeken/swe/main/scripts/install.sh | bash
```

For manual, global, or drop-in installation, see
[Installation](docs/INSTALL.md).

## Quick start

```bash
cd /path/to/your/project
opencode
```

Use `swe` for end-to-end orchestration. For implementation work, it routes to
`swe-build`. For greenfield or larger changes, switch to `swe-plan` (or run
`opencode run --agent swe-plan "your prompt"`) to create reviewable specs and
plans before building.

See [Usage](docs/USAGE.md) for the command reference, workflow, and project
layout.

Validate the installed system and run its local guards with:

```bash
bash scripts/validate.sh
bash scripts/guard-lifecycle.sh diff
bash scripts/guard-lifecycle.sh secrets
```

Use `/swe-threat-model`, `/swe-release`, `/swe-incident`, `/swe-ops-review`,
`/swe-accessibility`, and `/swe-contract` for production-facing quality gates.

## Documentation

- [Usage](docs/USAGE.md) — agents, commands, workflow, and layout
- [Installation](docs/INSTALL.md) — project, global, and drop-in installs
- [Architecture](docs/ARCHITECTURE.md) — coordination and extension model
- [SWE Standard](docs/SWE-STANDARD.md) — quality bar and Definition of Done

## License

MIT — adapt freely for your team.

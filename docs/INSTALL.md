# Installation

## Prerequisites

1. Install OpenCode: https://opencode.ai/docs/
2. Configure a provider: `opencode providers`
3. Confirm CLI works: `opencode --version` (this pack targets the markdown agent + `SKILL.md` format used by current OpenCode releases)

## Project install (recommended)

Install the latest release directly into the current project:

```bash
curl -fsSL https://raw.githubusercontent.com/yourdudeken/swe/main/scripts/install.sh | bash
```

Update an existing installation:

```bash
curl -fsSL https://raw.githubusercontent.com/yourdudeken/swe/main/scripts/update.sh | bash
```

Remove the pack from the current project:

```bash
curl -fsSL https://raw.githubusercontent.com/yourdudeken/swe/main/scripts/uninstall.sh | bash
```

Both install/update commands operate on the current directory by default. They download the
latest release archive and manage only `opencode.json`, `opencode.jsonc`, `AGENTS.md`,
and `.opencode/`; all other files in the project are preserved. If `opencode.json`
already exists, the installer updates it in place by adding the pack's default agent,
instructions, permissions, and built-in agent descriptions without replacing existing
settings. Existing `opencode.jsonc` and `AGENTS.md` files are never overwritten;
for JSONC configs, the pack config is saved as `opencode.swe.jsonc` for manual merging.
Existing
`.opencode/` files are preserved and pack files are updated in place. Set
`OPENCODE_SWE_TARGET=/path/to/project` to select another target directory.

From this repository:

```bash
TARGET=/path/to/your/application

cp opencode.jsonc "$TARGET/"
cp AGENTS.md "$TARGET/"
cp -a .opencode "$TARGET/"
```

If `$TARGET` already has `opencode.json` / `opencode.jsonc`, **merge** rather than overwrite:

- Set `"default_agent": "swe"`
- Append all `.opencode/instructions/*.md` paths to `instructions` (protocol, delegation, verification, definition-of-done, risk-tiers, change-discipline, spec-plan-build, interrupt)
- Keep any existing provider/model settings

Commands are canonical in `.opencode/commands/` and are discovered from there;
do not duplicate command definitions in `opencode.jsonc`. The repository's
`scripts/validate.sh` and `scripts/guard-lifecycle.sh` are maintainer/CI checks
and are not included in release installs.

Then:

```bash
cd "$TARGET"
opencode
```

## Global install

```bash
mkdir -p ~/.config/opencode/{agents,skills,commands}

cp .opencode/agents/*.md ~/.config/opencode/agents/
cp -a .opencode/skills/* ~/.config/opencode/skills/
cp .opencode/commands/*.md ~/.config/opencode/commands/
```

Add to `~/.config/opencode/opencode.jsonc`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "default_agent": "swe",
  "instructions": [
    // Use absolute paths or copy instructions into ~/.config/opencode/instructions/
    "/absolute/path/to/swe/.opencode/instructions/swe-protocol.md",
    "/absolute/path/to/swe/.opencode/instructions/delegation.md",
    "/absolute/path/to/swe/.opencode/instructions/verification.md",
    "/absolute/path/to/swe/.opencode/instructions/definition-of-done.md",
    "/absolute/path/to/swe/.opencode/instructions/risk-tiers.md",
    "/absolute/path/to/swe/.opencode/instructions/change-discipline.md",
    "/absolute/path/to/swe/.opencode/instructions/spec-plan-build.md",
    "/absolute/path/to/swe/.opencode/instructions/interrupt.md"
  ]
}
```

Prefer copying `instructions/` into `~/.config/opencode/instructions/` so paths stay stable.

## Verify discovery

```bash
opencode run --agent swe "Report the available SWE workflow entry points."
```

You should see primaries `swe`, `swe-build`, and `swe-plan`, plus specialists
including `spec-writer`, `plan-writer`, `debugger`, `code-reviewer`,
`threat-modeler`, `release-engineer`, `incident-responder`,
`observability-engineer`, `data-reviewer`, and `accessibility-reviewer`.

In a session, skills appear via the `skill` tool (`repository-mapping`, `verification-loop`, …). Slash commands appear as `/swe-fix`, `/swe-feature`, `/swe-release`, and `/swe-threat-model`.

When contributing to this repository, validate definitions with
`bash scripts/validate.sh` and run `bash scripts/guard-lifecycle.sh diff` before
reporting a change complete. These scripts are not required in installed projects.

## Using alongside built-in agents

| Goal | Agent |
|------|-------|
| SWE master orchestration (default) | `swe` |
| SWE build / fix / verify | `swe-build` |
| Specs + plans + human gates | `swe-plan` |
| Stock OpenCode builder | `build` (Tab to switch) |
| Stock read-only plan | `plan` (prefer `swe-plan` for durable specs/plans) |
| Quick stock explore | built-in `explore` or `@repo-explorer` |

### Spec → Plan → Build quick path

```bash
# In TUI: Tab to swe-plan, or:
opencode run --agent swe-plan "Your product prompt — produce specs for review"

# After you approve specs and plans:
opencode run --agent swe-build "/swe-build"
```

Interrupt mid-run with **Esc**, or `/swe-interrupt` then later `/swe-resume`.

For the command reference and the complete Spec → Plan → Build workflow, see
[Usage](USAGE.md).

## Model tips

Pin stronger models on `swe`, `swe-build`, `swe-plan`, `debugger`, and `code-reviewer` if desired — in each agent markdown frontmatter:

```yaml
model: anthropic/claude-sonnet-4-20250514
```

Or override in `opencode.jsonc` under `agent.<name>.model`.

## Uninstall

Remove the copied `.opencode/agents/swe.md`, `.opencode/agents/swe-build.md` (and other agents you added), skills, commands, and revert `default_agent`.

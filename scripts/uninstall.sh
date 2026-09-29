#!/usr/bin/env bash
set -euo pipefail

readonly target="${OPENCODE_SWE_TARGET:-$PWD}"

usage() {
  cat <<'EOF'
Usage: uninstall.sh [--help]

Remove the project-scoped OpenCode SWE pack from the current directory (or
OPENCODE_SWE_TARGET). This removes the installed .opencode files, strips the
pack config from opencode.jsonc/opencode.json, and deletes AGENTS.md if it was
added by this pack.
EOF
}

if [[ $# -gt 0 ]]; then
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
fi

if [[ ! -d "$target" ]]; then
  printf 'Target directory does not exist: %s\n' "$target" >&2
  exit 1
fi

pack_marker=0
for candidate in \
  "$target/.opencode/agents/swe.md" \
  "$target/.opencode/agents/swe-build.md" \
  "$target/.opencode/commands/swe-fix.md" \
  "$target/.opencode/instructions/swe-protocol.md"; do
  if [[ -e "$candidate" ]]; then
    pack_marker=1
    break
  fi
done

if (( pack_marker == 1 )); then
  rm -rf "$target/.opencode"
  printf 'Removed %s\n' "$target/.opencode"
fi

if [[ -f "$target/AGENTS.md" ]] && grep -Eq 'OpenCode SWE|swe-build|swe-plan|@repo-explorer' "$target/AGENTS.md" >/dev/null 2>&1; then
  rm -f "$target/AGENTS.md"
  printf 'Removed %s\n' "$target/AGENTS.md"
fi

if [[ -f "$target/opencode.swe.jsonc" ]]; then
  rm -f "$target/opencode.swe.jsonc"
  printf 'Removed %s\n' "$target/opencode.swe.jsonc"
fi

config_path=""
if [[ -f "$target/opencode.jsonc" ]]; then
  config_path="$target/opencode.jsonc"
elif [[ -f "$target/opencode.json" ]]; then
  config_path="$target/opencode.json"
fi

if [[ -n "$config_path" ]]; then
  python_bin=""
  if command -v python3 >/dev/null 2>&1; then
    python_bin="python3"
  elif command -v python >/dev/null 2>&1; then
    python_bin="python"
  else
    printf 'python3 is required to clean project OpenCode config.\n' >&2
    exit 1
  fi

  "$python_bin" - "$config_path" <<'PY'
import json
import pathlib
import sys


def strip_jsonc_comments(text: str) -> str:
    result = []
    in_string = False
    escape = False
    i = 0
    while i < len(text):
        ch = text[i]
        if in_string:
            result.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
            result.append(ch)
            i += 1
            continue

        if ch == "/" and i + 1 < len(text):
            nxt = text[i + 1]
            if nxt == "/":
                i += 2
                while i < len(text) and text[i] not in "\r\n":
                    i += 1
                continue
            if nxt == "*":
                i += 2
                while i + 1 < len(text) and not (text[i] == "*" and text[i + 1] == "/"):
                    i += 1
                i += 2 if i + 1 < len(text) else 1
                continue

        result.append(ch)
        i += 1

    return "".join(result)


path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
text = strip_jsonc_comments(text)
obj = json.loads(text)

if not isinstance(obj, dict):
    raise SystemExit(f"Config file is not a JSON object: {path}")

for key in ("default_agent",):
    obj.pop(key, None)

instructions = obj.get("instructions")
if isinstance(instructions, list):
    obj["instructions"] = [
        item
        for item in instructions
        if not (
            isinstance(item, str)
            and item.startswith(".opencode/instructions/")
            and any(item.endswith(f"{name}.md") for name in (
                "swe-protocol",
                "delegation",
                "verification",
                "definition-of-done",
                "risk-tiers",
                "change-discipline",
                "spec-plan-build",
                "interrupt",
            ))
        )
    ]

commands = obj.get("command")
if isinstance(commands, dict):
    for name in list(commands):
        if name.startswith("swe-") or name in {"swe", "swe-build", "swe-plan"}:
            del commands[name]

if not obj.get("instructions"):
    obj.pop("instructions", None)
if not obj.get("command"):
    obj.pop("command", None)

path.write_text(json.dumps(obj, indent=2) + "\n", encoding="utf-8")
print(f"Updated {path}")
PY
fi

printf 'Uninstalled OpenCode SWE from %s.\n' "$target"

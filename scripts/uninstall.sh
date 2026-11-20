#!/usr/bin/env bash
set -euo pipefail

readonly target="${OPENCODE_SWE_TARGET:-$PWD}"

usage() {
  cat <<'EOF'
Usage: uninstall.sh [--help]

Remove the project-scoped OpenCode SWE pack from the current directory (or
OPENCODE_SWE_TARGET). This removes the installed .opencode files, strips the
pack config from opencode.jsonc/opencode.json, and deletes AGENTS.md only when
it was added by this pack. Project-owned files are left untouched.
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

manifest="$target/.opencode/.swe-installed-files"
if (( pack_marker == 1 )); then
  if [[ -f "$manifest" ]]; then
    # Delete only the paths the installer recorded; leave custom project files.
    while IFS= read -r rel; do
      if [[ -n "$rel" && "$rel" != ".opencode/.swe-installed-files" ]]; then
        rm -f "$target/$rel"
      fi
    done < "$manifest"
    rm -f "$manifest"
    find "$target/.opencode" -depth -type d -empty -delete 2>/dev/null || true
    printf 'Removed pack files from %s\n' "$target/.opencode"
  else
    printf 'No pack manifest found; kept %s to avoid deleting project files.\n' "$target/.opencode" >&2
    printf 'Remove the SWE agent/command/skill files manually if needed.\n' >&2
  fi
fi

# Only remove the AGENTS.md this pack copied. A project-owned AGENTS.md may
# mention SWE agents, so match the pack's exact heading rather than keywords.
if [[ -f "$target/AGENTS.md" ]] &&
  [[ "$(head -n 1 "$target/AGENTS.md" | tr -d '\r')" == '# OpenCode SWE System' ]]; then
  rm -f "$target/AGENTS.md"
  printf 'Removed %s\n' "$target/AGENTS.md"
fi

# Legacy merge helper. It may contain manual edits, so never delete it here.
if [[ -f "$target/opencode.swe.jsonc" ]]; then
  printf 'Kept %s (may contain manual edits); remove it manually if no longer needed.\n' "$target/opencode.swe.jsonc" >&2
fi

python_bin=""
find_python() {
  if command -v python3 >/dev/null 2>&1; then
    python_bin="python3"
  elif command -v python >/dev/null 2>&1; then
    python_bin="python"
  else
    return 1
  fi
}

config_paths=()
for candidate in "$target/opencode.jsonc" "$target/opencode.json"; do
  if [[ -f "$candidate" ]]; then
    config_paths+=("$candidate")
  fi
done

if (( ${#config_paths[@]} > 0 )); then
  find_python || {
    printf 'python3 is required to clean project OpenCode config.\n' >&2
    exit 1
  }
  for config_path in "${config_paths[@]}"; do
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


def strip_trailing_commas(text: str) -> str:
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
        if ch == ",":
            j = i + 1
            while j < len(text) and text[j] in " \t\r\n":
                j += 1
            if j < len(text) and text[j] in "}]":
                i += 1
                continue
        result.append(ch)
        i += 1
    return "".join(result)


path = pathlib.Path(sys.argv[1])
text = strip_trailing_commas(strip_jsonc_comments(path.read_text(encoding="utf-8")))
try:
    obj = json.loads(text)
except json.JSONDecodeError as exc:
    raise SystemExit(f"Cannot parse OpenCode config {path}: {exc}") from exc
if not isinstance(obj, dict):
    raise SystemExit(f"Config file is not a JSON object: {path}")
original = json.loads(json.dumps(obj))

if obj.get("default_agent") == "swe":
    obj.pop("default_agent")

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
    if not obj["instructions"]:
        obj.pop("instructions")

commands = obj.get("command")
if isinstance(commands, dict):
    for name in list(commands):
        if name.startswith("swe-") or name in {"swe", "swe-build", "swe-plan"}:
            del commands[name]
    if not commands:
        obj.pop("command")

agents = obj.get("agent")
if isinstance(agents, dict):
    for name in ("build", "plan"):
        settings = agents.get(name)
        if (
            isinstance(settings, dict)
            and isinstance(settings.get("description"), str)
            and "Prefer swe" in settings["description"]
        ):
            settings.pop("description")
            if not settings:
                agents.pop(name)
    if not agents:
        obj.pop("agent")

if obj == original:
    print(f"OpenCode config has no pack settings: {path}")
else:
    path.write_text(json.dumps(obj, indent=2) + "\n", encoding="utf-8")
    print(f"Removed pack settings from {path}")
PY
  done
fi

printf 'Uninstalled OpenCode SWE from %s.\n' "$target"

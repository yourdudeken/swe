#!/usr/bin/env bash
set -euo pipefail

readonly repository="${OPENCODE_SWE_REPOSITORY:-yourdudeken/swe}"
readonly release_url="https://github.com/${repository}/releases/latest/download/opencode-swe.tar.gz"
readonly target="${OPENCODE_SWE_TARGET:-$PWD}"

if [[ ! -d "$target" ]]; then
  printf 'Target directory does not exist: %s\n' "$target" >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  printf 'curl is required to install OpenCode SWE.\n' >&2
  exit 1
fi

temporary_directory="$(mktemp -d)"
cleanup() {
  rm -rf "$temporary_directory"
}
trap cleanup EXIT

archive="$temporary_directory/opencode-swe.tar.gz"
curl --fail --location --silent --show-error "$release_url" --output "$archive"
tar -xzf "$archive" -C "$temporary_directory"

for required_path in opencode.jsonc AGENTS.md .opencode; do
  if [[ ! -e "$temporary_directory/$required_path" ]]; then
    printf 'Release archive is missing %s\n' "$required_path" >&2
    exit 1
  fi
done

if [[ -f "$target/opencode.json" ]]; then
  python_bin=""
  if command -v python3 >/dev/null 2>&1; then
    python_bin="python3"
  elif command -v python >/dev/null 2>&1; then
    python_bin="python"
  else
    printf 'python3 is required to update an existing opencode.json.\n' >&2
    exit 1
  fi

  "$python_bin" - "$target/opencode.json" "$temporary_directory/opencode.jsonc" <<'PY'
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
            if text[i + 1] == "/":
                i += 2
                while i < len(text) and text[i] not in "\r\n":
                    i += 1
                continue
            if text[i + 1] == "*":
                i += 2
                while i + 1 < len(text) and text[i:i + 2] != "*/":
                    i += 1
                i += 2
                continue
        result.append(ch)
        i += 1
    return "".join(result)


def load_jsonc(path: pathlib.Path) -> dict:
    value = json.loads(strip_jsonc_comments(path.read_text(encoding="utf-8")))
    if not isinstance(value, dict):
        raise SystemExit(f"Config file is not a JSON object: {path}")
    return value


def merge_defaults(target: dict, defaults: dict) -> None:
    for name, value in defaults.items():
        if name not in target:
            target[name] = value
        elif isinstance(target[name], dict) and isinstance(value, dict):
            merge_defaults(target[name], value)


target_path = pathlib.Path(sys.argv[1])
pack_path = pathlib.Path(sys.argv[2])
target = load_jsonc(target_path)
pack = load_jsonc(pack_path)

target["default_agent"] = pack["default_agent"]
instructions = target.get("instructions", [])
if not isinstance(instructions, list) or not all(
    isinstance(item, str) for item in instructions
):
    raise SystemExit(f"Config key 'instructions' must be a list of strings: {target_path}")
target["instructions"] = list(dict.fromkeys([*instructions, *pack["instructions"]]))
for key in ("permission", "agent"):
    target.setdefault(key, {})
    if not isinstance(target[key], dict):
        raise SystemExit(f"Config key '{key}' must be an object: {target_path}")
    merge_defaults(target[key], pack[key])

target_path.write_text(json.dumps(target, indent=2) + "\n", encoding="utf-8")
PY
  printf 'Updated existing OpenCode config in %s.\n' "$target/opencode.json"
elif [[ -f "$target/opencode.jsonc" ]]; then
  printf 'Preserving existing OpenCode config in %s.\n' "$target" >&2
  cp "$temporary_directory/opencode.jsonc" "$target/opencode.swe.jsonc"
  printf 'Merge the pack settings from %s/opencode.swe.jsonc manually.\n' "$target" >&2
else
  cp "$temporary_directory/opencode.jsonc" "$target/opencode.jsonc"
fi

if [[ -e "$target/AGENTS.md" ]]; then
  printf 'Preserving existing AGENTS.md in %s.\n' "$target" >&2
else
  cp "$temporary_directory/AGENTS.md" "$target/AGENTS.md"
fi

mkdir -p "$target/.opencode"
cp -a "$temporary_directory/.opencode/." "$target/.opencode/"

printf 'Installed the latest OpenCode SWE release in %s.\n' "$target"

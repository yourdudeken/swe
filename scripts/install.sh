#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: install.sh [--update] [--help]

Install or update the OpenCode SWE pack in the current project (or
OPENCODE_SWE_TARGET). Existing OpenCode configs are merged in place; no
separate merge file is created. Set OPENCODE_SWE_ARCHIVE to install from a
local release tarball instead of downloading.
EOF
}

case "${1-}" in
  -h|--help)
    usage
    exit 0
    ;;
  --update)
    update_mode=1
    shift
    ;;
  "")
    update_mode=0
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac

if [[ $# -gt 0 ]]; then
  usage >&2
  exit 1
fi

readonly repository="${OPENCODE_SWE_REPOSITORY:-yourdudeken/swe}"
readonly release_url="https://github.com/${repository}/releases/latest/download/opencode-swe.tar.gz"
readonly target="${OPENCODE_SWE_TARGET:-$PWD}"

if [[ ! -d "$target" ]]; then
  printf 'Target directory does not exist: %s\n' "$target" >&2
  exit 1
fi

temporary_directory="$(mktemp -d)"
cleanup() {
  rm -rf "$temporary_directory"
}
trap cleanup EXIT

archive="$temporary_directory/opencode-swe.tar.gz"
if [[ -n "${OPENCODE_SWE_ARCHIVE:-}" ]]; then
  if [[ ! -f "$OPENCODE_SWE_ARCHIVE" ]]; then
    printf 'Archive does not exist: %s\n' "$OPENCODE_SWE_ARCHIVE" >&2
    exit 1
  fi
  cp "$OPENCODE_SWE_ARCHIVE" "$archive"
else
  if ! command -v curl >/dev/null 2>&1; then
    printf 'curl is required to install OpenCode SWE.\n' >&2
    exit 1
  fi
  curl --fail --location --silent --show-error "$release_url" --output "$archive"
fi
tar -xzf "$archive" -C "$temporary_directory"

for required_path in opencode.jsonc AGENTS.md .opencode; do
  if [[ ! -e "$temporary_directory/$required_path" ]]; then
    printf 'Release archive is missing %s\n' "$required_path" >&2
    exit 1
  fi
done

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

config_path=""
if [[ -f "$target/opencode.json" ]]; then
  config_path="$target/opencode.json"
elif [[ -f "$target/opencode.jsonc" ]]; then
  config_path="$target/opencode.jsonc"
fi

if [[ -n "$config_path" ]]; then
  find_python || {
    printf 'python3 is required to update an existing OpenCode config.\n' >&2
    exit 1
  }
  "$python_bin" - "$config_path" "$temporary_directory/opencode.jsonc" <<'PY'
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


def load_config(path: pathlib.Path) -> dict:
    text = strip_trailing_commas(strip_jsonc_comments(path.read_text(encoding="utf-8")))
    try:
        value = json.loads(text)
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Cannot parse OpenCode config {path}: {exc}") from exc
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
target = load_config(target_path)
pack = load_config(pack_path)
original = json.loads(json.dumps(target))

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

if target == original:
    print(f"OpenCode config already current: {target_path}")
else:
    target_path.write_text(json.dumps(target, indent=2) + "\n", encoding="utf-8")
    print(f"Updated OpenCode config in place: {target_path}")
PY
else
  cp "$temporary_directory/opencode.jsonc" "$target/opencode.jsonc"
  printf 'Installed OpenCode config at %s/opencode.jsonc.\n' "$target"
fi

# Older updates left a copy here for manual merging. Remove it only when it is
# still the untouched pack copy; never delete a file the project may have edited.
if [[ -f "$target/opencode.swe.jsonc" ]]; then
  if cmp -s "$target/opencode.swe.jsonc" "$temporary_directory/opencode.jsonc"; then
    rm -f "$target/opencode.swe.jsonc"
    printf 'Removed legacy opencode.swe.jsonc; settings were merged in place.\n'
  else
    printf 'Legacy opencode.swe.jsonc kept because it was edited; settings are now merged in place.\n' >&2
  fi
fi

if [[ -e "$target/AGENTS.md" ]]; then
  # Older installs copied a paragraph pointing at maintainer-only scripts that
  # are not part of the release. Drop just that paragraph; keep user content.
  if find_python; then
    "$python_bin" - "$target/AGENTS.md" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
pattern = re.compile(
    r"^[ \t]*Use `bash scripts/validate\.sh`[^\n]*\r?\n"
    r"[ \t]*`bash scripts/guard-lifecycle\.sh`[^\n]*\r?\n"
    r"[ \t]*\r?\n?",
    re.MULTILINE,
)
updated = pattern.sub("", text)
if updated != text:
    path.write_text(updated, encoding="utf-8")
    print(f"Removed maintainer-only script references from {path}")
PY
  else
    printf 'python3 unavailable; kept existing AGENTS.md as-is.\n' >&2
  fi
  printf 'Preserved existing AGENTS.md in %s.\n' "$target" >&2
else
  cp "$temporary_directory/AGENTS.md" "$target/AGENTS.md"
fi

mkdir -p "$target/.opencode"
cp -a "$temporary_directory/.opencode/." "$target/.opencode/"
# Record exactly what this pack installed so uninstall never deletes project files.
(cd "$temporary_directory" && find .opencode -type f -print | LC_ALL=C sort) \
  > "$target/.opencode/.swe-installed-files"

if (( update_mode == 1 )); then
  printf 'Updated the OpenCode SWE release in %s.\n' "$target"
else
  printf 'Installed the latest OpenCode SWE release in %s.\n' "$target"
fi

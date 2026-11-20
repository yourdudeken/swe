#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# Build the same archive shape the release workflow publishes.
release_dir="$work/release"
mkdir -p "$release_dir"
cp opencode.jsonc AGENTS.md "$release_dir/"
cp -a .opencode "$release_dir/"
tar -czf "$work/opencode-swe.tar.gz" -C "$release_dir" .
export OPENCODE_SWE_ARCHIVE="$work/opencode-swe.tar.gz"

failures=0
fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}
ok() {
  printf 'ok: %s\n' "$1"
}
assert_file() {
  [[ -f "$1" ]] || fail "expected file: $1"
}
assert_no_file() {
  [[ ! -e "$1" ]] || fail "unexpected path: $1"
}
assert_contains() {
  grep -qF "$2" "$1" || fail "expected '$2' in $1"
}
assert_not_contains() {
  ! grep -qF "$2" "$1" || fail "unexpected '$2' in $1"
}
assert_valid_json() {
  python3 -c 'import json, sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$1" \
    || fail "invalid JSON: $1"
}

# Fresh install: config shipped verbatim, no maintainer scripts, manifest recorded.
t1="$work/fresh"
mkdir -p "$t1"
OPENCODE_SWE_TARGET="$t1" bash scripts/install.sh >"$work/fresh.log" 2>&1
assert_file "$t1/opencode.jsonc"
assert_file "$t1/AGENTS.md"
assert_file "$t1/.opencode/agents/swe.md"
assert_file "$t1/.opencode/.swe-installed-files"
assert_no_file "$t1/opencode.swe.jsonc"
assert_not_contains "$t1/AGENTS.md" 'scripts/validate.sh'
assert_not_contains "$t1/AGENTS.md" 'guard-lifecycle.sh'
if grep -RInE 'scripts/|guard-lifecycle\.sh|validate\.sh' \
  "$t1/.opencode" "$t1/AGENTS.md" "$t1/opencode.jsonc"; then
  fail 'installed files still reference maintainer-only scripts'
fi
ok 'fresh install'

# Update an existing JSONC config in place, keeping user settings.
t2="$work/jsonc-update"
mkdir -p "$t2"
cat >"$t2/opencode.jsonc" <<'EOF'
{
  // user settings
  "default_agent": "build",
  "my_setting": "keep-me",
  "instructions": ["./MY_NOTES.md"]
}
EOF
cp "$root/opencode.jsonc" "$t2/opencode.swe.jsonc"
OPENCODE_SWE_TARGET="$t2" bash scripts/install.sh --update >"$work/jsonc-update.log" 2>&1
assert_file "$t2/opencode.jsonc"
assert_no_file "$t2/opencode.swe.jsonc"
assert_contains "$t2/opencode.jsonc" '"my_setting": "keep-me"'
assert_contains "$t2/opencode.jsonc" '"default_agent": "swe"'
assert_contains "$t2/opencode.jsonc" './MY_NOTES.md'
assert_contains "$t2/opencode.jsonc" '.opencode/instructions/swe-protocol.md'
assert_valid_json "$t2/opencode.jsonc"
ok 'JSONC updated in place without a side file'

# Re-running the update is a no-op for the config file.
before="$(cat "$t2/opencode.jsonc")"
OPENCODE_SWE_TARGET="$t2" bash scripts/install.sh --update >"$work/jsonc-idempotent.log" 2>&1
after="$(cat "$t2/opencode.jsonc")"
[[ "$before" == "$after" ]] || fail 'unchanged update rewrote the config'
assert_contains "$work/jsonc-idempotent.log" 'already current'
ok 'update is idempotent'

# An existing JSON config keeps using the in-place merge path.
t3="$work/json-update"
mkdir -p "$t3"
printf '{"default_agent":"build","custom":true}\n' >"$t3/opencode.json"
OPENCODE_SWE_TARGET="$t3" bash scripts/install.sh --update >"$work/json-update.log" 2>&1
assert_contains "$t3/opencode.json" '"custom": true'
assert_contains "$t3/opencode.json" '"default_agent": "swe"'
assert_no_file "$t3/opencode.jsonc"
assert_valid_json "$t3/opencode.json"
ok 'JSON updated in place'

# JSONC trailing commas parse cleanly instead of crashing.
t7="$work/trailing-commas"
mkdir -p "$t7"
cat >"$t7/opencode.jsonc" <<'EOF'
{
  // trailing commas are valid JSONC
  "default_agent": "build",
  "custom": [1, 2,],
}
EOF
OPENCODE_SWE_TARGET="$t7" bash scripts/install.sh --update >"$work/trailing.log" 2>&1
assert_contains "$t7/opencode.jsonc" '"default_agent": "swe"'
assert_contains "$t7/opencode.jsonc" '"custom"'
assert_valid_json "$t7/opencode.jsonc"
ok 'JSONC with trailing commas merged'

# Older installs have their maintainer-script paragraph removed, not their notes.
t4="$work/legacy-agents"
mkdir -p "$t4"
cat >"$t4/AGENTS.md" <<'EOF'
# OpenCode SWE System

Use `bash scripts/validate.sh` to validate the complete customization inventory and
`bash scripts/guard-lifecycle.sh` for build, diff, secret, and success preflights.

## Agent map

Custom project notes.
EOF
printf '{"default_agent":"swe"}\n' >"$t4/opencode.jsonc"
printf '{"edited_by":"project"}\n' >"$t4/opencode.swe.jsonc"
OPENCODE_SWE_TARGET="$t4" bash scripts/install.sh --update >"$work/legacy-agents.log" 2>&1
assert_not_contains "$t4/AGENTS.md" 'scripts/validate.sh'
assert_not_contains "$t4/AGENTS.md" 'guard-lifecycle.sh'
assert_contains "$t4/AGENTS.md" 'Custom project notes.'
assert_file "$t4/opencode.swe.jsonc"
ok 'stale AGENTS.md script references cleaned; edited side file kept'

# Uninstall leaves project-owned files (including custom .opencode files) alone.
t5="$work/uninstall-preserves"
mkdir -p "$t5/scripts"
printf '#!/bin/sh\necho project-script\n' >"$t5/scripts/validate.sh"
cat >"$t5/AGENTS.md" <<'EOF'
# My Project

We use swe-build for implementation.
EOF
printf '{"default_agent":"swe","instructions":[".opencode/instructions/swe-protocol.md","./own.md"],"my_setting":"keep-me"}\n' >"$t5/opencode.jsonc"
printf '{"edited_by":"project"}\n' >"$t5/opencode.swe.jsonc"
OPENCODE_SWE_TARGET="$t5" bash scripts/install.sh >"$work/install-preserves.log" 2>&1
mkdir -p "$t5/.opencode/commands"
printf 'custom project command\n' >"$t5/.opencode/commands/my-custom.md"
OPENCODE_SWE_TARGET="$t5" bash scripts/uninstall.sh >"$work/uninstall-preserves.log" 2>&1
assert_file "$t5/scripts/validate.sh"
assert_file "$t5/AGENTS.md"
assert_file "$t5/.opencode/commands/my-custom.md"
assert_no_file "$t5/.opencode/agents/swe.md"
assert_no_file "$t5/.opencode/instructions/swe-protocol.md"
assert_file "$t5/opencode.swe.jsonc"
assert_contains "$t5/opencode.swe.jsonc" 'edited_by'
assert_not_contains "$t5/opencode.jsonc" 'default_agent'
assert_not_contains "$t5/opencode.jsonc" 'swe-protocol.md'
assert_contains "$t5/opencode.jsonc" './own.md'
assert_contains "$t5/opencode.jsonc" 'keep-me'
assert_valid_json "$t5/opencode.jsonc"
ok 'uninstall preserves project-owned files and edited side file'

# Uninstall removes all recorded pack files and the pack-copied AGENTS.md.
t6="$work/uninstall-pack"
mkdir -p "$t6"
OPENCODE_SWE_TARGET="$t6" bash scripts/install.sh >"$work/install-pack.log" 2>&1
printf '# OpenCode SWE System\r\n\r\nbody\r\n' >"$t6/AGENTS.md"
printf '{"default_agent":"swe","agent":{"build":{"description":"General-purpose builder (fallback). Prefer swe for oversight."}},"other":1}\n' >"$t6/opencode.json"
OPENCODE_SWE_TARGET="$t6" bash scripts/uninstall.sh >"$work/uninstall-pack.log" 2>&1
assert_no_file "$t6/AGENTS.md"
assert_no_file "$t6/.opencode"
assert_not_contains "$t6/opencode.json" 'default_agent'
assert_not_contains "$t6/opencode.json" 'Prefer swe'
assert_contains "$t6/opencode.json" '"other": 1'
assert_valid_json "$t6/opencode.json"
ok 'uninstall removes pack-owned files'

# Legacy installs without a manifest keep unidentified .opencode files.
t8="$work/legacy-uninstall"
mkdir -p "$t8/.opencode/agents"
printf 'legacy marker\n' >"$t8/.opencode/agents/swe.md"
printf '# OpenCode SWE System\n' >"$t8/AGENTS.md"
OPENCODE_SWE_TARGET="$t8" bash scripts/uninstall.sh >"$work/legacy-uninstall.log" 2>&1
assert_file "$t8/.opencode/agents/swe.md"
assert_no_file "$t8/AGENTS.md"
assert_contains "$work/legacy-uninstall.log" 'No pack manifest found'
ok 'legacy uninstall keeps unidentified files'

if (( failures > 0 )); then
  printf '%d lifecycle test failure(s)\n' "$failures" >&2
  exit 1
fi
printf 'Install/update/uninstall lifecycle tests passed.\n'

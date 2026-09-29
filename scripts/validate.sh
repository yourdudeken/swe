#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

failures=0
fail() {
  printf 'ERROR: %s\n' "$1" >&2
  failures=$((failures + 1))
}

for instruction in \
  swe-protocol delegation verification definition-of-done risk-tiers \
  change-discipline spec-plan-build interrupt; do
  [[ -f ".opencode/instructions/$instruction.md" ]] ||
    fail "missing instruction: .opencode/instructions/$instruction.md"
done

while IFS= read -r path; do
  [[ -f "$path" ]] || fail "missing referenced path: $path"
done < <(
  grep -oE '"\.opencode/(instructions|agents|skills)/[^"]+' opencode.jsonc |
    sed 's/^"//' |
    sort -u
)

while IFS= read -r agent; do
  [[ -f ".opencode/agents/$agent.md" ]] ||
    fail "missing delegated agent: @$agent"
done < <(
  grep -RhoE '@[A-Za-z][A-Za-z0-9_-]*' .opencode |
    sed 's/^@//' |
    sort -u
)

while IFS= read -r agent; do
  [[ -f ".opencode/agents/$agent.md" ]] ||
    fail "command targets missing agent: $agent"
done < <(
  grep -RhoE '^agent: [A-Za-z][A-Za-z0-9_-]*' .opencode/commands |
    awk '{print $2}' |
    sort -u
)

if (( failures > 0 )); then
  printf '%d validation error(s)\n' "$failures" >&2
  exit 1
fi

printf 'OpenCode SWE definitions validated successfully.\n'

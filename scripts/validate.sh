#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

failures=0
fail() {
  printf 'ERROR: %s\n' "$1" >&2
  failures=$((failures + 1))
}

require_file() {
  [[ -f "$1" ]] || fail "missing file: $1"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

require_command jq

for instruction in \
  swe-protocol delegation verification definition-of-done risk-tiers \
  change-discipline spec-plan-build interrupt; do
  require_file ".opencode/instructions/$instruction.md"
done

declare -A agents=()
declare -A skills=()
declare -A commands=()
declare -A workflows=()

while IFS= read -r path; do
  name="$(basename "$path" .md)"
  [[ -z "${agents[$name]+x}" ]] || fail "duplicate agent: $name"
  agents[$name]="$path"
done < <(find .opencode/agents -maxdepth 1 -type f -name '*.md' -print | sort)

while IFS= read -r path; do
  name="$(basename "$(dirname "$path")")"
  [[ -z "${skills[$name]+x}" ]] || fail "duplicate skill: $name"
  skills[$name]="$path"
done < <(find .opencode/skills -mindepth 2 -maxdepth 2 -type f -name 'SKILL.md' -print | sort)

while IFS= read -r path; do
  name="$(basename "$path" .md)"
  [[ -z "${commands[$name]+x}" ]] || fail "duplicate command: $name"
  commands[$name]="$path"
done < <(find .opencode/commands -maxdepth 1 -type f -name '*.md' -print | sort)

while IFS= read -r path; do
  name="$(basename "$path" .md)"
  [[ -z "${workflows[$name]+x}" ]] || fail "duplicate workflow: $name"
  workflows[$name]="$path"
done < <(find .opencode/workflows -maxdepth 1 -type f -name '*.md' -print | sort)

frontmatter_value() {
  awk -F': ' -v key="$1" '$1 == key { print substr($0, length($1) + 3); exit }' "$2"
}

for name in "${!agents[@]}"; do
  path="${agents[$name]}"
  [[ "$(head -n 1 "$path")" == '---' ]] || fail "agent missing frontmatter: $path"
  [[ -n "$(frontmatter_value description "$path")" ]] || fail "agent missing description: $path"
  mode="$(frontmatter_value mode "$path")"
  [[ "$mode" == primary || "$mode" == subagent ]] || fail "agent has invalid mode '$mode': $path"
done

for name in "${!skills[@]}"; do
  path="${skills[$name]}"
  [[ "$(head -n 1 "$path")" == '---' ]] || fail "skill missing frontmatter: $path"
  declared="$(frontmatter_value name "$path")"
  [[ "$declared" == "$name" ]] || fail "skill name '$declared' does not match directory '$name': $path"
  [[ -n "$(frontmatter_value description "$path")" ]] || fail "skill missing description: $path"
done

for name in "${!commands[@]}"; do
  path="${commands[$name]}"
  [[ "$(head -n 1 "$path")" == '---' ]] || fail "command missing frontmatter: $path"
  [[ -n "$(frontmatter_value description "$path")" ]] || fail "command missing description: $path"
  target="$(frontmatter_value agent "$path")"
  [[ -n "${agents[$target]+x}" ]] || fail "command targets missing agent '$target': $path"
done

for name in "${!workflows[@]}"; do
  path="${workflows[$name]}"
  [[ "$(head -n 1 "$path")" != '---' ]] || fail "workflow unexpectedly uses agent frontmatter: $path"
done

while IFS= read -r path; do
  [[ -f "$path" ]] || fail "missing referenced path: $path"
done < <(
  grep -oE '"\.opencode/(instructions|agents|skills|commands|workflows)/[^" ]+' opencode.jsonc |
    sed 's/^"//' |
    sort -u
)

while IFS= read -r agent; do
  [[ -n "${agents[$agent]+x}" ]] || fail "missing referenced agent: @$agent"
done < <(
  grep -RhoE '@[A-Za-z][A-Za-z0-9_-]*' .opencode AGENTS.md |
    sed 's/^@//' |
    sort -u
)

while IFS= read -r target; do
  [[ -n "${agents[$target]+x}" ]] || fail "command targets missing agent: $target"
done < <(
  for path in .opencode/commands/*.md; do frontmatter_value agent "$path"; done |
    sort -u
)

while IFS= read -r skill; do
  [[ -n "${skills[$skill]+x}" ]] || fail "missing referenced skill: $skill"
done < <(
  grep -RhoE '(skill|skills)[[:space:]]+`[A-Za-z][A-Za-z0-9_-]*`' .opencode AGENTS.md |
    sed -E 's/.*`([^`]+)`.*/\1/' |
    sort -u
)

restricted_agents=(repo-explorer architect code-reviewer security-reviewer performance-engineer)
for name in "${restricted_agents[@]}"; do
  path="${agents[$name]-}"
  [[ -n "$path" ]] || continue
  grep -qE '^  edit: deny$' "$path" || fail "restricted agent may edit: $path"
  grep -qE '"git (reset|clean|checkout|switch|branch -D)' "$path" || fail "restricted agent lacks destructive git denial: $path"
done

for name in spec-writer plan-writer; do
  path="${agents[$name]-}"
  [[ -n "$path" ]] || continue
  if [[ "$name" == spec-writer ]]; then
    grep -q '"specs/\*\*": allow' "$path" || fail "spec-writer lacks specs-only permission: $path"
  else
    grep -q '"plans/\*\*": allow' "$path" || fail "plan-writer lacks plans-only permission: $path"
  fi
done

while IFS= read -r path; do
  grep -q '"rm -rf /\*": deny' "$path" || fail "wildcard Bash policy lacks root deletion denial: $path"
  grep -qE '"git reset( --hard)?\*": (ask|deny)' "$path" || fail "wildcard Bash policy lacks reset protection: $path"
  grep -qE '"git clean\*": (ask|deny)' "$path" || fail "wildcard Bash policy lacks clean protection: $path"
done < <(grep -RIl '^    "\*": allow$' .opencode/agents)

grep -q 'plans/08-build-checklist.md' .opencode/commands/swe-build.md ||
  fail "swe-build command does not require the build checklist"
grep -q 'plans/08-build-checklist.md' .opencode/skills/build-from-spec/SKILL.md ||
  fail "build-from-spec skill does not require the build checklist"

for status_file in specs/STATUS.md plans/STATUS.md; do
  [[ -f "$status_file" ]] || continue
  status="$(awk -F': ' '$1 == "status" { print $2; exit }' "$status_file")"
  case "$status" in
    draft|self_review|human_review|changes_requested|approved) ;;
    *) fail "invalid lifecycle status '$status' in $status_file" ;;
  esac
done

jsonc_without_full_line_comments="$(mktemp)"
trap 'rm -f "$jsonc_without_full_line_comments"' EXIT
grep -vE '^[[:space:]]*//' opencode.jsonc >"$jsonc_without_full_line_comments"
jq empty "$jsonc_without_full_line_comments" >/dev/null 2>&1 || fail "opencode.jsonc is not valid JSONC-compatible configuration"

for path in AGENTS.md docs/ARCHITECTURE.md docs/SWE-STANDARD.md; do
  require_file "$path"
  for name in "${!agents[@]}"; do
    grep -q "\`$name\`" "$path" || fail "$path omits agent '$name'"
  done
done

for name in "${!commands[@]}"; do
  grep -q "/$name" AGENTS.md || fail "AGENTS.md omits command '$name'"
done

for name in "${!skills[@]}"; do
  grep -q "\`$name\`" AGENTS.md || fail "AGENTS.md omits skill '$name'"
done

for name in "${!workflows[@]}"; do
  grep -q "$name" docs/ARCHITECTURE.md || fail "docs/ARCHITECTURE.md omits workflow '$name'"
done

if (( failures > 0 )); then
  printf '%d validation error(s)\n' "$failures" >&2
  exit 1
fi

printf 'OpenCode SWE definitions validated successfully.\n'

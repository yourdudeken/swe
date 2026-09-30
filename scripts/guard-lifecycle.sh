#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

usage() {
  printf 'Usage: %s build [--waiver REASON] | status FILE STATUS | diff | secrets | success\n' "$0" >&2
  exit 2
}

fail() {
  printf 'GUARD BLOCKED: %s\n' "$1" >&2
  exit 1
}

status_value() {
  awk -F': ' '$1 == "status" { print $2; exit }' "$1"
}

case "${1-}" in
  build)
    waiver=''
    if [[ "${2-}" == '--waiver' && -n "${3-}" ]]; then
      waiver="$3"
    fi
    if [[ -n "$waiver" ]]; then
      printf 'Lifecycle waiver recorded for this preflight: %s\n' "$waiver"
    else
      [[ -f specs/STATUS.md ]] || fail 'missing specs/STATUS.md'
      [[ -f plans/STATUS.md ]] || fail 'missing plans/STATUS.md'
      [[ "$(status_value specs/STATUS.md)" == approved ]] || fail 'specs/STATUS.md is not approved'
      [[ "$(status_value plans/STATUS.md)" == approved ]] || fail 'plans/STATUS.md is not approved'
    fi
    [[ -f plans/08-build-checklist.md ]] || fail 'missing plans/08-build-checklist.md'
    printf 'Build lifecycle preflight passed.\n'
    ;;
  status)
    [[ $# -eq 3 ]] || usage
    file="$2"
    requested="$3"
    [[ -f "$file" ]] || fail "missing status file: $file"
    case "$requested" in
      draft|self_review|human_review|changes_requested|approved) ;;
      *) fail "invalid status: $requested" ;;
    esac
    if [[ "$requested" == approved && "${OPENCODE_HUMAN_APPROVAL-}" != 1 ]]; then
      fail 'only an explicit human approval may set status to approved'
    fi
    printf 'Status transition is permitted for %s: %s\n' "$file" "$requested"
    ;;
  diff)
    git diff --check || fail 'whitespace or patch errors found'
    printf 'Diff guard passed.\n'
    ;;
  secrets)
    additions="$(git diff --no-ext-diff --unified=0 | grep '^+' | grep -v '^+++' || true)"
    if printf '%s\n' "$additions" | grep -Eiq "BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY|AKIA[0-9A-Z]{16}|api[_-]?key[[:space:]]*[:=][[:space:]]*[\"']|secret[_-]?key[[:space:]]*[:=][[:space:]]*[\"']"; then
      fail 'likely secret or credential detected in added lines'
    fi
    printf 'Secret scan guard passed.\n'
    ;;
  success)
    [[ "${OPENCODE_VERIFIED-}" == 1 ]] || fail 'set OPENCODE_VERIFIED=1 only after real verification commands pass'
    "$0" diff
    "$0" secrets
    printf 'Success guard passed.\n'
    ;;
  *)
    usage
    ;;
esac

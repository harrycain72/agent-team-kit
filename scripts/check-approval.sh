#!/usr/bin/env bash
# Report whether the user has approved docs/requirements.md and docs/architecture.md. Read-only.
#
# Usage: scripts/check-approval.sh [--status requirements|architecture] [project-dir]
#
# A document is approved when its first "Status:" line says "approved". Only the user sets that
# line, by editing the file; agents write "Status: draft" and never change it to approved.
#
#   (no option)   print both statuses; exit 0 if both are approved, 1 if not, 2 on a usage error
#   --status DOC  print one word for that document: approved, draft (or any other written
#                 value), no-status (file has no Status line) or missing; always exit 0
#
# Never modifies the project.

set -euo pipefail

usage() { sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
die() { echo "error: $*" >&2; exit 2; }

ONE=""; PROJ="."
while [ $# -gt 0 ]; do
  case "$1" in
    --status) [ $# -ge 2 ] || die "--status needs a value"; ONE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) PROJ="$1"; shift ;;
  esac
done
case "$ONE" in ""|requirements|architecture) ;; *) die "unknown document: $ONE" ;; esac
[ -d "$PROJ" ] || die "not a directory: $PROJ"
PROJ="$(cd "$PROJ" && pwd)"

doc_status() {  # doc_status <name> -> approved | <written value> | no-status | missing
  local f="$PROJ/docs/$1.md" v
  [ -f "$f" ] || { echo missing; return; }
  v="$(sed -n 's/^[Ss]tatus:[[:space:]]*//p' "$f" | head -n 1 | tr 'A-Z' 'a-z' | tr -d '*_`[:space:]')"
  echo "${v:-no-status}"
}

if [ -n "$ONE" ]; then doc_status "$ONE"; exit 0; fi

RC=0
for d in requirements architecture; do
  s="$(doc_status "$d")"
  if [ "$s" = "approved" ]; then echo "  docs/$d.md: approved"
  else echo "  ! docs/$d.md: $s (the user must set 'Status: approved' in the file)"; RC=1; fi
done
if [ "$RC" -eq 0 ]; then echo "Result: approved, building may start"
else echo "Result: NOT approved. No code, tests or configuration may be written yet."; fi
exit "$RC"

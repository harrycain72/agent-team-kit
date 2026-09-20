#!/usr/bin/env bash
# Report whether the user has approved the requirements and the architecture. Read-only.
#
# Usage: scripts/check-approval.sh [--status DOC | --for E-N | --approved-features] [project-dir]
#
# Documents: docs/business-prd.md (solution overview), docs/architecture.md, and one
# docs/features/e-N-<slug>/business-prd.md per feature (= epic). A document is approved when its
# first "Status:" line says "approved". Only the user sets that line, by editing the file; agents
# write "Status: draft" and never change it to approved.
#
#   (no option)          print every status; exit 0 if the overview and the architecture are
#                        approved and at least one feature is, else 1; 2 on a usage error
#   --for E-N            can feature E-N be built? print the three statuses; exit 0 only when the
#                        overview, the architecture and that feature are all approved, else 1
#   --status DOC         print one word for that document: approved, draft (or any other written
#                        value), no-status (no Status line) or missing; always exit 0.
#                        DOC: requirements, architecture, e-N, or a feature directory name
#   --approved-features  print the id (e-N) of every approved feature, one per line; exit 0
#
# Never modifies the project.

set -euo pipefail

usage() { sed -n '2,22p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
die() { echo "error: $*" >&2; exit 2; }

MODE=""; ARG=""; PROJ="."
while [ $# -gt 0 ]; do
  case "$1" in
    --status) [ $# -ge 2 ] || die "--status needs a value"; MODE=status; ARG="$2"; shift 2 ;;
    --for) [ $# -ge 2 ] || die "--for needs an epic id such as E-3"; MODE=for; ARG="$2"; shift 2 ;;
    --approved-features) MODE=approved; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) PROJ="$1"; shift ;;
  esac
done
[ -d "$PROJ" ] || die "not a directory: $PROJ"
PROJ="$(cd "$PROJ" && pwd)"
FEATURES="$PROJ/docs/features"

file_status() {  # file_status <path> -> approved | <written value> | no-status | missing
  local v
  [ -f "$1" ] || { echo missing; return; }
  v="$(sed -n 's/^[Ss]tatus:[[:space:]]*//p' "$1" | head -n 1 | tr 'A-Z' 'a-z' | tr -d '*_`[:space:]')"
  echo "${v:-no-status}"
}

feature_file() {  # feature_file <e-N | dir name> -> path of its business-prd.md, or nothing
  local k f
  k="$(echo "$1" | tr 'A-Z' 'a-z')"
  [ -f "$FEATURES/$1/business-prd.md" ] && { echo "$FEATURES/$1/business-prd.md"; return; }
  case "$k" in e-[0-9]*) ;; *) return 0 ;; esac
  for f in "$FEATURES/$k"/business-prd.md "$FEATURES/$k"-*/business-prd.md; do
    [ -f "$f" ] && { echo "$f"; return; }
  done
  return 0
}

feature_ids() {  # feature_ids -> the e-N key of every feature directory, sorted
  local d
  for d in "$FEATURES"/*/; do
    [ -f "${d}business-prd.md" ] || continue
    basename "$d" | sed -n -E 's/^(e-[0-9]+)(-.*)?$/\1/p'
  done | sort -t- -k2 -n
}

doc_status() {  # doc_status <requirements | architecture | e-N | dir> -> one word
  case "$1" in
    requirements) file_status "$PROJ/docs/business-prd.md" ;;
    architecture) file_status "$PROJ/docs/architecture.md" ;;
    *) local f; f="$(feature_file "$1")"; [ -n "$f" ] && file_status "$f" || echo missing ;;
  esac
}

approved_features() { local k; for k in $(feature_ids); do [ "$(doc_status "$k")" = approved ] && echo "$k"; done; true; }

case "$MODE" in
  status) doc_status "$ARG"; exit 0 ;;
  approved) approved_features; exit 0 ;;
esac

line() {  # line <label> <status> -> prints, returns 1 if not approved
  if [ "$2" = "approved" ]; then echo "  $1: approved"; return 0; fi
  echo "  ! $1: $2 (the user must set 'Status: approved' in the file)"; return 1
}

RC=0
line docs/business-prd.md "$(doc_status requirements)" || RC=1
line docs/architecture.md "$(doc_status architecture)" || RC=1

if [ "$MODE" = "for" ]; then
  K="$(echo "$ARG" | tr 'A-Z' 'a-z')"
  case "$K" in e-[0-9]*) ;; *) die "expected an epic id such as E-3, got: $ARG" ;; esac
  F="$(feature_file "$K")"
  if [ -n "$F" ]; then L="${F#"$PROJ"/}"; else L="docs/features/$K-<slug>/business-prd.md"; fi
  line "$L" "$(doc_status "$K")" || RC=1
  if [ "$RC" -eq 0 ]; then echo "Result: approved, $ARG may be built"
  else echo "Result: NOT approved. No code, tests or configuration may be written for $ARG yet."; fi
  exit "$RC"
fi

N=0; OK=0; APPROVED=""
for k in $(feature_ids); do
  N=$((N + 1))
  s="$(doc_status "$k")"; f="$(feature_file "$k")"
  if [ "$s" = "approved" ]; then OK=$((OK + 1)); APPROVED="$APPROVED $k"; echo "  ${f#"$PROJ"/}: approved"
  else echo "  ${f#"$PROJ"/}: $s (waiting; the user must set 'Status: approved' in the file)"; fi
done
[ "$N" -gt 0 ] || echo "  ! no feature requirements yet (docs/features/e-N-<slug>/business-prd.md)"

if [ "$RC" -eq 0 ] && [ "$OK" -gt 0 ]; then
  echo "Result: building may start for:$APPROVED ($OK of $N features approved; the others wait)"
  exit 0
fi
echo "Result: NOT approved. No code, tests or configuration may be written yet (needs the overview, the architecture and at least one feature)."
exit 1

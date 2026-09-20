#!/usr/bin/env bash
# Check the Ordna task board of a kit project against the ordna-tasks conventions. Read-only.
#
# Usage: scripts/check-board.sh [--stage requirements|design|build] [project-dir]
#
#   project-dir   the project (default: the current directory)
#   --stage       what has been delivered so far; later stages check more:
#                 requirements  epics and stories exist and match docs/requirements.md
#                 design        also: every story has a dev and a verify task
#                 build         also: status and ownership rules (default)
#
# Exit codes: 0 board consistent, 1 problems found, 2 usage or error.
# Never modifies the project.

set -euo pipefail

usage() { sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
die() { echo "error: $*" >&2; exit 2; }

STAGE="build"; PROJ="."
while [ $# -gt 0 ]; do
  case "$1" in
    --stage) [ $# -ge 2 ] || die "--stage needs a value"; STAGE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *) PROJ="$1"; shift ;;
  esac
done
case "$STAGE" in requirements|design|build) ;; *) die "unknown stage: $STAGE" ;; esac
[ -d "$PROJ" ] || die "not a directory: $PROJ"
PROJ="$(cd "$PROJ" && pwd)"

PROBLEMS=0
bad() { echo "  ! $*"; PROBLEMS=$((PROBLEMS + 1)); }
ok()  { echo "  $*"; }

echo "Board: $PROJ (stage: $STAGE)"

# --- setup ----------------------------------------------------------------------
CONFIG="$PROJ/.ordna/config.yaml"
if [ ! -f "$CONFIG" ]; then
  bad ".ordna/config.yaml is missing: run 'ordna init --storage=file' in the project"
  echo; echo "Result: needs attention"; exit 1
fi
grep -q '^storage: file' "$CONFIG" || bad "storage is not 'file' in .ordna/config.yaml (agents need the markdown files)"
STATUSES="$(sed -n 's/^statuses:[[:space:]]*\[\(.*\)\].*/\1/p' "$CONFIG" | tr -d ' ')"
case ",$STATUSES," in *,review,*) ;; *) bad "statuses '${STATUSES:-default}' lack 'review' (expected todo, doing, review, done)" ;; esac
TASKDIR="$PROJ/$(sed -n 's/^tasksDir:[[:space:]]*//p' "$CONFIG" | head -n 1)"
[ "$TASKDIR" != "$PROJ/" ] || TASKDIR="$PROJ/tasks"
[ -d "$TASKDIR" ] || { bad "task directory $TASKDIR is missing"; echo; echo "Result: needs attention"; exit 1; }

# --- read every task: id|status|assignee|tags|deps|open_criteria|ticked_criteria ---
TABLE="$(for f in "$TASKDIR"/*.md; do
  [ -e "$f" ] || continue
  awk -v file="$(basename "$f")" '
    BEGIN { fm = 0; list = "" }
    /^---[[:space:]]*$/ { fm++; next }
    fm == 1 {
      if ($0 ~ /^[A-Za-z_]+:/) { list = ""; k = $0; sub(/:.*/, "", k); v = $0; sub(/^[^:]*:[[:space:]]*/, "", v); gsub(/"/, "", v)
        if (k == "id") id = v; else if (k == "status") st = v; else if (k == "assignee") as = (v == "null" ? "" : v)
        else if (k == "tags" || k == "depends_on") {
          list = k
          if (v ~ /^\[.*\]$/) {  # inline form: tags: [a, b]
            list = ""; gsub(/[\[\] ]/, "", v)
            if (v != "") { if (k == "tags") tags = tags (tags ? "," : "") v; else deps = deps (deps ? "," : "") v }
          }
        }
      } else if ($0 ~ /^[[:space:]]*-[[:space:]]/ && list != "") {
        v = $0; sub(/^[[:space:]]*-[[:space:]]*/, "", v); gsub(/"/, "", v)
        if (list == "tags") tags = tags (tags ? "," : "") v; else deps = deps (deps ? "," : "") v
      }
    }
    fm >= 2 { if ($0 ~ /^- \[ \]/ && $0 !~ /^- \[ \][[:space:]]*$/) open++; else if ($0 ~ /^- \[[xX]\]/) tick++ }
    END { printf "%s|%s|%s|%s|%s|%d|%d|%s\n", (id ? id : file), st, as, tags, deps, open, tick, file }
  ' "$f"
done)"

if [ -z "$TABLE" ]; then
  ok "no tasks yet"
  if [ "$STAGE" = "requirements" ] || [ "$STAGE" = "design" ] || [ "$STAGE" = "build" ]; then
    bad "the board is empty: the business-analyst has not created epics and stories yet"
  fi
  echo; echo "Result: needs attention"; exit 1
fi

field() { echo "$1" | cut -d'|' -f"$2"; }
has_tag() { case ",$(field "$1" 4)," in *,"$2",*) return 0 ;; *) return 1 ;; esac; }
tag_with_prefix() { echo "$(field "$1" 4)" | tr ',' '\n' | grep -E "^$2" | head -n 1 || true; }
row_of() { echo "$TABLE" | awk -F'|' -v id="$1" '$1 == id { print; exit }'; }
label() { echo "$(field "$1" 1) ($(echo "$1" | cut -d'|' -f8))"; }

EPICS=""; STORIES=""; TASKS=""
while IFS= read -r row; do
  n=0; kinds=""
  for k in epic story task; do has_tag "$row" "$k" && { n=$((n + 1)); kinds="$kinds $k"; }; done
  if [ "$n" -ne 1 ]; then bad "$(label "$row"): needs exactly one of the tags epic, story, task (has:${kinds:- none})"; continue; fi
  case "$kinds" in
    " epic")  EPICS="$EPICS$row"$'\n' ;;
    " story") STORIES="$STORIES$row"$'\n' ;;
    " task")  TASKS="$TASKS$row"$'\n' ;;
  esac
done <<< "$TABLE"

count() { [ -n "$1" ] && printf '%s' "$1" | grep -c . || echo 0; }
ok "$(count "$EPICS") epics, $(count "$STORIES") stories, $(count "$TASKS") tasks"

# --- dependency ids must exist ----------------------------------------------------
while IFS= read -r row; do
  [ -n "$row" ] || continue
  for d in $(field "$row" 5 | tr ',' ' '); do
    [ -n "$(row_of "$d")" ] || bad "$(label "$row"): depends_on $d, which does not exist"
  done
done <<< "$TABLE"

# --- epics ------------------------------------------------------------------------
while IFS= read -r e; do
  [ -n "$e" ] || continue
  ekey="$(tag_with_prefix "$e" 'e-[0-9]+$')"
  [ -n "$ekey" ] || { bad "$(label "$e"): epic without an e-N tag"; continue; }
  [ -n "$(field "$e" 5)" ] || bad "$(label "$e"): epic has no stories in depends_on (parent must depend on its children)"
  for d in $(field "$e" 5 | tr ',' ' '); do
    r="$(row_of "$d")"; [ -z "$r" ] || has_tag "$r" story || bad "$(label "$e"): depends_on $d, which is not a story"
  done
done <<< "$EPICS"

# --- stories ----------------------------------------------------------------------
while IFS= read -r s; do
  [ -n "$s" ] || continue
  skey="$(tag_with_prefix "$s" '(us-[0-9]+|s0)$')"
  ekey="$(tag_with_prefix "$s" 'e-[0-9]+$')"
  [ -n "$skey" ] || bad "$(label "$s"): story without a us-N (or s0) tag"
  [ -n "$ekey" ] || bad "$(label "$s"): story without an e-N tag"
  if [ -n "$ekey" ]; then
    epic="$(echo "$EPICS" | grep -E "\|(.*,)?$ekey(,.*)?\|" | head -n 1 || true)"
    if [ -z "$epic" ]; then bad "$(label "$s"): no epic carries the tag $ekey"
    else case ",$(field "$epic" 5)," in *,"$(field "$s" 1)",*) ;; *) bad "$(label "$s"): epic $(field "$epic" 1) does not depend on it" ;; esac; fi
  fi
  [ "$STAGE" = "requirements" ] && continue
  dev=0; ver=0
  for d in $(field "$s" 5 | tr ',' ' '); do
    r="$(row_of "$d")"; [ -n "$r" ] || continue
    has_tag "$r" task || bad "$(label "$s"): depends_on $d, which is not a task"
    has_tag "$r" dev && dev=$((dev + 1)); has_tag "$r" verify && ver=$((ver + 1))
  done
  [ "$dev" -ge 1 ] || bad "$(label "$s"): no dev task in depends_on (the architect creates one per story)"
  [ "$ver" -ge 1 ] || bad "$(label "$s"): no verify task in depends_on (the architect creates one per story)"
done <<< "$STORIES"

# --- tasks ------------------------------------------------------------------------
if [ "$STAGE" != "requirements" ]; then
  while IFS= read -r t; do
    [ -n "$t" ] || continue
    has_tag "$t" cancelled && continue
    tkey="$(tag_with_prefix "$t" '(us-[0-9]+|s0)$')"
    [ -n "$tkey" ] || { bad "$(label "$t"): task without a us-N (or s0) tag"; continue; }
    kinds=0; for k in dev verify defect; do has_tag "$t" "$k" && kinds=$((kinds + 1)); done
    [ "$kinds" -eq 1 ] || bad "$(label "$t"): needs exactly one of the tags dev, verify, defect"
    story="$(echo "$STORIES" | grep -E "\|(.*,)?$tkey(,.*)?\|" | head -n 1 || true)"
    if [ -z "$story" ]; then bad "$(label "$t"): no story carries the tag $tkey"
    else case ",$(field "$story" 5)," in *,"$(field "$t" 1)",*) ;; *) bad "$(label "$t"): story $(field "$story" 1) does not depend on it" ;; esac; fi
  done <<< "$TASKS"
fi

# --- requirements versus board ----------------------------------------------------
REQ="$PROJ/docs/requirements.md"
if [ -f "$REQ" ]; then
  REQ_IDS="$(sed -e '/([Ww])[[:space:]]*$/d' -n -e 's/^###[[:space:]]*US-\([0-9][0-9]*\).*/us-\1/p' "$REQ" | sort -u)"  # Won't stories get no board story
  BOARD_IDS="$(echo "$STORIES" | tr '|' '\n' | tr ',' '\n' | grep -E '^us-[0-9]+$' | sort -u || true)"
  for id in $REQ_IDS; do echo "$BOARD_IDS" | grep -qx "$id" || bad "docs/requirements.md has $id but the board has no story for it"; done
  for id in $BOARD_IDS; do echo "$REQ_IDS" | grep -qx "$id" || bad "the board has a story $id that docs/requirements.md does not list"; done
fi

# --- status and ownership (build stage) ---------------------------------------------
if [ "$STAGE" = "build" ]; then
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    st="$(field "$row" 2)"; as="$(field "$row" 3)"; open="$(field "$row" 6)"
    case ",$STATUSES," in *,"$st",*) ;; *) bad "$(label "$row"): status '$st' is not a configured status" ;; esac
    if has_tag "$row" task && ! has_tag "$row" cancelled && [ "$st" != "todo" ] && [ -z "$as" ]; then bad "$(label "$row"): is $st but has no assignee"; fi
    if [ "$st" = "done" ] && ! has_tag "$row" cancelled && [ "$open" -gt 0 ]; then bad "$(label "$row"): is done but $open acceptance criteria are still unticked"; fi
    if [ "$st" = "done" ]; then
      for d in $(field "$row" 5 | tr ',' ' '); do
        r="$(row_of "$d")"; [ -z "$r" ] || [ "$(field "$r" 2)" = "done" ] || bad "$(label "$row"): is done but depends on $d, which is $(field "$r" 2)"
      done
    fi
    if has_tag "$row" dev && [ "$st" = "done" ]; then
      tkey="$(tag_with_prefix "$row" '(us-[0-9]+|s0)$')"
      v="$(echo "$TASKS" | grep -E "\|(.*,)?verify(,.*)?\|" | grep -E "\|(.*,)?$tkey(,.*)?\|" | head -n 1 || true)"
      [ -z "$v" ] || [ "$(field "$v" 2)" = "done" ] || bad "$(label "$row"): dev task is done but its verify task $(field "$v" 1) is $(field "$v" 2)"
    fi
    if has_tag "$row" dev && [ "$st" = "review" ] && [ "$open" -gt 0 ]; then bad "$(label "$row"): is in review but $open of its own criteria are still unticked"; fi
  done <<< "$TASKS$STORIES$EPICS"

  # Build work must not have started before the user approved both documents.
  APPROVAL="$(dirname "${BASH_SOURCE[0]}")/check-approval.sh"
  if [ -x "$APPROVAL" ]; then
    started="$(echo "$TASKS" | awk -F'|' 'NF > 1 && $2 != "todo" && $4 ~ /(^|,)(dev|verify|defect)(,|$)/ { printf "%s ", $1 }')"
    if [ -n "$started" ]; then
      for d in requirements architecture; do
        [ "$("$APPROVAL" --status "$d" "$PROJ")" = "approved" ] || bad "build tasks are already started ($started) but docs/$d.md is not approved by the user"
      done
    fi
  else
    bad "check-approval.sh is missing next to check-board.sh, so the approval gate cannot be checked"
  fi

  # A parent must not be todo once any child has started; an epic or story is done only when its children are.
  for level in "$STORIES" "$EPICS"; do
    while IFS= read -r p; do
      [ -n "$p" ] || continue
      [ "$(field "$p" 2)" = "todo" ] || continue
      for d in $(field "$p" 5 | tr ',' ' '); do
        r="$(row_of "$d")"; [ -z "$r" ] || [ "$(field "$r" 2)" = "todo" ] || { bad "$(label "$p"): is todo but $d is $(field "$r" 2); whoever starts the first child moves the parent to doing"; break; }
      done
    done <<< "$level"
  done
fi

echo
if [ "$PROBLEMS" -eq 0 ]; then echo "Result: OK"; exit 0; fi
echo "Result: needs attention ($PROBLEMS problem(s), lines marked !)"
exit 1

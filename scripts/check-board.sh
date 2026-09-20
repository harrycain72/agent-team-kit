#!/usr/bin/env bash
# Check the Ordna task board of a project against the board model in CLAUDE.md ("Task board (Ordna)")
# and the ordna-tasks skill: one story card per user story, one requirements card per feature, one
# general-planning card per solution, and one column per agent. Read-only.
#
# Usage: scripts/check-board.sh [--stage requirements|design|build] [project-dir]
#
#   project-dir   the project (default: the current directory)
#   --stage       what has been delivered so far; later stages check more:
#                 requirements  the cards exist and match the feature requirements files
#                               (docs/features/e-N-<slug>/business-prd.md, one per feature)
#                 design        also: every story past technical-design has its Build checklist and
#                               Verification sections
#                 build         also: column, assignee and approval rules (default)
#
# Exit codes: 0 board consistent, 1 problems found, 2 usage or error.
# Never modifies the project.

set -euo pipefail

usage() { sed -n '2,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
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
EXPECTED="todo,general-planning,business-design,technical-design,test-design,development,functional-test,perf-test,done"
CONFIG="$PROJ/.ordna/config.yaml"
if [ ! -f "$CONFIG" ]; then
  bad ".ordna/config.yaml is missing: run 'ordna init --storage=file' in the project"
  echo; echo "Result: needs attention"; exit 1
fi
grep -q '^storage: file' "$CONFIG" || bad "storage is not 'file' in .ordna/config.yaml (agents need the markdown files)"
STATUSES="$(sed -n 's/^statuses:[[:space:]]*\[\(.*\)\].*/\1/p' "$CONFIG" | tr -d ' ')"
[ "$STATUSES" = "$EXPECTED" ] || bad "statuses '${STATUSES:-default}' are not [${EXPECTED//,/, }] in .ordna/config.yaml"
TASKDIR="$PROJ/$(sed -n 's/^tasksDir:[[:space:]]*//p' "$CONFIG" | head -n 1)"
[ "$TASKDIR" != "$PROJ/" ] || TASKDIR="$PROJ/tasks"
[ -d "$TASKDIR" ] || { bad "task directory $TASKDIR is missing"; echo; echo "Result: needs attention"; exit 1; }

# --- read every card: id|status|assignee|tags|deps|open_items|ticked_items|file ---
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
  ok "no cards yet"
  bad "the board is empty: the lead has not created the general-planning card and the business-analyst has not created the requirements and story cards yet"
  echo; echo "Result: needs attention"; exit 1
fi

field() { echo "$1" | cut -d'|' -f"$2"; }
has_tag() { case ",$(field "$1" 4)," in *,"$2",*) return 0 ;; *) return 1 ;; esac; }
tag_with_prefix() { echo "$(field "$1" 4)" | tr ',' '\n' | grep -E "^$2" | head -n 1 || true; }
row_of() { echo "$TABLE" | awk -F'|' -v id="$1" '$1 == id { print; exit }'; }
label() { echo "$(field "$1" 1) ($(echo "$1" | cut -d'|' -f8))"; }
in_list() { case " $2 " in *" $1 "*) return 0 ;; *) return 1 ;; esac; }
# the agent who has a card in a story column
agent_for() {
  case "$1" in
    business-design) echo business-analyst ;;  technical-design) echo architect ;;
    test-design) echo test-manager ;;          development) echo developer ;;
    functional-test) echo tester ;;            perf-test) echo perf-tester ;;
  esac
}

PLANNING=""; REQS=""; STORIES=""
while IFS= read -r row; do
  n=0; kinds=""
  for k in planning requirements story; do has_tag "$row" "$k" && { n=$((n + 1)); kinds="$kinds $k"; }; done
  if [ "$n" -ne 1 ]; then bad "$(label "$row"): needs exactly one of the tags planning, requirements, story (has:${kinds:- none})"; continue; fi
  case "$kinds" in
    " planning")     PLANNING="$PLANNING$row"$'\n' ;;
    " requirements") REQS="$REQS$row"$'\n' ;;
    " story")        STORIES="$STORIES$row"$'\n' ;;
  esac
done <<< "$TABLE"

count() { [ -n "$1" ] && printf '%s' "$1" | grep -c . || echo 0; }
ok "$(count "$PLANNING") general-planning cards, $(count "$REQS") requirements cards, $(count "$STORIES") stories"

# --- dependency ids must exist and be story cards ---------------------------------
while IFS= read -r row; do
  [ -n "$row" ] || continue
  for d in $(field "$row" 5 | tr ',' ' '); do
    r="$(row_of "$d")"
    if [ -z "$r" ]; then bad "$(label "$row"): depends_on $d, which does not exist"
    elif has_tag "$row" story && ! has_tag "$r" story; then bad "$(label "$row"): depends_on $d, which is not a story"; fi
  done
done <<< "$TABLE"

# --- general-planning card (one per solution) -----------------------------------------
if [ "$(count "$PLANNING")" -ne 1 ]; then
  bad "the board needs exactly one general-planning card (tags planning, general), found $(count "$PLANNING")"
fi
while IFS= read -r p; do
  [ -n "$p" ] || continue
  has_tag "$p" general || bad "$(label "$p"): general-planning card without the tag general"
done <<< "$PLANNING"

# --- requirements cards (one per feature) ---------------------------------------------
while IFS= read -r r; do
  [ -n "$r" ] || continue
  ekey="$(tag_with_prefix "$r" 'e-[0-9]+$')"
  [ -n "$ekey" ] || { bad "$(label "$r"): requirements card without an e-N tag"; continue; }
  if [ "$ekey" = "e-0" ] || [ -z "$(compgen -G "$PROJ/docs/features/$ekey-*/business-prd.md" || compgen -G "$PROJ/docs/features/$ekey/business-prd.md" || true)" ]; then
    bad "$(label "$r"): no requirements file docs/features/$ekey-<slug>/business-prd.md (one file per feature)"
  fi
  [ "$(echo "$REQS" | grep -cE "\|(.*,)?$ekey(,.*)?\|" || true)" -le 1 ] || bad "$(label "$r"): more than one requirements card carries the tag $ekey"
done <<< "$REQS"

# --- stories ----------------------------------------------------------------------
while IFS= read -r s; do
  [ -n "$s" ] || continue
  skey="$(tag_with_prefix "$s" '(us-[0-9]+|s0)$')"
  ekey="$(tag_with_prefix "$s" 'e-[0-9]+$')"
  [ -n "$skey" ] || bad "$(label "$s"): story without a us-N (or s0) tag"
  [ -n "$ekey" ] || bad "$(label "$s"): story without an e-N tag"
  if [ -n "$ekey" ] && [ "$ekey" != "e-0" ] && [ -z "$(echo "$REQS" | grep -E "\|(.*,)?$ekey(,.*)?\|" || true)" ]; then
    bad "$(label "$s"): no requirements card carries the tag $ekey"
  fi
  case "$(field "$s" 2)" in
    test-design|development|functional-test|perf-test|done)
      if [ "$STAGE" != "requirements" ] && ! has_tag "$s" cancelled; then
        f="$TASKDIR/$(echo "$s" | cut -d'|' -f8)"
        grep -q '^## Build checklist' "$f" || bad "$(label "$s"): is $(field "$s" 2) but has no '## Build checklist' (the architect adds it in technical-design)"
        grep -q '^## Verification' "$f" || bad "$(label "$s"): is $(field "$s" 2) but has no '## Verification' (the architect adds it in technical-design)"
      fi ;;
  esac
done <<< "$STORIES"

# --- requirements versus board ----------------------------------------------------
# One requirements file per feature (= epic): docs/features/e-N-<slug>/business-prd.md holds its stories.
# docs/business-prd.md is the solution overview and lists no stories.
story_ids() { sed -e '/([Ww])[[:space:]]*$/d' -n -e 's/^###[[:space:]]*US-\([0-9][0-9]*\).*/us-\1/p' "$1" | sort -u; }  # Won't stories get no board story
BOARD_IDS="$(echo "$STORIES" | tr '|' '\n' | tr ',' '\n' | grep -E '^us-[0-9]+$' | sort -u || true)"
REQ_IDS=""
OVERVIEW="$PROJ/docs/business-prd.md"
if [ -f "$OVERVIEW" ] && [ -n "$(story_ids "$OVERVIEW")" ]; then
  bad "docs/business-prd.md lists user stories ($(story_ids "$OVERVIEW" | tr '\n' ' ')): stories belong in docs/features/e-N-<slug>/business-prd.md, one file per feature"
fi
for f in "$PROJ"/docs/features/*/business-prd.md; do
  [ -e "$f" ] || continue
  rel="${f#"$PROJ"/}"; dir="$(basename "$(dirname "$f")")"
  fkey="$(echo "$dir" | sed -n -E 's/^(e-[0-9]+)(-.*)?$/\1/p')"
  if [ -z "$fkey" ]; then bad "$rel: the directory must start with the feature id, e-N-<slug>"; continue; fi
  hdr="$(sed -n 's/^Epic:[[:space:]]*\(E-[0-9][0-9]*\).*/\1/p' "$f" | head -n 1 | tr 'A-Z' 'a-z')"
  if [ -z "$hdr" ]; then bad "$rel: no 'Epic: E-N' line"
  elif [ "$hdr" != "$fkey" ]; then bad "$rel: says Epic $hdr but its directory is $fkey"; fi
  [ -n "$(echo "$REQS" | grep -E "\|(.*,)?$fkey(,.*)?\|" || true)" ] || bad "$rel: the board has no requirements card with the tag $fkey"
  for id in $(story_ids "$f"); do
    REQ_IDS="$REQ_IDS$id"$'\n'
    row="$(echo "$STORIES" | grep -E "\|(.*,)?$id(,.*)?\|" | head -n 1 || true)"
    if [ -z "$row" ]; then bad "$rel has $id but the board has no story for it"
    elif ! has_tag "$row" "$fkey"; then bad "$rel has $id, but the board story $(field "$row" 1) is not tagged $fkey (tag $(tag_with_prefix "$row" 'e-[0-9]+$'))"; fi
  done
done
REQ_IDS="$(echo "$REQ_IDS" | grep . | sort | uniq -c | awk '$1 > 1 { print "dup " $2 } $1 == 1 { print $2 }' || true)"
for id in $(echo "$REQ_IDS" | sed -n 's/^dup //p'); do bad "$id appears in more than one feature requirements file (story ids are unique across the solution)"; done
REQ_IDS="$(echo "$REQ_IDS" | sed 's/^dup //' | sort -u)"
for id in $BOARD_IDS; do echo "$REQ_IDS" | grep -qx "$id" || bad "the board has a story $id that no docs/features/*/business-prd.md lists"; done

# --- column, assignee and approval rules (build stage) ----------------------------------
if [ "$STAGE" = "build" ]; then
  while IFS= read -r row; do
    [ -n "$row" ] || continue
    st="$(field "$row" 2)"; as="$(field "$row" 3)"; open="$(field "$row" 6)"
    case ",$STATUSES," in *,"$st",*) ;; *) bad "$(label "$row"): status '$st' is not a configured status"; continue ;; esac
    if [ "$st" = "done" ] && ! has_tag "$row" cancelled && [ "$open" -gt 0 ]; then bad "$(label "$row"): is done but $open items are still unticked"; fi
    if [ "$st" = "done" ]; then
      for d in $(field "$row" 5 | tr ',' ' '); do
        r="$(row_of "$d")"; [ -z "$r" ] || [ "$(field "$r" 2)" = "done" ] || bad "$(label "$row"): is done but depends on $d, which is $(field "$r" 2)"
      done
    fi
    has_tag "$row" cancelled && continue
    if has_tag "$row" story; then
      # The column shows which agent has the story; the assignee is that agent.
      case "$st" in
        general-planning) bad "$(label "$row"): a story never enters general-planning (only the solution's planning card does)" ;;
        todo|done) ;;
        *) [ "$as" = "$(agent_for "$st")" ] || bad "$(label "$row"): is in $st, so the assignee must be $(agent_for "$st") (is '${as:-nobody}')" ;;
      esac
    elif has_tag "$row" requirements; then
      case "$st" in
        business-design) in_list "$as" "business-analyst user" || bad "$(label "$row"): requirements card in business-design must be assigned to business-analyst (writing) or user (review), is '${as:-nobody}'" ;;
        done) ;;
        *) bad "$(label "$row"): a requirements card lives in business-design until the lead moves it to done, is in $st" ;;
      esac
    elif has_tag "$row" planning; then
      case "$st" in
        general-planning) in_list "$as" "business-analyst architect test-manager user" || bad "$(label "$row"): general-planning card must be assigned to business-analyst, architect, test-manager or user, is '${as:-nobody}'" ;;
        done) ;;
        *) bad "$(label "$row"): the general-planning card lives in general-planning until the lead moves it to done, is in $st" ;;
      esac
    fi
  done <<< "$PLANNING$REQS$STORIES"

  # Build work must not have started before the user approved the overview, the architecture and the
  # story's feature (S0 / E-0: any approved feature). A story in development or later has started.
  APPROVAL="$(dirname "${BASH_SOURCE[0]}")/check-approval.sh"
  if [ -x "$APPROVAL" ]; then
    ANY_FEATURE="$("$APPROVAL" --approved-features "$PROJ")"
    while IFS= read -r s; do
      [ -n "$s" ] || continue
      case "$(field "$s" 2)" in development|functional-test|perf-test|done) ;; *) continue ;; esac
      tk="$(field "$s" 1)"; ek="$(tag_with_prefix "$s" 'e-[0-9]+$')"
      for d in requirements architecture; do
        [ "$("$APPROVAL" --status "$d" "$PROJ")" = "approved" ] || bad "story $tk is $(field "$s" 2) but docs/$d.md is not approved by the user"
      done
      if [ -z "$ek" ] || [ "$ek" = "e-0" ]; then
        [ -n "$ANY_FEATURE" ] || bad "story $tk is $(field "$s" 2) but no feature requirements file is approved by the user"
      else
        [ "$("$APPROVAL" --status "$ek" "$PROJ")" = "approved" ] || bad "story $tk is $(field "$s" 2) but the requirements of feature $ek are not approved by the user"
      fi
    done <<< "$STORIES"
  else
    bad "check-approval.sh is missing next to check-board.sh, so the approval gate cannot be checked"
  fi
fi

echo
if [ "$PROBLEMS" -eq 0 ]; then echo "Result: OK"; exit 0; fi
echo "Result: needs attention ($PROBLEMS problem(s), lines marked !)"
exit 1

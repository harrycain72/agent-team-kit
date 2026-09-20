#!/usr/bin/env bash
# Check a project created with new-project.sh against this kit. Read-only.
#
# Usage: scripts/check-project.sh <project-dir>
#
# Reports:
#   - the kit version the project pins (.claude/agent-team-kit.version and CLAUDE.md)
#     against this kit's version
#   - files in the project's .claude/ that differ from the kit (agents, the installed
#     skills, templates); when the versions are equal these are local edits, when the
#     project is older they are mostly changes the upgrade would bring
#
# Exit codes: 0 up to date and no differences, 1 needs attention, 2 usage or error.
# Never modifies the project. To upgrade, follow the steps in CHANGELOG.md.

set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() { sed -n '2,13p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
die() { echo "error: $*" >&2; exit 2; }

case "${1:-}" in
  -h|--help) usage; exit 0 ;;
  "") usage; exit 2 ;;
esac
[ $# -eq 1 ] || die "expected exactly one argument"
[ -d "$1" ] || die "not a directory: $1"
PROJ="$(cd "$1" && pwd)"
[ -d "$PROJ/.claude" ] || die "$PROJ has no .claude directory; not a kit project?"

ATTENTION=0
note()  { echo "  $*"; }
flag()  { echo "  ! $*"; ATTENTION=1; }

field() { sed -n "s/^$1=//p" "$2" | head -n 1; }

KIT_VERSION="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$KIT/.claude-plugin/plugin.json" | head -n 1)"
[ -n "$KIT_VERSION" ] || die "cannot read the kit version from $KIT/.claude-plugin/plugin.json"

echo "Project: $PROJ"
echo "Kit:     $KIT (version $KIT_VERSION)"
echo

# --- pinned version -------------------------------------------------------------
echo "Version"
VFILE="$PROJ/.claude/agent-team-kit.version"
FILE_VERSION=""; BACKEND=""; FRONTEND=""
if [ -f "$VFILE" ]; then
  FILE_VERSION="$(field version "$VFILE")"
  BACKEND="$(field backend "$VFILE")"
  FRONTEND="$(field frontend "$VFILE")"
  note ".claude/agent-team-kit.version: $FILE_VERSION (backend $BACKEND, frontend $FRONTEND)"
else
  flag ".claude/agent-team-kit.version is missing (project made before 0.3.0 or by hand)"
fi

CLAUDE_VERSION=""
if [ -f "$PROJ/CLAUDE.md" ]; then
  CLAUDE_VERSION="$(sed -n 's/^- agent-team-kit: \([0-9][0-9.]*\).*/\1/p' "$PROJ/CLAUDE.md" | head -n 1)"
  if [ -n "$CLAUDE_VERSION" ]; then
    note "CLAUDE.md pin:                       $CLAUDE_VERSION"
  else
    flag "CLAUDE.md has no '- agent-team-kit: <version>' line"
  fi
else
  flag "CLAUDE.md is missing"
fi

if [ -n "$FILE_VERSION" ] && [ -n "$CLAUDE_VERSION" ] && [ "$FILE_VERSION" != "$CLAUDE_VERSION" ]; then
  flag "the version file ($FILE_VERSION) and CLAUDE.md ($CLAUDE_VERSION) disagree; fix one so both match"
fi

PINNED="${CLAUDE_VERSION:-$FILE_VERSION}"
if [ -z "$PINNED" ]; then
  flag "no pinned version found; cannot compare with the kit"
elif [ "$PINNED" = "$KIT_VERSION" ]; then
  note "up to date with the kit ($KIT_VERSION)"
else
  NEWEST="$(printf '%s\n%s\n' "$PINNED" "$KIT_VERSION" | sort -V | tail -n 1)"
  if [ "$NEWEST" = "$KIT_VERSION" ]; then
    flag "project is on $PINNED, the kit is on $KIT_VERSION: see CHANGELOG.md for the upgrade steps"
  else
    flag "project pins $PINNED, which is newer than this kit ($KIT_VERSION): is this an old checkout of the kit?"
  fi
fi
echo

# --- packs ----------------------------------------------------------------------
echo "Packs"
INSTALLED_BACKEND="$(cd "$PROJ/.claude/skills" 2>/dev/null && ls -d stack-backend-* 2>/dev/null || true)"
INSTALLED_FRONTEND="$(cd "$PROJ/.claude/skills" 2>/dev/null && ls -d stack-frontend-* 2>/dev/null || true)"
note "installed backend:  ${INSTALLED_BACKEND:-none}"
note "installed frontend: ${INSTALLED_FRONTEND:-none}"
[ -n "$INSTALLED_BACKEND" ]  || flag "no backend pack installed"
[ -n "$INSTALLED_FRONTEND" ] || flag "no frontend pack installed"
[ "$(echo "$INSTALLED_BACKEND" | wc -w)" -le 1 ]  || flag "more than one backend pack installed"
[ "$(echo "$INSTALLED_FRONTEND" | wc -w)" -le 1 ] || flag "more than one frontend pack installed"
[ -z "$BACKEND" ]  || [ "$BACKEND"  = "$INSTALLED_BACKEND" ]  || flag "version file names $BACKEND but $INSTALLED_BACKEND is installed"
[ -z "$FRONTEND" ] || [ "$FRONTEND" = "$INSTALLED_FRONTEND" ] || flag "version file names $FRONTEND but $INSTALLED_FRONTEND is installed"
[ -d "$PROJ/.claude/skills/stack-common" ] || flag "stack-common is not installed"
for p in $INSTALLED_BACKEND $INSTALLED_FRONTEND; do
  [ -d "$KIT/skills/$p" ] || flag "$p does not exist in this kit (renamed or removed?)"
done
echo

# --- ordna board ------------------------------------------------------------------
echo "Approval gate"
if [ -f "$PROJ/.claude/settings.json" ] && grep -q 'require-approval.sh' "$PROJ/.claude/settings.json"; then
  note "hook registered in .claude/settings.json"
else
  flag "the approval hook is not registered in .claude/settings.json (copy hooks/require-approval.sh and add the PreToolUse entry from scripts/new-project.sh)"
fi
[ -x "$PROJ/.claude/hooks/require-approval.sh" ] || flag ".claude/hooks/require-approval.sh is missing or not executable"
if [ -x "$PROJ/.claude/scripts/check-approval.sh" ]; then
  "$PROJ/.claude/scripts/check-approval.sh" "$PROJ" | sed 's/^/  /' || true
fi
echo

echo "Ordna board"
if command -v ordna >/dev/null 2>&1; then note "ordna installed"; else flag "ordna is not installed (npm install -g @frehilm/ordna-cli, https://ordna.sh#install)"; fi
if [ -f "$PROJ/.ordna/config.yaml" ]; then
  grep -q '^storage: file' "$PROJ/.ordna/config.yaml" && note "storage: file" || flag "storage is not 'file' in .ordna/config.yaml (agents need the markdown files)"
  grep -Eq '^statuses: \[todo, general-planning, business-design, technical-design, test-design, development, functional-test, perf-test, done\]' "$PROJ/.ordna/config.yaml" \
    && note "statuses: one column per agent role" \
    || flag "statuses are not [todo, general-planning, business-design, technical-design, test-design, development, functional-test, perf-test, done] in .ordna/config.yaml"
else
  flag ".ordna/config.yaml is missing: run 'ordna init --storage=file' in the project (the kit's ordna-tasks skill needs it)"
fi
[ -d "$PROJ/tasks" ] || flag "tasks/ is missing"
[ -f "$PROJ/AGENTS.md" ] || note "AGENTS.md (upstream Ordna agent guide) is absent: ordna skill install (optional)"
note "board content: .claude/scripts/check-board.sh $PROJ"
echo

# --- differences from the kit ---------------------------------------------------
echo "Differences from the kit"
DIFFS=0
report() {  # report <diff -rq output>
  [ -n "$1" ] || return 0
  DIFFS=1
  echo "$1" | sed -e "s#$KIT/#kit:#g" -e "s#$PROJ/#project:#g" -e 's/^/  /'
}

for f in "$KIT"/agents/*.md; do
  n="$(basename "$f")"
  if [ ! -f "$PROJ/.claude/agents/$n" ]; then
    DIFFS=1; note "missing in project: .claude/agents/$n"
  elif ! cmp -s "$f" "$PROJ/.claude/agents/$n"; then
    DIFFS=1; note "differs: .claude/agents/$n"
  fi
done

for s in team-workflow ordna-tasks baseline-requirements stack-common $INSTALLED_BACKEND $INSTALLED_FRONTEND; do
  if [ ! -d "$KIT/skills/$s" ]; then continue; fi
  if [ ! -d "$PROJ/.claude/skills/$s" ]; then
    DIFFS=1; note "missing in project: .claude/skills/$s"
    continue
  fi
  report "$(diff -rq "$KIT/skills/$s" "$PROJ/.claude/skills/$s" || true)"
done

for pair in "scripts/check-board.sh:.claude/scripts/check-board.sh" "scripts/check-approval.sh:.claude/scripts/check-approval.sh" "hooks/require-approval.sh:.claude/hooks/require-approval.sh"; do
  src="${pair%%:*}"; dst="${pair##*:}"
  if [ ! -f "$PROJ/$dst" ]; then DIFFS=1; note "missing in project: $dst"
  elif ! cmp -s "$KIT/$src" "$PROJ/$dst"; then DIFFS=1; note "differs: $dst"; fi
done

report "$(diff -rq -x CLAUDE.md.template "$KIT/templates" "$PROJ/.claude/templates" || true)"


if [ "$DIFFS" -eq 0 ]; then
  note "none: agents, skills and templates match the kit"
else
  ATTENTION=1
  if [ -n "$PINNED" ] && [ "$PINNED" = "$KIT_VERSION" ]; then
    note "(versions are equal, so these are local edits to the copied kit files)"
  else
    note "(versions differ, so many of these are changes the upgrade brings; local edits are mixed in)"
  fi
fi
echo

if [ "$ATTENTION" -eq 0 ]; then
  echo "Result: OK"
else
  echo "Result: needs attention (see lines marked !, and the differences above)"
fi
exit "$ATTENTION"

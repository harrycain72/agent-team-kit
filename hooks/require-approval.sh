#!/usr/bin/env bash
# PreToolUse hook (Write, Edit, MultiEdit, NotebookEdit): the approval gate. Exit 2 blocks the call
# and the message on stderr goes back to the agent.
#
# 1. Until docs/requirements.md (solution overview), docs/architecture.md and at least one feature
#    requirements file (docs/features/e-N-<slug>/requirements.md) say "Status: approved", nothing
#    outside docs/, tasks/, .ordna/, CLAUDE.md, AGENTS.md and README.md may be written (no code,
#    tests, configuration, scripts). Which feature a source file belongs to is not known here.
# 2. Once a document is approved, agents may not edit it: the user reopens it (sets Status back
#    to draft) or makes the change.
# 3. Agents may never write "Status: approved" into either document.
# 4. Agents may not change the gate itself (.claude/settings*.json, .claude/hooks/, .claude/scripts/).
#
# Best effort: it sees file-editing tools only. A shell command that writes files is not caught here;
# the agents' instructions forbid it, and .claude/scripts/check-board.sh reports build work
# that started before approval.

set -uo pipefail

INPUT="$(cat)"
PROJ="$(cd "${CLAUDE_PROJECT_DIR:-$PWD}" && pwd)"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$HERE/../scripts/check-approval.sh"

if command -v jq >/dev/null 2>&1; then
  FILE="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)"
else
  FILE="$(printf '%s' "$INPUT" | sed -n 's/.*"\(file_path\|notebook_path\)"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\2/p' | head -n 1)"
fi
[ -n "$FILE" ] || exit 0

case "$FILE" in /*) ABS="$FILE" ;; *) ABS="$PROJ/$FILE" ;; esac
ABS="$(realpath -m -- "$ABS")"
case "$ABS" in "$PROJ"/*) REL="${ABS#"$PROJ"/}" ;; *) exit 0 ;; esac   # outside the project: not our business

deny() { echo "BLOCKED by the approval gate: $*" >&2; exit 2; }

case "$REL" in
  .claude/settings.json|.claude/settings.local.json|.claude/hooks/*|.claude/scripts/*)
    deny "$REL is part of the gate. Only the user changes it." ;;
esac

DOC=""
case "$REL" in
  docs/requirements.md) DOC=requirements ;;
  docs/architecture.md) DOC=architecture ;;
  docs/features/*/requirements.md) DOC="$(basename "$(dirname "$REL")")" ;;   # one per feature (epic)
esac

if [ -n "$DOC" ]; then
  if printf '%s' "$INPUT" | grep -Eiq 'status:[[:space:]]*[*_`]*approved'; then
    deny "only the user sets 'Status: approved' in $REL, by editing the file themselves. Write 'Status: draft' and ask the lead to have the user review it."
  fi
  if [ "$("$CHECK" --status "$DOC" "$PROJ")" = "approved" ]; then
    deny "$REL is approved and frozen. Ask the user to set its Status back to draft (or to make the change), then continue."
  fi
  exit 0
fi

case "$REL" in docs/*|tasks/*|.ordna/*|CLAUDE.md|AGENTS.md|README.md) exit 0 ;; esac

R="$("$CHECK" --status requirements "$PROJ")"; A="$("$CHECK" --status architecture "$PROJ")"
F="$("$CHECK" --approved-features "$PROJ" | tr '\n' ' ')"
if [ "$R" != "approved" ] || [ "$A" != "approved" ] || [ -z "${F// /}" ]; then
  deny "no code, tests or configuration until the user has approved the overview, the architecture and at least one feature (docs/requirements.md: $R, docs/architecture.md: $A, approved features: ${F:-none}). Do not write $REL. Stop, tell the lead which document is waiting for approval, and continue with other work that is allowed (documents, tasks)."
fi
# The hook cannot tell which feature a source file belongs to. Building only the approved
# features is the agents' rule (run check-approval.sh --for E-N) and check-board.sh reports breaches.
exit 0

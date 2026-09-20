#!/usr/bin/env bash
# Create a new project from the agent-team-kit (copy install, version pinned).
#
# Usage: scripts/new-project.sh <project-name> [--root DIR] [--backend PACK] [--frontend PACK]
#
#   <project-name>    directory name of the new project (letters, digits, - _ .)
#   --root DIR        parent directory for the new project
#                     (default: the directory that contains this kit, so the
#                     new project is a sibling of the kit's own repository)
#   --backend PACK    backend pack (default: stack-backend-fastapi-bce;
#                     also: stack-backend-quarkus-bce)
#   --frontend PACK   frontend pack (default: stack-frontend-react;
#                     also: stack-frontend-angular)
#
# Requires ordna (npm install -g @frehilm/ordna-cli, https://ordna.sh#install): the project gets an
# Ordna board (tasks/, .ordna/config.yaml, AGENTS.md) and the ordna-tasks skill.
# Does not run git init, commit or push.

set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$KIT/.." && pwd)"
BACKEND="stack-backend-fastapi-bce"
FRONTEND="stack-frontend-react"
NAME=""

usage() { sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }
die() { echo "error: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --root)     [ $# -ge 2 ] || die "--root needs a value";     ROOT="$2";     shift 2 ;;
    --backend)  [ $# -ge 2 ] || die "--backend needs a value";  BACKEND="$2";  shift 2 ;;
    --frontend) [ $# -ge 2 ] || die "--frontend needs a value"; FRONTEND="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) die "unknown option: $1" ;;
    *)  [ -z "$NAME" ] || die "unexpected argument: $1"; NAME="$1"; shift ;;
  esac
done

[ -n "$NAME" ] || { usage; exit 1; }
command -v ordna >/dev/null 2>&1 \
  || die "ordna is not installed; the team tracks its work on the Ordna board (https://ordna.sh#install). Install it with: npm install -g @frehilm/ordna-cli"
[[ "$NAME" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "invalid project name: $NAME"
[ -d "$ROOT" ] || die "root directory does not exist: $ROOT"
[[ "$BACKEND" == stack-backend-* && -d "$KIT/skills/$BACKEND" ]] \
  || die "unknown backend pack: $BACKEND (available: $(cd "$KIT/skills" && ls -d stack-backend-* | tr '\n' ' '))"
[[ "$FRONTEND" == stack-frontend-* && -d "$KIT/skills/$FRONTEND" ]] \
  || die "unknown frontend pack: $FRONTEND (available: $(cd "$KIT/skills" && ls -d stack-frontend-* | tr '\n' ' '))"

VERSION="$(sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$KIT/.claude-plugin/plugin.json" | head -n 1)"
[ -n "$VERSION" ] || die "cannot read version from $KIT/.claude-plugin/plugin.json"

DEST="$ROOT/$NAME"
if [ -e "$DEST" ] && [ -n "$(ls -A "$DEST" 2>/dev/null)" ]; then
  die "$DEST exists and is not empty"
fi

mkdir -p "$DEST/.claude/agents" "$DEST/.claude/skills" "$DEST/.claude/templates" "$DEST/.claude/scripts" "$DEST/.claude/hooks" "$DEST/docs/features"

# Roles, process, baseline, the shared stack conventions and the chosen backend and frontend packs
# (other packs are not copied).
cp "$KIT"/agents/*.md "$DEST/.claude/agents/"
cp -r "$KIT/skills/team-workflow" "$KIT/skills/ordna-tasks" "$KIT/skills/baseline-requirements" "$KIT/skills/stack-common" \
      "$KIT/skills/$BACKEND" "$KIT/skills/$FRONTEND" "$DEST/.claude/skills/"

# The read-only board check the lead and the architect run.
cp "$KIT/scripts/check-board.sh" "$KIT/scripts/check-approval.sh" "$DEST/.claude/scripts/"

# The approval gate: a hook that blocks file-editing tools until the user has approved
# the requirements (overview and feature files) and docs/architecture.md (see team-workflow, section 0).
cp "$KIT/hooks/require-approval.sh" "$DEST/.claude/hooks/"
cat > "$DEST/.claude/settings.json" <<'JSON'
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit|NotebookEdit",
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/require-approval.sh" }
        ]
      }
    ]
  }
}
JSON

# Ordna board: file storage (agents edit the markdown; a bare "ordna init" prompts and fails without a
# terminal), a review column between doing and done, and the upstream agent guide (AGENTS.md).
(cd "$DEST" && ordna init --storage=file >/dev/null && ordna skill install >/dev/null)
sed -i 's/^statuses:.*/statuses: [todo, doing, review, done]/' "$DEST/.ordna/config.yaml"
grep -q '^statuses: \[todo, doing, review, done\]' "$DEST/.ordna/config.yaml" || die "could not set the board statuses in $DEST/.ordna/config.yaml"

# Full template set for the agents (adr.md, arc42 skeleton, ...).
cp -r "$KIT"/templates/. "$DEST/.claude/templates/"
rm -f "$DEST/.claude/templates/CLAUDE.md.template"

# Starter documents, one authoritative file each, with the project name filled in. docs/requirements.md is
# the solution overview; every feature (epic) gets its own docs/features/e-N-<slug>/requirements.md, which
# the business-analyst creates from templates/feature-requirements.md.
for f in requirements.md architecture.md test-plan.md tdd-log.md; do
  sed "s/<Project>/$NAME/g" "$KIT/templates/$f" > "$DEST/docs/$f"
done
touch "$DEST/docs/features/.gitkeep"

# CLAUDE.md pins the kit version and names the packs.
sed -e "s/<Project name>/$NAME/" \
    -e "s/<version, e\.g\. [0-9.]*>/$VERSION/" \
    -e "s/^\(- Backend pack: \).*/\1$BACKEND/" \
    -e "s/^\(- Frontend pack: \).*/\1$FRONTEND/" \
    "$KIT/templates/CLAUDE.md.template" > "$DEST/CLAUDE.md"

# Machine-readable record of what the project was created from (CLAUDE.md pins the same version).
cat > "$DEST/.claude/agent-team-kit.version" <<EOF
version=$VERSION
backend=$BACKEND
frontend=$FRONTEND
EOF

cat <<EOF
Created $DEST (agent-team-kit $VERSION)
  backend pack:  $BACKEND
  frontend pack: $FRONTEND
  version pinned in CLAUDE.md and .claude/agent-team-kit.version
  Approval gate: hook in .claude/settings.json blocks code until you approve the overview, the architecture
                 and at least one feature
  Ordna board: tasks/ (columns todo, doing, review, done), AGENTS.md, skill ordna-tasks

Next steps:
  1. Edit $DEST/CLAUDE.md: overrides with reasons, project rules, commands.
     Do this before running any agent.
  2. Run the business-analyst -> docs/requirements.md (overview, feature index), one
     docs/features/e-N-<slug>/requirements.md per feature (= epic), and epics and stories on the board.
     Then: .claude/scripts/check-board.sh --stage requirements
  3. Run the architect -> docs/architecture.md plus a dev and a verify task per story;
     check S0 is a walking skeleton and every slice has a user entry point (BL-FLOW).
     Then: .claude/scripts/check-board.sh --stage design
  4. YOU review the documents and set "Status:" to the word approved in each file, and fill in
     Approved by / on: docs/requirements.md, docs/architecture.md and every feature you want built.
     Until then the hook blocks all code, tests and configuration; a feature is built only once its own
     file is approved. State: .claude/scripts/check-approval.sh  (or --for E-N)
  5. Build slice by slice (developer), verify each slice through the real UI (tester);
     agents update their tasks as they go. Watch the board with: ordna list  (or ordna web).
  6. git init when you are ready; this script does not. Commit tasks/ with the code.
EOF

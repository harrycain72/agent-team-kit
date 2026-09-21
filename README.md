# agent-team-kit

A reusable six-role software team (business-analyst, architect, test-manager, developer, tester, perf-tester), the workflow they follow, reusable baseline requirements, composable stack packs (backend, frontend, common) and document templates. Extracted from the todo-app build (2026-09-19). Version 0.8.0.

## What is here

```
agents/                       generic role definitions (no project specifics)
skills/
  team-workflow/              stages, file handoffs, TDD by vertical slice, definition of done, lessons learned
  ordna-tasks/                the Ordna board: one card per user story, one column per agent, who moves and updates what
  baseline-requirements/      reusable requirements with stable IDs (BL-API, BL-SEC, BL-A11Y, BL-PERF, BL-OPS, BL-TEST, BL-FLOW)
  stack-common/               shared by every combination: repo layout, Makefile targets, backend and frontend contracts
  stack-backend-fastapi-bce/  backend pack: FastAPI, BCE rules + import-linter contracts, test seams, pitfalls
  stack-backend-quarkus-bce/  backend pack: Quarkus + Maven, BCE rules + ArchUnit, test seams, pitfalls
  stack-frontend-react/       frontend pack: Vite, React, shadcn, TanStack Query
  stack-frontend-angular/     frontend pack: Angular, Material, Vitest
scripts/new-project.sh        create a new project from the kit (copy install, version pinned)
scripts/check-project.sh      read-only check of a project's pinned version, board setup and drift against the kit
scripts/check-approval.sh     read-only: have the documents been approved by the user?
hooks/require-approval.sh     PreToolUse hook: blocks code, tests and configuration until they are
scripts/check-board.sh        read-only check that the project's Ordna board follows the ordna-tasks conventions
templates/                    requirements (= docs/business-prd.md, solution overview), feature-requirements (= business-prd.md per feature), technical-prd (per feature), test-plan (per feature), test-strategy, architecture (general), ADR, TDD log, CLAUDE.md, arc42 skeleton
.claude-plugin/               plugin.json + marketplace.json (to install the kit as a plugin)
CHANGELOG.md
```

## Separation of concerns (the point of the layout)

| Concern | Lives in | Changes when |
|---|---|---|
| Roles, process and the task board | `agents/`, `skills/team-workflow`, `skills/ordna-tasks` | you learn something about how the team works |
| General requirements | `skills/baseline-requirements` | a second project needs a new general rule |
| Technology choices | `skills/stack-backend-*`, `skills/stack-frontend-*` | you add or change a backend or frontend (one pack per technology) |
| What every combination shares | `skills/stack-common` | the layout, Makefile names or the contracts between backend and frontend change |
| Project specifics | the project's `docs/` and `CLAUDE.md` | every project |

Agents never name project files; they read the project's `CLAUDE.md`, which names the kit version, the backend and frontend packs, the applied baseline and any overrides.

## Features, epics and documents

An app is a set of **features**. A feature is an **epic** (`E-N`); an epic has n **user stories** (`US-N`); a solution therefore has n epics. Each feature has exactly three documents, and the solution has three general ones:

```
docs/
  business-prd.md                        solution overview: goal, scope, shared domain, feature index, applied baseline (no stories)
  architecture.md                        only what is general: layout, tooling, cross-cutting rules, general ADRs, the S0 walking skeleton
  test-strategy.md                       the general test approach (levels, tools, environments, test data handling, gates); names no feature
  features/
    e-1-login/
      business-prd.md                    business-analyst: the epic E-1 and its stories US-1..US-3
      technical-prd.md                   architect: data model, API, design, feature ADRs, slice plan
      test-plan.md                       test-manager: test cases, test data, charters, traceability (links to the strategy, never restates it)
    e-2-checkout/ ...
```

Templates: `requirements.md` (overview), `feature-requirements.md`, `technical-prd.md`, `test-plan.md`, `test-strategy.md`, `architecture.md`. `E-N` and `US-N` are unique across the solution; the directory starts with the epic id, which is how `check-approval.sh` maps a feature to its board tag. The walking skeleton is the story `S0` with the tag `e-0`; it has no feature directory.

## Approval gate

The business PRDs (overview and each feature), `docs/architecture.md` and each feature's technical PRD begin with `Status: draft`. **You approve them**: read the document, replace `draft` with the word `approved` on that line and fill in `Approved by` / `Approved on`. Agents never set it. **Approval is per feature:** a feature may be built only when the overview, the architecture and that feature's own business PRD and technical PRD are approved, so a reviewed feature can be built while others are still being specified. The test strategy and the test plans are not gated. Until the overview, the architecture and at least one feature are approved, a hook (`.claude/hooks/require-approval.sh`, registered in `.claude/settings.json` by `new-project.sh`) blocks every file write outside `docs/`, `tasks/`, `.ordna/`, `CLAUDE.md`, `AGENTS.md` and `README.md`, for every agent including the lead. An approved document is frozen; to change it, set it back to `draft`. State: `.claude/scripts/check-approval.sh` (all documents) or `--for E-N` (may this feature be built?). Limits: the hook sees file-editing tools, not shell commands that write files, and it cannot tell which feature a source file belongs to (the agents run `--for E-N` and are told not to write files through the shell), and it is a guardrail against agents, not against you. **Known gap (0.7.0):** `check-approval.sh` and the hook check the business PRDs and the architecture only; they do not yet check `technical-prd.md`. The agents' instructions require it approved, but nothing enforces that yet.

## Task board (Ordna)

Requires [Ordna](https://ordna.sh#install): `npm install -g @frehilm/ordna-cli`. Work is tracked as **one card per user story**, stored as markdown in the project's `tasks/`, on a board with **one column per agent role**, so the board shows which agent has a story: `todo` → `general-planning` (business-analyst, architect and test-manager in turn, solution card only) → `business-design` (business-analyst) → `technical-design` (architect) → `test-design` (test-manager) → `development` (developer, unit tests included) → `functional-test` (tester) → `perf-test` (perf-tester) → `done`. The assignee is the agent who has the card now.

| Card | Created by | Updated by |
|---|---|---|
| General-planning card, one per solution (`General planning: <solution>`, tags `planning`, `general`) | lead | analyst (overview), architect (architecture), test-manager (test strategy) hand it on with `ordna assign`; then `user` approves; lead closes it |
| Requirements card, one per feature (`E-N requirements: <feature>`, tags `requirements`, `e-N`) | business-analyst | analyst writes; then waits for your approval in `business-design` (assignee `user`); lead closes it |
| Story card `US-N` (tags `story`, `us-N`, `e-N`; the analyst's criteria as checkboxes) | business-analyst | architect adds build checklist, verification items and notes; test-manager plans cases; developer builds and ticks the checklist; tester ticks criteria as observed and lists defects; perf-tester measures the performance criteria; lead closes it |
| Walking skeleton `S0` (tags `story`, `s0`, `e-0`) | architect | as a story card |

Ordna has no epics or subtasks; a feature is the tag `e-N` and its files, and a story lists the earlier story it builds on in `depends_on`. The `development` column is entered only by the developer's own claim, after `check-approval.sh --for E-N` passes. The rules, the status protocol and the exact commands are in `skills/ordna-tasks`. Agents never commit, including `ordna commit`.

**Known gap (0.7.0):** `scripts/check-board.sh` still checks the previous model (epics, `dev`/`verify` tasks, the `review` status) and has not been rewritten for this one; its errors about those are expected, and the lead judges the board by the `ordna-tasks` skill.

## Starting a new project

Quickest way (copy install, pins the kit version, creates the starter docs):

```bash
scripts/new-project.sh <name> [--root DIR] [--backend PACK] [--frontend PACK]

# examples
scripts/new-project.sh shop                                                       # FastAPI + React (defaults)
scripts/new-project.sh shop --frontend stack-frontend-angular                     # FastAPI + Angular
scripts/new-project.sh shop --backend stack-backend-quarkus-bce --frontend stack-frontend-angular
```

By default the project is created in the directory that contains this kit (so next to the kit's own repository); `--root` overrides that. It requires `ordna` on the PATH (and stops with the install command if it is missing), runs `ordna init --storage=file` in the project, sets the columns to `todo, general-planning, business-design, technical-design, test-design, development, functional-test, perf-test, done`, writes `AGENTS.md`, and copies `agents/`, `team-workflow`, `ordna-tasks`, `baseline-requirements`, `stack-common`, the chosen backend and frontend packs and the templates into `<project>/.claude/`, writes `CLAUDE.md` (with the kit version pinned) and `.claude/agent-team-kit.version`, and the starter documents in `docs/`, and never runs `git init`. Then fill in `CLAUDE.md` before running any agent; ask the business-analyst for one feature at a time, then the architect and the test-manager.

To see whether an existing project is behind the kit or has drifted from it:

```bash
scripts/check-project.sh <project-dir>
```

It is read-only. It compares the project's pinned version (`CLAUDE.md` and `.claude/agent-team-kit.version`) with the kit's, checks the installed packs, and lists agents, skills and templates that differ from the kit. Exit code 0 means up to date with no differences, 1 means attention needed, 2 means a usage error. To upgrade, follow the steps in `CHANGELOG.md`.

Manual steps, if you prefer:

1. Make the kit available (pick one):
   - **Plugin:** `claude plugin marketplace add <path-or-repo-of-this-kit>` then `claude plugin install agent-team-kit@agent-team-kit`.
   - **Copy:** copy `agents/*.md` to `<project>/.claude/agents/` (or `~/.claude/agents/` for all projects) and `skills/*` to `.claude/skills/`.
2. Copy `templates/CLAUDE.md.template` to `<project>/CLAUDE.md` and fill it in (kit version, backend and frontend packs, overrides). Copy `stack-common`, one `stack-backend-*` and one `stack-frontend-*` from `skills/`.
3. Run the business-analyst with `templates/requirements.md` (saved as `docs/business-prd.md`, the overview) and one `templates/feature-requirements.md` per feature (saved as its `business-prd.md`), referencing baseline IDs; then the architect with `templates/architecture.md`, `technical-prd.md` per feature and `adr.md` (and `templates/arc42/` if wanted); then the test-manager with `test-strategy.md` and `test-plan.md` per feature; then build slice by slice as in `skills/team-workflow`.
4. Give each agent its instructions before it starts, and enable the tools they need to hand off.

## Versioning

Semantic versioning in `plugin.json` and `CHANGELOG.md`. A project pins the version in its `CLAUDE.md`. Improve the kit from what each project teaches you, and note it in the changelog.

## Not verified yet (check before relying on it)

- **Document set and board model (0.7.0):** taken over from the task-manager project, where they are in use; the kit's own scripts were only syntax-checked after the change, and `new-project.sh` was not run end to end with the new statuses and starter documents. `check-board.sh` and the hook do not yet cover the new model (see the known gaps above).
- **Features (0.6.0):** `check-approval.sh`, the hook and `check-board.sh` were tested on a hand-made project with simulated hook input (per-feature approval, wrong epic file, duplicate story ids, stories in the overview, started tasks in an unapproved feature). `new-project.sh` and `check-project.sh` were run end to end, and `check-board.sh --stage requirements` was run against real `ordna` tasks and a feature file made from the template. Not observed: analysts actually splitting a real app into feature files, and several analysts drafting features in parallel.

- **Approval hook in Claude Code itself:** the hook script and `check-approval.sh` were tested with simulated hook input (JSON on stdin, exit 2 to block). That Claude Code invokes the hook with these exact field names (`tool_input.file_path`), matcher and `CLAUDE_PROJECT_DIR`, and that it also covers subagents, has not been observed in a live session. Start a real project, ask any agent to write a source file before approving, and confirm it is blocked.
- **Ordna board:** verified by hand against `@frehilm/ordna-cli` 0.4.0 (`ordna --version` prints 0.0.0; this was the previous model): `init --storage=file`, custom statuses, tags and `-d` on `create`, `depends_on` blocking `move ... done` in the parent-depends-on-children direction, `skill install`, and `check-board.sh` on positive and negative boards. **Not verified:** that the agents follow `ordna-tasks` in a real run (that is what `check-board.sh` is for), and parallel agents editing task files at once. The web UI (`ordna web`) was not started.
- The plugin and marketplace manifest fields (`plugin.json`, `marketplace.json`) are written from memory of the format and have never been installed. `owner.name` is a placeholder.
- Whether plugin agents are namespaced by plugin name, and which agent frontmatter fields plugins support.
- `SendMessage` is listed in the agents' `tools:` so they can hand off directly; that it is enough to enable messaging between agents has not been tested.
- The skills' `description` texts drive when they are loaded; adjust after seeing how they trigger.
- The packs describe scaffold files (compose file, Makefile, pyproject or pom, CI) but ship no code. Copy them from the todo-app once, generalise them, and add them as `skills/stack-common/scaffold/` and per-pack scaffolds.
- `stack-backend-quarkus-bce` and `stack-frontend-angular` were written from registry data and a scratch scaffold, never built in a project. Each has a "Verify at first scaffold" list; the first project that uses them should work through it and feed the results back.
- Only FastAPI + React has been built end to end. The other three combinations rely on the contracts in `stack-common`.

## Lifecycle

The kit lives in its own git repository (`agent-team-kit`), separate from any project. Tag each release (`v<version>`, matching `plugin.json` and `CHANGELOG.md`) so a project's pinned version refers to something real. Do not depend on any project for it.

---
name: ordna-tasks
description: How the team tracks its work on the Ordna board (https://ordna.sh): epics, user stories and tasks as markdown files in tasks/, who creates them, and how each role moves and updates them. Load before creating or changing any task, and whenever you start, finish or hand off work.
---

# Ordna task board

The board is the team's shared, current state. Ordna (`@frehilm/ordna-cli`, https://ordna.sh) stores each task as a markdown file `tasks/T-nnn.md`; git is the source of truth. The upstream agent guide is `AGENTS.md` in the project root (written by `ordna skill install`). It says Ordna has no epics or subtasks. **This skill adds them by convention, and it wins where the two differ.**

Install (once per machine): `npm install -g @frehilm/ordna-cli`. Project setup (done by `scripts/new-project.sh`): `ordna init --storage=file`, because agents have no terminal and a bare `ordna init` asks interactively and fails. Storage must be `file`: agents read and edit the markdown files. The board's columns are `todo`, `doing`, `review`, `done` (`statuses` in `.ordna/config.yaml`).

## 1. The hierarchy

| Level | Tags | Title | Created by | Meaning |
|---|---|---|---|---|
| Epic | `epic`, `e-N` | `E-N <title>` | business-analyst | a group of stories with one business goal |
| Story | `story`, `us-N`, `e-N` | `US-N <title>` | business-analyst | one user story = one vertical slice (BL-FLOW-1). Its acceptance criteria are the analyst's. |
| Task | `task`, `us-N`, `e-N`, and `dev`, `verify` or `defect` | `US-N dev: <title>` | architect (`dev`, `verify`); tester (`defect`) | one unit of work for one role |

- `US-N` and `E-N` are the ids in `docs/requirements.md`. Ordna's own ids (`T-nnn`) are separate and assigned in creation order. The tags `us-N` and `e-N` link the two: `ordna list -t us-3` shows a story with all its tasks.
- The walking skeleton (BL-FLOW-2) is a story with tag `s0` instead of `us-N`, under the epic `E-0 Foundation`. The architect creates both.
- **Roll-up is enforced by `depends_on`, parent depends on children:** the epic lists its stories, a story lists its tasks. `ordna move <parent> done` is then refused while any child is open. Never point a child at its parent.
- Never split one behaviour by layer: a story has one `dev` task (test-first, through all layers, ending usable) and one `verify` task, not a backend task and a frontend task (BL-FLOW-1). If a slice truly needs an earlier slice, its `dev` task lists the earlier `dev` task in `depends_on`.
- Tasks for a story are created in slice order, so ids ascend in build order.

## 2. What goes in a task file

Frontmatter is managed by the CLI; edit `depends_on` (the only way to add dependencies after creation) and set `updated_at` to today when you edit by hand. Body sections, in this order:

- `## Goal`: one or two sentences. Stories: the "As a … I want … so that …" text. Tasks: what this task delivers.
- `## Acceptance Criteria`: **one checkbox per criterion**, `- [ ]`. Ticked (`- [x]`) only by the role that observed it; never tick something you did not run.
  - Story: the analyst's Given/When/Then criteria (`US-3.1 …`), copied from `docs/requirements.md`. **Only the tester ticks these**, after seeing them pass through the real interface.
  - `dev` task: the outer acceptance test (named), unit tests for each layer touched, full check green, usable through the entry point. **Only the developer ticks these.**
  - `verify` task: every story criterion observed, the e2e test passes (named), exploratory notes written. **Only the tester ticks these.**
- `## Notes`: entry point, e2e test name, layers touched, links to ADRs, assumptions.
- `## Progress`: append-only, one line per event: `- 2026-09-20 developer: RED <test> fails (<reason>); logged in docs/tdd-log.md`. Get the date from `date +%F`.

## 3. Status protocol

| Status | Means | Set by |
|---|---|---|
| `todo` | planned, not started | creator |
| `doing` | claimed and in progress | the assignee, when they start |
| `review` | the owner's work is finished and needs someone else's check | the assignee, when finished |
| `done` | verified by someone other than the author | see the table below |

Claim: `ordna assign <id> <role>` then `ordna move <id> doing`, before you start work, not after. The assignee is the role name (`business-analyst`, `architect`, `developer`, `tester`). Do not work on a task assigned to another role.

## 4. Who does what, and when

| Moment | Role | Board update |
|---|---|---|
| Requirements written | business-analyst | Creates one story per `US-N` (criteria as checkboxes, priority from MoSCoW: Must=high, Should=medium, Could=low; Won't gets no story), then one epic per `E-N` with the story ids as `-d`. Creates the epics after their stories. Puts the `T-nnn` next to each `US-N` in a table in `docs/requirements.md` §4. |
| Slice plan written | architect | Creates `E-0` and the `s0` story, then for every story a `dev` and a `verify` task (Goal, criteria, Notes with entry point and e2e test name), then adds the task ids to each story's `depends_on` and the story ids to the epic's. Puts story and task ids in the slice table of `docs/architecture.md`. |
| Slice starts | developer | Claims the `dev` task and moves it to `doing`. If the story or epic is still `todo`, moves it to `doing` too (whoever starts the first task does). |
| Each red and green | developer | Appends a `## Progress` line; ticks `dev` criteria as they hold. |
| Slice finished, full check green | developer | Moves the `dev` task to `review`. Tells the lead and the tester. Does **not** mark it `done`. |
| Verification | tester | Claims the `verify` task, moves it to `doing`. Ticks the story's criteria one by one as observed. |
| Slice passes | tester | Moves the `verify` task and the `dev` task to `done`, appends a `## Progress` line with the evidence, and reports to the lead. |
| Slice fails | tester | For each defect: `ordna create "US-N defect: <title>" -t task -t defect -t us-N -t e-N -a developer -p high`, describes it in the file (steps, expected, actual, evidence), adds its id to the story's `depends_on`, and moves the `dev` task back to `doing`. Leaves the story's failed criteria unticked. |
| Defect fixed | developer | Fixes it test-first (the red test first), moves the defect task to `review`, and the `dev` task back to `review` once no defect for the story is `todo` or `doing`. |
| Defect verified | tester | Re-checks, moves the defect task to `done`, and continues as for "Slice passes". |
| Slice accepted | lead | Re-runs the checks, runs `.claude/scripts/check-board.sh`, moves the story to `done` (Ordna refuses while a task is open), and the epic once every story is done. |
| Requirement changes | business-analyst | Once `docs/requirements.md` is approved it is frozen: the user must reopen it (status back to draft) before the analyst changes it. Then edits the story's Goal and criteria and appends a `## Progress` line; tells the architect. A story that is already `done` is not reopened: create a new story instead. |

Rules:
- **Update the board when the work changes state, not at the end.** A stale board is worse than none: the lead and the other roles decide from it.
- **No `dev`, `verify` or `defect` task moves to `doing` before the user has approved `docs/requirements.md` and `docs/architecture.md`** (team-workflow, section 0). Tasks may be created and left in `todo` meanwhile; `check-board.sh` reports started build work without approval.
- **Nobody moves their own work to `done`.** The developer stops at `review`; the tester closes `dev`, `verify` and `defect` tasks; the lead closes stories and epics.
- Never delete a task or renumber ids. Cancel by appending a `## Progress` line and adding the tag `cancelled` (edit the frontmatter); a cancelled task is moved to `done`.
- **Do not run `ordna commit` or `git commit`** unless the user asked; changed `tasks/` files stay in the working tree for the lead to commit (the kit's rule that agents never commit). Ordna does not auto-commit either.
- Only one agent creates tasks at a time (creation is stage-bound: analyst, then architect; defects come from the tester). After `ordna create`, read the printed id back before using it. If two files share an id after a merge, the lead resolves it; Ordna never renumbers.
- Edit only what your role owns (section 4). Parallel agents editing different task files is fine; do not edit a task file another role is working on except to add a defect dependency or a `## Progress` line.
- Read a task with `ordna show <id>` or the file itself before changing it, so nobody's edits are overwritten.

## 5. Commands

```
ordna list                      the board
ordna list -t us-3              everything belonging to story US-3
ordna list -s review            work waiting for a check
ordna list -a developer         one role's tasks
ordna show T-012                one task in full
ordna create "US-3 dev: ..." -t task -t dev -t us-3 -t e-1 -p high -d T-010
ordna assign T-012 developer
ordna move T-012 doing          rejected if a dependency is not done (for done)
ordna web                       optional local Kanban in the browser
```

`.claude/scripts/check-board.sh [project-dir]` is a read-only consistency check (hierarchy, roll-up, statuses, ownership, requirements vs. board). The lead runs it after every stage and every slice.

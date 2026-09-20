---
name: ordna-tasks
description: How the team tracks its work on the Ordna board (https://ordna.sh): one card per user story (plus one requirements card per feature and one general-planning card per solution) as markdown files in tasks/, moving through one column per agent (todo, general-planning, business-design, technical-design, test-design, development, functional-test, perf-test, done), with the current agent as assignee. Load before creating or changing any card, and whenever you start, finish or hand off work.
---

# Ordna task board

The board is the team's shared, current state. Ordna (`@frehilm/ordna-cli`, https://ordna.sh) stores each card as a markdown file `tasks/T-nnn.md`. The upstream agent guide is `AGENTS.md` in the project root. **This project's model (below and in `CLAUDE.md`, "Task board (Ordna)") wins where the two differ.** It replaces the kit's epic > story > `dev`/`verify`/`defect` hierarchy: there is one card per user story, and the agent who owns it right now is the assignee.

Storage must be `file`: agents read and edit the markdown files. The columns are `todo`, `business-design`, `technical-design`, `test-design`, `development`, `functional-test`, `perf-test`, `done` (`statuses` in `.ordna/config.yaml`): one per agent role (`general-planning` is shared by the three planning roles), so the board shows which agent has a story.

## 1. Cards

| Card | Tags | Title | Created by | Meaning |
|---|---|---|---|---|
| General-planning card, one per solution | `planning`, `general` | `General planning: <solution>` | lead | The solution's general documents: overview (`docs/business-prd.md`, analyst), architecture (`docs/architecture.md`, architect), test strategy (`docs/test-strategy.md`, test-manager). |
| Requirements card, one per feature | `requirements`, `e-N` | `E-N requirements: <feature>` | business-analyst | The analyst writes the feature's requirements and story cards; the user approves them. |
| Story card, one per user story | `story`, `us-N`, `e-N` | `US-N <title>` | business-analyst | One vertical slice (BL-FLOW-1), built and verified on this one card. |
| Walking skeleton | `story`, `s0`, `e-0` | `S0 <title>` | architect | Story card for the foundation slice (BL-FLOW-2). |

- There are no epic cards. A feature is the tag `e-N` and its requirements file `docs/features/e-N-<slug>/business-prd.md`; `ordna list -t e-1` shows all its cards.
- `US-N` and `E-N` are the ids in the requirements files and are unique across the solution. Ordna's own ids (`T-nnn`) are separate and assigned in creation order.
- Never split one behaviour by layer or by role: one story is one card, from `todo` to `done`.
- A story lists in `depends_on` the earlier story card it builds on (US-1 on S0, US-2 on US-1). `ordna move <id> done` is refused while a dependency is not done.

## 2. What goes in a story card

Frontmatter is managed by the CLI; edit `depends_on` by hand and set `updated_at` to today when you edit by hand. Sections, in this order:

- `## Goal`: the "As a … I want … so that …" text.
- `## Acceptance Criteria`: the analyst's Given/When/Then criteria as `- [ ]` lines. **Only the tester ticks these**, after observing them through the real interface.
- `## Build checklist`: the developer's items (outer acceptance test red first then green, unit tests per layer, full check green, usable through the entry point). **Only the developer ticks these.** The architect writes them when it plans the slice.
- `## Verification`: the tester's items (every criterion observed, e2e test passes, exploratory notes written). **Only the tester ticks these.**
- `## Defects`: one unticked `- [ ]` per defect the tester finds (steps, expected, actual, evidence); the developer ticks each once fixed test-first.
- `## Notes`: entry point, e2e test name, layers touched, links to ADRs, assumptions.
- `## Progress`: append-only, one line per event: `- 2026-09-20 developer: RED <test> fails (<reason>); logged in docs/tdd-log.md`. Get the date from `date +%F`.

The requirements card has `## Goal`, `## Acceptance Criteria` (the analyst's items and the two approvals), `## Notes` and `## Progress`.

## 3. Status protocol

| Column | Agent with the card | Story card: means | Moved there by |
|---|---|---|---|
| `todo` | nobody yet (assignee = the next agent) | planned, no agent has claimed it | creator |
| `general-planning` | `business-analyst`, `architect`, `test-manager` in turn | solution card only: a general document is being written, or `user` is approving the overview and architecture | the lead (creation), each role hands over with `ordna assign` |
| `business-design` | `business-analyst` | the story and its criteria are being written | the analyst |
| `technical-design` | `architect` | the slice is being planned in the technical PRD | the analyst (hand-off), the architect (claim) |
| `test-design` | `test-manager` | test cases and test data are being planned | the architect (hand-off), the test-manager (claim) |
| `development` | `developer` | being built test-first (unit tests included), or fixing defects | the test-manager (hand-off), the developer (claim) |
| `functional-test` | `tester` | built, full check green; criteria being checked through the real interface | the developer (hand-off) |
| `perf-test` | `perf-tester` | functional test passed and the story has performance criteria; being measured | the tester (hand-off) |
| `done` | – | verified by the tester and accepted by the lead | the lead only |

A stage with nothing to do for a story is skipped: the card is moved on with a `## Progress` line saying why. `perf-test` is skipped for a story with no performance criterion (the tester says so in `## Progress` and the card stays in `functional-test` for the lead).

Requirements card: `business-design` (assignee `business-analyst`) = writing the files and story cards, `business-design` (assignee `user`) = waiting for the user's review and approval, `done` = the overview and the feature's business PRD are approved (the lead moves it).

Claim: `ordna assign <id> <role>` then `ordna move <id> <column>`, before you start work, not after. The assignee is the role name (`business-analyst`, `architect`, `test-manager`, `developer`, `tester`, `perf-tester`) or `user`. Do not work on a card that is with another role.

## 4. Who does what, and when

| Moment | Role | Board update |
|---|---|---|
| General documents | business-analyst, architect, test-manager | Each claims the solution's general-planning card in turn (`ordna assign <id> <role>`; the column stays `general-planning`), writes its general document, appends a `## Progress` line and hands the card on; the card goes to `user` for approval of the overview and the architecture and to `done` (lead) when both are approved. |
| Feature requirements start | business-analyst | Creates the requirements card, assigns it to itself, moves it to `business-design`. |
| Requirements written | business-analyst | Creates one story card per `US-N` (criteria as checkboxes, priority from MoSCoW: Must=high, Should=medium, Could=low; Won't gets no card), in `business-design`, assigned to itself; when the requirements are complete moves them to `technical-design`, assigned to `architect`. Keeps the requirements card in `business-design` and assigns it to `user`. Puts the `T-nnn` of each card into the feature file's board table and feature index. |
| Slice plan written | architect | Claims story cards in `technical-design` (assignee `architect`; creates `S0` there). Plans each slice in the feature's `technical-prd.md`, adds `## Build checklist`, `## Verification` and `## Notes` to the card and sets `depends_on`; puts the card ids in the slice table. Moves the card to `test-design`, assigned to `test-manager`. |
| Test plan written | test-manager | Claims the card in `test-design`, writes its cases and test data into the feature's `test-plan.md` (and `docs/test-strategy.md` once), appends a `## Progress` line with the case ids, moves the card to `development`, assigned to `developer`. |
| Approval | lead | When `check-approval.sh` shows the overview and the feature file approved, moves the requirements card to `done`. |
| Slice starts | developer | Runs the approval check for the card's feature, claims the card (`ordna assign … developer`, `ordna move … development`). |
| Each red and green | developer | Appends a `## Progress` line; ticks Build checklist items as they hold. |
| Slice finished, full check green | developer | Moves the card to `functional-test`, assigns it to `tester`, tells the lead and the tester. Does **not** move it to `done`. |
| Slice passes functional test | tester | Ticks the story criteria and the Verification items one by one as observed, appends the evidence to `## Progress`. With performance criteria: moves the card to `perf-test`, assigns it to `perf-tester`. Without: says so in `## Progress`, reports to the lead, the card stays in `functional-test`. |
| Slice passes performance test | perf-tester | Ticks the performance criteria one by one as measured, appends the evidence (tool, load, numbers) to `## Progress`, reports to the lead. The card stays in `perf-test`. |
| Slice fails | tester or perf-tester | Adds each defect as an unticked `- [ ]` under `## Defects`, leaves the failed criteria unticked, moves the card to `development`, assigns it to `developer`, reports to the lead. |
| Defects fixed | developer | Fixes each test-first (the red test first), ticks the defect, and hands the card back to `functional-test` and `tester` once none is open. |
| Slice accepted | lead | Re-runs the checks, then moves the card to `done`. |
| Requirement changes | business-analyst | Once a requirements file is approved it is frozen: the user must reopen it (status back to draft) first. Then the analyst edits the story's Goal and criteria and appends a `## Progress` line, and tells the architect. A story that is already `done` is not reopened: create a new one. |

Rules:
- **Update the board when the work changes state, not at the end.** A stale board is worse than none. That includes the checkboxes: tick each item (`- [x]`) the moment you have observed it hold, with a `## Progress` line as evidence, never in a batch when you finish. Never tick what you did not run, and never tick an item another role owns.
- **A story card moves to `development` only when the user has approved `docs/business-prd.md`, `docs/architecture.md` and the feature's requirements file** (check with `.claude/scripts/check-approval.sh --for E-N`; for `S0`, which has no feature file, run the plain `.claude/scripts/check-approval.sh`). Cards may be created and left in `todo` meanwhile.
- **Nobody moves their own work to `done`.** The developer stops at `functional-test`, the tester and perf-tester stop after ticking; the lead closes cards.
- Never delete a card or renumber ids. Cancel by appending a `## Progress` line and adding the tag `cancelled`; a cancelled card is moved to `done`.
- **Do not run `ordna commit` or `git commit`** unless the user asked; changed `tasks/` files stay in the working tree.
- Only one agent creates cards at a time (creation is stage-bound: analyst, then architect). After `ordna create`, read the printed id back before using it.
- Edit only what your role owns (section 2). Read a card with `ordna show <id>` or the file itself before changing it, so nobody's edits are overwritten.

## 5. Commands

```
ordna list                      the board
ordna list -t us-3              the card of story US-3
ordna list -t e-1               every card of feature E-1
ordna list -s functional-test      work waiting for the tester
ordna list -s perf-test            work waiting for the perf-tester
ordna list -a developer         one role's cards
ordna show T-012                one card in full
ordna create "US-3 <title>" -t story -t us-3 -t e-1 -a developer -p high
ordna assign T-012 tester
ordna move T-012 functional-test   rejected for done if a dependency is not done
ordna web                       local Kanban in the browser (columns = statuses, assignee on each card)
```

`.claude/scripts/check-board.sh` still checks the kit's old model until the user updates it; the lead judges the board by `CLAUDE.md` and this skill.

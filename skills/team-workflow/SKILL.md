---
name: team-workflow
description: How the six-role team (business-analyst, architect, test-manager, developer, tester, perf-tester) works together: stage order, file-based handoffs, TDD by vertical slice, definition of done, ownership and escalation rules. Load before starting or coordinating any project with these agents.
---

# Team workflow

Roles: **business-analyst** (requirements), **architect** (the general architecture and each feature's technical PRD with its slice plan), **test-manager** (the test strategy, and each feature's test plan with test cases and test data), **developer** (test-first implementation), **tester** (review, acceptance, end-to-end, exploratory), **perf-tester** (performance and load tests against the performance criteria). The **lead** (the main session) coordinates and verifies.

The work is tracked on the **Ordna board** (https://ordna.sh, `tasks/`) as one card per user story plus one requirements card per feature (`CLAUDE.md`, "Task board (Ordna)", overrides the kit's epic > story > task hierarchy). Load the `ordna-tasks` skill: it defines who creates what, and how each role moves and updates cards. The board is the current state of the project; the files below are the content.

## 0. Approval gate (the user, before any code)

A solution is a set of **features**; a feature is an **epic**. The requirements are therefore several documents, and each carries a `Status:` line:

| Document | Holds | Path |
|---|---|---|
| Overview | goal, scope, shared domain, feature index, applied baseline | `docs/business-prd.md` |
| Feature business PRD, one per epic | the epic `E-N` and its user stories | `docs/features/e-N-<slug>/business-prd.md` |
| Feature technical PRD, one per epic | that feature's data model, API, design, feature ADRs, slice plan | `docs/features/e-N-<slug>/technical-prd.md` |
| Feature test plan, one per epic (not gated) | test cases and test data | `docs/features/e-N-<slug>/test-plan.md` |
| Test strategy (not gated) | the general test approach for all features | `docs/test-strategy.md` |
| Architecture | only what is general and valid for all features (layout, tooling, cross-cutting rules, general ADRs, the S0 walking skeleton) | `docs/architecture.md` |

Agents write `Status: draft`. **Only the user sets it to approved**, after reading the document, by editing the file (with `Approved by` and `Approved on`). **A feature may be built only when the overview, the architecture and that feature's own business PRD and technical PRD are approved. Until then no agent (developer, tester, the lead, any other) writes code, tests, configuration or scripts for it.** Documents, the test plan and the board (`tasks/`) may be written meanwhile.

- Approval is per feature, so a feature the user has reviewed can be built while others are still being specified. The user approves the files one at a time.
- The lead, when a document is finished, asks the user to review it and to set the status; it does not set it, and does not start the build without it. `.claude/scripts/check-approval.sh` reports the state of every document (exit 0 when the overview, the architecture and at least one feature are approved); `check-approval.sh --for E-N` answers for one feature (exit 0 only when that feature may be built). The developer and the tester run it with the `e-N` tag of their task.
- An approved document is frozen. A change (a defect in the design, a new requirement) goes to the lead, the user reopens the document by setting the status back to `draft`, the owner edits it, and the user approves again. Work that depends on the changed part stops until then. A new feature needs a new file and a new row in the overview's feature index (reopen the overview), and its slices need the architecture reopened.
- Reopening the overview or the architecture stops **all** building (the hook cannot tell which feature a source file belongs to); reopening one feature's file stops that feature's tasks only, by rule and by `check-board.sh`.
- The rule is enforced by a hook (`.claude/hooks/require-approval.sh`, registered in `.claude/settings.json`) that blocks file-editing tools until the overview, the architecture and at least one feature are approved, and reported by `check-board.sh`, which also flags a started task whose own feature is not approved. The hook does not see shell commands that write files or which feature a source file belongs to, so the agents' instructions cover both.

## 1. Stages and handoffs

| Stage | Owner | Input | Output (the contract) | Done when |
|---|---|---|---|---|
| Requirements | business-analyst | the idea, `CLAUDE.md`, baseline requirements | `docs/business-prd.md` (overview, feature index) + one `docs/features/e-N-<slug>/business-prd.md` per feature (all `Status: draft`) + a requirements card per feature and a story card per `US-N` on the board | stories have testable acceptance criteria; assumptions and open questions listed; every feature has its file and requirements card |
| Design | architect | the overview and the feature's `business-prd.md` | `docs/architecture.md` (general only, `Status: draft`; + general ADRs) + a `technical-prd.md` per feature (`Status: draft`; + feature ADRs, slice plan) + the `S0` story card and, on every story card, the build checklist, verification items and notes | every open question resolved as an ADR; slice plan ordered; tag and package versions checked |
| Test planning | test-manager | the feature's `business-prd.md` and `technical-prd.md`, `docs/architecture.md` | `docs/test-strategy.md` (general) + `test-plan.md` per feature (test cases, test data); story cards moved to `development` | every criterion has a case or a written reason; datasets defined |
| Build | developer(s) | design; **overview, architecture and the feature's business PRD and technical PRD approved by the user** | code, tests, TDD log entries; story card `development`, then `functional-test` assigned to `tester` | slice green, `make check` (or equivalent) green |
| Functional test | tester | slice + acceptance criteria | execution of the feature's test plan, extra tests, defects listed on the story card; story criteria ticked (pass), or the card sent back to `development` (fail) | each criterion pass / fail / not tested, observed not assumed |
| Performance test | perf-tester | slice that passed the functional test and has performance criteria | measurements against the criteria and the test plan's performance cases; evidence and ticks on the story card, or the card sent back to `development` (fail); skipped when the story has no performance criterion | each performance criterion measured, not assumed |

Rules of the handoff:
- **Files are the contract.** Each stage writes its result to a named file and ends its turn with a short summary and the path. Do not paste long documents into messages.
- **One authoritative file per stage.** No draft variants left in the tree (a stray second requirements draft caused confusion once).
- **No editing upstream.** A downstream agent that finds a defect in an upstream document reports it to the lead; the owner changes it.
- **Independent stages run in parallel.** For example, backend and frontend developers on different slices, the tester's plan while the architect designs. Features are independent units of requirements work too: several analysts may draft different feature files at the same time, but the lead hands out the `E-N` ids first and creates the board items one feature at a time (story ids `US-N` are global, and so are Ordna's `T-nnn` ids).
- **The lead verifies.** After every agent report, re-run the checks (tests, lint, coverage) yourself before accepting, and run `.claude/scripts/check-board.sh` to see that the board matches what was reported. Reports are claims. Only the lead moves a card to `done`.
- **The board is updated as work changes state.** Each role claims the story card before starting (assignee = the current agent), hands it on when finished (developer: `functional-test`, assigned to `tester`; tester: `perf-test`, assigned to `perf-tester`, when the story has performance criteria; tester or perf-tester: back to `development` on failure) and never marks its own work `done`; the lead closes cards. A role that finishes without updating the board has not finished.
- If agents cannot message each other, all handoffs go through the lead. Design to need few of them.

## 2. TDD by vertical slice (the default process)

1. **Slice** = one user-visible behaviour through all layers (for example "create a todo"), ending in a working application. Deliver slice by slice, not layer by layer. The slice rules are the baseline **BL-FLOW-1 to BL-FLOW-6**; in short: S0 is a walking skeleton, slices are ordered by time-to-usage, and a slice is done only when a user can use it through the real interface. Never split one behaviour into backend and frontend tasks.
2. The **developer** of the slice writes the failing test first, then the code:
   - RED: an outer test at the API (or UI) boundary describing the behaviour, then unit tests per layer touched. Run them; confirm they fail **for the right reason**.
   - GREEN: the minimum code to pass.
   - REFACTOR: clean up with all tests green; behaviour changes start a new RED.
3. **No production code and no branch without a test that failed first.** Exempt: generated code and pure configuration (they start from a failing check instead).
4. The **tester** does not write layer tests ahead of the code. The tester reviews the slice's tests against the acceptance criteria, adds acceptance, end-to-end and exploratory tests, and reports defects.
5. **Evidence:** the red test is committed (or logged with command and failing summary line) before the implementation. Retroactive tests are allowed only when logged as such and shown able to fail.
6. Tests state behaviour through public interfaces. Do not test private helpers or mock what you own; use fakes for the ports (repository, clock, ids).
7. Never edit an existing test just to make it pass; report it, or change it with a logged reason.

Why not tester-writes-tests-first for whole layers: it serialised the work (developers idled), the tests were written against interfaces that did not exist yet (names became guesses), later design changes forced test rewrites, and no endpoint worked after an hour. See `references/lessons-learned.md`.

## 3. Definition of done (per slice)

- [ ] The overview, the architecture and this feature's requirements file were approved by the user before the first line of code (the approval is in the file, not in a chat message)
- [ ] Failing-test evidence exists and the tests were written before the code
- [ ] Every new source module has its unit test file (enforced by a mapping test, not by review)
- [ ] Full check green: lint and format, layer rules, type check, all unit and integration tests, coverage gates (defaults: 90 % backend, 80 % frontend; see `baseline-requirements`)
- [ ] No skip / xfail / `.only` without a written reason and follow-up in the TDD log
- [ ] Usable (BL-FLOW-4): the behaviour works through the real UI, the app starts with the one dev command, and the tester observed it
- [ ] End-to-end test for the slice exists and passes, referenced by story id (BL-FLOW-5); no orphaned endpoint or UI action (BL-FLOW-6)
- [ ] Refactor step done; API docs and README updated if behaviour or run instructions changed
- [ ] Board: the story card's build checklist and verification items are ticked, every story criterion is ticked by the tester (performance criteria by the perf-tester), and no item under `## Defects` is open
- [ ] The lead re-ran the check and saw it pass, then moved the story card to `done`

## 4. Practical rules learned

- Give each agent a **unique test database name per run**; a fixed shared name made parallel runs collide.
- Keep the **suite collectable** at every handoff: reds come from missing production code only, never from missing test helpers.
- **Verify before pinning**: check that image tags and package versions exist.
- If a **permission prompt or classifier denies a command**, do not work around it; name the command and let the user decide.
- **Untested branches** are a process breach: ask for the test first, leave the branch out until it is red.
- Do not run `git init`, commit or push unless the user asked. That includes `ordna commit`: task changes stay in the working tree.
- Enable the tools agents need to hand off (`SendMessage`), or plan for the lead to relay.
